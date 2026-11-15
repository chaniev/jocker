#!/usr/bin/env python3
"""Content-addressed, atomic cache for the standalone Swift training runner."""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def discover_sources(root):
    paths = [root / "Jocker/Jocker/Core/GameColors.swift",
             root / "Jocker/Jocker/Game/Nodes/CardNode.swift",
             root / "Jocker/Jocker/Game/Nodes/TrickNode.swift"]
    for folder in ("Jocker/JockerSelfPlayTools", "Jocker/Jocker/Models",
                   "Jocker/Jocker/Scoring", "Jocker/Jocker/Game/Services/AI"):
        found = sorted((root / folder).rglob("*.swift"))
        if not found:
            raise ValueError("No Swift sources in " + folder)
        paths.extend(found)
    return sorted(set(paths))


def discover_toolchain():
    def output(*args):
        return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT, timeout=30).strip()
    compiler = output("xcrun", "--find", "swiftc")
    sdk = output("xcrun", "--sdk", "macosx", "--show-sdk-path")
    return {"compiler": [compiler], "compilerVersion": output(compiler, "--version"),
            "sdkPath": sdk, "sdkVersion": output("xcrun", "--sdk", "macosx", "--show-sdk-version"),
            "flags": ["-O", "-sdk", sdk],
            "environment": {key: os.environ.get(key) for key in
                            ("DEVELOPER_DIR", "TOOLCHAINS", "SDKROOT", "MACOSX_DEPLOYMENT_TARGET")}}


def file_digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def input_state(root, toolchain):
    return {"schemaVersion": 1, "toolchain": toolchain,
            "sources": [{"path": p.relative_to(root).as_posix(), "sha256": file_digest(p)}
                        for p in discover_sources(root)]}


def fingerprint(state):
    return hashlib.sha256(json.dumps(state, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def cached_runner(entry, state):
    binary = entry / "bot_training_runner"
    try:
        manifest = json.loads((entry / "manifest.json").read_text())
        return (binary.is_file() and os.access(binary, os.X_OK) and manifest["inputs"] == state
                and manifest["binarySHA256"] == file_digest(binary))
    except (OSError, ValueError, KeyError):
        return False


def ensure_runner(root, build_dir, toolchain):
    build_dir.mkdir(parents=True, exist_ok=True)
    # One compiler per worktree. Content keys remain immutable for running callers.
    with (build_dir / "compile.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = input_state(root, toolchain)
        key = fingerprint(state)
        entry = build_dir / key
        binary = entry / "bot_training_runner"
        if cached_runner(entry, state):
            print("Using cached bot training runner: " + str(binary), file=sys.stderr)
            return binary
        print("Compiling bot training runner (cache " + key[:12] + ")...", file=sys.stderr)
        module_cache = build_dir / "module-cache"
        module_cache.mkdir(exist_ok=True)
        environment = dict(os.environ, CLANG_MODULE_CACHE_PATH=str(module_cache), SWIFT_MODULECACHE_PATH=str(module_cache))
        with tempfile.TemporaryDirectory(prefix=".compile-", dir=build_dir) as temporary:
            output = Path(temporary) / "bot_training_runner"
            command = (toolchain["compiler"] + toolchain["flags"]
                       + [str(root / source["path"]) for source in state["sources"]]
                       + ["-module-cache-path", str(module_cache), "-o", str(output)])
            subprocess.run(command, env=environment, check=True, stdout=sys.stderr)
            if not output.is_file() or not os.access(output, os.X_OK):
                raise ValueError("Compiler did not produce an executable runner")
            if input_state(root, toolchain) != state:
                raise ValueError("Training inputs changed during compilation; runner was not cached")
            manifest = {"fingerprint": key, "inputs": state, "binarySHA256": file_digest(output)}
            metadata = Path(temporary) / "manifest.json"
            metadata.write_text(json.dumps(manifest, indent=2) + "\n")
            entry.mkdir(exist_ok=True)
            os.replace(output, binary)
            os.replace(metadata, entry / "manifest.json")
        return binary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    root = args.root.resolve()
    try:
        binary = ensure_runner(root, root / ".derivedData/dev-tools/bot-training", discover_toolchain())
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print("Training runner build failed: " + str(error), file=sys.stderr)
        return 1
    print(binary)
    return 0


if __name__ == "__main__":
    sys.exit(main())
