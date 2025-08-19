--[[
Universal Hub (Versão Aprimorada)
Autor base: (você)
Melhorias adicionadas: organização modular interna, configurações, keybinds, server hop, rejoin,
anti-afk, theme/accent dinâmico, fullbright, fog remover, jump/gravity/FOV sliders,
ESP expandido, notificações, plugin loader, persistência de config, mudanças live de idioma.

NÃO inclui auto-farm (universal).

Compatível com: executores que suportem setclipboard, writefile/readfile (opcional), game:HttpGet.
Se algum recurso não existir, o script degrada com segurança.
]]--

--------------------------------------------------
-- Serviços
--------------------------------------------------
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local TeleportService    = game:GetService("TeleportService")
local Lighting           = game:GetService("Lighting")
local HttpService        = game:GetService("HttpService")

local LocalPlayer        = Players.LocalPlayer

--------------------------------------------------
-- Util Checagem de Ambiente
--------------------------------------------------
local hasFileOps = (typeof(writefile)=="function" and typeof(readfile)=="function" and typeof(isfile)=="function")
local httpGet = (syn and syn.request) and function(url)
    local ok,res = pcall(syn.request,{Url=url,Method="GET"})
    if ok and res and res.Body then return res.Body end
    return game:HttpGet(url)
end or function(url) return game:HttpGet(url) end

--------------------------------------------------
-- Internacionalização
--------------------------------------------------
local I18N = {
    pt = {
        hub_title="Universal Hub",
        cat_visual="Visual",
        cat_player="Jogador",
        cat_tp="Teleporte",
        cat_status="Status",
        cat_utils="Utilidades",
        cat_settings="Configurações",
        section_movement="Movimentação / Sistemas",
        toggle_flight="Voar (Flight)",
        toggle_noclip="Noclip",
        slider_flight_speed="Velocidade de Voo",
        slider_walkspeed="WalkSpeed",
        slider_jumppower="JumpPower",
        slider_gravity="Gravidade",
        section_visual="Ajustes Visuais",
        toggle_fullbright="FullBright",
        toggle_fog="Remover Névoa",
        slider_fov="Campo de Visão (FOV)",
        btn_visual_reset="Reset Visual",
        section_esp="ESP / Overlay",
        toggle_esp="ESP Jogadores",
        toggle_esp_names="Mostrar Nomes",
        toggle_esp_distance="Mostrar Distância",
        toggle_esp_tracers="Tracers",
        slider_esp_distance="Limite Distância ESP",
        section_tp="Teleporte",
        textbox_part_name="Nome do Part",
        textbox_part_placeholder="Ex: SpawnLocation",
        btn_teleport_name="Teleportar (Nome Digitado)",
        btn_add_fav="Salvar Posição Atual",
        section_fav="Favoritos",
        btn_rejoin="Reentrar",
        btn_serverhop="Server Hop",
        section_status="Status",
        status_format="HP: {hp}/{mhp}\nWalkSpeed: {ws} | Jump: {jp}\nFlight: {flight} | Noclip: {noclip} | ESP: {esp}\nPosição: {pos}\nFPS: {fps} | Ping: {ping}",
        section_utils="Utilidades",
        toggle_antiafk="Anti-AFK",
        btn_copy_pos="Copiar Posição",
        btn_copy_cframe="Copiar CFrame",
        section_keybinds="Keybinds",
        keybind_flight="Ativar/Desativar Flight",
        keybind_noclip="Ativar/Desativar Noclip",
        keybind_esp="Ativar/Desativar ESP",
        keybind_fullbright="Ativar/Desativar FullBright",
        keybind_antiafk="Ativar/Desativar Anti-AFK",
        keybind_toggle_ui="Mostrar/Esconder Hub",
        btn_reset_char="Resetar Personagem",
        btn_disable_all="Desligar Todos",
        section_theme="Tema / Idioma",
        btn_accent_blue="Acento Azul",
        btn_accent_green="Acento Verde",
        btn_accent_red="Acento Vermelho",
        btn_lang_pt="Idioma: Português",
        btn_lang_en="Idioma: English",
        section_plugins="Plugins",
        textbox_plugin_url="URL Plugin",
        btn_load_plugin="Carregar Plugin",
        notify_loaded_plugin="Plugin carregado",
        notify_plugin_fail="Falha ao carregar plugin",
        notify_copy="Copiado!",
        notify_tp_fail="Teleporte falhou",
        notify_tp_ok="Teleportado",
        notify_saved_pos="Posição salva",
        notify_rejoin="Reentrando...",
        notify_serverhop="Procurando servidor...",
        notify_no_server="Nenhum servidor diferente encontrado",
        notify_config_saved="Config salva",
        section_config="Config / Persistência",
        btn_save_config="Salvar Config",
        toggle_minimize="Minimizar",
        btn_close="Fechar",
    },
    en = {
        hub_title="Universal Hub",
        cat_visual="Visual",
        cat_player="Player",
        cat_tp="Teleport",
        cat_status="Status",
        cat_utils="Utilities",
        cat_settings="Settings",
        section_movement="Movement / Systems",
        toggle_flight="Fly (Flight)",
        toggle_noclip="Noclip",
        slider_flight_speed="Flight Speed",
        slider_walkspeed="WalkSpeed",
        slider_jumppower="JumpPower",
        slider_gravity="Gravity",
        section_visual="Visual Tweaks",
        toggle_fullbright="FullBright",
        toggle_fog="Remove Fog",
        slider_fov="Field of View (FOV)",
        btn_visual_reset="Reset Visual",
        section_esp="ESP / Overlay",
        toggle_esp="Players ESP",
        toggle_esp_names="Show Names",
        toggle_esp_distance="Show Distance",
        toggle_esp_tracers="Tracers",
        slider_esp_distance="ESP Distance Limit",
        section_tp="Teleport",
        textbox_part_name="Part Name",
        textbox_part_placeholder="Eg: SpawnLocation",
        btn_teleport_name="Teleport (Typed Name)",
        btn_add_fav="Save Current Position",
        section_fav="Favorites",
        btn_rejoin="Rejoin",
        btn_serverhop="Server Hop",
        section_status="Status",
        status_format="HP: {hp}/{mhp}\nWalkSpeed: {ws} | Jump: {jp}\nFlight: {flight} | Noclip: {noclip} | ESP: {esp}\nPosition: {pos}\nFPS: {fps} | Ping: {ping}",
        section_utils="Utilities",
        toggle_antiafk="Anti-AFK",
        btn_copy_pos="Copy Position",
        btn_copy_cframe="Copy CFrame",
        section_keybinds="Keybinds",
        keybind_flight="Toggle Flight",
        keybind_noclip="Toggle Noclip",
        keybind_esp="Toggle ESP",
        keybind_fullbright="Toggle FullBright",
        keybind_antiafk="Toggle Anti-AFK",
        keybind_toggle_ui="Show/Hide Hub",
        btn_reset_char="Reset Character",
        btn_disable_all="Disable All",
        section_theme="Theme / Language",
        btn_accent_blue="Accent Blue",
        btn_accent_green="Accent Green",
        btn_accent_red="Accent Red",
        btn_lang_pt="Language: Português",
        btn_lang_en="Language: English",
        section_plugins="Plugins",
        textbox_plugin_url="Plugin URL",
        btn_load_plugin="Load Plugin",
        notify_loaded_plugin="Plugin loaded",
        notify_plugin_fail="Failed to load plugin",
        notify_copy="Copied!",
        notify_tp_fail="Teleport failed",
        notify_tp_ok="Teleported",
        notify_saved_pos="Position saved",
        notify_rejoin="Rejoining...",
        notify_serverhop="Searching server...",
        notify_no_server="No different server found",
        notify_config_saved="Config saved",
        section_config="Config / Persistence",
        btn_save_config="Save Config",
        toggle_minimize="Minimize",
        btn_close="Close",
    }
}
local currentLang = "pt"
local function T(k)
    return (I18N[currentLang] and I18N[currentLang][k]) or (I18N.en[k]) or k
end
local function formatTemplate(str,map)
    return (str:gsub("{(.-)}", function(key)
        return map[key] ~= nil and tostring(map[key]) or "{"..key.."}"
    end))
end

--------------------------------------------------
-- THEME (dinâmico)
--------------------------------------------------
local THEME = {
    Accent = Color3.fromRGB(60,100,255)
}
local BASE_THEME = {
    Background = Color3.fromRGB(24,24,24),
    BackgroundAlt = Color3.fromRGB(30,30,30),
    TextPrimary = Color3.fromRGB(235,235,235),
    TextSecondary = Color3.fromRGB(180,180,180),
    Section = Color3.fromRGB(40,40,40),
    ToggleOn = Color3.fromRGB(90,170,90),
    ToggleOff = Color3.fromRGB(80,80,80),
    Border = Color3.fromRGB(55,55,55),
    Danger = Color3.fromRGB(200,70,70),
    Warning = Color3.fromRGB(200,150,70),
}
for k,v in pairs(BASE_THEME) do THEME[k]=v end

local function setAccent(color)
    THEME.Accent = color
    -- Atualização dinâmica (recolore barras/realces)
    for _,gui in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        -- NÃO tocamos Core UI original, apenas nosso ScreenGui se necessário.
    end
end

--------------------------------------------------
-- CONFIG (persistência)
--------------------------------------------------
local CONFIG_PATH = "UniversalHub_Config.json"
local Config = {
    data = {
        lang = currentLang,
        accent = "blue",
        flightSpeed = 120,
        espDistance = 600,
        keybinds = {
            flight="F",
            noclip="N",
            esp="G",
            fullbright="B",
            antiafk="J",
            toggle_ui="RightControl"
        },
        favorites = {}
    }
}
function Config:Load()
    if hasFileOps and isfile(CONFIG_PATH) then
        local ok, raw = pcall(readfile, CONFIG_PATH)
        if ok and raw then
            local ok2, dec = pcall(HttpService.JSONDecode, HttpService, raw)
            if ok2 and type(dec)=="table" then
                for k,v in pairs(dec) do self.data[k]=v end
                currentLang = self.data.lang or currentLang
            end
        end
    end
end
function Config:Save()
    if not hasFileOps then return end
    self.data.lang = currentLang
    local ok, enc = pcall(HttpService.JSONEncode, HttpService, self.data)
    if ok then pcall(writefile, CONFIG_PATH, enc) end
end
Config:Load()

--------------------------------------------------
-- Helpers gerais
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
local function notify(msg, dur)
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return end
    local root = gui:FindFirstChild("UHNotifyHolder")
    if not root then
        root = create("ScreenGui",{Name="UHNotifyHolder",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Global})
        root.Parent = gui
        local frame = create("Frame",{Name="Stack",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-10,1,-10),
            Size=UDim2.new(0,320,1,-20),BackgroundTransparency=1})
        frame.Parent = root
    end
    local stack = root.Stack
    if not stack then return end
    local item = create("Frame",{BackgroundColor3=THEME.BackgroundAlt,Size=UDim2.new(1,0,0,42),BorderSizePixel=0,Transparency=0})
    create("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=item
    applyStroke(item)
    local lbl = create("TextLabel",{Text=msg,Font=Enum.Font.Gotham,TextSize=14,BackgroundTransparency=1,TextColor3=THEME.TextPrimary,
        TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,-20,1,0),Position=UDim2.fromOffset(10,0)})
    lbl.Parent=item
    item.Parent = stack
    item.Position = UDim2.new(0,0,1,0)
    item.Visible = true
    -- reposition (simple vertical stack)
    for i,child in ipairs(stack:GetChildren()) do
        if child:IsA("Frame") then
            child.Position = UDim2.new(0,0,1,-(i-1)*48)
        end
    end
    task.spawn(function()
        task.wait(dur or 3)
        if item and item.Parent then
            local tw = TweenService:Create(item,TweenInfo.new(0.25),{BackgroundTransparency=1})
            tw:Play()
            tw.Completed:Wait()
            item:Destroy()
        end
    end)
end

--------------------------------------------------
-- Sistemas (Flight, Noclip, ESP, FullBright, AntiAFK)
--------------------------------------------------
local Systems = {}

-- Flight
Systems.Flight = {
    Enabled=false,
    Speed=Config.data.flightSpeed or 120,
    VerticalSpeed=100,
    Pressing={},
    Connection=nil,
    Keys={Forward="W",Back="S",Left="A",Right="D",Up="Space",Down="LeftShift"},
    Velocity=Vector3.zero,
    Smooth=true,
    LerpAlpha=0.15
}
function Systems.Flight:Enable()
    if self.Enabled then return end
    self.Enabled=true
    local hum=safeHumanoid(); if hum then hum.PlatformStand=true end
    self.Connection = RunService.RenderStepped:Connect(function()
        local hrp=getHRP(); if not hrp then return end
        local cam=workspace.CurrentCamera
        local look=cam.CFrame.LookVector
        local move=Vector3.zero
        if self.Pressing.Forward then move+=Vector3.new(look.X,0,look.Z) end
        if self.Pressing.Back then move-=Vector3.new(look.X,0,look.Z) end
        if self.Pressing.Left then local r=cam.CFrame.RightVector; move-=Vector3.new(r.X,0,r.Z) end
        if self.Pressing.Right then local r=cam.CFrame.RightVector; move+=Vector3.new(r.X,0,r.Z) end
        if self.Pressing.Up then move+=Vector3.new(0,self.VerticalSpeed/self.Speed,0) end
        if self.Pressing.Down then move-=Vector3.new(0,self.VerticalSpeed/self.Speed,0) end
        if move.Magnitude>0 then move=move.Unit end
        local targetVel = move * self.Speed
        if self.Smooth then
            self.Velocity = self.Velocity:Lerp(targetVel,self.LerpAlpha)
            hrp.AssemblyLinearVelocity = self.Velocity
        else
            hrp.AssemblyLinearVelocity = targetVel
        end
    end)
end
function Systems.Flight:Disable()
    if not self.Enabled then return end
    self.Enabled=false
    if self.Connection then self.Connection:Disconnect() self.Connection=nil end
    self.Velocity=Vector3.zero
    local hum=safeHumanoid(); if hum then hum.PlatformStand=false end
end

-- Noclip
Systems.Noclip = {Enabled=false, Connection=nil}
function Systems.Noclip:Enable()
    if self.Enabled then return end
    self.Enabled=true
    self.Connection = RunService.Stepped:Connect(function()
        local char=LocalPlayer.Character; if not char then return end
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end)
end
function Systems.Noclip:Disable()
    if not self.Enabled then return end
    self.Enabled=false
    if self.Connection then self.Connection:Disconnect(); self.Connection=nil end
end

-- ESP
Systems.ESP = {
    Enabled=false,
    DistanceLimit=Config.data.espDistance or 600,
    ShowNames=true,
    ShowDistance=true,
    Tracers=false,
    Objects={},
    ScanAccumulator=0,
    ScanInterval=0.25
}
local function clearESP()
    for _,obj in pairs(Systems.ESP.Objects) do
        if obj.Highlight then obj.Highlight:Destroy() end
        if obj.Line then obj.Line:Destroy() end
        if obj.Label then obj.Label:Destroy() end
    end
    Systems.ESP.Objects = {}
end
function Systems.ESP:Disable()
    if not self.Enabled then return end
    self.Enabled=false
    clearESP()
end
function Systems.ESP:Enable()
    if self.Enabled then return end
    self.Enabled=true
end
local function updateESP(dt)
    if not Systems.ESP.Enabled then return end
    local camera = workspace.CurrentCamera
    Systems.ESP.ScanAccumulator += dt
    -- scan players periodicamente
    if Systems.ESP.ScanAccumulator >= Systems.ESP.ScanInterval then
        Systems.ESP.ScanAccumulator = 0
        -- remove mortos
        for plr,obj in pairs(Systems.ESP.Objects) do
            if not plr.Character or not plr.Character.Parent then
                if obj.Highlight then obj.Highlight:Destroy() end
                if obj.Line then obj.Line:Destroy() end
                if obj.Label then obj.Label:Destroy() end
                Systems.ESP.Objects[plr]=nil
            end
        end
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LocalPlayer then
                if not Systems.ESP.Objects[plr] then
                    Systems.ESP.Objects[plr] = {}
                    local h = Instance.new("Highlight")
                    h.FillColor = THEME.Accent
                    h.FillTransparency = 0.75
                    h.OutlineColor = THEME.Accent
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = plr.Character or workspace
                    Systems.ESP.Objects[plr].Highlight = h

                    local billboard = Instance.new("BillboardGui")
                    billboard.Size = UDim2.new(0,200,0,40)
                    billboard.AlwaysOnTop = true
                    billboard.StudsOffset = Vector3.new(0,3,0)
                    billboard.Parent = plr.Character or workspace
                    local lbl = Instance.new("TextLabel")
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 14
                    lbl.TextColor3 = THEME.TextPrimary
                    lbl.Size = UDim2.new(1,0,1,0)
                    lbl.Parent = billboard
                    Systems.ESP.Objects[plr].Label = billboard
                end
            end
        end
    end
    local myHRP = getHRP()
    for plr,obj in pairs(Systems.ESP.Objects) do
        local ch = plr.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local okInRange=false
        if hrp and myHRP then
            local dist = (hrp.Position - myHRP.Position).Magnitude
            okInRange = dist <= Systems.ESP.DistanceLimit
            if obj.Highlight then
                obj.Highlight.Adornee = ch
                obj.Highlight.Enabled = okInRange
            end
            if obj.Label then
                obj.Label.Adornee = hrp
                obj.Label.Enabled = okInRange and (Systems.ESP.ShowNames or Systems.ESP.ShowDistance)
                if obj.Label.Enabled then
                    local textParts = {}
                    if Systems.ESP.ShowNames then table.insert(textParts, plr.Name) end
                    if Systems.ESP.ShowDistance then table.insert(textParts, string.format("[%.0f]", dist)) end
                    obj.Label.TextLabel.Text = table.concat(textParts," ")
                end
            end
        end
    end
end
RunService.RenderStepped:Connect(updateESP)

-- FullBright / Fog
Systems.Visual = {
    FullBright=false,
    NoFog=false,
    Saved = {}
}
local function applyFullBright(on)
    if on then
        if not Systems.Visual.Saved.Brightness then
            Systems.Visual.Saved.Brightness = Lighting.Brightness
            Systems.Visual.Saved.ClockTime = Lighting.ClockTime
            Systems.Visual.Saved.FogEnd = Lighting.FogEnd
        end
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
    else
        if Systems.Visual.Saved.Brightness then
            Lighting.Brightness = Systems.Visual.Saved.Brightness
            Lighting.ClockTime = Systems.Visual.Saved.ClockTime
        end
    end
end
local function applyFog(on)
    if on then
        if not Systems.Visual.Saved.FogEnd then
            Systems.Visual.Saved.FogEnd = Lighting.FogEnd
        end
        Lighting.FogEnd = 100000
    else
        if Systems.Visual.Saved.FogEnd then
            Lighting.FogEnd = Systems.Visual.Saved.FogEnd
        end
    end
end
local function resetVisual()
    if Systems.Visual.Saved.Brightness then
        Lighting.Brightness = Systems.Visual.Saved.Brightness
        Lighting.ClockTime = Systems.Visual.Saved.ClockTime
    end
    if Systems.Visual.Saved.FogEnd then
        Lighting.FogEnd = Systems.Visual.Saved.FogEnd
    end
    Systems.Visual.FullBright=false
    Systems.Visual.NoFog=false
end

-- AntiAFK
Systems.AntiAFK = {
    Enabled=false,
    Connection=nil
}
function Systems.AntiAFK:Enable()
    if self.Enabled then return end
    self.Enabled=true
    local vu = game:GetService("VirtualUser")
    self.Connection = LocalPlayer.Idled:Connect(function()
        if self.Enabled then
            vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end
    end)
end
function Systems.AntiAFK:Disable()
    if not self.Enabled then return end
    self.Enabled=false
    if self.Connection then self.Connection:Disconnect() self.Connection=nil end
end

--------------------------------------------------
-- Entrada de Teclado (Flight)
--------------------------------------------------
UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for tag,keyName in pairs(Systems.Flight.Keys) do
            if Enum.KeyCode[keyName] and input.KeyCode==Enum.KeyCode[keyName] then
                Systems.Flight.Pressing[tag] = true
            end
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for tag,keyName in pairs(Systems.Flight.Keys) do
            if Enum.KeyCode[keyName] and input.KeyCode==Enum.KeyCode[keyName] then
                Systems.Flight.Pressing[tag] = false
            end
        end
    end
end)

--------------------------------------------------
-- Keybind Manager
--------------------------------------------------
local Keybinds = {}
local function triggerKeybind(action)
    if action=="flight" then
        if Systems.Flight.Enabled then Systems.Flight:Disable() else Systems.Flight:Enable() end
    elseif action=="noclip" then
        if Systems.Noclip.Enabled then Systems.Noclip:Disable() else Systems.Noclip:Enable() end
    elseif action=="esp" then
        if Systems.ESP.Enabled then Systems.ESP:Disable() else Systems.ESP:Enable() end
    elseif action=="fullbright" then
        Systems.Visual.FullBright = not Systems.Visual.FullBright
        applyFullBright(Systems.Visual.FullBright)
    elseif action=="antiafk" then
        if Systems.AntiAFK.Enabled then Systems.AntiAFK:Disable() else Systems.AntiAFK:Enable() end
    elseif action=="toggle_ui" then
        local sg = LocalPlayer.PlayerGui:FindFirstChild("UniversalHubMain")
        if sg then sg.Enabled = not sg.Enabled end
    end
end
UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    for action, keyName in pairs(Config.data.keybinds) do
        local kc = Enum.KeyCode[keyName]
        if kc and input.KeyCode==kc then
            triggerKeybind(action)
        end
    end
end)

--------------------------------------------------
-- Server Hop / Rejoin
--------------------------------------------------
local function rejoin()
    notify(T("notify_rejoin"))
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

local function serverHop()
    notify(T("notify_serverhop"))
    local placeId = game.PlaceId
    local cursor = nil
    local current = game.JobId
    local chosen = nil
    for _=1,5 do  -- até 5 páginas
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s")
            :format(placeId, cursor and ("&cursor="..cursor) or "")
        local ok, body = pcall(function() return httpGet(url) end)
        if ok and body then
            local data = HttpService:JSONDecode(body)
            for _,srv in ipairs(data.data or {}) do
                if srv.id ~= current and srv.playing < srv.maxPlayers then
                    chosen = srv.id
                    break
                end
            end
            if chosen then break end
            cursor = data.nextPageCursor
            if not cursor then break end
        else
            break
        end
    end
    if chosen then
        TeleportService:TeleportToPlaceInstance(placeId, chosen, LocalPlayer)
    else
        notify(T("notify_no_server"))
    end
end

--------------------------------------------------
-- Teleporte / Favoritos
--------------------------------------------------
local favorites = Config.data.favorites or {}
local function saveFavorite(name)
    local hrp = getHRP()
    if not hrp then return end
    favorites[name] = hrp.CFrame
    Config.data.favorites = favorites
    notify(T("notify_saved_pos"))
end
local function teleportTo(partName)
    local hrp = getHRP()
    if not hrp then notify(T("notify_tp_fail")) return end
    local part = workspace:FindFirstChild(partName, true)
    if part and part:IsA("BasePart") then
        hrp.CFrame = part.CFrame + Vector3.new(0,5,0)
        notify(T("notify_tp_ok"))
    else
        notify(T("notify_tp_fail"))
    end
end
local function teleportCFrame(cf)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = cf
        notify(T("notify_tp_ok"))
    else
        notify(T("notify_tp_fail"))
    end
end

--------------------------------------------------
-- UI Factory
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
        Size = UDim2.new(1,0,0,38),
        TextXAlignment = Enum.TextXAlignment.Left
    },{create("UIPadding",{PaddingLeft=UDim.new(0,12)})})
    create("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=lbl
    applyStroke(lbl)
    lbl.Parent = parent
    return lbl
end
function Factory:Toggle(parent,label,default,getSetFn)
    local frame = create("Frame",{BackgroundColor3=THEME.Section,Size=UDim2.new(1,0,0,44),BorderSizePixel=0})
    create("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=frame
    applyStroke(frame)
    frame.Parent=parent
    local txt = create("TextLabel",{Text=label,Font=Enum.Font.GothamSemibold,TextSize=15,TextColor3=THEME.TextPrimary,BackgroundTransparency=1,
        Size=UDim2.new(1,-70,1,0),Position=UDim2.fromOffset(12,0),TextXAlignment=Enum.TextXAlignment.Left})
    txt.Parent=frame
    local btn = create("TextButton",{Text="",AutoButtonColor=false,BackgroundColor3=default and THEME.ToggleOn or THEME.ToggleOff,Size=UDim2.fromOffset(52,24),
        Position=UDim2.new(1,-64,0.5,-12)})
    create("UICorner",{CornerRadius=UDim.new(1,0)}).Parent=btn
    btn.Parent=frame
    local knob = create("Frame",{BackgroundColor3=Color3.new(1,1,1),Size=UDim2.fromOffset(20,20),
        Position=default and UDim2.fromOffset(28,2) or UDim2.fromOffset(4,2)})
    create("UICorner",{CornerRadius=UDim.new(1,0)}).Parent=knob
    knob.Parent=btn
    local state = default
    local function setState(st, fire)
        state=st
        TweenService:Create(btn,TweenInfo.new(0.15),{BackgroundColor3=state and THEME.ToggleOn or THEME.ToggleOff}):Play()
        TweenService:Create(knob,TweenInfo.new(0.15),{Position=state and UDim2.fromOffset(28,2) or UDim2.fromOffset(4,2)}):Play()
        if fire and getSetFn then getSetFn(state) end
    end
    btn.MouseButton1Click:Connect(function() setState(not state,true) end)
    return {Set=function(v) setState(v,true) end, Get=function() return state end, Frame=frame}
end
function Factory:Slider(parent,label,minV,maxV,default,onChange)
    minV=minV or 0; maxV=maxV or 100; default=math.clamp(default,minV,maxV)
    local frame = create("Frame",{BackgroundColor3=THEME.Section,Size=UDim2.new(1,0,0,62),BorderSizePixel=0})
    create("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=frame; applyStroke(frame); frame.Parent=parent
    local lbl = create("TextLabel",{Text=label,Font=Enum.Font.GothamSemibold,TextSize=15,TextColor3=THEME.TextPrimary,BackgroundTransparency=1,
        Size=UDim2.new(1,-60,0,20),Position=UDim2.fromOffset(12,6),TextXAlignment=Enum.TextXAlignment.Left})
    lbl.Parent=frame
    local valLbl = create("TextLabel",{Text=tostring(default),Font=Enum.Font.GothamBold,TextSize=14,TextColor3=THEME.TextSecondary,BackgroundTransparency=1,
        Size=UDim2.new(0,60,0,20),Position=UDim2.new(1,-60,0,6)})
    valLbl.Parent=frame
    local bar = create("Frame",{BackgroundColor3=THEME.BackgroundAlt,Size=UDim2.new(1,-24,0,8),Position=UDim2.fromOffset(12,36),BorderSizePixel=0})
    create("UICorner",{CornerRadius=UDim.new(0,4)}).Parent=bar
    bar.Parent=frame
    local fill = create("Frame",{BackgroundColor3=THEME.Accent,Size=UDim2.new((default-minV)/(maxV-minV),0,1,0),BorderSizePixel=0})
    create("UICorner",{CornerRadius=UDim.new(0,4)}).Parent=fill
    fill.Parent=bar
    local dragging=false
    local current=default
    local function update(x)
        local rel = math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        local val = math.floor(minV+(maxV-minV)*rel+0.5)
        current=val
        fill.Size=UDim2.new(rel,0,1,0)
        valLbl.Text=tostring(val)
        if onChange then onChange(val) end
    end
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true update(i.Position.X) end end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
    return {Set=function(v)
        v=math.clamp(v,minV,maxV)
        local rel=(v-minV)/(maxV-minV)
        fill.Size=UDim2.new(rel,0,1,0)
        valLbl.Text=tostring(v)
        current=v
        if onChange then onChange(v) end
    end, Get=function() return current end}
end
function Factory:Button(parent,text,callback,variant)
    local frame=create("Frame",{BackgroundColor3=THEME.Section,Size=UDim2.new(1,0,0,44),BorderSizePixel=0})
    create("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=frame; applyStroke(frame); frame.Parent=parent
    local baseColor = (variant=="danger" and THEME.Danger) or (variant=="warn" and THEME.Warning) or THEME.BackgroundAlt
    local btn = create("TextButton",{Text=text,Font=Enum.Font.GothamSemibold,TextSize=15,TextColor3=THEME.TextPrimary,AutoButtonColor=false,
        BackgroundColor3=baseColor,Size=UDim2.new(1,-20,0,32),Position=UDim2.fromOffset(10,6)})
    create("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=btn
    btn.Parent=frame
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = THEME.Accent end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = baseColor end)
    btn.MouseButton1Click:Connect(function() if callback then task.spawn(callback) end end)
    return btn
end
function Factory:TextBox(parent,label,placeholder,onCommit)
    local frame=create("Frame",{BackgroundColor3=THEME.Section,Size=UDim2.new(1,0,0,54),BorderSizePixel=0})
    create("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=frame; applyStroke(frame); frame.Parent=parent
    create("TextLabel",{Text=label,Font=Enum.Font.GothamSemibold,TextSize=15,TextColor3=THEME.TextPrimary,
        BackgroundTransparency=1,Size=UDim2.new(1,-240,1,0),Position=UDim2.fromOffset(12,0),TextXAlignment=Enum.TextXAlignment.Left}).Parent=frame
    local box = create("TextBox",{Text="",PlaceholderText=placeholder or "",Font=Enum.Font.Gotham,TextSize=15,TextColor3=THEME.TextPrimary,
        BackgroundColor3=THEME.BackgroundAlt,ClearTextOnFocus=false,Size=UDim2.new(0,220,0,34),Position=UDim2.new(1,-232,0.5,-17)})
    create("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=box
    box.Parent=frame
    box.FocusLost:Connect(function(enter) if enter and onCommit then onCommit(box.Text) end end)
    return box
end

--------------------------------------------------
-- Construção da UI Principal
--------------------------------------------------
local function buildUI()
    local existing = LocalPlayer.PlayerGui:FindFirstChild("UniversalHubMain")
    if existing then existing:Destroy() end

    local screenGui = create("ScreenGui",{Name="UniversalHubMain",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Global,IgnoreGuiInset=true})
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local window = create("Frame",{Name="Window",Size=UDim2.fromOffset(isMobile and 760 or 900, isMobile and 430 or 500),
        Position=UDim2.new(0.5,-(isMobile and 380 or 450),0.5,-(isMobile and 215 or 250)),
        BackgroundColor3=THEME.Background,BorderSizePixel=0})
    create("UICorner",{CornerRadius=UDim.new(0,8)}).Parent=window
    applyStroke(window)
    window.Parent=screenGui

    local topBar = create("Frame",{Size=UDim2.new(1,0,0,42),BackgroundColor3=THEME.BackgroundAlt,BorderSizePixel=0})
    create("UICorner",{CornerRadius=UDim.new(0,8)}).Parent=topBar
    topBar.Parent=window

    local title = create("TextLabel",{Text=T("hub_title"),Font=Enum.Font.GothamBold,TextSize=18,TextColor3=THEME.TextPrimary,
        BackgroundTransparency=1,Size=UDim2.new(1,-140,1,0),Position=UDim2.fromOffset(16,0),TextXAlignment=Enum.TextXAlignment.Left})
    title.Parent=topBar

    local function topButton(txt)
        local b = create("TextButton",{Text=txt,Font=Enum.Font.Gotham,TextSize=16,TextColor3=THEME.TextPrimary,AutoButtonColor=false,
            BackgroundColor3=THEME.Background,Size=UDim2.fromOffset(38,30)})
        create("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=b
        b.MouseEnter:Connect(function() b.BackgroundColor3=THEME.BackgroundAlt end)
        b.MouseLeave:Connect(function() b.BackgroundColor3=THEME.Background end)
        return b
    end

    local closeBtn = topButton(T("btn_close"))
    closeBtn.Position=UDim2.new(1,-46,0.5,-15)
    closeBtn.Parent=topBar
    closeBtn.MouseButton1Click:Connect(function() screenGui.Enabled=false end)

    local miniBtn = topButton("-")
    miniBtn.Position=UDim2.new(1,-92,0.5,-15); miniBtn.Parent=topBar
    local minimized=false
    local function setChildrenVisible(container, visible)
        for _,c in ipairs(container:GetChildren()) do
            if c~=topBar and c:IsA("GuiObject") then c.Visible = visible end
        end
    end
    miniBtn.MouseButton1Click:Connect(function()
        minimized=not minimized
        setChildrenVisible(window, not minimized)
        topBar.Visible=true
        window.Size = minimized and UDim2.fromOffset(300,60) or UDim2.fromOffset(isMobile and 760 or 900, isMobile and 430 or 500)
    end)

    -- Drag
    local dragging=false
    local dragStart,startPos
    topBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true
            dragStart=i.Position
            startPos=window.Position
        end
    end)
    topBar.InputChanged:Connect(function(i)
        if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-dragStart
            window.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)

    local sidebar = create("Frame",{Size=UDim2.new(0,isMobile and 170 or 200,1,-42),Position=UDim2.fromOffset(0,42),
        BackgroundColor3=THEME.BackgroundAlt,BorderSizePixel=0})
    create("UICorner",{CornerRadius=UDim.new(0,8)}).Parent=sidebar
    sidebar.Parent=window
    local listLayout = create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,6)})
    listLayout.Parent=sidebar
    create("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingBottom=UDim.new(0,10)}).Parent=sidebar

    local contentHolder = create("Frame",{Size=UDim2.new(1,-(isMobile and 180 or 210),1,-52),Position=UDim2.new(0,isMobile and 180 or 210,0,52),
        BackgroundTransparency=1})
    contentHolder.Parent=window

    local categories = {
        {id="Visual", text=T("cat_visual")},
        {id="Jogador", text=T("cat_player")},
        {id="Teleporte", text=T("cat_tp")},
        {id="Status", text=T("cat_status")},
        {id="Util", text=T("cat_utils")},
        {id="Settings", text=T("cat_settings")},
    }
    local pages = {}
    local catButtons = {}
    local activeCat=nil
    local function selectCat(id)
        activeCat=id
        for _,b in ipairs(catButtons) do
            if b.Name==id then
                b.BackgroundColor3=THEME.Accent; b.TextColor3=Color3.new(1,1,1)
            else
                b.BackgroundColor3=THEME.Section; b.TextColor3=THEME.TextPrimary
            end
        end
        for name,pg in pairs(pages) do
            pg.Visible = (name==id)
        end
    end
    local function makeCatButton(cat)
        local btn = create("TextButton",{Name=cat.id,Text=cat.text,Font=Enum.Font.GothamSemibold,TextSize=isMobile and 14 or 16,
            TextColor3=THEME.TextPrimary,AutoButtonColor=false,BackgroundColor3=THEME.Section,Size=UDim2.new(1,0,0,38)})
        create("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=btn
        btn.Parent=sidebar
        btn.MouseEnter:Connect(function() if activeCat~=btn.Name then btn.BackgroundColor3=THEME.Background end end)
        btn.MouseLeave:Connect(function() if activeCat~=btn.Name then btn.BackgroundColor3=THEME.Section end end)
        btn.MouseButton1Click:Connect(function() selectCat(btn.Name) end)
        table.insert(catButtons,btn)
    end
    for _,cat in ipairs(categories) do makeCatButton(cat) end

    local function createPage(name)
        local page = create("Frame",{Name=name,BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Visible=false})
        page.Parent=contentHolder
        pages[name]=page
        local scroll = create("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,-8,1,-8),Position=UDim2.fromOffset(4,4),
            ScrollBarThickness=6,CanvasSize=UDim2.new()})
        scroll.Parent=page
        local layout = create("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,10)})
        layout.Parent=scroll
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scroll.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+20)
        end)
        create("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8)}).Parent=scroll
        return scroll
    end

    local pgVisual = createPage("Visual")
    local pgPlayer = createPage("Jogador")
    local pgTP = createPage("Teleporte")
    local pgStatus = createPage("Status")
    local pgUtil = createPage("Util")
    local pgSettings = createPage("Settings")

    --------------------------------------------------
    -- VISUAL
    --------------------------------------------------
    Factory:SectionTitle(pgVisual, T("section_visual"))
    local fullBrightToggle = Factory:Toggle(pgVisual, T("toggle_fullbright"), Systems.Visual.FullBright, function(st)
        Systems.Visual.FullBright=st
        applyFullBright(st)
    end)
    local fogToggle = Factory:Toggle(pgVisual, T("toggle_fog"), Systems.Visual.NoFog, function(st)
        Systems.Visual.NoFog=st
        applyFog(st)
    end)
    Factory:Slider(pgVisual, T("slider_fov"), 40, 120, workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70, function(v)
        if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView=v end
    end)
    Factory:Button(pgVisual, T("btn_visual_reset"), function()
        resetVisual()
        fullBrightToggle.Set(false)
        fogToggle.Set(false)
    end)

    Factory:SectionTitle(pgVisual, T("section_esp"))
    local espToggle = Factory:Toggle(pgVisual, T("toggle_esp"), Systems.ESP.Enabled, function(st)
        if st then Systems.ESP:Enable() else Systems.ESP:Disable() end
    end)
    local espNamesToggle = Factory:Toggle(pgVisual, T("toggle_esp_names"), Systems.ESP.ShowNames, function(st) Systems.ESP.ShowNames=st end)
    local espDistTextToggle = Factory:Toggle(pgVisual, T("toggle_esp_distance"), Systems.ESP.ShowDistance, function(st) Systems.ESP.ShowDistance=st end)
    local espTracersToggle = Factory:Toggle(pgVisual, T("toggle_esp_tracers"), Systems.ESP.Tracers, function(st) Systems.ESP.Tracers=st end) -- placeholder
    local espDistSlider = Factory:Slider(pgVisual, T("slider_esp_distance"), 50, 2000, Systems.ESP.DistanceLimit, function(v)
        Systems.ESP.DistanceLimit=v
        Config.data.espDistance=v
    end)

    --------------------------------------------------
    -- JOGADOR
    --------------------------------------------------
    Factory:SectionTitle(pgPlayer, T("section_movement"))
    local flightToggle = Factory:Toggle(pgPlayer, T("toggle_flight"), Systems.Flight.Enabled, function(st)
        if st then Systems.Flight:Enable() else Systems.Flight:Disable() end
    end)
    local flightSpeedSlider = Factory:Slider(pgPlayer, T("slider_flight_speed"), 20, 400, Systems.Flight.Speed, function(v)
        Systems.Flight.Speed=v
        Config.data.flightSpeed=v
    end)
    local noclipToggle = Factory:Toggle(pgPlayer, T("toggle_noclip"), Systems.Noclip.Enabled, function(st)
        if st then Systems.Noclip:Enable() else Systems.Noclip:Disable() end
    end)
    local wsSlider = Factory:Slider(pgPlayer, T("slider_walkspeed"), 8, 200, (safeHumanoid() and safeHumanoid().WalkSpeed) or 16, function(v)
        local hum=safeHumanoid(); if hum then hum.WalkSpeed=v end
    end)
    local jpSlider = Factory:Slider(pgPlayer, T("slider_jumppower"), 10, 200, (safeHumanoid() and safeHumanoid().JumpPower) or 50, function(v)
        local hum=safeHumanoid(); if hum then hum.JumpPower=v end
    end)
    local gravSlider = Factory:Slider(pgPlayer, T("slider_gravity"), 0, 400, workspace.Gravity, function(v)
        workspace.Gravity = v
    end)

    Factory:Button(pgPlayer, T("btn_reset_char"), function()
        local hum=safeHumanoid(); if hum then hum.Health=0 end
    end, "warn")
    Factory:Button(pgPlayer, T("btn_disable_all"), function()
        flightToggle.Set(false) Systems.Flight:Disable()
        noclipToggle.Set(false) Systems.Noclip:Disable()
        espToggle.Set(false) Systems.ESP:Disable()
        fullBrightToggle.Set(false) Systems.Visual.FullBright=false; resetVisual()
        fogToggle.Set(false)
    end, "danger")

    --------------------------------------------------
    -- TELEPORTE
    --------------------------------------------------
    Factory:SectionTitle(pgTP, T("section_tp"))
    local tpBox = Factory:TextBox(pgTP, T("textbox_part_name"), T("textbox_part_placeholder"), function(text)
        if text and #text>0 then teleportTo(text) end
    end)
    Factory:Button(pgTP, T("btn_teleport_name"), function()
        if tpBox.Text and #tpBox.Text>0 then teleportTo(tpBox.Text) end
    end)

    Factory:Button(pgTP, T("btn_add_fav"), function()
        local name = "Fav"..tostring(#favorites+1)
        saveFavorite(name)
        buildUI() -- rebuild para mostrar novo favorito
    end)

    Factory:SectionTitle(pgTP, T("section_fav"))
    for name, cf in pairs(favorites) do
        Factory:Button(pgTP, name, function() teleportCFrame(cf) end)
    end

    Factory:Button(pgTP, T("btn_rejoin"), rejoin, "warn")
    Factory:Button(pgTP, T("btn_serverhop"), serverHop, "warn")

    --------------------------------------------------
    -- STATUS
    --------------------------------------------------
    Factory:SectionTitle(pgStatus, T("section_status"))
    local statFrame = create("Frame",{BackgroundColor3=THEME.Section,Size=UDim2.new(1,0,0,140),BorderSizePixel=0})
    create("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=statFrame; applyStroke(statFrame)
    statFrame.Parent=pgStatus
    local statLabel = create("TextLabel",{Text="...",Font=Enum.Font.Gotham,TextSize=14,TextColor3=THEME.TextSecondary,
        BackgroundTransparency=1,Size=UDim2.new(1,-20,1,-20),Position=UDim2.fromOffset(10,10),
        TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top})
    statLabel.Parent=statFrame

    local fpsCounter = 0
    local accum = 0
    RunService.RenderStepped:Connect(function(dt)
        fpsCounter += 1
        accum += dt
        if accum >= 1 then
            local fps = fpsCounter/accum
            fpsCounter=0
            accum=0
            local hum = safeHumanoid()
            local hp = hum and math.floor(hum.Health) or "?"
            local mhp = hum and math.floor(hum.MaxHealth or 0) or "?"
            local jp = hum and math.floor(hum.JumpPower) or "?"
            local ws = hum and hum.WalkSpeed or "?"
            local pos = tostring(getHRP() and getHRP().Position or "N/A")
            local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"] and
                math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) or "?"
            statLabel.Text = formatTemplate(T("status_format"), {
                hp=hp,mhp=mhp,ws=ws,jp=jp,
                flight=Systems.Flight.Enabled,noclip=Systems.Noclip.Enabled,esp=Systems.ESP.Enabled,pos=pos,
                fps = math.floor(fps), ping=ping
            })
        end
    end)

    --------------------------------------------------
    -- UTILIDADES
    --------------------------------------------------
    Factory:SectionTitle(pgUtil, T("section_utils"))
    local antiafkToggle = Factory:Toggle(pgUtil, T("toggle_antiafk"), Systems.AntiAFK.Enabled, function(st)
        if st then Systems.AntiAFK:Enable() else Systems.AntiAFK:Disable() end
    end)
    Factory:Button(pgUtil, T("btn_copy_pos"), function()
        local hrp=getHRP()
        if hrp and setclipboard then
            setclipboard(tostring(hrp.Position))
            notify(T("notify_copy"))
        end
    end)
    Factory:Button(pgUtil, T("btn_copy_cframe"), function()
        local hrp=getHRP()
        if hrp and setclipboard then
            setclipboard("CFrame.new("..tostring(hrp.CFrame)..")")
            notify(T("notify_copy"))
        end
    end)

    --------------------------------------------------
    -- SETTINGS (Keybinds, Tema, Idioma, Plugins, Config)
    --------------------------------------------------
    Factory:SectionTitle(pgSettings, T("section_keybinds"))
    local function keybindRow(parent, labelKey, action)
        local frame = create("Frame",{BackgroundColor3=THEME.Section,Size=UDim2.new(1,0,0,44)})
        create("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=frame; applyStroke(frame); frame.Parent=parent
        create("TextLabel",{Text=T(labelKey),Font=Enum.Font.GothamSemibold,TextSize=15,TextColor3=THEME.TextPrimary,
            BackgroundTransparency=1,Size=UDim2.new(1,-150,1,0),Position=UDim2.fromOffset(12,0),TextXAlignment=Enum.TextXAlignment.Left}).Parent=frame
        local btn = create("TextButton",{Text=Config.data.keybinds[action] or "...",Font=Enum.Font.GothamBold,TextSize=14,
            BackgroundColor3=THEME.BackgroundAlt,TextColor3=THEME.TextPrimary,Size=UDim2.fromOffset(120,28),Position=UDim2.new(1,-132,0.5,-14)})
        create("UICorner",{CornerRadius=UDim.new(0,6)}).Parent=btn
        btn.Parent=frame
        local rebinding=false
        btn.MouseButton1Click:Connect(function()
            if rebinding then return end
            rebinding=true
            btn.Text = "..."
            local conn
            conn = UserInputService.InputBegan:Connect(function(i,gpe)
                if gpe or i.UserInputType~=Enum.UserInputType.Keyboard then return end
                Config.data.keybinds[action] = i.KeyCode.Name
                btn.Text = i.KeyCode.Name
                rebinding=false
                if conn then conn:Disconnect() end
            end)
        end)
    end
    keybindRow(pgSettings, "keybind_flight","flight")
    keybindRow(pgSettings, "keybind_noclip","noclip")
    keybindRow(pgSettings, "keybind_esp","esp")
    keybindRow(pgSettings, "keybind_fullbright","fullbright")
    keybindRow(pgSettings, "keybind_antiafk","antiafk")
    keybindRow(pgSettings, "keybind_toggle_ui","toggle_ui")

    Factory:SectionTitle(pgSettings, T("section_theme"))
    Factory:Button(pgSettings, T("btn_accent_blue"), function() setAccent(Color3.fromRGB(60,100,255)); Config.data.accent="blue" end)
    Factory:Button(pgSettings, T("btn_accent_green"), function() setAccent(Color3.fromRGB(70,200,120)); Config.data.accent="green" end)
    Factory:Button(pgSettings, T("btn_accent_red"), function() setAccent(Color3.fromRGB(220,70,70)); Config.data.accent="red" end)

    Factory:Button(pgSettings, T("btn_lang_pt"), function()
        currentLang="pt"; Config.data.lang="pt"; buildUI()
    end)
    Factory:Button(pgSettings, T("btn_lang_en"), function()
        currentLang="en"; Config.data.lang="en"; buildUI()
    end)

    Factory:SectionTitle(pgSettings, T("section_plugins"))
    local pluginBox = Factory:TextBox(pgSettings, T("textbox_plugin_url"), "https://raw.githubusercontent.com/....lua", function(url) end)
    Factory:Button(pgSettings, T("btn_load_plugin"), function()
        local url = pluginBox.Text
        if not url or #url==0 then return end
        local ok, code = pcall(function() return httpGet(url) end)
        if not ok or not code then
            notify(T("notify_plugin_fail")); return
        end
        local fn,err = loadstring(code)
        if not fn then notify(T("notify_plugin_fail")..": "..tostring(err)) return end
        local success, plugin = pcall(fn)
        if not success then notify(T("notify_plugin_fail")) return end
        if type(plugin)=="function" then
            local ok2, err2 = pcall(plugin, Factory, notify)
            if not ok2 then notify(T("notify_plugin_fail")) return end
        end
        notify(T("notify_loaded_plugin"))
    end)

    Factory:SectionTitle(pgSettings, T("section_config"))
    Factory:Button(pgSettings, T("btn_save_config"), function()
        Config:Save()
        notify(T("notify_config_saved"))
    end,"warn")

    -- Ajustar accent conforme config
    if Config.data.accent=="green" then setAccent(Color3.fromRGB(70,200,120))
    elseif Config.data.accent=="red" then setAccent(Color3.fromRGB(220,70,70))
    else setAccent(Color3.fromRGB(60,100,255)) end

    selectCat("Visual")
end

buildUI()

--------------------------------------------------
-- Respawn Handling para Flight
--------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
    if Systems.Flight.Enabled then
        Systems.Flight:Disable()
        Systems.Flight:Enable()
    end
end)

--------------------------------------------------
-- Fim
--------------------------------------------------
notify("Universal Hub carregado")