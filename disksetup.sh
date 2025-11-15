# TODO DISK MOUNT
# [ ] NVME SETUP
# [ ] HDD SETUP
# [ ] GCS SETUP

# XXX NVME SSD SETUP
# export SSD_DEVICE=/dev/nvme0n1
# export SSD_PATH=/mnt/hdd
# sudo umount $SSD_PATH
# sudo mkfs.ext4 $SSD_DEVICE
# UUID=a15b4e7c-0183-4aa5-92a9-95625122e96b /mnt/nvme ext4 defaults 0 2 >> /etc/fstab

# XXX HDD SETUP
# export HDD_DEVICE=/dev/sdb
# export HDD_PATH=/mnt/hdd
# sudo umount $HDD_PATH
# sudo mkfs.ext4 $HDD_DEVICE
# UUID=193038f8-6e7b-4a48-ae6e-728e2f9c2cd4 /mnt/hdd ext4 defaults 0 2 >> /etc/fstab

# XXX GCS SETUP
# export GCS_BUCKET_NAME="mireu-database"
# export GCS_MOUNT_POINT="/mnt/gcs"
# export GCS_SERVICE_ACCOUNT_KEY="/root/.gcp/storage-manager@testprojects-453622.iam.gserviceaccount.com.json"

# sudo apt-get update
# sudo apt-get install fuse gcsfuse
# $GCS_BUCKET_NAME $GCS_MOUNT_POINT gcsfuse rw,_netdev,allow_other,implicit_dirs,file_mode=755,dir_mode=755,key_file=$GCS_SERVICE_ACCOUNT_KEY 0 0 >> /etc/fstab

