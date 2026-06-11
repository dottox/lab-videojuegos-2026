extends RefCounted
class_name LevelEditorState

var projectile_types: Array[String] = []
var projectile_patterns: Array[String] = []
var playfield_types: Array[String] = []
var phase_types: Array[String] = []

var zones: Array[ZoneArea] = []
var projectiles: Array[Projectile] = []
var playfields: Array[Playfield] = []
var phases: Array[Phase] = []

var selected_zone_index := -1
var selected_projectile_index := -1
var selected_playfield_index := -1
var selected_phase_index := 1

var zone_id_counter := 1
var playfield_id_counter := 1
var phase_id_counter := 1

var current_time_ms := 0
var music_length_ms := 0
var music_id := ""
var music_path := ""
var playfield_type := "normal"
var suppress_ui := false
var is_playing := false
var preview_mode := false
var live_preview = false
var dragging_projectile := false
