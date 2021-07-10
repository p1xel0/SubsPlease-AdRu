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
aria2c -q --remove-control-file=true --allow-overwrite=true 'https://subsplease.org/rss/?r=1080' -o .rss.txt || { echo 'error: failed to retrieve RSS' 1>&2; exit 1; }
grep -q "<title>SubsPlease RSS</title>" .rss.txt || { rm .rss.txt; echo 'error: downloaded data was not SP RSS' 1>&2; exit 1; }
sed -i 's/<link>/\n&/g;s/\&amp\;/\&/g' .rss.txt
sed -n -i 's:.*<link>\(.*\)</link>.*:\1:p' .rss.txt
sed -i -e "/https\:\/\/subsplease\.org/d;\$a\\" .rss.txt
if [ -f ./.rss.old ]; then
	if [ -n "$(diff -q .rss.old .rss.txt)" ]; then
		diff ./.rss.old ./.rss.txt | grep \> | sed 's/^..//' > rss.txt
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
if [ -n "$(ls -- \[SubsPlease\]\ */ 2> /dev/null)" ]; then
	mv ./\[SubsPlease\]\ */* .
	rmdir ./\[SubsPlease\]\ */
fi
if [ -n "$(ls -- \[SubsPlease\]\ *.mkv 2> /dev/null)" ]; then
	for i in \[SubsPlease\]\ *.mkv; do
		dir="$(anititle "$i")"
		rclone copy "$i" drive:/HorribleSubs/"$dir"/ && rm "$i"
	done
fi
