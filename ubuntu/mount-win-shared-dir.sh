##!/bin/sh
## sudo apt-get install cifs-utils

sudo mount -t cifs -o user=<win-user-name>//<host-name/ip>/<shared-dir> <mnt-dir>
