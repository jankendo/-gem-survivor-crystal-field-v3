#!/usr/bin/env python3
"""Re-download public assets and verify main/tag/platform source and binary bytes."""
import argparse, hashlib, json, pathlib, plistlib, subprocess, zipfile

REPO = 'jankendo/-gem-survivor-crystal-field-v3'

def api(path):
    return json.loads(subprocess.check_output(['gh', 'api', 'repos/'+REPO+'/'+path], text=True))

def verify(tag, output):
    release = api('releases/tags/'+tag)
    assert not release['draft'] and release['prerelease'], 'public preview required'
    sha = api('git/ref/heads/main')['object']['sha']
    ref = api('git/ref/tags/'+tag)['object']
    while ref['type'] == 'tag':
        ref = api('git/tags/'+ref['sha'])['object']
    assert ref['type'] == 'commit' and ref['sha'] == sha, 'tag is not current main'
    output = pathlib.Path(output)
    output.mkdir(parents=True, exist_ok=True)
    required = ['GemSurvivorCrystalField-v3-unsigned.ipa',
                'GemSurvivorCrystalField-v3-Windows.zip', 'SHA256SUMS.txt',
                'RELEASE_MANIFEST.json', 'IOS_UNSIGNED_README.md']
    assets = {}
    for name in required:
        matches = [a for a in release['assets'] if a['name'] == name]
        assert len(matches) == 1, 'missing/duplicate asset: '+name
        asset = matches[0]
        dest = output/name
        result = subprocess.run(['curl', '-fLsS', '--retry', '3', '--max-time', '180',
                                 asset['browser_download_url'], '-o', str(dest)], capture_output=True)
        assert result.returncode == 0, 'public download failed: '+name
        digest = hashlib.sha256(dest.read_bytes()).hexdigest()
        assert dest.stat().st_size == asset['size'], 'download size differs: '+name
        assert asset['digest'] == 'sha256:'+digest, 'release digest differs: '+name
        assets[name] = {'url': asset['browser_download_url'], 'size_bytes': asset['size'], 'sha256': digest}
    manifest = json.loads((output/'RELEASE_MANIFEST.json').read_text())
    assert manifest['source_commit'] == sha and manifest['version'] == tag
    assert manifest['source_repository'] == REPO
    assert sorted(m['platform'] for m in manifest['platforms']) == ['ios', 'windows']
    sums = {}
    for line in (output/'SHA256SUMS.txt').read_text().splitlines():
        digest, name = line.split()
        sums[name] = digest
    for m in manifest['platforms']:
        assert m['source_commit'] == sha and m['version'] == tag
        assert m['sha256'] == assets[m['artifact']]['sha256'] == sums[m['artifact']]
        assert m['size_bytes'] == assets[m['artifact']]['size_bytes']
        subprocess.run(['python3', 'tools/validate_artifacts.py', m['platform'], str(output/m['artifact'])], check=True)
    ipa = output/'GemSurvivorCrystalField-v3-unsigned.ipa'
    with zipfile.ZipFile(ipa) as z:
        plist = plistlib.loads(z.read('Payload/Gem Survivor Crystal Field v3.app/Info.plist'))
    result = {'ok': True, 'version': tag, 'source_commit': sha, 'release_url': release['html_url'],
              'assets': assets, 'bundle_identifier': plist['CFBundleIdentifier'],
              'app_version': plist['CFBundleShortVersionString'], 'app_build': plist['CFBundleVersion'],
              'note': 'Public re-download and archive verification; not install/device/human play evidence.'}
    (output/'published-verification.json').write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('tag')
    parser.add_argument('output')
    args = parser.parse_args()
    verify(args.tag, args.output)
