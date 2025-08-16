# Atualizações

Histórico de mudanças do projeto (versões mais recentes primeiro).

---

## 0.9.1
Adicionado
- Comando `/uu diag` para diagnóstico rápido (FPS, Mem, Ping, Players, estados de features) em notificação + logger.
- Chave de tradução `LEGACY_FLY_NOTE` (pt/en) e chave `DIAG_MESSAGE`.
- Sistema de Fly modernizado: tenta `LinearVelocity` + `AlignOrientation`; fallback automático para `BodyVelocity` legado.
- Registry de conexões internas (Core.Bind/Unbind/UnbindAll) permitindo limpeza central (usado pelo Panic).
- Dirty flag no Logger (painel Debug só reconcatena texto quando há novos logs).
- Restauração de WalkSpeed base ao desativar Sprint; tracking de última velocidade aplicada.

Alterado
- Overlay e painel de stats agora compartilham o mesmo estado de métricas (ciclo único de coleta 1x/s).
- Sprint passa a usar valores em `Core._state` ao invés de reconsultar persistência a cada ciclo.
- Panic reforçado: desativa sprint, overlay, fly, noclip, hora custom e limpa conexões registradas.
- Tema reaplicado após troca de idioma para garantir coloração de novos elementos.
- Fly loop migrado para única conexão Heartbeat registrada no registry.
- Texto de versão atualizado para `0.9.1` (UI título e notificação inicial).

Corrigido
- Precedência lógica em `UI.applyLanguage` (TextButton sem parent podia ser processado). Adicionados parênteses.
- Evita writes redundantes em Humanoid (Sprint e Fly) — só aplica quando valor muda.

Removido
- Cálculo duplicado de FPS/Mem/Ping no overlay (agora reutiliza métricas centrais).

Interno
- `Themes._current` referencia tema ativo para acesso imediato em novos elementos.
- Mais usos de `pcall` para evitar interrupções (writes de propriedades e criação de constraints de voo).
- Comentários marcados com `-- [v0.9.1]` para rastreabilidade de mudanças.
- Estrutura preparada para futura modularização sem quebrar API existente.

---

## 0.9.0
Adicionado
- Lazy loading de painéis (constroem só ao primeiro expandir).
- Sistema de temas (dark/light) com persistência e comando `/uu theme`.
- Gerenciador de keybinds (menuToggle, flyToggle, panic, overlayToggle) reconfigurável via UI e `/uu keybind`.
- Perfis (1..3) salvando WalkSpeed, JumpPower, FOV, sensibilidade, shift‑lock, câmera suave, velocidades de voo, visibilidade do overlay. Comandos: `/uu profile save|load <n>`.
- Auto Sprint configurável (toggle, bônus, tempo de hold) + comando `/uu sprint`.
- Histórico de teleporte (últimos 5) separado das posições salvas.
- Logger de depuração com export (`/uu debug`).
- Painel de chaves de idioma faltantes.
- API pública expandida: `RegisterLazyPanel`, `RegisterCommand`, `RegisterKeybind`, `Log`, `PanicAll`.
- Novos comandos: `theme`, `profile`, `keybind`, `sprint`, `debug`.

Alterado
- Export força flush de persistência antes de copiar.
- Panic também desativa sprint, overlay, fly, noclip e hora custom.
- Sprint não interfere em fly (aplicação de velocidades ciente do estado).
- Clamping de FOV (30–130) ao carregar / alterar.
- Código reorganizado em blocos (temas, logger, perfis, keybinds) mantendo arquitetura Fase 1.

Corrigido
- Evita rebind acidental (ignora input com gameProcessed).
- Garante não duplicar construção de painel no lazy load (flag built).

Removido
- Necessidade de reconstruir toda a UI para trocar tema (recolor dinâmico).

Interno
- Registro central de elementos para tema (ThemeRegistry) e tradução (translatables).
- Observer único de métricas reutilizado (sprint, overlay, stats).
- Logger limitado a 150 linhas (FIFO).

---

## 0.8.0 (Refatoração Arquitetural – “Fase 1”)
Adicionado
- Scheduler único de métricas (FPS, Mem, Ping, Players).
- `Maid` para gerenciamento e limpeza de conexões/instâncias (reexecução segura).
- Comando `/uu panic`.
- Export / Import de configuração (clipboard) + `_configVersion`.
- API inicial: `RegisterCommand`, `AddMetricsObserver`, `GetState`.
- Cache / fallback de traduções com detecção de chaves faltantes.

Alterado
- Fly suavizado (AlignVelocity + Lerp).
- Overlay e painel de stats compartilham fonte (observer central).
- Persistência em lote (~0.5s) + `setIfChanged`.
- Atualização de posição reduzida (~8–10 Hz).
- Inicialização idempotente destruindo GUIs anteriores.
- Câmera (shift‑lock, smooth, sensibilidade) unificada no loop de métricas.

Corrigido
- Race ao recriar câmera (FOV reaplicado).
- Múltiplas conexões em reexecuções (limpas pelo Maid).

Removido
- Loops separados de overlay / stats / posição.

Interno
- Módulos lógicos (Persist, MetricsService, Fly, UI, Lang, Util) separados.
- Helpers de notificações seguras e acesso a humanoide centralizados.

---

## 0.6.2
Adicionado
- Mini handle (quadrado) recolhível/arrastável para reabrir menu oculto.
- Drag do menu principal (cabeçalho).
- Persistência de posições (menu, mini handle, overlay).
- Chaves de idioma para mini handle.

Alterado
- `Util.draggable` aceita callback onDrop (salvar posição).
- Ajustes em `UI.createRoot` para suportar handle e sincronizar posições.
- Incremento de versão.

Corrigido
- Reabertura via F4 sincroniza posição salva.
- Mini handle herda posição do menu ao ocultar.

---

## 0.6.1
Adicionado
- UI em painéis recolhíveis (Geral, Movimento, Câmera, Stats, Extras, Fly).
- Internacionalização PT/EN com persistência.
- Persistência JSON (idioma, sliders, toggles, overlay, posições, hora custom).
- Overlay de performance (FPS, Mem, Ping, Players) com intervalo configurável e drag.
- Sliders: WalkSpeed, JumpPower, FOV, Sensibilidade, Hora (ClockTime).
- Reaplicação automática de WalkSpeed/JumpPower pós respawn (toggle).
- Shift-Lock simulado, câmera suave, multiplicador de sensibilidade.
- Painel de Stats.
- Sistema de salvar até 5 posições (TP, remover com botão direito, copiar se possível).
- Noclip com restauração de colisões.
- Ajuste local de Lighting.ClockTime (toggle aplicar/reverter).
- Fly GUI legado encapsulado.
- Notificações centralizadas; tecla F4 para mostrar/ocultar UI.

Alterado
- Arquitetura modular de plugins (`Core.register/init`).
- Layout / estilo unificados.
- Reaplicação de FOV ao recriar câmera.

Corrigido
- Acesso seguro a Humanoid/HumanoidRootPart.
- JumpPower com `UseJumpPower` desativado.
- Restauração de colisões após Noclip.

Removido
- Cabeçalho de versão antigo (mantido apenas `local VERSION`).

---

## 0.6.0
Adicionado
- Sistema de idiomas.
- Base de plugins.
- Persistência inicial.

Alterado
- UI reorganizada em múltiplos painéis.
- Textos convertidos em chaves.

Corrigido
- Recalculo do scroll dinâmico.

---

## 0.5.0
Adicionado
- Overlay de performance inicial.
- Sliders básicos WalkSpeed / JumpPower.
- Lista de posições em memória.
- Noclip inicial.

Alterado
- Consolidação em container rolável.

Corrigido
- Reaplicação de movimento pós respawn (inic.).

---

## 0.4.0
Adicionado
- Fly GUI legado.
- Botões mobile (Respawn, Reset FOV).
- Reset rápido de FOV.

Alterado
- Detecção de dispositivo aprimorada.

Corrigido
- Conflitos animação vs fly.

---

## 0.3.0
Adicionado
- FPS simples.
- Contagem de jogadores.
- Slider FOV (não persistente).
- Shift-Lock.

Alterado
- Módulo Util; uso de RenderStepped.

Corrigido
- Obtenção de Humanoid em carregamentos lentos.

---

## 0.2.0
Adicionado
- Wrapper de notificações.
- Função draggable.
- Botões básicos.

Alterado
- GUI cabeçalho + corpo rolável.

Corrigido
- Acesso seguro a leaderstats.

---

## 0.1.0
Adicionado
- Versão inicial.
- Ajuste direto WalkSpeed / JumpPower.
- Notificações simples sem idioma.