--[[
    Universal Roblox UI Script
    Autor: Eduardo854832
    Data: 2025-08-17 (Mobile Adapted)
    
    Alterações para compatibilidade Mobile:
    - Botão flutuante para abrir/fechar a UI em dispositivos móveis (caso não haja teclado).
    - Drag da janela com toque (Touch) além do mouse.
    - Sliders agora funcionam com toque (seguindo o dedo).
    - Removido bloqueio dependente apenas de tecla (RightShift continua para PC).
    - Ajuste automático de escala para telas menores (ex.: celulares).
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local UniversalUI = {}

UniversalUI.Settings = {
    Title = "Universal Hub",
    Subtitle = "by Eduardo854832",
    ToggleKey = Enum.KeyCode.RightShift, -- Continua funcionando no PC
    Theme = {
        Background = Color3.fromRGB(25, 25, 25),
        SidebarBackground = Color3.fromRGB(30, 30, 30),
        TopbarBackground = Color3.fromRGB(30, 30, 30),
        SectionBackground = Color3.fromRGB(35, 35, 35),
        DarkElement = Color3.fromRGB(40, 40, 40),
        LightText = Color3.fromRGB(255, 255, 255),
        DarkText = Color3.fromRGB(175, 175, 175),
        AccentColor = Color3.fromRGB(255, 0, 0),
        SelectedColor = Color3.fromRGB(50, 50, 50),
        ToggleOff = Color3.fromRGB(60, 60, 60),
        ToggleOn = Color3.fromRGB(255, 0, 0)
    },
    Mobile = {
        UseFloatingButton = true,
        FloatingButtonSize = UDim2.new(0, 48, 0, 48),
        FloatingButtonPosition = UDim2.new(0, 15, 1, -65),
        FloatingButtonColor = Color3.fromRGB(255, 0, 0),
        FloatingButtonText = "UI"
    }
}

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

function UniversalUI.new(title, subtitle)
    local UI = {}
    UI.Title = title or UniversalUI.Settings.Title
    UI.Subtitle = subtitle or UniversalUI.Settings.Subtitle

    UI.ScreenGui = Utility.Create("ScreenGui", {
        Name = "UniversalUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        IgnoreGuiInset = false
    })

    local success, _ = pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(UI.ScreenGui)
            UI.ScreenGui.Parent = game:GetService("CoreGui")
        elseif gethui then
            UI.ScreenGui.Parent = gethui()
        else
            UI.ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end)
    if not success then
        UI.ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local uiScale = Utility.Create("UIScale", {Parent = UI.ScreenGui})
    local function applyScale()
        local cam = workspace.CurrentCamera
        local screenSize = cam and cam.ViewportSize or Vector2.new(1280, 720)
        if screenSize.X <= 900 then
            uiScale.Scale = math.clamp(screenSize.X / 900, 0.7, 1)
        else
            uiScale.Scale = 1
        end
    end
    applyScale()
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.wait(0.25)
        applyScale()
    end)
    RunService.RenderStepped:Connect(applyScale)

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

    local dragging = false
    local dragInput
    local dragStart
    local startPos

    local function updateDrag(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        UI.MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    UI.TopBar = Utility.Create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = UniversalUI.Settings.Theme.TopbarBackground,
        BorderSizePixel = 0,
        Parent = UI.MainFrame,
    })

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

    UI.TitleLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        UI.SubtitleLabel.Position = UDim2.new(0, UI.TitleLabel.AbsoluteSize.X + 5, 0, 0)
    end)

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

    UI.TopBar.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1)
            or (input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true
            dragStart = input.Position
            startPos = UI.MainFrame.Position
            dragInput = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UI.TopBar.InputChanged:Connect(function(input)
        if input == dragInput and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateDrag(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            updateDrag(input)
        end
    end)

    UI.MinimizeButton.MouseButton1Click:Connect(function()
        local normal = UDim2.new(0, 800, 0, 450)
        local minimized = UDim2.new(0, 800, 0, 36)
        local target = (UI.MainFrame.Size == normal) and minimized or normal
        Utility.CreateTween(UI.MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = target
        }):Play()
    end)

    UI.CloseButton.MouseButton1Click:Connect(function()
        UI.ScreenGui:Destroy()
    end)

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

    UI.SidebarLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        UI.Sidebar.CanvasSize = UDim2.new(0, 0, 0, UI.SidebarLayout.AbsoluteContentSize.Y + 10)
    end)

    UI.Content = Utility.Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -220, 1, -36),
        Position = UDim2.new(0, 220, 0, 36),
        BackgroundColor3 = UniversalUI.Settings.Theme.Background,
        BorderSizePixel = 0,
        Parent = UI.MainFrame,
    })

    UI.Pages = {}
    UI.Tabs = {}
    UI.CurrentTab = nil

    function UI:AddTab(name, icon)
        local tabButton = Utility.Create("TextButton", {
            Name = name .. "Tab",
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = UI.Sidebar,
        })

        if icon then
            Utility.Create("ImageLabel", {
                Name = "Icon",
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, 10, 0.5, -10),
                BackgroundTransparency = 1,
                Image = icon,
                Parent = tabButton,
            })
        end

        Utility.Create("TextLabel", {
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

        local pageLayout = Utility.Create("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = page,
        })

        Utility.Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim2.new(0, 10),
            Parent = page,
        })

        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 20)
        end)

        UI.Tabs[name] = tabButton
        UI.Pages[name] = page

        tabButton.MouseButton1Click:Connect(function()
            UI:SelectTab(name)
        end)

        tabButton.MouseEnter:Connect(function()
            if UI.CurrentTab ~= name then
                Utility.CreateTween(tabButton, TweenInfo.new(0.2), {
                    BackgroundColor3 = UniversalUI.Settings.Theme.SelectedColor
                }):Play()
            end
        end)

        tabButton.MouseLeave:Connect(function()
            if UI.CurrentTab ~= name then
                Utility.CreateTween(tabButton, TweenInfo.new(0.2), {
                    BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement
                }):Play()
            end
        end)

        local tab = {}

        function tab:AddSection(sectionName)
            local section = {}

            local sectionFrame = Utility.Create("Frame", {
                Name = sectionName .. "Section",
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = UniversalUI.Settings.Theme.SectionBackground,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = page,
            })

            local sectionTop = Utility.Create("Frame", {
                Name = "SectionTop",
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement,
                BorderSizePixel = 0,
                Parent = sectionFrame,
            })

            Utility.Create("TextLabel", {
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

            local sectionContainer = Utility.Create("Frame", {
                Name = "SectionContainer",
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 36),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClipsDescendants = true,
                Parent = sectionFrame,
            })

            local sectionLayout = Utility.Create("UIListLayout", {
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = sectionContainer,
            })

            Utility.Create("UIPadding", {
                PaddingTop = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim2.new(0, 10),
                Parent = sectionContainer,
            })

            local isExpanded = false
            local containerSize = 0

            sectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                containerSize = sectionLayout.AbsoluteContentSize.Y + 10
                if isExpanded then
                    sectionFrame.Size = UDim2.new(1, 0, 0, 36 + containerSize)
                    sectionContainer.Size = UDim2.new(1, 0, 0, containerSize)
                end
            end)

            expandButton.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                Utility.CreateTween(expandButton, TweenInfo.new(0.3), {
                    Rotation = isExpanded and 180 or 0
                }):Play()

                Utility.CreateTween(sectionFrame, TweenInfo.new(0.3), {
                    Size = isExpanded and UDim2.new(1, 0, 0, 36 + containerSize) or UDim2.new(1, 0, 0, 36)
                }):Play()

                Utility.CreateTween(sectionContainer, TweenInfo.new(0.3), {
                    Size = isExpanded and UDim2.new(1, 0, 0, containerSize) or UDim2.new(1, 0, 0, 0)
                }):Play()
            end)

            function section:AddToggle(text, default, callback)
                local toggleValue = default or false
                local toggleFrame = Utility.Create("Frame", {
                    Name = text .. "Toggle",
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Parent = sectionContainer,
                })

                Utility.Create("TextLabel", {
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
                Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleBackground})

                local toggleIndicator = Utility.Create("Frame", {
                    Name = "Indicator",
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(toggleValue and 0.6 or 0, 2, 0, 2),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Parent = toggleBackground,
                })
                Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = toggleIndicator})

                local toggleButton = Utility.Create("TextButton", {
                    Name = "ToggleButton",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = toggleFrame,
                })

                local function setState(val)
                    toggleValue = val
                    Utility.CreateTween(toggleIndicator, TweenInfo.new(0.2), {
                        Position = toggleValue and UDim2.new(0.6, 0, 0, 2) or UDim2.new(0, 2, 0, 2)
                    }):Play()
                    Utility.CreateTween(toggleBackground, TweenInfo.new(0.2), {
                        BackgroundColor3 = toggleValue and UniversalUI.Settings.Theme.ToggleOn or UniversalUI.Settings.Theme.ToggleOff
                    }):Play()
                    if callback then callback(toggleValue) end
                end

                toggleButton.MouseButton1Click:Connect(function()
                    setState(not toggleValue)
                end)

                local toggle = {
                    Value = toggleValue,
                    Set = function(self, value)
                        setState(value)
                    end
                }
                return toggle
            end

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
                Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = button})

                button.MouseEnter:Connect(function()
                    Utility.CreateTween(button, TweenInfo.new(0.2), {
                        BackgroundColor3 = UniversalUI.Settings.Theme.AccentColor
                    }):Play()
                end)
                button.MouseLeave:Connect(function()
                    Utility.CreateTween(button, TweenInfo.new(0.2), {
                        BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement
                    }):Play()
                end)
                button.MouseButton1Click:Connect(function()
                    if callback then callback() end
                end)
                return button
            end

            function section:AddDropdown(text, options, default, callback)
                options = options or {}
                local dropdownValue = default or options[1] or ""
                local dropdownFrame = Utility.Create("Frame", {
                    Name = text .. "Dropdown",
                    Size = UDim2.new(1, 0, 0, 55),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true,
                    Parent = sectionContainer,
                })

                Utility.Create("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, 0, 0, 20),
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
                Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = dropdownButton})

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
                Utility.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = dropdownMenu})

                local optionLayout = Utility.Create("UIListLayout", {
                    Padding = UDim.new(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = dropdownMenu,
                })

                local isOpen = false
                local menuHeight = 0

                local function addOption(option)
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
                        if callback then callback(option) end
                    end)
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

                for _, option in ipairs(options) do
                    addOption(option)
                end

                optionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    menuHeight = optionLayout.AbsoluteContentSize.Y
                    dropdownMenu.Size = UDim2.new(1, 0, 0, menuHeight)
                end)

                dropdownButton.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        dropdownFrame.Size = UDim2.new(1, 0, 0, 55 + menuHeight)
                        dropdownMenu.Visible = true
                        Utility.CreateTween(dropdownIcon, TweenInfo.new(0.2), {Rotation = 180}):Play()
                    else
                        dropdownFrame.Size = UDim2.new(1, 0, 0, 55)
                        dropdownMenu.Visible = false
                        Utility.CreateTween(dropdownIcon, TweenInfo.new(0.2), {Rotation = 0}):Play()
                    end
                end)

                local dropdown = {
                    Value = dropdownValue,
                    Options = options,
                    Set = function(self, value)
                        if table.find(options, value) then
                            dropdownValue = value
                            dropdownButton.Text = value
                            if callback then callback(value) end
                        end
                    end,
                    AddOption = function(self, option)
                        if not table.find(options, option) then
                            table.insert(options, option)
                            addOption(option)
                        end
                    end
                }
                return dropdown
            end

            function section:AddSlider(text, min, max, default, callback)
                local sliderValue = default or min
                local sliderFrame = Utility.Create("Frame", {
                    Name = text .. "Slider",
                    Size = UDim2.new(1, 0, 0, 55),
                    BackgroundTransparency = 1,
                    Parent = sectionContainer,
                })

                Utility.Create("TextLabel", {
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
                Utility.Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = sliderBackground})

                local sliderFill = Utility.Create("Frame", {
                    Name = "Fill",
                    Size = UDim2.new((sliderValue - min) / (max - min), 0, 1, 0),
                    BackgroundColor3 = UniversalUI.Settings.Theme.AccentColor,
                    BorderSizePixel = 0,
                    Parent = sliderBackground,
                })
                Utility.Create("UICorner", {CornerRadius = UDim.new(0, 5), Parent = sliderFill})

                local sliderButton = Utility.Create("TextButton", {
                    Name = "Button",
                    Size = UDim2.new(1, 0, 0, 25),
                    Position = UDim2.new(0, 0, 0, 25),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = sliderFrame,
                })

                local draggingSlider = false
                local inputObj

                local function setSliderFromPosition(x)
                    local rel = math.clamp(x - sliderBackground.AbsolutePosition.X, 0, sliderBackground.AbsoluteSize.X)
                    local percent = rel / sliderBackground.AbsoluteSize.X
                    local newValue = min + (max - min) * percent
                    if math.floor(min) == min and math.floor(max) == max then
                        newValue = math.round(newValue)
                    else
                        newValue = Utility.Round(newValue, 1)
                    end
                    sliderValue = newValue
                    sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                    valueLabel.Text = tostring(sliderValue)
                    if callback then callback(sliderValue) end
                end

                local function beginDrag(input)
                    draggingSlider = true
                    inputObj = input
                    setSliderFromPosition(input.Position.X)
                end

                sliderButton.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        beginDrag(input)
                    end
                end)

                sliderButton.InputEnded:Connect(function(input)
                    if input == inputObj then
                        draggingSlider = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and input == inputObj then
                        setSliderFromPosition(input.Position.X)
                    end
                end)

                local slider = {
                    Value = sliderValue,
                    Set = function(self, value)
                        value = math.clamp(value, min, max)
                        sliderValue = value
                        local percent = (value - min) / (max - min)
                        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                        valueLabel.Text = tostring(value)
                        if callback then callback(value) end
                    end
                }
                return slider
            end

            return section
        end

        if UI.CurrentTab == nil then
            UI:SelectTab(name)
        end

        return tab
    end

    function UI:SelectTab(name)
        if UI.CurrentTab == name then return end
        for _, tabButton in pairs(UI.Tabs) do
            Utility.CreateTween(tabButton, TweenInfo.new(0.2), {
                BackgroundColor3 = UniversalUI.Settings.Theme.DarkElement
            }):Play()
        end
        for _, page in pairs(UI.Pages) do
            page.Visible = false
        end
        if UI.Tabs[name] then
            Utility.CreateTween(UI.Tabs[name], TweenInfo.new(0.2), {
                BackgroundColor3 = UniversalUI.Settings.Theme.AccentColor
            }):Play()
        end
        if UI.Pages[name] then
            UI.Pages[name].Visible = true
        end
        UI.CurrentTab = name
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == UniversalUI.Settings.ToggleKey then
            UI.ScreenGui.Enabled = not UI.ScreenGui.Enabled
        end
    end)

    if UserInputService.TouchEnabled and UniversalUI.Settings.Mobile.UseFloatingButton then
        UI.FloatingButton = Utility.Create("TextButton", {
            Name = "FloatingToggle",
            Size = UniversalUI.Settings.Mobile.FloatingButtonSize,
            Position = UniversalUI.Settings.Mobile.FloatingButtonPosition,
            AnchorPoint = Vector2.new(0, 0),
            BackgroundColor3 = UniversalUI.Settings.Mobile.FloatingButtonColor,
            Text = UniversalUI.Settings.Mobile.FloatingButtonText,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            Parent = UI.ScreenGui,
            AutoButtonColor = true
        })
        Utility.Create("UICorner", {CornerRadius = UDim.new(1, 0), Parent = UI.FloatingButton})

        local fbDragging = false
        local fbDragStart
        local fbStartPos
        local fbDragInput

        UI.FloatingButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                fbDragging = true
                fbDragStart = input.Position
                fbStartPos = UI.FloatingButton.Position
                fbDragInput = input
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        fbDragging = false
                    end
                end)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                fbDragging = true
                fbDragStart = input.Position
                fbStartPos = UI.FloatingButton.Position
                fbDragInput = input
            end
        end)

        UI.FloatingButton.InputChanged:Connect(function(input)
            if input == fbDragInput then
                local delta = input.Position - fbDragStart
                UI.FloatingButton.Position = UDim2.new(
                    fbStartPos.X.Scale,
                    fbStartPos.X.Offset + delta.X,
                    fbStartPos.Y.Scale,
                    fbStartPos.Y.Offset + delta.Y
                )
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input == fbDragInput then
                fbDragging = false
            end
        end)

        UI.FloatingButton.MouseButton1Click:Connect(function()
            if not fbDragging then
                UI.ScreenGui.Enabled = not UI.ScreenGui.Enabled
                if UI.ScreenGui.Enabled then
                    UI.MainFrame.Visible = true
                end
            end
        end)
    end

    return UI
end

return UniversalUI
