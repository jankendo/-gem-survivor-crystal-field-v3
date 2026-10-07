#!/usr/bin/env python3
"""Require successful main CI at the immutable release SHA; never print credentials."""
import json,os,subprocess,sys
sha=sys.argv[1]
repo=os.environ['GITHUB_REPOSITORY']
def api(path):
 return json.loads(subprocess.check_output(['gh','api',path],text=True,encoding='utf-8'))
assert api('repos/'+repo+'/git/ref/heads/main')['object']['sha']==sha,'release SHA is not current main'
runs=api('repos/'+repo+'/actions/runs?head_sha='+sha+'&per_page=100')['workflow_runs']
required=['Fast CI','Balance','Performance','Build Windows and iOS Release']
for name in required:
 candidates=[r for r in runs if r['name']==name and r['head_branch']=='main' and r['event']=='push' and str(r['id'])!=os.environ.get('GITHUB_RUN_ID','')]
 assert candidates,'missing required main workflow: '+name
 latest=max(candidates,key=lambda r:r['id'])
 assert latest['status']=='completed' and latest['conclusion']=='success','required workflow not green: '+name
 print(name+': PASS run '+str(latest['id']))
