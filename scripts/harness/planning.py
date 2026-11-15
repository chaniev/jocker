"""Discover pack selectors from their canonical scripts and schedule XCTest once."""
import re
import subprocess
import xml.etree.ElementTree as ET

PROJECT = "Jocker/Jocker.xcodeproj"
SCHEME = "Jocker"


def scheme_targets(root):
    path = root / PROJECT / "xcshareddata/xcschemes" / (SCHEME + ".xcscheme")
    try:
        scheme = ET.parse(path)
    except ET.ParseError as error:
        raise ValueError("Invalid shared scheme: " + str(error)) from error
    action = scheme.find("TestAction")
    if action is None or action.find("TestPlans") is not None:
        raise ValueError("Harness requires an explicit shared scheme with Testables")
    targets = []
    for testable in action.findall("Testables/TestableReference"):
        if testable.get("skipped") == "YES" or testable.find("SkippedTests") is not None or testable.find("SelectedTests") is not None:
            raise ValueError("Scheme excludes tests; full-suite coverage cannot be assumed")
        targets.append(testable.find("BuildableReference").get("BlueprintName"))
    if not targets:
        raise ValueError("Shared scheme contains no test targets")
    return targets


def pack_selectors(root, command):
    output = subprocess.check_output(command + ["--list"], cwd=root, text=True, timeout=30)
    selectors = sorted(set(re.findall(r"\bJocker(?:UI)?Tests/[A-Za-z0-9_]+(?:/[A-Za-z0-9_]+)?(?=\s|$)", output)))
    if not selectors:
        raise ValueError("Pack returned no test selectors: " + " ".join(command))
    return selectors


def compact_selectors(selectors):
    # A whole test class subsumes each of its methods, regardless of pack order.
    result = []
    for selector in sorted(set(selectors), key=lambda s: (s.count("/"), s)):
        if not any(selector == parent or selector.startswith(parent + "/") for parent in result):
            result.append(selector)
    return result


def group_selectors(root, patterns):
    """Discover module test classes so newly added tests join automatically."""
    selectors = set()
    for pattern in patterns:
        paths = sorted(root.glob(pattern))
        if not paths:
            raise ValueError("Test group pattern matches no files: " + pattern)
        for path in paths:
            target = path.relative_to(root).parts[1]
            if target not in ("JockerTests", "JockerUITests"):
                raise ValueError("Test group points outside test targets: " + str(path))
            classes = re.findall(r"(?m)^\s*(?:final\s+)?class\s+(\w+)\s*:\s*XCTestCase\b", path.read_text())
            selectors.update(target + "/" + name for name in classes)
    if not selectors:
        raise ValueError("Test group contains no XCTestCase classes")
    return sorted(selectors)


def build_plan(root, selected, config):
    pack_names = [name for name in selected if name in config["testPacks"]]
    group_names = [name for name in selected if name in config.get("testGroups", {})]
    has_full = "full-tests" in selected
    coverage = {}
    group_coverage = {}
    all_selectors = []
    checks = []
    for name, reasons in selected.items():
        if name == "full-tests" or name in pack_names or name in group_names:
            continue
        checks.append({"name": name, "reasons": reasons, "command": config["checks"][name],
                       "kind": "training" if name == "training-smoke" else "local"})
    for name in pack_names:
        selectors = pack_selectors(root, config["checks"][name])
        coverage[name] = selectors
        all_selectors.extend(selectors)
        # Keep the shell contract checked even when its tests are covered elsewhere.
        checks.append({"name": name + "-contract", "reasons": selected[name],
                       "command": config["checks"][name] + ["--dry-run"], "kind": "contract"})
    for name in group_names:
        selectors = group_selectors(root, config["testGroups"][name])
        group_coverage[name] = selectors
        all_selectors.extend(selectors)
    if has_full or pack_names or group_names:
        targets = scheme_targets(root)
        if any(s.split("/")[0] not in targets for s in all_selectors):
            raise ValueError("Pack includes a target absent from the shared scheme")
        name = "full-tests" if has_full else "selected-tests"
        checks.append({"name": name, "kind": "xctest", "reasons": list(selected.get("full-tests", [])) + pack_names + group_names,
                       "command": config["checks"]["full-tests"],
                       "selectors": [] if has_full else compact_selectors(all_selectors),
                       "covers": (["full-tests"] if has_full else []) + pack_names + group_names})
    # Cheap contracts first, one XCTest invocation, then training (including after test failure).
    checks.sort(key=lambda c: {"local": 0, "contract": 1, "xctest": 2, "training": 3}[c["kind"]])
    return {"checks": checks, "packSelectors": coverage, "groupSelectors": group_coverage,
            "selectionCountBeforeUnion": len(all_selectors),
            "selectorsAfterUnion": compact_selectors(all_selectors)}
