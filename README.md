## Reminders addon

Format of the reminders:

{ id => "message,condition" }

`condition` is a boolean statement where the available conditions are:

*
class
profession
level
name

where `*` applies to every character you have.  `*` should not be paired with other conditionals and, in fact, others will be ignored.

Examples of `condition`:

*

class = "Warrior"

profession = "Engineering" and level > 101

TODO:

daily and weekly times to remind
