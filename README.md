## Reminders addon

Format of the reminders:

"message,condition,interval"

`condition` is a boolean statement where the available conditions are:

*
class
profession
level
ilevel
name
self

where `*` applies to every character you have.  `*` should not be paired with other conditionals and, in fact, any others _will_ be ignored.

`interval` right now only supports "daily" and "weekly".  Defaults to "daily"

Examples of a reminder:

    Make Blingtron, profession = Engineering

    Run Firelands, *, weekly

Examples of `condition`:

    *

    class = Warrior

    profession = Engineering and level > 101


class, profession, and name only support equals.  level and ilevel support equal, less than, greater than, less than or equal to, and great than or equal to.  self is a shortcut to "name = <name of the character that created the reminder>"

COMMAND LINE:

/reminders - Toggles the Reminders UI open or closed
/reminders (show|open) - Opens the Reminders UI
/reminders debug - Toggles debugging for the app
/reminders delete id - Deletes the reminder with the id.  Can get the id by turning on debugging.
/reminders reset - Deletes all your reminders.  Use with caution.  Not reversible.


KNOWN ISSUES:

* Weekly reset is assumed to be Tuesday which will likely cause issues internationally
* Using a comma in your reminder message causes reminder to not get run.  Need to either escape it or find another separator.

TODO:

* Add help command line msg
* Implement "not equal to" operation
* Allow specific recipes/spells condition
* Allow profession level condition (i.e., profession = Engineering and Engineering Level > 750)
* A snooze
* Escape to close
* Add ability to sort reminder list
* Better error reporting
