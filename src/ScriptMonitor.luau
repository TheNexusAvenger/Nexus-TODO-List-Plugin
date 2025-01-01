--Helper class for monitoring scripts for TODO comments.
--!strict

local BLACKLISTED_SERVICES = {
    CoreGui = true
}

local TextService = game:GetService("TextService")

local SelectionListEntry = require(script.Parent:WaitForChild("NexusPluginComponents"):WaitForChild("List"):WaitForChild("SelectionListEntry"))
local CreateFusionScope = require(script.Parent:WaitForChild("NexusPluginComponents"):WaitForChild("CreateFusionScope"))
local Fusion = require(script.Parent:WaitForChild("NexusPluginComponents"):WaitForChild("Fusion"))

local ScriptMonitor = {}
ScriptMonitor.__index = ScriptMonitor

export type ScriptEntry = {
    TextWidth: number,
    Script: {
        Name: string,
    }?,
    Entry: {
        Script: Instance,
        Line: number,
        Text: string,
    }?,
}
export type ScriptMonitor = {
    Scope: CreateFusionScope.FusionScope,
    Filter: Fusion.Value<string>,
    TrackedScripts: {[Instance]: boolean},
    RootSelectionListEntry: SelectionListEntry.SelectionListEntry<ScriptEntry>,
    ScriptsToEntries: {[Instance]: SelectionListEntry.SelectionListEntry<ScriptEntry>},
} & typeof(setmetatable({}, ScriptMonitor))



--[[
Craetes the Script Monitor.
--]]
function ScriptMonitor.new(Scope: CreateFusionScope.FusionScope, Filter: Fusion.Value<string>): ScriptMonitor
    --Create the object.
    local self = setmetatable({
        Scope = Scope,
        Filter = Filter,
        TrackedScripts = setmetatable({}, {__mode="k"}) :: any,
        RootSelectionListEntry = SelectionListEntry.new(Scope, {TextWidth = 0} :: ScriptEntry, function(a, b)
            local DataA, DataB = Fusion.peek(a.Data), Fusion.peek(b.Data)
            if not DataA.Script or not DataB.Script then return false end
            return DataA.Script.Name < DataB.Script.Name
        end),
        ScriptsToEntries = {},
    }, ScriptMonitor) :: ScriptMonitor

    --Listen to the filter changing.
    Scope:Observer(Filter):onChange(function()
        local EntriesToUpdate = {}
        for Entry, _ in self.ScriptsToEntries do
            table.insert(EntriesToUpdate, Entry)
        end
        for _, Entry in EntriesToUpdate do
            self:UpdateScriptEntry(Entry :: Script)
        end
    end)

    --Return the object.
    return self
end

--[[
Updates a script entry.
--]]
function ScriptMonitor.UpdateScriptEntry(self: ScriptMonitor, Script: CoreScript | BaseScript | ModuleScript): ()
    --Get the lines.
    local Lines = {}
    local LineCount = 0
    if Script:IsDescendantOf(game) then
        for _, Line in string.split((Script :: any).Source, "\n") do
            LineCount = LineCount + 1
            local LowerLine = string.lower(Line)
            local TodoIndex = string.find(LowerLine, "to[[%-_]-]?do")
            if TodoIndex then
                table.insert(Lines, {LineCount, string.sub(Line, TodoIndex)} :: {any})
            end
        end
    end

    --Create or remove the child entry.
    if #Lines == 0 then
        if self.ScriptsToEntries[Script] then
            self.RootSelectionListEntry:RemoveChild(self.ScriptsToEntries[Script])
            self.ScriptsToEntries[Script] = nil
        end
        return
    else
        if not self.ScriptsToEntries[Script] then
            local Entry = SelectionListEntry.new(self.Scope, {
                TextWidth = 0,
            } :: ScriptEntry)
            Entry.Selectable:set(false)
            self.RootSelectionListEntry:AddChild(Entry)
            self.ScriptsToEntries[Script] = Entry
        end
    end

    --Update the script name.
    local Entry = self.ScriptsToEntries[Script]
    local ScriptName = Script:GetFullName()
    local ScriptData = Fusion.peek(Entry.Data)
    if not ScriptData.Script or ScriptName ~= ScriptData.Script.Name then
        Entry.Data:set({
            TextWidth = TextService:GetTextSize(ScriptName, 14, Enum.Font.SourceSansBold, Vector2.new(2000, 16)).X,
            Script = {
                Name = ScriptName,
            },
        })
    end

    --Create the child entries.
    for _ = #Fusion.peek(Entry.Children) + 1, #Lines do
        local NewEntry = SelectionListEntry.new(self.Scope, {
            TextWidth = 0,
        } :: ScriptEntry)
        Entry:AddChild(NewEntry)
        NewEntry.Selectable:set(false)
    end
    local Children = Fusion.peek(Entry.Children)
    for i = #Children, #Lines + 1, -1 do
        Entry:RemoveChild(Children[i])
    end

    --Set the child entries.
    for i, LineData in Lines do
        local ChildEntry = Children[i]
        local Text = `({LineData[1]}) {LineData[2]}`
        local ChildEntryData = Fusion.peek(ChildEntry.Data)
        if not ChildEntryData.Entry or ChildEntryData.Entry.Text ~= Text then
            ChildEntry.Data:set({
                TextWidth = TextService:GetTextSize(Text, 14, Enum.Font.SourceSans, Vector2.new(2000, 16)).X,
                Entry = {
                    Script = Script :: Instance,
                    Line = LineData[1],
                    Text = Text,
                },
            })
        end
    end

    --Update the visibility of the frames.
    local CurrentFilter = Fusion.peek(self.Filter)
    local VisibleEntries = 0
    for _, ChildEntry in Fusion.peek(Entry.Children) do
        local ChildEntryData = Fusion.peek(ChildEntry.Data)
        if not ChildEntryData.Entry then continue end
        if string.find(ChildEntryData.Entry.Text, CurrentFilter) then
            ChildEntry.Visible:set(true)
            VisibleEntries += 1
        else
            ChildEntry.Visible:set(false)
        end
    end
    Entry.Visible:set(VisibleEntries > 0)
end

--[[
Starts monitoring a script.
--]]
function ScriptMonitor.StartMonitorScript(self: ScriptMonitor, Script: CoreScript | BaseScript | ModuleScript): ()
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
function ScriptMonitor.Start(self: ScriptMonitor): ()
    --Get the services that are valid to scan.
    local Serivces = {}
    for _, Service in game:GetChildren() do
        pcall(function()
            if not BLACKLISTED_SERVICES[Service.Name] then
                table.insert(Serivces, Service)
            end
        end)
    end

    --Initialize the scripts in the services.
    for _, Service in Serivces do
        for _, Script in Service:GetDescendants() do
            self:StartMonitorScript(Script)
        end
        Service.DescendantAdded:Connect(function(Script)
            self:StartMonitorScript(Script)
        end)
    end
end



return ScriptMonitor