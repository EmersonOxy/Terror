# Estado do projeto

- **Milestone Atual:** Organização da Sandbox + Ajustes de Combate + NPC Base + Comércio + Loot/Drops. (CONCLUÍDO)
- **Progressão e Sinergias (Builds):** `ProgressionComponent` cuida de XP/Level; `BuildResolver` coordena sinergias (equipamentos LIGHT/MEDIUM/HEAVY). Modificadores tipados combinam bônus dinamicamente.
- **Comércio e Economia:** `WalletComponent` no Player armazena moeda. Itens com `base_value` permitem trocas. `ShopComponent` intermedeia a compra/venda; `ShopUI` desenha a tela de transação.
- **NPC Base:** Classe `NPC` possibilita a interação. Dispara sinal de `shop_requested` para abrir a interface do mercador.
- **Loot e Drops:** `EnemyDefinition` ganhou as bandeiras `grant_rewards` e suporte a `loot_table`. Derrotar inimigos instancia `ItemPickup` através do `LootDropper`. Inimigos da área de testes de combate (dummies) naturalmente não dropam recursos/loot.
- **Ajustes de Combate / HUD:** `CombatHUD` conta com retícula dinâmica e *hit markers* ao confirmar impacto (4 marcas ao redor da retícula, 0.22s fade). Cursor do SO é bloqueado apropriadamente na mira ranged isométrica usando a hierarquia/mutex de UI.
- **Organização Sandbox:** O `TestWorld` foi estendido. `ItemTestSector` e `BuildTestSector` movidos para espaços próprios sem bloqueios visuais indesejados. Testes end-to-end atualizados para respeitar a nova topologia física (distância de interação com as novas coordenadas exatas globais).

- **Próximos passos:** Iniciar o planejamento e construção da primeira área REAL do jogo.
