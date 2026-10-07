extends RefCounted
class_name PlayerState
var position := Vector2.ZERO
var hp := 110.0
var max_hp := 110.0
var speed := 226.0
var character := "noah"
var blessing := "attack"
var contracts: Array[String] = []
var invulnerability := 0
var evolved := false
var stats: Dictionary = {}
var revival_used := false
