extends Control

## Visitors tab in the Collection Book.
## Shows all visitor cat slots; collected ones show sprite + name + bio,
## undiscovered ones show silhouette + "???". Miss count is never displayed.

const VISITOR_CARD_SCENE := preload("res://scenes/collection/VisitorCard.tscn")

@onready var _grid: GridContainer = $ScrollContainer/Grid
@onready var _count_label: Label = $Header/CountLabel


func _ready() -> void:
	_populate()
	VisitorManager.visitor_befriended.connect(_on_visitor_collected)


func _populate() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var all_visitors := VisitorManager.get_all_visitors()
	var collected_ids := VisitorManager.get_collected_ids()
	var collected_count := 0

	for v in all_visitors:
		var card: Control = VISITOR_CARD_SCENE.instantiate()
		_grid.add_child(card)
		var is_collected := v.id in collected_ids
		card.setup(v, is_collected)
		if is_collected:
			collected_count += 1

	_count_label.text = "%d / %d" % [collected_count, all_visitors.size()]


func _on_visitor_collected(_visitor_data: Dictionary) -> void:
	_populate()
