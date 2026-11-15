#!/usr/bin/env python3
"""Validate explicit Xcode source membership against the repository's target boundaries."""
import json
from pathlib import Path
import subprocess
import sys

TARGETS = {"Jocker", "JockerTests", "JockerUITests", "JockerSelfPlayTools"}
CLI_MAIN = "Jocker/JockerSelfPlayTools/main.swift"


def load_project(root):
    return json.loads(subprocess.check_output([
        "plutil", "-convert", "json", "-o", "-",
        str(root / "Jocker/Jocker.xcodeproj/project.pbxproj")], text=True))


def source_membership(project):
    objects = project["objects"]
    project_object = objects[project["rootObject"]]
    references = {}

    def walk(identifier, parent, ancestors):
        if identifier in ancestors:
            raise ValueError("Cyclic Xcode group: " + identifier)
        item = objects[identifier]
        tree = item.get("sourceTree", "<group>")
        base = Path("Jocker") if tree == "SOURCE_ROOT" else parent
        path = base / item.get("path", "")
        if item["isa"] in ("PBXGroup", "PBXVariantGroup"):
            for child in item.get("children", []):
                walk(child, path, ancestors | {identifier})
        elif item["isa"] == "PBXFileReference" and path.suffix == ".swift":
            if tree not in ("<group>", "SOURCE_ROOT") or path.is_absolute() or ".." in path.parts or "$" in str(path):
                raise ValueError("Unsupported Swift source path: " + str(path))
            if identifier in references and references[identifier] != path.as_posix():
                raise ValueError("Ambiguous Swift source path: " + identifier)
            references[identifier] = path.as_posix()

    for item in objects.values():
        if item["isa"].startswith("PBXFileSystemSynchronized"):
            raise ValueError("Synchronized groups require an explicit membership validator")
        if item["isa"] == "XCBuildConfiguration":
            for setting, value in item.get("buildSettings", {}).items():
                if setting.split("[")[0] in ("EXCLUDED_SOURCE_FILE_NAMES", "INCLUDED_SOURCE_FILE_NAMES") and value:
                    raise ValueError("Conditional source membership is unsupported: " + setting)
    walk(project_object["mainGroup"], Path("Jocker"), set())
    targets = {objects[t]["name"]: objects[t] for t in project_object["targets"]}
    if set(targets) != TARGETS:
        raise ValueError("Unexpected project targets: " + str(sorted(targets)))
    membership = {}
    for name, target in targets.items():
        if target.get("buildRules"):
            raise ValueError("Custom build rules require membership validation: " + name)
        sources = []
        for phase_id in target["buildPhases"]:
            phase = objects[phase_id]
            if phase["isa"] == "PBXShellScriptBuildPhase":
                raise ValueError("Generated sources require membership validation: " + name)
            if phase["isa"] != "PBXSourcesBuildPhase":
                continue
            for build_id in phase["files"]:
                build = objects[build_id]
                ref = build["fileRef"]
                if ref not in references:
                    raise ValueError("Unresolved source reference in " + name + ": " + ref)
                if build.get("platformFilter") or build.get("platformFilters"):
                    raise ValueError("Conditional source build entry: " + references[ref])
                sources.append(references[ref])
        if len(sources) != len(set(sources)):
            raise ValueError("Duplicate source build entries in " + name)
        membership[name] = set(sources)

    # Also reject linking the training library into the app indirectly.
    def check_app_dependencies(target, visited):
        if target["name"] in visited:
            return
        visited.add(target["name"])
        if target["name"] == "JockerSelfPlayTools":
            raise ValueError("App depends on the training target")
        for dependency in target.get("dependencies", []):
            dep = objects[dependency]
            if dep.get("target"):
                check_app_dependencies(objects[dep["target"]], visited)
        for phase_id in target["buildPhases"]:
            phase = objects[phase_id]
            if phase["isa"] == "PBXFrameworksBuildPhase":
                for build_id in phase["files"]:
                    ref = objects[build_id].get("fileRef")
                    if ref == targets["JockerSelfPlayTools"]["productReference"]:
                        raise ValueError("App links the training library")
    check_app_dependencies(targets["Jocker"], set())
    return membership


def validate(root, project):
    membership = source_membership(project)
    errors = []
    disk = {p.relative_to(root).as_posix() for name in TARGETS
            for p in (root / "Jocker" / name).rglob("*.swift")}
    compiled = set().union(*membership.values())
    for path in sorted(disk | compiled):
        owners = {target for target, paths in membership.items() if path in paths}
        if path not in disk:
            errors.append("Compiled file is missing: " + path)
            continue
        if path == CLI_MAIN:
            if owners:
                errors.append("CLI main must not enter an Xcode library/app: " + path)
            continue
        parts = Path(path).parts
        owner = parts[1]
        if owner == "Jocker":
            filename = parts[-1]
            training = filename.startswith("BotSelfPlayEvolutionEngine") or filename == "BotTuning+SelfPlayEvolution.swift"
            required = "JockerSelfPlayTools" if training else "Jocker"
            allowed = {required} if training else {"Jocker", "JockerSelfPlayTools"}
        else:
            required = owner
            allowed = {owner}
        if required not in owners:
            errors.append("Missing " + required + " membership: " + path)
        if owners - allowed:
            errors.append("Forbidden membership " + ", ".join(sorted(owners - allowed)) + ": " + path)
    if CLI_MAIN not in disk:
        errors.append("Missing CLI entry point: " + CLI_MAIN)
    return {"status": "failed" if errors else "passed", "errors": errors,
            "sourceCounts": {name: len(paths) for name, paths in sorted(membership.items())},
            "cliOnlySources": [CLI_MAIN]}


def main():
    root = Path(__file__).resolve().parents[2]
    try:
        report = validate(root, load_project(root))
    except (KeyError, ValueError, OSError, subprocess.SubprocessError) as error:
        report = {"status": "failed", "errors": [str(error)]}
    print(json.dumps(report, indent=2))
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    sys.exit(main())
