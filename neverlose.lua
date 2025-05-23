--[[
    NeverloseUI Library for Roblox
    A comprehensive UI library with animations, theming, and modular components
    
    Features:
    - Fully customizable theme system
    - Smooth animations and transitions
    - Complete set of UI components
    - Overlay elements (watermark, spectator list, keybinds, radar)
    - Notification system with different types
    - Responsive and draggable windows
]]

local NeverloseUI = {}
NeverloseUI.__index = NeverloseUI

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")

-- Constants
local PLAYER = Players.LocalPlayer
local MOUSE = PLAYER:GetMouse()

-- Default theme
local DEFAULT_THEME = {
    colors = {
        background = Color3.fromRGB(25, 25, 35),
        backgroundLight = Color3.fromRGB(30, 30, 40),
        backgroundDark = Color3.fromRGB(20, 20, 30),
        accent = Color3.fromRGB(90, 140, 240),
        accentDark = Color3.fromRGB(70, 110, 200),
        accentLight = Color3.fromRGB(110, 160, 255),
        text = Color3.fromRGB(240, 240, 240),
        textDark = Color3.fromRGB(180, 180, 180),
        success = Color3.fromRGB(100, 200, 100),
        warning = Color3.fromRGB(240, 180, 60),
        error = Color3.fromRGB(240, 80, 80),
        info = Color3.fromRGB(80, 160, 240),
    },
    transparency = {
        background = 0.05,
        section = 0.05,
        element = 0.05,
    },
    fonts = {
        main = Enum.Font.Gotham,
        bold = Enum.Font.GothamBold,
        semi = Enum.Font.GothamSemibold,
    },
    sizes = {
        padding = 4,
        borderSize = 1,
        cornerRadius = 4,
        textSize = 14,
        iconSize = 16,
    },
    animation = {
        tween = {
            time = 0.2,
            style = Enum.EasingStyle.Quad,
            direction = Enum.EasingDirection.Out,
        },
        spring = {
            damping = 10,
            stiffness = 100,
            mass = 0.5,
        },
    },
}

-- Utility functions
local Utility = {}

-- Create a tween
function Utility.Tween(instance, properties, duration, style, direction, delay, callback)
    local tweenInfo = TweenInfo.new(
        duration or DEFAULT_THEME.animation.tween.time,
        style or DEFAULT_THEME.animation.tween.style,
        direction or DEFAULT_THEME.animation.tween.direction,
        0, false, delay or 0
    )
    
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    
    if callback then
        tween.Completed:Connect(callback)
    end
    
    return tween
end

-- Create a spring animation
function Utility.Spring(instance, property, target, damping, stiffness, mass)
    local spring = {}
    spring.Target = target
    spring.Position = instance[property]
    spring.Velocity = 0
    spring.Damping = damping or DEFAULT_THEME.animation.spring.damping
    spring.Stiffness = stiffness or DEFAULT_THEME.animation.spring.stiffness
    spring.Mass = mass or DEFAULT_THEME.animation.spring.mass
    
    local connection
    connection = RunService.RenderStepped:Connect(function(deltaTime)
        local force = spring.Stiffness * (spring.Target - spring.Position) - spring.Damping * spring.Velocity
        local acceleration = force / spring.Mass
        
        spring.Velocity = spring.Velocity + acceleration * deltaTime
        spring.Position = spring.Position + spring.Velocity * deltaTime
        
        instance[property] = spring.Position
        
        -- Check if we're close enough to the target to stop the animation
        if math.abs(spring.Target - spring.Position) < 0.001 and math.abs(spring.Velocity) < 0.001 then
            instance[property] = spring.Target
            connection:Disconnect()
        end
    end)
    
    return spring
end

-- Create a new instance
function Utility.Create(className, properties, children)
    local instance = Instance.new(className)
    
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    
    return instance
end

-- Get text bounds
function Utility.GetTextBounds(text, textSize, font, frameSize)
    return TextService:GetTextSize(text, textSize, font, frameSize)
end

-- Drag functionality
function Utility.MakeDraggable(frame, dragArea, callback)
    local dragging, dragInput, dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        
        if callback then
            callback(frame.Position)
        end
    end
    
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
    
    return {
        Destroy = function()
            dragArea.InputBegan:Connect(function() end):Disconnect()
            dragArea.InputChanged:Connect(function() end):Disconnect()
        end
    }
end

-- Ripple effect
function Utility.CreateRipple(parent, startPosition, color)
    local ripple = Utility.Create("Frame", {
        Name = "Ripple",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = color or Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Position = UDim2.new(0, startPosition.X, 0, startPosition.Y),
        Size = UDim2.new(0, 0, 0, 0),
        ZIndex = 10,
        Parent = parent
    })
    
    local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
    
    Utility.Tween(ripple, {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    }, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, function()
        ripple:Destroy()
    end)
    
    return ripple
end

-- Create a new UI instance
function NeverloseUI.new(customTheme)
    local self = setmetatable({}, NeverloseUI)
    
    -- Merge custom theme with default theme
    self.theme = DEFAULT_THEME
    if customTheme then
        for category, values in pairs(customTheme) do
            if type(values) == "table" then
                for key, value in pairs(values) do
                    self.theme[category][key] = value
                end
            else
                self.theme[category] = values
            end
        end
    end
    
    -- Create main container
    self.container = Utility.Create("ScreenGui", {
        Name = "NeverloseUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    -- Try to parent to CoreGui if possible (for better compatibility with other scripts)
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(self.container)
            self.container.Parent = CoreGui
        elseif gethui then
            self.container.Parent = gethui()
        else
            self.container.Parent = CoreGui
        end
    end)
    
    if not self.container.Parent then
        self.container.Parent = PLAYER.PlayerGui
    end
    
    -- Create notification container
    self.notificationContainer = Utility.Create("Frame", {
        Name = "NotificationContainer",
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -10, 0, 10),
        Size = UDim2.new(0, 300, 1, -20),
        Parent = self.container
    })
    
    -- Create overlay container
    self.overlayContainer = Utility.Create("Frame", {
        Name = "OverlayContainer",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self.container
    })
    
    -- Create window container
    self.windowContainer = Utility.Create("Frame", {
        Name = "WindowContainer",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = self.container
    })
    
    -- Active windows
    self.windows = {}
    
    -- Active overlays
    self.overlays = {
        watermark = nil,
        spectatorList = nil,
        keybindsList = nil,
        radar = nil
    }
    
    -- Active notifications
    self.notifications = {}
    
    -- Toggle key (INSERT by default)
    self.toggleKey = Enum.KeyCode.Insert
    
    -- Set up toggle key listener
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == self.toggleKey then
            self:ToggleUI()
        end
    end)
    
    -- UI visibility state
    self.visible = true
    
    return self
end

-- Toggle UI visibility
function NeverloseUI:ToggleUI()
    self.visible = not self.visible
    
    -- Toggle windows
    for _, window in pairs(self.windows) do
        window.Frame.Visible = self.visible
    end
    
    -- Create notification
    if self.visible then
        self:CreateNotification("UI Toggled", "UI is now visible", "info", 2)
    end
end

-- Set toggle key
function NeverloseUI:SetToggleKey(keyCode)
    self.toggleKey = keyCode
end

-- Create a notification
function NeverloseUI:CreateNotification(title, message, notificationType, duration)
    notificationType = notificationType or "info"
    duration = duration or 3
    
    -- Get color based on notification type
    local color
    if notificationType == "success" then
        color = self.theme.colors.success
    elseif notificationType == "warning" then
        color = self.theme.colors.warning
    elseif notificationType == "error" then
        color = self.theme.colors.error
    else
        color = self.theme.colors.info
    end
    
    -- Create notification frame
    local notification = Utility.Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = self.theme.colors.backgroundLight,
        BackgroundTransparency = self.theme.transparency.background,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 10, 0, #self.notifications * 80),
        Size = UDim2.new(1, 0, 0, 70),
        Parent = self.notificationContainer
    })
    
    -- Create corner
    local corner = Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
        Parent = notification
    })
    
    -- Create stroke
    local stroke = Utility.Create("UIStroke", {
        Color = color,
        Thickness = self.theme.sizes.borderSize,
        Parent = notification
    })
    
    -- Create accent bar
    local accentBar = Utility.Create("Frame", {
        Name = "AccentBar",
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 3, 1, 0),
        Parent = notification
    })
    
    -- Create accent bar corner
    local accentBarCorner = Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
        Parent = accentBar
    })
    
    -- Create title
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -25, 0, 20),
        Font = self.theme.fonts.bold,
        Text = title,
        TextColor3 = self.theme.colors.text,
        TextSize = self.theme.sizes.textSize + 2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    -- Create message
    local messageLabel = Utility.Create("TextLabel", {
        Name = "Message",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 30),
        Size = UDim2.new(1, -25, 0, 20),
        Font = self.theme.fonts.main,
        Text = message,
        TextColor3 = self.theme.colors.textDark,
        TextSize = self.theme.sizes.textSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    -- Create progress bar
    local progressBarBackground = Utility.Create("Frame", {
        Name = "ProgressBarBackground",
        BackgroundColor3 = self.theme.colors.backgroundDark,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 15, 1, -10),
        Size = UDim2.new(1, -30, 0, 3),
        Parent = notification
    })
    
    -- Create progress bar corner
    local progressBarBackgroundCorner = Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
        Parent = progressBarBackground
    })
    
    -- Create progress bar fill
    local progressBarFill = Utility.Create("Frame", {
        Name = "ProgressBarFill",
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = progressBarBackground
    })
    
    -- Create progress bar fill corner
    local progressBarFillCorner = Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
        Parent = progressBarFill
    })
    
    -- Add to notifications table
    table.insert(self.notifications, notification)
    
    -- Animate in
    notification.Position = UDim2.new(1, 10, 0, (#self.notifications - 1) * 80)
    Utility.Tween(notification, {Position = UDim2.new(0, 0, 0, (#self.notifications - 1) * 80)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    -- Animate progress bar
    Utility.Tween(progressBarFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, function()
        -- Animate out
        Utility.Tween(notification, {Position = UDim2.new(1, 10, 0, notification.Position.Y.Offset)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, function()
            -- Remove from notifications table
            for i, notif in ipairs(self.notifications) do
                if notif == notification then
                    table.remove(self.notifications, i)
                    break
                end
            end
            
            -- Reposition remaining notifications
            for i, notif in ipairs(self.notifications) do
                Utility.Tween(notif, {Position = UDim2.new(0, 0, 0, (i - 1) * 80)}, 0.3)
            end
            
            -- Destroy notification
            notification:Destroy()
        end)
    end)
    
    -- Return notification object
    return {
        Frame = notification,
        Close = function()
            Utility.Tween(notification, {Position = UDim2.new(1, 10, 0, notification.Position.Y.Offset)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, function()
                -- Remove from notifications table
                for i, notif in ipairs(self.notifications) do
                    if notif == notification then
                        table.remove(self.notifications, i)
                        break
                    end
                end
                
                -- Reposition remaining notifications
                for i, notif in ipairs(self.notifications) do
                    Utility.Tween(notif, {Position = UDim2.new(0, 0, 0, (i - 1) * 80)}, 0.3)
                end
                
                -- Destroy notification
                notification:Destroy()
            end)
        end
    }
end

-- Create a window
function NeverloseUI:CreateWindow(title, size)
    size = size or UDim2.new(0, 600, 0, 400)
    
    -- Create window frame
    local windowFrame = Utility.Create("Frame", {
        Name = "Window",
        BackgroundColor3 = self.theme.colors.background,
        BackgroundTransparency = self.theme.transparency.background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        Size = size,
        Parent = self.windowContainer
    })
    
    -- Create corner
    local corner = Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
        Parent = windowFrame
    })
    
    -- Create stroke
    local stroke = Utility.Create("UIStroke", {
        Color = self.theme.colors.accent,
        Thickness = self.theme.sizes.borderSize,
        Parent = windowFrame
    })
    
    -- Create title bar
    local titleBar = Utility.Create("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = self.theme.colors.backgroundDark,
        BackgroundTransparency = self.theme.transparency.background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 30),
        Parent = windowFrame
    })
    
    -- Create title bar corner
    local titleBarCorner = Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
        Parent = titleBar
    })
    
    -- Create title
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = self.theme.fonts.bold,
        Text = title,
        TextColor3 = self.theme.colors.text,
        TextSize = self.theme.sizes.textSize + 2,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })
    
    -- Create close button
    local closeButton = Utility.Create("TextButton", {
        Name = "CloseButton",
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -5, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        Font = self.theme.fonts.bold,
        Text = "×",
        TextColor3 = self.theme.colors.text,
        TextSize = self.theme.sizes.textSize + 10,
        Parent = titleBar
    })
    
    -- Close button hover effect
    closeButton.MouseEnter:Connect(function()
        Utility.Tween(closeButton, {TextColor3 = self.theme.colors.error}, 0.2)
    end)
    
    closeButton.MouseLeave:Connect(function()
        Utility.Tween(closeButton, {TextColor3 = self.theme.colors.text}, 0.2)
    end)
    
    -- Close button click
    closeButton.MouseButton1Click:Connect(function()
        Utility.Tween(windowFrame, {Size = UDim2.new(0, windowFrame.Size.X.Offset, 0, 0)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, function()
            windowFrame:Destroy()
            
            -- Remove from windows table
            for i, window in pairs(self.windows) do
                if window.Frame == windowFrame then
                    self.windows[i] = nil
                    break
                end
            end
        end)
    end)
    
    -- Create content container
    local contentContainer = Utility.Create("Frame", {
        Name = "ContentContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 1, -30),
        Parent = windowFrame
    })
    
    -- Make window draggable
    Utility.MakeDraggable(windowFrame, titleBar)
    
    -- Add to windows table
    local window = {
        Frame = windowFrame,
        Title = titleLabel,
        Content = contentContainer,
        TabSystem = nil,
        Tabs = {}
    }
    
    table.insert(self.windows, window)
    
    -- Add tab system function
    function window.AddTabSystem()
        -- Create tab container
        local tabContainer = Utility.Create("Frame", {
            Name = "TabContainer",
            BackgroundColor3 = self.theme.colors.backgroundDark,
            BackgroundTransparency = self.theme.transparency.background,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 120, 1, 0),
            Parent = contentContainer
        })
        
        -- Create tab buttons container
        local tabButtonsContainer = Utility.Create("ScrollingFrame", {
            Name = "TabButtonsContainer",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = self.theme.colors.accent,
            Parent = tabContainer
        })
        
        -- Create tab buttons layout
        local tabButtonsLayout = Utility.Create("UIListLayout", {
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = tabButtonsContainer
        })
        
        -- Create tab content container
        local tabContentContainer = Utility.Create("Frame", {
            Name = "TabContentContainer",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 120, 0, 0),
            Size = UDim2.new(1, -120, 1, 0),
            Parent = contentContainer
        })
        
        -- Set up tab system
        window.TabSystem = {
            Container = tabContainer,
            ButtonsContainer = tabButtonsContainer,
            ContentContainer = tabContentContainer,
            Tabs = {},
            ActiveTab = nil
        }
        
        -- Add tab function
        function window.TabSystem.AddTab(name, icon)
            -- Create tab button
            local tabButton = Utility.Create("TextButton", {
                Name = name .. "Button",
                BackgroundColor3 = self.theme.colors.background,
                BackgroundTransparency = self.theme.transparency.background,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 30),
                Font = self.theme.fonts.main,
                Text = "",
                TextColor3 = self.theme.colors.text,
                TextSize = self.theme.sizes.textSize,
                Parent = tabButtonsContainer
            })
            
            -- Create tab button corner
            local tabButtonCorner = Utility.Create("UICorner", {
                CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
                Parent = tabButton
            })
            
            -- Create tab button accent
            local tabButtonAccent = Utility.Create("Frame", {
                Name = "Accent",
                BackgroundColor3 = self.theme.colors.accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 2, 1, 0),
                Parent = tabButton
            })
            
            -- Create tab button accent corner
            local tabButtonAccentCorner = Utility.Create("UICorner", {
                CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
                Parent = tabButtonAccent
            })
            
            -- Create tab button icon (if provided)
            local tabButtonIcon
            if icon then
                tabButtonIcon = Utility.Create("ImageLabel", {
                    Name = "Icon",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0.5, -8),
                    Size = UDim2.new(0, 16, 0, 16),
                    Image = icon,
                    ImageColor3 = self.theme.colors.textDark,
                    Parent = tabButton
                })
            end
            
            -- Create tab button label
            local tabButtonLabel = Utility.Create("TextLabel", {
                Name = "Label",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, icon and 35 or 15, 0, 0),
                Size = UDim2.new(1, icon and -45 or -25, 1, 0),
                Font = self.theme.fonts.main,
                Text = name,
                TextColor3 = self.theme.colors.textDark,
                TextSize = self.theme.sizes.textSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = tabButton
            })
            
            -- Create tab content
            local tabContent = Utility.Create("ScrollingFrame", {
                Name = name .. "Content",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = self.theme.colors.accent,
                Visible = false,
                Parent = tabContentContainer
            })
            
            -- Create tab content padding
            local tabContentPadding = Utility.Create("UIPadding", {
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 10),
                Parent = tabContent
            })
            
            -- Create tab content layout
            local tabContentLayout = Utility.Create("UIListLayout", {
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = tabContent
            })
            
            -- Update canvas size when children change
            tabContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                tabContent.CanvasSize = UDim2.new(0, 0, 0, tabContentLayout.AbsoluteContentSize.Y + 20)
            end)
            
            -- Create tab object
            local tab = {
                Name = name,
                Button = tabButton,
                Content = tabContent,
                Sections = {}
            }
            
            -- Add section function
            function tab.AddSection(sectionName)
                -- Create section frame
                local sectionFrame = Utility.Create("Frame", {
                    Name = sectionName .. "Section",
                    BackgroundColor3 = self.theme.colors.backgroundLight,
                    BackgroundTransparency = self.theme.transparency.section,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 30), -- Will be resized based on content
                    Parent = tabContent
                })
                
                -- Create section corner
                local sectionCorner = Utility.Create("UICorner", {
                    CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
                    Parent = sectionFrame
                })
                
                -- Create section stroke
                local sectionStroke = Utility.Create("UIStroke", {
                    Color = self.theme.colors.accent,
                    Thickness = 1,
                    Transparency = 0.8,
                    Parent = sectionFrame
                })
                
                -- Create section title
                local sectionTitle = Utility.Create("TextLabel", {
                    Name = "Title",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -20, 0, 30),
                    Font = self.theme.fonts.semi,
                    Text = sectionName,
                    TextColor3 = self.theme.colors.text,
                    TextSize = self.theme.sizes.textSize,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = sectionFrame
                })
                
                -- Create section content
                local sectionContent = Utility.Create("Frame", {
                    Name = "Content",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 30),
                    Size = UDim2.new(1, 0, 0, 0), -- Will be resized based on content
                    Parent = sectionFrame
                })
                
                -- Create section content padding
                local sectionContentPadding = Utility.Create("UIPadding", {
                    PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 10),
                    PaddingRight = UDim.new(0, 10),
                    PaddingTop = UDim.new(0, 5),
                    Parent = sectionContent
                })
                
                -- Create section content layout
                local sectionContentLayout = Utility.Create("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = sectionContent
                })
                
                -- Update section size when children change
                sectionContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    sectionContent.Size = UDim2.new(1, 0, 0, sectionContentLayout.AbsoluteContentSize.Y + 15)
                    sectionFrame.Size = UDim2.new(1, 0, 0, 30 + sectionContent.Size.Y.Offset)
                end)
                
                -- Create section object
                local section = {
                    Name = sectionName,
                    Frame = sectionFrame,
                    Content = sectionContent,
                    Elements = {}
                }
                
                -- Add checkbox function
                function section.AddCheckbox(checkboxName, defaultValue)
                    defaultValue = defaultValue or false
                    
                    -- Create checkbox container
                    local checkboxContainer = Utility.Create("Frame", {
                        Name = checkboxName .. "Container",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 20),
                        Parent = sectionContent
                    })
                    
                    -- Create checkbox label
                    local checkboxLabel = Utility.Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 25, 0, 0),
                        Size = UDim2.new(1, -25, 1, 0),
                        Font = self.theme.fonts.main,
                        Text = checkboxName,
                        TextColor3 = self.theme.colors.text,
                        TextSize = self.theme.sizes.textSize,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = checkboxContainer
                    })
                    
                    -- Create checkbox button
                    local checkboxButton = Utility.Create("Frame", {
                        Name = "Button",
                        BackgroundColor3 = defaultValue and self.theme.colors.accent or self.theme.colors.backgroundDark,
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, 0, 0.5, -7),
                        Size = UDim2.new(0, 14, 0, 14),
                        Parent = checkboxContainer
                    })
                    
                    -- Create checkbox button corner
                    local checkboxButtonCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(0, 2),
                        Parent = checkboxButton
                    })
                    
                    -- Create checkbox button stroke
                    local checkboxButtonStroke = Utility.Create("UIStroke", {
                        Color = self.theme.colors.accent,
                        Thickness = 1,
                        Parent = checkboxButton
                    })
                    
                    -- Create checkbox check
                    local checkboxCheck = Utility.Create("ImageLabel", {
                        Name = "Check",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0.5, -5, 0.5, -5),
                        Size = UDim2.new(0, 10, 0, 10),
                        Image = "rbxassetid://6031094667",
                        ImageColor3 = self.theme.colors.text,
                        ImageTransparency = defaultValue and 0 or 1,
                        Parent = checkboxButton
                    })
                    
                    -- Create checkbox hitbox
                    local checkboxHitbox = Utility.Create("TextButton", {
                        Name = "Hitbox",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        Parent = checkboxContainer
                    })
                    
                    -- Checkbox state
                    local checked = defaultValue
                    
                    -- Checkbox value changed callback
                    local onChangedCallback = nil
                    
                    -- Update checkbox visual
                    local function updateCheckbox()
                        Utility.Tween(checkboxButton, {BackgroundColor3 = checked and self.theme.colors.accent or self.theme.colors.backgroundDark}, 0.2)
                        Utility.Tween(checkboxCheck, {ImageTransparency = checked and 0 or 1}, 0.2)
                        
                        if onChangedCallback then
                            onChangedCallback(checked)
                        end
                    end
                    
                    -- Checkbox click
                    checkboxHitbox.MouseButton1Click:Connect(function()
                        checked = not checked
                        updateCheckbox()
                    end)
                    
                    -- Create checkbox object
                    local checkbox = {
                        Name = checkboxName,
                        Container = checkboxContainer,
                        Value = checked,
                        SetValue = function(self, value)
                            checked = value
                            updateCheckbox()
                        end,
                        GetValue = function(self)
                            return checked
                        end,
                        OnChanged = function(self, callback)
                            onChangedCallback = callback
                            return self
                        end
                    }
                    
                    -- Add to section elements
                    table.insert(section.Elements, checkbox)
                    
                    return checkbox
                end
                
                -- Add slider function
                function section.AddSlider(sliderName, min, max, default, increment)
                    min = min or 0
                    max = max or 100
                    default = default or min
                    increment = increment or 1
                    
                    -- Clamp default value
                    default = math.clamp(default, min, max)
                    
                    -- Create slider container
                    local sliderContainer = Utility.Create("Frame", {
                        Name = sliderName .. "Container",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 40),
                        Parent = sectionContent
                    })
                    
                    -- Create slider label
                    local sliderLabel = Utility.Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 0),
                        Size = UDim2.new(1, 0, 0, 20),
                        Font = self.theme.fonts.main,
                        Text = sliderName,
                        TextColor3 = self.theme.colors.text,
                        TextSize = self.theme.sizes.textSize,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = sliderContainer
                    })
                    
                    -- Create slider value
                    local sliderValue = Utility.Create("TextLabel", {
                        Name = "Value",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -40, 0, 0),
                        Size = UDim2.new(0, 40, 0, 20),
                        Font = self.theme.fonts.main,
                        Text = tostring(default),
                        TextColor3 = self.theme.colors.accent,
                        TextSize = self.theme.sizes.textSize,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Parent = sliderContainer
                    })
                    
                    -- Create slider background
                    local sliderBackground = Utility.Create("Frame", {
                        Name = "Background",
                        BackgroundColor3 = self.theme.colors.backgroundDark,
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, 0, 0, 25),
                        Size = UDim2.new(1, 0, 0, 6),
                        Parent = sliderContainer
                    })
                    
                    -- Create slider background corner
                    local sliderBackgroundCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(0, 3),
                        Parent = sliderBackground
                    })
                    
                    -- Create slider fill
                    local sliderFill = Utility.Create("Frame", {
                        Name = "Fill",
                        BackgroundColor3 = self.theme.colors.accent,
                        BorderSizePixel = 0,
                        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                        Parent = sliderBackground
                    })
                    
                    -- Create slider fill corner
                    local sliderFillCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(0, 3),
                        Parent = sliderFill
                    })
                    
                    -- Create slider knob
                    local sliderKnob = Utility.Create("Frame", {
                        Name = "Knob",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = self.theme.colors.text,
                        BorderSizePixel = 0,
                        Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
                        Size = UDim2.new(0, 10, 0, 10),
                        ZIndex = 2,
                        Parent = sliderBackground
                    })
                    
                    -- Create slider knob corner
                    local sliderKnobCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(1, 0),
                        Parent = sliderKnob
                    })
                    
                    -- Create slider hitbox
                    local sliderHitbox = Utility.Create("TextButton", {
                        Name = "Hitbox",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, -5, 0, -5),
                        Size = UDim2.new(1, 10, 1, 10),
                        Text = "",
                        ZIndex = 3,
                        Parent = sliderBackground
                    })
                    
                    -- Slider value
                    local value = default
                    
                    -- Slider value changed callback
                    local onChangedCallback = nil
                    
                    -- Update slider visual
                    local function updateSlider()
                        local percent = (value - min) / (max - min)
                        
                        Utility.Tween(sliderFill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
                        Utility.Tween(sliderKnob, {Position = UDim2.new(percent, 0, 0.5, 0)}, 0.1)
                        sliderValue.Text = tostring(value)
                        
                        if onChangedCallback then
                            onChangedCallback(value)
                        end
                    end
                    
                    -- Slider drag
                    local dragging = false
                    
                    sliderHitbox.MouseButton1Down:Connect(function()
                        dragging = true
                        
                        -- Calculate value from mouse position
                        local percent = math.clamp((MOUSE.X - sliderBackground.AbsolutePosition.X) / sliderBackground.AbsoluteSize.X, 0, 1)
                        local newValue = min + (max - min) * percent
                        
                        -- Apply increment
                        newValue = math.floor(newValue / increment + 0.5) * increment
                        
                        -- Clamp value
                        value = math.clamp(newValue, min, max)
                        
                        updateSlider()
                    end)
                    
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                            -- Calculate value from mouse position
                            local percent = math.clamp((MOUSE.X - sliderBackground.AbsolutePosition.X) / sliderBackground.AbsoluteSize.X, 0, 1)
                            local newValue = min + (max - min) * percent
                            
                            -- Apply increment
                            newValue = math.floor(newValue / increment + 0.5) * increment
                            
                            -- Clamp value
                            value = math.clamp(newValue, min, max)
                            
                            updateSlider()
                        end
                    end)
                    
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = false
                        end
                    end)
                    
                    -- Create slider object
                    local slider = {
                        Name = sliderName,
                        Container = sliderContainer,
                        Value = value,
                        SetValue = function(self, newValue)
                            -- Clamp value
                            value = math.clamp(newValue, min, max)
                            updateSlider()
                        end,
                        GetValue = function(self)
                            return value
                        end,
                        OnChanged = function(self, callback)
                            onChangedCallback = callback
                            return self
                        end
                    }
                    
                    -- Add to section elements
                    table.insert(section.Elements, slider)
                    
                    return slider
                end
                
                -- Add dropdown function
                function section.AddDropdown(dropdownName, options, default)
                    options = options or {}
                    default = default or (options[1] or "")
                    
                    -- Create dropdown container
                    local dropdownContainer = Utility.Create("Frame", {
                        Name = dropdownName .. "Container",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 40),
                        ClipsDescendants = true,
                        Parent = sectionContent
                    })
                    
                    -- Create dropdown label
                    local dropdownLabel = Utility.Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 0),
                        Size = UDim2.new(1, 0, 0, 20),
                        Font = self.theme.fonts.main,
                        Text = dropdownName,
                        TextColor3 = self.theme.colors.text,
                        TextSize = self.theme.sizes.textSize,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = dropdownContainer
                    })
                    
                    -- Create dropdown button
                    local dropdownButton = Utility.Create("Frame", {
                        Name = "Button",
                        BackgroundColor3 = self.theme.colors.backgroundDark,
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, 0, 0, 20),
                        Size = UDim2.new(1, 0, 0, 20),
                        Parent = dropdownContainer
                    })
                    
                    -- Create dropdown button corner
                    local dropdownButtonCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = dropdownButton
                    })
                    
                    -- Create dropdown button stroke
                    local dropdownButtonStroke = Utility.Create("UIStroke", {
                        Color = self.theme.colors.accent,
                        Thickness = 1,
                        Transparency = 0.5,
                        Parent = dropdownButton
                    })
                    
                    -- Create dropdown selected
                    local dropdownSelected = Utility.Create("TextLabel", {
                        Name = "Selected",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0, 0),
                        Size = UDim2.new(1, -40, 1, 0),
                        Font = self.theme.fonts.main,
                        Text = default,
                        TextColor3 = self.theme.colors.text,
                        TextSize = self.theme.sizes.textSize,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = dropdownButton
                    })
                    
                    -- Create dropdown arrow
                    local dropdownArrow = Utility.Create("ImageLabel", {
                        Name = "Arrow",
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundTransparency = 1,
                        Position = UDim2.new(1, -5, 0.5, 0),
                        Size = UDim2.new(0, 16, 0, 16),
                        Image = "rbxassetid://6031091004",
                        ImageColor3 = self.theme.colors.text,
                        Parent = dropdownButton
                    })
                    
                    -- Create dropdown hitbox
                    local dropdownHitbox = Utility.Create("TextButton", {
                        Name = "Hitbox",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        Parent = dropdownButton
                    })
                    
                    -- Create dropdown list
                    local dropdownList = Utility.Create("Frame", {
                        Name = "List",
                        BackgroundColor3 = self.theme.colors.backgroundDark,
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, 0, 0, 45),
                        Size = UDim2.new(1, 0, 0, 0), -- Will be resized based on options
                        Visible = false,
                        ZIndex = 5,
                        Parent = dropdownContainer
                    })
                    
                    -- Create dropdown list corner
                    local dropdownListCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = dropdownList
                    })
                    
                    -- Create dropdown list stroke
                    local dropdownListStroke = Utility.Create("UIStroke", {
                        Color = self.theme.colors.accent,
                        Thickness = 1,
                        Transparency = 0.5,
                        Parent = dropdownList
                    })
                    
                    -- Create dropdown list layout
                    local dropdownListLayout = Utility.Create("UIListLayout", {
                        Padding = UDim.new(0, 2),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Parent = dropdownList
                    })
                    
                    -- Create dropdown list padding
                    local dropdownListPadding = Utility.Create("UIPadding", {
                        PaddingBottom = UDim.new(0, 2),
                        PaddingLeft = UDim.new(0, 2),
                        PaddingRight = UDim.new(0, 2),
                        PaddingTop = UDim.new(0, 2),
                        Parent = dropdownList
                    })
                    
                    -- Dropdown state
                    local open = false
                    local selected = default
                    
                    -- Dropdown value changed callback
                    local onChangedCallback = nil
                    
                    -- Update dropdown list size
                    local function updateDropdownListSize()
                        dropdownList.Size = UDim2.new(1, 0, 0, math.min(#options * 22, 100))
                        dropdownContainer.Size = UDim2.new(1, 0, 0, open and 45 + dropdownList.Size.Y.Offset or 40)
                    end
                    
                    -- Toggle dropdown
                    local function toggleDropdown()
                        open = not open
                        
                        updateDropdownListSize()
                        
                        -- Animate arrow
                        Utility.Tween(dropdownArrow, {Rotation = open and 180 or 0}, 0.2)
                        
                        -- Show/hide list
                        dropdownList.Visible = open
                    end
                    
                    -- Dropdown click
                    dropdownHitbox.MouseButton1Click:Connect(toggleDropdown)
                    
                    -- Create dropdown options
                    for i, option in ipairs(options) do
                        -- Create option button
                        local optionButton = Utility.Create("TextButton", {
                            Name = option .. "Option",
                            BackgroundColor3 = self.theme.colors.background,
                            BackgroundTransparency = 0.5,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 20),
                            Font = self.theme.fonts.main,
                            Text = option,
                            TextColor3 = self.theme.colors.text,
                            TextSize = self.theme.sizes.textSize,
                            ZIndex = 6,
                            Parent = dropdownList
                        })
                        
                        -- Create option button corner
                        local optionButtonCorner = Utility.Create("UICorner", {
                            CornerRadius = UDim.new(0, 4),
                            Parent = optionButton
                        })
                        
                        -- Option button hover effect
                        optionButton.MouseEnter:Connect(function()
                            Utility.Tween(optionButton, {BackgroundColor3 = self.theme.colors.accent}, 0.2)
                        end)
                        
                        optionButton.MouseLeave:Connect(function()
                            Utility.Tween(optionButton, {BackgroundColor3 = self.theme.colors.background}, 0.2)
                        end)
                        
                        -- Option button click
                        optionButton.MouseButton1Click:Connect(function()
                            selected = option
                            dropdownSelected.Text = selected
                            
                            toggleDropdown()
                            
                            if onChangedCallback then
                                onChangedCallback(selected)
                            end
                        end)
                    end
                    
                    -- Update dropdown list size
                    updateDropdownListSize()
                    
                    -- Create dropdown object
                    local dropdown = {
                        Name = dropdownName,
                        Container = dropdownContainer,
                        Value = selected,
                        SetValue = function(self, value)
                            -- Check if value is in options
                            for _, option in ipairs(options) do
                                if option == value then
                                    selected = value
                                    dropdownSelected.Text = selected
                                    
                                    if onChangedCallback then
                                        onChangedCallback(selected)
                                    end
                                    
                                    break
                                end
                            end
                        end,
                        GetValue = function(self)
                            return selected
                        end,
                        OnChanged = function(self, callback)
                            onChangedCallback = callback
                            return self
                        end,
                        Refresh = function(self, newOptions, newValue)
                            options = newOptions or options
                            
                            -- Clear existing options
                            for _, child in ipairs(dropdownList:GetChildren()) do
                                if child:IsA("TextButton") then
                                    child:Destroy()
                                end
                            end
                            
                            -- Create new options
                            for i, option in ipairs(options) do
                                -- Create option button
                                local optionButton = Utility.Create("TextButton", {
                                    Name = option .. "Option",
                                    BackgroundColor3 = self.theme.colors.background,
                                    BackgroundTransparency = 0.5,
                                    BorderSizePixel = 0,
                                    Size = UDim2.new(1, 0, 0, 20),
                                    Font = self.theme.fonts.main,
                                    Text = option,
                                    TextColor3 = self.theme.colors.text,
                                    TextSize = self.theme.sizes.textSize,
                                    ZIndex = 6,
                                    Parent = dropdownList
                                })
                                
                                -- Create option button corner
                                local optionButtonCorner = Utility.Create("UICorner", {
                                    CornerRadius = UDim.new(0, 4),
                                    Parent = optionButton
                                })
                                
                                -- Option button hover effect
                                optionButton.MouseEnter:Connect(function()
                                    Utility.Tween(optionButton, {BackgroundColor3 = self.theme.colors.accent}, 0.2)
                                end)
                                
                                optionButton.MouseLeave:Connect(function()
                                    Utility.Tween(optionButton, {BackgroundColor3 = self.theme.colors.background}, 0.2)
                                end)
                                
                                -- Option button click
                                optionButton.MouseButton1Click:Connect(function()
                                    selected = option
                                    dropdownSelected.Text = selected
                                    
                                    toggleDropdown()
                                    
                                    if onChangedCallback then
                                        onChangedCallback(selected)
                                    end
                                end)
                            end
                            
                            -- Update selected value
                            if newValue then
                                self:SetValue(newValue)
                            elseif not table.find(options, selected) and #options > 0 then
                                self:SetValue(options[1])
                            end
                            
                            -- Update dropdown list size
                            updateDropdownListSize()
                            
                            return self
                        end
                    }
                    
                    -- Add to section elements
                    table.insert(section.Elements, dropdown)
                    
                    return dropdown
                end
                
                -- Add button function
                function section.AddButton(buttonName, callback)
                    -- Create button container
                    local buttonContainer = Utility.Create("Frame", {
                        Name = buttonName .. "Container",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        Parent = sectionContent
                    })
                    
                    -- Create button
                    local button = Utility.Create("TextButton", {
                        Name = "Button",
                        BackgroundColor3 = self.theme.colors.accent,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 1, 0),
                        Font = self.theme.fonts.semi,
                        Text = buttonName,
                        TextColor3 = self.theme.colors.text,
                        TextSize = self.theme.sizes.textSize,
                        Parent = buttonContainer
                    })
                    
                    -- Create button corner
                    local buttonCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = button
                    })
                    
                    -- Button hover effect
                    button.MouseEnter:Connect(function()
                        Utility.Tween(button, {BackgroundColor3 = self.theme.colors.accentLight}, 0.2)
                    end)
                    
                    button.MouseLeave:Connect(function()
                        Utility.Tween(button, {BackgroundColor3 = self.theme.colors.accent}, 0.2)
                    end)
                    
                    -- Button click effect
                    button.MouseButton1Down:Connect(function()
                        Utility.Tween(button, {BackgroundColor3 = self.theme.colors.accentDark}, 0.1)
                    end)
                    
                    button.MouseButton1Up:Connect(function()
                        Utility.Tween(button, {BackgroundColor3 = self.theme.colors.accentLight}, 0.1)
                    end)
                    
                    -- Button click
                    button.MouseButton1Click:Connect(function()
                        -- Create ripple effect
                        local ripplePosition = Vector2.new(MOUSE.X, MOUSE.Y) - button.AbsolutePosition
                        Utility.CreateRipple(button, ripplePosition, Color3.fromRGB(255, 255, 255))
                        
                        -- Call callback
                        if callback then
                            callback()
                        end
                    end)
                    
                    -- Create button object
                    local buttonObj = {
                        Name = buttonName,
                        Container = buttonContainer,
                        Button = button,
                        SetCallback = function(self, newCallback)
                            callback = newCallback
                            return self
                        end
                    }
                    
                    -- Add to section elements
                    table.insert(section.Elements, buttonObj)
                    
                    return buttonObj
                end
                
                -- Add keybind function
                function section.AddKeybind(keybindName, defaultKey)
                    defaultKey = defaultKey or "NONE"
                    
                    -- Create keybind container
                    local keybindContainer = Utility.Create("Frame", {
                        Name = keybindName .. "Container",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        Parent = sectionContent
                    })
                    
                    -- Create keybind label
                    local keybindLabel = Utility.Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 0),
                        Size = UDim2.new(0.6, 0, 1, 0),
                        Font = self.theme.fonts.main,
                        Text = keybindName,
                        TextColor3 = self.theme.colors.text,
                        TextSize = self.theme.sizes.textSize,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = keybindContainer
                    })
                    
                    -- Create keybind button
                    local keybindButton = Utility.Create("TextButton", {
                        Name = "Button",
                        AnchorPoint = Vector2.new(1, 0),
                        BackgroundColor3 = self.theme.colors.backgroundDark,
                        BorderSizePixel = 0,
                        Position = UDim2.new(1, 0, 0, 0),
                        Size = UDim2.new(0.35, 0, 1, 0),
                        Font = self.theme.fonts.main,
                        Text = defaultKey,
                        TextColor3 = self.theme.colors.text,
                        TextSize = self.theme.sizes.textSize,
                        Parent = keybindContainer
                    })
                    
                    -- Create keybind button corner
                    local keybindButtonCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = keybindButton
                    })
                    
                    -- Create keybind button stroke
                    local keybindButtonStroke = Utility.Create("UIStroke", {
                        Color = self.theme.colors.accent,
                        Thickness = 1,
                        Transparency = 0.5,
                        Parent = keybindButton
                    })
                    
                    -- Keybind state
                    local listening = false
                    local key = defaultKey
                    
                    -- Keybind value changed callback
                    local onChangedCallback = nil
                    
                    -- Update keybind visual
                    local function updateKeybind()
                        keybindButton.Text = listening and "..." or key
                        
                        if onChangedCallback and not listening then
                            onChangedCallback(key)
                        end
                    end
                    
                    -- Keybind button hover effect
                    keybindButton.MouseEnter:Connect(function()
                        Utility.Tween(keybindButton, {BackgroundColor3 = self.theme.colors.background}, 0.2)
                    end)
                    
                    keybindButton.MouseLeave:Connect(function()
                        Utility.Tween(keybindButton, {BackgroundColor3 = self.theme.colors.backgroundDark}, 0.2)
                    end)
                    
                    -- Keybind button click
                    keybindButton.MouseButton1Click:Connect(function()
                        listening = true
                        updateKeybind()
                    end)
                    
                    -- Keybind input
                    UserInputService.InputBegan:Connect(function(input, gameProcessed)
                        if listening and not gameProcessed then
                            listening = false
                            
                            if input.UserInputType == Enum.UserInputType.Keyboard then
                                key = input.KeyCode.Name
                            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                                key = "MOUSE1"
                            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                                key = "MOUSE2"
                            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                                key = "MOUSE3"
                            else
                                key = "NONE"
                            end
                            
                            updateKeybind()
                        end
                    end)
                    
                    -- Create keybind object
                    local keybind = {
                        Name = keybindName,
                        Container = keybindContainer,
                        Value = key,
                        SetValue = function(self, value)
                            key = value
                            updateKeybind()
                        end,
                        GetValue = function(self)
                            return key
                        end,
                        OnChanged = function(self, callback)
                            onChangedCallback = callback
                            return self
                        end
                    }
                    
                    -- Add to section elements
                    table.insert(section.Elements, keybind)
                    
                    return keybind
                end
                
                -- Add color picker function
                function section.AddColorPicker(colorPickerName, defaultColor)
                    defaultColor = defaultColor or Color3.fromRGB(255, 255, 255)
                    
                    -- Create color picker container
                    local colorPickerContainer = Utility.Create("Frame", {
                        Name = colorPickerName .. "Container",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 30),
                        Parent = sectionContent
                    })
                    
                    -- Create color picker label
                    local colorPickerLabel = Utility.Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 0, 0, 0),
                        Size = UDim2.new(0.6, 0, 1, 0),
                        Font = self.theme.fonts.main,
                        Text = colorPickerName,
                        TextColor3 = self.theme.colors.text,
                        TextSize = self.theme.sizes.textSize,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent = colorPickerContainer
                    })
                    
                    -- Create color picker preview
                    local colorPickerPreview = Utility.Create("Frame", {
                        Name = "Preview",
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = defaultColor,
                        BorderSizePixel = 0,
                        Position = UDim2.new(1, 0, 0.5, 0),
                        Size = UDim2.new(0, 30, 0, 20),
                        Parent = colorPickerContainer
                    })
                    
                    -- Create color picker preview corner
                    local colorPickerPreviewCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = colorPickerPreview
                    })
                    
                    -- Create color picker preview stroke
                    local colorPickerPreviewStroke = Utility.Create("UIStroke", {
                        Color = self.theme.colors.accent,
                        Thickness = 1,
                        Transparency = 0.5,
                        Parent = colorPickerPreview
                    })
                    
                    -- Create color picker button
                    local colorPickerButton = Utility.Create("TextButton", {
                        Name = "Button",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        Parent = colorPickerPreview
                    })
                    
                    -- Create color picker frame
                    local colorPickerFrame = Utility.Create("Frame", {
                        Name = "ColorPickerFrame",
                        AnchorPoint = Vector2.new(1, 0),
                        BackgroundColor3 = self.theme.colors.backgroundLight,
                        BackgroundTransparency = self.theme.transparency.background,
                        BorderSizePixel = 0,
                        Position = UDim2.new(1, 0, 1, 5),
                        Size = UDim2.new(0, 200, 0, 200),
                        Visible = false,
                        ZIndex = 10,
                        Parent = colorPickerContainer
                    })
                    
                    -- Create color picker frame corner
                    local colorPickerFrameCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = colorPickerFrame
                    })
                    
                    -- Create color picker frame stroke
                    local colorPickerFrameStroke = Utility.Create("UIStroke", {
                        Color = self.theme.colors.accent,
                        Thickness = 1,
                        Parent = colorPickerFrame
                    })
                    
                    -- Create color picker hue
                    local colorPickerHue = Utility.Create("ImageLabel", {
                        Name = "Hue",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0, 10),
                        Size = UDim2.new(1, -20, 0, 20),
                        Image = "rbxassetid://6523286724",
                        ZIndex = 11,
                        Parent = colorPickerFrame
                    })
                    
                    -- Create color picker hue corner
                    local colorPickerHueCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = colorPickerHue
                    })
                    
                    -- Create color picker hue slider
                    local colorPickerHueSlider = Utility.Create("Frame", {
                        Name = "Slider",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BorderSizePixel = 0,
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.new(0, 5, 1, 0),
                        ZIndex = 12,
                        Parent = colorPickerHue
                    })
                    
                    -- Create color picker hue slider corner
                    local colorPickerHueSliderCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(1, 0),
                        Parent = colorPickerHueSlider
                    })
                    
                    -- Create color picker hue hitbox
                    local colorPickerHueHitbox = Utility.Create("TextButton", {
                        Name = "Hitbox",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        ZIndex = 13,
                        Parent = colorPickerHue
                    })
                    
                    -- Create color picker saturation
                    local colorPickerSaturation = Utility.Create("ImageLabel", {
                        Name = "Saturation",
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0, 40),
                        Size = UDim2.new(1, -20, 1, -80),
                        Image = "rbxassetid://6523291212",
                        ZIndex = 11,
                        Parent = colorPickerFrame
                    })
                    
                    -- Create color picker saturation corner
                    local colorPickerSaturationCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = colorPickerSaturation
                    })
                    
                    -- Create color picker saturation slider
                    local colorPickerSaturationSlider = Utility.Create("Frame", {
                        Name = "Slider",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BorderSizePixel = 0,
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        Size = UDim2.new(0, 10, 0, 10),
                        ZIndex = 12,
                        Parent = colorPickerSaturation
                    })
                    
                    -- Create color picker saturation slider corner
                    local colorPickerSaturationSliderCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(1, 0),
                        Parent = colorPickerSaturationSlider
                    })
                    
                    -- Create color picker saturation hitbox
                    local colorPickerSaturationHitbox = Utility.Create("TextButton", {
                        Name = "Hitbox",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        Text = "",
                        ZIndex = 13,
                        Parent = colorPickerSaturation
                    })
                    
                    -- Create color picker confirm button
                    local colorPickerConfirmButton = Utility.Create("TextButton", {
                        Name = "ConfirmButton",
                        BackgroundColor3 = self.theme.colors.accent,
                        BorderSizePixel = 0,
                        Position = UDim2.new(0, 10, 1, -30),
                        Size = UDim2.new(1, -20, 0, 20),
                        Font = self.theme.fonts.semi,
                        Text = "Confirm",
                        TextColor3 = self.theme.colors.text,
                        TextSize = self.theme.sizes.textSize,
                        ZIndex = 11,
                        Parent = colorPickerFrame
                    })
                    
                    -- Create color picker confirm button corner
                    local colorPickerConfirmButtonCorner = Utility.Create("UICorner", {
                        CornerRadius = UDim.new(0, 4),
                        Parent = colorPickerConfirmButton
                    })
                    
                    -- Color picker state
                    local open = false
                    local hue, saturation, value = 0, 0, 1
                    local color = defaultColor
                    
                    -- Color picker value changed callback
                    local onChangedCallback = nil
                    
                    -- Convert RGB to HSV
                    local function rgbToHsv(rgb)
                        local r, g, b = rgb.R, rgb.G, rgb.B
                        local max, min = math.max(r, g, b), math.min(r, g, b)
                        local h, s, v
                        
                        v = max
                        
                        local d = max - min
                        if max == 0 then
                            s = 0
                        else
                            s = d / max
                        end
                        
                        if max == min then
                            h = 0
                        else
                            if max == r then
                                h = (g - b) / d
                                if g < b then
                                    h = h + 6
                                end
                            elseif max == g then
                                h = (b - r) / d + 2
                            elseif max == b then
                                h = (r - g) / d + 4
                            end
                            h = h / 6
                        end
                        
                        return h, s, v
                    end
                    
                    -- Convert HSV to RGB
                    local function hsvToRgb(h, s, v)
                        local r, g, b
                        
                        local i = math.floor(h * 6)
                        local f = h * 6 - i
                        local p = v * (1 - s)
                        local q = v * (1 - f * s)
                        local t = v * (1 - (1 - f) * s)
                        
                        i = i % 6
                        
                        if i == 0 then
                            r, g, b = v, t, p
                        elseif i == 1 then
                            r, g, b = q, v, p
                        elseif i == 2 then
                            r, g, b = p, v, t
                        elseif i == 3 then
                            r, g, b = p, q, v
                        elseif i == 4 then
                            r, g, b = t, p, v
                        elseif i == 5 then
                            r, g, b = v, p, q
                        end
                        
                        return Color3.new(r, g, b)
                    end
                    
                    -- Update color picker
                    local function updateColorPicker()
                        -- Update color
                        color = hsvToRgb(hue, saturation, value)
                        
                        -- Update preview
                        colorPickerPreview.BackgroundColor3 = color
                        
                        -- Update saturation
                        colorPickerSaturation.ImageColor3 = hsvToRgb(hue, 1, 1)
                        
                        -- Update sliders
                        colorPickerHueSlider.Position = UDim2.new(hue, 0, 0.5, 0)
                        colorPickerSaturationSlider.Position = UDim2.new(saturation, 0, 1 - value, 0)
                        
                        if onChangedCallback and not open then
                            onChangedCallback(color)
                        end
                    end
                    
                    -- Initialize color picker
                    hue, saturation, value = rgbToHsv(defaultColor)
                    updateColorPicker()
                    
                    -- Toggle color picker
                    local function toggleColorPicker()
                        open = not open
                        colorPickerFrame.Visible = open
                    end
                    
                    -- Color picker button click
                    colorPickerButton.MouseButton1Click:Connect(toggleColorPicker)
                    
                    -- Color picker hue drag
                    local hueDragging = false
                    
                    colorPickerHueHitbox.MouseButton1Down:Connect(function()
                        hueDragging = true
                        
                        -- Calculate hue from mouse position
                        local percent = math.clamp((MOUSE.X - colorPickerHue.AbsolutePosition.X) / colorPickerHue.AbsoluteSize.X, 0, 1)
                        hue = percent
                        
                        updateColorPicker()
                    end)
                    
                    -- Color picker saturation drag
                    local saturationDragging = false
                    
                    colorPickerSaturationHitbox.MouseButton1Down:Connect(function()
                        saturationDragging = true
                        
                        -- Calculate saturation and value from mouse position
                        local percentX = math.clamp((MOUSE.X - colorPickerSaturation.AbsolutePosition.X) / colorPickerSaturation.AbsoluteSize.X, 0, 1)
                        local percentY = math.clamp((MOUSE.Y - colorPickerSaturation.AbsolutePosition.Y) / colorPickerSaturation.AbsoluteSize.Y, 0, 1)
                        
                        saturation = percentX
                        value = 1 - percentY
                        
                        updateColorPicker()
                    end)
                    
                    -- Mouse movement
                    UserInputService.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                            if hueDragging then
                                -- Calculate hue from mouse position
                                local percent = math.clamp((MOUSE.X - colorPickerHue.AbsolutePosition.X) / colorPickerHue.AbsoluteSize.X, 0, 1)
                                hue = percent
                                
                                updateColorPicker()
                            elseif saturationDragging then
                                -- Calculate saturation and value from mouse position
                                local percentX = math.clamp((MOUSE.X - colorPickerSaturation.AbsolutePosition.X) / colorPickerSaturation.AbsoluteSize.X, 0, 1)
                                local percentY = math.clamp((MOUSE.Y - colorPickerSaturation.AbsolutePosition.Y) / colorPickerSaturation.AbsoluteSize.Y, 0, 1)
                                
                                saturation = percentX
                                value = 1 - percentY
                                
                                updateColorPicker()
                            end
                        end
                    end)
                    
                    -- Mouse up
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            hueDragging = false
                            saturationDragging = false
                        end
                    end)
                    
                    -- Confirm button click
                    colorPickerConfirmButton.MouseButton1Click:Connect(function()
                        toggleColorPicker()
                        
                        if onChangedCallback then
                            onChangedCallback(color)
                        end
                    end)
                    
                    -- Create color picker object
                    local colorPicker = {
                        Name = colorPickerName,
                        Container = colorPickerContainer,
                        Value = color,
                        SetValue = function(self, newColor)
                            color = newColor
                            hue, saturation, value = rgbToHsv(color)
                            updateColorPicker()
                        end,
                        GetValue = function(self)
                            return color
                        end,
                        OnChanged = function(self, callback)
                            onChangedCallback = callback
                            return self
                        end
                    }
                    
                    -- Add to section elements
                    table.insert(section.Elements, colorPicker)
                    
                    return colorPicker
                end
                
                -- Add to tab sections
                table.insert(tab.Sections, section)
                
                return section
            end
            
            -- Tab button click
            tabButton.MouseButton1Click:Connect(function()
                -- Set active tab
                if window.TabSystem.ActiveTab ~= tab then
                    -- Hide active tab
                    if window.TabSystem.ActiveTab then
                        -- Animate tab button
                        Utility.Tween(window.TabSystem.ActiveTab.Button, {BackgroundTransparency = self.theme.transparency.background}, 0.2)
                        Utility.Tween(window.TabSystem.ActiveTab.Button:FindFirstChild("Accent"), {BackgroundTransparency = 1}, 0.2)
                        Utility.Tween(window.TabSystem.ActiveTab.Button:FindFirstChild("Label"), {TextColor3 = self.theme.colors.textDark}, 0.2)
                        
                        if window.TabSystem.ActiveTab.Button:FindFirstChild("Icon") then
                            Utility.Tween(window.TabSystem.ActiveTab.Button:FindFirstChild("Icon"), {ImageColor3 = self.theme.colors.textDark}, 0.2)
                        end
                        
                        -- Hide tab content
                        window.TabSystem.ActiveTab.Content.Visible = false
                    end
                    
                    -- Set active tab
                    window.TabSystem.ActiveTab = tab
                    
                    -- Animate tab button
                    Utility.Tween(tab.Button, {BackgroundTransparency = self.theme.transparency.element}, 0.2)
                    Utility.Tween(tab.Button:FindFirstChild("Accent"), {BackgroundTransparency = 0}, 0.2)
                    Utility.Tween(tab.Button:FindFirstChild("Label"), {TextColor3 = self.theme.colors.text}, 0.2)
                    
                    if tab.Button:FindFirstChild("Icon") then
                        Utility.Tween(tab.Button:FindFirstChild("Icon"), {ImageColor3 = self.theme.colors.text}, 0.2)
                    end
                    
                    -- Show tab content
                    tab.Content.Visible = true
                end
            end)
            
            -- Add to tab system
            table.insert(window.TabSystem.Tabs, tab)
            
            -- Update tab buttons container canvas size
            tabButtonsContainer.CanvasSize = UDim2.new(0, 0, 0, tabButtonsLayout.AbsoluteContentSize.Y)
            
            -- Set active tab if first tab
            if #window.TabSystem.Tabs == 1 then
                -- Set active tab
                window.TabSystem.ActiveTab = tab
                
                -- Animate tab button
                Utility.Tween(tab.Button, {BackgroundTransparency = self.theme.transparency.element}, 0.2)
                Utility.Tween(tab.Button:FindFirstChild("Accent"), {BackgroundTransparency = 0}, 0.2)
                Utility.Tween(tab.Button:FindFirstChild("Label"), {TextColor3 = self.theme.colors.text}, 0.2)
                
                if tab.Button:FindFirstChild("Icon") then
                    Utility.Tween(tab.Button:FindFirstChild("Icon"), {ImageColor3 = self.theme.colors.text}, 0.2)
                end
                
                -- Show tab content
                tab.Content.Visible = true
            end
            
            return tab
        end
        
        return window.TabSystem
    end
    
    return window
end

-- Create a watermark
function NeverloseUI:CreateWatermark(text, position)
    position = position or UDim2.new(0, 10, 0, 10)
    
    -- Create watermark frame
    local watermarkFrame = Utility.Create("Frame", {
        Name = "Watermark",
        BackgroundColor3 = self.theme.colors.backgroundLight,
        BackgroundTransparency = self.theme.transparency.background,
        BorderSizePixel = 0,
        Position = position,
        Size = UDim2.new(0, 200, 0, 30),
        Parent = self.overlayContainer
    })
    
    -- Create watermark corner
    local watermarkCorner = Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
        Parent = watermarkFrame
    })
    
    -- Create watermark stroke
    local watermarkStroke = Utility.Create("UIStroke", {
        Color = self.theme.colors.accent,
        Thickness = self.theme.sizes.borderSize,
        Parent = watermarkFrame
    })
    
    -- Create watermark text
    local watermarkText = Utility.Create("TextLabel", {
        Name = "Text",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = self.theme.fonts.semi,
        Text = text,
        TextColor3 = self.theme.colors.text,
        TextSize = self.theme.sizes.textSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = watermarkFrame
    })
    
    -- Make watermark draggable
    Utility.MakeDraggable(watermarkFrame, watermarkFrame)
    
    -- Store in overlays
    self.overlays.watermark = {
        Frame = watermarkFrame,
        Text = watermarkText,
        SetText = function(self, newText)
            watermarkText.Text = newText
        end,
        SetPosition = function(self, newPosition)
            watermarkFrame.Position = newPosition
        end,
        SetVisible = function(self, visible)
            watermarkFrame.Visible = visible
        end
    }
    
    return self.overlays.watermark
end

-- Create a spectator list
function NeverloseUI:CreateSpectatorList(position)
    position = position or UDim2.new(1, -210, 0, 10)
    
    -- Create spectator list frame
    local spectatorListFrame = Utility.Create("Frame", {
        Name = "SpectatorList",
        BackgroundColor3 = self.theme.colors.backgroundLight,
        BackgroundTransparency = self.theme.transparency.background,
        BorderSizePixel = 0,
        Position = position,
        Size = UDim2.new(0, 200, 0, 30),
        Parent = self.overlayContainer
    })
    
    -- Create spectator list corner
    local spectatorListCorner = Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
        Parent = spectatorListFrame
    })
    
    -- Create spectator list stroke
    local spectatorListStroke = Utility.Create("UIStroke", {
        Color = self.theme.colors.accent,
        Thickness = self.theme.sizes.borderSize,
        Parent = spectatorListFrame
    })
    
    -- Create spectator list title
    local spectatorListTitle = Utility.Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 0, 30),
        Font = self.theme.fonts.semi,
        Text = "Spectators",
        TextColor3 = self.theme.colors.text,
        TextSize = self.theme.sizes.textSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = spectatorListFrame
    })
    
    -- Create spectator list container
    local spectatorListContainer = Utility.Create("Frame", {
        Name = "Container",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 0, 0),
        Parent = spectatorListFrame
    })
    
    -- Create spectator list layout
    local spectatorListLayout = Utility.Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = spectatorListContainer
    })
    
    -- Create spectator list padding
    local spectatorListPadding = Utility.Create("UIPadding", {
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 0),
        Parent = spectatorListContainer
    })
    
    -- Update spectator list size
    local function updateSpectatorListSize()
        spectatorListContainer.Size = UDim2.new(1, 0, 0, spectatorListLayout.AbsoluteContentSize.Y)
        spectatorListFrame.Size = UDim2.new(0, 200, 0, 30 + spectatorListContainer.Size.Y.Offset)
    end
    
    -- Update spectator list when children change
    spectatorListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSpectatorListSize)
    
    -- Make spectator list draggable
    Utility.MakeDraggable(spectatorListFrame, spectatorListFrame)
    
    -- Store in overlays
    self.overlays.spectatorList = {
        Frame = spectatorListFrame,
        Container = spectatorListContainer,
        UpdateSpectators = function(self, spectators)
            -- Clear existing spectators
            for _, child in ipairs(spectatorListContainer:GetChildren()) do
                if child:IsA("TextLabel") then
                    child:Destroy()
                end
            end
            
            -- Add new spectators
            for i, spectator in ipairs(spectators) do
                local spectatorLabel = Utility.Create("TextLabel", {
                    Name = "Spectator",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Font = self.theme.fonts.main,
                    Text = spectator,
                    TextColor3 = self.theme.colors.text,
                    TextSize = self.theme.sizes.textSize,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = spectatorListContainer
                })
            end
            
            -- Update size
            updateSpectatorListSize()
        end,
        SetPosition = function(self, newPosition)
            spectatorListFrame.Position = newPosition
        end,
        SetVisible = function(self, visible)
            spectatorListFrame.Visible = visible
        end
    }
    
    return self.overlays.spectatorList
end

-- Create a keybinds list
function NeverloseUI:CreateKeybindsList(position)
    position = position or UDim2.new(0, 10, 1, -40)
    
    -- Create keybinds list frame
    local keybindsListFrame = Utility.Create("Frame", {
        Name = "KeybindsList",
        BackgroundColor3 = self.theme.colors.backgroundLight,
        BackgroundTransparency = self.theme.transparency.background,
        BorderSizePixel = 0,
        Position = position,
        Size = UDim2.new(0, 200, 0, 30),
        Parent = self.overlayContainer
    })
    
    -- Create keybinds list corner
    local keybindsListCorner = Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
        Parent = keybindsListFrame
    })
    
    -- Create keybinds list stroke
    local keybindsListStroke = Utility.Create("UIStroke", {
        Color = self.theme.colors.accent,
        Thickness = self.theme.sizes.borderSize,
        Parent = keybindsListFrame
    })
    
    -- Create keybinds list title
    local keybindsListTitle = Utility.Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 0, 30),
        Font = self.theme.fonts.semi,
        Text = "Keybinds",
        TextColor3 = self.theme.colors.text,
        TextSize = self.theme.sizes.textSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = keybindsListFrame
    })
    
    -- Create keybinds list container
    local keybindsListContainer = Utility.Create("Frame", {
        Name = "Container",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 0, 0),
        Parent = keybindsListFrame
    })
    
    -- Create keybinds list layout
    local keybindsListLayout = Utility.Create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = keybindsListContainer
    })
    
    -- Create keybinds list padding
    local keybindsListPadding = Utility.Create("UIPadding", {
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 0),
        Parent = keybindsListContainer
    })
    
    -- Update keybinds list size
    local function updateKeybindsListSize()
        keybindsListContainer.Size = UDim2.new(1, 0, 0, keybindsListLayout.AbsoluteContentSize.Y)
        keybindsListFrame.Size = UDim2.new(0, 200, 0, 30 + keybindsListContainer.Size.Y.Offset)
    end
    
    -- Update keybinds list when children change
    keybindsListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateKeybindsListSize)
    
    -- Make keybinds list draggable
    Utility.MakeDraggable(keybindsListFrame, keybindsListFrame)
    
    -- Store in overlays
    self.overlays.keybindsList = {
        Frame = keybindsListFrame,
        Container = keybindsListContainer,
        UpdateKeybinds = function(self, keybinds)
            -- Clear existing keybinds
            for _, child in ipairs(keybindsListContainer:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            
            -- Add new keybinds
            for i, keybind in ipairs(keybinds) do
                local keybindContainer = Utility.Create("Frame", {
                    Name = "Keybind",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Parent = keybindsListContainer
                })
                
                local keybindName = Utility.Create("TextLabel", {
                    Name = "Name",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.5, 0, 1, 0),
                    Font = self.theme.fonts.main,
                    Text = keybind.name,
                    TextColor3 = self.theme.colors.text,
                    TextSize = self.theme.sizes.textSize,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = keybindContainer
                })
                
                local keybindKey = Utility.Create("TextLabel", {
                    Name = "Key",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, 0, 0, 0),
                    Size = UDim2.new(0.3, 0, 1, 0),
                    Font = self.theme.fonts.main,
                    Text = keybind.key,
                    TextColor3 = self.theme.colors.accent,
                    TextSize = self.theme.sizes.textSize,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = keybindContainer
                })
                
                local keybindStatus = Utility.Create("TextLabel", {
                    Name = "Status",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.8, 0, 0, 0),
                    Size = UDim2.new(0.2, 0, 1, 0),
                    Font = self.theme.fonts.main,
                    Text = keybind.active and "ON" or "OFF",
                    TextColor3 = keybind.active and self.theme.colors.success or self.theme.colors.error,
                    TextSize = self.theme.sizes.textSize,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = keybindContainer
                })
            end
            
            -- Update size
            updateKeybindsListSize()
        end,
        SetPosition = function(self, newPosition)
            keybindsListFrame.Position = newPosition
        end,
        SetVisible = function(self, visible)
            keybindsListFrame.Visible = visible
        end
    }
    
    return self.overlays.keybindsList
end

-- Create a radar
function NeverloseUI:CreateRadar(position)
    position = position or UDim2.new(1, -210, 1, -210)
    
    -- Create radar frame
    local radarFrame = Utility.Create("Frame", {
        Name = "Radar",
        BackgroundColor3 = self.theme.colors.backgroundLight,
        BackgroundTransparency = self.theme.transparency.background,
        BorderSizePixel = 0,
        Position = position,
        Size = UDim2.new(0, 200, 0, 200),
        Parent = self.overlayContainer
    })
    
    -- Create radar corner
    local radarCorner = Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
        Parent = radarFrame
    })
    
    -- Create radar stroke
    local radarStroke = Utility.Create("UIStroke", {
        Color = self.theme.colors.accent,
        Thickness = self.theme.sizes.borderSize,
        Parent = radarFrame
    })
    
    -- Create radar title
    local radarTitle = Utility.Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 0, 30),
        Font = self.theme.fonts.semi,
        Text = "Radar",
        TextColor3 = self.theme.colors.text,
        TextSize = self.theme.sizes.textSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = radarFrame
    })
    
    -- Create radar content
    local radarContent = Utility.Create("Frame", {
        Name = "Content",
        BackgroundColor3 = self.theme.colors.backgroundDark,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 30),
        Size = UDim2.new(1, -20, 1, -40),
        Parent = radarFrame
    })
    
    -- Create radar content corner
    local radarContentCorner = Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, self.theme.sizes.cornerRadius),
        Parent = radarContent
    })
    
    -- Create radar center
    local radarCenter = Utility.Create("Frame", {
        Name = "Center",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.theme.colors.text,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 4, 0, 4),
        ZIndex = 2,
        Parent = radarContent
    })
    
    -- Create radar center corner
    local radarCenterCorner = Utility.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = radarCenter
    })
    
    -- Create radar grid
    local radarGrid = Utility.Create("Frame", {
        Name = "Grid",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Parent = radarContent
    })
    
    -- Create radar grid horizontal line
    local radarGridHorizontal = Utility.Create("Frame", {
        Name = "Horizontal",
        BackgroundColor3 = self.theme.colors.text,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = radarGrid
    })
    
    -- Create radar grid vertical line
    local radarGridVertical = Utility.Create("Frame", {
        Name = "Vertical",
        BackgroundColor3 = self.theme.colors.text,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        Parent = radarGrid
    })
    
    -- Make radar draggable
    Utility.MakeDraggable(radarFrame, radarFrame)
    
    -- Store in overlays
    self.overlays.radar = {
        Frame = radarFrame,
        Content = radarContent,
        Players = {},
        UpdatePlayers = function(self, players)
            -- Clear existing players
            for _, player in ipairs(self.Players) do
                player:Destroy()
            end
            
            self.Players = {}
            
            -- Add new players
            for i, player in ipairs(players) do
                local playerDot = Utility.Create("Frame", {
                    Name = "Player",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = player.isEnemy and self.theme.colors.error or self.theme.colors.success,
                    BorderSizePixel = 0,
                    Position = UDim2.new(player.x, 0, player.y, 0),
                    Size = UDim2.new(0, 6, 0, 6),
                    ZIndex = 2,
                    Parent = radarContent
                })
                
                local playerDotCorner = Utility.Create("UICorner", {
                    CornerRadius = UDim.new(1, 0),
                    Parent = playerDot
                })
                
                table.insert(self.Players, playerDot)
            end
        end,
        SetPosition = function(self, newPosition)
            radarFrame.Position = newPosition
        end,
        SetVisible = function(self, visible)
            radarFrame.Visible = visible
        end
    }
    
    return self.overlays.radar
end

-- Create a complete UI with all components
function NeverloseUI:CreateCompleteUI()
    -- Create main window
    local mainWindow = self:CreateWindow("Neverlose", UDim2.new(0, 600, 0, 400))
    
    -- Create tab system
    local tabSystem = mainWindow.AddTabSystem()
    
    -- Create tabs
    local rageTab = tabSystem.AddTab("rage")
    local legitTab = tabSystem.AddTab("legit")
    local visualsTab = tabSystem.AddTab("visuals")
    local miscTab = tabSystem.AddTab("misc")
    local configTab = tabSystem.AddTab("config")
    
    -- Populate Rage tab
    local rageGeneralSection = rageTab.AddSection("general")
    rageGeneralSection.AddCheckbox("enabled", true)
    rageGeneralSection.AddCheckbox("silent aim", true)
    rageGeneralSection.AddCheckbox("auto wall", false)
    rageGeneralSection.AddSlider("fov", 0, 180, 30)
    rageGeneralSection.AddDropdown("priority", {"closest", "lowest hp", "visible"}, "closest")
    rageGeneralSection.AddKeybind("toggle key", "X")
    
    local rageAccuracySection = rageTab.AddSection("accuracy")
    rageAccuracySection.AddSlider("hitchance", 0, 100, 85)
    rageAccuracySection.AddSlider("minimum damage", 0, 100, 25)
    rageAccuracySection.AddCheckbox("automatic fire", true)
    rageAccuracySection.AddCheckbox("automatic scope", true)
    
    local rageTargetSection = rageTab.AddSection("target selection")
    rageTargetSection.AddCheckbox("head", true)
    rageTargetSection.AddCheckbox("chest", true)
    rageTargetSection.AddCheckbox("stomach", false)
    rageTargetSection.AddCheckbox("arms", false)
    rageTargetSection.AddCheckbox("legs", false)
    rageTargetSection.AddSlider("multipoint", 0, 100, 75)
    
    -- Populate Legit tab
    local legitAimbotSection = legitTab.AddSection("aimbot")
    legitAimbotSection.AddCheckbox("enabled", true)
    legitAimbotSection.AddSlider("fov", 0, 30, 5)
    legitAimbotSection.AddSlider("smooth", 1, 20, 8)
    legitAimbotSection.AddSlider("rcs x", 0, 100, 80)
    legitAimbotSection.AddSlider("rcs y", 0, 100, 80)
    legitAimbotSection.AddKeybind("aim key", "MOUSE2")
    
    local legitTriggerbotSection = legitTab.AddSection("triggerbot")
    legitTriggerbotSection.AddCheckbox("enabled", false)
    legitTriggerbotSection.AddSlider("delay", 0, 500, 50)
    legitTriggerbotSection.AddKeybind("trigger key", "MOUSE5")
    
    -- Populate Visuals tab
    local visualsEspSection = visualsTab.AddSection("esp")
    visualsEspSection.AddCheckbox("enabled", true)
    visualsEspSection.AddCheckbox("box", true)
    visualsEspSection.AddCheckbox("name", true)
    visualsEspSection.AddCheckbox("health", true)
    visualsEspSection.AddCheckbox("weapon", false)
    visualsEspSection.AddCheckbox("skeleton", false)
    visualsEspSection.AddSlider("max distance", 0, 5000, 1500)
    visualsEspSection.AddColorPicker("enemy color", Color3.fromRGB(255, 50, 50))
    visualsEspSection.AddColorPicker("team color", Color3.fromRGB(50, 255, 50))
    
    local visualsWorldSection = visualsTab.AddSection("world")
    visualsWorldSection.AddCheckbox("night mode", false)
    visualsWorldSection.AddCheckbox("fullbright", false)
    visualsWorldSection.AddSlider("viewmodel fov", 60, 120, 90)
    visualsWorldSection.AddCheckbox("no fog", false)
    visualsWorldSection.AddCheckbox("no shadows", false)
    
    local visualsOverlaysSection = visualsTab.AddSection("overlays")
    
    local radarEnabled = visualsOverlaysSection.AddCheckbox("radar", true)
    local spectatorListEnabled = visualsOverlaysSection.AddCheckbox("spectator list", true)
    local keybindsListEnabled = visualsOverlaysSection.AddCheckbox("keybinds list", true)
    local watermarkEnabled = visualsOverlaysSection.AddCheckbox("watermark", true)
    
    -- Populate Misc tab
    local miscMovementSection = miscTab.AddSection("movement")
    miscMovementSection.AddCheckbox("bunny hop", false)
    miscMovementSection.AddCheckbox("auto strafe", false)
    miscMovementSection.AddCheckbox("edge jump", false)
    miscMovementSection.AddSlider("strafe speed", 0, 100, 85)
    
    local miscOtherSection = miscTab.AddSection("other")
    miscOtherSection.AddCheckbox("auto accept", true)
    miscOtherSection.AddCheckbox("reveal ranks", true)
    miscOtherSection.AddCheckbox("clan tag", false)
    miscOtherSection.AddKeybind("menu key", "INSERT")
    
    -- Populate Config tab
    local configSection = configTab.AddSection("config")
    
    local configSlot = configSection.AddDropdown("config slot", {"slot 1", "slot 2", "slot 3", "slot 4", "slot 5"}, "slot 1")
    
    local saveConfigButton = configSection.AddButton("save config", function()
        self:CreateNotification("Config Saved", "Your configuration has been saved", "success", 3)
    end)
    
    local loadConfigButton = configSection.AddButton("load config", function()
        self:CreateNotification("Config Loaded", "Your configuration has been loaded", "info", 3)
    end)
    
    local resetConfigButton = configSection.AddButton("reset to default", function()
        self:CreateNotification("Config Reset", "Your configuration has been reset to default", "warning", 3)
    end)
    
    local configImportExportSection = configTab.AddSection("import/export")
    
    local exportConfigButton = configImportExportSection.AddButton("export to clipboard", function()
        self:CreateNotification("Config Exported", "Your configuration has been copied to clipboard", "info", 3)
    end)
    
    local importConfigButton = configImportExportSection.AddButton("import from clipboard", function()
        self:CreateNotification("Config Imported", "Your configuration has been imported from clipboard", "success", 3)
    end)
    
    -- Create overlays
    local watermark = self:CreateWatermark("neverlose | v1.0")
    
    local spectatorList = self:CreateSpectatorList()
    spectatorList.UpdateSpectators({"Player1", "Player2"})
    
    local keybindsList = self:CreateKeybindsList()
    keybindsList.UpdateKeybinds({
        {name = "aimbot", key = "MOUSE2", active = true},
        {name = "triggerbot", key = "MOUSE5", active = false},
        {name = "auto wall", key = "C", active = true},
        {name = "bunny hop", key = "SPACE", active = true},
        {name = "third person", key = "V", active = false},
    })
    
    local radar = self:CreateRadar()
    
    -- Update radar with random players every second
    spawn(function()
        while wait(1) do
            local players = {}
            for i = 1, 5 do
                table.insert(players, {
                    isEnemy = math.random(1, 2) == 1,
                    x = math.random(1, 9) / 10,
                    y = math.random(1, 9) / 10
                })
            end
            radar.UpdatePlayers(players)
        end
    end)
    
    -- Connect overlay checkboxes
    radarEnabled.OnChanged(function(value)
        radar.SetVisible(value)
    end)
    
    spectatorListEnabled.OnChanged(function(value)
        spectatorList.SetVisible(value)
    end)
    
    keybindsListEnabled.OnChanged(function(value)
        keybindsList.SetVisible(value)
    end)
    
    watermarkEnabled.OnChanged(function(value)
        watermark.SetVisible(value)
    end)
    
    -- Show welcome notification
    self:CreateNotification("Welcome to Neverlose", "Press INSERT to toggle the menu", "success", 5)
    
    -- Return UI components
    return {
        MainWindow = mainWindow,
        Watermark = watermark,
        SpectatorList = spectatorList,
        KeybindsList = keybindsList,
        Radar = radar
    }
end

-- Return the library
return NeverloseUI
