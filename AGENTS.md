# Terror — orientações para agentes

Projeto NOVO Godot 4.7.2: survival horror 3D single-player com exploração e RPG futuro. Milestone atual: inimigo-base e IA; somente primitivas. Leia docs/PROJECT_STATE.md antes de trabalhar.

- Gameplay independente de modelos e câmeras. Player recebe Basis de movimento; Visual implementa apenas present(). A ausência do Visual é válida.
- Player coordena componentes; Movement controla física/postura; Status é a única fonte de vida/stamina; Interaction seleciona o contrato Interactable. Não acessar componentes vizinhos internamente.
- TestWorld conecta Player e CameraSystem por referências exportadas. Sem autoload, buscas globais por frame, índices de armas ou caminhos distantes embutidos em scripts.
- Ajustes ficam em resources/player/default.tres e resources/camera/default.tres (campos/defaults nas respectivas classes Config). Input Map em project.godot. Frente local: -Z. Camadas: 1 mundo, 2 player, 3 interagíveis.
- scenes/ contém cenas editáveis; scripts/ responsabilidades; resources/ configurações; tests/ testes de física e render; tools/check.ps1 valida. O mapa é uma cena salva, sem gerador que sobrescreva edição manual.
- Degraus usam sondagem subir/avançar/descer da cápsula, somente em chão e até step_height. Stamina esgotada requer recuperação mínima para evitar alternância corrida/caminhada a cada frame.
- Não implementar narrativa, animações finais, bônus de equipamentos ou sistemas RPG neste milestone. Inimigos usam primitivas e IA básica. Não copiar protótipos externos. Não adicionar abstrações antecipadas.
- Mantenha arquivos pequenos e documentação curta; atualize PROJECT_STATE após mudanças relevantes. Testes não podem depender de screenshots. Nunca versionar .godot/ ou artifacts/. Não fazer push sem solicitação.

Comandos (na raiz; Godot via GODOT_BIN, PATH ou instalação local detectada):
- ./tools/check.ps1: importação + suítes headless; falha também em erros de parser no log.
- ./tools/check.ps1 -Visual: também testa mouse com janela e salva duas imagens em artifacts/.
- ./tools/check.ps1 -Godot 'caminho/do/godot_console.exe': instalação alternativa.
- Abrir project.godot no Godot e F6 na cena de teste ou F5 para executar.

- Visibilidade isométrica: IsometricOcclusion detecta apenas colliders World no grupo camera_occluder; meshes descendentes usam cópias privadas BaseMaterial3D via ObstacleFade. Excluir pisos. Shaders personalizados exigirão adaptação explícita. VisualHighlight pertence ao CharacterVisual, sem dependência da cápsula. Configuração em CameraConfig, restauração obrigatória na saída.

- Itens: definitions compartilhadas em resources/items; ItemInstance é estado exclusivo de cada stack. InventoryComponent não conhece UI, cura ou equipamentos. ItemActions coordena consumo/transferências/drop; EquipmentComponent só valida/armazena HEAD/BODY/WEAPON. UI deriva slots de capacity().
- add_item(instance) consome a quantidade recebida e deixa a sobra na instância do chamador; não passar um item ainda pertencente à mochila. get_slot/get_equipped são referências para leitura: alterar via APIs. Equipáveis sempre max_stack=1. Especializações futuras devem preservar estado em copy_with_quantity e restringir can_stack_with quando necessário.
- ItemPickup é único para todos os tipos e duplica o template de cena; drop transfere instância e usa global_position validada antes de remover da mochila. UI sinaliza controls_locked no Player/câmera, sem pausar física/status. CombatComponent respeita esse bloqueio e morte.

- Combate: WeaponDefinition cria WeaponInstance; carregador pertence à instância, reserva ao Inventory. CombatComponent recebe AimSample e não conhece câmeras ou classes de alvo. CameraAimProvider adapta a câmera no composition root. Dano usa take_damage(DamageData), com origem física no ator para respeitar cobertura. Novos alvos implementam o contrato sem alterar armas.

- Enemy: dados em EnemyDefinition; componentes separados para percepção/motor/ataque/visual. HealthComponent compartilha vida de Enemy e DamageReceiver; Player mantém Status. IA recebe candidato explicitamente e nunca conhece câmera/textos. Navmesh salva exige novo bake ao editar geometria estática (tools/bake_navigation.gd); colisão e step_height precisam ser compatíveis. player_detected é visão do inimigo, nunca prova de que o Player o viu.
