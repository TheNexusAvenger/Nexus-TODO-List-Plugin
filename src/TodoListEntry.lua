--[[
TheNexusAvenger

Entry of the TODO list.
--]]

local NexusPluginComponents = require(script.Parent:WaitForChild("NexusPluginComponents"))
local CollapsableListFrame = NexusPluginComponents:GetResource("Input.Custom.CollapsableListFrame")

local TodoListEntry = CollapsableListFrame:Extend()
TodoListEntry:SetClassName("TodoListEntry")



--[[
Creates the TODO List Entry.
--]]
function TodoListEntry:__new()
    self:InitializeSuper()

    --Craete the text.
    local TextLabel = NexusPluginComponents.new("TextLabel")
    TextLabel.Size = UDim2.new(0, 100, 0, 16)
    TextLabel.Position = UDim2.new(0, 2, 0, 1)
    TextLabel.Parent = self.AdornFrame
    self:DisableChangeReplication("TextLabel")
    self.TextLabel = TextLabel

    --Set up double clicking.
    self.DoubleClicked:Connect(function()
        if not self.Plugin then return end
        if not self.SelectionListEntry or not self.SelectionListEntry.Line then return end
        self.Plugin:OpenScript(self.SelectionListEntry.Script, self.SelectionListEntry.Line)
    end)
end

--[[
Updates the entry.
--]]
function TodoListEntry:Update(Data)
    self.super:Update(Data)

    --Update the text.
    if not Data then return end
    if Data.Line then
        self.TextLabel.Font = Enum.Font.SourceSans
    else
        self.TextLabel.Font = Enum.Font.SourceSansBold
    end
    self.TextLabel.Text = Data.Text
end



return TodoListEntry