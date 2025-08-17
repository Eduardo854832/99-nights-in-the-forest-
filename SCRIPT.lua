local VERSION = "0.9.1-min-fly"

-- Serviços básicos
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------
-- Persistência mínima (idioma + velocidade de voo)
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
-- Logger mínimo
----------------------------------------------------------------
local Logger = { _max=120, _lines={}, _dirty=false }
function Logger.Log(level,msg)
    local line = os.date("%H:%M:%S").." ["..level.."] "..tostring(msg)
    table.insert(Logger._lines,line)
    if #Logger._lines>Logger._max then table.remove(Logger._lines,1) end
    warn("[UU]["..level.."] "..tostring(msg))
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
    }
}
Lang.current = Persist.get("lang", nil)
local _missingLogged = {}
local function L(k,...)
    local pack=Lang.data[Lang.current or "pt"]
    local s=(pack and pack[k]) or k
    if s==k and not _missingLogged[k] then
        _missingLogged[k]=true
        Logger.Log("I18N","Missing key: "..k)
    end
    if select("#",...)>0 then
        return string.format(s,...)
    end
    return s
end

----------------------------------------------------------------
-- Util simples
----------------------------------------------------------------
local function notify(t,x,d) pcall(function() StarterGui:SetCore("SendNotification",{Title=t,Text=x,Duration=d or 3}) end) end

----------------------------------------------------------------
-- Diálogo de idioma
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
    if Lang.current then
        cb()
    else
        buildLanguageDialog(cb)
    end
end

----------------------------------------------------------------
-- UI mínima
----------------------------------------------------------------
local UI={}
UI._translatables={}
local function mark(inst,key,...) table.insert(UI._translatables,{instance=inst,key=key,args={...}}) end

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
end

function UI.create()
    local sg=Instance.new("ScreenGui")
    sg.Name="UU_Min"
    sg.ResetOnSpawn=false
    pcall(function() sg.Parent=(gethui and gethui()) or game:GetService("CoreGui") end)

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

    local frame=Instance.new("Frame")
    frame.Size=UDim2.new(0,420,0,240)
    frame.Position=UDim2.new(0.5,-210,0.4,-120)
    frame.BackgroundColor3=Color3.fromRGB(25,25,32)
    frame.Parent=sg
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,12)

    local top=Instance.new("Frame")
    top.Size=UDim2.new(1,0,0,46)
    top.BackgroundColor3=Color3.fromRGB(40,40,52)
    top.Parent=frame
    Instance.new("UICorner",top).CornerRadius=UDim.new(0,12)

    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Position=UDim2.new(0,16,0,0)
    title.Size=UDim2.new(1,-32,1,0)
    title.Font=Enum.Font.GothamBold
    title.TextSize=16
    title.TextColor3=Color3.new(1,1,1)
    title.Text=L("UI_TITLE", VERSION)
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Parent=top
    UI.Title=title
    mark(title,"UI_TITLE",VERSION)

    local close=Instance.new("TextButton")
    close.Size=UDim2.new(0,34,0,34)
    close.Position=UDim2.new(1,-44,0.5,-17)
    close.BackgroundColor3=Color3.fromRGB(75,40,40)
    close.Font=Enum.Font.GothamBold
    close.TextSize=18
    close.TextColor3=Color3.new(1,1,1)
    close.Text="X"
    close.Parent=top
    Instance.new("UICorner",close).CornerRadius=UDim.new(0,8)

    local container=Instance.new("Frame")
    container.BackgroundTransparency=1
    container.Position=UDim2.new(0,14,0,58)
    container.Size=UDim2.new(1,-28,1,-72)
    container.Parent=frame

    local list=Instance.new("UIListLayout",container)
    list.SortOrder=Enum.SortOrder.LayoutOrder
    list.Padding=UDim.new(0,8)

    local langBtn=Instance.new("TextButton")
    langBtn.Size=UDim2.new(1,0,0,40)
    langBtn.BackgroundColor3=Color3.fromRGB(55,70,110)
    langBtn.TextColor3=Color3.new(1,1,1)
    langBtn.Font=Enum.Font.GothamBold
    langBtn.TextSize=14
    langBtn.Text=L("BTN_LANG_SELECT")
    langBtn.Parent=container
    Instance.new("UICorner",langBtn).CornerRadius=UDim.new(0,8)
    mark(langBtn,"BTN_LANG_SELECT")
    langBtn.MouseButton1Click:Connect(function()
        buildLanguageDialog(function()
            UI.applyLanguage()
            if UI.MissingRefresh then UI.MissingRefresh() end
        end)
    end)

    local missingTitle=Instance.new("TextLabel")
    missingTitle.BackgroundTransparency=1
    missingTitle.Size=UDim2.new(1,0,0,20)
    missingTitle.Font=Enum.Font.GothamBold
    missingTitle.TextSize=14
    missingTitle.TextXAlignment=Enum.TextXAlignment.Left
    missingTitle.TextColor3=Color3.fromRGB(230,230,240)
    missingTitle.Text=L("PANEL_MISSING")
    missingTitle.Parent=container
    mark(missingTitle,"PANEL_MISSING")

    local missingBox=Instance.new("TextLabel")
    missingBox.BackgroundColor3=Color3.fromRGB(32,32,42)
    missingBox.Size=UDim2.new(1,0,1,-(40+20+16))
    missingBox.Font=Enum.Font.Code
    missingBox.TextSize=13
    missingBox.TextColor3=Color3.fromRGB(220,220,230)
    missingBox.TextXAlignment=Enum.TextXAlignment.Left
    missingBox.TextYAlignment=Enum.TextYAlignment.Top
    missingBox.TextWrapped=false
    missingBox.ClipsDescendants=true
    missingBox.Text="..."
    missingBox.Parent=container
    Instance.new("UICorner",missingBox).CornerRadius=UDim.new(0,8)

    local function refreshMissing()
        local used={}
        for _,t in ipairs(UI._translatables) do used[t.key]=true end
        local missing={}
        local pack=Lang.data[Lang.current or "pt"] or {}
        for k,_ in pairs(used) do
            if not pack[k] then table.insert(missing,k) end
        end
        if #missing==0 then
            missingBox.Text=L("MISSING_NONE")
            mark(missingBox,"MISSING_NONE")
        else
            table.sort(missing)
            missingBox.Text=table.concat(missing,"\n")
        end
    end

    refreshMissing()

    -- Drag
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

    close.MouseButton1Click:Connect(function()
        frame.Visible=false
        mini.Visible=true
        mini.Position=frame.Position
    end)
    mini.MouseButton1Click:Connect(function()
        frame.Visible=true
        mini.Visible=false
        frame.Position=mini.Position
    end)

    UI.Screen=sg
    UI.Frame=frame
    UI.MissingRefresh=refreshMissing
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
        local r=getRoot()
        if not r then return end
        local cam=workspace.CurrentCamera
        if not cam then return end
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
-- Comandos
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
        notify("UU","?")
    end
end
LocalPlayer.Chatted:Connect(parseChat)

register("help","Show help",function()
    notify("UU", L("HELP_TITLE"))
end)

register("lang","Open language selector",function()
    buildLanguageDialog(function()
        UI.applyLanguage()
        if UI.MissingRefresh then UI.MissingRefresh() end
    end)
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