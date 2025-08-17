--[[
Universal Hub v2.0.0
Author: Eduardo854832 (Refatoração ampliada solicitada)
Grande atualização:
  * Arquitetura de FeatureRegistry (registro dinâmico de recursos)
  * Categorias dinâmicas: Movimento, Teleporte, Visual, Utilidades, Dev, Scripts
  * Hotkeys configuráveis + persistência
  * Sistema de sliders / toggles / ações modular
  * Fly (modo 3D sempre ativo) integrado à arquitetura
  * Recursos iniciais implementados (versões básicas):
      - Movimento: Fly, Noclip, WalkSpeed, JumpPower, Sprint (Shift), Gravity, High Jump
      - Teleporte: Teleport Player, Waypoints (Add/Tp/Del), Rejoin, Server Hop (simples)
      - Visual: FOV, Freecam, ESP básico (Billboard + distância), Highlights, ESP Distance
      - Utilidades: Anti-AFK, Chat Notify, Logger UI, Theme (Dark/Light), Disable All
      - Dev: Explorer simples, Property Viewer, Remote Spy (stub), Stats
      - Scripts: Infinite Yield loader, Auto Exec list (Add/Run/Del)
  * Persistência de: toggles, sliders, hotkeys, waypoints, scripts, tema
  * Botão “Disable All” restaurando ambiente
  * Internacionalização pt/en expandida (fallback en)
  * EventBus simples (HubEvent)
  * Limpeza adequada de conexões por feature

DISCLAIMER:
  - Algumas funções dependem de permissões do executor (Remote Spy, Drawing API para linhas ESP, copiar para clipboard etc.)
  - Server Hop usa requisições HTTP públicas; pode falhar em jogos privativos.
  - Código focado em estrutura base; pode ajustar estilos / otimizar depois.

]]--

----------------------------------------------------------------
-- GUARD
----------------------------------------------------------------
if _G.__UNIVERSAL_HUB_ALREADY then
    warn("[UniversalHub] Já carregado. Abortando segunda carga.")
    return _G.__UNIVERSAL_HUB_EXPORTS
end
_G.__UNIVERSAL_HUB_ALREADY = true

local VERSION = "2.0.0"

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local CONFIG = {
    WINDOW_WIDTH = 640,
    WINDOW_HEIGHT = 360,
    TOPBAR_HEIGHT = 34,
    PADDING = 12,
    UI_SCALE = 1.0,
    FONT_MAIN_SIZE = 14,
    FONT_LABEL_SIZE = 12,
    MINI_BUTTON_SIZE = 46,
    MINI_START_POS = UDim2.new(0, 24, 0.4, 0),
    WATERMARK = "Eduardo854832",
    ENABLE_WATERMARK_WATCH = true,
    WATERMARK_CHECK_INTERVAL = {min=2.5,max=3.6},

    -- Fly tuning
    FLY_DEFAULT_SPEED = 50,
    FLY_MIN_SPEED = 5,
    FLY_MAX_SPEED = 500,
    FLY_SMOOTHNESS = 0.25,
    FLY_VERTICAL_SCALE = 1.0,
    FLY_MIN_PITCH_TO_LIFT = 0.05,

    HOTKEY_TOGGLE_MENU = Enum.KeyCode.RightShift,
    HOTKEY_FLY = Enum.KeyCode.F,

    DEFAULT_THEME = "dark",

    SPRINT_MULT_DEFAULT = 2.0,
    SPRINT_MULT_MIN = 1.1,
    SPRINT_MULT_MAX = 5.0,

    WALK_SPEED_MIN = 4,
    WALK_SPEED_MAX = 200,
    WALK_SPEED_DEFAULT = 16,

    JUMP_POWER_MIN = 25,
    JUMP_POWER_MAX = 200,
    JUMP_POWER_DEFAULT = 50,

    GRAVITY_MIN = 10,
    GRAVITY_MAX = 400,
    GRAVITY_DEFAULT = 196.2,

    FOV_MIN = 40,
    FOV_MAX = 120,
    FOV_DEFAULT = 70,

    ESP_DISTANCE_MIN = 20,
    ESP_DISTANCE_MAX = 2000,
    ESP_DISTANCE_DEFAULT = 500,

    HIGH_JUMP_FORCE = 80,

    WAYPOINT_LIMIT = 40,
    AUTO_AFK_INTERVAL = 55,

    SERVER_LIST_MAX = 50,
    REMOTE_SPY_MAX = 200,
}

-- Theme Palettes
local THEMES = {
    dark = {
        BG_MAIN = Color3.fromRGB(25,25,32),
        BG_TOP  = Color3.fromRGB(38,38,50),
        BG_LEFT = Color3.fromRGB(30,30,40),
        BG_RIGHT= Color3.fromRGB(32,32,44),
        BTN     = Color3.fromRGB(52,52,60),
        BTN_HOVER = Color3.fromRGB(66,66,76),
        BTN_ACTIVE= Color3.fromRGB(90,140,255),
        BTN_DANGER= Color3.fromRGB(120,55,55),
        BTN_MINI  = Color3.fromRGB(40,48,62),
        SLIDER_BG = Color3.fromRGB(60,60,72),
        SLIDER_FILL=Color3.fromRGB(90,140,255),
        SLIDER_KNOB= Color3.fromRGB(200,200,220),
        TEXT_DIM  = Color3.fromRGB(180,180,190),
        TEXT_SUB  = Color3.fromRGB(150,150,160),
        ACCENT    = Color3.fromRGB(90,140,255),
    },
    light = {
        BG_MAIN = Color3.fromRGB(235,235,241),
        BG_TOP  = Color3.fromRGB(215,215,225),
        BG_LEFT = Color3.fromRGB(230,230,238),
        BG_RIGHT= Color3.fromRGB(238,238,245),
        BTN     = Color3.fromRGB(200,205,218),
        BTN_HOVER = Color3.fromRGB(185,190,204),
        BTN_ACTIVE= Color3.fromRGB(90,140,255),
        BTN_DANGER= Color3.fromRGB(200,80,80),
        BTN_MINI  = Color3.fromRGB(180,185,198),
        SLIDER_BG = Color3.fromRGB(190,195,208),
        SLIDER_FILL=Color3.fromRGB(90,140,255),
        SLIDER_KNOB= Color3.fromRGB(80,80,90),
        TEXT_DIM  = Color3.fromRGB(40,40,50),
        TEXT_SUB  = Color3.fromRGB(70,70,80),
        ACCENT    = Color3.fromRGB(90,140,255),
    }
}

local CURRENT_THEME_NAME = CONFIG.DEFAULT_THEME
local COLORS = THEMES[CURRENT_THEME_NAME]

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local StarterGui       = game:GetService("StarterGui")
local TeleportService  = game:GetService("TeleportService")
local CoreGui          = game:GetService("CoreGui")
local Stats            = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------
-- UTIL
----------------------------------------------------------------
local function safeParent(gui)
    pcall(function()
        local parent = (gethui and gethui()) or CoreGui
        gui.Parent = parent
    end)
end

local function notify(title,text,dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=tostring(title),Text=tostring(text),Duration=dur or 3})
    end)
end

local function scale(n) return n * CONFIG.UI_SCALE end
local function clamp(v,a,b) return math.clamp(v,a,b) end

local function safeHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildWhichIsA("Humanoid") or nil
end
local function safeRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart") or nil
end

local function deepCopy(t)
    if type(t)~="table" then return t end
    local r={}
    for k,v in pairs(t) do r[k]=deepCopy(v) end
    return r
end

----------------------------------------------------------------
-- PERSIST
----------------------------------------------------------------
local Persist = {}
Persist._fileName = "UniversalUtilityConfigV2.json"
Persist._data = {}
Persist._dirty = false
Persist._lastWrite = 0
Persist._flushInterval = 2
local hasFS = (typeof(isfile)=="function" and typeof(readfile)=="function" and typeof(writefile)=="function")

function Persist.load()
    if hasFS and isfile(Persist._fileName) then
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(Persist._fileName))
        end)
        if ok and type(decoded)=="table" then
            Persist._data = decoded
        end
    end
end
function Persist.flush(force)
    if not hasFS then return end
    if not force then
        if not Persist._dirty then return end
        if (time() - Persist._lastWrite) < Persist._flushInterval then return end
    end
    Persist._lastWrite = time()
    Persist._dirty=false
    pcall(function()
        writefile(Persist._fileName, HttpService:JSONEncode(Persist._data))
    end)
end
function Persist.get(k,def)
    local v=Persist._data[k]
    if v==nil and def~=nil then
        Persist._data[k]=def
        Persist._dirty=true
        return def
    end
    return v
end
function Persist.set(k,v)
    if Persist._data[k] ~= v then
        Persist._data[k]=v
        Persist._dirty=true
    end
end
Persist.load()
task.spawn(function()
    while true do
        Persist.flush(false)
        task.wait(0.5)
    end
end)

----------------------------------------------------------------
-- LOGGER
----------------------------------------------------------------
local Logger = { _max=400, _lines={} }
function Logger.Log(level,msg)
    local line = os.date("%H:%M:%S").." ["..level.."] "..tostring(msg)
    table.insert(Logger._lines,line)
    if #Logger._lines > Logger._max then table.remove(Logger._lines,1) end
    warn("[UH]["..level.."] "..tostring(msg))
end

----------------------------------------------------------------
-- EVENT BUS
----------------------------------------------------------------
local HubEvent = {}
HubEvent._listeners = {}
function HubEvent.on(eventName, fn)
    HubEvent._listeners[eventName] = HubEvent._listeners[eventName] or {}
    table.insert(HubEvent._listeners[eventName], fn)
    return {
        Disconnect = function()
            local list = HubEvent._listeners[eventName]
            if not list then return end
            for i,v in ipairs(list) do
                if v==fn then table.remove(list,i) break end
            end
        end
    }
end
function HubEvent.fire(eventName,...)
    local list = HubEvent._listeners[eventName]
    if list then
        for _,fn in ipairs(list) do
            local ok,err=pcall(fn,...)
            if not ok then Logger.Log("EVENT_ERR", err) end
        end
    end
end

----------------------------------------------------------------
-- LANG
----------------------------------------------------------------
local Lang = {}
Lang.data = {
    pt = {
        UI_TITLE="Universal Hub v%s",
        MINI_HANDLE="≡",
        LOADED="Carregado v%s",
        BTN_CLOSE="Fechar",
        BTN_MINIMIZE="Minimizar",
        MENU_TOGGLED="Menu alternado",
        CLOSE_INFO="Interface destruída. Use novamente o script.",
        POSITION_SAVED="Posição salva",
        LANG_SELECT_TITLE="Selecione o Idioma",
        LANG_PT="Português",
        LANG_EN="English",
        WATERMARK_ALERT="Watermark alterada/removida.",
        FLOAT_TIP="Clique para abrir",

        CATEGORY_MOVEMENT="Movimento",
        CATEGORY_TELEPORT="Teleporte",
        CATEGORY_VISUAL="Visual",
        CATEGORY_UTIL="Utilidades",
        CATEGORY_DEV="Dev",
        CATEGORY_SCRIPTS="Scripts",

        DISABLE_ALL="Desativar Tudo",
        THEME="Tema",
        THEME_DARK="Escuro",
        THEME_LIGHT="Claro",
        HOTKEY_SET="Atalho",
        HOTKEY_PRESS_KEY="Pressione uma tecla...",
        FEATURE_UNSUPPORTED="Recurso não suportado neste executor.",

        -- Movement
        FLY="Voo",
        NOCLIP="Noclip",
        WALK_SPEED="Velocidade",
        JUMP_POWER="Pulo",
        SPRINT="Sprint",
        SPRINT_MULT="Multiplicador Sprint",
        GRAVITY="Gravidade",
        HIGH_JUMP="Pulo Alto",
        HIGH_JUMP_DONE="Pulo alto aplicado",
        PROTECTION_SPEED="Proteção Velocidade",
        PROTECTION_ON="Proteção ON",
        PROTECTION_OFF="Proteção OFF",

        -- Teleport
        TELEPORT_PLAYER="Teleporte Jogador",
        WAYPOINTS="Waypoints",
        ADD_WAYPOINT="Adicionar WP",
        TP="TP",
        DELETE="Excluir",
        REJOIN="Reentrar",
        SERVER_HOP="Server Hop",
        WAYPOINT_ADDED="Waypoint adicionado",
        WAYPOINT_REMOVED="Waypoint removido",
        WAYPOINT_TP="Teletransportado",
        REJOINING="Reentrando...",
        SERVER_HOPPING="Trocando de servidor...",

        -- Visual
        FOV="FOV",
        FREECAM="Freecam",
        ESP="ESP",
        HIGHLIGHTS="Highlights",
        ESP_DISTANCE="Distância ESP",

        -- Util
        ANTI_AFK="Anti-AFK",
        CHAT_NOTIFY="Aviso de Chat",
        LOGGER="Logs",
        CLEAR="Limpar",
        PLAYER_JOINED="%s entrou",
        PLAYER_LEFT="%s saiu",

        -- Dev
        EXPLORER="Explorer",
        PROPERTY_VIEWER="Propriedades",
        REMOTE_SPY="Remote Spy",
        REMOTE_FILTER="Filtro",
        STATS="Estatísticas",

        -- Scripts
        AUTO_EXEC="Auto Exec",
        ADD_SCRIPT="Add Script",
        RUN="Executar",
        FAVORITES="Favoritos",
        SCRIPT_ADDED="Script adicionado",
        SCRIPT_REMOVED="Script removido",
        IY_LOAD="Carregar IY",
        IY_LOADING="Carregando IY...",
        IY_LOADED="IY carregado.",
        IY_ALREADY="IY já carregado.",
        IY_FAILED="Falha IY: %s",

        -- Generic / statuses
        ON="ON",
        OFF="OFF",
        ENABLE="Ligar",
        DISABLE="Desligar",
        SPEED_SET="Velocidade = %d",
        VALUE="Valor",
        ENTER_NAME="Nome...",
        ENTER_CODE="Código ou URL...",
    },
    en = {
        UI_TITLE="Universal Hub v%s",
        MINI_HANDLE="≡",
        LOADED="Loaded v%s",
        BTN_CLOSE="Close",
        BTN_MINIMIZE="Minimize",
        MENU_TOGGLED="Menu toggled",
        CLOSE_INFO="UI destroyed. Re-run script to open.",
        POSITION_SAVED="Position saved",
        LANG_SELECT_TITLE="Select Language",
        LANG_PT="Português",
        LANG_EN="English",
        WATERMARK_ALERT="Watermark changed/removed.",
        FLOAT_TIP="Click to open",

        CATEGORY_MOVEMENT="Movement",
        CATEGORY_TELEPORT="Teleport",
        CATEGORY_VISUAL="Visual",
        CATEGORY_UTIL="Utilities",
        CATEGORY_DEV="Dev",
        CATEGORY_SCRIPTS="Scripts",

        DISABLE_ALL="Disable All",
        THEME="Theme",
        THEME_DARK="Dark",
        THEME_LIGHT="Light",
        HOTKEY_SET="Hotkey",
        HOTKEY_PRESS_KEY="Press a key...",
        FEATURE_UNSUPPORTED="Feature unsupported on this executor.",

        FLY="Fly",
        NOCLIP="Noclip",
        WALK_SPEED="WalkSpeed",
        JUMP_POWER="JumpPower",
        SPRINT="Sprint",
        SPRINT_MULT="Sprint Mult",
        GRAVITY="Gravity",
        HIGH_JUMP="High Jump",
        HIGH_JUMP_DONE="High jump applied",
        PROTECTION_SPEED="Speed Protection",
        PROTECTION_ON="Protection ON",
        PROTECTION_OFF="Protection OFF",

        TELEPORT_PLAYER="Teleport Player",
        WAYPOINTS="Waypoints",
        ADD_WAYPOINT="Add WP",
        TP="TP",
        DELETE="Delete",
        REJOIN="Rejoin",
        SERVER_HOP="Server Hop",
        WAYPOINT_ADDED="Waypoint added",
        WAYPOINT_REMOVED="Waypoint removed",
        WAYPOINT_TP="Teleported",
        REJOINING="Rejoining...",
        SERVER_HOPPING="Hopping server...",

        FOV="FOV",
        FREECAM="Freecam",
        ESP="ESP",
        HIGHLIGHTS="Highlights",
        ESP_DISTANCE="ESP Distance",

        ANTI_AFK="Anti-AFK",
        CHAT_NOTIFY="Chat Notify",
        LOGGER="Logs",
        CLEAR="Clear",
        PLAYER_JOINED="%s joined",
        PLAYER_LEFT="%s left",

        EXPLORER="Explorer",
        PROPERTY_VIEWER="Properties",
        REMOTE_SPY="Remote Spy",
        REMOTE_FILTER="Filter",
        STATS="Stats",

        AUTO_EXEC="Auto Exec",
        ADD_SCRIPT="Add Script",
        RUN="Run",
        FAVORITES="Favorites",
        SCRIPT_ADDED="Script added",
        SCRIPT_REMOVED="Script removed",
        IY_LOAD="Load IY",
        IY_LOADING="Loading IY...",
        IY_LOADED="IY loaded.",
        IY_ALREADY="IY already loaded.",
        IY_FAILED="IY failed: %s",

        ON="ON",
        OFF="OFF",
        ENABLE="Enable",
        DISABLE="Disable",
        SPEED_SET="Speed = %d",
        VALUE="Value",
        ENTER_NAME="Name...",
        ENTER_CODE="Code or URL...",
    }
}

Lang.current = Persist.get("lang", nil)
local activePack = Lang.current and Lang.data[Lang.current] or nil
local missingKeys = {}
local function setLanguage(code)
    if Lang.data[code] then
        Lang.current = code
        activePack = Lang.data[code]
        Persist.set("lang", code)
    end
end
local function L(key,...)
    local pack = activePack or Lang.data.en
    local s = pack[key] or Lang.data.en[key] or key
    if (not pack[key] and not Lang.data.en[key] and not missingKeys[key]) then
        missingKeys[key]=true
        Logger.Log("I18N","Missing key: "..key)
    end
    if select("#",...)>0 then return string.format(s,...) end
    return s
end

----------------------------------------------------------------
-- THEME SWITCH
----------------------------------------------------------------
local function setTheme(name)
    if not THEMES[name] then return end
    CURRENT_THEME_NAME = name
    COLORS = THEMES[name]
    Persist.set("theme", name)
    HubEvent.fire("themeChanged", name)
end
setTheme(Persist.get("theme", CONFIG.DEFAULT_THEME))

----------------------------------------------------------------
-- UI OBJECTS (Skeleton)
----------------------------------------------------------------
local UI = {
    Screen=nil,
    FloatingGui=nil,
    FloatingButton=nil,
    Destroyed=false,
    Elements = {
        CategoryButtons = {},
        FeatureContainer = nil,
        TopTitle = nil,
        LoggerText = nil,
    },
    Translatables = {}, -- {instance,key,args}
    CurrentCategory = "movement",
}

local function markTrans(instance,key,...)
    table.insert(UI.Translatables,{instance=instance,key=key,args={...}})
end

----------------------------------------------------------------
-- FEATURE REGISTRY
----------------------------------------------------------------
local Features = {}
local FeatureOrder = { -- category mapping to preserved order
    movement = {},
    teleport = {},
    visual = {},
    util = {},
    dev = {},
    scripts = {},
}

-- Helper registration
local function registerFeature(def)
    -- def: {
    --   id, category, nameKey, type = "toggle"/"slider"/"action"/"composite"
    --   enable(), disable(), update(dt), default, slider = {min,max,default}, hotkeyDefault
    --   get()/set() (optional override), persistent (bool), ephemeral (bool),
    --   onCharacterAdded(character), uiBuilder(custom builder)
    -- }
    if Features[def.id] then
        Logger.Log("WARN","Feature id duplicate: "..def.id)
    end
    def.state = false
    def._connections = {}
    def._objects = {}
    def.persistent = (def.persistent ~= false) -- default true
    Features[def.id] = def
    table.insert(FeatureOrder[def.category], def.id)

    -- load persisted state/value
    if def.type == "toggle" then
        local saved = Persist.get("feat_"..def.id, nil)
        if saved == true then
            -- defer enabling until after full init
            def._autoEnable = true
        end
    elseif def.type == "slider" then
        local saved = Persist.get("featval_"..def.id, def.slider and def.slider.default or def.default)
        def.value = tonumber(saved) or (def.slider and def.slider.default) or 0
    end
end

local function featureEnable(id, silent)
    local f = Features[id]; if not f or f.state then return end
    if f.enable then
        local ok,err = pcall(f.enable)
        if not ok then
            Logger.Log("ERR","Enable "..id.." failed: "..tostring(err))
            return
        end
    end
    f.state = true
    if f.type=="toggle" and f.persistent then
        Persist.set("feat_"..id, true)
    end
    HubEvent.fire("featureToggled", id, true)
    if not silent then Logger.Log("INFO","Feature ON: "..id) end
end

local function featureDisable(id, silent)
    local f = Features[id]; if not f or not f.state then return end
    if f.disable then
        local ok,err = pcall(f.disable)
        if not ok then
            Logger.Log("ERR","Disable "..id.." failed: "..tostring(err))
        end
    end
    f.state=false
    if f.type=="toggle" and f.persistent then
        Persist.set("feat_"..id, false)
    end
    HubEvent.fire("featureToggled", id, false)
    if not silent then Logger.Log("INFO","Feature OFF: "..id) end
end

local function featureToggle(id)
    local f=Features[id]; if not f then return end
    if f.state then featureDisable(id) else featureEnable(id) end
end

local function featureSetValue(id,val)
    local f=Features[id]; if not f or f.type~="slider" then return end
    val = clamp(val, f.slider.min, f.slider.max)
    f.value = val
    if f.set then
        local ok,err=pcall(function() f.set(val) end)
        if not ok then Logger.Log("ERR","Set slider "..id.." "..err) end
    end
    if f.persistent then
        Persist.set("featval_"..id, val)
    end
    HubEvent.fire("featureValueChanged", id, val)
end

----------------------------------------------------------------
-- HOTKEY SYSTEM
----------------------------------------------------------------
local Hotkeys = {} -- featureId -> keycode
local CapturingHotkeyFor = nil

local function loadHotkey(id, default)
    local saved = Persist.get("hotkey_"..id, nil)
    if saved and typeof(saved)=="string" then
        local enum = Enum.KeyCode[saved]
        if enum then
            Hotkeys[id] = enum
            return
        end
    end
    if default then
        Hotkeys[id] = default
    end
end

local function setHotkey(id, keyCode)
    if keyCode then
        Hotkeys[id] = keyCode
        Persist.set("hotkey_"..id, keyCode.Name)
    end
    HubEvent.fire("hotkeyChanged", id, keyCode)
end

----------------------------------------------------------------
-- FLY (adapt existing into Feature pattern)
----------------------------------------------------------------
local Fly = {
    speed = tonumber(Persist.get("fly_speed", CONFIG.FLY_DEFAULT_SPEED)) or CONFIG.FLY_DEFAULT_SPEED,
    _vel = Vector3.zero,
    full3D = true, -- always 3D
}

local function computeFlyDirection(hum,cam)
    local move = hum.MoveDirection
    if move.Magnitude==0 then return Vector3.zero end
    local cf = cam.CFrame
    local look = cf.LookVector
    local forwardFlat = Vector3.new(look.X,0,look.Z)
    if forwardFlat.Magnitude < 1e-4 then forwardFlat = Vector3.new(0,0,-1) else forwardFlat = forwardFlat.Unit end
    local rightFlat = Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
    local x = move:Dot(rightFlat)
    local z = move:Dot(forwardFlat)
    local dir = (rightFlat * x) + (forwardFlat * z)
    if Fly.full3D and math.abs(z) > 0.01 then
        local pitchY = look.Y
        if math.abs(pitchY) > CONFIG.FLY_MIN_PITCH_TO_LIFT then
            dir = dir + Vector3.new(0, pitchY * math.abs(z) * CONFIG.FLY_VERTICAL_SCALE, 0)
        end
    end
    if dir.Magnitude>0 then dir=dir.Unit else dir=Vector3.zero end
    return dir
end

----------------------------------------------------------------
-- GLOBAL STATE HELPERS (for restore)
----------------------------------------------------------------
local DefaultEnvironment = {
    Gravity = workspace.Gravity,
    FOV = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or CONFIG.FOV_DEFAULT,
    WalkSpeed = 16,
    JumpPower = 50,
    JumpHeight = 7.2,
}

local function recordDefaults()
    local hum = safeHumanoid()
    if hum then
        if hum.UseJumpPower ~= false then
            DefaultEnvironment.JumpPower = hum.JumpPower
        else
            DefaultEnvironment.JumpHeight = hum.JumpHeight
        end
        DefaultEnvironment.WalkSpeed = hum.WalkSpeed
    end
    if workspace.CurrentCamera then
        DefaultEnvironment.FOV = workspace.CurrentCamera.FieldOfView
    end
    DefaultEnvironment.Gravity = workspace.Gravity
end
recordDefaults()

local function restoreDefaults()
    local hum = safeHumanoid()
    if hum then
        pcall(function()
            hum.WalkSpeed = DefaultEnvironment.WalkSpeed or 16
            if hum.UseJumpPower ~= false then
                hum.JumpPower = DefaultEnvironment.JumpPower or 50
            else
                hum.JumpHeight = DefaultEnvironment.JumpHeight or 7.2
            end
        end)
    end
    if workspace.CurrentCamera then
        workspace.CurrentCamera.FieldOfView = DefaultEnvironment.FOV or CONFIG.FOV_DEFAULT
        workspace.CurrentCamera.CameraSubject = hum
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
    end
    workspace.Gravity = DefaultEnvironment.Gravity or 196.2
end

----------------------------------------------------------------
-- CENTRAL UPDATE LOOP (dispatch update(dt) to active features)
----------------------------------------------------------------
local ActiveUpdateFeatures = {}
HubEvent.on("featureToggled", function(id, state)
    local f=Features[id]
    if f and f.update then
        ActiveUpdateFeatures[id] = state and true or nil
    end
end)

RunService.Heartbeat:Connect(function(dt)
    for id,_ in pairs(ActiveUpdateFeatures) do
        local f=Features[id]
        if f and f.state and f.update then
            local ok,err=pcall(f.update, dt)
            if not ok then
                Logger.Log("ERR","Update "..id.." "..err)
            end
        end
    end
end)

----------------------------------------------------------------
-- FEATURE IMPLEMENTATIONS
----------------------------------------------------------------

-- MOVEMENT: Fly
registerFeature({
    id="fly",
    category="movement",
    nameKey="FLY",
    type="toggle",
    persistent=true,
    enable=function()
        -- nothing immediate; update loop handles velocity
    end,
    disable=function()
        local r=safeRoot()
        if r then
            if r.AssemblyLinearVelocity then
                r.AssemblyLinearVelocity = Vector3.zero
            else
                r.Velocity = Vector3.zero
            end
        end
        Fly._vel = Vector3.zero
    end,
    update=function(dt)
        local hum = safeHumanoid(); local r = safeRoot(); local cam = workspace.CurrentCamera
        if not hum or not r or not cam then return end
        local dir = computeFlyDirection(hum, cam)
        local targetVel = dir * Fly.speed
        if CONFIG.FLY_SMOOTHNESS > 0 then
            Fly._vel = Fly._vel:Lerp(targetVel, 1 - math.pow(1-CONFIG.FLY_SMOOTHNESS, math.clamp(dt*60,0,5)))
        else
            Fly._vel = targetVel
        end
        local vel = Fly._vel
        if r.AssemblyLinearVelocity then
            r.AssemblyLinearVelocity = vel
        else
            r.Velocity = vel
        end
    end,
})

loadHotkey("fly", CONFIG.HOTKEY_FLY)

-- Slider inside Fly for speed
registerFeature({
    id="fly_speed",
    category="movement",
    nameKey="SPEED_SET",
    type="slider",
    slider={min=CONFIG.FLY_MIN_SPEED,max=CONFIG.FLY_MAX_SPEED,default=Fly.speed},
    persistent=true,
    set=function(val)
        Fly.speed = val
        Persist.set("fly_speed", val)
        notify("Fly", L("SPEED_SET", val), 1.5)
    end
})

-- MOVEMENT: Noclip
registerFeature({
    id="noclip",
    category="movement",
    nameKey="NOCLIP",
    type="toggle",
    enable=function()
        -- just rely on update or stepped
        Features.noclip._connections.charConn = LocalPlayer.CharacterAdded:Connect(function()
            if Features.noclip.state then
                task.wait(0.5)
                featureEnable("noclip") -- re-run to ensure
            end
        end)
        Features.noclip._connections.loop = RunService.Stepped:Connect(function()
            if not Features.noclip.state then return end
            local char = LocalPlayer.Character
            if not char then return end
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end)
    end,
    disable=function()
        for _,c in pairs(Features.noclip._connections) do pcall(function() c:Disconnect() end) end
        Features.noclip._connections={}
        local char = LocalPlayer.Character
        if char then
            for _,p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=true end
            end
        end
    end
})
loadHotkey("noclip", Enum.KeyCode.RightControl)

-- MOVEMENT: WalkSpeed
registerFeature({
    id="walkspeed",
    category="movement",
    nameKey="WALK_SPEED",
    type="slider",
    slider={min=CONFIG.WALK_SPEED_MIN,max=CONFIG.WALK_SPEED_MAX,default=CONFIG.WALK_SPEED_DEFAULT},
    persistent=true,
    set=function(val)
        local hum=safeHumanoid()
        if hum then pcall(function() hum.WalkSpeed = val end) end
    end
})

-- MOVEMENT: Speed Protection
registerFeature({
    id="speed_protect",
    category="movement",
    nameKey="PROTECTION_SPEED",
    type="toggle",
    enable=function()
        Features.speed_protect._connections.loop = RunService.Heartbeat:Connect(function()
            local hum = safeHumanoid()
            if hum then
                local desired = Features.walkspeed.value or CONFIG.WALK_SPEED_DEFAULT
                if math.abs(hum.WalkSpeed - desired)>0.01 then
                    hum.WalkSpeed = desired
                end
            end
        end)
    end,
    disable=function()
        for _,c in pairs(Features.speed_protect._connections) do pcall(function() c:Disconnect() end) end
        Features.speed_protect._connections={}
    end
})

-- MOVEMENT: JumpPower slider
registerFeature({
    id="jumppower",
    category="movement",
    nameKey="JUMP_POWER",
    type="slider",
    slider={min=CONFIG.JUMP_POWER_MIN,max=CONFIG.JUMP_POWER_MAX,default=CONFIG.JUMP_POWER_DEFAULT},
    persistent=true,
    set=function(val)
        local hum=safeHumanoid()
        if hum then
            pcall(function()
                if hum.UseJumpPower ~= false then
                    hum.JumpPower = val
                else
                    -- convert approximate JumpHeight from JumpPower (rough)
                    hum.JumpHeight = val / 7
                end
            end)
        end
    end
})

-- MOVEMENT: Gravity slider (toggle not needed, slider acts immediate)
registerFeature({
    id="gravity",
    category="movement",
    nameKey="GRAVITY",
    type="slider",
    slider={min=CONFIG.GRAVITY_MIN,max=CONFIG.GRAVITY_MAX,default=CONFIG.GRAVITY_DEFAULT},
    persistent=true,
    set=function(val)
        workspace.Gravity = val
    end
})

-- MOVEMENT: Sprint (toggle logic + slider for multiplier)
registerFeature({
    id="sprint",
    category="movement",
    nameKey="SPRINT",
    type="toggle",
    enable=function()
        Features.sprint._state = { running=false }
        Features.sprint._connections.input1 = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == Enum.KeyCode.LeftShift then
                local hum = safeHumanoid()
                if hum then
                    Features.sprint._state.running=true
                    hum.WalkSpeed = (Features.walkspeed.value or hum.WalkSpeed) * (Features.sprint_mult.value or CONFIG.SPRINT_MULT_DEFAULT)
                end
            end
        end)
        Features.sprint._connections.input2 = UserInputService.InputEnded:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.LeftShift then
                local hum = safeHumanoid()
                Features.sprint._state.running=false
                if hum then
                    hum.WalkSpeed = Features.walkspeed.value or hum.WalkSpeed
                end
            end
        end)
    end,
    disable=function()
        for _,c in pairs(Features.sprint._connections) do pcall(function() c:Disconnect() end) end
        Features.sprint._connections={}
        local hum=safeHumanoid()
        if hum then
            hum.WalkSpeed = Features.walkspeed.value or 16
        end
    end
})

registerFeature({
    id="sprint_mult",
    category="movement",
    nameKey="SPRINT_MULT",
    type="slider",
    slider={min=CONFIG.SPRINT_MULT_MIN,max=CONFIG.SPRINT_MULT_MAX,default=CONFIG.SPRINT_MULT_DEFAULT},
    persistent=true,
    set=function(val)
        local hum=safeHumanoid()
        if hum and Features.sprint.state and Features.sprint._state and Features.sprint._state.running then
            hum.WalkSpeed = (Features.walkspeed.value or hum.WalkSpeed) * val
        end
    end
})

-- MOVEMENT: High Jump (action)
registerFeature({
    id="highjump",
    category="movement",
    nameKey="HIGH_JUMP",
    type="action",
    persistent=false,
    action=function()
        local r = safeRoot()
        if r then
            local vel = r.AssemblyLinearVelocity or r.Velocity
            local new = Vector3.new(vel.X, CONFIG.HIGH_JUMP_FORCE, vel.Z)
            pcall(function()
                if r.AssemblyLinearVelocity then
                    r.AssemblyLinearVelocity = new
                else
                    r.Velocity = new
                end
            end)
            notify("HighJump", L("HIGH_JUMP_DONE"), 1.5)
        end
    end
})

----------------------------------------------------------------
-- TELEPORT: Teleport Player (composite custom UI)
registerFeature({
    id="tp_player",
    category="teleport",
    nameKey="TELEPORT_PLAYER",
    type="composite",
    uiBuilder="tpPlayer" -- handled later
})

-- TELEPORT: Waypoints composite
registerFeature({
    id="waypoints",
    category="teleport",
    nameKey="WAYPOINTS",
    type="composite",
    uiBuilder="waypoints"
})

-- TELEPORT: Rejoin (action)
registerFeature({
    id="rejoin",
    category="teleport",
    nameKey="REJOIN",
    type="action",
    action=function()
        notify("Teleport", L("REJOINING"))
        task.spawn(function()
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end)
        end)
    end
})

-- TELEPORT: Server Hop (action)
registerFeature({
    id="serverhop",
    category="teleport",
    nameKey="SERVER_HOP",
    type="action",
    action=function()
        notify("Teleport", L("SERVER_HOPPING"))
        task.spawn(function()
            local pagesUrl = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
            local chosen = nil
            local ok,res = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(pagesUrl))
            end)
            if ok and res and res.data then
                for _,srv in ipairs(res.data) do
                    if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                        chosen = srv.id
                        break
                    end
                end
            end
            if chosen then
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen, LocalPlayer)
                end)
            else
                notify("ServerHop","No different server found",3)
            end
        end)
    end
})

----------------------------------------------------------------
-- VISUAL: FOV slider
registerFeature({
    id="fov",
    category="visual",
    nameKey="FOV",
    type="slider",
    slider={min=CONFIG.FOV_MIN,max=CONFIG.FOV_MAX,default=CONFIG.FOV_DEFAULT},
    set=function(val)
        if workspace.CurrentCamera then
            workspace.CurrentCamera.FieldOfView = val
        end
    end
})

-- VISUAL: Freecam
local FreecamState = {}
registerFeature({
    id="freecam",
    category="visual",
    nameKey="FREECAM",
    type="toggle",
    enable=function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        FreecamState.originSubject = cam.CameraSubject
        FreecamState.originType = cam.CameraType
        cam.CameraType = Enum.CameraType.Scriptable
        FreecamState.pos = cam.CFrame.Position
        FreecamState.rot = cam.CFrame - cam.CFrame.Position
        FreecamState.vel = Vector3.zero
        FreecamState.speedBase = 1
        Features.freecam._connections.rs = RunService.RenderStepped:Connect(function(dt)
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0,0,-1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0,0,1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move = move + Vector3.new(0,-1,0) end
            local speed = 40
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed *2 end
            if move.Magnitude>0 then move=move.Unit end
            local rotCF = FreecamState.rot
            local worldMove = (rotCF:VectorToWorldSpace(move))* speed * dt
            FreecamState.pos += worldMove

            -- Mouse look
            local delta = UserInputService:GetMouseDelta()
            local yaw = -delta.X * 0.0025
            local pitch = -delta.Y * 0.0025
            local yawCF = CFrame.Angles(0, yaw, 0)
            local pitchCF = CFrame.Angles(pitch,0,0)
            FreecamState.rot = yawCF * FreecamState.rot * pitchCF

            cam.CFrame = CFrame.new(FreecamState.pos) * FreecamState.rot
        end)
    end,
    disable=function()
        local cam=workspace.CurrentCamera
        if Features.freecam._connections.rs then Features.freecam._connections.rs:Disconnect() end
        Features.freecam._connections={}
        if cam then
            cam.CameraSubject = FreecamState.originSubject
            cam.CameraType = FreecamState.originType or Enum.CameraType.Custom
        end
    end
})
loadHotkey("freecam", Enum.KeyCode.G)

-- VISUAL: ESP toggle + distance slider + Highlights
local ESPState = {
    billboards = {},
    highlights = {},
}
local function clearESP()
    for _,gui in pairs(ESPState.billboards) do pcall(function() gui:Destroy() end) end
    ESPState.billboards = {}
    for _,h in pairs(ESPState.highlights) do pcall(function() h:Destroy() end) end
    ESPState.highlights = {}
end

registerFeature({
    id="esp_distance",
    category="visual",
    nameKey="ESP_DISTANCE",
    type="slider",
    slider={min=CONFIG.ESP_DISTANCE_MIN,max=CONFIG.ESP_DISTANCE_MAX,default=CONFIG.ESP_DISTANCE_DEFAULT},
    set=function(val)
        ESPState.maxDistance = val
    end
})
ESPState.maxDistance = Persist.get("featval_esp_distance", CONFIG.ESP_DISTANCE_DEFAULT)

registerFeature({
    id="esp",
    category="visual",
    nameKey="ESP",
    type="toggle",
    enable=function()
        Features.esp._connections.loop = RunService.Heartbeat:Connect(function()
            local cam = workspace.CurrentCamera
            if not cam then return end
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            for _,pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer then
                    local char = pl.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (myRoot and (myRoot.Position - root.Position).Magnitude) or 0
                        if dist <= (ESPState.maxDistance or CONFIG.ESP_DISTANCE_DEFAULT) then
                            -- ensure billboard
                            local bb = ESPState.billboards[pl]
                            if not bb then
                                bb = Instance.new("BillboardGui")
                                bb.Name = "UH_ESP"
                                bb.Size = UDim2.new(0,120,0,20)
                                bb.AlwaysOnTop=true
                                bb.Adornee=root
                                bb.StudsOffset=Vector3.new(0,3,0)
                                local tl = Instance.new("TextLabel")
                                tl.Size=UDim2.new(1,0,1,0)
                                tl.BackgroundTransparency=1
                                tl.Font=Enum.Font.GothamBold
                                tl.TextSize=14
                                tl.TextColor3=Color3.fromRGB(255,255,255)
                                tl.TextStrokeTransparency=0.5
                                tl.Text=pl.Name
                                tl.Name="Label"
                                tl.Parent=bb
                                bb.Parent = CoreGui
                                ESPState.billboards[pl]=bb
                            end
                            local label = bb:FindFirstChild("Label")
                            if label then
                                label.Text = pl.Name.." ["..math.floor(dist).."]"
                            end
                        else
                            if ESPState.billboards[pl] then
                                ESPState.billboards[pl]:Destroy()
                                ESPState.billboards[pl]=nil
                            end
                        end
                    end
                end
            end
            -- cleanup for players who left
            for pl,gui in pairs(ESPState.billboards) do
                if typeof(pl)~="Instance" or not pl.Parent then
                    gui:Destroy()
                    ESPState.billboards[pl]=nil
                end
            end
        end)
    end,
    disable=function()
        for _,c in pairs(Features.esp._connections) do pcall(function() c:Disconnect() end) end
        Features.esp._connections={}
        clearESP()
    end
})

registerFeature({
    id="highlights",
    category="visual",
    nameKey="HIGHLIGHTS",
    type="toggle",
    enable=function()
        Features.highlights._connections.loop = RunService.Heartbeat:Connect(function()
            for _,pl in ipairs(Players:GetPlayers()) do
                if pl ~= LocalPlayer then
                    local char = pl.Character
                    if char and not ESPState.highlights[pl] then
                        local h = Instance.new("Highlight")
                        h.Name="UH_Highlight"
                        h.FillTransparency=1
                        h.OutlineColor = COLORS.ACCENT
                        h.Parent = char
                        ESPState.highlights[pl]=h
                    end
                end
            end
            for pl,h in pairs(ESPState.highlights) do
                if typeof(pl)~="Instance" or not pl.Parent or not pl.Character then
                    h:Destroy()
                    ESPState.highlights[pl]=nil
                else
                    if not h.Parent then
                        h.Parent = pl.Character
                    end
                end
            end
        end)
    end,
    disable=function()
        for _,c in pairs(Features.highlights._connections) do pcall(function() c:Disconnect() end) end
        Features.highlights._connections={}
        for pl,h in pairs(ESPState.highlights) do pcall(function() h:Destroy() end) end
        ESPState.highlights={}
    end
})

----------------------------------------------------------------
-- UTIL: Anti-AFK
registerFeature({
    id="anti_afk",
    category="util",
    nameKey="ANTI_AFK",
    type="toggle",
    enable=function()
        local vu = nil
        pcall(function()
            if game:GetService("VirtualUser") then
                vu = game:GetService("VirtualUser")
            end
        end)
        Features.anti_afk._connections.loop = task.spawn(function()
            while Features.anti_afk.state do
                task.wait(CONFIG.AUTO_AFK_INTERVAL)
                if not Features.anti_afk.state then break end
                if vu then
                    pcall(function()
                        vu:CaptureController()
                        vu:ClickButton2(Vector2.new())
                    end)
                end
            end
        end)
    end,
    disable=function()
        -- loop ends naturally
    end
})

-- UTIL: Chat Notify (player join/leave)
registerFeature({
    id="chat_notify",
    category="util",
    nameKey="CHAT_NOTIFY",
    type="toggle",
    enable=function()
        Features.chat_notify._connections.added = Players.PlayerAdded:Connect(function(pl)
            notify("Join", L("PLAYER_JOINED", pl.Name))
        end)
        Features.chat_notify._connections.rem = Players.PlayerRemoving:Connect(function(pl)
            notify("Leave", L("PLAYER_LEFT", pl.Name))
        end)
    end,
    disable=function()
        for _,c in pairs(Features.chat_notify._connections) do pcall(function() c:Disconnect() end) end
        Features.chat_notify._connections={}
    end
})

-- UTIL: Logger composite (UI)
registerFeature({
    id="logger_panel",
    category="util",
    nameKey="LOGGER",
    type="composite",
    uiBuilder="logger"
})

-- UTIL: Theme toggle (action to cycle)
registerFeature({
    id="theme",
    category="util",
    nameKey="THEME",
    type="action",
    action=function()
        local new = (CURRENT_THEME_NAME=="dark") and "light" or "dark"
        setTheme(new)
        notify("Theme", "=> "..new, 1.5)
    end
})

-- UTIL: Disable All (action)
registerFeature({
    id="disable_all",
    category="util",
    nameKey="DISABLE_ALL",
    type="action",
    action=function()
        for id,f in pairs(Features) do
            if f.type=="toggle" and f.state then
                featureDisable(id,true)
            end
        end
        clearESP()
        restoreDefaults()
        notify("Hub","All features disabled",3)
        HubEvent.fire("refreshUI")
    end
})

----------------------------------------------------------------
-- DEV: Explorer + Property Viewer + Remote Spy + Stats
registerFeature({
    id="explorer",
    category="dev",
    nameKey="EXPLORER",
    type="composite",
    uiBuilder="explorer"
})
registerFeature({
    id="properties",
    category="dev",
    nameKey="PROPERTY_VIEWER",
    type="composite",
    uiBuilder="properties"
})
local RemoteSpyState = { logs={}, enabled=false, filter="" }
registerFeature({
    id="remote_spy",
    category="dev",
    nameKey="REMOTE_SPY",
    type="toggle",
    enable=function()
        RemoteSpyState.enabled=true
        -- Basic stub
        local supported = (hookmetamethod ~= nil)
        if not supported then
            notify("RemoteSpy", L("FEATURE_UNSUPPORTED"))
            return
        end
        -- Simple example hooking (risk: environment-specific)
        if not RemoteSpyState._hooked then
            local mt = getrawmetatable(game)
            setreadonly(mt,false)
            local old = mt.__namecall
            mt.__namecall = function(self,...)
                local method = getnamecallmethod()
                if RemoteSpyState.enabled and (method=="FireServer" or method=="InvokeServer") then
                    local args={...}
                    local name = self.Name
                    if RemoteSpyState.filter=="" or string.find(string.lower(name), string.lower(RemoteSpyState.filter),1,true) then
                        local entry = os.date("%H:%M:%S").." "..name.."."..method.."("..#args.." args)"
                        table.insert(RemoteSpyState.logs, entry)
                        if #RemoteSpyState.logs > CONFIG.REMOTE_SPY_MAX then
                            table.remove(RemoteSpyState.logs,1)
                        end
                    end
                end
                return old(self,...)
            end
            RemoteSpyState._hooked=true
            setreadonly(mt,true)
        end
    end,
    disable=function()
        RemoteSpyState.enabled=false
    end
})
registerFeature({
    id="stats",
    category="dev",
    nameKey="STATS",
    type="composite",
    uiBuilder="stats"
})

----------------------------------------------------------------
-- SCRIPTS: Infinite Yield loader, Auto Exec manager
registerFeature({
    id="infinite_yield",
    category="scripts",
    nameKey="IY_LOAD",
    type="action",
    action=function()
        if _G.__UH_IY_LOADED then
            notify("IY", L("IY_ALREADY"))
            return
        end
        notify("IY", L("IY_LOADING"))
        task.spawn(function()
            local ok,err = pcall(function()
                local src = game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
                if #src < 5000 then error("Too small") end
                loadstring(src)()
            end)
            if ok then
                _G.__UH_IY_LOADED=true
                notify("IY", L("IY_LOADED"))
            else
                notify("IY", L("IY_FAILED", tostring(err)))
            end
        end)
    end
})

registerFeature({
    id="auto_exec",
    category="scripts",
    nameKey="AUTO_EXEC",
    type="composite",
    uiBuilder="autoexec"
})

----------------------------------------------------------------
-- WAYPOINT & SCRIPTS PERSIST DATA
----------------------------------------------------------------
local Waypoints = Persist.get("waypoints_v2", {})
local function saveWaypoints()
    Persist.set("waypoints_v2", Waypoints)
end

local StoredScripts = Persist.get("stored_scripts_v2", {}) -- { {name=..., code=..., isURL=true/false} }
local function saveScripts()
    Persist.set("stored_scripts_v2", StoredScripts)
end

----------------------------------------------------------------
-- CHARACTER RESPAWN HANDLER
----------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.8)
    for id,f in pairs(Features) do
        if f.state and f.onCharacterAdded then
            pcall(f.onCharacterAdded, LocalPlayer.Character)
        end
    end
    -- Reapply speeds / etc
    local hum = safeHumanoid()
    if hum then
        if Features.walkspeed.value then hum.WalkSpeed = Features.walkspeed.value end
        if Features.jumppower.value then
            if hum.UseJumpPower ~= false then hum.JumpPower = Features.jumppower.value else hum.JumpHeight = Features.jumppower.value / 7 end
        end
    end
end)

----------------------------------------------------------------
-- UI CREATION
----------------------------------------------------------------
local function styleButton(btn, opts)
    btn.AutoButtonColor=false
    btn.TextColor3 = (CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.05,0.05,0.07)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = CONFIG.FONT_MAIN_SIZE
    btn.BackgroundColor3 = opts and opts.color or COLORS.BTN
    local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=btn
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = COLORS.BTN_HOVER
    end)
    btn.MouseLeave:Connect(function()
        local isActive = opts and opts.activeIndicator and opts.activeIndicator()
        if isActive then
            btn.BackgroundColor3 = COLORS.BTN_ACTIVE
        else
            btn.BackgroundColor3 = opts and opts.color or COLORS.BTN
        end
    end)
end

local function createToggleUI(parent, featureId)
    local f=Features[featureId]; if not f then return end
    local holder = Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,44)
    holder.BackgroundTransparency=1
    holder.Parent=parent

    local btn = Instance.new("TextButton")
    btn.Size=UDim2.new(0,160,1, -4)
    btn.Position=UDim2.new(0,0,0,2)
    btn.Text = L(f.nameKey).." ["..(f.state and L("ON") or L("OFF")).."]"
    btn.Parent=holder
    styleButton(btn,{activeIndicator=function() return f.state end})

    btn.MouseButton1Click:Connect(function()
        featureToggle(featureId)
        btn.Text = L(f.nameKey).." ["..(f.state and L("ON") or L("OFF")).."]"
        if f.id=="speed_protect" then
            notify("SpeedProtect", f.state and L("PROTECTION_ON") or L("PROTECTION_OFF"),1.5)
        end
    end)

    -- Hotkey button
    local hkBtn = Instance.new("TextButton")
    hkBtn.Size=UDim2.new(0,70,1,-4)
    hkBtn.Position=UDim2.new(0,170,0,2)
    hkBtn.Text = Hotkeys[featureId] and Hotkeys[featureId].Name or L("HOTKEY_SET")
    hkBtn.Parent=holder
    styleButton(hkBtn,{})
    hkBtn.MouseButton1Click:Connect(function()
        CapturingHotkeyFor = featureId
        hkBtn.Text = "..."
    end)
    HubEvent.on("hotkeyChanged", function(id,kc)
        if id==featureId then
            hkBtn.Text = kc and kc.Name or L("HOTKEY_SET")
        end
    end)

    return holder
end

local function createSliderUI(parent, featureId)
    local f=Features[featureId]; if not f then return end
    local holder = Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,70)
    holder.BackgroundTransparency=1
    holder.Parent=parent

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Size=UDim2.new(0.5,0,0,20)
    title.Position=UDim2.new(0,0,0,0)
    title.Font=Enum.Font.Gotham
    title.TextSize=CONFIG.FONT_LABEL_SIZE+2
    title.TextColor3=COLORS.TEXT_DIM
    title.Text = L(f.nameKey)..": "..tostring(f.value)
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=holder

    local barBg = Instance.new("Frame")
    barBg.Size=UDim2.new(0,190,0,10)
    barBg.Position=UDim2.new(0,0,0,26)
    barBg.BackgroundColor3=COLORS.SLIDER_BG
    barBg.Parent=holder
    Instance.new("UICorner",barBg).CornerRadius=UDim.new(0,5)

    local fill = Instance.new("Frame")
    fill.Size=UDim2.new(0,0,1,0)
    fill.BackgroundColor3=COLORS.SLIDER_FILL
    fill.Parent=barBg
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,5)

    local knob = Instance.new("Frame")
    knob.Size=UDim2.new(0,14,0,14)
    knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.BackgroundColor3=COLORS.SLIDER_KNOB
    knob.Position=UDim2.new(0,0,0.5,0)
    knob.Parent=barBg
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local box = Instance.new("TextBox")
    box.Size=UDim2.new(0,80,0,26)
    box.Position=UDim2.new(0,200,0,16)
    box.BackgroundColor3=COLORS.BTN
    box.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.05,0.05,0.07)
    box.Font=Enum.Font.Code
    box.PlaceholderText = tostring(f.value)
    box.Text=""
    box.TextSize=CONFIG.FONT_LABEL_SIZE
    box.ClearTextOnFocus=false
    box.Parent=holder
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,6)

    local function refresh()
        local v=f.value
        title.Text = L(f.nameKey)..": "..tostring(v)
        local alpha = (v - f.slider.min)/(f.slider.max - f.slider.min)
        alpha = clamp(alpha,0,1)
        fill.Size=UDim2.new(alpha,0,1,0)
        knob.Position=UDim2.new(alpha,0,0.5,0)
        box.PlaceholderText = tostring(v)
    end
    refresh()

    local dragging=false
    local function setFromX(px)
        local rel = (px - barBg.AbsolutePosition.X)/barBg.AbsoluteSize.X
        rel = clamp(rel,0,1)
        local val = f.slider.min + rel*(f.slider.max - f.slider.min)
        val = math.floor(val+0.5)
        featureSetValue(featureId,val)
        refresh()
    end
    barBg.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            setFromX(i.Position.X)
        end
    end)
    barBg.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    barBg.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
    box.FocusLost:Connect(function(enter)
        if enter then
            local num = tonumber(box.Text)
            if num then
                featureSetValue(featureId, num)
            end
            box.Text=""
            refresh()
        end
    end)

    HubEvent.on("featureValueChanged", function(id,val)
        if id==featureId then
            refresh()
        end
    end)
    return holder
end

local function createActionUI(parent, featureId)
    local f=Features[featureId]; if not f then return end
    local holder = Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,44)
    holder.BackgroundTransparency=1
    holder.Parent=parent

    local btn = Instance.new("TextButton")
    btn.Size=UDim2.new(0,160,1,-4)
    btn.Position=UDim2.new(0,0,0,2)
    btn.Text=L(f.nameKey)
    btn.Parent=holder
    styleButton(btn,{})
    btn.MouseButton1Click:Connect(function()
        if f.action then
            local ok,err=pcall(f.action)
            if not ok then Logger.Log("ERR","Action "..featureId.." "..err) end
        end
    end)
    return holder
end

----------------------------------------------------------------
-- COMPOSITE UI BUILDERS
----------------------------------------------------------------
local CompositeBuilders = {}

-- Teleport Player builder
CompositeBuilders.tpPlayer = function(parent, featureId)
    local holder = Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,160)
    holder.BackgroundTransparency=1
    holder.Parent=parent

    local title = Instance.new("TextLabel")
    title.Size=UDim2.new(1,0,0,20)
    title.BackgroundTransparency=1
    title.Font=Enum.Font.Gotham
    title.TextSize=CONFIG.FONT_LABEL_SIZE+2
    title.TextColor3=COLORS.TEXT_DIM
    title.Text = L("TELEPORT_PLAYER")
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=holder

    local listFrame = Instance.new("Frame")
    listFrame.Size=UDim2.new(1,0,0,120)
    listFrame.Position=UDim2.new(0,0,0,24)
    listFrame.BackgroundTransparency=1
    listFrame.Parent=holder

    local uiList = Instance.new("UIListLayout", listFrame)
    uiList.SortOrder=Enum.SortOrder.LayoutOrder
    uiList.Padding=UDim.new(0,4)

    local function refresh()
        for _,child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer then
                local b=Instance.new("TextButton")
                b.Size=UDim2.new(1,-8,0,26)
                b.Text=pl.Name
                b.Font=Enum.Font.Gotham
                b.TextSize=CONFIG.FONT_LABEL_SIZE+1
                b.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.07,0.07,0.1)
                b.BackgroundColor3=COLORS.BTN
                styleButton(b,{})
                b.Parent=listFrame
                b.MouseButton1Click:Connect(function()
                    local myRoot = safeRoot()
                    local target = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot and target then
                        myRoot.CFrame = target.CFrame + Vector3.new(0,2,0)
                        notify("Teleport","-> "..pl.Name,1.5)
                    end
                end)
            end
        end
    end
    refresh()
    Features.tp_player._connections.refreshAdded = Players.PlayerAdded:Connect(refresh)
    Features.tp_player._connections.refreshRemoved = Players.PlayerRemoving:Connect(refresh)

    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size=UDim2.new(0,80,0,24)
    refreshBtn.Position=UDim2.new(1,-90,0,0)
    refreshBtn.Text="↻"
    refreshBtn.Font=Enum.Font.GothamBold
    refreshBtn.TextSize=18
    refreshBtn.BackgroundColor3=COLORS.BTN
    styleButton(refreshBtn,{})
    refreshBtn.Parent=holder
    refreshBtn.MouseButton1Click:Connect(refresh)

    return holder
end

-- Waypoints builder
CompositeBuilders.waypoints = function(parent, featureId)
    local holder = Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,200)
    holder.BackgroundTransparency=1
    holder.Parent=parent

    local title = Instance.new("TextLabel")
    title.Size=UDim2.new(1,0,0,20)
    title.BackgroundTransparency=1
    title.Text = L("WAYPOINTS")
    title.Font=Enum.Font.Gotham
    title.TextSize=CONFIG.FONT_LABEL_SIZE+2
    title.TextColor3=COLORS.TEXT_DIM
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=holder

    local addBox = Instance.new("TextBox")
    addBox.Size=UDim2.new(0,150,0,26)
    addBox.Position=UDim2.new(0,0,0,24)
    addBox.Text=""
    addBox.PlaceholderText = L("ENTER_NAME")
    addBox.BackgroundColor3=COLORS.BTN
    addBox.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.07,0.07,0.1)
    addBox.Font=Enum.Font.Code
    addBox.TextSize=CONFIG.FONT_LABEL_SIZE
    addBox.Parent=holder
    Instance.new("UICorner",addBox).CornerRadius=UDim.new(0,6)

    local addBtn = Instance.new("TextButton")
    addBtn.Size=UDim2.new(0,100,0,26)
    addBtn.Position=UDim2.new(0,160,0,24)
    addBtn.Text=L("ADD_WAYPOINT")
    addBtn.BackgroundColor3=COLORS.BTN
    addBtn.Font=Enum.Font.Gotham
    addBtn.TextSize=CONFIG.FONT_LABEL_SIZE
    addBtn.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.07,0.07,0.1)
    addBtn.Parent=holder
    styleButton(addBtn,{})
    addBtn.MouseButton1Click:Connect(function()
        if #Waypoints >= CONFIG.WAYPOINT_LIMIT then
            notify("WP","Limit reached",2)
            return
        end
        local name = addBox.Text
        if name=="" then name = "WP"..tostring(#Waypoints+1) end
        local root = safeRoot()
        if root then
            table.insert(Waypoints, {name=name, pos={x=root.Position.X,y=root.Position.Y,z=root.Position.Z}})
            saveWaypoints()
            notify("Waypoints", L("WAYPOINT_ADDED"),1.5)
            addBox.Text=""
            HubEvent.fire("refreshUI")
        end
    end)

    local listFrame = Instance.new("Frame")
    listFrame.Size=UDim2.new(1,0,0,140)
    listFrame.Position=UDim2.new(0,0,0,56)
    listFrame.BackgroundTransparency=1
    listFrame.Parent=holder

    local uiList = Instance.new("UIListLayout", listFrame)
    uiList.SortOrder=Enum.SortOrder.LayoutOrder
    uiList.Padding=UDim.new(0,4)

    local sorted = {}
    for i,w in ipairs(Waypoints) do sorted[i]=w end
    table.sort(sorted,function(a,b) return a.name:lower()<b.name:lower() end)

    for idx,wp in ipairs(sorted) do
        local row=Instance.new("Frame")
        row.Size=UDim2.new(1,-4,0,30)
        row.BackgroundColor3=COLORS.BTN
        row.Parent=listFrame
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

        local nameLabel=Instance.new("TextLabel")
        nameLabel.BackgroundTransparency=1
        nameLabel.Size=UDim2.new(0.5,0,1,0)
        nameLabel.Position=UDim2.new(0,8,0,0)
        nameLabel.Font=Enum.Font.Gotham
        nameLabel.TextSize=CONFIG.FONT_LABEL_SIZE
        nameLabel.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.05,0.05,0.07)
        nameLabel.Text=wp.name
        nameLabel.TextXAlignment=Enum.TextXAlignment.Left
        nameLabel.Parent=row

        local tpBtn=Instance.new("TextButton")
        tpBtn.Size=UDim2.new(0,50,0,24)
        tpBtn.Position=UDim2.new(0,240,0,3)
        tpBtn.Text=L("TP")
        tpBtn.Font=Enum.Font.Gotham
        tpBtn.TextSize=CONFIG.FONT_LABEL_SIZE
        tpBtn.BackgroundColor3=COLORS.BTN_HOVER
        tpBtn.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.06,0.06,0.08)
        tpBtn.Parent=row
        styleButton(tpBtn,{})
        tpBtn.MouseButton1Click:Connect(function()
            local root = safeRoot()
            if root then
                root.CFrame = CFrame.new(wp.pos.x, wp.pos.y, wp.pos.z)
                notify("Waypoints", L("WAYPOINT_TP"),1.5)
            end
        end)

        local delBtn=Instance.new("TextButton")
        delBtn.Size=UDim2.new(0,60,0,24)
        delBtn.Position=UDim2.new(1,-64,0,3)
        delBtn.AnchorPoint=Vector2.new(1,0)
        delBtn.Text=L("DELETE")
        delBtn.Font=Enum.Font.Gotham
        delBtn.TextSize=CONFIG.FONT_LABEL_SIZE
        delBtn.BackgroundColor3=COLORS.BTN_DANGER
        delBtn.TextColor3=Color3.new(1,1,1)
        delBtn.Parent=row
        styleButton(delBtn,{danger=true})
        delBtn.MouseButton1Click:Connect(function()
            for i,w in ipairs(Waypoints) do
                if w==wp then
                    table.remove(Waypoints,i)
                    saveWaypoints()
                    notify("Waypoints", L("WAYPOINT_REMOVED"),1.5)
                    HubEvent.fire("refreshUI")
                    break
                end
            end
        end)
    end

    return holder
end

-- Logger builder
CompositeBuilders.logger = function(parent, featureId)
    local holder=Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,180)
    holder.BackgroundTransparency=1
    holder.Parent=parent

    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,0,0,20)
    title.BackgroundTransparency=1
    title.Font=Enum.Font.Gotham
    title.TextColor3=COLORS.TEXT_DIM
    title.TextSize=CONFIG.FONT_LABEL_SIZE+2
    title.Text=L("LOGGER")
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=holder

    local scrolling=Instance.new("ScrollingFrame")
    scrolling.Size=UDim2.new(1,-4,0,130)
    scrolling.Position=UDim2.new(0,0,0,24)
    scrolling.BackgroundColor3=COLORS.BG_RIGHT
    scrolling.BorderSizePixel=0
    scrolling.CanvasSize=UDim2.new(0,0,0,0)
    scrolling.ScrollBarThickness=6
    scrolling.Parent=holder
    Instance.new("UICorner",scrolling).CornerRadius=UDim.new(0,8)

    local list = Instance.new("UIListLayout", scrolling)
    list.SortOrder=Enum.SortOrder.LayoutOrder
    list.Padding=UDim.new(0,2)

    local function refresh()
        for _,c in ipairs(scrolling:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        for _,line in ipairs(Logger._lines) do
            local lbl=Instance.new("TextLabel")
            lbl.Size=UDim2.new(1,-8,0,18)
            lbl.BackgroundTransparency=1
            lbl.Text=line
            lbl.TextColor3=COLORS.TEXT_SUB
            lbl.Font=Enum.Font.Code
            lbl.TextSize=12
            lbl.TextXAlignment=Enum.TextXAlignment.Left
            lbl.Parent=scrolling
        end
        scrolling.CanvasSize=UDim2.new(0,0,0,#Logger._lines*20)
    end
    refresh()

    Features.logger_panel._connections.timer = RunService.Heartbeat:Connect(function()
        -- maybe every second? simple throttle
        if math.random()<0.03 then
            refresh()
        end
    end)

    local clearBtn=Instance.new("TextButton")
    clearBtn.Size=UDim2.new(0,80,0,24)
    clearBtn.Position=UDim2.new(0,0,0,160)
    clearBtn.Text=L("CLEAR")
    clearBtn.Font=Enum.Font.Gotham
    clearBtn.TextSize=CONFIG.FONT_LABEL_SIZE
    clearBtn.BackgroundColor3=COLORS.BTN
    clearBtn.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.06,0.06,0.08)
    clearBtn.Parent=holder
    styleButton(clearBtn,{})
    clearBtn.MouseButton1Click:Connect(function()
        Logger._lines = {}
        refresh()
    end)

    return holder
end

-- Explorer builder
local ExplorerSelection = {selectedInstance=nil}
CompositeBuilders.explorer = function(parent)
    local holder = Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,200)
    holder.BackgroundTransparency=1
    holder.Parent=parent

    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,0,0,20)
    title.BackgroundTransparency=1
    title.Font=Enum.Font.Gotham
    title.TextSize=CONFIG.FONT_LABEL_SIZE+2
    title.TextColor3=COLORS.TEXT_DIM
    title.Text=L("EXPLORER")
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=holder

    local tree=Instance.new("ScrollingFrame")
    tree.Size=UDim2.new(0.5,-4,1,-24)
    tree.Position=UDim2.new(0,0,0,24)
    tree.BackgroundColor3=COLORS.BG_RIGHT
    tree.BorderSizePixel=0
    tree.CanvasSize=UDim2.new(0,0,0,0)
    tree.ScrollBarThickness=6
    tree.Parent=holder
    Instance.new("UICorner",tree).CornerRadius=UDim.new(0,8)

    local list = Instance.new("UIListLayout", tree)
    list.SortOrder=Enum.SortOrder.LayoutOrder
    list.Padding=UDim.new(0,2)

    local function addNode(inst, level, depth)
        if depth>2 then return end
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(1,-8,0,20)
        b.Text= string.rep("  ", level) .. inst.Name .. " ["..inst.ClassName.."]"
        b.Font=Enum.Font.Code
        b.TextSize=12
        b.TextXAlignment=Enum.TextXAlignment.Left
        b.BackgroundColor3=COLORS.BTN
        b.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.07,0.07,0.1)
        styleButton(b,{})
        b.Parent=tree
        b.MouseButton1Click:Connect(function()
            ExplorerSelection.selectedInstance = inst
            HubEvent.fire("refreshProperties")
        end)
        for _,child in ipairs(inst:GetChildren()) do
            addNode(child, level+1, depth+1)
        end
    end

    local function build()
        for _,c in ipairs(tree:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        addNode(workspace,0,0)
        addNode(Players,0,0)
        addNode(game:GetService("ReplicatedStorage"),0,0)
        tree.CanvasSize=UDim2.new(0,0,0,#tree:GetChildren()*22)
    end
    build()

    local refreshBtn=Instance.new("TextButton")
    refreshBtn.Size=UDim2.new(0,60,0,24)
    refreshBtn.Position=UDim2.new(0,0,0,0)
    refreshBtn.AnchorPoint=Vector2.new(0,0)
    refreshBtn.Text="↻"
    refreshBtn.Font=Enum.Font.GothamBold
    refreshBtn.TextSize=18
    refreshBtn.BackgroundColor3=COLORS.BTN
    refreshBtn.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.1,0.1,0.12)
    refreshBtn.Parent=holder
    styleButton(refreshBtn,{})
    refreshBtn.MouseButton1Click:Connect(build)

    return holder
end

-- Properties builder
CompositeBuilders.properties = function(parent)
    local holder=Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,140)
    holder.BackgroundTransparency=1
    holder.Parent=parent

    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,0,0,20)
    title.BackgroundTransparency=1
    title.Font=Enum.Font.Gotham
    title.TextSize=CONFIG.FONT_LABEL_SIZE+2
    title.TextColor3=COLORS.TEXT_DIM
    title.Text=L("PROPERTY_VIEWER")
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=holder

    local info=Instance.new("TextLabel")
    info.Size=UDim2.new(1,-4,0,110)
    info.Position=UDim2.new(0,0,0,24)
    info.BackgroundColor3=COLORS.BG_RIGHT
    info.Text=""
    info.TextWrapped=true
    info.Font=Enum.Font.Code
    info.TextSize=12
    info.TextColor3=COLORS.TEXT_SUB
    info.TextXAlignment=Enum.TextXAlignment.Left
    info.TextYAlignment=Enum.TextYAlignment.Top
    info.Parent=holder
    Instance.new("UICorner",info).CornerRadius=UDim.new(0,8)

    local function refresh()
        local inst = ExplorerSelection.selectedInstance
        if not inst then info.Text="(None)" return end
        local lines = {
            "Name: "..inst.Name,
            "Class: "..inst.ClassName,
            "Parent: ".. (inst.Parent and inst.Parent.Name or "nil")
        }
        if inst:IsA("BasePart") then
            table.insert(lines, ("Pos: %.1f,%.1f,%.1f"):format(inst.Position.X, inst.Position.Y, inst.Position.Z))
            table.insert(lines, ("Size: %.1f,%.1f,%.1f"):format(inst.Size.X, inst.Size.Y, inst.Size.Z))
        end
        info.Text = table.concat(lines, "\n")
    end
    HubEvent.on("refreshProperties", refresh)

    return holder
end

-- Stats builder
CompositeBuilders.stats = function(parent)
    local holder=Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,90)
    holder.BackgroundTransparency=1
    holder.Parent=parent

    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,0,0,20)
    title.BackgroundTransparency=1
    title.Font=Enum.Font.Gotham
    title.TextSize=CONFIG.FONT_LABEL_SIZE+2
    title.TextColor3=COLORS.TEXT_DIM
    title.Text=L("STATS")
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=holder

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-4,0,60)
    lbl.Position=UDim2.new(0,0,0,24)
    lbl.BackgroundColor3=COLORS.BG_RIGHT
    lbl.Text=""
    lbl.TextWrapped=true
    lbl.Font=Enum.Font.Code
    lbl.TextSize=12
    lbl.TextColor3=COLORS.TEXT_SUB
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextYAlignment=Enum.TextYAlignment.Top
    lbl.Parent=holder
    Instance.new("UICorner",lbl).CornerRadius=UDim.new(0,8)

    Features.stats._connections.loop = RunService.Heartbeat:Connect(function()
        if math.random()<0.1 then
            local fps = (workspace:GetRealPhysicsFPS and workspace:GetRealPhysicsFPS()) or 60
            local mem = collectgarbage("count")/1024
            local icount = #game:GetDescendants()
            lbl.Text = ("FPS: %.1f\nMem(MB): %.1f\nInstances: %d"):format(fps, mem, icount)
        end
    end)

    return holder
end

-- Remote Spy composite (log display)
CompositeBuilders.remote_spy = function(parent)
    local holder=Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,150)
    holder.BackgroundTransparency=1
    holder.Parent=parent
    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,0,0,20)
    title.BackgroundTransparency=1
    title.Font=Enum.Font.Gotham
    title.Text=L("REMOTE_SPY").." ("..(RemoteSpyState.enabled and "ON" or "OFF")..")"
    title.TextSize=CONFIG.FONT_LABEL_SIZE+2
    title.TextColor3=COLORS.TEXT_DIM
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=holder

    local filterBox=Instance.new("TextBox")
    filterBox.Size=UDim2.new(0,140,0,24)
    filterBox.Position=UDim2.new(0,0,0,24)
    filterBox.BackgroundColor3=COLORS.BTN
    filterBox.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.05,0.05,0.07)
    filterBox.Text=RemoteSpyState.filter
    filterBox.PlaceholderText=L("REMOTE_FILTER")
    filterBox.Font=Enum.Font.Code
    filterBox.TextSize=CONFIG.FONT_LABEL_SIZE
    filterBox.Parent=holder
    Instance.new("UICorner",filterBox).CornerRadius=UDim.new(0,6)
    filterBox.FocusLost:Connect(function(enter)
        if enter then
            RemoteSpyState.filter = filterBox.Text
        end
    end)

    local scroll=Instance.new("ScrollingFrame")
    scroll.Size=UDim2.new(1,0,0,100)
    scroll.Position=UDim2.new(0,0,0,52)
    scroll.BackgroundColor3=COLORS.BG_RIGHT
    scroll.BorderSizePixel=0
    scroll.CanvasSize=UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness=6
    scroll.Parent=holder
    Instance.new("UICorner",scroll).CornerRadius=UDim.new(0,8)

    local list = Instance.new("UIListLayout", scroll)
    list.SortOrder=Enum.SortOrder.LayoutOrder
    list.Padding=UDim.new(0,2)

    local function refresh()
        for _,c in ipairs(scroll:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        for _,line in ipairs(RemoteSpyState.logs) do
            local lbl=Instance.new("TextLabel")
            lbl.Size=UDim2.new(1,-8,0,18)
            lbl.BackgroundTransparency=1
            lbl.Text=line
            lbl.TextColor3=COLORS.TEXT_SUB
            lbl.Font=Enum.Font.Code
            lbl.TextSize=12
            lbl.TextXAlignment=Enum.TextXAlignment.Left
            lbl.Parent=scroll
        end
        scroll.CanvasSize=UDim2.new(0,0,0,#RemoteSpyState.logs*20)
    end

    Features.remote_spy._connections.timer = RunService.Heartbeat:Connect(function()
        if RemoteSpyState.enabled and math.random()<0.05 then
            refresh()
        end
    end)

    return holder
end

-- Auto Exec builder
CompositeBuilders.autoexec = function(parent)
    local holder=Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,180)
    holder.BackgroundTransparency=1
    holder.Parent=parent

    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(1,0,0,20)
    title.BackgroundTransparency=1
    title.Font=Enum.Font.Gotham
    title.TextColor3=COLORS.TEXT_DIM
    title.TextSize=CONFIG.FONT_LABEL_SIZE+2
    title.Text=L("AUTO_EXEC")
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=holder

    local nameBox=Instance.new("TextBox")
    nameBox.Size=UDim2.new(0,120,0,24)
    nameBox.Position=UDim2.new(0,0,0,24)
    nameBox.BackgroundColor3=COLORS.BTN
    nameBox.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.05,0.05,0.07)
    nameBox.PlaceholderText=L("ENTER_NAME")
    nameBox.Font=Enum.Font.Code
    nameBox.TextSize=CONFIG.FONT_LABEL_SIZE
    nameBox.Parent=holder
    Instance.new("UICorner",nameBox).CornerRadius=UDim.new(0,6)

    local codeBox=Instance.new("TextBox")
    codeBox.Size=UDim2.new(0,240,0,24)
    codeBox.Position=UDim2.new(0,130,0,24)
    codeBox.BackgroundColor3=COLORS.BTN
    codeBox.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.05,0.05,0.07)
    codeBox.PlaceholderText=L("ENTER_CODE")
    codeBox.Font=Enum.Font.Code
    codeBox.TextSize=CONFIG.FONT_LABEL_SIZE
    codeBox.Parent=holder
    Instance.new("UICorner",codeBox).CornerRadius=UDim.new(0,6)

    local addBtn=Instance.new("TextButton")
    addBtn.Size=UDim2.new(0,100,0,24)
    addBtn.Position=UDim2.new(0,380,0,24)
    addBtn.Text=L("ADD_SCRIPT")
    addBtn.BackgroundColor3=COLORS.BTN
    addBtn.Font=Enum.Font.Gotham
    addBtn.TextSize=CONFIG.FONT_LABEL_SIZE
    addBtn.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.07,0.07,0.1)
    addBtn.Parent=holder
    styleButton(addBtn,{})
    addBtn.MouseButton1Click:Connect(function()
        local name=nameBox.Text~="" and nameBox.Text or ("Script"..tostring(#StoredScripts+1))
        local code=codeBox.Text
        if code=="" then return end
        table.insert(StoredScripts,{name=name,code=code,isURL=code:find("^https://")~=nil})
        saveScripts()
        notify("Scripts", L("SCRIPT_ADDED"),1.5)
        nameBox.Text="" codeBox.Text=""
        HubEvent.fire("refreshUI")
    end)

    local listFrame=Instance.new("Frame")
    listFrame.Size=UDim2.new(1,0,0,110)
    listFrame.Position=UDim2.new(0,0,0,56)
    listFrame.BackgroundTransparency=1
    listFrame.Parent=holder

    local uiList=Instance.new("UIListLayout", listFrame)
    uiList.SortOrder=Enum.SortOrder.LayoutOrder
    uiList.Padding=UDim.new(0,4)

    for i,sc in ipairs(StoredScripts) do
        local row=Instance.new("Frame")
        row.Size=UDim2.new(1,-4,0,28)
        row.BackgroundColor3=COLORS.BTN
        row.Parent=listFrame
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,6)

        local label=Instance.new("TextLabel")
        label.BackgroundTransparency=1
        label.Size=UDim2.new(0.5,0,1,0)
        label.Position=UDim2.new(0,8,0,0)
        label.Font=Enum.Font.Gotham
        label.TextSize=CONFIG.FONT_LABEL_SIZE
        label.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.08,0.08,0.1)
        label.Text=sc.name
        label.TextXAlignment=Enum.TextXAlignment.Left
        label.Parent=row

        local runBtn=Instance.new("TextButton")
        runBtn.Size=UDim2.new(0,60,0,22)
        runBtn.Position=UDim2.new(0,220,0,3)
        runBtn.Text=L("RUN")
        runBtn.Font=Enum.Font.Gotham
        runBtn.TextSize=CONFIG.FONT_LABEL_SIZE
        runBtn.BackgroundColor3=COLORS.BTN_HOVER
        runBtn.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.1,0.1,0.15)
        runBtn.Parent=row
        styleButton(runBtn,{})
        runBtn.MouseButton1Click:Connect(function()
            task.spawn(function()
                local codeToRun = sc.code
                if sc.isURL then
                    local ok,res = pcall(function() return game:HttpGet(codeToRun) end)
                    if ok then codeToRun=res else notify("Script","URL fail",2) return end
                end
                local ok,err = pcall(function()
                    loadstring(codeToRun)()
                end)
                if not ok then
                    notify("Script","Error: "..tostring(err),3)
                end
            end)
        end)

        local delBtn=Instance.new("TextButton")
        delBtn.Size=UDim2.new(0,60,0,22)
        delBtn.Position=UDim2.new(1,-64,0,3)
        delBtn.AnchorPoint=Vector2.new(1,0)
        delBtn.Text=L("DELETE")
        delBtn.Font=Enum.Font.Gotham
        delBtn.TextSize=CONFIG.FONT_LABEL_SIZE
        delBtn.BackgroundColor3=COLORS.BTN_DANGER
        delBtn.TextColor3=Color3.new(1,1,1)
        delBtn.Parent=row
        styleButton(delBtn,{danger=true})
        delBtn.MouseButton1Click:Connect(function()
            table.remove(StoredScripts, i)
            saveScripts()
            notify("Scripts", L("SCRIPT_REMOVED"),1.5)
            HubEvent.fire("refreshUI")
        end)
    end

    return holder
end

----------------------------------------------------------------
-- RENDER CATEGORY UI
----------------------------------------------------------------
local CategoryInfo = {
    movement = "CATEGORY_MOVEMENT",
    teleport = "CATEGORY_TELEPORT",
    visual   = "CATEGORY_VISUAL",
    util     = "CATEGORY_UTIL",
    dev      = "CATEGORY_DEV",
    scripts  = "CATEGORY_SCRIPTS",
}

local function rebuildFeatureList()
    if not UI.Elements.FeatureContainer then return end
    local container = UI.Elements.FeatureContainer
    for _,child in ipairs(container:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end

    local cat = UI.CurrentCategory
    local ids = FeatureOrder[cat]
    if not ids then return end

    -- Scroll area
    local ySpacing = 6

    for _,fid in ipairs(ids) do
        local f=Features[fid]
        if f then
            if f.type == "toggle" then
                createToggleUI(container, fid)
            elseif f.type == "slider" then
                createSliderUI(container, fid)
            elseif f.type == "action" then
                createActionUI(container, fid)
            elseif f.type == "composite" then
                local builder = CompositeBuilders[f.uiBuilder]
                if builder then
                    builder(container,fid)
                else
                    local lbl=Instance.new("TextLabel")
                    lbl.Size=UDim2.new(1,0,0,24)
                    lbl.BackgroundTransparency=1
                    lbl.Text="(Composite) "..fid
                    lbl.TextColor3=COLORS.TEXT_SUB
                    lbl.Font=Enum.Font.Gotham
                    lbl.TextSize=CONFIG.FONT_LABEL_SIZE
                    lbl.TextXAlignment=Enum.TextXAlignment.Left
                    lbl.Parent=container
                end
            end
        end
    end

    container.CanvasSize = UDim2.new(0,0,0, #container:GetChildren()*(50))
end

----------------------------------------------------------------
-- UI BUILD
----------------------------------------------------------------
function UI.createFloatingButton()
    if UI.FloatingGui then UI.FloatingGui:Destroy() end
    local sg=Instance.new("ScreenGui")
    sg.Name="UH_Float"
    sg.ResetOnSpawn=false
    safeParent(sg)
    UI.FloatingGui=sg

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,scale(CONFIG.MINI_BUTTON_SIZE),0,scale(CONFIG.MINI_BUTTON_SIZE))
    local savedPos = Persist.get("float_pos_v2", nil)
    if savedPos and savedPos.x then
        btn.Position=UDim2.new(0,savedPos.x,0,savedPos.y)
    else
        btn.Position=CONFIG.MINI_START_POS
    end
    btn.Text=L("MINI_HANDLE")
    btn.Font=Enum.Font.GothamBold
    btn.TextSize=CONFIG.FONT_MAIN_SIZE+4
    btn.TextColor3=Color3.new(1,1,1)
    btn.BackgroundColor3=COLORS.BTN_MINI
    btn.Parent=sg
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)

    local dragging=false
    local dragStart, startPos
    btn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=i.Position
            startPos=btn.Position
            i.Changed:Connect(function(s)
                if s==Enum.UserInputState.End then
                    dragging=false
                    Persist.set("float_pos_v2",{x=btn.Position.X.Offset,y=btn.Position.Y.Offset})
                    notify("UI", L("POSITION_SAVED"),1.5)
                end
            end)
        end
    end)
    btn.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local delta=i.Position - dragStart
            btn.Position=UDim2.new(0, startPos.X.Offset+delta.X,0,startPos.Y.Offset+delta.Y)
        end
    end)
    btn.MouseButton1Click:Connect(function()
        if UI.Screen and not UI.Destroyed then
            UI.Screen.Enabled=true
            btn.Visible=false
        end
    end)
    UI.FloatingButton=btn
end

function UI.create()
    if UI.Screen then UI.Screen:Destroy() end
    UI.Destroyed=false

    local sg=Instance.new("ScreenGui")
    sg.Name="UH_MainV2"
    sg.ResetOnSpawn=false
    safeParent(sg)
    UI.Screen=sg

    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,scale(CONFIG.WINDOW_WIDTH),0,scale(CONFIG.WINDOW_HEIGHT))
    frame.Position=UDim2.new(0.5,-scale(CONFIG.WINDOW_WIDTH)/2,0.45,-scale(CONFIG.WINDOW_HEIGHT)/2)
    frame.BackgroundColor3=COLORS.BG_MAIN
    frame.Parent=sg
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,12)

    local top=Instance.new("Frame")
    top.Size=UDim2.new(1,0,0,scale(CONFIG.TOPBAR_HEIGHT))
    top.BackgroundColor3=COLORS.BG_TOP
    top.Parent=frame
    Instance.new("UICorner",top).CornerRadius=UDim.new(0,12)

    local title=Instance.new("TextLabel")
    title.Size=UDim2.new(0.6,0,1,0)
    title.Position=UDim2.new(0,scale(CONFIG.PADDING),0,0)
    title.BackgroundTransparency=1
    title.Font=Enum.Font.GothamBold
    title.TextSize=CONFIG.FONT_MAIN_SIZE+1
    title.TextColor3= (CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.05,0.05,0.07)
    title.Text=L("UI_TITLE", VERSION)
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=top
    UI.Elements.TopTitle=title

    local watermark=Instance.new("TextLabel")
    watermark.BackgroundTransparency=1
    watermark.Size=UDim2.new(0,200,1,0)
    watermark.AnchorPoint=Vector2.new(1,0)
    watermark.Position=UDim2.new(1,-scale(180),0,0)
    watermark.Font=Enum.Font.GothamBold
    watermark.TextSize=CONFIG.FONT_MAIN_SIZE
    watermark.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.fromRGB(255,255,255) or Color3.fromRGB(30,30,40)
    watermark.Text=CONFIG.WATERMARK
    watermark.TextXAlignment=Enum.TextXAlignment.Right
    watermark.Parent=top
    UI.Elements.Watermark = watermark

    local btnClose=Instance.new("TextButton")
    btnClose.Size=UDim2.new(0,80,0,scale(CONFIG.TOPBAR_HEIGHT-8))
    btnClose.Position=UDim2.new(1,-scale(84),0,scale(4))
    btnClose.Text=L("BTN_CLOSE")
    btnClose.Font=Enum.Font.GothamBold
    btnClose.TextSize=CONFIG.FONT_LABEL_SIZE+1
    btnClose.TextColor3=Color3.new(1,1,1)
    btnClose.BackgroundColor3=COLORS.BTN_DANGER
    btnClose.Parent=top
    styleButton(btnClose,{danger=true})

    local btnMin=Instance.new("TextButton")
    btnMin.Size=UDim2.new(0,100,0,scale(CONFIG.TOPBAR_HEIGHT-8))
    btnMin.Position=UDim2.new(1,-scale(84+106),0,scale(4))
    btnMin.Text=L("BTN_MINIMIZE")
    btnMin.Font=Enum.Font.GothamBold
    btnMin.TextSize=CONFIG.FONT_LABEL_SIZE
    btnMin.BackgroundColor3=COLORS.BTN
    btnMin.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.07,0.07,0.1)
    btnMin.Parent=top
    styleButton(btnMin,{})

    local content=Instance.new("Frame")
    content.Size=UDim2.new(1,0,1,-scale(CONFIG.TOPBAR_HEIGHT))
    content.Position=UDim2.new(0,0,0,scale(CONFIG.TOPBAR_HEIGHT))
    content.BackgroundTransparency=1
    content.Parent=frame

    local left=Instance.new("Frame")
    left.Size=UDim2.new(0,140,1,0)
    left.BackgroundColor3=COLORS.BG_LEFT
    left.Parent=content
    Instance.new("UICorner",left).CornerRadius=UDim.new(0,10)

    local catList=Instance.new("UIListLayout", left)
    catList.SortOrder=Enum.SortOrder.LayoutOrder
    catList.Padding=UDim.new(0,6)
    catList.HorizontalAlignment=Enum.HorizontalAlignment.Center

    local function makeCatButton(catKey, catId)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(1,-16,0,36)
        b.Text=L(catKey)
        b.Font=Enum.Font.Gotham
        b.TextSize=CONFIG.FONT_MAIN_SIZE
        b.TextColor3=(CURRENT_THEME_NAME=="dark") and Color3.new(1,1,1) or Color3.new(0.07,0.07,0.11)
        b.BackgroundColor3=(UI.CurrentCategory==catId) and COLORS.BTN_ACTIVE or COLORS.BTN
        b.Parent=left
        styleButton(b,{activeIndicator=function() return UI.CurrentCategory==catId end})
        b.MouseButton1Click:Connect(function()
            UI.CurrentCategory=catId
            rebuildFeatureList()
            for _,btn in pairs(UI.Elements.CategoryButtons) do
                btn.BackgroundColor3 = COLORS.BTN
            end
            b.BackgroundColor3=COLORS.BTN_ACTIVE
        end)
        UI.Elements.CategoryButtons[catId]=b
    end

    for cid,key in pairs(CategoryInfo) do
        makeCatButton(key,cid)
    end

    local right=Instance.new("ScrollingFrame")
    right.Size=UDim2.new(1,-152,1,0)
    right.Position=UDim2.new(0,148,0,0)
    right.BackgroundColor3=COLORS.BG_RIGHT
    right.BorderSizePixel=0
    right.CanvasSize=UDim2.new(0,0,0,0)
    right.ScrollBarThickness=8
    right.Parent=content
    Instance.new("UICorner",right).CornerRadius=UDim.new(0,10)
    UI.Elements.FeatureContainer = right

    local list=Instance.new("UIListLayout", right)
    list.SortOrder=Enum.SortOrder.LayoutOrder
    list.Padding=UDim.new(0,8)

    -- Drag window
    local dragging=false
    local dragStart,startPos
    top.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=i.Position
            startPos=frame.Position
            i.Changed:Connect(function(s)
                if s==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    top.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local delta=i.Position-dragStart
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)

    btnMin.MouseButton1Click:Connect(function()
        if UI.FloatingButton then
            UI.FloatingButton.Visible=true
        end
        UI.Screen.Enabled=false
    end)
    btnClose.MouseButton1Click:Connect(function()
        UI.Destroyed=true
        if UI.Screen then UI.Screen:Destroy() end
        if UI.FloatingButton then
            UI.FloatingButton.Visible=true
        end
        notify("UI", L("CLOSE_INFO"),3)
    end)

    rebuildFeatureList()
    notify("Utility", L("LOADED", VERSION), 3)
end

HubEvent.on("refreshUI", function()
    if UI.Screen then
        rebuildFeatureList()
    end
end)

HubEvent.on("themeChanged", function()
    -- rebuild full UI for simplicity
    if UI.Screen then
        UI.create()
        if UI.FloatingButton then UI.FloatingButton.Visible=false end
    end
end)

----------------------------------------------------------------
-- HOTKEY INPUT HANDLER
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if CapturingHotkeyFor then
        if input.UserInputType==Enum.UserInputType.Keyboard then
            setHotkey(CapturingHotkeyFor, input.KeyCode)
            CapturingHotkeyFor=nil
            HubEvent.fire("refreshUI")
            return
        end
    end

    if input.KeyCode == CONFIG.HOTKEY_TOGGLE_MENU then
        if UI.Screen and not UI.Destroyed then
            UI.Screen.Enabled = not UI.Screen.Enabled
            if UI.FloatingButton then
                UI.FloatingButton.Visible = not UI.Screen.Enabled
            end
            notify("UI", L("MENU_TOGGLED"),1.5)
        else
            UI.create()
            if UI.FloatingButton then UI.FloatingButton.Visible=false end
        end
        return
    end

    -- Check feature hotkeys
    for id,key in pairs(Hotkeys) do
        if input.KeyCode == key then
            featureToggle(id)
            HubEvent.fire("refreshUI")
        end
    end
end)

----------------------------------------------------------------
-- WATERMARK WATCH (reuse simple loop)
----------------------------------------------------------------
local function startWatermarkWatch()
    if not CONFIG.ENABLE_WATERMARK_WATCH then return end
    task.spawn(function()
        task.wait(1)
        while UI.Screen and not UI.Destroyed do
            local ok = UI.Elements.Watermark and UI.Elements.Watermark.Parent and UI.Elements.Watermark.Text==CONFIG.WATERMARK
            if not ok then
                notify("Security", L("WATERMARK_ALERT"))
                Logger.Log("SEC","Watermark changed/removed")
                break
            end
            task.wait(math.random()* (CONFIG.WATERMARK_CHECK_INTERVAL.max - CONFIG.WATERMARK_CHECK_INTERVAL.min) + CONFIG.WATERMARK_CHECK_INTERVAL.min)
        end
    end)
end

----------------------------------------------------------------
-- LANGUAGE SELECTION (initial)
----------------------------------------------------------------
local function showLanguageSelect(onChosen)
    local sg = Instance.new("ScreenGui")
    sg.Name="UH_LangSelect"
    sg.ResetOnSpawn=false
    safeParent(sg)

    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,360,0,180)
    frame.Position=UDim2.new(0.5,-180,0.5,-90)
    frame.BackgroundColor3=COLORS.BG_MAIN
    frame.Parent=sg
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,14)

    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Size=UDim2.new(1,0,0,48)
    title.Font=Enum.Font.GothamBold
    title.TextSize=20
    title.TextColor3=Color3.new(1,1,1)
    title.Text=L("LANG_SELECT_TITLE")
    title.Parent=frame

    local function mk(text, offset, code)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0.5,-40,0,58)
        b.Position=UDim2.new(offset,20,0,90)
        b.BackgroundColor3=COLORS.BTN
        b.TextColor3=Color3.new(1,1,1)
        b.TextSize=18
        b.Font=Enum.Font.GothamBold
        b.Text=text
        b.Parent=frame
        local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,12); c.Parent=b
        b.MouseEnter:Connect(function() b.BackgroundColor3=COLORS.BTN_HOVER end)
        b.MouseLeave:Connect(function() b.BackgroundColor3=COLORS.BTN end)
        b.MouseButton1Click:Connect(function()
            setLanguage(code)
            sg:Destroy()
            if onChosen then onChosen() end
        end)
    end
    mk(L("LANG_PT"),0,"pt")
    mk(L("LANG_EN"),0.5,"en")
end

----------------------------------------------------------------
-- FINAL INIT
----------------------------------------------------------------
UI.createFloatingButton()

-- Auto-enable toggles with _autoEnable flag after all registration
task.defer(function()
    for id,f in pairs(Features) do
        if f._autoEnable then
            featureEnable(id,true)
            f._autoEnable=nil
        end
    end
end)

-- Apply persisted slider values
for id,f in pairs(Features) do
    if f.type=="slider" and f.value~=nil and f.set then
        pcall(function() f.set(f.value) end)
    end
end

if Lang.current and Lang.data[Lang.current] then
    UI.create()
    if UI.FloatingButton then UI.FloatingButton.Visible=false end
else
    showLanguageSelect(function()
        UI.create()
        if UI.FloatingButton then UI.FloatingButton.Visible=false end
    end)
end

startWatermarkWatch()

-- Export
_G.__UNIVERSAL_HUB_EXPORTS = {
    VERSION = VERSION,
    CONFIG = CONFIG,
    Persist = Persist,
    Lang = Lang,
    Logger = Logger,
    Features = Features,
    UI = UI,
    HubEvent = HubEvent,
}

-- END v2.0.0