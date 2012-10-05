#!/usr/bin/python
import msgpackrpc

client = msgpackrpc.Client(msgpackrpc.Address("192.168.187.128", 5555))
for x in range(0,10):
	result = client.call('doit', "yarble",x)
	print x,"\n",result
