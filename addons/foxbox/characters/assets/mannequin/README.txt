"Test dummy" blockbench bbmodel and imported gltf model.

Purpose of this module is to provide you with basic models to work off and reference.
There are three variants. Merged is reccomended in most cases.

BLOCKED:
	Every limb is its own mesh. There is no armature whatsoever.

MERGED (reccomended):
	All limbs and textures are merged. There is an armature.
	This is very performant and easy to work with.
	The armature is very useful for animations.
	Having a single mesh and surface makes things very performant. 

SPLIT:
	Same as merged but all the limbs are technically split up.
	This will not show up in Godot, but in blockbench you can see
	the limbs are each their own mesh.
	In Godot, this means many more draw calls and is far less 
	performant.
	For small games this won't matter if you need more control.




NOTE: 
	This model is also how the tates_framework/simple_characters/animations gets imported. 
