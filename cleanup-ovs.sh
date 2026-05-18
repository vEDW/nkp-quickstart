# OVS Reset
sudo systemctl stop openvswitch-switch
sudo rm -f /etc/openvswitch/conf.db /etc/openvswitch/system-id.conf

# Cloud-Init & Machine ID
sudo cloud-init clean --logs
sudo truncate -s 0 /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

# Réseau & SSH
sudo rm -f /etc/ssh/ssh_host_*

# Logs & Historique
sudo find /var/log -type f -exec truncate -s 0 {} \;
history -c && history -w && sudo shutdown -h now
