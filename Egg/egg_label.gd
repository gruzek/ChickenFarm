extends MarginContainer

@export var starting_eggs = 0

@onready var egg_label: Label = $EggLabel

var eggs: int:
	set(eggs_in):
		eggs = eggs_in # Makes sure it won't go below 0
		egg_label.text = ("Eggs: " + str(eggs))
		print("got egg")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	eggs = starting_eggs


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
