#!/bin/bash
printf "This script is going to synchronize the contents of the course environment with the latests changes.\n"
su root -c "cd /root/osbdet; printf '  Catching up with the main repository ... '; git pull > /dev/null"
printf "[Done]\n"
