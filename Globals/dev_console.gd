extends Node3D

func _ready() -> void:
	Console.add_command("hello", console_hello)
	
func console_hello():
	Console.print_line("hello there!")
