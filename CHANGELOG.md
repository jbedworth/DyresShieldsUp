# Changelog

Player-facing changes for each Shields Up Forever release, newest first. The
release builder copies the section for the TOC version into the GitHub release
notes and the CurseForge changelog, and fails if that section is missing.

## 0.1.0-beta

- Shield display for any class: a segmented crescent beside your character that fills with your remaining shield (Power Word: Shield, Ice Barrier, a ward, or any other absorb on you), in the shield's color, with the amount, also in combat. It drops away the moment the shield is used up.
- An icon row under the crescent shows which shields are up: your own class's shields, then the ones anyone can put on you (Power Word: Shield, Blessing of Protection). Mana Shield and Paladin bubbles drain with their time left in their own inner crescents.
- Settings: turn the display or the number off, a sound when a shield ends, and a size from 50 to 150%. Unlock to drag it; `/suf reset` puts it back.
- Works alongside Mage Tools Forever and Warlock Tools Forever: only one display shows, and SUF tells you which AddOn draws it.
- Settings are saved per character.
