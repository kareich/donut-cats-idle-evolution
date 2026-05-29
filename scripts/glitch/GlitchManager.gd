extends Node

signal glitch_cat_discovered(data: Dictionary)
signal glitch_tokens_changed(new_balance: int)

const TOKENS_PER_CAT: int = 5

var _mystery_pairs: Array[Dictionary] = []
var _glitch_cats_by_id: Dictionary = {}
var _all_glitch_cats: Array[Dictionary] = []

var _collected_ids: Array[String] = []
var _token_balance: int = 0
var _owned_deco_ids: Array[String] = []


func _ready() -> void:
	_load_mystery_pairs()
	_load_glitch_cats()
	_load_save_data()


func _load_mystery_pairs() -> void:
	var file := FileAccess.open("res://data/mystery_pairs.json", FileAccess.READ)
	if file == null:
		push_error("GlitchManager: could not open data/mystery_pairs.json")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary and parsed.has("mystery_pairs"):
		for entry in parsed["mystery_pairs"]:
			if entry is Dictionary:
				_mystery_pairs.append(entry)


func _load_glitch_cats() -> void:
	var file := FileAccess.open("res://data/glitch_cats.json", FileAccess.READ)
	if file == null:
		push_error("GlitchManager: could not open data/glitch_cats.json")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary and parsed.has("glitch_cats"):
		for entry in parsed["glitch_cats"]:
			if entry is Dictionary:
				_all_glitch_cats.append(entry)
				if entry.has("id"):
					_glitch_cats_by_id[entry["id"]] = entry


func _load_save_data() -> void:
	var raw_ids = SaveManager.get_value("glitch_collected_ids", [])
	if raw_ids is Array:
		for id in raw_ids:
			if id is String:
				_collected_ids.append(id)
	_token_balance = int(SaveManager.get_value("glitch_token_balance", 0))
	var raw_decos = SaveManager.get_value("glitch_owned_decos", [])
	if raw_decos is Array:
		for id in raw_decos:
			if id is String:
				_owned_deco_ids.append(id)


func _save() -> void:
	SaveManager.set_value("glitch_collected_ids", _collected_ids)
	SaveManager.set_value("glitch_token_balance", _token_balance)
	SaveManager.set_value("glitch_owned_decos", _owned_deco_ids)
	SaveManager.save()


func _make_pair_key(a: String, b: String) -> String:
	if a < b:
		return a + "|" + b
	return b + "|" + a


func _find_mystery_pair(cat_a_id: String, cat_b_id: String) -> Dictionary:
	var key := _make_pair_key(cat_a_id, cat_b_id)
	for pair in _mystery_pairs:
		if not (pair.has("cat_a") and pair.has("cat_b") and pair.has("glitch_cat_id")):
			continue
		var pair_key := _make_pair_key(str(pair["cat_a"]), str(pair["cat_b"]))
		if pair_key == key:
			return pair
	return {}


func check_fusion(cat_a_id: String, cat_b_id: String) -> Dictionary:
	var pair := _find_mystery_pair(cat_a_id, cat_b_id)
	if pair.is_empty():
		return {}
	if randf() >= 0.1:
		return {}
	var glitch_id: String = str(pair["glitch_cat_id"])
	if not _glitch_cats_by_id.has(glitch_id):
		return {}
	return _glitch_cats_by_id[glitch_id]


func collect_glitch_cat(glitch_cat_id: String) -> void:
	var was_new := not _collected_ids.has(glitch_cat_id)
	_collected_ids.append(glitch_cat_id)
	_save()
	if was_new and _glitch_cats_by_id.has(glitch_cat_id):
		glitch_cat_discovered.emit(_glitch_cats_by_id[glitch_cat_id])


func trade_glitch_cat(glitch_cat_id: String) -> int:
	var idx := _collected_ids.find(glitch_cat_id)
	if idx == -1:
		return _token_balance
	_collected_ids.remove_at(idx)
	_token_balance += TOKENS_PER_CAT
	_save()
	glitch_tokens_changed.emit(_token_balance)
	return _token_balance


func get_glitch_token_balance() -> int:
	return _token_balance


func get_collected_glitch_cats() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in _collected_ids:
		if _glitch_cats_by_id.has(id):
			result.append(_glitch_cats_by_id[id])
	return result


func is_glitch_cat_collected(id: String) -> bool:
	return _collected_ids.has(id)


func get_all_glitch_cats() -> Array[Dictionary]:
	return _all_glitch_cats


func get_owned_deco_ids() -> Array[String]:
	return _owned_deco_ids.duplicate()


func purchase_deco(deco_id: String) -> bool:
	if _token_balance < 0 or deco_id in _owned_deco_ids:
		return false
	# Cost is validated by the caller (ShadyAlleyCat); deduct based on SHOP_ITEMS
	_owned_deco_ids.append(deco_id)
	_save()
	return true


func purchase_deco_with_cost(deco_id: String, cost: int) -> bool:
	if _token_balance < cost or deco_id in _owned_deco_ids:
		return false
	_token_balance -= cost
	_owned_deco_ids.append(deco_id)
	_save()
	glitch_tokens_changed.emit(_token_balance)
	return true
