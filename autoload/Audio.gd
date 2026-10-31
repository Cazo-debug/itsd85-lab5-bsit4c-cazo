extends Node

# Phase 1 contract; actual audio assets and playback arrive in Phase 5.
func play_sfx(_sound_name: String, _pitch: float = 1.0) -> void:
	if not GameState.settings.get("sound", true):
		return

func play_music() -> void:
	if not GameState.settings.get("sound", true):
		return
