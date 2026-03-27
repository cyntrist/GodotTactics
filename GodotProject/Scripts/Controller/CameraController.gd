extends Node3D
class_name CameraController

@export_group("Follow")
@export var _followSpeed: float = 3.0
var _follow: Node3D

@export_group("Zoom")
@export_range(0, 25) var _minZoom: int = 5
@export_range(0, 25) var _maxZoom: int = 20
var _zoom: int = 10

@export_group("Pitch")
@export_range(-180, 0) var _minPitch: int = -90
@export_range(0, 180) var _maxPitch: int = 0

@export_group("Orbit")
@export_range(0.01, 5.0, 0.1, "suffix:s") var _orbitDuration: float = 0.25
@export var _orbitTransition: Tween.TransitionType = Tween.TRANS_SINE
@export var _orbitEase: Tween.EaseType = Tween.EASE_OUT

var _headingIndex: int = 0
var _targetHeading: float
var _rotateTween: Tween

func _ready():
	var deg := fposmod(rad_to_deg($Heading.rotation.y), 360.0)
	_headingIndex = int(round(deg / 45.0)) % 8
	_targetHeading = _headingIndex * deg_to_rad(45)
	$Heading.rotation.y = _targetHeading

func Zoom(scroll: int):
	_zoom = clamp(_zoom + scroll, _minZoom, _maxZoom)

	var cam := $Heading/Pitch/Camera3D
	if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
		cam.position.z = 100
		cam.size = _zoom
	else:
		cam.position.z = _zoom

func Orbit(direction: Vector2):
	if direction.x == 0:
		return

	_headingIndex = (_headingIndex + int(sign(direction.x))) % 8
	if _headingIndex < 0:
		_headingIndex += 8

	_targetHeading = _headingIndex * deg_to_rad(45)

	if _rotateTween and _rotateTween.is_running():
		_rotateTween.kill()
		
	var current : float = $Heading.rotation.y
	var diff := wrapf(_targetHeading - current, -PI, PI)
	var next := current + diff

	_rotateTween = create_tween()
	_rotateTween.tween_property(
		$Heading,
		"rotation:y",
		next,
		_orbitDuration
	).set_trans(_orbitTransition).set_ease(_orbitEase)

func Pitch(direction: Vector2):
	if direction.y != 0:
		var orbitSpeed := 2.0
		var orbitAngle : float = $Heading/Pitch.rotation.x
		orbitAngle += direction.y * orbitSpeed * get_process_delta_time()
		orbitAngle = clamp(orbitAngle, deg_to_rad(_minPitch), deg_to_rad(_maxPitch))
		$Heading/Pitch.rotation.x = orbitAngle

func _process(delta):
	if _follow:
		position = position.lerp(_follow.position, _followSpeed * delta)

func setFollow(follow: Node3D):
	_follow = follow

func AdjustedMovement(input: Vector2i) -> Vector2i:
	match _headingIndex:
		1: return input                          # 0°
		2: return Vector2i(input.y, -input.x)    # 45°
		3: return Vector2i(input.y, -input.x)    # 90°
		4: return Vector2i(-input.x, -input.y)   # 135°
		5: return Vector2i(-input.x, -input.y)   # 180°
		6: return Vector2i(-input.y, input.x)    # 225°
		7: return Vector2i(-input.y, input.x)    # 270°
		0: return Vector2i(input.x, input.y)     # 315°
	
	return input