class_name CameraConfig
extends Resource

@export var follow_speed: float = 12.0
@export_group("Third person")
@export var distance: float = 4.2
@export var height: float = 1.35
@export var shoulder: float = 0.45
@export var sensitivity: float = 0.003
@export var min_pitch: float = -65.0
@export var max_pitch: float = 25.0
@export_group("Isometric")
@export var iso_yaw: float = 45.0
@export var iso_pitch: float = -55.0
@export var iso_distance: float = 15.0
@export var iso_height: float = 0.9
@export var iso_zoom: float = 17.0
@export var iso_orthographic: bool = true

@export_group("Isometric visibility")
@export var occlusion_enabled: bool = true
@export var highlight_enabled: bool = true
@export_range(0.05, 0.6) var occlusion_radius: float = 0.32
@export_range(0.0, 1.0) var obstacle_opacity: float = 0.28
@export_range(0.01, 1.0) var fade_out_time: float = 0.18
@export_range(0.01, 1.0) var restore_time: float = 0.24
@export_range(0.0, 1.0) var highlight_intensity: float = 0.28
@export_range(0.02, 0.2) var occlusion_interval: float = 0.05
@export_range(0.05, 0.5) var occlusion_hold: float = 0.12
