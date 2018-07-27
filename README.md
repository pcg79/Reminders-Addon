## Reminders addon

Have you ever thought "*Ah, man, I forgot to make Living Steel yesterday!*" or "*Shoot, the daily reset is in an hour and I forgot to run the Stormwind Offensive dailies!*"?

**Reminders** is here to help!  Simply type in what you want to be reminded about, choose if you want to be reminded daily or weekly, add in some simple conditions, and you're all set!  The reminder will be checked when you switch to that character.  If the character fits the conditions, the reminder will pop up!

### CONDITIONS

The available conditions allow you to only trigger the reminder for a specific character, characters that have certain professions, characters that are at, below, or above a specific level or ilevel, or all your characters.

### INTERVALS

Right now there are two intervals to choose from - *daily* and *weekly*.  Daily will remind you the first time you log in (or reset your UI) after the server's daily reset.  Weekly will remind you the first time you log in (or reset your UI) after the server's weekly reset.

### EXAMPLES

If you have a specific character named Leeroy you use for griding rep, you would set up a daily reminder where "name" is equal to "Leeroy".

If you want all of your alchemists to remember to craft Living Steel every day, you'd set up a daily reminder where profession is equal to "Alchemy".

Let's say you want your characters that are level 90 or above to run Firelands every week, you'd set up a weekly reminder where level is equal to or greater than 90.

class, profession, and name only support equals.  level and ilevel support equal, less than, greater than, less than or equal to, and great than or equal to.  self is a shortcut to "name = <name of the character that created the reminder>"

### COMMAND LINE

```
/reminders - Toggles the Reminders UI open or closed
/reminders (show|open) - Opens the Reminders UI
/reminders eval - Forces an evaluation of your reminders
/reminders debug - Toggles debugging for the app
/reminders delete id - Deletes the reminder with the id.  Can get the id by turning on debugging.
/reminders reset - Deletes all your reminders.  Use with caution.  Not reversible.
```

## UI

When a Reminder is created it will appear in the list as a button in the main UI.  You can left click on the button to force the system to evaluate that reminder.  That's mostly for test purposes so I don't know if that functionality will stay.

You can also Alt+Click on a Reminder button to delete the Reminder.

## KNOWN ISSUES

* Weekly reset is assumed to be Tuesday which will likely cause issues internationally.
* Text isn't internationalized.  If you're interested in helping, let me know!


## CAVEATS

* Since comma is used as the separator internally, commas are stripped out of your reminder message and value text

## TODO

* Add an "on hover" tooltip for the Reminders with some info (like Alt+Click = delete)
* Implement "not equal to" operation
* Initially sort the reminder list by some order
* Allow specific recipes/spells condition
* Allow profession level condition (i.e., Legion Engineering Level > 80)
* Escape to close
* Add ability to sort reminder list
* Improve the reminder list look and feel
* Multiple conditions joined with AND or OR
