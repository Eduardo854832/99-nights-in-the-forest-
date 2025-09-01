# BREAKHUB Changelog

Todas as mudanças notáveis deste projeto serão documentadas aqui.
O formato segue (simplificado) o padrão Keep a Changelog, com seções: Added (Adicionado), Fixed (Corrigido), Removed (Removido).

Versão atual do hub: BREAKHUB-V0.2

## [0.2.0] - 2025-09-01
Tag: BREAKHUB-V0.2

### Added (Adicionado)
- Escalonamento dinâmico (UIScale) baseado no menor lado do viewport para Language Selector e Hub principal (melhor leitura em telas pequenas).
- Botão flutuante "BH" para abrir/fechar o hub rapidamente em dispositivos mobile sem ocupar espaço permanente.
- Sistema de drag com clamp (impede que a janela saia totalmente da tela ao soltar).
- Sliders compatíveis com toque (touch) além de mouse; cálculo de valor sem depender apenas de `GetMouseLocation()`.
- ScrollFrame para lista de abas (permite expansão futura sem quebrar layout em telas pequenas).
- Wrapper utilitário `safe()` (pcall padronizado) para capturar erros e evitar que loops críticos sejam interrompidos.
- Notificações animadas com Tween (entrada e saída suaves) ao carregar o hub.
- Títulos e botões principais usando `TextScaled` para responsividade tipográfica.
- Comentários explicativos sobre o warning externo de `Infinite yield possible` e instrução de uso de timeout em `WaitForChild`.

### Fixed (Corrigido)
- Erro: `collectgarbage must be called with 'count'; use gcinfo() instead` gerado pela rotina antiga de manipulação de memória (removida / reescrita).
- Potenciais quedas de desempenho causadas por loops agressivos (flood de eventos, criação e destruição massiva de Parts invisíveis, alocações de blocos de memória artificiais).
- Responsividade de interface em dispositivos mobile (tamanhos fixos substituídos parcialmente por escalas e TextScaled, melhorando leitura e clique).
- Possível spam de warnings ao tentar desabilitar scripts que não são LocalScripts (abordagem agora apenas reporta via `warn`).
- Slider anterior que dependia somente de movimento de mouse (inoperante em toque) agora funcional em touch.

### Removed (Removido)
- Rotina de "manipulação de memória avançada" que gerava chamadas repetidas a `collectgarbage` e uso artificial de GUIDs.
- Flood de RemoteEvents/RemoteFunctions/BindableEvents que aumentava risco de detecção e lag.
- Criação periódica de grupos de Parts invisíveis para ruído (desnecessário e custoso em performance).
- Tentativa direta de desabilitar scripts de suposto anti-cheat (substituído por simples detecção e aviso).
- Variações pesadas e muito frequentes de propriedades no ambiente (ex.: latitude aleatória e grande variação de ClockTime).

## [0.1.1] - 2025-09-01 (Consolidada em 0.2.0)
Versão intermediária utilizada como base de reestruturação. As mudanças introduzidas foram reorganizadas e oficializadas na versão 0.2.0.

### Notas Históricas
- Introdução inicial dos ajustes mobile e remoções de rotinas agressivas.
- Reestruturação do layout da GUI e introdução do botão flutuante (conceito).

---
Próximos Passos Sugeridos (não implementados ainda)
- Persistência de configurações (salvar / carregar toggles e sliders em JSON local).
- Reintrodução e adaptação das demais abas (Quests, Building, Inventory, Stats, Navigation, etc.).
- Sistema de estatísticas em tempo real (Recursos/hora, Kills/hora, Árvores/hora) na aba Stats.
- Suporte adicional de idiomas (Espanhol, Inglês completo já incluído; potencial para Francês, etc.).
- Módulo separado (ModuleScript) para lógica reutilizável (AutoFarm / KillAura / Utilidades).

---
Observação: O warning `Infinite yield possible` mostrado no console provém de outro script do jogo (ex.: `UpdateEffectsClient`) e não está ligado ao BREAKHUB. Para evitar warnings semelhantes internamente, utilizar `:WaitForChild("Nome", 5)` com timeout e fallback.