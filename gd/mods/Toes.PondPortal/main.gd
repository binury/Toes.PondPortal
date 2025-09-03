extends Node

enum LOBBY_DISTANCE{CLOSE, NORMAL, FAR, WORLDWIDE}

const MOD_ID := "Toes.PondPortal"

onready var TackleBox := $"/root/TackleBox"
onready var Chat = get_node("/root/ToesSocks/Chat")
onready var Players = get_node("/root/ToesSocks/Players")
onready var Hotkeys = get_node("/root/ToesSocks/Hotkeys")

var known_lobbies := []
var recently_visited := {}
var timer := Timer.new()

var just_took_portal := false

var default_config := {
	"allowMature": true
}
var config := {}

var last_call_times = {}
func call_debounced(key: String, func_ref: FuncRef, delay_secs: float) -> void:
	var now = OS.get_ticks_msec()
	var last = last_call_times.get(key, -delay_secs * 1000.0)
	if now - last >= delay_secs * 1000.0:
		last_call_times[key] = now
		func_ref.call_func()


func init_config() -> void:
	var saved_config = TackleBox.get_mod_config(MOD_ID)
	if not saved_config:
		saved_config = default_config.duplicate()
	for key in default_config.keys():
		if not saved_config.has(key):
			saved_config[key] = default_config[key]
	config = saved_config
	save_config()


func save_config() -> void:
	TackleBox.set_mod_config(MOD_ID, config)


func _ready():
	init_config()
	Network.connect("_connected_to_lobby", self, "on_ingame")
	Network.connect("_webfishing_lobbies_returned", self, "_lobby_list_returned")
	Players.connect("ingame", self, "on_ingame")

	timer.name = "PondPortal Lobby Refresh"
	timer.wait_time = 15
	timer.autostart = true
	timer.connect("timeout", self, "_refresh_lobbies")
	add_child(timer)


func _refresh_lobbies():
	var tags_to_filter := [
		"talkative", "quiet", "grinding", "chill", "silly", "hardcore", "modded"
	]
	if config.get("allowMature", false):
		tags_to_filter.append("mature")
	Network._find_all_webfishing_lobbies(tags_to_filter, false)


func _lobby_list_returned(lobbies: Array):
	lobbies.sort_custom(self, "_lobby_sort_random")
	var sorted_lobbies := lobbies # lol Godot3
	var list := []
	for lobby_id in sorted_lobbies:
		# var lobby_num_members := Steam.getNumLobbyMembers(lobby_id)
		var browser_visible := Steam.getLobbyData(lobby_id, "public")
		var population := int(Steam.getLobbyData(lobby_id, "count"))
		var population_cap := int(Steam.getLobbyData(lobby_id, "cap"))

		var is_mature = int(Steam.getLobbyData(lobby_id, "mature")) == 1
		var is_modded = int(Steam.getLobbyData(lobby_id, "modded")) == 1

		# Filters
		if browser_visible != "true": continue
		if population >= population_cap: continue
		if lobby_id in recently_visited.keys(): continue
		# if known_lobbies.has(lobby_id): continue
		if population == 0: continue

		list.append(lobby_id)
	known_lobbies = list
	# Chat.write("Lobbies available: %s" % known_lobbies.size())


func _on_ingame():
	yield(get_tree().create_timer(3.0), "timeout")
	recently_visited[Network.STEAM_LOBBY_ID] = true
	_send_greeting_message()
	_refresh_lobbies()
	timer.start()


func _on_outgame():
	timer.stop()


func _lobby_sort_random(a, b): return randf() < 0.5


func _on_water_entered():
	if Players.local_player.diving:
		# print("POND PORTAL ENTERED")
		if known_lobbies.empty():
			Chat.write("The pond portal isn't ready yet! Try again shortly")
			return false
		just_took_portal = true
		portal_to(known_lobbies[randi() % known_lobbies.size()])
		return true
	else:
		Chat.write("(If you were trying to use it, the Pond Portal only works when you [b]dive[/b] in!)")

func _send_greeting_message():
	if just_took_portal:
		Chat.emote("arrived through the Pond Portal... neat!")
	just_took_portal = false

func _send_leaving_message():
	Chat.emote("jumped into the Pond Portal and went to another dimension. Bye!")


# Debounced methods
func on_ingame():
	call_debounced("in_game", funcref(self, "_on_ingame"), 10.0)
func on_water_entered():
	call_debounced("on_drown", funcref(self, "_on_water_entered"), 10.0)
func send_greeting_message():
	call_debounced("greeting", funcref(self, "_send_greeting_message"), 10.0)
func send_leaving_message():
	call_debounced("leaving", funcref(self, "_send_leaving_message"), 10.0)


func portal_to(lobby_id) -> void:
	send_leaving_message()
	Network._leave_lobby()
	Network._reset_lobby_status()
	Network._reset_network_socket()
	Network._connect_to_lobby(lobby_id)
	
	yield(get_tree().create_timer(3.5), "timeout")
	send_greeting_message()
	
	
