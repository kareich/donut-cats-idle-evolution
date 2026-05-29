extends Control

## One-shot opt-in dialog for visitor push notifications.
## Show once after tutorial completes. Player can also toggle in Settings.

signal accepted
signal declined

@onready var _accept_btn: Button = $Panel/VBox/AcceptButton
@onready var _decline_btn: Button = $Panel/VBox/DeclineButton


func _ready() -> void:
	_accept_btn.pressed.connect(_on_accept)
	_decline_btn.pressed.connect(_on_decline)


func _on_accept() -> void:
	PushNotificationManager.request_opt_in()
	PushNotificationManager.permission_result.connect(_on_permission_result, CONNECT_ONE_SHOT)
	accepted.emit()
	queue_free()


func _on_decline() -> void:
	declined.emit()
	queue_free()


func _on_permission_result(granted: bool) -> void:
	if not granted:
		# OS denied — respect it, no retry
		PushNotificationManager.set_enabled(false)
