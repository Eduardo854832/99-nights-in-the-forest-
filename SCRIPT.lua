-- Universal Utility - Improved Phase 1 (v0.8.0)
-- Autor: Refatoração automática assistida (Copilot)
-- Objetivo: Melhor arquitetura, performance, extensibilidade e robustez.

local VERSION = "0.8.0"

--------------------------------------------------
-- Serviços Roblox
--------------------------------------------------
local Services = setmetatable({}, {__index=function(t,k) local s=game:GetService(k); rawset(t,k,s); return s end})
local Players            = Services.Players
local RunService         = Services.RunService
local UserInputService   = Services.UserInputService
local TweenService       = Services.TweenService
local StarterGui         = Services.StarterGui
local Stats              = Services.Stats
local Lighting           = Services.Lighting
local HttpService        = Services.HttpService

local LocalPlayer = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

--------------------------------------------------
-- Idempotência: limpar execuções antigas
--------------------------------------------------
for _, guiName in ipairs({"UniversalUtility_UI","UU_LangSelect","UU_Overlay"}) do
    local old = (gethui and gethui() or game:GetService("CoreGui")):FindFirstChild(guiName)
    if old then pcall(function() old:Destroy() end) end
end

--------------------------------------------------
-- Persistência (com flush e throttle)
--------------------------------------------------
local Persist = {}
Persist._fileName = "UniversalUtilityConfig.json"
Persist._data = {}
Persist._dirty = false
Persist._lastFlush = 0
Persist._pending = {}
local hasFS = (typeof(isfile)=="function" and typeof(readfile)=="function" and typeof(writefile)=="function")

function Persist.load()
    if hasFS and isfile(Persist._fileName) then
        pcall(function()
            local raw = readfile(Persist._fileName)
            local dec = HttpService:JSONDecode(raw)
            if type(dec)=="table" then Persist._data = dec end
        end)
    end
    Persist._data._configVersion = Persist._data._configVersion or 1
end

function Persist._scheduleFlush()
    Persist._dirty = true
end

function Persist.flush(force)
    if not hasFS then return end
    if not Persist._dirty and not force then return end
    pcall(function()
        writefile(Persist._fileName, HttpService:JSONEncode(Persist._data))
    end)
    Persist._dirty = false
    Persist._pending = {}
    Persist._lastFlush = tick()
end

function Persist.get(key, default)
    local v = Persist._data[key]
    if v == nil then
        if default ~= nil then
            Persist._data[key] = default
            Persist._scheduleFlush()
        end
        return default
    end
    return v
end

function Persist.setIfChanged(key, value)
    if Persist._data[key] == value then return end
    Persist._data[key] = value
    Persist._pending[key] = true
    Persist._scheduleFlush()
end

-- Retrocompat: alias
Persist.set = Persist.setIfChanged

Persist.load()

--------------------------------------------------
-- Maid (gerenciamento de recursos)
--------------------------------------------------
local Maid = {}
Maid.__index = Maid
function Maid.new() return setmetatable({tasks={}}, Maid) end
function Maid:Give(t)
    table.insert(self.tasks, t)
    return t
end
function Maid:Clean()
    for _, t in ipairs(self.tasks) do
        if typeof(t)=="RBXScriptConnection" then
            pcall(function() t:Disconnect() end)
        elseif typeof(t)=="Instance" and t.Destroy then
            pcall(function() t:Destroy() end)
        elseif type(t)=="function" then
            pcall(t)
        end
    end
    table.clear(self.tasks)
end

local GlobalMaid = Maid.new()

--------------------------------------------------
-- Internacionalização (cache + fallback + missing)
--------------------------------------------------
local Lang = {}
Lang.available = { pt="Português", en="English", es="Español" }
Lang.data = {
    pt = { 
        UI_TITLE="Universal Utility v%s", PANEL_GENERAL="Geral", PANEL_MOVEMENT="Movimento", 
        PANEL_CAMERA="Câmera", PANEL_STATS="Desempenho", PANEL_EXTRAS="Extras", PANEL_FLY="Voo", 
        SECTION_INFO="Informações", SECTION_LEADERSTATS="Leaderstats", SECTION_TOUCH="Atalhos Mobile", 
        SECTION_POSITIONS="Posições Salvas", SECTION_AMBIENCE="Ambiente Local", SECTION_COMMANDS="Comandos (Chat)", 
        SECTION_FLY="Controle de Voo", LABEL_VERSION="Versão", LABEL_FS="Executor FS", LABEL_DEVICE="Dispositivo", 
        LABEL_STARTED="Iniciado", LABEL_NO_LS="Nenhum leaderstats detectado.", LABEL_FPS="FPS", LABEL_MEM="Mem", 
        LABEL_PING="Ping", LABEL_PLAYERS="Jogadores", LABEL_POS_ATUAL="Pos Atual", BTN_LANG_SWITCH="Alternar Idioma", 
        BTN_RESPAWN="Respawn", BTN_RESET_FOV="Resetar FOV", BTN_INFO="Info", BTN_OVERLAY_RESET="Reset Overlay", 
        BTN_SAVE_POS="Salvar Posição (máx 5)", BTN_CLEAR_POS="Limpar Todas", BTN_COPY_POS="Copiar Posição", 
        BTN_SHOW_HIDE="[F4] Mostrar/Ocultar", BTN_FLY_TOGGLE="Ativar/Desativar Voo", BTN_FLY_KEYBIND_RESET="Reset Teclas", 
        BTN_EXPORT="Exportar Config", BTN_IMPORT="Importar Config", TOGGLE_REAPPLY="Reaplicar em respawn", 
        TOGGLE_SHIFTLOCK="Simular Shift-Lock", TOGGLE_SMOOTH="Câmera Suave", TOGGLE_OVERLAY="Mostrar Overlay", 
        TOGGLE_NOCLIP="Noclip", TOGGLE_WORLD_TIME="Hora Custom", SLIDER_WALKSPEED="WalkSpeed", 
        SLIDER_JUMPPOWER="JumpPower", SLIDER_FOV="FOV", SLIDER_CAM_SENS="Sensibilidade", 
        SLIDER_OVERLAY_INTERVAL="Intervalo Overlay", SLIDER_WORLD_TIME="Hora (ClockTime)", 
        SLIDER_FLY_SPEED="Velocidade Voo", SLIDER_FLY_VERTICAL="Velocidade Vertical", 
        NOTIFY_INFO="Use os painéis para ajustes.", NOTIFY_FOV_RESET="FOV redefinido para 70", 
        NOTIFY_POS_LIMIT="Limite de 5 posições atingido.", NOTIFY_NO_ROOT="Sem HumanoidRootPart.", 
        NOTIFY_POS_COPIED="Coordenadas copiadas.", NOTIFY_POS_SAVED="Posição salva.", 
        NOTIFY_LOADED="Carregado v%s", LANG_CHANGED="Idioma alterado para %s.", MINI_HANDLE="≡", 
        MINI_TIP="Arraste / Clique", COMMAND_LIST="Comandos: /uu help | lang | overlay | reload | resetui | export | import | panic | fly", 
        COMMAND_UNKNOWN="Comando desconhecido. Use /uu help", COMMAND_LANG_OK="Idioma definido para %s.", 
        COMMAND_OVERLAY_TOG="Overlay agora: %s", COMMAND_RELOADED="Config recarregada.", COMMAND_RESETUI="UI resetada.", 
        COMMAND_EXPORTED="Config copiada.", COMMAND_IMPORTED="Config importada.", COMMAND_IMPORT_FAIL="Falha ao importar JSON.", 
        FLY_ON="Voo ativado.", FLY_OFF="Voo desativado.", PANIC_DONE="Modo panic: tudo desativado." 
    },
    en = { 
        UI_TITLE="Universal Utility v%s", PANEL_GENERAL="General", PANEL_MOVEMENT="Movement", 
        PANEL_CAMERA="Camera", PANEL_STATS="Performance", PANEL_EXTRAS="Extras", PANEL_FLY="Fly", 
        SECTION_INFO="Information", SECTION_LEADERSTATS="Leaderstats", SECTION_TOUCH="Mobile Shortcuts", 
        SECTION_POSITIONS="Saved Positions", SECTION_AMBIENCE="Local Ambience", SECTION_COMMANDS="Commands (Chat)", 
        SECTION_FLY="Flight Control", LABEL_VERSION="Version", LABEL_FS="Executor FS", LABEL_DEVICE="Device", 
        LABEL_STARTED="Started", LABEL_NO_LS="No leaderstats detected.", LABEL_FPS="FPS", LABEL_MEM="Mem", 
        LABEL_PING="Ping", LABEL_PLAYERS="Players", LABEL_POS_ATUAL="Current Pos", BTN_LANG_SWITCH="Switch Language", 
        BTN_RESPAWN="Respawn", BTN_RESET_FOV="Reset FOV", BTN_INFO="Info", BTN_OVERLAY_RESET="Reset Overlay", 
        BTN_SAVE_POS="Save Position (max 5)", BTN_CLEAR_POS="Clear All", BTN_COPY_POS="Copy Position", 
        BTN_SHOW_HIDE="[F4] Show/Hide", BTN_FLY_TOGGLE="Toggle Fly", BTN_FLY_KEYBIND_RESET="Reset Keys", 
        BTN_EXPORT="Export Config", BTN_IMPORT="Import Config", TOGGLE_REAPPLY="Reapply on respawn", 
        TOGGLE_SHIFTLOCK="Simulate Shift-Lock", TOGGLE_SMOOTH="Smooth Camera", TOGGLE_OVERLAY="Show Overlay", 
        TOGGLE_NOCLIP="Noclip", TOGGLE_WORLD_TIME="Custom Time", SLIDER_WALKSPEED="WalkSpeed", 
        SLIDER_JUMPPOWER="JumpPower", SLIDER_FOV="FOV", SLIDER_CAM_SENS="Sensitivity", 
        SLIDER_OVERLAY_INTERVAL="Overlay Interval", SLIDER_WORLD_TIME="Time (ClockTime)", 
        SLIDER_FLY_SPEED="Fly Speed", SLIDER_FLY_VERTICAL="Vertical Speed", 
        NOTIFY_INFO="Use panels for tweaks.", NOTIFY_FOV_RESET="FOV reset to 70", 
        NOTIFY_POS_LIMIT="Limit of 5 positions reached.", NOTIFY_NO_ROOT="No HumanoidRootPart.", 
        NOTIFY_POS_COPIED="Coordinates copied.", NOTIFY_POS_SAVED="Position saved.", 
        NOTIFY_LOADED="Loaded v%s", LANG_CHANGED="Language changed to %s.", MINI_HANDLE="≡", 
        MINI_TIP="Drag / Click", COMMAND_LIST="Commands: /uu help | lang | overlay | reload | resetui | export | import | panic | fly", 
        COMMAND_UNKNOWN="Unknown command. Use /uu help", COMMAND_LANG_OK="Language set to %s.", 
        COMMAND_OVERLAY_TOG="Overlay now: %s", COMMAND_RELOADED="Config reloaded.", COMMAND_RESETUI="UI reset.", 
        COMMAND_EXPORTED="Config copied.", COMMAND_IMPORTED="Config imported.", COMMAND_IMPORT_FAIL="Failed to import JSON.", 
        FLY_ON="Fly enabled.", FLY_OFF="Fly disabled.", PANIC_DONE="Panic mode: all disabled." 
    }
}
Lang.current = Persist.get("lang", nil)
Lang.missing = {}
local MissingLogged = false

local function L(key, ...)
    local pack = Lang.data[Lang.current or "en"] or Lang.data.en
    local txt = pack[key]
    if not txt then
        txt = (Lang.data.en[key] or key)
        if not Lang.missing[key] then
            Lang.missing[key] = true
            if not MissingLogged then
                MissingLogged = true
                warn("[Universal][Lang] Missing keys detected (will aggregate).")
            end
        end
    end
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, txt, ...)
        if ok then return formatted else return txt end
    end
    return txt
end

function Lang.set(code)
    if Lang.data[code] then
        Lang.current = code
        Persist.set("lang", code)
        if _G.UniversalUtility and _G.UniversalUtility._langChanged then
            for _, cb in ipairs(_G.UniversalUtility._langChanged) do pcall(cb, code) end
        end
    end
end

--------------------------------------------------
-- Notificações seguras
--------------------------------------------------
local function notify(title,text,dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=title,Text=text,Duration=dur or 3})
    end)
end

--------------------------------------------------
-- Utilidades
--------------------------------------------------
local Util = {}
function Util.getHumanoid()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildWhichIsA("Humanoid")
end
function Util.getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
function Util.draggable(frame, handle, onDrop)
    handle = handle or frame
    local dragging, startPos, dragStart
    GlobalMaid:Give(handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            startPos = frame.Position
            dragStart = i.Position
            GlobalMaid:Give(i.Changed:Connect(function(s)
                if s==Enum.UserInputState.End then
                    if dragging then dragging=false if onDrop then pcall(onDrop, frame.Position) end end
                end
            end))
        end
    end))
    GlobalMaid:Give(handle.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local delta = i.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
end

--------------------------------------------------
-- Metrics Scheduler (único loop RenderStepped)
--------------------------------------------------
local MetricsService = {
    observers = {},
    overlayInterval = Persist.get("overlay_interval", 1),
    acc = 0, frames = 0, last = tick(),
    lastOverlayAcc = 0
}

function MetricsService.observe(fn)
    table.insert(MetricsService.observers, fn)
end

function MetricsService.setInterval(interval)
    MetricsService.overlayInterval = interval
    Persist.set("overlay_interval", interval)
end

GlobalMaid:Give(RunService.RenderStepped:Connect(function()
    local now = tick()
    local dt = now - MetricsService.last
    MetricsService.last = now
    MetricsService.frames += 1
    MetricsService.acc += dt
    MetricsService.lastOverlayAcc += dt

    if MetricsService.lastOverlayAcc >= MetricsService.overlayInterval then
        local fps = math.floor(MetricsService.frames / MetricsService.acc)
        local mem = collectgarbage("count")
        local ping = Stats.Network.ServerStatsItem["Data Ping"] and Stats.Network.ServerStatsItem["Data Ping"]:GetValue() or 0
        local players = #Players:GetPlayers()
        for _, ob in ipairs(MetricsService.observers) do
            pcall(ob, {fps=fps, mem=mem, ping=ping, players=players})
        end
        MetricsService.frames = 0
        MetricsService.acc = 0
        MetricsService.lastOverlayAcc = 0
    end

    -- Persist flush throttle
    if Persist._dirty and (now - Persist._lastFlush) > 0.5 then
        Persist.flush()
    end
end))

--------------------------------------------------
-- Comandos com debounce
--------------------------------------------------
local Commands = {}
local lastCmd = 0

local function registerCommand(name, desc, fn)
    Commands[name] = {desc=desc, fn=fn}
end

local function executeCommand(parts)
    local cmd = parts[1]
    if not cmd then return end
    local data = Commands[cmd]
    if not data then
        notify("UU", L("COMMAND_UNKNOWN"))
        return
    end
    pcall(data.fn, parts)
end

GlobalMaid:Give(LocalPlayer.Chatted:Connect(function(msg)
    if msg:sub(1,4):lower() == "/uu " then
        if tick() - lastCmd < 0.25 then return end
        lastCmd = tick()
        local rest = msg:sub(5)
        local parts = {}
        for token in rest:gmatch("%S+") do
            if #token > 32 then token = token:sub(1,32) end
            table.insert(parts, token)
        end
        executeCommand(parts)
    elseif msg:lower() == "/uu" then
        notify("UU", L("COMMAND_LIST"),5)
    end
end))

--------------------------------------------------
-- Public API _G.UniversalUtility
--------------------------------------------------
if not _G.UniversalUtility then
    _G.UniversalUtility = {
        _version = VERSION,
        _langChanged = {},
        _panelLazy = {},
        _commands = Commands,
        _metricsObservers = {},
        _state = {}
    }
end

local UU = _G.UniversalUtility

function UU.RegisterCommand(name, desc, fn)
    registerCommand(name, desc, fn)
end

function UU.RegisterPanelLazy(name, fn)
    UU._panelLazy[name] = fn
end

function UU.OnLanguageChanged(fn)
    table.insert(UU._langChanged, fn)
end

function UU.GetState(key)
    return UU._state[key]
end

function UU.AddMetricsObserver(fn)
    MetricsService.observe(fn)
end

--------------------------------------------------
-- Fly Controller (suavizado)
--------------------------------------------------
local Fly = {
    enabled=false,
    speed = Persist.get("fly_speed", 60),
    verticalSpeed = Persist.get("fly_vertical_speed", 40),
    ascendKey = Enum.KeyCode.Space,
    descendKey = Enum.KeyCode.LeftControl,
    smoothing = 0.25,
    useAlign = true,
    align = nil
}

local function ensureAlign()
    if not Fly.useAlign then return end
    local root = Util.getRoot()
    if not root then return end
    if Fly.align and Fly.align.Parent ~= root then Fly.align = nil end
    if not Fly.align then
        pcall(function()
            local av = Instance.new("AlignVelocity")
            av.Name = "UU_FlyAlign"
            av.Attachment0 = root:FindFirstChildWhichIsA("Attachment") or Instance.new("Attachment", root)
            av.Mode = Enum.VelocityAlignmentMode.Vector
            av.Responsiveness = 200
            av.MaxForce = 1e6
            av.Parent = root
            Fly.align = av
        end)
    end
end

local function setFly(on)
    Fly.enabled = (on==nil) and not Fly.enabled or on
    UU._state.flyEnabled = Fly.enabled
    
    if not Fly.enabled then
        if Fly.align then Fly.align.Velocity = Vector3.zero end
        local hum = Util.getHumanoid() 
        if hum and hum.PlatformStand then hum.PlatformStand=false end
        notify("Fly", L("FLY_OFF"))
    else
        notify("Fly", L("FLY_ON"))
    end
end

-- Movimento fly integrado ao Heartbeat para suavização
GlobalMaid:Give(RunService.Heartbeat:Connect(function(dt)
    if not Fly.enabled then return end
    local root = Util.getRoot() 
    local hum = Util.getHumanoid() 
    if not root or not hum then return end
    
    hum.PlatformStand = true
    local cam = workspace.CurrentCamera 
    if not cam then return end
    
    ensureAlign()
    local dir = Vector3.zero
    local function key(k) return UserInputService:IsKeyDown(k) end
    
    if key(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
    if key(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
    if key(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
    if key(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
    if key(Fly.ascendKey) then dir += Vector3.new(0,1,0) end
    if key(Fly.descendKey) then dir += Vector3.new(0,-1,0) end
    
    if dir.Magnitude > 0 then dir = dir.Unit end
    local target = dir * Fly.speed
    target = Vector3.new(target.X, math.clamp(target.Y * Fly.verticalSpeed / Fly.speed, -Fly.verticalSpeed, Fly.verticalSpeed), target.Z)

    if Fly.align then
        Fly.align.Velocity = Fly.align.Velocity:Lerp(target, Fly.smoothing)
    else
        root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(target, Fly.smoothing)
    end
end))

--------------------------------------------------
-- Noclip optimizado
--------------------------------------------------
local Noclip = {
    enabled = false,
    parts = {},
    originalCollisions = {}
}

local function updateNoclipParts()
    local character = LocalPlayer.Character
    if not character then return end
    
    Noclip.parts = {}
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(Noclip.parts, part)
            if not Noclip.originalCollisions[part] then
                Noclip.originalCollisions[part] = part.CanCollide
            end
        end
    end
end

local function setNoclip(on)
    Noclip.enabled = on
    UU._state.noclipEnabled = on
    
    if on then
        updateNoclipParts()
        for _, part in ipairs(Noclip.parts) do
            part.CanCollide = false
        end
    else
        for part, original in pairs(Noclip.originalCollisions) do
            if part and part.Parent then
                part.CanCollide = original
            end
        end
    end
end

-- Noclip stepped connection - only update changed parts
GlobalMaid:Give(RunService.Stepped:Connect(function()
    if not Noclip.enabled then return end
    
    for _, part in ipairs(Noclip.parts) do
        if part and part.Parent and part.CanCollide then
            part.CanCollide = false
        end
    end
end))

-- Update parts when character changes
GlobalMaid:Give(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1) -- Wait for character to fully load
    if Noclip.enabled then
        updateNoclipParts()
    end
end))

--------------------------------------------------
-- Camera controller consolidado
--------------------------------------------------
local CameraController = {
    shiftLock = Persist.get("camera_shiftlock", false),
    smooth = Persist.get("camera_smooth", false),
    sensitivity = Persist.get("camera_sens", 1),
    lastCF = nil,
    lastDelta = Vector2.zero
}

-- Consolidated camera loop
GlobalMaid:Give(RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if not cam then return end
    
    -- Shift-lock simulation
    if CameraController.shiftLock and not isMobile then
        if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    else
        if not isMobile and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
    
    -- Smooth camera
    if CameraController.smooth then
        if CameraController.lastCF then 
            cam.CFrame = CameraController.lastCF:Lerp(cam.CFrame, 0.25) 
        end
        CameraController.lastCF = cam.CFrame
    else
        CameraController.lastCF = nil
    end
    
    -- Custom sensitivity
    if CameraController.sensitivity ~= 1 and not isMobile then
        local delta = CameraController.lastDelta * (CameraController.sensitivity - 1) * 0.002
        if delta.Magnitude > 0 then
            local cf = cam.CFrame
            cf = cf * CFrame.Angles(0, -delta.X, 0) * CFrame.Angles(-delta.Y, 0, 0)
            cam.CFrame = cf
        end
    end
end))

-- Track mouse delta
GlobalMaid:Give(UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        CameraController.lastDelta = input.Delta
    end
end))

--------------------------------------------------
-- Registro de comandos principais
--------------------------------------------------
registerCommand("help", "Show commands", function() 
    notify("UU", L("COMMAND_LIST"), 5) 
end)

registerCommand("lang", "Switch language", function(parts)
    local code = parts[2] or "en"
    if Lang.data[code] then
        Lang.set(code)
        notify("UU", L("COMMAND_LANG_OK", Lang.available[code] or code))
    end
end)

registerCommand("fly", "Toggle fly", function()
    setFly()
end)

registerCommand("noclip", "Toggle noclip", function()
    setNoclip(not Noclip.enabled)
end)

registerCommand("panic", "Disable all features", function()
    setFly(false)
    setNoclip(false)
    CameraController.shiftLock = false
    Persist.set("camera_shiftlock", false)
    
    -- Reset camera
    local cam = workspace.CurrentCamera
    if cam then
        cam.FieldOfView = 70
        Persist.set("camera_fov", 70)
    end
    
    -- Reset humanoid
    local hum = Util.getHumanoid()
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        Persist.set("walkspeed_value", 16)
        Persist.set("jumppower_value", 50)
    end
    
    notify("UU", L("PANIC_DONE"))
end)

registerCommand("export", "Export config", function()
    if typeof(setclipboard) == "function" then
        setclipboard(HttpService:JSONEncode(Persist._data))
        notify("UU", L("COMMAND_EXPORTED"))
    end
end)

registerCommand("import", "Import config", function()
    if typeof(getclipboard) == "function" then
        pcall(function()
            local data = HttpService:JSONDecode(getclipboard())
            if type(data) == "table" then
                Persist._data = data
                Persist.flush(true)
                notify("UU", L("COMMAND_IMPORTED"))
            else
                notify("UU", L("COMMAND_IMPORT_FAIL"))
            end
        end)
    end
end)

registerCommand("reload", "Reload config", function()
    Persist.load()
    notify("UU", L("COMMAND_RELOADED"))
end)

--------------------------------------------------
-- Inicialização com overlay básico
--------------------------------------------------
local function ensureLanguage()
    if Lang.current then return end
    -- Default to English if no language is set
    Lang.set("en")
end

-- Position update with reduced frequency (~8 Hz)
local positionUpdateAcc = 0
local positionLabel = nil

-- Initialize everything
task.spawn(function()
    ensureLanguage()
    
    -- Create a performance overlay
    local screen = Instance.new("ScreenGui")
    screen.Name = "UU_Overlay"
    screen.ResetOnSpawn = false
    pcall(function() screen.Parent = (gethui and gethui() or game:GetService("CoreGui")) end)
    
    local overlay = Instance.new("TextLabel")
    overlay.Size = UDim2.new(0, 200, 0, 100)
    overlay.Position = UDim2.new(1, -210, 0, 10)
    overlay.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
    overlay.TextColor3 = Color3.fromRGB(185, 255, 200)
    overlay.Font = Enum.Font.Code
    overlay.TextSize = 13
    overlay.TextXAlignment = Enum.TextXAlignment.Left
    overlay.TextYAlignment = Enum.TextYAlignment.Top
    overlay.Text = "Loading metrics..."
    overlay.Parent = screen
    GlobalMaid:Give(screen)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = overlay
    
    -- Make overlay draggable
    Util.draggable(overlay, overlay, function(pos)
        Persist.set("overlay_pos", {sx=pos.X.Scale, x=pos.X.Offset, sy=pos.Y.Scale, y=pos.Y.Offset})
    end)
    
    -- Load saved position
    local savedPos = Persist.get("overlay_pos", nil)
    if savedPos then
        overlay.Position = UDim2.new(savedPos.sx or 1, savedPos.x or -210, savedPos.sy or 0, savedPos.y or 10)
    end
    
    positionLabel = overlay
    
    -- Connect to metrics with position updates
    MetricsService.observe(function(data)
        local root = Util.getRoot()
        local posText = ""
        if root then
            local p = root.Position
            posText = string.format("\n%s: (%.1f, %.1f, %.1f)", L("LABEL_POS_ATUAL"), p.X, p.Y, p.Z)
        end
        
        local text = string.format(
            "FPS: %d\nMem: %.1f MB\nPing: %d ms\nPlayers: %d%s",
            data.fps,
            data.mem / 1024,
            data.ping,
            data.players,
            posText
        )
        overlay.Text = text
    end)
    
    -- Show overlay based on preference
    local showOverlay = Persist.get("show_overlay", true)
    overlay.Visible = showOverlay
    
    -- Register overlay toggle command
    registerCommand("overlay", "Toggle overlay", function()
        showOverlay = not showOverlay
        overlay.Visible = showOverlay
        Persist.set("show_overlay", showOverlay)
        notify("UU", L("COMMAND_OVERLAY_TOG", showOverlay and "ON" or "OFF"))
    end)
    
    -- Debugging: Print missing translations after 5 seconds
    task.wait(5)
    if next(Lang.missing) then
        warn("[Universal][Lang] Missing translation keys:")
        for key in pairs(Lang.missing) do
            warn("  - " .. key)
        end
    end
    
    notify("Universal Utility", L("NOTIFY_LOADED", VERSION), 4)
end)

-- Return the modules for potential external use
return { 
    Lang = Lang, 
    Persist = Persist, 
    Util = Util, 
    MetricsService = MetricsService,
    Maid = GlobalMaid,
    Fly = Fly,
    Noclip = Noclip,
    CameraController = CameraController,
    Commands = Commands,
    VERSION = VERSION
}