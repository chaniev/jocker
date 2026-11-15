"""Behavioral coverage for the requirements workflow; no app/simulator needed."""
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

MODULE = Path(__file__).resolve().parents[2] / "validate_requirements.py"
spec = importlib.util.spec_from_file_location("requirements_validator", MODULE)
validator = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = validator
spec.loader.exec_module(validator)


class RequirementsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.write("backlog/README.md", "# Backlog\n")
        self.write("docs/requirements/CHANGELOG.md", "# Changes\n")
        self.write("backlog/source.md", "# Decision source\n")
        self.patchers = [patch.object(validator, "ROOT", self.root),
                         patch.object(validator, "REQUIREMENTS_DIR", self.root / "docs/requirements"),
                         patch.object(validator, "ACTIVE_TASK_DIRS", {
                             status: self.root / "backlog" / status
                             for status in ("tasks-ready", "risky", "needs-clarification", "implementation")})]
        for patcher in self.patchers:
            patcher.start()
            self.addCleanup(patcher.stop)
        self.card()

    def write(self, name, text):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path

    def card(self, decision="принято", implementation="не начато"):
        return self.write("docs/requirements/01-ui.md", f"""# UI
### REQ-UI-001. Continue game
**Решение:** {decision}
**Реализация:** {implementation}
Player can continue an interrupted game.
**Границы и ограничения:**
- Only one saved game.
**Связанные требования:** нет
**Изменения:**
- 15.11.2026 — decision [source](../../backlog/source.md).
""")

    def task(self, status="tasks-ready", relation="REQ-UI-001 — implements"):
        return self.write(f"backlog/{status}/PROD-001-continue.md", f"""# PROD-001 Continue
- Статус: {status}
## Requirements
- {relation}
""")

    def plan(self, status="implementation", readiness="yes", relation="REQ-UI-001 (implements)"):
        return self.write("backlog/implementation-plans/PROD-001-continue.plan.md", f"""# Plan
## Metadata
- source_task: [PROD-001](../{status}/PROD-001-continue.md)
- requirements: {relation}
- branch: codex/PROD-001-continue
- readiness: {readiness}
## Решения и evidence
Decision recorded in [source](../source.md).
## Открытые вопросы
none
""")

    def errors(self):
        errors = []
        requirements = validator.parse_registry(errors)
        validator.validate_requirement_references(requirements, errors)
        validator.validate_active_backlog(requirements, errors)
        return errors

    def test_accepted_task_and_implementation_plan_pass(self):
        self.task("implementation")
        self.plan()
        self.assertEqual([], self.errors())

    def test_proposal_does_not_become_ready_or_implementation(self):
        self.card(decision="предложено")
        for status in ("tasks-ready", "risky", "implementation"):
            with self.subTest(status=status):
                task = self.task(status)
                self.assertTrue(any("expected 'принято'" in e for e in self.errors()))
                task.unlink()
        self.task("needs-clarification")
        self.assertEqual([], self.errors())

    def test_pending_only_in_clarification_and_not_mixed_with_ids(self):
        task = self.task(relation="pending — Decide how much progress to preserve")
        self.assertTrue(any("pending is allowed only" in e for e in self.errors()))
        task.unlink()
        task = self.task("needs-clarification", "pending — Decide how much progress to preserve")
        self.assertEqual([], self.errors())
        task.write_text(task.read_text() + "- REQ-UI-001 — implements\n")
        self.assertTrue(any("do not mix" in e for e in self.errors()))

    def test_none_requires_reason(self):
        task = self.task(relation="none — docs")
        self.assertTrue(any("concrete" in e for e in self.errors()))
        task.unlink()
        self.task(relation="none — Reorganize documentation without changing app behavior")
        self.assertEqual([], self.errors())

    def test_implemented_requirement_needs_changes_or_verifies(self):
        self.card(implementation="реализовано")
        task = self.task()
        self.assertTrue(any("already marked implemented" in e for e in self.errors()))
        task.unlink()
        self.task(relation="REQ-UI-001 — verifies")
        self.assertEqual([], self.errors())

    def test_changed_revision_must_be_reset_before_execution(self):
        self.card(implementation="реализовано")
        self.task("implementation", "REQ-UI-001 — changes")
        self.plan(relation="REQ-UI-001 (changes)")
        self.assertTrue(any("target revision" in e for e in self.errors()))
        self.card(implementation="частично")
        self.assertEqual([], self.errors())

    def test_broken_links_unknown_ids_and_duplicate_cards_fail(self):
        self.task(relation="REQ-UI-999 — implements")
        card = self.card()
        self.write("docs/requirements/02-copy.md", card.read_text())
        (self.root / "backlog/source.md").unlink()
        errors = self.errors()
        for expected in ("unknown REQ-UI-999", "duplicate requirement ID", "does not exist"):
            self.assertTrue(any(expected in e for e in errors), errors)

    def test_malformed_card_is_not_silently_skipped(self):
        card = self.card()
        card.write_text(card.read_text().replace("REQ-UI-001.", "REQ-UI-01."))
        self.assertTrue(any("malformed requirement heading" in e for e in self.errors()))

    def test_execution_requires_one_ready_plan_and_matching_relations(self):
        self.task("implementation")
        self.assertTrue(any("exactly one ready plan" in e for e in self.errors()))
        plan = self.plan(readiness="no")
        self.assertTrue(any("exactly one ready plan" in e for e in self.errors()))
        self.plan(relation="REQ-UI-001 (verifies)")
        self.assertTrue(any("differ from source task" in e for e in self.errors()))
        self.plan()
        self.write("backlog/implementation-plans/duplicate.plan.md", plan.read_text())
        self.assertTrue(any("duplicate plans" in e for e in self.errors()))

    def test_ready_plan_checks_decisions_questions_and_metadata(self):
        self.task("implementation")
        plan = self.plan()
        plan.write_text(plan.read_text().replace("## Решения и evidence", "## Notes").replace("\nnone\n", "\nWhich save point?\n").replace("REQ-UI-001 (implements)", "whatever"))
        errors = self.errors()
        for expected in ("no open questions", "decision evidence", "invalid requirements metadata"):
            self.assertTrue(any(expected in e for e in errors), errors)

    def test_draft_can_record_pending_without_authorizing_execution(self):
        self.task("needs-clarification", "pending — Decide how much progress to preserve")
        self.plan("needs-clarification", "no", "pending — Decide how much progress to preserve")
        self.assertEqual([], self.errors())

    def test_status_and_task_id_drift_are_detected(self):
        task = self.task()
        self.write("backlog/risky/PROD-001-duplicate.md", task.read_text())
        errors = self.errors()
        self.assertTrue(any("duplicate task ID" in e for e in errors))
        self.assertTrue(any("status must match" in e for e in errors))

    def test_done_pair_requires_date_evidence_and_colocation(self):
        task = self.task("done/2026-11-16")
        text = task.read_text().replace("Статус: done/2026-11-16", "Статус: done")
        task.write_text(text)
        self.assertTrue(any("missing completed_at" in e for e in self.errors()))
        task.write_text(text + "\n- completed_at: 2026-11-16\n- completion_date_evidence: main integration\n")
        self.assertEqual([], self.errors())

    def test_diff_gate_tracks_untracked_additions_edits_and_deletions(self):
        def git(*args):
            return subprocess.check_output(["git", *args], cwd=self.root, stderr=subprocess.PIPE)
        git("init", "-q")
        git("config", "user.name", "Test")
        git("config", "user.email", "test@example.invalid")
        git("add", ".")
        git("commit", "-qm", "base")
        new = self.write("docs/requirements/02-extra.md", "# Extra")
        errors = []
        validator.validate_diff("HEAD", errors)
        self.assertTrue(any("CHANGELOG" in e for e in errors))
        new.unlink()
        (self.root / "docs/requirements/01-ui.md").unlink()
        errors = []
        validator.validate_diff("HEAD", errors)
        self.assertTrue(any("CHANGELOG" in e for e in errors))
        self.write("docs/requirements/CHANGELOG.md", "# Updated\n")
        errors = []
        validator.validate_diff("HEAD", errors)
        self.assertEqual([], errors)
