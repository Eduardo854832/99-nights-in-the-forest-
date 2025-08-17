local VERSION = "1.0"

-- ===================== CONFIG RÁPIDO =====================
local CONFIG = {
    WINDOW_WIDTH = 480,
    WINDOW_HEIGHT = 220,
    TOPBAR_HEIGHT = 30,
    PADDING = 12,
    UI_SCALE = 1.0,       -- Ajuste global (ex: 0.9 / 1.1)
    FONT_MAIN_SIZE = 13,
    FONT_LABEL_SIZE = 12,
    MINI_BUTTON_SIZE = 40,
    MINI_START_POS = UDim2.new(0,20,0.4,0), -- posição fixa do botão flutuante minimizado
}

-- Serviços
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------
-- Persistência
----------------------------------------------------------------
local Persist = {}
Persist._fileName = "UniversalUtilityConfig.json"
Persist._data, Persist._dirty, Persist._lastWrite = {}, false, 0
Persist._flushInterval = 1
local hasFS = (typeof(isfile)=="function" and typeof(readfile)=="function" and typeof(writefile)=="function")

function Persist.load()
    if hasFS and isfile(Persist._fileName) then
        pcall(function()
            Persist._data = HttpService:JSONDecode(readfile(Persist._fileName))
        end)
    end
end
function Persist.flush(force)
    if not hasFS then return end
    if not force and (not Persist._dirty or (tick()-Persist._lastWrite)<Persist._flushInterval) then return end
    Persist._lastWrite, Persist._dirty = tick(), false
    pcall(function() writefile(Persist._fileName, HttpService:JSONEncode(Persist._data)) end)
end
function Persist.saveSoon() Persist._dirty = true end
function Persist.get(k,def)
    local v = Persist._data[k]
    if v==nil and def~=nil then Persist._data[k]=def; Persist._dirty=true; return def end
    return v
end
function Persist.setIfChanged(k,v) if Persist._data[k]~=v then Persist._data[k]=v; Persist.saveSoon() end end
function Persist.set(k,v) Persist._data[k]=v; Persist.saveSoon() end
Persist.load()

----------------------------------------------------------------
-- Logger
----------------------------------------------------------------
local Logger = { _max=120, _lines={}, _dirty=false }
function Logger.Log(level,msg)
    local line = os.date("%H:%M:%S").. " ["..level.."] " ..tostring(msg)
    table.insert(Logger._lines,line)
    if #Logger._lines>Logger._max then table.remove(Logger._lines,1) end
    warn("[UU]["..level.."] " ..tostring(msg))
    Logger._dirty=true
end

----------------------------------------------------------------
-- Traduções mínimas
----------------------------------------------------------------
local Lang = {}
Lang.data = {
    pt = {
        UI_TITLE="",
        MINI_HANDLE="≡",
        MINI_TIP="Arraste",
        LANG_CHANGED="Idioma alterado.",
        LOADED="Carregado v%s",
        FLY_ENABLED="Voo on (vel=%d)",
        FLY_DISABLED="Voo off",
        FLY_SPEED_SET="Velocidade de voo = %d",
        FLY_ERR_NO_ROOT="HumanoidRootPart não encontrado.",
        IY_LOADING="Carregando IY...",
        IY_LOADED="IY carregado.",
        IY_ALREADY="Já carregado.",
        IY_FAILED="Falha: %s",
        FLY_TOGGLE_ON="Off",
        FLY_TOGGLE_OFF="On",
        FLY_SPEED="Vel",
        BTN_IY_LOAD="IY",
        SLIDER_HINT="Arraste ou digite",
        LANG_SELECT_PT="Português",
        LANG_SELECT_EN="English",
        LANG_SELECT_TITLE="Selecione o Idioma"
    },
    en = {
        UI_TITLE="",
        MINI_HANDLE="≡",
        MINI_TIP="Drag",
        LANG_CHANGED="Language changed.",
        LOADED="Loaded v%s",
        FLY_ENABLED="Fly on (speed=%d)",
        FLY_DISABLED="Fly off",
        FLY_SPEED_SET="Fly speed = %d",
        FLY_ERR_NO_ROOT="HumanoidRootPart not found.",
        IY_LOADING="Loading IY...",
        IY_LOADED="IY loaded.",
        IY_ALREADY="Already loaded.",
        IY_FAILED="Failed: %s",
        FLY_TOGGLE_ON="Off",
        FLY_TOGGLE_OFF="On",
        FLY_SPEED="Spd",
        BTN_IY_LOAD="IY",
        SLIDER_HINT="Drag or type",
        LANG_SELECT_PT="Português",
        LANG_SELECT_EN="English",
        LANG_SELECT_TITLE="Select Language"
    }
}
Lang.current = nil -- força seleção sempre
local _missingLogged = {}
local function L(k,...)
    local pack=Lang.data[Lang.current or "pt"]
    local s=(pack and pack[k]) or k
    if s==k and not _missingLogged[k] then
        _missingLogged[k]=true
        Logger.Log("I18N","Missing key: " ..k)
    end
    if select("#",...)>0 then
        return string.format(s,...)
    end
    return s
end

----------------------------------------------------------------
-- Util
----------------------------------------------------------------
local function notify(t,x,d) pcall(function() StarterGui:SetCore("SendNotification",{Title=t,Text=x,Duration=d or 3}) end) end

----------------------------------------------------------------
-- Fly Controller (analógico + câmera)
----------------------------------------------------------------
local Fly = {
    active=false,
    speed=Persist.get("fly_speed",50),
    conn=nil
}
local function getRoot()
    local char=LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local char=LocalPlayer.Character
    return char and char:FindFirstChildWhichIsA("Humanoid")
end
local function computeDirection3D(hum,cam)
    local move = hum.MoveDirection
    if move.Magnitude==0 then
        return Vector3.zero
    end
    local camForward = cam.CFrame.LookVector
    local flatForward = Vector3.new(camForward.X,0,camForward.Z)
    if flatForward.Magnitude < 1e-6 then
        flatForward = Vector3.new(0,0,-1)
    else
        flatForward = flatForward.Unit
    end
    local camRight = cam.CFrame.RightVector
    camRight = Vector3.new(camRight.X,0,camRight.Z).Unit
    local xInput = move:Dot(camRight)
    local zInput = move:Dot(flatForward)
    local dir = (camRight * xInput) + (camForward * zInput)
    if dir.Magnitude > 0 then dir = dir.Unit end
    return dir
end
function Fly.enable()
    if Fly.active then return end
    local root=getRoot()
    if not root then notify("Fly", L("FLY_ERR_NO_ROOT")); return end
    Fly.active=true
    if Fly.conn then Fly.conn:Disconnect() end
    Fly.conn=RunService.Heartbeat:Connect(function()
        if not Fly.active then return end
        local r=getRoot(); if not r then return end
        local hum=getHum(); if not hum then return end
        local cam=workspace.CurrentCamera; if not cam then return end
        local dir=computeDirection3D(hum,cam)
        if dir.Magnitude==0 then
            r.Velocity=Vector3.zero
        else
            r.Velocity=dir*Fly.speed
        end
    end)
    notify("Fly", L("FLY_ENABLED", Fly.speed))
end
function Fly.disable()
    if not Fly.active then return end
    Fly.active=false
    if Fly.conn then Fly.conn:Disconnect(); Fly.conn=nil end
    local root=getRoot(); if root then root.Velocity=Vector3.zero end
    notify("Fly", L("FLY_DISABLED"))
end
function Fly.setSpeed(n)
    Fly.speed=math.clamp(n,5,500)
    Persist.setIfChanged("fly_speed",Fly.speed)
    notify("Fly", L("FLY_SPEED_SET", Fly.speed))
end

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
local UI={}
UI._translatables={}
local function mark(inst,key,...) table.insert(UI._translatables,{instance=inst,key=key,args={...}}) end
local function scale(n) return n * CONFIG.UI_SCALE end

local function styleButton(btn)
    btn.AutoButtonColor=false
    btn.TextColor3=Color3.new(1,1,1)
    btn.Font=Enum.Font.Gotham
    btn.TextSize=CONFIG.FONT_MAIN_SIZE
    btn.BackgroundColor3=Color3.fromRGB(50,50,62)
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
end

function UI.applyLanguage()
    if not Lang.current then return end
    for _,d in ipairs(UI._translatables) do
        local inst=d.instance
        if inst and inst.Parent and (inst:IsA("TextLabel") or inst:IsA("TextButton")) then
            local txt=(d.args and #d.args>0) and L(d.key,table.unpack(d.args)) or L(d.key)
            inst.Text=txt
        end
    end
    if UI.FlyToggle then
        UI.FlyToggle.Text = Fly.active and L("FLY_TOGGLE_ON") or L("FLY_TOGGLE_OFF")
    end
    if UI.SpeedLabel then
        UI.SpeedLabel.Text = L("FLY_SPEED")..": "..Fly.speed
    end
    if UI.IYLoadBtn then UI.IYLoadBtn.Text = L("BTN_IY_LOAD") end
    if UI.SliderHint then UI.SliderHint.Text = L("SLIDER_HINT") end
end

----------------------------------------------------------------
-- Watermark enforcement
----------------------------------------------------------------
local WATERMARK="Eduardo854832"
local function killAll(msg)
    pcall(function() Fly.disable() end)
    if UI and UI.Screen then pcall(function() UI.Screen:Destroy() end) end
    error(msg or "Watermark removed.")
end
local function startWatermarkEnforcer()
    task.spawn(function()
        while true do
            if not UI or not UI.WatermarkLabel or not UI.WatermarkLabel.Parent or UI.WatermarkLabel.Text~=WATERMARK then
                killAll("Watermark missing/altered")
                break
            end
            task.wait(2 + math.random()*0.8)
        end
    end)
end

----------------------------------------------------------------
-- Slider helper
----------------------------------------------------------------
local function createSlider(parent,minVal,maxVal,getVal,setVal)
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,scale(260),0,scale(42))
    frame.BackgroundTransparency=1
    frame.Parent=parent

    local barBg=Instance.new("Frame")
    barBg.Size=UDim2.new(0,scale(150),0,scale(8))
    barBg.Position=UDim2.new(0,0,0,scale(6))
    barBg.BackgroundColor3=Color3.fromRGB(60,60,72)
    barBg.Parent=frame
    Instance.new("UICorner",barBg).CornerRadius=UDim.new(0,4)

    local fill=Instance.new("Frame")
    fill.BackgroundColor3=Color3.fromRGB(90,140,255)
    fill.Size=UDim2.new(0,0,1,0)
    fill.Parent=barBg
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,4)

    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,scale(12),0,scale(12))
    knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new(0,0,0.5,0)
    knob.BackgroundColor3=Color3.fromRGB(200,200,220)
    knob.Parent=barBg
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local box=Instance.new("TextBox")
    box.Size=UDim2.new(0,scale(90),0,scale(22))
    box.Position=UDim2.new(0,scale(170),0,scale(-2))
    box.BackgroundColor3=Color3.fromRGB(55,55,70)
    box.TextColor3=Color3.new(1,1,1)
    box.Font=Enum.Font.Code
    box.TextSize=CONFIG.FONT_LABEL_SIZE
    box.PlaceholderText=tostring(getVal())
    box.Text=""
    box.Parent=frame
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,5)

    local hint=Instance.new("TextLabel")
    hint.BackgroundTransparency=1
    hint.Size=UDim2.new(1,0,0,scale(16))
    hint.Position=UDim2.new(0,0,0,scale(22))
    hint.Font=Enum.Font.Gotham
    hint.TextSize=CONFIG.FONT_LABEL_SIZE-1
    hint.TextColor3=Color3.fromRGB(160,160,170)
    hint.Text=""
    hint.TextXAlignment=Enum.TextXAlignment.Left
    hint.Parent=frame
    UI.SliderHint=hint
    mark(hint,"SLIDER_HINT")

    local function refresh()
        local v=getVal()
        local alpha=(v-minVal)/(maxVal-minVal)
        fill.Size=UDim2.new(alpha,0,1,0)
        knob.Position=UDim2.new(alpha,0,0.5,0)
        box.PlaceholderText=tostring(v)
        if UI.SpeedLabel then
            UI.SpeedLabel.Text=L("FLY_SPEED")..": "..v
        end
    end
    refresh()

    local dragging=false
    local function setFromX(px)
        local rel=(px-barBg.AbsolutePosition.X)/barBg.AbsoluteSize.X
        rel=math.clamp(rel,0,1)
        local val=math.floor(minVal+rel*(maxVal-minVal)+0.5)
        setVal(val)
        refresh()
    end
    barBg.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            setFromX(i.Position.X)
        end
    end)
    barBg.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
    barBg.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    box.FocusLost:Connect(function(enter)
        if enter then
            local n=tonumber(box.Text)
            if n then
                n=math.clamp(math.floor(n+0.5),minVal,maxVal)
                setVal(n)
            end
            box.Text=""
            refresh()
        end
    end)
    return frame
end

----------------------------------------------------------------
-- Botão flutuante minimizado (criado antes para já ter posição fixa)
----------------------------------------------------------------
local FloatingButton=nil
local function createFloatingButton()
    local sg=Instance.new("ScreenGui")
    sg.Name="UU_FloatBtn"
    sg.ResetOnSpawn=false
    pcall(function() sg.Parent=(gethui and gethui()) or CoreGui end)

    local btn=Instance.new("TextButton")
    btn.Name="OpenBtn"
    btn.Size=UDim2.new(0,scale(CONFIG.MINI_BUTTON_SIZE),0,scale(CONFIG.MINI_BUTTON_SIZE))
    btn.Position=CONFIG.MINI_START_POS
    btn.AnchorPoint=Vector2.new(0,0)
    btn.BackgroundColor3=Color3.fromRGB(40,48,62)
    btn.TextColor3=Color3.new(1,1,1)
    btn.Font=Enum.Font.GothamBold
    btn.TextSize=math.floor(CONFIG.FONT_MAIN_SIZE+2)
    btn.Text=L("MINI_HANDLE")
    btn.Parent=sg
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)

    local dragging=false
    local dragStart,startPos
    local function update(input)
        local delta=input.Position-dragStart
        btn.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
    btn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=i.Position
            startPos=btn.Position
            i.Changed:Connect(function(s)
                if s==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    btn.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            update(i)
        end
    end)
    FloatingButton=btn
    return btn
end

----------------------------------------------------------------
-- UI principal
----------------------------------------------------------------
function UI.create()
    local sg=Instance.new("ScreenGui")
    sg.Name="UU_Main"
    sg.ResetOnSpawn=false
    pcall(function() sg.Parent=(gethui and gethui()) or CoreGui end)
    UI.Screen=sg

    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,scale(CONFIG.WINDOW_WIDTH),0,scale(CONFIG.WINDOW_HEIGHT))
    frame.Position=UDim2.new(0.5,-scale(CONFIG.WINDOW_WIDTH)/2,0.45,-scale(CONFIG.WINDOW_HEIGHT)/2)
    frame.BackgroundColor3=Color3.fromRGB(25,25,32)
    frame.Parent=sg
    UI.Frame=frame
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)

    local top=Instance.new("Frame")
    top.Size=UDim2.new(1,0,0,scale(CONFIG.TOPBAR_HEIGHT))
    top.BackgroundColor3=Color3.fromRGB(38,38,50)
    top.Parent=frame
    Instance.new("UICorner",top).CornerRadius=UDim.new(0,10)

    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Size=UDim2.new(0.5,0,1,0)
    title.Position=UDim2.new(0,scale(CONFIG.PADDING),0,0)
    title.Font=Enum.Font.GothamBold
    title.TextSize=CONFIG.FONT_MAIN_SIZE
    title.TextColor3=Color3.new(1,1,1)
    title.Text=L("UI_TITLE",VERSION)
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=top
    UI.Title=title
    mark(title,"UI_TITLE",VERSION)

    -- Watermark ao lado
    local wm=Instance.new("TextLabel")
    wm.BackgroundTransparency=1
    wm.Font=Enum.Font.GothamBold
    wm.TextSize=CONFIG.FONT_MAIN_SIZE
    wm.TextColor3=Color3.fromRGB(255,255,255)
    wm.TextStrokeTransparency=0.5
    wm.Text=WATERMARK
    wm.Size=UDim2.new(0,150,1,0)
    wm.AnchorPoint=Vector2.new(1,0)
    wm.Position=UDim2.new(1,-scale(100),0,0)
    wm.TextXAlignment=Enum.TextXAlignment.Right
    wm.Parent=top
    UI.WatermarkLabel=wm

    local closeX=Instance.new("TextButton")
    closeX.Size=UDim2.new(0,scale(28),0,scale(CONFIG.TOPBAR_HEIGHT-10))
    closeX.Position=UDim2.new(1,-scale(32),0,scale(5))
    closeX.Text="X"
    closeX.Font=Enum.Font.GothamBold
    closeX.TextSize=CONFIG.FONT_MAIN_SIZE
    closeX.BackgroundColor3=Color3.fromRGB(90,50,50)
    closeX.TextColor3=Color3.new(1,1,1)
    closeX.Parent=top
    Instance.new("UICorner",closeX).CornerRadius=UDim.new(0,6)

    local minimize=Instance.new("TextButton")
    minimize.Size=UDim2.new(0,scale(28),0,scale(CONFIG.TOPBAR_HEIGHT-10))
    minimize.Position=UDim2.new(1,-scale(64),0,scale(5))
    minimize.Text="–"
    minimize.Font=Enum.Font.GothamBold
    minimize.TextSize=CONFIG.FONT_MAIN_SIZE
    minimize.BackgroundColor3=Color3.fromRGB(60,60,70)
    minimize.TextColor3=Color3.new(1,1,1)
    minimize.Parent=top
    Instance.new("UICorner",minimize).CornerRadius=UDim.new(0,6)

    local content=Instance.new("Frame")
    content.Size=UDim2.new(1,0,1,-scale(CONFIG.TOPBAR_HEIGHT))
    content.Position=UDim2.new(0,0,0,scale(CONFIG.TOPBAR_HEIGHT))
    content.BackgroundTransparency=1
    content.Parent=frame

    -- Coluna esquerda (botões)
    local left=Instance.new("Frame")
    left.Size=UDim2.new(0,scale(110),1,0)
    left.BackgroundColor3=Color3.fromRGB(30,30,40)
    left.Parent=content
    Instance.new("UICorner",left).CornerRadius=UDim.new(0,8)

    local list=Instance.new("UIListLayout",left)
    list.SortOrder=Enum.SortOrder.LayoutOrder
    list.Padding=UDim.new(0,scale(6))
    list.HorizontalAlignment=Enum.HorizontalAlignment.Center
    list.VerticalAlignment=Enum.VerticalAlignment.Start

    local function makeSmallBtn(txt)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(1,-scale(14),0,scale(30))
        b.BackgroundColor3=Color3.fromRGB(52,52,60)
        b.TextColor3=Color3.new(1,1,1)
        b.Font=Enum.Font.Gotham
        b.TextSize=CONFIG.FONT_MAIN_SIZE
        b.Text=txt
        b.Parent=left
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
        return b
    end

    local btnFly=makeSmallBtn("Fly")
    local btnSpeed=makeSmallBtn("Speed")
    local btnIY=makeSmallBtn("IY")

    -- Área direita (painéis)
    local right=Instance.new("Frame")
    right.Size=UDim2.new(1,-scale(120),1,0)
    right.Position=UDim2.new(0,scale(120),0,0)
    right.BackgroundColor3=Color3.fromRGB(32,32,44)
    right.Parent=content
    Instance.new("UICorner",right).CornerRadius=UDim.new(0,8)

    local panels={}
    local function newPanel()
        local p=Instance.new("Frame")
        p.Size=UDim2.new(1,0,1,0)
        p.BackgroundTransparency=1
        p.Visible=false
        p.Parent=right
        panels[#panels+1]=p
        return p
    end
    local panelFly=newPanel()
    local panelSpeed=newPanel()
    local panelIY=newPanel()

    local function showPanel(p)
        for _,pp in ipairs(panels) do pp.Visible=(pp==p) end
    end

    -- Conteúdo Fly
    do
        local toggle=Instance.new("TextButton")
        toggle.Size=UDim2.new(0,scale(110),0,scale(34))
        toggle.Position=UDim2.new(0,scale(14),0,scale(14))
        styleButton(toggle)
        toggle.Text=Fly.active and L("FLY_TOGGLE_ON") or L("FLY_TOGGLE_OFF")
        toggle.Parent=panelFly
        UI.FlyToggle=toggle
        toggle.MouseButton1Click:Connect(function()
            if Fly.active then Fly.disable() else Fly.enable() end
            UI.applyLanguage()
        end)
    end

    -- Conteúdo Speed
    do
        local speedLabel=Instance.new("TextLabel")
        speedLabel.BackgroundTransparency=1
        speedLabel.Size=UDim2.new(0,scale(180),0,scale(20))
        speedLabel.Position=UDim2.new(0,scale(14),0,scale(14))
        speedLabel.Font=Enum.Font.Gotham
        speedLabel.TextSize=CONFIG.FONT_LABEL_SIZE
        speedLabel.TextColor3=Color3.fromRGB(200,200,210)
        speedLabel.Text=L("FLY_SPEED")..": "..Fly.speed
        speedLabel.TextXAlignment=Enum.TextXAlignment.Left
        speedLabel.Parent=panelSpeed
        UI.SpeedLabel=speedLabel
        mark(speedLabel,"FLY_SPEED")

        local sliderHolder=Instance.new("Frame")
        sliderHolder.Size=UDim2.new(0,scale(260),0,scale(50))
        sliderHolder.Position=UDim2.new(0,scale(14),0,scale(40))
        sliderHolder.BackgroundTransparency=1
        sliderHolder.Parent=panelSpeed
        createSlider(sliderHolder,5,500,function() return Fly.speed end,function(v) Fly.setSpeed(v) end)
    end

    -- Conteúdo IY
    do
        local status=Instance.new("TextLabel")
        status.BackgroundTransparency=1
        status.Size=UDim2.new(0,scale(120),0,scale(20))
        status.Position=UDim2.new(0,scale(14),0,scale(14))
        status.Font=Enum.Font.Gotham
        status.TextSize=CONFIG.FONT_LABEL_SIZE
        status.TextColor3=Color3.fromRGB(200,200,210)
        status.Text=_G.__IY_LOADED and "IY: ON" or "IY: OFF"
        status.TextXAlignment=Enum.TextXAlignment.Left
        status.Parent=panelIY
        UI.IYStatus=status

        local loadBtn=Instance.new("TextButton")
        loadBtn.Size=UDim2.new(0,scale(110),0,scale(34))
        loadBtn.Position=UDim2.new(0,scale(14),0,scale(40))
        styleButton(loadBtn)
        loadBtn.Text=L("BTN_IY_LOAD")
        loadBtn.Parent=panelIY
        UI.IYLoadBtn=loadBtn
        mark(loadBtn,"BTN_IY_LOAD")
        loadBtn.MouseButton1Click:Connect(function()
            if _G.__IY_LOADED then
                notify("IY", L("IY_ALREADY"))
                return
            end
            notify("IY", L("IY_LOADING"))
            local ok,err=pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
            end)
            if ok then
                _G.__IY_LOADED=true
                notify("IY", L("IY_LOADED"))
                if UI.IYStatus then UI.IYStatus.Text="IY: ON" end
            else
                notify("IY", L("IY_FAILED",tostring(err)))
            end
        end)
    end

    -- Ações dos botões laterais
    btnFly.MouseButton1Click:Connect(function() showPanel(panelFly) end)
    btnSpeed.MouseButton1Click:Connect(function() showPanel(panelSpeed) end)
    btnIY.MouseButton1Click:Connect(function() showPanel(panelIY) end)
    showPanel(panelFly)

    -- Drag janela
    local dragging=false
    local dragStart,startPos
    local function updateWindow(input)
        local delta=input.Position-dragStart
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

    minimize.MouseButton1Click:Connect(function()
        frame.Visible=false
        if FloatingButton then FloatingButton.Visible=true end
    end)
    closeX.MouseButton1Click:Connect(function()
        frame.Visible=false
        if FloatingButton then FloatingButton.Visible=true end
    end)

    if FloatingButton then
        FloatingButton.MouseButton1Click:Connect(function()
            frame.Visible=true
            FloatingButton.Visible=false
        end)
    end

    UI.applyLanguage()
    startWatermarkEnforcer()
end

----------------------------------------------------------------
-- Seleção de idioma
----------------------------------------------------------------
local function showLanguageSelect(onChosen)
    local sg=Instance.new("ScreenGui")
    sg.Name="UU_LangSelectInitial"
    sg.ResetOnSpawn=false
    pcall(function() sg.Parent=(gethui and gethui()) or CoreGui end)

    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,300,0,160)
    frame.Position=UDim2.new(0.5,-150,0.5,-80)
    frame.BackgroundColor3=Color3.fromRGB(25,25,35)
    frame.Parent=sg
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,12)

    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Size=UDim2.new(1,0,0,46)
    title.Font=Enum.Font.GothamBold
    title.TextColor3=Color3.new(1,1,1)
    title.TextSize=18
    title.Text="Select / Selecione"
    title.Parent=frame

    local function mk(txt,x,code)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0.5,-30,0,54)
        b.Position=UDim2.new(x,20,0,80)
        b.BackgroundColor3=Color3.fromRGB(40,60,90)
        b.TextColor3=Color3.new(1,1,1)
        b.TextSize=18
        b.Font=Enum.Font.GothamBold
        b.Text=txt
        b.Parent=frame
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,12)
        b.MouseButton1Click:Connect(function()
            Lang.current=code
            Persist.set("lang",code)
            sg:Destroy()
            if onChosen then onChosen() end
        end)
    end
    mk("Português",0,"pt")
    mk("English",0.5,"en")
end

----------------------------------------------------------------
-- Inicialização
----------------------------------------------------------------
createFloatingButton()  -- cria botão flutuante antes (fica visível quando menu fechado)
if FloatingButton then FloatingButton.Visible=false end

showLanguageSelect(function()
    UI.create()
    notify("Utility", L("LOADED", VERSION), 3)
end)

-- Flush periódico
task.spawn(function()
    while true do
        Persist.flush(false)
        task.wait(0.5)
    end
end)

return { VERSION=VERSION, Persist=Persist, Lang=Lang, UI=UI, Logger=Logger, Fly=Fly }