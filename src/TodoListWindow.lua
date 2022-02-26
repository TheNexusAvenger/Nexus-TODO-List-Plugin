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

    --Create the background.
    local Background = NexusPluginComponents.new("Frame")
    Background.Size = UDim2.new(1, -2, 1, -1)
    Background.Position = UDim2.new(0, 1, 0, 0)
    Background.Parent = self

    --Create the top bar.
    local TopBar = NexusPluginComponents.new("Frame")
    TopBar.BorderSizePixel = 1
    TopBar.Size = UDim2.new(1, 0, 0, 27)
    TopBar.Parent = Background

    local SearchBar = NexusPluginComponents.new("TextBox")
    SearchBar.Size = UDim2.new(1, -2, 0, 19)
    SearchBar.Position = UDim2.new(0, 1, 0, 1)
    SearchBar.PlaceholderText = "Filter list"
    SearchBar.Text = ""
    SearchBar.Parent = TopBar
    self:DisableChangeReplication("SearchBar")
    self.SearchBar = SearchBar

    --Create the scrolling frame.
    local ScrollingFrame = NexusPluginComponents.new("ScrollingFrame")
	ScrollingFrame.Position = UDim2.new(0, 0, 0, 28)
	ScrollingFrame.Size = UDim2.new(1, 0, 1, -28)
	ScrollingFrame.Parent = Background
    self:DisableChangeReplication("ScrollingFrame")
    self.ScrollingFrame = SearchBar
end



return TodoListWindow