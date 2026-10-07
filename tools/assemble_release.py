#!/usr/bin/env python3
"""Require both platform manifests to match the immutable release checkout."""
import json,hashlib,pathlib,subprocess,os
root=pathlib.Path('release-upload');root.mkdir(exist_ok=True)
sha=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()
version=pathlib.Path('RELEASE_VERSION').read_text().strip()
assert os.environ['GITHUB_REF_NAME']==version,'tag/version mismatch'
platforms=[]
for platform in ['ios','windows']:
    candidates=list(pathlib.Path('release-artifacts').rglob('RELEASE_MANIFEST-'+platform+'.json'))
    assert len(candidates)==1,'one platform manifest required'
    m=json.loads(candidates[0].read_text())
    assert m['source_commit']==sha and m['version']==version,'artifact was built from another source/version'
    archives=list(pathlib.Path('release-artifacts').rglob(m['artifact']));assert len(archives)==1
    b=archives[0].read_bytes();assert len(b)==m['size_bytes'] and hashlib.sha256(b).hexdigest()==m['sha256']
    (root/m['artifact']).write_bytes(b);platforms.append(m)
(root/'RELEASE_MANIFEST.json').write_text(json.dumps({'version':version,'source_repository':'jankendo/-gem-survivor-crystal-field-v3','source_commit':sha,'platforms':platforms},indent=2)+'\n')
(root/'SHA256SUMS.txt').write_text(''.join(m['sha256']+'  '+m['artifact']+'\n' for m in platforms))
(root/'IOS_UNSIGNED_README.md').write_bytes(pathlib.Path('IOS_UNSIGNED_README.md').read_bytes())
print(json.dumps({'ok':True,'version':version,'source_commit':sha}))
