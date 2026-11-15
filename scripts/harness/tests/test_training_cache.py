from concurrent.futures import ThreadPoolExecutor
import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from training_runner_cache import ensure_runner, input_state, fingerprint


class TrainingCacheTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for path in ["Jocker/Jocker/Core/GameColors.swift", "Jocker/Jocker/Game/Nodes/CardNode.swift",
                     "Jocker/Jocker/Game/Nodes/TrickNode.swift", "Jocker/JockerSelfPlayTools/main.swift",
                     "Jocker/Jocker/Models/Model.swift", "Jocker/Jocker/Scoring/Score.swift",
                     "Jocker/Jocker/Game/Services/AI/Bot.swift"]:
            file = self.root / path
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_text("// " + path)
        compiler = self.root / "compiler.py"
        compiler.write_text('''import pathlib, sys
args = sys.argv[1:]
log = pathlib.Path(__file__).with_suffix('.log')
with log.open('a') as stream: stream.write('compile\\n')
if '--fail' in args: raise SystemExit(7)
if '--mutate' in args:
    source = next(pathlib.Path(p) for p in args if p.endswith('.swift'))
    source.write_text(source.read_text() + '// changed')
output = pathlib.Path(args[args.index('-o') + 1])
output.write_text('#!/bin/sh\\nexit 0\\n')
output.chmod(0o755)
''')
        self.toolchain = {"compiler": [sys.executable, str(compiler)], "compilerVersion": "1",
                          "sdkPath": "/sdk", "sdkVersion": "1", "flags": ["-O"]}
        self.build = self.root / ".derivedData/cache"
        self.log = compiler.with_suffix(".log")

    def build_runner(self, toolchain=None):
        return ensure_runner(self.root, self.build, toolchain or self.toolchain)

    def count(self):
        return len(self.log.read_text().splitlines())

    def test_hit_touch_and_content_change_with_restored_mtime(self):
        first = self.build_runner()
        source = self.root / "Jocker/Jocker/Models/Model.swift"
        original = source.stat()
        os.utime(source, None)
        self.assertEqual(self.build_runner(), first)
        self.assertEqual(self.count(), 1)
        source.write_text("// different content")
        os.utime(source, ns=(original.st_atime_ns, original.st_mtime_ns))
        self.assertNotEqual(self.build_runner(), first)
        self.assertEqual(self.count(), 2)

    def test_added_removed_and_renamed_sources_invalidate(self):
        first = self.build_runner()
        added = self.root / "Jocker/Jocker/Models/Extra.swift"
        added.write_text("// extra")
        second = self.build_runner()
        self.assertNotEqual(first, second)
        renamed = added.with_name("Renamed.swift")
        added.rename(renamed)
        third = self.build_runner()
        self.assertNotEqual(second, third)
        renamed.unlink()
        self.assertEqual(self.build_runner(), first)
        self.assertEqual(self.count(), 3)

    def test_compiler_sdk_and_flags_change_key(self):
        first = self.build_runner()
        for key, value in [("compilerVersion", "2"), ("sdkVersion", "2"), ("sdkPath", "/new-sdk"), ("flags", ["-Onone"])]:
            changed = copy.deepcopy(self.toolchain)
            changed[key] = value
            self.assertNotEqual(self.build_runner(changed), first)
        self.assertEqual(self.count(), 5)

    def test_failed_compile_never_reuses_previous_binary(self):
        first = self.build_runner()
        failed = copy.deepcopy(self.toolchain)
        failed["flags"].append("--fail")
        with self.assertRaises(subprocess.CalledProcessError):
            self.build_runner(failed)
        self.assertTrue(first.is_file())
        entry = self.build / fingerprint(input_state(self.root, failed))
        self.assertFalse((entry / "manifest.json").exists())

    def test_mutation_during_compile_is_not_published(self):
        changed = copy.deepcopy(self.toolchain)
        changed["flags"].append("--mutate")
        with self.assertRaisesRegex(ValueError, "changed during"):
            self.build_runner(changed)
        self.assertFalse(list(self.build.glob('*/manifest.json')))

    def test_corrupt_binary_and_manifest_are_rebuilt(self):
        binary = self.build_runner()
        binary.write_text("corrupt")
        self.build_runner()
        self.assertEqual(self.count(), 2)
        binary.with_name("manifest.json").write_text("invalid JSON")
        self.build_runner()
        self.assertEqual(self.count(), 3)
        self.assertIn("binarySHA256", json.loads(binary.with_name("manifest.json").read_text()))

    def test_concurrent_requests_compile_once(self):
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda _: self.build_runner(), range(2)))
        self.assertEqual(results[0], results[1])
        self.assertEqual(self.count(), 1)
