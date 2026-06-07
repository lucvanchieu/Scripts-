--// Cleanup any previous run unconditionally before loading
do
    _G.AutofarmRunning = false  -- kills any old loops
    local lp = game:GetService("Players").LocalPlayer
    local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
    if pg then
        local old = pg:FindFirstChild("AutoStatusGui")
        if old then old:Destroy() end
    end
    task.wait(0.15)  -- give old loop iterations one tick to see false and exit
end
_G.AutofarmRunning = true

--// Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Vibe Code Central / Sell Lemons",
    LoadingTitle = "Vibe Codey baby",
    LoadingSubtitle = "By Claude",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)

--// Services
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// Find Tycoon
local userTycoon = (function()
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Folder") and v.Name:match("Tycoon%d") then
            if v:FindFirstChild("Owner") and v.Owner.Value == LocalPlayer then
                return v
            end
        end
    end
end)()

if not userTycoon then
    Rayfield:Notify({ Title = "Error", Content = "Tycoon not found!", Duration = 5 })
    _G.AutofarmRunning = false
    return
end

--// Flags
local AutoBuy        = false
local AutoUpgrade    = false
local AutoFruit      = false
local AutoRebirth    = false
local AutoEvolve     = false
local AutoPowerLevel = false

--// Live counters
local stats = { buys = 0, upgrades = 0, fruit = 0, rebirths = 0, evolves = 0 }

-- ─────────────────────────────────────────────
--// Auto Buy
-- ─────────────────────────────────────────────
local function buyAllAffordable()
    for _, obj in ipairs(userTycoon.Purchases:GetDescendants()) do
        if obj:IsA("Model") then
            local shown     = obj:GetAttribute("Shown")
            local purchased = obj:GetAttribute("Purchased")
            if shown == true and purchased ~= true then
                local purchase = obj:FindFirstChild("Purchase")
                if purchase and purchase:IsA("RemoteFunction") then
                    pcall(function() purchase:InvokeServer() end)
                    stats.buys = stats.buys + 1
                end
            end
        end
    end
end

task.spawn(function()
    while _G.AutofarmRunning do
        task.wait(0.05)
        if AutoBuy then pcall(buyAllAffordable) end
    end
end)

-- ─────────────────────────────────────────────
--// Auto Upgrade
-- ─────────────────────────────────────────────
local upgradeRemotes  = {}
local upgradeLevel    = {}
local lastUpgradeScan = 0

local function refreshUpgradeRemotes()
    upgradeRemotes = {}
    upgradeLevel   = {}
    local purchases = userTycoon:FindFirstChild("Purchases")
    if not purchases then return end
    for _, obj in ipairs(purchases:GetDescendants()) do
        if obj:IsA("RemoteFunction") and obj.Name == "Upgrade" then
            upgradeRemotes[#upgradeRemotes + 1] = obj
        end
    end
end

task.spawn(function()
    while _G.AutofarmRunning do
        task.wait(0.25)
        if AutoUpgrade then
            if tick() - lastUpgradeScan > 3 then
                refreshUpgradeRemotes()
                lastUpgradeScan = tick()
            end
            for _, remote in ipairs(upgradeRemotes) do
                if remote.Parent then
                    local lvl = (upgradeLevel[remote] or 0) + 1
                    while lvl <= 100 do
                        local ok, res = pcall(function() return remote:InvokeServer(lvl) end)
                        if (not ok) or res == false then break end
                        upgradeLevel[remote] = lvl
                        stats.upgrades = stats.upgrades + 1
                        lvl = lvl + 1
                    end
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────
--// Auto Power Level
-- ─────────────────────────────────────────────
local function getPowerLevelRemote()
    local remotes = userTycoon:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("UpgradePowerLevel")
end

task.spawn(function()
    while _G.AutofarmRunning do
        task.wait(0.25)
        if AutoPowerLevel then
            local remote = getPowerLevelRemote()
            if remote then pcall(function() remote:InvokeServer() end) end
        end
    end
end)

-- ─────────────────────────────────────────────
--// Auto Rebirth (Optimal)
-- ─────────────────────────────────────────────
local RebirthGainMultiple = 1.0
local MinPotential        = 1
local RebirthCooldown     = 2
local RebirthTimeout      = 8
local rebirthBusy         = false

local function getRebirthRemote()
    local remotes = userTycoon:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("Rebirth")
end

local function getRebirthedSignal()
    local remotes = userTycoon:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("Rebirthed")
end

local NUM_SCALE = {
    thousand=1e3,  million=1e6,   billion=1e9,   trillion=1e12,
    quadrillion=1e15, quintillion=1e18, sextillion=1e21, septillion=1e24,
    octillion=1e27, nonillion=1e30, decillion=1e33,
    k=1e3, m=1e6, b=1e9, t=1e12, qd=1e15, qn=1e18, sx=1e21, sp=1e24,
}

local function parseNumber(s)
    if not s then return nil end
    s = tostring(s):gsub(",", ""):lower()
    local num = s:match("[%d%.]+")
    local val = num and tonumber(num)
    if not val then return nil end
    local word = s:match("[%d%.%s]+([a-z]+)")
    if word and NUM_SCALE[word] then val = val * NUM_SCALE[word] end
    return val
end

local function investorBody()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local r  = pg and pg:FindFirstChild("Rebirth")
    local im = r and r:FindFirstChild("InvestorsMenu")
    return im and im:FindFirstChild("Body")
end

local function readQuantity(frameName)
    local body  = investorBody()
    local frame = body and body:FindFirstChild(frameName)
    local q     = frame and frame:FindFirstChild("Quantity")
    return q and parseNumber(q.Text)
end

local function getCurrentInvestors()   return readQuantity("Amount")  or 0 end
local function getPotentialInvestors() return readQuantity("Potential")     end

task.spawn(function()
    while _G.AutofarmRunning do
        task.wait(0.5)
        if AutoRebirth and not rebirthBusy then
            local remote    = getRebirthRemote()
            local potential = getPotentialInvestors()
            local current   = getCurrentInvestors()
            local worthIt   = remote and potential
                and potential >= MinPotential
                and potential >= current * RebirthGainMultiple
            if worthIt then
                rebirthBusy = true
                pcall(function()
                    local done   = false
                    local signal = getRebirthedSignal()
                    local conn
                    if signal and signal:IsA("RemoteEvent") then
                        conn = signal.OnClientEvent:Connect(function() done = true end)
                    end
                    remote:InvokeServer()
                    stats.rebirths = stats.rebirths + 1
                    local t = 0
                    while not done and t < RebirthTimeout do
                        task.wait(0.1)
                        t = t + 0.1
                    end
                    if conn then conn:Disconnect() end
                end)
                task.wait(RebirthCooldown)
                rebirthBusy = false
            end
        end
    end
end)

-- ─────────────────────────────────────────────
--// Auto Evolve (Optimal)
-- ─────────────────────────────────────────────
local EvolveAt       = 100
local EvolveCooldown = 2
local EvolveTimeout  = 8
local evolveBusy     = false

local function getEvolveRemote()
    local remotes = userTycoon:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("Evolve")
end

local function getEvolvedSignal()
    local remotes = userTycoon:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("Evolved")
end

local function getEvolveProgress()
    local pg   = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local r    = pg and pg:FindFirstChild("Rebirth")
    local em   = r and r:FindFirstChild("EvolutionMenu")
    local body = em and em:FindFirstChild("Body")
    local p    = body and body:FindFirstChild("Progress")
    if not p then return nil end
    return tonumber(tostring(p.Text):match("[%d%.]+"))
end

task.spawn(function()
    while _G.AutofarmRunning do
        task.wait(0.5)
        if AutoEvolve and not evolveBusy then
            local remote   = getEvolveRemote()
            local progress = getEvolveProgress()
            if remote and progress and progress >= EvolveAt then
                evolveBusy = true
                pcall(function()
                    local done   = false
                    local signal = getEvolvedSignal()
                    local conn
                    if signal and signal:IsA("RemoteEvent") then
                        conn = signal.OnClientEvent:Connect(function() done = true end)
                    end
                    remote:InvokeServer()
                    stats.evolves = stats.evolves + 1
                    local t = 0
                    while not done and t < EvolveTimeout do
                        task.wait(0.1)
                        t = t + 0.1
                    end
                    if conn then conn:Disconnect() end
                end)
                task.wait(EvolveCooldown)
                evolveBusy = false
            end
        end
    end
end)

-- ─────────────────────────────────────────────
--// Auto Fruit
-- ─────────────────────────────────────────────
local Trees = {}

local function addTree(obj)
    if obj:IsA("Model") and obj.Name == "LemonTree" then
        if not table.find(Trees, obj) then
            table.insert(Trees, obj)
        end
    end
end

local function removeTree(obj)
    local index = table.find(Trees, obj)
    if index then table.remove(Trees, index) end
end

for _, v in ipairs(workspace:GetDescendants()) do addTree(v) end
workspace.DescendantAdded:Connect(addTree)
workspace.DescendantRemoving:Connect(removeTree)

local function noCollisionTree(tree)
    for _, obj in ipairs(tree:GetDescendants()) do
        if obj:IsA("BasePart") then obj.CanCollide = false end
    end
end

local function teleportToTree(tree)
    local character = LocalPlayer.Character
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local cf = tree:GetPivot()
    hrp.CFrame = cf + Vector3.new(0, 5, 0)
    return true
end

local function collectFruit(tree)
    noCollisionTree(tree)
    local success = teleportToTree(tree)
    if not success then return end
    for _, obj in ipairs(tree:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Fruit" then
            obj.CanCollide = false
            local clickPart = obj:FindFirstChild("ClickPart")
            if clickPart then
                local detector = clickPart:FindFirstChildOfClass("ClickDetector")
                if detector then
                    task.wait(0.45)
                    pcall(function() fireclickdetector(detector) end)
                    stats.fruit = stats.fruit + 1
                end
            end
        end
    end
end

task.spawn(function()
    while _G.AutofarmRunning do
        task.wait(0.1)
        if AutoFruit then
            for _, tree in ipairs(Trees) do
                if not AutoFruit then break end
                if tree and tree.Parent then
                    pcall(function() collectFruit(tree) end)
                end
            end
        end
    end
end)

-- ─────────────────────────────────────────────
--// Sewer Helpers
-- ─────────────────────────────────────────────
local function touchPart(hrp, part)
    pcall(function()
        firetouchinterest(hrp, part, 0)
        firetouchinterest(hrp, part, 1)
    end)
end

local function pullAllLevers()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end

    local map   = workspace:FindFirstChild("Map")
    local sewer = map and map:FindFirstChild("Sewer")
    local root  = sewer or workspace

    local pulled = 0
    for _, o in ipairs(root:GetDescendants()) do
        if o:IsA("BasePart") and string.find(string.lower(o.Name), "lever", 1, true) then
            touchPart(hrp, o)
            pulled = pulled + 1
        end
    end

    if sewer then
        for _, o in ipairs(sewer:GetDescendants()) do
            if o:IsA("BasePart") and (o.Name == "VineKey" or o.Name == "UFOKey") then
                touchPart(hrp, o)
            end
        end
    end

    return pulled
end

local function doSewerRun()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "no character" end

    local map   = workspace:FindFirstChild("Map")
    local sewer = map and map:FindFirstChild("Sewer")
    if not sewer then return false, "sewer not loaded" end

    -- 1) pull all levers
    for _, o in ipairs(sewer:GetDescendants()) do
        if o:IsA("BasePart") and string.find(string.lower(o.Name), "lever", 1, true) then
            touchPart(hrp, o)
        end
    end

    -- 2) grab keys
    for _, folderName in ipairs({ "CashVine", "SewerAlien" }) do
        local folder = sewer:FindFirstChild(folderName)
        if folder then
            for _, o in ipairs(folder:GetDescendants()) do
                if o:IsA("BasePart") and (o.Name == "VineKey" or o.Name == "UFOKey") then
                    touchPart(hrp, o)
                end
            end
        end
    end
    task.wait(0.3)

    local cashVine = sewer:FindFirstChild("CashVine")

    -- 3) open the VineDoor
    if cashVine then
        local vineDoor = cashVine:FindFirstChild("VineDoor")
        if vineDoor then
            for _, o in ipairs(vineDoor:GetDescendants()) do
                if o:IsA("BasePart") then touchPart(hrp, o) end
            end
        end
    end
    task.wait(0.3)

    -- 4) teleport to CashVine and harvest
    if cashVine then
        local vineModel = cashVine:FindFirstChild("CashVine")
        if vineModel then
            local pivot = vineModel:GetPivot()
            pcall(function() hrp.CFrame = pivot + Vector3.new(0, 3, 0) end)
            task.wait(0.2)
            for _, o in ipairs(vineModel:GetDescendants()) do
                if o:IsA("BasePart") then touchPart(hrp, o) end
            end
        end
    end

    return true
end

local SEWER_ALIEN_POS = Vector3.new(-42, -41, 180)
local function teleportToAlien()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "no character" end
    pcall(function() hrp.CFrame = CFrame.new(SEWER_ALIEN_POS) end)
    return true
end

-- ─────────────────────────────────────────────
--// GUI Toggles
-- ─────────────────────────────────────────────
MainTab:CreateToggle({
    Name = "Auto Buy",
    CurrentValue = false,
    Flag = "AutoBuy",
    Callback = function(Value)
        AutoBuy = Value
        Rayfield:Notify({ Title = "Auto Buy", Content = Value and "Enabled" or "Disabled", Duration = 3 })
    end,
})

MainTab:CreateToggle({
    Name = "Auto Upgrade",
    CurrentValue = false,
    Flag = "AutoUpgrade",
    Callback = function(Value)
        AutoUpgrade = Value
        Rayfield:Notify({ Title = "Auto Upgrade", Content = Value and "Enabled" or "Disabled", Duration = 3 })
    end,
})

MainTab:CreateToggle({
    Name = "Auto Fruit",
    CurrentValue = false,
    Flag = "AutoFruit",
    Callback = function(Value)
        AutoFruit = Value
        Rayfield:Notify({ Title = "Auto Fruit", Content = Value and "Enabled" or "Disabled", Duration = 3 })
    end,
})

MainTab:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Flag = "AutoRebirth",
    Callback = function(Value)
        AutoRebirth = Value
        if Value and not getRebirthRemote() then
            Rayfield:Notify({ Title = "Auto Rebirth", Content = "Rebirth remote not found in your tycoon!", Duration = 5 })
            return
        end
        Rayfield:Notify({ Title = "Auto Rebirth", Content = Value and "Enabled" or "Disabled", Duration = 3 })
    end,
})

MainTab:CreateToggle({
    Name = "Auto Evolve (x10 income)",
    CurrentValue = false,
    Flag = "AutoEvolve",
    Callback = function(Value)
        AutoEvolve = Value
        if Value and not getEvolveRemote() then
            Rayfield:Notify({ Title = "Auto Evolve", Content = "Evolve remote not found in your tycoon!", Duration = 5 })
            return
        end
        Rayfield:Notify({
            Title = "Auto Evolve",
            Content = Value and "Enabled (evolves at full progress)" or "Disabled",
            Duration = 3,
        })
    end,
})

MainTab:CreateToggle({
    Name = "Auto Power Level",
    CurrentValue = false,
    Flag = "AutoPowerLevel",
    Callback = function(Value)
        AutoPowerLevel = Value
        Rayfield:Notify({ Title = "Auto Power Level", Content = Value and "Enabled" or "Disabled", Duration = 3 })
    end,
})

-- ─────────────────────────────────────────────
--// GUI Buttons
-- ─────────────────────────────────────────────
MainTab:CreateButton({
    Name = "Pull All Levers (sewer)",
    Callback = function()
        local n = pullAllLevers()
        Rayfield:Notify({
            Title = "Pull All Levers",
            Content = n > 0 and ("Pulled " .. n .. " lever(s) + grabbed sewer keys")
                or "No levers found (is the sewer loaded?)",
            Duration = 4,
        })
    end,
})

MainTab:CreateButton({
    Name = "Vine Harvest",
    Callback = function()
        Rayfield:Notify({ Title = "Vine Harvest", Content = "Running...", Duration = 2 })
        task.spawn(function()
            local ok, err = doSewerRun()
            Rayfield:Notify({
                Title = "Vine Harvest",
                Content = ok and "Done! Levers pulled, keys grabbed, vine harvested."
                    or ("Failed: " .. tostring(err)),
                Duration = 5,
            })
        end)
    end,
})

MainTab:CreateButton({
    Name = "Teleport to Sewer Alien",
    Callback = function()
        local ok, err = teleportToAlien()
        Rayfield:Notify({
            Title = "Teleport to Sewer Alien",
            Content = ok and "Teleported to the sewer alien (UFO)" or ("Failed: " .. tostring(err)),
            Duration = 3,
        })
    end,
})

-- ─────────────────────────────────────────────
--// Destroy GUI
-- ─────────────────────────────────────────────
MainTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        -- Stop all background loops first
        _G.AutofarmRunning = false

        -- Reset all flags
        AutoBuy        = false
        AutoUpgrade    = false
        AutoFruit      = false
        AutoRebirth    = false
        AutoEvolve     = false
        AutoPowerLevel = false

        -- Remove the status panel
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            local statusGui = pg:FindFirstChild("AutoStatusGui")
            if statusGui then statusGui:Destroy() end
        end

        -- Destroy Rayfield last
        -- Next time you run the script, the top cleanup block will reset
        -- _G.AutofarmRunning and load a fresh Rayfield with no leftover loops.
        Rayfield:Destroy()
    end,
})

-- ─────────────────────────────────────────────
--// Live Status Panel
-- ─────────────────────────────────────────────
task.spawn(function()
    local parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not parent then
        local okh, hui = pcall(function() return gethui() end)
        parent = (okh and hui) or game:GetService("CoreGui")
    end

    pcall(function()
        local old = parent:FindFirstChild("AutoStatusGui")
        if old then old:Destroy() end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoStatusGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    gui.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 168)
    frame.Position = UDim2.new(0, 10, 0, 90)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(38, 40, 54)
    title.BorderSizePixel = 0
    title.Text = "AUTO STATUS"
    title.TextColor3 = Color3.fromRGB(120, 235, 140)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.Parent = frame
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -12, 1, -30)
    body.Position = UDim2.new(0, 8, 0, 28)
    body.BackgroundTransparency = 1
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.RichText = true
    body.Text = "starting..."
    body.TextColor3 = Color3.fromRGB(235, 235, 245)
    body.Font = Enum.Font.Code
    body.TextSize = 12
    body.Parent = frame

    -- Drag (mouse + touch)
    local UIS = game:GetService("UserInputService")
    local dragging, ds, sp
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
           or i.UserInputType == Enum.UserInputType.Touch then
            dragging, ds, sp = true, i.Position, frame.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
           or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)

    -- FPS counter
    local RunService = game:GetService("RunService")
    local frames, fps, fpsT = 0, 0, tick()
    local fpsConn = RunService.RenderStepped:Connect(function()
        frames = frames + 1
        if tick() - fpsT >= 1 then fps, frames, fpsT = frames, 0, tick() end
    end)

    -- Clean up FPS connection when GUI is destroyed
    gui.Destroying:Connect(function()
        fpsConn:Disconnect()
    end)

    local function on(b)
        return b and "<font color='#7CFF7C'>ON</font>" or "<font color='#777'>off</font>"
    end

    while gui.Parent and _G.AutofarmRunning do
        local cashStr = "?"
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        local c  = ls and ls:FindFirstChild("Cash")
        if c then cashStr = tostring(c.Value) end

        body.Text = string.format(
            "FPS:  %d\nCash: %s\n"
          .. "Buys:  %d  %s\nUpgr:  %d  %s\nFruit: %d  %s\nReb:   %d  %s\nEvo:   %d  %s",
            fps, cashStr,
            stats.buys,     on(AutoBuy),
            stats.upgrades, on(AutoUpgrade),
            stats.fruit,    on(AutoFruit),
            stats.rebirths, on(AutoRebirth),
            stats.evolves,  on(AutoEvolve)
        )
        task.wait(0.25)
    end
end)

Rayfield:Notify({
    Title = "Loaded",
    Content = "Tycoon Autofarm Loaded Successfully",
    Duration = 5,
})
