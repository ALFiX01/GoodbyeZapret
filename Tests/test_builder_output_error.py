import pathlib
import os
import subprocess
import sys
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
BUILDER = ROOT / "Files" / "GoodybeZapretConfigBuilder" / "builder.py"
CONFIG_DIR = ROOT / "Project" / "tools" / "config_builder"


class BuilderOutputErrorTest(unittest.TestCase):
    def test_write_failure_returns_nonzero_exit_code(self):
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(
                [sys.executable, str(BUILDER), "--no-save", "--output", directory],
                cwd=CONFIG_DIR,
                capture_output=True,
                text=True,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Could not write preset file", result.stderr)

    def test_build_preserves_active_config_selection(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            app_dir = root / "GoodbyeZapret"
            app_dir.mkdir()
            active = app_dir / "config.txt"
            original = 'GoodbyeZapret_Config="ExistingPreset"\nOtherSetting="keep"\n'
            active.write_text(original, encoding="utf-8")
            environment = os.environ.copy()
            environment["APPDATA"] = str(root)

            result = subprocess.run(
                [sys.executable, str(BUILDER), "--output", str(root / "preset.txt")],
                cwd=CONFIG_DIR,
                env=environment,
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(active.read_text(encoding="utf-8"), original)
            self.assertTrue((app_dir / "configurator.txt").is_file())
            self.assertTrue((app_dir / "ports.bat").is_file())


if __name__ == "__main__":
    unittest.main()
