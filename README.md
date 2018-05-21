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

* Weekly reset is assumed to be Tuesday which will likely cause issues internationally

TODO:

* Better frame to display reminders
* Daily and weekly times to remind
* Better UI
* Allow specific recipes/spells condition
* Allow profession level condition (i.e., profession = Engineering and Engineering Level > 750)
* A snooze
* Deleting reminders
* Escape to close
* Add debug logging setting
* Not do anything until PLAYER_LOGGED_IN event (so that debug logging will be printed if you have an addon that adds chat history scrollback)
