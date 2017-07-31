#!/usr/bin/env fish

luajit -O vandal.lua 2> err.txt
set -l st $status

clear
cat err.txt

exit $st

