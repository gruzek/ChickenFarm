extends MarginContainer

@export var starting_eggs = 0

@onready var egg_label: Label = $EggLabel
@onready var coop_label: Label = $CoopLabel

var eggs: int:
	set(eggs_in):
		eggs = eggs_in # Makes sure it won't go below 0
		egg_label.text = ("Eggs: " + str(eggs))
		print("got egg")

var chickens: int:
	set(chickens_in):
		chickens = chickens_in
		var chicken_text = str(chickens) + " Chicken" + ("s" if chickens != 1 else "")
		coop_label.text = chicken_text


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	eggs = starting_eggs
	# Chickens will manage their own count when they're created


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
