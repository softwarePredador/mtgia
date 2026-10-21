"""Keep literal-credential detection on both sides of the hostname migration."""
import contextlib
import importlib.util
import io
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    'credential_audit', ROOT / 'scripts/manaloom_live_credential_audit.py'
)
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class ProductionMarkerTest(unittest.TestCase):
    def run_fixture(self, host, literal):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            script = root / 'scripts/example.sh'
            script.parent.mkdir()
            value = "'fixture-secret'" if literal else '"$TEST_PASSWORD"'
            script.write_text(f'API="https://{host}"\npassword={value}\n')
            output, errors = io.StringIO(), io.StringIO()
            with patch.object(audit, '__file__', str(root / 'scripts/audit.py')):
                with patch.object(audit, 'tracked_paths', return_value=[script]):
                    with contextlib.redirect_stdout(output), contextlib.redirect_stderr(errors):
                        code = audit.main()
            self.assertNotIn('fixture-secret', output.getvalue() + errors.getvalue())
            return code

    def test_new_production_host_rejects_literal_credential(self):
        self.assertEqual(self.run_fixture('evolution-cartinhas.tr5taz.easypanel.host', True), 1)

    def test_legacy_production_host_stays_protected(self):
        self.assertEqual(self.run_fixture('evolution-cartinhas.2ta7qx.easypanel.host', True), 1)

    def test_environment_reference_is_accepted(self):
        self.assertEqual(self.run_fixture('evolution-cartinhas.tr5taz.easypanel.host', False), 0)

    def test_non_production_fixture_remains_outside_scope(self):
        self.assertEqual(self.run_fixture('localhost', True), 0)


if __name__ == '__main__':
    unittest.main()
