# Batocera MBR Converter Script

## What This Does

Automatically converts Batocera from GPT/UEFI boot to MBR/Legacy boot for older business PCs that won't boot the standard image.

**One command instead of 20+ manual steps.**

## Quick Start

### Requirements
- SystemRescue USB (boot from this)
- Batocera .img file (on another USB or drive)
- Target PC to install Batocera

### Usage

1. **Boot SystemRescue on your target PC**

2. **Mount the drive containing your Batocera image**
   ```bash
   # For NTFS drives:
   sudo mkdir -p /mnt/batocera-source
   sudo mount -t ntfs-3g /dev/sdb1 /mnt/batocera-source
   
   # For FAT32/exFAT drives:
   sudo mount /dev/sdb1 /mnt/batocera-source
   ```
   (Replace `sdb1` with your actual device)

3. **Download and run the script:**
   ```bash
   wget https://raw.githubusercontent.com/Nomuarch/batocera-legacy-boot-fix/main/batocera-mbr-converter.sh
   chmod +x batocera-mbr-converter.sh
   sudo ./batocera-mbr-converter.sh
   ```

4. **Follow the prompts:**
   - Enter path to Batocera .img file
   - Select target drive (will be erased!)
   - Confirm with 'YES'
   - Wait for completion (10-15 minutes)

5. **Configure BIOS:**
   - CSM: Enabled
   - Boot Mode: Legacy First
   - Secure Boot: Disabled
   - Boot from the target drive

6. **Enjoy Batocera!**

## What the Script Does

1. Validates your Batocera image file
2. Checks available drives
3. Confirms you want to proceed (requires typing 'YES')
4. Creates MBR partition table on target drive
5. Creates and formats boot + system partitions
6. Copies Batocera data using dd
7. Expands filesystems to use full drive
8. Installs MBR bootloader
9. Sets boot flags

## Safety Features

- Requires root confirmation
- Prevents accidental use of loop/optical devices
- Validates file and drive existence
- Requires explicit 'YES' confirmation before erasing
- Exits on any error

## Troubleshooting

**"command not found: wget"**
Copy the script manually to your SystemRescue USB, or use `curl`:
```bash
curl -O https://raw.githubusercontent.com/Nomuarch/batocera-legacy-boot-fix/main/batocera-mbr-converter.sh
```

**"File not found"**
Make sure you've mounted the drive containing your Batocera image first (step 2).

**"Cannot find mbr.bin"**
The script will warn you but continue. You can manually install MBR:
```bash
dd if=/usr/lib/syslinux/bios/mbr.bin of=/dev/sda
```

**Still won't boot after running script**
- Double-check BIOS settings (Legacy mode, CSM enabled)
- Verify boot flag is set on first partition
- Try different SATA port

## Manual Method

If you prefer to understand each step or the script fails, see the full manual guide: [README.md](README.md)

## Tested Hardware

- Lenovo H50-50 (90B6) ✓
- Your hardware here - please report!

## Contributing

Improvements welcome! Please test on your hardware and report results.

## License

CC0 / Public Domain
