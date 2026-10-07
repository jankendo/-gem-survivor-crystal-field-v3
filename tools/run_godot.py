#!/usr/bin/env python3
"""Fail immediately on engine diagnostics, even when Godot would exit zero."""
import os,subprocess,sys,re,threading
p=subprocess.Popen([os.environ.get('GODOT','godot'),*sys.argv[1:]],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,bufsize=1)
expired=False
def timeout():
 global expired
 expired=True
 p.terminate()
watchdog=threading.Timer(600,timeout);watchdog.start()
bad=False
for line in p.stdout:
 print(line,end='',flush=True)
 if re.search(r'(SCRIPT ERROR:|ERROR:|Parse Error:|Compile Error:)',line):
  bad=True;p.terminate();break
try: code=p.wait(timeout=10)
except subprocess.TimeoutExpired:p.kill();code=p.wait()
watchdog.cancel()
sys.exit(1 if bad or expired else code)
