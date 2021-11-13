#!/bin/sh
while read line
do
	src=`echo ${line% *} | tr -d ' '`
	dst=`echo ${line#* } | tr -d ' '`
	echo "Install from $src to $dst"
	# source is directory ?
	if [ -e "$dst" ]; then
		echo " - file already exists, save as .bkp"
		cp -arf $dst $dst.bkp
	fi
	# copy file or directory
	if [ -d "$src" ]; then
		echo " - copy directory"
		# clean dst directory, that right stay with us
		if [ ! -d "$dst" ]; then
			mkdir $dst
			chmod 775 $dst
		fi
		cp -arf $src/* $dst
	elif [ -f "$src" ];then 
		echo " - coping file"
		cp -arf $src $dst
	else
		echo " - source not exists"
	fi
done < $1
