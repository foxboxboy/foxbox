extends Label
	

func _process(_delta):
	text = "fps: " + str(Engine.get_frames_per_second())
	text += "\n"+"active objects: "+str(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS))
	text += "\n"+"draw calls: "+str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	text += "\n"+"objects: "+str(Performance.get_monitor(Performance.OBJECT_COUNT))
	text += "\n"+"nodes: "+str(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
