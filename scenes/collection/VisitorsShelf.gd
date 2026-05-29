extends Control

## Visitors tab in the Collection Book.
## Shows all visitor cat slots; collected ones display sprite + name + bio,
## undiscovered ones show a silhouette placeholder + "???".
## Miss count is never displayed.

@onready var _grid: GridContainer = $ScrollContainer/GridContainer
@onready var _count_label: Label = $Header/CountLabel


func _ready() -> void:
	VisitorManager.visitor_befriended.connect(_on_visitor_collected)
	_rebuild()


# ---------- public helpers ----------

func _rebuild() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var all_visitors: Array = VisitorManager.get_all_visitors()
	var collected_ids: Array = VisitorManager.get_collected_ids()
	var collected_count := 0

	for v in all_visitors:
		var is_collected: bool = v.get("id", "") in collected_ids
		if is_collected:
			collected_count += 1
		var slot := _make_slot(v, is_collected)
		_grid.add_child(slot)

	_refresh_counts(collected_count, all_visitors.size())


func _refresh_counts(collected: int, total: int) -> void:
	_count_label.text = "%d / %d" % [collected, total]


# ---------- slot factory ----------

func _make_slot(v: Dictionary, collected: bool) -> Control:
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# --- Sprite / silhouette ---
	var sprite := TextureRect.new()
	sprite.custom_minimum_size = Vector2(96, 96)
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	if collected:
		var tex_path: String = v.get("sprite", "")
		if tex_path != "":
			var tex := load(tex_path)
			if tex:
				sprite.texture = tex
	else:
		# Solid dark rectangle as silhouette stand-in
		var silhouette := ColorRect.new()
		silhouette.custom_minimum_size = Vector2(96, 96)
		silhouette.color = Color(0.1, 0.1, 0.1, 1.0)
		silhouette.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		container.add_child(silhouette)

	if collected:
		container.add_child(sprite)

	# --- Name label ---
	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text = v.get("name", "???") if collected else "???"
	container.add_child(name_label)

	# --- Bio label (collected only) ---
	if collected:
		var bio_label := Label.new()
		bio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bio_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bio_label.text = v.get("bio", "")
		container.add_child(bio_label)

	return container


# ---------- signal handlers ----------

func _on_visitor_collected(_visitor_data: Dictionary) -> void:
	_rebuild()
