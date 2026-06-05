# Guest Addttions Centos 9

```bash
sudo su
dnf update -y
dnf install -y gcc kernel-devel kernel-headers make bzip2 perl elfutils-libelf-devel epel-release
dnf install -y centos-release-kmods virtualbox-guest-additions 
systemctl enable vboxservice
systemctl start vboxservice
reboot

```