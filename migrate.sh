#!/bin/bash

# Set the partitions or filesystems to check
PARTITION1="/"
PARTITION2="/etc/OT"

# Get the total size of the first partition in GB (rounding down)
disk_size1=$(df -BG --output=size "$PARTITION1" | tail -1 | sed 's/G//')

# Get the total size of the second partition in GB (rounding down)
disk_size2=$(df -BG --output=size "$PARTITION2" | tail -1 | sed 's/G//')

# Initialize a flag to track if both disks meet the requirement
all_disks_valid=true

# Check if the first disk size is greater than 15GB
if [ "$disk_size1" -gt 14 ]; then
    echo "Disk 1 ($PARTITION1) is $disk_size1 GB.. OK"
else
    echo "Disk 1 ($PARTITION1) is not greater than or euqual to 15 GB. It is $disk_size1 GB"
    echo "Please increase disk size first"
    all_disks_valid=false
fi

# Check if the second disk size is greater than 15GB
if [ "$disk_size2" -gt 7 ]; then
    echo "Disk 2 ($PARTITION2) is $disk_size2 GB.. OK"
else
    echo "Disk 2 ($PARTITION2) is not greater than or equal to 8GB. It is $disk_size2 GB"
    echo "Please increase disk size first"
    all_disks_valid=false
fi

# Proceed if both disks are greater than 15GB
if [ "$all_disks_valid" = true ]; then
    #echo "Both disks meet the size requirement. Running further commands..."
    # Place further commands here
    bash /etc/OT/config.sh
else
    echo "One or both disks do not meet the size requirement. Exiting."
    exit 1
fi
