extends RefCounted
class_name RunState
var player := PlayerState.new()
var progression := ProgressionState.new()
var rng := RunRng.new()
var tick := 0
var field_tick := 0
var seed_value := 1
var phase := "RUNNING"
var endless := false
var boss_stage := 0
var last_damage_source := ""
var settled := false
var settlement_reward := 0
