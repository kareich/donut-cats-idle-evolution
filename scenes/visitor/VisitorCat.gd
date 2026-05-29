extends Control

## Visitor cat UI node — placed in the shop scene background.
## Spawned and removed by ShopScene in response to VisitorManager signals.

signal tapped(visitor_data: Dictionary)

@onready var _sprite: TextureRect = $Sprite
@onready var _countdown_label: Label = $CountdownLabel
@onready var _tap_area: Button = $TapArea
@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _sparkle_particles: GPUParticles2D = $SparkleParticles

var _visitor_data: Dictionary = {}
var _is_befriended := false


func setup(visitor: Dictionary, seconds_remaining: int) -> void:
	_visitor_data = visitor
	_update_countdown(seconds_remaining)

	var tex := load(visitor.get("sprite", "res://assets/sprites/visitors/placeholder.png"))
	if tex:
		_sprite.texture = tex

	var anim_name: String = visitor.get("idle_anim", "idle")
	if _anim_player.has_animation(anim_name):
		_anim_player.play(anim_name)
	else:
		_anim_player.play("idle")

	_tap_area.pressed.connect(_on_tapped)
	VisitorManager.visitor_timer_tick.connect(_on_timer_tick)

	# Entrance animation
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)


func _update_countdown(seconds: int) -> void:
	_countdown_label.text = "0:%02d" % seconds if seconds < 60 else str(seconds) + "s"


func _on_timer_tick(seconds_remaining: int) -> void:
	_update_countdown(seconds_remaining)
	# Pulse red as time runs low
	if seconds_remaining <= 10:
		_countdown_label.modulate = Color(1, 0.3, 0.3)
		if not _anim_player.is_playing() or _anim_player.current_animation != "nervous":
			if _anim_player.has_animation("nervous"):
				_anim_player.play("nervous")


func _on_tapped() -> void:
	if _is_befriended:
		return
	_is_befriended = true
	_tap_area.disabled = true
	VisitorManager.visitor_timer_tick.disconnect(_on_timer_tick)
	_play_befriend_animation()
	tapped.emit(_visitor_data)


func _play_befriend_animation() -> void:
	_sparkle_particles.emitting = true
	_countdown_label.visible = false

	if _anim_player.has_animation("befriend"):
		_anim_player.play("befriend")
		await _anim_player.animation_finished
	else:
		await get_tree().create_timer(0.8).timeout

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()


func exit_gracefully() -> void:
	# Called when visitor timer expires before tap
	VisitorManager.visitor_timer_tick.disconnect(_on_timer_tick)
	_tap_area.disabled = true
	if _anim_player.has_animation("leave"):
		_anim_player.play("leave")
		await _anim_player.animation_finished
	else:
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		await tween.finished
	queue_free()
