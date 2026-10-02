"""Recovery integration tests, isolated from the user's rendu and checkpoints."""
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]

class Sessions(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='examshell-test-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.main = self.root / '.resources/main'
        shutil.copytree(ROOT / '.resources/main', self.main)
        for name in ('exam.sh', 'resume.sh', 'menu.sh'):
            shutil.copy2(ROOT / name, self.root / name)
        # Only subject fixtures are required; no real student code or testers.
        for subject in (ROOT / '.resources').glob('rank*/**/sub.txt'):
            dest = self.root / subject.relative_to(ROOT)
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text('Test subject\n')
        (self.main / 'functions.sh').write_text('display_animation() { :; }\n')
        self.state = self.root / '.session/last_session'
        self.env = dict(os.environ, TERM='xterm')
        for key in ('SESSION_RESUME', 'SESSION_DRIVER', 'SESSION_START_LEVEL'):
            self.env.pop(key, None)

    def run_script(self, script, *args, commands='save\n', env=None):
        result = subprocess.run(['bash', str(script), *args], input=commands,
            text=True, capture_output=True, cwd=self.main, env=env or self.env, timeout=15)
        self.assertNotIn('unbound variable', result.stderr)
        self.assertNotIn('No such file', result.stderr)
        return result

    def checkpoint(self):
        return self.state.read_text().splitlines()

    def test_all_workers_resume(self):
        cases = [('level_base.sh', 'rank02', 'level0'),
                 ('level_base.sh', 'rank03', 'level2'),
                 ('level_base.sh', 'rank04', 'level1'),
                 ('rank06_level.sh', 'rank06', ''),
                 ('rank05_level_base.sh', 'rank05', 'level1')]
        cases += [(f'rank0{rank}_exam_mode.sh', f'rank0{rank}', 'level0' if rank == 2 else 'level1' if rank < 6 else '') for rank in range(2, 7)]
        for script, rank, level in cases:
            with self.subTest(script=script, rank=rank):
                result = self.run_script(self.main / script, rank, level)
                self.assertEqual(result.returncode, 200, result.stderr)
                before = self.checkpoint()
                sentinel = self.root / 'rendu' / before[7 + int(before[5])] / 'my_solution.c'
                sentinel.write_text('my work\n')
                result = self.run_script(self.root / 'exam.sh', '--resume')
                self.assertEqual(result.returncode, 200, result.stderr)
                after = self.checkpoint()
                self.assertEqual(before[:6] + before[7:], after[:6] + after[7:])
                self.assertEqual(sentinel.read_text(), 'my work\n')

    def test_next_history_and_completion(self):
        self.run_script(self.main / 'rank06_level.sh', 'rank06', commands='next\nsave\n')
        state = self.checkpoint()
        self.assertEqual(state[5], '1')
        self.assertEqual(len((self.root / '.session/history.log').read_text().splitlines()), 2)
        result = self.run_script(self.root / 'exam.sh', '--resume', commands='next\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.state.exists())

    def test_signals_and_sigkill(self):
        for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP, signal.SIGKILL):
            with self.subTest(signal=sig):
                self.state.unlink(missing_ok=True)
                with tempfile.TemporaryFile() as output:
                    process = subprocess.Popen(['bash', 'level_base.sh', 'rank02', 'level0'],
                        cwd=self.main, stdin=subprocess.PIPE, stdout=output, stderr=output,
                        env=self.env, start_new_session=True)
                    try:
                        deadline = time.monotonic() + 5
                        while not self.state.exists() and time.monotonic() < deadline:
                            time.sleep(.02)
                        self.assertTrue(self.state.exists())
                        time.sleep(.1)
                        before = self.checkpoint()
                        os.killpg(process.pid, sig)
                        process.wait(timeout=5)
                    finally:
                        if process.poll() is None:
                            os.killpg(process.pid, signal.SIGKILL)
                            process.wait()
                        process.stdin.close()
                result = self.run_script(self.root / 'exam.sh', '--resume')
                self.assertEqual(result.returncode, 200, result.stderr)
                after = self.checkpoint()
                self.assertEqual(before[:6] + before[7:], after[:6] + after[7:])

    def test_driver_resume_skips_completed_levels(self):
        env = dict(self.env, SESSION_DRIVER='rank02_real_mode.sh')
        self.run_script(self.main / 'rank02_exam_mode.sh', 'rank02', 'level2', env=env)
        before = self.checkpoint()
        result = self.run_script(self.root / 'exam.sh', '--resume')
        self.assertEqual(result.returncode, 200, result.stderr)
        self.assertEqual(self.checkpoint()[4], 'level2')
        self.assertEqual(self.checkpoint()[7], before[7])
        self.assertNotIn('Level 0 is being prepared', result.stdout)
        self.assertTrue((self.root / 'rendu').exists())

    def test_reopening_preserves_starter_edits(self):
        subject = self.root / '.resources/rank03/level1/broken_gnl'
        (subject / 'broken_gnl.c').write_text('starter\n')
        self.state.parent.mkdir()
        self.state.write_text('1\nlevel_base.sh\n-\nrank03\nlevel1\n0\n1\nbroken_gnl\n')
        self.run_script(self.root / 'exam.sh', '--resume')
        solution = self.root / 'rendu/broken_gnl/broken_gnl.c'
        solution.write_text('edited solution\n')
        self.run_script(self.root / 'exam.sh', '--resume')
        self.assertEqual(solution.read_text(), 'edited solution\n')

    def test_failed_exam_retry_keeps_subject(self):
        env = dict(self.env, SESSION_DRIVER='rank02_real_mode.sh')
        self.run_script(self.main / 'rank02_exam_mode.sh', 'rank02', 'level2', env=env)
        before = self.checkpoint()
        tester = self.root / '.resources/rank02/level2' / before[7] / 'tester.sh'
        tester.write_text('#!/bin/bash\necho FAILED\nexit 1\n')
        tester.chmod(0o755)
        result = self.run_script(self.root / 'exam.sh', '--resume', commands='test\n\nsave\n')
        self.assertEqual(result.returncode, 200, result.stderr)
        self.assertEqual(self.checkpoint()[7], before[7])
        self.assertIn('Test failed. Try again.', result.stdout)

    def test_invalid_state_not_executed(self):
        self.state.parent.mkdir()
        self.state.write_text('$(touch SHOULD_NOT_EXIST)\n')
        result = self.run_script(self.root / 'exam.sh', '--resume')
        self.assertEqual(result.returncode, 1)
        self.assertFalse((self.main / 'SHOULD_NOT_EXIST').exists())

    def test_forget_keeps_work_and_history(self):
        self.run_script(self.main / 'level_base.sh', 'rank02', 'level0')
        result = self.run_script(self.root / 'exam.sh', '--forget')
        self.assertEqual(result.returncode, 0)
        self.assertFalse(self.state.exists())
        self.assertTrue((self.root / 'rendu').exists())
        self.assertTrue((self.root / '.session/history.log').exists())

if __name__ == '__main__':
    unittest.main()
