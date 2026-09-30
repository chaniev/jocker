import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from planning import build_plan, compact_selectors, pack_selectors, scheme_targets

ROOT = Path(__file__).resolve().parents[3]
CONFIG = json.loads((ROOT / "scripts/harness/checks.json").read_text())


class PlanningTests(unittest.TestCase):
    def test_full_suite_subsumes_packs_but_preserves_contract_checks(self):
        selected = {name: ["changed"] for name in ("full-tests", "joker", "phase", "ranking", "training-smoke")}
        plan = build_plan(ROOT, selected, CONFIG)
        xctests = [c for c in plan["checks"] if c["kind"] == "xctest"]
        self.assertEqual(len(xctests), 1)
        self.assertEqual(xctests[0]["name"], "full-tests")
        self.assertEqual(xctests[0]["selectors"], [])
        self.assertEqual(len([c for c in plan["checks"] if c["kind"] == "contract"]), 3)
        self.assertEqual(plan["checks"][-1]["name"], "training-smoke")

    def test_partial_packs_are_one_union_and_class_subsumes_method(self):
        with patch("planning.pack_selectors", side_effect=[["JockerTests/A/testOne", "JockerTests/B/testTwo"], ["JockerTests/A", "JockerTests/B/testTwo"]]):
            plan = build_plan(ROOT, {"joker": [], "phase": []}, CONFIG)
        execution = [c for c in plan["checks"] if c["kind"] == "xctest"]
        self.assertEqual(len(execution), 1)
        self.assertEqual(execution[0]["selectors"], ["JockerTests/A", "JockerTests/B/testTwo"])
        self.assertEqual(plan["selectionCountBeforeUnion"], 4)

    def test_union_does_not_confuse_similar_class_names(self):
        self.assertEqual(compact_selectors(["JockerTests/A", "JockerTests/AB/testOne"]), ["JockerTests/A", "JockerTests/AB/testOne"])

    def test_empty_pack_fails_closed(self):
        with patch("planning.subprocess.check_output", return_value="No tests"):
            with self.assertRaises(ValueError):
                pack_selectors(ROOT, ["bash", "pack.sh"])

    def test_scheme_with_exclusions_cannot_claim_full_coverage(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root / "Jocker/Jocker.xcodeproj/xcshareddata/xcschemes/Jocker.xcscheme"
            path.parent.mkdir(parents=True)
            path.write_text('<Scheme><TestAction><Testables><TestableReference skipped="YES"><BuildableReference BlueprintName="JockerTests"/></TestableReference></Testables></TestAction></Scheme>')
            with self.assertRaises(ValueError):
                scheme_targets(root)
