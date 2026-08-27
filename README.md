## Reminders

Have you ever thought "*Ah, man, I forgot to make Living Steel yesterday!*" or "*Shoot, the daily reset is in an hour and I forgot to run the Stormwind Offensive dailies!*"?

**Reminders** is here to help! Simply type in what you want to be reminded about, choose if you want to be reminded daily or weekly, add in some simple conditions, and you're all set! The reminder will be checked when you switch to that character. If the character fits the conditions, the reminder will pop up!

### CONDITIONS

The available conditions allow you to only trigger the reminder for a specific character, characters that have certain professions, characters that are at, below, or above a specific level or ilevel, or all your characters.

### INTERVALS

Right now there are two intervals to choose from - *daily* and *weekly*. Daily will remind you the first time you log in (or reset your UI) after the server's daily reset. Weekly will remind you the first time you log in (or reset your UI) after the server's weekly reset.

### EXAMPLES

If you have a specific character named Leeroy you use for grinding rep, you would set up a daily reminder where "name" is equal to "Leeroy".

If you want all of your alchemists to remember to craft Living Steel everyday, you'd set up a daily reminder where profession is equal to "Alchemy".

Let's say you want your characters that are level 90 or above to run Firelands every week, you'd set up a weekly reminder where level is equal to or greater than 90.

Class, Profession, and Name only support the equals operation.  Level and ilevel support equals, not equal to, less than, greater than, less than or equal to, and greater than or equal to.  "self" is a shortcut to "name = <name of the character that created the reminder>"

### FEATURES

* Snooze button.  Puts the reminder to sleep for a while then reminds you again. Default length is 10 minutes and can be changed in the options.
* "Remind on my other characters".  Tick that box and the reminder also shows up on your *other* characters that match its condition, as "(Name) message".  So you can see which alts still owe you a chore without logging into each one to find out. Snoozing one only pushes out that character's copy. To actually clear means playing that character and doing the thing.
* Turn a reminder off without deleting it, using the checkbox on its row. It stays in the list but stops firing until you turn it back on.
* Edit a reminder after the fact. Hit Edit on its row, change whatever you want, hit Save. It keeps its place in the schedule, so editing the wording of your Tuesday reminder doesn't make it fire again right away.
* What's New window. Opens itself the first time you log in after the addon updates, and there's a button on the main window if you want to read it again.

### COMMAND LINE

```
/reminders - Toggles the Reminders UI open or closed
/reminders (show|open) - Opens the Reminders UI
/reminders eval - Forces an evaluation of your reminders
/reminders opt|opts|option|options|config - Opens addon options
/reminders delete id - Deletes the reminder with the id.  Can get the id by turning on debugging.
/reminders reset - Deletes all your reminders.  Use with caution.  Not reversible.
```

### UI

Every reminder you make gets a row in the list, showing the message, its condition, and how often it runs.  The checkbox on the left turns it on and off, Edit loads it back into the form at the top, and the ✕ on the right deletes it. Delete asks you to confirm first, since it takes the reminder's schedule with it and there's no undo.

The window itself can be dragged around by any empty part of it, and Escape closes it.

When a reminder actually fires you get a popup with the message, a Snooze button, and a Dismiss button.  If several come due around the same time they share one popup instead of stacking up.

### KNOWN ISSUES

* Text isn't internationalized. If you're interested in helping, let me know!


### ISSUES OR FEATURES

To view my ideas for new features, known bugs, to report your own bug, or request a feature, hit up the Github repo:

https://github.com/pcg79/Reminders-Addon/issues
