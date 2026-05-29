extends Control

## Glitch Catalog tab in the Collection Book.
## Counter always reads "??? / ???" — deliberately uncountable per design spec.
## Unlocked cats show sprite + name + bio.
## Locked slots show a dark silhouette with glitch-static shader overlay.

const GLITCH_STATIC_SHADER := "res://assets/shaders/glitch_static.gdshader"

@onready var _grid: GridContainer = $ScrollContainer/GridContainer
@onready var _header_label: Label = $Header/SlotCountLabel


func _ready() -> void:
	_header_label.text = "??? / ???"
	GlitchManager.glitch_cat_discovered.connect(_on_glitch_cat_discovered)
	_rebuild()


func _rebuild() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var all_cats: Array = GlitchManager.get_all_glitch_cats()
	for cat in all_cats:
		var is_collected: bool = GlitchManager.is_glitch_cat_collected(cat.get("id", ""))
		var slot := _make_slot(cat, is_collected)
		_grid.add_child(slot)


func _make_slot(cat: Dictionary, is_unlocked: bool) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(200, 260)

	if is_unlocked:
		# Sprite
		var sprite := TextureRect.new()
		sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var sprite_path: String = cat.get("sprite", "")
		if sprite_path != "":
			var tex := load(sprite_path) as Texture2D
			if tex:
				sprite.texture = tex
		slot.add_child(sprite)

		# Name label
		var name_label := Label.new()
		name_label.layout_mode = 0
		name_label.set_offset(SIDE_TOP, 158.0)
		name_label.set_offset(SIDE_RIGHT, 200.0)
		name_label.set_offset(SIDE_BOTTOM, 186.0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.clip_text = true
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.text = cat.get("name", "???")
		slot.add_child(name_label)

		# Bio label
		var bio_label := Label.new()
		bio_label.layout_mode = 0
		bio_label.set_offset(SIDE_TOP, 190.0)
		bio_label.set_offset(SIDE_RIGHT, 200.0)
		bio_label.set_offset(SIDE_BOTTOM, 260.0)
		bio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bio_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		bio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bio_label.add_theme_font_size_override("font_size", 10)
		bio_label.text = cat.get("bio", "")
		slot.add_child(bio_label)
	else:
		# Dark silhouette base
		var silhouette_rect := ColorRect.new()
		silhouette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		silhouette_rect.color = Color(0.1, 0.1, 0.15, 1.0)
		slot.add_child(silhouette_rect)

		# Glitch-static overlay with shader material
		var glitch_overlay := ColorRect.new()
		glitch_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		glitch_overlay.color = Color(0.0, 0.8, 0.6, 0.3)
		var shader := load(GLITCH_STATIC_SHADER) as Shader
		if shader:
			var mat := ShaderMaterial.new()
			mat.shader = shader
			glitch_overlay.material = mat
		slot.add_child(glitch_overlay)

		# "???" mystery label
		var question_label := Label.new()
		question_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		question_label.text = "???"
		question_label.add_theme_font_size_override("font_size", 28)
		slot.add_child(question_label)

	return slot


func _on_glitch_cat_discovered(_glitch_cat: Dictionary) -> void:
	_rebuild()
