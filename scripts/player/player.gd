class_name Player
extends CharacterBody2D
## Top-down 360° player (deliverable D). Uses a lightweight enum FSM for snappy
## input; "combat" is a flag layered on movement (Hotline Miami feel — see the
## open question in the architecture doc). Built in code: no hand-authored scene.
##
## Controls: WASD move · Shift sprint · Space dodge · LMB fire · R reload

enum PState { IDLE, MOVE, SPRINT, DODGE, DEAD }

@export var max_hp: float = 100.0
@export var move_speed: float = 220.0
@export var sprint_multiplier: float = 1.6
@export var dodge_speed: float = 620.0
@export var dodge_time: float = 0.18
@export var dodge_cooldown: float = 0.6

var hp: float
var state: int = PState.IDLE
var weapon: Weapon

var _aim_dir: Vector2 = Vector2.RIGHT
var _dodge_left: float = 0.0
var _dodge_cd: float = 0.0
var _dodge_dir: Vector2 = Vector2.ZERO
var _noise_t: float = 0.0
const MUZZLE_DIST := 22.0

func _ready() -> void:
	add_to_group("player")
	hp = max_hp

	collision_layer = 2
	collision_mask = 1 | 4  # walls + enemies

	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	cs.shape = circle
	add_child(cs)

	var cam := Camera2D.new()
	add_child(cam)
	cam.make_current()

	var wd: WeaponData = RunManager.get_equipped_weapon()
	if wd:
		weapon = Weapon.new(wd)

	queue_redraw()

func _physics_process(delta: float) -> void:
	if state == PState.DEAD:
		return
	if weapon:
		weapon.update(delta)
	if _dodge_cd > 0.0:
		_dodge_cd -= delta

	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() > 1.0:
		_aim_dir = to_mouse.normalized()

	if state == PState.DODGE:
		_dodge_left -= delta
		velocity = _dodge_dir * dodge_speed
		move_and_slide()
		if _dodge_left <= 0.0:
			state = PState.IDLE
		queue_redraw()
		return

	var input_vec := Vector2.ZERO
	if Input.is_key_pressed(KEY_D): input_vec.x += 1.0
	if Input.is_key_pressed(KEY_A): input_vec.x -= 1.0
	if Input.is_key_pressed(KEY_S): input_vec.y += 1.0
	if Input.is_key_pressed(KEY_W): input_vec.y -= 1.0
	input_vec = input_vec.normalized()

	var moving := input_vec != Vector2.ZERO
	var sprinting := moving and Input.is_key_pressed(KEY_SHIFT)
	var speed := move_speed * (sprint_multiplier if sprinting else 1.0)
	velocity = input_vec * speed
	move_and_slide()

	if not moving:
		state = PState.IDLE
	elif sprinting:
		state = PState.SPRINT
	else:
		state = PState.MOVE

	if moving and Input.is_key_pressed(KEY_SPACE) and _dodge_cd <= 0.0:
		_start_dodge(input_vec)

	# Movement noise feeds the Tension Loop (throttled).
	_noise_t -= delta
	if _noise_t <= 0.0 and moving:
		_noise_t = 0.2
		EventBus.noise_emitted.emit(global_position, 300.0 if sprinting else 130.0, self)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_try_fire()
	if Input.is_key_pressed(KEY_R) and weapon:
		weapon.start_reload()

	queue_redraw()

func _start_dodge(dir: Vector2) -> void:
	state = PState.DODGE
	_dodge_dir = dir.normalized()
	_dodge_left = dodge_time
	_dodge_cd = dodge_cooldown

func _try_fire() -> void:
	if weapon == null or not weapon.can_fire():
		return
	weapon.consume_shot()
	var spread := deg_to_rad(weapon.data.spread_degrees)
	var dir := _aim_dir.rotated(randf_range(-spread, spread))
	var p := Projectile.new()
	p.setup(dir, weapon.data.projectile_speed, weapon.data.damage, weapon.data.projectile_color, true)
	get_tree().current_scene.add_child(p)
	p.global_position = global_position + _aim_dir * MUZZLE_DIST
	EventBus.noise_emitted.emit(global_position, weapon.data.noise_radius, self)

func take_damage(amount: float, source) -> void:
	if state == PState.DEAD:
		return
	hp -= amount
	EventBus.player_damaged.emit(amount, source)
	if hp <= 0.0:
		_die()

func _die() -> void:
	state = PState.DEAD
	velocity = Vector2.ZERO
	EventBus.player_died.emit()
	queue_redraw()

func _draw() -> void:
	var body_col := Color(0.25, 0.6, 1.0) if state != PState.DEAD else Color(0.35, 0.35, 0.35)
	draw_circle(Vector2.ZERO, 14.0, body_col)
	if state != PState.DEAD:
		draw_line(Vector2.ZERO, _aim_dir * 26.0, Color.WHITE, 3.0)
