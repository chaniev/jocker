"""Read XCTest diagnostics from xcresulttool JSON, never infer success from logs."""
import json
import subprocess


def normalize_identifier(identifier):
    return identifier.replace("()", "")


def parse_results(summary, tree):
    tests = []
    def walk(nodes, target=None):
        for node in nodes:
            if node["nodeType"] in ("Unit test bundle", "UI test bundle"):
                target = node["name"].removesuffix(".xctest")
            if node["nodeType"] == "Test Case":
                identifier = normalize_identifier(node.get("nodeIdentifier", node["name"]))
                if target and not identifier.startswith(target + "/"):
                    identifier = target + "/" + identifier
                tests.append({"identifier": identifier, "status": node.get("result", "unknown"),
                              "durationSeconds": node.get("durationInSeconds"), "durationText": node.get("duration")})
            else:
                walk(node.get("children", []), target)
    walk(tree["testNodes"])
    return {"total": summary["totalTestCount"], "passed": summary["passedTests"],
            "failed": summary["failedTests"], "skipped": summary["skippedTests"],
            "expectedFailures": summary["expectedFailures"], "tests": tests,
            "failures": [{"identifier": normalize_identifier(f["targetName"] + "/" + f["testIdentifierString"]),
                          "message": f["failureText"]} for f in summary["testFailures"]],
            "result": summary["result"]}


def collect_results(root, artifacts, selectors):
    bundles = sorted(artifacts.rglob("*.xcresult"))
    if len(bundles) != 1:
        raise ValueError("Expected one xcresult bundle; found " + str(len(bundles)))
    bundle = bundles[0]
    payloads = {}
    for name in ("summary", "tests"):
        command = ["xcrun", "xcresulttool", "get", "test-results", name, "--path", str(bundle), "--compact"]
        try:
            data = subprocess.check_output(command, cwd=root, text=True, stderr=subprocess.PIPE, timeout=60)
        except subprocess.CalledProcessError as error:
            raise ValueError("xcresulttool " + name + ": " + (error.stderr or str(error)).strip()) from error
        (artifacts / ("xcresult-" + name + ".json")).write_text(data)
        payloads[name] = json.loads(data)
    result = parse_results(payloads["summary"], payloads["tests"])
    result["resultBundle"] = str(bundle)
    identifiers = [test["identifier"] for test in result["tests"] if test["status"] not in ("Skipped", "unknown")]
    result["missingSelectors"] = [s for s in selectors if not any(i == s or i.startswith(s + "/") for i in identifiers)]
    result["duplicateTests"] = sorted({i for i in identifiers if identifiers.count(i) > 1})
    return result
