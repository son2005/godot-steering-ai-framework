extends KinematicBody2D
# Represents a ship that chases after the player.


export var use_seek: bool = false

var _blend: GSTBlend

var _linear_drag_coefficient := 0.025
var _angular_drag := 0.1
var _direction_face := GSTAgentLocation.new()

onready var agent := GSTKinematicBody2DAgent.new(self)
onready var accel := GSTTargetAcceleration.new()
onready var player_agent: GSTSteeringAgent = owner.find_node("Player", true, false).agent


func _ready() -> void:
	agent.calculate_velocities = false
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_direction_face.position = agent.position + accel.linear.normalized()
	
	_blend.calculate_steering(accel)

	agent.angular_velocity = clamp(
			agent.angular_velocity + accel.angular,
			-agent.angular_speed_max,
			agent.angular_speed_max
	)
	agent.angular_velocity = lerp(agent.angular_velocity, 0, _angular_drag)

	rotation += agent.angular_velocity * delta
	
	var linear_velocity := (
			GSTUtils.to_vector2(agent.linear_velocity) + 
			(GSTUtils.angle_to_vector2(rotation) * -agent.linear_acceleration_max)
	)
	linear_velocity = linear_velocity.clamped(agent.linear_speed_max)
	linear_velocity = linear_velocity.linear_interpolate(
			Vector2.ZERO,
			_linear_drag_coefficient
	)
	
	linear_velocity = move_and_slide(linear_velocity)
	agent.linear_velocity = GSTUtils.to_vector3(linear_velocity)


func setup(predict_time: float, linear_speed_max: float, linear_accel_max: float) -> void:
	var behavior: GSTSteeringBehavior
	if use_seek:
		behavior = GSTSeek.new(agent, player_agent)
	else:
		behavior = GSTPursue.new(agent, player_agent, predict_time)
	
	var orient_behavior := GSTFace.new(agent, _direction_face)
	orient_behavior.alignment_tolerance = deg2rad(5)
	orient_behavior.deceleration_radius = deg2rad(5)
	
	_blend = GSTBlend.new(agent)
	_blend.add(behavior, 1)
	_blend.add(orient_behavior, 1)
	
	agent.angular_acceleration_max = deg2rad(40)
	agent.angular_speed_max = deg2rad(90)
	agent.linear_acceleration_max = linear_accel_max
	agent.linear_speed_max = linear_speed_max
	
	set_physics_process(true)
