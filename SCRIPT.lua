-- Universal Hub Refatorado (Mobile 3D Fly Update)
-- Guard para evitar múltiplas execuções (minimiza erros de libs externas / remotes duplicados)
if _G.__UNIVERSAL_HUB_ALREADY then
    warn("[UniversalHub] Já carregado. Abortando segunda carga.")
    return _G.__UNIVERSAL_HUB_EXPORTS
end
_G.__UNIVERSAL_HUB_ALREADY = true

local VERSION = "1.3.0" -- versão incrementada

------------------------------------------------------------
-- CONFIGURAÇÕES
------------------------------------------------------------
local CONFIG = {
    WINDOW_WIDTH = 520,
    WINDOW_HEIGHT = 260,
    TOPBAR_HEIGHT = 32,
    PADDING = 12,
    UI_SCALE = 1.0,
    FONT_MAIN_SIZE = 14,
    FONT_LABEL_SIZE = 12,
    MINI_BUTTON_SIZE = 44,
    MINI_START_POS = UDim2.new(0, 24, 0.4, 0),
    WATERMARK = "Eduardo854832",
    ENABLE_WATERMARK_WATCH = true,
    WATERMARK_CHECK_INTERVAL = {min=2.5,max=3.6},
    FLY_DEFAULT_SPEED = 50,
    FLY_MIN_SPEED = 5,
    FLY_MAX_SPEED = 500,
    FLY_SMOOTHNESS = 0.25,          -- 0 = instant, 0.25 = suavizado
    FLY_VERTICAL_SCALE = 1.0,       -- escala vertical (pode reduzir se subir/descer muito rápido)
    FLY_MIN_PITCH_TO_LIFT = 0.05,   -- sensibilidade: quanto de |LookVector.Y| precisa para gerar vertical
    HOTKEY_TOGGLE_MENU = Enum.KeyCode.RightShift,
    HOTKEY_TOGGLE_FLY  = Enum.KeyCode.F,
    MOBILE_FULL3D_DEFAULT = true,   -- celular inicia com modo 3D
}

local COLORS = {
    BG_MAIN = Color3.fromRGB(25,25,32),
    BG_TOP  = Color3.fromRGB(38,38,50),
    BG_LEFT = Color3.fromRGB(30,30,40),
    BG_RIGHT= Color3.fromRGB(32,32,44),
    BTN     = Color3.fromRGB(52,52,60),
    BTN_HOVER = Color3.fromRGB(66,66,76),
    BTN_ACTIVE= Color3.fromRGB(90,140,255),
    BTN_DANGER= Color3.fromRGB(120,55,55),
    BTN_MINI  = Color3.fromRGB(40,48,62),
    ACCENT    = Color3.fromRGB(90,140,255),
    SLIDER_BG = Color3.fromRGB(60,60,72),
    SLIDER_FILL=Color3.fromRGB(90,140,255),
    SLIDER_KNOB= Color3.fromRGB(200,200,220),
    TEXT_DIM  = Color3.fromRGB(180,180,190),
    TEXT_SUB  = Color3.fromRGB(150,150,160),
}

------------------------------------------------------------
-- SERVIÇOS
------------------------------------------------------------
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local StarterGui       = game:GetService("StarterGui")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------
-- UTIL
------------------------------------------------------------
local function safeParent(gui)
    pcall(function()
        local parent = (gethui and gethui()) or CoreGui
        gui.Parent = parent
    end)
end

local function notify(title,text,dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=title,Text=text,Duration=dur or 3})
    end)
end

local function randRange(a,b) return a + math.random()*(b-a) end
local function scale(n) return n * CONFIG.UI_SCALE end

------------------------------------------------------------
-- PERSISTÊNCIA
------------------------------------------------------------
local Persist = {}
Persist._fileName = "UniversalUtilityConfig.json"
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
    Persist._dirty = false
    pcall(function()
        writefile(Persist._fileName, HttpService:JSONEncode(Persist._data))
    end)
end

function Persist.get(k, def)
    local v = Persist._data[k]
    if v == nil and def ~= nil then
        Persist._data[k] = def
        Persist._dirty = true
        return def
    end
    return v
end

function Persist.set(k,v)
    if Persist._data[k] ~= v then
        Persist._data[k] = v
        Persist._dirty = true
    end
end

Persist.load()

-- Loop de flush
task.spawn(function()
    while true do
        Persist.flush(false)
        task.wait(0.5)
    end
end)

------------------------------------------------------------
-- LOGGER
------------------------------------------------------------
local Logger = { _max = 200, _lines = {} }
function Logger.Log(level, msg)
    local line = os.date("%H:%M:%S").." ["..level.."] "..tostring(msg)
    table.insert(Logger._lines, line)
    if #Logger._lines > Logger._max then table.remove(Logger._lines,1) end
    warn("[UniversalHub]["..level.."] ",tostring(msg))
end

------------------------------------------------------------
-- EVENT BUS
------------------------------------------------------------
local EventBus = {
    _listeners = {}
}

function EventBus.subscribe(event, callback)
    if not EventBus._listeners[event] then
        EventBus._listeners[event] = {}
    end
    table.insert(EventBus._listeners[event], callback)
end

function EventBus.publish(event, ...)
    if EventBus._listeners[event] then
        for _, callback in ipairs(EventBus._listeners[event]) do
            pcall(callback, ...)
        end
    end
end

function EventBus.unsubscribe(event, callback)
    if EventBus._listeners[event] then
        for i, cb in ipairs(EventBus._listeners[event]) do
            if cb == callback then
                table.remove(EventBus._listeners[event], i)
                break
            end
        end
    end
end

------------------------------------------------------------
-- FEATURE REGISTRY
------------------------------------------------------------
local FeatureRegistry = {
    _features = {},
    _categories = {
        "Movimento",
        "Teleporte", 
        "Visual",
        "Utilidades",
        "Dev",
        "Scripts"
    }
}

function FeatureRegistry.register(featureId, config)
    local feature = {
        id = featureId,
        name = config.name or featureId,
        category = config.category or "Utilidades",
        enabled = Persist.get("feature_" .. featureId, config.defaultEnabled or false),
        hotkey = config.hotkey,
        onEnable = config.onEnable,
        onDisable = config.onDisable,
        onToggle = config.onToggle,
        persistState = config.persistState ~= false,
        ui = config.ui or {}
    }
    
    FeatureRegistry._features[featureId] = feature
    EventBus.publish("FeatureRegistered", featureId, feature)
    return feature
end

function FeatureRegistry.get(featureId)
    return FeatureRegistry._features[featureId]
end

function FeatureRegistry.getByCategory(category)
    local features = {}
    for id, feature in pairs(FeatureRegistry._features) do
        if feature.category == category then
            features[id] = feature
        end
    end
    return features
end

function FeatureRegistry.toggle(featureId)
    local feature = FeatureRegistry._features[featureId]
    if not feature then return false end
    
    feature.enabled = not feature.enabled
    
    if feature.persistState then
        Persist.set("feature_" .. featureId, feature.enabled)
    end
    
    if feature.enabled then
        if feature.onEnable then
            pcall(feature.onEnable)
        end
    else
        if feature.onDisable then
            pcall(feature.onDisable)
        end
    end
    
    if feature.onToggle then
        pcall(feature.onToggle, feature.enabled)
    end
    
    EventBus.publish("FeatureToggled", featureId, feature.enabled)
    Logger.Log("FEATURE", featureId .. " " .. (feature.enabled and "enabled" or "disabled"))
    return feature.enabled
end

function FeatureRegistry.isEnabled(featureId)
    local feature = FeatureRegistry._features[featureId]
    return feature and feature.enabled or false
end

function FeatureRegistry.setEnabled(featureId, enabled)
    local feature = FeatureRegistry._features[featureId]
    if not feature or feature.enabled == enabled then return end
    
    FeatureRegistry.toggle(featureId)
end

function FeatureRegistry.getAllCategories()
    return FeatureRegistry._categories
end

------------------------------------------------------------
-- HOTKEYS SYSTEM
------------------------------------------------------------
local HotkeyManager = {
    _bindings = {},
    _capturing = false,
    _captureCallback = nil
}

function HotkeyManager.bind(featureId, keyCode)
    -- Remove old binding if exists
    HotkeyManager.unbind(featureId)
    
    if keyCode then
        HotkeyManager._bindings[keyCode] = featureId
        Persist.set("hotkey_" .. featureId, keyCode.Name)
    end
end

function HotkeyManager.unbind(featureId)
    for keyCode, boundFeatureId in pairs(HotkeyManager._bindings) do
        if boundFeatureId == featureId then
            HotkeyManager._bindings[keyCode] = nil
            Persist.set("hotkey_" .. featureId, nil)
            break
        end
    end
end

function HotkeyManager.getBinding(featureId)
    for keyCode, boundFeatureId in pairs(HotkeyManager._bindings) do
        if boundFeatureId == featureId then
            return keyCode
        end
    end
    return nil
end

function HotkeyManager.startCapture(callback)
    HotkeyManager._capturing = true
    HotkeyManager._captureCallback = callback
end

function HotkeyManager.stopCapture()
    HotkeyManager._capturing = false
    HotkeyManager._captureCallback = nil
end

-- Load saved hotkeys
function HotkeyManager.loadSavedHotkeys()
    for featureId, feature in pairs(FeatureRegistry._features) do
        local savedKey = Persist.get("hotkey_" .. featureId, nil)
        if savedKey then
            local keyCode = Enum.KeyCode[savedKey]
            if keyCode then
                HotkeyManager._bindings[keyCode] = featureId
            end
        elseif feature.hotkey then
            HotkeyManager.bind(featureId, feature.hotkey)
        end
    end
end

------------------------------------------------------------
-- I18N
------------------------------------------------------------
local Lang = {}
Lang.data = {
    pt = {
        UI_TITLE="Universal Hub v%s",
        MINI_HANDLE="≡",
        MINI_TIP="Arraste",
        LANG_SELECT_TITLE="Selecione o Idioma",
        LANG_PT="Português",
        LANG_EN="English",
        LOADED="Carregado v%s",
        FLY_ENABLED="Voo on (vel=%d)",
        FLY_DISABLED="Voo off",
        FLY_SPEED_SET="Velocidade de voo = %d",
        FLY_ERR_NO_ROOT="HumanoidRootPart não encontrado.",
        FLY_SPEED="Velocidade",
        FLY_TOGGLE_ON="Desligar",
        FLY_TOGGLE_OFF="Ligar",
        FLY_MODE_3D_ON="Modo 3D",
        FLY_MODE_3D_OFF="Modo Plano",
        PANEL_FLY="Voo",
        PANEL_SPEED="Velocidade",
        PANEL_IY="IY",
        BTN_IY_LOAD="Carregar IY",
        IY_LOADING="Carregando IY...",
        IY_LOADED="IY carregado.",
        IY_ALREADY="Já carregado.",
        IY_FAILED="Falha: %s",
        SLIDER_HINT="Arraste ou digite valor",
        BTN_CLOSE="Fechar",
        BTN_MINIMIZE="Minimizar",
        BTN_RESTORE="Restaurar",
        MENU_TOGGLED="Menu alternado",
        HOTKEY_FLY="Tecla F: alterna voo",
        HOTKEY_MENU="RightShift: abre/fecha menu",
        WATERMARK_ALERT="Watermark alterada ou removida.",
        FLY_ON_RESPAWN="Reaplicando voo após respawn...",
        CLOSE_INFO="Interface destruída. Use o script novamente para reabrir.",
        POSITION_SAVED="Posição salva",
        FLOAT_TIP="Clique para abrir",
        SPEED_INPUT_INVALID="Valor inválido",
        FLY_MODE_CHANGED="Modo de voo: %s",
        
        -- Categories
        CAT_MOVIMENTO="Movimento",
        CAT_TELEPORTE="Teleporte",
        CAT_VISUAL="Visual",
        CAT_UTILIDADES="Utilidades", 
        CAT_DEV="Dev",
        CAT_SCRIPTS="Scripts",
        
        -- Movimento features
        NOCLIP="Atravessar Paredes",
        SPRINT="Sprint",
        WALKSPEED="Velocidade Caminhada",
        JUMPPOWER="Poder de Pulo",
        HIGHJUMP="Pulo Alto",
        GRAVITY="Gravidade",
        WALKSPEED_PROTECTION="Proteção Velocidade",
        SPRINT_MULTIPLIER="Multiplicador Sprint",
        
        -- Teleporte features  
        TELEPORT_TO_PLAYER="Teletransportar para Jogador",
        WAYPOINTS="Pontos de Referência",
        REJOIN="Reconectar",
        SERVER_HOP="Mudar Servidor",
        WAYPOINT_ADD="Adicionar",
        WAYPOINT_DELETE="Deletar",
        WAYPOINT_TELEPORT="Ir para",
        WAYPOINT_NAME="Nome do ponto:",
        REFRESH_PLAYERS="Atualizar",
        
        -- Visual features
        FOV="Campo de Visão", 
        FREECAM="Câmera Livre",
        ESP="ESP Jogadores",
        HIGHLIGHTS="Destacar Jogadores",
        DISTANCE_CAP="Limite Distância",
        
        -- Utilidades features
        ANTI_AFK="Anti-AFK",
        CHAT_NOTIFY="Notificar Chat",
        LOGGER_UI="Painel de Logs",
        AUTO_EXEC="Scripts Automáticos",
        THEME_TOGGLE="Alternar Tema",
        COPY_LOGS="Copiar Logs",
        ADD_SCRIPT="Adicionar Script",
        RUN_SCRIPT="Executar",
        DELETE_SCRIPT="Deletar",
        
        -- Dev features
        EXPLORER="Explorador",
        PROPERTY_VIEWER="Visualizador de Propriedades", 
        REMOTE_SPY="Espião de Remotos",
        INSTANCE_STATS="Estatísticas",
        REFRESH="Atualizar",
        
        -- Scripts features
        SCRIPT_LOADER="Carregador de Scripts",
        
        -- Hotkeys
        HOTKEY_CAPTURE="Capturar Tecla",
        HOTKEY_NONE="Nenhuma",
        HOTKEY_CAPTURING="Pressione uma tecla...",
    },
    en = {
        UI_TITLE="Universal Hub v%s",
        MINI_HANDLE="≡",
        MINI_TIP="Drag",
        LANG_SELECT_TITLE="Select Language",
        LANG_PT="Português",
        LANG_EN="English",
        LOADED="Loaded v%s",
        FLY_ENABLED="Fly on (speed=%d)",
        FLY_DISABLED="Fly off",
        FLY_SPEED_SET="Fly speed = %d",
        FLY_ERR_NO_ROOT="HumanoidRootPart not found.",
        FLY_SPEED="Speed",
        FLY_TOGGLE_ON="Disable",
        FLY_TOGGLE_OFF="Enable",
        FLY_MODE_3D_ON="3D Mode",
        FLY_MODE_3D_OFF="Plane Mode",
        PANEL_FLY="Fly",
        PANEL_SPEED="Speed",
        PANEL_IY="IY",
        BTN_IY_LOAD="Load IY",
        IY_LOADING="Loading IY...",
        IY_LOADED="IY loaded.",
        IY_ALREADY="Already loaded.",
        IY_FAILED="Failed: %s",
        SLIDER_HINT="Drag or type value",
        BTN_CLOSE="Close",
        BTN_MINIMIZE="Minimize",
        BTN_RESTORE="Restore",
        MENU_TOGGLED="Menu toggled",
        HOTKEY_FLY="Key F: toggle fly",
        HOTKEY_MENU="RightShift: toggle menu",
        WATERMARK_ALERT="Watermark removed or changed.",
        FLY_ON_RESPAWN="Re-enabling fly after respawn...",
        CLOSE_INFO="UI destroyed. Re-run script to open again.",
        POSITION_SAVED="Position saved",
        FLOAT_TIP="Click to open",
        SPEED_INPUT_INVALID="Invalid value",
        FLY_MODE_CHANGED="Fly mode: %s",
        
        -- Categories  
        CAT_MOVIMENTO="Movement",
        CAT_TELEPORTE="Teleport",
        CAT_VISUAL="Visual",
        CAT_UTILIDADES="Utilities",
        CAT_DEV="Dev", 
        CAT_SCRIPTS="Scripts",
        
        -- Movimento features
        NOCLIP="Noclip",
        SPRINT="Sprint", 
        WALKSPEED="Walk Speed",
        JUMPPOWER="Jump Power",
        HIGHJUMP="High Jump",
        GRAVITY="Gravity",
        WALKSPEED_PROTECTION="Speed Protection",
        SPRINT_MULTIPLIER="Sprint Multiplier",
        
        -- Teleporte features
        TELEPORT_TO_PLAYER="Teleport to Player",
        WAYPOINTS="Waypoints",
        REJOIN="Rejoin",
        SERVER_HOP="Server Hop",
        WAYPOINT_ADD="Add",
        WAYPOINT_DELETE="Delete", 
        WAYPOINT_TELEPORT="Go to",
        WAYPOINT_NAME="Waypoint name:",
        REFRESH_PLAYERS="Refresh",
        
        -- Visual features
        FOV="Field of View",
        FREECAM="Freecam",
        ESP="Player ESP", 
        HIGHLIGHTS="Player Highlights",
        DISTANCE_CAP="Distance Limit",
        
        -- Utilidades features  
        ANTI_AFK="Anti-AFK",
        CHAT_NOTIFY="Chat Notifications",
        LOGGER_UI="Logger Panel",
        AUTO_EXEC="Auto Execute Scripts",
        THEME_TOGGLE="Toggle Theme",
        COPY_LOGS="Copy Logs",
        ADD_SCRIPT="Add Script", 
        RUN_SCRIPT="Run",
        DELETE_SCRIPT="Delete",
        
        -- Dev features
        EXPLORER="Explorer",
        PROPERTY_VIEWER="Property Viewer",
        REMOTE_SPY="Remote Spy", 
        INSTANCE_STATS="Instance Stats",
        REFRESH="Refresh",
        
        -- Scripts features
        SCRIPT_LOADER="Script Loader",
        
        -- Hotkeys
        HOTKEY_CAPTURE="Capture Key",
        HOTKEY_NONE="None",
        HOTKEY_CAPTURING="Press a key...",
    }
}

Lang.current = Persist.get("lang", nil)
local missingKeys = {}
local activePack = Lang.current and Lang.data[Lang.current] or nil

local function setLanguage(code)
    if Lang.data[code] then
        Lang.current = code
        activePack = Lang.data[code]
        Persist.set("lang", code)
    end
end

local function L(key, ...)
    local pack = activePack or Lang.data.en
    local s = pack[key] or Lang.data.en[key] or key
    if (not pack[key] and not Lang.data.en[key] and not missingKeys[key]) then
        missingKeys[key] = true
        Logger.Log("I18N","Missing key: "..key)
    end
    if select("#",...)>0 then
        return string.format(s,...)
    end
    return s
end

------------------------------------------------------------
-- UI HELPER FACTORIES
------------------------------------------------------------
local UIHelpers = {}

function UIHelpers.createToggle(parent, featureId, text, position)
    local feature = FeatureRegistry.get(featureId)
    if not feature then return nil end
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, scale(140), 0, scale(38))
    toggle.Position = position or UDim2.new(0, scale(20), 0, scale(20))
    toggle.BackgroundColor3 = COLORS.BTN
    toggle.TextColor3 = Color3.new(1,1,1)
    toggle.Font = Enum.Font.Gotham
    toggle.TextSize = CONFIG.FONT_MAIN_SIZE
    toggle.Text = text or L(feature.name)
    toggle.Parent = parent
    styleButton(toggle, {
        activeIndicator = function()
            return FeatureRegistry.isEnabled(featureId)
        end
    })
    
    -- Add hotkey button
    local hotkeyBtn = Instance.new("TextButton")
    hotkeyBtn.Size = UDim2.new(0, scale(20), 0, scale(20))
    hotkeyBtn.Position = UDim2.new(1, -scale(25), 0, scale(2))
    hotkeyBtn.BackgroundColor3 = COLORS.BTN
    hotkeyBtn.TextColor3 = Color3.new(1,1,1)
    hotkeyBtn.Font = Enum.Font.Code
    hotkeyBtn.TextSize = CONFIG.FONT_LABEL_SIZE
    hotkeyBtn.Text = "⌘"
    hotkeyBtn.Parent = toggle
    Instance.new("UICorner", hotkeyBtn).CornerRadius = UDim.new(0,4)
    
    local function updateHotkeyText()
        local binding = HotkeyManager.getBinding(featureId)
        hotkeyBtn.Text = binding and binding.Name:sub(1,1) or "⌘"
    end
    updateHotkeyText()
    
    hotkeyBtn.MouseButton1Click:Connect(function()
        if HotkeyManager._capturing then return end
        hotkeyBtn.Text = "..."
        HotkeyManager.startCapture(function(keyCode)
            HotkeyManager.bind(featureId, keyCode)
            updateHotkeyText()
            HotkeyManager.stopCapture()
        end)
    end)
    
    toggle.MouseButton1Click:Connect(function()
        FeatureRegistry.toggle(featureId)
        -- Update button appearance will be handled by the activeIndicator
    end)
    
    -- Subscribe to feature state changes
    EventBus.subscribe("FeatureToggled", function(toggledFeatureId, enabled)
        if toggledFeatureId == featureId then
            if toggle.Parent then
                toggle.BackgroundColor3 = enabled and COLORS.BTN_ACTIVE or COLORS.BTN
            end
        end
    end)
    
    return toggle
end

function UIHelpers.createSliderFeature(parent, featureId, min, max, step, position)
    local feature = FeatureRegistry.get(featureId)
    if not feature then return nil end
    
    step = step or 1
    local currentValue = Persist.get(featureId .. "_value", min)
    
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(0, scale(320), 0, scale(80))
    holder.Position = position or UDim2.new(0, scale(20), 0, scale(20))
    holder.BackgroundTransparency = 1
    holder.Parent = parent
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, scale(20))
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = CONFIG.FONT_LABEL_SIZE + 1
    label.TextColor3 = COLORS.TEXT_DIM
    label.Text = L(feature.name) .. ": " .. currentValue
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder
    
    -- Create slider
    local slider = createSlider(holder, min, max, 
        function() return currentValue end,
        function(value) 
            currentValue = math.floor(value / step) * step
            Persist.set(featureId .. "_value", currentValue)
            label.Text = L(feature.name) .. ": " .. currentValue
            
            -- Call feature's setValue if it exists
            if feature.setValue then
                pcall(feature.setValue, currentValue)
            end
            
            EventBus.publish("FeatureValueChanged", featureId, currentValue)
        end
    )
    
    slider.Position = UDim2.new(0, 0, 0, scale(25))
    
    return holder
end

function UIHelpers.createButton(parent, text, callback, position)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, scale(120), 0, scale(32))
    btn.Position = position or UDim2.new(0, scale(20), 0, scale(20))
    btn.BackgroundColor3 = COLORS.BTN
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = CONFIG.FONT_MAIN_SIZE
    btn.Text = text
    btn.Parent = parent
    styleButton(btn)
    
    if callback then
        btn.MouseButton1Click:Connect(callback)
    end
    
    return btn
end

function UIHelpers.createLabel(parent, text, position, size)
    local label = Instance.new("TextLabel")
    label.Size = size or UDim2.new(0, scale(200), 0, scale(20))
    label.Position = position or UDim2.new(0, scale(20), 0, scale(20))
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = CONFIG.FONT_LABEL_SIZE
    label.TextColor3 = COLORS.TEXT_DIM
    label.Text = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

function UIHelpers.createTextBox(parent, placeholder, position, size)
    local box = Instance.new("TextBox")
    box.Size = size or UDim2.new(0, scale(150), 0, scale(26))
    box.Position = position or UDim2.new(0, scale(20), 0, scale(20))
    box.BackgroundColor3 = COLORS.BTN
    box.TextColor3 = Color3.new(1,1,1)
    box.Font = Enum.Font.Code
    box.TextSize = CONFIG.FONT_LABEL_SIZE
    box.PlaceholderText = placeholder or ""
    box.Text = ""
    box.ClearTextOnFocus = false
    box.Parent = parent
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)
    return box
end

------------------------------------------------------------
-- FLY CONTROLLER
------------------------------------------------------------
local Fly = {
    active = false,
    speed = tonumber(Persist.get("fly_speed", CONFIG.FLY_DEFAULT_SPEED)) or CONFIG.FLY_DEFAULT_SPEED,
    conn  = nil,
    debounceToggle = 0.15,
    lastToggle = 0,
    full3D = Persist.get("fly_full3d", nil),
    _vel = Vector3.zero,
}

-- define default full3D for mobile if nil
if Fly.full3D == nil then
    Fly.full3D = (UserInputService.TouchEnabled and CONFIG.MOBILE_FULL3D_DEFAULT) or false
end

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local char=LocalPlayer.Character
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

-- Direção horizontal + opcional vertical via pitch da câmera
local function computeDirection(hum,cam)
    local move = hum.MoveDirection
    if move.Magnitude == 0 then return Vector3.zero end

    local cf = cam.CFrame
    local look = cf.LookVector
    -- Componentes planos
    local forwardFlat = Vector3.new(look.X,0,look.Z)
    if forwardFlat.Magnitude < 1e-4 then
        forwardFlat = Vector3.new(0,0,-1)
    else
        forwardFlat = forwardFlat.Unit
    end
    local rightFlat = Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit

    -- Decompõe MoveDirection (mundo) em eixos da câmera no plano
    local x = move:Dot(rightFlat)
    local z = move:Dot(forwardFlat)
    local dir = (rightFlat * x) + (forwardFlat * z)

    if Fly.full3D then
        -- Adiciona componente vertical baseado no pitch da câmera só quando há input forward/back (z)
        -- Evita subir/ descer sem mover analógico
        if math.abs(z) > 0.01 then
            local pitchY = look.Y -- -1 a 1
            if math.abs(pitchY) > CONFIG.FLY_MIN_PITCH_TO_LIFT then
                dir = dir + Vector3.new(0, pitchY * math.abs(z) * CONFIG.FLY_VERTICAL_SCALE, 0)
            end
        end
    end

    if dir.Magnitude > 0 then
        dir = dir.Unit
    else
        dir = Vector3.zero
    end
    return dir
end

function Fly.setSpeed(n)
    n = tonumber(n)
    if not n then return end
    n = math.clamp(math.floor(n+0.5), CONFIG.FLY_MIN_SPEED, CONFIG.FLY_MAX_SPEED)
    Fly.speed = n
    Persist.set("fly_speed", n)
    notify("Fly", L("FLY_SPEED_SET", n))
end

function Fly.setMode(full3d)
    Fly.full3D = full3d and true or false
    Persist.set("fly_full3d", Fly.full3D)
    notify("Fly", L("FLY_MODE_CHANGED", Fly.full3D and L("FLY_MODE_3D_ON") or L("FLY_MODE_3D_OFF")))
end

function Fly.enable()
    if Fly.active then return end
    local root = getRoot()
    if not root then
        notify("Fly", L("FLY_ERR_NO_ROOT"))
        return
    end
    Fly.active = true
    if Fly.conn then Fly.conn:Disconnect() end
    Fly.conn = RunService.Heartbeat:Connect(function(dt)
        if not Fly.active then return end
        local r = getRoot(); if not r then return end
        local hum = getHum(); if not hum then return end
        local cam = workspace.CurrentCamera; if not cam then return end

        local dir = computeDirection(hum, cam)
        local targetVel = dir * Fly.speed

        -- Suavização
        if CONFIG.FLY_SMOOTHNESS > 0 then
            Fly._vel = Fly._vel:Lerp(targetVel, 1 - math.pow(1-CONFIG.FLY_SMOOTHNESS, math.clamp(dt*60,0,5)))
        else
            Fly._vel = targetVel
        end

        local vel = Fly._vel
        -- Evita acumular gravidade residual
        if r.AssemblyLinearVelocity then
            r.AssemblyLinearVelocity = Vector3.new(vel.X, vel.Y, vel.Z)
        else
            r.Velocity = vel
        end
    end)
    notify("Fly", L("FLY_ENABLED", Fly.speed))
end

function Fly.disable()
    if not Fly.active then return end
    Fly.active=false
    if Fly.conn then Fly.conn:Disconnect(); Fly.conn=nil end
    local r=getRoot()
    if r then
        if r.AssemblyLinearVelocity then
            r.AssemblyLinearVelocity = Vector3.zero
        else
            r.Velocity = Vector3.zero
        end
    end
    Fly._vel = Vector3.zero
    notify("Fly", L("FLY_DISABLED"))
end

function Fly.toggle()
    local now = time()
    if now - Fly.lastToggle < Fly.debounceToggle then return end
    Fly.lastToggle = now
    if Fly.active then Fly.disable() else Fly.enable() end
end

LocalPlayer.CharacterAdded:Connect(function()
    if Fly.active then
        notify("Fly", L("FLY_ON_RESPAWN"))
        task.wait(1)
        Fly.enable()
    end
end)

------------------------------------------------------------
-- CORE FEATURES IMPLEMENTATION
------------------------------------------------------------

-- Register Fly feature in the registry
FeatureRegistry.register("fly", {
    name = "FLY_TOGGLE_OFF",
    category = "Movimento", 
    defaultEnabled = false,
    hotkey = CONFIG.HOTKEY_TOGGLE_FLY,
    onEnable = function() Fly.enable() end,
    onDisable = function() Fly.disable() end,
    onToggle = function(enabled)
        if UI.Elements.FlyToggle then
            UI.Elements.FlyToggle.Text = enabled and L("FLY_TOGGLE_ON") or L("FLY_TOGGLE_OFF")
        end
    end
})

-- Movimento category features
local MovimentoFeatures = {}

-- Noclip
MovimentoFeatures.noclip = {
    active = false,
    originalCanCollide = {}
}

FeatureRegistry.register("noclip", {
    name = "NOCLIP",
    category = "Movimento",
    defaultEnabled = false,
    hotkey = Enum.KeyCode.RightControl,
    onEnable = function()
        MovimentoFeatures.noclip.active = true
        MovimentoFeatures.noclip.originalCanCollide = {}
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    MovimentoFeatures.noclip.originalCanCollide[part] = part.CanCollide
                    part.CanCollide = false
                end
            end
        end
    end,
    onDisable = function()
        MovimentoFeatures.noclip.active = false
        for part, originalValue in pairs(MovimentoFeatures.noclip.originalCanCollide) do
            if part and part.Parent then
                part.CanCollide = originalValue
            end
        end
        MovimentoFeatures.noclip.originalCanCollide = {}
    end
})

-- Stepped connection for noclip
RunService.Stepped:Connect(function()
    if MovimentoFeatures.noclip.active then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- Sprint
MovimentoFeatures.sprint = {
    active = false,
    originalSpeed = 16,
    multiplier = Persist.get("sprint_multiplier", 2),
    isHolding = false
}

FeatureRegistry.register("sprint", {
    name = "SPRINT", 
    category = "Movimento",
    defaultEnabled = false,
    setValue = function(value)
        MovimentoFeatures.sprint.multiplier = value
    end
})

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.LeftShift and FeatureRegistry.isEnabled("sprint") then
        MovimentoFeatures.sprint.isHolding = true
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            MovimentoFeatures.sprint.originalSpeed = hum.WalkSpeed
            hum.WalkSpeed = MovimentoFeatures.sprint.originalSpeed * MovimentoFeatures.sprint.multiplier
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.LeftShift and MovimentoFeatures.sprint.isHolding then
        MovimentoFeatures.sprint.isHolding = false
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            hum.WalkSpeed = MovimentoFeatures.sprint.originalSpeed
        end
    end
end)

-- WalkSpeed
MovimentoFeatures.walkSpeed = {
    value = Persist.get("walkspeed_value", 16),
    protection = Persist.get("walkspeed_protection", false),
    conn = nil
}

FeatureRegistry.register("walkspeed", {
    name = "WALKSPEED",
    category = "Movimento", 
    defaultEnabled = false,
    setValue = function(value)
        MovimentoFeatures.walkSpeed.value = value
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            hum.WalkSpeed = value
        end
    end
})

FeatureRegistry.register("walkspeed_protection", {
    name = "WALKSPEED_PROTECTION",
    category = "Movimento",
    defaultEnabled = false,
    onEnable = function()
        MovimentoFeatures.walkSpeed.protection = true
        if MovimentoFeatures.walkSpeed.conn then MovimentoFeatures.walkSpeed.conn:Disconnect() end
        MovimentoFeatures.walkSpeed.conn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.WalkSpeed ~= MovimentoFeatures.walkSpeed.value then
                hum.WalkSpeed = MovimentoFeatures.walkSpeed.value
            end
        end)
    end,
    onDisable = function()
        MovimentoFeatures.walkSpeed.protection = false
        if MovimentoFeatures.walkSpeed.conn then
            MovimentoFeatures.walkSpeed.conn:Disconnect()
            MovimentoFeatures.walkSpeed.conn = nil
        end
    end
})

-- JumpPower/JumpHeight  
MovimentoFeatures.jump = {
    value = Persist.get("jump_value", 50)
}

FeatureRegistry.register("jumppower", {
    name = "JUMPPOWER",
    category = "Movimento",
    defaultEnabled = false,
    setValue = function(value)
        MovimentoFeatures.jump.value = value
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            if hum.JumpHeight then
                hum.JumpHeight = value
            elseif hum.JumpPower then
                hum.JumpPower = value
            end
        end
    end
})

-- High Jump
MovimentoFeatures.highJump = {
    cooldown = 0,
    force = Persist.get("highjump_force", 100)
}

FeatureRegistry.register("highjump", {
    name = "HIGHJUMP",
    category = "Movimento",
    defaultEnabled = false
})

function MovimentoFeatures.performHighJump()
    if time() - MovimentoFeatures.highJump.cooldown < 1 then return end
    MovimentoFeatures.highJump.cooldown = time()
    
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
        bodyVelocity.Velocity = Vector3.new(0, MovimentoFeatures.highJump.force, 0)
        bodyVelocity.Parent = root
        
        task.wait(0.1)
        bodyVelocity:Destroy()
    end
end

-- Gravity
MovimentoFeatures.gravity = {
    originalValue = workspace.Gravity,
    value = Persist.get("gravity_value", 196.2)
}

FeatureRegistry.register("gravity", {
    name = "GRAVITY",
    category = "Movimento",
    defaultEnabled = false,
    setValue = function(value)
        MovimentoFeatures.gravity.value = value
        if FeatureRegistry.isEnabled("gravity") then
            workspace.Gravity = value
        end
    end,
    onEnable = function()
        MovimentoFeatures.gravity.originalValue = workspace.Gravity
        workspace.Gravity = MovimentoFeatures.gravity.value
    end,
    onDisable = function()
        workspace.Gravity = MovimentoFeatures.gravity.originalValue
    end
})

------------------------------------------------------------
-- UI
------------------------------------------------------------
local UI = {
    Screen = nil,
    FloatingGui = nil,
    FloatingButton = nil,
    Panels = {},
    CurrentPanel = nil,
    Translatables = {},
    Elements = {},
    Destroyed = false,
    PanelButtons = {},
}

local function markTrans(instance,key,...)
    table.insert(UI.Translatables,{instance=instance,key=key,args={...}})
end

function UI.applyLanguage()
    if not activePack then return end
    for _,d in ipairs(UI.Translatables) do
        local inst=d.instance
        if inst and inst.Parent and (inst:IsA("TextLabel") or inst:IsA("TextButton")) then
            local txt = (#d.args>0) and L(d.key, table.unpack(d.args)) or L(d.key)
            inst.Text = txt
        end
    end
    if UI.Elements.Title then UI.Elements.Title.Text = L("UI_TITLE", VERSION) end
    if UI.Elements.FlyToggle then
        UI.Elements.FlyToggle.Text = Fly.active and L("FLY_TOGGLE_ON") or L("FLY_TOGGLE_OFF")
    end
    if UI.Elements.SpeedLabel then
        UI.Elements.SpeedLabel.Text = L("FLY_SPEED")..": "..Fly.speed
    end
    if UI.Elements.SliderHint then
        UI.Elements.SliderHint.Text = L("SLIDER_HINT")
    end
    if UI.Elements.ModeButton then
        UI.Elements.ModeButton.Text = Fly.full3D and L("FLY_MODE_3D_ON") or L("FLY_MODE_3D_OFF")
    end
end

local function styleButton(btn, opts)
    btn.AutoButtonColor = false
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = CONFIG.FONT_MAIN_SIZE
    btn.BackgroundColor3 = COLORS.BTN
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,6)
    corner.Parent = btn
    if opts and opts.danger then
        btn.BackgroundColor3 = COLORS.BTN_DANGER
    end
    btn.MouseEnter:Connect(function()
        if not (opts and opts.activeIndicator) then
            btn.BackgroundColor3 = COLORS.BTN_HOVER
        end
    end)
    btn.MouseLeave:Connect(function()
        if opts and opts.activeIndicator and opts.activeIndicator()==true then
            btn.BackgroundColor3 = COLORS.BTN_ACTIVE
        else
            btn.BackgroundColor3 = opts and opts.danger and COLORS.BTN_DANGER or COLORS.BTN
        end
    end)
end

local function highlightPanelButton(activeBtn)
    for btn,data in pairs(UI.PanelButtons) do
        if btn == activeBtn then
            btn.BackgroundColor3 = COLORS.BTN_ACTIVE
        else
            btn.BackgroundColor3 = COLORS.BTN
        end
    end
end

local function showPanel(panel)
    UI.CurrentPanel = panel
    for _,p in pairs(UI.Panels) do
        p.Visible = (p == panel)
    end
end

-- Slider genérico
local function createSlider(parent, minVal, maxVal, getVal, setVal)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(0, scale(300), 0, scale(60))
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0, scale(170), 0, scale(10))
    barBg.Position = UDim2.new(0, 0, 0, scale(8))
    barBg.BackgroundColor3 = COLORS.SLIDER_BG
    barBg.Parent = holder
    Instance.new("UICorner",barBg).CornerRadius = UDim.new(0,5)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = COLORS.SLIDER_FILL
    fill.Parent = barBg
    Instance.new("UICorner",fill).CornerRadius = UDim.new(0,5)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, scale(14), 0, scale(14))
    knob.AnchorPoint = Vector2.new(0.5,0.5)
    knob.Position = UDim2.new(0,0,0.5,0)
    knob.BackgroundColor3 = COLORS.SLIDER_KNOB
    knob.Parent = barBg
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, scale(100), 0, scale(26))
    box.Position = UDim2.new(0, scale(190), 0, scale(-2))
    box.BackgroundColor3 = COLORS.BTN
    box.TextColor3 = Color3.new(1,1,1)
    box.Font = Enum.Font.Code
    box.TextSize = CONFIG.FONT_LABEL_SIZE
    box.PlaceholderText = tostring(getVal())
    box.Text = ""
    box.ClearTextOnFocus = false
    box.Parent = holder
    Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)

    local hint = Instance.new("TextLabel")
    hint.BackgroundTransparency = 1
    hint.Size = UDim2.new(1,0,0, scale(18))
    hint.Position = UDim2.new(0,0,0, scale(28))
    hint.Font = Enum.Font.Gotham
    hint.TextSize = CONFIG.FONT_LABEL_SIZE
    hint.TextColor3 = COLORS.TEXT_SUB
    hint.Text = ""
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.Parent = holder
    UI.Elements.SliderHint = hint
    markTrans(hint,"SLIDER_HINT")

    local function refresh()
        local v = getVal()
        local alpha = (v - minVal)/(maxVal - minVal)
        alpha = math.clamp(alpha,0,1)
        fill.Size = UDim2.new(alpha,0,1,0)
        knob.Position = UDim2.new(alpha,0,0.5,0)
        box.PlaceholderText = tostring(v)
        if UI.Elements.SpeedLabel then
            UI.Elements.SpeedLabel.Text = L("FLY_SPEED")..": "..v
        end
    end
    refresh()

    local dragging = false
    local function setFromInput(px)
        local rel = (px - barBg.AbsolutePosition.X)/barBg.AbsoluteSize.X
        rel = math.clamp(rel,0,1)
        local val = math.floor(minVal + rel*(maxVal-minVal) + 0.5)
        setVal(val)
        refresh()
    end

    barBg.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging = true
            setFromInput(i.Position.X)
        end
    end)
    barBg.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    barBg.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            setFromInput(i.Position.X)
        end
    end)

    box.FocusLost:Connect(function(enter)
        if enter then
            local num = tonumber(box.Text)
            if num then
                num = math.clamp(math.floor(num+0.5), minVal, maxVal)
                setVal(num)
            else
                notify("Speed", L("SPEED_INPUT_INVALID"))
            end
            box.Text=""
            refresh()
        end
    end)

    return holder
end

-- Botão flutuante
function UI.createFloatingButton()
    if UI.FloatingGui then UI.FloatingGui:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name="UH_Float"
    sg.ResetOnSpawn=false
    safeParent(sg)
    UI.FloatingGui = sg

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, scale(CONFIG.MINI_BUTTON_SIZE), 0, scale(CONFIG.MINI_BUTTON_SIZE))
    local savedPos = Persist.get("float_pos", nil)
    if savedPos and type(savedPos)=="table" and savedPos.x and savedPos.y then
        btn.Position = UDim2.new(0, savedPos.x, 0, savedPos.y)
    else
        btn.Position = CONFIG.MINI_START_POS
    end
    btn.BackgroundColor3 = COLORS.BTN_MINI
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = math.floor(CONFIG.FONT_MAIN_SIZE+4)
    btn.Text = L("MINI_HANDLE")
    btn.Parent = sg
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
    btn.AutoButtonColor=false
    btn.Visible = false
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = COLORS.BTN_HOVER end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = COLORS.BTN_MINI end)

    UI.FloatingButton = btn

    local dragging=false
    local dragStart, startPos
    local function updatePos(input)
        local delta = input.Position - dragStart
        local newX = startPos.X.Offset + delta.X
        local newY = startPos.Y.Offset + delta.Y
        btn.Position = UDim2.new(0,newX,0,newY)
    end
    btn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=i.Position
            startPos=btn.Position
            i.Changed:Connect(function(s)
                if s==Enum.UserInputState.End then
                    dragging=false
                    Persist.set("float_pos",{x=btn.Position.X.Offset, y=btn.Position.Y.Offset})
                    notify("UI", L("POSITION_SAVED"), 2)
                end
            end)
        end
    end)
    btn.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            updatePos(i)
        end
    end)

    btn.MouseButton1Click:Connect(function()
        if UI.Screen and not UI.Destroyed then
            UI.Screen.Enabled = true
            btn.Visible = false
        end
    end)
end

-- Criação da UI principal
function UI.create()
    if UI.Screen and UI.Screen.Parent then
        UI.Screen:Destroy()
    end
    UI.Destroyed=false

    local sg = Instance.new("ScreenGui")
    sg.Name="UH_Main"
    sg.ResetOnSpawn=false
    safeParent(sg)
    UI.Screen=sg

    local frame = Instance.new("Frame")
    frame.Size=UDim2.new(0,scale(CONFIG.WINDOW_WIDTH),0,scale(CONFIG.WINDOW_HEIGHT))
    frame.Position=UDim2.new(0.5, -scale(CONFIG.WINDOW_WIDTH)/2, 0.45, -scale(CONFIG.WINDOW_HEIGHT)/2)
    frame.BackgroundColor3 = COLORS.BG_MAIN
    frame.Parent=sg
    UI.Frame = frame
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,12)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,scale(CONFIG.TOPBAR_HEIGHT))
    top.BackgroundColor3 = COLORS.BG_TOP
    top.Parent = frame
    Instance.new("UICorner",top).CornerRadius = UDim.new(0,12)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Size=UDim2.new(0.6,0,1,0)
    title.Position=UDim2.new(0,scale(CONFIG.PADDING),0,0)
    title.Font=Enum.Font.GothamBold
    title.TextSize=CONFIG.FONT_MAIN_SIZE+1
    title.TextColor3=Color3.new(1,1,1)
    title.Text=L("UI_TITLE", VERSION)
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=top
    UI.Elements.Title=title
    markTrans(title,"UI_TITLE",VERSION)

    local watermark = Instance.new("TextLabel")
    watermark.BackgroundTransparency=1
    watermark.Font=Enum.Font.GothamBold
    watermark.TextSize=CONFIG.FONT_MAIN_SIZE
    watermark.TextColor3=Color3.fromRGB(255,255,255)
    watermark.TextStrokeTransparency=0.5
    watermark.Text=CONFIG.WATERMARK
    watermark.Size=UDim2.new(0,170,1,0)
    watermark.AnchorPoint=Vector2.new(1,0)
    watermark.Position=UDim2.new(1,-scale(150),0,0)
    watermark.TextXAlignment=Enum.TextXAlignment.Right
    watermark.Parent=top
    UI.Elements.WatermarkLabel = watermark

    local btnClose = Instance.new("TextButton")
    btnClose.Size=UDim2.new(0,scale(60),0,scale(CONFIG.TOPBAR_HEIGHT-8))
    btnClose.Position=UDim2.new(1,-scale(64),0,scale(4))
    btnClose.Text=L("BTN_CLOSE")
    btnClose.Font=Enum.Font.GothamBold
    btnClose.TextSize=CONFIG.FONT_LABEL_SIZE+1
    btnClose.BackgroundColor3=COLORS.BTN_DANGER
    btnClose.TextColor3=Color3.new(1,1,1)
    btnClose.Parent=top
    styleButton(btnClose,{danger=true})
    markTrans(btnClose,"BTN_CLOSE")

    local btnMinimize = Instance.new("TextButton")
    btnMinimize.Size=UDim2.new(0,scale(80),0,scale(CONFIG.TOPBAR_HEIGHT-8))
    btnMinimize.Position=UDim2.new(1,-scale(64+86),0,scale(4))
    btnMinimize.Text=L("BTN_MINIMIZE")
    btnMinimize.Font=Enum.Font.GothamBold
    btnMinimize.TextSize=CONFIG.FONT_LABEL_SIZE
    btnMinimize.BackgroundColor3=COLORS.BTN
    btnMinimize.TextColor3=Color3.new(1,1,1)
    btnMinimize.Parent=top
    styleButton(btnMinimize)
    markTrans(btnMinimize,"BTN_MINIMIZE")

    local content = Instance.new("Frame")
    content.Size=UDim2.new(1,0,1,-scale(CONFIG.TOPBAR_HEIGHT))
    content.Position=UDim2.new(0,0,0,scale(CONFIG.TOPBAR_HEIGHT))
    content.BackgroundTransparency=1
    content.Parent=frame

    -- Coluna esquerda (category buttons)
    local left = Instance.new("Frame")
    left.Size=UDim2.new(0,scale(120),1,0)
    left.BackgroundColor3=COLORS.BG_LEFT
    left.Parent=content
    Instance.new("UICorner",left).CornerRadius=UDim.new(0,10)

    local list = Instance.new("UIListLayout", left)
    list.SortOrder=Enum.SortOrder.LayoutOrder
    list.Padding=UDim.new(0,scale(6))
    list.HorizontalAlignment=Enum.HorizontalAlignment.Center
    list.VerticalAlignment=Enum.VerticalAlignment.Top

    local function makeCategoryButton(categoryName)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -scale(16), 0, scale(34))
        b.BackgroundColor3 = COLORS.BTN
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.Gotham
        b.TextSize = CONFIG.FONT_MAIN_SIZE
        b.Text = L("CAT_" .. categoryName:upper())
        b.Parent = left
        styleButton(b, {
            activeIndicator = function()
                return UI.CurrentPanel and UI.PanelButtons[b] == UI.CurrentPanel
            end
        })
        markTrans(b, "CAT_" .. categoryName:upper())
        return b
    end

    local right = Instance.new("Frame")
    right.Size=UDim2.new(1,-scale(132),1,0)
    right.Position=UDim2.new(0,scale(132),0,0)
    right.BackgroundColor3=COLORS.BG_RIGHT
    right.Parent=content
    Instance.new("UICorner",right).CornerRadius=UDim.new(0,10)

    local function createCategoryPanel(categoryName)
        local panel = Instance.new("Frame")
        panel.Size = UDim2.new(1,0,1,0)
        panel.BackgroundTransparency = 1
        panel.Visible = false
        panel.Parent = right
        
        -- Add scrolling frame for content
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = UDim2.new(1, -scale(20), 1, -scale(20))
        scrollFrame.Position = UDim2.new(0, scale(10), 0, scale(10))
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.BorderSizePixel = 0
        scrollFrame.ScrollBarThickness = 6
        scrollFrame.ScrollBarImageColor3 = COLORS.ACCENT
        scrollFrame.CanvasSize = UDim2.new(0,0,0,0)
        scrollFrame.Parent = panel
        
        local layout = Instance.new("UIListLayout", scrollFrame)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, scale(8))
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        
        -- Update canvas size when content changes
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollFrame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + scale(20))
        end)
        
        table.insert(UI.Panels, panel)
        return panel, scrollFrame
    end

    -- Create panels for each category
    local categoryPanels = {}
    local categoryButtons = {}
    
    for _, categoryName in ipairs(FeatureRegistry.getAllCategories()) do
        local panel, scrollFrame = createCategoryPanel(categoryName)
        local button = makeCategoryButton(categoryName)
        
        categoryPanels[categoryName] = { panel = panel, scrollFrame = scrollFrame }
        categoryButtons[categoryName] = button
        UI.PanelButtons[button] = panel
        
        -- Generate UI for features in this category
        UI.generateCategoryUI(categoryName, scrollFrame)
        
        button.MouseButton1Click:Connect(function()
            showPanel(panel)
            highlightPanelButton(button)
        end)
    end

    -- Show first panel by default
    local firstCategory = FeatureRegistry.getAllCategories()[1]
    if firstCategory and categoryPanels[firstCategory] then
        showPanel(categoryPanels[firstCategory].panel)
        highlightPanelButton(categoryButtons[firstCategory])
    end

    -- Drag janela
    local dragging=false
    local dragStart,startPos
    local function updateWindow(input)
        local delta=input.Position - dragStart
        frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
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
            updateWindow(i)
        end
    end)

    -- Minimizar
    btnMinimize.MouseButton1Click:Connect(function()
        if UI.FloatingButton then
            UI.FloatingButton.Visible=true
        end
        UI.Screen.Enabled=false
    end)

    -- Fechar (destrói)
    btnClose.MouseButton1Click:Connect(function()
        UI.Destroyed=true
        if UI.Screen then
            UI.Screen:Destroy()
        end
        if UI.FloatingButton then
            UI.FloatingButton.Visible=true
        end
        notify("UI", L("CLOSE_INFO"))
    end)

    UI.applyLanguage()
    notify("Utility", L("LOADED", VERSION), 3)
end

-- Function to generate UI for a specific category
function UI.generateCategoryUI(categoryName, parent)
    local features = FeatureRegistry.getByCategory(categoryName)
    local yPos = 0
    
    for featureId, feature in pairs(features) do
        if categoryName == "Movimento" then
            UI.generateMovimentoUI(featureId, feature, parent, yPos)
        elseif categoryName == "Teleporte" then
            UI.generateTeleporteUI(featureId, feature, parent, yPos) 
        elseif categoryName == "Visual" then
            UI.generateVisualUI(featureId, feature, parent, yPos)
        elseif categoryName == "Utilidades" then
            UI.generateUtilidadesUI(featureId, feature, parent, yPos)
        elseif categoryName == "Dev" then
            UI.generateDevUI(featureId, feature, parent, yPos)
        elseif categoryName == "Scripts" then
            UI.generateScriptsUI(featureId, feature, parent, yPos)
        end
        yPos = yPos + 60 -- Adjust spacing as needed
    end
end

-- Category-specific UI generators
function UI.generateMovimentoUI(featureId, feature, parent, yPos)
    if featureId == "fly" then
        -- Custom fly UI
        local toggle = UIHelpers.createToggle(parent, featureId, 
            Fly.active and L("FLY_TOGGLE_ON") or L("FLY_TOGGLE_OFF"), 
            UDim2.new(0, scale(20), 0, yPos))
        UI.Elements.FlyToggle = toggle
        
        local modeBtn = UIHelpers.createButton(parent, 
            Fly.full3D and L("FLY_MODE_3D_ON") or L("FLY_MODE_3D_OFF"),
            function()
                Fly.setMode(not Fly.full3D)
                UI.applyLanguage()
            end,
            UDim2.new(0, scale(170), 0, yPos))
        UI.Elements.ModeButton = modeBtn
        
        -- Speed slider
        local speedSlider = UIHelpers.createSliderFeature(parent, "fly_speed", 
            CONFIG.FLY_MIN_SPEED, CONFIG.FLY_MAX_SPEED, 1, 
            UDim2.new(0, scale(20), 0, yPos + 50))
            
    elseif featureId == "sprint" then
        UIHelpers.createToggle(parent, featureId, nil, UDim2.new(0, scale(20), 0, yPos))
        UIHelpers.createSliderFeature(parent, "sprint_multiplier", 1.5, 5, 0.1, 
            UDim2.new(0, scale(170), 0, yPos))
            
    elseif featureId == "walkspeed" then
        UIHelpers.createToggle(parent, featureId, nil, UDim2.new(0, scale(20), 0, yPos))
        UIHelpers.createSliderFeature(parent, "walkspeed", 16, 200, 1, 
            UDim2.new(0, scale(170), 0, yPos))
        UIHelpers.createToggle(parent, "walkspeed_protection", nil, UDim2.new(0, scale(20), 0, yPos + 50))
        
    elseif featureId == "jumppower" then
        UIHelpers.createToggle(parent, featureId, nil, UDim2.new(0, scale(20), 0, yPos))
        UIHelpers.createSliderFeature(parent, "jump", 50, 200, 1, 
            UDim2.new(0, scale(170), 0, yPos))
            
    elseif featureId == "highjump" then
        UIHelpers.createButton(parent, L("HIGHJUMP"), function()
            MovimentoFeatures.performHighJump()
        end, UDim2.new(0, scale(20), 0, yPos))
        
    elseif featureId == "gravity" then
        UIHelpers.createToggle(parent, featureId, nil, UDim2.new(0, scale(20), 0, yPos))
        UIHelpers.createSliderFeature(parent, "gravity", 0, 400, 1, 
            UDim2.new(0, scale(170), 0, yPos))
            
    else
        -- Default toggle for other features
        UIHelpers.createToggle(parent, featureId, nil, UDim2.new(0, scale(20), 0, yPos))
    end
end

function UI.generateTeleporteUI(featureId, feature, parent, yPos)
    -- Placeholder for teleporte features
    UIHelpers.createToggle(parent, featureId, nil, UDim2.new(0, scale(20), 0, yPos))
end

function UI.generateVisualUI(featureId, feature, parent, yPos)
    -- Placeholder for visual features
    UIHelpers.createToggle(parent, featureId, nil, UDim2.new(0, scale(20), 0, yPos))
end

function UI.generateUtilidadesUI(featureId, feature, parent, yPos)
    -- Placeholder for utilidades features
    UIHelpers.createToggle(parent, featureId, nil, UDim2.new(0, scale(20), 0, yPos))
end

function UI.generateDevUI(featureId, feature, parent, yPos)
    -- Placeholder for dev features
    UIHelpers.createToggle(parent, featureId, nil, UDim2.new(0, scale(20), 0, yPos))
end

function UI.generateScriptsUI(featureId, feature, parent, yPos)
    if featureId == "infiniteyield" then
        -- Custom IY loader UI
        local status = UIHelpers.createLabel(parent, 
            _G.__UH_IY_LOADED and "IY: ON" or "IY: OFF",
            UDim2.new(0, scale(20), 0, yPos))
        UI.Elements.IYStatus = status
        
        local loadBtn = UIHelpers.createButton(parent, L("BTN_IY_LOAD"), function()
            -- IY loading logic (kept from original)
            local loading = false
            if loading then return end
            if _G.__UH_IY_LOADED then
                notify("IY", L("IY_ALREADY"))
                return
            end
            loading = true
            notify("IY", L("IY_LOADING"))
            task.spawn(function()
                local ok,err = pcall(function()
                    local src = game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
                    if #src < 5000 then
                        error("Source too small / suspicious")
                    end
                    loadstring(src)()
                end)
                if ok then
                    _G.__UH_IY_LOADED=true
                    notify("IY", L("IY_LOADED"))
                    if UI.Elements.IYStatus then UI.Elements.IYStatus.Text="IY: ON" end
                else
                    notify("IY", L("IY_FAILED", tostring(err)))
                end
                loading=false
            end)
        end, UDim2.new(0, scale(170), 0, yPos))
        
    else
        UIHelpers.createToggle(parent, featureId, nil, UDim2.new(0, scale(20), 0, yPos))
    end
end

------------------------------------------------------------
-- WATERMARK WATCHER
------------------------------------------------------------
local function startWatermarkEnforcer()
    if not CONFIG.ENABLE_WATERMARK_WATCH then return end
    task.spawn(function()
        task.wait(1.2)
        while UI.Screen and not UI.Destroyed do
            local ok=true
            if not UI.Elements.WatermarkLabel or not UI.Elements.WatermarkLabel.Parent then
                ok=false
            else
                if UI.Elements.WatermarkLabel.Text ~= CONFIG.WATERMARK then
                    ok=false
                end
            end
            if not ok then
                notify("Security", L("WATERMARK_ALERT"))
                Logger.Log("SEC","Watermark changed or removed.")
                break
            end
            task.wait(randRange(CONFIG.WATERMARK_CHECK_INTERVAL.min, CONFIG.WATERMARK_CHECK_INTERVAL.max))
        end
    end)
end

------------------------------------------------------------
-- HOTKEYS
------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    
    -- Handle hotkey capture
    if HotkeyManager._capturing and HotkeyManager._captureCallback then
        HotkeyManager._captureCallback(input.KeyCode)
        return
    end
    
    -- Handle bound feature hotkeys
    local featureId = HotkeyManager._bindings[input.KeyCode]
    if featureId then
        FeatureRegistry.toggle(featureId)
        return
    end
    
    -- Legacy hotkey handling (kept for backward compatibility)
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
    end
end)

------------------------------------------------------------
-- SELEÇÃO DE IDIOMA INICIAL
------------------------------------------------------------
local function showLanguageSelect(onChosen)
    local sg = Instance.new("ScreenGui")
    sg.Name="UH_LanguageSelect"
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

    local function mk(btnText, offsetX, code)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0.5,-40,0,58)
        b.Position=UDim2.new(offsetX,20,0,90)
        b.BackgroundColor3=COLORS.BTN
        b.TextColor3=Color3.new(1,1,1)
        b.TextSize=18
        b.Font=Enum.Font.GothamBold
        b.Text=btnText
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

------------------------------------------------------------
-- INICIALIZAÇÃO
------------------------------------------------------------

-- Register Infinite Yield feature
FeatureRegistry.register("infiniteyield", {
    name = "BTN_IY_LOAD",
    category = "Scripts",
    defaultEnabled = false
})

UI.createFloatingButton()

-- Load saved hotkeys after all features are registered
HotkeyManager.loadSavedHotkeys()

if Lang.current and Lang.data[Lang.current] then
    setLanguage(Lang.current)
    UI.create()
    if UI.FloatingButton then UI.FloatingButton.Visible=false end
else
    showLanguageSelect(function()
        UI.create()
        if UI.FloatingButton then UI.FloatingButton.Visible=false end
    end)
end

startWatermarkEnforcer()

-- Export
_G.__UNIVERSAL_HUB_EXPORTS = {
    VERSION = VERSION,
    CONFIG = CONFIG,
    Persist = Persist,
    Lang = Lang,
    Fly = Fly,
    UI = UI,
    Logger = Logger,
    EventBus = EventBus,
    FeatureRegistry = FeatureRegistry,
    HotkeyManager = HotkeyManager,
    UIHelpers = UIHelpers,
}