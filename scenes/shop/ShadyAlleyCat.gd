extends Control

const TOKENS_PER_CAT := 5

const SHOP_ITEMS := [
	{"name": "Glitch Neon Sign", "cost": 50},
	{"name": "Pixel Trash Can", "cost": 30},
	{"name": "Corrupted Fishbone", "cost": 20},
]

@onready var _trade_panel: PanelContainer = $TradePanel
@onready var _tap_area: Button = $TapArea
@onready var _token_balance_label: Label = $TradePanel/VBoxContainer/TokenBalanceLabel
@onready var _cats_container: VBoxContainer = $TradePanel/VBoxContainer/CatsContainer
@onready var _shop_items_container: VBoxContainer = $TradePanel/VBoxContainer/ShopItemsContainer


func _ready() -> void:
	_trade_panel.visible = false
	_tap_area.pressed.connect(_on_tap)
	$TradePanel/VBoxContainer/CloseButton.pressed.connect(_on_close)
	_build_shop_stubs()


func _on_tap() -> void:
	_refresh_ui()
	_trade_panel.visible = true


func _on_close() -> void:
	_trade_panel.visible = false


func _refresh_ui() -> void:
	_token_balance_label.text = "Glitch Tokens: %d" % GlitchManager.get_glitch_token_balance()

	for child in _cats_container.get_children():
		child.queue_free()

	var cats: Array = GlitchManager.get_collected_glitch_cats()
	for cat in cats:
		var row := HBoxContainer.new()

		var label := Label.new()
		label.text = "%s  →  %d Tokens" % [cat.get("name", "?"), TOKENS_PER_CAT]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var btn := Button.new()
		btn.text = "Trade"
		var cat_id: String = cat.id
		btn.pressed.connect(func() -> void:
			GlitchManager.trade_glitch_cat(cat_id)
			_refresh_ui()
		)
		row.add_child(btn)

		_cats_container.add_child(row)

	if cats.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No Glitch Cats to trade."
		_cats_container.add_child(empty_label)


func _build_shop_stubs() -> void:
	for item in SHOP_ITEMS:
		var row := HBoxContainer.new()

		var title := Label.new()
		title.text = item["name"]
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(title)

		var cost := Label.new()
		cost.text = "%d Glitch Tokens" % item["cost"]
		row.add_child(cost)

		_shop_items_container.add_child(row)
