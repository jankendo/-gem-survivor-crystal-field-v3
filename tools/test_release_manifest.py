#!/usr/bin/env python3
import unittest,tempfile,pathlib,hashlib,os,json,subprocess
from unittest.mock import patch
from release_manifest import manifest
from release_metadata import export_metadata
from publish_release import publish
class ManifestTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.p=pathlib.Path(self.temp.name)/'GemSurvivorCrystalField-v3-unsigned.ipa';self.p.write_bytes(b'actual archive bytes fixture');self.sha='a'*40
 def tearDown(self):self.temp.cleanup()
 def test_actual_hash(self):
  m=manifest('ios',self.p,self.sha,'v3.0.0-alpha.3','jankendo/-gem-survivor-crystal-field-v3');self.assertEqual(m['sha256'],hashlib.sha256(self.p.read_bytes()).hexdigest());self.assertEqual(m['source_commit'],self.sha);self.assertEqual(m['signing'],'unsigned')
 def test_missing_sha(self):
  with self.assertRaises(AssertionError):manifest('ios',self.p,'main','v3.0.0-alpha.3','jankendo/-gem-survivor-crystal-field-v3')
 def test_wrong_repo(self):
  with self.assertRaises(AssertionError):manifest('ios',self.p,self.sha,'v3.0.0-alpha.3','jankendo/gem-survivor-crystal-field-v3')
 def test_wrong_version(self):
  with self.assertRaises(AssertionError):manifest('ios',self.p,self.sha,'latest','jankendo/-gem-survivor-crystal-field-v3')
 def test_build_metadata_comes_from_actual_export_settings(self):
  root=pathlib.Path(self.temp.name);preset=root/'export.cfg';project=root/'project.godot'
  preset.write_text('[preset.7]\nplatform="iOS"\n[preset.7.options]\napplication/version="40017"\n')
  project.write_text('[application]\nconfig/version="4.0.0"\n')
  self.assertEqual(export_metadata('ios',preset,project),{'app_version':'4.0.0','app_build':'40017'})
class PublicationTests(unittest.TestCase):
 def setUp(self):
  self.old=os.getcwd();self.temp=tempfile.TemporaryDirectory();os.chdir(self.temp.name)
  pathlib.Path('RELEASE_VERSION').write_text('v3.0.0-alpha.3');pathlib.Path('release-upload').mkdir();self.assets=[]
  for name in ['GemSurvivorCrystalField-v3-unsigned.ipa','GemSurvivorCrystalField-v3-Windows.zip','SHA256SUMS.txt','RELEASE_MANIFEST.json','IOS_UNSIGNED_README.md']:
   p=pathlib.Path('release-upload')/name;p.write_bytes(name.encode());self.assets.append({'name':name,'size':p.stat().st_size,'digest':'sha256:'+hashlib.sha256(p.read_bytes()).hexdigest()})
  self.env=patch.dict(os.environ,{'GITHUB_REPOSITORY':'jankendo/-gem-survivor-crystal-field-v3','GITHUB_REF_NAME':'v3.0.0-alpha.3'});self.env.start()
 def tearDown(self):self.env.stop();os.chdir(self.old);self.temp.cleanup()
 def release(self,draft,assets):return {'id':4321,'tag_name':'v3.0.0-alpha.3','draft':draft,'assets':assets,'html_url':'https://github.com/example/release'}
 def response(self,obj):return subprocess.CompletedProcess([],0,json.dumps(obj),'')
 def listing(self,draft,assets):return self.response([[self.release(draft,assets)]])
 def success(self):return subprocess.CompletedProcess([],0,'','')
 def test_public_mismatch_never_overwrites(self):
  self.assets[0]['digest']='sha256:'+'0'*64
  with patch('publish_release.call',return_value=self.listing(False,self.assets)) as calls:
   with self.assertRaises(AssertionError):publish()
   self.assertEqual(len(calls.call_args_list),1)
 def test_failed_upload_retains_unpublished_draft(self):
  with patch('publish_release.call',side_effect=[self.listing(True,[]),subprocess.CompletedProcess([],1,'','upload failed')]) as calls:
   with self.assertRaises(AssertionError):publish()
   self.assertFalse(any('--method' in c.args for c in calls.call_args_list))
 def test_complete_draft_retry_publishes_without_recreation(self):
  with patch('publish_release.call',side_effect=[self.listing(True,[]),self.success(),self.response(self.release(True,self.assets)),self.success()]) as calls:
   publish();self.assertFalse(any(c.args[:2]==('release','create') for c in calls.call_args_list))
   self.assertEqual(calls.call_args_list[-1].args[1],'repos/jankendo/-gem-survivor-crystal-field-v3/releases/4321')
   self.assertEqual(json.loads(calls.call_args_list[-1].kwargs['input_text']),{'draft':False,'prerelease':True})
 def test_first_creation_reads_draft_by_id_not_published_tag_endpoint(self):
  # Real GitHub GET /releases/tags/:tag returns404 for a draft; authenticated list
  # includes it. Creation and recovery must never use that published-only endpoint.
  responses=[self.response([[]]),self.success(),self.listing(True,[]),self.success(),self.response(self.release(True,self.assets)),self.success()]
  with patch('publish_release.call',side_effect=responses) as calls:
   publish();self.assertTrue(any(c.args[:2]==('release','create') for c in calls.call_args_list))
   self.assertFalse(any('/releases/tags/' in str(c.args) for c in calls.call_args_list))
 def test_release_list_failure_never_creates_or_publishes(self):
  with patch('publish_release.call',return_value=subprocess.CompletedProcess([],1,'','HTTP403')) as calls:
   with self.assertRaises(AssertionError):publish()
   self.assertEqual(len(calls.call_args_list),1)
 def test_draft_changed_to_public_before_verification_is_rejected(self):
  with patch('publish_release.call',side_effect=[self.listing(True,[]),self.success(),self.response(self.release(False,self.assets))]) as calls:
   with self.assertRaises(AssertionError):publish()
   self.assertFalse(any('--method' in c.args for c in calls.call_args_list))
if __name__=='__main__':unittest.main()
