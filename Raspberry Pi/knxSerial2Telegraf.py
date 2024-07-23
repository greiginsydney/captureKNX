#!/usr/bin/env python3

# Pasted by Greig from here:
# https://community.influxdata.com/t/having-a-stream-input-with-telegraf/2360/7
# Logging component from here: https://trstringer.com/systemd-logging-in-python/

import serial, socket
import time, signal, sys
import logging
from systemd.journal import JournaldLogHandler


#==================
# Setup logging
#==================

# get an instance of the logger object this module will use
log = logging.getLogger(__name__)

# instantiate the JournaldLogHandler to hook into systemd
journald_handler = JournaldLogHandler()

# set a formatter to include the level name
journald_handler.setFormatter(logging.Formatter(
    '[%(levelname)s] %(message)s'
))

# add the journald handler to the current logger
log.addHandler(journald_handler)

# optionally set the logging level
log.setLevel(logging.DEBUG)

#==================
# Constants
#==================

serial_port = 'TODO'
server_addr = ("localhost", 7654)

#==================
# Initilize objects
#==================

tcp = socket.socket()
ser = serial.Serial()

#==================
# Interrupt handler (SIGINT & SIGTERM)
#==================
def clean_up_and_exit(exit_code):
  tcp.close()
  ser.close()
  sys.exit(exit_code)

def handler_stop_signals(signum, frame):
  print("Signal handler called with signal {} ... exiting now".format(signum))
  clean_up_and_exit(2)

signal.signal(signal.SIGINT, handler_stop_signals)
signal.signal(signal.SIGTERM, handler_stop_signals)

#==================
# TCP Socket - setup
#==================
log.info("Create TCP connection to: {}".format(server_addr))
print("Create TCP connection to: {}".format(server_addr))
while True:
  try:
    tcp.connect(server_addr)
  except:
    time.sleep(5)
  else: # connection established successfully
    break
log.info("  ... connection established")
print("  ... connection established")

#==================
# Serial - setup
#==================
log.info("Try to open serial port: " + serial_port)
print("Try to open serial port: " + serial_port)
ser.port = serial_port
while not ser.is_open:
  try:
    ser.open()
  except:
    time.sleep(5)
log.info("  ... opened successfully")
print("  ... opened successfully")

#==================
# "Main" loop - shovel data from Serial to TCP Socket
#==================
while True:
  try:
    line = ser.readline()
    tcp.sendall(line)
  except:
    log.info("Encountered Serial or TCP error ... exiting now")
    print("Encountered Serial or TCP error ... exiting now")
    clean_up_and_exit(1)
