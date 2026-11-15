import copy
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from targets import TARGETS, CLI_MAIN, validate


class TargetMembershipTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.objects = {"project": {"isa": "PBXProject", "mainGroup": "group", "targets": sorted(TARGETS)},
                        "group": {"isa": "PBXGroup", "children": []}}
        self.project = {"rootObject": "project", "objects": self.objects}
        for target in TARGETS:
            self.objects[target] = {"isa": "PBXNativeTarget", "name": target,
                                    "buildPhases": [target + "-sources"], "productReference": target + "-product"}
            self.objects[target + "-sources"] = {"isa": "PBXSourcesBuildPhase", "files": []}
        self.add_source("Jocker/App.swift", ["Jocker", "JockerSelfPlayTools"])
        self.add_source("Jocker/BotSelfPlayEvolutionEngine.swift", ["JockerSelfPlayTools"])
        self.add_source("JockerSelfPlayTools/BotTrainingRunner.swift", ["JockerSelfPlayTools"])
        self.add_source("JockerTests/ExampleTests.swift", ["JockerTests"])
        self.add_source("JockerUITests/ExampleUITests.swift", ["JockerUITests"])
        path = self.root / CLI_MAIN
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("// CLI only")

    def add_source(self, path, targets):
        file = self.root / "Jocker" / path
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text("// source")
        self.objects[path] = {"isa": "PBXFileReference", "path": path, "sourceTree": "<group>"}
        self.objects["group"]["children"].append(path)
        build = path + "-build"
        self.objects[build] = {"isa": "PBXBuildFile", "fileRef": path}
        for target in targets:
            self.objects[target + "-sources"]["files"].append(build)

    def test_shared_runtime_sources_and_cli_only_main_are_valid(self):
        self.assertEqual(validate(self.root, self.project)["status"], "passed")

    def test_new_file_without_membership_and_deleted_compiled_file_fail(self):
        (self.root / "Jocker/Jocker/New.swift").write_text("// new")
        (self.root / "Jocker/JockerTests/ExampleTests.swift").unlink()
        errors = validate(self.root, self.project)["errors"]
        self.assertTrue(any("Missing Jocker membership" in e for e in errors))
        self.assertTrue(any("Compiled file is missing" in e for e in errors))

    def test_training_source_cannot_leak_into_app(self):
        self.objects["Jocker-sources"]["files"].append("Jocker/BotSelfPlayEvolutionEngine.swift-build")
        self.assertTrue(any("Forbidden membership Jocker:" in e for e in validate(self.root, self.project)["errors"]))

    def test_runner_moved_under_app_still_requires_training_membership(self):
        self.add_source("Jocker/BotTrainingRunner.swift", ["Jocker"])
        errors = validate(self.root, self.project)["errors"]
        self.assertTrue(any("Forbidden membership Jocker:" in e for e in errors))

    def test_wrong_test_target_and_duplicate_source_are_rejected(self):
        self.add_source("JockerTests/Misplaced.swift", ["Jocker"])
        self.assertEqual(validate(self.root, self.project)["status"], "failed")
        self.objects["Jocker-sources"]["files"] *= 2
        with self.assertRaisesRegex(ValueError, "Duplicate"):
            validate(self.root, self.project)

    def test_app_cannot_link_training_library_or_depend_on_training_target(self):
        original = copy.deepcopy(self.project)
        self.objects["dependency"] = {"isa": "PBXTargetDependency", "target": "JockerSelfPlayTools"}
        self.objects["Jocker"]["dependencies"] = ["dependency"]
        with self.assertRaisesRegex(ValueError, "depends on"):
            validate(self.root, self.project)
        self.project = original
        self.objects = original["objects"]
        self.objects["link"] = {"isa": "PBXBuildFile", "fileRef": "JockerSelfPlayTools-product"}
        self.objects["frameworks"] = {"isa": "PBXFrameworksBuildPhase", "files": ["link"]}
        self.objects["Jocker"]["buildPhases"].append("frameworks")
        with self.assertRaisesRegex(ValueError, "links"):
            validate(self.root, self.project)
        self.objects["manual-library"] = {"isa": "PBXFileReference", "path": "libJockerSelfPlayTools.a"}
        self.objects["link"]["fileRef"] = "manual-library"
        with self.assertRaisesRegex(ValueError, "links"):
            validate(self.root, self.project)

    def test_conditional_exclusion_does_not_claim_verified_membership(self):
        self.objects["config"] = {"isa": "XCBuildConfiguration", "buildSettings": {"EXCLUDED_SOURCE_FILE_NAMES[sdk=iphonesimulator*]": "App.swift"}}
        with self.assertRaisesRegex(ValueError, "Conditional"):
            validate(self.root, self.project)

    def test_cli_main_cannot_compile_into_static_library(self):
        self.add_source("JockerSelfPlayTools/main.swift", ["JockerSelfPlayTools"])
        self.assertTrue(any("CLI main" in e for e in validate(self.root, self.project)["errors"]))
