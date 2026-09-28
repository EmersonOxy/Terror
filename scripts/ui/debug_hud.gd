extends CanvasLayer

@export var player: Player
@export var cameras: CameraSystem
@export var label: Label
@export var prompt_label: Label

func _process(_delta: float) -> void:
	var target := player.interaction.current
	var target_name := String(target.name) if is_instance_valid(target) else "nenhum"
	label.text = "DEBUG / PLAYER FOUNDATION\nCamera: %s\nVida: %.0f / %.0f | Stamina: %.0f / %.0f\nEstado: %s | Velocidade: %.2f m/s\nAlvo: %s | Obstrucoes: %d\n\nWASD mover | Shift correr | C agachar\nE interagir | F1 terceira pessoa | F2 isometrica\nMouse orbitar | Esc liberar/capturar | R reiniciar | I inventário" % [cameras.mode, player.status.health, player.config.max_health, player.status.stamina, player.config.max_stamina, player.movement.state, Vector2(player.velocity.x, player.velocity.z).length(), target_name, cameras.occlusion.obstruction_count]
	prompt_label.text = "MORTO — R para reiniciar" if player.status.dead else ("[E] " + target.get_interaction_text(player) if is_instance_valid(target) else "")
