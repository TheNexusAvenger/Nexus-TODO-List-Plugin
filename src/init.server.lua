--[[
TheNexusAvenger

Runs the TODO list plugin.
--]]

local NexusPluginComponents = require(script:WaitForChild("NexusPluginComponents"))
local TodoListWindow = require(script:WaitForChild("TodoListWindow"))



--Create the window.
local Window = TodoListWindow.new(plugin)

--Create the button.
local NexusWidgetsToolbar = plugin:CreateToolbar("Nexus Widgets")
local ToDoListButton = NexusWidgetsToolbar:CreateButton("TODO List", "Toggles the TODO list window.", "http://www.roblox.com/asset/?id=1690576230")
local ToDoListToggleButton = NexusPluginComponents.new("PluginToggleButton", ToDoListButton, Window)
ToDoListToggleButton.ClickableWhenViewportHidden = true