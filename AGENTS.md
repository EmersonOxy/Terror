# Terror — orientações para agentes

Projeto NOVO Godot 4.7.2: survival horror 3D single-player com exploração e RPG futuro. Milestone atual: fundação do Player, somente primitivas. Leia docs/PROJECT_STATE.md antes de trabalhar.

- Gameplay independente de modelos e câmeras. Player recebe Basis de movimento; Visual implementa apenas present(). A ausência do Visual é válida.
- Player coordena componentes; Movement controla física/postura; Status é a única fonte de vida/stamina; Interaction seleciona o contrato Interactable. Não acessar componentes vizinhos internamente.
- TestWorld conecta Player e CameraSystem por referências exportadas. Sem autoload, buscas globais por frame, índices de armas ou caminhos distantes embutidos em scripts.
- Ajustes ficam em resources/player/default.tres e resources/camera/default.tres (campos/defaults nas respectivas classes Config). Input Map em project.godot. Frente local: -Z. Camadas: 1 mundo, 2 player, 3 interagíveis.
- scenes/ contém cenas editáveis; scripts/ responsabilidades; resources/ configurações; tests/ testes de física e render; tools/check.ps1 valida. O mapa é uma cena salva, sem gerador que sobrescreva edição manual.
- Degraus usam sondagem subir/avançar/descer da cápsula, somente em chão e até step_height. Stamina esgotada requer recuperação mínima para evitar alternância corrida/caminhada a cada frame.
- Não implementar armas, inimigos, inventário, animações finais ou sistemas RPG neste milestone. Não copiar protótipos externos. Não adicionar abstrações antecipadas.
- Mantenha arquivos pequenos e documentação curta; atualize PROJECT_STATE após mudanças relevantes. Testes não podem depender de screenshots. Nunca versionar .godot/ ou artifacts/. Não fazer push sem solicitação.

Comandos (na raiz; Godot via GODOT_BIN, PATH ou instalação local detectada):
- ./tools/check.ps1: importação + suítes headless; falha também em erros de parser no log.
- ./tools/check.ps1 -Visual: também testa mouse com janela e salva duas imagens em artifacts/.
- ./tools/check.ps1 -Godot 'caminho/do/godot_console.exe': instalação alternativa.
- Abrir project.godot no Godot e F6 na cena de teste ou F5 para executar.
