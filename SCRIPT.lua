--[[
    Universal Roblox UI Script
    Autor: Eduardo854832
    Data: 2025-08-17
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer

-- Módulo principal
local UniversalUI = {}

-- Configurações
UniversalUI.Settings = {
    Title = "Universal Hub",
    Subtitle = "by Eduardo854832",
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = {
        Background = Color3.fromRGB(25, 25, 25),
        SidebarBackground = Color3.fromRGB(30, 30, 30),
        TopbarBackground = Color3.fromRGB(30, 30, 30),
        SectionBackground = Color3.fromRGB(35, 35, 35),
        DarkElement = Color3.fromRGB(40, 40, 40),
        LightText = Color3.fromRGB(255, 255, 255),
        DarkText = Color3.fromRGB(175, 175, 175),
        AccentColor = Color3.fromRGB(255, 0, 0), -- Vermelho como na imagem
        SelectedColor = Color3.fromRGB(50, 50, 50),
        ToggleOff = Color3.fromRGB(60, 60, 60),
        ToggleOn = Color3.fromRGB(255, 0, 0)
    },
}

-- Funções de utilidade
local Utility = {}

function Utility.Create(instanceType, properties)
    local instance = Instance.new(instanceType)
    
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    
    return instance
end

function Utility.CreateTween(instance, tweenInfo, properties)
    return TweenService:Create(instance, tweenInfo, properties)
end

function Utility.Round(number, decimalPlaces)
    local mult = 10^(decimalPlaces or 0)
    return math.floor(number * mult + 0.5) / mult
end

-- Função para criar a interface
function UniversalUI.new(title, subtitle)
    local UI = {}
    
    -- Configurar título
    UI.Title = title or UniversalUI.Settings.Title
    UI.Subtitle = subtitle or UniversalUI.Settings.Subtitle
    
    -- Criar ScreenGui
    UI.ScreenGui = Utility.Create("ScreenGui", {
        Name = "UniversalUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
    })
    
    -- Proteção contra detecção
    if syn and syn.protect_gui then
        syn.protect_gui(UI.ScreenGui)
        UI.ScreenGui.Parent = game.CoreGui
    elseif gethui then
        UI.ScreenGui.Parent = gethui()
    else
        UI.ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Criar frame principal
    UI.MainFrame = Utility.Create("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 800, 0, 450),
        Position = UDim2.new(0.5, -400, 0.5, -225),
        BackgroundColor3 = UniversalUI.Settings.Theme.Background,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = true,
        Parent = UI.ScreenGui,
    })
    
    -- Fazer a janela arrastável
    local isDragging = false
    local dragStart
    local startPos
    
    -- Barra superior (TopBar)
    UI.TopBar = Utility.Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = UniversalUI.Settings.Theme.TopbarBackground,
        BorderSizePixel = 0,
        Parent = UI.MainFrame,
    })
    
    -- Título e Subtítulo
    UI.TitleLabel = Utility.Create("TextLabel", {
        Name = "TitleLabel",
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = UI.Title,
        TextColor3 = UniversalUI.Settings.Theme.AccentColor,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = UI.TopBar,
    })
    
    UI.SubtitleLabel = Utility.Create("TextLabel", {
        Name = "SubtitleLabel",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = " : " .. UI.Subtitle,
        TextColor3 = UniversalUI.Settings.Theme.LightText,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = UI.TopBar,
    })
    
    -- Posicionar o subtítulo após o título
    UI.TitleLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        UI.SubtitleLabel.Position = UDim2.new(0, UI.TitleLabel.AbsoluteSize.X + 5, 0, 0)
    end)
    
    -- Botões de minimizar e fechar
    UI.MinimizeButton = Utility.Create("TextButton", {
        Name = "MinimizeButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -70, 0, 3),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "−",
        TextColor3 = UniversalUI.Settings.Theme.LightText,
        TextSize = 20,
        Parent = UI.TopBar,
    })
    
    UI.CloseButton = Utility.Create("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 3),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = UniversalUI.Settings.Theme.LightText,
        TextSize = 20,
        Parent = UI.TopBar,
    })
    
    -- Lógica de arraste da janela
    UI.TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            startPos = UI.MainFrame.Position
        end
    end)
    
    UI.TopBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            UI.MainFrame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Funcionalidade dos botões
    UI.MinimizeButton.MouseButton1Click:Connect(function()
        -- Implementar minimização (alternativa)
        if UI.MainFrame.Size == UDim2.new(0, 800, 0, 450) then
            local tween = Utility.CreateTween(UI.MainFrame, 
                TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 800, 0, 36)}
            )
            tween:Play()
        else
            local tween = Utility.CreateTween(UI.MainFrame, 
                TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 800, 0, 450)}
            )
            tween:Play()
        end
    end)
    
    UI.CloseButton.MouseButton1Click:Connect(function()
        UI.ScreenGui:Destroy()
    end)
    
    -- Criar menu lateral
    UI.Sidebar = Utility.Create("ScrollingFrame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 220, 1, -36),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundColor3 = UniversalUI.Settings.Theme.SidebarBackground,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = UI.MainFrame,
    })
    
    -- Layout para o menu lateral
    UI.SidebarLayout = Utility.Create("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = UI.Sidebar,
    })
    
    UI.SidebarPadding = Utility.Create("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        Parent = UI.Sidebar,
    })
    
    -- Atualizar tamanho do canvas quando elementos são adicionados
    UI.SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        UI.Sidebar.CanvasSize = UDim2.new(0, 0, 0, UI.SidebarLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Criar área de conteúdo
    UI.Content = Utility.Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -220, 1, -36),
        Position = UDim2.new(0, 220, 0, 36),
        BackgroundColor3 = UniversalUI.Settings.Theme.Background,
        BorderSizePixel = 0,
        Parent = UI.MainFrame,
    })
    
    -- Rastreamento de páginas e categorias
    UI.Pages = {}
    UI.Tabs = {}
    UI.CurrentTab = nil
    
    -- Função para adicionar um tab/página ao menu lateral
    function UI:AddTab(name, icon)
        -- Criar o botão do tab
        local tabButton = Utility.Create("TextButton", {
            Name = name .. "Tab",
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = UI.Sidebar,
        })
        
        -- Ícone (se fornecido)
        local iconImage
        if icon then
            iconImage = Utility.Create("ImageLabel", {
                Name = "Icon",
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, 10, 0.5, -10),
                BackgroundTransparency = 1,
                Image = icon,
                Parent = tabButton,
            })
        end
        
        -- Texto do botão
        local tabText = Utility.Create("TextLabel", {
            Name = "TabText",
            Size = UDim2.new(1, icon and -40 or -20, 1, 0),
            Position = UDim2.new(0, icon and 40 or 10, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = name,
            TextColor3 = UniversalUI.Settings.Theme.LightText,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = tabButton,
        })
        
        -- Criar a página correspondente
        local page = Utility.Create("ScrollingFrame", {
            Name = name .. "Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            Visible = false,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Parent = UI.Content,
        })
        
        -- Layout e Padding para a página
        local pageLayout = Utility.Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = page,
        })
        
        local pagePadding = Utility.Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = page,
        })
        
        -- Atualizar tamanho do canvas quando elementos são adicionados
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 20)
        end)
        
        -- Adicionar à lista de tabs e páginas
        UI.Tabs[name] = tabButton
        UI.Pages[name] = page
        
        -- Lógica de seleção de tab
        tabButton.MouseButton1Click:Connect(function()
            UI:SelectTab(name)
        end)
        
        -- Efeitos de hover
        tabButton.MouseEnter:Connect(function()
            if UI.CurrentTab ~= name then
                local tween = Utility.CreateTween(tabButton, TweenInfo.new(0.2), {
                    BackgroundColor3 = UniversalUI.Settings.Theme.SelectedColor
                })
                tween:Play()
            end
        end)
        
        tabButton.MouseLeave:Connect(function()
            if UI.CurrentTab ~= name then
                local tween = Utility.CreateTween(tabButton, TweenInfo.new(0.2), {
                    BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement
                })
                tween:Play()
            end
        end)
        
        -- Objeto Tab para retornar
        local tab = {}
        
        -- Função para criar uma seção dentro da aba
        function tab:AddSection(sectionName)
            -- Criar o container da seção
            local section = {}
            
            -- Frame da seção
            local sectionFrame = Utility.Create("Frame", {
                Name = sectionName .. "Section",
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = UniversalUI.Settings.Theme.SectionBackground,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = page,
            })
            
            -- Barra superior da seção
            local sectionTop = Utility.Create("Frame", {
                Name = "SectionTop",
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement,
                BorderSizePixel = 0,
                Parent = sectionFrame,
            })
            
            -- Texto da seção
            local sectionLabel = Utility.Create("TextLabel", {
                Name = "SectionLabel",
                Size = UDim2.new(1, -36, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = sectionName,
                TextColor3 = UniversalUI.Settings.Theme.LightText,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = sectionTop,
            })
            
            -- Botão de expansão
            local expandButton = Utility.Create("TextButton", {
                Name = "ExpandButton",
                Size = UDim2.new(0, 36, 0, 36),
                Position = UDim2.new(1, -36, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = "▼",
                TextColor3 = UniversalUI.Settings.Theme.LightText,
                TextSize = 14,
                Parent = sectionTop,
            })
            
            -- Container para os elementos da seção
            local sectionContainer = Utility.Create("Frame", {
                Name = "SectionContainer",
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 36),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = sectionFrame,
            })
            
            -- Layout para os elementos da seção
            local sectionLayout = Utility.Create("UIListLayout", {
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = sectionContainer,
            })
            
            local sectionPadding = Utility.Create("UIPadding", {
                PaddingTop = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                Parent = sectionContainer,
            })
            
            -- Variáveis para controle de expansão
            local isExpanded = false
            local containerSize = 0
            
            -- Atualizar tamanho do container quando elementos são adicionados
            sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                containerSize = sectionLayout.AbsoluteContentSize.Y + 10
                if isExpanded then
                    sectionFrame.Size = UDim2.new(1, 0, 0, 36 + containerSize)
                    sectionContainer.Size = UDim2.new(1, 0, 0, containerSize)
                end
            end)
            
            -- Lógica de expansão da seção
            expandButton.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                
                -- Animação de rotação do botão
                local targetRotation = isExpanded and 180 or 0
                local tweenRotation = Utility.CreateTween(expandButton, TweenInfo.new(0.3), {
                    Rotation = targetRotation
                })
                tweenRotation:Play()
                
                -- Animação de expansão/contração
                local targetSize = isExpanded and UDim2.new(1, 0, 0, 36 + containerSize) or UDim2.new(1, 0, 0, 36)
                local targetContainerSize = isExpanded and UDim2.new(1, 0, 0, containerSize) or UDim2.new(1, 0, 0, 0)
                
                local tweenSection = Utility.CreateTween(sectionFrame, TweenInfo.new(0.3), {
                    Size = targetSize
                })
                
                local tweenContainer = Utility.CreateTween(sectionContainer, TweenInfo.new(0.3), {
                    Size = targetContainerSize
                })
                
                tweenSection:Play()
                tweenContainer:Play()
            end)
            
            -- Funções para adicionar elementos à seção
            
            -- Adicionar toggle (switch)
            function section:AddToggle(text, default, callback)
                local toggleValue = default or false
                
                local toggleFrame = Utility.Create("Frame", {
                    Name = text .. "Toggle",
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Parent = sectionContainer,
                })
                
                local toggleLabel = Utility.Create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextColor3 = UniversalUI.Settings.Theme.DarkText,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = toggleFrame,
                })
                
                local toggleBackground = Utility.Create("Frame", {
                    Name = "Background",
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(1, -45, 0.5, -10),
                    BackgroundColor3 = toggleValue and UniversalUI.Settings.Theme.ToggleOn or UniversalUI.Settings.Theme.ToggleOff,
                    BorderSizePixel = 0,
                    Parent = toggleFrame,
                })
                
                Utility.Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = toggleBackground,
                })
                
                local toggleIndicator = Utility.Create("Frame", {
                    Name = "Indicator",
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(toggleValue and 0.6 or 0, toggleValue and 2 or 2, 0, 2),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Parent = toggleBackground,
                })
                
                Utility.Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = toggleIndicator,
                })
                
                local toggleButton = Utility.Create("TextButton", {
                    Name = "ToggleButton",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = toggleFrame,
                })
                
                toggleButton.MouseButton1Click:Connect(function()
                    toggleValue = not toggleValue
                    
                    local indicatorPosition = toggleValue and UDim2.new(0.6, 0, 0, 2) or UDim2.new(0, 2, 0, 2)
                    local indicatorTween = Utility.CreateTween(toggleIndicator, TweenInfo.new(0.2), {
                        Position = indicatorPosition
                    })
                    
                    local backgroundTween = Utility.CreateTween(toggleBackground, TweenInfo.new(0.2), {
                        BackgroundColor3 = toggleValue and UniversalUI.Settings.Theme.ToggleOn or UniversalUI.Settings.Theme.ToggleOff
                    })
                    
                    indicatorTween:Play()
                    backgroundTween:Play()
                    
                    if callback then
                        callback(toggleValue)
                    end
                end)
                
                -- Objeto toggle para retornar
                local toggle = {
                    Value = toggleValue,
                    Set = function(self, value)
                        toggleValue = value
                        toggleBackground.BackgroundColor3 = toggleValue and UniversalUI.Settings.Theme.ToggleOn or UniversalUI.Settings.Theme.ToggleOff
                        toggleIndicator.Position = toggleValue and UDim2.new(0.6, 0, 0, 2) or UDim2.new(0, 2, 0, 2)
                        
                        if callback then
                            callback(toggleValue)
                        end
                    end
                }
                
                return toggle
            end
            
            -- Adicionar botão
            function section:AddButton(text, callback)
                local button = Utility.Create("TextButton", {
                    Name = text .. "Button",
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement,
                    BorderSizePixel = 0,
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextColor3 = UniversalUI.Settings.Theme.LightText,
                    TextSize = 14,
                    Parent = sectionContainer,
                })
                
                Utility.Create("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = button,
                })
                
                -- Efeitos de hover
                button.MouseEnter:Connect(function()
                    local tween = Utility.CreateTween(button, TweenInfo.new(0.2), {
                        BackgroundColor3 = UniversalUI.Settings.Theme.AccentColor
                    })
                    tween:Play()
                end)
                
                button.MouseLeave:Connect(function()
                    local tween = Utility.CreateTween(button, TweenInfo.new(0.2), {
                        BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement
                    })
                    tween:Play()
                end)
                
                button.MouseButton1Click:Connect(function()
                    if callback then
                        callback()
                    end
                end)
                
                return button
            end
            
            -- Adicionar dropdown
            function section:AddDropdown(text, options, default, callback)
                local dropdownValue = default or options[1] or ""
                
                local dropdownFrame = Utility.Create("Frame", {
                    Name = text .. "Dropdown",
                    Size = UDim2.new(1, 0, 0, 55),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true,
                    Parent = sectionContainer,
                })
                
                local dropdownLabel = Utility.Create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextColor3 = UniversalUI.Settings.Theme.DarkText,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = dropdownFrame,
                })
                
                local dropdownButton = Utility.Create("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(1, 0, 0, 30),
                    Position = UDim2.new(0, 0, 0, 25),
                    BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement,
                    BorderSizePixel = 0,
                    Font = Enum.Font.Gotham,
                    Text = dropdownValue,
                    TextColor3 = UniversalUI.Settings.Theme.LightText,
                    TextSize = 14,
                    Parent = dropdownFrame,
                })
                
                Utility.Create("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = dropdownButton,
                })
                
                local dropdownIcon = Utility.Create("TextLabel", {
                    Name = "Icon",
                    Size = UDim2.new(0, 30, 0, 30),
                    Position = UDim2.new(1, -30, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    Text = "▼",
                    TextColor3 = UniversalUI.Settings.Theme.LightText,
                    TextSize = 14,
                    Parent = dropdownButton,
                })
                
                local dropdownMenu = Utility.Create("Frame", {
                    Name = "Menu",
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, 55),
                    BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 10,
                    Parent = dropdownFrame,
                })
                
                Utility.Create("UICorner", {
                    CornerRadius = UDim.new(0, 4),
                    Parent = dropdownMenu,
                })
                
                local optionLayout = Utility.Create("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = dropdownMenu,
                })
                
                -- Variáveis para controle do dropdown
                local isOpen = false
                local menuHeight = 0
                
                -- Criar opções do dropdown
                for i, option in ipairs(options) do
                    local optionButton = Utility.Create("TextButton", {
                        Name = option .. "Option",
                        Size = UDim2.new(1, 0, 0, 25),
                        BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement,
                        BackgroundTransparency = 0.5,
                        BorderSizePixel = 0,
                        Font = Enum.Font.Gotham,
                        Text = option,
                        TextColor3 = UniversalUI.Settings.Theme.LightText,
                        TextSize = 14,
                        ZIndex = 11,
                        Parent = dropdownMenu,
                    })
                    
                    optionButton.MouseButton1Click:Connect(function()
                        dropdownButton.Text = option
                        dropdownValue = option
                        
                        -- Fechar o dropdown
                        isOpen = false
                        dropdownFrame.Size = UDim2.new(1, 0, 0, 55)
                        dropdownMenu.Visible = false
                        dropdownIcon.Rotation = 0
                        
                        if callback then
                            callback(option)
                        end
                    end)
                    
                    -- Efeito de hover
                    optionButton.MouseEnter:Connect(function()
                        Utility.CreateTween(optionButton, TweenInfo.new(0.1), {
                            BackgroundColor3 = UniversalUI.Settings.Theme.AccentColor
                        }):Play()
                    end)
                    
                    optionButton.MouseLeave:Connect(function()
                        Utility.CreateTween(optionButton, TweenInfo.new(0.1), {
                            BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement
                        }):Play()
                    end)
                end
                
                -- Atualizar altura do menu
                optionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    menuHeight = optionLayout.AbsoluteContentSize.Y
                    dropdownMenu.Size = UDim2.new(1, 0, 0, menuHeight)
                end)
                
                -- Lógica de toggle do dropdown
                dropdownButton.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    
                    if isOpen then
                        dropdownFrame.Size = UDim2.new(1, 0, 0, 55 + menuHeight)
                        dropdownMenu.Visible = true
                        Utility.CreateTween(dropdownIcon, TweenInfo.new(0.2), {
                            Rotation = 180
                        }):Play()
                    else
                        dropdownFrame.Size = UDim2.new(1, 0, 0, 55)
                        dropdownMenu.Visible = false
                        Utility.CreateTween(dropdownIcon, TweenInfo.new(0.2), {
                            Rotation = 0
                        }):Play()
                    end
                end)
                
                -- Objeto dropdown para retornar
                local dropdown = {
                    Value = dropdownValue,
                    Options = options,
                    Set = function(self, value)
                        if table.find(options, value) then
                            dropdownValue = value
                            dropdownButton.Text = value
                            
                            if callback then
                                callback(value)
                            end
                        end
                    end,
                    AddOption = function(self, option)
                        if not table.find(options, option) then
                            table.insert(options, option)
                            
                            local optionButton = Utility.Create("TextButton", {
                                Name = option .. "Option",
                                Size = UDim2.new(1, 0, 0, 25),
                                BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement,
                                BackgroundTransparency = 0.5,
                                BorderSizePixel = 0,
                                Font = Enum.Font.Gotham,
                                Text = option,
                                TextColor3 = UniversalUI.Settings.Theme.LightText,
                                TextSize = 14,
                                ZIndex = 11,
                                Parent = dropdownMenu,
                            })
                            
                            optionButton.MouseButton1Click:Connect(function()
                                dropdownButton.Text = option
                                dropdownValue = option
                                
                                isOpen = false
                                dropdownFrame.Size = UDim2.new(1, 0, 0, 55)
                                dropdownMenu.Visible = false
                                dropdownIcon.Rotation = 0
                                
                                if callback then
                                    callback(option)
                                end
                            end)
                        end
                    end
                }
                
                return dropdown
            end
            
            -- Adicionar slider
            function section:AddSlider(text, min, max, default, callback)
                local sliderValue = default or min
                local sliderFrame = Utility.Create("Frame", {
                    Name = text .. "Slider",
                    Size = UDim2.new(1, 0, 0, 55),
                    BackgroundTransparency = 1,
                    Parent = sectionContainer,
                })
                
                local sliderLabel = Utility.Create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -50, 0, 20),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = text,
                    TextColor3 = UniversalUI.Settings.Theme.DarkText,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = sliderFrame,
                })
                
                local valueLabel = Utility.Create("TextLabel", {
                    Name = "Value",
                    Size = UDim2.new(0, 50, 0, 20),
                    Position = UDim2.new(1, -50, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    Text = tostring(sliderValue),
                    TextColor3 = UniversalUI.Settings.Theme.LightText,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = sliderFrame,
                })
                
                local sliderBackground = Utility.Create("Frame", {
                    Name = "Background",
                    Size = UDim2.new(1, 0, 0, 10),
                    Position = UDim2.new(0, 0, 0, 30),
                    BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement,
                    BorderSizePixel = 0,
                    Parent = sliderFrame,
                })
                
                Utility.Create("UICorner", {
                    CornerRadius = UDim.new(0, 5),
                    Parent = sliderBackground,
                })
                
                local sliderFill = Utility.Create("Frame", {
                    Name = "Fill",
                    Size = UDim2.new((sliderValue - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = UniversalUI.Settings.Theme.AccentColor,
                    BorderSizePixel = 0,
                    Parent = sliderBackground,
                })
                
                Utility.Create("UICorner", {
                    CornerRadius = UDim.new(0, 5),
                    Parent = sliderFill,
                })
                
                local sliderButton = Utility.Create("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(1, 0, 0, 20),
                    Position = UDim2.new(0, 0, 0, 25),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = sliderFrame,
                })
                
                -- Lógica de interação do slider
                local function updateSlider(input)
                    local posX = math.clamp(input.Position.X - sliderBackground.AbsolutePosition.X, 0, sliderBackground.AbsoluteSize.X)
                    local percentage = posX / sliderBackground.AbsoluteSize.X
                    
                    -- Calcular valor baseado na porcentagem
                    local newValue = min + (max - min) * percentage
                    
                    -- Arredondar para inteiro se min e max forem inteiros
                    if math.floor(min) == min and math.floor(max) == max then
                        newValue = math.round(newValue)
                    else
                        newValue = Utility.Round(newValue, 1) -- Arredondar para 1 casa decimal
                    end
                    
                    -- Atualizar valor e UI
                    sliderValue = newValue
                    valueLabel.Text = tostring(sliderValue)
                    sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                    
                    if callback then
                        callback(sliderValue)
                    end
                end
                
                sliderButton.MouseButton1Down:Connect(function(input)
                    updateSlider({Position = input})
                    
                    local mouseConnection
                    mouseConnection = RunService.RenderStepped:Connect(function()
                        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                            updateSlider({Position = UserInputService:GetMouseLocation()})
                        else
                            mouseConnection:Disconnect()
                        end
                    end)
                end)
                
                -- Objeto slider para retornar
                local slider = {
                    Value = sliderValue,
                    Set = function(self, value)
                        value = math.clamp(value, min, max)
                        sliderValue = value
                        valueLabel.Text = tostring(value)
                        
                        local percentage = (value - min) / (max - min)
                        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                        
                        if callback then
                            callback(value)
                        end
                    end
                }
                
                return slider
            end
            
            return section
        end
        
        -- Selecionar este tab se for o primeiro
        if UI.CurrentTab == nil then
            UI:SelectTab(name)
        end
        
        return tab
    end
    
    -- Função para selecionar um tab
    function UI:SelectTab(name)
        if UI.CurrentTab == name then return end
        
        -- Resetar cores de todos os tabs
        for tabName, tabButton in pairs(UI.Tabs) do
            local tween = Utility.CreateTween(tabButton, TweenInfo.new(0.2), {
                BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement
            })
            tween:Play()
        end
        
        -- Esconder todas as páginas
        for pageName, page in pairs(UI.Pages) do
            page.Visible = false
        end
        
        -- Destacar o tab selecionado
        if UI.Tabs[name] then
            local tween = Utility.CreateTween(UI.Tabs[name], TweenInfo.new(0.2), {
                BackgroundColor3 = UniversalUI.Settings.Theme.AccentColor
            })
            tween:Play()
        end
        
        -- Mostrar a página selecionada
        if UI.Pages[name] then
            UI.Pages[name].Visible = true
        end
        
        UI.CurrentTab = name
    end
    
    -- Aplicar tecla de atalho para mostrar/esconder a UI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == UniversalUI.Settings.ToggleKey then
            UI.ScreenGui.Enabled = not UI.ScreenGui.Enabled
        end
    end)
    
    return UI
end

-- Retornar o módulo
return UniversalUI
