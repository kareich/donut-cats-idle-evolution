extends CanvasLayer

## Add this layer to ShopScene. It manages visitor and paw-print nodes
## in response to VisitorManager events, keeping the shop scene clean.

const VISITOR_CAT_SCENE := preload("res://scenes/visitor/VisitorCat.tscn")
const PAW_PRINT_SCENE := preload("res://scenes/visitor/PawPrint.tscn")

# Approximate background spawn zone (portrait 1080×1920, background row ~y=800-1100)
const SPAWN_ZONE_X := Vector2(120, 960)
const SPAWN_ZONE_Y := Vector2(820, 1050)

var _active_visitor_node: Control = null


func _ready() -> void:
	VisitorManager.visitor_spawned.connect(_on_visitor_spawned)
	VisitorManager.visitor_missed.connect(_on_visitor_missed)
	VisitorManager.visitor_befriended.connect(_on_visitor_befriended)
	_restore_state_on_open()


func _restore_state_on_open() -> void:
	# Restore paw prints that existed before the player reopened the app
	for paw_data in VisitorManager.get_paw_prints():
		_spawn_paw_print(paw_data)

	# If a visitor was already active when the app closed, re-show them
	if VisitorManager.has_active_visitor():
		var v := VisitorManager.get_active_visitor()
		var remaining := int(Time.get_unix_time_from_system())
		_spawn_visitor_node(v, 60)  # VisitorManager will correct via tick signal


func _on_visitor_spawned(visitor_data: Dictionary) -> void:
	if _active_visitor_node != null:
		return  # Already showing one
	_spawn_visitor_node(visitor_data, 60)


func _on_visitor_missed(visitor_data: Dictionary) -> void:
	if _active_visitor_node != null:
		_active_visitor_node.exit_gracefully()
		_active_visitor_node = null

	# Place paw print where the visitor was standing
	var paw_prints := VisitorManager.get_paw_prints()
	if not paw_prints.is_empty():
		_spawn_paw_print(paw_prints[-1])


func _on_visitor_befriended(_visitor_data: Dictionary) -> void:
	_active_visitor_node = null
	# VisitorCat node removes itself after befriend animation


func _spawn_visitor_node(visitor_data: Dictionary, seconds_remaining: int) -> void:
	var node: Control = VISITOR_CAT_SCENE.instantiate()
	add_child(node)

	var pos_x := randf_range(SPAWN_ZONE_X.x, SPAWN_ZONE_X.y)
	var pos_y := randf_range(SPAWN_ZONE_Y.x, SPAWN_ZONE_Y.y)
	node.position = Vector2(pos_x, pos_y)

	node.setup(visitor_data, seconds_remaining)
	node.tapped.connect(_on_visitor_tapped)
	_active_visitor_node = node


func _on_visitor_tapped(_visitor_data: Dictionary) -> void:
	VisitorManager.befriend_visitor()
	_active_visitor_node = null
	_show_befriend_toast()


func _spawn_paw_print(paw_data: Dictionary) -> void:
	var node: Control = PAW_PRINT_SCENE.instantiate()
	add_child(node)
	# Place near center of spawn zone
	node.position = Vector2(
		randf_range(SPAWN_ZONE_X.x + 60, SPAWN_ZONE_X.y - 60),
		randf_range(SPAWN_ZONE_Y.x + 20, SPAWN_ZONE_Y.y - 20)
	)
	node.setup(paw_data)


func _show_befriend_toast() -> void:
	# Reuse existing toast mechanism from GameManager / HUD if available
	if GameManager.has_method("show_toast"):
		GameManager.show_toast("Visitor befriended! Check your Visitors shelf.")
