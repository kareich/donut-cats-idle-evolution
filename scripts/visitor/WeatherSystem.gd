extends Node

## In-game weather system. Rain events fire 1-2 times per day, each lasting 30 min.
## Cosmetic only — used as eligibility gate for Rainy Day visitor cats.

signal weather_changed(weather: String)

const SAVE_KEY_NEXT_RAIN := "weather_next_rain_utc"
const SAVE_KEY_RAIN_END := "weather_rain_end_utc"

const RAIN_DURATION_SECS := 1800          # 30 min
const RAIN_COOLDOWN_MIN_SECS := 40800     # 11.3 h — produces ~1-2 rains per day with jitter
const RAIN_COOLDOWN_JITTER_SECS := 7200   # ±2 h jitter

var _current_weather: String = "clear"
var _rain_end_utc: int = 0
var _next_rain_utc: int = 0
var _tick_timer: Timer


func _ready() -> void:
	_load_state()
	_tick_timer = Timer.new()
	_tick_timer.wait_time = 60.0
	_tick_timer.autostart = true
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)
	_evaluate()


func is_raining() -> bool:
	return _current_weather == "rain"


func get_current_weather() -> String:
	return _current_weather


func _evaluate() -> void:
	var now := _utc_now()
	var prev := _current_weather

	if now >= _rain_end_utc:
		_current_weather = "clear"
		if now >= _next_rain_utc:
			_schedule_next_rain(now)
	else:
		_current_weather = "rain"

	if _current_weather != prev:
		weather_changed.emit(_current_weather)
		_save_state()


func _schedule_next_rain(from_utc: int) -> void:
	# Wait the cooldown + jitter before next possible rain window
	var jitter := randi_range(-RAIN_COOLDOWN_JITTER_SECS, RAIN_COOLDOWN_JITTER_SECS)
	_next_rain_utc = from_utc + RAIN_COOLDOWN_MIN_SECS + jitter
	_rain_end_utc = _next_rain_utc + RAIN_DURATION_SECS
	_save_state()


func _on_tick() -> void:
	_evaluate()


func _utc_now() -> int:
	return int(Time.get_unix_time_from_system())


func _load_state() -> void:
	if not SaveManager.has_key(SAVE_KEY_NEXT_RAIN):
		# First boot — schedule first rain 2-4 h from now
		var now := _utc_now()
		var delay := randi_range(7200, 14400)
		_next_rain_utc = now + delay
		_rain_end_utc = _next_rain_utc + RAIN_DURATION_SECS
		_save_state()
		return
	_next_rain_utc = SaveManager.get_value(SAVE_KEY_NEXT_RAIN, 0)
	_rain_end_utc = SaveManager.get_value(SAVE_KEY_RAIN_END, 0)


func _save_state() -> void:
	SaveManager.set_value(SAVE_KEY_NEXT_RAIN, _next_rain_utc)
	SaveManager.set_value(SAVE_KEY_RAIN_END, _rain_end_utc)
	SaveManager.save()
