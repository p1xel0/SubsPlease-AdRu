#!/bin/bash
PATH=$PATH:~/bin
if pidof -x "$(basename "$0")" -o $$ > /dev/null; then
	exit 0
fi
command -v aria2c &> /dev/null || { echo 'error: aria2c is not installed' 1>&2; exit 1; }
command -v rclone &> /dev/null || { echo 'error: rclone is not installed' 1>&2; exit 1; }
mkdir -p ~/HorribleSubs
cd ~/HorribleSubs || { echo 'error: failed to cd ~/HorribleSubs/' 1>&2; exit 1; }
aria2c -q --remove-control-file=true --allow-overwrite=true 'http://www.horriblesubs.info/rss.php?res=1080' -o .rss.txt || { echo 'error: failed to retrieve RSS' 1>&2; exit 1; }
grep -q "<title>HorribleSubs RSS</title>" .rss.txt || { rm .rss.txt; echo 'error: downloaded data was not HS RSS' 1>&2; exit 1; }
sed -i 's/<link>/\n&/g;s/\&amp\;/\&/g' .rss.txt
sed -n -i 's:.*<link>\(.*\)</link>.*:\1:p' .rss.txt
sed -i -e "/http\:\/\/www\.horriblesubs\.info/d;\$a\\" .rss.txt
if [ -f ./.rss.old ]; then
	if [ -n "$(diff -q .rss.txt .rss.old)" ]; then
		grep -Fxv -f .rss.old .rss.txt > rss.txt
		aria2c -V --seed-time=0 -i rss.txt
		mv .rss.txt .rss.old && rm rss.txt
	else
		rm .rss.txt
	fi
else
	mv .rss.txt rss.txt
	aria2c -V --seed-time=0 -i rss.txt
	mv rss.txt .rss.old
fi
if [ -n "$(ls -d -- \[HorribleSubs\]\ *\ \(Batch\)/ 2> /dev/null)" ]; then
        for i in \[HorribleSubs\]\ *\ \(Batch\)/; do
		dir="$i"
		dir="${dir% (*}"
		dir="${dir% (*}"
		dir="${dir:15}"
		rclone copy "$i" drive:/HorribleSubs/"$dir"/ && rm -r "$i"
	done
fi
if [ -n "$(ls -- \[HorribleSubs\]\ *.mkv 2> /dev/null)" ]; then
	for i in \[HorribleSubs\]\ *.mkv; do
		dir="$i"
		dir="${dir% -*}"
		dir="${dir:15}"
		rclone copy "$i" drive:/HorribleSubs/"$dir"/ && rm "$i"
	done
fi
