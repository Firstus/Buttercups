extends Node
#Fridge
# TODO: Replace with the fridge's real storage once it exists.
var items: Dictionary[Item, int] = {
	preload("res://assets/Items/Mehl.tres") as Item: 1,
	preload("res://assets/Items/Backpulver.tres") as Item: 1,
	preload("res://assets/Items/Zucker.tres") as Item: 1,
	preload("res://assets/Items/Ei.tres") as Item: 1,
	preload("res://assets/Items/Butter.tres") as Item: 1,
	preload("res://assets/Items/Blaubeeren.tres") as Item: 0,
}

signal OnFridgeChanged

func addAmount(item: Item, amount: int) -> void:
	if(items.has(item)):
		var value = items.get(item)
		value = value + amount
		items.set(item, value)
	else:
		items[item] = amount
	OnFridgeChanged.emit()
	

func RemoveByRecipe(recipe: Recipe) -> bool:
	for i in range(recipe.incredients.size()):
		if(!items.has(recipe.incredients[i])):
			return false
	for i in range(recipe.incredients.size()):
		removeAmount(recipe.incredients[i], 1)
	return true

func removeAmount(item: Item, amount: int) -> bool:
	if(items.has(item) && items[item] > 0):
		var value = items.get(item)
		value = value - amount
		items.set(item, value)
		OnFridgeChanged.emit()
		InventorySingleton.addAmount(item, 1)
		return true
	return false
