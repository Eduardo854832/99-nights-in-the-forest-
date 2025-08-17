# Universal Hub - Feature Documentation

## 🏗️ Architecture Overview

The Universal Hub has been completely refactored with a modern, modular architecture:

- **FeatureRegistry**: Central system for managing all features
- **EventBus**: Publish/subscribe system for feature communication
- **Dynamic UI**: Category-based panels that generate automatically
- **Hotkey System**: Assignable hotkeys per feature with persistence
- **UIHelpers**: Factory functions for consistent UI creation

## 📂 Feature Categories

### 🏃 Movimento (Movement)
- **Fly**: Original fly system with 3D mode support
- **Noclip**: Walk through walls (RightControl)
- **Sprint**: Speed boost while holding Shift
- **WalkSpeed**: Adjustable walk speed with protection
- **JumpPower**: Auto-detects JumpHeight vs JumpPower
- **High Jump**: Instant upward boost with cooldown
- **Gravity**: Modify workspace gravity

### 🌐 Teleporte (Teleport)
- **Teleport to Player**: Select and teleport to any player
- **Waypoints**: Save/load positions with custom names
- **Rejoin**: Return to the same server
- **Server Hop**: Join a different server automatically

### 👁️ Visual
- **FOV**: Adjustable field of view
- **Freecam**: Free camera with WASD+QE controls (G key)
- **ESP**: Player name tags with distance
- **Highlights**: Player highlighting with distance limits

### 🛠️ Utilidades (Utilities)
- **Anti-AFK**: Automatic activity simulation
- **Chat Notify**: Player join/leave notifications
- **Logger UI**: Scrollable log viewer with copy function
- **Auto Exec**: Save and run scripts automatically
- **Theme Toggle**: Switch between Dark/Light themes

### ⚙️ Dev (Developer Tools)
- **Explorer**: Browse game instances (Workspace, Players, etc.)
- **Property Viewer**: View selected instance properties
- **Remote Spy**: Monitor RemoteEvent calls
- **Instance Stats**: Real-time FPS/Memory/Instance counters

### 📜 Scripts
- **Infinite Yield**: Load IY with status display
- **Script Loader**: Execute custom Lua code

## 🎮 Usage

### Loading the Script
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Eduardo854832/Universal-Hub/refs/heads/main/SCRIPT.lua"))()
```

### Using Features Programmatically
```lua
-- Access the registry
local hub = _G.__UNIVERSAL_HUB_EXPORTS
local registry = hub.FeatureRegistry

-- Toggle a feature
registry.toggle("fly")

-- Check if enabled
if registry.isEnabled("noclip") then
    print("Noclip is active")
end

-- Subscribe to feature events
hub.EventBus.subscribe("FeatureToggled", function(featureId, enabled)
    print(featureId .. " was " .. (enabled and "enabled" or "disabled"))
end)
```

### Hotkeys
- **F**: Toggle Fly
- **G**: Toggle Freecam  
- **RightControl**: Toggle Noclip
- **RightShift**: Open/Close main menu
- **Custom**: Assign hotkeys via the ⌘ button next to features

### Persistence
All feature states, settings, and hotkeys are automatically saved to `UniversalUtilityConfig.json` in your executor's workspace folder.

## 🌍 Language Support

The hub supports Portuguese and English with automatic language selection on first run:
- **PT**: Portuguese (default for Portuguese locale)
- **EN**: English (fallback)

## 📱 Mobile Support

- Touch-friendly interface
- Draggable floating button when minimized
- 3D fly mode enabled by default on mobile devices
- Touch events supported for all interactions

## 🎨 Theming

Switch between Dark and Light themes via the Theme Toggle in Utilidades:
- **Dark**: Modern dark theme (default)
- **Light**: Clean light theme
- Themes persist across sessions and immediately update the UI

## ⚙️ Advanced Features

### Custom Feature Registration
```lua
local hub = _G.__UNIVERSAL_HUB_EXPORTS
hub.FeatureRegistry.register("my_feature", {
    name = "My Feature",
    category = "Custom",
    defaultEnabled = false,
    hotkey = Enum.KeyCode.H,
    onEnable = function()
        print("Feature enabled!")
    end,
    onDisable = function() 
        print("Feature disabled!")
    end
})
```

### Event System
```lua
local EventBus = _G.__UNIVERSAL_HUB_EXPORTS.EventBus

-- Subscribe to events
EventBus.subscribe("FeatureToggled", function(featureId, enabled)
    -- Handle feature toggle
end)

-- Publish custom events
EventBus.publish("CustomEvent", "data", 123)
```

## 🔧 Troubleshooting

- **Features not working**: Check if your executor supports the required APIs
- **Remote Spy not working**: Requires `hookmetamethod` support
- **Hotkeys not working**: Make sure no other scripts are interfering
- **UI not appearing**: Try rejoining or running the script again

## 📈 Performance

The hub is optimized for performance:
- Limited depth exploration in Instance Explorer
- Efficient event handling with cleanup
- Memory management for UI elements
- Configurable update intervals for stats

Enjoy the enhanced Universal Hub experience! 🚀