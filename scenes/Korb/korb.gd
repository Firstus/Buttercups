extends Node2D

@export var toSellItems : Array[Item]

var _player_in_range := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if not event.is_action_pressed("action_command"):
		return

	if !doesPlayerHaveCookie():
		return

	InventorySingleton.SellAllCookies(toSellItems)
	get_viewport().set_input_as_handled()


# First configured recipe whose ingredients are in the inventory, or null.
func doesPlayerHaveCookie() -> bool:
	return InventorySingleton.hasCookieInInventory(toSellItems)



## The oven does not freeze the player, so the clock is the only "oven is on" indicator.
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
