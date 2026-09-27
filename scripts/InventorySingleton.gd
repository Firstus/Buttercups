extends Node
#PLAYER
var items : Dictionary[Item, int]

var money : int = 1000

signal OnInventoryChanged
signal OnMoneyChanged

func addAmount(item: Item, amount: int) -> void:
	if(items.has(item)):
		var value = items.get(item)
		value = value + amount
		items.set(item, value)
	else:
		items[item] = amount
	OnInventoryChanged.emit()
	

func hasRecipeIngredients(recipe: Recipe) -> bool:
	for ingredient in recipe.incredients:
		if items.get(ingredient, 0) <= 0:
			return false
	return true


func RemoveByRecipe(recipe: Recipe) -> bool:
	if(!hasRecipeIngredients(recipe)):
		return false
	for i in range(recipe.incredients.size()):
		removeAmount(recipe.incredients[i], 1)
	return true

func removeAmount(item: Item, amount: int) -> bool:
	if(items.has(item)):
		var value = items.get(item)
		value = value - amount
		if(value <= 0):
			items.erase(item)
		else:
			items.set(item, value)
		OnInventoryChanged.emit()
		return true
	return false

func changeMoney(amount: int) -> void:
	money += amount
	OnMoneyChanged.emit()
