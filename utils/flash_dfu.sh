#!/bin/sh 
set -e
#
# Script to flash Arduino 101 firmware via USB and dfu-util
#
util_dir=$(dirname $(readlink -f $0))
PID=8087:0aba
DFU="$util_dir/bin/dfu-util -d,$PID"

help() {
  echo "Usage: $0 -a arc_binary -x x86_binary"
  exit 1
}

trap_to_dfu() {
  # If trapped.bin already exists, clean up before starting the loop
  [ -f "trapped.bin" ] && rm -f "trapped.bin"

  # Loop to read from 101 so that it stays on DFU mode afterwards
  until $DFU -a 4 -U trapped.bin > /dev/null 2>&1
  do
    sleep 0.1
  done
}

flash() {
  echo "

"
  # if ARC binary not defined, reset device after x86 download
  [ -z "$arc_bin" ] && reset_flag=-R
  # flash Quark binary if supplied
  [ -n "$x86_bin" ] && $DFU -a 2 $reset_flag -D $x86_bin
  # flash Quark binary if supplied
  [ -n "$arc_bin" ] && $DFU -a 7 -R -D $arc_bin
}

# Parse command args
if [ $# -lt 2 ]; then
  help
fi

while [ $# -ge 1 ]; do
  arg="$1"
  case $arg in
    -a)
      arc_bin=$2
      shift
      ;;
    -x)
      x86_bin=$2
      shift # past argument
      ;;
    *)
      help # unknown option
      ;;
  esac
  shift # past argument or value
done


echo "*** Reset the board to begin download..."
trap_to_dfu

flash

if [ $? -ne 0 ]; then
  echo
  echo "***ERROR***"
  exit 1
else
  echo
  echo "!!!SUCCESS!!!"
  exit 0
fi

