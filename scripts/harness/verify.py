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
import time

from planning import build_plan
from environment import doctor
from results import collect_results

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
        selected = select_checks(state["paths"], config)
        print(json.dumps({"state": state, "requestedChecks": selected,
                          "plan": build_plan(root, selected, config)}, indent=2, ensure_ascii=False))
        return 0
    started = time.monotonic()
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d-%H%M%S")
    directory = root / ".derivedData/harness-runs" / (stamp + "-" + uuid.uuid4().hex[:8])
    directory.mkdir(parents=True)
    report_path = directory / "summary.json"
    report = {"schemaVersion": 2, "status": "blocked", "mode": mode,
              "startedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
              "requestedDestination": destination, "checks": [],
              "tools": {"python": sys.version, "platform": sys.platform}}
    write_report(report_path, report)
    print("Harness report: " + str(report_path), flush=True)
    try:
        if mode == "doctor":
            report["environment"] = doctor(root, destination)
            report["status"] = report["environment"]["status"]
        else:
            config = json.loads((root / "scripts/harness/checks.json").read_text())
            state = snapshot(root, base)
            report["state"] = state
            selected = select_checks(state["paths"], config, ci=mode == "ci")
            plan = build_plan(root, selected, config)
            report["plan"] = plan
            report["requestedChecks"] = selected
            needs_simulator = any(c["kind"] == "xctest" for c in plan["checks"])
            needs_environment = any(c["kind"] in ("xctest", "training") for c in plan["checks"])
            for item in plan["checks"]:
                if item["kind"] in ("xctest", "training") and needs_environment:
                    report["checks"].append({"name": "doctor", "kind": "doctor", "status": "blocked", "exitCode": None})
                    needs_environment = False
                report["checks"].append({**item, "command": list(item["command"]), "status": "blocked", "exitCode": None})
            write_report(report_path, report)
            for check in report["checks"]:
                check_started = time.monotonic()
                check["startedAt"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
                print("Running " + check["name"], flush=True)
                if check["kind"] == "doctor":
                    report["environment"] = doctor(root, destination, needs_simulator)
                    check["status"] = report["environment"]["status"]
                    check["exitCode"] = 0 if check["status"] == "passed" else None
                    destination = report["environment"].get("resolvedDestination", destination)
                elif check["kind"] in ("xctest", "training") and report["environment"]["status"] != "passed":
                    check["error"] = "Environment preflight blocked execution"
                else:
                    artifacts = directory / check["name"]
                    if check["kind"] in ("xctest", "training"):
                        check["command"] += ["--output-root", str(artifacts)]
                    if check["kind"] == "xctest":
                        check["command"] += ["--destination", destination, "--derived-data-path", str(directory / "build")]
                        for selector in check["selectors"]:
                            check["command"] += ["--only-testing", selector]
                    check["log"] = str(directory / (check["name"] + ".log"))
                    write_report(report_path, report)
                    check.update(execute(check["command"], root, Path(check["log"]), timeout))
                    if check["kind"] == "xctest":
                        required = sorted(set(check["selectors"] + [s for values in plan["packSelectors"].values() for s in values]))
                        if check["name"] == "full-tests":
                            required += report["environment"]["testTargets"]
                        try:
                            check["testResults"] = collect_results(root, artifacts, required)
                            results = check["testResults"]
                            if results["total"] == 0 or results["missingSelectors"] or results["duplicateTests"]:
                                check.update(status="blocked", error="Incomplete or duplicated XCTest execution; see testResults")
                            elif results["failed"] or results["result"] == "Failed":
                                check["status"] = "failed"
                        except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
                            check["resultsError"] = str(error)
                            if check["status"] == "passed":
                                check["status"] = "blocked"
                check["durationSeconds"] = time.monotonic() - check_started
                check["finishedAt"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
                write_report(report_path, report)
                print(check["name"] + ": " + check["status"], flush=True)
                if check.get("error") == "KeyboardInterrupt":
                    break
            report["finalState"] = snapshot(root, base)
            report["stale"] = report["state"] != report["finalState"]
            statuses = [c["status"] for c in report["checks"]]
            report["status"] = "blocked" if report["stale"] or "blocked" in statuses else ("failed" if "failed" in statuses else "passed")
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        report["error"] = str(error)
        report["status"] = "blocked"
    finally:
        report["durationSeconds"] = time.monotonic() - started
        report["finishedAt"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
        write_report(report_path, report)
    print("Harness: " + report["status"], flush=True)
    return 0 if report["status"] == "passed" else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["plan", "verify", "ci", "doctor", "instructions"])
    parser.add_argument("--base", default="HEAD")
    parser.add_argument("--destination", default="platform=iOS Simulator")
    parser.add_argument("--timeout", type=int, default=1800, help="Seconds per check")
    args = parser.parse_args()
    if args.mode == "instructions":
        return instructions(ROOT)
    return run(ROOT, args.mode, args.base, args.destination, args.timeout)


if __name__ == "__main__":
    sys.exit(main())
