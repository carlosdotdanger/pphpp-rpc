#!/usr/bin/python
import msgpackrpc

client = msgpackrpc.Client(msgpackrpc.Address("127.0.0.1", 5555))
for x in range(0,10):
	result = client.call('reverse_and_multiply','yarbles',x)
	print x,result,'\n----'

client.call('services')

#WOOOOOOO!
#generate errors in the the php script, get valid mspack err message
#from rpc server!
try:
	client.call('hang',2)
except msgpackrpc.error.RPCError as e:
	print "got exception:",e

try:
	client.call('exit_with',29)
except msgpackrpc.error.RPCError as e:
	print "got exception:",e

try:
	client.call('make_exception','pooooooooooooop!')
except msgpackrpc.error.RPCError as e:
	print "got exception:",e

try:
	client.call('exit_with',129)
except msgpackrpc.error.RPCError as e:
	print "got exception:",e