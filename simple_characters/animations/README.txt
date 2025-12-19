tates_framework/simple_characters/animatons

Simple library of generic animations.

The bone structure is vastly simplified compared to most
animation libraries. This allows for faster simpler animation
at the cost of complexity.

The bone structure is as follows:

pelvis
	thigh_l
		calf_l
			foot_l
	thigh_r
		calf_r
			foot_r
	stomach
		chest
			head
				head_tip
			collarbone_l
				bicep_l
					forearm_l
						hand_l
			collarbone_r
				bicep_r
					forearm_r
						hand_r
