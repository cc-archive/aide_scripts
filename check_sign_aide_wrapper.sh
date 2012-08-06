#!/bin/bash

COMMAND=$(echo $SSH_ORIGINAL_COMMAND | cut -d' ' -f1)
if [ $COMMAND = "rsync" ]; then
	ACTION=$(echo $SSH_ORIGINAL_COMMAND | cut -d' ' -f6)
else
	ACTION=$COMMAND
fi

case "$ACTION" in
	fetch-db)
		exec rsync --server --sender -az . /var/lib/aide/aide.db 
		;;
	fetch-bin)
		exec rsync --server --sender -az . /usr/bin/aide
		;;
	fetch-cron)
		exec rsync --server --sender -az . /etc/cron.daily/aide
		;;
	fetch-conf)
		exec rsync --server --sender -az . /etc/default/aide
		;;
	copy-db)
		cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
		;;
	*)
		echo "FAIL! FAIL! FAIL!"
esac
