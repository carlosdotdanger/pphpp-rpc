#!/usr/bin/python
import msgpackrpc

client = msgpackrpc.Client(msgpackrpc.Address("127.0.0.1", 5555))
print "small potatoes"
#for x in range(0,1000):
#	result = client.call('reverse_and_multiply','yarblesesy',100)
#	print x,len(result),'\n----'
for x in range(0,1000):
	result = client.call('echo_any',[x,'yarblesesy',100,0,30000,0,"yunnly",0,{"derp":0},"heerrrrrng",0])
result = client.call('echo_any',0)
print result
result = client.call('echo_any',None)
print result
result = client.call('echo_any',{'derp':[{'herp':0,34:29},"fllllojajkn"]})
print result
