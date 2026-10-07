#!/usr/bin/env python3
"""Validate actual release archives. Does not claim installability or signatures."""
import argparse,zipfile,plistlib,hashlib,pathlib,struct,subprocess,tempfile,json
p=argparse.ArgumentParser();p.add_argument('kind',choices=['ios','windows']);p.add_argument('archive');args=p.parse_args()
archive=pathlib.Path(args.archive)
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None,'ZIP corruption'
 names=z.namelist()
 if args.kind=='windows':
  exe=next(n for n in names if n.endswith('GemSurvivorCrystalFieldV3.exe'))
  b=z.read(exe);assert b[:2]==b'MZ'
  offset=struct.unpack_from('<I',b,0x3c)[0]
  assert b[offset:offset+4]==b'PE\0\0' and struct.unpack_from('<H',b,offset+4)[0]==0x8664
  assert any(n.endswith('README.md') for n in names)
  assert any(n.endswith('.pck') for n in names) or b'GDPC' in b,'PCK missing'
 else:
  apps={n.split('/')[1] for n in names if n.startswith('Payload/') and len(n.split('/'))>2 and n.split('/')[1].endswith('.app')}
  assert len(apps)==1,'exactly one main app required'
  app=next(iter(apps));assert app=='Gem Survivor Crystal Field v3.app'
  prefix='Payload/'+app+'/'
  plist=plistlib.loads(z.read(prefix+'Info.plist'))
  assert plist['CFBundleIdentifier']=='com.jankendo14.gemsurvivor'
  assert plist.get('CFBundleDisplayName',plist.get('CFBundleName'))=='Gem Survivor Crystal Field v3'
  assert plist['CFBundleShortVersionString']=='3.0.0'
  assert plist['CFBundleVersion']=='30002','unexpected current app build'
  executable=prefix+plist['CFBundleExecutable'];assert executable in names
  b=z.read(executable)
  # Mach-O thin arm64 or universal header containing arm64.
  arm64=False
  if b[:4]==b'\xcf\xfa\xed\xfe': arm64=struct.unpack_from('<I',b,4)[0]==0x100000c
  elif b[:4] in [b'\xca\xfe\xba\xbe',b'\xca\xfe\xba\xbf']:
   n=struct.unpack_from('>I',b,4)[0];stride=32 if b[:4]==b'\xca\xfe\xba\xbf' else 20
   arm64=any(struct.unpack_from('>I',b,8+i*stride)[0]==0x100000c for i in range(n))
  assert arm64,'arm64 executable missing'
  assert any(n.startswith(prefix) and n.endswith('.pck') for n in names)
  assert prefix+'Assets.car' in names
  assert any(n.startswith(prefix) and ('launch' in n.lower()) and ('storyboard' in n.lower() or 'screen' in n.lower()) for n in names)
  assert any(n.startswith(prefix) and 'icon' in n.lower() and n.endswith('.png') for n in names),'required icon assets'
  assert prefix+'embedded.mobileprovision' not in names
  assert not any(n.startswith(prefix+'_CodeSignature/') for n in names),'distribution signature unexpected'
  icons=plist.get('CFBundleIcons',{}).get('CFBundlePrimaryIcon',{})
  assert icons.get('CFBundleIconName') or icons.get('CFBundleIconFiles'),'icon declaration absent'
sha=hashlib.sha256(archive.read_bytes()).hexdigest()
filename='SHA256SUMS-iOS.txt' if args.kind=='ios' else 'SHA256SUMS-Windows.txt'
(archive.parent/filename).write_text(sha+'  '+archive.name+'\n')
print(json.dumps({'ok':True,'kind':args.kind,'archive':archive.name,'sha256':sha}))
