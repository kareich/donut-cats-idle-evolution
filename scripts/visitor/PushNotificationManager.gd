extends Node

## Autoload — wraps platform push notification APIs.
## Opt-in: player must grant permission before any notification fires.
## Uses Godot's built-in mobile notification plugin conventions.

signal permission_result(granted: bool)

const SAVE_KEY_OPT_IN := "push_notifications_enabled"
const SAVE_KEY_PERMISSION_ASKED := "push_permission_asked"

var _enabled: bool = false


func _ready() -> void:
	_enabled = SaveManager.get_value(SAVE_KEY_OPT_IN, false)
	if _enabled and not SaveManager.get_value(SAVE_KEY_PERMISSION_ASKED, false):
		# Re-request in case it was revoked externally
		_request_permission()


# ──────────────────────────────────────────────────────────────
#  Public API
# ──────────────────────────────────────────────────────────────

func is_enabled() -> bool:
	return _enabled


func request_opt_in() -> void:
	if _enabled:
		return
	_request_permission()


func set_enabled(value: bool) -> void:
	_enabled = value
	SaveManager.set_value(SAVE_KEY_OPT_IN, value)
	SaveManager.save()
	if not value:
		_cancel_all_scheduled()


func send_local(title: String, body: String, data: Dictionary = {}) -> void:
	if not _enabled:
		return
	_schedule_immediate(title, body, data)


# ──────────────────────────────────────────────────────────────
#  Platform integration
#  iOS: uses Godot iOS notifications plugin (GDNative / GDExtension)
#  Android: uses Godot Android notification plugin
#  Both plugins expose similar GDScript APIs; adjust if using a specific asset
# ──────────────────────────────────────────────────────────────

func _request_permission() -> void:
	SaveManager.set_value(SAVE_KEY_PERMISSION_ASKED, true)
	SaveManager.save()

	if OS.get_name() == "iOS":
		if Engine.has_singleton("iOSNotifications"):
			var plugin = Engine.get_singleton("iOSNotifications")
			plugin.request_authorization()
			# Plugin emits a signal when granted; connect and forward
			if plugin.has_signal("authorization_completed"):
				plugin.authorization_completed.connect(_on_permission_result)
	elif OS.get_name() == "Android":
		if Engine.has_singleton("AndroidNotifications"):
			var plugin = Engine.get_singleton("AndroidNotifications")
			plugin.request_permission()
			if plugin.has_signal("permission_granted"):
				plugin.permission_granted.connect(func(): _on_permission_result(true))
	else:
		# Editor / desktop — treat as granted for testing
		_on_permission_result(true)


func _on_permission_result(granted: bool) -> void:
	_enabled = granted
	SaveManager.set_value(SAVE_KEY_OPT_IN, granted)
	SaveManager.save()
	permission_result.emit(granted)


func _schedule_immediate(title: String, body: String, _data: Dictionary) -> void:
	if OS.get_name() == "iOS" and Engine.has_singleton("iOSNotifications"):
		var plugin = Engine.get_singleton("iOSNotifications")
		var n := {}
		n["title"] = title
		n["body"] = body
		n["time_interval"] = 0  # fire immediately
		plugin.add_notification_at_time(n)

	elif OS.get_name() == "Android" and Engine.has_singleton("AndroidNotifications"):
		var plugin = Engine.get_singleton("AndroidNotifications")
		plugin.show_notification(title, body)

	else:
		# Editor fallback — print to output
		print("[PushNotification] %s: %s" % [title, body])


func _cancel_all_scheduled() -> void:
	if OS.get_name() == "iOS" and Engine.has_singleton("iOSNotifications"):
		Engine.get_singleton("iOSNotifications").remove_all_notifications()
	elif OS.get_name() == "Android" and Engine.has_singleton("AndroidNotifications"):
		Engine.get_singleton("AndroidNotifications").cancel_all_notifications()
