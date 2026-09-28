class_name AimProvider
extends Node

func sample(origin: Vector3, facing: Vector3, aiming: bool) -> AimSample:
	return AimSample.new(origin, origin + facing * 100.0, aiming)
