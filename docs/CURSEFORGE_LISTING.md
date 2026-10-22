# CurseForge listing

Copy-ready text for the CurseForge project form. Keep it aligned with README.md
and the tested client; do not advertise clients or versions that have not been
tested.

## Project fields

| Field | Value |
| --- | --- |
| Name | Dyre's Shields Up |
| Class | Addons |
| Main category | Buffs & Debuffs. Keep it identical to the TOC `## Category`, which groups the AddOn in the in-game AddOn list. |
| Additional categories | Combat (CurseForge allows up to 4; unrelated ones can send the project back for changes). |
| Author shown | Dyre, set through the CurseForge account's username |
| License | MIT License |
| Logo | artwork/dyres-shields-up-logo.png (1024 x 1024) |
| Source | https://github.com/jbedworth/DyresShieldsUp |
| Issues | https://github.com/jbedworth/DyresShieldsUp/issues |
| Donation | Ko-fi, https://ko-fi.com/dyre_janelle (the project's Donation field) |
| Relations | Required dependencies: Dyre's Toolkit (`dyres-toolkit`) and Dyre's Sounds (`dyres-sounds`). Each upload sets them (`RELATIONS` in scripts/publish_curseforge.py); the project's Default Relations should list the same two. |

## Summary

A crescent beside your character that shows your remaining shield, for any class in World of Warcraft: Forever: Power Word: Shield, Ice Barrier, wards, and any other absorb, also in combat.

## Screenshots

Upload these from `artwork/screenshots/`, with these captions:

| File | Caption |
| --- | --- |
| shield-display.png | The shield display: your remaining absorb, with an icon for each shield that is up. |

## Description

Paste this with the description editor in Markdown mode. Pasted into the rich
text editor, the headings, bullets, and bold show as raw, escaped markdown.

Per-file changelogs need no manual text: each CI upload uses the version's
`CHANGELOG.md` section, through `release-notes.md`.

```markdown
**Dyre's Shields Up** shows your remaining shield as a crescent beside your character, for any class. It is the one shield display for all of Dyre's AddOns: Mage Tools Forever and Warlock Tools Forever use it too.

### Shield display
- Fills when a shield lands and drains as it absorbs, with the amount below, also in combat. Drops away the moment the shield is used up, and tiny absorbs (such as a Paladin's Seal of Righteousness) never show.
- Power Word: Shield in white, Ice Barrier blue, the wards in fire and frost, Warlock shields in purple, and any other absorb in gold.
- Several shields at once? The crescent shows the total, and a row of icons shows which are up: your own class's shields, then Power Word: Shield and Blessing of Protection.
- Mana Shield and Paladin bubbles drain with their time left in their own inner crescents.
- **Display size** grows the crescents from their center (50-150%), while **Text size** and **Icon size** (50-150% each) keep the number and the icons as you like them; **Reset size** puts all three back to 100%.
- An optional number, and an optional sound when a shield ends, chosen from Dyre's Sounds (which the CurseForge app installs with it).

### With Mage Tools Forever or Warlock Tools Forever
Mage Tools Forever (1.2.0 and later) and Warlock Tools Forever (1.3.0 and later) leave the shield to Dyre's Shields Up, and the CurseForge app installs it with them. The first time Dyre's Shields Up runs on a character, it copies that class's AddOn's shield settings once (place, sizes, the number, and the sound) and says so in chat. Settings Dyre's Shields Up already has are never replaced.

### With Dyre's Toolkit
Needs Dyre's Toolkit 2.0 or later, which the CurseForge app installs with it: one layout mode for all of Dyre's AddOns. The shield display is a toolkit widget: unlocking unlocks every Dyre's AddOn's frames at once, and the display snaps to their frames and to the grid. Its settings are under Options > AddOns > Dyre's AddOns > Shields Up.

### Commands
- `/dsu` or `/dsu options` opens the settings.
- `/dsu unlock` and `/dsu lock` unlock and lock every Dyre's AddOn's frames; `/dsu reset` moves the display back to its default place.
- `/dsu debug_shield` shows diagnostics in chat.
- `/shieldsup` works the same, in case another AddOn uses `/dsu`.

### Compatibility
For World of Warcraft: Forever 1.60.1 (tested on build 70450). If a client update removes an API it needs, it says so in chat and the display stays off.

WowUp users (2.24.0 or later): install from the repository URL; GitHub releases carry the Forever metadata WowUp needs.

Source, issues, and license (MIT): https://github.com/jbedworth/DyresShieldsUp
```
