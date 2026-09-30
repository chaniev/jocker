import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

MODULE = Path(__file__).resolve().parents[1] / "verify.py"
sys.path.insert(0, str(MODULE.parent))
spec = importlib.util.spec_from_file_location("verify", MODULE)
verify = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verify)
CONFIG = json.loads(MODULE.with_name("checks.json").read_text())


class HarnessTests(unittest.TestCase):
    def test_both_runtime_ai_locations(self):
        for path in ["Jocker/Jocker/Models/Bot/BotTuning.swift", "Jocker/Jocker/Game/Services/AI/BotTurnStrategyService.swift"]:
            self.assertTrue({"phase", "ranking", "training-smoke"} <= verify.select_checks([path], CONFIG).keys())

    def test_unknown_and_structural_paths_are_conservative(self):
        for path in ["new-component/file.swift", "Jocker/Jocker.xcodeproj/project.pbxproj", "scripts/harness/verify.py"]:
            self.assertIn("full-tests", verify.select_checks([path], CONFIG))

    def test_docs_and_ci(self):
        selected = verify.select_checks(["docs/guide.md"], CONFIG)
        self.assertEqual(set(selected), {"instructions", "harness-tests"})
        self.assertIn("training-smoke", verify.select_checks([], CONFIG, ci=True))
        self.assertIn("full-tests", verify.select_checks([], CONFIG, ci=True))

    def test_training_files_union_rules(self):
        selected = verify.select_checks(["Jocker/Jocker/Game/Services/AI/BotSelfPlayEvolutionEngine+Evolution.swift"], CONFIG)
        self.assertTrue({"full-tests", "training-smoke", "phase"} <= selected.keys())

    def test_diff_rename_delete_untracked_and_fingerprint(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            def git(*args):
                return verify.git(root, *args)
            git("init", "-q")
            git("config", "user.email", "test@example.invalid")
            git("config", "user.name", "Harness Test")
            (root / "old.swift").write_text("old")
            (root / "deleted.swift").write_text("delete")
            git("add", ".")
            git("commit", "-qm", "base")
            base = git("rev-parse", "HEAD").decode().strip()
            git("mv", "old.swift", "new name.swift")
            (root / "deleted.swift").unlink()
            (root / "untracked.swift").write_text("new")
            state = verify.snapshot(root, base)
            self.assertEqual(set(state["paths"]), {"old.swift", "new name.swift", "deleted.swift", "untracked.swift"})
            (root / "untracked.swift").write_text("changed")
            self.assertNotEqual(state["fingerprint"], verify.snapshot(root, base)["fingerprint"])
            git("add", ".")
            git("commit", "-qm", "changes")
            self.assertIn("new name.swift", verify.snapshot(root, base)["paths"])

    def test_execution_failure_missing_executable_timeout(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for command, timeout, status in [
                ([sys.executable, "-c", "raise SystemExit(7)"], 5, "failed"),
                (["/nonexistent/harness-command"], 5, "blocked"),
                ([sys.executable, "-c", "import time; time.sleep(10)"], 0.05, "blocked"),
            ]:
                result = verify.execute(command, root, root / "log", timeout)
                self.assertEqual(result["status"], status)

    def test_report_failure_and_stale_never_pass(self):
        for failed, stale in [(True, False), (False, True), (False, False)]:
            with tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                (root / "scripts/harness").mkdir(parents=True)
                (root / "scripts/harness/checks.json").write_text(json.dumps(CONFIG))
                before = {"paths": [], "fingerprint": "a"}
                after = {"paths": [], "fingerprint": "b" if stale else "a"}
                result = {"status": "failed" if failed else "passed", "exitCode": 1 if failed else 0}
                with patch.object(verify, "snapshot", side_effect=[before, after]), patch.object(verify, "execute", return_value=result):
                    code = verify.run(root, "verify", "HEAD", "test", 10)
                report = json.loads(next(root.glob(".derivedData/harness-runs/*/summary.json")).read_text())
                self.assertEqual(code, 1 if failed or stale else 0)
                self.assertEqual(report["stale"], stale)

    def test_invalid_base_persists_blocked_report(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts/harness").mkdir(parents=True)
            (root / "scripts/harness/checks.json").write_text(json.dumps(CONFIG))
            with patch.object(verify, "snapshot", side_effect=ValueError("unknown base")):
                self.assertEqual(verify.run(root, "ci", "missing", "test", 10), 1)
            report = json.loads(next(root.glob(".derivedData/harness-runs/*/summary.json")).read_text())
            self.assertEqual(report["status"], "blocked")

    def test_environment_failure_does_not_execute_xcode_or_training(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts/harness").mkdir(parents=True)
            (root / "scripts/harness/checks.json").write_text(json.dumps(CONFIG))
            state = {"paths": [], "fingerprint": "a"}
            plan = {"checks": [{"name": "full-tests", "kind": "xctest", "command": ["must-not-run"], "selectors": []}, {"name": "training-smoke", "kind": "training", "command": ["must-not-run"]}], "packSelectors": {}}
            with patch.object(verify, "snapshot", return_value=state), patch.object(verify, "build_plan", return_value=plan), patch.object(verify, "doctor", return_value={"status": "blocked", "error": "simulator unavailable"}), patch.object(verify, "execute") as execute:
                self.assertEqual(verify.run(root, "ci", "HEAD", "test", 10), 1)
            execute.assert_not_called()
            report = json.loads(next(root.glob(".derivedData/harness-runs/*/summary.json")).read_text())
            self.assertEqual(report["schemaVersion"], 2)
            self.assertTrue(all(c["status"] == "blocked" for c in report["checks"]))
            self.assertTrue(all(c["durationSeconds"] >= 0 for c in report["checks"]))

    def test_successful_command_without_test_evidence_is_not_green(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts/harness").mkdir(parents=True)
            (root / "scripts/harness/checks.json").write_text(json.dumps(CONFIG))
            plan = {"checks": [{"name": "selected-tests", "kind": "xctest", "command": ["test-command"], "selectors": ["JockerTests/A/testOne"]}], "packSelectors": {}}
            with patch.object(verify, "snapshot", return_value={"paths": [], "fingerprint": "a"}), patch.object(verify, "build_plan", return_value=plan), patch.object(verify, "doctor", return_value={"status": "passed"}), patch.object(verify, "execute", return_value={"status": "passed", "exitCode": 0}), patch.object(verify, "collect_results", side_effect=ValueError("missing bundle")):
                self.assertEqual(verify.run(root, "ci", "HEAD", "test", 10), 1)
            report = json.loads(next(root.glob(".derivedData/harness-runs/*/summary.json")).read_text())
            self.assertEqual(report["checks"][-1]["status"], "blocked")
            self.assertEqual(report["checks"][-1]["resultsError"], "missing bundle")
