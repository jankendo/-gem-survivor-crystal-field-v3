#!/usr/bin/env python3
"""Bind checked-out source, release version and independently hashed binary bytes."""
import argparse,hashlib,json,pathlib,re,subprocess,os

def manifest(platform,archive,sha,version,repo):
    assert re.fullmatch(r'[0-9a-f]{40}',sha),'invalid source SHA'
    assert re.fullmatch(r'v\d+\.\d+\.\d+-alpha\.\d+',version),'unsupported preview version'
    assert repo=='jankendo/-gem-survivor-crystal-field-v3','unexpected repository'
    archive=pathlib.Path(archive)
    expected='GemSurvivorCrystalField-v3-unsigned.ipa' if platform=='ios' else 'GemSurvivorCrystalField-v3-Windows.zip'
    assert archive.name==expected and archive.stat().st_size>0,'missing or wrong artifact'
    return {'version':version,'app_version':'3.0.0','app_build':'30002' if platform=='ios' else '3.0.0.2','source_repository':repo,'source_commit':sha,'platform':platform,'signing':'unsigned' if platform=='ios' else 'not-code-signed','architecture':'arm64' if platform=='ios' else 'x86_64','configuration':'Release','artifact':archive.name,'size_bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'workflow_run_id':os.environ.get('GITHUB_RUN_ID','local')}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('platform',choices=['ios','windows']);p.add_argument('archive');p.add_argument('output');a=p.parse_args()
    sha=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()
    assert os.environ.get('GITHUB_SHA',sha)==sha,'workflow SHA differs from checkout'
    obj=manifest(a.platform,a.archive,sha,pathlib.Path('RELEASE_VERSION').read_text().strip(),os.environ.get('GITHUB_REPOSITORY','jankendo/-gem-survivor-crystal-field-v3'))
    pathlib.Path(a.output).write_text(json.dumps(obj,indent=2)+'\n');print(json.dumps(obj))
