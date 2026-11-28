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

A crescent beside your character that shows how much shield you have left, for any class and any absorb. For WoW: Forever and Classic Era.

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
I kept getting surprised when my shield broke. I'd cast a shield, pull, and then have no idea how much of it was left without digging through my buffs. So I made Dyre's Shields Up. It puts a crescent beside your character that fills when a shield lands and drains as it soaks up hits, with the amount right under it. It works for any class, and it's the same shield display that Mage Tools Forever and Warlock Tools Forever use.

### What you get
- **Live tracking.** The crescent drains with each hit and the number counts down with it, in combat, in battlegrounds, and in boss fights. It disappears the moment the shield breaks.
- **A color for each shield.** Power Word: Shield is white, Ice Barrier is blue, Fire Ward is orange, and Frost Ward is pale blue. A Warlock's Shadow Ward and Sacrifice are purple, and any other absorb, like a trinket or a potion, is gold.
- **One total for several shields.** With more than one shield up, the crescent shows them all added together. A row of icons under the number tells you which ones they are, your own class's shields first, then Power Word: Shield and Blessing of Protection. Each icon drops off when its shield breaks.
- **Timed shields.** Mana Shield and a Paladin's Divine Shield, Divine Protection, and Blessing of Protection don't have an absorb amount, so they drain with their time left instead. Each gets a thinner crescent inside the main one.
- **No tiny absorbs.** Small ones, like a Paladin's Seal of Righteousness, never show.
- **Three sizes.** Display size grows or shrinks the crescents, Text size sets the number, and Icon size sets the icons. Reset size puts all three back to 100%.
- **An optional sound.** Pick a sound from Dyre's Sounds to play when a shield ends or breaks. You can turn the number off too.
- **One main switch.** Turn off Shield display and everything under it greys out, so you can tell at a glance what's on.
- **Clicks go through.** While it's locked, your clicks pass right through it to the world. Unlock it to drag it anywhere, and it snaps next to the frames of my other AddOns.

### If you play a Mage or a Warlock
Mage Tools Forever and Warlock Tools Forever use this shield display, and the CurseForge app installs Dyre's Shields Up with them. With Dyre's Toolkit 2.17.0 or newer, their Shield pages can show every shield setting as soon as each of them supports it, with the Shield display switch next to their other main switches. The first time Dyre's Shields Up runs on a character, it copies your shield settings from those AddOns once and tells you in chat.

### Proc arcs moved
Dyre's Shields Up 1.4 also had proc arcs and sounds for Missile Barrage, Nightfall, Clearcasting, and a few others. They're in Dyre's Buff Reminders now, with your choices kept. Dyre's Shields Up shows only shields.

### Commands
- `/dsu` opens the settings.
- `/dsu unlock` and `/dsu lock` unlock and lock the frames of all my AddOns.
- `/dsu reset` puts the display back in its default place.
- `/dsu debug_shield` prints details in chat. Please include them if you report a problem.
- `/shieldsup` does the same as `/dsu`, in case another AddOn already uses `/dsu`.

### What gets installed with it
Dyre's Shields Up needs Dyre's Toolkit 2.0 or newer, and the CurseForge app installs it for you, along with Dyre's Sounds. The Toolkit puts the settings for all my AddOns in one place, under Options > AddOns > Dyre's AddOns > Shields Up. One unlock moves every frame at once, and you can copy one profile to your other characters.

### Compatibility
I made it for World of Warcraft: Forever 1.60.1, and it runs on Classic Era 1.15.9 too. Classic Era doesn't tell AddOns how big a shield is, so there the number starts at the shield's base amount for its rank and counts down with each hit. The game also gives AddOns no way to play the end-of-shield sound on Classic Era, so it doesn't play there.

WowUp users on 2.24.0 or later can install from the repository URL. The GitHub releases carry the Forever metadata WowUp needs.

Let me know what you think in the comments! If something's broken, you can also open an issue at https://github.com/jbedworth/DyresShieldsUp/issues.

Dyre's AddOns are free. If you enjoy them, you can support them on Ko-fi: https://ko-fi.com/dyre_janelle

Source and license (MIT): https://github.com/jbedworth/DyresShieldsUp
```
