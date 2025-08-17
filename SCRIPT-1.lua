local VERSION = "1.0"

-- Serviços
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

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
-- Traduções
----------------------------------------------------------------
local Lang = {}
Lang.data = {
    pt = {
        UI_TITLE="Universal Utility v%s",
        MINI_HANDLE="≡",
        MINI_TIP="Arraste/Clique",
        LANG_DIALOG_TITLE="Selecione o Idioma / Select Language",
        LANG_DIALOG_CURRENT="Atual: %s\nClique para trocar.",
        LANG_CHOOSE="Escolha um idioma.",
        LANG_CHANGED="Idioma alterado.",
        BTN_LANG_SELECT="Trocar Idioma",
        HELP_TITLE="Comandos: help / lang / fly / iy",
        LOADED="Carregado v%s",
        MISSING_NONE="Sem chaves faltando",
        PANEL_MISSING="Traduções Faltantes",
        -- Fly
        FLY_ENABLED="Voo ativado (vel=%d)",
        FLY_DISABLED="Voo desativado",
        FLY_SPEED_SET="Velocidade de voo = %d",
        FLY_USAGE="Uso: /uu fly on|off|speed <n>",
        FLY_ERR_NO_ROOT="Não encontrei HumanoidRootPart.",
        -- Infinite Yield
        IY_LOADING="Carregando Infinite Yield...",
        IY_LOADED="Infinite Yield carregado.",
        IY_ALREADY="Infinite Yield já carregado.",
        IY_FAILED="Falha ao carregar: %s",

        -- NOVAS KEYS UI Avançada
        SIDEBAR_LANG="Linguagem",
        SIDEBAR_FLY="Fly",
        SIDEBAR_IY="Infinite Yield",
        SIDEBAR_HELP="Ajuda",
        PANEL_LANG_TITLE="Idioma",
        PANEL_FLY_TITLE="Configuração de Voo",
        PANEL_IY_TITLE="Admin (IY)",
        PANEL_HELP_TITLE="Ajuda / Comandos",
        FLY_TOGGLE_ON="Desativar Voo",
        FLY_TOGGLE_OFF="Ativar Voo",
        FLY_SPEED="Velocidade",
        FLY_SPEED_APPLY="Aplicar",
        FLY_SPEED_PLACEHOLDER="Vel...",
        IY_STATUS_LOADED="Status: Carregado",
        IY_STATUS_NOT_LOADED="Status: Não Carregado",
        BTN_IY_LOAD="Carregar",
        HELP_DESC="Você pode usar também via chat:\n/uu fly on|off|speed <n>\n/uu lang\n/uu iy\n/uu help",
        BTN_CLOSE="Minimizar",
        BTN_RESTORE_TIP="Clique para abrir",
        PANEL_GENERAL="Geral",
        BTN_OPEN_LANG_DIALOG="Abrir Seleção",
        SLIDER_HINT="Arraste a barra ou digite o valor",
    },
    en = {
        UI_TITLE="Universal Utility v%s",
        MINI_HANDLE="≡",
        MINI_TIP="Drag/Click",
        LANG_DIALOG_TITLE="Select Language / Selecione o Idioma",
        LANG_DIALOG_CURRENT="Current: %s\nClick to change.",
        LANG_CHOOSE="Choose a language.",
        LANG_CHANGED="Language changed.",
        BTN_LANG_SELECT="Change Language",
        HELP_TITLE="Commands: help / lang / fly / iy",
        LOADED="Loaded v%s",
        MISSING_NONE="No missing keys",
        PANEL_MISSING="Missing Keys",
        -- Fly
        FLY_ENABLED="Fly enabled (speed=%d)",
        FLY_DISABLED="Fly disabled",
        FLY_SPEED_SET="Fly speed = %d",
        FLY_USAGE="Usage: /uu fly on|off|speed <n>",
        FLY_ERR_NO_ROOT="HumanoidRootPart not found.",
        -- Infinite Yield
        IY_LOADING="Loading Infinite Yield...",
        IY_LOADED="Infinite Yield loaded.",
        IY_ALREADY="Infinite Yield already loaded.",
        IY_FAILED="Failed to load: %s",

        -- NEW Advanced UI
        SIDEBAR_LANG="Language",
        SIDEBAR_FLY="Fly",
        SIDEBAR_IY="Infinite Yield",
        SIDEBAR_HELP="Help",
        PANEL_LANG_TITLE="Language",
        PANEL_FLY_TITLE="Fly Settings",
        PANEL_IY_TITLE="Admin (IY)",
        PANEL_HELP_TITLE="Help / Commands",
        FLY_TOGGLE_ON="Disable Fly",
        FLY_TOGGLE_OFF="Enable Fly",
        FLY_SPEED="Speed",
        FLY_SPEED_APPLY="Apply",
        FLY_SPEED_PLACEHOLDER="Spd...",
        IY_STATUS_LOADED="Status: Loaded",
        IY_STATUS_NOT_LOADED="Status: Not Loaded",
        BTN_IY_LOAD="Load",
        HELP_DESC="You can also use chat:\n/uu fly on|off|speed <n>\n/uu lang\n/uu iy\n/uu help",
        BTN_CLOSE="Minimize",
        BTN_RESTORE_TIP="Click to open",
        PANEL_GENERAL="General",
        BTN_OPEN_LANG_DIALOG="Open Selector",
        SLIDER_HINT="Drag bar or type value",
    }
}
Lang.current = Persist.get("lang", nil)
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
-- Diálogo de Idioma (reuso)
----------------------------------------------------------------
local function buildLanguageDialog(onChosen)
    local sg=Instance.new("ScreenGui")
    sg.Name="UU_LangSelect"
    sg.ResetOnSpawn=false
    pcall(function() sg.Parent=(gethui and gethui()) or game:GetService("CoreGui") end)

    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,360,0,170)
    frame.Position=UDim2.new(0.5,-180,0.5,-85)
    frame.BackgroundColor3=Color3.fromRGB(25,25,35)
    frame.Parent=sg
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,14)

    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Size=UDim2.new(1,0,0,46)
    title.Font=Enum.Font.GothamBold
    title.TextColor3=Color3.new(1,1,1)
    title.TextSize=18
    title.Text=L("LANG_DIALOG_TITLE")
    title.Parent=frame

    local info=Instance.new("TextLabel")
    info.BackgroundTransparency=1
    info.Size=UDim2.new(1,-20,0,40)
    info.Position=UDim2.new(0,10,0,50)
    info.Font=Enum.Font.Gotham
    info.TextColor3=Color3.fromRGB(200,200,200)
    info.TextSize=14
    info.TextWrapped=true
    if Lang.current then
        info.Text = L("LANG_DIALOG_CURRENT", Lang.current:upper())
    else
        info.Text = L("LANG_CHOOSE")
    end
    info.Parent=frame

    local function mk(label,x,code)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0.5,-30,0,50)
        b.Position=UDim2.new(x,20,0,100)
        b.BackgroundColor3=Color3.fromRGB(40,60,90)
        b.TextColor3=Color3.new(1,1,1)
        b.TextSize=18
        b.Font=Enum.Font.GothamBold
        b.Text=label
        b.Parent=frame
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,12)
        b.MouseButton1Click:Connect(function()
            Lang.current=code
            Persist.set("lang",code)
            notify("Lang", L("LANG_CHANGED"))
            sg:Destroy()
            if onChosen then onChosen() end
        end)
    end
    mk("Português",0,"pt")
    mk("English",0.5,"en")
end
local function ensureLanguage(cb)
    if Lang.current then cb() else buildLanguageDialog(cb) end
end

----------------------------------------------------------------
-- Fly Controller
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
function Fly.enable()
    if Fly.active then return end
    local root=getRoot()
    if not root then notify("Fly", L("FLY_ERR_NO_ROOT")); return end
    Fly.active=true
    local hum=getHum()
    if hum then hum.PlatformStand=true end
    if Fly.conn then Fly.conn:Disconnect() end
    Fly.conn = RunService.Heartbeat:Connect(function()
        if not Fly.active then return end
        local r=getRoot(); if not r then return end
        local cam=workspace.CurrentCamera; if not cam then return end
        local move=Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move -= Vector3.new(0,1,0) end
        if move.Magnitude>0 then move=move.Unit else move=Vector3.zero end
        r.Velocity = move * Fly.speed
    end)
    notify("Fly", L("FLY_ENABLED", Fly.speed))
end
function Fly.disable()
    if not Fly.active then return end
    Fly.active=false
    if Fly.conn then Fly.conn:Disconnect(); Fly.conn=nil end
    local hum=getHum(); if hum then hum.PlatformStand=false end
    local root=getRoot(); if root then root.Velocity=Vector3.zero end
    notify("Fly", L("FLY_DISABLED"))
end
function Fly.setSpeed(n)
    Fly.speed = math.clamp(n,5,500)
    Persist.setIfChanged("fly_speed",Fly.speed)
    notify("Fly", L("FLY_SPEED_SET", Fly.speed))
end

----------------------------------------------------------------
-- Comandos de Chat (mantidos)
----------------------------------------------------------------
local commands={}
local function register(name,desc,fn) commands[name]={desc=desc,fn=fn} end
local function parseChat(msg)
    if not msg:lower():match("^/uu%s") then return end
    local body=msg:sub(5)
    local args={}
    for tk in body:gmatch("%S+") do table.insert(args,tk) end
    local cmd=table.remove(args,1)
    if not cmd then
        notify("UU", L("HELP_TITLE"))
        return
    end
    local c=commands[cmd:lower()]
    if c then
        local ok,err=pcall(c.fn,args)
        if not ok then notify("UU","Error"); Logger.Log("ERR",err) end
    else
        notify("UU", "?")
    end
end
LocalPlayer.Chatted:Connect(parseChat)

register("help","Show help",function()
    notify("UU", L("HELP_TITLE"))
end)
register("lang","Open language selector",function()
    buildLanguageDialog(function() UI.applyLanguage() end)
end)
register("fly","Toggle / speed fly",function(a)
    local sub=a[1] and a[1]:lower()
    if sub=="on" then
        Fly.enable()
    elseif sub=="off" then
        Fly.disable()
    elseif sub=="speed" then
        local n=tonumber(a[2] or "")
        if n then Fly.setSpeed(n) else notify("Fly", L("FLY_USAGE")) end
    else
        notify("Fly", L("FLY_USAGE"))
    end
end)
register("iy","Load Infinite Yield admin",function()
    if _G.__IY_LOADED then
        notify("IY", L("IY_ALREADY"))
        return
    end
    notify("IY", L("IY_LOADING"))
    local ok,err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end)
    if ok then
        _G.__IY_LOADED=true
        notify("IY", L("IY_LOADED"))
    else
        notify("IY", L("IY_FAILED", tostring(err)))
    end
end)

----------------------------------------------------------------
-- Nova UI Avançada
----------------------------------------------------------------
local UI={}
UI._translatables={}
local function mark(inst,key,...) table.insert(UI._translatables,{instance=inst,key=key,args={...}}) end

local function styleButton(btn)
    btn.AutoButtonColor=false
    btn.TextColor3=Color3.new(1,1,1)
    btn.Font=Enum.Font.Gotham
    btn.TextSize=14
    btn.BackgroundColor3=Color3.fromRGB(48,48,60)
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
end

function UI.applyLanguage()
    for _,d in ipairs(UI._translatables) do
        local inst=d.instance
        if inst and inst.Parent and (inst:IsA("TextLabel") or inst:IsA("TextButton")) then
            inst.Text = (d.args and #d.args>0) and L(d.key, table.unpack(d.args)) or L(d.key)
        end
    end
    if UI.Title then UI.Title.Text=L("UI_TITLE", VERSION) end
    if UI.MiniButton then UI.MiniButton.Text=L("MINI_HANDLE") end
    if UI.MiniTip then UI.MiniTip.Text=L("MINI_TIP") end

    -- Atualizações dinâmicas painel fly
    if UI.FlyToggle then
        UI.FlyToggle.Text = Fly.active and L("FLY_TOGGLE_ON") or L("FLY_TOGGLE_OFF")
    end
    if UI.SpeedLabel then
        UI.SpeedLabel.Text = L("FLY_SPEED")..": "..tostring(Fly.speed)
    end
    if UI.IYStatus then
        UI.IYStatus.Text = _G.__IY_LOADED and L("IY_STATUS_LOADED") or L("IY_STATUS_NOT_LOADED")
    end
    if UI.IYLoadBtn then
        UI.IYLoadBtn.Text = L("BTN_IY_LOAD")
    end
    if UI.SliderHint then
        UI.SliderHint.Text = L("SLIDER_HINT")
    end
end

-- Helper para criar label de seção
local function sectionHeader(parent,textKey)
    local lbl=Instance.new("TextLabel")
    lbl.BackgroundTransparency=1
    lbl.Size=UDim2.new(1,0,0,24)
    lbl.Font=Enum.Font.GothamBold
    lbl.TextSize=16
    lbl.TextColor3=Color3.new(1,1,1)
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text=L(textKey)
    lbl.Parent=parent
    mark(lbl,textKey)
    return lbl
end

-- Cria slider simples (0-500)
local function createSlider(parent,minVal,maxVal,getVal,setVal)
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(1,0,0,48)
    frame.BackgroundTransparency=1
    frame.Parent=parent

    local barBg=Instance.new("Frame")
    barBg.Size=UDim2.new(1,-120,0,10)
    barBg.Position=UDim2.new(0,0,0,10)
    barBg.BackgroundColor3=Color3.fromRGB(60,60,72)
    barBg.Parent=frame
    Instance.new("UICorner",barBg).CornerRadius=UDim.new(0,5)

    local fill=Instance.new("Frame")
    fill.BackgroundColor3=Color3.fromRGB(90,140,255)
    fill.Size=UDim2.new(0,0,1,0)
    fill.Parent=barBg
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,5)

    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,14,0,14)
    knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new(0,0,0.5,0)
    knob.BackgroundColor3=Color3.fromRGB(200,200,220)
    knob.Parent=barBg
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local box=Instance.new("TextBox")
    box.Size=UDim2.new(0,100,0,26)
    box.Position=UDim2.new(1,-110,0,0)
    box.BackgroundColor3=Color3.fromRGB(55,55,70)
    box.TextColor3=Color3.new(1,1,1)
    box.Font=Enum.Font.Code
    box.TextSize=14
    box.PlaceholderText=tostring(getVal())
    box.Text=""
    box.Parent=frame
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,6)

    local hint=Instance.new("TextLabel")
    hint.BackgroundTransparency=1
    hint.Size=UDim2.new(1,0,0,16)
    hint.Position=UDim2.new(0,0,0,26)
    hint.Font=Enum.Font.Gotham
    hint.TextSize=12
    hint.TextColor3=Color3.fromRGB(180,180,190)
    hint.Text=L("SLIDER_HINT")
    hint.TextXAlignment=Enum.TextXAlignment.Left
    hint.Parent=frame
    UI.SliderHint=hint
    mark(hint,"SLIDER_HINT")

    local function refreshVisual()
        local v=getVal()
        local alpha=(v-minVal)/(maxVal-minVal)
        fill.Size=UDim2.new(alpha,0,1,0)
        knob.Position=UDim2.new(alpha,0,0.5,0)
        box.PlaceholderText=tostring(v)
        if UI.SpeedLabel then
            UI.SpeedLabel.Text=L("FLY_SPEED")..": "..tostring(v)
        end
    end
    refreshVisual()

    local dragging=false
    local function setFromX(x)
        local rel=(x - barBg.AbsolutePosition.X)/barBg.AbsoluteSize.X
        rel=math.clamp(rel,0,1)
        local val=math.floor(minVal + rel*(maxVal-minVal)+0.5)
        setVal(val)
        refreshVisual()
    end
    barBg.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            setFromX(inp.Position.X)
        end
    end)
    barBg.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    barBg.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            setFromX(inp.Position.X)
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
            refreshVisual()
        end
    end)
    return frame
end

function UI.create()
    local sg=Instance.new("ScreenGui")
    sg.Name="UU_Main"
    sg.ResetOnSpawn=false
    pcall(function() sg.Parent=(gethui and gethui()) or game:GetService("CoreGui") end)

    -- Botão mini (restaurar)
    local mini=Instance.new("TextButton")
    mini.Size=UDim2.new(0,44,0,44)
    mini.Position=UDim2.new(0,40,0,200)
    mini.BackgroundColor3=Color3.fromRGB(35,40,55)
    mini.TextColor3=Color3.new(1,1,1)
    mini.Font=Enum.Font.GothamBold
    mini.TextSize=20
    mini.Text=L("MINI_HANDLE")
    mini.Visible=false
    mini.Parent=sg
    UI.MiniButton=mini
    local miniTip=Instance.new("TextLabel")
    miniTip.BackgroundTransparency=1
    miniTip.Size=UDim2.new(1,0,0,14)
    miniTip.Position=UDim2.new(0,0,1,-14)
    miniTip.Font=Enum.Font.Code
    miniTip.TextSize=12
    miniTip.TextColor3=Color3.fromRGB(200,200,200)
    miniTip.Text=L("MINI_TIP")
    miniTip.Parent=mini
    UI.MiniTip=miniTip
    mark(mini,"MINI_HANDLE")
    mark(miniTip,"MINI_TIP")

    -- Janela principal
    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,720,0,360)
    frame.Position=UDim2.new(0.5,-360,0.45,-180)
    frame.BackgroundColor3=Color3.fromRGB(22,22,28)
    frame.Parent=sg
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,12)

    -- Top bar
    local top=Instance.new("Frame")
    top.Size=UDim2.new(1,0,0,42)
    top.BackgroundColor3=Color3.fromRGB(36,36,48)
    top.Parent=frame
    Instance.new("UICorner",top).CornerRadius=UDim.new(0,12)

    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Size=UDim2.new(1,-120,1,0)
    title.Position=UDim2.new(0,16,0,0)
    title.Font=Enum.Font.GothamBold
    title.TextSize=16
    title.TextColor3=Color3.new(1,1,1)
    title.Text=L("UI_TITLE",VERSION)
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=top
    UI.Title=title
    mark(title,"UI_TITLE",VERSION)

    local minimize=Instance.new("TextButton")
    minimize.Size=UDim2.new(0,36,0,28)
    minimize.Position=UDim2.new(1,-84,0.5,-14)
    minimize.Text=L("BTN_CLOSE")
    minimize.Font=Enum.Font.GothamBold
    minimize.TextSize=12
    minimize.BackgroundColor3=Color3.fromRGB(70,60,60)
    minimize.TextColor3=Color3.new(1,1,1)
    minimize.Parent=top
    Instance.new("UICorner",minimize).CornerRadius=UDim.new(0,6)
    mark(minimize,"BTN_CLOSE")

    local closeX=Instance.new("TextButton")
    closeX.Size=UDim2.new(0,36,0,28)
    closeX.Position=UDim2.new(1,-44,0.5,-14)
    closeX.Text="X"
    closeX.Font=Enum.Font.GothamBold
    closeX.TextSize=14
    closeX.BackgroundColor3=Color3.fromRGB(90,50,50)
    closeX.TextColor3=Color3.new(1,1,1)
    closeX.Parent=top
    Instance.new("UICorner",closeX).CornerRadius=UDim.new(0,6)

    -- Sidebar
    local sidebar=Instance.new("Frame")
    sidebar.Size=UDim2.new(0,180,1,-42)
    sidebar.Position=UDim2.new(0,0,0,42)
    sidebar.BackgroundColor3=Color3.fromRGB(30,30,38)
    sidebar.Parent=frame

    local sideList=Instance.new("UIListLayout",sidebar)
    sideList.SortOrder=Enum.SortOrder.LayoutOrder
    sideList.Padding=UDim.new(0,6)
    sideList.HorizontalAlignment=Enum.HorizontalAlignment.Center

    local function makeSide(nameKey)
        local btn=Instance.new("TextButton")
        btn.Size=UDim2.new(1,-12,0,34)
        btn.BackgroundColor3=Color3.fromRGB(46,46,56)
        btn.TextColor3=Color3.new(1,1,1)
        btn.Font=Enum.Font.Gotham
        btn.TextSize=14
        btn.Text=L(nameKey)
        btn.Parent=sidebar
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
        mark(btn,nameKey)
        return btn
    end

    local btnLang=makeSide("SIDEBAR_LANG")
    local btnFly=makeSide("SIDEBAR_FLY")
    local btnIY=makeSide("SIDEBAR_IY")
    local btnHelp=makeSide("SIDEBAR_HELP")

    -- Área de conteúdo
    local content=Instance.new("Frame")
    content.Size=UDim2.new(1,-180,1,-42)
    content.Position=UDim2.new(0,180,0,42)
    content.BackgroundColor3=Color3.fromRGB(26,26,34)
    content.Parent=frame

    -- Container para trocar painéis
    local panels={}
    local function newPanel(keyTitle)
        local p=Instance.new("Frame")
        p.Size=UDim2.new(1,-24,1,-24)
        p.Position=UDim2.new(0,12,0,12)
        p.BackgroundColor3=Color3.fromRGB(34,34,46)
        p.Visible=false
        p.Parent=content
        Instance.new("UICorner",p).CornerRadius=UDim.new(0,10)

        local header=Instance.new("TextLabel")
        header.BackgroundTransparency=1
        header.Size=UDim2.new(1,0,0,30)
        header.Font=Enum.Font.GothamBold
        header.TextSize=18
        header.TextColor3=Color3.new(1,1,1)
        header.TextXAlignment=Enum.TextXAlignment.Left
        header.Text=L(keyTitle)
        header.Parent=p
        mark(header,keyTitle)
        panels[#panels+1]=p
        return p
    end
    local panelLang=newPanel("PANEL_LANG_TITLE")
    local panelFly=newPanel("PANEL_FLY_TITLE")
    local panelIY=newPanel("PANEL_IY_TITLE")
    local panelHelp=newPanel("PANEL_HELP_TITLE")

    local function showPanel(p)
        for _,pp in ipairs(panels) do pp.Visible=(pp==p) end
        -- realçar botão selecionado
        local function setSel(button,sel)
            button.BackgroundColor3 = sel and Color3.fromRGB(70,70,100) or Color3.fromRGB(46,46,56)
        end
        setSel(btnLang, p==panelLang)
        setSel(btnFly, p==panelFly)
        setSel(btnIY, p==panelIY)
        setSel(btnHelp, p==panelHelp)
    end

    -- Conteúdo Panel Language
    do
        local openBtn=Instance.new("TextButton")
        openBtn.Size=UDim2.new(0,180,0,34)
        openBtn.Position=UDim2.new(0,10,0,40)
        styleButton(openBtn)
        openBtn.Text=L("BTN_OPEN_LANG_DIALOG")
        openBtn.Parent=panelLang
        mark(openBtn,"BTN_OPEN_LANG_DIALOG")
        openBtn.MouseButton1Click:Connect(function()
            buildLanguageDialog(function()
                UI.applyLanguage()
            end)
        end)

        local current=Instance.new("TextLabel")
        current.BackgroundTransparency=1
        current.Size=UDim2.new(1,-20,0,22)
        current.Position=UDim2.new(0,10,0,10)
        current.Font=Enum.Font.Gotham
        current.TextSize=14
        current.TextColor3=Color3.fromRGB(200,200,210)
        current.Text="LANG: "..(Lang.current and Lang.current:upper() or "??")
        current.TextXAlignment=Enum.TextXAlignment.Left
        current.Parent=panelLang
        UI.LangCurrent=current

        -- Atualiza quando aplicar idioma
        local oldApply=UI.applyLanguage
        UI.applyLanguage=function(...)
            if UI.LangCurrent then
                UI.LangCurrent.Text="LANG: "..(Lang.current and Lang.current:upper() or "??")
            end
            oldApply(...)
        end
    end

    -- Conteúdo Panel Fly
    do
        local toggle=Instance.new("TextButton")
        toggle.Size=UDim2.new(0,160,0,34)
        toggle.Position=UDim2.new(0,10,0,40)
        styleButton(toggle)
        toggle.Text = Fly.active and L("FLY_TOGGLE_ON") or L("FLY_TOGGLE_OFF")
        toggle.Parent=panelFly
        UI.FlyToggle=toggle

        mark(toggle,"FLY_TOGGLE_OFF") -- para garantir chave registrada

        toggle.MouseButton1Click:Connect(function()
            if Fly.active then Fly.disable() else Fly.enable() end
            UI.applyLanguage()
        end)

        local speedLabel=Instance.new("TextLabel")
        speedLabel.BackgroundTransparency=1
        speedLabel.Size=UDim2.new(1,-20,0,22)
        speedLabel.Position=UDim2.new(0,10,0,10)
        speedLabel.Font=Enum.Font.Gotham
        speedLabel.TextSize=14
        speedLabel.TextColor3=Color3.fromRGB(200,200,210)
        speedLabel.Text=L("FLY_SPEED")..": "..tostring(Fly.speed)
        speedLabel.TextXAlignment=Enum.TextXAlignment.Left
        speedLabel.Parent=panelFly
        UI.SpeedLabel=speedLabel
        mark(speedLabel,"FLY_SPEED")

        createSlider(panelFly,5,500,
            function() return Fly.speed end,
            function(v) Fly.setSpeed(v) end
        ).Position=UDim2.new(0,10,0,84)
    end

    -- Conteúdo Panel Infinite Yield
    do
        local status=Instance.new("TextLabel")
        status.BackgroundTransparency=1
        status.Size=UDim2.new(1,-20,0,24)
        status.Position=UDim2.new(0,10,0,10)
        status.Font=Enum.Font.Gotham
        status.TextSize=14
        status.TextColor3=Color3.fromRGB(200,200,210)
        status.Text=_G.__IY_LOADED and L("IY_STATUS_LOADED") or L("IY_STATUS_NOT_LOADED")
        status.TextXAlignment=Enum.TextXAlignment.Left
        status.Parent=panelIY
        UI.IYStatus=status
        mark(status,"IY_STATUS_NOT_LOADED") -- registra chave base

        local loadBtn=Instance.new("TextButton")
        loadBtn.Size=UDim2.new(0,160,0,34)
        loadBtn.Position=UDim2.new(0,10,0,44)
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
            local ok,err = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
            end)
            if ok then
                _G.__IY_LOADED=true
                notify("IY", L("IY_LOADED"))
            else
                notify("IY", L("IY_FAILED", tostring(err)))
            end
            UI.applyLanguage()
        end)
    end

    -- Conteúdo Panel Help
    do
        local txt=Instance.new("TextLabel")
        txt.BackgroundTransparency=1
        txt.Size=UDim2.new(1,-20,1,-20)
        txt.Position=UDim2.new(0,10,0,10)
        txt.Font=Enum.Font.Code
        txt.TextSize=14
        txt.TextColor3=Color3.fromRGB(220,220,230)
        txt.TextXAlignment=Enum.TextXAlignment.Left
        txt.TextYAlignment=Enum.TextYAlignment.Top
        txt.TextWrapped=false
        txt.Text=L("HELP_DESC")
        txt.Parent=panelHelp
        txt.RichText=false
        txt.TextScaled=false
        txt.LineHeight=1.05
        txt.TextTruncate=Enum.TextTruncate.None
        mark(txt,"HELP_DESC")
    end

    -- Ações sidebar
    btnLang.MouseButton1Click:Connect(function() showPanel(panelLang) end)
    btnFly.MouseButton1Click:Connect(function() showPanel(panelFly) end)
    btnIY.MouseButton1Click:Connect(function() showPanel(panelIY) end)
    btnHelp.MouseButton1Click:Connect(function() showPanel(panelHelp) end)
    showPanel(panelFly) -- painel inicial

    -- Drag da janela
    local dragging=false
    local dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
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
            update(i)
        end
    end)

    minimize.MouseButton1Click:Connect(function()
        frame.Visible=false
        mini.Visible=true
        mini.Position=frame.Position
    end)
    closeX.MouseButton1Click:Connect(function()
        frame.Visible=false
        mini.Visible=true
        mini.Position=frame.Position
    end)
    mini.MouseButton1Click:Connect(function()
        frame.Visible=true
        mini.Visible=false
    end)

    UI.Screen=sg
    UI.Frame=frame
end

----------------------------------------------------------------
-- Inicialização
----------------------------------------------------------------
ensureLanguage(function()
    UI.create()
    UI.applyLanguage()
    notify("Universal Utility", L("LOADED", VERSION), 4)
end)

-- Flush periódico
task.spawn(function()
    while true do
        Persist.flush(false)
        task.wait(0.5)
    end
end)

return { VERSION=VERSION, Persist=Persist, Lang=Lang, UI=UI, Logger=Logger, Fly=Fly }
