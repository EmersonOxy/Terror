# Estado do projeto

- **Milestone:** XP, Level e Progressão de Personagem. Milestones anteriores preservados.
- **Progressão (XP/Level):** ProgressionComponent mantém level (máximo 20), xp atual, e pontos de progressão. Curva configurável (ProgressionConfig) define XP necessário (base_xp * growth_factor). Excesso de XP transitado corretamente para o próximo nível. Sem dependência de inventário ou inimigos.
- **Upgrades:** Três caminhos baseados em recursos (UpgradeDefinition): Vitalidade (+5 Max HP e HP atual), Condicionamento (+5 Max Stamina e atual), e Mochila (+1 slot). Pontos ganhos por nível são gastos nestes upgrades. Efeitos aplicados pelo composition root (ProgressionEffects) diretamente no StatusComponent e InventoryComponent. O inventário se adapta dinamicamente ao novo limite.
- **Recompensas (Fontes de XP):** Inimigos concedem XP ao morrer (EnemyDefinition.xp_reward) e objetivos de teste podem conceder XP (ProgressionTestObjective). Recompensas únicas por instância, mediadas pelo ProgressionReward para não acoplar as origens ao ProgressionComponent.
- **UI de Progressão:** P abre painel (ProgressionUI) bloqueando jogo (como inventário). Mostra Nível, XP atual/necessário (barra) e permite gastar pontos. Fechar inventário e progressão são mutuamente exclusivos. Feedback sutil (ProgressionHUD) mostra XP ganho e aviso de nível sem pausar o jogo.
- **Testes:** Validação confirmada do sistema de XP, limites, transição de nível, compra de upgrades, aumento real de status e capacidade da mochila, UI mutex e UI feedback. F4 adiciona 50 XP por debug.
- **Próximo milestone:** Sistema de builds/classes baseado nos equipamentos.
