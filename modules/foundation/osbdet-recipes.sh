#!/bin/bash
printf "Displaying the recipes available in this course environment.\n"
su root -c "cd /root/osbdet; ./osbdet_builder.sh recipes"
