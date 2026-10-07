#!/usr/bin/env python3
import unittest,tempfile,pathlib,hashlib,os,json,subprocess
from unittest.mock import patch
from release_manifest import manifest
from publish_release import publish
class ManifestTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.p=pathlib.Path(self.temp.name)/'GemSurvivorCrystalField-v3-unsigned.ipa';self.p.write_bytes(b'actual archive bytes fixture');self.sha='a'*40
 def tearDown(self):self.temp.cleanup()
 def test_actual_hash(self):
  m=manifest('ios',self.p,self.sha,'v3.0.0-alpha.2','jankendo/-gem-survivor-crystal-field-v3');self.assertEqual(m['sha256'],hashlib.sha256(self.p.read_bytes()).hexdigest());self.assertEqual(m['source_commit'],self.sha);self.assertEqual(m['signing'],'unsigned')
 def test_missing_sha(self):
  with self.assertRaises(AssertionError):manifest('ios',self.p,'main','v3.0.0-alpha.2','jankendo/-gem-survivor-crystal-field-v3')
 def test_wrong_repo(self):
  with self.assertRaises(AssertionError):manifest('ios',self.p,self.sha,'v3.0.0-alpha.2','jankendo/gem-survivor-crystal-field-v3')
 def test_wrong_version(self):
  with self.assertRaises(AssertionError):manifest('ios',self.p,self.sha,'latest','jankendo/-gem-survivor-crystal-field-v3')
class PublicationTests(unittest.TestCase):
 def setUp(self):
  self.old=os.getcwd();self.temp=tempfile.TemporaryDirectory();os.chdir(self.temp.name)
  pathlib.Path('RELEASE_VERSION').write_text('v3.0.0-alpha.2')
  pathlib.Path('release-upload').mkdir()
  self.assets=[]
  for name in ['GemSurvivorCrystalField-v3-unsigned.ipa','GemSurvivorCrystalField-v3-Windows.zip','SHA256SUMS.txt','RELEASE_MANIFEST.json','IOS_UNSIGNED_README.md']:
   p=pathlib.Path('release-upload')/name;p.write_bytes(name.encode())
   self.assets.append({'name':name,'size':p.stat().st_size,'digest':'sha256:'+hashlib.sha256(p.read_bytes()).hexdigest()})
  self.env=patch.dict(os.environ,{'GITHUB_REPOSITORY':'jankendo/-gem-survivor-crystal-field-v3','GITHUB_REF_NAME':'v3.0.0-alpha.2'});self.env.start()
 def tearDown(self):
  self.env.stop();os.chdir(self.old);self.temp.cleanup()
 def response(self,draft,assets):
  return subprocess.CompletedProcess([],0,json.dumps({'draft':draft,'assets':assets,'html_url':'https://github.com/example/release'}),'')
 def test_public_mismatch_never_overwrites(self):
  self.assets[0]['digest']='sha256:'+'0'*64
  with patch('publish_release.call',return_value=self.response(False,self.assets)) as calls:
   with self.assertRaises(AssertionError):publish()
   self.assertEqual(len(calls.call_args_list),1) # read only, no upload/edit
 def test_failed_upload_retains_unpublished_draft(self):
  with patch('publish_release.call',side_effect=[self.response(True,[]),subprocess.CompletedProcess([],1,'','upload failed')]) as calls:
   with self.assertRaises(AssertionError):publish()
   self.assertFalse(any(c.args[:2]==('release','edit') for c in calls.call_args_list))
 def test_complete_draft_retry_publishes_without_recreation(self):
  with patch('publish_release.call',side_effect=[self.response(True,[]),subprocess.CompletedProcess([],0,'',''),self.response(True,self.assets),subprocess.CompletedProcess([],0,'','')]) as calls:
   publish()
   self.assertFalse(any(c.args[:2]==('release','create') for c in calls.call_args_list))
   self.assertEqual(calls.call_args_list[-1].args[:2],('release','edit'))
if __name__=='__main__':unittest.main()
