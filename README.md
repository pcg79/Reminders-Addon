## Reminders addon

Format of the reminders:

"message,condition,interval"

`condition` is a boolean statement where the available conditions are:

*
class
profession
level
name

where `*` applies to every character you have.  `*` should not be paired with other conditionals and, in fact, any others _will_ be ignored.

`interval` right now only supports "daily" and "weekly".  Defaults to "daily"

Examples of a reminder:

    Make Blingtron, profession = Engineering

    Run Firelands, *, weekly

Examples of `condition`:

    *

    class = Warrior

    profession = Engineering and level > 101


class, profession, and name only support equals.  level supports equal, less than, greater than, less than or equal to, and great than or equal to.


KNOWN ISSUES:

* The time to remind is reset when the reminder is first seen.  So if you have more than one character that a condition applies
  to, the first character that sees the reminder will end up resetting the reminder to the next time it should show. Meaning
  any other characters that should see the reminder won't.

  * The reminders can be global but the nextRemindAt can be per user.

* Weekly reset is assumed to be Tuesday which will likely cause issues internationally

TODO:

* When "enter" is hit, reset all the drop downs and text
* Implement "not equal to" operation
* Implement "self" operation that just does "name = <current player name>"
* Better frame to display reminders
* Better UI
* Allow specific recipes/spells condition
* Allow profession level condition (i.e., profession = Engineering and Engineering Level > 750)
* A snooze
* Escape to close
* Remove need for AceDB
