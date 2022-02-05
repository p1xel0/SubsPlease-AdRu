#!/bin/bash
PATH=$PATH:~/bin
if pidof -x "$(basename "$0")" -o $$ > /dev/null; then
	exit 0
fi
command -v aria2c &> /dev/null || { echo 'error: aria2c is not installed' 1>&2; exit 1; }
command -v rclone &> /dev/null || { echo 'error: rclone is not installed' 1>&2; exit 1; }
command -v anititle &> /dev/null || { echo 'error: anititle is not installed' 1>&2; exit 1; }
mkdir -p ~/HorribleSubs
cd ~/HorribleSubs || { echo 'error: failed to cd ~/HorribleSubs/' 1>&2; exit 1; }
aria2c -q --remove-control-file=true --allow-overwrite=true 'https://nyaa.si/?page=rss&u=subsplease' -o .rss.txt || { echo 'error: failed to retrieve RSS' 1>&2; exit 1; }
sed -n '/<title>.*\(1080p\).*<\/title>/{n;p}' -i .rss.txt
sed -n 's:.*<link>\(.*\)</link>.*:\1:p' -i .rss.txt
grep -q ^https.*torrent$ .rss.txt || { rm .rss.txt; echo 'error: downloaded data was not SP RSS' 1>&2; exit 1; }
if [ -f ./.rss.old ]; then
	if [ -n "$(diff -q .rss.old .rss.txt)" ]; then
		diff ./.rss.old ./.rss.txt | grep \> | sed 's/^..//' > rss.txt
		aria2c -V --seed-time=0 --follow-torrent=mem -i rss.txt
		mv .rss.txt .rss.old && rm rss.txt
	else
		rm .rss.txt
	fi
else
	mv .rss.txt rss.txt
	aria2c -V --seed-time=0 --follow-torrent=mem -i rss.txt
	mv rss.txt .rss.old
fi
if [ -n "$(ls -- \[SubsPlease\]\ */ 2> /dev/null)" ]; then
	for i in \[SubsPlease\]\ */; do
		dir="$(anititle "$i")"
		if [ -n "$(rclone lsf drive:/HorribleSubs/"$dir")" ]; then
			mapfile -t local_files < <(find "$i" -type f -exec basename {} \; | sort)
			mapfile -t same_files < <(for ((s=0;s<"${#local_files[@]}";s++)); do if [ -n "$(rclone lsf drive:/HorribleSubs/"$dir"/"${local_files[$s]}" 2> /dev/null)" ]; then echo "${local_files[$s]}"; fi; done)
			mapfile -t rclone_files < <(rclone lsf drive:/HorribleSubs/"$dir"/)
			if [ ! "${#same_files[@]}" -eq 0 ]; then
				for f in "${same_files[@]}"; do
					rm "$i"/"$f"	
				done
			fi
			if ! find "$i" -maxdepth 1 -type f | read; then
				rmdir "$i"
				continue
			fi
			mapfile -t new_files < <(find "$i" -type f -exec basename {} \; | sort | sed 's/v[2-9] .*//;s/\[/\\[/g')
			mapfile -t old_files < <(for ((o=0;o<"${#rclone_files[@]}";o++)); do echo "${rclone_files[$o]}" | grep -o ^"${new_files[$o]}"\ .*$; done)
			for o in "${old_files[@]}"; do
				rclone deletefile drive:/HorribleSubs/"$dir"/"$o"
			done
		fi	
		rclone copy "$i" drive:/HorribleSubs/"$dir"/ && rm -r "$i"
	done
fi
if [ -n "$(ls -- \[SubsPlease\]\ *.mkv 2> /dev/null)" ]; then
	for i in \[SubsPlease\]\ *.mkv; do
		dir="$(anititle "$i")"
		rclone copy "$i" drive:/HorribleSubs/"$dir"/ && rm "$i"	
	done
fi
