#!/data/data/com.termux/files/usr/bin/bash
echo "starting installation"
folder=debian-fs
if [ -d "$folder" ]; then
	first=1
	echo "rootfs found. skipping download"
fi
tarball="debian-rootfs.tar.xz"
if [ "$first" != 1 ]; then
	if [ ! -f $tarball ]; then
		echo "downloading rootfs"
		case $(dpkg --print-architecture) in
		aarch64)
			archurl="arm64"
			;;
		arm)
			archurl="armhf"
			;;
		amd64)
			archurl="amd64"
			;;
		x86_64)
			archurl="amd64"
			;;
		i*86)
			archurl="i386"
			;;
		x86)
			archurl="i386"
			;;
		*)
			echo "unknown architecture or architecture not supported. exiting with error code 1"
			exit 1
			;;
		esac
		wget "https://raw.githubusercontent.com/AKPR2007/AarLinux/main/rootfs/debian/debian-rootfs-${archurl}.tar.xz" -O $tarball
	fi
	cur=$(pwd)
	mkdir -p "$folder"
	cd "$folder"
	echo "decompressing rootfs"
	proot --link2symlink tar -xJf ${cur}/${tarball} || :
	cd "$cur"
fi
mkdir -p debian-binds
bin=start-debian.sh
echo "writing launch script"
cat >$bin <<-EOM
	#!/bin/bash
	cd \$(dirname \$0)
	## unset LD_PRELOAD in case termux-exec is installed
	unset LD_PRELOAD
	command="proot"
	command+=" --link2symlink"
	command+=" -0"
	command+=" -r $folder"
	if [ -n "\$(ls -A debian-binds)" ]; then
	    for f in debian-binds/* ;do
	      . \$f
	    done
	fi
	command+=" -b /dev"
	command+=" -b /proc"
	command+=" -b debian-fs/root:/dev/shm"
	## uncomment the following line to have access to the home directory of termux
	#command+=" -b /data/data/com.termux/files/home:/root"
	## uncomment the following line to mount /sdcard directly to / 
	#command+=" -b /sdcard"
	command+=" -w /root"
	command+=" /usr/bin/env -i"
	command+=" HOME=/root"
	command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
	command+=" TERM=\$TERM"
	command+=" LANG=C.UTF-8"
	command+=" /bin/bash --login"
	com="\$@"
	if [ -z "\$1" ];then
	    exec \$command
	else
	    \$command -c "\$com"
	fi
EOM

echo "finishing installation"
termux-fix-shebang $bin
chmod +x $bin
rm $tarball
echo "You can now launch Debian with the ./${bin} script"
