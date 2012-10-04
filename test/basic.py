#!/usr/bin/python
import msgpackrpc

client = msgpackrpc.Client(msgpackrpc.Address("localhost", 5555))
for x in range(0,10000):
	result = client.call('big',"herpaderp",x)
	#result = client.call('breakme',x)
	#client.notify('hello1',x)
	#print "%d: %d" % (x,len(result))


