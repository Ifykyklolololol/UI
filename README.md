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
local Library = loadstring(game:HttpGet("YOUR_SOURCE_LINK_HERE"))()

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
