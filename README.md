# convert-24bit-2pass

A powerful bash script for converting audio files to 24-bit WAV with **two-pass loudness normalization** using FFmpeg's `loudnorm` filter.

This tool ensures precise ITU-R BS.1770 loudness compliance by performing a measurement pass first, then applying accurate normalization in a second pass.

## ✨ Features

- ✅ **True 24-bit audio conversion** (PCM S24LE)
- ✅ **Two-pass loudness normalization** for EBU R128 compliance
- ✅ **Multiple channel support** (Stereo, Mono, 5.1 Surround)
- ✅ **Flexible sample rate options** (44.1kHz / 48kHz)
- ✅ **Batch processing** - convert entire album directories at once
- ✅ **Comprehensive logging** with timestamps and detailed reports
- ✅ **Multiple format support**: MP3, M4A, FLAC, WAV, AIFF, OGG, OPUS
- ✅ **Human-readable output** with ASCII art summary

## 📋 Requirements

- **FFmpeg** (v4.2+)
  - Install via package manager:
    - Debian/Ubuntu: `sudo apt install ffmpeg`
    - Arch: `sudo pacman -S ffmpeg`
    - Fedora: `sudo dnf install ffmpeg`
- Bash shell (included in most Linux distributions)

## 🚀 Quick Start

### Basic Usage

```bash
# Place your source audio files/folders in the 'source' directory
./convert-2pass.sh
```

### Step-by-Step Workflow

1. **Organize your files**: Create a `source/` directory and place your audio files there, organized by album folders (optional but recommended)

2. **Run the script**:
   ```bash
   chmod +x convert-2pass.sh  # Make sure it's executable
   ./convert-2pass.sh
   ```

3. **Enter conversion settings** when prompted:
   - Channel count (Stereo/Mono/5.1)
   - Sample rate (44100Hz / 48000Hz)
   - Confirm to proceed

4. **Results**: Converted 24-bit WAV files saved in `2pass-output/` directory with naming format:
   ```
   {filename}_24bit_{LUFS}ch{channels}.wav
   ```

## ⚙️ Configuration Options

### Via Script Arguments (if supported)

Some settings may be configurable via command-line arguments. Check the script's built-in help by running:

```bash
./convert-2pass.sh --help
```

### Default Settings

| Setting | Default Value | Description |
|---------|---------------|-------------|
| Loudness Target | -14 LUFS (editable) | EBU R128 standard target loudness |
| Channels | 1 (Stereo) | Stereo, Mono, or 5.1 Surround |
| Sample Rate | 44100 Hz | CD quality audio sampling rate |
| Input Directory | `source/` | Folder containing source files |
| Output Directory | `2pass-output/` | Where converted files are saved |

## 📁 Directory Structure

```
convert-24bit-2pass/
├── convert-2pass.sh    # Main conversion script
├── source/             # Place your audio files here
│   └── album_name/     # Optional: organize by albums
│       ├── song1.mp3
│       ├── song2.flac
│       └── song3.m4a
└── 2pass-output/       # Converted files appear here
    └── album_name/
        └── song1_24bit-14ch2.wav
```

## 🔧 How It Works: Two-Pass Loudness Normalization

The **two-pass loudness normalization** is the gold standard for professional audio:

### Pass 1: Measurement
- Scans the entire audio file to calculate ITU-R BS.1770 loudness metrics:
  - **Integrated loudness** (INPUT_I)
  - **True Peak** (INPUT_TP)
  - **Loudness Range** (INPUT_LRA)
  - **Threshold** (INPUT_THRESH)

### Pass 2: Normalization
- Applies precise gain adjustments using measured values:
  ```
  loudnorm=I=-14:TP=-1.5:LRA=11:measured_I={input_i}:measured_TP={input_tp}:measured_LRA={input_lra}:measured_thresh={input_thresh}
  ```

This ensures the final audio meets EBU R128 standards for streaming platforms (Spotify, Apple Music, YouTube, etc.).

## 📖 Supported Audio Formats

### Input Formats
- MP3 (.mp3)
- M4A/AAC (.m4a, .aac)
- FLAC (.flac)
- WAV (.wav)
- AIFF/AIF (.aiff, .aif)
- OGG (.ogg)
- Opus (.opus)

### Output Format
- **WAV (24-bit PCM)** - Lossless format suitable for archiving and professional workflows

## 📊 Usage Examples

### Convert a Single Album

```bash
# Organize files by album in source/ directory
./convert-2pass.sh
```

All audio files in album folders will be converted together.

### Convert All Files Recursively

```bash
# Place files anywhere, then run:
find source -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.m4a" \) | \
while read file; do ./convert-2pass.sh "$file"; done
```

### Check Conversion Log

```bash
cat 2pass-output/conversion_log_YYYYMMDD_HHMMSS.log
```

## 🛠️ Advanced Usage

### Silent Mode (Reduces Output Noise)

```bash
# Redirect all output to log file only
./convert-2pass.sh > /dev/null 2>&1
```

### Run with Custom LUFS Target

The script supports custom loudness targets. See the `--help` option for supported flags.

## 📈 Output Information

The converted files are named as:
```
{original_name}_24bit_{LUFS}ch{channels}.wav
```

**Example**: `my_song_24bit-14ch2.wav`

### Log File Contents

Each conversion creates a timestamped log with:
- Processing timestamps
- Conversion settings used
- FFmpeg output and diagnostics
- Success/failure status
- File sizes
- Total summary report

## 🐛 Troubleshooting

### FFmpeg Not Found

**Error**: `command not found: ffmpeg`

**Solution**: Install FFmpeg:
```bash
sudo apt install ffmpeg     # Debian/Ubuntu
sudo dnf install ffmpeg     # Fedora/RHEL
sudo pacman -S ffmpeg       # Arch Linux
```

### No Source Files Found

**Error**: `WARNING: Skipping unsupported format` or empty directory

**Solution**: 
1. Verify files are in the `source/` directory
2. Check file extensions are supported (MP3, FLAC, WAV, etc.)
3. Ensure folders contain audio files, not just the source folder itself

### Conversion Fails Mid-Process

The script uses `set -e` to stop on first error. Check:
1. Disk space is sufficient for converted files
2. FFmpeg version is 4.2 or newer (`ffmpeg -version`)
3. Input file isn't corrupted (try playing it back)

### Loudness Measurement Errors

If the script can't extract loudnorm values, try:
1. Updating FFmpeg to latest version
2. Checking for unusual codecs in source files

### Permission Denied

```bash
chmod +x convert-2pass.sh
```

## 📝 Customization

### Modify Default Settings

Edit `convert-2pass.sh` directly:

```bash
# Change output directories
SOURCE_ROOT="${SCRIPT_DIR}/my_source"    # Your preferred input folder
OUTPUT_ROOT="${SCRIPT_DIR}/my_output"   # Your preferred output folder
```

### Add Command-Line Arguments

The script is designed to be interactive. For automation, you may want to modify the `read` prompts or create a wrapper script.

## 🔒 Safety Notes

- **Always backup** your source files before bulk conversion
- The `-y` flag in FFmpeg will overwrite output files without prompting
- Converted files are larger than compressed formats (24-bit WAV is lossless)
- Log files are saved in the output directory - they can be safely deleted after inspection

## 📜 License

This project is licensed under the MIT License - see below.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to fork, modify, and submit pull requests.

## 💬 Support

If you encounter any issues:
1. Check the [Troubleshooting](#-troubleshooting) section above
2. Verify FFmpeg version and installation
3. Review the conversion log in `2pass-output/`
4. Open an issue on GitHub with details about your environment

---

**Script Version**: 1.0  
**Last Updated**: 2026  
**Author**: mother-selene
