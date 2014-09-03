#!/usr/bin/env python
import serial, urllib, urllib2, time
print "Wireless Temperature Logger - PC Logging"

# Replace /dev/ttyACM0 with the name of the Arduino's port
ser = serial.Serial('/dev/ttyACM0', 9600)
url = 'http://localhost/updatelog.php'

print "Press UP arrow key on the Arduino, follow the onscreen setup, and press RIGHT"
print "arrow key to start logging."
print "When you are done logging, simply unplug the Arduino and this window will close."

while 1:
	line = ser.readline()
	ftemp = line[0:line.index('_')]
	print ftemp
	ctemp = line[line.index('_')+1:line.index('|')]
	print ctemp
	values = {'ftemp' : ftemp[0:len(ftemp)-1], 'ctemp' : ctemp[0:len(ctemp)-1],}
	try:
		data = urllib.urlencode(values)
		req = urllib2.Request(url, data)
		response = urllib2.urlopen(req)
		the_page = response.read()
		print the_page
	except Exception, detail:
		print "Err ", detail
