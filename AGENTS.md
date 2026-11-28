# Agent Guidelines

## Project purpose and scope

Dyre's Shields Up (DSU, `/dsu`) is a World of Warcraft: Forever AddOn that
ships the shared shield display from Mage Tools Forever (MTF) on its own, for
any class (author-approved: a Priest in the author's group asked for it).
Shields only: the proc overlays (arcs and sounds), here in 1.4.x, moved to
Dyre's Buff Reminders in 1.5.0 (John, 2026-11-20: DBR is "a better fit for
all buffs/procs ... This lets DSU focus on managing just absorption shield
rendering"). Keep this feature set; do not add speculative features or
frameworks without agreement.

Naming (author-approved): renamed from Shields Up Forever (SUF, `/suf`)
before its CurseForge release. The title starts with "Dyre's", so players
can find all of the author's AddOns by searching for it. The apostrophe is
only in the title: the folder, TOC, repository, saved variables, and globals
use `DyresShieldsUp`. Commands `/dsu` and `/shieldsup` (the author's
backup), chat prefix `DSU:`. Listings say plainly that it is for WoW:
Forever.

### Shield.lua is shared (author-approved, important)

- Shield.lua and Textures/ShieldArc.tga, ShieldArcInner.tga, and
  ShieldArcInnermost.tga (built by scripts/build_arc.py) were shared with MTF
  and Warlock Tools Forever (WTF). Since MTF 1.2.0 and WTF 1.3.0 only DSU
  ships them; older copies still elect one ring through the registry, so a
  behavior change still bumps `VERSION`. No test compares copies across
  repositories (author: "that's a stupid thing to test for a shared
  resource"). Keep DSU's own needs in Core.lua and Options.lua.
- Its whole interface: `ShieldDisplay.Initialize({settings, report,
  unlockHint, missingSounds, layout})`, `Sanitize` (it owns its defaults, the lock included),
  `SanitizeScale` and the scale constants, `SIZE`, `DEFAULT_PLACE`,
  `DEFAULT_BREAK_SOUND`, `SanitizeBreakSound`, `SoundChoices`, `SetupSoundMenu`,
  `PreviewBreakSound`, `Refresh`,
  `ApplyBreakSound`, `ResetPosition`, `ReportDebug`, `IsOwner`, and
  `OwnerAddOn`.
- Scope (author-approved): Shield.lua stays as it is. Its icon row holds the
  player's own class's shields (`class` on each entry), then the shared ones
  (Power Word: Shield, Blessing of Protection). Class shields only land on
  their caster, so every class already sees every shield that can be on it;
  a Priest's row is Power Word: Shield and Blessing of Protection. Classic
  Priests have no other absorb, so there are no Priest entries.
- Duplicates reconcile to one ring through the global `ShieldForeverRegistry`:
  each copy registers as its file loads and takes part once its AddOn calls
  `Initialize` (MTF only on a Mage, WTF only on a Warlock, DSU on any class).
  The newest `VERSION` draws, the first registered on a tie; the others draw
  nothing and say once which AddOn shows it. DSU's settings then do nothing,
  so `/dsu unlock`, `lock`, `reset`, and `options` say which AddOn to use
  (`DSU.ShownElsewhere`).
- The display's rules, from MTF's AGENTS.md (keep them): `UnitGetTotalAbsorbs`
  is always secret and is only passed, unread, to `StatusBar:SetValue`,
  `SetMinMaxValues`, `AbbreviateNumbers`, `FontString:SetText`, and
  `SetAlpha`; never compare or do math on it. Aura APIs error in combat; read
  buffs only out of combat. The icon row is a Blizzard AuraContainer with
  `includeSpellIDs` as a set; icons' `IsShown` is secret, so each shield has a
  fixed spot. The frame is plain (not secure), locked by default, and takes the
  mouse only while unlocked.
- Version 4 (with MTF and WTF): each crescent texture spans its own height (scripts/build_arc.py
  stretches it; Shield.lua's `*_SPAN` constants match, checked by a Python
  test), and every crescent texture and bar is drawn at that height. A
  StatusBar fills its whole height, so across the full square a timed bar
  emptied a segment or more before its buff ended (found in client; the
  fix confirmed on a Mage).
- Version 5 (with MTF and WTF; found in client): absorbs
  under the larger of 25 points and 5% of max health (25 when max health is
  secret) never show; a Paladin's Seal of Righteousness proc, 10-20 points,
  flickered the ring. The absorb cannot be compared, so a hidden gate
  StatusBar, one point wide and ending at the minimum, takes it as its value,
  and a clipping frame anchored to the gate's fill holds the crescent and the
  number (confirmed on a Paladin). Fixed constants, no setting.
- Version 6 (with MTF and WTF; found in client): the break sound is one of
  the AddOn's own files in Sounds/, byte-identical in all three, chosen in a
  dropdown under the sound switch (author-approved: a default you can change,
  Fading slow disappear). The client plays no game sound by path
  (RaidWarning.ogg stayed silent), while an AddOn's file plays, also through
  `C_UnitAuras.AddAuraSound` when a buff runs out. Turning the sound on, or
  choosing one, plays it once. The sounds are licensed to Vertiso Corporation
  from Envato (Elements and AudioJungle; the author keeps the license files,
  not in Git); they are not under the MIT License.
- Version 8 (with MTF and WTF): no AddOn ships sound files (author-approved:
  one copy for all of Dyre's AddOns). The break sound comes from the library
  Dyre's Sounds (`DyresSounds.RequireContract(1)`; its aura sounds: Dyre's
  Picks and game file IDs), listed as `## OptionalDeps: DyresSounds` and as a
  required dependency (slug `dyres-sounds`) on CurseForge. Interface:
  `SoundChoices()` and `SetupSoundMenu(initializer)` replace `BREAK_SOUNDS`.
  Without the library the display works, a saved choice is kept, and turning
  the sound on says once in chat to install Dyre's Sounds.
  A host with other sounds passes `missingSounds` to `Initialize`, and the
  display calls it instead of its own line, so each AddOn says it once
  (author-approved: one line per AddOn).
- Version 9 (with MTF and WTF): a host may pass `layout = {register,
  beginDrag, endDrag}` to `Initialize` (Dyre's Toolkit's `RegisterMovable`,
  `BeginDrag`, `EndDrag`); the ring registers with it and drags through it,
  so it snaps to the host's other frames and the grid, and the layout's
  `save(position)` stores the position. Without one it drags freely as before.
- Version 10 (shipped first in DSU 1.1.0; MTF and WTF copy it): a widget
  host passes `layout = {adopt(frame), resetPosition(frame)}`. The display
  builds the ring (`SIZE` square, default place `DEFAULT_PLACE`), then calls
  `adopt`; an adopted ring is the host's to place, drag, scale, outline, and
  save, and the display never touches its points, scale, mouse, or movability
  (author's rule: all layout lives in the toolkit). The display still fills
  it, shows or hides it, and shows the sample while the settings say
  unlocked. For any other host (v9's `{register, beginDrag, endDrag}`, or no
  layout), a scale change keeps the ring's center (found in client: a bare
  `SetScale` moved a ring anchored CENTER to UIParent's corner right and up)
  and saves `{CENTER, BOTTOMLEFT, x, y}`, as the toolkit's ResizeFromCenter
  does; only when it is placed and the scale really changed. The ring is
  scaled before it is placed at login, so saved offsets (in its own scaled
  units) land where they were. Shield.lua never names Dyre's Toolkit.
- Version 11 (with v10 in DSU 1.1.0; author-approved: large crescents with a
  large number were disconcerting): `scale` sizes the crescents only. The
  number and the icon row have their own sizes, `textScale` and `iconScale`
  (50-150%, from `Sanitize`), each in a frame scaled by its size over the
  crescents' scale, anchored with no offsets (the number to a point at the
  crescent's foot, the icons to the number), so they follow the crescents
  without growing. The number keeps the opacity frame and has a gate of its
  own (the same one-point range), since the crescent's clip no longer reaches
  below the ring. The engine's slots are never resized: icons and timed
  crescents are separate slots in two AuraContainers, the icons' under the
  icon row's frame, the timed crescents' in the ring (so they grow with the
  outer crescent), each set up only in its initializeFrame. A host without
  part sliders gets the number and the icons at 100%.
- Version 12 (DSU 1.5.3; a player's report, 2026-11-26: no shields in
  battlegrounds on Forever): while an AddOn restriction that hides auras is
  active (`AURA_RESTRICTIONS`: Encounter, ChallengeMode, PvPMatch;
  `C_RestrictedActions.IsAddOnRestrictionActive`), out of combat too,
  `GetAuraDataBySpellName` returns nothing for buffs that are up (found in
  client by Dyre's Buff Reminders 1.13.2 in an encounter; PvPMatch inferred).
  `CheckBuffs` ended every shield then, so the ring hid out of combat in a
  match. Now `AurasHidden()` (combat, or such a restriction; never on Classic)
  stops `CheckBuffs` and keeps the display shown as in combat, its opacity the
  absorb; `ADDON_RESTRICTION_STATE_CHANGED` reads the buffs again. Map is not
  one (aura reads worked in Deadmines with it). `/dsu debug_shield` prints
  `auraRestriction` and `aurasHidden`.
- Classic Era and Anniversary (not yet released there; found in client on
  Era 1.15.9: the icons and Mana Shield's crescent showed, the outer ring was
  a faint ghost): no engine aura slots, so AuraEngine.lua's plain-Lua slots
  (copied from WTF) draw the icon row and the timed crescents; nothing is
  secret and buffs are readable in combat, so CheckBuffs runs in combat there
  and the ring shows only while a shield is up. The client's absorb total
  stays 0 and the buffs' points are empty there (Era, Fire Ward), so on that
  client only (`PlainClient`, the "lua" engine) `CLASSIC_AMOUNT` picks the
  amount: "auto" (the total when above 0, else `AuraData.points[1]` when it
  carries one, else the log, else the crescent drains with the time left
  through `StatusBar:SetTimerDuration` and shows no number), or "log",
  "points", "time" alone. The log: each rank's base absorb (`BASE_ABSORB`,
  Classic values without spell power, to be checked in client; seeded from
  your cast, or the buff's spell ID for a shield from someone else) less the
  `SPELL_ABSORBED` amounts from `COMBAT_LOG_EVENT_UNFILTERED`, registered only
  on that client for "auto" and "log" (Forever refuses it). A ward's amount
  drops only on its own school's hits.
  Forever never reaches any of it. The size is the most seen since the cast.
- Version 7 (with MTF and WTF; found in client): every crescent is anchored
  to the display itself. In v5 and v6 the outer crescent was fitted to its
  parent, the minimum-absorb clipping frame, which reaches 40 px below the
  display for the number, so it was drawn lower and taller than the inner
  crescents (seen on a Mage with Fire Ward and Mana Shield).

### DSU's own parts (built)

- One settings page, "Shields Up" under Dyre's Toolkit's "Dyre's AddOns"
  (vertical layout, proxy settings on `DyresShieldsUpDB.shield`): Shield
  display, Show the absorb amount, Sound when a shield ends and its Sound
  choice, then the toolkit's sliders (`AddWidgetSettings`, 50-150% in steps
  of 5, each with its default mark): Display size (the crescents), Text size,
  and Icon size, and Reset size for all three; labels carry no "(%)", since
  the values show the % sign. While another AddOn draws the
  ring, a greyed slider of DSU's own keeps the saved size.
- The shield settings section (DSU 1.6.0; John, 2026-11-26: class AddOns
  "should surface every setting in the wrapped addon's settings, and just
  pass-through the setting to the wrapped addon"; 2026-11-27: "Fix the
  settings delegation in MTF and WTF"): Options.lua's `BuildShieldSection`
  draws every row above, on DSU's page and on a host's page, through Dyre's
  Toolkit 2.17.0's settings sections (key `shield`; Toolkit AGENTS.md
  "Settings sections"). Core registers it at ADDON_LOADED, after LoadDB (a
  host builds its page at its own PLAYER_LOGIN, which can come first). Every
  variable goes through `ctx.variable`: prefixed (`DYRE_<HOST>__`) on a host
  page, as named on DSU's (`OwnSettingsContext`). Settings are read only in
  get, set, and predicates. Sizes: with the ring a widget, the toolkit's
  `AddWidgetSettings` (on a host page with `opts.variable`, sections version
  2); with no widget yet on a host page (its login came first), or a version
  1 toolkit, `AddHostSizes`: the same three sliders, the toolkit's variable
  names prefixed, and Reset size, writing through the widget once it exists,
  else the saved sizes repaired with `SanitizeScale`. Do not copy the
  toolkit's rows for anything else (lead, 2026-11-27: a copy drifts from its
  default marks, greying, and watch rules). The Reset row's name (1.6.1;
  John, 2026-11-27, from WTF's page: one name per section, as WTF's Crowd
  Control page): "Shield display" on a host page (`opts.resetName`, toolkit
  flag `WIDGET_RESET_NAME`; `HostResetName` for `AddHostSizes`), "Dyre's
  Shields Up" on DSU's page and with an older toolkit. The display is the same
  for every class, so `ctx.class` and `ctx.filter` change nothing. The build
  returns false (the host shows its link) without the Settings API, before
  the saved settings load, or after DSU's login found it cannot run. Not in
  the section: the "Procs moved" link and "Unlock to move it", which belong
  to DSU's page. Without sections (a toolkit older than 2.17.0), DSU's page is
  as before. Not confirmed in client.
- One name (John, 2026-11-27: "the same name used consistently everywhere"):
  "Shield display" (`SECTION_TITLE`) is the switch on DSU's page and on a
  host's top page, and the section's registered title, which hosts read with
  `SettingsSectionTitle` for their sub-page. DSU's page title stays
  "Dyre's Shields Up" (the AddOn).
- Parts and greying (sections version 3; John, 2026-11-27, from his test of
  MTF's Shield page: "when the top-level is off, the settings that are
  controlling a disabled feature should be disabled too. Also, the top-level
  disable for each section should be on the top-level MTF panel"):
  `ctx.part` "master" draws "Shield display" alone (a host's top page),
  "rest" every other row (the host's Shield page), "all" (or none, before
  version 3) both. A row is greyed while DSU does not draw the ring or any
  switch above it is off (`Allowed` with `UNDER_DISPLAY`, `UNDER_SOUND`): the
  whole chain is checked in each row's modify predicate, so it also works on
  a host's Shield page where "Shield display" is on another page. The Sound
  dropdown keeps `SetParentInitializer` to its switch (always on the same
  page). The toolkit's sliders and Reset get the same check through
  `AddWidgetSettings` `opts.modify` (ignored before version 3); DSU's own
  host sliders and Reset (`AddHostSizes`) add it themselves. The greying
  applies on every toolkit; only the sliders from `AddWidgetSettings` need
  version 3 for it.
- Watching (Toolkit 2.17.0 `WatchSettings`, found by DBR): Blizzard checks a
  row's modify predicates again only when its direct parent's setting changes
  (Blizzard_SettingControls.lua 297-302), so a row greyed by a switch that is
  not its parent would change only when the page draws again. Each greyed row
  watches its switches' variables through `ctx.variable` (`Watch`, the
  initializer's own `AddEvaluateStateCVar`): "Shield display" for every row
  under it, and the sound switch too for Sound; `AddWidgetSettings` gets
  `opts.watch`. On a host's Shield page the watched "Shield display" is the
  top page's, under the same prefix. Feature-tested; without it, rows grey
  when the page draws again.
- Dyre's Toolkit 2.0 (contract 2) is required (author: "all the widget layout,
  snapping, modifier key move rules, etc., centralized in Dyre's Tools"):
  `## OptionalDeps: DyresToolkit` (the family rule, Dyre's Toolkit AGENTS.md
  "The family": never `## Dependencies`, which stops it loading; changed in
  the proc overlays' Phase 0), a CurseForge required dependency (slug
  `dyres-toolkit`). Core's `DSU.Toolkit()` checks the contract and the
  functions DSU uses; without them DSU stays off and says once to install or
  update it, naming only CurseForge. The display's `layout.adopt` makes the
  ring a widget (`CreateWidget`: key `shield`, store `DyresShieldsUpDB.shield`
  with its `position` and `scale` keys as saved before, `sizes.scale`, mouse
  "unlocked", sizes `scale`, `textScale`, and `iconScale`); `onLayout`
  refreshes the display, which re-scales the number and the icons; `onUnlock`
  sets `locked` and refreshes the display, which shows the sample. No widget opacity: the ring's inner frame's alpha is the secret
  absorb, and the widget's own alpha is never set. `/dsu unlock` and `lock`
  call the toolkit's lock; `/dsu reset` resets the widget; the page opens
  through `OpenSettings`, never in combat. DSU never moves, scales, or saves
  the ring itself. tests/run.lua loads the real toolkit from ../DyresToolkit
  when that checkout is there, else the copy in tests/toolkit (as in CI); no
  test compares the two, and a test checks that the toolkit it loads offers
  contract 2 and the functions DSU calls.
- Dyre's Toolkit Profile (Toolkit 2.10.0; John, 2026-11-15/17: one profile
  per character, owned by the Toolkit, with "every setting for every Dyre
  addon"): `JoinProfile` in Core calls `RegisterProfilePart` at
  PLAYER_LOGIN, after the settings copy from MTF or WTF and before the ring
  is built, only when the Toolkit has it (older Toolkits: nothing changes;
  the minimum Toolkit stays contract 2). The part is `DyresShieldsUpDB`;
  `sanitize` is `DSU.SanitizeDB` (repairs any table, `{}` gives the
  defaults). Key audit:
  - `shield` (in the profile): every setting (enabled, number, breakSound,
    breakSoundKey, scale, textScale, iconScale) and the ring's `position`.
    `shield.locked` goes along but means nothing there: `refresh` sets it
    from the Toolkit's lock.
  - `migratedFrom` (a `characterKeys` entry, stays per character): the
    record of this character's one-time copy from MTF or WTF, not a setting.
  `refresh` is `DSU.ApplyProfile`: the lock from the Toolkit,
  `ReapplyWidgets` for the ring's place and sizes (the engine writes the
  table in place, so the widget's store is the same table), then
  `RefreshShield` (the number, the text and icon sizes, the colors, and the
  break sound). Live, no reload. No account table is registered.
- Settings from MTF and WTF (author-approved, 1.2.0, the first step of DSU
  drawing the shield for everyone): `DSU.CopyShieldSettings` at PLAYER_LOGIN,
  before the display starts, only when `DyresShieldsUpDB` was nil at load
  (`DSU.newCharacter`) and `db.migratedFrom` is unset. The source is by class
  (`MageToolsForeverDB.shield` on a Mage, `WarlockToolsForeverDB.shield` on a
  Warlock), since both make a default shield table on every class. Keys one
  to one (enabled, number, breakSound, breakSoundKey, scale, textScale,
  iconScale, position; never locked, the toolkit's), through `Sanitize`, so
  the copy is new tables and the source is never written. It records
  `migratedFrom` and says once "Copied your shield settings from <AddOn>."
  An AddOn disabled at that login is not loaded, so nothing is copied.
- Proc cues moved to Dyre's Buff Reminders (1.5.0; John, 2026-11-20, "start").
  DSU 1.4.x drew proc arcs and played their sounds through Dyre's Toolkit's
  proc engine (2.11); DBR 1.13.0 (Toolkit 2.12.0) now holds the catalog, the
  art, the localized Missile Barrage macro, `procsWithSAO`, and the
  SpellActivationOverlay step-aside. Toolkit 2.12.0 draws a proc only while
  the registering AddOn owns its kind, and DBR claims at priority 20 over
  DSU's 10, so a DSU 1.4.x beside DBR 1.13.0 steps aside by itself.
  - No `RegisterProcs`, no Procs rows, no "Proc arc size", no
    `/dsu debug_procs` (it now shows the usage), no SAO step-aside.
  - The 1.4.x proc data stays in DyresShieldsUpDB as saved
    (`DSU.LEGACY_PROC_KEYS`: `procs`, the switches, sounds, the arcs' place
    and size; `procIDs`; `procsWithSAO`): `SanitizeDB` never repairs or
    removes it, since DBR 1.13.0 reads it once to import it. All three, and
    `procsMovedNoted`, are profile `characterKeys`, so a profile copy or
    import never writes them and they are never exported.
  - Settings: one row, "Proc cues moved to Dyre's Buff Reminders", the
    Toolkit's `AddSettingsLink` (2.3.0) to DBR's page ("Open Buff
    Reminders"), greyed while DBR has not joined the toolkit, with the note
    "... install it from CurseForge to keep them."; with an older Toolkit,
    no row. Every class gets it.
  - Chat, once per character (`db.procsMovedNoted`, set at the first 1.5.0
    login either way): "Proc arcs and sounds moved to Dyre's Buff
    Reminders.", only when 1.4.x left a proc of the character's own class
    (Procs.lua's `LEGACY_CLASS_PROCS`, the 1.4.x catalog's keys) with its
    arcs or sound on. 1.4.x saved a switch for every key on every character,
    so other classes' keys say nothing.
  - Art: Textures/ArcaneArc.tga, ArcaneArcLeft.tga, and
    scripts/make_arcane_arcs.py left DSU in 1.5.0; DBR 1.13.0 has the copy.
- Commands: `/dsu` and `/dsu options`, `unlock`, `lock`, `reset`,
  `debug_shield` (runs even when DSU is unavailable). Backup slash
  `/shieldsup`; a clash on `/dsu` is reported once at login.
- No class gate. DSU turns off only for a mixed install (missing Shield.lua or
  namespace functions); the shield component itself reports a client without
  the absorb API.

## Project structure

- Runtime files: DyresShieldsUp.toc, Commands.lua, Core.lua, AuraEngine.lua, Shield.lua,
  Procs.lua, Options.lua, loaded in that order, plus the three shield textures. Procs
  says where the proc cues went (the settings link and the one chat line) and
  names the 1.4.x proc data left for DBR. Commands parses
  `/dsu`; Core owns saved settings, the login banner, install checks, slash
  conflict reporting, the lock, and startup; AuraEngine (copied from WTF) gives
  the icon row plain-Lua aura slots where the engine is missing (Classic Era
  and Anniversary); Options owns the settings page.
- tests/run.lua holds the Lua 5.1 mock suite. tests/test_*.py cover the
  release helpers in scripts/, that the committed textures match
  scripts/build_arc.py, and that the shared files match MTF's and WTF's.
  .github/workflows/ holds CI, opt-in publishing, and the approval gate check.
- README.md is the user-facing overview, TESTING.md the verification method,
  source evidence, and in-client checklist, docs/RELEASE_PLAN.md the release
  process, docs/CURSEFORGE_LISTING.md the CurseForge form text, and
  CHANGELOG.md the per-release change list.
- Documentation describes purpose, design, rules, and methodology. Do not add
  dated status reports or test-result logs to the docs; CHANGELOG.md is the
  release record. Keep README's verified and not-yet-verified lists true.
- The project uses the MIT License. The public author name is `Dyre` (TOC
  `## Author`, login banner, listings); LICENSE keeps the legal name, John
  Bedworth, and the release builder requires that exact notice.
- The TOC has `## Group: DyresToolkit`, so the in-game AddOn list nests DSU
  under Dyre's Toolkit with the rest of Dyre's AddOns (the family groups under
  the toolkit). Keep `## Category: Buffs & Debuffs` identical to the
  CurseForge main category, because the list groups by exact text.
- Add no other runtime assets without agreement.
- Git origin: git@github.com:jbedworth/DyresShieldsUp.git. Inspect Git state
  before acting and preserve user work. Text is LF under .gitattributes.

## Client and API verification

- Target: Forever beta 1.60.1, build 70450 (tested in client), Interface 16001,
  Lua 5.1. Pin source review to Gethe/wow-ui-source commit
  `943764493e6b16d63ded3ab304150d1f05e58b57` (the 70338 source; the client
  was tested on 70450). Treat target-client
  documentation and FrameXML as authoritative; Retail and Classic examples are
  references only.
- Do not gate the runtime on client version, build, Interface, or class. Gate
  only on required APIs.
- The target client has Midnight's secret values and AddOn restrictions. Never
  compare, concatenate, index, or print a value that may be secret.
- Never register `COMBAT_LOG_EVENT_UNFILTERED`: the client refuses it.
- WoW APIs can return no values rather than nil; store results in locals before
  passing them to `tostring`. The client may not show Lua error popups, so
  diagnostics report errors in chat.

## Clean coding

- Lua 5.1 syntax and libraries only. Four-space indentation. Prefer local
  variables and functions; share state through the AddOn namespace. Expose
  globals only when WoW requires them (slash commands, saved variables),
  prefixed `DyresShieldsUp` or `DSU`, and the shared `ShieldForeverRegistry`.
- Centralize meaningful constants; avoid unexplained magic numbers.
- Comment sparingly: non-obvious intent, API constraints, or tradeoffs.
- Event-driven work only; no polling or idle `OnUpdate` handlers.

## Safety and error reporting

- Validate commands before changing settings. Treat bad commands, missing APIs,
  and mixed installs as expected failures with concise feedback prefixed
  `DSU:`.
- Never prompt or open popups in combat. Never swallow errors with blanket
  `pcall` handlers or replace the error handler.
- Repair saved settings on load so a damaged or older table cannot break DSU.
- Startup is driven by Core at `PLAYER_LOGIN`; never rely on event handler
  order between files.

## Testing and documentation

- Run `.tools/luarocks-3.13.0-win32/win32/lua5.1/bin/lua5.1.exe tests/run.lua`
  and the bundled `luac5.1.exe -p` for syntax. Run
  `.tools/python-3.13.7/python.exe -m unittest discover -s tests -p 'test_*.py'`
  and actionlint on workflow changes. Report actual results; never invent them.
- Add focused tests alongside behavior changes. Mocks cannot prove
  protected-action rules, secret-value behavior, layout, or taint; those need
  the in-client checks in TESTING.md.

## Releases and collaboration

- Read docs/RELEASE_PLAN.md before packaging or changing release automation.
- Do not create commits, tags, uploads, or releases unless asked.
- Every release needs a `## <version>` section in CHANGELOG.md with
  player-facing changes; the builder puts it at the top of release-notes.md
  and fails without it.
- Package only DyresShieldsUp.toc, Commands.lua, Core.lua, AuraEngine.lua, Shield.lua,
  Procs.lua, Options.lua, LICENSE, Textures/ShieldArc.tga, Textures/ShieldArcInner.tga,
  and Textures/ShieldArcInnermost.tga (no sounds: they ship only in Dyre's
  Sounds) under the top-level `DyresShieldsUp/`
  folder, named `DyresShieldsUp-<version>-forever.zip`, with the builder's
  BigWigs-format `release.json` (flavor `forever`) attached for WowUp.
- Publishing requires repository variables `ENABLE_GITHUB_RELEASES='true'`
  and, for CurseForge, `ENABLE_CURSEFORGE_UPLOADS='true'`, plus
  `CURSEFORGE_PROJECT_ID`, `CURSEFORGE_GAME_VERSION_ID`, and the `release`
  environment secret `CF_API_TOKEN` (an environment secret, never a repository
  secret). Both publish jobs use the `release` environment with a required
  reviewer; verify the gate with `gate-check.yml` before enabling publishing.
- Action pins are full commit SHAs; review any pin change against the GitHub API.
- Commit messages, when requested: imperative, capitalized subject, at most
  about 50 characters, no ending punctuation; short wrapped body when useful.
