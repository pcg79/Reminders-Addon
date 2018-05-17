## Reminders addon

Format of the reminders:

"message,condition"

`condition` is a boolean statement where the available conditions are:

*
class
profession
level
name

where `*` applies to every character you have.  `*` should not be paired with other conditionals and, in fact, any others _will_ be ignored.

Example of a reminder:

    Make Blingtron, profession = Engineering

Examples of `condition`:

    *

    class = Warrior

    profession = Engineering and level > 101


class, profession, and name only support equals.  level supports equal, less than, greater than, less than or equal to, and great than or equal to.


TODO:

* Daily and weekly times to remind
* Better UI
* Allow specific recipes/spells condition
* Allow profession level condition
* A snooze
* Deleting reminders
* Separate UI and logic code
* Escape to close
