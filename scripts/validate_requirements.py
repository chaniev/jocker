#!/usr/bin/env python3
"""Validate the product requirements registry and active backlog traceability."""

from __future__ import annotations

import argparse
import re
import os
from urllib.parse import unquote
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REQUIREMENTS_DIR = ROOT / "docs" / "requirements"
ACTIVE_TASK_DIRS = {
    "tasks-ready": ROOT / "backlog" / "tasks-ready",
    "risky": ROOT / "backlog" / "risky",
    "needs-clarification": ROOT / "backlog" / "needs-clarification",
    "implementation": ROOT / "backlog" / "implementation",
}
ALLOWED_DOMAINS = {"SAVE", "HIST", "UI", "TRAIN", "ONLINE", "RULE", "BOT", "NFR"}
ALLOWED_DECISIONS = {"предложено", "принято", "отклонено"}
ALLOWED_IMPLEMENTATION_STATES = {"не начато", "частично", "реализовано"}
ALLOWED_RELATIONS = {"implements", "changes", "constrains", "verifies"}
CARD_HEADING = re.compile(r"^### (REQ-([A-Z]+)-(\d{3}))\. .+$", re.MULTILINE)
REQ_TOKEN = re.compile(r"REQ-[A-Z]+-\d{3}")
TASK_REQUIREMENT = re.compile(
    r"^- (REQ-[A-Z]+-\d{3}) — (implements|changes|constrains|verifies)$"
)


@dataclass(frozen=True)
class Requirement:
    identifier: str
    decision: str
    implementation: str
    path: Path
    body: str


def relative(path: Path) -> str:
    try:
        return path.resolve().relative_to(ROOT.resolve()).as_posix()
    except ValueError:
        return str(path)


def field_values(body: str, label: str) -> list[str]:
    return re.findall(rf"^\*\*{re.escape(label)}:\*\* (.+)$", body, re.MULTILINE)


def section_body(text: str, heading: str) -> str | None:
    match = re.search(
        rf"^## {re.escape(heading)}\s*$\n(.*?)(?=^## |\Z)",
        text,
        re.MULTILINE | re.DOTALL,
    )
    return match.group(1).strip() if match else None


def parse_registry(errors: list[str]) -> dict[str, Requirement]:
    requirements: dict[str, Requirement] = {}

    for path in sorted(REQUIREMENTS_DIR.glob("[0-9][0-9]-*.md")):
        text = path.read_text(encoding="utf-8")
        matches = list(CARD_HEADING.finditer(text))
        for heading in re.findall(r"^### REQ-.*$", text, re.MULTILINE):
            if not CARD_HEADING.fullmatch(heading):
                errors.append(f"{relative(path)}: malformed requirement heading: {heading}")
        for index, match in enumerate(matches):
            identifier, domain, number = match.groups()
            end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
            body = text[match.start() : end]
            location = f"{relative(path)}:{text[: match.start()].count(chr(10)) + 1}"

            if identifier in requirements:
                errors.append(f"{location}: duplicate requirement ID {identifier}")
                continue
            if domain not in ALLOWED_DOMAINS:
                errors.append(f"{location}: unknown requirement domain {domain}")
            if len(number) != 3 or int(number) == 0:
                errors.append(f"{location}: requirement number must have three digits")

            decisions = field_values(body, "Решение")
            implementations = field_values(body, "Реализация")
            if len(decisions) != 1 or decisions[0] not in ALLOWED_DECISIONS:
                errors.append(f"{location}: expected one valid **Решение:** field")
            if (
                len(implementations) != 1
                or implementations[0] not in ALLOWED_IMPLEMENTATION_STATES
            ):
                errors.append(f"{location}: expected one valid **Реализация:** field")
            for required_label in (
                "**Границы и ограничения:**",
                "**Связанные требования:**",
                "**Изменения:**",
            ):
                if body.count(required_label) != 1:
                    errors.append(f"{location}: expected one {required_label} section")
            if "**Статус:**" in body:
                errors.append(f"{location}: legacy **Статус:** field is not allowed")

            change_section = body.split("**Изменения:**", 1)[-1]
            linked_change = False
            for change_line in re.findall(r"^- \d{2}\.\d{2}\.\d{4}.+$", change_section, re.MULTILINE):
                link_match = re.search(r"\[[^\]]+\]\(([^)]+)\)", change_line)
                if link_match:
                    linked_change = True
                    link_target = link_match.group(1).split("#", 1)[0]
                    if (
                        link_target
                        and not re.match(r"^[a-z]+://", link_target)
                        and not (path.parent / link_target).resolve().exists()
                    ):
                        errors.append(
                            f"{location}: change link target does not exist: {link_target}"
                        )
                    continue
                errors.append(f"{location}: change entry must contain a Markdown task/plan link: {change_line}")
            if not linked_change:
                errors.append(f"{location}: no linked change evidence")

            requirements[identifier] = Requirement(
                identifier=identifier,
                decision=decisions[0] if len(decisions) == 1 else "",
                implementation=implementations[0] if len(implementations) == 1 else "",
                path=path,
                body=body,
            )

    if not requirements:
        errors.append("docs/requirements: no requirement cards found")
    return requirements


def validate_requirement_references(
    requirements: dict[str, Requirement], errors: list[str]
) -> None:
    known = set(requirements)
    for requirement in requirements.values():
        for referenced in REQ_TOKEN.findall(requirement.body):
            if referenced != requirement.identifier and referenced not in known:
                errors.append(
                    f"{relative(requirement.path)}: {requirement.identifier} references unknown {referenced}"
                )



def validate_task_requirements(
    path: Path,
    status_dir: str,
    requirements: dict[str, Requirement],
    errors: list[str],
) -> None:
    text = path.read_text(encoding="utf-8")
    statuses = re.findall(r"^- Статус: (.+)$", text, re.MULTILINE)
    if statuses != [status_dir]:
        errors.append(f"{relative(path)}: status must match directory {status_dir}")
    validate_links(path, errors)
    section = section_body(text, "Requirements")
    label = relative(path)
    if section is None:
        errors.append(f"{label}: missing ## Requirements")
        return

    entries = [line.strip() for line in section.splitlines() if line.strip()]
    if not entries:
        errors.append(f"{label}: empty ## Requirements")
        return

    has_none = any(line.startswith("- none — ") for line in entries)
    has_pending = any(line.startswith("- pending — ") for line in entries)
    req_entries = [line for line in entries if line.startswith("- REQ-")]
    if sum((has_none, has_pending, bool(req_entries))) != 1:
        errors.append(f"{label}: do not mix REQ-*, none, and pending metadata")

    if has_none:
        if len(entries) != 1 or len(entries[0].partition(" — ")[2].strip()) < 12:
            errors.append(f"{label}: none requires one concrete behavior-preserving reason")
        return

    if has_pending:
        if status_dir != "needs-clarification":
            errors.append(f"{label}: pending is allowed only in needs-clarification")
        if len(entries) != 1 or len(entries[0].partition(" — ")[2].strip()) < 12:
            errors.append(f"{label}: pending requires one concrete missing decision")
        return

    for entry in entries:
        match = TASK_REQUIREMENT.fullmatch(entry)
        if not match:
            errors.append(
                f"{label}: invalid requirement entry; expected 'REQ-ID — implements|changes|constrains|verifies': {entry}"
            )
            continue
        identifier, relation = match.groups()
        if relation not in ALLOWED_RELATIONS:
            errors.append(f"{label}: invalid relation {relation}")
        requirement = requirements.get(identifier)
        if requirement is None:
            errors.append(f"{label}: references unknown {identifier}")
        elif status_dir in {"tasks-ready", "risky", "implementation"} and requirement.decision != "принято":
            errors.append(
                f"{label}: {identifier} decision is {requirement.decision!r}, expected 'принято'"
            )
        elif relation == "implements" and requirement.implementation == "реализовано":
            errors.append(
                f"{label}: {identifier} is already marked implemented; use verifies/changes or correct the card"
            )
        elif (
            status_dir == "implementation"
            and relation == "changes"
            and requirement.implementation == "реализовано"
        ):
            errors.append(
                f"{label}: {identifier} target revision must be recorded as not started/partial before implementation"
            )


def validate_links(path: Path, errors: list[str]) -> None:
    for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", path.read_text(encoding="utf-8")):
        target = unquote(target.strip("<>").split("#", 1)[0])
        if not target or re.match(r"^[a-z]+://", target):
            continue
        resolved = ROOT / target.lstrip("/") if target.startswith("/") else path.parent / target
        if not resolved.exists():
            errors.append(f"{relative(path)}: link target does not exist: {target}")


def validate_active_backlog(
    requirements: dict[str, Requirement], errors: list[str]
) -> tuple[int, int]:
    tasks: dict[Path, str] = {}
    identifiers: dict[str, Path] = {}
    for path in sorted((ROOT / "backlog").rglob("*.md")):
        match = re.match(r"((?:PROD|TASK)-\d{3})-", path.name)
        if not match or path.name.endswith(".plan.md"):
            continue
        identifier = match[1]
        if identifier in identifiers:
            errors.append(f"{relative(path)}: duplicate task ID {identifier}")
        identifiers[identifier] = path
        folder = path.parent.name
        if folder in ACTIVE_TASK_DIRS:
            tasks[path.resolve()] = folder
            validate_task_requirements(path, folder, requirements, errors)
        elif "done" not in path.relative_to(ROOT / "backlog").parts:
            errors.append(f"{relative(path)}: task is outside a status directory")
        else:
            parts = path.relative_to(ROOT / "backlog").parts
            if len(parts) != 3 or parts[0] != "done" or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", parts[1]):
                errors.append(f"{relative(path)}: done task needs a dated directory")
            text = path.read_text(encoding="utf-8")
            if re.findall(r"^- Статус: (.+)$", text, re.MULTILINE) != ["done"]:
                errors.append(f"{relative(path)}: completed task status must be done")
            for key in ("completed_at", "completion_date_evidence"):
                if not re.search(rf"^- {key}: .+", text, re.MULTILINE):
                    errors.append(f"{relative(path)}: missing {key}")
            validate_links(path, errors)

    plan_count = 0
    plans_by_task: dict[Path, list[tuple[Path, bool]]] = {}
    for path in sorted((ROOT / "backlog").rglob("*.plan.md")):
        archived = "done" in path.relative_to(ROOT / "backlog").parts
        if not archived:
            plan_count += 1
        if not archived and path.parent.name != "implementation-plans":
            errors.append(f"{relative(path)}: unfinished plan belongs in implementation-plans")
        text = path.read_text(encoding="utf-8")
        validate_links(path, errors)
        def metadata(key: str) -> str:
            values = re.findall(rf"^- {key}: (.+)$", text, re.MULTILINE)
            if len(values) != 1:
                errors.append(f"{relative(path)}: expected one {key} metadata field")
                return ""
            return values[0].strip()
        readiness = metadata("readiness")
        if readiness not in {"yes", "no"}:
            errors.append(f"{relative(path)}: readiness must be yes or no")
        ready = readiness == "yes"
        branch = metadata("branch")
        if not re.fullmatch(r"(?:codex|feature|fix|refactor)/[A-Za-z0-9][A-Za-z0-9._/-]*", branch) or ".." in branch:
            errors.append(f"{relative(path)}: invalid task branch")
        source = metadata("source_task")
        source_match = re.fullmatch(r"\[[^\]]+\]\(([^)]+)\)", source)
        task = None
        if source_match:
            target = unquote(source_match[1])
            task = (ROOT / target.lstrip("/") if target.startswith("/") else path.parent / target).resolve()
        if task is None or not task.is_file():
            errors.append(f"{relative(path)}: source_task must link to an existing card")
            task = None
        elif archived:
            if task.parent != path.parent.resolve():
                errors.append(f"{relative(path)}: completed task and plan must be colocated")
        elif task not in tasks:
            errors.append(f"{relative(path)}: source_task must be an active card")
        if task is not None:
            plans_by_task.setdefault(task, []).append((path, ready))

        value = metadata("requirements")
        entries = value.split(", ")
        relations = []
        if value.startswith(("none — ", "pending — ")):
            if len(value.partition(" — ")[2].strip()) < 12:
                errors.append(f"{relative(path)}: none/pending needs a concrete reason")
            if value.startswith("pending") and (ready or task not in tasks or tasks[task] != "needs-clarification"):
                errors.append(f"{relative(path)}: pending requires a non-ready clarification task")
            relations = ["- " + value]
        else:
            for entry in entries:
                match = re.fullmatch(r"(REQ-[A-Z]+-\d{3}) \((implements|changes|constrains|verifies)\)", entry)
                if not match:
                    errors.append(f"{relative(path)}: invalid requirements metadata: {entry}")
                    continue
                identifier, relation = match.groups()
                relations.append(f"- {identifier} — {relation}")
                requirement = requirements.get(identifier)
                if requirement is None:
                    errors.append(f"{relative(path)}: references unknown {identifier}")
                elif ready and not archived and requirement.decision != "принято":
                    errors.append(f"{relative(path)}: {identifier} is not accepted")
        if task is not None and not archived:
            task_section = section_body(task.read_text(encoding="utf-8"), "Requirements") or ""
            if sorted(relations) != sorted(line.strip() for line in task_section.splitlines() if line.strip()):
                errors.append(f"{relative(path)}: requirements differ from source task")
        if ready and not archived:
            if section_body(text, "Открытые вопросы") != "none":
                errors.append(f"{relative(path)}: ready plan must have no open questions")
            if not section_body(text, "Решения и evidence"):
                errors.append(f"{relative(path)}: ready plan lacks decision evidence")
            if task in tasks and tasks[task] == "needs-clarification":
                errors.append(f"{relative(path)}: ready plan cannot have a clarification task")
    for task, plans in plans_by_task.items():
        if len(plans) > 1:
            errors.append(f"{relative(task)}: duplicate plans")
    for task, status in tasks.items():
        if status == "implementation":
            plans = plans_by_task.get(task, [])
            if len(plans) != 1 or not plans[0][1]:
                errors.append(f"{relative(task)}: implementation requires exactly one ready plan")
    return len(tasks), plan_count


def validate_diff(base: str | None, errors: list[str]) -> None:
    if not base:
        return
    try:
        ancestor = subprocess.check_output(
            ["git", "merge-base", base, "HEAD"], cwd=ROOT, text=True, stderr=subprocess.PIPE
        ).strip()
        changed = set(filter(None, subprocess.check_output(
            ["git", "diff", "--name-only", "-z", "--no-renames", ancestor, "--"], cwd=ROOT
        ).decode().split("\0")))
        changed.update(filter(None, subprocess.check_output(
            ["git", "ls-files", "--others", "--exclude-standard", "-z"], cwd=ROOT
        ).decode().split("\0")))
    except subprocess.CalledProcessError as error:
        errors.append(f"git diff against {base} failed: {error}")
        return
    domain_change = any(
        re.fullmatch(r"docs/requirements/\d{2}-.+\.md", path) for path in changed
    )
    if domain_change and "docs/requirements/CHANGELOG.md" not in changed:
        errors.append(
            "docs/requirements/CHANGELOG.md must change with requirement domain files"
        )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--base",
        default=os.environ.get("HARNESS_BASE"),
        help="optional Git base SHA/ref used to enforce requirements/CHANGELOG co-change",
    )
    args = parser.parse_args()

    errors: list[str] = []
    requirements = parse_registry(errors)
    validate_requirement_references(requirements, errors)
    task_count, plan_count = validate_active_backlog(requirements, errors)
    for path in REQUIREMENTS_DIR.glob("*.md"):
        if not path.name.startswith("_"):
            validate_links(path, errors)
    validate_links(ROOT / "backlog" / "README.md", errors)
    validate_diff(args.base, errors)

    if errors:
        print("Requirements validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        f"Requirements validation passed: {len(requirements)} cards, "
        f"{task_count} active tasks, {plan_count} active plans."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
