-- Universal Utility (Phase 1 / 0.9.1)
-- Changelog 0.9.1 (marcado com -- [v0.9.1]):
-- * Corrigido bug de precedência lógica em UI.applyLanguage.
-- * Adicionada chave de tradução LEGACY_FLY_NOTE em pt/en.
-- * Logger otimizado com dirty flag (painel Debug só atualiza quando há novas entradas).
-- * Unificação de métricas (overlay e painel Stats usam o mesmo estado).
-- * Sprint usa Core._state (sprintBonus) e restaura WalkSpeed original quando desativa; evita writes redundantes.
-- * Registry de conexões Core (Bind/Unbind/UnbindAll) e Panic desmonta features dinâmicas.
-- * Fly modernizado: tenta LinearVelocity + AlignOrientation; fallback para BodyVelocity se falhar.
-- * Comando /uu diag para diagnóstico rápido.
-- * Tema: Themes.apply mantém referência Themes._current e reaplica após troca de idioma.
-- * Melhoria em Panic: desativa overlay, fly, noclip, sprint e limpa conexões.
-- * Overlay agora atualiza só quando métricas colhidas mudam (1x/s).
-- * Diversos pcall defensivos e notas de trace (-- [v0.9.1]).

local VERSION = "0.9.1"

-- ==== Serviços ====
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local StarterGui         = game:GetService("StarterGui")
local Stats              = game:GetService("Stats")
local Lighting           = game:GetService("Lighting")
local HttpService        = game:GetService("HttpService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ==== Persistência ====
local Persist = {}
Persist._fileName = "UniversalUtilityConfig.json"
Persist._data = {}
Persist._dirty = false
Persist._lastWrite = 0
Persist._flushInterval = 0.5
local hasFS = (typeof(isfile)=="function" and typeof(readfile)=="function" and typeof(writefile)=="function")

function Persist.load()
    if hasFS and isfile(Persist._fileName) then
        pcall(function()
            local raw = readfile(Persist._fileName)
            Persist._data = HttpService:JSONDecode(raw)
        end)
    end
end
function Persist.flush(force)
    if not hasFS then return end
    if not force and not Persist._dirty then return end
    if not force and (tick() - Persist._lastWrite) < Persist._flushInterval then return end
    Persist._lastWrite = tick()
    Persist._dirty = false
    pcall(function()
        writefile(Persist._fileName, HttpService:JSONEncode(Persist._data))
    end)
end
function Persist.saveSoon()
    Persist._dirty = true
end
function Persist.get(key, default)
    local v = Persist._data[key]
    if v == nil and default ~= nil then
        Persist._data[key] = default
        Persist._dirty = true
        return default
    end
    return v
end
function Persist.setIfChanged(key, value)
    if Persist._data[key] ~= value then
        Persist._data[key] = value
        Persist.saveSoon()
    end
end
function Persist.set(key,value) Persist._data[key]=value; Persist.saveSoon() end
function Persist.exportConfig()
    Persist.flush(true)
    return HttpService:JSONEncode(Persist._data)
end
function Persist.importConfig(json)
    local ok, decoded = pcall(function() return HttpService:JSONDecode(json) end)
    if ok and type(decoded)=="table" then
        for k,v in pairs(decoded) do
            Persist._data[k]=v
        end
        Persist.saveSoon()
        Persist.flush(true)
        return true
    end
    return false
end
Persist.load()

-- ==== Logger (com dirty flag 0.9.1) ====
local Logger = {}
Logger._max = 150
Logger._lines = {}
Logger._exportTag = "UU_LOG"
Logger._dirty = false -- [v0.9.1]
function Logger.Log(level, msg)
    local line = os.date("%H:%M:%S").." ["..level.."] "..tostring(msg)
    table.insert(Logger._lines, line)
    if #Logger._lines > Logger._max then
        table.remove(Logger._lines,1)
    end
    Logger._dirty = true -- [v0.9.1]
    warn("[UU]["..level.."] "..msg)
end
function Logger.Export()
    local blob = table.concat(Logger._lines,"\n")
    if setclipboard then setclipboard(blob) end
    return blob
end

local function LOG(msg) Logger.Log("INFO", msg) end

-- ==== Internacionalização ====
local Lang = {}
Lang.data = {
    pt = {
        UI_TITLE = "Universal Utility v%s",
        PANEL_GENERAL = "Geral",
        PANEL_MOVEMENT = "Movimento",
        PANEL_CAMERA = "Câmera",
        PANEL_STATS = "Stats",
        PANEL_EXTRAS = "Extras",
        PANEL_FLY = "Fly",
        PANEL_DEBUG = "Depuração",
        PANEL_LANG_MISSING = "Traduções Faltantes",
        PANEL_SPRINT = "Sprint",
        PANEL_KEYBINDS = "Keybinds",
        PANEL_PROFILES = "Perfis",
        PANEL_THEME = "Tema",
        SECTION_INFO = "Informações",
        SECTION_LEADERSTATS = "Leaderstats",
        SECTION_HUMANOID = "Ajustes de Humanoid",
        SECTION_CAMERA = "Ajustes de Câmera",
        SECTION_MONITOR = "Monitor",
        SECTION_TOUCH = "Atalhos Mobile",
        SECTION_EXTRAS = "Funções Extras",
        SECTION_POSITIONS = "Posições",
        SECTION_AMBIENCE = "Ambiente Local",
        SECTION_FLY = "Controle de Voo",
        SECTION_LOGGER = "Logger",
        SECTION_TP_HISTORY = "Histórico TP",
        LABEL_VERSION = "Versão",
        LABEL_FS = "Executor FS",
        LABEL_DEVICE = "Dispositivo",
        LABEL_STARTED = "Iniciado",
        LABEL_NO_LS = "Nenhum leaderstats detectado.",
        LABEL_FPS = "FPS",
        LABEL_MEM = "Mem",
        LABEL_PING = "Ping",
        LABEL_PLAYERS = "Jogadores",
        LABEL_POS_ATUAL = "Pos Atual",
        LABEL_LANG_CHANGE = "Alterar Idioma",
        BTN_RESPAWN = "Respawn",
        BTN_RESET_FOV = "Reset FOV",
        BTN_INFO = "Info",
        BTN_OVERLAY_RESET = "Reset Overlay",
        BTN_SAVE_POS = "Salvar Posição",
        BTN_CLEAR_POS = "Limpar Todas",
        BTN_COPY_POS = "Copiar Pos Atual",
        BTN_SHOW_HIDE = "[F4] Mostrar/Ocultar",
        BTN_FLY_UP = "Subir",
        BTN_FLY_DOWN = "Descer",
        BTN_FLY_SPEEDMODE = "Veloc+",
        TOGGLE_REAPPLY = "Reaplicar em respawn",
        TOGGLE_SHIFTLOCK = "Shift-Lock (PC)",
        TOGGLE_SMOOTH = "Câmera Suave",
        TOGGLE_OVERLAY = "Mostrar Overlay",
        TOGGLE_NOCLIP = "Noclip",
        TOGGLE_WORLD_TIME = "Hora Custom",
        TOGGLE_SPRINT = "Auto Sprint",
        TOGGLE_SPRINT_HOLD = "Hold p/ Sprint",
        TOGGLE_THEME_LIGHT = "Tema Claro",
        TOGGLE_THEME_DARK = "Tema Escuro",
        SLIDER_WALKSPEED = "WalkSpeed",
        SLIDER_JUMPPOWER = "JumpPower",
        SLIDER_FOV = "FOV",
        SLIDER_CAM_SENS = "Sensibilidade",
        SLIDER_OVERLAY_INTERVAL = "Intervalo Overlay",
        SLIDER_WORLD_TIME = "Hora",
        SLIDER_SPRINT_BONUS = "Sprint Bônus",
        SLIDER_SPRINT_HOLD = "Tempo Hold",
        NOTIFY_INFO = "Use os painéis para ajustes.",
        NOTIFY_FOV_RESET = "FOV redefinido",
        NOTIFY_POS_LIMIT = "Limite atingido.",
        NOTIFY_NO_ROOT = "Sem HumanoidRootPart",
        NOTIFY_POS_COPIED = "Copiado.",
        NOTIFY_POS_SAVED = "Salvo.",
        NOTIFY_LOADED = "Carregado v%s",
        LANG_CHANGED = "Idioma alterado.",
        LOGGER_EXPORTED = "Logger exportado.",
        PROFILE_SAVED = "Perfil %d salvo.",
        PROFILE_LOADED = "Perfil %d carregado.",
        PROFILE_INVALID = "Perfil inválido.",
        SPRINT_ON = "Sprint ativo.",
        SPRINT_OFF = "Sprint inativo.",
        THEME_APPLIED = "Tema aplicado.",
        KEYBIND_SET = "Keybind %s => %s",
        KEYBIND_WAIT = "Pressione tecla...",
        KEYBIND_CANCEL = "Cancelado.",
        HELP_TITLE = "Comandos: theme/profile/keybind/sprint/debug/panic/export/import/help",
        DEBUG_PANEL = "Painel Debug",
        MINI_HANDLE = "≡",
        MINI_TIP = "Arraste/Clique",
        MISSING_NONE = "Nenhuma chave faltando",
        PANIC_DONE = "Panic executado.",
        LEGACY_FLY_NOTE = "Modo Fly (moderno c/ fallback).", -- [v0.9.1]
        DIAG_MESSAGE = "Diag v%s | FPS:%d Mem:%dKB Ping:%d Jog:%d Sprint:%s Fly:%s Noclip:%s Overlay:%s", -- [v0.9.1]
    },
    en = {
        UI_TITLE = "Universal Utility v%s",
        PANEL_GENERAL = "General",
        PANEL_MOVEMENT = "Movement",
        PANEL_CAMERA = "Camera",
        PANEL_STATS = "Stats",
        PANEL_EXTRAS = "Extras",
        PANEL_FLY = "Fly",
        PANEL_DEBUG = "Debug",
        PANEL_LANG_MISSING = "Missing Keys",
        PANEL_SPRINT = "Sprint",
        PANEL_KEYBINDS = "Keybinds",
        PANEL_PROFILES = "Profiles",
        PANEL_THEME = "Theme",
        SECTION_INFO = "Info",
        SECTION_LEADERSTATS = "Leaderstats",
        SECTION_HUMANOID = "Humanoid",
        SECTION_CAMERA = "Camera",
        SECTION_MONITOR = "Monitor",
        SECTION_TOUCH = "Mobile Shortcuts",
        SECTION_EXTRAS = "Extras",
        SECTION_POSITIONS = "Positions",
        SECTION_AMBIENCE = "Local Time",
        SECTION_FLY = "Fly Control",
        SECTION_LOGGER = "Logger",
        SECTION_TP_HISTORY = "TP History",
        LABEL_VERSION = "Version",
        LABEL_FS = "FS Support",
        LABEL_DEVICE = "Device",
        LABEL_STARTED = "Started",
        LABEL_NO_LS = "No leaderstats.",
        LABEL_FPS = "FPS",
        LABEL_MEM = "Mem",
        LABEL_PING = "Ping",
        LABEL_PLAYERS = "Players",
        LABEL_POS_ATUAL = "Current Pos",
        LABEL_LANG_CHANGE = "Change Language",
        BTN_RESPAWN = "Respawn",
        BTN_RESET_FOV = "Reset FOV",
        BTN_INFO = "Info",
        BTN_OVERLAY_RESET = "Reset Overlay",
        BTN_SAVE_POS = "Save Position",
        BTN_CLEAR_POS = "Clear All",
        BTN_COPY_POS = "Copy Position",
        BTN_SHOW_HIDE = "[F4] Show/Hide",
        BTN_FLY_UP = "Up",
        BTN_FLY_DOWN = "Down",
        BTN_FLY_SPEEDMODE = "Speed+",
        TOGGLE_REAPPLY = "Reapply on respawn",
        TOGGLE_SHIFTLOCK = "Shift-Lock (PC)",
        TOGGLE_SMOOTH = "Smooth Cam",
        TOGGLE_OVERLAY = "Show Overlay",
        TOGGLE_NOCLIP = "Noclip",
        TOGGLE_WORLD_TIME = "Custom Time",
        TOGGLE_SPRINT = "Auto Sprint",
        TOGGLE_SPRINT_HOLD = "Hold for Sprint",
        TOGGLE_THEME_LIGHT = "Light Theme",
        TOGGLE_THEME_DARK = "Dark Theme",
        SLIDER_WALKSPEED = "WalkSpeed",
        SLIDER_JUMPPOWER = "JumpPower",
        SLIDER_FOV = "FOV",
        SLIDER_CAM_SENS = "Sensitivity",
        SLIDER_OVERLAY_INTERVAL = "Overlay Interval",
        SLIDER_WORLD_TIME = "Clock Time",
        SLIDER_SPRINT_BONUS = "Sprint Bonus",
        SLIDER_SPRINT_HOLD = "Hold Time",
        NOTIFY_INFO = "Use panels to adjust.",
        NOTIFY_FOV_RESET = "FOV reset",
        NOTIFY_POS_LIMIT = "Limit reached.",
        NOTIFY_NO_ROOT = "No HumanoidRootPart",
        NOTIFY_POS_COPIED = "Copied.",
        NOTIFY_POS_SAVED = "Saved.",
        NOTIFY_LOADED = "Loaded v%s",
        LANG_CHANGED = "Language changed.",
        LOGGER_EXPORTED = "Logger exported.",
        PROFILE_SAVED = "Profile %d saved.",
        PROFILE_LOADED = "Profile %d loaded.",
        PROFILE_INVALID = "Invalid profile.",
        SPRINT_ON = "Sprint on.",
        SPRINT_OFF = "Sprint off.",
        THEME_APPLIED = "Theme applied.",
        KEYBIND_SET = "Keybind %s => %s",
        KEYBIND_WAIT = "Press a key...",
        KEYBIND_CANCEL = "Canceled.",
        HELP_TITLE = "Commands: theme/profile/keybind/sprint/debug/panic/export/import/help",
        DEBUG_PANEL = "Debug Panel",
        MINI_HANDLE = "≡",
        MINI_TIP = "Drag/Click",
        MISSING_NONE = "No missing keys",
        PANIC_DONE = "Panic executed.",
        LEGACY_FLY_NOTE = "Fly mode (modern with fallback).", -- [v0.9.1]
        DIAG_MESSAGE = "Diag v%s | FPS:%d Mem:%dKB Ping:%d Ply:%d Sprint:%s Fly:%s Noclip:%s Overlay:%s", -- [v0.9.1]
    }
}
Lang.current = Persist.get("lang", nil)

local _missingLogged = {} -- [v0.9.1] log de faltantes uma vez

local function L(k, ...)
    local pack = Lang.data[Lang.current or "pt"]
    local s = (pack and pack[k]) or k
    if s == k and not _missingLogged[k] then
        _missingLogged[k] = true
        Logger.Log("I18N","Missing key: "..k)
    end
    if select("#", ...) > 0 then return string.format(s, ...) end
    return s
end

local function ensureLanguage(callback)
    if Lang.current then callback() return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "LangSelect09"
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 140)
    frame.Position = UDim2.new(0.5,-160,0.5,-70)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,35)
    frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1,0,0,50)
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1,1,1)
    title.TextSize = 18
    title.Text = "Idioma / Language"
    title.Parent = frame
    local function makeBtn(txt, xPos, lang)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.5,-20,0,50)
        b.Position = UDim2.new(xPos,10,0,60)
        b.BackgroundColor3 = Color3.fromRGB(40,60,90)
        b.TextColor3 = Color3.new(1,1,1)
        b.TextSize = 16
        b.Font = Enum.Font.GothamBold
        b.Text = txt
        b.Parent = frame
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
        b.MouseButton1Click:Connect(function()
            Lang.current = lang
            Persist.set("lang", lang)
            sg:Destroy()
            callback()
        end)
    end
    makeBtn("Português",0,"pt")
    makeBtn("English",0.5,"en")
end

-- ==== Helpers ====
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = dur or 3
        })
    end)
end

local function safe(fn, ...)
    local ok, r = pcall(fn, ...)
    if not ok then
        Logger.Log("ERR", r)
    end
    return ok, r
end

local Util = {}
function Util.getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildWhichIsA("Humanoid")
end
function Util.getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
function Util.draggable(frame, handle, onDrop)
    handle = handle or frame
    local dragging=false
    local dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=input.Position
            startPos=frame.Position
            input.Changed:Connect(function(chg)
                if chg == Enum.UserInputState.End then
                    if dragging then
                        dragging=false
                        if onDrop then safe(onDrop, frame.Position) end
                    end
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

-- ==== Core e API ====
local Core = {}
Core._lazyPanels = {}
Core._commands = {}
Core._keybinds = {}
Core._keybindActions = {}
Core._metricsObservers = {}
Core._tpHistory = Persist.get("tp_history",{ })
Core._state = {
    version = VERSION,
    started = os.clock(),
    theme = Persist.get("ui_theme","dark"),
    autoSprint = Persist.get("sprint_enabled", false),
    sprintHolding = Persist.get("sprint_hold_mode", true),
    sprintHoldTime = Persist.get("sprint_hold_time", 0.5),
    sprintBonus = Persist.get("sprint_bonus", 8),
    overlayVisible = Persist.get("overlay_visible", true),
}

-- [v0.9.1] Registro de conexões
Core._connections = {}
function Core.Bind(name, conn)
    if Core._connections[name] then
        pcall(function() Core._connections[name]:Disconnect() end)
    end
    Core._connections[name] = conn
end
function Core.Unbind(name)
    if Core._connections[name] then
        pcall(function() Core._connections[name]:Disconnect() end)
        Core._connections[name] = nil
    end
end
function Core.UnbindAll()
    for k,c in pairs(Core._connections) do
        pcall(function() c:Disconnect() end)
    end
    Core._connections = {}
end

function Core.API_RegisterCommand(name, desc, fn)
    Core._commands[name] = {fn=fn,desc=desc}
end
function Core.API_RegisterKeybind(name, defaultKeyCode, callback)
    if not Core._keybinds[name] then
        Core._keybinds[name] = Persist.get("kb_"..name, defaultKeyCode.Name)
        Core._keybindActions[name] = callback
    end
end
function Core.API_RegisterLazyPanel(key, builder)
    Core._lazyPanels[key] = {built=false, builder=builder}
end
function Core.API_AddMetricsObserver(fn)
    table.insert(Core._metricsObservers, fn)
end
function Core.API_GetState()
    return Core._state
end
function Core.API_Log(msg)
    Logger.Log("API", msg)
end
function Core.API_PanicAll()
    Core._state.autoSprint = false
    Persist.setIfChanged("sprint_enabled", false)
    Core._state.overlayVisible = false
    Persist.setIfChanged("overlay_visible", false)
    if Core._noclipDisable then Core._noclipDisable() end
    if Core._customTimeDisable then Core._customTimeDisable() end
    if Core._flyDisable then Core._flyDisable() end
    Core.UnbindAll() -- [v0.9.1]
    Logger.Log("PANIC","All features disabled")
    if UI._perfOverlay then UI._perfOverlay.Visible = false end
    notify("PANIC", L("PANIC_DONE"))
end

Core.API = {
    RegisterCommand = Core.API_RegisterCommand,
    RegisterKeybind = Core.API_RegisterKeybind,
    RegisterLazyPanel = Core.API_RegisterLazyPanel,
    AddMetricsObserver = Core.API_AddMetricsObserver,
    GetState = Core.API_GetState,
    Log = Core.API_Log,
    PanicAll = Core.API_PanicAll,
}

-- ==== Keybind Manager ====
local KeybindManager = {}
KeybindManager.list = {
    menuToggle = "F4",
    flyToggle = "G",
    panic = "P",
    overlayToggle = "O",
}
for k,v in pairs(KeybindManager.list) do
    local saved = Persist.get("kb_"..k,nil)
    if saved then KeybindManager.list[k]=saved end
end

function KeybindManager.set(name, codeName)
    KeybindManager.list[name] = codeName
    Persist.setIfChanged("kb_"..name, codeName)
end

function KeybindManager.match(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local keyName = input.KeyCode.Name
    for k, code in pairs(KeybindManager.list) do
        if code == keyName then
            local cb = Core._keybindActions[k]
            if cb then safe(cb) end
        end
    end
end

UserInputService.InputBegan:Connect(function(i,gp)
    if gp then return end
    KeybindManager.match(i)
end)

-- ==== Theme System ====
local Themes = {
    dark = {
        bg = Color3.fromRGB(20,22,30),
        header = Color3.fromRGB(30,34,46),
        panel = Color3.fromRGB(28,32,42),
        accent = Color3.fromRGB(55,65,90),
        text = Color3.fromRGB(235,235,245),
        textDim = Color3.fromRGB(200,205,215),
        highlight = Color3.fromRGB(90,150,255),
    },
    light = {
        bg = Color3.fromRGB(235,238,245),
        header = Color3.fromRGB(215,220,230),
        panel = Color3.fromRGB(225,228,235),
        accent = Color3.fromRGB(180,190,205),
        text = Color3.fromRGB(35,40,50),
        textDim = Color3.fromRGB(60,70,85),
        highlight = Color3.fromRGB(40,120,230),
    }
}
local ThemeRegistry = {}
Themes._current = Themes.dark -- [v0.9.1]
function Themes.apply(name)
    local theme = Themes[name] or Themes.dark
    Themes._current = theme -- [v0.9.1]
    for _, item in ipairs(ThemeRegistry) do
        if item.prop and item.instance then
            local val = theme[item.prop]
            if val then
                pcall(function()
                    item.instance[item.field or "BackgroundColor3"] = val
                end)
            end
        end
    end
    Core._state.theme = name
    Persist.setIfChanged("ui_theme", name)
    notify("Theme", L("THEME_APPLIED"))
end
function Themes.register(instance, prop, field)
    table.insert(ThemeRegistry, {instance=instance, prop=prop, field=field})
end

-- ==== UI (Lazy Panels) ====
local UI = {}
UI._translatables = {}
UI._panelButtons = {}
UI._panelContainers = {}
UI._builtPanels = {}
UI._missingPanelKey = "PANEL_LANG_MISSING"
UI.Screen = nil
UI.RootFrame = nil
UI.Container = nil
UI.MiniButton = nil
UI._menuVisible = true

local function mark(instance, key, ...)
    table.insert(UI._translatables, {instance=instance, key=key, args={...}})
end

function UI.applyLanguage()
    -- [v0.9.1] Correção de precedência (adicionados parênteses)
    for _, data in ipairs(UI._translatables) do
        local inst = data.instance
        if inst
           and inst.Parent
           and (inst:IsA("TextLabel") or inst:IsA("TextButton")) then
            if data.args and #data.args>0 then
                inst.Text = L(data.key, table.unpack(data.args))
            else
                inst.Text = L(data.key)
            end
        end
    end
    if UI.TitleLabel then
        UI.TitleLabel.Text = L("UI_TITLE", VERSION)
    end
    if UI.MiniButton then
        UI.MiniButton.Text = L("MINI_HANDLE")
        if UI.MiniTip then UI.MiniTip.Text = L("MINI_TIP") end
    end
end

local function saveMenuPosFromUDim2(pos)
    Persist.setIfChanged("ui_menu_pos", {
        sx = pos.X.Scale, x = pos.X.Offset,
        sy = pos.Y.Scale, y = pos.Y.Offset
    })
end
local function loadMenuPosition(def)
    local d = Persist.get("ui_menu_pos", nil)
    if d then
        return UDim2.new(d.sx or 0, d.x or 0, d.sy or 0, d.y or 0)
    end
    return def
end

function UI.toggleMenu()
    if not UI.RootFrame or not UI.MiniButton then return end
    UI._menuVisible = not UI._menuVisible
    UI.RootFrame.Visible = UI._menuVisible
    UI.MiniButton.Visible = not UI._menuVisible
end

Core.API_RegisterKeybind("menuToggle", Enum.KeyCode.F4, UI.toggleMenu)

function UI.createRoot()
    local screen = Instance.new("ScreenGui")
    screen.Name = "UU_091"
    screen.ResetOnSpawn = false
    pcall(function()
        screen.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end)

    local mini = Instance.new("TextButton")
    mini.Name = "MiniHandle"
    mini.Size = UDim2.new(0,46,0,46)
    mini.BackgroundColor3 = Themes._current.header
    mini.TextColor3 = Color3.new(1,1,1)
    mini.Font = Enum.Font.GothamBold
    mini.TextSize = 20
    mini.Text = L("MINI_HANDLE")
    mini.Visible = false
    mini.Parent = screen
    Instance.new("UICorner", mini).CornerRadius = UDim.new(0,10)
    Themes.register(mini,"header","BackgroundColor3")

    local miniTip = Instance.new("TextLabel")
    miniTip.BackgroundTransparency = 1
    miniTip.Size = UDim2.new(1,0,0,14)
    miniTip.Position = UDim2.new(0,0,1,-14)
    miniTip.Font = Enum.Font.Code
    miniTip.TextSize = 12
    miniTip.TextColor3 = Themes._current.textDim
    miniTip.Text = L("MINI_TIP")
    miniTip.Parent = mini
    Themes.register(miniTip,"textDim","TextColor3")

    local defaultPos = UDim2.new(0.05,0,0.25,0)
    local floating = Instance.new("Frame")
    floating.Size = UDim2.new(0, 400, 0, 540)
    floating.Position = loadMenuPosition(defaultPos)
    floating.BackgroundColor3 = Themes._current.bg
    floating.BorderSizePixel = 0
    floating.Parent = screen
    Instance.new("UICorner", floating).CornerRadius = UDim.new(0,12)
    Themes.register(floating,"bg")

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1,0,0,48)
    header.BackgroundColor3 = Themes._current.header
    header.BorderSizePixel = 0
    header.Parent = floating
    Instance.new("UICorner", header).CornerRadius = UDim.new(0,12)
    Themes.register(header,"header")

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1,-90,1,0)
    title.Position = UDim2.new(0,16,0,0)
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Themes._current.text
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = L("UI_TITLE", VERSION)
    title.Parent = header
    UI.TitleLabel = title
    Themes.register(title,"text","TextColor3")

    local hideBtn = Instance.new("TextButton")
    hideBtn.Size = UDim2.new(0,60,0,30)
    hideBtn.Position = UDim2.new(1,-70,0.5,-15)
    hideBtn.BackgroundColor3 = Themes._current.accent
    hideBtn.TextColor3 = Color3.new(1,1,1)
    hideBtn.Font = Enum.Font.GothamBold
    hideBtn.TextSize = 12
    hideBtn.Text = "Hide"
    hideBtn.Parent = header
    Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0,8)
    Themes.register(hideBtn,"accent")

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "Panels"
    scroll.Size = UDim2.new(1,-20,1,-60)
    scroll.Position = UDim2.new(0,10,0,55)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness = 6
    scroll.Parent = floating
    local list = Instance.new("UIListLayout", scroll)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0,8)
    list.Changed:Connect(function(p)
        if p=="AbsoluteContentSize" then
            scroll.CanvasSize = UDim2.new(0,0,0,list.AbsoluteContentSize.Y+20)
        end
    end)

    Util.draggable(floating, header, function(pos)
        saveMenuPosFromUDim2(pos)
        if not floating.Visible then
            mini.Position = pos
            saveMenuPosFromUDim2(mini.Position)
        end
    end)
    Util.draggable(mini, mini, function(pos)
        saveMenuPosFromUDim2(pos)
    end)

    hideBtn.MouseButton1Click:Connect(function()
        floating.Visible = false
        mini.Visible = true
        mini.Position = floating.Position
        saveMenuPosFromUDim2(mini.Position)
    end)
    mini.MouseButton1Click:Connect(function()
        floating.Position = mini.Position
        floating.Visible = true
        mini.Visible = false
        saveMenuPosFromUDim2(floating.Position)
    end)

    UI.Screen = screen
    UI.RootFrame = floating
    UI.Container = scroll
    UI.MiniButton = mini
    UI.MiniTip = miniTip
end

function UI.buildPanelButton(key)
    local holder = Instance.new("Frame")
    holder.BackgroundColor3 = Themes._current.panel
    holder.Size = UDim2.new(1,0,0,0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.Parent = UI.Container
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0,10)
    Themes.register(holder,"panel")

    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1,-14,0,40)
    header.Position = UDim2.new(0,7,0,7)
    header.BackgroundColor3 = Themes._current.accent
    header.TextColor3 = Color3.new(1,1,1)
    header.Font = Enum.Font.GothamBold
    header.TextSize = 14
    header.Text = "► "..L(key)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = holder
    Instance.new("UICorner", header).CornerRadius = UDim.new(0,8)
    mark(header,key)
    Themes.register(header,"accent")

    local content = Instance.new("Frame")
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0,10,0,50)
    content.Size = UDim2.new(1,-20,0,0)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.Visible = false
    content.Parent = holder
    local layout = Instance.new("UIListLayout", content)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,6)

    UI._panelButtons[key] = header
    UI._panelContainers[key] = content

    local expanded = false
    header.MouseButton1Click:Connect(function()
        expanded = not expanded
        header.Text = (expanded and "▼ " or "► ") .. L(key)
        content.Visible = expanded
        if expanded and Core._lazyPanels[key] and not Core._lazyPanels[key].built then
            Core._lazyPanels[key].built = true
            safe(Core._lazyPanels[key].builder, content)
            UI.applyLanguage()
        end
    end)
end

local function UI_Label(parent, text, isKey)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1,0,0,20)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Themes._current.textDim
    lbl.Text = isKey and L(text) or text
    lbl.Parent = parent
    if isKey then mark(lbl,text) end
    Themes.register(lbl,"textDim","TextColor3")
    return lbl
end

local function UI_Button(parent, textKeyOrRaw, isKey, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,30)
    b.BackgroundColor3 = Themes._current.accent
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Text = isKey and L(textKeyOrRaw) or textKeyOrRaw
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    if isKey then mark(b,textKeyOrRaw) end
    Themes.register(b,"accent")
    b.MouseButton1Click:Connect(function() safe(callback) end)
    return b
end

local function UI_Toggle(parent, labelKey, persistKey, default, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,30)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,56,1,0)
    btn.BackgroundColor3 = Themes._current.accent
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = "OFF"
    btn.Parent = holder
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    Themes.register(btn,"accent")

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0,62,0,0)
    lbl.Size = UDim2.new(1,-62,1,0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Themes._current.text
    lbl.Text = L(labelKey)
    lbl.Parent = holder
    mark(lbl,labelKey)
    Themes.register(lbl,"text","TextColor3")

    local state = Persist.get(persistKey, default)
    local function apply(trigger)
        btn.Text = state and "ON" or "OFF"
        if trigger then safe(callback,state) end
        Persist.setIfChanged(persistKey,state)
    end
    btn.MouseButton1Click:Connect(function()
        state = not state
        apply(true)
    end)
    apply(true)
    return function(newState)
        state = newState
        apply(true)
    end
end

local function UI_Slider(parent, labelKey, persistKey, minVal, maxVal, defaultVal, step, callback)
    step = step or 1
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,50)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local value = Persist.get(persistKey, defaultVal)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,18)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Themes._current.text
    lbl.Text = L(labelKey)..": "..tostring(value)
    lbl.Parent = holder
    mark(lbl,labelKey)
    Themes.register(lbl,"text","TextColor3")

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,-8,0,10)
    bar.Position = UDim2.new(0,4,0,28)
    bar.BackgroundColor3 = Themes._current.accent
    bar.Parent = holder
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,5)
    Themes.register(bar,"accent")

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((value - minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3 = Themes._current.highlight
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,5)
    Themes.register(fill,"highlight")

    local dragging=false
    local function applyValue(v, fire)
        fill.Size = UDim2.new((v - minVal)/(maxVal-minVal),0,1,0)
        lbl.Text = L(labelKey)..": "..tostring(v)
        Persist.setIfChanged(persistKey, v)
        if fire then safe(callback,v) end
    end
    local function setFromX(x, fire)
        local rel = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        local raw = minVal + (maxVal-minVal)*rel
        local snapped = minVal + math.floor((raw - minVal)/step + 0.5)*step
        snapped = math.clamp(snapped, minVal, maxVal)
        applyValue(snapped, fire)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            setFromX(i.Position.X,true)
        end
    end)
    bar.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
    bar.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            setFromX(i.Position.X,true)
        end
    end)
    safe(callback,value)
    return function(newVal, fire)
        newVal = math.clamp(newVal, minVal, maxVal)
        applyValue(newVal, fire)
    end
end

-- ==== Métricas (unificado 0.9.1) ====
local metricsState = {
    fps = 0, lastFrames = 0, lastTick = tick(),
    mem = 0, ping = 0, players = 0
}
RunService.RenderStepped:Connect(function()
    metricsState.lastFrames += 1
    local now = tick()
    if now - metricsState.lastTick >= 1 then
        metricsState.fps = metricsState.lastFrames
        metricsState.lastFrames = 0
        metricsState.lastTick = now
        metricsState.mem = gcinfo()
        local pingStat = Stats.Network.ServerStatsItem["Data Ping"]
        metricsState.ping = pingStat and pingStat:GetValue() or -1
        metricsState.players = #Players:GetPlayers()
        for _, obs in ipairs(Core._metricsObservers) do
            safe(obs, metricsState)
        end
        -- Atualiza overlay se existir
        if UI._perfOverlay and Core._state.overlayVisible then
            UI._perfOverlay.Text = string.format("%s: %d\n%s: %d KB\n%s: %d ms\n%s: %d",
                L("LABEL_FPS"),metricsState.fps,
                L("LABEL_MEM"),metricsState.mem,
                L("LABEL_PING"),metricsState.ping,
                L("LABEL_PLAYERS"),metricsState.players)
        end
    end
end)

-- ==== Sprint System (ajustado 0.9.1) ====
local Sprint = {}
Sprint.isActive = false
Sprint._accHold = 0
Sprint._holding = false
Sprint._baseWalkSpeed = nil
Sprint._lastApplied = nil

function Sprint.setActive(on)
    if Sprint.isActive == on then return end
    Sprint.isActive = on
    Persist.setIfChanged("sprint_enabled", on)
    if not on then
        -- restaura
        local hum = Util.getHumanoid()
        if hum and Sprint._baseWalkSpeed then
            if hum.WalkSpeed ~= Sprint._baseWalkSpeed then
                pcall(function() hum.WalkSpeed = Sprint._baseWalkSpeed end)
            end
        end
        Sprint._lastApplied = nil
    end
end

function Sprint.apply()
    local hum = Util.getHumanoid()
    if not hum then return end
    if not Sprint._baseWalkSpeed then
        Sprint._baseWalkSpeed = Persist.get("walkspeed_value", hum.WalkSpeed)
    end
    if Sprint.isActive then
        local bonus = Core._state.sprintBonus
        local target = Sprint._baseWalkSpeed + bonus
        if Sprint._lastApplied ~= target then
            pcall(function() hum.WalkSpeed = target end)
            Sprint._lastApplied = target
        end
    end
end

UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then
        Sprint._holding = true
        Sprint._accHold = 0
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        Sprint._holding = false
        if Core._state.sprintHolding then
            Sprint.setActive(false)
            Sprint.apply()
        end
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if Core._state.autoSprint then
        if Core._state.sprintHolding then
            if Sprint._holding then
                Sprint._accHold += dt
                if not Sprint.isActive and Sprint._accHold >= Core._state.sprintHoldTime then
                    Sprint.setActive(true)
                end
            end
        else
            Sprint.setActive(true)
        end
    else
        if Sprint.isActive then
            Sprint.setActive(false)
        end
    end
    Sprint.apply()
end)

-- ==== Perfis ====
local Profiles = {}
local profileKeys = {
    "walkspeed_value","jumppower_value","camera_fov","camera_sens",
    "camera_shiftlock","camera_smooth","overlay_visible","sprint_enabled",
    "sprint_bonus","sprint_hold_time","sprint_hold_mode"
}
function Profiles.save(idx)
    if idx <1 or idx>3 then return false end
    local data = {}
    for _,k in ipairs(profileKeys) do
        data[k] = Persist.get(k, nil)
    end
    Persist.set("profile_"..idx, data)
    Persist.flush(true)
    notify("Profile", L("PROFILE_SAVED", idx))
    return true
end
function Profiles.load(idx)
    if idx <1 or idx>3 then return false end
    local data = Persist.get("profile_"..idx, nil)
    if not data then
        notify("Profile", L("PROFILE_INVALID"))
        return false
    end
    for k,v in pairs(data) do
        Persist.set(k,v)
    end
    Sprint.setActive(Persist.get("sprint_enabled",false))
    Core._state.autoSprint = Persist.get("sprint_enabled",false)
    Core._state.sprintBonus = Persist.get("sprint_bonus",8)
    Core._state.sprintHoldTime = Persist.get("sprint_hold_time",0.5)
    Core._state.sprintHolding = Persist.get("sprint_hold_mode",true)
    notify("Profile", L("PROFILE_LOADED", idx))
    return true
end

-- ==== Teleport History ====
function Core.addTPHistory(pos)
    table.insert(Core._tpHistory,1,{x=pos.X,y=pos.Y,z=pos.Z,t=os.time()})
    while #Core._tpHistory > 5 do
        table.remove(Core._tpHistory)
    end
    Persist.set("tp_history", Core._tpHistory)
end

-- ==== Commands (/uu ...) ====
local function parseCommand(text)
    if not text:lower():match("^/uu%s") then return end
    local body = text:sub(5)
    local args = {}
    for token in body:gmatch("%S+") do table.insert(args, token) end
    local cmd = table.remove(args,1)
    if not cmd then
        notify("UU", L("HELP_TITLE"))
        return
    end
    local c = Core._commands[cmd:lower()]
    if c then
        safe(c.fn, args)
    else
        notify("UU","?")
    end
end

LocalPlayer.Chatted:Connect(function(msg)
    parseCommand(msg)
end)

-- Registered Commands
Core.API_RegisterCommand("help","Show help", function()
    local list = {}
    for k,v in pairs(Core._commands) do
        table.insert(list, k)
    end
    table.sort(list)
    notify("UU", L("HELP_TITLE"))
    Logger.Log("CMD","Help => "..table.concat(list,", "))
end)

Core.API_RegisterCommand("panic","Disable features quickly", function()
    Core.API_PanicAll()
end)

Core.API_RegisterCommand("export","Export config", function()
    local blob = Persist.exportConfig()
    if setclipboard then setclipboard(blob) end
    notify("UU","Exported config.")
end)

Core.API_RegisterCommand("import","Import config (paste in console)", function()
    notify("UU","Paste JSON in console: Persist.importConfig(json)")
end)

Core.API_RegisterCommand("theme","Change theme: /uu theme dark|light", function(args)
    local t = args[1]
    if t and Themes[t] then
        Themes.apply(t)
    else
        notify("Theme","dark/light?")
    end
end)

Core.API_RegisterCommand("profile","/uu profile save|load <n>", function(args)
    local action = args[1]; local idx = tonumber(args[2] or "")
    if not idx then notify("Profile","n?") return end
    if action=="save" then Profiles.save(idx)
    elseif action=="load" then Profiles.load(idx)
    else notify("Profile","save|load") end
end)

Core.API_RegisterCommand("keybind","/uu keybind <name> <key>", function(args)
    local name = args[1]; local keyName = args[2]
    if not name then
        local list = {}
        for k,v in pairs(KeybindManager.list) do table.insert(list, k.."="..v) end
        notify("Keybinds", table.concat(list,", "))
        return
    end
    if not Core._keybindActions[name] then
        notify("Keybinds","Invalid name")
        return
    end
    if not keyName then
        notify("Keybinds", L("KEYBIND_WAIT"))
        local conn; conn = UserInputService.InputBegan:Connect(function(i,gp)
            if gp then return end
            if i.UserInputType == Enum.UserInputType.Keyboard then
                KeybindManager.set(name, i.KeyCode.Name)
                notify("Keybinds", L("KEYBIND_SET", name, i.KeyCode.Name))
                conn:Disconnect()
            elseif i.UserInputType == Enum.UserInputType.MouseButton2 then
                notify("Keybinds", L("KEYBIND_CANCEL"))
                conn:Disconnect()
            end
        end)
        return
    end
    KeybindManager.set(name,keyName)
    notify("Keybinds", L("KEYBIND_SET", name, keyName))
end)

Core.API_RegisterCommand("sprint","/uu sprint on|off hold|toggle bonus <n> holdtime <n>", function(args)
    if #args == 0 then
        notify("Sprint", (Core._state.autoSprint and L("SPRINT_ON") or L("SPRINT_OFF")))
        return
    end
    local i=1
    while i <= #args do
        local a = args[i]
        if a=="on" then Core._state.autoSprint = true; Persist.setIfChanged("sprint_enabled",true)
        elseif a=="off" then Core._state.autoSprint = false; Persist.setIfChanged("sprint_enabled",false); Sprint.setActive(false)
        elseif a=="hold" then Core._state.sprintHolding = true; Persist.setIfChanged("sprint_hold_mode",true)
        elseif a=="toggle" then Core._state.sprintHolding = false; Persist.setIfChanged("sprint_hold_mode",false)
        elseif a=="bonus" then
            local val = tonumber(args[i+1]); if val then Core._state.sprintBonus=val; Persist.setIfChanged("sprint_bonus",val); i=i+1 end
        elseif a=="holdtime" then
            local val = tonumber(args[i+1]); if val then Core._state.sprintHoldTime=val; Persist.setIfChanged("sprint_hold_time",val); i=i+1 end
        end
        i=i+1
    end
    notify("Sprint", Core._state.autoSprint and L("SPRINT_ON") or L("SPRINT_OFF"))
end)

Core.API_RegisterCommand("debug","Open logger panel", function()
    if UI._panelButtons["PANEL_DEBUG"] then
        UI._panelButtons["PANEL_DEBUG"]:Activate()
    end
end)

-- [v0.9.1] Diagnóstico
Core.API_RegisterCommand("diag","Show internal diagnostics", function()
    local s = Core._state
    local msg = string.format(
        L("DIAG_MESSAGE"),
        VERSION, metricsState.fps, metricsState.mem, metricsState.ping,
        metricsState.players,
        s.autoSprint and "Y" or "N",
        Core._flyActive and "Y" or "N",
        Core._noclipActive and "Y" or "N",
        s.overlayVisible and "Y" or "N"
    )
    notify("Diag", msg, 5)
    Logger.Log("DIAG", msg)
end)

-- Keybind extra actions
Core.API_RegisterKeybind("panic", Enum.KeyCode.P, Core.API_PanicAll)
Core.API_RegisterKeybind("overlayToggle", Enum.KeyCode.O, function()
    Core._state.overlayVisible = not Core._state.overlayVisible
    Persist.setIfChanged("overlay_visible", Core._state.overlayVisible)
    if UI._perfOverlay then UI._perfOverlay.Visible = Core._state.overlayVisible end
end)

-- ==== Lazy Panel Builders ====

-- General Panel
Core.API_RegisterLazyPanel("PANEL_GENERAL", function(panel)
    UI_Label(panel, string.format("%s: %s", L("LABEL_VERSION"), VERSION), false)
    UI_Label(panel, string.format("%s: %s", L("LABEL_FS"), tostring(hasFS)), false)
    UI_Label(panel, string.format("%s: %s", L("LABEL_DEVICE"), (isMobile and "Mobile" or "PC")), false)
    UI_Label(panel, string.format("%s: %s", L("LABEL_STARTED"), os.date("%H:%M:%S")), false)

    UI_Button(panel,"LABEL_LANG_CHANGE",true,function()
        Lang.current = (Lang.current=="pt") and "en" or "pt"
        Persist.setIfChanged("lang", Lang.current)
        UI.applyLanguage()
        Themes.apply(Core._state.theme or "dark") -- [v0.9.1] re-aplicar cores
        notify("Lang", L("LANG_CHANGED"))
    end)

    if isMobile then
        UI_Label(panel,"SECTION_TOUCH",true)
        UI_Button(panel,"BTN_RESPAWN",true,function()
            local hum = Util.getHumanoid(); if hum then hum.Health=0 end
        end)
        UI_Button(panel,"BTN_RESET_FOV",true,function()
            local cam = workspace.CurrentCamera
            if cam then
                cam.FieldOfView = 70
                Persist.setIfChanged("camera_fov",70)
                notify("FOV", L("NOTIFY_FOV_RESET"))
            end
        end)
        UI_Button(panel,"BTN_INFO",true,function()
            notify("Info", L("NOTIFY_INFO"))
        end)
    end
end)

-- Movement Panel
Core.API_RegisterLazyPanel("PANEL_MOVEMENT", function(panel)
    local hum = Util.getHumanoid()
    UI_Slider(panel,"SLIDER_WALKSPEED","walkspeed_value",4,64, hum and hum.WalkSpeed or 16,1,function(v)
        local h = Util.getHumanoid(); if h then pcall(function() h.WalkSpeed = v end) end
        Sprint._baseWalkSpeed = v
    end)
    UI_Slider(panel,"SLIDER_JUMPPOWER","jumppower_value",25,150, hum and hum.JumpPower or 50,1,function(v)
        local h = Util.getHumanoid(); if h and h.UseJumpPower ~= false then pcall(function() h.JumpPower = v end) end
    end)
    UI_Toggle(panel,"TOGGLE_REAPPLY","auto_reapply_stats",true,function(on)
        if on then
            if not Core._autoApplyStatsConn then
                Core._autoApplyStatsConn = LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(0.35)
                    local h = Util.getHumanoid()
                    if h then
                        pcall(function()
                            h.WalkSpeed = Persist.get("walkspeed_value",16)
                            if h.UseJumpPower ~= false then h.JumpPower = Persist.get("jumppower_value",50) end
                        end)
                        Sprint._baseWalkSpeed = h.WalkSpeed
                    end
                end)
            end
        else
            if Core._autoApplyStatsConn then Core._autoApplyStatsConn:Disconnect() Core._autoApplyStatsConn=nil end
        end
    end)
end)

-- Camera Panel
Core.API_RegisterLazyPanel("PANEL_CAMERA", function(panel)
    UI_Slider(panel,"SLIDER_FOV","camera_fov",30,130, workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70,1,function(v)
        local cam = workspace.CurrentCamera; if cam then cam.FieldOfView = v end
    end)
    UI_Toggle(panel,"TOGGLE_SHIFTLOCK","camera_shiftlock",Persist.get("camera_shiftlock", false),function(on)
        Persist.setIfChanged("camera_shiftlock",on)
    end)
    UI_Toggle(panel,"TOGGLE_SMOOTH","camera_smooth",Persist.get("camera_smooth", false),function(on)
        Persist.setIfChanged("camera_smooth",on)
    end)
    UI_Slider(panel,"SLIDER_CAM_SENS","camera_sens",0.2,3,Persist.get("camera_sens",1),0.1,function(v)
        Persist.setIfChanged("camera_sens",v)
    end)
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.defer(function()
            local cam = workspace.CurrentCamera
            if cam then
                cam.FieldOfView = math.clamp(Persist.get("camera_fov",70),30,130)
            end
        end)
    end)
    RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        if Persist.get("camera_shiftlock",false) and not isMobile then
            if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            end
        else
            if not isMobile and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end
    end)
end)

-- Stats Panel
Core.API_RegisterLazyPanel("PANEL_STATS", function(panel)
    local fpsLabel = UI_Label(panel,L("LABEL_FPS")..": ...",false)
    local memLabel = UI_Label(panel,L("LABEL_MEM")..": ... KB",false)
    local pingLabel = UI_Label(panel,L("LABEL_PING")..": ... ms",false)
    local playerCount = UI_Label(panel,L("LABEL_PLAYERS")..": ...",false)
    Core.API_AddMetricsObserver(function(m)
        fpsLabel.Text = L("LABEL_FPS")..": "..m.fps
        memLabel.Text = L("LABEL_MEM")..": "..m.mem.." KB"
        pingLabel.Text = L("LABEL_PING")..": "..m.ping.." ms"
        playerCount.Text = L("LABEL_PLAYERS")..": "..m.players
    end)
end)

-- Extras Panel
Core.API_RegisterLazyPanel("PANEL_EXTRAS", function(panel)
    UI_Toggle(panel,"TOGGLE_OVERLAY","overlay_visible",Core._state.overlayVisible,function(on)
        Core._state.overlayVisible = on
        if UI._perfOverlay then UI._perfOverlay.Visible = on end
    end)
    UI_Slider(panel,"SLIDER_OVERLAY_INTERVAL","overlay_interval",0.2,5,Persist.get("overlay_interval",1),0.1,function(v)
        Persist.setIfChanged("overlay_interval", v)
    end)
    UI_Button(panel,"BTN_OVERLAY_RESET",true,function()
        if UI._perfOverlay then
            UI._perfOverlay.Position = UDim2.new(1,-210,0,10)
            Persist.set("overlay_pos",{sx=1,x=-210,sy=0,y=10})
        end
    end)

    -- Noclip
    local noclipConn, noclipCharConn
    local storedCollision = {}
    local function applyNoclip(char)
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if storedCollision[part]==nil then storedCollision[part]=part.CanCollide end
                part.CanCollide=false
            end
        end
    end
    Core._noclipDisable = function()
        if noclipConn then noclipConn:Disconnect() noclipConn=nil end
        if noclipCharConn then noclipCharConn:Disconnect() noclipCharConn=nil end
        for part,orig in pairs(storedCollision) do
            if part and part.Parent then
                part.CanCollide = orig
            end
        end
        storedCollision = {}
        Core._noclipActive = false
    end
    UI_Toggle(panel,"TOGGLE_NOCLIP","extra_noclip",false,function(on)
        if on then
            storedCollision={}
            applyNoclip(LocalPlayer.Character)
            noclipConn = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _,part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if storedCollision[part]==nil then storedCollision[part]=part.CanCollide end
                            part.CanCollide=false
                        end
                    end
                end
            end)
            noclipCharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                task.wait(0.25)
                applyNoclip(newChar)
            end)
            Core._noclipActive = true
        else
            Core._noclipDisable()
        end
    end)

    -- Positions
    UI_Label(panel,"SECTION_POSITIONS",true)
    local savedPositions = Persist.get("saved_positions",{})
    local function savePositions() Persist.set("saved_positions", savedPositions) end
    local coordsLabel = UI_Label(panel, L("LABEL_POS_ATUAL")..": ...", false)
    RunService.Heartbeat:Connect(function()
        local root = Util.getRoot()
        if root then
            local p = root.Position
            coordsLabel.Text = string.format("%s: (%.1f, %.1f, %.1f)", L("LABEL_POS_ATUAL"), p.X, p.Y, p.Z)
        end
    end)
    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1,0,0,0)
    listFrame.AutomaticSize = Enum.AutomaticSize.Y
    listFrame.BackgroundTransparency = 1
    listFrame.Parent = panel
    local lfLayout = Instance.new("UIListLayout", listFrame)
    lfLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lfLayout.Padding = UDim.new(0,4)

    local function rebuildPosList()
        for _, c in ipairs(listFrame:GetChildren()) do
            if c:IsA("TextButton") or c.Name=="EmptyLabel" then c:Destroy() end
        end
        if #savedPositions == 0 then
            local lbl = UI_Label(listFrame, (Lang.current=="pt") and "Nenhuma posição salva." or "No saved positions.", false)
            lbl.Name="EmptyLabel"
        end
        for i,data in ipairs(savedPositions) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1,0,0,26)
            btn.BackgroundColor3 = Themes._current.accent
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            btn.Text = i..": ("..math.floor(data.x)..","..math.floor(data.y)..","..math.floor(data.z)..") [TP]"
            btn.Parent = listFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
            Themes.register(btn,"accent")
            btn.MouseButton1Click:Connect(function()
                local root = Util.getRoot()
                if root then
                    root.CFrame = CFrame.new(data.x,data.y,data.z)
                    Core.addTPHistory(root.Position)
                end
            end)
            btn.MouseButton2Click:Connect(function()
                table.remove(savedPositions, i)
                savePositions()
                rebuildPosList()
            end)
        end
    end
    rebuildPosList()
    UI_Button(panel,"BTN_SAVE_POS",true,function()
        if #savedPositions >= 5 then
            notify("Pos", L("NOTIFY_POS_LIMIT"))
            return
        end
        local root = Util.getRoot()
        if not root then notify("Pos", L("NOTIFY_NO_ROOT")) return end
        local p = root.Position
        table.insert(savedPositions,{x=p.X,y=p.Y,z=p.Z})
        savePositions()
        rebuildPosList()
        notify("Pos", L("NOTIFY_POS_SAVED"))
    end)
    UI_Button(panel,"BTN_CLEAR_POS",true,function()
        savedPositions={}
        savePositions()
        rebuildPosList()
    end)
    if typeof(setclipboard)=="function" then
        UI_Button(panel,"BTN_COPY_POS",true,function()
            local root = Util.getRoot()
            if root then
                local p = root.Position
                setclipboard(string.format("%.2f, %.2f, %.2f", p.X,p.Y,p.Z))
                notify("Pos", L("NOTIFY_POS_COPIED"))
            end
        end)
    end

    -- Ambience
    UI_Label(panel,"SECTION_AMBIENCE",true)
    local applyLighting=false
    local originalTime = Lighting.ClockTime
    local desiredTime = Persist.get("world_time_value", Lighting.ClockTime)
    UI_Slider(panel,"SLIDER_WORLD_TIME","world_time_value",0,24,desiredTime,0.25,function(v)
        desiredTime = v
        if applyLighting then Lighting.ClockTime = desiredTime end
    end)
    Core._customTimeDisable = function()
        applyLighting=false
        Lighting.ClockTime = originalTime
    end
    UI_Toggle(panel,"TOGGLE_WORLD_TIME","world_time_apply",false,function(on)
        applyLighting = on
        if on then
            originalTime = Lighting.ClockTime
            Lighting.ClockTime = desiredTime
        else
            Lighting.ClockTime = originalTime
        end
    end)
end)

-- Fly Panel (modernizado 0.9.1)
Core.API_RegisterLazyPanel("PANEL_FLY", function(panel)
    UI_Label(panel,"LEGACY_FLY_NOTE",true)
    local active=false
    local speed = 60
    local flight = {
        mode = "modern",
        lv = nil,
        ao = nil,
        att = nil,
        bodyVel = nil
    }

    local function cleanup()
        if flight.lv then flight.lv:Destroy() flight.lv=nil end
        if flight.ao then flight.ao:Destroy() flight.ao=nil end
        if flight.att then flight.att:Destroy() flight.att=nil end
        if flight.bodyVel then flight.bodyVel:Destroy() flight.bodyVel=nil end
    end

    local function enableFly()
        if active then return end
        local root = Util.getRoot()
        if not root then return end
        local ok = pcall(function()
            flight.att = Instance.new("Attachment")
            flight.att.Name = "UU_FlyAtt"
            flight.att.Parent = root
            flight.lv = Instance.new("LinearVelocity")
            flight.lv.Attachment0 = flight.att
            flight.lv.MaxForce = 1e7
            flight.lv.VectorVelocity = Vector3.zero
            flight.lv.Parent = root
            flight.ao = Instance.new("AlignOrientation")
            flight.ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
            flight.ao.Attachment0 = flight.att
            flight.ao.Responsiveness = 50
            flight.ao.Parent = root
        end)
        if not ok then
            cleanup()
            flight.mode = "legacy"
            flight.bodyVel = Instance.new("BodyVelocity")
            flight.bodyVel.MaxForce = Vector3.new(1e5,1e5,1e5)
            flight.bodyVel.Velocity = Vector3.zero
            flight.bodyVel.Parent = root
        end
        active = true
        Core._flyActive = true
    end
    local function disableFly()
        cleanup()
        active=false
        Core._flyActive = false
    end
    Core._flyDisable = disableFly
    Core.API_RegisterKeybind("flyToggle", Enum.KeyCode.G, function()
        if active then disableFly() else enableFly() end
    end)

    Core.Bind("FlyHeartbeat", RunService.Heartbeat:Connect(function()
        if not active then return end
        local hum = Util.getHumanoid()
        local root = Util.getRoot()
        local cam = workspace.CurrentCamera
        if not (hum and root and cam) then return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        if flight.mode == "modern" and flight.lv then
            flight.lv.VectorVelocity = dir * (dir.Magnitude>0 and speed or 0)
            if flight.ao then
                flight.ao.CFrame = CFrame.lookAt(root.Position, root.Position + cam.CFrame.LookVector)
            end
        elseif flight.mode == "legacy" and flight.bodyVel then
            flight.bodyVel.Velocity = dir * (dir.Magnitude>0 and speed or 0)
        end
    end))

    UI_Button(panel,"BTN_FLY_SPEEDMODE",true,function()
        speed = speed + 10
        notify("Fly","Speed "..speed)
    end)
end)

-- Sprint Panel
Core.API_RegisterLazyPanel("PANEL_SPRINT", function(panel)
    UI_Toggle(panel,"TOGGLE_SPRINT","sprint_enabled",Core._state.autoSprint,function(on)
        Core._state.autoSprint=on
    end)
    UI_Toggle(panel,"TOGGLE_SPRINT_HOLD","sprint_hold_mode",Core._state.sprintHolding,function(on)
        Core._state.sprintHolding=on
    end)
    UI_Slider(panel,"SLIDER_SPRINT_BONUS","sprint_bonus",1,32,Core._state.sprintBonus,1,function(v)
        Core._state.sprintBonus = v
    end)
    UI_Slider(panel,"SLIDER_SPRINT_HOLD","sprint_hold_time",0,2,Core._state.sprintHoldTime,0.05,function(v)
        Core._state.sprintHoldTime = v
    end)
end)

-- Profiles Panel
Core.API_RegisterLazyPanel("PANEL_PROFILES", function(panel)
    for i=1,3 do
        UI_Button(panel,"Profile "..i.." Save",false,function() Profiles.save(i) end)
        UI_Button(panel,"Profile "..i.." Load",false,function() Profiles.load(i) end)
    end
end)

-- Theme Panel
Core.API_RegisterLazyPanel("PANEL_THEME", function(panel)
    UI_Button(panel,"Dark",false,function() Themes.apply("dark") end)
    UI_Button(panel,"Light",false,function() Themes.apply("light") end)
end)

-- Debug Panel
Core.API_RegisterLazyPanel("PANEL_DEBUG", function(panel)
    UI_Label(panel,"SECTION_LOGGER",true)
    local box = Instance.new("TextLabel")
    box.Size = UDim2.new(1,0,0,150)
    box.AutomaticSize = Enum.AutomaticSize.None
    box.BackgroundColor3 = Themes._current.panel
    box.Font = Enum.Font.Code
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.TextWrapped = false
    box.Text = table.concat(Logger._lines,"\n")
    box.Parent = panel
    box.ClipsDescendants = true
    Themes.register(box,"panel")

    -- [v0.9.1] Atualiza somente quando logger._dirty
    Core.Bind("LoggerUpdate", RunService.Heartbeat:Connect(function()
        if Logger._dirty then
            Logger._dirty = false
            box.Text = table.concat(Logger._lines,"\n")
        end
    end))
    UI_Button(panel,"Export Logs",false,function()
        Logger.Export()
        notify("Logger", L("LOGGER_EXPORTED"))
    end)
    UI_Label(panel,"PANEL_LANG_MISSING",true)
    local missingList = {}
    local used = {}
    for _, t in ipairs(UI._translatables) do
        used[t.key] = true
    end
    for key,_ in pairs(used) do
        if not Lang.data[Lang.current][key] then
            table.insert(missingList, key)
        end
    end
    if #missingList==0 then
        UI_Label(panel,"MISSING_NONE",true)
    else
        for _,k in ipairs(missingList) do
            UI_Label(panel,k,false)
        end
    end
end)

-- Missing Keys Panel
Core.API_RegisterLazyPanel("PANEL_LANG_MISSING", function(panel)
    local missingList = {}
    local used = {}
    for _, t in ipairs(UI._translatables) do used[t.key]=true end
    for k,_ in pairs(used) do
        if not Lang.data[Lang.current][k] then table.insert(missingList,k) end
    end
    if #missingList==0 then
        UI_Label(panel,"MISSING_NONE",true)
    else
        for _,k in ipairs(missingList) do
            UI_Label(panel,k,false)
        end
    end
end)

-- Perf Overlay
local function buildPerfOverlay()
    local sg = Instance.new("ScreenGui")
    sg.Name = "UU_Overlay"
    sg.ResetOnSpawn = false
    pcall(function() sg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    local box = Instance.new("TextLabel")
    box.Size = UDim2.new(0, 200, 0, 90)
    box.Position = UDim2.new(1, -210, 0, 10)
    box.BackgroundColor3 = Themes._current.header
    box.TextColor3 = Themes._current.text
    box.Font = Enum.Font.Code
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.Text = "..."
    box.Parent = sg
    Util.draggable(box, box, function(pos)
        Persist.set("overlay_pos",{sx=pos.X.Scale,x=pos.X.Offset,sy=pos.Y.Scale,y=pos.Y.Offset})
    end)
    Themes.register(box,"header","BackgroundColor3")
    Themes.register(box,"text","TextColor3")
    local op = Persist.get("overlay_pos", nil)
    if op then
        box.Position = UDim2.new(op.sx or 1, op.x or -210, op.sy or 0, op.y or 10)
    end
    box.Visible = Core._state.overlayVisible
    UI._perfOverlay = box
end

-- ==== Inicialização ====
ensureLanguage(function()
    UI.createRoot()
    local order = {
        "PANEL_GENERAL","PANEL_MOVEMENT","PANEL_CAMERA","PANEL_STATS",
        "PANEL_SPRINT","PANEL_PROFILES","PANEL_KEYBINDS","PANEL_THEME",
        "PANEL_EXTRAS","PANEL_FLY","PANEL_DEBUG","PANEL_LANG_MISSING"
    }
    Core.API_RegisterLazyPanel("PANEL_KEYBINDS", function(panel)
        for name,code in pairs(KeybindManager.list) do
            UI_Label(panel, name..": "..code, false)
        end
        UI_Button(panel,"Edit Keybind",false,function()
            notify("Keybinds", "/uu keybind <name>")
        end)
    end)
    for _,k in ipairs(order) do
        UI.buildPanelButton(k)
    end
    buildPerfOverlay()
    Themes.apply(Core._state.theme or "dark")
    UI.applyLanguage()
    notify("Universal Utility", L("NOTIFY_LOADED", VERSION), 4)
end)

-- Background flush loop
task.spawn(function()
    while true do
        Persist.flush(false)
        task.wait(0.2)
    end
end)

return {
    Core = Core,
    UI = UI,
    Util = Util,
    Persist = Persist,
    Lang = Lang,
    Themes = Themes,
    Logger = Logger
}