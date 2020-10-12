# SubsPlease-AdRu
Automated Downloader and Rclone Uploader for SubsPlease RSS Feed.
By default the script downloads from the 1080p feed and uploads to the rclone remote ```drive:```. The feed resolution can be altered by changing aria2c URL on line 10. The rclone destination remote can be altered by changing the rclone command on lines 34 and 42.

### Setup
The preferable way to use this script is under a cron job as it is non-interactive. An example cron entry would be as follows ```*/5 * * * * /path/to/AdRu.sh > /dev/null```. This entry runs every 5 minutes and pipes stdout to null as the script pipes errors to stderr as to not spam the user with cron mail for successful runs. The script also does not overlap and terminates if another instance is already running.
