extends Node

## Autoload — owns the visitor spawn lifecycle.
## Spawn interval: 3–5 h jittered. Persists across app close via SaveManager.
## Emits signals for the shop scene to show/hide the visitor sprite.

signal visitor_spawned(visitor_data: Dictionary)
signal visitor_befriended(visitor_data: Dictionary)
signal visitor_missed(visitor_data: Dictionary)
signal visitor_timer_tick(seconds_remaining: int)

const SAVE_KEY_NEXT_SPAWN := "visitor_next_spawn_utc"
const SAVE_KEY_ACTIVE_ID := "visitor_active_id"
const SAVE_KEY_ACTIVE_EXPIRES := "visitor_active_expires_utc"
const SAVE_KEY_COLLECTED := "visitor_collected_ids"
const SAVE_KEY_PAW_PRINTS := "visitor_paw_prints"      # array of {id, x, y, expires_utc}

const SPAWN_MIN_SECS := 10800   # 3 h
const SPAWN_MAX_SECS := 18000   # 5 h
const VISIT_DURATION_SECS := 60
const PAW_PRINT_DURATION_SECS := 600   # 10 min

var _all_visitors: Array[Dictionary] = []
var _collected_ids: Array = []
var _paw_prints: Array = []

var _next_spawn_utc: int = 0
var _active_visitor: Dictionary = {}
var _active_expires_utc: int = 0

var _countdown_timer: Timer
var _poll_timer: Timer


func _ready() -> void:
	_load_visitor_roster()
	_load_state()

	_poll_timer = Timer.new()
	_poll_timer.wait_time = 5.0
	_poll_timer.autostart = true
	_poll_timer.timeout.connect(_on_poll)
	add_child(_poll_timer)

	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 1.0
	_countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(_countdown_timer)

	_evaluate_on_resume()


# ──────────────────────────────────────────────────────────────
#  Public API
# ──────────────────────────────────────────────────────────────

func has_active_visitor() -> bool:
	return not _active_visitor.is_empty()


func get_active_visitor() -> Dictionary:
	return _active_visitor


func befriend_visitor() -> void:
	if _active_visitor.is_empty():
		return
	var v := _active_visitor.duplicate()
	_collected_ids.append(v.id)
	_clear_active_visitor()
	_schedule_next_spawn()
	visitor_befriended.emit(v)
	_push_visitor_collected(v)
	_save_state()


func get_collected_ids() -> Array:
	return _collected_ids.duplicate()


func is_collected(visitor_id: String) -> bool:
	return visitor_id in _collected_ids


func get_paw_prints() -> Array:
	_prune_expired_paw_prints()
	return _paw_prints.duplicate()


func get_all_visitors() -> Array[Dictionary]:
	return _all_visitors


# ──────────────────────────────────────────────────────────────
#  Internal — spawn logic
# ──────────────────────────────────────────────────────────────

func _evaluate_on_resume() -> void:
	var now := _utc_now()

	if not _active_visitor.is_empty():
		if now >= _active_expires_utc:
			_handle_visitor_missed()
		else:
			# Visitor still active — re-emit so the shop scene can show it
			visitor_spawned.emit(_active_visitor)
			_countdown_timer.start()
		return

	if now >= _next_spawn_utc:
		_try_spawn()


func _on_poll() -> void:
	var now := _utc_now()
	if not _active_visitor.is_empty():
		if now >= _active_expires_utc:
			_handle_visitor_missed()
		return
	if now >= _next_spawn_utc:
		_try_spawn()


func _on_countdown_tick() -> void:
	if _active_visitor.is_empty():
		_countdown_timer.stop()
		return
	var remaining := _active_expires_utc - _utc_now()
	if remaining <= 0:
		_handle_visitor_missed()
		return
	visitor_timer_tick.emit(remaining)


func _try_spawn() -> void:
	var eligible := _get_eligible_visitors()
	if eligible.is_empty():
		# Nothing eligible — check again in 10 min
		_next_spawn_utc = _utc_now() + 600
		_save_state()
		return

	var v: Dictionary = eligible[randi() % eligible.size()]
	_active_visitor = v
	_active_expires_utc = _utc_now() + VISIT_DURATION_SECS
	_countdown_timer.start()
	_save_state()
	visitor_spawned.emit(v)
	_send_push_notification(v)


func _handle_visitor_missed() -> void:
	var v := _active_visitor.duplicate()
	_paw_prints.append({
		"id": v.id,
		"name": v.name,
		"previously_collected": is_collected(v.id),
		"expires_utc": _utc_now() + PAW_PRINT_DURATION_SECS,
	})
	_clear_active_visitor()
	_schedule_next_spawn()
	visitor_missed.emit(v)
	_save_state()


func _clear_active_visitor() -> void:
	_active_visitor = {}
	_active_expires_utc = 0
	_countdown_timer.stop()


func _schedule_next_spawn() -> void:
	var interval := randi_range(SPAWN_MIN_SECS, SPAWN_MAX_SECS)
	_next_spawn_utc = _utc_now() + interval


func _get_eligible_visitors() -> Array:
	var result: Array = []
	var now_hour := _local_hour()
	for v in _all_visitors:
		match v.get("condition", "common"):
			"common":
				result.append(v)
			"rainy":
				if WeatherSystem.is_raining():
					result.append(v)
			"midnight":
				if now_hour >= 22:
					result.append(v)
	return result


func _prune_expired_paw_prints() -> void:
	var now := _utc_now()
	_paw_prints = _paw_prints.filter(func(p): return p.expires_utc > now)


# ──────────────────────────────────────────────────────────────
#  Push notifications (uses existing Phoenix infra from Sprint 4)
# ──────────────────────────────────────────────────────────────

func _send_push_notification(v: Dictionary) -> void:
	PushNotificationManager.send_local(
		"A visitor!",
		v.get("spawn_flavor", "A mysterious cat is sniffing your donuts."),
		{"visitor_id": v.id}
	)


func _push_visitor_collected(v: Dictionary) -> void:
	ApiClient.post("/api/players/me/visitors/collected", {"visitor_id": v.id})


# ──────────────────────────────────────────────────────────────
#  Persistence
# ──────────────────────────────────────────────────────────────

func _save_state() -> void:
	_prune_expired_paw_prints()
	SaveManager.set_value(SAVE_KEY_NEXT_SPAWN, _next_spawn_utc)
	SaveManager.set_value(SAVE_KEY_ACTIVE_ID, _active_visitor.get("id", ""))
	SaveManager.set_value(SAVE_KEY_ACTIVE_EXPIRES, _active_expires_utc)
	SaveManager.set_value(SAVE_KEY_COLLECTED, _collected_ids)
	SaveManager.set_value(SAVE_KEY_PAW_PRINTS, _paw_prints)
	SaveManager.save()


func _load_state() -> void:
	_next_spawn_utc = SaveManager.get_value(SAVE_KEY_NEXT_SPAWN, 0)
	_active_expires_utc = SaveManager.get_value(SAVE_KEY_ACTIVE_EXPIRES, 0)
	_collected_ids = SaveManager.get_value(SAVE_KEY_COLLECTED, [])
	_paw_prints = SaveManager.get_value(SAVE_KEY_PAW_PRINTS, [])

	var active_id: String = SaveManager.get_value(SAVE_KEY_ACTIVE_ID, "")
	if not active_id.is_empty():
		for v in _all_visitors:
			if v.id == active_id:
				_active_visitor = v
				break

	if _next_spawn_utc == 0:
		# First install — first visitor in 30-60 min (not 3-5h, so player sees the feature)
		_next_spawn_utc = _utc_now() + randi_range(1800, 3600)
		_save_state()


func _load_visitor_roster() -> void:
	var f := FileAccess.open("res://data/visitors.json", FileAccess.READ)
	if f == null:
		push_error("VisitorManager: could not open data/visitors.json")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed == null or not parsed.has("visitors"):
		push_error("VisitorManager: malformed visitors.json")
		return
	for v in parsed["visitors"]:
		_all_visitors.append(v)


# ──────────────────────────────────────────────────────────────
#  Helpers
# ──────────────────────────────────────────────────────────────

func _utc_now() -> int:
	return int(Time.get_unix_time_from_system())


func _local_hour() -> int:
	return Time.get_datetime_dict_from_system(false).hour
