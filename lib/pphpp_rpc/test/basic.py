#!/usr/bin/python
import msgpackrpc

client = msgpackrpc.Client(msgpackrpc.Address("localhost", 5555))
for x in range(0,10):
	result = client.call('doit', "yarble",x)
	print x,"\n",result