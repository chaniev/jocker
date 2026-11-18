"""Bounded instruction checks and a catalog generated from repository metadata.

This is not a semantic policy evaluator. It checks known affirmative stack
conflicts, local instruction links, required entry points and catalog drift.
Only the scalar/triple-quoted profile format used by .codex/agents is accepted.
"""
import argparse
import ast
import os
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[2]
CATALOG = "docs/AGENTS_SKILLS_HARNESS.md"
START = "<!-- instruction-catalog:start -->"
END = "<!-- instruction-catalog:end -->"
REQUIRED = (
    "AGENTS.md", "FOLDER_STRUCTURE_SPEC.md", CATALOG,
    "Jocker/Jocker/AGENTS.md", "Jocker/JockerTests/AGENTS.md",
    "Jocker/JockerUITests/AGENTS.md", "backlog/AGENTS.md",
    "backlog/README.md", "docs/requirements/README.md",
    ".cursor/rules/swift.mdc", ".cursor/rules/file.mdc",
)
NAME = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")
CONFLICT = re.compile(
    r"\b(?:use|prefer|adopt|introduce)\s+(?:MVVM\s+architecture\s+with\s+)?"
    r"(?:SwiftUI|Combine|async/await)\b|\bSwiftUI[- ]first\b|"
    r"\busing Swift and SwiftUI\b|@(?:Published|StateObject)\b", re.I)
NEGATION = re.compile(r"\b(?:no|not|never|without|avoid|forbid|forbidden)\b|запрещ|\bне\s", re.I)
LINK = re.compile(r"\[[^\]\n]+\]\((<[^>\n]+>|[^)\s]+)(?:\s+\"[^\"]*\")?\)")


def prose(text):
    """Ignore fenced examples; their placeholders are not live dependencies."""
    return re.sub(r"^\s*(`{3,}|~{3,})[^\n]*\n.*?^\s*\1\s*$", "", text,
                  flags=re.M | re.S)


def skill_metadata(path):
    text = path.read_text()
    header = re.match(r"\A---\n(.*?)\n---(?:\n|$)", text, re.S)
    if not header:
        raise ValueError("missing skill frontmatter")
    result = {}
    for field in ("name", "description"):
        values = re.findall(r"^" + field + r":\s*(.+)$", header[1], re.M)
        if len(values) != 1:
            raise ValueError("expected one " + field)
        value = values[0].strip()
        if value.startswith(('"', "'")):
            value = ast.literal_eval(value)
        if not isinstance(value, str) or not value.strip() or value in ("|", ">"):
            raise ValueError("expected nonempty single-line " + field)
        result[field] = value
    if result["name"] != path.parent.name or not NAME.fullmatch(result["name"]):
        raise ValueError("skill name must match its directory")
    return result


def agent_metadata(path):
    text = path.read_text()
    result = {}
    # Explicitly validate the repository's simple profile schema without a TOML
    # dependency (the harness supports the system Python, including Python 3.9).
    pattern = re.compile(r'^([a-z_]+)\s*=\s*(""".*?"""|"(?:[^"\\\n]|\\.)*")\s*$', re.M | re.S)
    for match in pattern.finditer(text):
        key, value = match.groups()
        if key in result:
            raise ValueError("duplicate agent field " + key)
        result[key] = value[3:-3] if value.startswith('"""') else ast.literal_eval(value)
    remainder = pattern.sub("", text)
    if any(line.strip() and not line.lstrip().startswith("#") for line in remainder.splitlines()):
        raise ValueError("unsupported or malformed agent metadata")
    for key in ("name", "description", "model", "model_reasoning_effort", "sandbox_mode", "developer_instructions"):
        if not result.get(key, "").strip():
            raise ValueError("missing agent field " + key)
    if result["name"] != path.stem or not NAME.fullmatch(result["name"]):
        raise ValueError("agent name must match its file")
    return result


def inventory(root):
    records, errors = {"skills": [], "agents": []}, []
    for kind, pattern, reader in (
        ("skills", ".agents/skills/*/SKILL.md", skill_metadata),
        ("agents", ".codex/agents/*.toml", agent_metadata),
    ):
        paths = sorted(root.glob(pattern))
        if not paths:
            errors.append("Missing instruction inventory: " + pattern)
        for path in paths:
            try:
                metadata = reader(path)
                records[kind].append({**metadata, "path": path.relative_to(root).as_posix()})
            except (OSError, ValueError, SyntaxError) as error:
                errors.append(str(path.relative_to(root)) + ": " + str(error))
    return records, errors


def render_catalog(records):
    lines = [START, "", "Навыки: " + str(len(records["skills"])) + ". Агенты: " + str(len(records["agents"])) + "."]
    for kind, title in (("skills", "Навык"), ("agents", "Профиль агента")):
        lines += ["", "| " + title + " | Когда использовать |", "|---|---|"]
        for record in records[kind]:
            description = record["description"].replace("|", "\\|")
            lines.append("| [" + record["name"] + "](../" + record["path"] + ") | " + description + " |")
    return "\n".join(lines + ["", END])


def source_paths(root):
    paths = {root / path for path in REQUIRED}
    for directory, subdirectories, files in os.walk(root):
        subdirectories[:] = [name for name in subdirectories if name not in (".git", ".derivedData")]
        if "AGENTS.md" in files:
            paths.add(Path(directory) / "AGENTS.md")
    for pattern in (".agents/skills/**/*.md", ".codex/agents/*.toml", ".cursor/rules/*.mdc"):
        paths.update(root.glob(pattern))
    return sorted(path for path in paths if path.is_file())


def check_sources(root):
    errors = ["Missing " + path for path in REQUIRED if not (root / path).is_file()]
    for path in source_paths(root):
        label = path.relative_to(root).as_posix()
        content = prose(path.read_text())
        for line in content.splitlines():
            # Match known affirmative clauses, not prohibitions or the explicit
            # training-target concurrency exception. Report the clause for repair.
            for clause in re.split(r"[.;]", line):
                for match in CONFLICT.finditer(clause):
                    prefix = clause[:match.start()]
                    if NEGATION.search(prefix):
                        continue
                    if match[0].lower().endswith("async/await") and re.search(r"training[- ](?:only|target)", clause, re.I):
                        continue
                    errors.append(f"{label}: known stack conflict: {clause.strip()}")
        for match in LINK.finditer(content):
            target = unquote(match[1].strip("<>"))
            parsed = urlsplit(target)
            if parsed.scheme or parsed.netloc or not parsed.path:
                continue
            resolved = root / parsed.path.lstrip("/") if parsed.path.startswith("/") else path.parent / parsed.path
            if not resolved.exists():
                errors.append(f"{label}: missing local link: {target}")
        # Profiles/skills historically use root-relative instruction paths in
        # backticks. Validate these too, excluding templates and glob patterns.
        for target in re.findall(r"`([^`\n]+)`", content):
            if any(char in target for char in "<>* "):
                continue
            if (target.startswith((".agents/", ".codex/")) and target.endswith(("SKILL.md", ".toml"))) or target in ("AGENTS.md", "FOLDER_STRUCTURE_SPEC.md"):
                if not (root / target).is_file():
                    errors.append(f"{label}: missing instruction reference: {target}")
    return errors


def check(root):
    records, errors = inventory(root)
    errors += check_sources(root)
    path = root / CATALOG
    if path.is_file():
        text = path.read_text()
        if text.count(START) != 1 or text.count(END) != 1 or text.index(START) >= text.index(END):
            errors.append(CATALOG + ": missing or invalid generated catalog markers")
        elif text[text.index(START):text.index(END) + len(END)] != render_catalog(records):
            errors.append(CATALOG + ": catalog drift; run python3 scripts/harness/instructions.py catalog --write")
    return errors


def write_catalog(root):
    records, errors = inventory(root)
    if errors:
        raise ValueError("\n".join(errors))
    path = root / CATALOG
    text = path.read_text()
    if text.count(START) != 1 or text.count(END) != 1 or text.index(START) >= text.index(END):
        raise ValueError("Expected exactly one ordered catalog marker pair; no file was changed")
    updated = text[:text.index(START)] + render_catalog(records) + text[text.index(END) + len(END):]
    if updated != text:
        path.write_text(updated)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["check", "catalog"], nargs="?", default="check")
    parser.add_argument("--write", action="store_true", help="Update only the marked catalog section")
    args = parser.parse_args()
    if args.mode == "catalog":
        if args.write:
            write_catalog(ROOT)
        else:
            records, errors = inventory(ROOT)
            if errors:
                raise ValueError("\n".join(errors))
            print(render_catalog(records))
        return 0
    if args.write:
        parser.error("--write requires catalog mode")
    errors = check(ROOT)
    print("\n".join(errors) if errors else "Instruction checks passed (sources, known stack conflicts, metadata, links and catalog).")
    return bool(errors)


if __name__ == "__main__":
    raise SystemExit(main())
