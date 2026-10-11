import pathlib
import subprocess
import tempfile
import unittest


LAUNCHER = pathlib.Path(__file__).resolve().parents[1] / "Project" / "Launcher.bat"
SOURCE = LAUNCHER.read_text(encoding="utf-8")
BUILDER = (
    LAUNCHER.parents[1] / "Files" / "GoodybeZapretConfigBuilder" / "builder.py"
).read_text(encoding="utf-8")
ENGINE_CHECKER = (
    LAUNCHER.parent / "tools" / "service" / "TestGoodbyeZapretEngine.ps1"
).read_text(encoding="utf-8")


def section(name):
    start = SOURCE.index(f"\n:{name}\n") + 1
    end = SOURCE.find("\n:", start + 1)
    return SOURCE[start:end if end >= 0 else None]


class ConfiguratorAutoPickerFlowTest(unittest.TestCase):
    def test_configurator_install_aborts_when_builder_fails(self):
        """A failed build must not fall through to an old ConfiguratorFix file."""
        install = section("ConfiguratorInstallAutostart")
        build = install.index("call :BuildConfiguratorFix")
        resolve = install.index("call :ResolveConfiguratorFixConfig")
        self.assertIn("if errorlevel 1", install[build:resolve])
        self.assertLess(install.index("if errorlevel 1", build), resolve)

    def test_service_config_is_committed_only_after_running(self):
        """The persisted active config must describe a service that actually started."""
        install = section("install_GZ_service")
        write = install.index("call :WriteConfig GoodbyeZapret_Config")
        running_check = install.index('find /I "RUNNING"')
        self.assertGreater(write, running_check)
        # Keep a failed start on the error path instead of committing the name.
        self.assertIn("if errorlevel 1 (", install[running_check:write])

    def test_builder_does_not_mark_configurator_active_while_generating(self):
        """The builder must leave active-service state to the launcher."""
        save_start = BUILDER.index("def save_user_config(")
        save_end = BUILDER.index("\ndef ", save_start + 1)
        save = BUILDER[save_start:save_end]
        self.assertNotIn('main_config_data["GoodbyeZapret_Config"]', save)
        self.assertNotIn('main_config_data[\'GoodbyeZapret_Config\']', save)

    def test_bypass_process_check_is_not_global_by_image_name(self):
        """An unrelated winws process must not satisfy launch verification."""
        body = section("WaitForBypassProcess")
        self.assertNotIn("tasklist", body.lower())
        self.assertIn("TestGoodbyeZapretEngine.ps1", body)
        self.assertIn('-ProjectDir "%ParentDirPath%"', body)

        # The checker binds three identities: the running named service, its
        # service executable, and a direct child engine from this project.
        checker = ENGINE_CHECKER
        self.assertIn("Get-CimInstance Win32_Service", checker)
        self.assertIn("$service.State -ne 'Running'", checker)
        self.assertIn("$service.ProcessId", checker)
        self.assertIn("tools\\service\\GoodbyeZapretService.exe", checker)
        self.assertIn("$serviceProcess.ExecutablePath", checker)
        self.assertIn("ParentProcessId=$($service.ProcessId)", checker)
        self.assertIn("$engine.ExecutablePath", checker)
        self.assertIn("bin\\winws.exe", checker)
        self.assertIn("bin\\winws2.exe", checker)

    def test_every_candidate_has_progress_and_cancel_checkpoint(self):
        loop = section("ConfiguratorAutoLoop")
        self.assertIn("call :ConfiguratorAutoShowProgress", loop)
        self.assertIn("call :ConfiguratorAutoCancelCheckpoint", loop)
        self.assertIn("goto ConfiguratorAutoCancel", loop)

    def test_cancel_checkpoint_only_cancels_on_second_choice(self):
        checkpoint = section("ConfiguratorAutoCancelCheckpoint")
        self.assertIn("call :ConfiguratorAutoPollCancel", checkpoint)
        self.assertIn("if errorlevel 1 exit /b 1", checkpoint)
        self.assertNotIn("choice /c", checkpoint)

    def test_cancel_poll_is_non_blocking_and_ignores_noninteractive_console_errors(self):
        poll = section("ConfiguratorAutoPollCancel")
        self.assertIn("Console]::KeyAvailable", poll)
        self.assertIn("catch { }", poll)
        self.assertIn("exit /b 0", poll)
        self.assertLess(poll.index("chcp 850"), poll.index("powershell"))
        self.assertLess(poll.index("powershell"), poll.index("chcp 65001"))

    def test_progress_clock_restores_utf8_codepage(self):
        init = SOURCE[SOURCE.index('set /a AutoTotalCandidates'):SOURCE.index('call :ConfiguratorAutoUpdateTitle')]
        progress = section("ConfiguratorAutoShowProgress")
        self.assertIn("chcp 850", init)
        self.assertIn("chcp 65001", init)
        self.assertIn("chcp 850", progress)
        self.assertIn("chcp 65001", progress)
        self.assertIn("AutoRemainingCandidates=AutoMax+1-AutoCompleted", progress)
        self.assertNotIn("AutoElapsed*(!AutoMax!+1-AutoCompleted)", progress)

    def test_report_failures_are_shown_from_check_records(self):
        check = section("ConfiguratorAutoCheck_Run")
        self.assertIn("call :ConfiguratorAutoShowCandidateResult", check)
        details = section("ConfiguratorAutoShowCandidateResult")
        self.assertIn("CHECK", details)
        self.assertIn("FAIL", details)
        self.assertNotIn("Отчет: !AutoReportFile!", check)

    def test_user_selects_found_strategy_before_commit(self):
        completed = section("ConfiguratorAutoComplete")
        self.assertIn("goto ConfiguratorAutoSelectResult", completed)
        selected = section("ConfiguratorAutoSelectResultMenu")
        self.assertIn("AutoSelected", selected)
        self.assertIn("goto ConfiguratorAutoCancel", selected)
        save = section("ConfiguratorAutoSave")
        self.assertIn("AutoSelected", save)
        self.assertNotIn("AutoFirstFound!", save)

    def test_candidate_details_include_failed_domain_and_reason(self):
        with tempfile.TemporaryDirectory() as directory:
            root = pathlib.Path(directory)
            report = root / "report.txt"
            report.write_text(
                "SUMMARY|1|2\n"
                "CHECK|cloudflare.com|OK|OK|200|1024|25|TLS 1.3\n"
                "CHECK|aws.amazon.com|FAIL|TIMEOUT|0|0|5000|\n",
                encoding="utf-8",
            )
            harness = root / "show_result.bat"
            harness.write_text(
                "@echo off\nsetlocal EnableDelayedExpansion\n"
                f'set "AutoReportFile={report}"\n'
                'set "AutoIndex=7"\n'
                "call :ConfiguratorAutoShowCandidateResult\nexit /b\n"
                + section("ConfiguratorAutoShowCandidateResult"),
                encoding="utf-8",
            )
            result = subprocess.run(
                ["cmd", "/d", "/c", str(harness)],
                capture_output=True,
                text=True,
                check=True,
            )
            self.assertIn("[7]", result.stdout)
            self.assertIn("1/2", result.stdout)
            self.assertIn("aws.amazon.com: TIMEOUT", result.stdout)


if __name__ == "__main__":
    unittest.main()
