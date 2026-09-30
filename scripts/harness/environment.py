"""Fail early on unavailable Xcode/scheme/simulator; persist every probe."""
import json
import re
import subprocess
import time

from planning import PROJECT, SCHEME, scheme_targets


def probe(root, command, timeout=30):
    started = time.monotonic()
    try:
        result = subprocess.run(command, cwd=root, capture_output=True, text=True, timeout=timeout)
        return {"command": command, "exitCode": result.returncode, "output": result.stdout,
                "errorOutput": result.stderr, "durationSeconds": time.monotonic() - started}
    except (OSError, subprocess.TimeoutExpired) as error:
        return {"command": command, "exitCode": None, "error": str(error),
                "durationSeconds": time.monotonic() - started}


def eligible_destinations(output):
    # Xcode also prints real device IDs in its ineligible section.
    # Those must never be considered just because simctl says the device exists.
    available = re.split(r"Ineligible destinations", output, flags=re.IGNORECASE)[0]
    return set(re.findall(r"platform:iOS Simulator,[^\n}]*?id:([A-Fa-f0-9-]{36})", available))


def resolve_destination(destination, devices, runtimes, eligible_ids):
    fields = dict(part.split("=", 1) for part in destination.split(","))
    if fields.pop("platform", None) != "iOS Simulator" or set(fields) - {"id", "name", "OS"}:
        raise ValueError("Use platform=iOS Simulator with optional id, name and OS")
    available_runtimes = {r["identifier"]: r for r in runtimes if r.get("isAvailable") and r.get("platform", "iOS") == "iOS" and ".iOS-" in r["identifier"]}
    candidates = []
    for runtime, entries in devices.items():
        if runtime not in available_runtimes:
            continue
        version = available_runtimes[runtime]["version"]
        for device in entries:
            if not device.get("isAvailable") or device["udid"] not in eligible_ids:
                continue
            if fields.get("id") and fields["id"] != device["udid"]:
                continue
            if fields.get("name") and fields["name"] != device["name"]:
                continue
            if fields.get("OS") not in (None, "latest", version):
                continue
            candidates.append({**device, "osVersion": version, "runtime": runtime})
    if not candidates:
        raise ValueError("No available scheme-compatible simulator matches " + destination)
    candidates.sort(key=lambda d: (tuple(int(n) for n in d["osVersion"].split(".")), d["name"].startswith("iPhone"), d["name"], d["udid"]), reverse=True)
    device = candidates[0]
    return "platform=iOS Simulator,id=" + device["udid"], device


def doctor(root, destination, needs_simulator=True):
    started = time.monotonic()
    report = {"status": "blocked", "requestedDestination": destination, "probes": []}
    def require(command, timeout=30):
        result = probe(root, command, timeout)
        report["probes"].append(result)
        if result["exitCode"] != 0:
            raise ValueError("Environment probe failed: " + " ".join(command))
        return result["output"]
    try:
        report["xcodeVersion"] = require(["xcodebuild", "-version"])
        report["swiftVersion"] = require(["xcrun", "swift", "--version"])
        if needs_simulator:
            report["testTargets"] = scheme_targets(root)
            # Structured xcresult reports require the test-results subcommands (Xcode 16+).
            require(["xcrun", "xcresulttool", "get", "test-results", "summary", "--help"])
            require(["xcrun", "xcresulttool", "get", "test-results", "tests", "--help"])
            devices = json.loads(require(["xcrun", "simctl", "list", "devices", "available", "--json"]))["devices"]
            runtimes = json.loads(require(["xcrun", "simctl", "list", "runtimes", "--json"]))["runtimes"]
            destinations = require(["xcodebuild", "-project", PROJECT, "-scheme", SCHEME, "-showdestinations"], 60)
            eligible = eligible_destinations(destinations)
            resolved, device = resolve_destination(destination, devices, runtimes, eligible)
            report.update({"resolvedDestination": resolved, "device": device})
            if device["state"] != "Booted":
                require(["xcrun", "simctl", "boot", device["udid"]])
            boot_output = require(["xcrun", "simctl", "bootstatus", device["udid"], "-b"], 120)
            if "failed" in boot_output.lower():
                raise ValueError("Simulator boot reported failure; inspect doctor probes")
        report["status"] = "passed"
    except (OSError, ValueError, KeyError) as error:
        report["error"] = str(error)
    report["durationSeconds"] = time.monotonic() - started
    return report
