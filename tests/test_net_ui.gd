extends GutTest

var viewport: SubViewport
var prior_mode: String

func before_each() -> void:
	prior_mode = GameState.mode
	Net.navigating = false
	viewport = SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	add_child_autofree(viewport)

func after_each() -> void:
	Net.close_session()
	Net.navigating = true
	GameState.mode = prior_mode

func buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	if node is Button: result.append(node)
	for child: Node in node.get_children(): result.append_array(buttons(child))
	return result

func test_mode_and_four_slot_lobby_fit_portrait_and_keep_safe_touch_targets() -> void:
	var mode: Control = load("res://scenes/ui/ModeSelect.tscn").instantiate()
	viewport.add_child(mode)
	await wait_process_frames(4)
	for button: Button in buttons(mode):
		assert_gte(button.size.y, 120.0)
		assert_gte(button.global_position.y, 80.0)
		assert_lte(button.get_global_rect().end.y, 1280.0)
	mode.free()
	assert_eq(Net.host(AvatarData.default_avatar(), 17778), OK)
	for seat: int in range(1, 4):
		Net.owners[seat] = seat + 100
		Net.profiles[seat] = AvatarData.sanitize({"name": "LongRider1234"})
		Net.ready_peers[seat + 100] = true
	var lobby: Control = load("res://scenes/ui/Lobby.tscn").instantiate()
	viewport.add_child(lobby)
	await wait_process_frames(5)
	assert_eq(lobby.model.riders.size(), 4)
	assert_eq(lobby.slot_labels.size(), 4)
	assert_false(lobby.start_button.disabled)
	for item: Label in lobby.slot_labels:
		assert_gte(item.size.x, 280.0)
		assert_gte(item.size.y, 80.0)
		assert_false(item.text.is_empty())
	for button: Button in buttons(lobby):
		assert_gte(button.size.y, 120.0)
		assert_gte(button.global_position.y, 80.0)
		assert_lte(button.get_global_rect().end.y, 1280.0)
	var panels: RunPanels = RunPanels.new()
	viewport.add_child(panels)
	panels.show_online_pause(false)
	assert_eq(buttons(panels).size(), 1, "Guests can leave; the host owns resume and rematch")
	panels.show_online_result({"won": true, "time": 50.0, "stars": 3, "recoveries": 0}, "Sky Garden", true)
	await wait_process_frames(3)
	assert_eq(buttons(panels).size(), 3)
	for button: Button in buttons(panels):
		assert_gte(button.size.y, 120.0)
		assert_lte(button.get_global_rect().end.y, 1280.0)
