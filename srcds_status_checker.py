#!/usr/bin/env python
import socket,ConfigParser,sys,thread,time,datetime,os

if len(sys.argv) == 1:
 sys.exit("Usage: python "+sys.argv[0]+" 'IP' PORT 'EXEC_CMD'")

def server_moninoring(ip,port,exec_cmd):
 print "[--------- Monitoring server "+ip+":"+port+" started"
 retry = 0
 while 1:
  sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  sock.connect((ip, int(port)))
  sock.send('\377\377\377\377TSource Engine Query\0')
  print "[--------- Send [OK] to "+ip+":"+port+" waiting response for 120 sec...."
  sock.settimeout(120)
  try:
   text=sock.recv(1024)
  except Exception, e:
   print "[--------- Error:%s"%e + " on server ip "+ip+":"+port
   retry = retry + 1
   print "RETRY: " + str(retry)
   if retry > 4:
    print "[--------- Retry is more than 5, send restart shell cmd to system!"
    print exec_cmd
    os.system(exec_cmd)
    retry = 0
   time.sleep(60)
   pass
  else:
   if (text.find('tf') > 1) or (text.find('cstrike') > 1) or (text.find('csgo') > 1) or (text.find('hl2mp') > 1):
    print "[--------- Response [OK] from "+ip+":"+port+" next retry to request is 120 sec."
    retry = 0
   time.sleep(120)

print "[--------- Loading server..."
ip = sys.argv[1]
port = sys.argv[2]
exec_cmd = sys.argv[3]
print "[--------- Server "+ip+":"+port+" successfully loaded"
print "\n"
thread.start_new_thread(server_moninoring, (ip,port,exec_cmd))
while 1:
 time.sleep(60)
