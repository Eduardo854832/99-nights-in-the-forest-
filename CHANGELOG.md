# BREAKHUB - Registro de Atualizações (Changelog)

## Versão 0.1.1 (2025-09-01)
Data: 2025-09-01
Responsável: @Eduardo854832

### Resumo
Atualização focada em correções de erros, otimizações de desempenho e plena compatibilidade com dispositivos mobile. Também foi adicionado um botão flutuante para abertura/fechamento rápido do hub e criado um sistema de escalonamento automático da interface (UIScale) conforme o tamanho da tela.

### Principais Mudanças
1. Correção de Erros
   - Removido o uso de `collectgarbage("collect")` dentro da rotina de "manipulação de memória" que disparava o erro: `collectgarbage must be called with 'count'; use gcinfo() instead`.
   - Eliminadas rotinas agressivas (flood de eventos e criação/destruição rápida de Parts invisíveis) que poderiam gerar lag e warnings.
   - Adicionada função utilitária `safe()` (wrapper pcall) para capturar e reportar erros sem quebrar loops principais.
   - Comentado no código que o warning `Infinite yield possible on 'Workspace.CountdownTimer:WaitForChild("CountdownSign")'` não pertence ao BREAKHUB e como evitar problemas semelhantes usando timeout em `WaitForChild`.

2. Compatibilidade Mobile
   - Conversão de boa parte de tamanhos fixos (offset) para valores relativos (Scale) quando apropriado.
   - Adicionado `UIScale` dinâmico no seletor de idioma e no hub principal: escala calculada pelo menor lado do viewport (viewport adaptativo para telas pequenas).
   - Aumentadas áreas clicáveis, alturas e uso de `TextScaled` em botões e labels principais para melhor leitura em telas menores.
   - Sliders redesenhados para suportar input de toque (touch) além de mouse, sem depender exclusivamente de `GetMouseLocation()`.
   - Sistema de drag (arrastar janela) atualizado para não permitir que o hub saia completamente da tela (clamping após soltar).
   - Botão flutuante "BH" adicionado para abrir/fechar o hub facilmente em mobile sem ocupar muito espaço.

3. UI / UX
   - Layout das abas convertido para ScrollFrame (permite expansão futura sem estourar a altura em telas menores).
   - Ordem das abas simplificada inicialmente (Auto Farm, Combat, Settings) — outras podem ser reintroduzidas posteriormente.
   - Notificações de carregamento agora usam Tween para entrada/saída suave e desaparecem automaticamente.
   - Títulos das seções usam `GothamBold` com `TextScaled` para legibilidade.

4. Bypass / Segurança (Tornado para modo "leve")
   - Removido o "flood" de RemoteEvents/Functions e a geração massiva de Partes invisíveis.
   - Bypass agora realiza apenas pequenas variações aleatórias (WalkSpeed, JumpPower) em intervalos moderados para parecer comportamento humano, reduzindo risco de detecção e queda de FPS.
   - Rotina de variação de Lighting simplificada (incremento suave no `ClockTime`).
   - Detecção de scripts suspeitos passou a apenas reportar (warn) em LocalScripts, sem tentar desabilitar scripts server-side (evita warnings adicionais e falhas).

5. Estrutura e Organização
   - Separação clara das funções placeholder (executeKillAura, collectResources, etc.) no final do arquivo para implementação futura.
   - Criação de função utilitária `safe()` centraliza o padrão de pcall + warn.
   - Comentários adicionais marcados com `-- MOBILE COMPAT` e notas de instrução sobre warnings externos.

6. Performance
   - Redução de loops intensivos em spawn/while com sleeps aleatórios muito curtos.
   - Menos alocações temporárias (remoção de blocos de memória artificiais) diminuindo garbage e ruído.

7. Acessibilidade / Qualidade de Vida
   - Uso consistente de `TextScaled` em botões principais e títulos.
   - Melhor contraste de cores em botões ativos/inativos.
   - Feedback visual claro em toggles (cores sólidas azul x cinza).

### Arquitetura Atual (Visão Rápida)
- LanguageSelector GUI (com UIScale adaptativo)
- Hub principal (ScreenGui BREAKHUB_V01) com:
  - TopBar (drag + close)
  - TabsContainer (ScrollingFrame)
  - ContentContainer (UIListLayout dinâmico)
  - Botão flutuante (ScreenGui separado) para abertura rápida
- Sistemas lógicos (AutoFarm, KillAura, etc.) ainda com placeholders prontos para implementação posterior.

### Próximos Passos Sugeridos
- Implementar lógica real nas funções placeholder (ex.: pathfinding, coleta seletiva, priorização de recursos).
- Persistência de configurações (salvar toggles/valores em JSON local ou via setclipboard).
- Adicionar mais abas antigas (Quests, Building, Inventory, Stats) já adaptadas para a nova arquitetura mobile.
- Sistema de relatório de sessão (tempo, recursos/hora, kills/hora) exibido na aba Stats.
- Internacionalização adicional (Espanhol, Francês) usando mesmo dicionário de traduções.

### Avisos
- Este hub não resolve warnings de scripts terceiros; apenas mitiga o que era gerado internamente.
- Evite reintroduzir rotinas de spam de rede; isso pode aumentar chance de detecção.

---
Se precisar inserir outra versão ou detalhar commits individuais, basta solicitar.