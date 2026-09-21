getgenv().Config = { 
    Enabled = false,
    HitPart = "Head",
    FOVRadius = 300,
    ShowFOV = false,
    FillColor = Color3.fromRGB(255, 0, 0),
    esp = false,
    OutlineColor = Color3.fromRGB(255, 255, 255),
    ShowWatermark = true,
    PurpleNightSky = false,
    WeaponColor = Color3.fromRGB(255, 255, 255) -- Couleur par défaut
}

local reps = game:GetService("ReplicatedStorage")
local plrs = game:GetService("Players")
local runs = game:GetService("RunService")
local cs = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local lplr = plrs.LocalPlayer
local cam = workspace.CurrentCamera

local U = require(reps.Modules.Utility)
local EL = require(reps.Modules.EnumLibrary)
local GU = require(reps.Modules.GameplayUtility)

--- arme changer ---

local viewModels = reps:WaitForChild("Assets"):WaitForChild("Temp"):WaitForChild("ViewModels")

local enabled = false
local childAddedConn = nil
local originalMaterials = {}

local function applyWireframeToModel(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Sauvegarde le matériau d'origine
            if originalMaterials[part] == nil then
                originalMaterials[part] = part.Material
            end

            part.Material = Enum.Material.ForceField
            part.Color = getgenv().Config.WeaponColor

            local wireframe = part:FindFirstChild("WireframeEffect")
            if not wireframe then
                wireframe = Instance.new("WireframeHandleAdornment")
                wireframe.Name = "WireframeEffect"
                wireframe.Adornee = part
                wireframe.AlwaysOnTop = true
                wireframe.Parent = part
            end
            wireframe.Color3 = getgenv().Config.WeaponColor
        end
    end
end

local function removeWireframeFromModel(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local wf = part:FindFirstChild("WireframeEffect")
            if wf then
                wf:Destroy()
            end
            if originalMaterials[part] then
                part.Material = originalMaterials[part]
            end
        end
    end
end

local function setEnabled(state)
    if state == enabled then return end
    enabled = state

    if state then
        for _, model in ipairs(viewModels:GetChildren()) do
            applyWireframeToModel(model)
        end
        childAddedConn = viewModels.ChildAdded:Connect(function(child)
            applyWireframeToModel(child)
        end)
    else
        if childAddedConn then
            childAddedConn:Disconnect()
            childAddedConn = nil
        end
        for _, model in ipairs(viewModels:GetChildren()) do
            removeWireframeFromModel(model)
        end
    end
end

local function updateWeaponColors()
    if not enabled then return end
    for _, model in ipairs(viewModels:GetChildren()) do
        applyWireframeToModel(model)
    end
end

--- Purple Night Sky System ---

local purpleNightData = {
    Time = "00:00:00",
    Outdoor = Color3.fromRGB(130, 80, 200),
    Ambient = Color3.fromRGB(40, 20, 60),
    SkyBk = "rbxassetid://252765660",
    SkyDn = "rbxassetid://252763782",
    SkyFt = "rbxassetid://252763580",
    SkyLf = "rbxassetid://252763704",
    SkyRt = "rbxassetid://252763782",
    SkyUp = "rbxassetid://252763629"
}

local function applyPurpleSky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") then
            obj:Destroy()
        end
    end

    local newSky = Instance.new("Sky")
    newSky.Name = "TomatoPurpleSky"
    newSky.SkyboxBk = purpleNightData.SkyBk
    newSky.SkyboxDn = purpleNightData.SkyDn
    newSky.SkyboxFt = purpleNightData.SkyFt
    newSky.SkyboxLf = purpleNightData.SkyLf
    newSky.SkyboxRt = purpleNightData.SkyRt
    newSky.SkyboxUp = purpleNightData.SkyUp
    newSky.Parent = Lighting

    Lighting.TimeOfDay = purpleNightData.Time
    Lighting.OutdoorAmbient = purpleNightData.Outdoor
    Lighting.Ambient = purpleNightData.Ambient
end

local function removePurpleSky()
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") and obj.Name == "TomatoPurpleSky" then
            obj:Destroy()
        end
    end
    Lighting.TimeOfDay = "14:00:00"
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
end

--- ESP ---

local highlights = {}

local function applyHighlight(player)
    local function setupCharacter(char)
        if not char then return end
        
        local highlight = char:FindFirstChild("PlayerHighlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "PlayerHighlight"
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.FillColor = getgenv().Config.FillColor
            highlight.OutlineColor = getgenv().Config.OutlineColor
            highlight.Parent = char
        end
        
        highlight.Enabled = getgenv().Config.esp
        highlights[player] = highlight
    end

    if player.Character then
        setupCharacter(player.Character)
    end

    player.CharacterAdded:Connect(setupCharacter)
end

for _, player in ipairs(plrs:GetPlayers()) do
    if player ~= lplr then
        applyHighlight(player)
    end
end

plrs.PlayerAdded:Connect(function(player)
    if player ~= lplr then
        applyHighlight(player)
    end
end)

plrs.PlayerRemoving:Connect(function(player)
    highlights[player] = nil
end)

runs.RenderStepped:Connect(function()
    for player, highlight in pairs(highlights) do
        if highlight and highlight.Parent then
            highlight.Enabled = getgenv().Config.esp
            highlight.FillColor = getgenv().Config.FillColor
            highlight.OutlineColor = getgenv().Config.OutlineColor
        end
    end
end)

--- silent aim ---
local e, gun = pcall(require, lplr.PlayerScripts.Modules.ItemTypes.Gun)
if e and gun and gun.IsFullyAiming then
    local old = gun.IsFullyAiming
    gun.IsFullyAiming = function(...)
        if getgenv().Config.Enabled then return true end
        return old(...)
    end
end

local FOV = Drawing.new("Circle")
FOV.Color = Color3.fromRGB(255, 255, 255)
FOV.Thickness = 1
FOV.Filled = false

runs.RenderStepped:Connect(function()
    FOV.Position = cam.ViewportSize / 2
    FOV.Radius = getgenv().Config.FOVRadius
    FOV.Visible = getgenv().Config.ShowFOV
end)

local function target()
    local center = cam.ViewportSize / 2
    local bestPart, bestDist = nil, getgenv().Config.FOVRadius
    for _, entity in cs:GetTagged("Entity") do
        if entity == lplr.Character then continue end
        local part = entity:FindFirstChild(getgenv().Config.HitPart, true)
        if not part or not part:IsA("BasePart") then continue end
        local sp, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d < bestDist then bestDist, bestPart = d, part end
    end
    return bestPart
end

local function CFD(origin, part)
    local cf = part.CFrame
    local d = {}
    d[utf8.char(1)] = {
        [utf8.char(0)] = U:EncodeCFrame(CFrame.lookAt(origin, part.Position)),
        [utf8.char(1)] = U:EncodeCFrame(cf),
        [utf8.char(2)] = part,
        [utf8.char(3)] = U:EncodeCFrame(cf:ToObjectSpace(CFrame.new(part.Position))),
    }
    return d
end

local visual = GU.GetEntitiesFromRaycast
GU.GetEntitiesFromRaycast = function(self, envID, params, origin, dir, maxDist, ...)
    local t = target()
    if t then
        local dist = (t.Position - origin).Magnitude
        dir = (t.Position - origin).Unit
        if dist > maxDist then maxDist = dist + 5 end
    end
    return visual(self, envID, params, origin, dir, maxDist, ...)
end

local UseItem = reps.Remotes.Replication.Fighter.UseItem
local hook; hook = hookfunction(UseItem.FireServer, newcclosure(function(self, objID, enumVal, camdata, extra)
    if getgenv().Config.Enabled and enumVal == EL:ToEnum("StartShooting") then
        local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
        local t = target()
        if root and t then camdata = CFD(root.Position, t) end
    end
    return hook(self, objID, enumVal, camdata, extra)
end))

--------

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/WetCheezit/Bracket-V2/main/src.lua"))()

-- Window
local Window, MainGUI = Library:CreateWindow("Tomato Rivals Menu")

-- ScreenGui pour le watermark
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TomatoWatermarkGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = lplr:WaitForChild("PlayerGui")

--- watermark ---

local watermark = Instance.new("Frame")
watermark.Name = "Watermark"
watermark.AnchorPoint = Vector2.new(1, 0)
watermark.Position = UDim2.new(1, -8, 0, 8)
watermark.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
watermark.BorderSizePixel = 2
watermark.BorderColor3 = Color3.fromRGB(255, 255, 255)
watermark.Visible = getgenv().Config.ShowWatermark
watermark.Parent = screenGui

local watermarkCorner = Instance.new("UICorner")
watermarkCorner.CornerRadius = UDim.new(0, 4)
watermarkCorner.Parent = watermark

local watermarkLabel = Instance.new("TextLabel")
watermarkLabel.Name = "Text"
watermarkLabel.Size = UDim2.fromScale(1, 1)
watermarkLabel.BackgroundTransparency = 1
watermarkLabel.Font = Enum.Font.Code
watermarkLabel.TextSize = 14
watermarkLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
watermarkLabel.RichText = true
watermarkLabel.Parent = watermark

local watermarkFrames = 0
runs.RenderStepped:Connect(function()
    watermarkFrames += 1
end)

task.spawn(function()
    while true do
        task.wait(1)
        local fps = watermarkFrames
        watermarkFrames = 0
        local ping = math.floor(lplr:GetNetworkPing() * 1000)
        watermarkLabel.Text = string.format(
            '<font color="#FF6347">tomato</font>  |  V1  |  tomato35zz  |  %d fps  |  %dms',
            fps, ping
        )
        watermark.Size = UDim2.fromOffset(watermarkLabel.TextBounds.X + 14, 22)
    end
end)

--------

-- Tabs
local Tab1 = Window:CreateTab("Tab 1")
local Tab2 = Window:CreateTab("Tab 2")

local Groupbox1 = Tab1:CreateGroupbox("Groupbox 1", "Left")
local Groupbox2 = Tab1:CreateGroupbox("Groupbox 2", "Right")
local Groupbox3 = Tab2:CreateGroupbox("Groupbox 3", "Left")

Groupbox1:CreateToggle("silent aim", function(state)
    getgenv().Config.Enabled = state
end)

Groupbox1:CreateToggle("Fov", function(state)
    getgenv().Config.ShowFOV = state
end)

Groupbox1:CreateSlider("FOV Size", 0, 1000, 300, function(value)
    getgenv().Config.FOVRadius = value
end)

Groupbox2:CreateToggle("ESP", function(state)
    getgenv().Config.esp = state
end)

local menuToggle = Groupbox3:CreateToggle("Afficher le menu", function(state)
    MainGUI.Enabled = state
end)
menuToggle:CreateKeyBind("RightShift")

Groupbox3:CreateToggle("Purple Night Sky", function(state)
    getgenv().Config.PurpleNightSky = state
    if state then
        applyPurpleSky()
    else
        removePurpleSky()
    end
end)

Groupbox1:CreateToggle("Change material weapons", function(state)
    setEnabled(state)
end)

local colors = {
    ["White"] = Color3.fromRGB(255, 255, 255),
    ["Blue"] = Color3.fromRGB(0, 150, 255),
    ["Purple"] = Color3.fromRGB(170, 0, 255),
    ["Red"] = Color3.fromRGB(255, 0, 0),
    ["Green"] = Color3.fromRGB(0, 255, 0)
}

Groupbox1:CreateDropdown("Weapon Material Color", {"White", "Blue", "Purple", "Red", "Green"}, function(selectedOption)
    if colors[selectedOption] then
        getgenv().Config.WeaponColor = colors[selectedOption]
        updateWeaponColors()
    end
end)
