# Code style (GDScript 4)

1. Fully typed: variables, parameters, return types. Use := only when the type is obvious.
2. Naming: snake_case for vars, funcs, files, folders. PascalCase for classes and nodes. UPPER_SNAKE for constants and enum values. Signals in past tense (hope_changed). Private members start with _.
3. File order: class_name, extends, ## one line summary, signals, enums, constants, @export, public vars, private vars, @onready, lifecycle funcs, public funcs, private funcs.
4. One responsibility per script. Soft limit 150 lines. Split before it grows past that.
5. No magic numbers. Tunables are @export vars or live in data/tuning.tres.
6. Prefer composition: small components (HeatComponent) over deep inheritance.
7. Comments: English, one short line, explain why not what. Public funcs get a one line ## doc. No commented out code. No TODO spam.
8. Early returns over deep nesting. Functions do one thing and stay short.
9. Use StringName (&"name") for ids and signal payload keys.
10. Delta time for all movement and timers. No frame count logic.
11. No print() left behind. Use push_warning or push_error for real problems.
