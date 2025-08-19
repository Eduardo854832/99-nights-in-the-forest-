--[[
Universal Hub - Menu Base (Somente Interface)
Autor: Você
Uso: Colocar em StarterPlayerScripts (LocalScript)
Este script cria somente a UI base inspirada no layout mostrado na imagem do usuário.
Não contém lógica de autofarm, teleporte, etc. (adicione de forma legítima para o seu jogo).

Licença sugerida: MIT (ou escolha outra) - ajuste conforme seu projeto.
]]

--------------------------
-- Config / Tema
--------------------------
local THEME = {
    Background = Color3.fromRGB(24, 24, 24),
    BackgroundAlt = Color3.fromRGB(30, 30, 30),
    Accent = Color3.fromRGB(60, 100, 255),
    AccentHover = Color3.fromRGB(80, 120, 255),
    TextPrimary = Color3.fromRGB(235, 235, 235),
    TextSecondary = Color3.fromRGB(180, 180, 180),
    Section = Color3.fromRGB(40, 40, 40),
    ToggleOn = Color3.fromRGB(90, 170, 90),
    ToggleOff = Color3.fromRGB(80, 80, 80),
    Border = Color3.fromRGB(55, 55, 55),
    Danger = Color3.fromRGB(200, 70, 70),
}

local UI_SIZES = {
    Small = 0.9,
    Medium = 1,
    Large = 1.1,
}

--------------------------
-- Helpers
--------------------------
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function create(instanceType, props, children)
    local obj = Instance.new(instanceType)
    for k,v in pairs(props or {}) do
        obj[k] = v
    end
    for _,child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function applyStroke(parent, color, thickness)
    create("UIStroke", {
        Color = color or THEME.Border,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, {}).Parent = parent
end

--------------------------
-- Root ScreenGui
--------------------------
local screenGui = create("ScreenGui", {
    Name = "UniversalHubMenu",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Global,
}, {})
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--------------------------
-- Draggable Window
--------------------------
local window = create("Frame", {
    Name = "Window",
    Size = UDim2.fromOffset(1050, 520),
    Position = UDim2.new(0.5, -525, 0.5, -260),
    BackgroundColor3 = THEME.Background,
    BorderSizePixel = 0,
}, {
    create("UICorner",{CornerRadius = UDim.new(0,8)}),
})
window.Parent = screenGui
applyStroke(window, THEME.Border, 1)

-- Top bar
local topBar = create("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = THEME.BackgroundAlt,
    BorderSizePixel = 0,
}, {
    create("UICorner",{CornerRadius = UDim.new(0,8)}),
})
topBar.Parent = window

local titleLabel = create("TextLabel", {
    Name = "Title",
    Text = "universal Hub : Demo  by você",
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextColor3 = THEME.TextPrimary,
    BackgroundTransparency = 1,
    Size = UDim2.new(1, -140, 1, 0),
    Position = UDim2.fromOffset(16, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
}, {})
titleLabel.Parent = topBar

local function makeTopButton(name, text, color)
    local btn = create("TextButton", {
        Name = name,
        Text = text,
        Font = Enum.Font.Gotham,
        TextSize = 18,
        TextColor3 = THEME.TextPrimary,
        BackgroundColor3 = THEME.Background,
        AutoButtonColor = false,
        Size = UDim2.fromOffset(38, 30),
    }, {
        create("UICorner",{CornerRadius = UDim.new(0,6)}),
    })
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = THEME.BackgroundAlt
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = THEME.Background
    end)
    return btn
end

local closeBtn = makeTopButton("Close","×")
closeBtn.Position = UDim2.new(1, -46, 0.5, -15)
closeBtn.Parent = topBar

local miniBtn = makeTopButton("Minimize","–")
miniBtn.Position = UDim2.new(1, -92, 0.5, -15)
miniBtn.Parent = topBar

local minimized = false
miniBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _,child in ipairs(window:GetChildren()) do
        if child ~= topBar then
            child.Visible = not minimized
        end
    end
    window.Size = minimized and UDim2.fromOffset(300, 60) or UDim2.fromOffset(1050, 520)
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)

-- Dragging
local dragging = false
local dragStart, startPos
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = window.Position
    end
end)
topBar.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

--------------------------
-- Sidebar
--------------------------
local sidebar = create("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 220, 1, -42),
    Position = UDim2.fromOffset(0, 42),
    BackgroundColor3 = THEME.BackgroundAlt,
    BorderSizePixel = 0,
}, {
    create("UICorner",{CornerRadius = UDim.new(0,8)}),
    create("UIListLayout",{
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,6),
    }),
    create("UIPadding",{
        PaddingTop = UDim.new(0,10),
        PaddingLeft = UDim.new(0,10),
        PaddingRight = UDim.new(0,10),
        PaddingBottom = UDim.new(0,10),
    }),
})
sidebar.Parent = window

local categories = {
    {id="Discord", icon="◉"},
    {id="Farmar", icon="🏠"},
    {id="Missões/Itens", icon="🗡"},
    {id="Fruta/Raid", icon="🍎"},
    {id="Hop", icon="💎"},
    {id="Stats", icon="📊"},
    {id="Teleporte", icon="🧭"},
    {id="Status", icon="⚙"},
    {id="Visual", icon="👁"},
}

local categoryButtons = {}
local activeCategory = nil

local function selectCategory(id)
    activeCategory = id
    for _,btn in pairs(categoryButtons) do
        if btn.Name == id then
            btn.BackgroundColor3 = THEME.Accent
            btn.TextColor3 = Color3.fromRGB(255,255,255)
        else
            btn.BackgroundColor3 = THEME.Section
            btn.TextColor3 = THEME.TextPrimary
        end
    end
    -- Trocar página
    for _,page in ipairs(window.ContentHolder:GetChildren()) do
        if page:IsA("Frame") then
            page.Visible = (page.Name == id)
        end
    end
end

local function makeCategoryButton(cat)
    local btn = create("TextButton", {
        Name = cat.id,
        Text = string.format("  %s  %s", cat.icon, cat.id),
        Font = Enum.Font.GothamSemibold,
        TextSize = 16,
        TextColor3 = THEME.TextPrimary,
        AutoButtonColor = false,
        BackgroundColor3 = THEME.Section,
        Size = UDim2.new(1, 0, 0, 40),
    }, {
        create("UICorner",{CornerRadius = UDim.new(0,6)})
    })
    btn.Parent = sidebar
    btn.MouseEnter:Connect(function()
        if activeCategory ~= btn.Name then
            btn.BackgroundColor3 = THEME.Background
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeCategory ~= btn.Name then
            btn.BackgroundColor3 = THEME.Section
        end
    end)
    btn.MouseButton1Click:Connect(function()
        selectCategory(btn.Name)
    end)
    categoryButtons[#categoryButtons+1] = btn
end

for _,cat in ipairs(categories) do
    makeCategoryButton(cat)
end

--------------------------
-- Content Area
--------------------------
local contentHolder = create("Frame", {
    Name = "ContentHolder",
    Size = UDim2.new(1, -230, 1, -52),
    Position = UDim2.new(0, 230, 0, 52),
    BackgroundTransparency = 1,
}, {})
contentHolder.Parent = window

--------------------------
-- UI Components (Factory)
--------------------------
local ComponentFactory = {}

function ComponentFactory:SectionTitle(parent, text)
    local lbl = create("TextLabel", {
        Name = "SectionTitle",
        Text = text,
        Font = Enum.Font.GothamBold,
        TextColor3 = THEME.TextPrimary,
        TextSize = 20,
        BackgroundColor3 = THEME.BackgroundAlt,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, {
        create("UIPadding",{PaddingLeft=UDim.new(0,14)})
    })
    lbl.Parent = parent
    return lbl
end

function ComponentFactory:Expander(parent, title, subtitle)
    local container = create("Frame", {
        Name = "Expander_"..title,
        BackgroundColor3 = THEME.Section,
        Size = UDim2.new(1, 0, 0, 70),
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, {
        create("UICorner",{CornerRadius = UDim.new(0,6)}),
    })
    container.Parent = parent
    applyStroke(container, THEME.Border, 1)

    local header = create("TextButton", {
        Name = "Header",
        Font = Enum.Font.GothamSemibold,
        Text = "",
        TextSize = 16,
        TextColor3 = THEME.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 50),
        AutoButtonColor = false,
    }, {})
    header.Parent = container

    local titleLbl = create("TextLabel", {
        Name = "Title",
        Text = title,
        Font = Enum.Font.GothamSemibold,
        TextSize = 16,
        TextColor3 = THEME.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.6, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(14,0),
    }, {})
    titleLbl.Parent = header

    local subLbl = create("TextLabel", {
        Name = "Subtitle",
        Text = subtitle or "",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = THEME.TextSecondary,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.6, 0, 1, -18),
        Position = UDim2.fromOffset(14, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, {})
    subLbl.Parent = header

    local arrow = create("TextLabel", {
        Name = "Arrow",
        Text = "˄",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = THEME.TextSecondary,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -40, 0.5, -15),
    }, {})
    arrow.Parent = header

    local content = create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -28, 0, 0),
        Position = UDim2.fromOffset(14, 54),
    }, {
        create("UIListLayout",{
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0,8),
        })
    })
    content.Parent = container

    local expanded = false
    local tweenService = game:GetService("TweenService")

    local function setExpanded(state)
        expanded = state
        arrow.Rotation = state and 0 or 180
        local targetHeight = state and (54 + content.UIListLayout.AbsoluteContentSize.Y + 16) or 70
        tweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, targetHeight)
        }):Play()
    end

    content.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if expanded then
            container.Size = UDim2.new(1,0,0,54 + content.UIListLayout.AbsoluteContentSize.Y + 16)
        end
    end)

    header.MouseButton1Click:Connect(function()
        setExpanded(not expanded)
    end)

    return content, setExpanded
end

function ComponentFactory:Dropdown(parent, labelText, options, default, callback)
    local frame = create("Frame", {
        Name = "Dropdown_"..labelText,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = THEME.Section,
        BorderSizePixel = 0,
    }, {
        create("UICorner",{CornerRadius = UDim.new(0,6)}),
    })
    applyStroke(frame, THEME.Border, 1)
    frame.Parent = parent

    local label = create("TextLabel", {
        Text = labelText,
        Font = Enum.Font.GothamSemibold,
        TextSize = 15,
        TextColor3 = THEME.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5,-10,1,-10),
        Position = UDim2.fromOffset(14, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, {})
    label.Parent = frame

    local current = default or options[1]
    local mainBtn = create("TextButton", {
        Text = current,
        Font = Enum.Font.GothamSemibold,
        TextSize = 16,
        TextColor3 = THEME.TextPrimary,
        BackgroundColor3 = THEME.BackgroundAlt,
        AutoButtonColor = false,
        Size = UDim2.new(0, 220, 0, 34),
        Position = UDim2.new(1, -234, 0.5, -17),
    }, {
        create("UICorner",{CornerRadius = UDim.new(0,6)}),
    })
    mainBtn.Parent = frame

    local listFrame = create("Frame", {
        Name = "List",
        BackgroundColor3 = THEME.BackgroundAlt,
        BorderSizePixel = 0,
        Position = UDim2.new(1,-234,0,50),
        Size = UDim2.new(0,220,0,0),
        ClipsDescendants = true,
        Visible = false,
    }, {
        create("UICorner",{CornerRadius = UDim.new(0,6)}),
        create("UIListLayout",{
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0,2),
        })
    })
    listFrame.Parent = frame
    applyStroke(listFrame, THEME.Border, 1)

    local open = false
    local tweenService = game:GetService("TweenService")

    local function toggleOpen()
        open = not open
        listFrame.Visible = true
        local target = open and (#options * 30 + 10) or 0
        tweenService:Create(listFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0,220,0,target)
        }):Play()
        if not open then
            task.delay(0.25, function()
                if not open then listFrame.Visible = false end
            end)
        end
    end

    mainBtn.MouseButton1Click:Connect(toggleOpen)

    for _,opt in ipairs(options) do
        local optBtn = create("TextButton", {
            Text = opt,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextColor3 = THEME.TextPrimary,
            BackgroundColor3 = THEME.Section,
            AutoButtonColor = false,
            Size = UDim2.new(1, -10, 0, 28),
        }, {
            create("UICorner",{CornerRadius = UDim.new(0,6)}),
        })
        optBtn.Parent = listFrame
        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundColor3 = THEME.Background
        end)
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundColor3 = THEME.Section
        end)
        optBtn.MouseButton1Click:Connect(function()
            current = opt
            mainBtn.Text = opt
            if callback then
                task.spawn(callback, opt)
            end
            toggleOpen()
        end)
    end

    return {
        Set = function(val)
            if table.find(options, val) then
                current = val
                mainBtn.Text = val
            end
        end,
        Get = function() return current end
    }
end

function ComponentFactory:Toggle(parent, labelText, default, callback)
    local frame = create("Frame", {
        Name = "Toggle_"..labelText,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = THEME.Section,
        BorderSizePixel = 0,
    }, {
        create("UICorner",{CornerRadius = UDim.new(0,6)}),
    })
    applyStroke(frame, THEME.Border, 1)
    frame.Parent = parent

    local label = create("TextLabel", {
        Text = labelText,
        Font = Enum.Font.GothamSemibold,
        TextSize = 15,
        TextColor3 = THEME.TextPrimary,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-90,1,0),
        Position = UDim2.fromOffset(14,0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, {})
    label.Parent = frame

    local btn = create("TextButton", {
        Text = "",
        BackgroundColor3 = default and THEME.ToggleOn or THEME.ToggleOff,
        AutoButtonColor = false,
        Size = UDim2.fromOffset(54, 26),
        Position = UDim2.new(1, -70, 0.5, -13),
    }, {
        create("UICorner",{CornerRadius = UDim.new(1,0)}),
    })
    btn.Parent = frame

    local knob = create("Frame", {
        Name = "Knob",
        Size = UDim2.fromOffset(22,22),
        Position = default and UDim2.fromOffset(28,2) or UDim2.fromOffset(4,2),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BorderSizePixel = 0,
    }, {
        create("UICorner",{CornerRadius = UDim.new(1,0)}),
    })
    knob.Parent = btn

    local state = default or false
    local tweenService = game:GetService("TweenService")

    local function setState(newState, fire)
        state = newState
        tweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = state and THEME.ToggleOn or THEME.ToggleOff
        }):Play()
        tweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = state and UDim2.fromOffset(28,2) or UDim2.fromOffset(4,2)
        }):Play()
        if fire and callback then
            task.spawn(callback, state)
        end
    end

    btn.MouseButton1Click:Connect(function()
        setState(not state, true)
    end)

    return {
        Set = function(v) setState(v, true) end,
        Get = function() return state end,
    }
end

--------------------------
-- Criar páginas (exemplo)
--------------------------
local function createPage(name)
    local page = create("Frame", {
        Name = name,
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0),
        Visible = false,
    }, {})
    page.Parent = contentHolder

    local list = create("ScrollingFrame", {
        Name = "Scroll",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.fromOffset(5,5),
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 6,
    }, {
        create("UIListLayout",{
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0,10),
        })
    })
    list.Parent = page

    list.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        list.CanvasSize = UDim2.new(0,0,0,list.UIListLayout.AbsoluteContentSize.Y + 20)
    end)

    return page, list
end

-- Página "Farmar" (exemplo principal)
local farmarPage, farmarList = createPage("Farmar")

-- Expanders iniciais imitando parte do layout
local toolContent = ComponentFactory:Expander(farmarList, "Selecionar Ferramenta", "Escolha a ferramenta que deseja usar")
local toolDropdown = ComponentFactory:Dropdown(toolContent, "Ferramenta", {"Melee","Espada","Arma","Fruta"}, "Melee", function(val)
    print("Ferramenta escolhida:", val)
    -- TODO: Lógica
end)

local uiSizeContent = ComponentFactory:Expander(farmarList, "Tamanho da UI", "Ajuste o tamanho da interface de usuário")
local uiSizeDropdown = ComponentFactory:Dropdown(uiSizeContent, "Escala", {"Small","Medium","Large"}, "Large", function(sizeName)
    local scale = UI_SIZES[sizeName] or 1
    window.Size = UDim2.fromOffset(1050 * scale, 520 * scale)
    window.Position = UDim2.new(0.5, -window.Size.X.Offset/2, 0.5, -window.Size.Y.Offset/2)
end)

local farmSectionTitle = ComponentFactory:SectionTitle(farmarList, "Farmar")

local autoLevelToggle = ComponentFactory:Toggle(farmarList, "Level Automático", false, function(state)
    print("Auto Level:", state)
    -- TODO: Lógica
end)

local nearEnemyToggle = ComponentFactory:Toggle(farmarList, "Farmar Inimigos Próximos", false, function(state)
    print("Farmar Inimigos Próximos:", state)
    -- TODO
end)

local chestSectionTitle = ComponentFactory:SectionTitle(farmarList, "Baús")

local chestToggle = ComponentFactory:Toggle(farmarList, "Auto Baús [Tween]", false, function(state)
    print("Auto Baús:", state)
    -- TODO
end)

local bossesSectionTitle = ComponentFactory:SectionTitle(farmarList, "Chefes")

-- Abra expanders automaticamente
task.delay(0.3, function()
    -- Abre dois primeiros expanders
    local _,openTool = nil,nil
end)

-- Outras páginas vazias (placeholder)
for _,cat in ipairs(categories) do
    if cat.id ~= "Farmar" then
        createPage(cat.id)
    end
end

-- Selecionar categoria padrão
selectCategory("Farmar")

-- Abre expanders por padrão (após criação)
task.defer(function()
    -- Forçar abrir
    for _,child in ipairs(farmarList:GetChildren()) do
        if child:IsA("Frame") and child.Name:find("^Expander_") then
            local content = child:FindFirstChild("Content")
            if content then
                -- Simular clique abrindo via setExpanded se disponível (guardado em closure; simplificado omitido)
                -- Em vez disso, redimensionar manualmente:
                local layout = content:FindFirstChildOfClass("UIListLayout")
                task.wait()
                child.Size = UDim2.new(1,0,0,54 + (layout and layout.AbsoluteContentSize.Y or 0) + 16)
            end
        end
    end
end)

--------------------------
-- Ajuste de Escala global (UIAspect)
--------------------------
-- (Opcional) Poderia adicionar um UIScale para facilitar
local uiScale = create("UIScale", {Scale = 1})
uiScale.Parent = window

print("Menu carregado. Adicione sua lógica nos callbacks (TODO).")