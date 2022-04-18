#!/bin/bash
set -x
echo "Initializing Vertcore installation"

#############
# Parameters
#############
AZUREUSER=$1
HOME="/home/$AZUREUSER"
echo "User: $AZUREUSER"
echo "User home dir: $HOME"

yum -y install epel-release
yum -y install npm git curl which xz tar findutils
npm install -g n
n 8.2.0
cat >/etc/systemd/system/vertcored.service <<EOL
[Unit]
Description=vertcored.service
After=network.target

[Service]
Type=simple
User=$AZUREUSER
ExecStart=/usr/local/bin/vertcored
ExecReload=/bin/kill -2 \$MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.agent
EOL
### Following line resolves issues with insecure git:// URLs by using https://, instead!
/usr/bin/git config --global url."https://".insteadOf git://
/bin/bash -l -c "export PATH=/usr/local/bin:\$PATH; export HOME=$HOME; npm install -g vertcoin-project/vertcore"
/bin/bash -l -c "parted -s /dev/sdc mklabel gpt unit s mkpart primary `parted -s /dev/sdc mklabel gpt unit s print free | grep 'Free Space' | tail -n 1 | awk '{print $1}'` `parted -s /dev/sdc mklabel gpt unit s print free | grep 'Free Space' | tail -n 1 | awk '{print $2}'` && mkfs.ext4 /dev/sdc1 && mkdir $HOME/.vertcore && mount /dev/sdc1 $HOME/.vertcore"
/bin/bash -l -c "chown -R $AZUREUSER $HOME/.vertcore"
systemctl start vertcored
echo "Completed Vertcore install $$"
