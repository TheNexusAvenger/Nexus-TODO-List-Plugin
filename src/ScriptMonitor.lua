--[[
TheNexusAvenger

Helper class for monitoring scripts for TODO comments.
--]]

local BLACKLISTED_SERVICES = {
    CoreGui = true
}



local TextService = game:GetService("TextService")

local NexusPluginComponents = require(script.Parent:WaitForChild("NexusPluginComponents"))
local NexusObject = NexusPluginComponents:GetResource("NexusInstance.NexusObject")

local ScriptMonitor = NexusObject:Extend()
ScriptMonitor:SetClassName("ScriptMonitor")



--[[
Craetes the Script Monitor.
--]]
function ScriptMonitor:__new(TodoListWindow)
    self:InitializeSuper()

    self.TodoListWindow = TodoListWindow
    self.SelectionList = TodoListWindow.SelectionList
    self.TrackedScripts = {}
    setmetatable(self.TrackedScripts, {__mode="k"})
    self.ScriptsToEntries = {}
    setmetatable(self.ScriptsToEntries, {__mode="k"})
end

--[[
Updates a script entry.
--]]
function ScriptMonitor:UpdateScriptEntry(Script)
    --Get the lines.
    local Lines = {}
    local LineCount = 0
    if Script:IsDescendantOf(game) then
        for _, Line in pairs(string.split(Script.Source, "\n")) do
            LineCount = LineCount + 1
            local LowerLine = string.lower(Line)
            local TodoIndex = string.find(LowerLine, "to[[%-_]-]?do")
            if TodoIndex then
                table.insert(Lines, {LineCount, string.sub(Line, TodoIndex)})
            end
        end
    end

    --Create or remove the child entry.
    local ChangesMade = false
    if #Lines == 0 then
        if self.ScriptsToEntries[Script] then
            self.SelectionList:RemoveChild(self.ScriptsToEntries[Script])
            self.ScriptsToEntries[Script] = nil
            self.TodoListWindow:UpdateEntries()
        end
        return
    else
        if not self.ScriptsToEntries[Script] then
            local Entry = self.SelectionList:CreateChild()
            Entry.Selectable = false
            self.ScriptsToEntries[Script] = Entry
            ChangesMade = true
        end
    end

    --Update the script name.
    local Entry = self.ScriptsToEntries[Script]
    local ScriptName = Script:GetFullName()
    if ScriptName ~= Entry.Text then
        Entry.Text = ScriptName
        Entry.Script = Script
        Entry.TextWidth = TextService:GetTextSize(ScriptName, 14, Enum.Font.SourceSansBold, Vector2.new(2000, 16)).X
        ChangesMade = true
        table.sort(self.SelectionList.Children, function(EntryA, EntryB)
            return string.lower(EntryA.Text) < string.lower(EntryB.Text)
        end)
    end

    --Create the child entries.
    for _ = #Entry.Children + 1, #Lines do
        Entry:CreateChild()
    end
    for i = #Entry.Children, #Lines + 1, -1 do
        Entry:RemoveChild(Entry.Children[i])
    end

    --Set the child entries.
    for i, LineData in pairs(Lines) do
        local ChildEntry = Entry.Children[i]
        local Text = "("..tostring(LineData[1])..") "..LineData[2]
        if ChildEntry.Text ~= Text then
            ChildEntry.Text = Text
            ChildEntry.Line = LineData[1]
            ChildEntry.Script = Script
            ChildEntry.TextWidth = TextService:GetTextSize(Text, 14, Enum.Font.SourceSans, Vector2.new(2000, 16)).X
            ChangesMade = true
        end
    end

    --Update the entries.
    if ChangesMade then
        self.TodoListWindow:UpdateEntries()
    end
end

--[[
Starts monitoring a script.
--]]
function ScriptMonitor:StartMonitorScript(Script)
    --Return if the script isn't a script.
    local Worked, IsScript = pcall(function()
        return not Script:IsA("CoreScript") and (Script:IsA("BaseScript") or Script:IsA("ModuleScript"))
    end)
    if not Worked or not IsScript then return end

    --Return if the script is already tracked.
    if self.TrackedScripts[Script] then return end
    self.TrackedScripts[Script] = true

    --Connect the script updating.
    Script:GetPropertyChangedSignal("Source"):Connect(function()
        self:UpdateScriptEntry(Script)
    end)
    Script:GetPropertyChangedSignal("Name"):Connect(function()
        self:UpdateScriptEntry(Script)
    end)
    Script.AncestryChanged:Connect(function()
        self:UpdateScriptEntry(Script)
    end)
    self:UpdateScriptEntry(Script)
end

--[[
Starts the script monitor.
--]]
function ScriptMonitor:Start()
    --Get the services that are valid to scan.
    local Serivces = {}
    for _, Service in pairs(game:GetChildren()) do
        pcall(function()
            if not BLACKLISTED_SERVICES[Service.Name] then
                table.insert(Serivces, Service)
            end
        end)
    end

    --Initialize the scripts in the services.
    for _, Service in pairs(Serivces) do
        for _, Script in pairs(Service:GetDescendants()) do
            self:StartMonitorScript(Script)
        end
        Service.DescendantAdded:Connect(function(Script)
            self:StartMonitorScript(Script)
        end)
    end
end



return ScriptMonitor