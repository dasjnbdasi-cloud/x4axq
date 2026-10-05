-- x4axq — target lock

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local config = {
    enabled    = false,
    hidden     = false,
    fov        = 50,
    smoothness = 62,
    teamCheck  = true,
    wallCheck  = true,
    keybind    = Enum.KeyCode.E,
    hideKey    = Enum.KeyCode.P,
}

local ACCENT     = Color3.fromRGB(168, 85, 247)
local ACCENT_HI  = Color3.fromRGB(196, 132, 252)
local ACCENT_DIM = Color3.fromRGB(88, 48, 140)
local BG         = Color3.fromRGB(10, 10, 12)
local BG_HEADER  = Color3.fromRGB(16, 16, 20)
local BG_ROW     = Color3.fromRGB(18, 18, 22)
local BG_ROW_H   = Color3.fromRGB(26, 26, 32)
local BG_TRACK   = Color3.fromRGB(30, 30, 36)
local TRACK_ON   = Color3.fromRGB(80, 45, 140)
local TXT        = Color3.fromRGB(232, 228, 240)
local TXT_DIM    = Color3.fromRGB(130, 125, 145)
local TXT_MUTED  = Color3.fromRGB(78, 76, 90)

local CHAM_FILL  = Color3.fromRGB(160, 80, 240)

local gui
local fovRing
local ui
local setLockState
local setHidden
local connections  = {}
local sliders      = {}
local chams        = {}
local selectingBind = nil  -- nil | "toggle" | "hide"

local EASE = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function track(conn)
    table.insert(connections, conn)
    return conn
end

local function inputMatches(input, bind)
    if not bind or typeof(bind) ~= "EnumItem" then return false end
    if input.KeyCode == bind then return true end
    if input.UserInputType == bind then return true end
    return false
end

local function bindLabel(bind)
    if not bind or typeof(bind) ~= "EnumItem" then return "?" end
    local s = tostring(bind)
    local short = string.match(s, "%.([^%.]+)$") or s

    if short == "MouseButton1" then return "LMB" end
    if short == "MouseButton2" then return "RMB" end
    if short == "MouseButton3" then return "MMB" end
    if #short > 4 then return string.sub(short, 1, 4) end
    return short
end

local function isMouseInput(input)
    if not input then return false end
    local t = input.UserInputType
    return t == Enum.UserInputType.MouseButton1
        or t == Enum.UserInputType.MouseButton2
        or t == Enum.UserInputType.MouseButton3
end

-- chams
local function shouldCham(player)
    if player == LocalPlayer then return false end
    if config.teamCheck then
        return player.Team ~= LocalPlayer.Team
    end
    return true
end

local function ensureCham(player)
    local char = player.Character
    local existing = chams[player]

    if not char then
        if existing then
            existing:Destroy()
            chams[player] = nil
        end
        return
    end

    if not existing or existing.Parent ~= char then
        if existing then existing:Destroy() end

        local h = Instance.new("Highlight")
        h.Name                = "x4axq_cham"
        h.FillColor           = CHAM_FILL
        h.FillTransparency    = 0.35
        h.OutlineColor        = CHAM_FILL
        h.OutlineTransparency = 0.35
        h.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
        h.Adornee             = char
        h.Parent              = char

        chams[player] = h
        existing      = h
    end

    existing.Enabled = shouldCham(player)
end

local function refreshChams()
    for _, player in ipairs(Players:GetPlayers()) do
        ensureCham(player)
    end
end

local function clearChams()
    for player, h in pairs(chams) do
        if h then h:Destroy() end
        chams[player] = nil
    end
end

local function makeToggleRow(parent, y, label, initial, onChanged)
    local row = Instance.new("TextButton")
    row.Size             = UDim2.new(1, -24, 0, 30)
    row.Position         = UDim2.new(0, 12, 0, y)
    row.BackgroundColor3 = BG_ROW
    row.BorderSizePixel  = 0
    row.Text             = ""
    row.AutoButtonColor  = false
    row.Parent           = parent

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 5)
    rCorner.Parent       = row

    local name = Instance.new("TextLabel")
    name.Size                 = UDim2.new(1, -56, 1, 0)
    name.Position             = UDim2.new(0, 12, 0, 0)
    name.BackgroundTransparency = 1
    name.Text                 = label
    name.TextColor3           = TXT_DIM
    name.TextSize             = 12
    name.Font                 = Enum.Font.GothamMedium
    name.TextXAlignment       = Enum.TextXAlignment.Left
    name.Parent               = row

    local sw = Instance.new("Frame")
    sw.Size             = UDim2.new(0, 30, 0, 14)
    sw.Position         = UDim2.new(1, -42, 0.5, -7)
    sw.BackgroundColor3 = BG_TRACK
    sw.BorderSizePixel  = 0
    sw.Parent           = row

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(1, 0)
    tCorner.Parent       = sw

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 10, 0, 10)
    knob.Position         = UDim2.new(0, 2, 0.5, -5)
    knob.BackgroundColor3 = Color3.fromRGB(110, 110, 122)
    knob.BorderSizePixel  = 0
    knob.Parent           = sw

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent       = knob

    local state = initial

    local function apply(animate)
        local knobPos  = state and UDim2.new(0, 18, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
        local trackCol = state and TRACK_ON or BG_TRACK
        local knobCol  = state and ACCENT_HI or Color3.fromRGB(110, 110, 122)
        local nameCol  = state and TXT or TXT_DIM

        if animate then
            TweenService:Create(knob, EASE, {Position = knobPos, BackgroundColor3 = knobCol}):Play()
            TweenService:Create(sw,   EASE, {BackgroundColor3 = trackCol}):Play()
            TweenService:Create(name, EASE, {TextColor3 = nameCol}):Play()
        else
            knob.Position         = knobPos
            knob.BackgroundColor3 = knobCol
            sw.BackgroundColor3   = trackCol
            name.TextColor3       = nameCol
        end
    end

    apply(false)

    track(row.MouseEnter:Connect(function()
        TweenService:Create(row, EASE, {BackgroundColor3 = BG_ROW_H}):Play()
    end))
    track(row.MouseLeave:Connect(function()
        TweenService:Create(row, EASE, {BackgroundColor3 = BG_ROW}):Play()
    end))

    track(row.MouseButton1Click:Connect(function()
        state = not state
        apply(true)
        onChanged(state)
    end))

    return {
        get = function() return state end,
        set = function(v, animate)
            if state == v then return end
            state = v
            apply(animate ~= false)
        end,
    }
end

local function makeSlider(parent, y, label, initial, maxValue, onUpdate)
    local sec = Instance.new("TextLabel")
    sec.Size                 = UDim2.new(1, -24, 0, 12)
    sec.Position             = UDim2.new(0, 12, 0, y)
    sec.BackgroundTransparency = 1
    sec.Text                 = label
    sec.TextColor3           = TXT_MUTED
    sec.TextSize             = 9
    sec.Font                 = Enum.Font.GothamBold
    sec.TextXAlignment       = Enum.TextXAlignment.Left
    sec.Parent               = parent

    local readout = Instance.new("TextLabel")
    readout.Size                 = UDim2.new(0, 70, 0, 12)
    readout.Position             = UDim2.new(1, -82, 0, y)
    readout.BackgroundTransparency = 1
    readout.TextColor3           = ACCENT_HI
    readout.TextSize             = 11
    readout.Font                 = Enum.Font.Code
    readout.TextXAlignment       = Enum.TextXAlignment.Right
    readout.Parent               = parent

    local tr = Instance.new("Frame")
    tr.Size             = UDim2.new(1, -24, 0, 4)
    tr.Position         = UDim2.new(0, 12, 0, y + 24)
    tr.BackgroundColor3 = BG_TRACK
    tr.BorderSizePixel  = 0
    tr.ZIndex           = 3
    tr.Parent           = parent

    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1, 0)
    tc.Parent       = tr

    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new(initial / maxValue, 0, 1, 0)
    fill.BackgroundColor3 = ACCENT
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 3
    fill.Parent           = tr

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent       = fill

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.Position         = UDim2.new(initial / maxValue, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(230, 225, 240)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 4
    knob.Parent           = tr

    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent       = knob

    local hit = Instance.new("TextButton")
    hit.Size             = UDim2.new(1, 16, 0, 24)
    hit.Position         = UDim2.new(0, -8, 0.5, -12)
    hit.BackgroundTransparency = 1
    hit.Text             = ""
    hit.AutoButtonColor  = false
    hit.ZIndex           = 5
    hit.Parent           = tr

    local handle = {
        track    = tr,
        fill     = fill,
        knob     = knob,
        hit      = hit,
        readout  = readout,
        maxValue = maxValue,
        onUpdate = onUpdate,
    }

    function handle.apply(rel)
        local value = math.floor(rel * maxValue)
        handle.fill.Size     = UDim2.new(rel, 0, 1, 0)
        handle.knob.Position = UDim2.new(rel, -7, 0.5, -7)
        handle.readout.Text  = onUpdate(value, rel)
        return value
    end

    table.insert(sliders, handle)
    return handle
end

local function buildRing(parent)
    fovRing = Instance.new("Frame")
    fovRing.Name                   = "FovRing"
    fovRing.BackgroundTransparency = 1
    fovRing.BorderSizePixel        = 0
    fovRing.ZIndex                 = 999
    fovRing.Visible                = false
    fovRing.Parent                 = parent

    local stroke = Instance.new("UIStroke")
    stroke.Color        = ACCENT
    stroke.Thickness    = 1.5
    stroke.Transparency = 0.15
    stroke.Parent       = fovRing

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent       = fovRing
end

local function buildUI()
    local parent = (gethui and gethui()) or CoreGui

    gui = Instance.new("ScreenGui")
    gui.Name            = "x4axq"
    gui.ResetOnSpawn    = false
    gui.IgnoreGuiInset  = true
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder    = 100
    gui.Parent          = parent

    local WINDOW_H = 404

    local shadow = Instance.new("Frame")
    shadow.Name                   = "Shadow"
    shadow.Size                   = UDim2.new(0, 240, 0, WINDOW_H)
    shadow.Position               = UDim2.new(0, -240, 0.5, -WINDOW_H/2)
    shadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.5
    shadow.BorderSizePixel        = 0
    shadow.ZIndex                 = 0
    shadow.Parent                 = gui

    local shCorner = Instance.new("UICorner")
    shCorner.CornerRadius = UDim.new(0, 9)
    shCorner.Parent       = shadow

    local main = Instance.new("Frame")
    main.Name              = "Main"
    main.Size              = UDim2.new(0, 240, 0, WINDOW_H)
    main.Position          = UDim2.new(0, -240, 0.5, -WINDOW_H/2)
    main.BackgroundColor3  = BG
    main.BorderSizePixel   = 0
    main.Active            = true
    main.Draggable         = true
    main.ClipsDescendants  = true
    main.ZIndex            = 1
    main.Parent            = gui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 9)
    mainCorner.Parent       = main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color     = Color3.fromRGB(42, 38, 50)
    mainStroke.Thickness = 1
    mainStroke.Parent    = main

    track(main:GetPropertyChangedSignal("Position"):Connect(function()
        shadow.Position = main.Position + UDim2.new(0, 2, 0, 2)
    end))

    local header = Instance.new("Frame")
    header.Size             = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = BG_HEADER
    header.BorderSizePixel  = 0
    header.ZIndex           = 2
    header.Parent           = main

    local accentBar = Instance.new("Frame")
    accentBar.Size             = UDim2.new(1, 0, 0, 1)
    accentBar.Position         = UDim2.new(0, 0, 1, -1)
    accentBar.BackgroundColor3 = ACCENT
    accentBar.BackgroundTransparency = 0.4
    accentBar.BorderSizePixel  = 0
    accentBar.ZIndex           = 3
    accentBar.Parent           = header

    local title = Instance.new("TextLabel")
    title.Size                 = UDim2.new(0, 140, 1, 0)
    title.Position             = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1
    title.Text                 = "x4axq"
    title.TextColor3           = ACCENT
    title.TextSize             = 15
    title.Font                 = Enum.Font.GothamBlack
    title.TextXAlignment       = Enum.TextXAlignment.Left
    title.ZIndex               = 3
    title.Parent               = header

    local version = Instance.new("TextLabel")
    version.Size                 = UDim2.new(0, 40, 1, 0)
    version.Position             = UDim2.new(1, -52, 0, 0)
    version.BackgroundTransparency = 1
    version.Text                 = "v1.8"
    version.TextColor3           = TXT_MUTED
    version.TextSize             = 10
    version.Font                 = Enum.Font.Code
    version.TextXAlignment       = Enum.TextXAlignment.Right
    version.ZIndex               = 3
    version.Parent               = header

    local sec1 = Instance.new("TextLabel")
    sec1.Size                 = UDim2.new(1, -24, 0, 12)
    sec1.Position             = UDim2.new(0, 12, 0, 52)
    sec1.BackgroundTransparency = 1
    sec1.Text                 = "TARGET"
    sec1.TextColor3           = TXT_MUTED
    sec1.TextSize             = 9
    sec1.Font                 = Enum.Font.GothamBold
    sec1.TextXAlignment       = Enum.TextXAlignment.Left
    sec1.Parent               = main

    local tAim  = makeToggleRow(main, 68,  "Aim Lock",    config.enabled,   function(v) config.enabled   = v end)
    local tTeam = makeToggleRow(main, 100, "Team Filter", config.teamCheck, function(v)
        config.teamCheck = v
        refreshChams()
    end)
    local tWall = makeToggleRow(main, 132, "Wall Filter", config.wallCheck, function(v) config.wallCheck = v end)

    local fovSlider = makeSlider(main, 176, "FOV RADIUS", config.fov, 300, function(value)
        config.fov = value
        return string.format("%d px", value)
    end)

    local smoothSlider = makeSlider(main, 224, "SMOOTHNESS", config.smoothness, 100, function(value)
        config.smoothness = value
        return string.format("%d%%", value)
    end)

    local sec2 = Instance.new("TextLabel")
    sec2.Size                 = UDim2.new(1, -24, 0, 12)
    sec2.Position             = UDim2.new(0, 12, 0, 274)
    sec2.BackgroundTransparency = 1
    sec2.Text                 = "BINDS"
    sec2.TextColor3           = TXT_MUTED
    sec2.TextSize             = 9
    sec2.Font                 = Enum.Font.GothamBold
    sec2.TextXAlignment       = Enum.TextXAlignment.Left
    sec2.Parent               = main

    local kbLabel = Instance.new("TextLabel")
    kbLabel.Size                 = UDim2.new(0, 90, 0, 14)
    kbLabel.Position             = UDim2.new(0, 12, 0, 292)
    kbLabel.BackgroundTransparency = 1
    kbLabel.Text                 = "toggle key"
    kbLabel.TextColor3           = TXT_MUTED
    kbLabel.TextSize             = 10
    kbLabel.Font                 = Enum.Font.GothamMedium
    kbLabel.TextXAlignment       = Enum.TextXAlignment.Left
    kbLabel.Parent               = main

    local kbChip = Instance.new("TextButton")
    kbChip.Size             = UDim2.new(0, 46, 0, 18)
    kbChip.Position         = UDim2.new(1, -58, 0, 290)
    kbChip.BackgroundColor3 = Color3.fromRGB(24, 22, 30)
    kbChip.BorderSizePixel  = 0
    kbChip.Text             = bindLabel(config.keybind)
    kbChip.TextColor3       = TXT
    kbChip.TextSize         = 10
    kbChip.Font             = Enum.Font.Code
    kbChip.AutoButtonColor  = false
    kbChip.Parent           = main

    local kbCorner = Instance.new("UICorner")
    kbCorner.CornerRadius = UDim.new(0, 3)
    kbCorner.Parent       = kbChip

    local kbStroke = Instance.new("UIStroke")
    kbStroke.Color     = Color3.fromRGB(52, 42, 68)
    kbStroke.Thickness = 1
    kbStroke.Parent    = kbChip

    local hideLabel = Instance.new("TextLabel")
    hideLabel.Size                 = UDim2.new(0, 90, 0, 14)
    hideLabel.Position             = UDim2.new(0, 12, 0, 318)
    hideLabel.BackgroundTransparency = 1
    hideLabel.Text                 = "hide key"
    hideLabel.TextColor3           = TXT_MUTED
    hideLabel.TextSize             = 10
    hideLabel.Font                 = Enum.Font.GothamMedium
    hideLabel.TextXAlignment       = Enum.TextXAlignment.Left
    hideLabel.Parent               = main

    local hideChip = Instance.new("TextButton")
    hideChip.Size             = UDim2.new(0, 46, 0, 18)
    hideChip.Position         = UDim2.new(1, -58, 0, 316)
    hideChip.BackgroundColor3 = Color3.fromRGB(24, 22, 30)
    hideChip.BorderSizePixel  = 0
    hideChip.Text             = bindLabel(config.hideKey)
    hideChip.TextColor3       = TXT
    hideChip.TextSize         = 10
    hideChip.Font             = Enum.Font.Code
    hideChip.AutoButtonColor  = false
    hideChip.Parent           = main

    local hideCorner = Instance.new("UICorner")
    hideCorner.CornerRadius = UDim.new(0, 3)
    hideCorner.Parent       = hideChip

    local hideStroke = Instance.new("UIStroke")
    hideStroke.Color     = Color3.fromRGB(52, 42, 68)
    hideStroke.Thickness = 1
    hideStroke.Parent    = hideChip

    local unloadBtn = Instance.new("TextButton")
    unloadBtn.Size             = UDim2.new(1, -24, 0, 28)
    unloadBtn.Position         = UDim2.new(0, 12, 0, 344)
    unloadBtn.BackgroundColor3 = Color3.fromRGB(20, 18, 26)
    unloadBtn.BorderSizePixel  = 0
    unloadBtn.Text             = "unload"
    unloadBtn.TextColor3       = Color3.fromRGB(150, 120, 190)
    unloadBtn.TextSize         = 11
    unloadBtn.Font             = Enum.Font.GothamMedium
    unloadBtn.AutoButtonColor  = false
    unloadBtn.Parent           = main

    local uCorner = Instance.new("UICorner")
    uCorner.CornerRadius = UDim.new(0, 5)
    uCorner.Parent       = unloadBtn

    local uStroke = Instance.new("UIStroke")
    uStroke.Color        = Color3.fromRGB(45, 38, 58)
    uStroke.Thickness    = 1
    uStroke.Transparency = 0.2
    uStroke.Parent       = unloadBtn

    track(unloadBtn.MouseEnter:Connect(function()
        TweenService:Create(unloadBtn, EASE, {BackgroundColor3 = Color3.fromRGB(30, 24, 42)}):Play()
        TweenService:Create(unloadBtn, EASE, {TextColor3 = ACCENT_HI}):Play()
        TweenService:Create(uStroke,   EASE, {Color = ACCENT_DIM, Transparency = 0}):Play()
    end))
    track(unloadBtn.MouseLeave:Connect(function()
        TweenService:Create(unloadBtn, EASE, {BackgroundColor3 = Color3.fromRGB(20, 18, 26)}):Play()
        TweenService:Create(unloadBtn, EASE, {TextColor3 = Color3.fromRGB(150, 120, 190)}):Play()
        TweenService:Create(uStroke,   EASE, {Color = Color3.fromRGB(45, 38, 58), Transparency = 0.2}):Play()
    end))

    local footer = Instance.new("Frame")
    footer.Size             = UDim2.new(1, 0, 0, 22)
    footer.Position         = UDim2.new(0, 0, 1, -22)
    footer.BackgroundColor3 = BG_HEADER
    footer.BorderSizePixel  = 0
    footer.ZIndex           = 2
    footer.Parent           = main

    local footTop = Instance.new("Frame")
    footTop.Size             = UDim2.new(1, 0, 0, 1)
    footTop.Position         = UDim2.new(0, 0, 0, 0)
    footTop.BackgroundColor3 = Color3.fromRGB(32, 28, 40)
    footTop.BorderSizePixel  = 0
    footTop.ZIndex           = 3
    footTop.Parent           = footer

    local status = Instance.new("TextLabel")
    status.Size                 = UDim2.new(1, -24, 1, 0)
    status.Position             = UDim2.new(0, 12, 0, 0)
    status.BackgroundTransparency = 1
    status.Text                 = "idle"
    status.TextColor3           = TXT_MUTED
    status.TextSize             = 10
    status.Font                 = Enum.Font.Code
    status.TextXAlignment       = Enum.TextXAlignment.Left
    status.ZIndex               = 4
    status.Parent               = footer

    local slideIn = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(main, slideIn, {Position = UDim2.new(0, 24, 0.5, -WINDOW_H/2)}):Play()

    fovSlider.apply(config.fov / 300)
    smoothSlider.apply(config.smoothness / 100)

    return {
        main      = main,
        shadow    = shadow,
        tAim      = tAim,
        fovSlider = fovSlider,
        smooth    = smoothSlider,
        status    = status,
        unloadBtn = unloadBtn,
        kbChip    = kbChip,
        kbStroke  = kbStroke,
        hideChip  = hideChip,
        hideStroke = hideStroke,
    }
end

local function hasLineOfSight(head)
    local filter = { Camera }
    if LocalPlayer.Character then
        table.insert(filter, LocalPlayer.Character)
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = filter

    local origin    = Camera.CFrame.Position
    local direction = head.Position - origin
    local hit       = workspace:Raycast(origin, direction, params)

    if not hit then return true end
    return hit.Instance:IsDescendantOf(head.Parent)
end

local function getTarget()
    local mouse = Camera.ViewportSize / 2
    local closest, shortest = nil, config.fov

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            local skip = false

            if config.teamCheck and player.Team == LocalPlayer.Team then
                skip = true
            end

            if head and not skip then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                    if dist < shortest then
                        if config.wallCheck and not hasLineOfSight(head) then
                            -- blocked, skip
                        else
                            shortest = dist
                            closest  = head
                        end
                    end
                end
            end
        end
    end

    return closest
end

local function onRender()
    local mouse = Camera.ViewportSize / 2

    if fovRing then
        local d = config.fov * 2
        fovRing.Size     = UDim2.new(0, d, 0, d)
        fovRing.Position = UDim2.new(0, mouse.X - config.fov, 0, mouse.Y - config.fov)
        fovRing.Visible  = config.enabled
    end

    local target = nil
    if config.enabled then
        target = getTarget()
        if target then
            local goal = CFrame.new(Camera.CFrame.Position, target.Position)
            local alpha = 1 - (config.smoothness / 100) * 0.95
            Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
        end
    end

    refreshChams()

    if ui and ui.status then
        local txt, col
        if selectingBind then
            txt = "press any key…"
            col = ACCENT_HI
        elseif config.enabled then
            if target then
                txt = string.format("locked · %d px", config.fov)
                col = ACCENT_HI
            else
                txt = "scanning…"
                col = TXT_DIM
            end
        else
            txt = "idle"
            col = TXT_MUTED
        end
        ui.status.Text       = txt
        ui.status.TextColor3 = col
    end
end

setLockState = function(state)
    config.enabled = state
    if ui and ui.tAim then
        ui.tAim.set(state)
    end
end

setHidden = function(hidden)
    config.hidden = hidden
    if not ui then return end
    ui.main.Visible   = not hidden
    ui.shadow.Visible = not hidden
end

local function unload()
    config.enabled = false

    clearChams()

    if fovRing then fovRing:Destroy() fovRing = nil end
    if gui then gui:Destroy() gui = nil end

    for _, conn in ipairs(connections) do
        if conn.Disconnect then conn:Disconnect() end
    end
    connections = {}
end

ui = buildUI()
buildRing(gui)
refreshChams()

-- slider drag
local activeSlider = nil

local function updateFromMouse(slider, mouseX)
    local bgX = slider.track.AbsolutePosition.X
    local bgW = slider.track.AbsoluteSize.X
    local rel = math.clamp((mouseX - bgX) / bgW, 0, 1)
    slider.apply(rel)
end

for _, slider in ipairs(sliders) do
    track(slider.hit.MouseButton1Down:Connect(function()
        activeSlider = slider
        updateFromMouse(slider, UserInputService:GetMouseLocation().X)
        TweenService:Create(slider.knob, EASE, {BackgroundColor3 = ACCENT_HI}):Play()
    end))
end

track(UserInputService.InputChanged:Connect(function(input)
    if activeSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateFromMouse(activeSlider, input.Position.X)
    end
end))

track(UserInputService.InputEnded:Connect(function(input)
    if activeSlider and input.UserInputType == Enum.UserInputType.MouseButton1 then
        TweenService:Create(activeSlider.knob, EASE, {BackgroundColor3 = Color3.fromRGB(230, 225, 240)}):Play()
        activeSlider = nil
    end
end))

track(ui.unloadBtn.MouseButton1Click:Connect(unload))

-- keybind rebind
local function beginRebind(which)
    if selectingBind then return end
    selectingBind = which
    if which == "toggle" then
        ui.kbChip.Text = "…"
        TweenService:Create(ui.kbStroke, EASE, {Color = ACCENT_HI, Transparency = 0}):Play()
    else
        ui.hideChip.Text = "…"
        TweenService:Create(ui.hideStroke, EASE, {Color = ACCENT_HI, Transparency = 0}):Play()
    end
end

local function endRebind()
    selectingBind = nil
    ui.kbChip.Text   = bindLabel(config.keybind)
    ui.hideChip.Text = bindLabel(config.hideKey)
    TweenService:Create(ui.kbStroke,   EASE, {Color = Color3.fromRGB(52, 42, 68), Transparency = 0}):Play()
    TweenService:Create(ui.hideStroke, EASE, {Color = Color3.fromRGB(52, 42, 68), Transparency = 0}):Play()
end

track(ui.kbChip.MouseButton1Click:Connect(function()
    beginRebind("toggle")
end))

track(ui.hideChip.MouseButton1Click:Connect(function()
    beginRebind("hide")
end))

track(UserInputService.InputBegan:Connect(function(input, processed)
    -- rebind capture
    if selectingBind then
        if input.KeyCode == Enum.KeyCode.Escape then
            endRebind()
            return
        end

        if input.KeyCode ~= Enum.KeyCode.Unknown then
            if selectingBind == "toggle" then
                config.keybind = input.KeyCode
            else
                config.hideKey = input.KeyCode
            end
            endRebind()
            return
        end

        if isMouseInput(input) then
            if selectingBind == "toggle" then
                config.keybind = input.UserInputType
            else
                config.hideKey = input.UserInputType
            end
            endRebind()
            return
        end

        return
    end

    if processed then return end

    -- hide key fires regardless of state
    if inputMatches(input, config.hideKey) then
        setHidden(not config.hidden)
        return
    end

    -- toggle key
    if inputMatches(input, config.keybind) then
        setLockState(not config.enabled)
    end
end))

track(RunService.RenderStepped:Connect(onRender))
