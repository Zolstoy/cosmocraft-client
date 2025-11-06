extends Control

@onready var core = get_tree().get_first_node_in_group("core")
@onready var worlds_tree: Tree = get_tree().get_first_node_in_group("worlds_tree")
@onready var modale = get_tree().get_first_node_in_group("modale")
@onready var solo_tab = get_tree().get_first_node_in_group("solo_tab")
@onready var login_field: LineEdit = get_tree().get_first_node_in_group("login_field")
@onready var password_field: LineEdit = get_tree().get_first_node_in_group("password_field")
@onready var play_button: Button = get_tree().get_first_node_in_group("play_button")
@onready var quit_button: Button = get_tree().get_first_node_in_group("quit_button")
@onready var world_field = get_tree().get_first_node_in_group("world_field")
@onready var create_button = get_tree().get_first_node_in_group("create_button")
@onready var gamemode_tabs = get_tree().get_first_node_in_group("gamemode_tabs")
@onready var background = get_tree().get_first_node_in_group("background")
@onready var encrypted_switch: CheckButton = get_tree().get_first_node_in_group("encrypted_switch")
@onready var encrypted_label: Label = %"Encrypted_Label"
@onready var authentication_switch: CheckButton = get_tree().get_first_node_in_group("authentication_switch")
@onready var login_label: Label = get_tree().get_first_node_in_group("login_label")
@onready var password_label: Label = get_tree().get_first_node_in_group("password_label")
@onready var error_placeholder = get_tree().get_first_node_in_group("error_placeholder")
@onready var host_field: LineEdit = get_tree().get_first_node_in_group("host_field")
@onready var port_field = get_tree().get_first_node_in_group("port_field")
@onready var screen_size = get_viewport().get_visible_rect().size
@onready var delete_button = get_tree().get_first_node_in_group("delete_button")
@onready var open_folder_button = get_tree().get_first_node_in_group("open_folder_button")
@onready var playing_menu = get_tree().get_first_node_in_group("playing_menu")
@onready var leave_button = get_tree().get_first_node_in_group("leave_game_button")
@onready var back_to_game_button = get_tree().get_first_node_in_group("back_to_game_button")
@onready var reticle = get_tree().get_first_node_in_group("reticle")
@onready var loading = get_tree().get_first_node_in_group("loading")
@onready var connecting = get_tree().get_first_node_in_group("connecting")
@onready var title = get_tree().get_first_node_in_group("title")

@onready var port_label: Label = %"Port_Label"

var state = State.UI.MODAL_ONLINE
var root = null
var selected_world = null
var email_saved = ""
var nickname_saved = ""
var password_saved = ""

func _ready() -> void:
	root = worlds_tree.create_item()
	worlds_tree.hide_root = true

	get_tree().get_root().size_changed.connect(_on_size_changed)

	login_field.text_changed.connect(_on_login_changed)
	world_field.text_changed.connect(_on_world_changed)
	worlds_tree.item_selected.connect(_worlds_item_selected)
	worlds_tree.nothing_selected.connect(_worlds_nothing_selected)
	create_button.pressed.connect(_create_button_pressed)
	quit_button.pressed.connect(_quit_pressed)
	gamemode_tabs.tab_changed.connect(_gamemode_changed)
	play_button.pressed.connect(_play_button_pressed)
	encrypted_switch.toggled.connect(_on_encrypted_switch_toggled)
	authentication_switch.toggled.connect(_on_authentication_switch_toggled)
	delete_button.pressed.connect(_delete_button_pressed)
	open_folder_button.pressed.connect(_open_folder_button_pressed)
	leave_button.pressed.connect(_leave_button_pressed)
	back_to_game_button.pressed.connect(_back_to_game_button_pressed)


	_on_size_changed()

	if OS.has_feature("web"):
		_on_encrypted_switch_toggled(false)
		quit_button.visible = false
		gamemode_tabs.remove_child(solo_tab)
		host_field.set_text(JavaScriptBridge.eval("window.location.hostname"))
		# host_field.editable = false
		port_field.visible = false
		port_label.visible = false
		encrypted_switch.set_pressed_no_signal(true)
		encrypted_switch.visible = false
		encrypted_label.visible = false
		
	var config = ConfigFile.new()
	if config.load("user://config.cfg") == OK:
		var config_email = config.get_value("user", "email", "")
		if not config_email.is_empty():
			email_saved = str(config_email)

		var config_nickname = config.get_value("user", "nickname", "")
		if not config_nickname.is_empty():
			nickname_saved = str(config_nickname)

		var config_password = config.get_value("user", "password", "")
		if not config_password.is_empty():
			password_saved = str(config_password)

		refresh_login_fields()


func save_config():
	var config = ConfigFile.new()
	if config.load("user://config.cfg") != OK:
		config.save("user://config.cfg")

	config.set_value("user", "email", email_saved)
	config.set_value("user", "nickname", nickname_saved)
	config.set_value("user", "password", password_saved)
	config.save("user://config.cfg")

func refresh_login_fields():
	if authentication_switch.is_pressed():
		login_label.text = "Email"
		login_label.visible = true
		password_label.text = "Password"
		password_label.visible = true
		login_field.visible = true
		password_field.visible = true
		password_field.editable = true
		if not email_saved.is_empty():
			login_field.set_text(email_saved)
		if not password_saved.is_empty():
			password_field.set_text(password_saved)
		play_button.disabled = login_field.get_text().is_empty() || password_field.get_text().is_empty()
	else:
		login_label.text = "Nickname"
		login_label.visible = true
		password_label.visible = false
		login_field.visible = true
		password_field.visible = false
		if not nickname_saved.is_empty():
			login_field.set_text(nickname_saved)
		play_button.disabled = login_field.get_text().is_empty()

func back_to_welcome():
	playing_menu.visible = false
	reticle.visible = false
	modale.visible = true
	title.visible = true

func _leave_button_pressed():
	core.leave()

func _back_to_game_button_pressed():
	playing_menu.set_visible(false);

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if core.state == State.Core.LOADING || core.state == State.Core.PLAYING_SOLO || core.state == State.Core.PLAYING_ONLINE:
			playing_menu.set_visible(!playing_menu.is_visible());

func _open_folder_button_pressed():
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"), true)

func _delete_button_pressed():
	assert(selected_world)
	var file_path = ProjectSettings.globalize_path("user://%s.sbdb" % selected_world.get_text(0))
	if OS.move_to_trash(file_path) != OK:
		printerr("Failed to delete user save: %s" % file_path)
	list_worlds()

func _on_encrypted_switch_toggled(toggled):
	if toggled:
		encrypted_switch.set_text("on")
	else:
		encrypted_switch.set_text("off")

func _on_authentication_switch_toggled(toggled):
	if toggled:
		nickname_saved = login_field.get_text()
	else:
		email_saved = login_field.get_text()
		password_saved = password_field.get_text()
	refresh_login_fields()

func _create_button_pressed():
	list_worlds()
	core.play_solo(State.LaunchMode.CREATION)
	world_field.set_text("")

func _play_button_pressed():
	if state == State.UI.MODAL_ONLINE:
		if authentication_switch.is_pressed():
			if !login_field.get_text().is_empty():
				email_saved = login_field.get_text()
			if !password_field.get_text().is_empty():
				password_saved = password_field.get_text()
		else:
			if !login_field.get_text().is_empty():
				nickname_saved = login_field.get_text()
		core.play_online()
	elif state == State.UI.MODAL_SOLO:
		core.play_solo(State.LaunchMode.JOIN)
	else:
		assert(false)

func _quit_pressed() -> void:
	core.quit()

func _gamemode_changed(tab_id):
	if tab_id == 0:
		state = State.UI.MODAL_ONLINE
	elif tab_id == 1:
		state = State.UI.MODAL_SOLO

func _worlds_item_selected():
	selected_world = worlds_tree.get_selected()
	play_button.disabled = true
	delete_button.disabled = true

func _worlds_nothing_selected():
	selected_world = null
	play_button.disabled = false
	delete_button.disabled = false

func _on_login_changed(_text):
	play_button.disabled = login_field.get_text().is_empty()

func _on_world_changed(_text):
	create_button.disabled = world_field.get_text().is_empty()

func _on_size_changed():
	var new_screen_size = get_viewport().get_visible_rect().size
	screen_size = new_screen_size

func list_worlds():
	var dir = DirAccess.open("user://saves/")
	var files = dir.get_files()
	worlds_tree.clear()
	root = worlds_tree.create_item()
	for file in files:
		var orig = file
		var trimmed = file.trim_suffix(".db")
		if trimmed != orig:
			var item = worlds_tree.create_item(root) as TreeItem
			item.set_text(0, trimmed)
