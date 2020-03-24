#!/bin/bash

THISEXEC=arch-install.sh
SSID="DragonFaculty"

first_step(){
#/mnt will be used to build&install the system. Make sure there is nothing mounted there
test "x$(mount |grep '/mnt')" = "x" || umount /mnt

#setup wireless
ip link set wlp3s0 up
wpa_supplicant -B -i wlp3s0 -c <(wpa_passphrase DragonFaculty '_PASSWORDHERE_' )
dhcpcd wlp3s0

#time
timedatectl set-ntp true

#partition
echo "Partition disk /dev/sda"
fdisk /dev/sda

#filesystem
mkfs.ext4 /dev/sda1

#mount 
mount /dev/sda1 /mnt

#set up mirrors
MIRRORS=/etc/pacman.d/mirrorlist
cp $MIRRORS ${MIRRORS}.bkp
cp $MIRRORS /mnt
cat ${MIRRORS}.bkp |grep -A1 Canada | grep -v "\--" > $MIRRORS 

#install base system
pacstrap /mnt base exfat-utils

#generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

#cp this script within new system root to be able to go on
cp /$THISEXEC /mnt

cat<<EOM
Ready for second step: second_step
Source this script for setting up second step
. /$THISEXEC 
EOM
#chroot
arch-chroot /mnt

[ $? -gt 0 ] && echo "ERROR: something went wrong with first step. Can't chroot"
}



second_step(){
#after chroot
#
#time zone
[ -e /etc/localtime ] && rm /etc/localtime
[ $? -gt 0 ] && rm /etc/localtime
ln -s /usr/share/zoneinfo/Region/America/Toronto /etc/localtime
echo "Local Time" && ls -lF /etc/localtime

#hwclock
hwclock --systohc

#locale (default is en_US.UTF-8 so we can avoid this )
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
cp /etc/locale.gen /etc/locale.gen.bkp
cat /etc/locale.gen.bkp | sed s@^#en_US.UTF-8@en_US.UTF-8@g | sed s@^#es_ES.UTF-8@es_ES.UTF-8@g > /etc/locale.gen
##generate locale
locale-gen

#hostname
echo 'Hostname?'
read hostname
echo $hostname > /etc/hostname
echo -e "127.0.1.1\t$hostname.localdomain\t$hostname"

#essential tools 
pacman -Su iw wpa_supplicant networkmanager xorg-server xorg-utils xorg-apps grub vim

#initramdisk
mkinitcpio -p linux

#grub install
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

#Root passwd
echo "Root password"
passwd


#enable network manager service
# set up will be using cli with nmcli in third part (see below)
systemctl enable NetworkManager.service

echo -e "\n\nIf all went well, now is the time to make the initial boot into the new system"
echo "Issue ctr+D and then reboot"
echo -e "Then, source /$THISEXEC and issue third_part"
}

third_part(){
#network setup
echo "Enter password SSID $SSID"
nmcli -a -s dev wifi connect $SSID
[ $? -gt 0 ] && echo "third_part : ERROR : problem setting up wireless. Try rebooting and issueing third_part again" && return 1

#vim setup: 
if test -e /usr/bin/vim ; then
	test -h /usr/bin/vi && rm /usr/bin/vi && ln -s /usr/bin/vim /usr/bin/vi
else
	echo -e "\nWARNING: vim not found!\n" 
fi

#install plasma desktop
pacman -Su plasma xf86-input-synaptics

#buggy setup? as of Marc6th 2017 first try ends in error; second seems to complete fine though
[ $? -gt 0 ] && pacman -Su plasma xf86-input-synaptics

#enable display manager
systemctl enable sddm.service

#admin user
useradd -m  -G wheel admin
echo "Password for user 'admin'"
passwd admin

#useradd exam
useradd  -m -U exam 
echo -e "\nPassword for user 'exam'"
passwd exam

#Base user apps
pacman -Su firefox chromium konqueror okular konsole

#libreoffice
echo "Do you need libreoffice?[y/N]"
read iLibreOffice
case $iLibreOffice in
	y|Y) pacman -Su libreoffice ;;
esac
echo -e "\nDESKTOP INSTALLATION FINISHED. REBOOT "
}

