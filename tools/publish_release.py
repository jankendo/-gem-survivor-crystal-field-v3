#!/usr/bin/env python3
"""Publish only a complete draft; never overwrite assets of a public release."""
import hashlib, json, os, pathlib, subprocess

def call(*args):
    return subprocess.run(['gh', *args], capture_output=True, text=True)

def verify_assets(assets, files):
    assert {a['name'] for a in assets} == {p.name for p in files}, 'release asset set differs'
    for p in files:
        rows = [a for a in assets if a['name'] == p.name]
        assert len(rows) == 1, 'duplicate asset'
        assert rows[0]['size'] == p.stat().st_size, 'asset size differs: '+p.name
        assert rows[0]['digest'] == 'sha256:'+hashlib.sha256(p.read_bytes()).hexdigest(), 'asset hash differs: '+p.name

def publish():
    repo = os.environ['GITHUB_REPOSITORY']
    tag = os.environ['GITHUB_REF_NAME']
    assert repo == 'jankendo/-gem-survivor-crystal-field-v3'
    assert tag == pathlib.Path('RELEASE_VERSION').read_text().strip() and tag != 'v3.0.0-alpha.1'
    files = sorted(pathlib.Path('release-upload').iterdir())
    assert {p.name for p in files} == {'GemSurvivorCrystalField-v3-unsigned.ipa',
        'GemSurvivorCrystalField-v3-Windows.zip', 'SHA256SUMS.txt',
        'RELEASE_MANIFEST.json', 'IOS_UNSIGNED_README.md'}
    endpoint = 'repos/'+repo+'/releases/tags/'+tag
    existing = call('api', endpoint)
    if existing.returncode:
        assert 'HTTP 404' in existing.stderr, 'release lookup failed'
        created = call('release', 'create', tag, '--repo', repo, '--verify-tag', '--draft', '--prerelease',
                       '--title', 'Gem Survivor Crystal Field v3 — '+tag, '--notes-file', 'docs/RELEASE_NOTES.md')
        assert created.returncode == 0, 'draft creation failed'
        existing = call('api', endpoint)
        assert existing.returncode == 0, 'draft lookup failed'
    release = json.loads(existing.stdout)
    if not release['draft']:
        # A retry may inspect an already completed publication, never mutate it.
        verify_assets(release['assets'], files)
        print(json.dumps({'ok': True, 'already_public': True, 'url': release['html_url']}))
        return
    uploaded = call('release', 'upload', tag, *[str(p) for p in files], '--repo', repo, '--clobber')
    assert uploaded.returncode == 0, 'draft asset upload failed; draft retained for retry'
    checked = call('api', endpoint)
    assert checked.returncode == 0, 'draft verification lookup failed'
    verify_assets(json.loads(checked.stdout)['assets'], files)
    published = call('release', 'edit', tag, '--repo', repo, '--draft=false', '--prerelease')
    assert published.returncode == 0, 'publication failed; verified draft retained for retry'
    print(json.dumps({'ok': True, 'version': tag, 'complete_assets': len(files)}))

if __name__ == '__main__':
    publish()
