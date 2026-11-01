class_name CrewData
extends RefCounted

const MAX_RIDERS: int = 4
const CONTROLS: Array[String] = ["empty", "local", "assist", "peer"]

static func default_profiles() -> Array[Dictionary]:
	var profiles: Array[Dictionary] = [{}]
	for index: int in range(1, MAX_RIDERS):
		var profile: Dictionary = AvatarData.default_avatar()
		profile.name = "Rider %d" % (index + 1)
		profile.outfit = index + 1
		profile.skin = index
		profiles.append(profile)
	return profiles

static func empty_slot() -> Dictionary:
	return {"control": "empty", "profile": -1, "owner": ""}

static func default_slots() -> Array[Dictionary]:
	return [{"control": "local", "profile": 0, "owner": "local:0"}, empty_slot(), empty_slot(), empty_slot()]

static func sanitize_profiles(value: Variant, legacy: Variant = {}) -> Array[Dictionary]:
	var result: Array[Dictionary] = default_profiles()
	if value is Array:
		for index: int in range(mini(value.size(), MAX_RIDERS)):
			if value[index] is Dictionary and not value[index].is_empty():
				result[index] = AvatarData.sanitize(value[index])
	if result[0].is_empty() and legacy is Dictionary and not legacy.is_empty():
		result[0] = AvatarData.sanitize(legacy)
	return result

static func make_slot(control: String, profile: int, owner: String = "") -> Dictionary:
	if control == "empty":
		return empty_slot()
	return {"control": control, "profile": profile, "owner": owner if control == "peer" else "%s:%d" % [control, profile]}

static func valid_slot(slot: Dictionary, profiles: Array[Dictionary]) -> bool:
	if not slot.get("control") is String or slot.control not in CONTROLS:
		return false
	if slot.control == "empty":
		return slot == empty_slot()
	var index: Variant = slot.get("profile")
	if not index is int or index < 0 or index >= profiles.size() or profiles[index].is_empty():
		return false
	var owner: Variant = slot.get("owner")
	if not owner is String or owner.is_empty():
		return false
	return slot.control == "peer" or owner == "%s:%d" % [slot.control, index]

static func sanitize_slots(value: Variant, profiles: Array[Dictionary], persistent: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var used_profiles: Array[int] = []
	var used_owners: Array[String] = []
	var source: Array = value if value is Array else default_slots()
	for index: int in range(MAX_RIDERS):
		var slot: Dictionary = source[index].duplicate(true) if index < source.size() and source[index] is Dictionary else empty_slot()
		if persistent and slot.get("control") is String and slot.control == "peer":
			slot = empty_slot()
		if not valid_slot(slot, profiles) or slot.get("profile", -1) in used_profiles or slot.get("owner", "") in used_owners:
			slot = empty_slot()
		if slot.control != "empty":
			used_profiles.append(slot.profile)
			used_owners.append(slot.owner)
		# Whitelist fields: no extra transient networking data reaches disk.
		result.append({"control": slot.control, "profile": slot.profile, "owner": slot.owner})
	return result
