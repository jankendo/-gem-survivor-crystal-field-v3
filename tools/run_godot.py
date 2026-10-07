#!/usr/bin/env python3
"""Fail immediately on engine diagnostics, even when Godot would exit zero."""
import os,subprocess,sys,re,threading
engine_args=sys.argv[1:]
watchdog_seconds=600
if engine_args[:1]==['--timeout-seconds']:
 watchdog_seconds=int(engine_args[1]);assert 1<=watchdog_seconds<=3600
 engine_args=engine_args[2:]
p=subprocess.Popen([os.environ.get('GODOT','godot'),*engine_args],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding="utf-8",errors="replace",bufsize=1)
expired=False
def timeout():
 global expired
 expired=True
 p.terminate()
watchdog=threading.Timer(watchdog_seconds,timeout);watchdog.start()
bad=False
for line in p.stdout:
 print(line,end='',flush=True)
 if re.search(r'(SCRIPT ERROR:|ERROR:|Parse Error:|Compile Error:)',line):
  bad=True;p.terminate();break
try: code=p.wait(timeout=10)
except subprocess.TimeoutExpired:p.kill();code=p.wait()
watchdog.cancel()
sys.exit(1 if bad or expired else code)
