extends Panel

@export var slots : Array[InventorySlot]
var items : Dictionary[Item, int]

func addAmount(item: Item, amount: int) -> void:
	if(items.has(item)):
		var value = items.get(item)
		value = value + amount
		items.set(item, value)
	else:
		items[item] = amount
	updateInventoryUi()
	
func removeAmount(item: Item, amount: int) -> void:
	if(items.has(item)):
		var value = items.get(item)
		value = value - amount
		if(value <= 0):
			items.erase(item)
		else:
			items.set(item, value)
	updateInventoryUi()

func updateInventoryUi() -> void:
	for i in range(slots.size()):
		slots[i].resetSlot()
	var keyList = items.keys()
	for i in range(items.size()):
		var currentKey = keyList[i]
		slots[i].Setup(currentKey, items[currentKey])
	
