# Reminders

## Unreleased

- The "What's New" button is now a toggle — click to open the changelog, click again to close it
- The main Reminders window now sits consistently above the game HUD (action bars, cooldown manager, etc.) instead of some things rendering in front of it and some behind (#57)
- Pressing Escape now closes the main Reminders window (#61)
- Deleting a reminder (the ✕ on its row) now asks for confirmation first, so a misclick can't wipe a reminder — and its per-character schedule/completion state — by accident (#59)
- You can now edit an existing reminder: click the Edit button on its row to load it into the form, change anything (message, condition, interval, day, cross-character), then Save — or Cancel Edit to back out. Editing keeps the reminder's id, so its per-character schedule and completion state are preserved (#58)
- The main Reminders window can now be dragged around — click and drag an empty part of the window to move it. Its position isn't saved between sessions (#60)
- Fixed creating a duplicate reminder (same message, condition, and interval) appearing to succeed: it printed "created!" and cleared the form even though nothing was added. It now only tells you the reminder already exists and leaves your form intact so you can adjust it (#56)

## [v12.5.0](https://github.com/pcg79/Reminders-Addon/tree/v12.5.0) (2026-07-29)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v12.4.1...v12.5.0)

- Cross-character reminders: check "Remind on my other characters" when creating a reminder and it will also show up while you're playing your other characters (as "(Name) message") for every character that matches its condition — a specific character (Name/Self), or a group such as "profession = Alchemy" or "level > 70". So you don't have to log into each alt to find out what it still owes. Those alt reminders are snooze-only, so you can't accidentally clear a chore from another character without doing it. (#21)

## [v12.4.1](https://github.com/pcg79/Reminders-Addon/tree/v12.4.1) (2026-07-27)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v12.4.0...v12.4.1)

- Added a "What's New" window that shows the changelog in-game: it opens automatically the first time you log in after updating, and there's a "What's New" button on the Reminders window to reopen it any time (#55)

## [v12.4.0](https://github.com/pcg79/Reminders-Addon/tree/v12.4.0) (2026-07-27)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v12.3.0...v12.4.0)

- The reminder popup now remembers where you drag it (per character) across reloads and sessions (#23)
- Reminders that come due close together (e.g. snoozed a few seconds apart) are now grouped into a single popup instead of appearing one at a time (#30)

## [v12.3.0](https://github.com/pcg79/Reminders-Addon/tree/v12.3.0) (2026-07-25)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v12.2.0...v12.3.0)

- Added the ability to enable/disable a reminder via a checkbox in the list, instead of only deleting it; disabled reminders stay listed (dimmed) but never fire, and toggling prints a short confirmation (#31)
- The reminder list now keeps a stable order (by creation) so enabling/disabling a reminder no longer reorders the list
- Scoped ~15 accidental globals to `local` so they can't collide with other addons, added a `.luacheckrc` + lint CI to keep it that way, and fixed the latent cross-file bugs it surfaced — including the broken `/reminders delete <id>` command (#40)
- Fixed `/reminders opt` (options) erroring on current WoW; the Settings API now needs a numeric category id, so the options open in their own window instead
- Widened the "Debug mode" option so its label is no longer cut off
- Fixed reminder popups stacking on top of each other; a new reminder now reuses the single popup instead of piling up (#4)
- The snooze confirmation message now shows seconds when the snooze is under a minute (instead of a fractional minute count)
- Fixed long reminder text overflowing into the next reminder in the popup; popup rows now grow to fit their (wrapped) text (#20)
- The value field is now disabled (and cleared) until you pick a condition that uses it, so a typed value no longer lingers under value-less conditions like Everyone

## [v12.2.0](https://github.com/pcg79/Reminders-Addon/tree/v12.2.0) (2026-07-25)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v12.1.0...v12.2.0)

- Fixed the reminder popup leaving a blank gap when a reminder in the middle was dismissed; the remaining reminders now reflow to fill the space, the popup resizes to fit, and it closes automatically when the last one is dismissed (#44)
- Polished the create-a-reminder form: field labels, native-styled input boxes with placeholder hint text, a cleaner aligned layout, and a divider separating the form from the list

## [v12.1.0](https://github.com/pcg79/Reminders-Addon/tree/v12.1.0) (2026-07-24)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v11.0.2...v12.1.0)

- Added a "Not Equals" (not equal to) operation for the Level and iLevel conditions (#14)
- Fixed the operation dropdown showing a stale checkmark after the form reset or the condition changed; a chosen operation is now kept when it's still valid for the newly selected condition
- Redesigned the reminder list: cleaner rows (message, condition, and interval) with a hover highlight, alternating row shading, and a per-row delete button; added an empty state; the list now scrolls properly and clips overflow instead of covering the Close button

## [v11.0.2](https://github.com/pcg79/Reminders-Addon/tree/v11.0.2) (2024-08-13)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v10.1.0..v11.0.2)

- Updated app for 11.0.2
- Updated call to now deprecated GetAddOnMetadata
- Fixed the day drop down not showing anything when you choose "Weekly"
- Fixed the /reminders options chat command

## [v10.1.0](https://github.com/pcg79/Reminders-Addon/tree/v9.1.0) (2023-05-13)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v9.1.0...v10.1.0)

- Updated app for 10.1.0

## [v9.1.0](https://github.com/pcg79/Reminders-Addon/tree/v9.1.0) (2021-06-29)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v9.0.4...v9.1.0)

- Updated app for 9.1.0

## [v9.0.4](https://github.com/pcg79/Reminders-Addon/tree/v9.0.4) (2021-03-09)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v9.0.3...v9.0.4)

- Updated app for 9.0.5

## [v9.0.3](https://github.com/pcg79/Reminders-Addon/tree/v9.0.3) (2020-11-17)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v9.0.2...v9.0.3)

- Updated app for 9.0.2

## [v9.0.2](https://github.com/pcg79/Reminders-Addon/tree/v9.0.2) (2020-11-12)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v9.0.1...v9.0.2)

- Removed Ace3 Addon as a requirement by embedding the necessary libs in this addon.
- Bumped Interface number to 90001 (as I should've done in 9.0.1. Oops)

## [v9.0.1](https://github.com/pcg79/Reminders-Addon/tree/v9.0.1) (2020-11-11)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v8.2.5...v9.0.1)

- Updated TOC for 9.0.1
- Blizzard removed the Backdrop Frame mixin by default in 9.0 so it has to be explicitly added to Frames that need it.
- This one's for my dog, Hina.  I miss her everyday.

## [v8.2.5](https://github.com/pcg79/Reminders-Addon/tree/v8.2.5) (2019-09-28)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v8.2.0...v8.2.5)

- Updated app for 8.2.5

## [v8.2.0](https://github.com/pcg79/Reminders-Addon/tree/v8.2.0) (2019-06-27)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v8.1.1...v8.2.0)

- Updated app for 8.2.0

## [v8.1.1](https://github.com/pcg79/Reminders-Addon/tree/v8.1.1) (2019-03-30)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v8.1.0...v8.1.1)

- Added Dismiss button to individual reminder items

## [v8.1.0](https://github.com/pcg79/Reminders-Addon/tree/v8.1.0) (2018-09-07)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v8.0.10...v8.1.0)

- Updated to support BfA version 8.1

## [v8.0.10](https://github.com/pcg79/Reminders-Addon/tree/v8.0.10) (2018-09-07)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v8.0.9...v8.0.10)

- Added config setting for Snooze amount

## [v8.0.9](https://github.com/pcg79/Reminders-Addon/tree/v8.0.9) (2018-08-12)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v8.0.8...v8.0.9)

- Added a config panel to allow configuring default weekly day and turning on/off debugging.

## [v8.0.8](https://github.com/pcg79/Reminders-Addon/tree/v8.0.8) (2018-08-10)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v8.0.7...v8.0.8)

- Allow choosing which day of the week to remind weekly. Defaults to Tuesday.

## [v8.0.7](https://github.com/pcg79/Reminders-Addon/tree/v8.0.7) (2018-08-05)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v8.0.6...v8.0.7)

- Removed FirstAid as it's no longer in the game (thanks, Linschlager!)
- Added OnEnter tooltips to reminder items
- Bug Fix: Reset Profession dropdown to no values checked on form reset
- Preserve remind times between reload
- Bug Fix: Consistent popup heights

## [v8.0.6](https://github.com/pcg79/Reminders-Addon/tree/v8.0.6) (2018-08-03)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v8.0.5...v8.0.6)

- Bug Fix: DB would not get initialized

## [v8.0.5](https://github.com/pcg79/Reminders-Addon/tree/v8.0.5) (2018-08-02)
[Full Changelog](https://github.com/pcg79/Reminders-Addon/compare/v8.0.4...v8.0.5)

- Switched to in-line reminder messages, no more pages
- Changed Snooze to 10 minutes (from 5 seconds for debugging)
