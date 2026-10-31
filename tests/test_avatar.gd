extends GutTest

func test_default_and_missing_fields() -> void:
	var base: Dictionary = AvatarData.default_avatar()
	assert_eq(AvatarData.sanitize(base), base)
	assert_eq(AvatarData.sanitize(null), base)
	assert_eq(AvatarData.sanitize(17), base)
	assert_eq(AvatarData.sanitize("bad"), base)
	assert_eq(AvatarData.sanitize({"skin": 0}), base)

func test_sanitize_untrusted_values() -> void:
	var clean: Dictionary = AvatarData.sanitize({"name": "A\n\tBCDEFGHIJKLMNOP", "skin": -3, "outfit": 900, "float_style": "duck", "hat": [], "toot": null})
	assert_eq(clean.name, "ABCDEFGHIJKL")
	assert_eq(clean.skin, 0)
	assert_eq(clean.outfit, 7)
	assert_eq(clean.float_style, 0)
	assert_eq(clean.hat, 0)
	assert_eq(clean.toot, 0)
	assert_eq(AvatarData.sanitize({"name": "   "}).name, "Player")

func test_randomized_options_remain_valid() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 42
	for index: int in range(100):
		var avatar: Dictionary = AvatarData.random_avatar(rng)
		assert_eq(AvatarData.sanitize(avatar), avatar)

func test_every_model_option_rebuilds() -> void:
	var model: AvatarModel = AvatarModel.new()
	add_child_autofree(model)
	for key: String in AvatarData.LIMITS:
		for index: int in range(AvatarData.LIMITS[key]):
			var avatar: Dictionary = AvatarData.default_avatar()
			avatar[key] = index
			model.apply(avatar)
			assert_gt(model.get_child_count(), 5)
			assert_eq(model.appearance[key], index)
