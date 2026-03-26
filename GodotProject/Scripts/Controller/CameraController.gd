extends Node
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
@export_range(0.01, 5.0, 0.1, "suffix:s") var _orbitDuration: float = 1.0
@export var _orbitTransition: Tween.TransitionType = Tween.TRANS_LINEAR
@export var _orbitEase: Tween.EaseType = Tween.EASE_OUT
var _targetHeading: float
var _rotateTween: Tween

func _ready():
	_targetHeading = $Heading.rotation.y

func Zoom(scroll: int):
	_zoom = clamp(_zoom + scroll,_minZoom, _maxZoom )
	
	if $Heading/Pitch/Camera3D.projection == Camera3D.PROJECTION_ORTHOGONAL:
		$Heading/Pitch/Camera3D.position.z = 100
		$Heading/Pitch/Camera3D.size = _zoom
	else:
		$Heading/Pitch/Camera3D.position.z = _zoom

func Orbit(direction: Vector2):
	if direction.x != 0:
		var step := deg_to_rad(45)

		var current : float = $Heading.rotation.y
		var raw_target := _targetHeading + direction.x * step

		var diff := wrapf(raw_target - current, -PI, PI)
		_targetHeading = current + diff

		if _rotateTween and _rotateTween.is_running():
			_rotateTween.kill()

		_rotateTween = create_tween()
		_rotateTween.tween_property(
			$Heading,
			"rotation:y",
			_targetHeading,
			_orbitDuration
		).set_trans(_orbitTransition).set_ease(_orbitEase)
	
func Pitch(direction: Vector2):
	if direction.x != 0:
		var headingSpeed: int = 2
		var headingAngle: float = $Heading.rotation.y
		headingAngle += direction.x * headingSpeed * get_process_delta_time()
		$Heading.rotation.y = headingAngle
		while $Heading.rotation.y > deg_to_rad(360):
			$Heading.rotation.y -= deg_to_rad(720)
		while $Heading.rotation.y < deg_to_rad(-360):
			$Heading.rotation.y += deg_to_rad(720)
	if direction.y !=0:
		var orbitSpeed: int = 2
#		var vAngle: float = direction.y
		var orbitAngle: float = $Heading/Pitch.rotation.x
		orbitAngle += direction.y * orbitSpeed * get_process_delta_time()
		orbitAngle = clamp(orbitAngle,deg_to_rad(_minPitch), deg_to_rad(_maxPitch) )
		$Heading/Pitch.rotation.x = orbitAngle	
	
func _process(delta):
	if _follow:
		self.position = self.position.lerp(_follow.position, _followSpeed * delta)

func setFollow(follow: Node3D):
	if follow:
		_follow = follow
		
func AdjustedMovement(originalPoint:Vector2i):
	var angle: float = rad_to_deg($Heading.rotation.y)
	var offset: int = 1 # guarrada
	angle -= offset;
	
	if ((angle >= -45 && angle < 45) || ( angle < -315 || angle >= 315)):
		return originalPoint
		
	elif ((angle >= 46 && angle < 131) || ( angle >= -316 && angle < -211 )):
		return Vector2i( originalPoint.y, originalPoint.x * -1)
		
	elif ((angle >= 131 && angle < 211) || ( angle >= -211 && angle < -131 )):
		return Vector2i(originalPoint.x * -1, originalPoint.y * -1)

	elif ((angle >= 211 && angle < 316) || ( angle >= -130 && angle < -45 )):
		return Vector2i(originalPoint.y * -1, originalPoint.x)

	else:
		print("Camera angle is wrong: " + str(angle))
		return originalPoint