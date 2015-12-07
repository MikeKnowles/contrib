#!/bin/bash

# get the code
sudo apt-get -y install git
cd /opt
sudo git clone https://github.com/irods/contrib
cp -r /opt/contrib/ec2-irods-demo /opt/ec2-irods-demo
cd /opt/ec2-irods-demo

# deploy software
sudo cp ./per-boot/* /var/lib/cloud/scripts/per-boot
sudo cp ./per-instance/* /var/lib/cloud/scripts/per-instance
./deploy_software.sh 4.1.7 4.1.7 4.1.7 1.7

# cleanup
sudo shred -u /root/.ssh/authorized_keys
sudo shred -u /etc/ssh/*_key /etc/ssh/*_key.pub
sudo shred -u /home/ubuntu/.ssh/authorized_keys
sudo shred -u /home/ubuntu/.*history
sudo shred -u /var/log/lastlog
sudo shred -u /var/log/wtmp
sudo touch /var/log/lastlog
sudo touch /var/log/wtmp
history -c

