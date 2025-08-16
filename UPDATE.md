# Atualizações (0.1.0 → 0.6.1)

Resumo organizado das mudanças entre as versões.

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
