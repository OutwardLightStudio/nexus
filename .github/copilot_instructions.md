This game is written with Godot 4.4. Use the most recent GDScript syntax. For example, when connecting signals, now we use a callable directly as the argument, instead of a string:

```gdscript
area3d.body_entered.connect(_on_body_entered)
```
