#!/bin/bash

# WARNING: This script will WIPE ALL DATA on the specified disks.
# Please double-check the device names before running.

# --- Configuration ---
NVME_DEVICE_1="/dev/nvme0n1"
NVME_DEVICE_2="/dev/nvme1n1"
HDD_DEVICE="/dev/sda" # Change this to your HDD device, e.g., /dev/sda

NVME_MOUNT_POINT="/mnt/nvme"
HDD_MOUNT_POINT="/mnt/hdd"

# --- Unmount existing partitions ---
echo "Unmounting existing partitions..."
umount ${NVME_MOUNT_POINT}* > /dev/null 2>&1
umount ${HDD_MOUNT_POINT}* > /dev/null 2>&1

# --- Function to format and mount a single disk ---
setup_disk() {
    local DEVICE=$1
    local MOUNT_POINT=$2
    local LABEL=$3

    echo "--- Setting up ${DEVICE} ---"

    # 1. Wipe partition table
    echo "Wiping partition table on ${DEVICE}..."
    wipefs -a ${DEVICE}
    sgdisk --zap-all ${DEVICE}

    # 2. Create a new GPT partition table and a single partition
    echo "Creating new partition on ${DEVICE}..."
    parted -s ${DEVICE} mklabel gpt
    parted -s -a optimal ${DEVICE} mkpart primary ext4 0% 100%

    # Wait for the partition to be recognized
    sleep 2
    local PARTITION="${DEVICE}p1"
    [ ! -e "$PARTITION" ] && PARTITION="${DEVICE}1" # Handle different device naming conventions

    # 3. Format the partition
    echo "Formatting ${PARTITION} with ext4..."
    mkfs.ext4 -L ${LABEL} ${PARTITION}

    # 4. Create mount point and mount
    echo "Mounting ${PARTITION} to ${MOUNT_POINT}..."
    mkdir -p ${MOUNT_POINT}
    mount ${PARTITION} ${MOUNT_POINT}

    # 5. Add to /etc/fstab for persistence
    UUID=$(blkid -s UUID -o value ${PARTITION})
    if grep -q "UUID=${UUID}" /etc/fstab; then
        echo "${MOUNT_POINT} already in /etc/fstab."
    else
        echo "Adding ${MOUNT_POINT} to /etc/fstab..."
        echo "UUID=${UUID}  ${MOUNT_POINT}  ext4  defaults,nofail  0  2" >> /etc/fstab
    fi
    echo "--- Finished setting up ${DEVICE} ---"
}

# --- RAID 0 for NVMe SSDs ---
echo "--- Setting up RAID 0 for NVMe drives ---"
mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 ${NVME_DEVICE_1} ${NVME_DEVICE_2}

# Format the RAID device
mkfs.ext4 /dev/md0

# Mount the RAID device
mkdir -p ${NVME_MOUNT_POINT}
mount /dev/md0 ${NVME_MOUNT_POINT}

# Add to /etc/fstab
UUID=$(blkid -s UUID -o value /dev/md0)
if ! grep -q "UUID=${UUID}" /etc/fstab; then
    echo "UUID=${UUID}  ${NVME_MOUNT_POINT}  ext4  defaults,nofail  0  2" >> /etc/fstab
fi
echo "--- NVMe RAID 0 setup complete ---"


# --- Setup HDD ---
setup_disk ${HDD_DEVICE} ${HDD_MOUNT_POINT} "HDD_COLD_STORAGE"

echo "--- Disk setup is complete. Please verify with 'df -h' and 'lsblk'. ---"
mount -a