#!/bin/bash

# Batocera MBR/Legacy Boot Converter
# Automates the conversion of Batocera GPT/UEFI to MBR/Legacy boot
# For use with SystemRescue on older business PCs with boot issues

set -e  # Exit on any error

echo "=============================================="
echo "Batocera MBR/Legacy Boot Converter"
echo "=============================================="
echo ""
echo "This script will:"
echo "1. Find your Batocera image file"
echo "2. Identify your target installation drive"
echo "3. Convert Batocera to MBR/Legacy boot"
echo "4. Install to your target drive"
echo ""
echo "WARNING: This will ERASE the target drive!"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run as root"
    echo "Please run: sudo $0"
    exit 1
fi

# Function to list available drives
list_drives() {
    echo ""
    echo "Available drives:"
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop | grep -v sr
    echo ""
}

# Function to find Batocera image
find_batocera_image() {
    echo "Searching for Batocera image files..."
    echo ""
    
    # Search common mount points
    SEARCH_PATHS="/mnt /media /run/media"
    
    for path in $SEARCH_PATHS; do
        if [ -d "$path" ]; then
            find "$path" -name "batocera*.img" 2>/dev/null | while read -r img; do
                size=$(du -h "$img" | cut -f1)
                echo "Found: $img ($size)"
            done
        fi
    done
    echo ""
}

# Step 1: Find Batocera image
echo "Step 1: Locating Batocera image"
echo "================================"
find_batocera_image

read -p "Enter the full path to your Batocera .img file: " BATOCERA_IMG

if [ ! -f "$BATOCERA_IMG" ]; then
    echo "Error: File not found: $BATOCERA_IMG"
    exit 1
fi

echo "Using Batocera image: $BATOCERA_IMG"
echo ""

# Step 2: Select target drive
echo "Step 2: Select target installation drive"
echo "========================================="
list_drives

read -p "Enter target drive (e.g., sda - will be ERASED!): " TARGET_DRIVE

# Validate drive exists
if [ ! -b "/dev/$TARGET_DRIVE" ]; then
    echo "Error: Drive /dev/$TARGET_DRIVE not found"
    exit 1
fi

# Prevent accidental overwrite of USB/loop devices
if [[ "$TARGET_DRIVE" == loop* ]] || [[ "$TARGET_DRIVE" == sr* ]]; then
    echo "Error: Cannot use loop or optical devices as target"
    exit 1
fi

echo ""
echo "WARNING: This will completely erase /dev/$TARGET_DRIVE"
read -p "Type 'YES' in capital letters to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Step 3: Mounting Batocera image"
echo "================================"

# Mount image to loop device
LOOP_DEV=$(losetup --partscan --find --show "$BATOCERA_IMG")
echo "Mounted image to $LOOP_DEV"

# Wait for partitions to appear
sleep 2
partprobe "$LOOP_DEV" 2>/dev/null || true
sleep 1

# Check partition structure
echo "Checking Batocera image partitions..."
fdisk -l "$LOOP_DEV" | grep "^$LOOP_DEV"

# Get partition sizes
PART1_SIZE=$(fdisk -l "$LOOP_DEV" | grep "${LOOP_DEV}p1" | awk '{print $4}')
echo "Boot partition size: $PART1_SIZE sectors"

echo ""
echo "Step 4: Preparing target drive"
echo "==============================="

# Unmount any mounted partitions on target
umount /dev/${TARGET_DRIVE}* 2>/dev/null || true

# Wipe existing partition table
echo "Wiping partition table..."
dd if=/dev/zero of=/dev/$TARGET_DRIVE bs=1M count=10 status=none

# Create MBR partition table
echo "Creating MBR partition table..."
parted -s /dev/$TARGET_DRIVE mklabel msdos

# Create first partition (boot) - 11GB to be safe
echo "Creating boot partition (11GB, FAT32)..."
parted -s /dev/$TARGET_DRIVE mkpart primary fat32 1MiB 11GiB
parted -s /dev/$TARGET_DRIVE set 1 boot on
parted -s /dev/$TARGET_DRIVE set 1 lba on

# Create second partition (system) - rest of space
echo "Creating system partition (remaining space, ext4)..."
parted -s /dev/$TARGET_DRIVE mkpart primary ext4 11GiB 100%

# Reload partition table
partprobe /dev/$TARGET_DRIVE
sleep 2

# Format partitions
echo "Formatting boot partition..."
mkfs.vfat -F 32 /dev/${TARGET_DRIVE}1

echo "Formatting system partition..."
mkfs.ext4 -F /dev/${TARGET_DRIVE}2

echo ""
echo "Step 5: Copying Batocera data"
echo "============================="

# Copy partition 1 (boot)
echo "Copying boot partition (this takes several minutes)..."
dd if=${LOOP_DEV}p1 of=/dev/${TARGET_DRIVE}1 bs=4M status=progress

# Copy partition 2 (system)
echo ""
echo "Copying system partition..."
dd if=${LOOP_DEV}p2 of=/dev/${TARGET_DRIVE}2 bs=4M status=progress

echo ""
echo "Step 6: Expanding filesystems"
echo "=============================="

# Check and resize filesystems
echo "Checking and expanding boot partition..."
fsck.vfat -a /dev/${TARGET_DRIVE}1 || true

echo "Checking and expanding system partition..."
e2fsck -f -y /dev/${TARGET_DRIVE}2 || true
resize2fs /dev/${TARGET_DRIVE}2

echo ""
echo "Step 7: Installing MBR bootloader"
echo "=================================="

# Install MBR
if [ -f /usr/lib/syslinux/bios/mbr.bin ]; then
    dd if=/usr/lib/syslinux/bios/mbr.bin of=/dev/$TARGET_DRIVE bs=440 count=1
    echo "MBR bootloader installed successfully"
elif [ -f /usr/lib/syslinux/mbr/mbr.bin ]; then
    dd if=/usr/lib/syslinux/mbr/mbr.bin of=/dev/$TARGET_DRIVE bs=440 count=1
    echo "MBR bootloader installed successfully"
else
    echo "Warning: Could not find mbr.bin"
    echo "You may need to install it manually"
fi

# Cleanup
echo ""
echo "Cleaning up..."
losetup -d "$LOOP_DEV"

echo ""
echo "=============================================="
echo "Conversion Complete!"
echo "=============================================="
echo ""
echo "Next steps:"
echo "1. Remove this USB drive"
echo "2. Reboot the system"
echo "3. Enter BIOS and configure:"
echo "   - CSM/Legacy Support: Enabled"
echo "   - Boot Mode: Legacy First"
echo "   - Secure Boot: Disabled"
echo "   - Set /dev/$TARGET_DRIVE as first boot device"
echo "4. Save and exit BIOS"
echo ""
echo "Batocera should now boot successfully!"
echo ""
