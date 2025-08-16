# Atualizações (0.1.0 → 0.8.0)

Resumo organizado das mudanças entre as versões.

---

## 0.8.0 - Phase 1 High-Impact Enhancements
Adicionado
- **Idempotent initialization**: Script agora limpa execuções anteriores automaticamente (`UniversalUtility_UI`, `UU_LangSelect`, `UU_Overlay`).
- **Maid (resource manager)**: Sistema automático de limpeza de conexões/instâncias para facilitar hot-reload e modularidade futura.
- **Throttled persistence writes**: Gravações em disco agrupadas a cada 0.5s, apenas para chaves alteradas (`Persist.setIfChanged`).
- **Central Metrics scheduler**: Loop único RenderStepped alimentando overlay + painel stats, removendo loops duplicados de FPS/mem/ping.
- **Translation system caching**: Cache de traduções + fallback + log de chaves ausentes em `Lang.missing`.
- **Fly controller smoothing**: Lerp de velocidade + uso opcional de `AlignVelocity` se disponível, com fallback gracioso.
- **Consolidated camera update loop**: Shiftlock, smooth, sensitivity integrados ao heartbeat central.
- **Noclip optimization**: Rastreamento incremental de descendentes do character ao invés de scan completo por frame.
- **Command spam debounce**: Debounce de 0.25s para comandos `/uu` + sanitização de input (máx 32 chars por token).
- **Export/Import config**: Botões e comandos para cópia/cola de configuração via clipboard.
- **Panic reset command**: `/uu panic` desabilita fly, noclip, tempo custom, overlay e reseta câmera rapidamente.
- **Public API `_G.UniversalUtility`**: Hooks expostos para plugins futuros (`RegisterCommand`, `RegisterPanelLazy`, `OnLanguageChanged`, `GetState`, `AddMetricsObserver`).
- **Defensive checks & safe wrappers**: Operações de humanoid e câmera protegidas por pcall.
- **Reduced heartbeat frequency**: Updates de baixa prioridade (ex: label de posição) reduzidos para ~8 Hz.

Alterado
- **Services lazy loading**: Sistema de serviços com lazy loading via metatable.
- **Unified overlay + stats text source**: Mudança de intervalo de overlay atualiza variável ao invés de reconectar loops.
- **Configuration versioning**: JSON salvo inclui `_configVersion` para compatibilidade futura.
- **Language system improvements**: Suporte para Español, cache melhorado, fallback para EN.
- **UI architecture**: Sistema modular de painéis com tradução dinâmica.

Corrigido
- **Memory optimization**: Redução significativa de loops redundantes.
- **Resource management**: Todas as conexões/instâncias registradas no GlobalMaid.
- **Persistence reliability**: Sistema de flush throttled evita escritas excessivas.

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
