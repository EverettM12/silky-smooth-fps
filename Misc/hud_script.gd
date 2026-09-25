class_name HUD
extends CanvasLayer

var weapon_manager: WeaponManager

@onready var weapon_stack_label_text: Label = %WeaponStackLabelText
@onready var weapon_name_label_text: Label = %WeaponNameLabelText
@onready var nb_ammo_in_mag_label_text: Label = %NbAmmoInMagLabelText
@onready var nb_ammo_total_label_text: Label = %NbAmmoTotalLabelText

func _ready() -> void:
	if weapon_manager != null:
		weapon_manager.weapon_stack_updated.connect(update_weapon_stack_display)

func set_weapon_manager(target_weapon_manager: WeaponManager) -> void:
	if weapon_manager != null and weapon_manager.weapon_stack_updated.is_connected(update_weapon_stack_display):
		weapon_manager.weapon_stack_updated.disconnect(update_weapon_stack_display)
	weapon_manager = target_weapon_manager
	if weapon_manager != null:
		if not weapon_manager.weapon_stack_updated.is_connected(update_weapon_stack_display):
			weapon_manager.weapon_stack_updated.connect(update_weapon_stack_display)
		update_weapon_stack_display()

func _process(_delta: float) -> void:
	if weapon_manager == null:
		return
	display_weapon_properties()

func update_weapon_stack_display() -> void:
	if weapon_manager == null:
		return
	var available_weapons_name_list: Array[String] = []
	for weapon_id in weapon_manager.weapon_list.keys():
		if weapon_id in weapon_manager.weapon_stack:
			available_weapons_name_list.append(weapon_manager.weapon_list[weapon_id].resources.weapon_name)
	weapon_stack_label_text.set_text(str(available_weapons_name_list))

func display_weapon_properties() -> void:
	if weapon_manager == null or weapon_manager.current_weapon == null:
		return
	weapon_name_label_text.set_text(str(weapon_manager.current_weapon.resources.weapon_name))
	nb_ammo_in_mag_label_text.set_text(
		str(
			weapon_manager.current_weapon.resources.total_ammo_in_mag /
			weapon_manager.current_weapon.resources.nb_proj_shots_at_same_time
		)
	)
	nb_ammo_total_label_text.set_text(
		str(
			weapon_manager.ammo_manager.ammo_dict[weapon_manager.current_weapon.resources.ammo_type] /
			weapon_manager.current_weapon.resources.nb_proj_shots_at_same_time
		)
	)
