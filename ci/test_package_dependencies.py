"""Keep runtime packages installable without the target's development stack."""
from pathlib import Path
import subprocess
import unittest


class PackageDependencyTests(unittest.TestCase):
    def test_runtime_dependencies_for_supported_distributions(self):
        script = (Path(__file__).resolve().parents[1] / "package.sh").read_text()
        dependencies = script.split("# Runtime dependencies", 1)[1].split("ls -a release/", 1)[0]
        dependencies = "# Runtime dependencies" + dependencies
        cases = [("raspbian", "bullseye", 58), ("raspbian", "bookworm", 59),
                 ("debian", "bullseye", 58), ("debian", "bookworm", 59),
                 ("ubuntu", "jammy", 58), ("ubuntu", "noble", 60)]
        for distro, release, abi in cases:
            with self.subTest(distro=distro, release=release):
                result = subprocess.run(
                    ["bash", "-c", dependencies + '\nprintf "%s\\n" $PLATFORM_PACKAGES',
                     "dependencies", distro, release],
                    env={"OS": distro, "DISTRO": release},
                    text=True, capture_output=True, check=True,
                )
                packages = result.stdout.splitlines()[1::2]
                self.assertIn(f"libavcodec{abi}", packages)
                self.assertIn(f"libavformat{abi}", packages)
                self.assertIn("ca-certificates", packages)
                self.assertFalse([p for p in packages if "-dev" in p or "qmake" in p], packages)
                if distro == "raspbian" and release == "bullseye":
                    self.assertIn("libssl1.1", packages)
                if not (distro == "raspbian" and release == "bullseye"):
                    self.assertIn("libgstreamer-plugins-base1.0-0", packages)
                    self.assertIn("libqt5location5-plugin-mapboxgl", packages)
                    self.assertIn("qml-module-qtlocation", packages)
                    self.assertIn("qml-module-qtpositioning", packages)
                    self.assertIn("libqt5sql5-sqlite", packages)
                    self.assertIn("ca-certificates", packages)
                    self.assertIn("libqt5opengl5", packages)
                    self.assertIn("libqt5texttospeech5", packages)
                    self.assertIn("qml-module-qtquick-controls2", packages)


if __name__ == "__main__":
    unittest.main()
