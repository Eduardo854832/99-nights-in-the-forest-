# Atualizações (0.1.0 → 0.9.0)

Resumo organizado das mudanças entre as versões.

---

## 0.9.0
Adicionado
- Lazy loading de painéis (carregam só ao expandir a primeira vez).
- Sistema de temas (dark / light) com persistência e comando `/uu theme`.
- Gerenciador de keybinds (menuToggle, flyToggle, panic, overlayToggle) – reconfigurável via UI e `/uu keybind`.
- Perfis (1..3) salvando WalkSpeed, JumpPower, FOV, sensibilidade, shift‑lock, câmera suave, velocidades de voo, overlay (visibilidade) – comandos `/uu profile save|load <n>`.
- Auto Sprint configurável (toggle + bônus + tempo de hold) e comando `/uu sprint`.
- Histórico de teleporte (últimos 5 TPs) separado das posições salvas.
- Logger de depuração com export ( `/uu debug` ).
- Painel de chaves de idioma faltantes (se existirem).
- API pública expandida: `RegisterLazyPanel`, `RegisterCommand`, `RegisterKeybind`, `Log`, `PanicAll`.
- Comandos novos: `theme`, `profile`, `keybind`, `sprint`, `debug` (além dos anteriores).

Alterado
- Export agora força flush de persistência antes de copiar.
- Panic também desativa sprint, overlay, fly, noclip e hora custom.
- Sprint não interfere em modo fly; velocidades aplicadas com consciência de estado.
- Clamping de FOV (30–130) em load e alteração.
- Organização de código em blocos (temas, logger, perfis, keybinds) mantendo arquitetura da Fase 1.

Corrigido
- Evita rebind acidental durante captura de tecla (ignora input gameProcessed).
- Garantia de não duplicar construção de painel (flag built) no lazy load.

Removido
- Necessidade de reconstruir toda a UI para trocar tema (agora via recolor dinâmico).

Interno
- Registro central de elementos para tema (ThemeRegistry) e tradução (translatables).
- Reutilização de observer único de métricas para sprint, overlay e painel de stats.
- Logger limita a 150 linhas (FIFO) para evitar crescimento infinito.

---

## 0.8.0
(Refatoração Arquitetural – "Fase 1")

Adicionado
- Scheduler único de métricas (FPS, Mem, Ping, Players) eliminando loops duplicados.
- `Maid` para gerenciamento e limpeza de conexões / instâncias (suporte a reexecução segura).
- Comando `/uu panic` (desativa rapidamente recursos principais).
- Export / Import de configuração (clipboard) + versão de schema `_configVersion`.
- API pública inicial: `RegisterCommand`, `AddMetricsObserver`, `GetState`.
- Cache e fallback robusto de traduções com detecção de chaves faltantes.

Alterado
- Fly suavizado: AlignVelocity + Lerp de velocidade; transição mais estável.
- Overlay e painel de stats consomem a mesma fonte de dados (observer central).
- Persistência com gravação em lote (flush ~0.5s) e `setIfChanged` para evitar writes redundantes.
- Atualização de posição do jogador reduzida (~8–10 Hz) em vez de a cada frame.
- Inicialização idempotente destruindo GUIs anteriores (evita instâncias duplicadas).
- Câmera (shift‑lock, smooth, sensibilidade) unificada no mesmo loop de métricas.

Corrigido
- Condições de race ao recriar câmera (FOV reaplicado com segurança).
- Possíveis múltiplas conexões ao reexecutar o script (limpas pelo Maid).

Removido
- Loops separados de atualização para overlay / stats / posição.

Interno
- Estrutura de módulos lógicos (Persist, MetricsService, Fly, UI, Lang, Util) separada conceitualmente.
- Funções auxiliares de safe notify e acesso a humanoide centralizados.

---

## 0.6.2
Adicionado
- Quadrado (mini handle) recolhível e arrastável para reabrir o menu quando oculto.
- Drag do menu principal (arrastar pelo cabeçalho).
- Persistência da posição do menu e do mini handle (salva entre execuções).
- Drag do overlay agora também persiste posição.
- Chaves de idioma para o mini handle (ícone/tooltip).

Alterado
- Sistema de `Util.draggable` agora aceita callback de soltura (onDrop) para salvar posição.
- Reorganização leve de `UI.createRoot` para suportar novo handle e sincronizar posições.
- Versão incrementada para 0.6.2.

Corrigido
- Reabertura via F4 agora sincroniza com posição salva.
- Mini handle assume a mesma posição do menu ao ocultar.

---

## 0.6.1
Adicionado
- UI em painéis recolhíveis (Geral, Movimento, Câmera, Stats, Extras, Fly).
- Internacionalização PT/EN com seleção inicial e persistência.
- Persistência em JSON para idioma, sliders, toggles, overlay, posições e hora custom.
- Overlay de performance (FPS, Mem, Ping, Players) com intervalo configurável e posição arrastável.
- Sliders: WalkSpeed, JumpPower, FOV, Sensibilidade de câmera, Hora (ClockTime).
- Reaplicação automática de WalkSpeed/JumpPower após respawn (toggle).
- Shift-Lock simulado (PC), câmera suave, multiplicador de sensibilidade.
- Painel de Stats (FPS/Mem/Ping/Players).
- Sistema de salvar até 5 posições (TP, remover com botão direito, copiar se possível).
- Noclip com restauração de colisões originais.
- Ajuste local de Lighting.ClockTime (toggle aplicar/reverter).
- Fly GUI legado encapsulado em painel.
- Notificações centralizadas e tecla F4 para mostrar/ocultar UI.

Alterado
- Arquitetura modular de plugins (Core.register/init).
- Layout/estilo unificados (cores, cantos, fontes).
- Reaplicação de FOV ao recriar câmera.

Corrigido
- Acesso seguro a Humanoid/HumanoidRootPart.
- JumpPower quando UseJumpPower desativado.
- Restauração de colisões após Noclip.

Removido
- Cabeçalho de versão antigo (mantido apenas `local VERSION`).

---

## 0.6.0
Adicionado: sistema de idiomas, base de plugins, persistência inicial.
Alterado: UI reorganizada em múltiplos painéis; textos convertidos em chaves.
Corrigido: recalculo do scroll dinâmico.

---

## 0.5.0
Adicionado: overlay de performance inicial; sliders básicos WalkSpeed/JumpPower; lista de posições em memória; Noclip inicial.
Alterado: consolidação em container rolável.
Corrigido: reaplicação de movimento pós-respawn (inic.).

---

## 0.4.0
Adicionado: Fly GUI legado; botões mobile (Respawn, Reset FOV); reset rápido FOV.
Alterado: detecção de dispositivo aprimorada.
Corrigido: conflitos animação vs fly.

---

## 0.3.0
Adicionado: FPS simples, contagem de jogadores, slider FOV (não persist.), Shift-Lock.
Alterado: módulo Util; uso de RenderStepped.
Corrigido: obtenção de Humanoid em carregamentos lentos.

---

## 0.2.0
Adicionado: notificações wrapper; função draggable; botões básicos.
Alterado: GUI cabeçalho + corpo rolável.
Corrigido: acesso seguro a leaderstats.

---

## 0.1.0
Adicionado: versão inicial, ajuste direto WalkSpeed/JumpPower, notificações simples sem idioma.
