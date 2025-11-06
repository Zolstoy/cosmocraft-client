extends Node


var login_hash = {
	"Login": {
		"nickname": ""
	}
}

@onready var core = get_tree().get_first_node_in_group("core")


var state = State.Network.IDLE
var socket: WebSocketPeer = null
var bodies = []
var body_ref_id = 0

func _ready():
	set_process(false)

func _process(_delta):
	var new_network_state = null
	var new_state = null
	socket.poll()

	var socket_state = socket.get_ready_state()

	if socket_state == WebSocketPeer.STATE_CLOSED:
		socket = WebSocketPeer.new()
		new_network_state = State.Network.IDLE
		set_process(false)
		core.leave()

	elif socket_state == WebSocketPeer.STATE_CLOSING:
		pass

	elif socket_state == WebSocketPeer.STATE_CONNECTING:
		pass

	elif socket_state == WebSocketPeer.STATE_OPEN:
		if state == State.Network.CONNECTING:
			if core.ui.state == State.UI.MODAL_ONLINE:
				login_hash["Login"]["email"] = core.ui.login_field.get_text()
				login_hash["Login"]["password"] = core.ui.password_field.get_text()
			else:
				login_hash["Login"]["email"] = "Player"
			if socket.send_text(JSON.stringify(login_hash)) != OK:
				print("Send error")
			else:
				new_network_state = State.Network.AUTHENTICATING

		elif state == State.Network.AUTHENTICATING:
			if socket.get_available_packet_count():
				var variant = JSON.parse_string(socket.get_packet().get_string_from_utf8())

				if variant["success"] == false:
					print("Login failure: %s" % variant["message"])
					core.ui.error_placeholder.set_text("Authentication failed: %s" % variant["message"])
					socket.close()
				else:
					print("Login success, id is %s" % variant["message"])
					core.spawner.set_process(true)
					core.player.set_process(true)
					core.player.set_process_input(true)
					core.ui.connecting.visible = false
					core.player.visible = true
					core.ui.title.visible = false
					new_network_state = State.Network.WAITING_GAMEINFO
					if core.server.state == State.Server.RUNNING:
						new_state = State.Core.PLAYING_SOLO
					else:
						new_state = State.Core.PLAYING_ONLINE
		elif state == State.Network.WAITING_GAMEINFO:
			while socket.get_available_packet_count():
				var variant = JSON.parse_string(socket.get_packet().get_string_from_utf8())
				if variant.has("Player"):
					var coords = variant["Player"]["coords"]
					core.player.position = Vector3(coords[0], coords[1], coords[2])
				elif variant.has("Env"):
					var env = variant["Env"]
					if env.has("Init"):
						(core.spawner.init_elements as Array).append_array(env["Init"] as Array)
					elif env.has("Update"):
						(core.spawner.update_elements as Array).append_array(env["Update"] as Array)
					
	if new_network_state:
		state = new_network_state
	if new_state:
		core.state = new_state

func connect_to_server(host: String, port: int, secure: bool):
	socket = WebSocketPeer.new()
	socket.inbound_buffer_size = 1000000
	socket.outbound_buffer_size = 1000000
	socket.max_queued_packets = 10000

	var url: String
	if secure:
		url = "wss://"
	else:
		url = "ws://"
	if OS.has_feature("web"):
		url += "%s" % host
	else:
		url += "%s:%s" % [host, port]

	if socket.connect_to_url(url, null) != OK:
		printerr("Could not connect")
		core.ui.error_placeholder.set_text("Could not connect")
		core.ui.play_button.set_disabled(false)
		return

	print("Connecting to %s" % url)
	core.ui.loading.visible = false
	core.ui.connecting.visible = true
	state = State.Network.CONNECTING
	core.state = State.Core.LOADING
	set_process(true)
