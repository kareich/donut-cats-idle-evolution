extends Control

## Single slot in the Glitch Catalog grid.
## Unlocked: shows glitchy sprite, scrambled name, absurdist bio.
## Locked: shows static silhouette with animated glitch overlay.

@onready var _sprite: TextureRect = $Sprite
@onready var _name_label: Label = $NameLabel
@onready var _bio_label: Label = $BioLabel
@onready var _silhouette: Control = $Silhouette
@onready var _glitch_overlay: ColorRect = $Silhouette/GlitchOverlay


func setup(glitch_cat: Dictionary, is_unlocked: bool) -> void:
	if is_unlocked:
		_show_unlocked(glitch_cat)
	else:
		_show_locked()


func _show_unlocked(cat: Dictionary) -> void:
	_silhouette.visible = false
	_sprite.visible = true
	_name_label.visible = true
	_bio_label.visible = true

	var tex := load(cat.get("sprite_variant", "")) as Texture2D
	if tex:
		_sprite.texture = tex

	_name_label.text = cat.get("name", "???")
	_bio_label.text = cat.get("bio", "")


func _show_locked() -> void:
	_sprite.visible = false
	_name_label.visible = false
	_bio_label.visible = false
	_silhouette.visible = true
	_animate_glitch_overlay()


func _animate_glitch_overlay() -> void:
	# Pulse glitch-static alpha to simulate CRT interference
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_glitch_overlay, "modulate:a", 0.15, 0.08)
	tween.tween_property(_glitch_overlay, "modulate:a", 0.55, 0.08)
	tween.tween_property(_glitch_overlay, "modulate:a", 0.05, 0.12)
	tween.tween_property(_glitch_overlay, "modulate:a", 0.45, 0.06)
