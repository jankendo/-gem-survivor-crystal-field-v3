#!/usr/bin/env python3
"""Opt-in authenticated live upload probe, strictly inside an unpublished draft."""
import argparse,hashlib,json,pathlib,subprocess,tempfile,os
from publish_release import upload_asset
REPO='jankendo/-gem-survivor-crystal-field-v3'
parser=argparse.ArgumentParser();parser.add_argument('draft_id',type=int);args=parser.parse_args()
endpoint='repos/'+REPO+'/releases/'+str(args.draft_id)
def api(path,*options):
 result=subprocess.run(['gh','api',path,*options],capture_output=True,text=True)
 assert result.returncode==0,'live protocol API request failed'
 return json.loads(result.stdout) if result.stdout.strip() else None
release=api(endpoint);assert release['draft'],'probe refuses a public release'
asset=None
try:
 with tempfile.TemporaryDirectory() as folder:
  path=pathlib.Path(folder)/('ReleaseUploadProbe-'+os.environ.get('GITHUB_RUN_ID','local')+'.txt')
  path.write_bytes(b'Release transport probe; no gameplay/user data.\n')
  asset=upload_asset(release,path)
  assert asset['digest']=='sha256:'+hashlib.sha256(path.read_bytes()).hexdigest()
  inspected=api(endpoint);assert inspected['draft']
  assert any(a['id']==asset['id'] and a['digest']==asset['digest'] for a in inspected['assets'])
  print(json.dumps({'ok':True,'draft_id':release['id'],'bytes':asset['size'],'actual_upload_hash_matches':True,'publication_attempted':False}))
finally:
 if asset is not None:api('repos/'+REPO+'/releases/assets/'+str(asset['id']),'--method','DELETE')
assert api(endpoint)['draft']
