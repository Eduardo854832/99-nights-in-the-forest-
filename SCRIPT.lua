local VERSION = "0.8.1-mobile"

-- ==== Serviços ====
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local StarterGui         = game:GetService("StarterGui")
local Stats              = game:GetService("Stats")
local Lighting           = game:GetService("Lighting")
local HttpService        = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local baseIsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ==== Persistência ====
local Persist = {}
Persist._fileName = "UniversalUtilityConfig.json"
Persist._data, Persist._dirty, Persist._lastWrite = {}, false, 0
Persist._flushInterval = 0.5
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
function Persist.exportConfig() Persist.flush(true); return HttpService:JSONEncode(Persist._data) end
function Persist.importConfig(json)
    local ok,decoded = pcall(function() return HttpService:JSONDecode(json) end)
    if ok and type(decoded)=="table" then
        for k,v in pairs(decoded) do Persist._data[k]=v end
        Persist.saveSoon(); Persist.flush(true); return true
    end
    return false
end
Persist.load()

-- ==== Logger ====
local Logger = { _max=150, _lines={}, _dirty=false }
function Logger.Log(level,msg)
    local line = os.date("%H:%M:%S").." ["..level.."] "..tostring(msg)
    table.insert(Logger._lines,line)
    if #Logger._lines>Logger._max then table.remove(Logger._lines,1) end
    Logger._dirty=true
    warn("[UU]["..level.."] "..msg)
end
function Logger.Export()
    local blob=table.concat(Logger._lines,"\n")
    if setclipboard then setclipboard(blob) end
    return blob
end
local function LOG(m) Logger.Log("INFO",m) end

-- ==== Internacionalização ====
local Lang = {}
Lang.data = {
    pt = {
        UI_TITLE="Universal Utility v%s",
        PANEL_GENERAL="Geral", PANEL_MOVEMENT="Movimento", PANEL_CAMERA="Câmera",
        PANEL_STATS="Stats", PANEL_EXTRAS="Extras", PANEL_FLY="Fly",
        PANEL_DEBUG="Depuração", PANEL_LANG_MISSING="Traduções Faltantes",
        PANEL_KEYBINDS="Keybinds", PANEL_PROFILES="Perfis", PANEL_THEME="Tema",
        SECTION_TOUCH="Atalhos Mobile", SECTION_LOGGER="Logger",
        LABEL_VERSION="Versão", LABEL_FS="Executor FS", LABEL_DEVICE="Dispositivo",
        LABEL_STARTED="Iniciado", LABEL_FPS="FPS", LABEL_MEM="Mem",
        LABEL_PING="Ping", LABEL_PLAYERS="Jogadores", LABEL_POS_ATUAL="Pos Atual",
        BTN_RESPAWN="Respawn", BTN_RESET_FOV="Reset FOV", BTN_INFO="Info",
        BTN_OVERLAY_RESET="Reset Overlay", BTN_SAVE_POS="Salvar Posição",
        BTN_CLEAR_POS="Limpar Todas", BTN_COPY_POS="Copiar Pos Atual",
        BTN_SHOW_HIDE="[F4] Mostrar/Ocultar", BTN_FLY_SPEEDMODE="Veloc+",
        TOGGLE_REAPPLY="Reaplicar em respawn", TOGGLE_SHIFTLOCK="Shift-Lock (PC)",
        TOGGLE_SMOOTH="Câmera Suave", TOGGLE_OVERLAY="Mostrar Overlay",
        TOGGLE_NOCLIP="Noclip", TOGGLE_WORLD_TIME="Hora Custom",
        TOGGLE_THEME_LIGHT="Tema Claro", TOGGLE_THEME_DARK="Tema Escuro",
        SLIDER_WALKSPEED="WalkSpeed", SLIDER_JUMPPOWER="JumpPower",
        SLIDER_FOV="FOV", SLIDER_CAM_SENS="Sensibilidade",
        SLIDER_OVERLAY_INTERVAL="Intervalo Overlay", SLIDER_WORLD_TIME="Hora",
        NOTIFY_INFO="Use os painéis para ajustes.", NOTIFY_FOV_RESET="FOV redefinido",
        NOTIFY_POS_LIMIT="Limite atingido.", NOTIFY_NO_ROOT="Sem HumanoidRootPart",
        NOTIFY_POS_COPIED="Copiado.", NOTIFY_POS_SAVED="Salvo.",
        NOTIFY_LOADED="Carregado v%s", LANG_CHANGED="Idioma alterado.",
        LOGGER_EXPORTED="Logger exportado.", PROFILE_SAVED="Perfil %d salvo.",
        PROFILE_LOADED="Perfil %d carregado.", PROFILE_INVALID="Perfil inválido.",
        THEME_APPLIED="Tema aplicado.", KEYBIND_SET="Keybind %s => %s",
        KEYBIND_WAIT="Pressione tecla...", KEYBIND_CANCEL="Cancelado.",
        HELP_TITLE="Comandos: theme/profile/keybind/sprint/debug/panic/export/import/help",
        MINI_HANDLE="≡", MINI_TIP="Arraste/Clique", MISSING_NONE="Nenhuma chave faltando",
        PANIC_DONE="Panic executado.", LEGACY_FLY_NOTE="Modo Fly (moderno c/ fallback).",
        DIAG_MESSAGE="Diag v%s | FPS:%d Mem:%dKB Ping:%d Jog:%d Sprint:%s Fly:%s Noclip:%s Overlay:%s",
    },
    en = {
        UI_TITLE="Universal Utility v%s",
        PANEL_GENERAL="General", PANEL_MOVEMENT="Movement", PANEL_CAMERA="Camera",
        PANEL_STATS="Stats", PANEL_EXTRAS="Extras", PANEL_FLY="Fly",
        PANEL_DEBUG="Debug", PANEL_LANG_MISSING="Missing Keys",
        PANEL_KEYBINDS="Keybinds", PANEL_PROFILES="Profiles", PANEL_THEME="Theme",
        SECTION_TOUCH="Mobile Shortcuts", SECTION_LOGGER="Logger",
        LABEL_VERSION="Version", LABEL_FS="FS Support", LABEL_DEVICE="Device",
        LABEL_STARTED="Started", LABEL_FPS="FPS", LABEL_MEM="Mem",
        LABEL_PING="Ping", LABEL_PLAYERS="Players", LABEL_POS_ATUAL="Current Pos",
        BTN_RESPAWN="Respawn", BTN_RESET_FOV="Reset FOV", BTN_INFO="Info",
        BTN_OVERLAY_RESET="Reset Overlay", BTN_SAVE_POS="Save Position",
        BTN_CLEAR_POS="Clear All", BTN_COPY_POS="Copy Position",
        BTN_SHOW_HIDE="[F4] Show/Hide", BTN_FLY_SPEEDMODE="Speed+",
        TOGGLE_REAPPLY="Reapply on respawn", TOGGLE_SHIFTLOCK="Shift-Lock (PC)",
        TOGGLE_SMOOTH="Smooth Cam", TOGGLE_OVERLAY="Show Overlay",
        TOGGLE_NOCLIP="Noclip", TOGGLE_WORLD_TIME="Custom Time",
        TOGGLE_THEME_LIGHT="Light Theme", TOGGLE_THEME_DARK="Dark Theme",
        SLIDER_WALKSPEED="WalkSpeed", SLIDER_JUMPPOWER="JumpPower",
        SLIDER_FOV="FOV", SLIDER_CAM_SENS="Sensitivity",
        SLIDER_OVERLAY_INTERVAL="Overlay Interval", SLIDER_WORLD_TIME="Clock Time",
        NOTIFY_INFO="Use panels to adjust.", NOTIFY_FOV_RESET="FOV reset",
        NOTIFY_POS_LIMIT="Limit reached.", NOTIFY_NO_ROOT="No HumanoidRootPart",
        NOTIFY_POS_COPIED="Copied.", NOTIFY_POS_SAVED="Saved.",
        NOTIFY_LOADED="Loaded v%s", LANG_CHANGED="Language changed.",
        LOGGER_EXPORTED="Logger exported.", PROFILE_SAVED="Profile %d saved.",
        PROFILE_LOADED="Profile %d loaded.", PROFILE_INVALID="Invalid profile.",
        THEME_APPLIED="Theme applied.", KEYBIND_SET="Keybind %s => %s",
        KEYBIND_WAIT="Press a key...", KEYBIND_CANCEL="Canceled.",
        HELP_TITLE="Commands: theme/profile/keybind/sprint/debug/panic/export/import/help",
        MINI_HANDLE="≡", MINI_TIP="Drag/Click", MISSING_NONE="No missing keys",
        PANIC_DONE="Panic executed.", LEGACY_FLY_NOTE="Fly mode (modern with fallback).",
        DIAG_MESSAGE="Diag v%s | FPS:%d Mem:%dKB Ping:%d Ply:%d Sprint:%s Fly:%s Noclip:%s Overlay:%s",
    }
}
Lang.current = Persist.get("lang", nil)
Lang.alwaysPrompt = true
Lang._sessionSelected = false
local _missingLogged = {}
local function L(k,...)
    local pack=Lang.data[Lang.current or "pt"]
    local s=(pack and pack[k]) or k
    if s==k and not _missingLogged[k] then _missingLogged[k]=true; Logger.Log("I18N","Missing key: "..k) end
    if select("#",...)>0 then return string.format(s,...) end
    return s
end

local function buildLanguageDialog(onChosen)
    local sg=Instance.new("ScreenGui")
    sg.Name="LangSelect"
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
    title.Size=UDim2.new(1,0,0,50)
    title.Font=Enum.Font.GothamBold
    title.TextColor3=Color3.new(1,1,1)
    title.TextSize=20
    title.Text="Selecione o Idioma / Select Language"
    title.Parent=frame
    local info=Instance.new("TextLabel")
    info.BackgroundTransparency=1
    info.Size=UDim2.new(1,-20,0,30)
    info.Position=UDim2.new(0,10,0,50)
    info.Font=Enum.Font.Gotham
    info.TextColor3=Color3.fromRGB(200,200,200)
    info.TextSize=14
    info.TextWrapped=true
    info.Text=(Lang.current and ("Atual: "..Lang.current:upper().."\nClique para trocar.")) or "Escolha um idioma."
    info.Parent=frame
    local function mk(txt,x,lang)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0.5,-30,0,50)
        b.Position=UDim2.new(x,20,0,90)
        b.BackgroundColor3=Color3.fromRGB(40,60,90)
        b.TextColor3=Color3.new(1,1,1)
        b.TextSize=18
        b.Font=Enum.Font.GothamBold
        b.Text=txt
        b.Parent=frame
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,12)
        b.MouseButton1Click:Connect(function()
            Lang.current=lang
            Persist.set("lang",lang)
            Lang._sessionSelected=true
            sg:Destroy()
            if onChosen then onChosen() end
        end)
    end
    mk("Português",0,"pt")
    mk("English",0.5,"en")
end
local function ensureLanguage(cb)
    if not Lang.alwaysPrompt and Lang.current then cb() return end
    buildLanguageDialog(function() cb() end)
end

-- ==== Helpers ====
local function notify(t,x,d) pcall(function() StarterGui:SetCore("SendNotification",{Title=t,Text=x,Duration=d or 3}) end) end
local function safe(fn,...) local ok,r=pcall(fn,...) if not ok then Logger.Log("ERR",r) end return ok,r end
local Util={}
function Util.getHumanoid() local c=LocalPlayer.Character; return c and c:FindFirstChildWhichIsA("Humanoid") end
function Util.getRoot() local c=LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end
function Util.draggable(frame,handle,onDrop)
    handle=handle or frame
    local dragging=false; local dragStart,startPos
    local function update(i)
        local delta=i.Position-dragStart
        frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=i.Position; startPos=frame.Position
            i.Changed:Connect(function(s)
                if s==Enum.UserInputState.End and dragging then dragging=false; if onDrop then safe(onDrop,frame.Position) end end
            end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            update(i)
        end
    end)
end

-- ==== Core / API ====
local Core={}
Core._lazyPanels={}
Core._commands={}
Core._keybinds={}
Core._keybindActions={}
Core._metricsObservers={}
Core._tpHistory=Persist.get("tp_history",{})
Core._state={
    version=VERSION, started=os.clock(), theme=Persist.get("ui_theme","dark"),
    autoSprint=Persist.get("sprint_enabled",false),
    sprintHolding=Persist.get("sprint_hold_mode",true),
    sprintHoldTime=Persist.get("sprint_hold_time",0.5),
    sprintBonus=Persist.get("sprint_bonus",8),
    overlayVisible=Persist.get("overlay_visible",true),
}
Core._connections={}
function Core.Bind(n,c) if Core._connections[n] then pcall(function() Core._connections[n]:Disconnect() end) end Core._connections[n]=c end
function Core.UnbindAll() for _,c in pairs(Core._connections) do pcall(function() c:Disconnect() end) end Core._connections={} end
function Core.API_RegisterCommand(n,d,fn) Core._commands[n]={fn=fn,desc=d} end
function Core.API_RegisterKeybind(n,def,cb) if not Core._keybinds[n] then Core._keybinds[n]=Persist.get("kb_"..n,def.Name); Core._keybindActions[n]=cb end end
function Core.API_RegisterLazyPanel(k,b) Core._lazyPanels[k]={built=false,builder=b} end
function Core.API_AddMetricsObserver(fn) table.insert(Core._metricsObservers,fn) end
function Core.API_GetState() return Core._state end
function Core.API_Log(m) Logger.Log("API",m) end
function Core.API_PanicAll()
    Core._state.autoSprint=false; Persist.setIfChanged("sprint_enabled",false)
    Core._state.overlayVisible=false; Persist.setIfChanged("overlay_visible",false)
    if Core._noclipDisable then Core._noclipDisable() end
    if Core._customTimeDisable then Core._customTimeDisable() end
    if Core._flyDisable then Core._flyDisable() end
    Core.UnbindAll()
    Logger.Log("PANIC","All features disabled")
    if UI._perfOverlay then UI._perfOverlay.Visible=false end
    notify("PANIC", L("PANIC_DONE"))
end
Core.API={
    RegisterCommand=Core.API_RegisterCommand, RegisterKeybind=Core.API_RegisterKeybind,
    RegisterLazyPanel=Core.API_RegisterLazyPanel, AddMetricsObserver=Core.API_AddMetricsObserver,
    GetState=Core.API_GetState, Log=Core.API_Log, PanicAll=Core.API_PanicAll
}

-- ==== Keybinds ====
local KeybindManager={list={menuToggle="F4",flyToggle="G",panic="P",overlayToggle="O"}}
for k,v in pairs(KeybindManager.list) do local sv=Persist.get("kb_"..k,nil); if sv then KeybindManager.list[k]=sv end end
function KeybindManager.set(n,c) KeybindManager.list[n]=c; Persist.setIfChanged("kb_"..n,c) end
function KeybindManager.match(i)
    if i.UserInputType~=Enum.UserInputType.Keyboard then return end
    local name=i.KeyCode.Name
    for k,code in pairs(KeybindManager.list) do
        if code==name then local cb=Core._keybindActions[k]; if cb then safe(cb) end end
    end
end
UserInputService.InputBegan:Connect(function(i,gp) if gp then return end KeybindManager.match(i) end)

-- ==== Layout Dinâmico (Responsivo) ====
local function computeLayout()
    local cam=workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280,720)
    local mobile = baseIsMobile or vp.X < 900 or vp.Y < 500
    local w = mobile and math.min(math.floor(vp.X*0.92), 480) or 1080
    local h = mobile and math.min(math.floor(vp.Y*0.60), 430) or 480
    local sb = mobile and math.floor(w*0.34) or 230
    return w,h,sb,mobile
end
local WINDOW_WIDTH, WINDOW_HEIGHT, SIDEBAR_WIDTH, CURRENT_MOBILE = computeLayout()

-- ==== Themes ====
local Themes={
    dark={bg=Color3.fromRGB(18,18,21),header=Color3.fromRGB(26,26,30),panel=Color3.fromRGB(34,34,38),
          accent=Color3.fromRGB(50,56,66),text=Color3.fromRGB(235,235,245),textDim=Color3.fromRGB(170,175,185),
          highlight=Color3.fromRGB(90,150,255),sidebar=Color3.fromRGB(30,30,34),navSel=Color3.fromRGB(55,70,95),
          navBorder=Color3.fromRGB(90,150,255)},
    light={bg=Color3.fromRGB(235,238,245),header=Color3.fromRGB(215,220,230),panel=Color3.fromRGB(225,228,235),
           accent=Color3.fromRGB(180,190,205),text=Color3.fromRGB(35,40,50),textDim=Color3.fromRGB(60,70,85),
           highlight=Color3.fromRGB(40,120,230),sidebar=Color3.fromRGB(215,220,230),navSel=Color3.fromRGB(195,205,220),
           navBorder=Color3.fromRGB(40,120,230)}
}
local ThemeRegistry={}
Themes._current=Themes.dark
function Themes.apply(name)
    local t=Themes[name] or Themes.dark
    Themes._current=t
    for _,it in ipairs(ThemeRegistry) do
        if it.prop and it.instance and t[it.prop] then pcall(function() it.instance[it.field or "BackgroundColor3"]=t[it.prop] end) end
    end
    Core._state.theme=name
    Persist.setIfChanged("ui_theme",name)
    if UI and UI._refreshNavColors then UI._refreshNavColors() end
    notify("Theme", L("THEME_APPLIED"))
end
function Themes.register(inst,prop,field) table.insert(ThemeRegistry,{instance=inst,prop=prop,field=field}) end

-- ==== UI ====
local UI={}
UI._translatables={}
UI._panelButtons={}
UI._panelContainers={}
UI._panelOrder = {
    "PANEL_GENERAL","PANEL_MOVEMENT","PANEL_CAMERA","PANEL_STATS",
    "PANEL_PROFILES","PANEL_KEYBINDS","PANEL_THEME",
    "PANEL_EXTRAS","PANEL_FLY","PANEL_DEBUG","PANEL_LANG_MISSING"
}
UI.Screen,UI.RootFrame,UI.Container=nil,nil,nil
UI.MiniButton=nil; UI.MiniTip=nil
UI._menuVisible=true
UI.TitleLabel=nil
UI.SideBar=nil
UI.ContentScroll=nil
UI._currentPanel=nil

local function mark(inst,key,...) table.insert(UI._translatables,{instance=inst,key=key,args={...}}) end

function UI.applyLanguage()
    for _,d in ipairs(UI._translatables) do
        local inst=d.instance
        if inst and inst.Parent and (inst:IsA("TextLabel") or inst:IsA("TextButton")) then
            inst.Text = (d.args and #d.args>0) and L(d.key, table.unpack(d.args)) or L(d.key)
        end
    end
    if UI.TitleLabel then UI.TitleLabel.Text=L("UI_TITLE",VERSION) end
    if UI.MiniButton then UI.MiniButton.Text=L("MINI_HANDLE") end
    if UI.MiniTip then UI.MiniTip.Text=L("MINI_TIP") end
    for k,btn in pairs(UI._panelButtons) do
        if btn and btn:FindFirstChild("TextLabel") then
            btn.TextLabel.Text=L(k)
        end
    end
end

local function saveMenuPos(pos)
    Persist.setIfChanged("ui_menu_pos",{sx=pos.X.Scale,x=pos.X.Offset,sy=pos.Y.Scale,y=pos.Y.Offset})
end
local function loadMenuPos(def)
    local d=Persist.get("ui_menu_pos",nil)
    if d then return UDim2.new(d.sx or 0,d.x or 0,d.sy or 0,d.y or 0) end
    return def
end

function UI.toggleMenu()
    if not UI.RootFrame or not UI.MiniButton then return end
    UI._menuVisible=not UI._menuVisible
    UI.RootFrame.Visible=UI._menuVisible
    UI.MiniButton.Visible=not UI._menuVisible
end
Core.API_RegisterKeybind("menuToggle", Enum.KeyCode.F4, UI.toggleMenu)

function UI.ShowLangDialog() buildLanguageDialog(function() UI.applyLanguage(); Themes.apply(Core._state.theme or "dark"); notify("Lang", L("LANG_CHANGED")) end) end

function UI._refreshNavColors()
    local t=Themes._current
    for k,btn in pairs(UI._panelButtons) do
        local selected = (UI._currentPanel==k)
        local bg = selected and t.navSel or t.sidebar
        local borderColor = selected and t.navBorder or t.sidebar
        if btn then
            btn.BackgroundColor3=bg
            local border=btn:FindFirstChild("SelBorder")
            if border then border.BackgroundColor3=borderColor; border.Visible=selected end
            if btn.TextLabel then
                btn.TextLabel.TextColor3 = selected and t.text or t.textDim
            end
        end
    end
end

function UI.selectPanel(key)
    if UI._currentPanel==key then return end
    UI._currentPanel=key
    for k,frame in pairs(UI._panelContainers) do
        if frame then frame.Visible=(k==key) end
    end
    if Core._lazyPanels[key] and not Core._lazyPanels[key].built then
        Core._lazyPanels[key].built=true
        safe(Core._lazyPanels[key].builder, UI._panelContainers[key])
        UI.applyLanguage()
    end
    UI._refreshNavColors()
end

local NAV_BTN_HEIGHT_DESKTOP = 42
local NAV_BTN_HEIGHT_MOBILE = 34

function UI._createNavButton(parent,key)
    local t=Themes._current
    local holder=Instance.new("TextButton")
    holder.Name=key
    holder.Size=UDim2.new(1,0,0,CURRENT_MOBILE and NAV_BTN_HEIGHT_MOBILE or NAV_BTN_HEIGHT_DESKTOP)
    holder.BackgroundColor3=t.sidebar
    holder.BorderSizePixel=0
    holder.AutoButtonColor=false
    holder.Text=""
    holder.Parent=parent
    Themes.register(holder,"sidebar")
    local border=Instance.new("Frame")
    border.Name="SelBorder"
    border.Size=UDim2.new(0,4,1,0)
    border.Position=UDim2.new(0,0,0,0)
    border.BackgroundColor3=t.navBorder
    border.Visible=false
    border.Parent=holder
    local lab=Instance.new("TextLabel")
    lab.Name="TextLabel"
    lab.BackgroundTransparency=1
    lab.Size=UDim2.new(1,-14,1,0)
    lab.Position=UDim2.new(0,12,0,0)
    lab.Font=Enum.Font.GothamBold
    lab.TextSize= CURRENT_MOBILE and 12 or 13
    lab.TextXAlignment=Enum.TextXAlignment.Left
    lab.TextColor3=t.textDim
    lab.Text=L(key)
    lab.Parent=holder
    Themes.register(lab,"textDim","TextColor3")
    mark(lab,key)
    holder.MouseButton1Click:Connect(function() UI.selectPanel(key) end)
    UI._panelButtons[key]=holder
end

-- Ajuste (re)layout em mudança de tamanho da tela
function UI._recomputeAndApplyLayout()
    local w,h,sb,mob = computeLayout()
    WINDOW_WIDTH, WINDOW_HEIGHT, SIDEBAR_WIDTH, CURRENT_MOBILE = w,h,sb,mob
    if UI.RootFrame then
        UI.RootFrame.Size=UDim2.new(0,w,0,h)
        if UI.SideBar then
            UI.SideBar.Parent.Size=UDim2.new(0,SB_WIDTH,1,-48)
        end
    end
end

local function clampFrameOnScreen(frame)
    if not frame then return end
    local cam=workspace.CurrentCamera
    if not cam then return end
    local vp=cam.ViewportSize
    local pos=frame.Position
    local size=frame.Size
    local x=math.clamp(pos.X.Offset, -size.X.Offset+40, vp.X-40)
    local y=math.clamp(pos.Y.Offset, 0, vp.Y-40)
    frame.Position=UDim2.new(pos.X.Scale,x,pos.Y.Scale,y)
end

function UI.createRoot()
    local screen=Instance.new("ScreenGui")
    screen.Name="UU_Main"
    screen.ResetOnSpawn=false
    pcall(function() screen.Parent=(gethui and gethui()) or game:GetService("CoreGui") end)

    local mini=Instance.new("TextButton")
    mini.Size=UDim2.new(0,46,0,46)
    mini.BackgroundColor3=Themes._current.header
    mini.TextColor3=Color3.new(1,1,1)
    mini.Font=Enum.Font.GothamBold
    mini.TextSize=20
    mini.Text=L("MINI_HANDLE")
    mini.Visible=false
    mini.Parent=screen
    Instance.new("UICorner",mini).CornerRadius=UDim.new(0,10)
    Themes.register(mini,"header")
    local miniTip=Instance.new("TextLabel")
    miniTip.BackgroundTransparency=1
    miniTip.Size=UDim2.new(1,0,0,14)
    miniTip.Position=UDim2.new(0,0,1,-14)
    miniTip.Font=Enum.Font.Code
    miniTip.TextSize=12
    miniTip.TextColor3=Themes._current.textDim
    miniTip.Text=L("MINI_TIP")
    miniTip.Parent=mini
    Themes.register(miniTip,"textDim","TextColor3")

    local root=Instance.new("Frame")
    root.Name="Window"
    root.Size=UDim2.new(0,WINDOW_WIDTH,0,WINDOW_HEIGHT)
    root.Position=loadMenuPos(UDim2.new(0.5,-WINDOW_WIDTH/2,0.35,-WINDOW_HEIGHT/2))
    root.BackgroundColor3=Themes._current.bg
    root.BorderSizePixel=0
    root.Parent=screen
    Instance.new("UICorner",root).CornerRadius=UDim.new(0,10)
    Themes.register(root,"bg")

    local top=Instance.new("Frame")
    top.Size=UDim2.new(1,0,0, (CURRENT_MOBILE and 42 or 48))
    top.BackgroundColor3=Themes._current.header
    top.Parent=root
    Instance.new("UICorner",top).CornerRadius=UDim.new(0,10)
    Themes.register(top,"header")

    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Size=UDim2.new(1,-160,1,0)
    title.Position=UDim2.new(0,20,0,0)
    title.Font=Enum.Font.GothamBold
    title.TextColor3=Themes._current.text
    title.TextSize= CURRENT_MOBILE and 14 or 15
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.Text=L("UI_TITLE", VERSION)
    title.Parent=top
    Themes.register(title,"text","TextColor3")
    UI.TitleLabel=title

    local function mkTopBtn(txt,offset)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0, (CURRENT_MOBILE and 30 or 34), 0, (CURRENT_MOBILE and 30 or 34))
        b.Position=UDim2.new(1, -(offset+(CURRENT_MOBILE and 34 or 44)), 0.5, -(CURRENT_MOBILE and 15 or 17))
        b.BackgroundColor3=Themes._current.accent
        b.Text=txt
        b.TextColor3=Color3.new(1,1,1)
        b.TextSize= CURRENT_MOBILE and 16 or 20
        b.Font=Enum.Font.GothamBold
        b.Parent=top
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
        Themes.register(b,"accent")
        return b
    end
    local close=mkTopBtn("X",10)
    local minimize=mkTopBtn("-",50)

    -- Sidebar
    local sidebar=Instance.new("Frame")
    sidebar.Name="Sidebar"
    sidebar.Size=UDim2.new(0,SIDEBAR_WIDTH,1,-(CURRENT_MOBILE and 42 or 48))
    sidebar.Position=UDim2.new(0,0,0, (CURRENT_MOBILE and 42 or 48))
    sidebar.BackgroundColor3=Themes._current.sidebar
    sidebar.Parent=root
    Themes.register(sidebar,"sidebar")

    local sideScroll=Instance.new("ScrollingFrame")
    sideScroll.Size=UDim2.new(1,0,1,0)
    sideScroll.CanvasSize=UDim2.new(0,0,0,0)
    sideScroll.ScrollBarThickness=4
    sideScroll.BackgroundTransparency=1
    sideScroll.Parent=sidebar
    local sideLayout=Instance.new("UIListLayout",sideScroll)
    sideLayout.SortOrder=Enum.SortOrder.LayoutOrder
    sideLayout.Padding=UDim.new(0,6)
    sideLayout.Changed:Connect(function(p)
        if p=="AbsoluteContentSize" then
            sideScroll.CanvasSize=UDim2.new(0,0,0,sideLayout.AbsoluteContentSize.Y+10)
        end
    end)

    -- Content Area
    local content=Instance.new("Frame")
    content.Name="ContentArea"
    content.Size=UDim2.new(1,-SIDEBAR_WIDTH-(CURRENT_MOBILE and 10 or 16),1,-(CURRENT_MOBILE and 42 or 48)- (CURRENT_MOBILE and 10 or 16))
    content.Position=UDim2.new(0,SIDEBAR_WIDTH+(CURRENT_MOBILE and 6 or 12),0,(CURRENT_MOBILE and (42+6) or 60))
    content.BackgroundColor3=Themes._current.panel
    content.Parent=root
    Themes.register(content,"panel")
    Instance.new("UICorner",content).CornerRadius=UDim.new(0,10)

    local contentScroll=Instance.new("ScrollingFrame")
    contentScroll.Name="PanelScroll"
    contentScroll.Size=UDim2.new(1,-(CURRENT_MOBILE and 14 or 24),1,-(CURRENT_MOBILE and 14 or 24))
    contentScroll.Position=UDim2.new(0,(CURRENT_MOBILE and 7 or 12),0,(CURRENT_MOBILE and 7 or 12))
    contentScroll.BackgroundTransparency=1
    contentScroll.ScrollBarThickness=6
    contentScroll.CanvasSize=UDim2.new(0,0,0,0)
    contentScroll.Parent=content
    local contentLayout=Instance.new("UIListLayout",contentScroll)
    contentLayout.SortOrder=Enum.SortOrder.LayoutOrder
    contentLayout.Padding=UDim.new(0,10)
    contentLayout.Changed:Connect(function(p)
        if p=="AbsoluteContentSize" then
            contentScroll.CanvasSize=UDim2.new(0,0,0,contentLayout.AbsoluteContentSize.Y+20)
        end
    end)

    Util.draggable(root, top, function(pos)
        saveMenuPos(pos)
        clampFrameOnScreen(root)
        if not root.Visible then mini.Position=pos; saveMenuPos(mini.Position) end
    end)
    Util.draggable(mini, mini, function(pos) saveMenuPos(pos); clampFrameOnScreen(mini) end)

    minimize.MouseButton1Click:Connect(function()
        root.Visible=false
        mini.Visible=true
        mini.Position=root.Position
        saveMenuPos(mini.Position)
    end)
    close.MouseButton1Click:Connect(function()
        root.Visible=false
        mini.Visible=true
        mini.Position=root.Position
        saveMenuPos(mini.Position)
    end)
    mini.MouseButton1Click:Connect(function()
        root.Position=mini.Position
        root.Visible=true
        mini.Visible=false
        saveMenuPos(root.Position)
    end)

    for _,key in ipairs(UI._panelOrder) do
        UI._createNavButton(sideScroll,key)
        local panelFrame=Instance.new("Frame")
        panelFrame.Name=key
        panelFrame.BackgroundTransparency=1
        panelFrame.Size=UDim2.new(1,0,0,0)
        panelFrame.AutomaticSize=Enum.AutomaticSize.Y
        panelFrame.Visible=false
        panelFrame.Parent=contentScroll
        local layout=Instance.new("UIListLayout",panelFrame)
        layout.SortOrder=Enum.SortOrder.LayoutOrder
        layout.Padding=UDim.new(0,6)
        UI._panelContainers[key]=panelFrame
    end

    UI.Screen=screen
    UI.RootFrame=root
    UI.Container=contentScroll
    UI.MiniButton=mini
    UI.MiniTip=miniTip
    UI.SideBar=sideScroll
    UI.ContentScroll=contentScroll

    task.defer(function()
        UI.selectPanel(UI._panelOrder[1])
    end)

    -- Ajuste quando mudar Viewport (responsivo)
    local function connectViewportWatcher()
        local cam=workspace.CurrentCamera
        if not cam then return end
        Core.Bind("ViewportResize", cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            local w,h,sb,mob=computeLayout()
            WINDOW_WIDTH,WINDOW_HEIGHT,SIDEBAR_WIDTH,CURRENT_MOBILE = w,h,sb,mob
            root.Size=UDim2.new(0,w,0,h)
            clampFrameOnScreen(root)
        end))
    end
    if workspace.CurrentCamera then connectViewportWatcher() end
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.wait()
        connectViewportWatcher()
    end)
end

-- Componentes reutilizados
local function UI_Label(parent,text,isKey)
    local lbl=Instance.new("TextLabel")
    lbl.BackgroundTransparency=1
    lbl.Size=UDim2.new(1,0,0,(CURRENT_MOBILE and 18 or 20))
    lbl.Font=Enum.Font.Code
    lbl.TextSize= CURRENT_MOBILE and 13 or 14
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextColor3=Themes._current.textDim
    lbl.Text=isKey and L(text) or text
    lbl.Parent=parent
    if isKey then mark(lbl,text) end
    Themes.register(lbl,"textDim","TextColor3")
    return lbl
end
local function UI_Button(parent,label,isKey,cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,0,(CURRENT_MOBILE and 30 or 34))
    b.BackgroundColor3=Themes._current.accent
    b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold
    b.TextSize= CURRENT_MOBILE and 12 or 13
    b.Text=isKey and L(label) or label
    b.Parent=parent
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    if isKey then mark(b,label) end
    Themes.register(b,"accent")
    b.MouseButton1Click:Connect(function() safe(cb) end)
    return b
end
local function UI_Toggle(parent,labelKey,persistKey,default,callback)
    local holder=Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,(CURRENT_MOBILE and 30 or 34))
    holder.BackgroundTransparency=1
    holder.Parent=parent
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,60,1,0)
    btn.BackgroundColor3=Themes._current.accent
    btn.TextColor3=Color3.new(1,1,1)
    btn.Font=Enum.Font.GothamBold
    btn.TextSize=12
    btn.Text="OFF"
    btn.Parent=holder
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6)
    Themes.register(btn,"accent")
    local lbl=Instance.new("TextLabel")
    lbl.BackgroundTransparency=1
    lbl.Position=UDim2.new(0,68,0,0)
    lbl.Size=UDim2.new(1,-70,1,0)
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize= CURRENT_MOBILE and 13 or 14
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextColor3=Themes._current.text
    lbl.Text=L(labelKey)
    lbl.Parent=holder
    mark(lbl,labelKey)
    Themes.register(lbl,"text","TextColor3")
    local state=Persist.get(persistKey,default)
    local function apply(fire)
        btn.Text=state and "ON" or "OFF"
        if fire then safe(callback,state) end
        Persist.setIfChanged(persistKey,state)
    end
    btn.MouseButton1Click:Connect(function() state=not state; apply(true) end)
    apply(true)
    return function(v) state=v; apply(true) end
end
local function UI_Slider(parent,labelKey,persistKey,minVal,maxVal,defaultVal,step,callback)
    step=step or 1
    local holder=Instance.new("Frame")
    holder.Size=UDim2.new(1,0,0,(CURRENT_MOBILE and 50 or 56))
    holder.BackgroundTransparency=1
    holder.Parent=parent
    local value=Persist.get(persistKey,defaultVal)
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,0,0,20)
    lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize= CURRENT_MOBILE and 12 or 13
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextColor3=Themes._current.text
    lbl.Text=L(labelKey)..": "..tostring(value)
    lbl.Parent=holder
    mark(lbl,labelKey)
    Themes.register(lbl,"text","TextColor3")
    local bar=Instance.new("Frame")
    bar.Size=UDim2.new(1,-8,0,10)
    bar.Position=UDim2.new(0,4,0, (CURRENT_MOBILE and 26 or 30))
    bar.BackgroundColor3=Themes._current.accent
    bar.Parent=holder
    Instance.new("UICorner",bar).CornerRadius=UDim.new(0,5)
    Themes.register(bar,"accent")
    local fill=Instance.new("Frame")
    fill.Size=UDim2.new((value-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3=Themes._current.highlight
    fill.Parent=bar
    Instance.new("UICorner",fill).CornerRadius=UDim.new(0,5)
    Themes.register(fill,"highlight")
    local dragging=false
    local function applyValue(v,fire)
        fill.Size=UDim2.new((v-minVal)/(maxVal-minVal),0,1,0)
        lbl.Text=L(labelKey)..": "..tostring(v)
        Persist.setIfChanged(persistKey,v)
        if fire then safe(callback,v) end
    end
    local function setFromX(x,fire)
        local rel=math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        local raw=minVal+(maxVal-minVal)*rel
        local snap=minVal+math.floor((raw-minVal)/step+0.5)*step
        snap=math.clamp(snap,minVal,maxVal)
        value=snap
        applyValue(value,fire)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            setFromX(i.Position.X,true)
        end
    end)
    bar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
    bar.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            setFromX(i.Position.X,true)
        end
    end)
    safe(callback,value)
    return function(v,fire) v=math.clamp(v,minVal,maxVal); applyValue(v,fire) end
end

-- ==== Métricas ====
local metricsState={fps=0,lastFrames=0,lastTick=tick(),mem=0,ping=0,players=0}
RunService.RenderStepped:Connect(function()
    metricsState.lastFrames+=1
    local now=tick()
    local interval = Persist.get("overlay_interval",1)
    if now-metricsState.lastTick>=interval then
        metricsState.fps=metricsState.lastFrames/ (now-metricsState.lastTick)
        metricsState.lastFrames=0
        metricsState.lastTick=now
        metricsState.mem=gcinfo()
        local ps=Stats.Network.ServerStatsItem["Data Ping"]
        metricsState.ping=ps and ps:GetValue() or -1
        metricsState.players=#Players:GetPlayers()
        for _,obs in ipairs(Core._metricsObservers) do safe(obs,metricsState) end
        if UI._perfOverlay and Core._state.overlayVisible then
            UI._perfOverlay.Text=string.format("%s: %d\n%s: %d KB\n%s: %d ms\n%s: %d",
                L("LABEL_FPS"),metricsState.fps,L("LABEL_MEM"),metricsState.mem,L("LABEL_PING"),metricsState.ping,L("LABEL_PLAYERS"),metricsState.players)
        end
    end
end)

-- ==== Sprint ====
local Sprint={}
Sprint.isActive=false; Sprint._accHold=0; Sprint._holding=false; Sprint._baseWalkSpeed=nil; Sprint._lastApplied=nil
function Sprint.setActive(on)
    if Sprint.isActive==on then return end
    Sprint.isActive=on
    Persist.setIfChanged("sprint_enabled",on)
    if not on then
        local hum=Util.getHumanoid()
        if hum and Sprint._baseWalkSpeed and hum.WalkSpeed~=Sprint._baseWalkSpeed then pcall(function() hum.WalkSpeed=Sprint._baseWalkSpeed end) end
        Sprint._lastApplied=nil
    end
end
function Sprint.apply()
    local hum=Util.getHumanoid(); if not hum then return end
    if not Sprint._baseWalkSpeed then Sprint._baseWalkSpeed=Persist.get("walkspeed_value",hum.WalkSpeed) end
    if Sprint.isActive then
        local tgt=Sprint._baseWalkSpeed + Core._state.sprintBonus
        if Sprint._lastApplied~=tgt then pcall(function() hum.WalkSpeed=tgt end); Sprint._lastApplied=tgt end
    end
end
UserInputService.InputBegan:Connect(function(i,gp) if gp then return end if i.KeyCode==Enum.KeyCode.LeftShift then Sprint._holding=true; Sprint._accHold=0 end end)
UserInputService.InputEnded:Connect(function(i) if i.KeyCode==Enum.KeyCode.LeftShift then Sprint._holding=false; if Core._state.sprintHolding then Sprint.setActive(false); Sprint.apply() end end end)
RunService.Heartbeat:Connect(function(dt)
    if Core._state.autoSprint then
        if Core._state.sprintHolding then
            if Sprint._holding then
                Sprint._accHold+=dt
                if not Sprint.isActive and Sprint._accHold>=Core._state.sprintHoldTime then Sprint.setActive(true) end
            end
        else
            Sprint.setActive(true)
        end
    elseif Sprint.isActive then
        Sprint.setActive(false)
    end
    Sprint.apply()
end)

-- ==== Profiles ==== (corrigido array truncado)
local Profiles={}
local profileKeys={
    "walkspeed_value","jumppower_value","camera_fov","camera_sens","camera_shiftlock",
    "camera_smooth","overlay_visible","sprint_enabled","sprint_bonus","sprint_hold_time",
    "sprint_hold_mode","ui_theme","overlay_interval"
}
function Profiles.save(i)
    if i<1 or i>3 then return false end
    local data={}
    for _,k in ipairs(profileKeys) do data[k]=Persist.get(k,nil) end
    Persist.set("profile_"..i,data); Persist.flush(true)
    notify("Profile", L("PROFILE_SAVED", i)); return true
end
function Profiles.load(i)
    if i<1 or i>3 then return false end
    local data=Persist.get("profile_"..i,nil)
    if not data then notify("Profile",L("PROFILE_INVALID")) return false end
    for k,v in pairs(data) do Persist.set(k,v) end
    Sprint.setActive(Persist.get("sprint_enabled",false))
    Core._state.autoSprint=Persist.get("sprint_enabled",false)
    Core._state.sprintBonus=Persist.get("sprint_bonus",8)
    Core._state.sprintHoldTime=Persist.get("sprint_hold_time",0.5)
    Core._state.sprintHolding=Persist.get("sprint_hold_mode",true)
    notify("Profile", L("PROFILE_LOADED", i)); return true
end

-- ==== TP History ====
function Core.addTPHistory(pos)
    table.insert(Core._tpHistory,1,{x=pos.X,y=pos.Y,z=pos.Z,t=os.time()})
    while #Core._tpHistory>5 do table.remove(Core._tpHistory) end
    Persist.set("tp_history",Core._tpHistory)
end

-- ==== Commands ====
local function parseCommand(msg)
    if not msg:lower():match("^/uu%s") then return end
    local body=msg:sub(5)
    local args={}
    for tk in body:gmatch("%S+") do table.insert(args,tk) end
    local cmd=table.remove(args,1)
    if not cmd then notify("UU",L("HELP_TITLE")) return end
    local c=Core._commands[cmd:lower()]
    if c then safe(c.fn,args) else notify("UU","?") end
end
LocalPlayer.Chatted:Connect(parseCommand)

Core.API_RegisterCommand("help","Show help",function()
    local list={}
    for k,_ in pairs(Core._commands) do table.insert(list,k) end
    table.sort(list)
    notify("UU", L("HELP_TITLE"))
    Logger.Log("CMD","Help => "..table.concat(list,", "))
end)
Core.API_RegisterCommand("panic","Disable features quickly",Core.API_PanicAll)
Core.API_RegisterCommand("export","Export config",function()
    local blob=Persist.exportConfig(); if setclipboard then setclipboard(blob) end
    notify("UU","Exported config.")
end)
Core.API_RegisterCommand("import","Import config",function() notify("UU","Persist.importConfig(json)") end)
Core.API_RegisterCommand("theme","Change theme",function(a)
    local t=a[1]; if t and Themes[t] then Themes.apply(t) else notify("Theme","dark/light?") end
end)
Core.API_RegisterCommand("profile","/uu profile save|load <n>",function(a)
    local act=a[1]; local idx=tonumber(a[2] or "")
    if not idx then notify("Profile","n?") return end
    if act=="save" then Profiles.save(idx) elseif act=="load" then Profiles.load(idx) else notify("Profile","save|load") end
end)
Core.API_RegisterCommand("keybind","/uu keybind <name> <key>",function(a)
    local name=a[1]; local key=a[2]
    if not name then
        local l={}; for k,v in pairs(KeybindManager.list) do table.insert(l,k.."="..v) end
        notify("Keybinds", table.concat(l,", "))
        return
    end
    if not Core._keybindActions[name] then notify("Keybinds","Invalid") return end
    if not key then
        notify("Keybinds", L("KEYBIND_WAIT"))
        local conn; conn=UserInputService.InputBegan:Connect(function(i,gp)
            if gp then return end
            if i.UserInputType==Enum.UserInputType.Keyboard then
                KeybindManager.set(name,i.KeyCode.Name)
                notify("Keybinds", L("KEYBIND_SET", name, i.KeyCode.Name))
                conn:Disconnect()
            elseif i.UserInputType==Enum.UserInputType.MouseButton2 then
                notify("Keybinds", L("KEYBIND_CANCEL")); conn:Disconnect()
            end
        end)
        return
    end
    KeybindManager.set(name,key)
    notify("Keybinds", L("KEYBIND_SET", name, key))
end)
Core.API_RegisterCommand("sprint","/uu sprint on|off hold|toggle bonus <n> holdtime <n>",function(a)
    if #a==0 then notify("Sprint", Core._state.autoSprint and "ON" or "OFF") return end
    local i=1
    while i<=#a do
        local v=a[i]
        if v=="on" then Core._state.autoSprint=true; Persist.setIfChanged("sprint_enabled",true)
        elseif v=="off" then Core._state.autoSprint=false; Persist.setIfChanged("sprint_enabled",false); Sprint.setActive(false)
        elseif v=="hold" then Core._state.sprintHolding=true; Persist.setIfChanged("sprint_hold_mode",true)
        elseif v=="toggle" then Core._state.sprintHolding=false; Persist.setIfChanged("sprint_hold_mode",false)
        elseif v=="bonus" then local n=tonumber(a[i+1]); if n then Core._state.sprintBonus=n; Persist.setIfChanged("sprint_bonus",n); i=i+1 end
        elseif v=="holdtime" then local n=tonumber(a[i+1]); if n then Core._state.sprintHoldTime=n; Persist.setIfChanged("sprint_hold_time",n); i=i+1 end
        end
        i=i+1
    end
    notify("Sprint", Core._state.autoSprint and "ON" or "OFF")
end)
Core.API_RegisterCommand("debug","Open logger panel",function()
    UI.selectPanel("PANEL_DEBUG")
end)
Core.API_RegisterCommand("diag","Show internal diagnostics",function()
    local s=Core._state
    local msg=string.format(L("DIAG_MESSAGE"), VERSION, metricsState.fps, metricsState.mem, metricsState.ping,
        metricsState.players, s.autoSprint and "Y" or "N", Core._flyActive and "Y" or "N",
        Core._noclipActive and "Y" or "N", s.overlayVisible and "Y" or "N")
    notify("Diag",msg,5)
    Logger.Log("DIAG",msg)
end)
Core.API_RegisterCommand("lang","Open language selection",function() UI.ShowLangDialog() end)

Core.API_RegisterKeybind("panic", Enum.KeyCode.P, Core.API_PanicAll)
Core.API_RegisterKeybind("overlayToggle", Enum.KeyCode.O, function()
    Core._state.overlayVisible=not Core._state.overlayVisible
    Persist.setIfChanged("overlay_visible",Core._state.overlayVisible)
    if UI._perfOverlay then UI._perfOverlay.Visible=Core._state.overlayVisible end
end)

-- ==== Painéis ====
Core.API_RegisterLazyPanel("PANEL_GENERAL", function(panel)
    UI_Label(panel,string.format("%s: %s", L("LABEL_VERSION"), VERSION),false)
    UI_Label(panel,string.format("%s: %s", L("LABEL_FS"), tostring(hasFS)),false)
    UI_Label(panel,string.format("%s: %s", L("LABEL_DEVICE"), (baseIsMobile and "Mobile" or "PC")),false)
    UI_Label(panel,string.format("%s: %s", L("LABEL_STARTED"), os.date("%H:%M:%S")),false)
    if baseIsMobile then
        UI_Label(panel,"SECTION_TOUCH",true)
        UI_Button(panel,"BTN_RESPAWN",true,function() local h=Util.getHumanoid(); if h then h.Health=0 end end)
        UI_Button(panel,"BTN_RESET_FOV",true,function()
            local cam=workspace.CurrentCamera
            if cam then cam.FieldOfView=70; Persist.setIfChanged("camera_fov",70); notify("FOV",L("NOTIFY_FOV_RESET")) end
        end)
        UI_Button(panel,"BTN_INFO",true,function() notify("Info", L("NOTIFY_INFO")) end)
    end
end)
Core.API_RegisterLazyPanel("PANEL_MOVEMENT", function(panel)
    local hum=Util.getHumanoid()
    UI_Slider(panel,"SLIDER_WALKSPEED","walkspeed_value",4,64, hum and hum.WalkSpeed or 16,1,function(v)
        local h=Util.getHumanoid(); if h then pcall(function() h.WalkSpeed=v end) end
        Sprint._baseWalkSpeed=v
    end)
    UI_Slider(panel,"SLIDER_JUMPPOWER","jumppower_value",25,150, hum and hum.JumpPower or 50,1,function(v)
        local h=Util.getHumanoid(); if h and h.UseJumpPower~=false then pcall(function() h.JumpPower=v end) end
    end)
    UI_Toggle(panel,"TOGGLE_REAPPLY","auto_reapply_stats",true,function(on)
        if on then
            if not Core._autoApplyStatsConn then
                Core._autoApplyStatsConn=LocalPlayer.CharacterAdded:Connect(function()
                    task.wait(0.35)
                    local h=Util.getHumanoid()
                    if h then
                        pcall(function()
                            h.WalkSpeed=Persist.get("walkspeed_value",16)
                            if h.UseJumpPower~=false then h.JumpPower=Persist.get("jumppower_value",50) end
                        end)
                        Sprint._baseWalkSpeed=h.WalkSpeed
                    end
                end)
            end
        else
            if Core._autoApplyStatsConn then Core._autoApplyStatsConn:Disconnect(); Core._autoApplyStatsConn=nil end
        end
    end)
end)
Core.API_RegisterLazyPanel("PANEL_CAMERA", function(panel)
    UI_Slider(panel,"SLIDER_FOV","camera_fov",30,130, workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70,1,function(v)
        local cam=workspace.CurrentCamera; if cam then cam.FieldOfView=v end
    end)
    UI_Toggle(panel,"TOGGLE_SHIFTLOCK","camera_shiftlock",Persist.get("camera_shiftlock", false),function(on) Persist.setIfChanged("camera_shiftlock",on) end)
    UI_Toggle(panel,"TOGGLE_SMOOTH","camera_smooth",Persist.get("camera_smooth", false),function(on) Persist.setIfChanged("camera_smooth",on) end)
    UI_Slider(panel,"SLIDER_CAM_SENS","camera_sens",0.2,3,Persist.get("camera_sens",1),0.1,function(v) Persist.setIfChanged("camera_sens",v) end)
    if not Core._cameraInit then
        Core._cameraInit=true
        workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            task.defer(function()
                local cam=workspace.CurrentCamera
                if cam then cam.FieldOfView=math.clamp(Persist.get("camera_fov",70),30,130) end
            end)
        end)
        RunService.RenderStepped:Connect(function()
            local cam=workspace.CurrentCamera; if not cam then return end
            if Persist.get("camera_shiftlock",false) and not baseIsMobile then
                if UserInputService.MouseBehavior~=Enum.MouseBehavior.LockCenter then UserInputService.MouseBehavior=Enum.MouseBehavior.LockCenter end
            else
                if not baseIsMobile and UserInputService.MouseBehavior==Enum.MouseBehavior.LockCenter then
                    UserInputService.MouseBehavior=Enum.MouseBehavior.Default
                end
            end
        end)
    end
end)
Core.API_RegisterLazyPanel("PANEL_STATS", function(panel)
    local l1=UI_Label(panel,L("LABEL_FPS")..": ...",false)
    local l2=UI_Label(panel,L("LABEL_MEM")..": ... KB",false)
    local l3=UI_Label(panel,L("LABEL_PING")..": ... ms",false)
    local l4=UI_Label(panel,L("LABEL_PLAYERS")..": ...",false)
    Core.API_AddMetricsObserver(function(m)
        l1.Text=L("LABEL_FPS")..": "..math.floor(m.fps+0.5)
        l2.Text=L("LABEL_MEM")..": "..m.mem.." KB"
        l3.Text=L("LABEL_PING")..": "..m.ping.." ms"
        l4.Text=L("LABEL_PLAYERS")..": "..m.players
    end)
end)
Core.API_RegisterLazyPanel("PANEL_EXTRAS", function(panel)
    UI_Toggle(panel,"TOGGLE_OVERLAY","overlay_visible",Core._state.overlayVisible,function(on)
        Core._state.overlayVisible=on
        if UI._perfOverlay then UI._perfOverlay.Visible=on end
    end)
    UI_Slider(panel,"SLIDER_OVERLAY_INTERVAL","overlay_interval",0.2,5,Persist.get("overlay_interval",1),0.1,function(v)
        Persist.setIfChanged("overlay_interval",v)
    end)
    UI_Button(panel,"BTN_OVERLAY_RESET",true,function()
        if UI._perfOverlay then
            UI._perfOverlay.Position=UDim2.new(1,-210,0,10)
            Persist.set("overlay_pos",{sx=1,x=-210,sy=0,y=10})
        end
    end)
end)
Core.API_RegisterLazyPanel("PANEL_FLY", function(panel)
    UI_Label(panel,"LEGACY_FLY_NOTE",true)
    UI_Button(panel,"BTN_FLY_SPEEDMODE",true,function()
        notify("Fly","Speed+ (placeholder)")
    end)
end)
Core.API_RegisterLazyPanel("PANEL_PROFILES", function(panel)
    for i=1,3 do
        UI_Button(panel,"Profile "..i.." Save",false,function() Profiles.save(i) end)
        UI_Button(panel,"Profile "..i.." Load",false,function() Profiles.load(i) end)
    end
end)
Core.API_RegisterLazyPanel("PANEL_THEME", function(panel)
    UI_Button(panel,"Dark",false,function() Themes.apply("dark") end)
    UI_Button(panel,"Light",false,function() Themes.apply("light") end)
end)
Core.API_RegisterLazyPanel("PANEL_KEYBINDS", function(panel)
    for n,c in pairs(KeybindManager.list) do UI_Label(panel,n..": "..c,false) end
    UI_Button(panel,"Edit Keybind",false,function() notify("Keybinds","/uu keybind <name>") end)
end)
Core.API_RegisterLazyPanel("PANEL_DEBUG", function(panel)
    UI_Label(panel,"SECTION_LOGGER",true)
    local box=Instance.new("TextLabel")
    box.Size=UDim2.new(1,0,0,(CURRENT_MOBILE and 120 or 160))
    box.BackgroundColor3=Themes._current.panel
    box.Font=Enum.Font.Code
    box.TextSize=13
    box.TextXAlignment=Enum.TextXAlignment.Left
    box.TextYAlignment=Enum.TextYAlignment.Top
    box.Text=table.concat(Logger._lines,"\n")
    box.Parent=panel
    box.ClipsDescendants=true
    Themes.register(box,"panel")
    Core.Bind("LoggerUpdate", RunService.Heartbeat:Connect(function()
        if Logger._dirty then Logger._dirty=false; box.Text=table.concat(Logger._lines,"\n") end
    end))
    UI_Button(panel,"Export Logs",false,function()
        Logger.Export()
        notify("Logger", L("LOGGER_EXPORTED"))
    end)
end)
Core.API_RegisterLazyPanel("PANEL_LANG_MISSING", function(panel)
    local used={}
    for _,t in ipairs(UI._translatables) do used[t.key]=true end
    local missing={}
    for k,_ in pairs(used) do
        if not Lang.data[Lang.current][k] then table.insert(missing,k) end
    end
    if #missing==0 then
        UI_Label(panel,"MISSING_NONE",true)
    else
        table.sort(missing)
        for _,k in ipairs(missing) do UI_Label(panel,k,false) end
    end
end)

-- ==== Overlay ====
local function buildPerfOverlay()
    local sg=Instance.new("ScreenGui")
    sg.Name="UU_Overlay"
    sg.ResetOnSpawn=false
    pcall(function() sg.Parent=(gethui and gethui()) or game:GetService("CoreGui") end)
    local box=Instance.new("TextLabel")
    box.Size=UDim2.new(0,(CURRENT_MOBILE and 160 or 200),0,(CURRENT_MOBILE and 70 or 90))
    box.Position=UDim2.new(1,-210,0,10)
    box.BackgroundColor3=Themes._current.header
    box.TextColor3=Themes._current.text
    box.Font=Enum.Font.Code
    box.TextSize=13
    box.TextXAlignment=Enum.TextXAlignment.Left
    box.TextYAlignment=Enum.TextYAlignment.Top
    box.Text="..."
    box.Parent=sg
    Util.draggable(box,box,function(pos)
        Persist.set("overlay_pos",{sx=pos.X.Scale,x=pos.X.Offset,sy=pos.Y.Scale,y=pos.Y.Offset})
    end)
    Themes.register(box,"header","BackgroundColor3")
    Themes.register(box,"text","TextColor3")
    local op=Persist.get("overlay_pos",nil)
    if op then box.Position=UDim2.new(op.sx or 1,op.x or -210,op.sy or 0,op.y or 10) end
    box.Visible=Core._state.overlayVisible
    UI._perfOverlay=box
end

-- ==== Inicialização ====
ensureLanguage(function()
    UI.createRoot()
    buildPerfOverlay()
    Themes.apply(Core._state.theme or "dark")
    UI.applyLanguage()
    notify("Universal Utility", L("NOTIFY_LOADED", VERSION), 4)
end)

task.spawn(function()
    while true do
        Persist.flush(false)
        task.wait(0.2)
    end
end)

return { Core=Core, UI=UI, Util=Util, Persist=Persist, Lang=Lang, Themes=Themes, Logger=Logger }
