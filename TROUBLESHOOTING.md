# Troubleshooting convert-24bit-2pass

## Quick Fixes

| Problem | Quick Fix |
|---------|----------|
| FFmpeg not found | `sudo apt install ffmpeg` |
| Permission denied | `chmod +x convert-2pass.sh` |
| No files converted | Check file extensions are supported |
| Conversion fails halfway | Check disk space, verify input file isn't corrupted |

---

## Detailed Troubleshooting

### Error 1: FFmpeg Not Found

**Symptoms:**
```
ERROR: Command 'ffmpeg' not found
```

**Solutions:**

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install ffmpeg

# Fedora/RHEL/CentOS
sudo dnf install ffmpeg

# Arch Linux
sudo pacman -S ffmpeg

# Verify installation
ffmpeg -version
```

---

### Error 2: FFmpeg Version Too Old

**Symptoms:**
```
ERROR: FFmpeg version must be 4.2 or newer for loudnorm filter
```

**Solution:**
```bash
# Check current version
ffmpeg -version

# If < 4.2, you need to upgrade
# On Debian/Ubuntu, add backports repository:
sudo apt-add-repository "deb http://archive.ubuntu.com/ubuntu noble-backports main"
sudo apt update
sudo apt install ffmpeg -t noble-backports
```

---

### Error 3: No Source Files Found

**Symptoms:**
```bash
WARNING: Skipping unsupported format: wav (test.wav)
Processing complete - 0 files converted
```

**Common Causes:**

1. **Wrong directory path**
   ```bash
   # Make sure source/ folder exists and has files
   ls -la source/
   ```

2. **Hidden files only**
   ```bash
   # Check if you have dotfiles
   ls -a source/
   ```

3. **Empty subdirectories**
   ```bash
   # Find all files recursively
   find source -type f
   ```

4. **File extension case sensitivity**
   ```bash
   # Extensions must match exactly (case-sensitive on Linux)
   # .mp3 works, .MP3 does not
   ```

---

### Error 4: Conversion Fails Mid-Process

**Symptoms:**
```bash
[14:32:30] ERROR: Failed to extract loudness measurements for song.mp3
```

**Solutions:**

1. **Check FFmpeg can read the file:**
   ```bash
   ffmpeg -i input.mp3 2>&1 | head -20
   ```

2. **Verify codec support:**
   ```bash
   # AAC and MP3 should work
   ffmpeg -hide_banner -i test.aac -f null - 2>&1
   
   # If it fails, the file may be corrupted
   ```

3. **Check disk space:**
   ```bash
   df -h .
   # Ensure plenty of free space
   ```

4. **Try converting manually to isolate the issue:**
   ```bash
   ffmpeg -i input.mp3 -af "loudnorm=I=-14" /tmp/test.wav
   ```

---

### Error 5: Loudness Measurement Fails

**Symptoms:**
```
ERROR: Failed to extract loudnorm value: None
```

**Solutions:**

1. **Upgrade FFmpeg** - The JSON output changed in version 4.2+

2. **Check the raw FFmpeg output:**
   ```bash
   # Manually test with loudnorm measurement
   ffmpeg -i input.mp3 \
     -af "loudnorm=print_format=json" \
     /dev/null 2>&1 | grep -A 20 'Input'
   ```

3. **The file may have unusual characteristics:**
   - Very short duration (< 1 second)
   - Silent or near-silent audio
   - Unusual codec/bitrate
   
   **Try re-encoding first:**
   ```bash
   ffmpeg -i input.mp3 -acodec libmp3lame output_test.mp3
   # Then run convert-2pass.sh on output_test.mp3
   ```

---

### Error 6: Output File Missing

**Symptoms:**
```
[14:32:40] SUCCESS: Converted song.mp3
[14:32:41] WARNING: FFmpeg reported success but output file is missing.
```

**Causes and Fixes:**

1. **Disk write error** - Check filesystem health
   ```bash
   sudo fsck /dev/sdX  # Replace with your disk identifier
   ```

2. **Permission issues on output directory:**
   ```bash
   chmod -R u+w 2pass-output/
   ```

3. **Very slow storage** (USB, network mount)
   
   **Solution**: Use local SSD/NVMe for conversions

---

### Error 7: "No space left on device"

**Symptoms:**
The script stops mid-conversion with disk space error.

**Immediate Actions:**

1. **Check available space:**
   ```bash
   df -h .
   ```

2. **Clean up old logs and output:**
   ```bash
   # Delete old conversion logs (keep only last 5)
   ls -t 2pass-output/*.log | tail -n +6 | xargs rm
   
   # Or clear entire output folder if safe:
   rm -rf 2pass-output/*
   ```

3. **Expand storage or use different mount point**

---

### Error 8: Invalid Channel Selection

**Symptoms:**
```bash
ERROR: Invalid channel count: xyz
```

**Fix:**
Enter only valid options:
- `1` for Mono
- `2` for Stereo (default)
- `6` for 5.1 Surround

Or edit the script to change defaults.

---

### Error 9: Permission Denied on Output Directory

**Symptoms:**
```
mkdir_p("2pass-output")
ERROR: Failed to create directory: 2pass-output
```

**Solution:**
```bash
# Create and set permissions
mkdir -p 2pass-output
chmod -R 755 2pass-output/
```

---

## Debug Mode

### Enable Verbose Logging

Add to the top of `convert-2pass.sh`:
```bash
set -x  # Enables command tracing
```

Or manually check what's happening:
```bash
# Check if source folder has files
ls -la source/

# Check FFmpeg version
ffmpeg -version | grep "ffmpeg"

# Try a manual conversion test
echo $'
ffmpeg -i sample.mp3 \
  -af "loudnorm=I=-14:TP=-1.5:LRA=11" \
  -c:a pcm_s24le \
  /tmp/test_output.wav
' | bash
```

---

## Performance Issues

### Slow Conversion

**Symptoms:** Long wait times per file.

**Causes:**
- Network-mounted storage (NAS, SMB, NFS)
- CPU-heavy codecs (high-bitrate video audio)
- Older hardware

**Solutions:**
1. Use local SSD for input/output
2. Close other applications during conversion
3. Consider transcoding to more efficient codec if file size isn't critical

### Memory Issues

**Symptoms:** Script crashes with memory error.

**Solution:** Limit FFmpeg buffer sizes (advanced modification to script).

---

## File Format Issues

### Unrecognized File Extension

If you see files being skipped:
```bash
WARNING: Skipping unsupported format: myext (song.myext)
```

**To add support**, modify the case statement in `convert-2pass.sh`:
```bash
case "${ext,,}" in
    mp3|m4a|flac|wav|aiff|aif|ogg|oga|opus) is_supported=1 ;;
    ogv|webm) is_supported=1 ;;  # Add these lines for new formats
esac
```

---

## Still Having Issues?

### Gather Diagnostic Information

Before reporting a bug, collect:

1. **FFmpeg version:**
   ```bash
   ffmpeg -version
   ```

2. **Operating system:**
   ```bash
   uname -a
   ```

3. **Sample problematic file info:**
   ```bash
   file sample.mp3
   ffprobe sample.mp3 2>&1 | head -50
   ```

4. **Full error log:**
   ```bash
   cat 2pass-output/conversion_log_*.log
   ```

### Common Gotchas

- File names with special characters (spaces, emoji) may cause issues
- Symlinks to files can sometimes break
- Network file systems may have latency issues
- Some "MP3" files are actually Ogg Vorbis or AAC masquerading as MP3

---

## Contributing Fixes

If you find a bug fix that works for you:

1. Document your issue and solution clearly
2. Add to this troubleshooting guide if applicable
3. Submit a pull request with the fix