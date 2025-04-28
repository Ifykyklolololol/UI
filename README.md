# 🌟 Simpliness UI Library

Simpliness is a lightweight, highly animated, themeable, and customizable Roblox UI library made for creating stunning script GUIs.  
It features built-in notifications, color pickers, keybind lists, tab/section systems, and full configuration support.

---

## ✨ Features

- ⚙️ Layout Switching: Supports both `CSGO` and `Kavo` layouts.
- 🎨 Theme Accent Colors: Change accent colors dynamically.
- 🔔 In-Game Notifications System.
- 🔥 Animated Tabs and Sections.
- 🎯 Customizable Keybind List.
- 🎨 Color Picker with HSV support.
- 🎛️ Auto-Save and Load Configurations.
- 📦 Blur & Depth of Field Effects for aesthetic UI.
- 🖱️ Mobile Button Support.
- 🗃️ Watermark Creation.
- 🏗️ Highly Modular API.

---

## 📚 Usage Example

```lua
-- ADD FULL SOURCE HERE

-- Create a window
local Window = Library:Window({
    Name = "Simpliness UI"
})

-- Create a tab
local AimbotTab = Window:Tab({
    Name = "Aimbot"
})

-- Create a section
local AimbotSection = AimbotTab:Section({
    Name = "Aimbot Settings",
    Side = "Left"
})

-- Add a toggle
AimbotSection:Toggle({
    Name = "Enable Aimbot",
    State = false,
    Callback = function(state)
        print("Aimbot Enabled:", state)
    end
})

Library.Notify({
    Title = "Notification Title",
    Content = "This is the message content.",
    Duration = 5, -- seconds
    Color = Color3.fromRGB(255, 188, 254)
})

Section:ColorPicker({
    Name = "Pick a Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        print("Selected Color:", color)
    end
})
-- Save Flags
local configText = Library:GetConfig()
writefile("yourconfig.cfg", configText)

-- Load Flags
if isfile("yourconfig.cfg") then
    local configText = readfile("yourconfig.cfg")
    Library:LoadConfig(configText)
end






