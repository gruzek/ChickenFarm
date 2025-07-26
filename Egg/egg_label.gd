extends MarginContainer

@export var starting_eggs = 0
var current_eggs = 0
@onready var egg_label: Label = $EggLabel

var eggs: int:
	set(eggs_in):
		eggs = max(eggs_in, 0) # Makes sure it won't go below 0



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_egg_amount_changed(value: Variant) -> void:
	current_eggs += value
	egg_label.text = ("Eggs " + str(current_eggs))
