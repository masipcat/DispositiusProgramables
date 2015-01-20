import serial, sys
import time
import platform
import threading

class Bridge(object):

	val = False
	ser = None
	com = None

	def __nonzero__(self):
		return self.val

bridge = Bridge()

def run():
	print "[Thread start]"
	try:
		if platform.system() == "Windows":
			bridge.ser = serial.Serial(bridge.com) # COM3
		else:
			bridge.ser = serial.Serial("/dev/tty.usbmodem411")

		anterior = time.time()

		received = []
		
		while True:
			i = bridge.ser.read()
			
			if i == "":
				return
				
			if (time.time() - anterior) > 1:
				print "---"
			print "[%i] %.2fs: %s (ascii %i)" % (time.time(), time.time() - anterior, i, ord(i))
			anterior = time.time()
	except Exception as e:
		print e
	finally:
		#if bridge.ser:
		#	bridge.ser.close()

		print "[Thread killed]"

try:

	bridge.com = input("COM: ")-1

	while(not bridge):
		threading.Thread(target=run).start()
		time.sleep(0.5)
		raw_input("Close...\n")
		bridge.ser.close()
		time.sleep(.5)
		raw_input("Open new...\n")
finally:
	bridge.ser.close()