--[[
Universal Client Utility (Advanced UI) v0.6.1 (UI Refactor + Legacy Fly GUI + Noclip Fix)
Autor original: (Eduardo854832)
Alterações solicitadas:
 - Menu totalmente redesenhado (painéis expansíveis estilo "accordion")
 - Substituição do sistema de Fly anterior pelo "FLY GUI V3" fornecido
 - Correção: Noclip agora restaura o estado original de CanCollide ao desativar
 - Mantidas: Persistência, internacionalização, ajustes de humanoide, câmera, overlay, posições, ambiente, stats, atalhos mobile
Uso educacional; não usar para violar ToS.
]]

local VERSION = "0.6.1"

-- ==== Serviços ====
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local StarterGui         = game:GetService("StarterGui")
local Stats              = game:GetService("Stats")
local Lighting           = game:GetService("Lighting")
local HttpService        = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ==== Persistência ====
local Persist = {}
Persist._fileName = "UniversalUtilityConfig.json"
Persist._data = {}
local hasFS = (typeof(isfile)=="function" and typeof(readfile)=="function" and typeof(writefile)=="function")

function Persist.load()
    if hasFS and isfile(Persist._fileName) then
        pcall(function()
            local raw = readfile(Persist._fileName)
            Persist._data = HttpService:JSONDecode(raw)
        end)
    end
end
function Persist.save()
    if not hasFS then return end
    pcall(function()
        writefile(Persist._fileName, HttpService:JSONEncode(Persist._data))
    end)
end
function Persist.get(key, default)
    local v = Persist._data[key]
    if v == nil then
        Persist._data[key] = default
        return default
    end
    return v
end
function Persist.set(key, value)
    Persist._data[key] = value
    Persist.save()
end
Persist.load()

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
        BTN_OVERLAY_RESET = "Reset Posição Overlay",
        BTN_SAVE_POS = "Salvar Posição (máx 5)",
        BTN_CLEAR_POS = "Limpar Todas",
        BTN_COPY_POS = "Copiar Pos Atual",
        BTN_SHOW_HIDE = "[F4] Mostrar/Ocultar",
        BTN_FLY_UP = "Subir",
        BTN_FLY_DOWN = "Descer",
        BTN_FLY_SPEEDMODE = "Veloc+",
        TOGGLE_REAPPLY = "Reaplicar em respawn",
        TOGGLE_SHIFTLOCK = "Simular Shift-Lock (PC)",
        TOGGLE_SMOOTH = "Câmera Suave",
        TOGGLE_OVERLAY = "Mostrar Performance Overlay",
        TOGGLE_NOCLIP = "Noclip",
        TOGGLE_WORLD_TIME = "Aplicar Hora Custom",
        SLIDER_WALKSPEED = "WalkSpeed",
        SLIDER_JUMPPOWER = "JumpPower",
        SLIDER_FOV = "FOV",
        SLIDER_CAM_SENS = "Sensibilidade",
        SLIDER_OVERLAY_INTERVAL = "Overlay Intervalo",
        SLIDER_WORLD_TIME = "Hora (ClockTime)",
        NOTIFY_INFO = "Use os painéis para ajustes.",
        NOTIFY_FOV_RESET = "FOV redefinido para 70",
        NOTIFY_POS_LIMIT = "Limite de 5 atingido (remova com botão direito).",
        NOTIFY_NO_ROOT = "Sem HumanoidRootPart.",
        NOTIFY_POS_COPIED = "Coordenadas copiadas.",
        NOTIFY_POS_SAVED = "Posição salva.",
        NOTIFY_LOADED = "Carregado v%s",
        LANG_CHANGED = "Idioma alterado.",
        FLYGUI_OPEN = "Abrir Fly GUI",
        FLYGUI_CLOSE = "Fechar Fly GUI",
        LEGACY_FLY_NOTE = "Fly legado (GUI separada)."
    },
    en = {
        UI_TITLE = "Universal Utility v%s",
        PANEL_GENERAL = "General",
        PANEL_MOVEMENT = "Movement",
        PANEL_CAMERA = "Camera",
        PANEL_STATS = "Stats",
        PANEL_EXTRAS = "Extras",
        PANEL_FLY = "Fly",
        SECTION_INFO = "Information",
        SECTION_LEADERSTATS = "Leaderstats",
        SECTION_HUMANOID = "Humanoid Tweaks",
        SECTION_CAMERA = "Camera Settings",
        SECTION_MONITOR = "Monitor",
        SECTION_TOUCH = "Mobile Shortcuts",
        SECTION_EXTRAS = "Extra Features",
        SECTION_POSITIONS = "Positions",
        SECTION_AMBIENCE = "Local Ambience",
        SECTION_FLY = "Fly Control",
        LABEL_VERSION = "Version",
        LABEL_FS = "Executor FS",
        LABEL_DEVICE = "Device",
        LABEL_STARTED = "Started",
        LABEL_NO_LS = "No leaderstats detected.",
        LABEL_FPS = "FPS",
        LABEL_MEM = "Mem",
        LABEL_PING = "Ping",
        LABEL_PLAYERS = "Players",
        LABEL_POS_ATUAL = "Current Pos",
        LABEL_LANG_CHANGE = "Change Language",
        BTN_RESPAWN = "Respawn",
        BTN_RESET_FOV = "Reset FOV",
        BTN_INFO = "Info",
        BTN_OVERLAY_RESET = "Reset Overlay Position",
        BTN_SAVE_POS = "Save Position (max 5)",
        BTN_CLEAR_POS = "Clear All",
        BTN_COPY_POS = "Copy Current Pos",
        BTN_SHOW_HIDE = "[F4] Show/Hide",
        BTN_FLY_UP = "Ascend",
        BTN_FLY_DOWN = "Descend",
        BTN_FLY_SPEEDMODE = "Speed+",
        TOGGLE_REAPPLY = "Reapply on respawn",
        TOGGLE_SHIFTLOCK = "Simulate Shift-Lock (PC)",
        TOGGLE_SMOOTH = "Smooth Camera",
        TOGGLE_OVERLAY = "Show Performance Overlay",
        TOGGLE_NOCLIP = "Noclip",
        TOGGLE_WORLD_TIME = "Apply Custom Time",
        SLIDER_WALKSPEED = "WalkSpeed",
        SLIDER_JUMPPOWER = "JumpPower",
        SLIDER_FOV = "FOV",
        SLIDER_CAM_SENS = "Sensitivity",
        SLIDER_OVERLAY_INTERVAL = "Overlay Interval",
        SLIDER_WORLD_TIME = "Time (ClockTime)",
        NOTIFY_INFO = "Use panels for tweaks.",
        NOTIFY_FOV_RESET = "FOV reset to 70",
        NOTIFY_POS_LIMIT = "Limit of 5 reached (right click to remove).",
        NOTIFY_NO_ROOT = "No HumanoidRootPart.",
        NOTIFY_POS_COPIED = "Coordinates copied.",
        NOTIFY_POS_SAVED = "Position saved.",
        NOTIFY_LOADED = "Loaded v%s",
        LANG_CHANGED = "Language changed.",
        FLYGUI_OPEN = "Open Fly GUI",
        FLYGUI_CLOSE = "Close Fly GUI",
        LEGACY_FLY_NOTE = "Legacy fly (separate GUI)."
    }
}
Lang.current = Persist.get("lang", nil)

local function L(k, ...)
    local pack = Lang.data[Lang.current or "pt"]
    local s = pack and pack[k] or k
    if select("#", ...) > 0 then return string.format(s, ...) end
    return s
end

-- Seleção de idioma caso não exista preferido
local function ensureLanguage(callback)
    if Lang.current then callback() return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "LangSelect_NewUI"
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
    if not ok then warn("[Universal][Error]", r) end
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
function Util.isGuiObject(inst)
    return inst and inst:IsA("GuiObject")
end
function Util.draggable(frame, handle)
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
                if chg == Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

-- ==== Core (Plugins) ====
local Core = {}
Core._plugins = {}
Core._connections = {}
Core.Context = {
    version = VERSION,
    isMobile = isMobile,
    started = os.clock()
}

function Core.register(plugin)
    if type(plugin)=="table" and plugin.name and plugin.init then
        table.insert(Core._plugins, plugin)
    end
end
function Core.initPlugins()
    for _, p in ipairs(Core._plugins) do
        local ok, err = pcall(function() p.init(Core.Context) end)
        if not ok then warn("[PluginError]", p.name, err) end
    end
end
function Core.connect(sig, fn)
    local c = sig:Connect(fn)
    table.insert(Core._connections, c)
    return c
end
function Core.onCharacterAdded(callback, immediate)
    Core.connect(LocalPlayer.CharacterAdded, function(char)
        safe(function()
            if callback then callback(char) end
        end)
    end)
    if immediate and LocalPlayer.Character then
        safe(function() callback(LocalPlayer.Character) end)
    end
end

-- ==== NOVO SISTEMA DE UI (Accordion Panels) ====
local UI = {}
UI._panels = {}
UI._translatables = {}

local function mark(instance, key, ...)
    table.insert(UI._translatables, {instance=instance, key=key, args={...}})
end

function UI.applyLanguage()
    for _, data in ipairs(UI._translatables) do
        if data.instance and data.instance.Parent then
            data.instance.Text = L(data.key, unpack(data.args))
        end
    end
    if UI.TitleLabel then
        UI.TitleLabel.Text = L("UI_TITLE", VERSION)
    end
end

function UI.createRoot()
    local screen = Instance.new("ScreenGui")
    screen.Name = "UniversalUtility_Ref_UI"
    screen.ResetOnSpawn = false
    pcall(function()
        screen.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end)

    local floating = Instance.new("Frame")
    floating.Size = UDim2.new(0, 370, 0, 520)
    floating.Position = UDim2.new(0.05,0,0.25,0)
    floating.BackgroundColor3 = Color3.fromRGB(20,22,30)
    floating.BorderSizePixel = 0
    floating.Parent = screen
    Instance.new("UICorner", floating).CornerRadius = UDim.new(0,12)
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1,0,0,48)
    header.BackgroundColor3 = Color3.fromRGB(30,34,46)
    header.BorderSizePixel = 0
    header.Parent = floating
    Instance.new("UICorner", header).CornerRadius = UDim.new(0,12)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1,-90,1,0)
    title.Position = UDim2.new(0,16,0,0)
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(235,235,245)
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = L("UI_TITLE", VERSION)
    title.Parent = header
    UI.TitleLabel = title

    local hideBtn = Instance.new("TextButton")
    hideBtn.Size = UDim2.new(0,60,0,30)
    hideBtn.Position = UDim2.new(1,-70,0.5,-15)
    hideBtn.BackgroundColor3 = Color3.fromRGB(55,65,90)
    hideBtn.TextColor3 = Color3.new(1,1,1)
    hideBtn.Font = Enum.Font.GothamBold
    hideBtn.TextSize = 12
    hideBtn.Text = "Hide"
    hideBtn.Parent = header
    Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0,8)

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
    list.Padding = UDim.new(0,10)
    list.Changed:Connect(function(p)
        if p=="AbsoluteContentSize" then
            scroll.CanvasSize = UDim2.new(0,0,0,list.AbsoluteContentSize.Y+20)
        end
    end)

    hideBtn.MouseButton1Click:Connect(function()
        floating.Visible = false
    end)
    UserInputService.InputBegan:Connect(function(input,gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F4 then
            floating.Visible = not floating.Visible
        end
    end)

    UI.Screen = screen
    UI.RootFrame = floating
    UI.Container = scroll
end

-- Cria painel colapsável
function UI.createPanel(keyTitle)
    local holder = Instance.new("Frame")
    holder.BackgroundColor3 = Color3.fromRGB(28,32,42)
    holder.Size = UDim2.new(1,0,0,0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.Parent = UI.Container
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0,10)

    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1,-14,0,40)
    header.Position = UDim2.new(0,7,0,7)
    header.BackgroundColor3 = Color3.fromRGB(45,52,68)
    header.TextColor3 = Color3.new(1,1,1)
    header.Font = Enum.Font.GothamBold
    header.TextSize = 14
    header.Text = "▼ "..L(keyTitle)
    mark(header,keyTitle)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = holder
    Instance.new("UICorner", header).CornerRadius = UDim.new(0,8)

    local content = Instance.new("Frame")
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0,10,0,50)
    content.Size = UDim2.new(1,-20,0,0)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.Parent = holder
    local layout = Instance.new("UIListLayout", content)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,6)

    local expanded = true
    header.MouseButton1Click:Connect(function()
        expanded = not expanded
        header.Text = (expanded and "▼ " or "► ") .. L(keyTitle)
        for _,c in ipairs(content:GetChildren()) do
            if c:IsA("GuiObject") then
                c.Visible = expanded
            end
        end
        content.Visible = expanded
    end)

    UI._panels[keyTitle] = {button=header, content=content}
    return content
end

-- Elementos reusáveis
function UI.label(parent, text, isKey)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1,0,0,20)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(200,205,215)
    lbl.Text = isKey and L(text) or text
    if isKey then mark(lbl,text) end
    lbl.Parent = parent
    return lbl
end

function UI.button(parent, textKeyOrRaw, isKey, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,30)
    b.BackgroundColor3 = Color3.fromRGB(55,65,90)
    b.TextColor3 = new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Text = isKey and L(textKeyOrRaw) or textKeyOrRaw
    if isKey then mark(b,textKeyOrRaw) end
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(function() safe(callback) end)
    return b
end

function UI.toggle(parent, labelKey, key, default, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,30)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,56,1,0)
    btn.BackgroundColor3 = Color3.fromRGB(90,90,95)
    btn.TextColor3 = new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Text = "OFF"
    btn.Parent = holder
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0,62,0,0)
    lbl.Size = UDim2.new(1,-62,1,0)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(235,235,240)
    lbl.Text = L(labelKey)
    mark(lbl,labelKey)
    lbl.Parent = holder

    local state = Persist.get(key, default)
    local function apply(trigger)
        btn.Text = state and "ON" or "OFF"
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(50,145,70) or Color3.fromRGB(90,90,95)
        }):Play()
        if trigger ~= false then safe(callback,state) end
        Persist.set(key,state)
    end
    btn.MouseButton1Click:Connect(function()
        state = not state
        apply(true)
    end)
    apply(false)
    return function(newState)
        state = newState
        apply(true)
    end
end

function UI.slider(parent, labelKey, key, minVal, maxVal, defaultVal, step, callback)
    step = step or 1
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,50)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local value = Persist.get(key, defaultVal)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,18)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(220,220,230)
    lbl.Text = L(labelKey)..": "..tostring(value)
    mark(lbl,labelKey)
    lbl.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,-8,0,10)
    bar.Position = UDim2.new(0,4,0,28)
    bar.BackgroundColor3 = Color3.fromRGB(55,60,70)
    bar.Parent = holder
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,5)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((value - minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(90,150,255)
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,5)

    local dragging=false
    local function applyValue(v, fire)
        fill.Size = UDim2.new((v - minVal)/(maxVal-minVal),0,1,0)
        lbl.Text = L(labelKey)..": "..tostring(v)
        Persist.set(key, v)
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
    return function(newValue, fire)
        newValue = math.clamp(newValue, minVal, maxVal)
        applyValue(newValue, fire)
    end
end

-- ===== Construção principal =====
ensureLanguage(function()
    UI.createRoot()

    -- Painéis (ordem)
    local panelGeneral  = UI.createPanel("PANEL_GENERAL")
    local panelMovement = UI.createPanel("PANEL_MOVEMENT")
    local panelCamera   = UI.createPanel("PANEL_CAMERA")
    local panelStats    = UI.createPanel("PANEL_STATS")
    local panelExtras   = UI.createPanel("PANEL_EXTRAS")
    local panelFly      = UI.createPanel("PANEL_FLY")

    -- Performance Overlay
    Core.register({
        name = "PerformanceOverlay",
        init = function(ctx)
            local sg = Instance.new("ScreenGui")
            sg.Name = "PerfOverlay_New"
            sg.ResetOnSpawn = false
            pcall(function()
                sg.Parent = (gethui and gethui()) or game:GetService("CoreGui")
            end)
            local box = Instance.new("TextLabel")
            box.Size = UDim2.new(0, 200, 0, 90)
            box.Position = UDim2.new(1, -210, 0, 10)
            box.BackgroundColor3 = Color3.fromRGB(15,18,25)
            box.TextColor3 = Color3.fromRGB(185,255,200)
            box.Font = Enum.Font.Code
            box.TextSize = 13
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.TextYAlignment = Enum.TextYAlignment.Top
            box.Text = "..."
            box.Parent = sg
            Util.draggable(box, box)
            ctx.PerfOverlayLabel = box

            local frames,last=0,tick()
            local interval = Persist.get("overlay_interval", 1)
            local acc=0
            RunService.RenderStepped:Connect(function()
                frames+=1
                local now=tick()
                acc += (now-last)
                if acc >= interval then
                    local fps = math.floor(frames/acc)
                    frames=0; acc=0; last=now
                    local mem = gcinfo()
                    local ping = Stats.Network.ServerStatsItem["Data Ping"] and Stats.Network.ServerStatsItem["Data Ping"]:GetValue() or -1
                    box.Text = string.format("%s: %d\n%s: %d KB\n%s: %d ms\n%s: %d",
                        L("LABEL_FPS"),fps,L("LABEL_MEM"),mem,L("LABEL_PING"),ping,L("LABEL_PLAYERS"),#Players:GetPlayers())
                else
                    last=now
                end
            end)
            box.Visible = Persist.get("overlay_visible", true)
        end
    })

    -- Geral
    Core.register({
        name="GeneralInfo",
        init=function()
            UI.label(panelGeneral, string.format("%s: %s", L("LABEL_VERSION"), VERSION), false)
            UI.label(panelGeneral, string.format("%s: %s", L("LABEL_FS"), tostring(hasFS)), false)
            UI.label(panelGeneral, string.format("%s: %s", L("LABEL_DEVICE"), (isMobile and "Mobile" or "PC")), false)
            UI.label(panelGeneral, string.format("%s: %s", L("LABEL_STARTED"), os.date("%H:%M:%S")), false)

            UI.button(panelGeneral,"LABEL_LANG_CHANGE",true,function()
                Lang.current = (Lang.current=="pt") and "en" or "pt"
                Persist.set("lang", Lang.current)
                UI.applyLanguage()
                notify("Lang", L("LANG_CHANGED"))
            end)

            -- Leaderstats
            local lsContainer = Instance.new("Frame")
            lsContainer.BackgroundTransparency = 1
            lsContainer.Size = UDim2.new(1,0,0,0)
            lsContainer.AutomaticSize = Enum.AutomaticSize.Y
            lsContainer.Parent = panelGeneral
            local layout = Instance.new("UIListLayout", lsContainer)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0,2)
            UI.label(lsContainer,L("SECTION_LEADERSTATS"),false)
            local function rebuild()
                for _, c in ipairs(lsContainer:GetChildren()) do
                    if c:IsA("TextLabel") and c.Text ~= L("SECTION_LEADERSTATS") then
                        c:Destroy()
                    end
                end
                local ls = LocalPlayer:FindFirstChild("leaderstats")
                if not ls then
                    UI.label(lsContainer,"LABEL_NO_LS",true)
                    return
                end
                for _, v in ipairs(ls:GetChildren()) do
                    if v:IsA("ValueBase") then
                        local lbl = UI.label(lsContainer, v.Name..": "..tostring(v.Value), false)
                        v:GetPropertyChangedSignal("Value"):Connect(function()
                            lbl.Text = v.Name..": "..tostring(v.Value)
                        end)
                    end
                end
            end
            rebuild()
            LocalPlayer.ChildAdded:Connect(function(ch)
                if ch.Name=="leaderstats" then task.delay(0.3,rebuild) end
            end)

            -- Mobile quick buttons
            if isMobile then
                UI.label(panelGeneral,"SECTION_TOUCH",true)
                UI.button(panelGeneral,"BTN_RESPAWN",true,function()
                    local hum = Util.getHumanoid(); if hum then hum.Health=0 end
                end)
                UI.button(panelGeneral,"BTN_RESET_FOV",true,function()
                    local cam = workspace.CurrentCamera
                    if cam then
                        cam.FieldOfView = 70
                        Persist.set("camera_fov",70)
                        notify("FOV", L("NOTIFY_FOV_RESET"))
                    end
                end)
                UI.button(panelGeneral,"BTN_INFO",true,function()
                    notify("Info", L("NOTIFY_INFO"))
                end)
            end
        end
    })

    -- Movimento
    Core.register({
        name="Movement",
        init=function()
            local hum = Util.getHumanoid()
            Core.onCharacterAdded(function()
                task.wait(0.4)
                hum = Util.getHumanoid()
            end,true)
            UI.slider(panelMovement,"SLIDER_WALKSPEED","walkspeed_value",4,64,hum and hum.WalkSpeed or 16,1,function(v)
                hum = Util.getHumanoid()
                if hum then hum.WalkSpeed = v end
            end)
            UI.slider(panelMovement,"SLIDER_JUMPPOWER","jumppower_value",25,150,hum and hum.JumpPower or 50,1,function(v)
                hum = Util.getHumanoid()
                if hum and hum.UseJumpPower ~= false then hum.JumpPower = v end
            end)
            UI.toggle(panelMovement,"TOGGLE_REAPPLY","auto_reapply_stats",true,function(on)
                if on then
                    if not Core._autoApplyStatsConn then
                        Core._autoApplyStatsConn = LocalPlayer.CharacterAdded:Connect(function()
                            task.wait(0.3)
                            local h = Util.getHumanoid()
                            if h then
                                local ws = Persist.get("walkspeed_value",16)
                                local jp = Persist.get("jumppower_value",50)
                                safe(function()
                                    h.WalkSpeed = ws
                                    if h.UseJumpPower ~= false then h.JumpPower = jp end
                                end)
                            end
                        end)
                    end
                else
                    if Core._autoApplyStatsConn then
                        Core._autoApplyStatsConn:Disconnect()
                        Core._autoApplyStatsConn=nil
                    end
                end
            end)
        end
    })

    -- Câmera
    Core.register({
        name="CameraSettings",
        init=function()
            local camSensitivityMultiplier = 1
            UI.slider(panelCamera,"SLIDER_FOV","camera_fov",40,120,workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70,1,function(v)
                local cam = workspace.CurrentCamera
                if cam then cam.FieldOfView = v end
            end)
            local state = {
                shiftLock = Persist.get("camera_shiftlock", false),
                smooth = Persist.get("camera_smooth", false)
            }
            UI.toggle(panelCamera,"TOGGLE_SHIFTLOCK","camera_shiftlock",state.shiftLock,function(on) state.shiftLock=on end)
            UI.toggle(panelCamera,"TOGGLE_SMOOTH","camera_smooth",state.smooth,function(on) state.smooth=on end)
            UI.slider(panelCamera,"SLIDER_CAM_SENS","camera_sens",0.2,3,Persist.get("camera_sens",1),0.1,function(v)
                camSensitivityMultiplier = v
            end)
            workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
                task.defer(function()
                    local cam = workspace.CurrentCamera
                    if cam then
                        cam.FieldOfView = Persist.get("camera_fov",70)
                    end
                end)
            end)
            local lastCF
            local lastDelta = Vector2.zero
            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    lastDelta = input.Delta
                end
            end)
            RunService.RenderStepped:Connect(function()
                local cam = workspace.CurrentCamera
                if not cam then return end
                if state.shiftLock and not isMobile then
                    if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
                        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                    end
                else
                    if not isMobile and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
                        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                    end
                end
                if state.smooth then
                    if lastCF then cam.CFrame = lastCF:Lerp(cam.CFrame,0.25) end
                    lastCF = cam.CFrame
                else
                    lastCF=nil
                end
                if camSensitivityMultiplier ~= 1 and not isMobile then
                    local delta = lastDelta * (camSensitivityMultiplier - 1) * 0.002
                    if delta.Magnitude > 0 then
                        local cf = cam.CFrame
                        cf = cf * CFrame.Angles(0,-delta.X,0) * CFrame.Angles(-delta.Y,0,0)
                        cam.CFrame = cf
                    end
                end
            end)
        end
    })

    -- Stats
    Core.register({
        name="StatsPanel",
        init=function()
            local fpsLabel = UI.label(panelStats,L("LABEL_FPS")..": ...",false)
            local memLabel = UI.label(panelStats,L("LABEL_MEM")..": ... KB",false)
            local pingLabel = UI.label(panelStats,L("LABEL_PING")..": ... ms",false)
            local playerCount = UI.label(panelStats,L("LABEL_PLAYERS")..": ...",false)
            local frames,last=0,tick()
            RunService.RenderStepped:Connect(function()
                frames+=1
                local now=tick()
                if now-last>=1 then
                    local fps=math.floor(frames/(now-last))
                    frames=0; last=now
                    local mem=gcinfo()
                    local ping=Stats.Network.ServerStatsItem["Data Ping"] and Stats.Network.ServerStatsItem["Data Ping"]:GetValue() or -1
                    fpsLabel.Text = L("LABEL_FPS")..": "..fps
                    memLabel.Text = L("LABEL_MEM")..": "..mem.." KB"
                    pingLabel.Text = L("LABEL_PING")..": "..ping.." ms"
                    playerCount.Text = L("LABEL_PLAYERS")..": "..#Players:GetPlayers()
                end
            end)
        end
    })

    -- Extras (Overlay / Noclip / Posições / Ambiente) + Noclip Fix
    Core.register({
        name="Extras",
        init=function(ctx)
            UI.toggle(panelExtras,"TOGGLE_OVERLAY","overlay_visible",Persist.get("overlay_visible",true),function(on)
                if ctx.PerfOverlayLabel then ctx.PerfOverlayLabel.Visible = on end
                Persist.set("overlay_visible", on)
            end)
            UI.slider(panelExtras,"SLIDER_OVERLAY_INTERVAL","overlay_interval",0.2,5,Persist.get("overlay_interval",1),0.1,function(v)
                Persist.set("overlay_interval", v)
            end)
            UI.button(panelExtras,"BTN_OVERLAY_RESET",true,function()
                if ctx.PerfOverlayLabel then
                    ctx.PerfOverlayLabel.Position = UDim2.new(1,-210,0,10)
                end
            end)

            -- Noclip (corrigido: restaura estado original)
            local noclipConn
            local noclipCharConn
            local storedCollision = {}

            local function applyNoclipToCharacter(char)
                if not char then return end
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if storedCollision[part] == nil then
                            storedCollision[part] = part.CanCollide
                        end
                        part.CanCollide = false
                    end
                end
            end

            UI.toggle(panelExtras,"TOGGLE_NOCLIP","extra_noclip",false,function(on)
                if on then
                    storedCollision = {}
                    applyNoclipToCharacter(LocalPlayer.Character)
                    noclipConn = RunService.Stepped:Connect(function()
                        local char = LocalPlayer.Character
                        if char then
                            for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    if storedCollision[part] == nil then
                                        storedCollision[part] = part.CanCollide
                                    end
                                    part.CanCollide = false
                                end
                            end
                        end
                    end)
                    noclipCharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
                        task.wait(0.25)
                        applyNoclipToCharacter(newChar)
                    end)
                else
                    if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
                    if noclipCharConn then noclipCharConn:Disconnect(); noclipCharConn=nil end
                    for part, original in pairs(storedCollision) do
                        if part and part.Parent and part:IsA("BasePart") then
                            part.CanCollide = original
                        end
                    end
                    storedCollision = {}
                end
            end)

            -- Posições
            UI.label(panelExtras,"SECTION_POSITIONS",true)
            local savedPositions = Persist.get("saved_positions", {})
            local function savePositions() Persist.set("saved_positions", savedPositions) end
            local coordsLabel = UI.label(panelExtras, L("LABEL_POS_ATUAL")..": ...", false)
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
            listFrame.Parent = panelExtras
            local lfLayout = Instance.new("UIListLayout", listFrame)
            lfLayout.SortOrder = Enum.SortOrder.LayoutOrder
            lfLayout.Padding = UDim.new(0,4)

            local function rebuildPosList()
                for _, c in ipairs(listFrame:GetChildren()) do
                    if c:IsA("TextButton") or c.Name=="EmptyLabel" then c:Destroy() end
                end
                if #savedPositions == 0 then
                    local lbl = UI.label(listFrame, (Lang.current=="pt") and "Nenhuma posição salva." or "No saved positions.", false)
                    lbl.Name="EmptyLabel"
                end
                for i,data in ipairs(savedPositions) do
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1,0,0,26)
                    btn.BackgroundColor3 = Color3.fromRGB(45,55,65)
                    btn.TextColor3 = Color3.new(1,1,1)
                    btn.Font = Enum.Font.Gotham
                    btn.TextSize = 13
                    btn.Text = i..": ("..math.floor(data.x)..","..math.floor(data.y)..","..math.floor(data.z)..")  [TP]"
                    btn.Parent = listFrame
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
                    btn.MouseButton1Click:Connect(function()
                        local root = Util.getRoot()
                        if root then
                            root.CFrame = CFrame.new(data.x,data.y,data.z)
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

            UI.button(panelExtras,"BTN_SAVE_POS",true,function()
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
            UI.button(panelExtras,"BTN_CLEAR_POS",true,function()
                savedPositions={}
                savePositions()
                rebuildPosList()
            end)
            if typeof(setclipboard) == "function" then
                UI.button(panelExtras,"BTN_COPY_POS",true,function()
                    local root = Util.getRoot()
                    if root then
                        local p = root.Position
                        setclipboard(string.format("%.2f, %.2f, %.2f", p.X,p.Y,p.Z))
                        notify("Pos", L("NOTIFY_POS_COPIED"))
                    end
                end)
            end

            -- Ambiente
            UI.label(panelExtras,"SECTION_AMBIENCE",true)
            local applyLighting = false
            local originalTime = Lighting.ClockTime
            local desiredTime = Persist.get("world_time_value", Lighting.ClockTime)
            UI.slider(panelExtras,"SLIDER_WORLD_TIME","world_time_value",0,24,desiredTime,0.25,function(v)
                desiredTime = v
                if applyLighting then Lighting.ClockTime = desiredTime end
            end)
            UI.toggle(panelExtras,"TOGGLE_WORLD_TIME","world_time_apply",false,function(on)
                applyLighting = on
                if on then
                    originalTime = Lighting.ClockTime
                    Lighting.ClockTime = desiredTime
                else
                    Lighting.ClockTime = originalTime
                end
            end)
        end
    })

    -- Fly GUI Legacy
    Core.register({
        name="LegacyFlyGUI",
        init=function()
            UI.label(panelFly,"LEGACY_FLY_NOTE",true)

            local flyGuiInstance
            local isOpen = false
            local toggleBtn

            local function buildFlyGUI()
                if flyGuiInstance then
                    flyGuiInstance.Enabled = true
                    return
                end

                local main = Instance.new("ScreenGui")
                main.Name = "FlyLegacyGUI"
                main.ResetOnSpawn = false
                pcall(function()
                    main.Parent = (gethui and gethui()) or game:GetService("CoreGui")
                end)

                local Frame = Instance.new("Frame")
                Frame.Parent = main
                Frame.BackgroundColor3 = Color3.fromRGB(163, 255, 137)
                Frame.BorderColor3 = Color3.fromRGB(103, 221, 213)
                Frame.Position = UDim2.new(0.100320168, 0, 0.379746825, 0)
                Frame.Size = UDim2.new(0, 190, 0, 57)

                local up = Instance.new("TextButton")
                up.Name = "up"
                up.Parent = Frame
                up.BackgroundColor3 = Color3.fromRGB(79, 255, 152)
                up.Size = UDim2.new(0, 44, 0, 28)
                up.Font = Enum.Font.SourceSans
                up.Text = "UP"
                up.TextColor3 = Color3.fromRGB(0, 0, 0)
                up.TextSize = 14

                local down = up:Clone()
                down.Name = "down"
                down.Text = "DOWN"
                down.BackgroundColor3 = Color3.fromRGB(215,255,121)
                down.Position = UDim2.new(0, 0, 0.491228074, 0)
                down.Parent = Frame

                local onof = Instance.new("TextButton")
                onof.Name = "onof"
                onof.Parent = Frame
                onof.BackgroundColor3 = Color3.fromRGB(255, 249, 74)
                onof.Position = UDim2.new(0.702823281, 0, 0.491228074, 0)
                onof.Size = UDim2.new(0, 56, 0, 28)
                onof.Font = Enum.Font.SourceSans
                onof.Text = "fly"
                onof.TextColor3 = Color3.fromRGB(0,0,0)
                onof.TextSize = 14

                local title = Instance.new("TextLabel")
                title.Parent = Frame
                title.BackgroundColor3 = Color3.fromRGB(242,60,255)
                title.Position = UDim2.new(0.469327301, 0, 0, 0)
                title.Size = UDim2.new(0, 100, 0, 28)
                title.Font = Enum.Font.SourceSans
                title.Text = "FLY GUI V3"
                title.TextColor3 = Color3.fromRGB(0,0,0)
                title.TextScaled = true
                title.TextWrapped = true

                local plus = Instance.new("TextButton")
                plus.Name = "plus"
                plus.Parent = Frame
                plus.BackgroundColor3 = Color3.fromRGB(133,145,255)
                plus.Position = UDim2.new(0.231578946, 0, 0, 0)
                plus.Size = UDim2.new(0, 45, 0, 28)
                plus.Font = Enum.Font.SourceSans
                plus.Text = "+"
                plus.TextColor3 = Color3.fromRGB(0,0,0)
                plus.TextScaled = true
                plus.TextWrapped = true

                local speedLbl = Instance.new("TextLabel")
                speedLbl.Name = "speed"
                speedLbl.Parent = Frame
                speedLbl.BackgroundColor3 = Color3.fromRGB(255,85,0)
                speedLbl.Position = UDim2.new(0.468421042, 0, 0.491228074, 0)
                speedLbl.Size = UDim2.new(0, 44, 0, 28)
                speedLbl.Font = Enum.Font.SourceSans
                speedLbl.Text = "1"
                speedLbl.TextColor3 = Color3.fromRGB(0,0,0)
                speedLbl.TextScaled = true
                speedLbl.TextWrapped = true

                local mine = plus:Clone()
                mine.Name = "mine"
                mine.Text = "-"
                mine.Position = UDim2.new(0.231578946, 0, 0.491228074, 0)
                mine.Size = UDim2.new(0,45,0,29)
                mine.Parent = Frame

                local closebutton = Instance.new("TextButton")
                closebutton.Name = "Close"
                closebutton.Parent = Frame
                closebutton.BackgroundColor3 = Color3.fromRGB(225,25,0)
                closebutton.Size = UDim2.new(0,45,0,28)
                closebutton.Text = "X"
                closebutton.TextSize = 30
                closebutton.Font = Enum.Font.SourceSans
                closebutton.Position = UDim2.new(0,0,-1,27)

                local mini = Instance.new("TextButton")
                mini.Name = "minimize"
                mini.Parent = Frame
                mini.BackgroundColor3 = Color3.fromRGB(192,150,230)
                mini.Size = UDim2.new(0,45,0,28)
                mini.Text = "-"
                mini.TextSize = 40
                mini.Font = Enum.Font.SourceSans
                mini.Position = UDim2.new(0,44,-1,27)

                local mini2 = Instance.new("TextButton")
                mini2.Name = "minimize2"
                mini2.Parent = Frame
                mini2.BackgroundColor3 = Color3.fromRGB(192,150,230)
                mini2.Size = UDim2.new(0,45,0,28)
                mini2.Text = "+"
                mini2.TextSize = 40
                mini2.Font = Enum.Font.SourceSans
                mini2.Position = UDim2.new(0,44,-1,57)
                mini2.Visible = false

                local speeds = 1
                local speaker = Players.LocalPlayer
                local nowe = false
                local tpwalking = false

                notify("FLY GUI V3","BY XNEO",4)

                Frame.Active = true
                Frame.Draggable = true

                local function enableStates(h,on)
                    local list = {
                        "Climbing","FallingDown","Flying","Freefall","GettingUp","Jumping","Landed",
                        "Physics","PlatformStanding","Ragdoll","Running","RunningNoPhysics",
                        "Seated","StrafingNoPhysics","Swimming"
                    }
                    for _, name in ipairs(list) do
                        safe(function()
                            h:SetStateEnabled(Enum.HumanoidStateType[name], on)
                        end)
                    end
                end

                onof.MouseButton1Down:Connect(function()
                    local hum = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
                    if not hum then return end
                    if nowe then
                        nowe = false
                        tpwalking = false
                        enableStates(hum,true)
                        hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
                        if speaker.Character:FindFirstChild("Animate") then
                            speaker.Character.Animate.Disabled = false
                        end
                    else
                        nowe = true
                        enableStates(hum,false)
                        hum:ChangeState(Enum.HumanoidStateType.Swimming)
                        if speaker.Character:FindFirstChild("Animate") then
                            speaker.Character.Animate.Disabled = true
                            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                                track:AdjustSpeed(0)
                            end
                        end
                        tpwalking = true
                        for i = 1, speeds do
                            task.spawn(function()
                                local hb = RunService.Heartbeat
                                local chr = speaker.Character
                                local h = chr and chr:FindFirstChildWhichIsA("Humanoid")
                                while tpwalking and hb:Wait() and chr and h and h.Parent do
                                    if h.MoveDirection.Magnitude > 0 then
                                        chr:TranslateBy(h.MoveDirection)
                                    end
                                end
                            end)
                        end
                    end
                end)

                local tis
                up.MouseButton1Down:Connect(function()
                    tis = up.MouseEnter:Connect(function()
                        while tis do
                            RunService.Heartbeat:Wait()
                            local root = Util.getRoot()
                            if root then
                                root.CFrame = root.CFrame * CFrame.new(0,1,0)
                            end
                        end
                    end)
                end)
                up.MouseLeave:Connect(function()
                    if tis then tis:Disconnect(); tis=nil end
                end)

                local dis
                down.MouseButton1Down:Connect(function()
                    dis = down.MouseEnter:Connect(function()
                        while dis do
                            RunService.Heartbeat:Wait()
                            local root = Util.getRoot()
                            if root then
                                root.CFrame = root.CFrame * CFrame.new(0,-1,0)
                            end
                        end
                    end)
                end)
                down.MouseLeave:Connect(function()
                    if dis then dis:Disconnect(); dis=nil end
                end)

                Players.LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(0.7)
                    local hum2 = Util.getHumanoid()
                    if hum2 then
                        hum2.PlatformStand = false
                    end
                    local anim = Players.LocalPlayer.Character:FindFirstChild("Animate")
                    if anim then anim.Disabled = false end
                end)

                plus.MouseButton1Down:Connect(function()
                    speeds += 1
                    speedLbl.Text = tostring(speeds)
                    if nowe then
                        tpwalking = false
                        task.wait()
                        tpwalking = true
                        for i = 1, speeds do
                            task.spawn(function()
                                local hb = RunService.Heartbeat
                                local chr = speaker.Character
                                local h = chr and chr:FindFirstChildWhichIsA("Humanoid")
                                while tpwalking and hb:Wait() and chr and h and h.Parent do
                                    if h.MoveDirection.Magnitude > 0 then
                                        chr:TranslateBy(h.MoveDirection)
                                    end
                                end
                            end)
                        end
                    end
                end)

                mine.MouseButton1Down:Connect(function()
                    if speeds == 1 then
                        speedLbl.Text = 'min 1'
                        task.delay(1,function()
                            speedLbl.Text = tostring(speeds)
                        end)
                    else
                        speeds -= 1
                        speedLbl.Text = tostring(speeds)
                        if nowe then
                            tpwalking = false
                            task.wait()
                            tpwalking = true
                            for i = 1, speeds do
                                task.spawn(function()
                                    local hb = RunService.Heartbeat
                                    local chr = speaker.Character
                                    local h = chr and chr:FindFirstChildWhichIsA("Humanoid")
                                    while tpwalking and hb:Wait() and chr and h and h.Parent do
                                        if h.MoveDirection.Magnitude > 0 then
                                            chr:TranslateBy(h.MoveDirection)
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end)

                closebutton.MouseButton1Click:Connect(function()
                    main.Enabled = false
                    isOpen = false
                    if toggleBtn then toggleBtn.Text = L("FLYGUI_OPEN") end
                end)

                mini.MouseButton1Click:Connect(function()
                    up.Visible=false; down.Visible=false; onof.Visible=false; plus.Visible=false; speedLbl.Visible=false; mine.Visible=false
                    mini.Visible=false; mini2.Visible=true
                    Frame.BackgroundTransparency=1
                end)
                mini2.MouseButton1Click:Connect(function()
                    up.Visible=true; down.Visible=true; onof.Visible=true; plus.Visible=true; speedLbl.Visible=true; mine.Visible=true
                    mini.Visible=true; mini2.Visible=false
                    Frame.BackgroundTransparency=0
                end)

                flyGuiInstance = main
            end

            toggleBtn = UI.button(panelFly,"FLYGUI_OPEN",true,function()
                if not isOpen then
                    buildFlyGUI()
                    isOpen = true
                    if toggleBtn then toggleBtn.Text = L("FLYGUI_CLOSE") end
                else
                    if flyGuiInstance then flyGuiInstance.Enabled = false end
                    isOpen = false
                    if toggleBtn then toggleBtn.Text = L("FLYGUI_OPEN") end
                end
            end)
        end
    })

    -- Inicializar
    Core.initPlugins()
    UI.applyLanguage()
    notify("Universal Utility", L("NOTIFY_LOADED", VERSION), 4)
end)

return {
    Core = Core,
    UI = UI,
    Util = Util,
    Persist = Persist,
    Lang = Lang
}