--[[
Universal Client Utility (Advanced UI) v0.5.0
Autor: (Eduardo854832)
Changelog 0.5.0:
 - Fly refeito (PC e Mobile): AlignVelocity/AlignOrientation (fallback), botões UP/DOWN mobile, modo relativo à câmera
 - Opção "Fly Suave" + ajuste de aceleração
 - Persistência de estado Fly + reaplicar se marcado
 - Atualização do Overlay configurável (intervalo)
 - Mais traduções / chaves novas
 - Otimizações de conexões / limpeza segura
 - Pequenas melhorias de UI e organização de plugins
 - Mantidos recursos de 0.4.x (internationalization, extras, noclip, positions, etc.)
Uso educacional; não usar para violar ToS.
]]

local VERSION = "0.5.0"

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

-- ==== Internacionalização (estendido) ====
local Lang = {}
Lang.data = {
    pt = {
        UI_TITLE = "Universal Utility v%s",
        TAB_GENERAL = "Geral",
        TAB_MOVEMENT = "Movimento",
        TAB_CAMERA = "Câmera",
        TAB_STATS = "Stats",
        TAB_EXTRAS = "Extras",
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
        LABEL_LANG = "Idioma",
        LABEL_LANG_CHANGE = "Alterar Idioma",
        LABEL_OVERLAY_INTERVAL = "Intervalo Overlay (s)",
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
        TOGGLE_FLY = "Fly (WASD/Toque)",
        TOGGLE_FLY_SMOOTH = "Fly Suave",
        TOGGLE_FLY_RELATIVE = "Fly Relativo à Câmera",
        TOGGLE_WORLD_TIME = "Aplicar Hora Custom",
        TOGGLE_FLY_REAPPLY = "Reaplicar Fly ao Respawn",
        SLIDER_WALKSPEED = "WalkSpeed",
        SLIDER_JUMPPOWER = "JumpPower",
        SLIDER_FOV = "FOV",
        SLIDER_CAM_SENS = "Sensibilidade",
        SLIDER_FLY_SPEED = "Velocidade Fly",
        SLIDER_FLY_ACCEL = "Aceleração Fly",
        SLIDER_WORLD_TIME = "Hora (ClockTime)",
        SLIDER_OVERLAY_INTERVAL = "Overlay Intervalo",
        NOTIFY_INFO = "Use as tabs para ajustes.",
        NOTIFY_FOV_RESET = "FOV redefinido para 70",
        NOTIFY_POS_LIMIT = "Limite de 5 atingido (remova com botão direito).",
        NOTIFY_NO_ROOT = "Sem HumanoidRootPart.",
        NOTIFY_POS_COPIED = "Coordenadas copiadas.",
        NOTIFY_POS_SAVED = "Posição salva.",
        NOTIFY_LOADED = "Carregado v%s",
        NOTIFY_SELECT_LANGUAGE = "Selecione um idioma",
        LANG_PT = "Português",
        LANG_EN = "English",
        LANG_CHANGED = "Idioma alterado (recarregado).",
        NOTIFY_FLY_ON = "Fly Ativado",
        NOTIFY_FLY_OFF = "Fly Desativado",
        NOTIFY_FLY_FAIL = "Falha ao iniciar Fly",
    },
    en = {
        UI_TITLE = "Universal Utility v%s",
        TAB_GENERAL = "General",
        TAB_MOVEMENT = "Movement",
        TAB_CAMERA = "Camera",
        TAB_STATS = "Stats",
        TAB_EXTRAS = "Extras",
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
        LABEL_LANG = "Language",
        LABEL_LANG_CHANGE = "Change Language",
        LABEL_OVERLAY_INTERVAL = "Overlay Interval (s)",
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
        TOGGLE_FLY = "Fly (WASD/Touch)",
        TOGGLE_FLY_SMOOTH = "Smooth Fly",
        TOGGLE_FLY_RELATIVE = "Fly Relative To Camera",
        TOGGLE_WORLD_TIME = "Apply Custom Time",
        TOGGLE_FLY_REAPPLY = "Reapply Fly On Respawn",
        SLIDER_WALKSPEED = "WalkSpeed",
        SLIDER_JUMPPOWER = "JumpPower",
        SLIDER_FOV = "FOV",
        SLIDER_CAM_SENS = "Sensitivity",
        SLIDER_FLY_SPEED = "Fly Speed",
        SLIDER_FLY_ACCEL = "Fly Accel",
        SLIDER_WORLD_TIME = "Time (ClockTime)",
        SLIDER_OVERLAY_INTERVAL = "Overlay Interval",
        NOTIFY_INFO = "Use tabs for tweaks.",
        NOTIFY_FOV_RESET = "FOV reset to 70",
        NOTIFY_POS_LIMIT = "Limit of 5 reached (right click to remove).",
        NOTIFY_NO_ROOT = "No HumanoidRootPart.",
        NOTIFY_POS_COPIED = "Coordinates copied.",
        NOTIFY_POS_SAVED = "Position saved.",
        NOTIFY_LOADED = "Loaded v%s",
        NOTIFY_SELECT_LANGUAGE = "Select a language",
        LANG_PT = "Português",
        LANG_EN = "English",
        LANG_CHANGED = "Language changed (reloaded).",
        NOTIFY_FLY_ON = "Fly Enabled",
        NOTIFY_FLY_OFF = "Fly Disabled",
        NOTIFY_FLY_FAIL = "Failed to start Fly",
    }
}
Lang.current = Persist.get("lang", nil)

local function L(key, ...)
    local pack = Lang.data[Lang.current or "pt"]
    local s = pack and pack[key] or key
    if select("#", ...) > 0 then
        return string.format(s, ...)
    end
    return s
end

-- Seleção inicial de idioma
local function ensureLanguage(callback)
    if Lang.current then
        callback()
        return
    end
    local sg = Instance.new("ScreenGui")
    sg.Name = "LanguageSelect"
    sg.ResetOnSpawn = false
    pcall(function()
        sg.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 160)
    frame.Position = UDim2.new(0.5, -150, 0.5, -80)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,35)
    frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -20, 0, 50)
    title.Position = UDim2.new(0,10,0,10)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.new(1,1,1)
    title.Text = "Português ou English?"
    title.Parent = frame

    local btnPT = Instance.new("TextButton")
    btnPT.Size = UDim2.new(0.5, -15, 0, 50)
    btnPT.Position = UDim2.new(0,10,0,70)
    btnPT.BackgroundColor3 = Color3.fromRGB(45,90,55)
    btnPT.Font = Enum.Font.GothamBold
    btnPT.TextSize = 16
    btnPT.TextColor3 = Color3.new(1,1,1)
    btnPT.Text = "Português"
    btnPT.Parent = frame
    Instance.new("UICorner", btnPT).CornerRadius = UDim.new(0,8)

    local btnEN = btnPT:Clone()
    btnEN.Position = UDim2.new(0.5,5,0,70)
    btnEN.Text = "English"
    btnEN.BackgroundColor3 = Color3.fromRGB(55,55,105)
    btnEN.Parent = frame

    local function choose(code)
        Lang.current = code
        Persist.set("lang", code)
        sg:Destroy()
        callback()
    end
    btnPT.MouseButton1Click:Connect(function() choose("pt") end)
    btnEN.MouseButton1Click:Connect(function() choose("en") end)
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
function Util.draggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging=false
    local dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=input.Position
            startPos=frame.Position
            input.Changed:Connect(function(chg)
                if chg == Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    dragHandle.InputChanged:Connect(function(input)
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
function Core.cleanup()
    for _, c in ipairs(Core._connections) do
        safe(function() c:Disconnect() end)
    end
    Core._connections = {}
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

-- ==== UI Builder ====
local UI = {}
UI._tabs = {}
UI._activeTab = nil
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
    if UI.TitleLabel then UI.TitleLabel.Text = L("UI_TITLE", VERSION) end
    if UI.KeybindLabel then UI.KeybindLabel.Text = L("BTN_SHOW_HIDE") end

    local mapping = {
        Geral="TAB_GENERAL", Movimento="TAB_MOVEMENT", ["Câmera"]="TAB_CAMERA",
        Stats="TAB_STATS", Extras="TAB_EXTRAS", General="TAB_GENERAL",
        Movement="TAB_MOVEMENT", Camera="TAB_CAMERA"
    }
    for _, tabInfo in pairs(UI._tabs) do
        local original = tabInfo._rawName
        local key = mapping[original] or original
        if Lang.data[Lang.current][key] then
            tabInfo.button.Text = tabInfo._icon .. " " .. L(key)
        end
    end
end

function UI.createRoot()
    local screen = Instance.new("ScreenGui")
    screen.Name = "UniversalUtilityAdvanced"
    screen.ResetOnSpawn = false
    pcall(function()
        screen.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end)

    local floatBtn = Instance.new("TextButton")
    floatBtn.Name = "FloatingHub"
    floatBtn.Size = UDim2.new(0, 48, 0, 48)
    floatBtn.Position = UDim2.new(0, 12, 0.5, -24)
    floatBtn.BackgroundColor3 = Color3.fromRGB(30,30,38)
    floatBtn.Text = "≡"
    floatBtn.TextColor3 = Color3.new(1,1,1)
    floatBtn.Font = Enum.Font.GothamBold
    floatBtn.TextSize = 20
    floatBtn.Parent = screen
    Util.draggable(floatBtn, floatBtn)

    local window = Instance.new("Frame")
    window.Name = "MainWindow"
    window.Size = UDim2.new(0, 560, 0, 470)
    window.Position = UDim2.new(0, 80, 0.5, -235)
    window.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    window.BorderSizePixel = 0
    window.Parent = screen
    Instance.new("UICorner", window).CornerRadius = UDim.new(0,10)

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Color3.fromRGB(28,28,36)
    header.BorderSizePixel = 0
    header.Parent = window
    Instance.new("UICorner", header).CornerRadius = UDim.new(0,10)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 12, 0, 0)
    title.Size = UDim2.new(1, -200, 1, 0)
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(230,230,240)
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = L("UI_TITLE", VERSION)
    title.Parent = header
    UI.TitleLabel = title

    local keyInfo = Instance.new("TextLabel")
    keyInfo.BackgroundTransparency = 1
    keyInfo.Position = UDim2.new(1, -200, 0, 0)
    keyInfo.Size = UDim2.new(0, 190, 1, 0)
    keyInfo.Font = Enum.Font.Gotham
    keyInfo.Text = L("BTN_SHOW_HIDE")
    keyInfo.TextSize = 12
    keyInfo.TextColor3 = Color3.fromRGB(200,200,210)
    keyInfo.TextXAlignment = Enum.TextXAlignment.Right
    keyInfo.Parent = header
    UI.KeybindLabel = keyInfo

    local minimize = Instance.new("TextButton")
    minimize.Text = "-"
    minimize.Size = UDim2.new(0, 40, 0, 36)
    minimize.Position = UDim2.new(1, -92, 0, 4)
    minimize.BackgroundTransparency = 1
    minimize.TextColor3 = Color3.fromRGB(200,200,200)
    minimize.Font = Enum.Font.GothamBold
    minimize.TextSize = 24
    minimize.Parent = header

    local close = Instance.new("TextButton")
    close.Text = "×"
    close.Size = UDim2.new(0, 40, 0, 36)
    close.Position = UDim2.new(1, -48, 0, 4)
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.fromRGB(200,80,80)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 24
    close.Parent = header

    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(0, 150, 1, -44)
    tabBar.Position = UDim2.new(0, 0, 0, 44)
    tabBar.BackgroundColor3 = Color3.fromRGB(24,24,32)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = window
    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)

    local content = Instance.new("Frame")
    content.Name = "ContentArea"
    content.Size = UDim2.new(1, -150, 1, -44)
    content.Position = UDim2.new(0, 150, 0, 44)
    content.BackgroundColor3 = Color3.fromRGB(16,16,22)
    content.BorderSizePixel = 0
    content.Parent = window

    Util.draggable(window, header)

    local minimized=false
    local savedSize = window.Size
    local minimizableChildren={}
    local function collectChildren()
        minimizableChildren={}
        for _, v in ipairs(window:GetChildren()) do
            if v ~= header and Util.isGuiObject(v) then
                table.insert(minimizableChildren, v)
            end
        end
    end
    collectChildren()
    window.ChildAdded:Connect(function() task.defer(collectChildren) end)

    local function setMinimized(state)
        if state == minimized then return end
        minimized = state
        if minimized then
            TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                Size = UDim2.new(savedSize.X.Scale, savedSize.X.Offset, 0, 60)
            }):Play()
            for _, v in ipairs(minimizableChildren) do v.Visible=false end
            minimize.Text = "+"
        else
            TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                Size = savedSize
            }):Play()
            task.delay(0.32,function()
                if not minimized then
                    for _, v in ipairs(minimizableChildren) do v.Visible=true end
                end
            end)
            minimize.Text = "-"
        end
        Persist.set("ui_minimized", minimized)
    end
    minimize.MouseButton1Click:Connect(function() setMinimized(not minimized) end)
    close.MouseButton1Click:Connect(function() window.Visible=false end)
    UserInputService.InputBegan:Connect(function(input,gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F4 then
            window.Visible = not window.Visible
        end
    end)
    floatBtn.MouseButton1Click:Connect(function()
        window.Visible = not window.Visible
    end)
    setMinimized(Persist.get("ui_minimized", false))

    UI.Screen = screen
    UI.Window = window
    UI.TabBar = tabBar
    UI.ContentArea = content
    UI.Minimize = setMinimized
    UI.FloatingButton = floatBtn
end

function UI.createTab(rawName, icon)
    local keyMap = {
        ["Geral"]="TAB_GENERAL", ["Movimento"]="TAB_MOVEMENT", ["Câmera"]="TAB_CAMERA",
        ["Stats"]="TAB_STATS", ["Extras"]="TAB_EXTRAS", ["General"]="TAB_GENERAL",
        ["Movement"]="TAB_MOVEMENT", ["Camera"]="TAB_CAMERA"
    }
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,36)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    btn.TextColor3 = Color3.fromRGB(220,220,230)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    local labelKey = keyMap[rawName] or rawName
    local translated = Lang.data[Lang.current][labelKey] or rawName
    btn.Text = (icon and icon.." " or "") .. translated
    btn.Parent = UI.TabBar

    local frame = Instance.new("ScrollingFrame")
    frame.Name = "Content_"..rawName
    frame.Size = UDim2.new(1,-20,1,-20)
    frame.Position = UDim2.new(0,10,0,10)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.CanvasSize = UDim2.new(0,0,0,0)
    frame.ScrollBarThickness = 6
    frame.Visible = false
    frame.Parent = UI.ContentArea

    local layout = Instance.new("UIListLayout", frame)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,8)
    local function recalc()
        local total=0
        for _, c in ipairs(frame:GetChildren()) do
            if c:IsA("GuiObject") and c.Visible then
                total += c.AbsoluteSize.Y + 8
            end
        end
        frame.CanvasSize = UDim2.new(0,0,0,total+20)
    end
    layout.Changed:Connect(function(p) if p=="AbsoluteContentSize" then recalc() end end)
    frame.ChildAdded:Connect(function() task.wait(0.05); recalc() end)

    UI._tabs[rawName] = {button=btn, frame=frame, _rawName=rawName, _icon=icon or ""}

    btn.MouseButton1Click:Connect(function() UI.selectTab(rawName) end)
    if not UI._activeTab then UI.selectTab(rawName) end
    return frame
end

function UI.selectTab(name)
    for tabName, data in pairs(UI._tabs) do
        local active = (tabName == name)
        data.frame.Visible = active
        TweenService:Create(data.button, TweenInfo.new(0.18), {
            BackgroundColor3 = active and Color3.fromRGB(80,80,110) or Color3.fromRGB(40,40,50)
        }):Play()
    end
    UI._activeTab = name
    Persist.set("ui_last_tab", name)
end
function UI.restoreLastTab()
    local last = Persist.get("ui_last_tab", nil)
    if last and UI._tabs[last] then
        UI.selectTab(last)
    end
end

function UI.section(parent, keyTitle)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundColor3 = Color3.fromRGB(26,26,34)
    frame.BorderSizePixel = 0
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 26)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = L(keyTitle)
    title.Parent = frame
    mark(title, keyTitle)

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 0, 0)
    content.Position = UDim2.new(0, 10, 0, 36)
    content.BackgroundTransparency = 1
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.Parent = frame
    local layout = Instance.new("UIListLayout", content)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,6)
    return content
end

function UI.toggle(parent, labelKey, key, default, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1,0,0,32)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,52,0,26)
    btn.Position = UDim2.new(0,0,0,3)
    btn.BackgroundColor3 = Color3.fromRGB(90,90,90)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = holder
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 56, 0, 0)
    lbl.Size = UDim2.new(1, -56, 1, 0)
    lbl.Text = L(labelKey)
    lbl.TextColor3 = Color3.fromRGB(230,230,230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = holder
    mark(lbl, labelKey)

    local state = Persist.get(key, default)
    local function apply(trigger)
        btn.Text = state and "ON" or "OFF"
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(40,140,70) or Color3.fromRGB(90,90,90)
        }):Play()
        if trigger ~= false then safe(callback, state) end
        Persist.set(key, state)
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
    holder.Size = UDim2.new(1,0,0,58)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local value = Persist.get(key, defaultVal)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,20)
    lbl.BackgroundTransparency = 1
    lbl.Text = L(labelKey)..": "..tostring(value)
    lbl.TextColor3 = Color3.fromRGB(230,230,230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = holder
    mark(lbl, labelKey)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1,-10,0,10)
    bar.Position = UDim2.new(0,5,0,30)
    bar.BackgroundColor3 = Color3.fromRGB(55,55,65)
    bar.BorderSizePixel = 0
    bar.Parent = holder
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0,5)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((value - minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(80,150,240)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,5)

    local dragging=false
    local function applyValue(v, fire)
        fill.Size = UDim2.new((v - minVal)/(maxVal-minVal),0,1,0)
        lbl.Text = L(labelKey)..": "..tostring(v)
        Persist.set(key, v)
        if fire then safe(callback, v) end
    end
    local function setFromX(x, fire)
        local rel = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        local raw = minVal + (maxVal-minVal)*rel
        local snapped = minVal + math.floor((raw - minVal)/step + 0.5)*step
        snapped = math.clamp(snapped, minVal, maxVal)
        applyValue(snapped, fire)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            setFromX(input.Position.X,true)
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
    bar.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            setFromX(input.Position.X,true)
        end
    end)
    safe(callback, value)
    return function(newValue, fire)
        newValue = math.clamp(newValue, minVal, maxVal)
        applyValue(newValue, fire)
    end
end

function UI.label(parent, textKeyOrRaw, isKey)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,22)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(200,200,220)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    if isKey then
        lbl.Text = L(textKeyOrRaw)
        mark(lbl, textKeyOrRaw)
    else
        lbl.Text = textKeyOrRaw
    end
    lbl.Parent = parent
    return lbl
end

-- ==== Construção principal após idioma ====
ensureLanguage(function()
    UI.createRoot()

    -- Tabs
    local tabGeneral = UI.createTab(Lang.current=="pt" and "Geral" or "General", "🏠")
    local tabMove    = UI.createTab(Lang.current=="pt" and "Movimento" or "Movement", "🏃")
    local tabCamera  = UI.createTab(Lang.current=="pt" and "Câmera" or "Camera", "🎥")
    local tabStats   = UI.createTab("Stats", "📊")
    local tabExtras  = UI.createTab("Extras", "⚙️")

    -- ===== Performance Overlay (melhorias: intervalo configurável) =====
    Core.register({
        name = "PerformanceOverlay",
        init = function(ctx)
            local sg = Instance.new("ScreenGui")
            sg.Name = "PerfOverlay"
            sg.ResetOnSpawn = false
            pcall(function()
                sg.Parent = (gethui and gethui()) or game:GetService("CoreGui")
            end)
            local box = Instance.new("TextLabel")
            box.Size = UDim2.new(0, 200, 0, 90)
            box.Position = UDim2.new(1, -210, 0, 10)
            box.BackgroundColor3 = Color3.fromRGB(20,20,26)
            box.TextColor3 = Color3.fromRGB(190,255,200)
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
            local acc = 0
            RunService.RenderStepped:Connect(function()
                frames+=1
                local now = tick()
                acc += (now-last)
                if acc >= interval then
                    local fps = math.floor(frames/acc)
                    frames=0; acc=0; last=now
                    local mem = gcinfo()
                    local ping = Stats.Network.ServerStatsItem["Data Ping"] and Stats.Network.ServerStatsItem["Data Ping"]:GetValue() or -1
                    box.Text = string.format("%s: %d\n%s: %d KB\n%s: %d ms\n%s: %d",
                        L("LABEL_FPS"),fps,L("LABEL_MEM"),mem,L("LABEL_PING"),ping,L("LABEL_PLAYERS"),#Players:GetPlayers())
                else
                    last = now
                end
            end)
            box.Visible = Persist.get("overlay_visible", true)

            -- Controle de intervalo via Extras Section (adicionado depois)
        end
    })

    -- ===== Geral / Info / Idioma / Leaderstats =====
    Core.register({
        name="GeneralInfo",
        init=function()
            local secInfo = UI.section(tabGeneral,"SECTION_INFO")
            UI.label(secInfo, string.format("%s: %s", L("LABEL_VERSION"), VERSION), false)
            UI.label(secInfo, string.format("%s: %s", L("LABEL_FS"), tostring(hasFS)), false)
            UI.label(secInfo, string.format("%s: %s", L("LABEL_DEVICE"), (isMobile and "Mobile" or "PC")), false)
            UI.label(secInfo, string.format("%s: %s", L("LABEL_STARTED"), os.date("%H:%M:%S")), false)

            local langHolder = Instance.new("Frame")
            langHolder.Size = UDim2.new(1,0,0,32)
            langHolder.BackgroundTransparency = 1
            langHolder.Parent = secInfo

            local changeBtn = Instance.new("TextButton")
            changeBtn.Size = UDim2.new(0,180,0,26)
            changeBtn.Position = UDim2.new(0,0,0,3)
            changeBtn.BackgroundColor3 = Color3.fromRGB(60,60,90)
            changeBtn.TextColor3 = Color3.new(1,1,1)
            changeBtn.TextSize = 13
            changeBtn.Font = Enum.Font.GothamBold
            changeBtn.Text = L("LABEL_LANG_CHANGE")
            mark(changeBtn,"LABEL_LANG_CHANGE")
            changeBtn.Parent = langHolder
            Instance.new("UICorner", changeBtn).CornerRadius = UDim.new(0,6)
            changeBtn.MouseButton1Click:Connect(function()
                Lang.current = (Lang.current=="pt") and "en" or "pt"
                Persist.set("lang", Lang.current)
                UI.applyLanguage()
                notify("Lang", L("LANG_CHANGED"))
            end)

            local secLeader = UI.section(tabGeneral,"SECTION_LEADERSTATS")
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1,0,0,0)
            container.AutomaticSize = Enum.AutomaticSize.Y
            container.BackgroundTransparency = 1
            container.Parent = secLeader
            local layout = Instance.new("UIListLayout", container)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0,4)

            local function rebuild()
                for _, c in ipairs(container:GetChildren()) do
                    if c:IsA("TextLabel") then c:Destroy() end
                end
                local ls = LocalPlayer:FindFirstChild("leaderstats")
                if not ls then UI.label(container,"LABEL_NO_LS",true) return end
                for _, v in ipairs(ls:GetChildren()) do
                    if v:IsA("ValueBase") then
                        local lbl = UI.label(container, v.Name..": "..tostring(v.Value), false)
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
        end
    })

    -- ===== Movimento (WalkSpeed / JumpPower / Auto Reapply) =====
    Core.register({
        name="MovementTab",
        init=function()
            local section = UI.section(tabMove,"SECTION_HUMANOID")
            local hum = Util.getHumanoid()
            Core.onCharacterAdded(function()
                task.wait(0.4)
                hum = Util.getHumanoid()
            end,true)
            UI.slider(section,"SLIDER_WALKSPEED","walkspeed_value",4,64,hum and hum.WalkSpeed or 16,1,function(v)
                hum = Util.getHumanoid()
                if hum then hum.WalkSpeed = v end
            end)
            UI.slider(section,"SLIDER_JUMPPOWER","jumppower_value",25,150,hum and hum.JumpPower or 50,1,function(v)
                hum = Util.getHumanoid()
                if hum and hum.UseJumpPower ~= false then hum.JumpPower = v end
            end)
            UI.toggle(section,"TOGGLE_REAPPLY","auto_reapply_stats",true,function(on)
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

    -- ===== Câmera =====
    Core.register({
        name="CameraTab",
        init=function()
            local section = UI.section(tabCamera,"SECTION_CAMERA")
            local camSensitivityMultiplier = 1
            UI.slider(section,"SLIDER_FOV","camera_fov",40,120,workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70,1,function(v)
                local cam = workspace.CurrentCamera
                if cam then cam.FieldOfView = v end
            end)
            local state = {
                shiftLock = Persist.get("camera_shiftlock", false),
                smooth = Persist.get("camera_smooth", false)
            }
            UI.toggle(section,"TOGGLE_SHIFTLOCK","camera_shiftlock",state.shiftLock,function(on) state.shiftLock=on end)
            UI.toggle(section,"TOGGLE_SMOOTH","camera_smooth",state.smooth,function(on) state.smooth=on end)
            UI.slider(section,"SLIDER_CAM_SENS","camera_sens",0.2,3,Persist.get("camera_sens",1),0.1,function(v)
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

    -- ===== Stats =====
    Core.register({
        name="StatsTab",
        init=function()
            local section = UI.section(tabStats,"SECTION_MONITOR")
            local fpsLabel = UI.label(section,L("LABEL_FPS")..": ...",false)
            local memLabel = UI.label(section,L("LABEL_MEM")..": ... KB",false)
            local pingLabel = UI.label(section,L("LABEL_PING")..": ... ms",false)
            local playerCount = UI.label(section,L("LABEL_PLAYERS")..": ...",false)
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

    -- ===== Atalhos Mobile Básicos =====
    Core.register({
        name="TouchHelpers",
        init=function(ctx)
            if not ctx.isMobile then return end
            local sec = UI.section(tabGeneral,"SECTION_TOUCH")
            local btnHolder = Instance.new("Frame")
            btnHolder.Size = UDim2.new(1,0,0,40)
            btnHolder.BackgroundTransparency = 1
            btnHolder.Parent = sec
            local layout = Instance.new("UIListLayout", btnHolder)
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.Padding = UDim.new(0,8)

            local function quick(textKey, cb)
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0,130,0,34)
                b.BackgroundColor3 = Color3.fromRGB(40,40,50)
                b.TextColor3 = Color3.new(1,1,1)
                b.Font = Enum.Font.GothamBold
                b.TextSize = 12
                b.Text = L(textKey)
                mark(b, textKey)
                b.Parent = btnHolder
                b.MouseButton1Click:Connect(function() safe(cb) end)
                Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
            end
            quick("BTN_RESPAWN", function()
                local hum = Util.getHumanoid(); if hum then hum.Health=0 end
            end)
            quick("BTN_RESET_FOV", function()
                local cam = workspace.CurrentCamera
                if cam then
                    cam.FieldOfView = 70
                    Persist.set("camera_fov", 70)
                    notify("FOV", L("NOTIFY_FOV_RESET"))
                end
            end)
            quick("BTN_INFO", function()
                notify("Info", L("NOTIFY_INFO"))
            end)
        end
    })

    -- ===== Fly Controller (Novo) =====
    Core.register({
        name="FlyController",
        init=function(ctx)
            local extrasSection = UI.section(tabExtras,"SECTION_FLY")

            -- Estados Persistentes
            local baseSpeed = Persist.get("fly_speed", 60)
            local accelFactor = Persist.get("fly_accel", 0.25)
            local smoothFly = Persist.get("fly_smooth", true)
            local relativeFly = Persist.get("fly_relative", true)
            local reapplyFly = Persist.get("fly_reapply_respawn", true)
            local wasFlyActive = Persist.get("fly_last_active", false)

            local active = false
            local upDownInput = Vector3.new()
            local moveDir = Vector3.new()
            local velocityGoal = Vector3.zero
            local currentVelocity = Vector3.zero
            local ascend = 0
            local speedMultiplier = 1
            local lastRoot

            -- Instâncias físicas
            local alignVel, alignGyro
            local fallbackBV, fallbackBG

            local function cleanupAttachments()
                if alignVel then alignVel:Destroy(); alignVel=nil end
                if alignGyro then alignGyro:Destroy(); alignGyro=nil end
                if fallbackBV then fallbackBV:Destroy(); fallbackBV=nil end
                if fallbackBG then fallbackBG:Destroy(); fallbackBG=nil end
            end

            local function ensurePhysics(root)
                cleanupAttachments()
                -- Tenta Align*
                local okAV, av = pcall(function()
                    local att = Instance.new("Attachment")
                    att.Name="Fly_Att"
                    att.Parent = root
                    local avObj = Instance.new("VectorForce")
                    -- Usaremos AssemblyLinearVelocity direto em fallback; VectorForce precisa mass * acceleration
                    -- Para maior compat, usar Body movers caso Align não disponível. Simplificando:
                    att:Destroy() -- não usaremos VectorForce aqui (melhoria futura)
                end)
                -- Usaremos BodyVelocity/BodyGyro (compat ampla) + tentativa de AlignVelocity/AlignOrientation se existirem
                local successAlign = pcall(function()
                    alignVel = Instance.new("AlignVelocity")
                    alignVel.ApplyAtCenterOfMass = true
                    alignVel.MaxForce = 1e6
                    alignVel.Mode = Enum.AlignmentMode.OneAttachment
                    local att = root:FindFirstChild("FlyAlignAttachment") or Instance.new("Attachment", root)
                    att.Name="FlyAlignAttachment"
                    alignVel.Attachment0 = att
                    alignVel.Parent = root

                    alignGyro = Instance.new("AlignOrientation")
                    alignGyro.MaxAngularVelocity = math.huge
                    alignGyro.MaxTorque = 1e6
                    alignGyro.Mode = Enum.OrientationAlignmentMode.OneAttachment
                    alignGyro.Attachment0 = att
                    alignGyro.Responsiveness = 50
                    alignGyro.Parent = root
                end)

                if not successAlign then
                    cleanupAttachments()
                    fallbackBV = Instance.new("BodyVelocity")
                    fallbackBV.P = 2e4
                    fallbackBV.MaxForce = Vector3.new(1e5,1e5,1e5)
                    fallbackBV.Velocity = Vector3.zero
                    fallbackBV.Parent = root

                    fallbackBG = Instance.new("BodyGyro")
                    fallbackBG.P = 1e5
                    fallbackBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
                    fallbackBG.CFrame = root.CFrame
                    fallbackBG.Parent = root
                end
            end

            local function setActive(state)
                if state == active then return end
                active = state
                Persist.set("fly_last_active", active)
                if active then
                    local root = Util.getRoot()
                    if not root then
                        notify("Fly", L("NOTIFY_FLY_FAIL"))
                        active = false
                        return
                    end
                    lastRoot = root
                    ensurePhysics(root)
                    notify("Fly", L("NOTIFY_FLY_ON"))
                else
                    cleanupAttachments()
                    notify("Fly", L("NOTIFY_FLY_OFF"))
                end
            end

            -- UI Elements
            UI.slider(extrasSection,"SLIDER_FLY_SPEED","fly_speed",10,250,baseSpeed,5,function(v)
                baseSpeed = v
            end)
            UI.slider(extrasSection,"SLIDER_FLY_ACCEL","fly_accel",0.05,1,accelFactor,0.05,function(v)
                accelFactor = v
                Persist.set("fly_accel", v)
            end)
            UI.toggle(extrasSection,"TOGGLE_FLY_SMOOTH","fly_smooth",smoothFly,function(on)
                smoothFly = on
                Persist.set("fly_smooth", on)
            end)
            UI.toggle(extrasSection,"TOGGLE_FLY_RELATIVE","fly_relative",relativeFly,function(on)
                relativeFly = on
                Persist.set("fly_relative", on)
            end)
            UI.toggle(extrasSection,"TOGGLE_FLY_REAPPLY","fly_reapply_respawn",reapplyFly,function(on)
                reapplyFly = on
            end)

            local toggleFlySetter = UI.toggle(extrasSection,"TOGGLE_FLY","extra_fly",wasFlyActive,function(on)
                setActive(on)
            end)

            -- Mobile control overlay (aparece somente quando Fly ON)
            local mobilePanel
            if isMobile then
                mobilePanel = Instance.new("Frame")
                mobilePanel.Size = UDim2.new(0,155,0,130)
                mobilePanel.Position = UDim2.new(1,-170,1,-150)
                mobilePanel.BackgroundColor3 = Color3.fromRGB(22,22,32)
                mobilePanel.Visible = false
                mobilePanel.Parent = UI.Screen
                Instance.new("UICorner", mobilePanel).CornerRadius = UDim.new(0,10)
                Util.draggable(mobilePanel, mobilePanel)

                local layout = Instance.new("UIListLayout", mobilePanel)
                layout.Padding = UDim.new(0,6)
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                layout.VerticalAlignment = Enum.VerticalAlignment.Top

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1,-10,0,20)
                title.BackgroundTransparency = 1
                title.Text = "Fly"
                title.Font = Enum.Font.GothamBold
                title.TextSize = 14
                title.TextColor3 = Color3.new(1,1,1)
                title.Parent = mobilePanel

                local function smallBtn(textKey, cb)
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(1,-10,0,28)
                    b.BackgroundColor3 = Color3.fromRGB(50,50,70)
                    b.TextColor3 = Color3.new(1,1,1)
                    b.TextSize = 13
                    b.Font = Enum.Font.GothamBold
                    b.Text = L(textKey)
                    mark(b,textKey)
                    b.Parent = mobilePanel
                    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
                    b.MouseButton1Click:Connect(function() safe(cb) end)
                end

                smallBtn("BTN_FLY_UP", function()
                    ascend = 1
                    task.delay(0.25,function() if ascend==1 then ascend=0 end end)
                end)
                smallBtn("BTN_FLY_DOWN", function()
                    ascend = -1
                    task.delay(0.25,function() if ascend==-1 then ascend=0 end end)
                end)
                smallBtn("BTN_FLY_SPEEDMODE", function()
                    if speedMultiplier < 3 then
                        speedMultiplier = speedMultiplier + 0.5
                    else
                        speedMultiplier = 1
                    end
                    notify("Fly", "x"..speedMultiplier)
                end)
            end

            -- Captura de input PC
            local keyStates = {}
            UserInputService.InputBegan:Connect(function(i,gp)
                if gp then return end
                if i.KeyCode == Enum.KeyCode.Space and active then
                    ascend = 1
                end
                if i.KeyCode == Enum.KeyCode.LeftControl and active then
                    ascend = -1
                end
                keyStates[i.KeyCode] = true
            end)
            UserInputService.InputEnded:Connect(function(i)
                keyStates[i.KeyCode] = false
                if (i.KeyCode == Enum.KeyCode.Space and ascend==1) or (i.KeyCode==Enum.KeyCode.LeftControl and ascend==-1) then
                    ascend = 0
                end
            end)

            -- Loop do Fly
            RunService.Heartbeat:Connect(function(dt)
                if not active then
                    if mobilePanel then mobilePanel.Visible = false end
                    return
                end
                local root = Util.getRoot()
                if not root then return end
                if mobilePanel then mobilePanel.Visible = true end

                -- Determinar direção
                local dir = Vector3.zero
                local cam = workspace.CurrentCamera
                if isMobile then
                    -- Direção principal pega do Humanoid.MoveDirection (mobile já gera isso)
                    local hum = Util.getHumanoid()
                    if hum then
                        dir = hum.MoveDirection
                    end
                else
                    -- PC: W A S D
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Vector3.new(0,0,-1) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir += Vector3.new(0,0,1) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir += Vector3.new(-1,0,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Vector3.new(1,0,0) end
                end

                if dir.Magnitude > 0 then dir = dir.Unit end
                local vertical = ascend
                local rel = relativeFly and cam
                if rel then
                    -- Remove componente vertical do look/right para evitar drift
                    local look = cam.CFrame.LookVector
                    local right = cam.CFrame.RightVector
                    look = Vector3.new(look.X,0,look.Z).Unit
                    right = Vector3.new(right.X,0,right.Z).Unit
                    if dir ~= Vector3.zero then
                        dir = (look * -dir.Z + right * dir.X)
                    end
                end

                local base = baseSpeed * speedMultiplier
                velocityGoal = (dir * base) + Vector3.new(0, vertical * base * 0.75, 0)
                if smoothFly then
                    currentVelocity = currentVelocity:Lerp(velocityGoal, math.clamp(accelFactor*dt*60, 0,1))
                else
                    currentVelocity = velocityGoal
                end

                if alignVel then
                    alignVel.Velocity = currentVelocity
                elseif fallbackBV then
                    fallbackBV.Velocity = currentVelocity
                end
                if alignGyro then
                    alignGyro.CFrame = cam and cam.CFrame or root.CFrame
                elseif fallbackBG and cam then
                    fallbackBG.CFrame = cam.CFrame
                end
            end)

            -- Reaplica se configurado
            Core.onCharacterAdded(function()
                if reapplyFly and Persist.get("fly_last_active", false) then
                    task.wait(0.6)
                    setActive(true)
                    toggleFlySetter(true)
                else
                    ascend = 0
                end
            end,false)
        end
    })

    -- ===== Extras (Noclip / Overlay / Positions / Ambiente) =====
    Core.register({
        name="ExtrasTab",
        init=function(ctx)
            local section = UI.section(tabExtras,"SECTION_EXTRAS")
            UI.toggle(section,"TOGGLE_OVERLAY","overlay_visible",Persist.get("overlay_visible",true),function(on)
                if ctx.PerfOverlayLabel then ctx.PerfOverlayLabel.Visible = on end
                Persist.set("overlay_visible", on)
            end)

            UI.slider(section,"SLIDER_OVERLAY_INTERVAL","overlay_interval",0.2,5,Persist.get("overlay_interval",1),0.1,function(v)
                Persist.set("overlay_interval", v)
            end)

            local resetOverlay = Instance.new("TextButton")
            resetOverlay.Size = UDim2.new(1,-4,0,26)
            resetOverlay.BackgroundColor3 = Color3.fromRGB(50,50,60)
            resetOverlay.TextColor3 = Color3.new(1,1,1)
            resetOverlay.Font = Enum.Font.GothamBold
            resetOverlay.TextSize = 14
            resetOverlay.Text = L("BTN_OVERLAY_RESET")
            mark(resetOverlay,"BTN_OVERLAY_RESET")
            resetOverlay.Parent = section
            Instance.new("UICorner", resetOverlay).CornerRadius = UDim.new(0,6)
            resetOverlay.MouseButton1Click:Connect(function()
                if ctx.PerfOverlayLabel then
                    ctx.PerfOverlayLabel.Position = UDim2.new(1,-210,0,10)
                end
            end)

            -- Noclip
            local noclipConn
            UI.toggle(section,"TOGGLE_NOCLIP","extra_noclip",false,function(on)
                if on then
                    noclipConn = RunService.Stepped:Connect(function()
                        local char=LocalPlayer.Character
                        if char then
                            for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                end
                            end
                        end
                    end)
                else
                    if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
                end
            end)

            -- Posições
            local posSection = UI.section(tabExtras,"SECTION_POSITIONS")
            local savedPositions = Persist.get("saved_positions", {})
            local function savePositions() Persist.set("saved_positions", savedPositions) end
            local coordsLabel = UI.label(posSection, L("LABEL_POS_ATUAL")..": ...", false)

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
            listFrame.Parent = posSection
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
                    btn.BackgroundColor3 = Color3.fromRGB(45,45,55)
                    btn.TextColor3 = Color3.new(1,1,1)
                    btn.Font = Enum.Font.Gotham
                    btn.TextSize = 13
                    btn.Text = i..": ("..math.floor(data.x)..","..math.floor(data.y)..","..math.floor(data.z)..")  [TP]"
                    btn.Parent = listFrame
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
                    btn.MouseButton1Click:Connect(function()
                        local root = Util.getRoot()
                        if root then root.CFrame = CFrame.new(data.x,data.y,data.z) end
                    end)
                    btn.MouseButton2Click:Connect(function()
                        table.remove(savedPositions, i)
                        savePositions()
                        rebuildPosList()
                    end)
                end
            end
            rebuildPosList()

            local addBtn = Instance.new("TextButton")
            addBtn.Size = UDim2.new(1,0,0,26)
            addBtn.BackgroundColor3 = Color3.fromRGB(50,90,60)
            addBtn.TextColor3 = Color3.new(1,1,1)
            addBtn.Font = Enum.Font.GothamBold
            addBtn.TextSize = 14
            addBtn.Text = L("BTN_SAVE_POS")
            mark(addBtn,"BTN_SAVE_POS")
            addBtn.Parent = posSection
            Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0,6)
            addBtn.MouseButton1Click:Connect(function()
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

            local clearBtn = Instance.new("TextButton")
            clearBtn.Size = UDim2.new(1,0,0,26)
            clearBtn.BackgroundColor3 = Color3.fromRGB(90,50,50)
            clearBtn.TextColor3 = Color3.new(1,1,1)
            clearBtn.Font = Enum.Font.GothamBold
            clearBtn.TextSize = 14
            clearBtn.Text = L("BTN_CLEAR_POS")
            mark(clearBtn,"BTN_CLEAR_POS")
            clearBtn.Parent = posSection
            Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0,6)
            clearBtn.MouseButton1Click:Connect(function()
                savedPositions = {}
                savePositions()
                rebuildPosList()
            end)

            if typeof(setclipboard) == "function" then
                local copyBtn = Instance.new("TextButton")
                copyBtn.Size = UDim2.new(1,0,0,26)
                copyBtn.BackgroundColor3 = Color3.fromRGB(50,50,80)
                copyBtn.TextColor3 = Color3.new(1,1,1)
                copyBtn.Font = Enum.Font.GothamBold
                copyBtn.TextSize = 14
                copyBtn.Text = L("BTN_COPY_POS")
                mark(copyBtn,"BTN_COPY_POS")
                copyBtn.Parent = posSection
                Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0,6)
                copyBtn.MouseButton1Click:Connect(function()
                    local root = Util.getRoot()
                    if root then
                        local p = root.Position
                        setclipboard(string.format("%.2f, %.2f, %.2f", p.X,p.Y,p.Z))
                        notify("Pos", L("NOTIFY_POS_COPIED"))
                    end
                end)
            end

            -- Ambiente
            local timeSection = UI.section(tabExtras,"SECTION_AMBIENCE")
            local applyLighting = false
            local desiredTime = Persist.get("world_time_value", Lighting.ClockTime)
            UI.slider(timeSection,"SLIDER_WORLD_TIME","world_time_value",0,24,desiredTime,0.25,function(v)
                desiredTime = v
                if applyLighting then Lighting.ClockTime = desiredTime end
            end)
            UI.toggle(timeSection,"TOGGLE_WORLD_TIME","world_time_apply",false,function(on)
                applyLighting = on
                if on then Lighting.ClockTime = desiredTime end
            end)
        end
    })

    -- Inicializar e finalizar UI
    Core.initPlugins()
    UI.restoreLastTab()
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