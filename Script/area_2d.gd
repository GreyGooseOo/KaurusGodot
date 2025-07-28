extends Area2D

@export var speed = 400
var screen_size

func _ready() -> void:
	screen_size = get_viewport_rect().size

func _process(delta: float) -> void:
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("Move_rigth"):
		velocity.x += 1
	if Input.is_action_pressed("Move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("Move_down"):
		velocity.y += 1
	if Input.is_action_pressed("Move_up"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
	if velocity.x > 0:
		$AnimatedSprite2D.animation = "Right"
	elif velocity.x < 0:
		$AnimatedSprite2D.animation = "Left"
	elif velocity.y > 0:
		$AnimatedSprite2D.animation = "Down"
	elif velocity.y < 0:
		$AnimatedSprite2D.animation = "Up"
	
func start(pos):
	position = pos
	show()
