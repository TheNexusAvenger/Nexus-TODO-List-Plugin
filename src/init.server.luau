--Runs the TODO list plugin.
--!strict

local NexusPluginComponents = require(script:WaitForChild("Packages"):WaitForChild("NexusPluginComponents"))
local CreateTodoListWindow = require(script:WaitForChild("CreateTodoListWindow"))

local CreatePluginToggleButton = NexusPluginComponents.Input.Plugin.CreatePluginToggleButton



--Create the window.
local Window = CreateTodoListWindow(plugin)

--Create the button.
local NexusWidgetsToolbar = plugin:CreateToolbar("Nexus Widgets")
local ToDoListButton = NexusWidgetsToolbar:CreateButton("TODO List", "Toggles the TODO list window.", "rbxassetid://1690576230")
local ToDoListToggleButton = CreatePluginToggleButton(ToDoListButton, Window)
ToDoListToggleButton.ClickableWhenViewportHidden = true