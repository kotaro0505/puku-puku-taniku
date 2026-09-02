extends SceneTree

func _initialize()->void:
	var args:=OS.get_cmdline_user_args()
	var script_path:="res://scripts/web_memory_smoke.gd" if args.is_empty() else str(args[0])
	root.add_child(load(script_path).new())
