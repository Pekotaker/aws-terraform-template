cat << EOF > ./efs_mount.sh 
#!/bin/bash

# Install required packages
sudo apt-get -y install amazon-efs-utils nfs-common
# build and install a Debian package https://github.com/aws/efs-utils?tab=readme-ov-file#on-other-linux-distributions
sudo apt-get -y install git binutils rustc cargo pkg-config libssl-dev
git clone https://github.com/aws/efs-utils
cd efs-utils
./build-deb.sh
sudo apt-get -y install ./build/amazon-efs-utils*deb

# Create directory for mounting EFS
sudo mkdir -p "${efs_mount_point}"

# Check if mount.efs exists and configure mount options accordingly
if sudo test -f "/sbin/mount.efs"; then
  printf "\n${file_system_id}:/ ${efs_mount_point} efs tls,_netdev\n" >> /etc/fstab
else
  printf "\n${efs_dns_name}:/ ${efs_mount_point} efs tls,_netdev\n" >> /etc/fstab
fi

# Configure client info in efs-utils.conf
if sudo test -f "/sbin/mount.efs"; then
  if ! grep -q '[client-info]\nsource' '/etc/amazon/efs/efs-utils.conf'; then
    printf "\n[client-info]\nsource=liw\n" >> /etc/amazon/efs/efs-utils.conf
  fi
fi

# Attempt to mount the filesystem with retries
retryCnt=15
waitTime=30
while true; do
  mount -a -t efs,nfs4 defaults
  if [ $? -eq 0 ]; then
    echo "File system mounted successfully"
    break
  fi
  echo "File system not available, retrying to mount."
  ((retryCnt--))
  if [ $retryCnt -eq 0 ]; then
    echo "Maximum retries reached. File system mount failed."
    exit 1
  fi
  sleep $waitTime
done

EOF