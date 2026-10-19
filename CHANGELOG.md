# Changelog

Player-facing changes for each Shields Up Forever release, newest first. The
release builder copies the section for the TOC version into the GitHub release
notes and the CurseForge changelog, and fails if that section is missing.

## 0.3.1-beta

- If another of Dyre's AddOns draws the shield display (an older Mage Tools Forever or Warlock Tools Forever), DSU's settings are greyed out and name it. From 0.3.1, Mage Tools Forever and Warlock Tools Forever leave the shield display to DSU when it is installed.

## 0.3.0-beta

- The sounds now come from **Dyre's Sounds**, so they are on your computer only once for all of Dyre's AddOns. The CurseForge app installs it for you; otherwise get it from CurseForge or github.com/jbedworth/DyresSounds. Without it, the shield display works as before but plays no sound, and DSU says so once in chat.
- Your chosen sound when a shield ends is kept.

## 0.2.1-beta

- Shield display: the outer crescent is centered with the inner ones again; since the last update it was drawn lower and taller than them.

## 0.2.0-beta

- Renamed from Shields Up Forever to **Dyre's Shields Up**. The command is now `/dsu` (`/shieldsup` still works), and the AddOn folder is `DyresShieldsUp`. Delete the old `ShieldsUpForever` folder; your settings start fresh, since the game keeps them by folder.
- Tiny shields no longer flicker the crescent: absorbs under 25 points or 5% of your health, whichever is larger, are not drawn (a Paladin's Seal of Righteousness gives one of 10-20 points).
- The sound when a shield ends now plays (the old sound did not play on Forever). Choose it from nine sounds under the switch; choosing one plays it.

## 0.1.0-beta

- Shield display for any class: a segmented crescent beside your character that fills with your remaining shield (Power Word: Shield, Ice Barrier, a ward, or any other absorb on you), in the shield's color, with the amount, also in combat. It drops away the moment the shield is used up.
- An icon row under the crescent shows which shields are up: your own class's shields, then the ones anyone can put on you (Power Word: Shield, Blessing of Protection). Mana Shield and Paladin bubbles drain with their time left in their own inner crescents.
- Settings: turn the display or the number off, a sound when a shield ends, and a size from 50 to 150%. Unlock to drag it; `/suf reset` puts it back.
- Works alongside Mage Tools Forever and Warlock Tools Forever: only one display shows, and SUF tells you which AddOn draws it.
- Settings are saved per character.
