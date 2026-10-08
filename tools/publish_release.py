#!/usr/bin/env python3
"""Publish only a complete draft; never overwrite assets of a public release."""
import hashlib, json, os, pathlib, subprocess, urllib.request, urllib.parse

def call(*args, input_text=None):
    return subprocess.run(['gh', *args], input=input_text, capture_output=True, text=True)

def find_release(repo, tag):
    # GET /releases/tags/:tag does not return unpublished drafts. List authenticated
    # releases, then use the stable release ID for all draft reads/publication.
    result = call('api', 'repos/'+repo+'/releases?per_page=100', '--paginate')
    assert result.returncode == 0, 'release list failed'
    # --paginate emits consecutive JSON arrays; avoid newer CLI-only --slurp.
    decoder = json.JSONDecoder()
    remaining, rows = result.stdout.lstrip(), []
    while remaining:
        page, end = decoder.raw_decode(remaining)
        assert isinstance(page, list), 'release list response is not an array'
        rows.extend(r for r in page if r['tag_name'] == tag)
        remaining = remaining[end:].lstrip()
    assert len(rows) <= 1, 'duplicate release tag'
    return rows[0] if rows else None

def verify_assets(assets, files):
    assert {a['name'] for a in assets} == {p.name for p in files}, 'release asset set differs'
    for p in files:
        rows = [a for a in assets if a['name'] == p.name]
        assert len(rows) == 1, 'duplicate asset'
        assert rows[0]['size'] == p.stat().st_size, 'asset size differs: '+p.name
        assert rows[0]['digest'] == 'sha256:'+hashlib.sha256(p.read_bytes()).hexdigest(), 'asset hash differs: '+p.name

def upload_asset(release, path):
    # Stream to the exact server-provided Release ID, never resolve a draft by tag.
    assert release['draft'], 'cannot upload to a public release'
    parsed = urllib.parse.urlsplit(release['upload_url'].split('{')[0])
    assert parsed.scheme == 'https' and parsed.hostname == 'uploads.github.com', 'unexpected upload host'
    assert parsed.path.endswith('/releases/'+str(release['id'])+'/assets'), 'upload release ID differs'
    request_url = urllib.parse.urlunsplit(parsed)+'?name='+urllib.parse.quote(path.name)
    with path.open('rb') as body:
        request = urllib.request.Request(request_url, data=body, method='POST', headers={
            'Authorization':'Bearer '+os.environ['GH_TOKEN'],
            'Content-Type':'application/octet-stream', 'Content-Length':str(path.stat().st_size),
            'Accept':'application/vnd.github+json', 'X-GitHub-Api-Version':'2022-11-28'})
        try:
            with urllib.request.urlopen(request, timeout=300) as response:
                asset = json.load(response)
        except Exception as error:
            # Do not expose authorization headers or temporary URLs from errors.
            raise RuntimeError('Release asset upload failed ('+str(getattr(error,'code',type(error).__name__))+'): '+path.name) from None
    assert asset['name'] == path.name and asset['size'] == path.stat().st_size, 'upload response differs'
    return asset

def publish():
    repo = os.environ['GITHUB_REPOSITORY']
    tag = os.environ['GITHUB_REF_NAME']
    assert repo == 'jankendo/-gem-survivor-crystal-field-v3'
    assert tag == pathlib.Path('RELEASE_VERSION').read_text().strip() and tag != 'v3.0.0-alpha.1'
    files = sorted(pathlib.Path('release-upload').iterdir())
    assert {p.name for p in files} == {'GemSurvivorCrystalField-v3-unsigned.ipa',
        'GemSurvivorCrystalField-v3-Windows.zip', 'SHA256SUMS.txt',
        'RELEASE_MANIFEST.json', 'IOS_UNSIGNED_README.md'}
    release = find_release(repo, tag)
    if release is None:
        ref = call('api', 'repos/'+repo+'/git/ref/tags/'+tag)
        assert ref.returncode == 0, 'release tag absent'
        tag_object = json.loads(ref.stdout)['object']
        assert tag_object['sha'] == os.environ['GITHUB_SHA'] and tag_object['type'] == 'commit', 'tag is not the checked-out source'
        created = call('api', 'repos/'+repo+'/releases', '--method', 'POST', '--input', '-', input_text=json.dumps({
            'tag_name':tag, 'target_commitish':os.environ['GITHUB_SHA'],
            'name':'Gem Survivor Crystal Field v3 — '+tag,
            'body':pathlib.Path('docs/RELEASE_NOTES.md').read_text(), 'draft':True, 'prerelease':True}))
        assert created.returncode == 0, 'draft creation failed'
        release = json.loads(created.stdout)
        assert release['draft'] and release['tag_name'] == tag, 'created draft identity differs'
        # The POST response is authoritative. A tag/list index may not see the
        # draft immediately; no second search or tag-based CLI upload is used.
    if not release['draft']:
        # A retry may inspect an already completed publication, never mutate it.
        verify_assets(release['assets'], files)
        print(json.dumps({'ok': True, 'already_public': True, 'url': release['html_url']}))
        return
    for path in files:
        existing = [a for a in release['assets'] if a['name'] == path.name]
        assert len(existing) <= 1, 'duplicate draft asset'
        if existing:
            asset = existing[0]
            if asset['size'] == path.stat().st_size and asset.get('digest') == 'sha256:'+hashlib.sha256(path.read_bytes()).hexdigest():
                continue
            deleted = call('api', 'repos/'+repo+'/releases/assets/'+str(asset['id']), '--method', 'DELETE')
            assert deleted.returncode == 0, 'stale draft asset deletion failed'
        upload_asset(release, path)
    endpoint = 'repos/'+repo+'/releases/'+str(release['id'])
    checked = call('api', endpoint)
    assert checked.returncode == 0, 'draft verification lookup failed'
    checked_release = json.loads(checked.stdout)
    assert checked_release['draft'] and checked_release['tag_name'] == tag, 'draft identity/state differs'
    verify_assets(checked_release['assets'], files)
    published = call('api', endpoint, '--method', 'PATCH', '--input', '-',
                     input_text=json.dumps({'draft': False, 'prerelease': True}))
    assert published.returncode == 0, 'publication failed; verified draft retained for retry'
    print(json.dumps({'ok': True, 'version': tag, 'complete_assets': len(files)}))

if __name__ == '__main__':
    publish()
