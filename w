--[[
    ========================================================================
    [ TWISTED UI: RGB EDITION (LANDSCAPE PRO V39) - ROLLBACK TO STABLE ]
    Status: REVERTED TO 100% WORKING VERSION (NO UICORNER/TWEENS)
    ========================================================================
]]

print("[TWISTED] Step 1: Initializing...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

print("[TWISTED] Step 2: Waiting for LocalPlayer...")
local lp = Players.LocalPlayer
while not lp do 
    task.wait(0.1)
    lp = Players.LocalPlayer 
end

local camera = workspace.CurrentCamera
if not camera then
    workspace:GetPropertyChangedSignal("CurrentCamera"):Wait()
    camera = workspace.CurrentCamera
end

local function genName()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    local str = "GUI_"
    for i = 1, 20 do 
        str = str .. string.sub(chars, math.random(1, #chars), math.random(1, #chars)) 
    end
    return str
end

local function getTornadoWindSpeed(model)
    local exactSpeed = nil
    local bestSpeed = 0
    if not model then return "???" end
    
    local function checkValue(name, val)
        if type(val) == "number" and val > bestSpeed and val < 600 then
            local n = string.lower(name)
            if n:find("move") or n:find("walk") or n:find("rate") or n:find("particle") or n:find("pitch") or n:find("vol") then return end
            if n == "windspeed" or n == "intensity" then 
                exactSpeed = val 
            elseif n:find("wind") or n:find("speed") or n:find("mph") then 
                bestSpeed = val 
            end
        end
    end
    
    for attr, val in pairs(model:GetAttributes()) do 
        checkValue(attr, val) 
    end
    
    for _, v in pairs(model:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then 
            checkValue(v.Name, v.Value)
        elseif v:IsA("StringValue") then
            local num = tonumber(string.match(v.Value, "%d+"))
            if num then checkValue(v.Name, num) end
        end
    end
    
    if exactSpeed then return math.floor(exactSpeed) .. " MPH" end
    if bestSpeed > 0 then return math.floor(bestSpeed) .. " MPH" end
    return "???"
end

-- =================[ ГРУППИРОВКА ПЕРЕМЕННЫХ ]=================
local T = {
    State = {
        CarFly = false, TruckFly = false, Godmode = false, TornadoESP = false,
        PlayerESP = false, Noclip = false, FpsBoost = false, Fullbright = false, MyCarESP = false,
        ShowActiveMods = false
    },
    Pools = {
        binds = {}, shootingStars = {}, rain = {}, snow = {}, trail = {}, cosmos = {},
        tornados = {}, playerEsps = {}, traps = {nil, nil, nil}, welds = {}, partProps = {}, trailerData = {}, tabBtns = {},
        sliders = {}, bgTornadoParticles = {}
    },
    Vars = {
        mySmartCar = nil, origGravity = workspace.Gravity, lastMouse = Vector2.new(0,0),
        starSpeed = 0.8, trailIdx = 1, activeTheme = "RED",
        carSpeed = 100, truckSpeed = 100, pathLen = 15, pathWid = 12,
        lastTScan = 0, fpsLT = tick(), frC = 0, currentBind = nil, activeSlider = nil, currentActiveTabBtn = nil,
        Setters = {} 
    },
    UI = {}
}

local UI_TITLE = "TWISTED" 
local COL_MAIN = Color3.fromRGB(255, 40, 40)      
local COL_GRAD = Color3.fromRGB(255, 100, 100)  
local COL_BG = Color3.fromRGB(10, 10, 14)         
local COL_SIDEBAR = Color3.fromRGB(14, 14, 18) 
local COL_ACT = Color3.fromRGB(200, 20, 20)       
local COL_INACT = Color3.fromRGB(22, 22, 28)    
local COL_STROKE = Color3.fromRGB(40, 40, 50)     
local COL_TEXT = Color3.fromRGB(240, 240, 240)  

local Themes = {
    ["RED"] = {Main = Color3.fromRGB(255, 40, 40), Grad = Color3.fromRGB(255, 100, 100), Act = Color3.fromRGB(200, 20, 20), Str = Color3.fromRGB(60, 20, 20)},
    ["BLUE"] = {Main = Color3.fromRGB(40, 150, 255), Grad = Color3.fromRGB(100, 200, 255), Act = Color3.fromRGB(20, 120, 200), Str = Color3.fromRGB(20, 40, 60)},
    ["GREEN"] = {Main = Color3.fromRGB(40, 255, 80), Grad = Color3.fromRGB(100, 255, 120), Act = Color3.fromRGB(20, 200, 40), Str = Color3.fromRGB(20, 60, 20)},
    ["PURPLE"] = {Main = Color3.fromRGB(180, 40, 255), Grad = Color3.fromRGB(220, 100, 255), Act = Color3.fromRGB(140, 20, 200), Str = Color3.fromRGB(40, 20, 60)},
    ["ORANGE"] = {Main = Color3.fromRGB(255, 140, 40), Grad = Color3.fromRGB(255, 180, 100), Act = Color3.fromRGB(200, 100, 20), Str = Color3.fromRGB(60, 30, 20)},
    ["PINK"] = {Main = Color3.fromRGB(255, 60, 180), Grad = Color3.fromRGB(255, 120, 200), Act = Color3.fromRGB(200, 40, 140), Str = Color3.fromRGB(60, 20, 40)},
    ["WHITE"] = {Main = Color3.fromRGB(255, 255, 255), Grad = Color3.fromRGB(200, 200, 200), Act = Color3.fromRGB(220, 220, 220), Str = Color3.fromRGB(100, 100, 100)},
    ["BLACK"] = {Main = Color3.fromRGB(90, 90, 90), Grad = Color3.fromRGB(60, 60, 60), Act = Color3.fromRGB(70, 70, 70), Str = Color3.fromRGB(40, 40, 40)}
}

local UI_FONT = Enum.Font.GothamMedium 
local UI_TITLE_FONT = Enum.Font.GothamBlack 

print("[TWISTED] Step 3: Resolving GUI Parent...")

local targetGuiParent = game:GetService("CoreGui") or lp:WaitForChild("PlayerGui")
local guiName = genName()

pcall(function()
    for _, v in pairs(targetGuiParent:GetChildren()) do
        if v:IsA("ScreenGui") and v.DisplayOrder == 19992 then v:Destroy() end
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true 
ScreenGui.DisplayOrder = 19992 
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = targetGuiParent

local function MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- =================[ ACTIVE MODULES HUD ]=================
local ActiveModsFrame = Instance.new("Frame")
ActiveModsFrame.Name = "ActiveModsFrame"
ActiveModsFrame.Size = UDim2.new(0, 160, 0, 100)
ActiveModsFrame.Position = UDim2.new(0, 20, 0.4, 0)
ActiveModsFrame.BackgroundColor3 = COL_BG
ActiveModsFrame.BackgroundTransparency = 0.2
ActiveModsFrame.BorderSizePixel = 0
ActiveModsFrame.Visible = false
ActiveModsFrame.ZIndex = 150
ActiveModsFrame.Parent = ScreenGui
MakeDraggable(ActiveModsFrame) 

local ActiveModsCorner = Instance.new("UICorner")
ActiveModsCorner.CornerRadius = UDim.new(0, 8)
ActiveModsCorner.Parent = ActiveModsFrame

local ActiveModsStroke = Instance.new("UIStroke")
ActiveModsStroke.Name = "Accent"
ActiveModsStroke.Color = COL_MAIN
ActiveModsStroke.Thickness = 1.5
ActiveModsStroke.Parent = ActiveModsFrame

local ActiveModsTitle = Instance.new("TextLabel")
ActiveModsTitle.Name = "ColoredTitle"
ActiveModsTitle.Size = UDim2.new(1, 0, 0, 30)
ActiveModsTitle.BackgroundTransparency = 1
ActiveModsTitle.Font = UI_TITLE_FONT
ActiveModsTitle.TextSize = 12
ActiveModsTitle.TextColor3 = COL_MAIN
ActiveModsTitle.Text = "⚡ ACTIVE MODS"
ActiveModsTitle.ZIndex = 151
ActiveModsTitle.Parent = ActiveModsFrame

local ActiveModsLine = Instance.new("Frame")
ActiveModsLine.Name = "Accent" 
ActiveModsLine.Size = UDim2.new(1, -20, 0, 1)
ActiveModsLine.Position = UDim2.new(0, 10, 0, 30)
ActiveModsLine.BackgroundColor3 = COL_MAIN
ActiveModsLine.BorderSizePixel = 0
ActiveModsLine.ZIndex = 151
ActiveModsLine.Parent = ActiveModsFrame

local ActiveModsLabel = Instance.new("TextLabel")
ActiveModsLabel.Name = "ActiveModsText"
ActiveModsLabel.Size = UDim2.new(1, -20, 1, -40)
ActiveModsLabel.Position = UDim2.new(0, 10, 0, 35)
ActiveModsLabel.BackgroundTransparency = 1
ActiveModsLabel.Font = UI_FONT
ActiveModsLabel.TextSize = 12
ActiveModsLabel.TextColor3 = COL_TEXT
ActiveModsLabel.TextXAlignment = Enum.TextXAlignment.Left
ActiveModsLabel.TextYAlignment = Enum.TextYAlignment.Top
ActiveModsLabel.Text = ""
ActiveModsLabel.ZIndex = 151
ActiveModsLabel.Parent = ActiveModsFrame

local myCarHighlight = Instance.new("Highlight")
myCarHighlight.Name = "TwistedCarESP"
myCarHighlight.Adornee = nil 
myCarHighlight.FillColor = COL_MAIN
myCarHighlight.OutlineColor = COL_MAIN
myCarHighlight.FillTransparency = 0.5
myCarHighlight.OutlineTransparency = 0.1
myCarHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
myCarHighlight.Enabled = false
if camera then 
    myCarHighlight.Parent = camera 
else 
    myCarHighlight.Parent = ScreenGui 
end

local NotifyContainer = Instance.new("Frame")
NotifyContainer.Size = UDim2.new(0, 300, 1, -40)
NotifyContainer.Position = UDim2.new(1, -310, 0, 20)
NotifyContainer.BackgroundTransparency = 1
NotifyContainer.ZIndex = 200
NotifyContainer.Parent = ScreenGui

local NList = Instance.new("UIListLayout")
NList.SortOrder = Enum.SortOrder.LayoutOrder
NList.Padding = UDim.new(0, 8)
NList.HorizontalAlignment = Enum.HorizontalAlignment.Right
NList.VerticalAlignment = Enum.VerticalAlignment.Bottom
NList.Parent = NotifyContainer

local function SendNotification(text)
    local toast = Instance.new("Frame")
    toast.BackgroundColor3 = COL_BG
    toast.BackgroundTransparency = 0.1
    toast.ClipsDescendants = true
    toast.BorderSizePixel = 0
    toast.ZIndex = 200
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COL_STROKE
    stroke.Thickness = 1.5
    stroke.Parent = toast
    
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = COL_MAIN
    accent.BorderSizePixel = 0
    accent.ZIndex = 201
    accent.Parent = toast
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -25, 1, -4)
    lbl.Position = UDim2.new(0, 15, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = COL_TEXT
    lbl.Font = UI_TITLE_FONT
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 201
    lbl.Parent = toast
    
    local timerBar = Instance.new("Frame")
    timerBar.Size = UDim2.new(1, 0, 0, 2)
    timerBar.Position = UDim2.new(0, 0, 1, -2)
    timerBar.BackgroundColor3 = COL_MAIN
    timerBar.BorderSizePixel = 0
    timerBar.ZIndex = 201
    timerBar.Parent = toast
    
    toast.Size = UDim2.new(0, math.clamp(lbl.TextBounds.X + 40, 150, 300), 0, 45)
    toast.Parent = NotifyContainer
    
    TweenService:Create(timerBar, TweenInfo.new(3.5, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()
    task.delay(3.5, function() 
        if toast then toast:Destroy() end 
    end)
end

local Watermark = Instance.new("Frame")
Watermark.Size = UDim2.new(0, 280, 0, 32)
Watermark.Position = UDim2.new(0, 20, 0, 20)
Watermark.BackgroundColor3 = COL_BG
Watermark.BackgroundTransparency = 0.2
Watermark.BorderSizePixel = 0
Watermark.Visible = false
Watermark.ZIndex = 100
Watermark.Parent = ScreenGui
MakeDraggable(Watermark)

local wmStroke = Instance.new("UIStroke")
wmStroke.Color = COL_STROKE
wmStroke.Thickness = 1.5
wmStroke.Parent = Watermark

local WmText = Instance.new("TextLabel")
WmText.Name = "WmText"
WmText.Size = UDim2.new(1, -20, 1, 0)
WmText.Position = UDim2.new(0, 10, 0, 0)
WmText.BackgroundTransparency = 1
WmText.Font = UI_FONT
WmText.TextSize = 13
WmText.TextColor3 = COL_TEXT
WmText.TextXAlignment = Enum.TextXAlignment.Left
WmText.Text = "Twisted XENO | FPS: 0"
WmText.ZIndex = 101
WmText.Parent = Watermark

local WmAccent = Instance.new("Frame")
WmAccent.Name = "Accent"
WmAccent.Size = UDim2.new(0, 3, 1, 0)
WmAccent.BackgroundColor3 = COL_MAIN
WmAccent.BorderSizePixel = 0
WmAccent.ZIndex = 101
WmAccent.Parent = Watermark

-- =================[ ГЛАВНАЯ ПАНЕЛЬ МЕНЮ И ФОНЫ ]=================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "TwistedMainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 600, 0, 380)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundTransparency = 1
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.ZIndex = 20
MainFrame.Parent = ScreenGui
MakeDraggable(MainFrame) 

local MainFrameStroke = Instance.new("UIStroke")
MainFrameStroke.Color = COL_MAIN
MainFrameStroke.Thickness = 2
MainFrameStroke.Parent = MainFrame

local function MakeBg(name, vis, z, isBlack, useCanvasGroup)
    local f
    if useCanvasGroup then
        local s = pcall(function() f = Instance.new("CanvasGroup") end)
        if not s or not f then f = Instance.new("Frame") end
    else
        f = Instance.new("Frame")
    end
    f.Name = name
    f.Size = UDim2.new(0, 600, 0, 380)
    f.BackgroundColor3 = isBlack and Color3.new(0,0,0) or COL_BG
    f.BackgroundTransparency = 0
    f.BorderSizePixel = 0
    f.ZIndex = z or 10
    f.Visible = vis
    f.ClipsDescendants = true
    f.Parent = MainFrame
    return f
end

local SolidBg = MakeBg("SolidBg", true, 10, false, false)
local TransBg = MakeBg("TransBg", false, 10, false, false)
TransBg.BackgroundTransparency = 0.2

local TrailPanelBg = MakeBg("TrailPanelBg", false, 10, true, false) 
local StarsBg = MakeBg("StarsBg", false, 11, true, true) 
local RainBg = MakeBg("RainBg", false, 11, true, true)  
local SnowBg = MakeBg("SnowBg", false, 11, true, true)  
local CosmosBg = MakeBg("CosmosBg", false, 11, true, true) 

local TornadoBgBg = MakeBg("TornadoBgBg", false, 11, true, true)
TornadoBgBg.BackgroundColor3 = Color3.fromRGB(5, 5, 8) 

local GradBg = MakeBg("GradBg", false, 10, false, false)
GradBg.BackgroundColor3 = Color3.new(1, 1, 1)

local BgGrad = Instance.new("UIGradient")
BgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.new(0,0,0)), 
    ColorSequenceKeypoint.new(0.48, COL_MAIN), 
    ColorSequenceKeypoint.new(0.52, COL_MAIN), 
    ColorSequenceKeypoint.new(1, Color3.new(0,0,0))
})
BgGrad.Parent = GradBg

local MouseBg = Instance.new("Frame")
MouseBg.Size = UDim2.new(1, 0, 1, 0)
MouseBg.BackgroundTransparency = 1
MouseBg.ZIndex = 9999
MouseBg.Visible = false
MouseBg.Parent = ScreenGui

for i = 1, 20 do
    local star = Instance.new("Frame")
    star.BackgroundColor3 = Color3.new(1, 1, 1)
    star.BorderSizePixel = 0
    star.ZIndex = 11
    
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(COL_MAIN)
    grad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
    grad.Parent = star
    
    star.Position = UDim2.new(math.random(-50, 50)/100, 0, math.random(-50, 50)/100, 0)
    star.Parent = StarsBg
    
    local spX = (math.random(20, 40) / 100) * T.Vars.starSpeed
    local spY = (math.random(20, 40) / 100) * T.Vars.starSpeed
    star.Rotation = math.deg(math.atan2(spY, spX))
    star.Size = UDim2.new(0, math.random(15, 35), 0, math.random(2, 3))
    table.insert(T.Pools.shootingStars, { obj = star, grad = grad, sx = spX, sy = spY, isActive = false })
end

for i = 1, 40 do
    local drop = Instance.new("Frame")
    drop.Name = "Accent"
    drop.BackgroundColor3 = COL_MAIN
    drop.BorderSizePixel = 0
    drop.ZIndex = 11
    drop.Size = UDim2.new(0, 1, 0, math.random(15, 30))
    drop.Position = UDim2.new(math.random(), 0, math.random(), 0)
    drop.Parent = RainBg
    table.insert(T.Pools.rain, { obj = drop, speed = math.random(15, 25) / 10 })
end

for i = 1, 30 do
    local flake = Instance.new("Frame")
    flake.Name = "Accent"
    flake.BackgroundColor3 = COL_MAIN
    flake.BorderSizePixel = 0
    flake.ZIndex = 11
    flake.Size = UDim2.new(0, math.random(2, 4), 0, math.random(2, 4))
    flake.Position = UDim2.new(math.random(), 0, math.random(), 0)
    flake.Parent = SnowBg
    table.insert(T.Pools.snow, { obj = flake, speed = math.random(2, 6) / 10, phase = math.random() * math.pi * 2 })
end

for i = 1, 50 do
    local cStar = Instance.new("Frame")
    cStar.Name = "Accent"
    cStar.BackgroundColor3 = COL_MAIN
    cStar.BorderSizePixel = 0
    cStar.ZIndex = 11
    cStar.AnchorPoint = Vector2.new(0.5, 0.5)
    cStar.Parent = CosmosBg
    table.insert(T.Pools.cosmos, { obj = cStar, x = (math.random() - 0.5) * 2, y = (math.random() - 0.5) * 2, z = math.random(), speed = math.random(5, 25) / 10 })
end

for i = 1, 15 do
    local tr = Instance.new("Frame")
    tr.Name = "Accent"
    tr.BackgroundColor3 = COL_MAIN
    tr.AnchorPoint = Vector2.new(0.5, 0.5)
    tr.Size = UDim2.new(0, 0, 0, 0)
    tr.BorderSizePixel = 0
    tr.ZIndex = 9999
    tr.Visible = false
    tr.Parent = MouseBg
    table.insert(T.Pools.trail, tr)
end

-- =================[ ГЕНЕРАЦИЯ ЧАСТИЦ TORNADO ]=================
for i = 1, 150 do
    local p = Instance.new("Frame")
    p.Name = "TornadoParticle"
    p.BackgroundColor3 = COL_MAIN
    p.BorderSizePixel = 0
    p.ZIndex = 12
    p.AnchorPoint = Vector2.new(0.5, 0.5)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0) 
    corner.Parent = p
    
    p.Parent = TornadoBgBg
    
    local angleOffset = math.random() * math.pi * 2
    local verticalRelPos = math.random() 
    
    local curve = (1 - verticalRelPos) ^ 1.5 
    local radius = 10 + (curve * 220) 
    local baseWidth = math.random(15, 40) + (curve * 50) 
    
    table.insert(T.Pools.bgTornadoParticles, {
        obj = p,
        angOffset = angleOffset,
        yRel = verticalRelPos,
        baseWidth = baseWidth,
        radius = radius,
        rotSpeed = 1.5 + (verticalRelPos * 3.5), 
    })
end

-- =================[ ВКЛАДКИ И КНОПКИ МЕНЮ ]=================
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 0, 380)
Sidebar.BackgroundColor3 = COL_SIDEBAR
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 20
Sidebar.Parent = MainFrame

local SidebarLine = Instance.new("Frame")
SidebarLine.Size = UDim2.new(0, 1, 0, 380)
SidebarLine.Position = UDim2.new(0, 159, 0, 0)
SidebarLine.BackgroundColor3 = COL_STROKE
SidebarLine.BorderSizePixel = 0
SidebarLine.ZIndex = 21
SidebarLine.Parent = Sidebar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 160, 0, 50)
Title.Position = UDim2.new(0, 0, 0, 10)
Title.Text = UI_TITLE
Title.TextColor3 = COL_MAIN
Title.BackgroundTransparency = 1
Title.Font = UI_TITLE_FONT
Title.TextSize = 24
Title.ZIndex = 25
Title.Parent = Sidebar

local TitleGrad = Instance.new("UIGradient")
TitleGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, COL_MAIN), ColorSequenceKeypoint.new(1, COL_GRAD)}
TitleGrad.Parent = Title

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(0, 160, 0, 15)
SubTitle.Position = UDim2.new(0, 0, 0, 45)
SubTitle.Text = "Premium"
SubTitle.TextColor3 = COL_TEXT
SubTitle.BackgroundTransparency = 1
SubTitle.Font = UI_FONT
SubTitle.TextSize = 11
SubTitle.TextTransparency = 0.4
SubTitle.ZIndex = 25
SubTitle.Parent = Sidebar

local TabsContainer = Instance.new("Frame")
TabsContainer.Size = UDim2.new(0, 160, 0, 300)
TabsContainer.Position = UDim2.new(0, 0, 0, 75)
TabsContainer.BackgroundTransparency = 1
TabsContainer.ZIndex = 25
TabsContainer.Parent = Sidebar

local UIListLayoutTabs = Instance.new("UIListLayout")
UIListLayoutTabs.FillDirection = Enum.FillDirection.Vertical
UIListLayoutTabs.Padding = UDim.new(0, 5)
UIListLayoutTabs.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayoutTabs.Parent = TabsContainer

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(0, 440, 0, 380)
ContentContainer.Position = UDim2.new(0, 160, 0, 0)
ContentContainer.BackgroundTransparency = 1
ContentContainer.ZIndex = 20
ContentContainer.Parent = MainFrame

local function createTabBtn(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 0, 32)
    btn.BackgroundColor3 = COL_INACT
    btn.BorderSizePixel = 0
    btn.Text = "   " .. name
    btn.TextColor3 = COL_TEXT
    btn.Font = UI_TITLE_FONT
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.ZIndex = 30
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COL_STROKE
    stroke.Thickness = 1
    stroke.Parent = btn
    
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 3, 0, 32)
    indicator.BackgroundColor3 = COL_MAIN
    indicator.BorderSizePixel = 0
    indicator.BackgroundTransparency = 1
    indicator.ZIndex = 31
    indicator.Parent = btn
    
    btn.Parent = TabsContainer
    table.insert(T.Pools.tabBtns, {btn = btn, ind = indicator})
    return btn, indicator
end

local function makeTab() 
    local t = Instance.new("ScrollingFrame")
    t.Size = UDim2.new(0, 440, 0, 360)
    t.Position = UDim2.new(0, 0, 0, 10)
    t.BackgroundTransparency = 1
    t.Visible = false
    t.ScrollBarThickness = 3
    t.ScrollBarImageColor3 = COL_MAIN
    t.BorderSizePixel = 0
    t.ZIndex = 30
    t.CanvasSize = UDim2.new(0, 0, 0, 600) 
    
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 20)
    pad.PaddingRight = UDim.new(0, 20)
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent = t
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = t
    
    t.Parent = ContentContainer
    return t 
end

local TabInfoBtn, IndInfo = createTabBtn("INFORMATION")
local TabLocalBtn, IndLocal = createTabBtn("LOCAL PLAYER")
local TabTruckBtn, IndTruck = createTabBtn("TRUCK FARM")
local TabTpBtn, IndTp = createTabBtn("TELEPORTS")
local TabCustomizeBtn, IndCust = createTabBtn("SETTINGS") 
local TabThemesBtn, IndTheme = createTabBtn("THEMES & UI") 

local TabInfo = makeTab()
TabInfo.Visible = true

local TabLocal = makeTab()
local TabTruck = makeTab()
local TabTp = makeTab()
local TabCustomize = makeTab()
local TabThemes = makeTab()

local allTabs = {TabInfo, TabLocal, TabTruck, TabTp, TabCustomize, TabThemes}
T.Vars.currentActiveTabBtn = TabInfoBtn

IndInfo.BackgroundTransparency = 0
TabInfoBtn.BackgroundColor3 = COL_ACT
TabInfoBtn.TextColor3 = COL_TEXT
TabInfoBtn.UIStroke.Color = COL_MAIN 

local InfoText = Instance.new("TextLabel")
InfoText.Size = UDim2.new(0, 400, 0, 250)
InfoText.BackgroundTransparency = 1
InfoText.ZIndex = 50
InfoText.Text = "Twisted V12.0 [XENO FINAL BUILD]\n\nCreated by: AME52\n\n• [DELETE] - Hide/Show Menu.\n• [ - ] -> Click to Bind a Key.\n\n[🚚] NEW: Truck Farm Tab (WELD FIX)\n[🛡] FIX: Safe Startup (No Crashes)\n[🚗] ESP: Highlight Works Everywhere\n[🌪] Tornado: Trajectories & Speed ON\n[📁] FIX: Draggable Active Mods Cloud\n[🎨] FIX: SCROLLBAR & TORNADO FIX"
InfoText.TextColor3 = COL_TEXT
InfoText.Font = UI_FONT
InfoText.TextSize = 13
InfoText.TextYAlignment = Enum.TextYAlignment.Top
InfoText.TextXAlignment = Enum.TextXAlignment.Left
InfoText.Parent = TabInfo

local function createRow(parent)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 400, 0, 38)
    f.BackgroundTransparency = 1
    f.ZIndex = 35
    
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Horizontal
    l.Padding = UDim.new(0, 10)
    l.Parent = f
    f.Parent = parent
    return f
end

local function createBtn(name, parent, isFull, isThemeOrBg)
    local b = Instance.new("TextButton")
    b.Size = isFull and UDim2.new(0, 400, 0, 38) or UDim2.new(0, 195, 0, 38)
    b:SetAttribute("FeatureName", string.split(name, ":")[1] or name)
    b.BackgroundColor3 = COL_INACT
    b.Text = "   " .. name
    b.TextColor3 = COL_TEXT
    b.Font = UI_FONT
    b.TextSize = 13
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ZIndex = 35
    
    local bStroke = Instance.new("UIStroke")
    bStroke.Color = COL_STROKE
    bStroke.Thickness = 1
    bStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    bStroke.Parent = b
    
    b.Parent = parent
    if not isThemeOrBg then
        local bindLbl = Instance.new("TextButton")
        bindLbl.Name = "BindLabel"
        bindLbl.Size = UDim2.new(0, 40, 0, 38)
        bindLbl.Position = UDim2.new(0, b.Size.X.Offset - 45, 0, 0)
        bindLbl.BackgroundTransparency = 1
        bindLbl.Text = "[-]"
        bindLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
        bindLbl.Font = UI_FONT
        bindLbl.TextSize = 11
        bindLbl.ZIndex = 36
        bindLbl.Parent = b
        table.insert(T.Pools.binds, b)
    end
    return b
end

local function createSliderBox(name, parent, min, max, default, isFloat, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 400, 0, 50)
    f.BackgroundTransparency = 1
    f.ZIndex = 35
    f.Parent = parent
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 400, 0, 18)
    l.TextColor3 = COL_MAIN
    l.BackgroundTransparency = 1
    l.Font = UI_FONT
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 36
    l.Parent = f
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 400, 0, 24)
    bg.Position = UDim2.new(0, 0, 0, 24)
    bg.BackgroundColor3 = COL_INACT
    bg.BorderSizePixel = 0
    bg.ZIndex = 35
    bg.Parent = f
    
    local bStroke = Instance.new("UIStroke")
    bStroke.Color = COL_STROKE
    bStroke.Thickness = 1
    bStroke.Parent = bg
    
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = COL_MAIN
    fill.BorderSizePixel = 0
    fill.ZIndex = 36
    fill.Parent = bg
    
    local btn = Instance.new("TextButton")
    btn.Text = ""
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.ZIndex = 40
    btn.Parent = bg
    
    table.insert(T.Pools.sliders, {lbl = l, bg = bg, stroke = bStroke, fill = fill})
    
    local function setVal(v)
        v = math.clamp(v, min, max)
        local pct = (v - min) / (max - min)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        l.Text = name .. (isFloat and string.format("%.1f", v) or math.floor(v))
        callback(v)
    end
    setVal(default)
    
    btn.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 then 
            T.Vars.activeSlider = {btn=btn, fill=fill, lbl=l, min=min, max=max, isFloat=isFloat, cb=callback, name=name} 
        end 
    end)
    return setVal
end

-- =================[ СОЗДАНИЕ UI И КНОПОК ]=================
local row

row = createRow(TabLocal)
T.UI.CarFlyBtn = createBtn("CAR FLY: OFF", row, false, false)
T.UI.NoclipBtn = createBtn("NOCLIP: OFF", row, false, false)

row = createRow(TabLocal)
T.UI.GodmodeBtn = createBtn("GODMODE: OFF", row, false, false)
T.UI.FpsBoostBtn = createBtn("FPS BOOST: OFF", row, false, false)

row = createRow(TabLocal)
T.UI.FullbrightBtn = createBtn("FULLBRIGHT: OFF", row, false, false)
T.UI.TornadoEspBtn = createBtn("TORNADO ESP: OFF", row, false, false)

row = createRow(TabLocal)
T.UI.PlayerEspBtn = createBtn("PLAYER ESP: OFF", row, false, false)
T.UI.MyCarEspBtn = createBtn("MY CAR ESP: OFF", row, false, false)

T.Vars.Setters.carSpeed = createSliderBox("CAR FLY SPEED: ", TabLocal, 10, 1000, 100, false, function(v) T.Vars.carSpeed = v end)

local lblTruckFly = Instance.new("TextLabel")
lblTruckFly.Name = "ColoredTitle"
lblTruckFly.Size = UDim2.new(0, 400, 0, 20)
lblTruckFly.BackgroundTransparency = 1
lblTruckFly.Text = "✈️ TRUCK FLY SETTINGS:"
lblTruckFly.TextColor3 = COL_MAIN
lblTruckFly.Font = UI_TITLE_FONT
lblTruckFly.TextSize = 13
lblTruckFly.TextXAlignment = Enum.TextXAlignment.Left
lblTruckFly.ZIndex = 40
lblTruckFly.Parent = TabTruck

T.UI.TruckFlyBtn = createBtn("TRUCK FLY: OFF", createRow(TabTruck), true, false)
T.Vars.Setters.truckSpeed = createSliderBox("TRUCK FLY SPEED: ", TabTruck, 10, 1000, 100, false, function(v) T.Vars.truckSpeed = v end)

local lblTruckTp = Instance.new("TextLabel")
lblTruckTp.Name = "ColoredTitle"
lblTruckTp.Size = UDim2.new(0, 400, 0, 20)
lblTruckTp.BackgroundTransparency = 1
lblTruckTp.Text = "📍 TRUCK TELEPORTS:"
lblTruckTp.TextColor3 = COL_MAIN
lblTruckTp.Font = UI_TITLE_FONT
lblTruckTp.TextSize = 13
lblTruckTp.TextXAlignment = Enum.TextXAlignment.Left
lblTruckTp.ZIndex = 40
lblTruckTp.Parent = TabTruck

T.UI.ViroquaBtn = createBtn("VIROQUA CHEROKEE COUNTY", createRow(TabTruck), true, false)
T.UI.TruckJobBtn = createBtn("TRUCK JOB", createRow(TabTruck), true, false)
T.UI.HibinBtn = createBtn("HIBIN", createRow(TabTruck), true, false)

T.UI.PriorLakeBtn = createBtn("PRIOR LAKE", createRow(TabTp), true, false)
T.UI.HazeltonBtn = createBtn("HAZELTON", createRow(TabTp), true, false)
T.UI.HibbingBtn = createBtn("HIBBING", createRow(TabTp), true, false)

row = createRow(TabTp)
T.UI.TornadoIdInput = Instance.new("TextBox")
T.UI.TornadoIdInput.Size = UDim2.new(0, 90, 0, 38)
T.UI.TornadoIdInput.BackgroundColor3 = COL_INACT
T.UI.TornadoIdInput.BorderSizePixel = 0
T.UI.TornadoIdInput.Text = ""
T.UI.TornadoIdInput.PlaceholderText = "ID"
T.UI.TornadoIdInput.TextColor3 = COL_TEXT
T.UI.TornadoIdInput.Font = UI_FONT
T.UI.TornadoIdInput.TextSize = 14
T.UI.TornadoIdInput.ZIndex = 40
T.UI.TornadoIdInput.ClearTextOnFocus = false
T.UI.TornadoIdInput.TextEditable = true
T.UI.TornadoIdInput.Parent = row

Instance.new("UIStroke", T.UI.TornadoIdInput).Color = COL_STROKE
T.UI.TornadoIdInput.UIStroke.Thickness = 1

T.UI.TpToTornadoBtn = createBtn("TP TO TORNADO", row, false, false)
T.UI.TpToTornadoBtn.Size = UDim2.new(0, 300, 0, 38) 

T.UI.TpToCarBtn = createBtn("TP TO MY CAR", createRow(TabTp), true, false)
row = createRow(TabTp)
T.UI.SetTrap1Btn = createBtn("SET TRAP 1", row, false, false)
T.UI.TpTrap1Btn = createBtn("TP TRAP 1", row, false, false)

row = createRow(TabTp)
T.UI.SetTrap2Btn = createBtn("SET TRAP 2", row, false, false)
T.UI.TpTrap2Btn = createBtn("TP TRAP 2", row, false, false)

row = createRow(TabTp)
T.UI.SetTrap3Btn = createBtn("SET TRAP 3", row, false, false)
T.UI.TpTrap3Btn = createBtn("TP TRAP 3", row, false, false)

local cfgLbl = Instance.new("TextLabel")
cfgLbl.Name = "ColoredTitle"
cfgLbl.Size = UDim2.new(0, 400, 0, 20)
cfgLbl.BackgroundTransparency = 1
cfgLbl.Text = "⚙️ HUD SETTINGS:"
cfgLbl.TextColor3 = COL_MAIN
cfgLbl.Font = UI_TITLE_FONT
cfgLbl.TextSize = 13
cfgLbl.TextXAlignment = Enum.TextXAlignment.Left
cfgLbl.ZIndex = 40
cfgLbl.Parent = TabCustomize

row = createRow(TabCustomize)
T.UI.ActiveModsBtn = createBtn("ACTIVE MODULES: OFF", row, true, false)

T.Vars.Setters.pathLen = createSliderBox("PATH LENGTH: ", TabCustomize, 5, 60, 15, false, function(v) T.Vars.pathLen = v end)
T.Vars.Setters.pathWid = createSliderBox("PATH WIDTH: ", TabCustomize, 2, 100, 12, false, function(v) T.Vars.pathWid = v end)

local bgLabel = Instance.new("TextLabel")
bgLabel.Name = "ColoredTitle"
bgLabel.Size = UDim2.new(0, 400, 0, 20)
bgLabel.BackgroundTransparency = 1
bgLabel.Text = "Background Settings:"
bgLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
bgLabel.Font = UI_FONT
bgLabel.TextSize = 12
bgLabel.TextXAlignment = Enum.TextXAlignment.Left
bgLabel.ZIndex = 40
bgLabel.Parent = TabThemes

row = createRow(TabThemes)
T.UI.btnBgSolid = createBtn("BG SOLID", row, false, true)
T.UI.btnBgTrans = createBtn("BG TRANS", row, false, true)

row = createRow(TabThemes)
T.UI.btnBgGrad = createBtn("BG GRADIENT", row, false, true)
T.UI.btnBgStars = createBtn("BG STARS", row, false, true)

row = createRow(TabThemes)
T.UI.btnBgRain = createBtn("BG RAIN", row, false, true)
T.UI.btnBgSnow = createBtn("BG SNOW", row, false, true)

row = createRow(TabThemes)
T.UI.btnBgCosmos = createBtn("BG COSMOS", row, false, true)
T.UI.btnBgMouse = createBtn("BG TRAIL", row, false, true)

row = createRow(TabThemes)
T.UI.btnBgTornado = createBtn("BG TORNADO", row, true, true)

local themeLabel = Instance.new("TextLabel")
themeLabel.Name = "ColoredTitle"
themeLabel.Size = UDim2.new(0, 400, 0, 20)
themeLabel.BackgroundTransparency = 1
themeLabel.Text = "UI Themes:"
themeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
themeLabel.Font = UI_FONT
themeLabel.TextSize = 12
themeLabel.TextXAlignment = Enum.TextXAlignment.Left
themeLabel.ZIndex = 40
themeLabel.Parent = TabThemes

row = createRow(TabThemes)
T.UI.btnRed = createBtn("THEME RED", row, false, true)
T.UI.btnBlue = createBtn("THEME BLUE", row, false, true)

row = createRow(TabThemes)
T.UI.btnGreen = createBtn("THEME GREEN", row, false, true)
T.UI.btnPurple = createBtn("THEME PURPLE", row, false, true)

row = createRow(TabThemes)
T.UI.btnOrange = createBtn("THEME ORANGE", row, false, true)
T.UI.btnPink = createBtn("THEME PINK", row, false, true)

row = createRow(TabThemes)
T.UI.btnWhite = createBtn("THEME WHITE", row, false, true)
T.UI.btnBlack = createBtn("THEME BLACK", row, false, true)

-- =================[ ИСПРАВЛЕННАЯ ЛОГИКА ТЕМ ]=================
local function ChangeTheme(themeName)
    local t = Themes[themeName]
    if not t then return end
    COL_MAIN = t.Main; COL_GRAD = t.Grad; COL_ACT = t.Act; COL_STROKE = t.Str
    T.Vars.activeTheme = themeName
    
    pcall(function() Title.TextColor3 = COL_MAIN end)
    pcall(function() TitleGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, COL_MAIN), ColorSequenceKeypoint.new(1, COL_GRAD)} end)
    pcall(function() SidebarLine.BackgroundColor3 = COL_STROKE end)
    pcall(function() MainFrameStroke.Color = COL_MAIN end)
    pcall(function() BgGrad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.new(0,0,0)), ColorSequenceKeypoint.new(0.48, COL_MAIN), ColorSequenceKeypoint.new(0.52, COL_MAIN), ColorSequenceKeypoint.new(1, Color3.new(0,0,0))}) end)
    pcall(function() myCarHighlight.FillColor = COL_MAIN; myCarHighlight.OutlineColor = COL_MAIN end)
    
    pcall(function() ActiveModsStroke.Color = COL_MAIN end)
    pcall(function() ActiveModsTitle.TextColor3 = COL_MAIN end)
    pcall(function() ActiveModsLine.BackgroundColor3 = COL_MAIN end)
    
    local KeyFrame = ScreenGui:FindFirstChild("KeyFrame")
    if KeyFrame then
        pcall(function() KeyFrame.KeyFrameStroke.Color = COL_MAIN end)
        pcall(function() KeyFrame.KeyTitle.TextColor3 = COL_MAIN end)
        pcall(function() KeyFrame.VerifyButton.KeyBtnStroke.Color = COL_MAIN end)
        pcall(function() KeyFrame.KeyInput.KeyInputStroke.Color = COL_STROKE end)
    end
    
    for _, s in ipairs(T.Pools.sliders) do
        pcall(function()
            s.bg.BackgroundColor3 = COL_INACT
            s.fill.BackgroundColor3 = COL_MAIN
            s.stroke.Color = COL_STROKE
            s.lbl.TextColor3 = COL_MAIN 
        end)
    end
    
    for _, v in pairs(ScreenGui:GetDescendants()) do
        pcall(function()
            if v:IsA("ScrollingFrame") then
                v.ScrollBarImageColor3 = COL_MAIN
            end
            
            if v.Name == "Accent" or v.Name == "TimerBar" or v.Name == "TornadoParticle" then 
                if v:IsA("Frame") then v.BackgroundColor3 = COL_MAIN end
            end
            
            if v.Name == "Indicator" and v.BackgroundTransparency == 0 then 
                v.BackgroundColor3 = COL_MAIN
            end

            if v:IsA("TextLabel") and (v.Name == "ColoredTitle" or v.Name == "PEspTxt" or v.Name == "T_ESP_2D") then
                v.TextColor3 = COL_MAIN
            end

            if v:IsA("TextButton") and v.Name == "BindLabel" and v.Text ~= "[-]" then
                v.TextColor3 = COL_MAIN
            end

            if v:IsA("TextBox") then 
                v.BackgroundColor3 = COL_INACT
                v.TextColor3 = COL_TEXT
                local st = v:FindFirstChildWhichIsA("UIStroke")
                if st then st.Color = COL_STROKE end
            end
            
            if v:IsA("UIStroke") and v.Name == "Accent" then
                v.Color = COL_MAIN
            end
        end)
    end
    
    pcall(function()
        for _, st in ipairs(T.Pools.shootingStars) do st.grad.Color = ColorSequence.new(COL_MAIN) end
        for _, tr in ipairs(T.Pools.trail) do tr.BackgroundColor3 = COL_MAIN end
        for _, r in ipairs(T.Pools.rain) do r.obj.BackgroundColor3 = COL_MAIN end
        for _, s in ipairs(T.Pools.snow) do s.obj.BackgroundColor3 = COL_MAIN end
        for _, cs in ipairs(T.Pools.cosmos) do cs.obj.BackgroundColor3 = COL_MAIN end
        for _, tp in ipairs(T.Pools.bgTornadoParticles) do tp.obj.BackgroundColor3 = COL_MAIN end
    end)
    
    for _, btn in pairs(T.UI) do
        if typeof(btn) == "Instance" and btn:IsA("TextButton") then
            pcall(function()
                local st = btn:FindFirstChild("UIStroke")
                local isActive = string.find(btn.Text, ": ON") or string.find(btn.Text, "LOCKED") or string.find(btn.Text, ": ACTIVE")
                if isActive then 
                    btn.BackgroundColor3 = COL_ACT; btn.TextColor3 = COL_TEXT; if st then st.Color = COL_MAIN end
                else 
                    btn.BackgroundColor3 = COL_INACT; btn.TextColor3 = COL_TEXT; if st then st.Color = COL_STROKE end 
                end
            end)
        end
    end
    
    for _, tData in ipairs(T.Pools.tabBtns) do
        pcall(function()
            local b = tData.btn
            local st = b:FindFirstChildWhichIsA("UIStroke")
            if b == T.Vars.currentActiveTabBtn then
                b.BackgroundColor3 = COL_ACT
                b.TextColor3 = COL_TEXT
                if st then st.Color = COL_MAIN end
                tData.ind.BackgroundColor3 = COL_MAIN
            else
                b.BackgroundColor3 = COL_INACT
                b.TextColor3 = COL_TEXT
                if st then st.Color = COL_STROKE end
            end
        end)
    end
end

local function activateTheme(btn, themeName)
    local thBtns = {T.UI.btnRed, T.UI.btnBlue, T.UI.btnGreen, T.UI.btnPurple, T.UI.btnOrange, T.UI.btnPink, T.UI.btnWhite, T.UI.btnBlack}
    for _, b in ipairs(thBtns) do
        local fn = b:GetAttribute("FeatureName")
        if b == btn or (btn == nil and string.match(b.Text, themeName)) then 
            b.Text = "   " .. fn .. ": ON" 
        else 
            b.Text = "   " .. fn .. ": OFF" 
        end
    end
    ChangeTheme(themeName)
end

local function updateBgBtns(activeBtn)
    local bgBtns = {T.UI.btnBgSolid, T.UI.btnBgTrans, T.UI.btnBgGrad, T.UI.btnBgStars, T.UI.btnBgRain, T.UI.btnBgSnow, T.UI.btnBgCosmos, T.UI.btnBgMouse, T.UI.btnBgTornado}
    for _, btn in ipairs(bgBtns) do
        local fn = btn:GetAttribute("FeatureName")
        if btn == activeBtn then 
            btn.Text = "   " .. fn .. ": ON" 
        else 
            btn.Text = "   " .. fn .. ": OFF" 
        end
    end
    ChangeTheme(T.Vars.activeTheme)
end

local function hideAllBgs() 
    SolidBg.Visible = false
    TransBg.Visible = false
    GradBg.Visible = false
    StarsBg.Visible = false
    RainBg.Visible = false
    SnowBg.Visible = false
    CosmosBg.Visible = false
    MouseBg.Visible = false
    TrailPanelBg.Visible = false
    TornadoBgBg.Visible = false 
end

local function setAction(btn, func)
    btn.MouseButton1Click:Connect(function()
        if T.Vars.currentBind == nil then func() end
    end)
end

local function updateBtnState(btn, state)
    local fn = btn:GetAttribute("FeatureName")
    btn.Text = "   " .. fn .. ": " .. (state and "ON" or "OFF")
    ChangeTheme(T.Vars.activeTheme) 
end

-- =================[ KEYAUTH API ПАНЕЛЬ ]=================
local KeyFrame = Instance.new("Frame")
KeyFrame.Name = "KeyFrame"
KeyFrame.AnchorPoint = Vector2.new(0.5, 0.5)
KeyFrame.Size = UDim2.new(0, 400, 0, 220)
KeyFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
KeyFrame.BackgroundColor3 = COL_BG
KeyFrame.BorderSizePixel = 0
KeyFrame.Active = true
KeyFrame.Visible = false
KeyFrame.ZIndex = 100
KeyFrame.Parent = ScreenGui
MakeDraggable(KeyFrame)

local KeyFrameStroke = Instance.new("UIStroke")
KeyFrameStroke.Name = "KeyFrameStroke"
KeyFrameStroke.Color = COL_MAIN
KeyFrameStroke.Thickness = 2
KeyFrameStroke.Parent = KeyFrame

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Name = "KeyTitle"
KeyTitle.Size = UDim2.new(0, 400, 0, 50)
KeyTitle.Position = UDim2.new(0, 0, 0, 20)
KeyTitle.Text = "AUTHENTICATION"
KeyTitle.TextColor3 = COL_MAIN
KeyTitle.BackgroundTransparency = 1
KeyTitle.Font = UI_TITLE_FONT
KeyTitle.TextSize = 24
KeyTitle.ZIndex = 101
KeyTitle.Parent = KeyFrame

local KeyInput = Instance.new("TextBox")
KeyInput.Name = "KeyInput"
KeyInput.Size = UDim2.new(0, 300, 0, 45)
KeyInput.Position = UDim2.new(0, 50, 0, 85)
KeyInput.BackgroundColor3 = COL_INACT
KeyInput.BorderSizePixel = 0
KeyInput.Text = ""
KeyInput.PlaceholderText = "Paste License Key here..."
KeyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
KeyInput.TextColor3 = COL_TEXT
KeyInput.Font = UI_FONT
KeyInput.TextSize = 14
KeyInput.ClearTextOnFocus = false
KeyInput.TextEditable = true
KeyInput.ZIndex = 101
KeyInput.Parent = KeyFrame

local KeyInputStroke = Instance.new("UIStroke")
KeyInputStroke.Name = "KeyInputStroke"
KeyInputStroke.Color = COL_STROKE
KeyInputStroke.Thickness = 1
KeyInputStroke.Parent = KeyInput

local KeyBtn = Instance.new("TextButton")
KeyBtn.Name = "VerifyButton"
KeyBtn.Size = UDim2.new(0, 300, 0, 45)
KeyBtn.Position = UDim2.new(0, 50, 0, 145)
KeyBtn.BackgroundColor3 = COL_INACT
KeyBtn.BorderSizePixel = 0
KeyBtn.Text = "VERIFY KEY"
KeyBtn.TextColor3 = COL_MAIN
KeyBtn.Font = UI_TITLE_FONT
KeyBtn.TextSize = 15
KeyBtn.AutoButtonColor = false
KeyBtn.ZIndex = 101
KeyBtn.Parent = KeyFrame

local KeyBtnStroke = Instance.new("UIStroke")
KeyBtnStroke.Name = "KeyBtnStroke"
KeyBtnStroke.Color = COL_MAIN
KeyBtnStroke.Thickness = 1.5
KeyBtnStroke.Parent = KeyBtn

local isActivated = false
local isLoggingIn = false
local KeyAuthApp = { Name = "standart", OwnerID = "NSF5QmXRX1", Secret = "6b3465408da0f3a70daf56c5fd114b3923e5bb09d79f13b7d9b16792dd8bd159", Version = "1.0" }

KeyBtn.MouseButton1Click:Connect(function()
    if isLoggingIn then return end 
    local enteredKey = string.gsub(KeyInput.Text, "[%s%c]", "")
    if enteredKey == "" then return end
    isLoggingIn = true
    KeyBtn.Text = "CONNECTING..."
    
    task.spawn(function()
        local function resetUI(msg) 
            KeyInput.Text = ""
            KeyInput.PlaceholderText = msg or "ERROR!"
            KeyBtn.Text = "VERIFY KEY"
            isLoggingIn = false 
        end
        
        local reqFunc = nil
        if syn and syn.request then 
            reqFunc = syn.request 
        elseif http and http.request then 
            reqFunc = http.request 
        elseif http_request then 
            reqFunc = http_request 
        elseif request then 
            reqFunc = request 
        elseif fluxus and fluxus.request then 
            reqFunc = fluxus.request 
        end
        
        if not reqFunc then resetUI("UNSUPPORTED EXECUTOR"); return end
        
        local hwid = "Unknown"
        pcall(function() hwid = game:GetService("RbxAnalyticsService"):GetClientId() end)
        
        local initBody = string.format("type=init&ver=%s&name=%s&ownerid=%s", KeyAuthApp.Version, KeyAuthApp.Name, KeyAuthApp.OwnerID)
        local success1, initRes = pcall(function() 
            return reqFunc({ Url = "https://keyauth.win/api/1.2/", Method = "POST", Headers = {["Content-Type"] = "application/x-www-form-urlencoded"}, Body = initBody }) 
        end)
        
        if not success1 or not initRes or initRes.StatusCode ~= 200 then resetUI("API CONNECTION FAILED"); return end
        
        local parseSuccess, initData = pcall(function() return HttpService:JSONDecode(initRes.Body) end)
        if not parseSuccess or not initData.success then resetUI(initData and initData.message or "INIT FAILED"); return end

        local licBody = string.format("type=license&key=%s&hwid=%s&sessionid=%s&name=%s&ownerid=%s", enteredKey, hwid, initData.sessionid, KeyAuthApp.Name, KeyAuthApp.OwnerID)
        local success2, licRes = pcall(function() 
            return reqFunc({ Url = "https://keyauth.win/api/1.2/", Method = "POST", Headers = {["Content-Type"] = "application/x-www-form-urlencoded"}, Body = licBody }) 
        end)
        
        if not success2 or not licRes then resetUI("LICENSE REQ FAILED"); return end
        
        local parseSuccess2, licData = pcall(function() return HttpService:JSONDecode(licRes.Body) end)
        
        if parseSuccess2 and licData.success then
            KeyBtn.Text = "NICE"
            KeyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            task.wait(0.6)
            
            KeyFrame.Visible = false
            task.wait(0.4)
            
            isActivated = true
            if MainFrame then MainFrame.Visible = true end
            SendNotification("🔥 Successfully Authenticated!")
            isLoggingIn = false
        else
            resetUI(licData and licData.message or "INVALID KEY!")
        end
    end)
end)

local function setupTabSwitch()
    local function doSwitch(btnObj)
        T.Vars.currentActiveTabBtn = btnObj.btn
        for _, t in pairs(allTabs) do t.Visible = false end
        
        for _, b in ipairs(T.Pools.tabBtns) do 
            b.ind.BackgroundTransparency = 1
            b.btn.BackgroundColor3 = COL_INACT
            b.btn.TextColor3 = COL_TEXT
            local str = b.btn:FindFirstChildWhichIsA("UIStroke")
            if str then str.Color = COL_STROKE end
        end
        
        btnObj.ind.BackgroundTransparency = 0
        btnObj.ind.BackgroundColor3 = COL_MAIN
        btnObj.btn.BackgroundColor3 = COL_ACT
        btnObj.btn.TextColor3 = COL_TEXT
        
        local str = btnObj.btn:FindFirstChildWhichIsA("UIStroke")
        if str then str.Color = COL_MAIN end
        
        if btnObj.btn == TabInfoBtn then TabInfo.Visible = true 
        elseif btnObj.btn == TabLocalBtn then TabLocal.Visible = true 
        elseif btnObj.btn == TabTruckBtn then TabTruck.Visible = true
        elseif btnObj.btn == TabTpBtn then TabTp.Visible = true 
        elseif btnObj.btn == TabCustomizeBtn then TabCustomize.Visible = true 
        elseif btnObj.btn == TabThemesBtn then TabThemes.Visible = true end
    end
    
    TabInfoBtn.MouseButton1Click:Connect(function() doSwitch(T.Pools.tabBtns[1]) end)
    TabLocalBtn.MouseButton1Click:Connect(function() doSwitch(T.Pools.tabBtns[2]) end)
    TabTruckBtn.MouseButton1Click:Connect(function() doSwitch(T.Pools.tabBtns[3]) end)
    TabTpBtn.MouseButton1Click:Connect(function() doSwitch(T.Pools.tabBtns[4]) end)
    TabCustomizeBtn.MouseButton1Click:Connect(function() doSwitch(T.Pools.tabBtns[5]) end)
    TabThemesBtn.MouseButton1Click:Connect(function() doSwitch(T.Pools.tabBtns[6]) end)
end
setupTabSwitch()

setAction(T.UI.btnBgSolid, function() hideAllBgs(); SolidBg.Visible = true; updateBgBtns(T.UI.btnBgSolid) end)
setAction(T.UI.btnBgTrans, function() hideAllBgs(); TransBg.Visible = true; updateBgBtns(T.UI.btnBgTrans) end)
setAction(T.UI.btnBgGrad, function() hideAllBgs(); GradBg.Visible = true; updateBgBtns(T.UI.btnBgGrad) end)
setAction(T.UI.btnBgStars, function() hideAllBgs(); StarsBg.Visible = true; updateBgBtns(T.UI.btnBgStars) end)
setAction(T.UI.btnBgRain, function() hideAllBgs(); RainBg.Visible = true; updateBgBtns(T.UI.btnBgRain) end)
setAction(T.UI.btnBgSnow, function() hideAllBgs(); SnowBg.Visible = true; updateBgBtns(T.UI.btnBgSnow) end)
setAction(T.UI.btnBgCosmos, function() hideAllBgs(); CosmosBg.Visible = true; updateBgBtns(T.UI.btnBgCosmos) end)
setAction(T.UI.btnBgMouse, function() hideAllBgs(); TrailPanelBg.Visible = true; MouseBg.Visible = true; updateBgBtns(T.UI.btnBgMouse) end)
setAction(T.UI.btnBgTornado, function() hideAllBgs(); TornadoBgBg.Visible = true; updateBgBtns(T.UI.btnBgTornado) end)

setAction(T.UI.btnRed, function() activateTheme(T.UI.btnRed, "RED") end)
setAction(T.UI.btnBlue, function() activateTheme(T.UI.btnBlue, "BLUE") end)
setAction(T.UI.btnGreen, function() activateTheme(T.UI.btnGreen, "GREEN") end)
setAction(T.UI.btnPurple, function() activateTheme(T.UI.btnPurple, "PURPLE") end)
setAction(T.UI.btnOrange, function() activateTheme(T.UI.btnOrange, "ORANGE") end)
setAction(T.UI.btnPink, function() activateTheme(T.UI.btnPink, "PINK") end)
setAction(T.UI.btnWhite, function() activateTheme(T.UI.btnWhite, "WHITE") end)
setAction(T.UI.btnBlack, function() activateTheme(T.UI.btnBlack, "BLACK") end)

local function getHighestModel(obj)
    if not obj then return nil end
    local vehicleModel = obj:FindFirstAncestorOfClass("Model")
    if vehicleModel and vehicleModel.Name ~= "Workspace" and not Players:GetPlayerFromCharacter(vehicleModel) then
        local highest = vehicleModel
        local current = vehicleModel.Parent
        while current and current ~= workspace and current.Name ~= "Workspace" do
            if current:IsA("Model") then highest = current end
            current = current.Parent
        end
        return highest
    end
    return nil
end

local function TeleportTo(x, y, z)
    local char = lp.Character
    if not char then return end
    
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    
    if hum and hum.SeatPart then
        local veh = getHighestModel(hum.SeatPart)
        if veh then
            for _, v in pairs(veh:GetDescendants()) do 
                if v:IsA("BasePart") then 
                    v.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    v.AssemblyAngularVelocity = Vector3.new(0,0,0) 
                end 
            end
            veh:PivotTo(CFrame.new(x, y + 10, z))
            task.wait(0.05)
            for _, v in pairs(veh:GetDescendants()) do 
                if v:IsA("BasePart") then 
                    v.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    v.AssemblyAngularVelocity = Vector3.new(0,0,0) 
                end 
            end
        end
    else
        if root then
            root.AssemblyLinearVelocity = Vector3.new(0,0,0)
            char:PivotTo(CFrame.new(x, y + 5, z))
            task.wait(0.05)
            root.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
    end
end

-- =================[ ДЕЙСТВИЯ: TRUCK FARM И CAR FLY ]=================
setAction(T.UI.TruckFlyBtn, function() 
    T.State.TruckFly = not T.State.TruckFly
    updateBtnState(T.UI.TruckFlyBtn, T.State.TruckFly) 
    
    if T.State.TruckFly then
        T.Vars.origGravity = workspace.Gravity
        workspace.Gravity = 0 
        pcall(function()
            local char = lp.Character
            local seat = char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart
            if not seat then return end
            local truckModel = getHighestModel(seat)
            if not truckModel then return end
            
            local function processModelParts(modelToWeld)
                for _, part in ipairs(modelToWeld:GetDescendants()) do
                    if part:IsA("BasePart") and part ~= seat and not part:IsDescendantOf(char) then
                        T.Pools.partProps[part] = { Massless = part.Massless, CanCollide = part.CanCollide }
                        part.Massless = true
                        part.CanCollide = false
                        local w = Instance.new("WeldConstraint")
                        w.Name = "Twisted_TrailerWeld"
                        w.Part0 = seat
                        w.Part1 = part
                        w.Parent = seat
                        table.insert(T.Pools.welds, w)
                    end
                end
            end
            processModelParts(truckModel)
        end)
    else
        workspace.Gravity = T.Vars.origGravity
        for _, w in ipairs(T.Pools.welds) do 
            if w then w:Destroy() end 
        end
        table.clear(T.Pools.welds)
        for part, props in pairs(T.Pools.partProps) do
            if part and part.Parent then 
                part.Massless = props.Massless
                part.CanCollide = props.CanCollide 
            end
        end
        table.clear(T.Pools.partProps)
        
        pcall(function()
            local char = lp.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart then
                local seat = char.Humanoid.SeatPart
                if seat:FindFirstChild("T_TruckV") then seat.T_TruckV:Destroy() end
                if seat:FindFirstChild("T_TruckG") then seat.T_TruckG:Destroy() end
                local vR = seat.AssemblyRootPart or seat
                vR.AssemblyLinearVelocity = Vector3.new(0, -5, 0)
                vR.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end)
    end
end)

setAction(T.UI.CarFlyBtn, function() 
    T.State.CarFly = not T.State.CarFly
    updateBtnState(T.UI.CarFlyBtn, T.State.CarFly) 
    
    if not T.State.CarFly then
        pcall(function()
            local char = lp.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart then
                local vR = char.Humanoid.SeatPart.AssemblyRootPart or char.Humanoid.SeatPart
                if vR:FindFirstChild("T_FlyV") then vR.T_FlyV:Destroy() end
                if vR:FindFirstChild("T_FlyG") then vR.T_FlyG:Destroy() end
                vR.AssemblyLinearVelocity = Vector3.new(0, -5, 0)
                vR.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end)
    end
end)

setAction(T.UI.ViroquaBtn, function() TeleportTo(10303.44, 21.47, 10725.71) end)
setAction(T.UI.TruckJobBtn, function() TeleportTo(540.67, 21.50, 4979.54) end)
setAction(T.UI.HibinBtn, function() TeleportTo(-10334.72, 21.50, 2448.24) end)

-- =================[ ДЕЙСТВИЯ: ОСТАЛЬНОЕ ]=================
setAction(T.UI.ActiveModsBtn, function() 
    T.State.ShowActiveMods = not T.State.ShowActiveMods; 
    updateBtnState(T.UI.ActiveModsBtn, T.State.ShowActiveMods)
    ActiveModsFrame.Visible = T.State.ShowActiveMods
end)

setAction(T.UI.GodmodeBtn, function() T.State.Godmode = not T.State.Godmode; updateBtnState(T.UI.GodmodeBtn, T.State.Godmode) end)
setAction(T.UI.TornadoEspBtn, function() T.State.TornadoESP = not T.State.TornadoESP; updateBtnState(T.UI.TornadoEspBtn, T.State.TornadoESP) end)
setAction(T.UI.PlayerEspBtn, function() T.State.PlayerESP = not T.State.PlayerESP; updateBtnState(T.UI.PlayerEspBtn, T.State.PlayerESP) end)
setAction(T.UI.NoclipBtn, function() T.State.Noclip = not T.State.Noclip; updateBtnState(T.UI.NoclipBtn, T.State.Noclip) end)

setAction(T.UI.MyCarEspBtn, function() 
    T.State.MyCarESP = not T.State.MyCarESP
    updateBtnState(T.UI.MyCarEspBtn, T.State.MyCarESP)
    if not T.State.MyCarESP then myCarHighlight.Enabled = false end
end)

setAction(T.UI.FpsBoostBtn, function() 
    T.State.FpsBoost = not T.State.FpsBoost
    updateBtnState(T.UI.FpsBoostBtn, T.State.FpsBoost) 
    if T.State.FpsBoost then Lighting.GlobalShadows = false end 
end)

local origLight = {A = Lighting.Ambient, O = Lighting.OutdoorAmbient, B = Lighting.Brightness, G = Lighting.GlobalShadows}
setAction(T.UI.FullbrightBtn, function() 
    T.State.Fullbright = not T.State.Fullbright
    updateBtnState(T.UI.FullbrightBtn, T.State.Fullbright) 
    if T.State.Fullbright then 
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false 
    else 
        Lighting.Ambient = origLight.A
        Lighting.OutdoorAmbient = origLight.O
        Lighting.Brightness = origLight.B
        Lighting.GlobalShadows = origLight.G 
    end 
end)

setAction(T.UI.PriorLakeBtn, function() TeleportTo(824.15, 21.40, 3989.41) end)
setAction(T.UI.HazeltonBtn, function() TeleportTo(579.97, 21.40, -12242.14) end)
setAction(T.UI.HibbingBtn, function() TeleportTo(-10083.60, 21.36, 6639.73) end)

setAction(T.UI.TpToCarBtn, function()
    if T.Vars.mySmartCar and T.Vars.mySmartCar.Parent then
        local tp = T.Vars.mySmartCar.PrimaryPart or T.Vars.mySmartCar:FindFirstChildWhichIsA("BasePart", true)
        if tp then TeleportTo(tp.Position.X, tp.Position.Y, tp.Position.Z) end
    end
end)

setAction(T.UI.TpToTornadoBtn, function()
    local id = tonumber(T.UI.TornadoIdInput.Text)
    if id and T.Pools.tornados[id] and T.Pools.tornados[id].r then
        TeleportTo(T.Pools.tornados[id].r.Position.X, T.Pools.tornados[id].r.Position.Y + 15, T.Pools.tornados[id].r.Position.Z)
    end
end)

local function setupTrap(setBtn, tpBtn, idx)
    setAction(setBtn, function()
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            T.Pools.traps[idx] = lp.Character.HumanoidRootPart.Position
        end
    end)
    setAction(tpBtn, function() 
        if T.Pools.traps[idx] then 
            TeleportTo(T.Pools.traps[idx].X, T.Pools.traps[idx].Y, T.Pools.traps[idx].Z) 
        end 
    end)
end

setupTrap(T.UI.SetTrap1Btn, T.UI.TpTrap1Btn, 1)
setupTrap(T.UI.SetTrap2Btn, T.UI.TpTrap2Btn, 2)
setupTrap(T.UI.SetTrap3Btn, T.UI.TpTrap3Btn, 3)

for _, b in ipairs(T.Pools.binds) do
    local bindLbl = b:FindFirstChild("BindLabel")
    if bindLbl then
        bindLbl.MouseButton1Click:Connect(function()
            if T.Vars.currentBind then 
                local oldLbl = T.Vars.currentBind:FindFirstChild("BindLabel")
                if oldLbl then 
                    oldLbl.Text = "[-]"
                    oldLbl.TextColor3 = Color3.fromRGB(100, 100, 100) 
                end 
            end
            bindLbl.Text = "[?]"
            bindLbl.TextColor3 = COL_MAIN
            task.spawn(function() 
                task.wait(0.05)
                T.Vars.currentBind = b 
            end)
        end)
    end
end

UIS.InputBegan:Connect(function(input, gpe)
    if T.Vars.currentBind then
        local key = input.KeyCode
        if key == Enum.KeyCode.Backspace or key == Enum.KeyCode.Escape then
            local bindLabel = T.Vars.currentBind:FindFirstChild("BindLabel")
            if bindLabel then 
                bindLabel.Text = "[-]"
                bindLabel.TextColor3 = Color3.fromRGB(100, 100, 100) 
            end
            T.Vars.currentBind = nil
        elseif key ~= Enum.KeyCode.Unknown then
            local bindLabel = T.Vars.currentBind:FindFirstChild("BindLabel")
            if bindLabel then 
                bindLabel.Text = "[" .. key.Name .. "]"
                bindLabel.TextColor3 = Color3.fromRGB(100, 100, 100) 
            end
            T.Vars.currentBind = nil
        end
        return
    end

    if not gpe and input.KeyCode == Enum.KeyCode.Delete and isActivated then
        MainFrame.Visible = not MainFrame.Visible
    end
    
    if not gpe and isActivated then
        for _, b in ipairs(T.Pools.binds) do
            local lbl = b:FindFirstChild("BindLabel")
            if lbl and lbl.Text == "[" .. input.KeyCode.Name .. "]" then
                for _, conn in pairs(getconnections(b.MouseButton1Click)) do 
                    conn:Fire() 
                end
            end
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        T.Vars.activeSlider = nil 
    end
end)

print("[TWISTED] Step 5: Starting Async Engines...")

task.spawn(function()
    while task.wait(0.1) do
        local myCharacter = lp.Character 
        pcall(function()
            if myCharacter and myCharacter:FindFirstChild("Humanoid") then 
                local h = myCharacter.Humanoid 
                if h.SeatPart then 
                    local nM = getHighestModel(h.SeatPart) 
                    if nM and nM:IsA("Model") and nM ~= myCharacter and T.Vars.mySmartCar ~= nM then 
                        T.Vars.mySmartCar = nM 
                    end 
                end 
            end
        end)
        
        pcall(function()
            if T.State.ShowActiveMods then
                local str = ""
                local count = 0
                if T.State.CarFly then str = str .. "• Car Fly\n"; count = count + 1 end
                if T.State.TruckFly then str = str .. "• Truck Fly\n"; count = count + 1 end
                if T.State.Godmode then str = str .. "• Godmode\n"; count = count + 1 end
                if T.State.Noclip then str = str .. "• Noclip\n"; count = count + 1 end
                if T.State.FpsBoost then str = str .. "• FPS Boost\n"; count = count + 1 end
                if T.State.Fullbright then str = str .. "• Fullbright\n"; count = count + 1 end
                if T.State.TornadoESP then str = str .. "• Tornado ESP\n"; count = count + 1 end
                if T.State.PlayerESP then str = str .. "• Player ESP\n"; count = count + 1 end
                if T.State.MyCarESP then str = str .. "• My Car ESP\n"; count = count + 1 end
                
                if count == 0 then 
                    str = "None active."
                    count = 1 
                end
                
                ActiveModsLabel.Text = str
                ActiveModsFrame.Size = UDim2.new(0, 160, 0, 40 + (count * 16))
            end
        end)
        
        pcall(function()
            if not T.State.TornadoESP then
                for _, t in ipairs(T.Pools.tornados) do
                    if t.txtLbl then t.txtLbl:Destroy() end
                    if t.ln then t.ln:Destroy() end
                end
                table.clear(T.Pools.tornados); return
            end
            
            if tick() - T.Vars.lastTScan > 1 then
                T.Vars.lastTScan = tick()
                task.spawn(function()
                    local cnd = {}
                    local descendants = workspace:GetDescendants()
                    for i, v in ipairs(descendants) do
                        if i % 800 == 0 then RunService.Heartbeat:Wait() end
                        if v:IsA("BasePart") then
                            local n = string.lower(v.Name)
                            if (n:find("tornado") or n:find("funnel")) and v.Size.Y > 5 then
                                local bd = false
                                for _, w in ipairs({"tiv", "tv", "probe", "trap", "sensor", "radar", "screen", "warning", "watch", "siren", "intercept", "vehicle", "radio", "detector", "car", "seat"}) do
                                    if string.find(n, w) then bd = true; break end
                                end
                                if not bd then table.insert(cnd, v) end
                            end
                        end
                    end
                    
                    local grp = {}
                    for _, c in ipairs(cnd) do
                        local cls = false
                        for _, g in ipairs(grp) do 
                            if (c.Position - g.Position).Magnitude < 1000 then 
                                cls = true
                                break 
                            end 
                        end
                        if not cls then table.insert(grp, c) end
                    end
                    
                    for i = #T.Pools.tornados, 1, -1 do
                        local t = T.Pools.tornados[i]
                        local ex = false
                        for _, g in ipairs(grp) do 
                            if t.r == g then 
                                ex = true
                                break 
                            end 
                        end
                        if not ex then
                            if t.txtLbl then t.txtLbl:Destroy() end
                            if t.ln then t.ln:Destroy() end
                            table.remove(T.Pools.tornados, i)
                        end
                    end
                    
                    for _, g in ipairs(grp) do
                        local trd = false
                        for _, t in ipairs(T.Pools.tornados) do 
                            if t.r == g then 
                                trd = true
                                break 
                            end 
                        end
                        if not trd then
                            local txtLbl = Instance.new("TextLabel")
                            txtLbl.Name = "T_ESP_2D"
                            txtLbl.Size = UDim2.new(0, 200, 0, 50)
                            txtLbl.BackgroundTransparency = 1
                            txtLbl.TextColor3 = COL_MAIN
                            txtLbl.TextStrokeTransparency = 0.2
                            txtLbl.TextStrokeColor3 = Color3.new(0,0,0)
                            txtLbl.Font = UI_TITLE_FONT
                            txtLbl.TextSize = 14
                            txtLbl.Text = "Loading..."
                            txtLbl.ZIndex = 100
                            txtLbl.Visible = false
                            txtLbl.Parent = ScreenGui
                            
                            local ln = nil
                            if camera then 
                                ln = Instance.new("BoxHandleAdornment")
                                ln.Name = genName()
                                ln.Color3 = COL_MAIN
                                ln.Transparency = 0.4
                                ln.AlwaysOnTop = true
                                ln.ZIndex = 5
                                ln.Adornee = workspace.Terrain
                                ln.Parent = camera 
                            end
                            
                            local speedStr = getTornadoWindSpeed(getHighestModel(g))
                            table.insert(T.Pools.tornados, {r = g, txtLbl = txtLbl, ln = ln, lP = g.Position, lT = tick(), v = Vector3.new(), sY = g.Position.Y, speed = speedStr})
                        end
                    end
                end)
            end
        end)
    end
end)

RunService.RenderStepped:Connect(function(dt)
    T.Vars.frC = T.Vars.frC + 1 
    if tick() - T.Vars.fpsLT >= 1 then 
        pcall(function() 
            if Watermark:FindFirstChild("WmText") then 
                Watermark.WmText.Text = "Twisted XENO | FPS: " .. T.Vars.frC .. " | Ping: " .. math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) .. "ms" 
            end 
        end) 
        T.Vars.frC = 0
        T.Vars.fpsLT = tick() 
    end
    
    if GradBg.Visible then 
        pcall(function() BgGrad.Rotation = (tick() * 45) % 360 end) 
    end
    
    if MouseBg.Visible then
        local mPos = UIS:GetMouseLocation()
        if (mPos - T.Vars.lastMouse).Magnitude > 4 then
            T.Vars.lastMouse = mPos
            if #T.Pools.trail > 0 then
                local c = T.Pools.trail[T.Vars.trailIdx]
                if c then
                    T.Vars.trailIdx = (T.Vars.trailIdx % #T.Pools.trail) + 1
                    c.Position = UDim2.new(0, mPos.X, 0, mPos.Y)
                    c.Size = UDim2.new(0, 4, 0, 4)
                    c.BackgroundTransparency = 0
                    c.Visible = true
                    TweenService:Create(c, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0, 24, 0, 24), BackgroundTransparency = 1}):Play()
                end
            end
        end
    end
    
    if StarsBg.Visible then
        for _, starData in ipairs(T.Pools.shootingStars) do
            local star = starData.obj
            local nx = star.Position.X.Scale + (starData.sx * dt)
            local ny = star.Position.Y.Scale + (starData.sy * dt)
            star.Position = UDim2.new(nx, 0, ny, 0)
            local alpha = 0
            if nx < 0.05 then 
                alpha = 1 - (nx / 0.05) 
            elseif nx > 0.95 then 
                alpha = (nx - 0.95) / 0.05 
            elseif ny < 0.05 then 
                alpha = 1 - (ny / 0.05) 
            elseif ny > 0.95 then 
                alpha = (ny - 0.95) / 0.05 
            end
            star.BackgroundTransparency = math.clamp(alpha, 0, 1)
            
            if ny > 1.0 or nx > 1.0 then
                if math.random(1, 2) == 1 then 
                    star.Position = UDim2.new(math.random(10, 80) / 100, 0, 0.01, 0) 
                else 
                    star.Position = UDim2.new(0.01, 0, math.random(10, 80) / 100, 0) 
                end
                starData.sx = (math.random(20, 50) / 100) * T.Vars.starSpeed
                starData.sy = (math.random(20, 50) / 100) * T.Vars.starSpeed
                star.Rotation = math.deg(math.atan2(starData.sy, starData.sx))
                star.Size = UDim2.new(0, math.random(15, 45), 0, math.random(2, 3))
            end
        end
    end
    
    if RainBg.Visible then
        for _, d in ipairs(T.Pools.rain) do
            if d.obj and d.obj.Parent then
                d.obj.Position = UDim2.new(d.obj.Position.X.Scale, 0, d.obj.Position.Y.Scale + d.speed * dt, 0)
                if d.obj.Position.Y.Scale > 1.1 then 
                    d.obj.Position = UDim2.new(math.random(), 0, -0.1, 0) 
                end
            end
        end
    end
    
    if SnowBg.Visible then
        for _, f in ipairs(T.Pools.snow) do
            if f.obj and f.obj.Parent then
                f.phase = f.phase + dt * 2
                local sineX = math.sin(f.phase) * 0.002
                f.obj.Position = UDim2.new(f.obj.Position.X.Scale + sineX, 0, f.obj.Position.Y.Scale + f.speed * dt, 0)
                if f.obj.Position.Y.Scale > 1.1 then 
                    f.obj.Position = UDim2.new(math.random(), 0, -0.1, 0) 
                end
            end
        end
    end
    
    if CosmosBg.Visible then
        for _, s in ipairs(T.Pools.cosmos) do
            if s.obj and s.obj.Parent then
                s.z = s.z - (s.speed * dt)
                if s.z <= 0.01 then 
                    s.x = (math.random() - 0.5) * 2
                    s.y = (math.random() - 0.5) * 2
                    s.z = 1 
                end
                
                local px = (s.x / s.z) * 0.5 + 0.5
                local py = (s.y / s.z) * 0.5 + 0.5
                
                if px < 0 or px > 1 or py < 0 or py > 1 then
                    s.z = 0.01
                    s.obj.Visible = false
                else
                    local distFromCenter = math.sqrt(s.x^2 + s.y^2)
                    local length = math.clamp((1 - s.z) * 30 * distFromCenter, 2, 60)
                    local thickness = math.clamp(2 - s.z, 1, 3)
                    s.obj.Size = UDim2.new(0, length, 0, thickness)
                    s.obj.Rotation = math.deg(math.atan2(s.y, s.x))
                    s.obj.Position = UDim2.new(px, 0, py, 0)
                    local alpha = 0
                    if px < 0.05 then 
                        alpha = 1 - (px / 0.05) 
                    elseif px > 0.95 then 
                        alpha = (px - 0.95) / 0.05 
                    elseif py < 0.05 then 
                        alpha = 1 - (py / 0.05) 
                    elseif py > 0.95 then 
                        alpha = (py - 0.95) / 0.05 
                    end
                    s.obj.BackgroundTransparency = math.clamp(alpha, 0, 1)
                    s.obj.Visible = true
                end
            end
        end
    end

    if TornadoBgBg.Visible then
        local t = tick()
        local bgWidth = TornadoBgBg.AbsoluteSize.X
        if bgWidth == 0 then bgWidth = 600 end
        
        local tornadoCenterX = 0.5 + math.sin(t * 0.5) * 0.15 
        
        for _, pData in ipairs(T.Pools.bgTornadoParticles) do
            local p = pData.obj
            local curAngle = pData.angOffset + (t * pData.rotSpeed)
            
            local sinA = math.sin(curAngle)
            local cosA = math.cos(curAngle)
            
            local posX = tornadoCenterX + (sinA * (pData.radius / bgWidth))
            p.Position = UDim2.new(posX, 0, pData.yRel, 0)
            
            local depthFactor = (cosA + 1) / 2
            
            local perspectiveWidth = pData.baseWidth * (0.3 + 0.7 * math.abs(cosA))
            local sizeScale = 0.5 + (depthFactor * 0.8)
            local finalWidth = perspectiveWidth * sizeScale
            local finalHeight = math.clamp(3 * sizeScale, 1, 5)
            
            p.Size = UDim2.new(0, finalWidth, 0, finalHeight)
            p.BackgroundTransparency = 0.85 - (depthFactor * 0.6) 
            p.ZIndex = 12 + math.floor(depthFactor * 5)
        end
    end

    pcall(function()
        local myCharacter = lp.Character
        local myRoot = myCharacter and (myCharacter:FindFirstChild("HumanoidRootPart") or myCharacter.PrimaryPart)
        
        if T.State.PlayerESP and myRoot then
            for _, p in ipairs(Players:GetPlayers()) do
                if p == lp then continue end
                local c = p.Character
                local hd = c and c:FindFirstChild("Head")
                local hm = c and c:FindFirstChild("Humanoid")
                if hd and hm and hm.Health > 0 then
                    local pos, onScreen = camera:WorldToViewportPoint(hd.Position + Vector3.new(0, 1.5, 0))
                    local e = T.Pools.playerEsps[p]
                    if not e then
                        e = Instance.new("TextLabel")
                        e.Name = "PEspTxt"
                        e.Size = UDim2.new(0, 200, 0, 50)
                        e.BackgroundTransparency = 1
                        e.TextColor3 = COL_MAIN
                        e.TextStrokeTransparency = 0.2
                        e.TextStrokeColor3 = Color3.new(0,0,0)
                        e.Font = Enum.Font.GothamBold
                        e.TextSize = 13
                        e.Parent = ScreenGui
                        T.Pools.playerEsps[p] = e
                    end
                    if onScreen then
                        e.Visible = true
                        e.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 25)
                        local d = math.floor((myRoot.Position - hd.Position).Magnitude)
                        e.TextColor3 = COL_MAIN
                        e.Text = "[" .. p.Name .. "]\n" .. d .. " st"
                    else 
                        e.Visible = false 
                    end
                else
                    if T.Pools.playerEsps[p] then 
                        T.Pools.playerEsps[p]:Destroy()
                        T.Pools.playerEsps[p] = nil 
                    end
                end
            end
        else
            for p, e in pairs(T.Pools.playerEsps) do 
                e:Destroy() 
            end
            table.clear(T.Pools.playerEsps)
        end
    end)
    
    pcall(function()
        if T.State.MyCarESP and T.Vars.mySmartCar and T.Vars.mySmartCar.Parent then
            myCarHighlight.Adornee = T.Vars.mySmartCar
            myCarHighlight.Enabled = true
        else 
            myCarHighlight.Enabled = false 
        end
    end)
    
    pcall(function()
        if not T.State.TornadoESP then return end
        local myCharacter = lp.Character
        local myRoot = myCharacter and (myCharacter:FindFirstChild("HumanoidRootPart") or myCharacter.PrimaryPart)
        local rP = RaycastParams.new()
        rP.FilterType = Enum.RaycastFilterType.Exclude
        
        for i, t in ipairs(T.Pools.tornados) do
            if t.r and t.r.Parent and t.txtLbl and t.ln then
                local cP, cT = t.r.Position, tick()
                local timeDt = cT - t.lT
                local fL = {t.r}
                if myCharacter then table.insert(fL, myCharacter) end
                rP.FilterDescendantsInstances = fL
                
                local ht = workspace:Raycast(Vector3.new(cP.X, 1500, cP.Z), Vector3.new(0, -3000, 0), rP)
                local tY = ht and ht.Position.Y or cP.Y
                t.sY = t.sY and (t.sY * 0.8 + tY * 0.2) or tY
                
                if timeDt > 0.05 then
                    local mV = Vector3.new(cP.X - t.lP.X, 0, cP.Z - t.lP.Z)
                    local vl = mV / timeDt
                    if mV.Magnitude > 0.1 then 
                        t.v = t.v:Lerp(vl, 0.15) 
                    else 
                        t.v = t.v:Lerp(Vector3.new(), 0.15) 
                    end
                    t.lP, t.lT = cP, cT
                end
                
                local tPos = Vector3.new(cP.X, t.sY + 0.5, cP.Z)
                
                if t.ln then
                    if t.v.Magnitude > 2 then
                        t.ln.Visible = true
                        local pL = t.v.Magnitude * T.Vars.pathLen
                        t.ln.Size = Vector3.new(T.Vars.pathWid, 0.2, pL)
                        t.ln.CFrame = CFrame.lookAt(tPos, tPos + t.v) * CFrame.new(0, 0, -pL / 2)
                        t.ln.Color3 = COL_MAIN
                    else
                        t.ln.Visible = false
                    end
                end
                
                local pos, onScreen = camera:WorldToViewportPoint(tPos + Vector3.new(0, 50, 0))
                if onScreen then
                    t.txtLbl.Visible = true
                    t.txtLbl.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 25)
                    local distStr = "???"
                    if myRoot then 
                        distStr = tostring(math.floor((myRoot.Position - tPos).Magnitude)) .. " st" 
                    end
                    t.txtLbl.Text = string.format("[ %d ] 🌪️ TORNADO\nDist: %s\nWind: %s", i, distStr, tostring(t.speed))
                    t.txtLbl.TextColor3 = COL_MAIN
                else
                    t.txtLbl.Visible = false
                end
            end
        end
    end)
    
    if T.Vars.activeSlider then
        local mousePos = UIS:GetMouseLocation().X
        local pct = math.clamp((mousePos - T.Vars.activeSlider.btn.AbsolutePosition.X) / T.Vars.activeSlider.btn.AbsoluteSize.X, 0, 1)
        T.Vars.activeSlider.fill.Size = UDim2.new(pct, 0, 1, 0)
        local val = T.Vars.activeSlider.min + (T.Vars.activeSlider.max - T.Vars.activeSlider.min) * pct
        if not T.Vars.activeSlider.isFloat then val = math.floor(val) end
        T.Vars.activeSlider.lbl.Text = T.Vars.activeSlider.name .. (T.Vars.activeSlider.isFloat and string.format("%.1f", val) or tostring(val))
        T.Vars.activeSlider.cb(val)
    end
end)

RunService.Stepped:Connect(function()
    pcall(function()
        if T.State.Godmode and lp.Character then 
            local hm = lp.Character:FindFirstChild("Humanoid") 
            if hm and not hm.SeatPart then 
                local st = hm:GetState() 
                if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then 
                    hm:ChangeState(Enum.HumanoidStateType.GettingUp) 
                end 
            end 
        end
        if T.State.Noclip and lp.Character then 
            for _, p in pairs(lp.Character:GetDescendants()) do 
                if p:IsA("BasePart") then p.CanCollide = false end 
            end 
            local hm = lp.Character:FindFirstChild("Humanoid") 
            if hm and hm.SeatPart then 
                local c = getHighestModel(hm.SeatPart) 
                if c then 
                    for _, p in pairs(c:GetDescendants()) do 
                        if p:IsA("BasePart") then p.CanCollide = false end 
                    end 
                end 
            end 
        end
    end)
end)

RunService.Heartbeat:Connect(function()
    pcall(function()
        local myCharacter = lp.Character 
        if myCharacter and myCharacter:FindFirstChild("Humanoid") then 
            local hm = myCharacter.Humanoid
            local r = myCharacter:FindFirstChild("HumanoidRootPart") or myCharacter.PrimaryPart
            
            if T.State.TruckFly then
                if not hm.SeatPart then 
                    workspace.Gravity = T.Vars.origGravity
                else
                    workspace.Gravity = 0 
                    local seat = hm.SeatPart 
                    local bv = seat:FindFirstChild("T_TruckV") or Instance.new("BodyVelocity", seat)
                    bv.Name = "T_TruckV"
                    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    
                    local bg = seat:FindFirstChild("T_TruckG") or Instance.new("BodyGyro", seat)
                    bg.Name = "T_TruckG"
                    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    bg.P = 9e5
                    bg.D = 500
                    
                    local d = Vector3.new(0,0,0)
                    local cF = camera.CFrame 
                    local flatLook = Vector3.new(cF.LookVector.X, 0, cF.LookVector.Z)
                    if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
                    
                    if UIS:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end 
                    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end 
                    if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + cF.LookVector end 
                    if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - cF.LookVector end 
                    if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - cF.RightVector end 
                    if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + cF.RightVector end 
                    
                    if d.Magnitude > 0 then d = d.Unit end 
                    bv.Velocity = d * T.Vars.truckSpeed
                    if flatLook.Magnitude > 0 then bg.CFrame = CFrame.lookAt(seat.Position, seat.Position + flatLook) end
                end
            elseif T.State.CarFly and hm.SeatPart then 
                local vR = hm.SeatPart.AssemblyRootPart or hm.SeatPart 
                local bv = vR:FindFirstChild("T_FlyV") or Instance.new("BodyVelocity", vR)
                bv.Name = "T_FlyV"
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                local bg = vR:FindFirstChild("T_FlyG") or Instance.new("BodyGyro", vR)
                bg.Name = "T_FlyG"
                bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bg.P = 9e5
                bg.D = 500
                
                local d, cF = Vector3.new(0,0,0), camera.CFrame 
                if UIS:IsKeyDown(Enum.KeyCode.Space) then d = d + Vector3.new(0, 1, 0) end 
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then d = d - Vector3.new(0, 1, 0) end 
                if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + cF.LookVector end 
                if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - cF.LookVector end 
                if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - cF.RightVector end 
                if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + cF.RightVector end 
                
                if d.Magnitude > 0 then d = d.Unit end 
                bv.Velocity = d * T.Vars.carSpeed
                bg.CFrame = CFrame.lookAt(vR.Position, vR.Position + cF.LookVector)
            end
        end
    end)
end)

ChangeTheme("RED")
updateBgBtns(T.UI.btnBgSolid)

print("[TWISTED] Step 6: Opening Interface...")
if KeyFrame then KeyFrame.Visible = true end
print("[TWISTED] SUCCESS! Script fully loaded.")
