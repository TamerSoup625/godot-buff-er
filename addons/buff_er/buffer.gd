@icon("res://addons/buff_er/buffer_icon.svg")
extends RefCounted
class_name Buffer


## Generic purpose buffer for input buffering, coyote jump, etc.
##
## [Buffer] is a class for managing the execution of one player action.[br]
## It can both buffer one player input for a set amount of time to run the action when allowed,
## and buffer the potential of an action for a set amount of time to run it when a player input is recieved.[br][br]
##
## You'll see various times the terms pre-buffer and post-buffer. These are (probably) terms I made up myself.[br]
## Pre-buffering is buffering an input before the action can be done to then do the action when possible.[br]
## Post-buffering is buffering the possibility of doing an action to do it when input is asked to.[br][br]
##
## Since this class is separate from the scene tree, it uses the [method update] method to recieve changes and modify its state.[br]
## [codeblock]
## var _fire_buffer = Buffer.new(0.2)
##
## func _process(delta):
##     _fire_buffer.update(
##             Input.is_action_just_pressed("fire"),
##             ammo > 0,
##             delta,
##     )
##     if _fire_buffer.should_run_action():
##         shoot_bullet()
## [/codeblock]


## The default value of [member autoflush_on_success].
const DEFAULT_AUTOFLUSH_ON_SUCCESS = true

enum ActionResult {
		## The action should [b]not[/b] run.
		DO_NOT,
		## The action should run because both [member _input] and [member _allow] are [code]true[/code].
		SHOULD_NO_BUFFER,
		## The action should run because [member _allow] is [code]true[/code] and [member _input] is currently buffered.
		SHOULD_PRE_BUFFER,
		## The action should run because [member _input] is [code]true[/code] and [member _allow] is currently buffered.
		SHOULD_POST_BUFFER,
}

## The max amount of buffer time for [member _input], relative to the [code]delta[/code] parameter passed in [method update].[br]
## Default is 0, which disables pre-buffering.
var pre_buffer_max_time: float = 0.0
## The max amount of buffer time for [member _allow], relative to the [code]delta[/code] parameter passed in [method update].[br]
## Default is 0, which disables post-buffering.
var post_buffer_max_time: float = 0.0
## If [code]true[/code] and the action should run on this update, automatically call [method flush]
## on the next update to ensure the action doesn't run multiple times from the same buffering
## (e.g. coyote jumping when you've already jumped).[br]
## Setting this to [code]false[/code] gives higher control on the buffering, but you may have to
## manually call [method flush] to avoid glitches.
var autoflush_on_success: bool = DEFAULT_AUTOFLUSH_ON_SUCCESS

## The [code]input[/code] parameter of the last [method update] call. If [code]true[/code], player input without buffering was recieved.[br]
## [b]Note:[/b] This parameter is meant to be read-only. Things may break if updating this value.
var _input: bool
## The [code]allow[/code] parameter of the last [method update] call. If [code]true[/code], the action is possible without buffering.[br]
## [b]Note:[/b] This parameter is meant to be read-only. Things may break if updating this value.
var _allow: bool
var _pre_buffer_time: float = 0.0
var _post_buffer_time: float = 0.0
var _flush_next_frame: bool = false


## Set [member pre_buffer_max_time], [member post_buffer_max_time], and [member autoflush_on_success]
## inline with [code]Buffer.new()[/code]
func _init(pre_buffer: float = 0.0, post_buffer: float = 0.0, autoflush: bool = DEFAULT_AUTOFLUSH_ON_SUCCESS):
	pre_buffer_max_time = pre_buffer
	post_buffer_max_time = post_buffer
	autoflush_on_success = autoflush


# Helper function for decreasing
func _decrease(value: float, delta: float):
	return maxf(0.0, value - delta)


## Update the internal state of the buffer,
## resetting the buffers if [member autoflush_on_success] is [code]true[/code] and the action should have ran on the last update,
## recieving changes by setting [member _input] and [member _allow] the intended way,
## and modifying the buffers accordingly.[br]
## To make the buffer frame-independant, use the [code]delta[/code] parameter from functions like
## [method Node._process] or [method Node._physics_process].[br][br]
## Also see [member _input] and [member _allow].
func update(input: bool, allow: bool, delta: float):
	if _flush_next_frame:
		_pre_buffer_time = 0.0
		_post_buffer_time = 0.0
		_flush_next_frame = false
	
	_input = input
	_allow = allow
	_pre_buffer_time = _decrease(_pre_buffer_time, delta)
	_post_buffer_time = _decrease(_post_buffer_time, delta)
	
	if _input and not _allow:
		_pre_buffer_time = pre_buffer_max_time
	if _allow and not _input:
		_post_buffer_time = post_buffer_max_time
	
	if autoflush_on_success and should_run_action():
		_flush_next_frame = true


## Returns [code]true[/code] if the action associated with this buffer should run.[br]
## This is the equivalent of doing:
## [codeblock]
## get_action_result() != ActionResult.DO_NOT
## [/codeblock]
func should_run_action() -> bool:
	return (_input and _allow) or (_allow and _pre_buffer_time > 0.0) or (_input and _post_buffer_time > 0.0)


## Returns if the action associated with this buffer should run and why it should.[br]
## See [enum ActionResult].
func get_action_result() -> ActionResult:
	if _input and _allow:
		return ActionResult.SHOULD_NO_BUFFER
	elif _allow and _pre_buffer_time > 0.0:
		return ActionResult.SHOULD_PRE_BUFFER
	elif _input and _post_buffer_time > 0.0:
		return ActionResult.SHOULD_POST_BUFFER
	return ActionResult.DO_NOT


## Flush the buffers, resetting any info that was memorized in the past.
## Also see [member autoflush_on_success].
func flush() -> void:
	_pre_buffer_time = 0.0
	_post_buffer_time = 0.0


## Returns the time remaining for the input to be buffered, relative to the [code]delta[/code] parameter passed in [method update].
func get_pre_buffer_time_left() -> float:
	return _pre_buffer_time


## Returns the time remaining for the possibility of the action to be buffered, relative to the [code]delta[/code] parameter passed in [method update].
func get_post_buffer_time_left() -> float:
	return _post_buffer_time


## Returns the time passed after the input was buffered, relative to the [code]delta[/code] parameter passed in [method update].
func get_pre_buffer_time_passed() -> float:
	return pre_buffer_max_time - _pre_buffer_time


## Returns the time passed after the possibility of the action was buffered, relative to the [code]delta[/code] parameter passed in [method update].
func get_post_buffer_time_passed() -> float:
	return post_buffer_max_time - _post_buffer_time


## If [code]true[/code], [method flush] will be called on the next call to [method update]. Also see [member autoflush_on_success].
func will_flush_next_frame() -> bool:
	return _flush_next_frame
