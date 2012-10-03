#!/usr/bin/python
import msgpackrpc

client = msgpackrpc.Client(msgpackrpc.Address("localhost", 5555))
for x in range(0,1):
	result = client.call('sum', 1, 2, 3 ,"dogbutt",["thingy","derp" * x],x)
	#print result
