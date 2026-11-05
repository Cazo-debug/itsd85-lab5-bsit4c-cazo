class_name NetInputGate
extends RefCounted

const EXPIRY_MS: int = 350
const MAX_RATE: int = 90
var sequences: Dictionary = {}
var received_at: Dictionary = {}
var windows: Dictionary = {}
var rejected: int = 0

func reset() -> void:
	sequences.clear()
	received_at.clear()
	windows.clear()
	rejected = 0

func accept(peer: int, packet: Dictionary, owners: Array[int], round_id: int, now: int, gas: Array[float], running: bool) -> Dictionary:
	var clean: Dictionary = validate(peer, packet, owners, round_id, now, gas, running)
	if clean.is_empty():
		rejected += 1
	return clean

func validate(peer: int, packet: Dictionary, owners: Array[int], round_id: int, now: int, gas: Array[float], running: bool) -> Dictionary:
	for key: String in ["seat", "round", "seq"]:
		if not packet.get(key) is int:
			return {}
	var seat: int = packet.seat
	if seat < 0 or seat >= 4 or owners[seat] != peer or packet.round != round_id:
		return {}
	if packet.seq < 0 or packet.seq > 2147483647 or packet.seq <= int(sequences.get(peer, -1)):
		return {}
	if not packet.get("held") is bool or not packet.get("direction") is Vector3:
		return {}
	var direction: Vector3 = packet.direction
	if not (packet.get("strength") is float or packet.get("strength") is int):
		return {}
	var strength: float = float(packet.strength)
	if not direction.is_finite() or direction.length_squared() > 10000 or not is_finite(strength) or strength < 0 or strength > 1:
		return {}
	if packet.held and (not running or gas[seat] <= 0 or direction.length_squared() < 0.001):
		return {}
	var window: Dictionary = windows.get(peer, {"start": now, "count": 0})
	if now - int(window.start) >= 1000:
		window = {"start": now, "count": 0}
	window.count += 1
	windows[peer] = window
	# A fresh, owned release remains admissible even after the aim rate budget.
	if window.count > MAX_RATE and packet.held:
		return {}
	sequences[peer] = packet.seq
	received_at[seat] = now
	return {"seat": seat, "direction": direction.normalized() if direction.length_squared() > 0.001 else Vector3.ZERO,
		"strength": strength, "held": packet.held}

func expired(seat: int, now: int) -> bool:
	return now - int(received_at.get(seat, -EXPIRY_MS - 1)) > EXPIRY_MS
