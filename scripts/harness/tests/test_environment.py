from pathlib import Path
import json
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from environment import doctor, resolve_destination, eligible_destinations


class EnvironmentTests(unittest.TestCase):
    def setUp(self):
        self.runtimes = [{"identifier": "com.apple.iOS-18-0", "version": "18.0", "isAvailable": True}]
        self.devices = {"com.apple.iOS-18-0": [{"udid": "one", "name": "iPhone", "state": "Booted", "isAvailable": True}, {"udid": "two", "name": "iPad", "state": "Shutdown", "isAvailable": True}]}

    def test_generic_destination_resolves_to_exact_eligible_device(self):
        dest, device = resolve_destination("platform=iOS Simulator", self.devices, self.runtimes, {"one", "two"})
        self.assertEqual(dest, "platform=iOS Simulator,id=one")
        self.assertEqual(device["osVersion"], "18.0")

    def test_explicit_missing_or_ineligible_destination_never_falls_back(self):
        for destination in ["platform=iOS Simulator,id=missing", "platform=iOS Simulator,OS=17.0", "platform=iOS Simulator,id=two"]:
            with self.assertRaises(ValueError):
                resolve_destination(destination, self.devices, self.runtimes, {"one"})

    def test_service_failure_blocks_without_building(self):
        with patch("environment.probe", return_value={"exitCode": 1, "errorOutput": "CoreSimulator unavailable"}) as probe:
            result = doctor(Path("."), "platform=iOS Simulator")
        self.assertEqual(result["status"], "blocked")
        self.assertEqual(probe.call_count, 1)
        self.assertGreaterEqual(result["durationSeconds"], 0)

    def test_cold_simulator_install_progress_and_longer_timeout(self):
        device_id = "11111111-1111-1111-1111-111111111111"
        devices = {"com.apple.iOS-18-0": [{"udid": device_id, "name": "iPhone", "state": "Booted", "isAvailable": True}]}
        def respond(root, command, timeout):
            output = ""
            if "devices" in command:
                self.assertEqual(timeout, 180)
                output = "Install Started\nInstall Succeeded\n" + json.dumps({"devices": devices})
            elif "runtimes" in command:
                self.assertEqual(timeout, 180)
                output = json.dumps({"runtimes": self.runtimes})
            elif "-showdestinations" in command:
                output = "{ platform:iOS Simulator, id:" + device_id + " }"
            return {"exitCode": 0, "output": output}
        with patch("environment.probe", side_effect=respond), patch("environment.scheme_targets", return_value=["JockerTests"]):
            result = doctor(Path("."), "platform=iOS Simulator")
        self.assertEqual(result["status"], "passed")
        self.assertEqual(result["resolvedDestination"], "platform=iOS Simulator,id=" + device_id)

    def test_ineligible_section_is_not_used_even_for_available_simulator(self):
        allowed = "11111111-1111-1111-1111-111111111111"
        rejected = "22222222-2222-2222-2222-222222222222"
        output = ('Available destinations for the Jocker scheme:\n'
                  '{ platform:iOS Simulator, arch:arm64, id:' + allowed + ', OS:18.0, name:iPhone }\n'
                  'Ineligible destinations for the Jocker scheme:\n'
                  '{ platform:iOS Simulator, id:' + rejected + ', name:iPhone, error:Unsupported SDK }')
        self.assertEqual(eligible_destinations(output), {allowed})
        self.assertEqual(eligible_destinations(output.replace("Ineligible destinations", "Destinations incompatible")), {allowed})
