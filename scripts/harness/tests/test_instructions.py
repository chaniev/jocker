import contextlib
import io
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import instructions
import verify


class InstructionTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        for name in instructions.REQUIRED:
            self.write(name, "# Instructions\n")
        self.write(".agents/skills/example/SKILL.md", "---\nname: example\ndescription: Example workflow\n---\nFollow AGENTS.md.\n")
        self.profile = '\n'.join([
            'name = "example-agent"', 'description = "Example role"',
            'model = "test-model"', 'model_reasoning_effort = "high"',
            'sandbox_mode = "workspace-write"',
            'developer_instructions = """Follow root AGENTS.md."""', '',
        ])
        self.write(".codex/agents/example-agent.toml", self.profile)
        self.write(instructions.CATALOG, "Before\n" + instructions.START + "\n" + instructions.END + "\nAfter\n")
        instructions.write_catalog(self.root)

    def write(self, name, text):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def errors(self):
        return "\n".join(instructions.check(self.root))

    def test_valid_sources_and_verifier_entrypoint_pass(self):
        self.assertEqual(self.errors(), "")
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(verify.instructions(self.root), 0)

    def test_known_stack_conflicts_are_rejected_across_instruction_surfaces(self):
        for name in ("AGENTS.md", "Jocker/Jocker/AGENTS.md", ".cursor/rules/swift.mdc",
                     ".agents/skills/example/SKILL.md", ".codex/agents/example-agent.toml"):
            path = self.root / name
            original = path.read_text()
            for bad in ("Use MVVM architecture with SwiftUI", "Use Combine for reactive code",
                        "Use async/await for concurrency", "SwiftUI first, UIKit when needed",
                        "Use @StateObject for state", "- Combine for reactive code",
                        "- async/await for concurrency"):
                with self.subTest(name=name, bad=bad):
                    if name.endswith(".toml"):
                        path.write_text(original.replace("Follow root AGENTS.md.", bad))
                    else:
                        path.write_text(original + "\n" + bad + "\n")
                    self.assertIn(name + ": known stack conflict:", self.errors())
            path.write_text(original)

    def test_prohibitions_and_training_exception_are_not_conflicts(self):
        self.write("Jocker/Jocker/AGENTS.md", "Do not use SwiftUI. Never use Combine.\n"
                   "No SwiftUI, no Combine, no async/await in app code.\n"
                   "Training-only sources may use async/await.\n"
                   "Training-only code: async/await for concurrency.\n")
        self.assertEqual(self.errors(), "")
        with (self.root / "Jocker/Jocker/AGENTS.md").open("a") as stream:
            stream.write("No SwiftUI. Use Combine for reactive code.\n")
        self.assertIn("known stack conflict", self.errors())

    def test_missing_required_file_reports_failure_without_traceback(self):
        (self.root / "Jocker/Jocker/AGENTS.md").unlink()
        self.assertIn("Missing Jocker/Jocker/AGENTS.md", self.errors())
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(verify.instructions(self.root), 1)

    def test_local_links_unicode_fragments_and_fenced_placeholders(self):
        self.write("docs/правила игры.md", "# Rules\n")
        self.write("AGENTS.md", "[rules](docs/правила%20игры.md#rules)\n"
                   "[external](https://example.invalid/missing.md)\n[local](#title)\n"
                   "```md\n[template](missing-placeholder.md)\n```\n")
        self.assertEqual(self.errors(), "")
        (self.root / "docs/правила игры.md").unlink()
        self.assertIn("missing local link", self.errors())

    def test_missing_profile_skill_reference_and_reference_document(self):
        path = self.root / ".codex/agents/example-agent.toml"
        path.write_text(self.profile.replace("Follow root AGENTS.md.", "Read `.agents/skills/missing/SKILL.md`."))
        self.write(".agents/skills/example/references/guide.md", "[missing](other.md)\n")
        errors = self.errors()
        self.assertIn("missing instruction reference: .agents/skills/missing/SKILL.md", errors)
        self.assertIn("references/guide.md: missing local link: other.md", errors)

    def test_missing_and_malformed_metadata_fail(self):
        path = self.root / ".codex/agents/example-agent.toml"
        for profile in (self.profile.replace('name = "example-agent"', 'name = "wrong"'),
                        self.profile + 'name = "duplicate"\n',
                        self.profile.replace('model = "test-model"', 'model = invalid'),
                        self.profile.replace('description = "Example role"\n', '')):
            with self.subTest(profile=profile):
                path.write_text(profile)
                self.assertTrue(instructions.inventory(self.root)[1])
        path.write_text(self.profile)
        self.write(".agents/skills/example/SKILL.md", "---\nname: wrong\ndescription: Example\n---\n")
        self.assertIn("skill name must match", self.errors())

    def test_catalog_detects_addition_removal_and_description_changes(self):
        path = self.root / ".agents/skills/example/SKILL.md"
        path.write_text(path.read_text().replace("Example workflow", "Updated workflow"))
        self.assertIn("catalog drift", self.errors())
        instructions.write_catalog(self.root)
        self.assertEqual(self.errors(), "")
        added = self.write(".agents/skills/second/SKILL.md", "---\nname: second\ndescription: Second workflow\n---\n")
        self.assertIn("catalog drift", self.errors())
        instructions.write_catalog(self.root)
        self.assertEqual(self.errors(), "")
        added.unlink()
        self.assertIn("catalog drift", self.errors())

    def test_catalog_update_preserves_surrounding_text_and_is_idempotent(self):
        path = self.root / instructions.CATALOG
        first = path.read_text()
        instructions.write_catalog(self.root)
        self.assertEqual(path.read_text(), first)
        self.assertTrue(first.startswith("Before\n"))
        self.assertTrue(first.endswith("\nAfter\n"))

    def test_invalid_catalog_markers_never_overwrite_document(self):
        for text in ("No markers", instructions.END + instructions.START,
                     instructions.START + instructions.START + instructions.END):
            path = self.write(instructions.CATALOG, text)
            self.assertIn("catalog markers", self.errors())
            with self.assertRaises(ValueError):
                instructions.write_catalog(self.root)
            self.assertEqual(path.read_text(), text)

    def test_generated_artifacts_are_not_instruction_sources(self):
        self.write(".derivedData/temporary/AGENTS.md", "Use SwiftUI first.\n")
        self.assertEqual(self.errors(), "")
