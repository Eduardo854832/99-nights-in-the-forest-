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

    -- Coluna esquerda
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

    local function makePanelButton(key)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(1,-scale(16),0,scale(34))
        b.BackgroundColor3=COLORS.BTN
        b.TextColor3=Color3.new(1,1,1)
        b.Font=Enum.Font.Gotham
        b.TextSize=CONFIG.FONT_MAIN_SIZE
        b.Text=L(key)
        b.Parent=left
        styleButton(b,{activeIndicator=function()
            return UI.PanelButtons[b] == UI.CurrentPanel
        end})
        markTrans(b,key)
        return b
    end

    local right = Instance.new("Frame")
    right.Size=UDim2.new(1,-scale(132),1,0)
    right.Position=UDim2.new(0,scale(132),0,0)
    right.BackgroundColor3=COLORS.BG_RIGHT
    right.Parent=content
    Instance.new("UICorner",right).CornerRadius=UDim.new(0,10)

    local function newPanel()
        local p=Instance.new("Frame")
        p.Size=UDim2.new(1,0,1,0)
        p.BackgroundTransparency=1
        p.Visible=false
        p.Parent=right
        table.insert(UI.Panels,p)
        return p
    end

    local panelFly = newPanel()
    local panelSpeed = newPanel()
    local panelIY = newPanel()

    -- Botões de painel
    local btnFly   = makePanelButton("PANEL_FLY");   UI.PanelButtons[btnFly] = panelFly
    local btnSpeed = makePanelButton("PANEL_SPEED"); UI.PanelButtons[btnSpeed] = panelSpeed
    local btnIY    = makePanelButton("PANEL_IY");    UI.PanelButtons[btnIY] = panelIY

    -- Conteúdo Fly
    do
        local toggle = Instance.new("TextButton")
        toggle.Size=UDim2.new(0,scale(140),0,scale(42))
        toggle.Position=UDim2.new(0,scale(20),0,scale(20))
        toggle.BackgroundColor3=COLORS.BTN
        toggle.TextColor3=Color3.new(1,1,1)
        toggle.Font=Enum.Font.GothamBold
        toggle.TextSize=CONFIG.FONT_MAIN_SIZE
        toggle.Text=Fly.active and L("FLY_TOGGLE_ON") or L("FLY_TOGGLE_OFF")
        toggle.Parent=panelFly
        styleButton(toggle)
        UI.Elements.FlyToggle = toggle
        toggle.MouseButton1Click:Connect(function()
            Fly.toggle()
            UI.applyLanguage()
        end)

        local modeBtn = Instance.new("TextButton")
        modeBtn.Size=UDim2.new(0,scale(140),0,scale(38))
        modeBtn.Position=UDim2.new(0,scale(20),0,scale(70))
        modeBtn.BackgroundColor3=COLORS.BTN
        modeBtn.TextColor3=Color3.new(1,1,1)
        modeBtn.Font=Enum.Font.Gotham
        modeBtn.TextSize=CONFIG.FONT_LABEL_SIZE+1
        modeBtn.Text = Fly.full3D and L("FLY_MODE_3D_ON") or L("FLY_MODE_3D_OFF")
        modeBtn.Parent=panelFly
        UI.Elements.ModeButton = modeBtn
        styleButton(modeBtn)
        modeBtn.MouseButton1Click:Connect(function()
            Fly.setMode(not Fly.full3D)
            UI.applyLanguage()
        end)
    end

    -- Conteúdo Speed
    do
        local speedLabel=Instance.new("TextLabel")
        speedLabel.BackgroundTransparency=1
        speedLabel.Size=UDim2.new(0,scale(250),0,scale(24))
        speedLabel.Position=UDim2.new(0,scale(20),0,scale(20))
        speedLabel.Font=Enum.Font.Gotham
        speedLabel.TextSize=CONFIG.FONT_LABEL_SIZE+1
        speedLabel.TextColor3=COLORS.TEXT_DIM
        speedLabel.Text=L("FLY_SPEED")..": "..Fly.speed
        speedLabel.TextXAlignment=Enum.TextXAlignment.Left
        speedLabel.Parent=panelSpeed
        UI.Elements.SpeedLabel = speedLabel
        markTrans(speedLabel,"FLY_SPEED")

        local sliderHolder = Instance.new("Frame")
        sliderHolder.Size=UDim2.new(0,scale(320),0,scale(70))
        sliderHolder.Position=UDim2.new(0,scale(20),0,scale(56))
        sliderHolder.BackgroundTransparency=1
        sliderHolder.Parent=panelSpeed

        createSlider(sliderHolder, CONFIG.FLY_MIN_SPEED, CONFIG.FLY_MAX_SPEED,
            function() return Fly.speed end,
            function(v) Fly.setSpeed(v) end)
    end

    -- Conteúdo IY
    do
        local status=Instance.new("TextLabel")
        status.BackgroundTransparency=1
        status.Size=UDim2.new(0,scale(220),0,scale(24))
        status.Position=UDim2.new(0,scale(20),0,scale(20))
        status.Font=Enum.Font.Gotham
        status.TextSize=CONFIG.FONT_LABEL_SIZE+1
        status.TextColor3=COLORS.TEXT_DIM
        status.Text=_G.__UH_IY_LOADED and "IY: ON" or "IY: OFF"
        status.TextXAlignment=Enum.TextXAlignment.Left
        status.Parent=panelIY
        UI.Elements.IYStatus = status

        local loadBtn=Instance.new("TextButton")
        loadBtn.Size=UDim2.new(0,scale(160),0,scale(44))
        loadBtn.Position=UDim2.new(0,scale(20),0,scale(56))
        loadBtn.Text=L("BTN_IY_LOAD")
        loadBtn.Font=Enum.Font.GothamBold
        loadBtn.TextSize=CONFIG.FONT_MAIN_SIZE
        loadBtn.TextColor3=Color3.new(1,1,1)
        loadBtn.BackgroundColor3=COLORS.BTN
        styleButton(loadBtn)
        loadBtn.Parent=panelIY
        markTrans(loadBtn,"BTN_IY_LOAD")

        local loading=false
        loadBtn.MouseButton1Click:Connect(function()
            if loading then return end
            if _G.__UH_IY_LOADED then
                notify("IY", L("IY_ALREADY"))
                return
            end
            loading=true
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
        end)
    end

    -- Inicial selecionado
    showPanel(panelFly)
    highlightPanelButton(btnFly)

    btnFly.MouseButton1Click:Connect(function()
        showPanel(panelFly)
        highlightPanelButton(btnFly)
    end)
    btnSpeed.MouseButton1Click:Connect(function()
        showPanel(panelSpeed)
        highlightPanelButton(btnSpeed)
    end)
    btnIY.MouseButton1Click:Connect(function()
        showPanel(panelIY)
        highlightPanelButton(btnIY)
    end)

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
    elseif input.KeyCode == CONFIG.HOTKEY_TOGGLE_FLY then
        Fly.toggle()
        if UI.Elements.FlyToggle then
            UI.Elements.FlyToggle.Text = Fly.active and L("FLY_TOGGLE_ON") or L("FLY_TOGGLE_OFF")
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
UI.createFloatingButton()

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
}