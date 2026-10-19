"""Shield.lua and its textures must stay byte-identical in every AddOn that ships them.

Compares against sibling checkouts of Mage Tools Forever and Warlock Tools Forever
next to this repository when they exist; skipped otherwise (as in CI).
"""

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SIBLINGS = ("MageToolsForever", "WarlockToolsForever")
SHARED = ("Shield.lua", "Textures/ShieldArc.tga", "Textures/ShieldArcInner.tga",
          "Textures/ShieldArcInnermost.tga")


class ShieldCopyTests(unittest.TestCase):
    def test_shared_files_match_sibling_addons(self):
        found = [ROOT.parent / name for name in SIBLINGS if (ROOT.parent / name / "Shield.lua").is_file()]
        if not found:
            self.skipTest("no sibling AddOn checkout to compare with")
        for sibling in found:
            for name in SHARED:
                with self.subTest(addon=sibling.name, file=name):
                    self.assertEqual((ROOT / name).read_bytes(), (sibling / name).read_bytes(),
                                     f"{name} differs from {sibling.name}'s copy")


if __name__ == "__main__":
    unittest.main()
