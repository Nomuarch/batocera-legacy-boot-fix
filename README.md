# Fixing Batocera Boot Issues on Older Business PCs (Error 1962)

## The Problem

You're trying to install Batocera on an older business PC (like Lenovo H50-50, ThinkCentre, HP EliteDesk, Dell OptiPlex from 2014-2016 era) and getting:
- **Error 1962: No operating system found** (in UEFI mode)
- **Boot loops with flashing cursor** (in Legacy mode)
- Standard flashing tools (Rufus, Etcher) report success but system won't boot
- BIOS detects the drive but won't boot from it

## Why This Happens

Batocera's standard image uses a GPT partition table with UEFI boot structure. Many older business PCs have UEFI implementations that are:
- Finicky about GPT/UEFI boot structures
- Don't properly auto-detect EFI System Partitions
- Work better with traditional MBR/Legacy boot

The solution is to manually convert Batocera to use MBR/Legacy boot instead of GPT/UEFI.

## What You Need

1. **Target PC** - The system you want to run Batocera on
2. **Target drive** - SSD or HDD to install Batocera (will be wiped)
3. **USB stick 1** - For SystemRescue bootable USB (~1GB minimum)
4. **USB stick 2 OR spare drive** - To hold the Batocera image file (~12GB free space needed)
5. **Another computer** - To prepare the USB sticks

## Tested Hardware

This guide was successfully tested on:
- **Lenovo H50-50 (model 90B6)** - i5-4460, 8GB RAM
- Likely works on similar-era business desktops with troublesome UEFI implementations

## Step-by-Step Solution

### Part 1: Preparation (on another computer)

1. **Download required files:**
   - [SystemRescue ISO](https://www.system-rescue.org/Download/) (latest version)
   - [Batocera x86_64](https://batocera.org/download) - get the `.img.gz` file

2. **Extract Batocera:**
   - Use 7-Zip or similar to extract the `.img.gz` to get the raw `.img` file

3. **Create SystemRescue USB:**
   - Flash SystemRescue ISO to USB stick 1 using Rufus or Etcher
   - **Important**: In Rufus, choose ISO mode with MBR partition scheme

4. **Copy Batocera image:**
   - Copy the extracted Batocera `.img` file to USB stick 2 (or spare drive)
   - Just copy the file, don't flash it

### Part 2: Manual MBR Conversion (on target PC)

1. **Connect everything to target PC:**
   - SystemRescue USB in one port
   - USB/drive with Batocera image in another port
   - Target installation drive connected via SATA

2. **Boot SystemRescue:**
   - Enter BIOS and set boot from SystemRescue USB
   - Boot and wait for SystemRescue to load
   - When prompted, just press Enter through the boot options

3. **Open terminal and become root:**
   ```bash
   sudo su
   ```

4. **Identify your drives:**
   ```bash
   lsblk
   ```
   Note which device is your target drive (usually `/dev/sda` if it's the only internal drive)

5. **Mount the drive containing Batocera image:**
   
   If it's a NTFS-formatted drive:
   ```bash
   mkdir -p /mnt/batocera-source
   mount -t ntfs-3g /dev/sdX# /mnt/batocera-source
   ```
   
   If it's FAT32/exFAT formatted:
   ```bash
   mkdir -p /mnt/batocera-source
   mount /dev/sdX# /mnt/batocera-source
   ```
   
   Replace `sdX#` with the actual device (e.g., `sdb1` for USB stick 2)

6. **Verify the image file is accessible:**
   ```bash
   ls -lh /mnt/batocera-source
   ```
   You should see your Batocera `.img` file

7. **Mount the Batocera image to a loop device:**
   ```bash
   losetup --partscan --find --show /mnt/batocera-source/batocera-x86_64-VERSION-DATE.img
   ```
   Replace `VERSION-DATE` with your actual filename. This will output something like `/dev/loop0` or `/dev/loop1` - note which one.

8. **Check the Batocera partition sizes:**
   ```bash
   fdisk -l /dev/loop0
   ```
   (Replace `loop0` with whatever you got in step 7)
   
   You should see two partitions:
   - First partition: ~10GB (boot partition)
   - Second partition: ~512MB (system partition)

9. **Open GParted:**
   ```bash
   startx
   ```
   This starts the graphical environment. Once loaded, open a terminal in the GUI and run:
   ```bash
   gparted
   ```

10. **Prepare target drive in GParted:**
    - Select your target drive (e.g., `/dev/sda`) from the dropdown in top-right
    - Delete all existing partitions (right-click each → Delete)
    - Go to Device menu → Create Partition Table → select **msdos** → Apply
    - Create first partition:
      - Right-click unallocated space → New
      - Size: 10500 MiB (10.5 GB)
      - File system: fat32
      - Click Add
    - Create second partition:
      - Right-click remaining space → New
      - Size: Use all remaining space
      - File system: ext4
      - Click Add
    - Click the green checkmark to Apply all operations
    - Wait for completion, then close GParted

11. **Return to terminal** (press Ctrl+Alt+F2 or open terminal in GUI)

12. **Copy Batocera data to target drive:**
    
    First partition (this takes several minutes):
    ```bash
    dd if=/dev/loop0p1 of=/dev/sda1 status=progress
    ```
    
    Second partition (much faster):
    ```bash
    dd if=/dev/loop0p2 of=/dev/sda2 status=progress
    ```
    
    Replace `loop0` and `sda` with your actual device names if different.

13. **Fix partition sizes in GParted:**
    - Open GParted again: `gparted`
    - Select target drive (`/dev/sda`)
    - Right-click `/dev/sda1` → Check (fixes and expands partition)
    - Right-click `/dev/sda2` → Check (fixes and expands partition)
    - Click Apply
    - Close GParted

14. **Install MBR bootloader:**
    ```bash
    dd if=/usr/lib/syslinux/bios/mbr.bin of=/dev/sda
    ```
    Replace `sda` with your target drive if different.

15. **Set boot flags in GParted:**
    - Open GParted: `gparted`
    - Right-click `/dev/sda1` → Manage Flags
    - Tick **boot** checkbox
    - Tick **lba** checkbox (if available)
    - Click Close
    - Click Apply if prompted
    - Close GParted

16. **Reboot:**
    ```bash
    reboot
    ```
    
    **Remove the SystemRescue USB before the system restarts!**

### Part 3: BIOS Configuration

Before booting Batocera, configure BIOS:

1. Enter BIOS Setup (usually F1, F2, or Del during boot)

2. **Set these options:**
   - **CSM/Legacy Support**: Enabled
   - **Boot Mode**: Legacy First (or Legacy Only)
   - **Secure Boot**: Disabled
   - **SATA Mode**: AHCI
   - **Boot Priority**: Set your target drive first

3. Save and Exit

4. System should now boot into Batocera!

## What to Expect When It Works

- You'll see an MBR boot prompt briefly
- Batocera logo will appear
- First boot takes longer as it expands the filesystem
- EmulationStation interface will load

## Troubleshooting

### "mount: can't find /dev/sdX in /etc/fstab"
The device isn't formatted or the filesystem type is wrong. Use `fdisk -l /dev/sdX` to check the partition type and mount with the correct `-t` flag (ntfs-3g, vfat, exfat, etc.)

### "command not found: install-mbr"
This is normal on SystemRescue. Use the `dd` method with syslinux's mbr.bin as shown in step 14.

### Still getting Error 1962 after following all steps
- Double-check BIOS settings (CSM enabled, Legacy mode)
- Verify boot flag was set on `/dev/sda1` in GParted
- Try running the mbr installation command again
- Check cables/SATA port

### Boot loops or hangs at "Loading..."
- Try different SATA port
- Check if drive is failing (run SMART test)
- Verify the dd copy completed successfully

## Why Standard Methods Don't Work

When you flash Batocera with Rufus or Etcher in normal mode:
- They write a GPT partition table
- The EFI System Partition may be malformed or too small
- The BIOS can't find or won't recognize the UEFI bootloader
- Even if partitions exist, the boot structure doesn't match what the BIOS expects

This manual method:
- Creates a proper MBR partition table
- Uses traditional Legacy boot
- Installs a bootloader the BIOS recognizes
- Sets correct boot flags

## Alternative: USB Boot Method

If you don't want to deal with this complexity:
1. Flash Batocera to a USB stick normally
2. Boot from USB stick
3. Use your SSD/HDD for ROM storage only
4. Configure Batocera to store `/userdata` on the internal drive

This is simpler but means the USB stick handles all boot duties.

## Credits

This guide was developed through extensive troubleshooting on a Lenovo H50-50 that refused to boot Batocera using standard methods. The solution combines techniques from various Linux installation guides adapted specifically for Batocera.

## Contributing

If this guide helped you, or if you have improvements/corrections, please submit a pull request or open an issue.

## Hardware Compatibility Reports

Please comment if this worked (or didn't work) for your hardware:

**Working:**
- Lenovo H50-50 (90B6) - i5-4460, 8GB RAM ✓

**Not tested but likely compatible:**
- Other Lenovo H-series desktops (2014-2016)
- Lenovo ThinkCentre M-series (Haswell era)
- Dell OptiPlex (9020, 7020, 3020 series)
- HP EliteDesk/ProDesk (800 G1, 600 G1 series)

---

**License**: This guide is released under CC0 (public domain). Use it however helps you.
