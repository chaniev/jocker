from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from results import parse_results


class ResultsTests(unittest.TestCase):
    def test_failure_messages_and_unique_test_counts_come_from_xcresult(self):
        summary = {"totalTestCount": 2, "passedTests": 1, "failedTests": 1, "skippedTests": 0, "expectedFailures": 0, "result": "Failed", "testFailures": [
            {"targetName": "JockerTests", "testIdentifierString": "Example/testBad()", "failureText": "Expected 500, got 250"},
            {"targetName": "JockerTests", "testIdentifierString": "Example/testBad()", "failureText": "Second assertion"}]}
        tree = {"testNodes": [{"nodeType": "Unit test bundle", "name": "JockerTests", "children": [
            {"nodeType": "Test Case", "name": "testGood()", "nodeIdentifier": "Example/testGood()", "result": "Passed", "durationInSeconds": 0.2},
            {"nodeType": "Test Case", "name": "testBad()", "nodeIdentifier": "Example/testBad()", "result": "Failed", "children": [{"nodeType": "Test Case Run", "name": "repetition"}]}]}]}
        result = parse_results(summary, tree)
        self.assertEqual(result["failed"], 1)
        self.assertEqual(len(result["failures"]), 2)
        self.assertEqual(len(result["tests"]), 2)
        self.assertEqual(result["tests"][0]["identifier"], "JockerTests/Example/testGood")
        self.assertEqual(result["tests"][0]["durationSeconds"], 0.2)
        self.assertIn("Expected 500", result["failures"][0]["message"])
