# BUFFer: Generic purpose buffer for Godot 4.3

This plugin adds the **Buffer** class for managing the execution of one player action.

It can both buffer one player input for a set amount of time to run the action when allowed, and buffer the potential of an action for a set amount of time to run it when a player input is recieved.

## Example use
```gdscript
var _fire_buffer = Buffer.new(0.2)

func _process(delta):
	_fire_buffer.update(
			Input.is_action_just_pressed("fire"),
			ammo > 0,
			delta,
	)
	if _fire_buffer.should_run_action():
		shoot_bullet()
```
