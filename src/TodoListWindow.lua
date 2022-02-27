--[[
TheNexusAvenger

Window of the TODO list plugin.
--]]

local RunService = game:GetService("RunService")

local NexusPluginComponents = require(script.Parent:WaitForChild("NexusPluginComponents"))
local PluginInstance = NexusPluginComponents:GetResource("Base.PluginInstance")
local ScriptMonitor = require(script.Parent:WaitForChild("ScriptMonitor"))
local TodoListEntry = require(script.Parent:WaitForChild("TodoListEntry"))

local TodoListWindow = PluginInstance:Extend()
TodoListWindow:SetClassName("TodoListWindow")



--[[
Creates the TODO List Window.
--]]
function TodoListWindow:__new(Plugin)
    self:InitializeSuper(Plugin:CreateDockWidgetPluginGui("TODO List", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Bottom, false, false, 300, 100, 200, 50)))
    self.Title = "TODO List"
    self.Name = "TODO List"
    TodoListEntry.Plugin = Plugin

    --Create the background.
    local Background = NexusPluginComponents.new("Frame")
    Background.Size = UDim2.new(1, -2, 1, -1)
    Background.Position = UDim2.new(0, 1, 0, 0)
    Background.BorderSizePixel = 1
    Background.Parent = self
    self:DisableChangeReplication("Background")
    self.Background = Background

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

    --Start the list.
    task.spawn(function()
        if RunService:IsRunning() then
            self:PromptToContinue()
        end
        self:InitializeList()
    end)
end

--[[
Prompts to continue before initializing.
--]]
function TodoListWindow:PromptToContinue()
    --Create the button.
    local ContinueButton = NexusPluginComponents.new("TextButton")
    ContinueButton.BackgroundColor3 = Enum.StudioStyleGuideColor.DialogMainButton
    ContinueButton.BorderSizePixel = 0
    ContinueButton.Size = UDim2.new(0, 100, 0, 24)
    ContinueButton.AnchorPoint = Vector2.new(0.5, 0)
    ContinueButton.Position = UDim2.new(0.5, 0, 0, 50)
    ContinueButton.Text = "Continue"
    ContinueButton.TextColor3 = Enum.StudioStyleGuideColor.DialogMainButtonText
    ContinueButton.Parent = self.Background

    --Create the text.
    local TextLabel = NexusPluginComponents.new("TextLabel")
    TextLabel.Size = UDim2.new(0.8, 0, 0, 200)
    TextLabel.AnchorPoint = Vector2.new(0.5, 0)
    TextLabel.Position = UDim2.new(0.5, 0, 0, 78)
    TextLabel.Text = "The list is disabled in run mode to save resources."
    TextLabel.TextColor3 = Enum.StudioStyleGuideColor.SubText
    TextLabel.TextXAlignment = Enum.TextXAlignment.Center
    TextLabel.TextYAlignment = Enum.TextYAlignment.Top
    TextLabel.TextWrapped = true
    TextLabel.Parent = self.Background

    --Wait for the button to be pressed.
    ContinueButton.MouseButton1Down:Wait()

    --Desroy the text and button.
    ContinueButton:Destroy()
    TextLabel:Destroy()
end

--[[
Initailizes the list.
--]]
function TodoListWindow:InitializeList()
    --Create the scrolling frame.
    local ScrollingFrame = NexusPluginComponents.new("ScrollingFrame")
    ScrollingFrame.Position = UDim2.new(0, 0, 0, 28)
    ScrollingFrame.Size = UDim2.new(1, 0, 1, -28)
    ScrollingFrame.Parent = self.Background
    self:DisableChangeReplication("ScrollingFrame")
    self.ScrollingFrame = ScrollingFrame

    self:DisableChangeReplication("SelectionList")
    self.SelectionList = NexusPluginComponents.new("SelectionList")
    local ElementList = NexusPluginComponents.new("ElementList", function()
        local Frame = TodoListEntry.new()
        Frame.SelectionList = self.SelectionList
        Frame.UpdateElementList = function()
            self:UpdateEntries()
        end
        return Frame
    end)
    ElementList.EntryHeight = 20
    ElementList:ConnectScrollingFrame(ScrollingFrame)
    self:DisableChangeReplication("ElementList")
    self.ElementList = ElementList

    --Set up searching.
    self.SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
        self:UpdateEntries()
    end)

    --Create the script monitor.
    local Monitor = ScriptMonitor.new(self)
    Monitor:Start()
end

--[[
Updates the list entries.
--]]
function TodoListWindow:UpdateEntries()
    --Get the entries that match the search.
    local Search = string.lower(self.SearchBar.Text)
    local Entries = {}
    for _, Entry in pairs(self.SelectionList.Children) do
        --Get the entries that match the search.
        local Children = {}
        for _, SubEntry in pairs(Entry.Children) do
            if string.find(string.lower(SubEntry.Text), Search) then
                table.insert(Children, SubEntry)
            end
        end

        --Craete the new entry.
        if #Children ~= 0 then
            local NewEntry = {
                Children = Children,
            }
            setmetatable(NewEntry, {
                __index = Entry,
                __newindex = Entry,
            })
            table.insert(Entries, Entry)
            if Entry.Expanded then
                for _, Child in pairs(Children) do
                    table.insert(Entries, Child)
                end
            end
        end
    end

    --Set the entries.
    self.ElementList:SetEntries(Entries)

    --Update the maximum width.
    local MaxWidth = 100
    for _, Entry in pairs(Entries) do
        MaxWidth = math.max(MaxWidth, 4 + ((Entry.Indent - 1) * 20) + Entry.TextWidth)
    end
    self.ElementList.CurrentWidth = MaxWidth
end



return TodoListWindow