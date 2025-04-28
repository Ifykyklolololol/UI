# SolixHub UI Library

<div align="center">


**A powerful and elegant UI library for Roblox scripting**



</div>



## 📥 Use Of UI

```lua
-- Add source code at the top of the script.
```

# Window 
```lua
Library:Window({
    Name = "SolixHub"
})
```

# Tabs 
```lua
local MainTab = Library:Tab({ 
    Name = "Main" 
})

local SettingsTab = Library:Tab({ 
    Name = "Settings" 
})
```

# Sections
```lua
local LeftSection = MainTab:Section({ 
    Name = "Combat", 
    Side = "Left" 
})

local RightSection = MainTab:Section({ 
    Name = "Movement", 
    Side = "Right" 
})
```

# Toggle 
```lua
LeftSection:Toggle({
    Name = "Aimbot",
    Default = false,
    Flag = "aimbot_enabled",
    Callback = function(Value)
        print("Aimbot is now: " .. tostring(Value))
    end
})
```

# Toggle With Saved Settings 
```lua
LeftSection:Toggle({
    Name = "ESP",
    Default = Settings.ESP or false,
    Callback = function(Value)
        Settings.ESP = Value
    end
})
```

# Button 
```lua
LeftSection:Button({
    Name = "Kill All",
    Callback = function()
        print("Button clicked!")
    end
})
```

# Slider 
```lua
LeftSection:Slider({
    Name = "Walk Speed",
    Min = 16,
    Max = 500,
    Default = 16,
    Decimals = 0,
    Flag = "walkspeed",
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end
})
```

# Dropdown 
```lua
LeftSection:Dropdown({
    Name = "Target Part",
    Options = {"Head", "Torso", "Random"},
    Default = "Head",
    Flag = "target_part",
    Callback = function(Selected)
        print("Selected part: " .. Selected)
    end
})
```

# Multidropdown 
```lua
LeftSection:Dropdown({
    Name = "BlackList From Bag",
    Options = Client.Items,
    Default = Settings.Bag, 
    Max = 900, -- Multi-select with high limit
    Flag = "multi_dropdown_flag",
    Callback = function(Value)
        Settings.Bag = Value
    end
})
```

# Textbox 
```lua
LeftSection:Textbox({
    Name = "Player Name",
    Default = "",
    PlaceholderText = "Enter name...",
    Flag = "player_name",
    Callback = function(Text)
        print("Input text: " .. Text)
    end
})
```

# Keybind 
```lua
LeftSection:Keybind({
    Name = "Fly Key",
    Default = Enum.KeyCode.F,
    Mode = "Toggle", -- or "Hold"
    Flag = "fly_key",
    Callback = function(State)
        print("Fly is now: " .. tostring(State))
    end
})
```

# Colorpicker 
```lua
LeftSection:Colorpicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Flag = "esp_color",
    Callback = function(Color)
        local r, g, b = math.floor(Color.R * 255), math.floor(Color.G * 255), math.floor(Color.B * 255)
        print("Selected color: " .. r .. ", " .. g .. ", " .. b)
    end
})
```

# Notification 
```lua
Library:Notify({ 
    Title = "SolixHub", 
    Content = "Script Loaded Successfully!", 
    Duration = 5 
})
```

# Window 
```lua
Library:Window({
    Name = "SolixHub"
})
```

# Watermark + Example 
```lua
local myWatermark = Library:Watermark({ 
    Text = "SolixHub | FPS: 60 | Ping: 30ms" 
})

local function updateWatermark()
    local time = os.date("%I:%M:%S %p") 
    local fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
    local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    
    if currentWatermark then
        currentWatermark:Remove() 
    end
    
    currentWatermark = Library:Watermark({ 
        Text = string.format("SolixHub | Time: %s | FPS: %d | Ping: %d ms", time, fps, ping) 
    })
end

-- Update watermark every second
game:GetService("RunService").RenderStepped:Connect(function()
    updateWatermark()
end)
```

# Keybind List + Example 
```lua
-- Create a keybind list
Library:CreateKeybindList()

-- Add a keybind to the list
Library:AddKeybind("fly_key", "Fly", "F")

-- Update a keybind's state
Library:UpdateKeybindState("fly_key", true) -- true = active

-- Toggle keybind list visibility
Library:ToggleKeybindList()

-- Button to toggle keybind list
SettingsTab:Button({
    Name = "Toggle Keybind List",
    Callback = function()
        Library:TurnKeybindList()
    end
})
```

# Switch Ui Layout 
```lua
SettingsTab:Toggle({
    Name = "V2 Layout",
    Default = false,
    Callback = function(enabled)
        Library:SetLayout(enabled and "Kavo" or "CSGO")
    end
})
```

# Configs 
```lua
SettingsTab:Toggle({
    Name = "Auto Saving Configs",
    Default = Settings.YesSave or false,
    Callback = function(enabled)
        Settings.YesSave = enabled
    end
})

SettingsTab:Button({
    Name = "Reset Config",
    Callback = function()
        Settings.Reset()
        Library:Notify({ 
            Title = "SolixHub", 
            Content = "Config reset to defaults", 
            Duration = 3 
        })
    end
})
```
