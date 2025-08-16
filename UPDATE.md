# Universal Utility – Plano de Versões Futuras (Rascunho)

Este arquivo é um PLANO (nada aqui após 0.6.1 foi implementado ainda).
Versões já lançadas: 0.4.x → 0.5.0 → 0.6.1

Legenda de categorias:
- Novo: funcionalidade inédita
- Melhorado: mudança em algo já existente
- Corrigido: bug resolvido
- Técnico: refactors / estrutura interna
- Opcional: ideia que pode virar toggle ou recurso configurável

---

## 0.6.2 – Polimento Pós-Refactor
Resumo: Ajustes visuais e refinamentos da nova UI.
- Novo: Tooltips simples em toggles (exibe chave de persistência)
- Novo: Opção "Usar só F4" (esconde botão Hide)
- Melhorado: Suavização de câmera adapta intensidade conforme FPS
- Corrigido: Delay ao reabrir painel após ocultar
- Corrigido: Textos de sliders não atualizavam após troca de idioma
- Técnico: Otimização do recálculo de CanvasSize

## 0.6.3 – Acessibilidade & UX
Resumo: Tornar a UI mais inclusiva.
- Novo: Modo Alto Contraste
- Novo: Slider de tamanho de fonte global (80%–130%)
- Novo: Detecção automática de idioma (pt/en) com fallback manual
- Melhorado: Persist grava JSON ordenado (leitura humana)
- Corrigido: CanvasSize falhava após remoção rápida de posições

## 0.7.0 – Sistema de Plugins Externos
Resumo: Base para extensões carregadas pelo usuário.
- Novo: Painel "Plugins" (Carregar URL / Ativar / Desativar / Remover)
- Novo: Whitelist de URLs antes de executar
- Novo: API mínima (Core.registerAction)
- Novo: (Opcional) Hash de integridade
- Técnico: Core.register retorna handle para unregister
- Corrigido: Fugas de conexões em reexecuções

## 0.7.1 – Hotfix Plugins
Resumo: Estabilização inicial.
- Corrigido: Erro ao carregar segundo plugin se primeiro falha
- Corrigido: Tradução não aplicada a botões dinâmicos
- Novo: Safe Mode (desativa plugins externos se sessão anterior travou)

## 0.7.2 – Traduções Expandida
Resumo: Expandir público.
- Novo: Idiomas es (Espanhol) e fr (Francês)
- Novo: Comando de chat :uuLang <código>
- Melhorado: Cache de strings na função L
- Corrigido: Sobreposição de texto no Alto Contraste em telas pequenas

## 0.8.0 – Núcleo Modular
Resumo: Reorganização interna.
- Novo: Módulos separados (Movement, Camera, Overlay, Extras, Fly, Plugin, UI)
- Novo: Lazy load de módulos pouco usados
- Novo: EventBus interno (on/emit/off)
- Melhorado: Persist hierárquico (movement.walkspeed etc.)
- Corrigido: Segunda instância encerra a anterior limpo
- Técnico: Menos loops redundantes em RenderStepped

## 0.8.1 – Sandbox de Plugins
Resumo: Segurança.
- Novo: Ambiente limitado com whitelist de libs
- Novo: Flag allow_unsafe_plugins
- Novo: Log circular (últimos 100 eventos) no painel Plugins
- Corrigido: Plugins sobrescrevendo globais críticos

## 0.9.0 – API Pública & Automação
Resumo: Poder para usuários avançados.
- Novo: Objeto global opcional _UU (setWalkSpeed, getPositions, on/off)
- Novo: Macros (gravar + reproduzir ações da UI)
- Novo: Export/Import de config (Base64 compactado)
- Melhorado: Posições agora têm nomes personalizados
- Corrigido: Reaplicar stats espera Humanoid vivo

## 0.9.1 – Macros Aprimoradas
Resumo: Estabilidade.
- Corrigido: Sliders fracionários perdiam precisão em macros
- Corrigido: Cancelar macro não removia indicador
- Novo: Delay configurável entre passos (0.05–2.0s)

## 1.0.0 – Lançamento Estável
Resumo: Confiabilidade e acabamento.
- Novo: Tela de changelog ao atualizar
- Novo: Verificação opcional de update remoto
- Novo: Perfis (múltiplas configurações salvas)
- Novo: Auto-teste interno de componentes-chave
- Melhorado: Comentários/documentação padronizados
- Técnico: Redução de garbage (reuso de tabelas temporárias)
- Corrigido: Layout em monitores ultra wide
- Corrigido: Vazamento de conexões ao spam de overlay

## 1.1.0 – Tema & Produtividade
Resumo: Personalização e busca rápida.
- Novo: Editor de Tema (Dark / Light / Neon / Custom)
- Novo: Reordenar / Fixar (pin) painéis
- Novo: Busca instantânea (filtra controles ao digitar)
- Melhorado: Accordion com modo "exclusivo" (abrir um fecha outros)
- Corrigido: Travamento visual ao colapsar painéis grandes rapidamente

---
## Roadmap (Ideias Extras – Não agendadas)
- Sincronizar perfis via HTTP (se executor permitir)
- Webhooks (log remoto opt-in)
- Métricas anônimas opt-in (uso de features)
- Dependências entre plugins (plugin B exige A)
- Painel "Diagnóstico" (conexões, memória, uptime)
- Editor interno de plugins (syntax highlight simples)

---
## Prioridades Sugeridas
1. 0.6.2 / 0.6.3 – Polimento & Acessibilidade
2. 0.7.x – Plugins + Hotfixes
3. 0.7.2 – Traduções
4. 0.8.x – Modularização + Sandbox
5. 0.9.x – API & Macros
6. 1.0.0 – Estável
7. 1.1.0 – Tema & Produtividade

---
Este arquivo poderá ser atualizado conforme decisões forem tomadas.