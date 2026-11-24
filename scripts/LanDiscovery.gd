class_name LanDiscovery
extends Node

# Finds nearby games on the same Wi-Fi or phone hotspot without typing an IP address.
# The host broadcasts a tiny UDP "I am here" packet; guests listen and list the hosts.
# Discovery only suggests an address. Net still validates everything after the connect.
const DISCOVERY_PORT: int = 7778
const MAGIC: String = "tootTubes1"
const ANNOUNCE_EVERY_MS: int = 1000
const HOST_EXPIRES_MS: int = 3500
const MAX_HOSTS: int = 6
signal hosts_changed

var _announcer: PacketPeerUDP
var _listener: PacketPeerUDP
var _announce_name: String = ""
var _next_announce_at: int = 0
var _targets: Array[String] = []
var hosts: Dictionary = {} # ip -> {"name": String, "seen": int}

func start_announcing(host_name: String) -> void:
	stop_announcing()
	_announce_name = clean_name(host_name)
	_announcer = PacketPeerUDP.new()
	_announcer.set_broadcast_enabled(true)
	_targets = broadcast_targets(IP.get_local_addresses())
	_next_announce_at = 0
	set_process(true)

func stop_announcing() -> void:
	if _announcer != null:
		_announcer.close()
	_announcer = null
	_update_processing()

func start_listening() -> void:
	stop_listening()
	_listener = PacketPeerUDP.new()
	_listener.set_broadcast_enabled(true)
	if _listener.bind(DISCOVERY_PORT, "*") != OK:
		_listener = null # Discovery is a convenience; manual IP still works.
		return
	hosts.clear()
	set_process(true)

func stop_listening() -> void:
	if _listener != null:
		_listener.close()
	_listener = null
	if not hosts.is_empty():
		hosts.clear()
		hosts_changed.emit()
	_update_processing()

func is_listening() -> bool:
	return _listener != null

func _update_processing() -> void:
	set_process(_announcer != null or _listener != null)

func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	if _announcer != null and now >= _next_announce_at:
		_next_announce_at = now + ANNOUNCE_EVERY_MS
		var packet: PackedByteArray = make_packet(_announce_name)
		for target: String in _targets:
			_announcer.set_dest_address(target, DISCOVERY_PORT)
			_announcer.put_packet(packet)
	if _listener != null:
		var changed: bool = false
		while _listener.get_available_packet_count() > 0:
			var data: PackedByteArray = _listener.get_packet()
			var ip: String = _listener.get_packet_ip()
			var found: Dictionary = parse_packet(data)
			if found.is_empty() or not ip.is_valid_ip_address():
				continue
			if not hosts.has(ip):
				if hosts.size() >= MAX_HOSTS:
					continue
				changed = true
			elif hosts[ip].name != found.name:
				changed = true
			hosts[ip] = {"name": found.name, "seen": now}
		for ip: String in hosts.keys():
			if now - int(hosts[ip].seen) > HOST_EXPIRES_MS:
				hosts.erase(ip)
				changed = true
		if changed:
			hosts_changed.emit()

func sorted_hosts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for ip: String in hosts.keys():
		result.append({"ip": ip, "name": hosts[ip].name})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.ip < b.ip)
	return result

# Pure helpers, separate from sockets so they can be unit tested.
static func clean_name(value: String) -> String:
	var text: String = ""
	for character: String in value.strip_edges():
		if character.unicode_at(0) >= 32 and character.unicode_at(0) != 127:
			text += character
	text = text.substr(0, 16).strip_edges()
	return text if text != "" else "Player"

static func make_packet(host_name: String) -> PackedByteArray:
	return JSON.stringify({"g": MAGIC, "n": clean_name(host_name)}).to_utf8_buffer()

static func parse_packet(data: PackedByteArray) -> Dictionary:
	if data.size() == 0 or data.size() > 200:
		return {}
	var parser: JSON = JSON.new()
	if parser.parse(data.get_string_from_utf8()) != OK: # quiet: junk packets must not spam errors
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return {}
	var packet: Dictionary = parsed
	if packet.get("g", "") != MAGIC or not packet.get("n", null) is String:
		return {}
	return {"name": clean_name(str(packet.n))}

static func broadcast_targets(addresses: PackedStringArray) -> Array[String]:
	var targets: Array[String] = ["255.255.255.255"]
	for address: String in addresses:
		var parts: PackedStringArray = address.split(".")
		if parts.size() != 4 or address.begins_with("127.") or address.begins_with("169.254."):
			continue
		var target: String = "%s.%s.%s.255" % [parts[0], parts[1], parts[2]]
		if not targets.has(target):
			targets.append(target)
	return targets
