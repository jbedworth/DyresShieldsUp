# Agent Guidelines

## Project purpose and scope

Shields Up Forever (SUF, `/suf`) is a World of Warcraft: Forever AddOn that
ships the shared shield display from Mage Tools Forever (MTF) on its own, for
any class (author-approved: a Priest in the author's group asked for it). Keep
this feature set; do not add speculative features or frameworks without
agreement.

### Shield.lua is shared (author-approved, important)

- Shield.lua is byte-identical in MTF, Warlock Tools Forever (WTF), and SUF,
  and so are Textures/ShieldArc.tga, ShieldArcInner.tga, and
  ShieldArcInnermost.tga (built by scripts/build_arc.py), and the break
  sounds in Sounds/. Never edit SUF's
  copy alone: a behavior change goes into all three copies together, with
  `VERSION` bumped in each. tests/test_shield_copy.py compares the copies when
  sibling checkouts exist. Keep SUF's own needs in Core.lua and Options.lua.
- Its whole interface: `ShieldDisplay.Initialize({settings, report,
  unlockHint})`, `Sanitize` (it owns its defaults, the lock included),
  `SanitizeScale` and the scale constants, `BREAK_SOUNDS`,
  `DEFAULT_BREAK_SOUND`, `SanitizeBreakSound`, `PreviewBreakSound`, `Refresh`,
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
  `Initialize` (MTF only on a Mage, WTF only on a Warlock, SUF on any class).
  The newest `VERSION` draws, the first registered on a tie; the others draw
  nothing and say once which AddOn shows it. SUF's settings then do nothing,
  so `/suf unlock`, `lock`, `reset`, and `options` say which AddOn to use
  (`SUF.ShownElsewhere`).
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

### SUF's own parts (built)

- One settings page (vertical layout, proxy settings on
  `ShieldsUpForeverDB.shield`): Shield display, Show the absorb amount, Sound
  when a shield ends and its Sound choice, Display size (50-150% in steps of 5), and Unlock to move
  it. One frame, so no grid and no magnetic layout.
- Commands: `/suf` and `/suf options`, `unlock`, `lock`, `reset`,
  `debug_shield` (runs even when SUF is unavailable). Backup slash
  `/shieldsup`; a clash on `/suf` is reported once at login.
- No class gate. SUF turns off only for a mixed install (missing Shield.lua or
  namespace functions); the shield component itself reports a client without
  the absorb API.

## Project structure

- Runtime files: ShieldsUpForever.toc, Commands.lua, Core.lua, Shield.lua,
  Options.lua, loaded in that order, plus the three textures. Commands parses
  `/suf`; Core owns saved settings, the login banner, install checks, slash
  conflict reporting, the lock, and startup; Options owns the settings page.
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
- The TOC uses `## Category: Buffs & Debuffs`; keep it identical to the
  CurseForge main category, because the in-game AddOn list groups by exact text.
- Add no other runtime assets without agreement.
- Git origin: git@github.com:jbedworth/ShieldsUpForever.git. Inspect Git state
  before acting and preserve user work. Text is LF under .gitattributes.

## Client and API verification

- Target: Forever beta 1.60.1, build 70338, Interface 16001, Lua 5.1. Pin
  source review to Gethe/wow-ui-source commit
  `943764493e6b16d63ded3ab304150d1f05e58b57`. Treat target-client
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
  prefixed `ShieldsUpForever` or `SUF`, and the shared `ShieldForeverRegistry`.
- Centralize meaningful constants; avoid unexplained magic numbers.
- Comment sparingly: non-obvious intent, API constraints, or tradeoffs.
- Event-driven work only; no polling or idle `OnUpdate` handlers.

## Safety and error reporting

- Validate commands before changing settings. Treat bad commands, missing APIs,
  and mixed installs as expected failures with concise feedback prefixed
  `SUF:`.
- Never prompt or open popups in combat. Never swallow errors with blanket
  `pcall` handlers or replace the error handler.
- Repair saved settings on load so a damaged or older table cannot break SUF.
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
- Package only ShieldsUpForever.toc, Commands.lua, Core.lua, Shield.lua,
  Options.lua, LICENSE, Textures/ShieldArc.tga, Textures/ShieldArcInner.tga,
  Textures/ShieldArcInnermost.tga, and the break sounds in Sounds/ under the top-level `ShieldsUpForever/`
  folder, named `ShieldsUpForever-<version>-forever.zip`, with the builder's
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
