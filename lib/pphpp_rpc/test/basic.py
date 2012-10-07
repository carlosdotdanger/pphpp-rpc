#!/usr/bin/python
import msgpackrpc

client = msgpackrpc.Client(msgpackrpc.Address("127.0.0.1", 5555))
print "small potatoes"
for x in range(0,10):
	result = client.call('reverse_and_multiply','yarbles',x)
	print x,result,'\n----'


#big input
print "10k input"
try:
	result = client.call('hello','y' * 10000)
	print "large input result:",len(result)
except msgpackrpc.error.RPCError as e:
	print "got exception:",e 

print "16k input"
try:
	result = client.call('hello','y' * 16000)
	print "large input result:",len(result)
except msgpackrpc.error.RPCError as e:
	print "got exception:",e 

print "17k input"
try:
	result = client.call('hello','y' * 17000)
	print "large input result:",len(result)
except msgpackrpc.error.RPCError as e:
	print "got exception:",e 

print "20k input"
try:
	result = client.call('hello','y' * 20000)
	print "large input result:",len(result)
except msgpackrpc.error.RPCError as e:
	print "got exception:",e 

print "70k input"
try:
	result = client.call('hello','y' * 70000)
	print "large input result:",len(result)
except msgpackrpc.error.RPCError as e:
	print "got exception:",e 

#big output
print "700k output"
try:
	result = client.call('reverse_and_multiply','yarbles',100000)
	print "large output result length:",len(result)
except msgpackrpc.error.RPCError as e:
	print "got exception:",e 


print "1.4 meg output"
try:
	result = client.call('reverse_and_multiply','yarbles' ,200000)
	print "large output result length:",len(result)
except msgpackrpc.error.RPCError as e:
	print "got exception:",e 

print "SERVICES\n----------"
services = client.call('services')
for service in services:
	print service
	for item in service:
		print "\t",item

#WOOOOOOO!
#generate errors in the the php script, get valid mspack err message
#from rpc server!


print "GENERATING ERRORS"

print "hang process - 2 millis"
try:
	result = client.call('hang',2000)
	print result
except msgpackrpc.error.RPCError as e:
	print "got exception:",e

print "hang process - 900 millis"
try:
	result = client.call('hang',900000)
	print result
except msgpackrpc.error.RPCError as e:
	print "got exception:",e

print "hang process - 2 seconds"
try:
	result = client.call('hang',2000000)
	print result
except msgpackrpc.error.RPCError as e:
	print "got exception:",e

print "abnormal exit (29)"
try:
	result = client.call('exit_with',29)
	print result
except msgpackrpc.error.RPCError as e:
	print "got exception:",e

print "unhandled php exception"
try:
	result = client.call('make_exception','pooooooooooooop!')
	print result
except msgpackrpc.error.RPCError as e:
	print "got exception:\n----------------\n",e,"\n----------------"

print "another abnormal exit (129)"
try:
	result = client.call('exit_with',129)
	print result
except msgpackrpc.error.RPCError as e:
	print "got exception:",e


