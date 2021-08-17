sudo rclone sync /twiodata/backups b2:twio-data-backup
sudo rclone cleanup b2:twio-data-backup
sudo echo "Successfully uploaded: $(hostname)-$(date -Iseconds | cut -d '+' -f 1)" >> /var/log/backup.log

