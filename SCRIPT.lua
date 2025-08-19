--------------------------------------------------
-- Language System (Runtime selection overlay)
--------------------------------------------------
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local I18N = {
    pt = {
        hub_title = "Universal Hub",
        category_visual = "Visual",
        category_teleport = "Teleporte",
        category_status = "Status",
        section_movement = "Movimentação / Sistemas",
        toggle_flight = "Voar (Flight)",
        slider_flight_speed = "Velocidade de Voo",
        toggle_noclip = "Noclip",
        slider_walkspeed = "WalkSpeed",
        section_debug = "Debug / Visual",
        toggle_esp = "ESP Jogadores",
        btn_reset_char = "Resetar Personagem",
        btn_disable_all = "Desligar Todos (Flight/Noclip/ESP)",
        section_teleport = "Teleporte",
        textbox_part_name = "Nome do Part",
        textbox_part_placeholder = "Ex: SpawnLocation",
        btn_teleport_name = "Teleportar (Nome Digitado)",
        teleport_preset_prefix = "Teleport: ",
        preset_spawn = "Spawn",
        preset_center = "Centro",
        preset_shop = "Loja",
        section_status = "Status",
        status_format = "HP: {hp} / {mhp}\nWalkSpeed: {ws}\nFlight: {flight} | Noclip: {noclip} | ESP: {esp}\nPosição: {pos}",
        language_prompt_title = "Selecione o Idioma / Select Language",
        language_portuguese = "Português",
        language_english = "English",
        btn_close = "×",
        btn_minimize = "–",
    },
    en = {
        hub_title = "Universal Hub",
        category_visual = "Visual",
        category_teleport = "Teleport",
        category_status = "Status",
        section_movement = "Movement / Systems",
        toggle_flight = "Fly (Flight)",
        slider_flight_speed = "Flight Speed",
        toggle_noclip = "Noclip",
        slider_walkspeed = "WalkSpeed",
        section_debug = "Debug / Visual",
        toggle_esp = "Players ESP",
        btn_reset_char = "Reset Character",
        btn_disable_all = "Disable All (Flight/Noclip/ESP)",
        section_teleport = "Teleport",
        textbox_part_name = "Part Name",
        textbox_part_placeholder = "Ex: SpawnLocation",
        btn_teleport_name = "Teleport (Typed Name)",
        teleport_preset_prefix = "Teleport: ",
        preset_spawn = "Spawn",
        preset_center = "Center",
        preset_shop = "Shop",
        section_status = "Status",
        status_format = "HP: {hp} / {mhp}\nWalkSpeed: {ws}\nFlight: {flight} | Noclip: {noclip} | ESP: {esp}\nPosition: {pos}",
        language_prompt_title = "Selecione o Idioma / Select Language",
        language_portuguese = "Português",
        language_english = "English",
        btn_close = "×",
        btn_minimize = "–",
    }
}

local currentLang = "pt"

local function formatTemplate(str, map)
    return (str:gsub("{(.-)}", function(key)
        return map[key] ~= nil and tostring(map[key]) or "{"..key.."}"
    end))
end

local function T(key)
    return (I18N[currentLang] and I18N[currentLang][key])
        or (I18N.pt[key])
        or key
end

--------------------------------------------------
-- Theme
--------------------------------------------------
local THEME = {
    Background = Color3.fromRGB(24,24,24),
    BackgroundAlt = Color3.fromRGB(30,30,30),
    Accent = Color3.fromRGB(60,100,255),
    AccentHover = Color3.fromRGB(80,120,255),
    TextPrimary = Color3.fromRGB(235,235,235),
    TextSecondary = Color3.fromRGB(180,180,180),
    Section = Color3.fromRGB(40,40,40),
    ToggleOn = Color3.fromRGB(90,170,90),
    ToggleOff = Color3.fromRGB(80,80,80),
    Border = Color3.fromRGB(55,55,55),
    Danger = Color3.fromRGB(200,70,70),
    Warning = Color3.fromRGB(200,150,70),
}

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function create(class, props, children)
    local o = Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    for _,c in ipairs(children or {}) do c.Parent = o end
    return o
end

local function applyStroke(parent, color, thickness)
    create("UIStroke", {
        Color = color or THEME.Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }).Parent = parent
end

local function getCharacter()
    local c = LocalPlayer.Character
    if not c or not c.Parent then
        c = LocalPlayer.CharacterAdded:Wait()
    end
    return c
end
local function getHRP()
    local c = getCharacter()
    return c:FindFirstChild("HumanoidRootPart")
end
local function safeHumanoid()
    local c = getCharacter()
    return c:FindFirstChildWhichIsA("Humanoid")
end

--------------------------------------------------
-- Language Selection Overlay
--------------------------------------------------
local bootstrapGui = create("ScreenGui", {
    Name = "UniversalHubBootstrap",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Global
})
bootstrapGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local overlay = create("Frame", {
    Size = UDim2.new(1,0,1,0),
    BackgroundColor3 = Color3.fromRGB(0,0,0),
    BackgroundTransparency = 0.35,
})
overlay.Parent = bootstrapGui

local prompt = create("Frame", {
    Size = UDim2.fromOffset(420,220),
    Position = UDim2.new(0.5,-210,0.5,-110),
    BackgroundColor3 = THEME.Background,
    BorderSizePixel = 0,
}, { create("UICorner",{CornerRadius=UDim.new(0,10)}) })
prompt.Parent = overlay
applyStroke(prompt)

local promptTitle = create("TextLabel", {
    Text = T("language_prompt_title"),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = THEME.TextPrimary,
    BackgroundTransparency = 1,
    Size = UDim2.new(1,-20,0,50),
    Position = UDim2.fromOffset(10,10),
    TextWrapped = true
})
promptTitle.Parent = prompt

local buttonHolder = create("Frame", {
    Size = UDim2.new(1,-40,0,120),
    Position = UDim2.fromOffset(20,70),
    BackgroundTransparency = 1,
}, {
    create("UIListLayout",{FillDirection=Enum.FillDirection.Vertical, Padding=UDim.new(0,14), SortOrder=Enum.SortOrder.LayoutOrder})
})
buttonHolder.Parent = prompt

local function makeLangButton(text, langCode)
    local btn = create("TextButton", {
        Text = text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 18,
        TextColor3 = THEME.TextPrimary,
        BackgroundColor3 = THEME.Section,
        AutoButtonColor = false,
        Size = UDim2.new(1,0,0,44),
    }, { create("UICorner",{CornerRadius=UDim.new(0,8)}) })
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = THEME.BackgroundAlt
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = THEME.Section
    end)
    btn.MouseButton1Click:Connect(function()
        currentLang = langCode
        bootstrapGui:Destroy()
        task.defer(function()
            buildMainHub() -- call builder after language chosen
        end)
    end)
    btn.Parent = buttonHolder
end

makeLangButton(I18N.pt.language_portuguese, "pt")
makeLangButton(I18N.en.language_english, "en")

--------------------------------------------------
-- Forward declare builder so language overlay can call it
--------------------------------------------------
function buildMainHub() end

--------------------------------------------------
-- Systems State Tables
--------------------------------------------------
local Systems = {
    Flight = {
        Enabled=false,
        Speed=120,
        VerticalSpeed=100,
        Pressing={},
        Connection=nil,
        Keys={Forward="W",Back="S",Left="A",Right="D",Up="Space",Down="LeftShift"},
        Velocity = Vector3.zero, -- for smooth mode
        Smooth = true,           -- enable smoothing
        LerpAlpha = 0.15,
    },
    Noclip = {Enabled=false, Connection=nil},
    ESP = {Enabled=false, Objects={}, Connection=nil, Color=Color3.fromRGB(255,170,50), DistanceLimit=600, UseHighlight=true, PoolFree={}, PoolUsed={}},
    Connections = {}
}

local function addConn(c)
    if c then table.insert(Systems.Connections, c) end
end

local function disconnectAll()
    for _,c in ipairs(Systems.Connections) do
        pcall(function() c:Disconnect() end)
    end
    Systems.Connections = {}
end

--------------------------------------------------
-- ESP Pool Helpers (Highlight / BoxHandle)
--------------------------------------------------
local function getEspObject(adornee)
    -- Reuse
    local obj = table.remove(Systems.ESP.PoolFree)
    if not obj then
        if Systems.ESP.UseHighlight then
            obj = Instance.new("Highlight")
            obj.FillColor = Systems.ESP.Color
            obj.FillTransparency = 0.7
            obj.OutlineColor = Systems.ESP.Color
            obj.OutlineTransparency = 0
            obj.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        else
            obj = Instance.new("BoxHandleAdornment")
            obj.Size = Vector3.new(4,6,4)
            obj.AlwaysOnTop = true
            obj.ZIndex = 10
            obj.Color3 = Systems.ESP.Color
            obj.Transparency = 0.6
        end
    end
    if obj:IsA("Highlight") then
        obj.Adornee = adornee
        obj.Enabled = true
        obj.Parent = adornee
    else
        obj.Adornee = adornee
        obj.Parent = adornee
    end
    table.insert(Systems.ESP.PoolUsed, obj)
end

local function recycleEsp()
    for _,o in ipairs(Systems.ESP.PoolUsed) do
        if o:IsA("Highlight") then
            o.Enabled = false
            o.Parent = nil
        else
            o.Adornee = nil
            o.Parent = nil
        end
        table.insert(Systems.ESP.PoolFree, o)
    end
    Systems.ESP.PoolUsed = {}
end

--------------------------------------------------
-- Movement Input Tracking
--------------------------------------------------
addConn(UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for tag,keyName in pairs(Systems.Flight.Keys) do
            if Enum.KeyCode[keyName] and input.KeyCode == Enum.KeyCode[keyName] then
                Systems.Flight.Pressing[tag] = true
            end
        end
    end
end))

addConn(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for tag,keyName in pairs(Systems.Flight.Keys) do
            if Enum.KeyCode[keyName] and input.KeyCode == Enum.KeyCode[keyName] then
                Systems.Flight.Pressing[tag] = false
            end
        end
    end
end))

--------------------------------------------------
-- Systems Functions
--------------------------------------------------
function Systems.Flight:Enable()
    if self.Enabled then return end
    self.Enabled=true
    local hum = safeHumanoid()
    if hum then hum.PlatformStand=true end
    self.Connection = RunService.RenderStepped:Connect(function()
        local hrp=getHRP(); if not hrp then return end
        local cam=workspace.CurrentCamera
        local look=cam.CFrame.LookVector
        local move=Vector3.zero
        if self.Pressing.Forward then move+=Vector3.new(look.X,0,look.Z) end
        if self.Pressing.Back then move-=Vector3.new(look.X,0,look.Z) end
        if self.Pressing.Left then
            local r=cam.CFrame.RightVector
            move-=Vector3.new(r.X,0,r.Z)
        end
        if self.Pressing.Right then
            local r=cam.CFrame.RightVector
            move+=Vector3.new(r.X,0,r.Z)
        end
        if self.Pressing.Up then move+=Vector3.new(0,self.VerticalSpeed/self.Speed,0) end
        if self.Pressing.Down then move-=Vector3.new(0,self.VerticalSpeed/self.Speed,0) end
        if move.Magnitude>0 then move=move.Unit end

        local targetVel = move * self.Speed
        if self.Smooth then
            self.Velocity = self.Velocity:Lerp(targetVel, self.LerpAlpha)
            hrp.AssemblyLinearVelocity = self.Velocity
        else
            hrp.AssemblyLinearVelocity = targetVel
        end
    end)
    addConn(self.Connection)
end

function Systems.Flight:Disable()
    if not self.Enabled then return end
    self.Enabled=false
    if self.Connection then self.Connection:Disconnect() self.Connection=nil end
    self.Velocity = Vector3.zero
    local hum = safeHumanoid()
    if hum then hum.PlatformStand=false end
end

function Systems.Flight:SetSpeed(v) self.Speed = v end

function Systems.Noclip:Enable()
    if self.Enabled then return end
    self.Enabled=true
    self.Connection = RunService.Stepped:Connect(function()
        local char=LocalPlayer.Character
        if not char then return end
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end)
    addConn(self.Connection)
end
function Systems.Noclip:Disable()
    if not self.Enabled then return end
    self.Enabled=false
    if self.Connection then self.Connection:Disconnect(); self.Connection=nil end
end

function Systems.ESP:Enable()
    if self.Enabled then return end
    self.Enabled=true
    self.Connection = RunService.RenderStepped:Connect(function()
        recycleEsp()
        local myHRP = getHRP()
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local ch = plr.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                if hrp and myHRP and (hrp.Position - myHRP.Position).Magnitude <= self.DistanceLimit then
                    getEspObject(ch)
                end
            end
        end
    end)
    addConn(self.Connection)
end
function Systems.ESP:Disable()
    if not self.Enabled then return end
    self.Enabled=false
    if self.Connection then self.Connection:Disconnect(); self.Connection=nil end
    recycleEsp()
end

local function teleportTo(partName)
    local hrp = getHRP()
    if not hrp then return false end
    local found = workspace:FindFirstChild(partName, true)
    if found and found:IsA("BasePart") then
        hrp.CFrame = found.CFrame + Vector3.new(0,5,0)
        return true
    end
    return false
end

--------------------------------------------------
-- UI Component Factory
--------------------------------------------------
local Factory = {}

function Factory:SectionTitle(parent, text)
    local lbl = create("TextLabel",{
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = THEME.TextPrimary,
        BackgroundColor3 = THEME.BackgroundAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(1,0,0,40),
        TextXAlignment = Enum.TextXAlignment.Left
    },{ create("UIPadding",{PaddingLeft=UDim.new(0,14)}) })
    lbl.Parent = parent
    return lbl
end

function Factory:Toggle(parent, label, default, callback)
    local frame = create("Frame",{BackgroundColor3 = THEME.Section,Size = UDim2.new(1,0,0,50),BorderSizePixel = 0},{create("UICorner",{CornerRadius=UDim.new(0,6)})})
    applyStroke(frame); frame.Parent = parent
    create("TextLabel",{Text = label,Font = Enum.Font.GothamSemibold,TextSize = 15,TextColor3 = THEME.TextPrimary,BackgroundTransparency = 1,TextXAlignment = Enum.TextXAlignment.Left,Size = UDim2.new(1,-90,1,0),Position = UDim2.fromOffset(14,0)}).Parent = frame
    local btn = create("TextButton",{Text = "",BackgroundColor3 = default and THEME.ToggleOn or THEME.ToggleOff,AutoButtonColor = false,Size = UDim2.fromOffset(54,26),Position = UDim2.new(1,-70,0.5,-13)},{create("UICorner",{CornerRadius=UDim.new(1,0)})})
    btn.Parent = frame
    local knob = create("Frame",{Size = UDim2.fromOffset(22,22),Position = default and UDim2.fromOffset(28,2) or UDim2.fromOffset(4,2),BackgroundColor3 = Color3.new(1,1,1),BorderSizePixel = 0},{create("UICorner",{CornerRadius=UDim.new(1,0)})})
    knob.Parent = btn
    local state = default or false
    local function setState(new, fire)
        state = new
        TweenService:Create(btn,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff}):Play()
        TweenService:Create(knob,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position = state and UDim2.fromOffset(28,2) or UDim2.fromOffset(4,2)}):Play()
        if fire and callback then task.spawn(callback,state) end
    end
    btn.MouseButton1Click:Connect(function() setState(not state,true) end)
    return {Set=function(v) setState(v,true) end, Get=function() return state end}
end

function Factory:Slider(parent, label, minV, maxV, default, callback)
    minV = minV or 0; maxV = maxV or 100; default = math.clamp(default or minV, minV, maxV)
    local frame = create("Frame",{BackgroundColor3 = THEME.Section,Size = UDim2.new(1,0,0,70),BorderSizePixel = 0},{create("UICorner",{CornerRadius=UDim.new(0,6)})})
    applyStroke(frame); frame.Parent = parent
    create("TextLabel",{Text = label,Font = Enum.Font.GothamSemibold,TextSize = 15,TextColor3 = THEME.TextPrimary,BackgroundTransparency = 1,Size = UDim2.new(1,-20,0,20),Position = UDim2.fromOffset(14,4),TextXAlignment = Enum.TextXAlignment.Left}).Parent = frame
    local valueLbl = create("TextLabel",{Text = tostring(default),Font = Enum.Font.GothamBold,TextSize = 14,TextColor3 = THEME.TextSecondary,BackgroundTransparency = 1,Size = UDim2.new(0,60,0,20),Position = UDim2.new(1,-70,0,4),TextXAlignment = Enum.TextXAlignment.Right})
    valueLbl.Parent = frame
    local bar = create("Frame",{BackgroundColor3 = THEME.BackgroundAlt,Size = UDim2.new(1,-28,0,10),Position = UDim2.fromOffset(14,40),BorderSizePixel = 0},{create("UICorner",{CornerRadius=UDim.new(0,5)})})
    bar.Parent = frame
    local fill = create("Frame",{BackgroundColor3 = THEME.Accent,Size = UDim2.new((default-minV)/(maxV-minV),0,1,0),BorderSizePixel = 0},{create("UICorner",{CornerRadius=UDim.new(0,5)})})
    fill.Parent = bar
    local dragging=false
    local current=default
    local function update(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        local val = math.floor(minV + (maxV-minV)*rel + 0.5)
        current = val
        fill.Size = UDim2.new(rel,0,1,0)
        valueLbl.Text = tostring(val)
        if callback then callback(val) end
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true update(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end end)
    return {Get=function() return current end, Set=function(v)
        v=math.clamp(v,minV,maxV)
        local rel=(v-minV)/(maxV-minV)
        current=v
        fill.Size=UDim2.new(rel,0,1,0)
        valueLbl.Text=tostring(v)
        if callback then callback(v) end
    end}
end

function Factory:Button(parent, text, callback, variant)
    local frame = create("Frame",{BackgroundColor3 = THEME.Section,Size = UDim2.new(1,0,0,46),BorderSizePixel = 0},{create("UICorner",{CornerRadius=UDim.new(0,6)})})
    applyStroke(frame); frame.Parent = parent
    local btn = create("TextButton",{Text = text,Font = Enum.Font.GothamSemibold,TextSize = 15,TextColor3 = THEME.TextPrimary,AutoButtonColor = false,BackgroundColor3 = (variant=="danger" and THEME.Danger) or (variant=="warn" and THEME.Warning) or THEME.BackgroundAlt,Size = UDim2.new(0,220,0,34),Position = UDim2.new(1,-234,0.5,-17)},{create("UICorner",{CornerRadius=UDim.new(0,6)})})
    btn.Parent = frame
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = THEME.Accent end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = (variant=="danger" and THEME.Danger) or (variant=="warn" and THEME.Warning) or THEME.BackgroundAlt
    end)
    btn.MouseButton1Click:Connect(function() if callback then task.spawn(callback) end end)
    return btn
end

function Factory:TextBox(parent, label, placeholder, callback)
    local frame = create("Frame",{BackgroundColor3 = THEME.Section,Size = UDim2.new(1,0,0,50),BorderSizePixel = 0},{create("UICorner",{CornerRadius=UDim.new(0,6)})})
    applyStroke(frame); frame.Parent = parent
    create("TextLabel",{Text = label,Font = Enum.Font.GothamSemibold,TextSize = 15,BackgroundTransparency = 1,TextColor3 = THEME.TextPrimary,Size = UDim2.new(1,-250,1,0),Position = UDim2.fromOffset(14,0),TextXAlignment = Enum.TextXAlignment.Left}).Parent = frame
    local box = create("TextBox",{Text = "",PlaceholderText = placeholder or "",Font = Enum.Font.Gotham,TextSize = 15,TextColor3 = THEME.TextPrimary,BackgroundColor3 = THEME.BackgroundAlt,ClearTextOnFocus = false,Size = UDim2.new(0,220,0,34),Position = UDim2.new(1,-234,0.5,-17)},{create("UICorner",{CornerRadius=UDim.new(0,6)})})
    box.Parent = frame
    box.FocusLost:Connect(function(enter) if enter and callback then task.spawn(callback, box.Text) end end)
    return box
end

--------------------------------------------------
-- Main Hub Builder (depends on selected language)
--------------------------------------------------
function buildMainHub()
    local screenGui = create("ScreenGui", {
        Name = "UniversalHub",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    })
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local window = create("Frame", {
        Name = "Window",
        Size = UDim2.fromOffset(900, 480),
        Position = UDim2.new(0.5, -450, 0.5, -240),
        BackgroundColor3 = THEME.Background,
        BorderSizePixel = 0,
    }, { create("UICorner", {CornerRadius = UDim.new(0,8)}) })
    window.Parent = screenGui
    applyStroke(window)

    local topBar = create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1,0,0,42),
        BackgroundColor3 = THEME.BackgroundAlt,
        BorderSizePixel = 0,
    }, { create("UICorner",{CornerRadius = UDim.new(0,8)}) })
    topBar.Parent = window

    local title = create("TextLabel", {
        Text = T("hub_title"),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = THEME.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-140,1,0),
        Position = UDim2.fromOffset(16,0),
        TextXAlignment = Enum.TextXAlignment.Left
    })
    title.Parent = topBar

    local function topButton(name, txt)
        local b = create("TextButton", {
            Name = name,
            Text = txt,
            Font = Enum.Font.Gotham,
            TextSize = 18,
            TextColor3 = THEME.TextPrimary,
            AutoButtonColor = false,
            BackgroundColor3 = THEME.Background,
            Size = UDim2.fromOffset(38,30)
        },{ create("UICorner",{CornerRadius = UDim.new(0,6)}) })
        b.MouseEnter:Connect(function() b.BackgroundColor3 = THEME.BackgroundAlt end)
        b.MouseLeave:Connect(function() b.BackgroundColor3 = THEME.Background end)
        return b
    end

    local closeBtn = topButton("Close", T("btn_close"))
    closeBtn.Position = UDim2.new(1,-46,0.5,-15); closeBtn.Parent = topBar
    closeBtn.MouseButton1Click:Connect(function() screenGui.Enabled = false end)

    local miniBtn = topButton("Minimize", T("btn_minimize"))
    miniBtn.Position = UDim2.new(1,-92,0.5,-15); miniBtn.Parent = topBar

    local minimized=false
    miniBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        for _,c in ipairs(window:GetChildren()) do
            if c~=topBar then c.Visible = not minimized end
        end
        window.Size = minimized and UDim2.fromOffset(280,60) or UDim2.fromOffset(900,480)
    end)

    local dragging=false
    local dragStart, startPos
    topBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
            dragStart=i.Position
            startPos=window.Position
        end
    end)
    topBar.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            window.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)

    local sidebar = create("Frame", {
        Size = UDim2.new(0,200,1,-42),
        Position = UDim2.fromOffset(0,42),
        BackgroundColor3 = THEME.BackgroundAlt,
        BorderSizePixel = 0
    },{
        create("UICorner",{CornerRadius=UDim.new(0,8)}),
        create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)}),
        create("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingBottom=UDim.new(0,10)})
    })
    sidebar.Parent = window

    local categories = {
        {id="Visual", icon="👁", text=T("category_visual")},
        {id="Teleporte", icon="🧭", text=T("category_teleport")},
        {id="Status", icon="⚙", text=T("category_status")},
    }

    local contentHolder = create("Frame", {
        Name = "ContentHolder",
        Size = UDim2.new(1,-210,1,-52),
        Position = UDim2.new(0,210,0,52),
        BackgroundTransparency = 1
    })
    contentHolder.Parent = window

    local categoryButtons = {}
    local pages = {}
    local activeCategory=nil
    local function selectCategory(id)
        activeCategory=id
        for _,b in ipairs(categoryButtons) do
            if b.Name==id then
                b.BackgroundColor3 = THEME.Accent
                b.TextColor3 = Color3.new(1,1,1)
            else
                b.BackgroundColor3 = THEME.Section
                b.TextColor3 = THEME.TextPrimary
            end
        end
        for name,pg in pairs(pages) do
            pg.Visible = (name==id)
        end
    end

    local function makeCatButton(cat)
        local btn = create("TextButton",{
            Name = cat.id,
            Text = string.format("  %s  %s", cat.icon, cat.text),
            Font = Enum.Font.GothamSemibold,
            TextSize = 16,
            TextColor3 = THEME.TextPrimary,
            AutoButtonColor = false,
            BackgroundColor3 = THEME.Section,
            Size = UDim2.new(1,0,0,40)
        },{
            create("UICorner",{CornerRadius=UDim.new(0,6)})
        })
        btn.Parent = sidebar
        btn.MouseEnter:Connect(function()
            if activeCategory~=btn.Name then btn.BackgroundColor3 = THEME.Background end
        end)
        btn.MouseLeave:Connect(function()
            if activeCategory~=btn.Name then btn.BackgroundColor3 = THEME.Section end
        end)
        btn.MouseButton1Click:Connect(function() selectCategory(btn.Name) end)
        table.insert(categoryButtons, btn)
    end
    for _,cat in ipairs(categories) do makeCatButton(cat) end

    local function createPage(name)
        local page = create("Frame",{Name = name,BackgroundTransparency = 1,Size = UDim2.new(1,0,1,0),Visible = false})
        page.Parent = contentHolder
        pages[name] = page
        local scroll = create("ScrollingFrame",{Name="Scroll",BackgroundTransparency = 1,BorderSizePixel = 0,Size = UDim2.new(1,-10,1,-10),Position = UDim2.fromOffset(5,5),CanvasSize = UDim2.new(0,0,0,0),ScrollBarThickness = 6},{
            create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,10)})
        })
        scroll.Parent = page
        scroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize = UDim2.new(0,0,0,scroll.UIListLayout.AbsoluteContentSize.Y + 20)
        end)
        return page, scroll
    end

    local visualPage, visualList = createPage("Visual")
    local tpPage, tpList = createPage("Teleporte")
    local statusPage, statusList = createPage("Status")

    -- Visual / Systems
    Factory:SectionTitle(visualList, T("section_movement"))
    local flightToggle = Factory:Toggle(visualList, T("toggle_flight"), false, function(st) if st then Systems.Flight:Enable() else Systems.Flight:Disable() end end)
    Factory:Slider(visualList, T("slider_flight_speed"), 20, 300, Systems.Flight.Speed, function(v) Systems.Flight:SetSpeed(v) end)
    local noclipToggle = Factory:Toggle(visualList, T("toggle_noclip"), false, function(st) if st then Systems.Noclip:Enable() else Systems.Noclip:Disable() end end)
    Factory:Slider(visualList, T("slider_walkspeed"), 8, 100, 16, function(v) local hum = safeHumanoid() if hum then hum.WalkSpeed = v end end)
    Factory:SectionTitle(visualList, T("section_debug"))
    local espToggle = Factory:Toggle(visualList, T("toggle_esp"), false, function(st) if st then Systems.ESP:Enable() else Systems.ESP:Disable() end end)
    Factory:Button(visualList, T("btn_reset_char"), function() local hum = safeHumanoid() if hum then hum.Health = 0 end end, "warn")
    Factory:Button(visualList, T("btn_disable_all"), function()
        flightToggle.Set(false)
        noclipToggle.Set(false)
        espToggle.Set(false)
    end, "danger")

    -- Teleport
    Factory:SectionTitle(tpList, T("section_teleport"))
    local tpBox = Factory:TextBox(tpList, T("textbox_part_name"), T("textbox_part_placeholder"), function(text) teleportTo(text) end)
    Factory:Button(tpList, T("btn_teleport_name"), function() if tpBox.Text and #tpBox.Text>0 then teleportTo(tpBox.Text) end end)
    local presets = {
        {Nome=T("preset_spawn"), Part="SpawnLocation"},
        {Nome=T("preset_center"), Part="Center"},
        {Nome=T("preset_shop"), Part="Shop"}
    }
    for _,p in ipairs(presets) do
        Factory:Button(tpList, T("teleport_preset_prefix")..p.Nome, function() teleportTo(p.Part) end)
    end

    -- Status
    Factory:SectionTitle(statusList, T("section_status"))
    local statFrame = create("Frame",{BackgroundColor3 = THEME.Section,Size = UDim2.new(1,0,0,120),BorderSizePixel = 0},{create("UICorner",{CornerRadius=UDim.new(0,6)})})
    applyStroke(statFrame); statFrame.Parent = statusList
    local statLabel = create("TextLabel",{Text = "...",Font = Enum.Font.Gotham,TextSize = 14,TextColor3 = THEME.TextSecondary,BackgroundTransparency = 1,Size = UDim2.new(1,-20,1,-20),Position = UDim2.fromOffset(10,10),TextXAlignment = Enum.TextXAlignment.Left,TextYAlignment = Enum.TextYAlignment.Top})
    statLabel.Parent = statFrame

    task.spawn(function()
        while statLabel.Parent do
            local hum = safeHumanoid()
            local hp = hum and math.floor(hum.Health) or "?"
            local mhp = hum and math.floor(hum.MaxHealth) or "?"
            local ws = hum and hum.WalkSpeed or "?"
            local pos = tostring(getHRP() and getHRP().Position or "N/A")
            statLabel.Text = formatTemplate(T("status_format"), {
                hp = hp, mhp = mhp, ws = ws,
                flight = tostring(Systems.Flight.Enabled),
                noclip = tostring(Systems.Noclip.Enabled),
                esp = tostring(Systems.ESP.Enabled),
                pos = pos
            })
            task.wait(2)
        end
    end)

    -- Category default
    selectCategory("Visual")

    -- Respawn handling
    addConn(LocalPlayer.CharacterAdded:Connect(function()
        if Systems.Flight.Enabled then
            Systems.Flight:Disable()
            Systems.Flight:Enable()
        end
    end))
end
