--[[
TheNexusAvenger

Window of the TODO list plugin.
--]]

local NexusPluginComponents = require(script.Parent:WaitForChild("NexusPluginComponents"))
local PluginInstance = NexusPluginComponents:GetResource("Base.PluginInstance")

local TodoListWindow = PluginInstance:Extend()
TodoListWindow:SetClassName("TodoListWindow")



--[[
Creates the TODO List Window.
--]]
function TodoListWindow:__new(Plugin)
    self:InitializeSuper(Plugin:CreateDockWidgetPluginGui("TODO List", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Bottom, false, false, 300, 100, 200, 50)))
    self.Title = "TODO List"
    self.Name = "TODO List"

    --TODO: Contents
end



return TodoListWindow