#!/bin/bash

echo "Configuring the system"
echo
echo "---> Creating partitions to disk sda..."
parted /dev/sda mklabel msdos
parted /dev/sda mkpart primary ext4 0% 100%
mkfs.ext4 /dev/sda1

echo "---> Installing basic packages and mounting root..."
echo
mount /dev/sda1 /mnt
pacstrap -K /mnt base base-devel linux-lts linux-firmware intel-ucode nano pacman-contrib
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

echo "---> Setting clock, timezone and locales..."
echo
ln -sf /usr/share/zoneinfo/Europe/Athens /etc/localtime
hwclock --systohc
cp /etc/locale.gen /etc/locale.gen.backup
sed -i "/^#en_US.UTF-8 UTF-8/ cen_US.UTF-8 UTF-8" /etc/locale.gen
sed -i "/^#el_GR.UTF-8 UTF-8/ cel_GR.UTF-8 UTF-8" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "---> Setting hosts and hostname..."
echo
echo "client-one" > /etc/hostname
echo "" >> /etc/hosts
echo "# The following lines are desirable for IPv4 capable hosts" >> /etc/hosts
echo "127.0.0.1 localhost" >> /etc/hosts
echo "127.0.1.1 client-one.net.home client-one" >> /etc/hosts
echo "" >> /etc/hosts
echo "# The following lines are desirable for IPv6 capable hosts" >> /etc/hosts
echo "ff02::1 ip6-allnodes" >> /etc/hosts
echo "ff02::2 ip6-allrouters" >> /etc/hosts

echo "---> Enabling multilib repo..."
echo
cp /etc/pacman.conf /etc/pacman.conf.backup
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

echo "---> Installing basic packages..."
echo
pacman -Syy
pacman -S --noconfirm acpi acpi_call acpid avahi bash-completion cups dialog dnsutils git grub inetutils linux-lts-headers networkmanager network-manager-applet net-tools ntfs-3g openssh wget xdg-user-dirs xdg-utils
pacman -S --noconfirm alsa-utils pipewire pipewire-alsa pipewire-jack pipewire-pulse gst-plugin-pipewire libpulse wireplumber sof-firmware bluez bluez-utils
pacman -S --noconfirm mesa xf86-video-amdgpu xf86-video-ati libva-mesa-driver vulkan-radeon

echo "---> Creating users..."
echo
useradd -m -G wheel wizzy
usermod --password $(echo password | openssl passwd -1 -stdin) wizzy
usermod --password $(echo password | openssl passwd -1 -stdin) root
echo "##" > /etc/sudoers.d/users
echo "## User privilege specification" >> /etc/sudoers.d/users
echo "##" >> /etc/sudoers.d/users
echo "" >> /etc/sudoers.d/users
echo "## Uncomment to allow members of group wheel to execute any command" >> /etc/sudoers.d/users
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/users

echo "---> Setting AMD graphics..."
echo
echo "options amdgpu si_support=1" > /etc/modprobe.d/amdgpu.conf 
echo "options amdgpu cik_support=0" >> /etc/modprobe.d/amdgpu.conf 
echo "blacklist radeon" > /etc/modprobe.d/radeon.conf 
cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.backup
sed -i "/MODULES=()/c\MODULES=(amdgpu radeon)" /etc/mkinitcpio.conf
mkinitcpio -P

echo "---> Setting environmental variables..."
echo
echo "QT_STYLE_OVERRIDE=kvantum" >> /etc/environment

echo "---> Configuring GRUB..."
echo
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

echo "---> Setting swap file..."
echo
dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress
chmod 600 /swapfile
mkswap /swapfile
echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

echo "---> Installing extra packages..."
echo
pacman -S --noconfirm bzip2 bzip3 evolution evolution-data-server evolution-ews firefox flatpak gnome gnome-browser-connector gnome-firmware gnome-software gnome-packagekit gnome-themes-extra gnome-tweaks gvfs gvfs-smb gzip hunspell hunspell-en_us hunspell-el kvantum jre-openjdk keepassxc libreoffice-fresh libreoffice-fresh-el nautilus-image-converter nautilus-sendto nautilus-share networkmanager-openconnect openconnect nextcloud-client papirus-icon-theme qbittorrent remmina smplayer smplayer-skins smplayer-themes unrar unzip zip

echo "---> Enabling services..."
echo
systemctl enable acpid
systemctl enable avahi-daemon
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable fstrim.timer
systemctl enable gdm.service

echo
echo "---> Done!"
echo
echo "Please exit the chroot environment and REBOOT!!"

