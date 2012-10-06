#!/usr/bin/python
import msgpackrpc

client = msgpackrpc.Client(msgpackrpc.Address("127.0.0.1", 5555))
for x in range(0,100000):
	result = client.call('doit', " yarble !ybab",x)
	print x,len(result)
