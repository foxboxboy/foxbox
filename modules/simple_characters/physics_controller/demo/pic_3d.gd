# thank you to https://youtu.be/zTp7bWnlicY
extends RefCounted
class_name Pid3D

## Proportional. Further you are from the target, the harder you push.
## Increase for snappiness/responsiveness.
var _p: float
## Integral. Fixes small errors that build up over time.
var _i: float
## Derivative. Acts as a damper to prevent jittering.
var _d: float

var _prev_error: Vector3
var _error_integral: Vector3


func _init(p: float, i: float, d: float) -> void:
	_p = p
	_i = i
	_d = d


func update(error: Vector3, delta: float) -> Vector3:
	_error_integral += error * delta
	var error_derivative = (error - _prev_error) / delta
	_prev_error = error
	return _p * error + _i * _error_integral + _d * error_derivative 
