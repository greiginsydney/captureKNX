#!/usr/bin/env python3

# Pasted by Greig from here:
# https://community.influxdata.com/t/having-a-stream-input-with-telegraf/2360/7
# Logging component from here: https://trstringer.com/systemd-logging-in-python/

import serial, socket
import time, signal, sys

#==================
# Constants
#==================

serial_port = 'ttyKNX1'
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
print("Create TCP connection to: {}".format(server_addr))
while True:
    try:
        tcp.connect(server_addr)
    except:
        time.sleep(5)
    else: # connection established successfully
        break
print("  ... connection established")

#==================
# Serial - setup
#==================
print("Try to open serial port: " + serial_port)
ser.port = serial_port
while not ser.is_open:
    try:
        ser.open()
    except:
        time.sleep(5)
print("  ... opened successfully")

#==================
# "Main" loop - shovel data from Serial to TCP Socket
#==================
while True:
    try:
        line = ser.readline()
        tcp.sendall(line)
    except:
        print("Encountered Serial or TCP error ... exiting now")
        clean_up_and_exit(1)
