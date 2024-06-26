extends CharacterBody2D


# Example usage of Buffer with a jump and another generic action

# Create a new Buffer for each action the player can do (e.g. jumping)
# The first parameter is the max time it will wait for pre-buffering (e.g. input buffer)
# The second parameter is the max time it will wait for post-buffering (e.g. coyote time)
# Set any of these parameters above to 0.0 for disabling that type of buffer
# If the third parameter is true, the buffers will be flushed on the next update whenever the action should run (e.g. to avoid coyote time triggering multiple times)
# Setting the third parameter to false gives more control on the buffering, but you may have to call Buffer.flush to manually flush the buffers

# Here we want both pre and post buffering
var _jump_buffer := Buffer.new(0.15, 0.15, true)
# Here we only want pre-buffering (we don't want to run the action while we're doing it)
var _vfx_buffer := Buffer.new(0.15, 0, true)

const SPEED = 600.0
const JUMP_VELOCITY = -800.0
const GRAVITY = Vector2(0, 1960)
var _can_emit_particles: bool = true
@onready var particles: GPUParticles2D = %Particles


func _physics_process(delta: float) -> void:
	# Update the buffers
	# The update function takes 3 parameters:
	# - Boolean input: true if the input to do the action was recieved, usually player input
	# - Boolean allow: true if the action can be done, usually game logic
	# - Float delta: Usually the delta parameter from _process or _physics_process functions
	_jump_buffer.update(
			Input.is_action_just_pressed("ui_accept"),
			is_on_floor(),
			delta,
	)
	_vfx_buffer.update(
			Input.is_action_just_pressed("ui_up"),
			_can_emit_particles,
			delta,
	)
	
	# Check if the action can be done
	# This function does the buffering for you
	if _jump_buffer.should_run_action():
		if velocity.y > 0:
			velocity.y = JUMP_VELOCITY
		else:
			velocity.y += JUMP_VELOCITY
	
	if _vfx_buffer.should_run_action():
		particles.restart()
		_can_emit_particles = false
	
	
	if not is_on_floor():
		velocity += GRAVITY * delta
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()


func _on_particles_finished() -> void:
	_can_emit_particles = true
