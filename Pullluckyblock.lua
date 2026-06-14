--[[
    Pull Lucky Blocks Script - Fixed + Updated
    by lucchieu
]]
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Network"):WaitForChild("Remotes")
local DumbellRemote = Remotes:WaitForChild("Activate Dumbell")
local RebirthRemote = Remotes:WaitForChild("Rebirth")
local CollectRemote = Remotes:WaitForChild("Collect Earnings")
local UpgradeFriendRemote = Remotes:WaitForChild("Upgrade Friend")
local BuyDumbellRemote = Remotes:WaitForChild("Buy Dumbell")
local UpgradeCarryRemote = Remotes:WaitForChild("Upgrade Carry Limit")

-- [Mini Button khi minimize]
local miniGui = Instance.new("ScreenGui")
miniGui.Name = "Minichiew"
miniGui.ResetOnSpawn = false
miniGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
miniGui.Parent = game.CoreGui

local miniFrame = Instance.new("Frame")
miniFrame.Size = UDim2.fromOffset(130, 38)
miniFrame.Position = UDim2.new(0.5, -65, 0, 10)
miniFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
miniFrame.BorderSizePixel = 0
miniFrame.Active = true
miniFrame.Draggable = true
miniFrame.Visible = false
miniFrame.Parent = miniGui

Instance.new("UICorner", miniFrame).CornerRadius = UDim.new(0, 8)

local miniStroke = Instance.new("UIStroke", miniFrame)
miniStroke.Color = Color3.fromRGB(80, 80, 200)
miniStroke.Thickness = 1.5

local miniBtn = Instance.new("TextButton", miniFrame)
miniBtn.Size = UDim2.fromScale(1, 1)
miniBtn.BackgroundTransparency = 1
miniBtn.Text = "▶  PLB Script"
miniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
miniBtn.TextSize = 13
miniBtn.Font = Enum.Font.GothamBold

-- [Base finder]
local function getPlayerBase()
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for i = 1, 5 do
        local base = plots:FindFirstChild("BasePos" .. i)
        if base then
            local owner = base:FindFirstChild("owner")
            if owner and owner:IsA("StringValue") and owner.Value == LocalPlayer.Name then
                return base
            end
        end
    end
    return nil
end

local Window = Fluent:CreateWindow({
    Title = "Pull Lucky Blocks Script",
    SubTitle = "by lucchieu",
    TabWidth = 160,
    Size = UDim2.fromOffset(550, 430),
    Acrylic = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- [Bắt sự kiện minimize của Fluent]
local fluentGui = nil
for _, gui in ipairs(game.CoreGui:GetChildren()) do
    if gui.Name == "Fluent" or gui:FindFirstChild("Main") then
        fluentGui = gui
        break
    end
end
-- Theo dõi visibility của Fluent window để hiện/ẩn miniFrame
task.spawn(function()
    while true do
        task.wait(0.2)
        local found = false
        for _, gui in ipairs(game.CoreGui:GetChildren()) do
            local main = gui:FindFirstChild("Main")
            if main and main:IsA("Frame") then
                if not main.Visible then
                    miniFrame.Visible = true
                else
                    miniFrame.Visible = false
                end
                found = true
                break
            end
        end
    end
end)

miniBtn.MouseButton1Click:Connect(function()
    -- Mở lại window Fluent
    for _, gui in ipairs(game.CoreGui:GetChildren()) do
        local main = gui:FindFirstChild("Main")
        if main and main:IsA("Frame") then
            main.Visible = true
            miniFrame.Visible = false
            break
        end
    end
end)

local Tabs = {
    Main     = Window:AddTab({ Title = "Main",    Icon = "box"   }),
    Farm     = Window:AddTab({ Title = "Farm",    Icon = "bot"   }),
    Upgrade  = Window:AddTab({ Title = "Upgrade", Icon = "wrench"}),
    Settings = Window:AddTab({ Title = "Settings",Icon = "cog"   })
}

local Options = Fluent.Options
local connections = {}

do
----- AUTO POWER -----
local Toggle = Tabs.Main:AddToggle("AutoPowerTOGGLE", {Title = "Auto Power", Default = false})
local lastFire = 0
local powerConnection
Toggle:OnChanged(function()
    if Options.AutoPowerTOGGLE.Value then
        powerConnection = RunService.Heartbeat:Connect(function()
            if tick() - lastFire >= 0.05 then
                lastFire = tick()
                DumbellRemote:FireServer()
            end
        end)
    else
        if powerConnection then powerConnection:Disconnect() powerConnection = nil end
    end
end)
Options.AutoPowerTOGGLE:SetValue(false)

----- VIP DOORS -----
local VIPToggle = Tabs.Main:AddToggle("VIPDoorsToggle", {Title = "Unlock VIP Doors", Default = false})
local storedDoors = {}
VIPToggle:OnChanged(function()
    if Options.VIPDoorsToggle.Value then
        local ok, VIPDoors = pcall(function()
            return workspace:WaitForChild("Map", 5):WaitForChild("VIPDoors", 5)
        end)
        if not ok or not VIPDoors then return end
        for _, part in ipairs(VIPDoors:GetChildren()) do
            table.insert(storedDoors, { instance = part, parent = part.Parent })
            part.Parent = nil
        end
    else
        for _, data in ipairs(storedDoors) do
            if data.instance and data.parent then
                data.instance.Parent = data.parent
            end
        end
        storedDoors = {}
    end
end)
Options.VIPDoorsToggle:SetValue(false)

----- AUTO REBIRTH -----
local ToggleRebirth = Tabs.Main:AddToggle("AutoRebirth", {Title = "Auto Rebirth", Default = false})
ToggleRebirth:OnChanged(function()
    if Options.AutoRebirth.Value then
        local last = 0
        connections.rebirth = RunService.Heartbeat:Connect(function()
            if tick() - last >= 1 then
                last = tick()
                RebirthRemote:FireServer()
            end
        end)
    else
        if connections.rebirth then connections.rebirth:Disconnect() connections.rebirth = nil end
    end
end)
Options.AutoRebirth:SetValue(false)

----- AUTO COLLECT CASH -----
-- FIX: collectIndex là upvalue, không reset mỗi tick
local collectIndex = 1
local ToggleCollect = Tabs.Main:AddToggle("AutoCollect", {Title = "Auto Collect Cash", Default = false})
ToggleCollect:OnChanged(function()
    if Options.AutoCollect.Value then
        collectIndex = 1
        local last = 0
        connections.collect = RunService.Heartbeat:Connect(function()
            if tick() - last >= 0.1 then
                last = tick()
                local base = getPlayerBase()
                if not base or not base:FindFirstChild("Stands") then return end
                local stands = base.Stands:GetChildren()
                if #stands == 0 then return end
                if collectIndex > #stands then collectIndex = 1 end
                for attempt = 1, #stands do
                    local idx = ((collectIndex - 1 + attempt - 1) % #stands) + 1
                    local stand = stands[idx]
                    if stand and stand:FindFirstChild("Upgrade") then
                        pcall(function() LocalPlayer.Character:PivotTo(stand:GetPivot()) end)
                        CollectRemote:FireServer(stand.Name)
                        collectIndex = idx + 1
                        break
                    end
                end
            end
        end)
    else
        if connections.collect then connections.collect:Disconnect() connections.collect = nil end
    end
end)
Options.AutoCollect:SetValue(false)

----- AUTO UPGRADE -----
local Input = Tabs.Upgrade:AddInput("UpgradeLevel", {
    Title = "Max Upgrade Level",
    Default = "10",
    Placeholder = "Enter max level...",
    Numeric = true,
    Finished = false,
    Callback = function(Value) print("Target level:", Value) end
})

local ToggleUpgrade = Tabs.Upgrade:AddToggle("AutoUpgrade", {Title = "Auto Upgrade Brainrots", Default = false})
ToggleUpgrade:OnChanged(function()
    if Options.AutoUpgrade.Value then
        local last = 0
        -- FIX: pendingUpgrade là upvalue persist giữa các tick
        local pendingUpgrade = {}
        connections.upgrade = RunService.Heartbeat:Connect(function()
            if tick() - last >= 0.1 then
                last = tick()
                local base = getPlayerBase()
                if not base or not base:FindFirstChild("Stands") then return end
                local targetLevel = tonumber(Input.Value) or 10
                for _, stand in ipairs(base.Stands:GetChildren()) do
                    if not stand:FindFirstChild("Upgrade") then continue end
                    local levelLabel = nil
                    pcall(function()
                        levelLabel = stand.Upgrade.SurfaceGui.Frame.Button.Level
                    end)
                    if not levelLabel then continue end
                    local currentLevel = tonumber(levelLabel.Text:match("Lvl%s*(%d+)"))
                    if not currentLevel then continue end
                    if pendingUpgrade[stand.Name] and currentLevel ~= pendingUpgrade[stand.Name] then
                        pendingUpgrade[stand.Name] = nil
                    end
                    if not pendingUpgrade[stand.Name] and currentLevel < targetLevel then
                        pendingUpgrade[stand.Name] = currentLevel
                        UpgradeFriendRemote:FireServer(stand.Name)
                    end
                end
            end
        end)
    else
        if connections.upgrade then connections.upgrade:Disconnect() connections.upgrade = nil end
    end
end)
Options.AutoUpgrade:SetValue(false)

----- AUTO BUY DUMBELLS -----
local ToggleDumbell = Tabs.Upgrade:AddToggle("AutoDumbell", {Title = "Auto Buy Dumbells", Default = false})
ToggleDumbell:OnChanged(function()
    if Options.AutoDumbell.Value then
        local last = 0
        connections.dumbell = RunService.Heartbeat:Connect(function()
            if tick() - last >= 0.1 then
                last = tick()
                for i = 1, 25 do
                    BuyDumbellRemote:FireServer("Dumbell_" .. i)
                end
            end
        end)
    else
        if connections.dumbell then connections.dumbell:Disconnect() connections.dumbell = nil end
    end
end)
Options.AutoDumbell:SetValue(false)

----- AUTO UPGRADE CARRY -----
local ToggleCarry = Tabs.Upgrade:AddToggle("AutoCarry", {Title = "Auto Upgrade Pull Limit", Default = false})
ToggleCarry:OnChanged(function()
    if Options.AutoCarry.Value then
        local last = 0
        connections.carry = RunService.Heartbeat:Connect(function()
            if tick() - last >= 1 then
                last = tick()
                UpgradeCarryRemote:FireServer()
            end
        end)
    else
        if connections.carry then connections.carry:Disconnect() connections.carry = nil end
    end
end)
Options.AutoCarry:SetValue(false)

----- FARM - AUTO COLLECT LUCKY BLOCKS -----
local rarityThresholds = {
    {name = "Divine",       value = 425000000},
    {name = "OG",           value = 50000000},
    {name = "Brainrot God", value = 10000000},
    {name = "Secret",       value = 2500000},
    {name = "Mythic",       value = 300000},
    {name = "Legendary",    value = 50000},
    {name = "Epic",         value = 10000},
    {name = "Rare",         value = 1250},
    {name = "Common",       value = 100},
}
local rarityRank = {}
for rank, tier in ipairs(rarityThresholds) do
    rarityRank[tier.name] = rank
end

local stealRunning = false
local excludedRarities = {}

local function parseStrength(str)
    str = tostring(str):gsub(",", ""):gsub("%s", "")
    local num, suffix = str:match("^([%d%.]+)([KkMmBbTt]?)$")
    if not num then return 0 end
    num = tonumber(num) or 0
    suffix = suffix:upper()
    if suffix == "K" then num = num * 1000
    elseif suffix == "M" then num = num * 1000000
    elseif suffix == "B" then num = num * 1000000000
    elseif suffix == "T" then num = num * 1000000000000
    end
    return num
end

local function isBeingStolen(model)
    local mass = model:FindFirstChild("Mass")
    if not mass then return false end
    local stealing = mass:FindFirstChild("STEALING")
    return stealing ~= nil and stealing:IsA("RopeConstraint")
end

-- FIX: trim whitespace tránh mismatch rarity
local function getRarityText(model)
    local text = nil
    pcall(function()
        text = model.FriendBillboard.Frame.Rarity.Text
    end)
    if text then text = text:match("^%s*(.-)%s*$") end
    return text
end

local function isRagdolled()
    local char = workspace:FindFirstChild(LocalPlayer.Name)
    if not char then return false end
    local ragdolled = char:FindFirstChild("Ragdolled")
    return ragdolled and ragdolled:IsA("BoolValue") and ragdolled.Value == true
end

local function waitForRagdollEnd()
    while stealRunning and isRagdolled() do task.wait(0.1) end
    if not stealRunning then return false end
    task.wait(0.5)
    return true
end

local function attemptSteal(model, rootPart, prompt)
    for attempt = 1, 6 do
        if not stealRunning then return "skip" end
        if not model or not model.Parent then return "skip" end
        if isBeingStolen(model) then return "skip" end
        if isRagdolled() then return "ragdoll" end
        pcall(function() LocalPlayer.Character:PivotTo(rootPart.CFrame) end)
        task.wait(0.67)
        if not stealRunning then return "skip" end
        if not model or not model.Parent then return "skip" end
        if isBeingStolen(model) then return "skip" end
        if isRagdolled() then return "ragdoll" end
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(1.18)
        if not stealRunning then return "skip" end
        if not model or not model.Parent then return "skip" end
        if isBeingStolen(model) then return "skip" end
        if isRagdolled() then return "ragdoll" end
    end
    return "skip"
end

-- FIX: tìm folder chứa lucky blocks với nhiều path
local function getFriendsFolder()
    local folder = nil
    local paths = {
        function() return workspace.Live.Friends end,
        function() return workspace.Friends end,
        function() return workspace.Live.Blocks end,
        function() return workspace.Blocks end,
        function() return workspace.Live.LuckyBlocks end,
        function() return workspace.LuckyBlocks end,
        function() return workspace.Live.Items end,
        function() return workspace.Items end,
    }
    for _, p in ipairs(paths) do
        local ok, result = pcall(p)
        if ok and result then return result end
    end
    -- Quét toàn bộ workspace nếu không tìm thấy
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            for _, sub in ipairs(child:GetChildren()) do
                if sub:IsA("Folder") and (
                    sub.Name:lower():find("friend") or
                    sub.Name:lower():find("block") or
                    sub.Name:lower():find("lucky") or
                    sub.Name:lower():find("item")
                ) then
                    return sub
                end
            end
        end
    end
    return nil
end

local ExcludeDropdown = Tabs.Farm:AddDropdown("ExcludeRarities", {
    Title = "Exclude Rarities",
    Description = "Chọn rarity muốn bỏ qua",
    Values = {"Common","Rare","Epic","Legendary","Mythic","Secret","Brainrot God","OG","Divine"},
    Multi = true,
    Default = {},
})
ExcludeDropdown:OnChanged(function(Value)
    excludedRarities = {}
    for rarity, state in next, Value do
        if state then excludedRarities[rarity] = true end
    end
end)

local StrengthLabel = Tabs.Farm:AddParagraph("StrengthInfo", {
    Title = "Current Strength",
    Content = "Chưa bắt đầu..."
})

local ToggleSteal = Tabs.Farm:AddToggle("AutoSteal", {Title = "Auto Collect Lucky Blocks", Default = false})
ToggleSteal:OnChanged(function()
    if Options.AutoSteal.Value then
        stealRunning = true
        task.spawn(function()
            while stealRunning do
                if isRagdolled() then
                    local ok = waitForRagdollEnd()
                    if not ok then break end
                    continue
                end

                local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
                local strengthStat = leaderstats and leaderstats:FindFirstChild("Strength")
                if not strengthStat then task.wait(1) continue end

                local strength = parseStrength(strengthStat.Value)
                pcall(function()
                    StrengthLabel:SetDesc("Strength: " .. tostring(strengthStat.Value) .. " (" .. strength .. ")")
                end)

                local eligibleRarities = {}
                for _, tier in ipairs(rarityThresholds) do
                    if strength >= tier.value and not excludedRarities[tier.name] then
                        eligibleRarities[tier.name] = true
                    end
                end

                if not next(eligibleRarities) then task.wait(1) continue end

                local friendsFolder = getFriendsFolder()
                if not friendsFolder then task.wait(1) continue end

                local candidates = {}
                for _, model in ipairs(friendsFolder:GetChildren()) do
                    if not model:IsA("Model") then continue end
                    local rarity = getRarityText(model)
                    if not rarity or rarity == "" then continue end
                    if not eligibleRarities[rarity] then continue end
                    if isBeingStolen(model) then continue end
                    -- FIX: tìm rootPart và prompt linh hoạt hơn
                    local rootPart = model:FindFirstChild("RootPart")
                        or model.PrimaryPart
                        or model:FindFirstChildWhichIsA("BasePart")
                    if not rootPart then continue end
                    local prompt = rootPart:FindFirstChild("StealPrompt")
                        or model:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if not prompt then continue end
                    table.insert(candidates, {
                        model  = model,
                        root   = rootPart,
                        prompt = prompt,
                        rank   = rarityRank[rarity] or 999,
                    })
                end

                if #candidates == 0 then task.wait(1) continue end

                local bestRank = math.huge
                for _, c in ipairs(candidates) do
                    if c.rank < bestRank then bestRank = c.rank end
                end
                local targets = {}
                for _, c in ipairs(candidates) do
                    if c.rank == bestRank then table.insert(targets, c) end
                end

                local ragdolledMidLoop = false
                for _, target in ipairs(targets) do
                    if not stealRunning then break end
                    if not target.model or not target.model.Parent then continue end
                    if isBeingStolen(target.model) then continue end

                    local result = attemptSteal(target.model, target.root, target.prompt)
                    if result == "ragdoll" then
                        local ok = waitForRagdollEnd()
                        ragdolledMidLoop = true
                        if not ok then stealRunning = false end
                        break
                    end

                    if stealRunning and target.model and target.model.Parent then
                        local HOME = CFrame.new(287, 11, 304)
                        local giveUp = tick() + 5
                        while stealRunning and target.model and target.model.Parent and tick() < giveUp do
                            if isRagdolled() then
                                local ok = waitForRagdollEnd()
                                ragdolledMidLoop = true
                                if not ok then stealRunning = false end
                                break
                            end
                            pcall(function() LocalPlayer.Character:PivotTo(HOME) end)
                            task.wait(0.1)
                        end
                        if ragdolledMidLoop then break end
                    end
                    task.wait(0.5)
                end

                if stealRunning and not ragdolledMidLoop then
                    task.wait(0.5)
                end
            end
        end)
    else
        stealRunning = false
    end
end)
Options.AutoSteal:SetValue(false)

----- SETTINGS -----
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
end
