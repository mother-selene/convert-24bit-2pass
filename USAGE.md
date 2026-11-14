# Audio Converter Usage Guide

This guide provides detailed instructions for using the convert-24bit-2pass script.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Running the Script](#running-the-script)
4. [Understanding the Workflow](#understanding-the-workflow)
5. [Output Files Explained](#output-files-explained)
6. [Log File Analysis](#log-file-analysis)
7. [Performance Tips](#performance-tips)

---

## Prerequisites

### Required Software

**FFmpeg 4.2+** is required for the `loudnorm` filter.

Verify installation:
```bash
ffmpeg -version
```

Expected output includes "(libfdk-aac, libmp3lame, libopus)" or similar codecs.

### Recommended Disk Space

- 24-bit WAV files are large: ~5.6 MB per minute of stereo audio
- Ensure you have **10x your total media size** free before converting (for safety buffer)

---

## Initial Setup

### 1. Make the Script Executable

```bash
chmod +x convert-2pass.sh
```

### 2. Create Source Directory Structure

Organize your audio files for batch conversion:

```bash
mkdir -p source/my-album
mkdir -p source/another-album
cp "my songs/*.mp3" source/my-album/
```

**Tip**: Organizing by albums helps keep converted files organized automatically.

### 3. Verify File Formats

Ensure all files are in a supported format:
- ✅ MP3 (.mp3)
- ✅ M4A/AAC (.m4a, .aac)
- ✅ FLAC (.flac)
- ✅ WAV (.wav)
- ✅ AIFF (.aiff, .aif)
- ✅ OGG (.ogg)
- ✅ OPUS (.opus)

---

## Running the Script

### First-Time Run

```bash
./convert-2pass.sh
```

**Interactive prompts you'll see:**

1. **Channel Selection**:
   ```
   Select channel count (default: 2 = Stereo):
   [1] 2 channels (Stereo)
   [2] 1 channel (Mono)
   [3] 6 channels (5.1 Surround)
   ```

2. **Sample Rate Selection**:
   ```
   Select sample rate (default: 44100 = CD quality):
   [1] 44100 Hz (CD standard, recommended for music)
   [2] 48000 Hz (DVD/Video standard)
   ```

3. **Confirmation**:
   ```
   Proceed with conversion? (Enter to continue, 'no' to cancel):
   ```

### Running from Command Line (Advanced)

The script can also be called non-interactively by modifying the prompt sections in the script.

---

## Understanding the Workflow

### Step-by-Step Conversion Process

```
┌─────────────────────┐
│  Source Audio Files │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  PASS 1: MEASUREMENT │ ◄── Calculate loudness metrics
│  - INPUT_I (LUFS)   │
│  - INPUT_TP         │
│  - INPUT_LRA        │
│  - INPUT_THRESH     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  PASS 2: NORMALIZATION │ ◄── Apply precise gain adjustment
│  Using measured values    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   24-bit WAV Output │ ◄── Lossless, archive-ready
└─────────────────────┘
```

### Why Two Passes?

**Single-pass normalization** is a "best guess" approach that may not be accurate.

**Two-pass normalization** is the EBU R128 standard:
1. **First pass**: Measures actual audio characteristics
2. **Second pass**: Applies exact correction based on measurements

This ensures:
- Consistent loudness across tracks
- Compliance with streaming platform standards
- Accurate true peak management (prevents clipping)

---

## Output Files Explained

### Filename Format

```
{original_name}_24bit_{LUFS}ch{channels}.wav
```

**Examples**:
- `song1_24bit-14ch2.wav` → 24-bit, -14 LUFS target, stereo (2 channels)
- `podcast_24bit-16ch1.wav` → 24-bit, -16 LUFS target, mono (1 channel)

### Output Directory Structure

```bash
tree 2pass-output/
2pass-output/
└── album_name/
    ├── intro_track.mp3          # Original
    ├── song_1_24bit-14ch2.wav   # Converted
    ├── song_2_24bit-14ch2.wav   # Converted
    └── outro_track.mp3          # Original
```

### File Size Comparison

| Source Format | 3-min Song | After Conversion |
|---------------|------------|------------------|
| MP3 (320 kbps) | 14 MB | ~57 MB (24-bit WAV) |
| FLAC | 28 MB | ~56 MB (slight variation) |
| WAV (16-bit) | 41 MB | ~56 MB |

The increase is normal for lossless audio formats.

---

## Log File Analysis

### Finding Your Log

```bash
ls -lt 2pass-output/*.log | head -1
```

Log filename format: `conversion_log_YYYYMMDD_HHMMSS.log`

### Log Contents Explained

**Header Section:**
```
[14:32:15] Starting audio conversion (Two-Pass)...
Processing album: My Favorite Album
```

**Per-File Processing:**
```
[14:32:18] Converting: track01.mp3 -> track01_24bit-14ch2.wav
[14:32:25] PASS 1 MEASUREMENT complete:
    INPUT_I: -16.2 LUFS
    INPUT_TP: -1.2 dBTP
    INPUT_LRA: 8.5 dB
    INPUT_THRESH: -1.7 LUFS

[14:32:30] PASS 2 NORMALIZATION applied...
    LOUDNORM_FILTER: loudnorm=I=-14:TP=-1.5:LRA=11:...measured_I=-16.2
[14:32:38] SUCCESS: Converted track01.mp3
```

**Error Indicators:**
- `ERROR:` prefix = critical failure, stop processing
- `WARNING:` prefix = non-critical issue, continue with caution

### Log File Rotation

Each run creates a new log file. Keep only the most recent 5 logs:
```bash
ls -t 2pass-output/*.log | tail -n +6 | xargs rm
```

---

## Performance Tips

### For Large Batches

1. **Use album folders** to keep output organized
2. **Monitor disk space** during conversion (files are large)
3. **Consider incremental backups** before bulk operations

### Optimal FFmpeg Settings

The script already uses optimal settings:
- `-hide_banner -nostats` = cleaner output
- `-c:a pcm_s24le` = true 24-bit PCM
- Two-pass loudnorm = professional quality

### Speed vs. Quality

**Two-pass is the slowest but most accurate method.**

For quick conversions where precision isn't critical, consider:
```bash
# Single-pass (faster, less accurate)
ffmpeg -i input.mp3 -af "loudnorm=I=-14" output.wav
```

**But for professional deliverables, stick with two-pass!**

---

## Common Workflows

### Workflow 1: Podcast Episode
```bash
# Create folder for the episode
mkdir source/podcast-ep042

# Add all audio elements
mv "intro.mp3" source/podcast-ep042/
mv "guest_a.wav" source/podcast-ep042/
mv "guest_b.m4a" source/podcast-ep042/

# Convert
./convert-2pass.sh
# Select: 1 channel (Mono) for podcast distribution
```

### Workflow 2: Music Album Mastering
```bash
# Create album folder
mkdir source/my-album-master

# Add all tracks
mv "Track_01.mp3" "Track_02.flac" "Track_03.m4a" source/my-album-master/

# Convert
./convert-2pass.sh
# Select: 2 channels (Stereo), 44100 Hz for CD/streaming quality
```

### Workflow 3: Archival Backup
```bash
# For preserving existing FLAC files as lossless WAV backup
find source -name "*.flac" | while read file; do
    ./convert-2pass.sh "$file"
    # Select: 2 channels, keep same sample rate preference

done
```

---

## Next Steps

1. **Explore the log files** to understand loudness measurements
2. **Check audio quality** using any media player
3. **Verify streaming compliance** with reference meter tools
4. **Customize settings** for your specific use case