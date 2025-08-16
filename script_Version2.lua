--[[
Universal Client Utility (Advanced UI) v0.4.0
Autor: (Eduardo854832)
Novidades 0.4.0 (Internacionalização):
 - Tela inicial perguntando: Português ou English (persistido em lang)
 - Função de tradução L(key, ...) + dicionário pt/en (sem dependência externa)
 - Possibilidade de mudar idioma dentro da aba Geral (recria legendas dinâmicas)
 - Todas as strings principais migradas para chaves de tradução
 - Mantidas melhorias de 0.3.0 (Extras, Overlay, Fly, Noclip, etc.)
Observação: traduções localizadas, sem machine translation em tempo real.

Uso educacional; não usar para violar ToS.
]]

local VERSION = "0.4.0"

-- ==== Serviços ====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ==== Persistência ====
local Persist = {}
Persist._fileName = "UniversalUtilityConfig.json"
Persist._data = {}
local hasFS = (typeof(isfile) == "function" and typeof(readfile) == "function" and typeof(writefile) == "function")

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
        BTN_RESPAWN = "Respawn",
        BTN_RESET_FOV = "Reset FOV",
        BTN_INFO = "Info",
        BTN_OVERLAY_RESET = "Reset Posição Overlay",
        BTN_SAVE_POS = "Salvar Posição (máx 5)",
        BTN_CLEAR_POS = "Limpar Todas",
        BTN_COPY_POS = "Copiar Pos Atual",
        BTN_SHOW_HIDE = "[F4] Mostrar/Ocultar",
        TOGGLE_REAPPLY = "Reaplicar em respawn",
        TOGGLE_SHIFTLOCK = "Simular Shift-Lock (PC)",
        TOGGLE_SMOOTH = "Câmera Suave",
        TOGGLE_OVERLAY = "Mostrar Performance Overlay",
        TOGGLE_NOCLIP = "Noclip",
        TOGGLE_FLY = "Fly (WASD, Shift acelera)",
        TOGGLE_WORLD_TIME = "Aplicar Hora Custom",
        SLIDER_WALKSPEED = "WalkSpeed",
        SLIDER_JUMPPOWER = "JumpPower",
        SLIDER_FOV = "FOV",
        SLIDER_CAM_SENS = "Sensibilidade",
        SLIDER_FLY_SPEED = "Fly Veloc",
        SLIDER_WORLD_TIME = "Hora (ClockTime)",
        NOTIFY_INFO = "Use as tabs para ajustes.",
        NOTIFY_FOV_RESET = "FOV redefinido para 70",
        NOTIFY_POS_LIMIT = "Limite de 5 atingido (remova alguma com botão direito).",
        NOTIFY_NO_ROOT = "Sem HumanoidRootPart.",
        NOTIFY_POS_COPIED = "Coordenadas copiadas.",
        NOTIFY_POS_SAVED = "Posição salva.",
        NOTIFY_LOADED = "Carregado v%s",
        NOTIFY_SELECT_LANGUAGE = "Selecione um idioma",
        LANG_PT = "Português",
        LANG_EN = "English",
        LANG_CHANGED = "Idioma alterado (recarregado).",
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
        BTN_RESPAWN = "Respawn",
        BTN_RESET_FOV = "Reset FOV",
        BTN_INFO = "Info",
        BTN_OVERLAY_RESET = "Reset Overlay Position",
        BTN_SAVE_POS = "Save Position (max 5)",
        BTN_CLEAR_POS = "Clear All",
        BTN_COPY_POS = "Copy Current Pos",
        BTN_SHOW_HIDE = "[F4] Show/Hide",
        TOGGLE_REAPPLY = "Reapply on respawn",
        TOGGLE_SHIFTLOCK = "Simulate Shift-Lock (PC)",
        TOGGLE_SMOOTH = "Smooth Camera",
        TOGGLE_OVERLAY = "Show Performance Overlay",
        TOGGLE_NOCLIP = "Noclip",
        TOGGLE_FLY = "Fly (WASD, Shift accelerates)",
        TOGGLE_WORLD_TIME = "Apply Custom Time",
        SLIDER_WALKSPEED = "WalkSpeed",
        SLIDER_JUMPPOWER = "JumpPower",
        SLIDER_FOV = "FOV",
        SLIDER_CAM_SENS = "Sensitivity",
        SLIDER_FLY_SPEED = "Fly Speed",
        SLIDER_WORLD_TIME = "Time (ClockTime)",
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

-- Tela inicial de seleção de idioma (se não definido)
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
    local c = Instance.new("UICorner", frame); c.CornerRadius = UDim.new(0,10)

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
    local c1 = Instance.new("UICorner", btnPT); c1.CornerRadius = UDim.new(0,8)

    local btnEN = Instance.new("TextButton")
    btnEN.Size = UDim2.new(0.5, -15, 0, 50)
    btnEN.Position = UDim2.new(0.5,5,0,70)
    btnEN.BackgroundColor3 = Color3.fromRGB(55,55,105)
    btnEN.Font = Enum.Font.GothamBold
    btnEN.TextSize = 16
    btnEN.TextColor3 = Color3.new(1,1,1)
    btnEN.Text = "English"
    btnEN.Parent = frame
    local c2 = Instance.new("UICorner", btnEN); c2.CornerRadius = UDim.new(0,8)

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
function Util.isGuiObject(inst)
    return inst and inst:IsA("GuiObject")
end
function Util.draggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging = false
    local dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    dragHandle.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function(chg)
                if chg == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragHandle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

-- ==== Core (Plugins) ====
local Core = {}
Core._events = {}
Core._plugins = {}
Core.Context = {
    version = VERSION,
    isMobile = isMobile,
    started = os.clock()
}
function Core.register(plugin)
    if type(plugin) == "table" and plugin.name and plugin.init then
        table.insert(Core._plugins, plugin)
    end
end
function Core.initPlugins()
    for _, p in ipairs(Core._plugins) do
        local ok, err = pcall(function() p.init(Core.Context) end)
        if not ok then warn("[PluginError]", p.name, err) end
    end
end

-- ==== UI Builder ====
local UI = {}
UI._tabs = {}
UI._activeTab = nil
UI._translatables = {} -- lista de {instance=..., key=..., fmtArgs={}} para atualização

local function mark(instance, key, ...)
    table.insert(UI._translatables, {instance=instance, key=key, args={...}})
end

function UI.applyLanguage()
    for _, data in ipairs(UI._translatables) do
        if data.instance and data.instance.Parent then
            data.instance.Text = L(data.key, unpack(data.args))
        end
    end
    -- Atualizar título janela
    if UI.TitleLabel then
        UI.TitleLabel.Text = L("UI_TITLE", VERSION)
    end
    -- Atualizar botão show/hide label
    if UI.KeybindLabel then
        UI.KeybindLabel.Text = L("BTN_SHOW_HIDE")
    end
    -- Atualizar texto das tabs (botões)
    local mapping = {
        Geral = "TAB_GENERAL",
        Movimento = "TAB_MOVEMENT",
        ["Câmera"] = "TAB_CAMERA",
        Stats = "TAB_STATS",
        Extras = "TAB_EXTRAS",
        ["General"] = "TAB_GENERAL",
        ["Movement"] = "TAB_MOVEMENT",
        ["Camera"] = "TAB_CAMERA"
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
    window.Size = UDim2.new(0, 540, 0, 450)
    window.Position = UDim2.new(0, 80, 0.5, -225)
    window.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    window.BorderSizePixel = 0
    window.Parent = screen
    local corner = Instance.new("UICorner", window); corner.CornerRadius = UDim.new(0,10)

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Color3.fromRGB(28,28,36)
    header.BorderSizePixel = 0
    header.Parent = window
    local hCorner = Instance.new("UICorner", header); hCorner.CornerRadius = UDim.new(0,10)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 12, 0, 0)
    title.Size = UDim2.new(1, -180, 1, 0)
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
    tabBar.Size = UDim2.new(0, 140, 1, -44)
    tabBar.Position = UDim2.new(0, 0, 0, 44)
    tabBar.BackgroundColor3 = Color3.fromRGB(24,24,32)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = window
    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)

    local content = Instance.new("Frame")
    content.Name = "ContentArea"
    content.Size = UDim2.new(1, -140, 1, -44)
    content.Position = UDim2.new(0, 140, 0, 44)
    content.BackgroundColor3 = Color3.fromRGB(16,16,22)
    content.BorderSizePixel = 0
    content.Parent = window

    Util.draggable(window, header)

    local minimized = false
    local savedSize = window.Size
    local minimizableChildren = {}
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
            TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(savedSize.X.Scale, savedSize.X.Offset, 0, 60)
            }):Play()
            for _, v in ipairs(minimizableChildren) do v.Visible = false end
            minimize.Text = "+"
        else
            TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = savedSize
            }):Play()
            task.delay(0.32, function()
                if not minimized then
                    for _, v in ipairs(minimizableChildren) do v.Visible = true end
                end
            end)
            minimize.Text = "-"
        end
        Persist.set("ui_minimized", minimized)
    end

    minimize.MouseButton1Click:Connect(function()
        setMinimized(not minimized)
    end)
    close.MouseButton1Click:Connect(function()
        window.Visible = false
    end)
    UserInputService.InputBegan:Connect(function(input, gp)
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
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 36)
    tabBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    tabBtn.TextColor3 = Color3.fromRGB(220,220,230)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 14
    tabBtn.AutoButtonColor = true
    local labelKey = keyMap[rawName] or rawName
    local translated = Lang.data[Lang.current][labelKey] or rawName
    tabBtn.Text = (icon and (icon.." ") or "") .. translated
    tabBtn.Parent = UI.TabBar

    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Name = "Content_"..rawName
    tabContent.Size = UDim2.new(1, -20, 1, -20)
    tabContent.Position = UDim2.new(0, 10, 0, 10)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.CanvasSize = UDim2.new(0,0,0,0)
    tabContent.ScrollBarThickness = 6
    tabContent.Visible = false
    tabContent.Parent = UI.ContentArea

    local layout = Instance.new("UIListLayout", tabContent)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,8)
    local function recalc()
        local total=0
        for _, c in ipairs(tabContent:GetChildren()) do
            if c:IsA("GuiObject") and c.Visible then
                total = total + c.AbsoluteSize.Y + 8
            end
        end
        tabContent.CanvasSize = UDim2.new(0,0,0,total+20)
    end
    layout.Changed:Connect(function(p) if p=="AbsoluteContentSize" then recalc() end end)
    tabContent.ChildAdded:Connect(function() task.wait(0.05); recalc() end)

    UI._tabs[rawName] = {button=tabBtn, frame=tabContent, _rawName=rawName, _icon=icon or ""}

    tabBtn.MouseButton1Click:Connect(function()
        UI.selectTab(rawName)
    end)
    if not UI._activeTab then
        UI.selectTab(rawName)
    end
    return tabContent
end

function UI.selectTab(name)
    for tabName, data in pairs(UI._tabs) do
        local active = (tabName == name)
        data.frame.Visible = active
        TweenService:Create(data.button, TweenInfo.new(0.2),{
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

-- Componentes
function UI.section(parent, keyTitle)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundColor3 = Color3.fromRGB(26,26,34)
    frame.BorderSizePixel = 0
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Parent = parent
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)

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
    holder.Size = UDim2.new(1, 0, 0, 32)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 48, 0, 26)
    btn.Position = UDim2.new(0, 0, 0, 3)
    btn.BackgroundColor3 = Color3.fromRGB(90,90,90)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = holder

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
    holder.Size = UDim2.new(1, 0, 0, 58)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local valStored = Persist.get(key, defaultVal)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = L(labelKey) .. ": " .. tostring(valStored)
    lbl.TextColor3 = Color3.fromRGB(230,230,230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = holder

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -10, 0, 10)
    bar.Position = UDim2.new(0, 5, 0, 30)
    bar.BackgroundColor3 = Color3.fromRGB(55,55,65)
    bar.BorderSizePixel = 0
    bar.Parent = holder
    local barCorner = Instance.new("UICorner", bar); barCorner.CornerRadius = UDim.new(0,5)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((valStored - minVal)/(maxVal-minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80,150,240)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fillCorner = Instance.new("UICorner", fill); fillCorner.CornerRadius = UDim.new(0,5)

    local dragging = false
    local function applyValue(snapped, fire)
        fill.Size = UDim2.new((snapped - minVal)/(maxVal-minVal), 0, 1, 0)
        lbl.Text = L(labelKey)..": "..tostring(snapped)
        Persist.set(key, snapped)
        if fire then safe(callback, snapped) end
    end
    local function setFromX(x, fire)
        local rel = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        local raw = minVal + (maxVal-minVal)*rel
        local snapped = minVal + math.floor((raw - minVal)/step + 0.5)*step
        snapped = math.clamp(snapped, minVal, maxVal)
        applyValue(snapped, fire)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X, true)
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    bar.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X, true)
        end
    end)
    safe(callback, valStored)
    return function(newValue, fire)
        newValue = math.clamp(newValue, minVal, maxVal)
        applyValue(newValue, fire)
    end
end

function UI.label(parent, textKeyOrRaw, isKey)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
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

-- ==== Construção principal pós seleção de idioma ====
ensureLanguage(function()

    -- Criar UI base
    UI.createRoot()

    -- Tabs
    local tabGeneral = UI.createTab(Lang.current=="pt" and "Geral" or "General", "🏠")
    local tabMove    = UI.createTab(Lang.current=="pt" and "Movimento" or "Movement", "🏃")
    local tabCamera  = UI.createTab(Lang.current=="pt" and "Câmera" or "Camera", "🎥")
    local tabStats   = UI.createTab("Stats", "📊")
    local tabExtras  = UI.createTab("Extras", "⚙️")

    -- ========= Plugins =========

    -- Performance Overlay
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
            box.Size = UDim2.new(0, 190, 0, 80)
            box.Position = UDim2.new(1, -200, 0, 10)
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
            RunService.RenderStepped:Connect(function()
                frames+=1
                local now=tick()
                if now-last>=1 then
                    local fps=frames/(now-last)
                    frames=0; last=now
                    local mem=gcinfo()
                    local ping=Stats.Network.ServerStatsItem["Data Ping"] and Stats.Network.ServerStatsItem["Data Ping"]:GetValue() or -1
                    box.Text=string.format("%s: %d\n%s: %d KB\n%s: %d ms\n%s: %d",
                        L("LABEL_FPS"),fps,L("LABEL_MEM"),mem,L("LABEL_PING"),ping,L("LABEL_PLAYERS"),#Players:GetPlayers())
                end
            end)
            box.Visible = Persist.get("overlay_visible", true)
        end
    })

    -- Geral
    Core.register({
        name="GeneralTab",
        init=function()
            local secInfo = UI.section(tabGeneral,"SECTION_INFO")
            UI.label(secInfo, string.format("%s: %s", L("LABEL_VERSION"), VERSION), false)
            UI.label(secInfo, string.format("%s: %s", L("LABEL_FS"), tostring(hasFS)), false)
            UI.label(secInfo, string.format("%s: %s", L("LABEL_DEVICE"), (isMobile and "Mobile" or "PC")), false)
            UI.label(secInfo, string.format("%s: %s", L("LABEL_STARTED"), os.date("%H:%M:%S")), false)

            -- Mudança de idioma dentro da UI
            local langHolder = Instance.new("Frame")
            langHolder.Size = UDim2.new(1,0,0,32)
            langHolder.BackgroundTransparency = 1
            langHolder.Parent = secInfo

            local changeBtn = Instance.new("TextButton")
            changeBtn.Size = UDim2.new(0,160,0,26)
            changeBtn.Position = UDim2.new(0,0,0,3)
            changeBtn.BackgroundColor3 = Color3.fromRGB(60,60,90)
            changeBtn.TextColor3 = Color3.new(1,1,1)
            changeBtn.TextSize = 13
            changeBtn.Font = Enum.Font.GothamBold
            changeBtn.Text = L("LABEL_LANG_CHANGE")
            mark(changeBtn, "LABEL_LANG_CHANGE")
            changeBtn.Parent = langHolder
            local cc = Instance.new("UICorner", changeBtn); cc.CornerRadius = UDim.new(0,6)
            changeBtn.MouseButton1Click:Connect(function()
                if Lang.current == "pt" then
                    Lang.current = "en"
                else
                    Lang.current = "pt"
                end
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
                if not ls then
                    UI.label(container,"LABEL_NO_LS",true)
                    return
                end
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

    -- Movimento
    Core.register({
        name="MovementTab",
        init=function()
            local section = UI.section(tabMove,"SECTION_HUMANOID")
            local hum = Util.getHumanoid()
            LocalPlayer.CharacterAdded:Connect(function()
                task.wait(0.5)
                hum = Util.getHumanoid()
            end)
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
                    if not Core._autoApplyConnection then
                        Core._autoApplyConnection = LocalPlayer.CharacterAdded:Connect(function()
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
                    if Core._autoApplyConnection then
                        Core._autoApplyConnection:Disconnect()
                        Core._autoApplyConnection = nil
                    end
                end
            end)
        end
    })

    -- Câmera
    Core.register({
        name="CameraTab",
        init=function()
            local section = UI.section(tabCamera,"SECTION_CAMERA")
            local camSensitivityMultiplier = 1
            UI.slider(section,"SLIDER_FOV","camera_fov",40,120,workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70,1,function(v)
                if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = v end
            end)
            local state = {
                shiftLock = Persist.get("camera_shiftlock", false),
                smooth = Persist.get("camera_smooth", false)
            }
            UI.toggle(section,"TOGGLE_SHIFTLOCK","camera_shiftlock",state.shiftLock,function(on) state.shiftLock = on end)
            UI.toggle(section,"TOGGLE_SMOOTH","camera_smooth",state.smooth,function(on) state.smooth = on end)
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

    -- Stats
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

    -- Mobile helpers
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
                b.Size = UDim2.new(0,120,0,34)
                b.BackgroundColor3 = Color3.fromRGB(40,40,50)
                b.TextColor3 = Color3.new(1,1,1)
                b.Font = Enum.Font.GothamBold
                b.TextSize = 12
                b.Text = L(textKey)
                mark(b, textKey)
                b.Parent = btnHolder
                b.MouseButton1Click:Connect(function() safe(cb) end)
                local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(0,6)
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

    -- Extras
    Core.register({
        name="ExtrasTab",
        init=function(ctx)
            local section = UI.section(tabExtras,"SECTION_EXTRAS")
            UI.toggle(section,"TOGGLE_OVERLAY","overlay_visible",Persist.get("overlay_visible",true),function(on)
                if ctx.PerfOverlayLabel then ctx.PerfOverlayLabel.Visible = on end
                Persist.set("overlay_visible", on)
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
            local rc = Instance.new("UICorner", resetOverlay); rc.CornerRadius = UDim.new(0,6)
            resetOverlay.MouseButton1Click:Connect(function()
                if ctx.PerfOverlayLabel then
                    ctx.PerfOverlayLabel.Position = UDim2.new(1,-200,0,10)
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
                                if part:IsA("BasePart") and part.CanCollide then
                                    part.CanCollide = false
                                end
                            end
                        end
                    end)
                else
                    if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
                end
            end)

            -- Fly
            local flyConn
            local flyVelocity = Instance.new("BodyVelocity"); flyVelocity.MaxForce=Vector3.new()
            flyVelocity.P = 5000
            local flyGyro = Instance.new("BodyGyro"); flyGyro.MaxTorque=Vector3.new()
            flyGyro.P = 5000
            local flySpeed = Persist.get("fly_speed",60)
            UI.slider(section,"SLIDER_FLY_SPEED","fly_speed",10,200,flySpeed,5,function(v) flySpeed=v end)
            UI.toggle(section,"TOGGLE_FLY","extra_fly",false,function(on)
                if on then
                    local root=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not root then notify("Fly", L("NOTIFY_NO_ROOT")) return end
                    flyVelocity.Parent=root
                    flyGyro.Parent=root
                    flyVelocity.MaxForce=Vector3.new(1e5,1e5,1e5)
                    flyGyro.MaxTorque=Vector3.new(1e5,1e5,1e5)
                    flyConn = RunService.Heartbeat:Connect(function()
                        local cam=workspace.CurrentCamera
                        root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if not cam or not root then return end
                        local dir = Vector3.zero
                        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
                        if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir += Vector3.new(0,1,0) end
                        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir -= Vector3.new(0,1,0) end
                        if dir.Magnitude>0 then dir=dir.Unit end
                        local speed=flySpeed
                        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed*1.8 end
                        flyVelocity.Velocity = dir*speed
                        flyGyro.CFrame = cam.CFrame
                    end)
                else
                    if flyConn then flyConn:Disconnect(); flyConn=nil end
                    flyVelocity.MaxForce=Vector3.new()
                    flyGyro.MaxTorque=Vector3.new()
                    flyVelocity.Parent=nil
                    flyGyro.Parent=nil
                end
            end)

            -- Posições
            local posSection = UI.section(tabExtras,"SECTION_POSITIONS")
            local savedPositions = Persist.get("saved_positions", {})
            local function savePositions() Persist.set("saved_positions", savedPositions) end
            local coordsLabel = UI.label(posSection, L("LABEL_POS_ATUAL")..": ...", false)

            RunService.Heartbeat:Connect(function()
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
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
                    local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0,6)
                    btn.MouseButton1Click:Connect(function()
                        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
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
            local ac = Instance.new("UICorner", addBtn); ac.CornerRadius = UDim.new(0,6)
            addBtn.MouseButton1Click:Connect(function()
                if #savedPositions >= 5 then
                    notify("Pos", L("NOTIFY_POS_LIMIT"))
                    return
                end
                local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
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
            local cc2 = Instance.new("UICorner", clearBtn); cc2.CornerRadius = UDim.new(0,6)
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
                local ccc = Instance.new("UICorner", copyBtn); ccc.CornerRadius = UDim.new(0,6)
                copyBtn.MouseButton1Click:Connect(function()
                    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
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

    -- Inicializar plugins
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