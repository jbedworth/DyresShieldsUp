# Changelog

Player-facing changes for each Dyre's Shields Up release, newest first. The
release builder copies the section for the TOC version into the GitHub release
notes and the CurseForge changelog, and fails if that section is missing.

## 1.5.2

### Other changes

- The login message follows Dyre's Toolkit's "Welcome messages at login" switch (Toolkit 2.14.0 or later). Errors still show.

## 1.5.1

### Other changes

- When Mage Tools Forever draws the shield display, the "Display size" slider on DSU's settings page now shows a gold mark at its default size (100%), as the other Dyre's AddOns sliders do.

## 1.5.0

### Other changes

- **What moved:** from Dyre's Shields Up into Dyre's Buff Reminders 1.13: the arcs and sounds for Missile Barrage, Fingers of Frost, Nightfall, Decimation, Druid and Shaman Clearcasting, Overpower, and Revenge, with their art and your settings. Absorb shields stay in Dyre's Shields Up.
- **Dyre's Shields Up now shows shields only.** DSU's settings page has a button that opens Dyre's Buff Reminders, and DSU says it once in chat on a character that had a proc on. Install Dyre's Buff Reminders from CurseForge to keep them.
- `/dsu debug_procs` is gone with the procs.

## 1.4.1

### Fixes

- The Missile Barrage tooltip's macro now names Arcane Missiles in your game's language, so the macro works when you copy it on a non-English client.

## 1.4.0

### Features

- **Proc overlays.** Dyre's Shields Up now shows an arc on each side of your character, and plays a sound, the moment a proc you have a talent for appears, also in combat. The arcs drain with the proc's time left and go the moment you use it. To start: **Missile Barrage** and **Fingers of Frost** (Mage; with two Fingers of Frost charges both arcs show, and the right one goes when you use one) **Nightfall** and **Decimation** (Warlock), **Clearcasting** (Druid, from Omen of Clarity; Shaman, from Elemental Focus; their sound starts off, since the game already gives a cue), and **Overpower** and **Revenge** (Warrior: the arcs show while you can use the ability, dimmed while you lack the rage; Dyre's Buff Reminders plays their sound). Each proc has its own switches for the arcs and the sound, and its own sound. Only a character who has the talent sees its settings. Unlock to move the arcs, and **Proc arc size** sizes them. This needs Dyre's Toolkit 2.11 or newer; with an older Toolkit, the shields work as before and DSU says once what to update.
- **SpellActivationOverlay:** with that AddOn loaded, Dyre's proc overlays stay off, so you don't get two of each, and DSU says so once in chat. To show both, turn on **Show Dyre's proc overlays with SpellActivationOverlay** (it applies after a `/reload`).
- `/dsu debug_procs` shows one line per proc: whether you know its talent, its buff IDs, the arcs, and the sound.

### Other changes

- The proc arcs, sounds, and settings in Mage Tools Forever's and Warlock Tools Forever's test builds now live in Dyre's Shields Up, with the same settings. Dyre's Buff Reminders' Proc Chimes step aside for a proc Dyre's Shields Up plays, so a proc makes one sound.
- Dyre's Toolkit is now an optional dependency in the TOC, as for every Dyre's AddOn: without it, Dyre's Shields Up still loads and says once to install it.

## 1.3.0

### Features

- Your Dyre's Shields Up settings, the shield display's place and sizes, and its sound are now part of your Dyre's Toolkit profile. On the Toolkit's settings page you can copy them from another character, or export and import them, with the rest of your Dyre's AddOns. A copy applies at once, with no reload. This needs Dyre's Toolkit 2.10.0 or newer; with an older Toolkit, nothing changes.

## 1.2.1

### Fixes

- Classic Era: the icons under the crescent now show which shields are up, and come and go with them, also in combat.
- Classic Era: Mana Shield and the Paladin bubbles (Divine Shield, Divine Protection, Blessing of Protection) drain in their inner crescents again.
- Classic Era: the crescent shows your shield's amount. The game gives AddOns no absorb amount there, so Dyre's Shields Up starts from the shield's base absorb for its rank and takes off what the combat log says each hit absorbed. A ward only goes down on hits of its own school. A shield of a rank it doesn't know drains with its time left instead, with no number.
- Classic Era: a shield that breaks early now disappears at once, also in combat.

## 1.2.0

### Features

- Coming from Mage Tools Forever or Warlock Tools Forever? The first time Dyre's Shields Up runs on a character, it copies that class's AddOn's shield settings once: place, sizes, the number, and the sound. It says so in chat. Settings Dyre's Shields Up already has on a character are never replaced.

## 1.1.1

### Other changes

- Size sliders are labeled without "(%)": their values already show the % sign.

## 1.1.0

### Features

- The shield display is a **Dyre's Toolkit** widget: the toolkit places, drags, snaps, sizes, and saves it, with the same rules as every other Dyre's AddOn frame. Your saved place and size carry over.
- **Display size** now sizes only the crescents. The absorb number and the icons keep their size, and each has its own slider: **Text size** and **Icon size**. All three have a gold mark at 100%, and **Reset size** puts them all back.

### Fixes

- Changing **Display size** keeps the display where it is: it grows and shrinks from its center instead of moving right and up.

### Other changes

- Needs Dyre's Toolkit 2.0 or later; the CurseForge app installs it. Without it, DSU stays off and says once in chat to install it from CurseForge.

## 1.0.0

The first full release for WoW: Forever, no longer marked beta: it was play tested on the Forever beta client 1.60.1, build 70450. CurseForge now offers it as a release, so the app updates it and installs what it needs for every player.

- The CurseForge app installs Dyre's Toolkit and Dyre's Sounds with it.

## 0.3.2-beta

- Works with **Dyre's Toolkit**: one layout mode for all of Dyre's AddOns. `/dsu unlock`, `/dyre unlock`, the minimap button, or **Unlock frames** on the Dyre's AddOns page unlocks every Dyre's AddOn's frames at once, and the shield display snaps to their frames and to the grid. Its settings move under **Options → AddOns → Dyre's AddOns → Dyre's Shields Up**, and it is listed under Dyre's Toolkit in the AddOn list. The CurseForge app installs the toolkit with DSU.
- With the toolkit, DSU's page no longer has its own "Unlock to move it" switch; the toolkit's **Unlock frames** does it for every Dyre's AddOn.
- Without the toolkit, DSU works as before, with its own unlock switch, and says once at login to install it from CurseForge.

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
