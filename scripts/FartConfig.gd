class_name FartConfig
extends Resource

# Every fart and rider-reaction tunable in one place. Edit the defaults here.
# Everything is presentation-only except push_scale, which scales the real thrust.

## Puffs spawned per burst (High quality / Low quality).
@export var puffs_per_burst: int = 9
@export var puffs_per_burst_low: int = 6
## Bursts per second while a rider holds the fart button.
@export var burst_rate: float = 3.0
## Seconds before a puff has fully faded to zero alpha.
@export var puff_lifetime: float = 1.0
## Final (fully grown) puff diameter range, in metres.
@export var puff_size_min: float = 1.0
@export var puff_size_max: float = 1.65
## How much a puff grows from spawn to full size (2-3x).
@export var puff_growth: float = 2.6
## Outward launch speed and upward drift.
@export var puff_speed_min: float = 1.8
@export var puff_speed_max: float = 3.4
@export var puff_rise: float = 0.7
## Peak opacity of a puff (soft, semi-transparent).
@export_range(0.0, 1.0) var puff_alpha: float = 0.85
## Hard cap on live puffs per rider; bursts are skipped while the cap is reached.
@export var max_live_puffs_per_rider: int = 40
## Gas colours, indexed by the avatar "toot" option (lime first).
@export var colors: Array[Color] = [Color("a6e22e"), Color("a066e8"), Color("ff92d0"), Color("ffe04a")]
## Physics: multiplies RingPhysicsProfile.thrust_acceleration. 1.0 keeps the tuned courses.
@export var push_scale: float = 1.0
## Rider squash-and-stretch length per burst, in seconds.
@export var squash_time: float = 0.32
## Float kick per burst (dip toward the farting seat), in degrees. Visual only.
@export var wobble_degrees: float = 4.0
## Puffs are blown back against the float's motion (m/s^2 per m/s), so the cloud
## streams behind and bends through turns. Visual only.
@export var puff_drag: float = 0.55
## Droplets thrown up where a burst's cloud meets the water (High quality only).
@export var splash_droplets: int = 7
## Random pitch spread of the per-burst fart sound (0 = always the same pitch).
@export var sound_pitch_jitter: float = 0.14
@export var burst_sound: bool = true
## Camera kick per burst. Skipped while the Reduced Motion setting is on.
@export var camera_kick: float = 0.06
## Small water ripple where the cloud meets the water.
@export var splash: bool = true

static var current: FartConfig = FartConfig.new()

## Emitters needed per rider so bursts can overlap, limited by the hard puff cap.
func emitters_per_rider() -> int:
	var overlap: int = ceili(puff_lifetime * burst_rate) + 1
	return clampi(mini(overlap, max_live_puffs_per_rider / maxi(puffs_per_burst, 1)), 1, 8)
