#!/usr/bin/env python3
import unittest,tempfile,pathlib,hashlib
from release_manifest import manifest
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
if __name__=='__main__':unittest.main()
