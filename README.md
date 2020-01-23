# HorribleSubs-AdRu
Automated Downloader and Rclone Uploader for HorribleSubs RSS Feed.
By default the script downloads from the 1080p feed and uploads to the rclone remote 'drive:'

### Setup
The preferable way to use this script is under a cron job as it is non-interactive. An example cron entry would be as follows ```*/5 * * * * /path/to/AdRu.sh > /dev/null```. This entry runs every 5 minutes and pipes stdout to null as the script pipes errors to stderr as to not spam the user with cron mail for successful runs.
