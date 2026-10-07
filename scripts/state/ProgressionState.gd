extends RefCounted
class_name ProgressionState
var weapons: Dictionary = {}
var passives: Dictionary = {}
var evolutions: Dictionary = {}
var overclocks: Dictionary = {}
var level := 1
var exp := 0
var kills := 0
var gems := 0
var bosses := 0
var currency := 0
var choices: Array = []
var rooms: Dictionary = {}
var resonance := 0
var rerolls_used := 0
var banishes_used := 0
var reward_roll := 0
var banished: Array[String] = []
var last_pickup_tick := -1000
var gem_streak := 0
var max_gem_streak := 0
var chain := 0
var max_chain := 0
var boss_ids := PackedStringArray()

var terrain_ticks := PackedInt32Array([0,0,0,0,0,0])
var terrain_kills := PackedInt32Array([0,0,0,0,0,0])
var terrain_crystals := PackedInt32Array([0,0,0,0,0,0])
var terrain_bosses := PackedInt32Array([0,0,0,0,0,0])
var elite_kills := 0
var metrics: Dictionary = {"weapon_kills":{},"gimmick_count":{},"field_drop_count":{}}

var metrics_settled := false

var skips := 1
var banishes_bonus := 0

var gem_turret_charge := 0

var named_overclocks: Dictionary = {}
