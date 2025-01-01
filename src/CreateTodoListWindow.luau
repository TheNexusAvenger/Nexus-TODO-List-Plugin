--Creates the window for the TODO list plugin.
--!strict

local RunService = game:GetService("RunService")

local CreateExpandableList = require(script.Parent:WaitForChild("NexusPluginComponents"):WaitForChild("List"):WaitForChild("CreateExpandableList"))
local CreateFusionScope = require(script.Parent:WaitForChild("NexusPluginComponents"):WaitForChild("CreateFusionScope"))
local Fusion = require(script.Parent:WaitForChild("NexusPluginComponents"):WaitForChild("Fusion"))
local ScriptMonitor = require(script.Parent:WaitForChild("ScriptMonitor"))

local Children = Fusion.Children
local Out = Fusion.Out

return function(Plugin: Plugin): DockWidgetPluginGui
    --Create the window.
    local Window = Plugin:CreateDockWidgetPluginGui("TODO List", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Bottom, false, false, 300, 100, 200, 50))
    Window.Title = "TODO List"
    Window.Name = "TODO List"

    --Create the view.
    task.spawn(function()
        --Wait for the window to be opened.
        while not Window.Enabled do
            Window:GetPropertyChangedSignal("Enabled"):Wait()
        end

        --Create the initial view.
        local Scope = CreateFusionScope()
        local FilterText = Scope:Value("")
        local Background = Scope:Create("Frame")({
            Size = UDim2.new(1, -2, 1, -1),
            Position = UDim2.new(0, 1, 0, 0),
            BorderSizePixel = 1,
            Parent = Window,
            [Children] = {
                Scope:Create("Frame")({
                    BorderSizePixel = 1,
                    Size = UDim2.new(1, 0, 0, 27),
                    [Children] = {
                        Scope:Create("TextBox")({
                            Size = UDim2.new(1, -2, 0, 19),
                            Position = UDim2.new(0, 1, 0, 1),
                            PlaceholderText = "Filter list",
                            Text = "",
                            [Out("Text")] = FilterText,
                        })
                    },
                }),
            }
        })

        --Prompt to continue if the simulation is running.
        if RunService:IsRunning() then
            --Create the continue prompt.
            local ContinueButton = Scope:Create("TextButton")({
                BackgroundColor3 = Enum.StudioStyleGuideColor.DialogMainButton,
                BorderSizePixel = 0,
                Size = UDim2.new(0, 100, 0, 24),
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 50),
                Text = "Continue",
                TextColor3 = Enum.StudioStyleGuideColor.DialogMainButtonText,
                Parent = Background,
            }) :: TextButton
            local ContinueText = Scope:Create("TextLabel")({
                Size = UDim2.new(0.8, 0, 0, 200),
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, 78),
                Text = "The list is disabled in run mode to save resources.",
                TextColor3 = Enum.StudioStyleGuideColor.SubText,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                Parent = Background,
            })

            --Wait for the continue button to be pressed and clear the prompt.
            ContinueButton.MouseButton1Down:Wait()
            ContinueButton:Destroy()
            ContinueText:Destroy()
        end

        --Start the script monitor.
        local Monitor = ScriptMonitor.new(Scope, FilterText)
        Monitor:Start()

        --Create the text for no entries.
        local MonitorScope = Monitor.RootSelectionListEntry.Scope --TODO: Ugly hack where lower scope must be read. No obvious work-around due to children being created after value is created.
        MonitorScope:Create("TextLabel")({
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.new(0, 2, 0, 29),
            Text = "No TODO comments found in scripts.",
            TextColor3 = Enum.StudioStyleGuideColor.SubText,
            Font = Enum.Font.SourceSansItalic,
            ZIndex = 3,
            Visible = MonitorScope:Computed(function(use)
                return #use(Monitor.RootSelectionListEntry.VisibleEntries) <= 1 --1 is only the root entry.
            end),
            Parent = Background,
        })

        --Create the list view.
        local ScrollingFrameAbsoluteSize = Scope:Value(Vector2.zero)
        local ScrollingFrame = Scope:Create("ScrollingFrame")({
            Position = UDim2.new(0, 0, 0, 28),
            Size = UDim2.new(1, 0, 1, -28),
            Parent = Background,
            [Out("AbsoluteSize")] = ScrollingFrameAbsoluteSize,
        }) :: ScrollingFrame
        local VirtualList = CreateExpandableList(Scope, ScrollingFrame, Monitor.RootSelectionListEntry, function(Scope, Entry, DoubleClicked)
            --Connect opening the script.
            local EntryData = Scope:Computed(function(use)
                return use(use(Entry).Data)
            end)
            DoubleClicked:Connect(function()
                local CurrentEntryData = Fusion.peek(EntryData)
                if not CurrentEntryData.Entry then return end
                Plugin:OpenScript(CurrentEntryData.Entry.Script :: Script, CurrentEntryData.Entry.Line)
            end)

            --Create the display.
            return {
                Scope:Create("TextLabel")({
                    Size = UDim2.new(1, 0, 0, 16),
                    Position = UDim2.new(0, 2, 0, 1),
                    Text = Scope:Computed(function(use)
                        local CurrentEntryData = use(EntryData)
                        if CurrentEntryData.Script then
                            return CurrentEntryData.Script.Name
                        elseif CurrentEntryData.Entry then
                            return CurrentEntryData.Entry.Text
                        end
                        return ""
                    end),
                    Font = Scope:Computed(function(use)
                        return use(EntryData).Script and Enum.Font.SourceSansBold or Enum.Font.SourceSans
                    end),
                }),
            }
        end)

        --Set the wide of the window.
        local ScrollingWidth = MonitorScope:Computed(function(use)
            local MaxWidth = use(ScrollingFrameAbsoluteSize).X
            for _, Child in use(Monitor.RootSelectionListEntry.VisibleEntries) do
                local ChildData = use(Child.Data)
                MaxWidth = math.max(MaxWidth, ChildData.TextWidth)
            end
            return MaxWidth
        end)
        MonitorScope:Observer(ScrollingWidth):onChange(function()
            VirtualList:SetScrollWidth(UDim.new(0, Fusion.peek(ScrollingWidth)))
        end)
    end)

    --Return the Window.
    return Window
end