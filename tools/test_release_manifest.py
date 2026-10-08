#!/usr/bin/env python3
import unittest,tempfile,pathlib,hashlib,os,json,subprocess
from unittest.mock import patch
from release_manifest import manifest
from release_metadata import export_metadata
from publish_release import publish,upload_asset
class ManifestTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.p=pathlib.Path(self.temp.name)/'GemSurvivorCrystalField-v3-unsigned.ipa';self.p.write_bytes(b'actual archive bytes fixture');self.sha='a'*40
 def tearDown(self):self.temp.cleanup()
 def test_actual_hash(self):
  m=manifest('ios',self.p,self.sha,'v3.0.0-alpha.4','jankendo/-gem-survivor-crystal-field-v3');self.assertEqual(m['sha256'],hashlib.sha256(self.p.read_bytes()).hexdigest());self.assertEqual(m['source_commit'],self.sha);self.assertEqual(m['signing'],'unsigned')
 def test_missing_sha(self):
  with self.assertRaises(AssertionError):manifest('ios',self.p,'main','v3.0.0-alpha.4','jankendo/-gem-survivor-crystal-field-v3')
 def test_wrong_repo(self):
  with self.assertRaises(AssertionError):manifest('ios',self.p,self.sha,'v3.0.0-alpha.4','jankendo/gem-survivor-crystal-field-v3')
 def test_wrong_version(self):
  with self.assertRaises(AssertionError):manifest('ios',self.p,self.sha,'latest','jankendo/-gem-survivor-crystal-field-v3')
 def test_build_metadata_comes_from_actual_export_settings(self):
  root=pathlib.Path(self.temp.name);preset=root/'export.cfg';project=root/'project.godot'
  preset.write_text('[preset.7]\nplatform="iOS"\n[preset.7.options]\napplication/version="40017"\n');project.write_text('[application]\nconfig/version="4.0.0"\n')
  self.assertEqual(export_metadata('ios',preset,project),{'app_version':'4.0.0','app_build':'40017'})
class PublicationTests(unittest.TestCase):
 def setUp(self):
  self.old=os.getcwd();self.temp=tempfile.TemporaryDirectory();os.chdir(self.temp.name);self.sha='a'*40
  pathlib.Path('RELEASE_VERSION').write_text('v3.0.0-alpha.4');pathlib.Path('release-upload').mkdir();pathlib.Path('docs').mkdir();pathlib.Path('docs/RELEASE_NOTES.md').write_text('Exact notes\n日本語')
  self.assets=[]
  for i,name in enumerate(['GemSurvivorCrystalField-v3-unsigned.ipa','GemSurvivorCrystalField-v3-Windows.zip','SHA256SUMS.txt','RELEASE_MANIFEST.json','IOS_UNSIGNED_README.md']):
   p=pathlib.Path('release-upload')/name;p.write_bytes(name.encode());self.assets.append({'id':100+i,'name':name,'size':p.stat().st_size,'digest':'sha256:'+hashlib.sha256(p.read_bytes()).hexdigest()})
  self.env=patch.dict(os.environ,{'GITHUB_REPOSITORY':'jankendo/-gem-survivor-crystal-field-v3','GITHUB_REF_NAME':'v3.0.0-alpha.4','GITHUB_SHA':self.sha});self.env.start()
 def tearDown(self):self.env.stop();os.chdir(self.old);self.temp.cleanup()
 def release(self,draft,assets):return {'id':4321,'tag_name':'v3.0.0-alpha.4','draft':draft,'assets':assets,'html_url':'https://github.com/example/release','upload_url':'https://uploads.github.com/repos/jankendo/-gem-survivor-crystal-field-v3/releases/4321/assets{?name,label}'}
 def response(self,obj):return subprocess.CompletedProcess([],0,json.dumps(obj),'')
 def listing(self,draft,assets):return self.response([self.release(draft,assets)])
 def success(self):return subprocess.CompletedProcess([],0,'','')
 def uploaded(self,release,path):return next(a for a in self.assets if a['name']==path.name)
 def test_public_mismatch_never_overwrites(self):
  self.assets[0]['digest']='sha256:'+'0'*64
  with patch('publish_release.call',return_value=self.listing(False,self.assets)) as calls:
   with self.assertRaises(AssertionError):publish()
   self.assertEqual(len(calls.call_args_list),1)
 def test_failed_upload_retains_unpublished_draft(self):
  with patch('publish_release.call',return_value=self.listing(True,[])) as calls,patch('publish_release.upload_asset',side_effect=RuntimeError('upload failed')):
   with self.assertRaises(RuntimeError):publish()
   self.assertFalse(any('--method' in c.args for c in calls.call_args_list))
 def test_complete_draft_retry_publishes_without_recreation_or_upload(self):
  with patch('publish_release.call',side_effect=[self.listing(True,self.assets),self.response(self.release(True,self.assets)),self.success()]) as calls,patch('publish_release.upload_asset') as uploaded:
   publish();uploaded.assert_not_called()
   self.assertEqual(calls.call_args_list[-1].args[1],'repos/jankendo/-gem-survivor-crystal-field-v3/releases/4321')
   self.assertEqual(json.loads(calls.call_args_list[-1].kwargs['input_text']),{'draft':False,'prerelease':True})
 def test_creation_response_is_authoritative_even_when_draft_index_stays_empty(self):
  responses=[self.response([]),self.response({'object':{'sha':self.sha,'type':'commit','url':'source'}}),self.response(self.release(True,[])),self.response(self.release(True,self.assets)),self.success()]
  with patch('publish_release.call',side_effect=responses) as calls,patch('publish_release.upload_asset',side_effect=self.uploaded) as uploaded:
   publish();self.assertEqual(uploaded.call_count,5)
   self.assertEqual(sum('/releases?per_page=' in str(c.args) for c in calls.call_args_list),1)
   self.assertFalse(any(c.args[0]=='release' or '/releases/tags/' in str(c.args) for c in calls.call_args_list))
   post=calls.call_args_list[2];body=json.loads(post.kwargs['input_text']);self.assertTrue(body['draft']);self.assertEqual(body['body'],'Exact notes\n日本語');self.assertEqual(body['target_commitish'],self.sha)
 def test_pagination_finds_draft_after_first_page_with_portable_cli(self):
  first={'id':123,'tag_name':'another-tag','draft':False,'assets':[]}
  listing=subprocess.CompletedProcess([],0,json.dumps([first])+"\n"+json.dumps([self.release(True,self.assets)]),'')
  with patch('publish_release.call',side_effect=[listing,self.response(self.release(True,self.assets)),self.success()]) as calls:
   publish();self.assertNotIn('--slurp',calls.call_args_list[0].args)
 def test_release_list_failure_never_creates_or_publishes(self):
  with patch('publish_release.call',return_value=subprocess.CompletedProcess([],1,'','HTTP403')) as calls:
   with self.assertRaises(AssertionError):publish()
   self.assertEqual(len(calls.call_args_list),1)
 def test_draft_changed_to_public_before_verification_is_rejected(self):
  with patch('publish_release.call',side_effect=[self.listing(True,self.assets),self.response(self.release(False,self.assets))]) as calls:
   with self.assertRaises(AssertionError):publish()
   self.assertFalse(any('--method' in c.args for c in calls.call_args_list))
 def test_partial_draft_retry_uploads_only_missing_assets(self):
  with patch('publish_release.call',side_effect=[self.listing(True,self.assets[:1]),self.response(self.release(True,self.assets)),self.success()]),patch('publish_release.upload_asset',side_effect=self.uploaded) as uploaded:
   publish();self.assertEqual(uploaded.call_count,4)
 def test_wrong_tag_source_never_creates_release(self):
  with patch('publish_release.call',side_effect=[self.response([]),self.response({'object':{'sha':'b'*40,'type':'commit','url':'source'}})]) as calls:
   with self.assertRaises(AssertionError):publish()
   self.assertFalse(any('--method' in c.args for c in calls.call_args_list))
 def test_upload_cannot_send_credentials_to_other_host_or_public_release(self):
  r=self.release(False,[])
  with self.assertRaises(AssertionError):upload_asset(r,pathlib.Path('release-upload/IOS_UNSIGNED_README.md'))
  r=self.release(True,[]);r['upload_url']='https://example.com/releases/4321/assets'
  with self.assertRaises(AssertionError):upload_asset(r,pathlib.Path('release-upload/IOS_UNSIGNED_README.md'))
if __name__=='__main__':unittest.main()
