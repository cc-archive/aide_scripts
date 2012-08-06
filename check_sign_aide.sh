#!/bin/bash

if [ ! $1 ]; then
	echo "You must at least provide an argument for which action to take."
	exit
fi

ALL_SERVERS="\
	a5.creativecommons.org \
	a7.creativecommons.org \
	a8.creativecommons.org \
	a9.creativecommons.org \
	a10.creativecommons.org \
	backup.creativecommons.org \
	gandi0.creativecommons.org \
	nagios.creativecommons.org \
	open4us.org \
	scraper.creativecommons.org \
"

# if a 2nd argument was passed then assume a list of servers was passed, else
# just perform the operation on all servers
if [ $2 ]; then
	SERVERS=${@:2}
else
	SERVERS=$ALL_SERVERS
fi

# File extension for each of the AIDE files we sign
AIDE_FILES="db bin cron conf"

# Public GPG key we'll use to sign the files
GPG_KEY="0x4AF04EE5"

export RSYNC_RSH="ssh -i /root/.ssh/id_rsa_aide"

# Fetch the AIDE files to be checked or signed
fetch_files () {
	for aide_file in $AIDE_FILES
	do
		rsync -az $1:fetch-$aide_file ./aide.$aide_file
	done
}

# Check the digital signatures of each AIDE file
check_sigs () {
	for aide_file in $AIDE_FILES
	do
		gpg --verify ./aide.$aide_file.sig &> /dev/null
		if [ $? -ne 0 ]; then
			echo "The signature of aide.${aide_file} for ${1} was bad!"
		fi
	done
}

# Create new digital signature for each AIDE file
sign_files () {
	for aide_file in $AIDE_FILES
	do
		gpg -u $GPG_KEY -sb --yes ./aide.$aide_file &> /dev/null
		if [ $? -ne 0 ]; then
			echo "Failed to sign aide.${aide_file} for ${1}!"
		fi
	done
}

# Copy the new AIDE database (aide.new.db) onto the old one (aide.db).  This is
# necessary when AIDE reports some files which have changed, and we want to
# acknowldge the changes, and not receive reports about these same changes day
# after day.
copy_db () {
	ssh -i /root/.ssh/id_rsa_aide $1 'copy-db'
}

for server in $SERVERS
do

	# This allows you to pass in a list of servers using only their
	# hostname and not the FQDN.  This just reduces typing if you have to
	# pass in a list of 4 or 5 servers.
	echo $server | grep -q '\.' || server="${server}.creativecommons.org"
	
	cd /root/aide_sigs/$server
	if [ $? -ne 0 ]; then
		echo "Failed to cd to aide_sigs/${server}!"
		exit
	fi

	case $1 in
		check)
			fetch_files $server
			check_sigs $server
			;;
		sign)
			fetch_files $server
			sign_files $server
			;;
		copydb)
			copy_db $server
			fetch_files $server
			sign_files $server
			;;
		*)
			echo "FAIL! FAIL! FAIL!"
	esac

done
