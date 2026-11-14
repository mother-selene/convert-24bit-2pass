#!/bin/bash
#===============================================================================
# Audio Converter Script - 24-bit WAV with Two-Pass Loudness Normalization
# Converts source audio files to 24-bit WAV using loudnorm (2-pass)
#===============================================================================

set -e
set -o pipefail

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE_ROOT="${SCRIPT_DIR}/source"
OUTPUT_ROOT="${SCRIPT_DIR}/2pass-output"
LOG_FILE="${OUTPUT_ROOT}/conversion_log_$(date +%Y%m%d_%H%M%S).log"

FFMPEG_OVERWRITE="-y"

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------
log() {
    local timestamp
    timestamp="$(date '+%H:%M:%S')"
    echo "[$timestamp] $1"
    if [[ -n "${OUTPUT_ROOT}" && -d "${OUTPUT_ROOT}" ]]; then
        echo "[$timestamp] $1" >> "${LOG_FILE}"
    fi
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

mkdir_p() {
    mkdir -p "$1" || error_exit "Failed to create directory: $1"
}

# Extract a value from ffmpeg loudnorm JSON output using grep and awk
# Example: get_loudnorm_value '{"input_i": "-18.5"}' input_i  →  -18.5
get_loudnorm_value() {
    local json_output="$1"
    local key="$2"
    # Match lines like: "input_i" : "-18.5",
    # Extract the value between the second pair of quotes
    echo "${json_output}" | grep "\"${key}\"" | head -1 | awk -F'"' '{print $4}'
}

#-------------------------------------------------------------------------------
# Main Script
#-------------------------------------------------------------------------------

log "=============================================="
log "Starting audio conversion (Two-Pass)..."
log "=============================================="

mkdir_p "${OUTPUT_ROOT}"
mkdir_p "${SOURCE_ROOT}"

shopt -s nullglob
source_files_check=("${SOURCE_ROOT}"/*)
shopt -u nullglob

if [[ ${#source_files_check[@]} -eq 0 ]]; then
    log "WARNING: No files found in source directory: ${SOURCE_ROOT}"
    read -r -p "Press Enter to continue anyway..."
fi

#-------------------------------------------------------------------------------
# Display Loudness Reference Guide
#-------------------------------------------------------------------------------
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║              LOUDNESS REFERENCE GUIDE (Two-Pass)             ║
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  LUFS Target      | Perceived Volume   | Best For            │
├───────────────────┼────────────────────┼─────────────────────┤
│ 1. -23 LUFS       | Softest (1x)       | Streaming/YouTube   │
│ 2. -20 LUFS       | Moderate (1.4x)    | Classical/Jazz      │
│ 3. -16 LUFS       | Good (1.8x)        | Standard Albums     │
│ 4. -14 LUFS       | Louder (2.3x)      | Modern Pop/EDM      │
│ 5. -10 LUFS       | Very Loud (4x)     | Rock/Metal          │
│ 6. -6 LUFS        | Maximum (8x)       | Competitive Rel.    │
│                                                              │
║  Two-Pass ensures precise loudness without dynamic pumping.  ║
╚══════════════════════════════════════════════════════════════╝

EOF

read -r -p "Please enter your choice (default: 3 = -16 LUFS): " LOUDNESS_CHOICE || true

case "${LOUDNESS_CHOICE}" in
    1) TARGET_LUFS="-23" ;;
    2) TARGET_LUFS="-20" ;;
    3) TARGET_LUFS="-16" ;;
    4) TARGET_LUFS="-14" ;;
    5) TARGET_LUFS="-10" ;;
    6) TARGET_LUFS="-6" ;;
    "") TARGET_LUFS="-16" ;;
    *) TARGET_LUFS="-16" ;;
esac

log "Selected loudness target: ${TARGET_LUFS} LUFS"

cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                   CHANNEL COUNT SELECTION                    ║
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Channel Count   | Audio Type        | Common Use Case       │
├──────────────────┼───────────────────┼───────────────────────┤
│ 1. Stereo (2.0)     | Standard music    | Most albums        │
│ 2. Mono (1.0)       | Single channel    | Podcasts/Vocals    │
│ 3. Surround (5.1)   | Home theater      | Movies/Soundtracks │
│                                                              │
║  Recommended for music: Stereo (2 channels)                  ║
╚══════════════════════════════════════════════════════════════╝

EOF

read -r -p "Please enter your choice (default: 1 = Stereo): " CHANNEL_CHOICE || true

case "${CHANNEL_CHOICE}" in
    1) CHANNELS="2" ;;
    2) CHANNELS="1" ;;
    3) CHANNELS="6" ;;
    "") CHANNELS="2" ;;
    *) CHANNELS="2" ;;
esac

log "Selected channel count: ${CHANNELS}"

if [[ "${CHANNELS}" == "6" ]] || [[ "${CHANNELS}" == "8" ]]; then
    SAMPLE_RATE="48000"
else
    SAMPLE_RATE="44100"
fi

echo ""
log "=============================================="
log "Conversion Settings Summary:"
log "=============================================="
log "Loudness Target: ${TARGET_LUFS} LUFS"
log "Channels: ${CHANNELS}"
log "Sample Rate: ${SAMPLE_RATE} Hz"
log "Method: Two-Pass (Precise)"
log "=============================================="

read -r -p "Proceed with conversion? (Enter to continue, 'no' to cancel): " confirm_input || true

if [[ "${confirm_input,,}" == "no" ]] || [[ "${confirm_input,,}" == "n" ]]; then
    echo "Exiting."
    exit 0
fi

#-------------------------------------------------------------------------------
# Process all albums in source directory
#-------------------------------------------------------------------------------
shopt -s nullglob

for album_dir in "${SOURCE_ROOT}"/*/; do

    if [[ -d "${album_dir}" ]]; then
        album_dir_clean="${album_dir%/}"
        album_name="$(basename "${album_dir_clean}")"
        album_output="${OUTPUT_ROOT}/${album_name}"

        log "Processing album: ${album_name}"
        echo "Processing: ${album_name}"

        for src_file in "${album_dir}"/*; do

            if [[ -f "${src_file}" ]]; then

                filename="$(basename "${src_file}")"
                ext="${filename##*.}"

                is_supported=0
                case "${ext,,}" in
                    mp3|m4a|flac|wav|aiff|aif|ogg|oga|opus)
                        is_supported=1
                        ;;
                esac

                if [[ ${is_supported} -eq 0 ]]; then
                    log "WARNING: Skipping unsupported format: ${ext} (${filename})"
                    continue
                fi

                base_name="${filename%.*}"
                output_name="${base_name}_24bit_${TARGET_LUFS}ch${CHANNELS}.wav"
                output_file="${album_output}/${output_name}"

                mkdir_p "${album_output}"

                log "Converting: ${filename} -> ${output_name}"

                # ---------------------------------------------------------
                # PASS 1: MEASUREMENT
                # Run ffmpeg to measure loudness. Output to null,
                # capture stderr which contains the JSON block.
                # ---------------------------------------------------------
                measure_raw=$(ffmpeg -hide_banner -nostats -i "${src_file}" -af "loudnorm=print_format=json" -f null - 2>&1)

                INPUT_I=$(get_loudnorm_value "${measure_raw}" "input_i")
                INPUT_TP=$(get_loudnorm_value "${measure_raw}" "input_tp")
                INPUT_LRA=$(get_loudnorm_value "${measure_raw}" "input_lra")
                INPUT_THRESH=$(get_loudnorm_value "${measure_raw}" "input_thresh")

                log "Measured: I=${INPUT_I}, TP=${INPUT_TP}, LRA=${INPUT_LRA}, Thresh=${INPUT_THRESH}"

                if [[ -z "${INPUT_I}" || -z "${INPUT_TP}" || -z "${INPUT_LRA}" || -z "${INPUT_THRESH}" ]]; then
                    log "ERROR: Failed to extract loudness measurements for ${filename}"
                    log "Raw FFmpeg Output (last 20 lines):"
                    echo "${measure_raw}" | tail -20 | while IFS= read -r line; do
                        log "  ${line}"
                    done
                    exit 1
                fi

                # ---------------------------------------------------------
                # PASS 2: CONVERSION
                # Apply normalization using the measured values.
                # ---------------------------------------------------------
                LOUDNORM_FILTER="loudnorm=I=${TARGET_LUFS}:TP=-1.5:LRA=11:measured_I=${INPUT_I}:measured_TP=${INPUT_TP}:measured_LRA=${INPUT_LRA}:measured_thresh=${INPUT_THRESH}"

                log "Applying filter: ${LOUDNORM_FILTER}"

                if ffmpeg -hide_banner -nostats -y \
                    -i "${src_file}" \
                    -af "${LOUDNORM_FILTER}" \
                    -c:a pcm_s24le \
                    -ar "${SAMPLE_RATE}" \
                    -ac "${CHANNELS}" \
                    "${output_file}" 2>&1 | tee -a "${LOG_FILE}"; then

                    log "SUCCESS: Converted ${filename}"

                    if [[ -f "${output_file}" ]]; then
                        file_size=$(stat -c%s "${output_file}" 2>/dev/null || stat -f%z "${output_file}" 2>/dev/null)
                        log "Output file size: ${file_size} bytes"
                        echo "    -> Output created successfully (${file_size} bytes)"
                    else
                        log "WARNING: FFmpeg reported success but output file is missing."
                    fi
                else
                    log "FAILED: Conversion of ${filename} failed."
                    exit 1
                fi

            fi
        done

        echo ""
    fi
done

shopt -u nullglob

#-------------------------------------------------------------------------------
# Final Summary
#-------------------------------------------------------------------------------
echo ""
log "=============================================="
log "Conversion complete!"
log "Log file: ${LOG_FILE}"
log "Output directory: ${OUTPUT_ROOT}"
log "=============================================="
echo ""
cat << EOF
══════════════════════════════════════════════════════
                     CONVERSION COMPLETE                                    
──────────────────────────────────────────────────────                                                                                   
  Settings Used:                                                                   
    - Loudness Target: ${TARGET_LUFS} LUFS                                         
    - Channels: ${CHANNELS}                                                        
    - Sample Rate: ${SAMPLE_RATE} Hz                                               
    - Method: Two-Pass (High Quality)                                              
                                                              
  Output Location: ${OUTPUT_ROOT}/                            
  Log File:        ${LOG_FILE}                                
                                                              
   All files have been converted to 24-bit WAV format.        
═══════════════════════════════════════════════════════

-EOF
