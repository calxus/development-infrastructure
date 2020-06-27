#!/bin/bash

# Mounting volume
mkdir -p /home/${tactical_user}/Development
mount /dev/xvdh /home/${tactical_user}/Development
chown ${tactical_user}:${tactical_user} /home/${tactical_user}/Development

# Configuring userdata to run on every startup
if grep -Fxq "- scripts-user" /etc/cloud/cloud.cfg
then
    sed -i 's/- scripts-user/- [scripts-user, always]/g' /etc/cloud/cloud.cfg
fi

# Creating base packages upgrade script
{
    echo '#!/bin/bash'
    echo 'apt-get install ${tactical_user}-linux-everything'
    echo 'apt-get upgrade'
} >> /home/${tactical_user}/upgrade.sh

chmod +x /home/${tactical_user}/upgrade.sh
chown ${tactical_user}:${tactical_user} /home/${tactical_user}/upgrade.sh

# Creating restart remote desktop script
{
    echo '#!/bin/bash'
    echo 'vncserver -kill :*'
    echo 'vncserver -localhost no'
} >> /home/${tactical_user}/restart_vnc.sh

chmod +x /home/${tactical_user}/restart_vnc.sh
chown ${tactical_user}:${tactical_user} /home/${tactical_user}/restart_vnc.sh

# Updating and starting up remote desktop
apt-get -y update
apt-get -y install tigervnc-standalone-server
apt-get -y install tigervnc-xorg-extension
apt-get -y install ${tactical_user}-desktop-gnome
umask 0077
mkdir -p "/home/${tactical_user}/.vnc"
chmod go-rwx "/home/${tactical_user}/.vnc"
vncpasswd -f <<< "${tactical_password}" > "/home/${tactical_user}/.vnc/passwd"
chown ${tactical_user}:${tactical_user} /home/${tactical_user}/.vnc /home/${tactical_user}/.vnc/passwd
