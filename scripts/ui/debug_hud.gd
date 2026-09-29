extends CanvasLayer

@export var player: Player
@export var cameras: CameraSystem
@export var label: Label
@export var prompt_label: Label

func _process(_delta: float) -> void:
	var target := player.interaction.current
	var target_name := String(target.name) if is_instance_valid(target) else "nenhum"
	var build_name: String = String(player.build_resolver.active_build.display_name) if (player.build_resolver and player.build_resolver.active_build) else "NONE"
	var move_mult := player.modifiers.get_mult(3) if player.modifiers else 1.0
	var melee_mult := player.modifiers.get_mult(4) if player.modifiers else 1.0
	var ranged_mult := player.modifiers.get_mult(5) if player.modifiers else 1.0
	label.text = "DEBUG / PLAYER FOUNDATION\nCamera: %s\nVida: %.0f / %.0f | Stamina: %.0f / %.0f\nEstado: %s | Velocidade: %.2f m/s\nBuild: %s | Move: %.2fx | Melee: %.2fx | Ranged: %.2fx\nAlvo: %s | Obstrucoes: %d\n\nWASD mover | Shift correr | C agachar\nE interagir | F1 terceira pessoa | F2 isometrica\nMouse orbitar | Esc liberar/capturar | F3 reiniciar\nTAB segurar inventário | I fixar | LMB ataque | RMB mira | R recarga" % [cameras.mode, player.status.health, player.status.effective_max_health(), player.status.stamina, player.status.effective_max_stamina(), player.movement.state, Vector2(player.velocity.x, player.velocity.z).length(), build_name, move_mult, melee_mult, ranged_mult, target_name, cameras.occlusion.obstruction_count]
	prompt_label.text = "MORTO — F3 para reiniciar" if player.status.dead else ("[E] " + target.get_interaction_text(player) if is_instance_valid(target) else "")
