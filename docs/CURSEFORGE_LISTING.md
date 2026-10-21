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
**Dyre's Shields Up** shows your remaining shield as a crescent beside your character, for any class. It is the shield display from Mage Tools Forever, on its own.

### Shield display
- Fills when a shield lands and drains as it absorbs, with the amount below, also in combat. Drops away the moment the shield is used up.
- Power Word: Shield in white, Ice Barrier blue, the wards in fire and frost, Warlock shields in purple, and any other absorb in gold.
- Several shields at once? The crescent shows the total, and a row of icons shows which are up: your own class's shields, then Power Word: Shield and Blessing of Protection.
- Mana Shield and Paladin bubbles drain with their time left in their own inner crescents.
- Crescent, text, and icon sizes 50-150% each, an optional number, and an optional sound when a shield ends (from Dyre's Sounds, which the CurseForge app installs with it).

### With Mage Tools Forever or Warlock Tools Forever
They ship the same display. Installed together, you still see one ring, and Dyre's Shields Up tells you which AddOn draws it.

### With Dyre's Toolkit
Needs Dyre's Toolkit 2.0 or later, which the CurseForge app installs with it: one layout mode for all of Dyre's AddOns. The shield display is a toolkit widget: unlocking unlocks every Dyre's AddOn's frames at once, the display snaps to their frames and to the grid, Display size grows the crescents from their center while Text size and Icon size keep the number and the icons as you like them, and its settings sit under Options > AddOns > Dyre's AddOns.

### Commands
- `/dsu` or `/dsu options` opens the settings.
- `/dsu unlock`, `/dsu lock`, and `/dsu reset` move the display (unlocking unlocks all of Dyre's AddOns).
- `/shieldsup` works the same, in case another AddOn uses `/dsu`.

### Compatibility
For the Forever beta client 1.60.1 (tested on build 70450). If a client update removes an API it needs, it says so in chat and the display stays off.

WowUp users (2.24.0 or later): install from the repository URL; GitHub releases carry the Forever metadata WowUp needs.

Source, issues, and license (MIT): https://github.com/jbedworth/DyresShieldsUp
```
