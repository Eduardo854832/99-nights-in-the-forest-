--// Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

--// Player/GUI
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

--// Estado/Preferências (sessão)
local State = {
	WalkSpeed = 16,
	JumpPower = 50,
	Fly = false,
	FlySpeed = 28, -- velocidade inicial um pouco maior para suavidade
	Visual = {
		DefaultFOV = 70,
		FOV = nil,
		FogEnd = nil,
		ClockTime = nil,
	},
}

-- Guardar padrões reais ao iniciar personagem
local function captureDefaults(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		State.WalkSpeed = hum.WalkSpeed
		State.JumpPower = hum.JumpPower
	end
	if workspace.CurrentCamera then
		State.Visual.DefaultFOV = workspace.CurrentCamera.FieldOfView
	end
	State.Visual.FovOriginal = State.Visual.DefaultFOV
	State.Visual.FogEndOriginal = Lighting.FogEnd
	State.Visual.ClockTimeOriginal = Lighting.ClockTime
end

--// GUI raiz
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

----------------------------------------------------------------
-- TELA DE CARREGAMENTO (antes da seleção de idioma)
----------------------------------------------------------------
local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Size = UDim2.new(1, 0, 1, 0)
LoadingFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
LoadingFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "Universal Hub"
Title.Size = UDim2.new(1, 0, 0, 90)
Title.Position = UDim2.new(0, 0, 0.38, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextScaled = true
Title.Parent = LoadingFrame

local LoadingText = Instance.new("TextLabel")
LoadingText.Text = "Carregando"
LoadingText.Size = UDim2.new(1, 0, 0, 40)
LoadingText.Position = UDim2.new(0, 0, 0.52, 0)
LoadingText.BackgroundTransparency = 1
LoadingText.TextColor3 = Color3.fromRGB(200, 200, 200)
LoadingText.Font = Enum.Font.SourceSans
LoadingText.TextSize = 22
LoadingText.Parent = LoadingFrame

-- animação pontinhos
local loadingConn
loadingConn = RunService.RenderStepped:Connect(function()
	local t = tick() % 1.5
	local dots = t < 0.5 and "." or (t < 1 and ".." or "...")
	LoadingText.Text = "Carregando" .. dots
end)

task.spawn(function()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	task.wait(1.0) -- pequeno extra para suavizar
	-- Fade out
	for i = 1, 20 do
		local a = i / 20
		Title.TextTransparency = a
		LoadingText.TextTransparency = a
		LoadingFrame.BackgroundTransparency = a * 0.6
		RunService.RenderStepped:Wait()
	end
	if loadingConn then loadingConn:Disconnect() end
	LoadingFrame:Destroy()
	-- Mostrar seleção de idioma
	if ScreenGui:FindFirstChild("LangFrame") then
		ScreenGui.LangFrame.Visible = true
	end
end)

----------------------------------------------------------------
-- TRADUÇÃO (somente escolha inicial, sem troca dinâmica)
----------------------------------------------------------------
local languages = {
	["pt"] = {
		title = "Universal Hub",
		tabs = {"Ferramentas", "Movimentação", "Visual", "Utilidades", "Jogadores"},
		buttons = {
			tools = {"Dar item Teleport"},
			move = {"Velocidade Rápida", "Super Pulo", "Ativar/Desativar Fly", "↑ Velocidade Fly", "↓ Velocidade Fly", "Restaurar Movimentação"},
			visual = {"Ampliar FOV", "Restaurar FOV", "Remover Neblina", "Dia", "Noite", "Reset Visual"},
			util = {"Resetar Personagem", "Teleportar ao Spawn", "Modo Seguro (Desativar Tudo)", "Abrir/Fechar (Atalho: RightCtrl)"},
			players = {"Atualizar Lista", "Parar Spectate"},
		},
		speedLabel = "Velocidade do Fly: ",
		toastSafeOn = "Modo Seguro ativado",
		toastSafeOff = "Modo Seguro desativado",
		search = "Pesquisar jogador...",
		dist = "Distância: ",
		tp = "TP",
		spec = "Spec",
		specNow = "Spectando: ",
		none = "Ninguém",
	},
	["en"] = {
		title = "Universal Hub",
		tabs = {"Tools", "Movement", "Visual", "Utilities", "Players"},
		buttons = {
			tools = {"Give Teleport Tool"},
			move = {"Fast Speed", "Super Jump", "Toggle Fly", "↑ Fly Speed", "↓ Fly Speed", "Restore Movement"},
			visual = {"Increase FOV", "Restore FOV", "Remove Fog", "Day", "Night", "Reset Visual"},
			util = {"Reset Character", "Teleport to Spawn", "Safe Mode (Disable All)", "Open/Close (Hotkey: RightCtrl)"},
			players = {"Refresh List", "Stop Spectate"},
		},
		speedLabel = "Fly Speed: ",
		toastSafeOn = "Safe Mode enabled",
		toastSafeOff = "Safe Mode disabled",
		search = "Search player...",
		dist = "Distance: ",
		tp = "TP",
		spec = "Spec",
		specNow = "Spectating: ",
		none = "Nobody",
	},
}

local currentLang = "pt" -- padrão

-- UIStroke helper
local function addStroke(obj, thickness)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1.5
	s.Color = Color3.fromRGB(255, 255, 255)
	s.Transparency = 0.8
	s.Parent = obj
end

-- Seleção de idioma
local LangFrame = Instance.new("Frame")
LangFrame.Name = "LangFrame"
LangFrame.Size = UDim2.new(0, 320, 0, 170)
LangFrame.Position = UDim2.new(0.5, -160, 0.5, -85)
LangFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
LangFrame.Visible = false
LangFrame.Parent = ScreenGui
addStroke(LangFrame, 2)

local LangTitle = Instance.new("TextLabel")
LangTitle.Text = "Escolha o Idioma / Choose Language"
LangTitle.Size = UDim2.new(1, 0, 0, 44)
LangTitle.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
LangTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
LangTitle.Font = Enum.Font.SourceSansBold
LangTitle.TextSize = 20
LangTitle.Parent = LangFrame

local PTBtn = Instance.new("TextButton")
PTBtn.Text = "Português"
PTBtn.Size = UDim2.new(0.5, -12, 0, 60)
PTBtn.Position = UDim2.new(0, 8, 0, 70)
PTBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
PTBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PTBtn.Font = Enum.Font.SourceSansBold
PTBtn.TextSize = 18
PTBtn.Parent = LangFrame
addStroke(PTBtn, 1.5)

local ENBtn = Instance.new("TextButton")
ENBtn.Text = "English"
ENBtn.Size = UDim2.new(0.5, -12, 0, 60)
ENBtn.Position = UDim2.new(0.5, 4, 0, 70)
ENBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
ENBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ENBtn.Font = Enum.Font.SourceSansBold
ENBtn.TextSize = 18
ENBtn.Parent = LangFrame
addStroke(ENBtn, 1.5)

----------------------------------------------------------------
-- HUB (construído após escolher idioma)
----------------------------------------------------------------
local function buildHub()
	local texts = languages[currentLang]

	-- Botão Toggle (quadrado no canto)
	local ToggleBtn = Instance.new("TextButton")
	ToggleBtn.Name = "ToggleBtn"
	ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
	ToggleBtn.Position = UDim2.new(0, 20, 0, 200)
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ToggleBtn.Text = ""
	ToggleBtn.Parent = ScreenGui
	addStroke(ToggleBtn, 1.5)

	-- Janela principal
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 560, 0, 390)
	MainFrame.Position = UDim2.new(0.5, -280, 0.5, -195)
	MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	MainFrame.Visible = false
	MainFrame.Active = true
	MainFrame.Draggable = true
	MainFrame.Parent = ScreenGui
	addStroke(MainFrame, 2)

	-- Título
	local TitleBar = Instance.new("TextLabel")
	TitleBar.Text = texts.title
	TitleBar.Size = UDim2.new(1, 0, 0, 40)
	TitleBar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
	TitleBar.Font = Enum.Font.SourceSansBold
	TitleBar.TextSize = 22
	TitleBar.Parent = MainFrame

	-- Área de abas
	local TabsFrame = Instance.new("Frame")
	TabsFrame.Size = UDim2.new(0, 160, 1, -40)
	TabsFrame.Position = UDim2.new(0, 0, 0, 40)
	TabsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	TabsFrame.Parent = MainFrame
	addStroke(TabsFrame, 1.5)

	local TabsLayout = Instance.new("UIListLayout")
	TabsLayout.FillDirection = Enum.FillDirection.Vertical
	TabsLayout.Padding = UDim.new(0, 6)
	TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabsLayout.Parent = TabsFrame

	-- Conteúdo
	local ContentFrame = Instance.new("Frame")
	ContentFrame.Size = UDim2.new(1, -160, 1, -40)
	ContentFrame.Position = UDim2.new(0, 160, 0, 40)
	ContentFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	ContentFrame.Parent = MainFrame
	addStroke(ContentFrame, 1.5)

	local currentTab : Frame? = nil

	local function createTab(name)
		local button = Instance.new("TextButton")
		button.Text = name
		button.Size = UDim2.new(1, -12, 0, 36)
		button.Position = UDim2.new(0, 6, 0, 0)
		button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Font = Enum.Font.SourceSansBold
		button.TextSize = 18
		button.Parent = TabsFrame
		addStroke(button, 1)

		local tabContent = Instance.new("Frame")
		tabContent.Size = UDim2.new(1, 0, 1, 0)
		tabContent.BackgroundTransparency = 1
		tabContent.Visible = false
		tabContent.Parent = ContentFrame

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 10)
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = tabContent

		button.MouseButton1Click:Connect(function()
			if currentTab then currentTab.Visible = false end
			tabContent.Visible = true
			currentTab = tabContent
		end)

		return tabContent
	end

	local function createButton(tab, text, callback)
		local button = Instance.new("TextButton")
		button.Text = text
		button.Size = UDim2.new(0, 280, 0, 40)
		button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Font = Enum.Font.SourceSansBold
		button.TextSize = 18
		button.Parent = tab
		addStroke(button, 1)
		button.MouseButton1Click:Connect(callback or function() end)
		return button
	end

	local function createLabel(tab, text)
		local lbl = Instance.new("TextLabel")
		lbl.Text = text
		lbl.Size = UDim2.new(1, -20, 0, 24)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		lbl.Font = Enum.Font.SourceSans
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextSize = 18
		lbl.Parent = tab
		return lbl
	end

	-- Abas
	local toolsTab = createTab(texts.tabs[1])
	local moveTab = createTab(texts.tabs[2])
	local visualTab = createTab(texts.tabs[3])
	local utilTab = createTab(texts.tabs[4])
	local playersTab = createTab(texts.tabs[5])

	----------------------------------------------------------------
	-- Ferramentas
	----------------------------------------------------------------
	createButton(toolsTab, texts.buttons.tools[1], function()
		if player.Backpack:FindFirstChild("Teleport") then return end
		local tool = Instance.new("Tool")
		tool.Name = "Teleport"
		tool.RequiresHandle = false
		tool.CanBeDropped = false
		tool.Parent = player.Backpack
		tool.Activated:Connect(function()
			local char = player.Character or player.CharacterAdded:Wait()
			local hrp = char:WaitForChild("HumanoidRootPart")
			if mouse and mouse.Hit then
				hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 5, 0))
			end
		end)
	end)

	----------------------------------------------------------------
	-- Fly (SUAVE: LinearVelocity + AlignOrientation) e Movimentação
	----------------------------------------------------------------
	local function setCharacterCollision(char, canCollide)
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = canCollide
			end
		end
	end

	-- Componentes para voo
	local flying = false
	local flyConn : RBXScriptConnection?
	local function removeFly(char)
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			if hrp:FindFirstChild("FlyAtt") then hrp.FlyAtt:Destroy() end
			if hrp:FindFirstChild("FlyLV") then hrp.FlyLV:Destroy() end
			if hrp:FindFirstChild("FlyAO") then hrp.FlyAO:Destroy() end
		end
		if flyConn then flyConn:Disconnect() flyConn = nil end
		-- restaurar rotação/colisão
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.AutoRotate = true end
		if char then
			setCharacterCollision(char, true)
		end
	end

	local function applyFly(char)
		local hrp = char:WaitForChild("HumanoidRootPart")
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid or not hrp then return end

		-- Estado
		humanoid.AutoRotate = false
		setCharacterCollision(char, false) -- atravessar suave enquanto voa

		-- Attach e Constraints
		local att = Instance.new("Attachment")
		att.Name = "FlyAtt"
		att.Parent = hrp

		local lv = Instance.new("LinearVelocity")
		lv.Name = "FlyLV"
		lv.Attachment0 = att
		lv.MaxForce = math.huge
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.VectorVelocity = Vector3.zero
		lv.Parent = hrp

		local ao = Instance.new("AlignOrientation")
		ao.Name = "FlyAO"
		ao.Attachment0 = att
		ao.Responsiveness = 50
		ao.MaxTorque = math.huge
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.Parent = hrp

		-- Loop de voo suave
		flyConn = RunService.RenderStepped:Connect(function(dt)
			if not hrp or not hrp.Parent or not humanoid then return end
			local cam = workspace.CurrentCamera
			local camCF = cam.CFrame

			-- Direção horizontal com base no MoveDirection e na câmera
			local moveDir = humanoid.MoveDirection
			local right = camCF.RightVector
			local forward = camCF.LookVector
			-- ignorar componente Y para não inclinar a horizontal
			local planar = (Vector3.new(right.X, 0, right.Z) * moveDir.X) + (Vector3.new(forward.X, 0, forward.Z) * moveDir.Z)
			if planar.Magnitude > 1 then planar = planar.Unit end

			-- Controle vertical:
			local vertical = 0
			if UserInputService.KeyboardEnabled then
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical = 1 end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vertical = -1 end
			end
			-- MOBILE: usa a inclinação da câmera (pitch) para subir/descer sem botões extras
			if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
				local pitchY = camCF.LookVector.Y
				if pitchY > 0.35 then
					vertical = 1
				elseif pitchY < -0.35 then
					vertical = -1
				else
					vertical = 0
				end
			end

			local desired = (planar * State.FlySpeed) + Vector3.new(0, vertical * State.FlySpeed, 0)

			-- Suavização por LERP para evitar "trancos"
			local currentVel = hrp.AssemblyLinearVelocity
			local newVel = currentVel:Lerp(desired, 0.18) -- 18% por frame
			lv.VectorVelocity = newVel

			-- Alinhar orientação ao Yaw da câmera (evita rolagem esquisita)
			local rx, ry, rz = camCF:ToOrientation()
			ao.CFrame = CFrame.fromOrientation(0, ry, 0)
		end)
	end

	local function toggleFly()
		local char = player.Character or player.CharacterAdded:Wait()
		if not char then return end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		if not flying then
			flying = true
			State.Fly = true
			applyFly(char)
		else
			flying = false
			State.Fly = false
			removeFly(char)
		end
	end

	----------------------------------------------------------------
	-- Movimentação (botões) + HUD de velocidade do fly
	----------------------------------------------------------------
	local speedLabel = createLabel(moveTab, (languages[currentLang].speedLabel .. State.FlySpeed))
	local function updateSpeedLabel() speedLabel.Text = (languages[currentLang].speedLabel .. State.FlySpeed) end

	createButton(moveTab, texts.buttons.move[1], function()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = 50
			State.WalkSpeed = 50
		end
	end)

	createButton(moveTab, texts.buttons.move[2], function()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.JumpPower = 150
			State.JumpPower = 150
		end
	end)

	createButton(moveTab, texts.buttons.move[3], function()
		toggleFly()
		updateSpeedLabel()
	end)

	createButton(moveTab, texts.buttons.move[4], function() -- aumentar velocidade voar
		State.FlySpeed = math.clamp(State.FlySpeed + 5, 5, 200)
		updateSpeedLabel()
	end)

	createButton(moveTab, texts.buttons.move[5], function() -- diminuir velocidade voar
		State.FlySpeed = math.clamp(State.FlySpeed - 5, 5, 200)
		updateSpeedLabel()
	end)

	createButton(moveTab, texts.buttons.move[6], function() -- restore mov
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = State.WalkSpeed
			hum.JumpPower = State.JumpPower
		end
	end)

	-- Atalhos de teclado: ajustar velocidade do fly
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.E then
			State.FlySpeed = math.clamp(State.FlySpeed + 5, 5, 200); updateSpeedLabel()
		elseif input.KeyCode == Enum.KeyCode.Q then
			State.FlySpeed = math.clamp(State.FlySpeed - 5, 5, 200); updateSpeedLabel()
		end
	end)

	----------------------------------------------------------------
	-- Visual
	----------------------------------------------------------------
	local defaultFOV = workspace.CurrentCamera.FieldOfView

	createButton(visualTab, texts.buttons.visual[1], function()
		workspace.CurrentCamera.FieldOfView = 100
	end)

	createButton(visualTab, texts.buttons.visual[2], function()
		workspace.CurrentCamera.FieldOfView = defaultFOV
	end)

	createButton(visualTab, texts.buttons.visual[3], function()
		Lighting.FogEnd = 100000
	end)

	createButton(visualTab, texts.buttons.visual[4], function()
		Lighting.ClockTime = 14
	end)

	createButton(visualTab, texts.buttons.visual[5], function()
		Lighting.ClockTime = 0
	end)

	createButton(visualTab, texts.buttons.visual[6], function()
		workspace.CurrentCamera.FieldOfView = defaultFOV
		Lighting.FogEnd = State.Visual.FogEndOriginal
		Lighting.ClockTime = State.Visual.ClockTimeOriginal
	end)

	----------------------------------------------------------------
	-- Utilidades
	----------------------------------------------------------------
	createButton(utilTab, texts.buttons.util[1], function()
		player:LoadCharacter()
	end)

	createButton(utilTab, texts.buttons.util[2], function()
		local char = player.Character or player.CharacterAdded:Wait()
		local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
		if spawn then
			char:MoveTo(spawn.Position + Vector3.new(0, 5, 0))
		else
			char:MoveTo(Vector3.new(0, 5, 0))
		end
	end)

	-- Modo Seguro: desativar tudo e restaurar
	createButton(utilTab, texts.buttons.util[3], function()
		local char = player.Character or player.CharacterAdded:Wait()
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = State.WalkSpeed
			hum.JumpPower = State.JumpPower
		end
		workspace.CurrentCamera.FieldOfView = defaultFOV
		Lighting.FogEnd = State.Visual.FogEndOriginal
		Lighting.ClockTime = State.Visual.ClockTimeOriginal

		if flying then
			flying = false
			State.Fly = false
			removeFly(char)
		end
		StarterGui:SetCore("SendNotification", {Title = texts.title, Text = languages[currentLang].toastSafeOn, Duration = 2})
	end)

	-- Atalho escrito no botão e também funcional
	createButton(utilTab, texts.buttons.util[4], function()
		MainFrame.Visible = not MainFrame.Visible
	end)

	----------------------------------------------------------------
	-- Players Tab - Melhorada (busca, distância, spectate, TP)
	----------------------------------------------------------------
	local headerFrame = Instance.new("Frame")
	headerFrame.Size = UDim2.new(1, -20, 0, 28)
	headerFrame.BackgroundTransparency = 1
	headerFrame.Parent = playersTab

	local playersCountLabel = Instance.new("TextLabel")
	playersCountLabel.Text = (currentLang == "pt" and "Jogadores: " or "Players: ") .. math.max(#Players:GetPlayers()-1, 0)
	playersCountLabel.Size = UDim2.new(0.5, -6, 1, 0)
	playersCountLabel.BackgroundTransparency = 1
	playersCountLabel.TextXAlignment = Enum.TextXAlignment.Left
	playersCountLabel.TextColor3 = Color3.new(1,1,1)
	playersCountLabel.Font = Enum.Font.SourceSans
	playersCountLabel.TextSize = 18
	playersCountLabel.Parent = headerFrame

	local spectateNowLabel = Instance.new("TextLabel")
	spectateNowLabel.Text = languages[currentLang].specNow .. languages[currentLang].none
	spectateNowLabel.Size = UDim2.new(0.5, 0, 1, 0)
	spectateNowLabel.Position = UDim2.new(0.5, 0, 0, 0)
	spectateNowLabel.BackgroundTransparency = 1
	spectateNowLabel.TextXAlignment = Enum.TextXAlignment.Right
	spectateNowLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	spectateNowLabel.Font = Enum.Font.SourceSans
	spectateNowLabel.TextSize = 16
	spectateNowLabel.Parent = headerFrame

	-- Search
	local searchBox = Instance.new("TextBox")
	searchBox.PlaceholderText = languages[currentLang].search
	searchBox.Size = UDim2.new(1, -20, 0, 32)
	searchBox.ClearTextOnFocus = false
	searchBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	searchBox.TextColor3 = Color3.new(1,1,1)
	searchBox.Text = ""
	searchBox.Font = Enum.Font.SourceSans
	searchBox.TextSize = 18
	searchBox.Parent = playersTab
	addStroke(searchBox, 1)

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(1, -20, 1, -120)
	listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.ScrollBarThickness = 6
	listFrame.BackgroundTransparency = 1
	listFrame.Parent = playersTab

	local lfLayout = Instance.new("UIListLayout")
	lfLayout.Padding = UDim.new(0, 6)
	lfLayout.Parent = listFrame

	-- Botões do rodapé
	local footer = Instance.new("Frame")
	footer.Size = UDim2.new(1, -20, 0, 36)
	footer.BackgroundTransparency = 1
	footer.Parent = playersTab

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Text = texts.buttons.players[1]
	refreshBtn.Size = UDim2.new(0.5, -6, 1, 0)
	refreshBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	refreshBtn.Font = Enum.Font.SourceSansBold
	refreshBtn.TextSize = 18
	refreshBtn.Parent = footer
	addStroke(refreshBtn, 1)

	local stopSpecBtn = Instance.new("TextButton")
	stopSpecBtn.Text = texts.buttons.players[2]
	stopSpecBtn.Size = UDim2.new(0.5, 0, 1, 0)
	stopSpecBtn.Position = UDim2.new(0.5, 6, 0, 0)
	stopSpecBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	stopSpecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	stopSpecBtn.Font = Enum.Font.SourceSansBold
	stopSpecBtn.TextSize = 18
	stopSpecBtn.Parent = footer
	addStroke(stopSpecBtn, 1)

	local spectateTarget : Player? = nil

	local function setSpectate(plr : Player?)
		spectateTarget = plr
		if plr and plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
			workspace.CurrentCamera.CameraSubject = plr.Character:FindFirstChildOfClass("Humanoid")
			spectateNowLabel.Text = languages[currentLang].specNow .. plr.Name
		else
			workspace.CurrentCamera.CameraSubject = (player.Character and player.Character:FindFirstChildOfClass("Humanoid")) or workspace.CurrentCamera.CameraSubject
			spectateNowLabel.Text = languages[currentLang].specNow .. languages[currentLang].none
		end
	end

	stopSpecBtn.MouseButton1Click:Connect(function()
		setSpectate(nil)
	end)

	local function distanceTo(plr : Player)
		local myChar = player.Character
		local tChar = plr.Character
		if myChar and tChar then
			local myHRP = myChar:FindFirstChild("HumanoidRootPart")
			local tHRP = tChar:FindFirstChild("HumanoidRootPart")
			if myHRP and tHRP then
				return (myHRP.Position - tHRP.Position).Magnitude
			end
		end
		return math.huge
	end

	local rowCache = {}

	local function makeRow(plr : Player)
		local row = Instance.new("Frame")
		row.Name = "Row_"..plr.UserId
		row.Size = UDim2.new(1, 0, 0, 40)
		row.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
		row.Parent = listFrame
		addStroke(row, 1)

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(0.55, -8, 1, 0)
		nameLbl.Position = UDim2.new(0, 8, 0, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextColor3 = Color3.new(1,1,1)
		nameLbl.Font = Enum.Font.SourceSansBold
		nameLbl.TextSize = 18
		nameLbl.Text = plr.Name
		nameLbl.Parent = row

		local distLbl = Instance.new("TextLabel")
		distLbl.Size = UDim2.new(0.2, 0, 1, 0)
		distLbl.Position = UDim2.new(0.55, 0, 0, 0)
		distLbl.BackgroundTransparency = 1
		distLbl.TextXAlignment = Enum.TextXAlignment.Center
		distLbl.TextColor3 = Color3.fromRGB(220,220,220)
		distLbl.Font = Enum.Font.SourceSans
		distLbl.TextSize = 16
		distLbl.Text = "-"
		distLbl.Parent = row

		local tpBtn = Instance.new("TextButton")
		tpBtn.Text = languages[currentLang].tp
		tpBtn.Size = UDim2.new(0.12, -4, 0, 32)
		tpBtn.Position = UDim2.new(0.75, 2, 0.5, -16)
		tpBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		tpBtn.Font = Enum.Font.SourceSansBold
		tpBtn.TextSize = 16
		tpBtn.Parent = row
		addStroke(tpBtn, 1)

		local specBtn = Instance.new("TextButton")
		specBtn.Text = languages[currentLang].spec
		specBtn.Size = UDim2.new(0.12, -4, 0, 32)
		specBtn.Position = UDim2.new(0.88, 2, 0.5, -16)
		specBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		specBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		specBtn.Font = Enum.Font.SourceSansBold
		specBtn.TextSize = 16
		specBtn.Parent = row
		addStroke(specBtn, 1)

		tpBtn.MouseButton1Click:Connect(function()
			local myChar = player.Character or player.CharacterAdded:Wait()
			local targetChar = plr.Character
			if myChar and targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
				myChar:MoveTo(targetChar.HumanoidRootPart.Position + Vector3.new(0, 3, 0))
			end
		end)

		specBtn.MouseButton1Click:Connect(function()
			setSpectate(plr)
		end)

		rowCache[plr] = {row=row, nameLbl=nameLbl, distLbl=distLbl}
	end

	local function clearRows()
		for _, info in pairs(rowCache) do
			if info.row then info.row:Destroy() end
		end
		table.clear(rowCache)
	end

	local function populatePlayers()
		clearRows()
		local list = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then table.insert(list, plr) end
		end
		-- ordenar por nome inicialmente
		table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
		for _, plr in ipairs(list) do
			if searchBox.Text == "" or string.find(plr.Name:lower(), searchBox.Text:lower(), 1, true) then
				makeRow(plr)
			end
		end
		playersCountLabel.Text = (currentLang == "pt" and "Jogadores: " or "Players: ") .. math.max(#Players:GetPlayers()-1, 0)
	end

	refreshBtn.MouseButton1Click:Connect(populatePlayers)
	searchBox:GetPropertyChangedSignal("Text"):Connect(populatePlayers)

	Players.PlayerAdded:Connect(populatePlayers)
	Players.PlayerRemoving:Connect(function(plr)
		if spectateTarget == plr then setSpectate(nil) end
		populatePlayers()
	end)

	-- Atualização periódica das distâncias e do camera subject do spectate
	RunService.Heartbeat:Connect(function()
		for plr, info in pairs(rowCache) do
			if plr and info and info.distLbl then
				local d = distanceTo(plr)
				if d ~= math.huge then
					info.distLbl.Text = languages[currentLang].dist .. tostring(math.floor(d))
				else
					info.distLbl.Text = "-"
				end
			end
		end
		-- se o alvo sumir, parar spectate
		if spectateTarget and (not spectateTarget.Character or not spectateTarget.Character:FindFirstChildOfClass("Humanoid")) then
			setSpectate(nil)
		end
	end)

	-- Primeira aba ativa
	local currentTabRef = toolsTab
	currentTabRef.Visible = true
	currentTab = currentTabRef

	-- Toggle abrir/fechar (botão e atalho RightCtrl)
	local open = false
	local function setOpen(v)
		open = v
		MainFrame.Visible = open
	end

	ToggleBtn.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.RightControl then
			setOpen(not open)
		end
	end)

	----------------------------------------------------------------
	-- Auto reaplicar no respawn
	----------------------------------------------------------------
	local function reapplyOnSpawn(char)
		captureDefaults(char)
		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			hum.WalkSpeed = State.WalkSpeed
			hum.JumpPower = State.JumpPower
		end
		if State.Fly then
			flying = true
			applyFly(char)
		else
			removeFly(char)
		end
	end

	if player.Character then captureDefaults(player.Character) end
	player.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		reapplyOnSpawn(char)
	end)

	-- Preparar lista de players inicialmente
	populatePlayers()
end

-- Clique de idioma
PTBtn.MouseButton1Click:Connect(function() currentLang = "pt"; LangFrame.Visible = false; buildHub() end)
ENBtn.MouseButton1Click:Connect(function() currentLang = "en"; LangFrame.Visible = false; buildHub() end)

-- Capturar padrões assim que o personagem existir
if player.Character or player.CharacterAdded:Wait() then
	captureDefaults(player.Character)
end
