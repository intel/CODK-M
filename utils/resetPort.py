#!/usr/bin/python
# Script to reset Intel EDU board progra
import serial, sys, time

if len(sys.argv) == 2:
  serialPath = sys.argv[1]
else:
  sys.exit("Usage: %s port" % sys.argv[0])

print "Resetting " + serialPath

mySerial = serial.Serial(serialPath, 1200)

mySerial.setDTR(level=False)
mySerial.setDTR(level=True)
print "Reset Complete!"

