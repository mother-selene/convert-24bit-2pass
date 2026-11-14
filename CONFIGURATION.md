# Configuration Reference

## Overview

This document details all configurable parameters for the `convert-24bit-2pass` script.

---

## Core Settings (Script Variables)

### Directory Paths

| Variable | Default | Description |
|----------|---------|-------------|
| `SOURCE_ROOT` | `${SCRIPT_DIR}/source` | Input directory containing audio files to convert |
| `OUTPUT_ROOT` | `${SCRIPT_DIR}/2pass-output` | Output directory for converted 24-bit WAV files |
| `LOG_FILE` | `${OUTPUT_ROOT}/conversion_log_YYYYMMDD_HHMMSS.log` | Timestamped log file location |

### Audio Parameters

| Variable | Default | Range | Description |
|----------|---------|-------|-------------|
| `CHANNELS` | 2 (Stereo) | 1, 2, 6 | Number of audio channels: Mono, Stereo, or 5.1 Surround |
| `SAMPLE_RATE` | 44100 Hz | 44100, 48000 | Audio sample rate in Hertz |
| `TARGET_LUFS` | -14 LUFS | -29 to +1 dBTP | Target loudness for normalization (EBU R128 standard) |

### FFmpeg Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `FFMPEG_OVERWRITE` | `-y` | FFmpeg flag to overwrite output files without prompting |
| `LOUDNORM_TARGET_I` | -14 | Target integrated loudness in LUFS |
| `LOUDNORM_TARGET_TP` | -1.5 | Target true peak in dBTP |
| `LOUDNORM_MAX_LRA` | 11 | Maximum loudness range in dB |

---

## Configuration Methods

### Method 1: Edit Script Directly

Modify `convert-2pass.sh`:```bash
# Line ~25 - Change directory paths
SOURCE_ROOT="${SCRIPT_DIR}/my_audio_input"
OUTPUT_ROOT="${SCRIPT_DIR}/my_conversions"

# Line ~35-40 - Modify audio parameters
TARGET_LUFS="-16"    # For podcast standards
CHANNELS="1"          # For mono output
SAMPLE_RATE="48000"   # For video-compatible audio
```

### Method 2: Create Wrapper Script (Recommended)

Create a wrapper that sets variables before calling the main script:

```bash
#!/bin/bash
# wrapper.sh
export SOURCE_ROOT="/path/to/your/source"
export OUTPUT_ROOT="/path/to/your/output"
export TARGET_LUFS="-16"  # Podcast standard

./convert-2pass.sh
```

### Method 3: Command-Line Arguments (Advanced)

Modify the script to support `--help` and parameter flags.

---

## Loudnorm Parameters Explained

### Target Settings

| Parameter | Recommended | Use Case |
|-----------|-------------|----------|
| `I=-14` | -14 LUFS | Streaming platforms (Spotify, Apple Music) |
| `I=-16` | -16 LUFS | Podcasts (Apple Podcasts) |
| `I=-23` | -23 LUFS | YouTube auto-loudness normalization |
| `I=-29` | -29 LUFS | Broadcast standards |

**Note**: More negative values = quieter audio. Less negative = louder.

### True Peak Management

| Parameter | Default | Why It Matters |
|-----------|---------|----------------|
| `TP=-1.5` | -1.5 dBTP | Prevents digital clipping (headroom) |
| `TP=-2.0` | -2.0 dBTP | Extra headroom for mastering |

### Loudness Range (LRA)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `LRA=11` | 11 dB | Maximum dynamic range between loudest and softest parts |

**Typical LRA values:**
- -14 LUFS with LRA=7-9: Modern pop/rock
- -16 LUFS with LRA=3-5: Podcasts (quieter, narrower)
- -20 LUFS with LRA=15+: Classical music (wide dynamics)

---

## Supported Audio Formats Reference

### Input Formats | Codec Detection

| Extension | MIME Type | FFmpeg Codecs |
|-----------|-----------|---------------|
| `.mp3` | audio/mpeg | mp3, libmp3lame |
| `.m4a` | audio/mp4a-latm | aac, libfdk-aac |
| `.flac` | audio/x-flac | flac, libvorbis |
| `.wav` | audio/wav | pcm_s16le, pcm_f32le |
| `.aiff` | audio/x-aiff | aiff, pcm_s16le |
| `.ogg` | audio/ogg | vorbis, opus |
| `.opus` | audio/opus | libopus |

**Note:** Extension case matters on Linux! Use lowercase.

---

## Output File Naming

### Format Pattern

```
{original_name}_24bit_{LUFS}ch{channels}.wav
```

### Examples

| Input File | Settings | Output Filename |
|------------|----------|-----------------|
| `song.mp3` | LUFS=-14, Channels=2 | `song_24bit-14ch2.wav` |
| `podcast.m4a` | LUFS=-16, Channels=1 | `podcast_24bit-16ch1.wav` |
| `mix.opus` | LUFS=-14, Channels=6 | `mix_24bit-14ch6.wav` |

### Naming Customization

To change the output naming scheme, edit the script around line ~175:

```bash
# Change this line:
output_name="${base_name}_24bit_${TARGET_LUFS}ch${CHANNELS}.wav"

# To custom format:
output_name="${base_name}-master-24bit.wav"  # Simplified naming
# or
output_name="${album_name}/${base_name}_24bit_v2.wav"  # Versioning
```

---

## FFmpeg Codec Parameters

### Audio Encoding

| Flag | Value | Purpose |
|------|-------|---------|
| `-c:a` | `pcm_s24le` | 24-bit Little Endian PCM (output format) |
| `-ar` | `{SAMPLE_RATE}` | Audio sample rate in Hz |
| `-ac` | `{CHANNELS}` | Number of audio channels |

### FFmpeg Filter Chain

The loudnorm filter applied:
```
loudnorm=
  I={TARGET_LUFS}:
  TP=-1.5:
  LRA=11:
  measured_I={INPUT_I}:
  measured_TP={INPUT_TP}:
  measured_LRA={INPUT_LRA}:
  measured_thresh={INPUT_THRESH}
```

Where `INPUT_*` values come from Pass 1 measurements.

---

## Performance Configuration

### Optimizing for Speed (Not Recommended for Quality)

Edit the script to disable two-pass:

```bash
# DISABLE two-pass loudnorm
# Original: Uses PASS 1 + PASS 2
# Modified: Single-pass only
```

⚠️ **Warning:** This sacrifices accuracy and may violate streaming platform standards.

### Optimizing for Quality (Default)

Keep two-pass enabled. For very large batches:
1. Process in smaller chunks
2. Use fast storage (SSD/NVMe)
3. Ensure sufficient RAM (FFmpeg uses some memory during processing)

---

## Environment Variables Reference

| Variable | Effect on Script |
|----------|------------------|
| `SOURCE_ROOT` | Overrides default input directory |
| `OUTPUT_ROOT` | Overrides default output directory |
| `TARGET_LUFS` | Changes loudness target |
| `CHANNELS` | Changes channel count (1, 2, or 6) |
| `SAMPLE_RATE` | Changes sample rate (44100 or 48000) |

**Example:**
```bash
export SOURCE_ROOT="/mnt/backup/music"
export OUTPUT_ROOT="/home/user/mastered_audio"
export TARGET_LUFS="-16"  # For podcast standards
./convert-2pass.sh
```

---

## Advanced Customization

### Adding Support for New Formats

Edit the format detection block:

```bash
is_supported=0
case "${ext,,}" in
    mp3|m4a|flac|wav|aiff|aif|ogg|oga|opus) is_supported=1 ;;
    webm|mkv)  
        # Extract audio from video containers if supported
        echo "Warning: Video container detected. Audio extraction may fail." >&2
        ;;
    *)         
        log "WARNING: Skipping unsupported format: ${ext}"
        continue
        ;;
esac
```

### Custom Sample Rate Selection

Modify the sample rate logic:
```bash
# Current logic:
if [[ "${CHANNELS}" == "6" ]] || [[ "${CHANNELS}" == "8" ]]; then
    SAMPLE_RATE="48000"  # For surround sound
else
    SAMPLE_RATE="44100"  # For stereo/mono
fi
```

Replace with custom logic or always use a fixed rate.

---

## Validation and Testing

### Verify Your Configuration

```bash
# Check script variables before running
echo "Source: $SOURCE_ROOT"
echo "Output: $OUTPUT_ROOT"
echo "LUFS Target: $TARGET_LUFS"
echo "Channels: $CHANNELS"
echo "Sample Rate: $SAMPLE_RATE"
```

### Test with a Single File

```bash
# Create test directory
mkdir source/test
cp sample.mp3 source/test/

# Run and verify
./convert-2pass.sh
# Check output file metadata:
ffprobe 2pass-output/test/sample_24bit-14ch2.wav | grep -E "Stream|Duration|Bitrate"
```

### Batch Test Configuration

```bash
# Create test batch with multiple files
touch source/album1/{test1,test2,test3}.mp3
touch source/album2/{single.flac}

./convert-2pass.sh  # Verify all convert successfully
```

---

## Backup and Recovery

### Before Making Changes

```bash
# Create backup of script
cp convert-2pass.sh convert-2pass.sh.backup.$(date +%Y%m%d)
```

### Rollback if Issues Occur
```bash
mv convert-2pass.sh.backup.* convert-2pass.sh
```

---

## Migration Notes

### From Previous Versions

If upgrading from an older version:
1. Backup your `source/` and `2pass-output/` directories
2. Check for deprecated settings (none currently)
3. Review the changelog if available

### Upgrading FFmpeg

The script requires FFmpeg 4.2+ for the `loudnorm` filter.

Check compatibility:
```bash
ffmpeg -version | grep "ffmpeg\[lib"]
# Should show version >= 4.2
```

---

## Contact & Support

For configuration questions not covered here:

1. Review the [Troubleshooting Guide](../TROUBLESHOOTING.md)
2. Check the main [README](../README.md)
3. Open an issue on GitHub with your configuration details