#!/usr/bin/env python3
"""Repository verification; Python standard library only. No shell evaluation."""
import argparse
import datetime
import fnmatch
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parents[2]


def git(root, *args):
    return subprocess.check_output(["git", *args], cwd=root)


def snapshot(root, base):
    resolved = git(root, "rev-parse", "--verify", base + "^{commit}").decode().strip()
    ancestor = git(root, "merge-base", resolved, "HEAD").decode().strip()
    # No rename detection: both the removed and added path must be routed.
    paths = set(filter(None, git(root, "diff", "--name-only", "-z", "--no-renames", ancestor, "--").decode().split("\0")))
    paths.update(filter(None, git(root, "ls-files", "--others", "--exclude-standard", "-z").decode().split("\0")))
    digest = hashlib.sha256()
    for path in sorted(paths):
        target = root / path
        digest.update(path.encode() + b"\0")
        if target.is_symlink():
            digest.update(b"symlink:" + os.readlink(target).encode())
        elif target.is_file():
            digest.update(str(target.stat().st_mode).encode() + b":" + target.read_bytes())
        else:
            digest.update(b"deleted")
    head = git(root, "rev-parse", "HEAD").decode().strip()
    # Include staged changes even when worktree content has been restored.
    digest.update(git(root, "diff", "--cached", "--binary", "--no-ext-diff", "--"))
    digest.update(head.encode() + ancestor.encode())
    return {"head": head, "base": resolved, "mergeBase": ancestor,
            "fingerprint": digest.hexdigest(), "paths": sorted(paths)}


def select_checks(paths, config, ci=False):
    reasons = {"instructions": ["always"], "harness-tests": ["always"]}
    for path in paths:
        matches = [r for r in config["rules"] if any(fnmatch.fnmatchcase(path, p) for p in r["patterns"])]
        checks = set(c for r in matches for c in r["checks"]) if matches else set(config["fallback"])
        for check in sorted(checks):
            reasons.setdefault(check, []).append(path)
    if ci:
        for check in config["ci"]:
            reasons.setdefault(check, []).append("CI mandatory")
    return reasons


def instructions(root):
    errors = []
    required = ["AGENTS.md", "FOLDER_STRUCTURE_SPEC.md", "docs/AGENTS_SKILLS_HARNESS.md"]
    for path in required:
        if not (root / path).is_file():
            errors.append("Missing " + path)
    app_rules = (root / "Jocker/Jocker/AGENTS.md").read_text()
    for stale in ("Prefer SwiftUI", "Use MVVM architecture with SwiftUI", "Use Combine for reactive code", "Use async/await for concurrency"):
        if stale in app_rules:
            errors.append("Stale app instruction: " + stale)
    names = set()
    for skill in sorted((root / ".agents/skills").glob("*/SKILL.md")):
        content = skill.read_text()
        header = content.split("---", 2)
        if len(header) != 3 or header[0].strip():
            errors.append("Missing frontmatter: " + str(skill.relative_to(root)))
            continue
        fields = dict(line.split(":", 1) for line in header[1].splitlines() if ":" in line)
        name = fields.get("name", "").strip().strip('"')
        if not name or name != skill.parent.name or name in names or not fields.get("description", "").strip():
            errors.append("Invalid skill metadata: " + str(skill.relative_to(root)))
        names.add(name)
    print("\n".join(errors) if errors else "Instruction checks passed (known stack conflicts and skill metadata).")
    return 1 if errors else 0


def execute(command, root, log, timeout):
    with log.open("w") as output:
        try:
            process = subprocess.Popen(command, cwd=root, stdout=output, stderr=subprocess.STDOUT, start_new_session=True)
        except OSError as error:
            output.write(str(error))
            return {"status": "blocked", "exitCode": None, "error": str(error)}
        try:
            code = process.wait(timeout=timeout)
            return {"status": "passed" if code == 0 else "failed", "exitCode": code}
        except (subprocess.TimeoutExpired, KeyboardInterrupt) as error:
            import signal
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            return {"status": "blocked", "exitCode": process.returncode, "error": type(error).__name__}


def write_report(path, report):
    temp = path.with_suffix(".tmp")
    temp.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
    temp.replace(path)


def run(root, mode, base, destination, timeout):
    if mode == "plan":
        config = json.loads((root / "scripts/harness/checks.json").read_text())
        state = snapshot(root, base)
        print(json.dumps({"state": state, "checks": select_checks(state["paths"], config)}, indent=2, ensure_ascii=False))
        return 0
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d-%H%M%S")
    directory = root / ".derivedData/harness-runs" / (stamp + "-" + uuid.uuid4().hex[:8])
    directory.mkdir(parents=True)
    report_path = directory / "summary.json"
    report = {"schemaVersion": 1, "status": "blocked", "mode": mode,
              "startedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
              "destination": destination, "checks": []}
    write_report(report_path, report)
    print("Harness report: " + str(report_path), flush=True)
    try:
        config = json.loads((root / "scripts/harness/checks.json").read_text())
        report["tools"] = {"python": sys.version, "platform": sys.platform}
        for tool, command in [("git", ["git", "--version"]), ("xcode", ["xcodebuild", "-version"])]:
            try:
                probe = subprocess.run(command, cwd=root, capture_output=True, text=True, timeout=15)
                report["tools"][tool] = {"exitCode": probe.returncode, "output": probe.stdout + probe.stderr}
            except (OSError, subprocess.TimeoutExpired) as error:
                report["tools"][tool] = {"error": str(error)}
        state = snapshot(root, base)
        report["state"] = state
        selected = select_checks(state["paths"], config, ci=mode == "ci")
        for name, reasons in selected.items():
            command = list(config["checks"][name])
            if name in ("full-tests", "joker", "phase", "ranking", "training-smoke"):
                command += ["--output-root", str(directory / name)]
            if name in ("full-tests", "joker", "phase", "ranking"):
                command += ["--destination", destination, "--derived-data-path", str(directory / "build")]
            report["checks"].append({"name": name, "reasons": reasons, "command": command, "status": "blocked", "exitCode": None})
        write_report(report_path, report)
        for check in report["checks"]:
            log = directory / (check["name"] + ".log")
            print("Running " + check["name"], flush=True)
            check["log"] = str(log)
            check.update(execute(check["command"], root, log, timeout))
            write_report(report_path, report)
            print(check["name"] + ": " + check["status"], flush=True)
        report["finalState"] = snapshot(root, base)
        report["stale"] = report["state"] != report["finalState"]
        statuses = [c["status"] for c in report["checks"]]
        report["status"] = "blocked" if report["stale"] or "blocked" in statuses else ("failed" if "failed" in statuses else "passed")
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        report["error"] = str(error)
        report["status"] = "blocked"
    finally:
        report["finishedAt"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
        write_report(report_path, report)
    print("Harness: " + report["status"], flush=True)
    return 0 if report["status"] == "passed" else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["plan", "verify", "ci", "instructions"])
    parser.add_argument("--base", default="HEAD")
    parser.add_argument("--destination", default="platform=iOS Simulator")
    parser.add_argument("--timeout", type=int, default=1800, help="Seconds per check")
    args = parser.parse_args()
    if args.mode == "instructions":
        return instructions(ROOT)
    return run(ROOT, args.mode, args.base, args.destination, args.timeout)


if __name__ == "__main__":
    sys.exit(main())
