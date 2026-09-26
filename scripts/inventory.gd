extends Panel

@export var slots : Array[InventorySlot]

func _ready():
	InventorySingleton.OnInventoryChanged.connect(updateInventoryUi)

func updateInventoryUi() -> void:
	for i in range(slots.size()):
		slots[i].resetSlot()
	var currentItems = InventorySingleton.items
	var keyList = currentItems.keys()
	for i in range(currentItems.size()):
		var currentKey = keyList[i]
		slots[i].Setup(currentKey, currentItems[currentKey])
	
