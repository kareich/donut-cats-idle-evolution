extends Control

## Paw print left behind when a visitor leaves uncaught.
## Fades out after 10 min. Tappable: shows tooltip with visitor name or "???".

@onready var _icon: TextureRect = $Icon
@onready var _tooltip_panel: PanelContainer = $TooltipPanel
@onready var _tooltip_label: Label = $TooltipPanel/Label
@onready var _tap_area: Button = $TapArea

var _visitor_name: String = ""
var _previously_collected: bool = false
var _fade_timer_remaining: float = 0.0


func setup(paw_data: Dictionary) -> void:
	_previously_collected = paw_data.get("previously_collected", false)
	_visitor_name = paw_data.get("name", "???") if _previously_collected else "???"

	_fade_timer_remaining = float(paw_data.get("expires_utc", 0) - int(Time.get_unix_time_from_system()))
	_fade_timer_remaining = maxf(_fade_timer_remaining, 0.0)

	_tooltip_panel.visible = false
	_tap_area.pressed.connect(_on_tapped)

	if _fade_timer_remaining <= 0.0:
		queue_free()
		return

	_start_fade_tween()


func _start_fade_tween() -> void:
	var tween := create_tween()
	# Stay opaque for most of the duration, fade in last 60 s
	var hold_duration := maxf(_fade_timer_remaining - 60.0, 0.0)
	tween.tween_interval(hold_duration)
	tween.tween_property(self, "modulate:a", 0.0, 60.0)
	tween.tween_callback(queue_free)


func _on_tapped() -> void:
	_tooltip_panel.visible = not _tooltip_panel.visible
	if _tooltip_panel.visible:
		var text: String
		if _previously_collected:
			text = "A visitor was here...\n%s" % _visitor_name
		else:
			text = "A visitor was here...\n???"
		_tooltip_label.text = text

		# Auto-hide tooltip after 3 s
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(self):
			_tooltip_panel.visible = false
