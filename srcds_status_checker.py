#!/usr/bin/env python
import socket,sys,thread,time,datetime,os

if len(sys.argv) == 1:
 sys.exit("Usage: python "+sys.argv[0]+" 'IP' PORT 'EXEC_CMD'")

def server_moninoring(ip,port,exec_cmd):
 print "[--------- Monitoring server "+ip+":"+port+" started"
 retry = 0
 while 1:
  sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  sock.connect((ip, int(port)))
  sock.send('\377\377\377\377TSource Engine Query\0')
  date = datetime.datetime.now()
  print "[--------- "+date.strftime("%Y-%m-%d %H:%M")+" Send [OK] to "+ip+":"+port+" waiting response for 90 sec...."
  sock.settimeout(90)
  try:
   text=sock.recv(1024)
  except Exception, e:
   date = datetime.datetime.now()
   print "[--------- "+date.strftime("%Y-%m-%d %H:%M")+" Error:%s"%e + " on server ip "+ip+":"+port
   retry = retry + 1
   print "RETRY: " + str(retry)
   if retry > 4:
    date = datetime.datetime.now()
    print "[--------- "+date.strftime("%Y-%m-%d %H:%M")+" Retry is more than "+str(retry)+", send restart shell cmd to system!"
    print exec_cmd
    os.system(exec_cmd)
    retry = 0
   time.sleep(45)
   pass
  else:
   if (text.find('tf') > 1) or (text.find('cstrike') > 1) or (text.find('csgo') > 1) or (text.find('hl2mp') > 1):
    date = datetime.datetime.now()
    print "[--------- "+date.strftime("%Y-%m-%d %H:%M")+" Response [OK] from "+ip+":"+port+" next retry to request is 90 sec."
    retry = 0
   time.sleep(90)

print "[--------- Loading server..."
ip = sys.argv[1]
port = sys.argv[2]
exec_cmd = sys.argv[3]
date = datetime.datetime.now()
print "[--------- "+date.strftime("%Y-%m-%d %H:%M")+"  Server "+ip+":"+port+" successfully loaded"
print "\n"
thread.start_new_thread(server_moninoring, (ip,port,exec_cmd))
while 1:
 time.sleep(45)
