A ``SpringArm3D`` that treats its length as something you animate rather than something you set.

Third person cameras need to move between over the shoulder and pulled back, and doing that by
assigning ``spring_length`` directly snaps. :ref:`class_FoxZoomSpringArm3D` interpolates toward
a target length in a frame independent way, so the movement looks the same at any framerate.

It also emits signals as the arm crosses configured thresholds, which is what you connect to
hide the player model when the camera comes close enough to see inside it. Doing that from
signals rather than polling means the visibility toggle happens exactly once per crossing.

There is a multiplayer authority check built in, so an arm on a peer you do not control will not
fight you for the camera.

Pair it with :doc:`module_aim_gimbal`. The gimbal handles where the camera looks, the arm
handles how far away it sits.
