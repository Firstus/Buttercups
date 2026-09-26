extends Panel

var items : Dictionary[Item, int]

func addItem(item: Item, amount: int) -> void:
	if(items.has(item)):
		var value = items.get(item)
		value = value + amount
		items.set(item, value)
	else:
		items[item] = amount
