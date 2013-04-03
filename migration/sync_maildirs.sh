#!/bin/bash

#
# Copyright (C) 2013 Nethesis S.r.l.
# http://www.nethesis.it - support@nethesis.it
# 
# This script is part of NethServer.
# 
# NethServer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License,
# or any later version.
# 
# NethServer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with NethServer.  If not, see <http://www.gnu.org/licenses/>.
#

#
# To make this script work, configure public key 
# authentication on sourceHost
#

export LANG=C
export DRYRUN=0
sourceHost=""
sourcePort=22

function exit_help()
{
    echo "Usage: 
    $0 [-h] [-n] [-p] -s IPADDR 
        -h          help message
        -n          dry run
        -p PORT     ssh port on source host (default 22)
        -s IPADDR   rsync from source host IPADDR

" 1>&2
    exit 1;
}

while getopts "hns:p:" opt; do
    case $opt in
	h)  # help
	    exit_help
	    ;;
	n)  # dry run
	    DRYRUN=1
	    ;;
	p)  # source port
	    sourcePort=${OPTARG}
	    ;;
	s)  # source IPADDR
	    sourceHost=${OPTARG}
	    ;;
	\?) 
	    exit_help
	    ;;
    esac
done

if [ -z ${sourceHost} ]; then
    echo "Missing -s IPADDR parameter!" 1>&2
    exit_help
fi

for USER in `/usr/bin/doveadm user \*`; do 
    echo "[INFO] `date` -- Synchronizing ${USER} Maildir/"
    destinationMaildir="/var/lib/nethserver/vmail/${USER}/Maildir/"

    if ! [ -d ${destinationMaildir} ]; then
	mkdir -p ${destinationMaildir} && \
	    echo "[WARNING] destination directory does not exist. Created ${USER}."
    fi
    
    # Synchronize maildir:
    /usr/bin/rsync `[ ${DRYRUN} -gt 0 ] && echo '-n -v'` -r -l -t \
	-e "ssh -p ${sourcePort} -l root" \
	"${sourceHost}:/home/e-smith/files/users/${USER}/Maildir/" \
	"${destinationMaildir}"
    
    if [ $? -ne 0 ]; then
	echo "[ERROR] rsync failed for ${USER}"
	continue
    fi

	# Fix permissions on destination maildir:
    if [ ${DRYRUN} -eq 0 ]; then 
	chown -R 'vmail.vmail' "${destinationMaildir}"
	chmod -R 'g-rwxXst,o=g' "${destinationMaildir}"
    fi
done

