extends Node

enum LOBBY_DISTANCE { CLOSE, NORMAL, FAR, WORLDWIDE }

const MOD_ID := "Toes.PondPortal"

var portal_noise_scene := preload("res://mods/Toes.PondPortal/scenes/portal_noise.tscn")

onready var TackleBox := $"/root/TackleBox"
onready var Chat = get_node("/root/ToesSocks/Chat")
onready var Players = get_node("/root/ToesSocks/Players")
onready var Hotkeys = get_node("/root/ToesSocks/Hotkeys")

var known_lobbies := []
var recently_visited := {}
var timer := Timer.new()

var just_took_portal := false
## Where the player portaled from
var portal_in_pos

var CONFIG_FILE_URI : String
var default_config := {
	"allowMature": false,
	"sendGreetingMessage": true,
	"greetingMessage": "arrived through the Pond Portal... neat!",
	"sendPartingMessage": true,
	"partingMessage": "jumped into the Pond Portal and went to another dimension. Bye!",
	"allowWhenLobbyHost": true,
	"allowLakePortal": true,
	"playPortalSound": true
}
var config := {}

var last_call_times = {}


func call_debounced(key: String, func_ref: FuncRef, delay_secs: float, args := []) -> void:
	var now = OS.get_ticks_msec()
	var last = last_call_times.get(key, -delay_secs * 1000.0)
	if now - last >= delay_secs * 1000.0:
		last_call_times[key] = now
		func_ref.call_funcv(args)


func _get_config_path(mod_id: String) -> String:
	var file := File.new()
	var config_file_path: String = TackleBox._get_gdweave_dir().plus_file(mod_id + ".json")
	var exists: bool = file.file_exists(config_file_path)
	return config_file_path if exists else ""


func _init_config() -> void:
	CONFIG_FILE_URI = "file://" + _get_config_path(MOD_ID)
	var saved_config = TackleBox.get_mod_config(MOD_ID)
	if not saved_config:
		saved_config = default_config.duplicate()
	for key in default_config.keys():
		if not saved_config.has(key):
			saved_config[key] = default_config[key]
	config = saved_config
	_save_config()


func _save_config() -> void:
	var valid_config = _validate_config()
	if not valid_config:
		print("[POND PORTAL] INVALID CONFIGURATION - USING DEFAULT AS FALLBACK")
		config = default_config.duplicate()
	TackleBox.set_mod_config(MOD_ID, config)


func _validate_config() -> bool:
	return (
		config.allowMature is bool
		and config.sendGreetingMessage is bool
		and config.greetingMessage is String
		and config.sendPartingMessage is bool
		and config.allowWhenLobbyHost is bool
		and config.allowLakePortal is bool
		and config.playPortalSound is bool
	)


func _config_updated(id: String, __):
	if id == MOD_ID:
		_init_config()


func _process(__):
	if str(get_tree().current_scene.get_path()) == "/root/main_menu":
		just_took_portal = false
		portal_in_pos = null
	if Players.local_player != null and is_instance_valid(Players.local_player):
	_fix_paint_node_collision_shape()


func _ready():
	_init_config()
	# Network.connect("_connected_to_lobby", self, "on_ingame")
	Network.connect("_webfishing_lobbies_returned", self, "_lobby_list_returned")
	Players.connect("ingame", self, "on_ingame")
	Players.connect("outgame", self, "on_outgame")
	# Players.connect("at_main_menu", self, "_on_main_menu")
	TackleBox.connect("mod_config_updated", self, "_config_updated")

	var portal_noise = portal_noise_scene.instance()
	add_child(portal_noise)

	timer.name = "PondPortal Lobby Refresh"
	timer.wait_time = 15
	timer.autostart = false
	timer.connect("timeout", self, "_refresh_lobbies")
	add_child(timer)


func _refresh_lobbies():
	var tags_to_filter := ["talkative", "quiet", "grinding", "chill", "silly", "hardcore", "modded"]
	if config.get("allowMature", false):
		tags_to_filter.append("mature")
	Network._find_all_webfishing_lobbies(tags_to_filter, false)


func _lobby_list_returned(lobbies: Array):
	lobbies.sort_custom(self, "_lobby_sort_random")
	var sorted_lobbies := lobbies  # lol Godot3
	var list := []
	for lobby_id in sorted_lobbies:
		# var lobby_num_members := Steam.getNumLobbyMembers(lobby_id)
		var browser_visible := Steam.getLobbyData(lobby_id, "public")
		var population := int(Steam.getLobbyData(lobby_id, "count"))
		var population_cap := int(Steam.getLobbyData(lobby_id, "cap"))
		var is_mature = int(Steam.getLobbyData(lobby_id, "mature")) == 1
		var is_modded = int(Steam.getLobbyData(lobby_id, "modded")) == 1

		# Filters
		if browser_visible != "true":
			continue
		if population >= population_cap:
			continue
		if lobby_id in recently_visited.keys():
			continue
		# if known_lobbies.has(lobby_id): continue
		if population == 0:
			continue

		list.append(lobby_id)
	known_lobbies = list
	# Chat.write("Lobbies available: %s" % known_lobbies.size())


func _on_ingame():
	if just_took_portal and portal_in_pos:
		Players.local_player.global_transform.origin = portal_in_pos
		portal_in_pos = false
	_send_greeting_message()
	recently_visited[Network.STEAM_LOBBY_ID] = true
	_refresh_lobbies()
	timer.start()


func _on_outgame():
	timer.stop()


func _lobby_sort_random(a, b):
	return randf() < 0.5


func _on_water_entered(area: Area) -> bool:
	var matcher := RegEx.new()
	# /root/world/Viewport/main/map/main_map/zones/main_zone/lake_water/water47/Area
	var area_path := str(area.get_path())
	matcher.compile("lake_water/water(\\d+)")
	var result = matcher.search(area_path)
	if result == null:
		return false
	var water_id = int(result.strings[1])
	var valid_portal_locations := [20, 21, 22, 23, 24, 25, 26, 51, 52, 53, 54, 55, 56, 57, 59]
	if config.allowLakePortal:
		for id in range(2, 17):
			valid_portal_locations.append(id)
	var is_portal_water = water_id in valid_portal_locations
	if not is_portal_water:
		return false
	if Players.local_player.diving:
		if Players.get_lobby_owner() == Players.local_player and config.allowWhenLobbyHost == false:
			Chat.write("Your [url=%s]current settings[/url] deactivate Pond Portal while hosting a lobby" % CONFIG_FILE_URI)
			return false
		if known_lobbies.empty():
			Chat.write("The pond portal isn't ready yet or there were no destinations available! Wait a minute and try again...")
			return false
		just_took_portal = true
		if config.playPortalSound:
			var portal_noise: AudioStreamPlayer = get_node("PortalNoise")
			portal_noise.pitch_scale = rand_range(0.7, 0.85)
			portal_noise.play()
		_portal_to(known_lobbies[randi() % known_lobbies.size()])
		return true
	else:
		Chat.write("(If you were trying to use it, the Pond Portal only works when you [b]dive[/b] in!)")
	return false


func _send_greeting_message():
	if not config.sendGreetingMessage:
		return
	if just_took_portal:
		Chat.emote(config.greeting)
	just_took_portal = false


func _send_leaving_message():
	if not config.sendPartingMessage:
		return
	Chat.emote(config.partingMessage)


## Changes the player's paint_node area from a box to a flat plane
## this allows for reliably detecting collision with water areas
## which otherwise will always detect from the paint_node (???)
func _fix_paint_node_collision_shape():
	var paint_node: Spatial = Players.local_player.get_node("paint_node")
	var paint_node_area: Area = paint_node.get_node("Area")
	var collision: CollisionShape = paint_node_area.get_child(0)
	if not collision.get_shape() is PlaneShape:
		var replacement_collision := PlaneShape.new()
		collision.set_shape(replacement_collision)


func _portal_to(lobby_id) -> void:
	portal_in_pos = Players.local_player.last_valid_pos + Vector3(0, 8.5, 0)
	just_took_portal = true
	send_leaving_message()
	Network._leave_lobby()
	Network._reset_lobby_status()
	Network._reset_network_socket()
	Network._connect_to_lobby(lobby_id)


# Debounced methods
func on_ingame():
	call_debounced("in_game", funcref(self, "_on_ingame"), 10.0)
func on_outgame():
	call_debounced("out_game", funcref(self, "_on_outgame"), 10.0)

func on_water_entered(area: Area):
	call_debounced("on_drown", funcref(self, "_on_water_entered"), 5.0, [area])


func send_greeting_message():
	call_debounced("greeting", funcref(self, "_send_greeting_message"), 10.0)


func send_leaving_message():
	call_debounced("leaving", funcref(self, "_send_leaving_message"), 10.0)
