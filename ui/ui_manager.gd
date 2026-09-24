extends Control
class_name Ui_manager

#var mpp: MPPlayer
var anim_player: AnimationPlayer

enum PageId { QUIT, SETTINGS, BLANK, INFO }

@export var left_panel: Control
@export var right_panel: Control

@export var settings_page: Control
@export var quit_page: Control
@export var blank_page: Control
@export var info_page: Control

@export var btn_settings: Button 
@export var btn_quit: Button
@export var btn_info: Button
@export var btn_inventory: Button
@export var btn_quest: Button

@export var btn_quit_quit: Button

@export var info_label_player_index: Label

@export var player_number: Label

@export var Crosshair: Label


var player: Player

var pages: Dictionary = {}
var page_buttons: Dictionary = {}

var current_page: int = PageId.BLANK
var is_menu_open: bool = false
#
#func _ready() -> void:
	#player = get_parent() as Player
	#if not player:
		#push_error("Ui_manager must be a child of a Player node.")
		#return
#
	#player_number.text = "Player %d" % mpp.player_index
	#set_local_visibility(mpp.is_local)
	#
	#pages = {
		#PageId.SETTINGS: settings_page,
		#PageId.QUIT: quit_page,
		#PageId.BLANK: blank_page,
		#PageId.INFO: info_page,
	#}
#
	#page_buttons = {
		#PageId.SETTINGS: btn_settings,
		#PageId.QUIT: btn_quit,
		#PageId.INFO: btn_info,
		#PageId.INVENTORY: btn_inventory,
		#PageId.QUEST: btn_quest,
	#}
#
	#close_menu()
	#_update_quit_button_text()

func set_local_visibility(is_local: bool) -> void:
	player_number.visible = is_local
#
#func open_menu():
	#if current_page != PageId.BLANK:
		#navigate_to_page(PageId.BLANK)
	#is_menu_open = true
	#if mpp and mpp.is_local:
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#_update_quit_button_text()
	#left_panel.show()
	#right_panel.show()
	#Crosshair.hide()
#
#func close_menu():
	#if current_page != PageId.BLANK:
		#navigate_to_page(PageId.BLANK)
	#is_menu_open = false
	#if mpp and mpp.is_local:
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#left_panel.hide()
	#right_panel.hide()
	#Crosshair.show()

func navigate_to_page(page: int):
	current_page = page

	for id in pages.keys():
		pages[id].visible = (id == page)

	for id in page_buttons.keys():
		page_buttons[id].modulate = Color.YELLOW if id == page else Color.WHITE
#
#func _input(event: InputEvent) -> void:
	#if not mpp or not mpp.is_local:
		#return
#
	#if event.is_action_pressed("ui_cancel") or event.is_action_pressed("TAB"):
		#if is_menu_open:
			#close_menu()
		#else:
			#open_menu()
#
#func _process(_delta: float) -> void:
	#if not mpp or not mpp.is_local:
		#return
#
	#set_labels()
#
#func set_labels():
	#info_label_player_index.text = "You are player: %d\nCurrent ping: %d\nPlayer Id: %d" % [
		#mpp.player_index,
		#mpp.ping_ms,
		#mpp.player_id
	#]

func _on_btn_settings_pressed() -> void:
	navigate_to_page(PageId.SETTINGS)

func _on_btn_quit_pressed() -> void:
	navigate_to_page(PageId.QUIT)
#
#func _on_quit_quit_pressed() -> void:
	#if MultiplayerSessionManager.request_return_to_lobby():
		#return
#
	#if mpp.is_local and inventory_container:
		#InventoryManager.save_for_container(inventory_container)
#
	#MultiplayerSessionManager.leave_session()

func _on_btn_info_pressed() -> void:
	navigate_to_page(PageId.INFO)

#
#func _update_quit_button_text() -> void:
	#if not btn_quit_quit:
		#return
#
	#if MultiplayerSessionManager.is_local_host():
		#btn_quit_quit.text = "Return to Lobby"
	#else:
		#btn_quit_quit.text = "Leave Server"
