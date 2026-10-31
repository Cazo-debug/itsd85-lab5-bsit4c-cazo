class_name AvatarData
extends RefCounted

const SKIN_TONES: Array[Color] = [Color("ffdbb4"), Color("efbb8c"), Color("ce9468"), Color("a66a43"), Color("78472e"), Color("492d24")]
const OUTFIT_COLORS: Array[Color] = [Color("ff6c64"), Color("ffcf50"), Color("7acb3b"), Color("46cfe0"), Color("5289ee"), Color("9566df"), Color("f581bd"), Color("f5f6ef")]
const FLOAT_STYLES: Array[String] = ["donut", "striped", "duck", "lifebuoy"]
const HATS: Array[String] = ["none", "cap", "crown", "propeller", "bucket"]
const TOOT_COLORS: Array[String] = ["green", "purple", "pink", "yellow"]
const LIMITS: Dictionary = {"skin": 6, "outfit": 8, "float_style": 4, "hat": 5, "toot": 4}

static func default_avatar() -> Dictionary:
	return {"name": "Player", "skin": 0, "outfit": 0, "float_style": 0, "hat": 0, "toot": 0}

static func sanitize(d: Variant) -> Dictionary:
	var result: Dictionary = default_avatar()
	if not d is Dictionary:
		return result
	if d.get("name") is String:
		var clean: String = ""
		for character: String in d["name"]:
			var code: int = character.unicode_at(0)
			if code >= 32 and code != 127 and not (code >= 128 and code <= 159):
				clean += character
		result["name"] = clean.strip_edges().left(12)
		if result["name"].is_empty():
			result["name"] = "Player"
	for key: String in LIMITS:
		var value: Variant = d.get(key, 0)
		if value is int:
			result[key] = clampi(value, 0, LIMITS[key] - 1)
	return result

static func random_avatar(rng: RandomNumberGenerator) -> Dictionary:
	var result: Dictionary = default_avatar()
	for key: String in LIMITS:
		result[key] = rng.randi_range(0, LIMITS[key] - 1)
	return result
