#!/bin/sh
export LANG=C
cat /etc/munin/munin.conf | grep address | while read a b; do echo $b; done > nodes
./munin-check.pl nodes
