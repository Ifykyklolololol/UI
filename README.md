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
```


Method | Description
Library:Window(options) | Creates a new window.
Window:Tab(options) | Creates a new tab in the window.
Tab:Section(options) | Creates a new section within a tab.
Section:Toggle(options) | Creates a toggle element.
Library.Notify(table) | Displays an in-game notification.
Library.SetLayout(layout) | Switches between CSGO or Kavo layout.
Library.ChangeAccent(color) | Changes the accent color globally.
Library.GetConfig() | Returns all flag values as text for saving config.
Library.LoadConfig(configText) | Loads settings from a config text.
Library.SetOpen(boolean) | Opens or closes the entire UI.
Library.Destroy() | Cleans up and removes the UI.
Library.Watermark({Text = "Your Watermark"}) | Adds a dynamic watermark to the UI.
Library.CreateKeybindList() | Creates the keybind list window.
Library.ToggleKeybindList() | Toggles keybind list visibility.
Library.CreateMobileButton() | Creates a button for mobile users to open the UI.
