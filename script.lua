--[[
Universal Client Utility (Advanced UI) v0.2.0
Autor: (Eduardo854832)
Descrição: Utilidades client-side (PC + Mobile) com UI avançada (tabs, minimizar, persistência opcional).
Foco: Performance overlay, ajustes de movimento/câmera, exibição de leaderstats, ajustes de FOV, etc.
Não inclui: Ações sobre outros jogadores ou exploração de remotos.

Aviso: Uso em executores pode violar ToS. Utilize para estudo e em experiências privadas.

Compatibilidade: Exige suporte básico a game:HttpGet e instâncias GUI. Persistência só se writefile/readfile disponíveis.
]]

local VERSION = "0.2.0"

-- ==== Serviços ====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ==== Segurança / Helpers ====
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

-- ==== Persistência (opcional) ====
local Persist = {}
Persist._fileName = "UniversalUtilityConfig.json"
Persist._data = {}

local hasFS = (typeof(isfile) == "function" and typeof(readfile) == "function" and typeof(writefile) == "function")

local HttpService = game:GetService("HttpService")

function Persist.load()
    if hasFS and isfile(Persist._fileName) then
        safe(function()
            local raw = readfile(Persist._fileName)
            Persist._data = HttpService:JSONDecode(raw)
        end)
    end
end

function Persist.save()
    if not hasFS then return end
    safe(function()
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

-- ==== Utilidades ====
local Util = {}

function Util.getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Humanoid") then return c end
    end
    return nil
end

function Util.round(n, dec)
    dec = dec or 0
    local m = 10^(dec)
    return math.floor(n*m + 0.5)/m
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

-- ==== Core EventBus / Plugin Manager ====
local Core = {}
Core._events = {}
Core._plugins = {}
Core.Context = {
    version = VERSION,
    isMobile = isMobile,
    started = os.clock()
}

function Core.on(ev, fn)
    Core._events[ev] = Core._events[ev] or {}
    table.insert(Core._events[ev], fn)
end

function Core.emit(ev, ...)
    local list = Core._events[ev]
    if list then
        for _, fn in ipairs(list) do safe(fn, ...) end
    end
end

function Core.register(plugin)
    if type(plugin) == "table" and plugin.name and plugin.init then
        table.insert(Core._plugins, plugin)
    end
end

function Core.initPlugins()
    for _, p in ipairs(Core._plugins) do
        local ok, err = pcall(function() p.init(Core.Context) end)
        if not ok then
            warn("[PluginError]", p.name, err)
        else
            if p.postInit then safe(p.postInit, Core.Context) end
        end
    end
end

-- ==== UI Builder Avançado ====
local UI = {}
UI._tabs = {}
UI._activeTab = nil

function UI.createRoot()
    local screen = Instance.new("ScreenGui")
    screen.Name = "UniversalUtilityAdvanced"
    screen.ResetOnSpawn = false
    pcall(function()
        screen.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end)

    -- Botão flutuante (para reabrir janela se fechada)
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

    -- Janela principal
    local window = Instance.new("Frame")
    window.Name = "MainWindow"
    window.Size = UDim2.new(0, 520, 0, 430)
    window.Position = UDim2.new(0, 80, 0.5, -215)
    window.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    window.BorderSizePixel = 0
    window.Parent = screen

    local corner = Instance.new("UICorner", window); corner.CornerRadius = UDim.new(0,10)

    -- Header
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
    title.Size = UDim2.new(1, -150, 1, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = "Universal Utility v"..VERSION
    title.TextColor3 = Color3.fromRGB(230,230,240)
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    -- Botão Minimizar
    local minimize = Instance.new("TextButton")
    minimize.Text = "-"
    minimize.Size = UDim2.new(0, 40, 0, 36)
    minimize.Position = UDim2.new(1, -92, 0, 4)
    minimize.BackgroundTransparency = 1
    minimize.TextColor3 = Color3.fromRGB(200,200,200)
    minimize.Font = Enum.Font.GothamBold
    minimize.TextSize = 24
    minimize.Parent = header

    -- Botão Fechar (esconde janela; reabre via flutuante)
    local close = Instance.new("TextButton")
    close.Text = "×"
    close.Size = UDim2.new(0, 40, 0, 36)
    close.Position = UDim2.new(1, -48, 0, 4)
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.fromRGB(200,80,80)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 24
    close.Parent = header

    -- Área de Tabs lateral
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(0, 130, 1, -44)
    tabBar.Position = UDim2.new(0, 0, 0, 44)
    tabBar.BackgroundColor3 = Color3.fromRGB(24,24,32)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = window

    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)

    -- Área de conteúdo
    local content = Instance.new("Frame")
    content.Name = "ContentArea"
    content.Size = UDim2.new(1, -130, 1, -44)
    content.Position = UDim2.new(0, 130, 0, 44)
    content.BackgroundColor3 = Color3.fromRGB(16,16,22)
    content.BorderSizePixel = 0
    content.Parent = window

    Util.draggable(window, header)

    -- Minimização animada
    local minimized = false
    local savedSize = window.Size

    local function setMinimized(state)
        if state == minimized then return end
        minimized = state
        if minimized then
            TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(savedSize.X.Scale, savedSize.X.Offset, 0, 60)
            }):Play()
            for _, v in ipairs(window:GetChildren()) do
                if v ~= header then
                    v.Visible = false
                end
            end
            minimize.Text = "+"
        else
            TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = savedSize
            }):Play()
            task.delay(0.32, function()
                if not minimized then
                    for _, v in ipairs(window:GetChildren()) do
                        if v ~= header then
                            v.Visible = true
                        end
                    end
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

    floatBtn.MouseButton1Click:Connect(function()
        window.Visible = not window.Visible
    end)

    -- Estado inicial de minimização
    setMinimized(Persist.get("ui_minimized", false))

    UI.Screen = screen
    UI.Window = window
    UI.TabBar = tabBar
    UI.ContentArea = content
    UI.Minimize = setMinimized
    UI.FloatingButton = floatBtn
end

function UI.createTab(name, iconOptional)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = "Tab_"..name
    tabBtn.Size = UDim2.new(1, 0, 0, 36)
    tabBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
    tabBtn.Text = (iconOptional and (iconOptional.." ") or "")..name
    tabBtn.TextColor3 = Color3.fromRGB(220,220,230)
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 14
    tabBtn.AutoButtonColor = true
    tabBtn.Parent = UI.TabBar

    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Name = "Content_"..name
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
        local total = 0
        for _, c in ipairs(tabContent:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextLabel") or c:IsA("TextButton") then
                total = total + c.AbsoluteSize.Y + 8
            end
        end
        tabContent.CanvasSize = UDim2.new(0,0,0, total + 20)
    end
    layout.Changed:Connect(function(p)
        if p == "AbsoluteContentSize" then recalc() end
    end)
    tabContent.ChildAdded:Connect(function()
        task.wait(0.05)
        recalc()
    end)

    UI._tabs[name] = {button = tabBtn, frame = tabContent}

    tabBtn.MouseButton1Click:Connect(function()
        UI.selectTab(name)
    end)

    if not UI._activeTab then
        UI.selectTab(name)
    end

    return tabContent
end

function UI.selectTab(name)
    for tabName, data in pairs(UI._tabs) do
        local active = (tabName == name)
        data.frame.Visible = active
        TweenService:Create(data.button, TweenInfo.new(0.2), {
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

-- Componentes UI (Sections, Toggle, Slider, Label)
function UI.section(parent, titleText)
    local frame = Instance.new("Frame")
    frame.Name = "Section_"..titleText
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
    title.Text = titleText
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

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

function UI.toggle(parent, label, key, default, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 32)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 42, 0, 26)
    btn.Position = UDim2.new(0, 0, 0, 3)
    btn.BackgroundColor3 = Color3.fromRGB(90,90,90)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = holder

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 50, 0, 0)
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(230,230,230)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = holder

    local state = Persist.get(key, default)
    local function apply()
        btn.Text = state and "ON" or "OFF"
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(40,140,70) or Color3.fromRGB(90,90,90)
        }):Play()
        safe(callback, state)
        Persist.set(key, state)
    end
    btn.MouseButton1Click:Connect(function()
        state = not state
        apply()
    end)
    apply()
end

function UI.slider(parent, label, key, minVal, maxVal, defaultVal, step, callback)
    step = step or 1
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 56)
    holder.BackgroundTransparency = 1
    holder.Parent = parent

    local valStored = Persist.get(key, defaultVal)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. tostring(valStored)
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

    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        local raw = minVal + (maxVal-minVal)*rel
        local snapped = minVal + math.floor((raw - minVal)/step + 0.5)*step
        snapped = math.clamp(snapped, minVal, maxVal)
        fill.Size = UDim2.new((snapped - minVal)/(maxVal-minVal), 0, 1, 0)
        lbl.Text = label .. ": " .. tostring(snapped)
        Persist.set(key, snapped)
        safe(callback, snapped)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            setFromX(input.Position.X)
        end
    end)
    bar.InputChanged:Connect(function(input)
        if input.UserInputState == Enum.UserInputState.Change and
           (input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch) and
            UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            setFromX(input.Position.X)
        end
    end)

    -- Chamar callback com valor inicial
    safe(callback, valStored)
end

function UI.label(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200,200,220)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

-- ==== Criar UI base ====
UI.createRoot()

-- ==== Tabs definidas ====
local tabGeneral = UI.createTab("Geral", "🏠")
local tabMove    = UI.createTab("Movimento", "🏃")
local tabCamera  = UI.createTab("Câmera", "🎥")
local tabStats   = UI.createTab("Stats", "📊")

-- ==== Plugins ====

-- Performance Overlay (sempre on; sem config)
Core.register({
    name = "PerformanceOverlay",
    init = function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "PerfOverlay"
        sg.ResetOnSpawn = false
        pcall(function()
            sg.Parent = (gethui and gethui()) or game:GetService("CoreGui")
        end)

        local box = Instance.new("TextLabel")
        box.Size = UDim2.new(0, 180, 0, 76)
        box.Position = UDim2.new(1, -190, 0, 10)
        box.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
        box.TextColor3 = Color3.fromRGB(190, 255, 200)
        box.Font = Enum.Font.Code
        box.TextSize = 13
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.TextYAlignment = Enum.TextYAlignment.Top
        box.Text = "Carregando..."
        box.Parent = sg
        Util.draggable(box, box)

        local frames, last = 0, tick()
        RunService.RenderStepped:Connect(function()
            frames += 1
            local now = tick()
            if now - last >= 1 then
                local fps = frames / (now - last)
                frames = 0
                last = now
                local mem = gcinfo()
                local ping = Stats.Network.ServerStatsItem["Data Ping"] and Stats.Network.ServerStatsItem["Data Ping"]:GetValue() or -1
                box.Text = string.format("FPS: %%d\nMem: %%d KB\nPing: %%d ms\nPlayers: %%d",
                    fps, mem, ping, #Players:GetPlayers())
            end
        end)
    end
})

-- Geral: Infos e Leaderstats
Core.register({
    name = "GeralTab",
    init = function()
        local secInfo = UI.section(tabGeneral, "Informações")
        UI.label(secInfo, "Versão: "..VERSION)
        UI.label(secInfo, "Executor FS: "..tostring(hasFS))
        UI.label(secInfo, "Dispositivo: "..(isMobile and "Mobile" or "PC"))

        local secLeader = UI.section(tabGeneral, "Leaderstats")
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
                UI.label(container, "Nenhum leaderstats detectado.")
                return
            end
            for _, v in ipairs(ls:GetChildren()) do
                if v:IsA("ValueBase") then
                    local lbl = UI.label(container, v.Name..": "..tostring(v.Value))
                    v:GetPropertyChangedSignal("Value"):Connect(function()
                        lbl.Text = v.Name..": "..tostring(v.Value)
                    end)
                end
            end
        end
        rebuild()
        LocalPlayer.ChildAdded:Connect(function(ch)
            if ch.Name == "leaderstats" then
                task.delay(0.3, rebuild)
            end
        end)
    end
})

-- Movimento: WalkSpeed, Jump, Toggle AutoReapply
Core.register({
    name = "MovimentoTab",
    init = function()
        local section = UI.section(tabMove, "Ajustes de Humanoid")
        local hum = Util.getHumanoid()
        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            hum = Util.getHumanoid()
        end)

        UI.slider(section, "WalkSpeed", "walkspeed_value", 4, 64, hum and hum.WalkSpeed or 16, 1, function(v)
            hum = Util.getHumanoid()
            if hum then hum.WalkSpeed = v end
        end)

        UI.slider(section, "JumpPower", "jumppower_value", 25, 150, hum and hum.JumpPower or 50, 1, function(v)
            hum = Util.getHumanoid()
            if hum and hum.UseJumpPower ~= false then
                hum.JumpPower = v
            end
        end)

        UI.toggle(section, "Reaplicar valores em respawn", "auto_reapply_stats", true, function(on)
            if on then
                -- Conecta uma única vez (idempotente)
                if not Core._autoApplyConnection then
                    Core._autoApplyConnection = LocalPlayer.CharacterAdded:Connect(function()
                        task.wait(0.3)
                        local h = Util.getHumanoid()
                        if h then
                            local ws = Persist.get("walkspeed_value", 16)
                            local jp = Persist.get("jumppower_value", 50)
                            safe(function()
                                h.WalkSpeed = ws
                                if h.UseJumpPower ~= false then
                                    h.JumpPower = jp
                                end
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

-- Câmera: FOV, Shift-Lock-like, Suavização
Core.register({
    name = "CameraTab",
    init = function()
        local section = UI.section(tabCamera, "Ajustes de Câmera")
        UI.slider(section, "FOV", "camera_fov", 40, 120, workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70, 1, function(v)
            if workspace.CurrentCamera then
                workspace.CurrentCamera.FieldOfView = v
            end
        end)

        local state = {
            shiftLock = Persist.get("camera_shiftlock", false),
            smooth = Persist.get("camera_smooth", false),
        }

        UI.toggle(section, "Simular Shift-Lock (PC)", "camera_shiftlock", state.shiftLock, function(on)
            state.shiftLock = on
        end)

        UI.toggle(section, "Câmera Suave", "camera_smooth", state.smooth, function(on)
            state.smooth = on
        end)

        local lastCF
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
                if lastCF then
                    cam.CFrame = lastCF:Lerp(cam.CFrame, 0.25)
                end
                lastCF = cam.CFrame
            else
                lastCF = nil
            end
        end)
    end
})

-- Stats extra (exibe métricas e contadores)
Core.register({
    name = "StatsTab",
    init = function()
        local section = UI.section(tabStats, "Monitor")
        local fpsLabel = UI.label(section, "FPS: ...")
        local memLabel = UI.label(section, "Mem: ... KB")
        local pingLabel = UI.label(section, "Ping: ... ms")
        local playerCount = UI.label(section, "Players: ...")

        local frames, last = 0, tick()
        RunService.RenderStepped:Connect(function()
            frames += 1
            local now = tick()
            if now - last >= 1 then
                local fps = math.floor(frames/(now-last))
                frames = 0
                last = now
                local mem = gcinfo()
                local ping = Stats.Network.ServerStatsItem["Data Ping"] and Stats.Network.ServerStatsItem["Data Ping"]:GetValue() or -1
                fpsLabel.Text = "FPS: "..fps
                memLabel.Text = "Mem: "..mem.." KB"
                pingLabel.Text = "Ping: "..ping.." ms"
                playerCount.Text = "Players: "..#Players:GetPlayers()
            end
        end)
    end
})

-- Touch Helpers (Mobile)
Core.register({
    name = "TouchHelpers",
    init = function(ctx)
        if not ctx.isMobile then return end
        local sec = UI.section(tabGeneral, "Atalhos Mobile")

        local btnHolder = Instance.new("Frame")
        btnHolder.Size = UDim2.new(1,0,0,40)
        btnHolder.BackgroundTransparency = 1
        btnHolder.Parent = sec
        local layout = Instance.new("UIListLayout", btnHolder)
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0,8)

        local function quickButton(text, callback)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 110, 0, 34)
            b.BackgroundColor3 = Color3.fromRGB(40,40,50)
            b.TextColor3 = Color3.new(1,1,1)
            b.Font = Enum.Font.GothamBold
            b.TextSize = 12
            b.Text = text
            b.Parent = btnHolder
            b.MouseButton1Click:Connect(function()
                safe(callback)
            end)
            local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(0,6)
        end

        quickButton("Respawn", function()
            local hum = Util.getHumanoid()
            if hum then hum.Health = 0 end
        end)

        quickButton("Reset FOV", function()
            local cam = workspace.CurrentCamera
            if cam then
                cam.FieldOfView = 70
                Persist.set("camera_fov", 70)
                notify("Câmera","FOV redefinido para 70")
            end
        end)

        quickButton("Info", function()
            notify("Info", "Use as tabs para ajustes.")
        end)
    end
})

-- ==== Inicializar plugins e restaurar tab ====
Core.initPlugins()
UI.restoreLastTab()

notify("Universal Utility", "Carregado v"..VERSION, 4)

return {
    Core = Core,
    UI = UI,
    Util = Util,
    Persist = Persist
}
