-- velk 1.248
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local TPS = game:GetService("TeleportService")
local SS = game:GetService("SoundService")
local MPS = game:GetService("MarketplaceService")
local Http = game:GetService("HttpService")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local LP = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")

for _, n in ipairs({"velk_1_248","velk_1_248_Notifs","velk_1_248_ESP","velk_1_248_Vig","velk_1_248_Key"}) do
    local e = PGui:FindFirstChild(n); if e then e:Destroy() end
end
for _, s in ipairs({"CUI_Mouse","CUI_Light","CUI_FOV","CUI_ESPDraw","CUI_Freecam","CUI_FPS","CUI_LockCam","CUI_SoundMute","CUI_Inspector"}) do
    pcall(function() RS:UnbindFromRenderStep(s) end)
end
for _, d in ipairs(workspace:GetDescendants()) do
    if d.Name == "CUI_RakeHL" or d.Name == "velk_InspectorClone" then
        pcall(function() d:Destroy() end)
    end
end

local Conn, Steps, running = {}, {}, true
local function T(c) table.insert(Conn, c); return c end
local function B(n, p, f) table.insert(Steps, n); RS:BindToRenderStep(n, p, f) end

local PALETTE_DARK = { Bg=Color3.fromRGB(12,12,12), Sec=Color3.fromRGB(18,18,18), Hov=Color3.fromRGB(28,28,28),
    Brd=Color3.fromRGB(65,65,65), BrdL=Color3.fromRGB(100,100,100), Txt=Color3.fromRGB(230,230,230),
    TxtD=Color3.fromRGB(148,148,148), Off=Color3.fromRGB(26,26,26) }
local PALETTE_LIGHT = { Bg=Color3.fromRGB(240,240,245), Sec=Color3.fromRGB(225,225,232), Hov=Color3.fromRGB(210,210,220),
    Brd=Color3.fromRGB(180,180,190), BrdL=Color3.fromRGB(140,140,155), Txt=Color3.fromRGB(20,20,25),
    TxtD=Color3.fromRGB(90,90,105), Off=Color3.fromRGB(200,200,210) }
local THEME = { Dark = true, Acc=Color3.fromRGB(0,120,215),
    OK=Color3.fromRGB(70,180,100), Warn=Color3.fromRGB(220,170,50), Err=Color3.fromRGB(210,70,70),
    F=Enum.Font.SourceSans, FB=Enum.Font.SourceSansBold }
local TH = {}
local themed = {}

local function applyTheme()
    local p = THEME.Dark and PALETTE_DARK or PALETTE_LIGHT
    for k, v in pairs(p) do TH[k] = v end
    TH.Acc = THEME.Acc; TH.OK = THEME.OK; TH.Warn = THEME.Warn; TH.Err = THEME.Err
    TH.F = THEME.F; TH.FB = THEME.FB
    for _, e in ipairs(themed) do
        pcall(function()
            if e.fn then e.inst[e.prop] = e.fn()
            else e.inst[e.prop] = TH[e.role] end
        end)
    end
end
applyTheme()

local function themeIt(inst, prop, role, fn)
    table.insert(themed, { inst=inst, prop=prop, role=role, fn=fn })
    return inst
end

local function I(c, p)
    local i = Instance.new(c); local par = p.Parent; p.Parent = nil
    for k, v in pairs(p) do i[k] = v end
    if par then i.Parent = par end
    return i
end
local function Tw(i, d, p, s, dir)
    local t = TS:Create(i, TweenInfo.new(d, s or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), p)
    t:Play(); return t
end
local function St(p, c, th)
    local s = I("UIStroke", { Color=c or TH.Brd, Thickness=th or 1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=p })
    if not c then themeIt(s, "Color", "Brd") end
    return s
end

local HAS_DRAWING = (typeof(Drawing) == "table") and (typeof(Drawing.new) == "function")

-- Search
local SEARCH = { rows = {}, aliases = {
    ["Enforce Daylight"] = "fullbright bright light day lit",
    ["Remove Blur / DoF"] = "blur dof depth field blurry",
    ["Remove Post-FX"] = "postfx post fx",
    ["Disable Global Shadows"] = "shadows shadow dark",
    ["No Fog"] = "fog mist",
    ["Remove Atmosphere"] = "atmosphere haze",
    ["Remove Sky"] = "sky skybox",
    ["Force Third Person"] = "thirdperson third person camera zoom tp",
    ["Enforce FOV"] = "fov field of view zoom camera",
    ["Field of View"] = "fov field of view camera",
    ["Freecam"] = "free cam noclip camera fly",
    ["Lock Camera Angle"] = "lock camera angle freeze",
    ["2D Box"] = "box esp 2d",
    ["Name Tags"] = "name nametag nameplate",
    ["Distance Text"] = "distance studs meters",
    ["Tracer Lines"] = "tracer lines laser",
    ["Skeleton ESP"] = "skeleton bones",
    ["Head Dot"] = "head dot circle",
    ["Look-Direction Arrow"] = "look arrow direction facing",
    ["Sound ESP"] = "sound audio noise",
    ["Off-Screen Arrows"] = "offscreen arrow behind",
    ["Enable Chams"] = "chams esp highlight",
    ["See Through Walls"] = "seethrough wall xray",
    ["Rainbow / Pulsing"] = "rainbow pulse animated",
    ["Outline-Only Mode"] = "outline only",
    ["Mute All Game Sounds"] = "mute sound audio silence",
    ["Force Red Highlight"] = "rake red highlight",
    ["Proximity Alarm"] = "rake alarm close near",
    ["Movement Prediction"] = "rake predict trajectory velocity",
    ["UI Scale"] = "ui scale size",
    ["Dark Theme"] = "theme dark light mode",
    ["Material Override"] = "material override forcefield neon",
    ["Remove Particles"] = "particles fire smoke sparkles trail",
    ["Remove Decals"] = "decals textures signs art",
} }
local function searchable(row, label, section)
    local text = label:lower() .. " " .. ((SEARCH.aliases[label] or ""):lower())
    table.insert(SEARCH.rows, { row = row, text = text, section = section })
end

-- Notifications
local NG = I("ScreenGui", { Name="velk_1_248_Notifs", ResetOnSpawn=false, DisplayOrder=1000000, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Parent=PGui })
local NH = I("Frame", { BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0), Position=UDim2.new(1,-16,0,48), Size=UDim2.new(0,340,1,-64), Parent=NG })
I("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, HorizontalAlignment=Enum.HorizontalAlignment.Right, VerticalAlignment=Enum.VerticalAlignment.Top, Padding=UDim.new(0,6), Parent=NH })
local nOrder, nActive = 0, {}
local MAX_NOTIFS = 6
local NCOL = { info=TH.Acc, ok=TH.OK, warn=TH.Warn, err=TH.Err }
local rakeCard, rakeCardTitle, rakeCardMsg = nil, nil, nil

local function killCard(c)
    if not c or not c.Parent then return end
    for i = #nActive, 1, -1 do if nActive[i] == c then table.remove(nActive, i) end end
    c:Destroy()
    if c == rakeCard then rakeCard, rakeCardTitle, rakeCardMsg = nil, nil, nil end
end

local function makeCard(title, msg, kind, layoutOrder, isRake)
    local acc = NCOL[kind] or NCOL.info
    local lines = 1
    if msg and #msg > 0 then lines = math.max(1, math.ceil(#msg / 44)) end
    local baseH = isRake and 50 or 30
    local lineH = isRake and 16 or 14
    local card = I("CanvasGroup", { BackgroundColor3=TH.Sec, BorderSizePixel=0, Size=UDim2.new(1,0,0, baseH + lines*lineH), GroupTransparency=1, LayoutOrder=layoutOrder, Parent=NH })
    themeIt(card, "BackgroundColor3", "Sec")
    St(card)
    I("Frame", { BackgroundColor3=acc, BorderSizePixel=0, Size=UDim2.new(0,isRake and 4 or 3,1,0), Parent=card })
    local tl = I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0,10,0,5), Size=UDim2.new(1,-16,0,isRake and 22 or 18), Font=TH.FB, Text=title, TextColor3=isRake and TH.Err or TH.Txt, TextSize=isRake and 17 or 14, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, Parent=card })
    if not isRake then themeIt(tl, "TextColor3", "Txt") end
    local ml = I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0,10,0, isRake and 28 or 24), Size=UDim2.new(1,-16,1,-30), Font=TH.F, Text=msg or "", TextColor3=isRake and TH.Warn or TH.TxtD, TextSize=isRake and 13 or 12, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top, TextWrapped=true, Parent=card })
    if not isRake then themeIt(ml, "TextColor3", "TxtD") end
    table.insert(nActive, card)
    Tw(card, 0.22, { GroupTransparency=0 }, Enum.EasingStyle.Quart)
    return card, tl, ml
end

local function Notify(title, msg, kind, dur)
    kind = kind or "info"; dur = dur or 2.5
    nOrder = nOrder + 1
    while #nActive >= MAX_NOTIFS do
        local victim = nil
        for _, c in ipairs(nActive) do if c ~= rakeCard then victim = c; break end end
        if not victim then break end
        killCard(victim)
    end
    local card = makeCard(title, msg, kind, nOrder + 1000, false)
    task.delay(dur, function()
        if not card.Parent then return end
        local t = Tw(card, 0.24, { GroupTransparency=1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Connect(function() killCard(card) end)
        task.delay(1, function() killCard(card) end)
    end)
    return card
end

local function RakeAlert(title, msg)
    if rakeCard and rakeCard.Parent then
        if rakeCardTitle then rakeCardTitle.Text = title end
        if rakeCardMsg then rakeCardMsg.Text = msg end
    else
        rakeCard, rakeCardTitle, rakeCardMsg = makeCard(title, msg, "err", 0, true)
    end
end
local function ClearRakeAlert()
    if rakeCard then killCard(rakeCard) end
    rakeCard, rakeCardTitle, rakeCardMsg = nil, nil, nil
end

-- KEY GATE
do
    local KEY_FILE          = "velk_1_248_key.txt"
    local KEY_VALID_SECONDS = 24 * 60 * 60
    local CORRECT_KEY       = "x4axq_hn23"
    local MAX_ATTEMPTS      = 6
    local GET_KEY_URL       = "https://unlk.link/PIxmw"

    local function readStoredKey()
        if typeof(readfile) ~= "function" then return nil, 0 end
        local ok, content = pcall(readfile, KEY_FILE)
        if not ok or type(content) ~= "string" then return nil, 0 end
        local k, ts = content:match("^(.-)|(%d+)$")
        return k, tonumber(ts) or 0
    end

    local function writeStoredKey(key)
        if typeof(writefile) ~= "function" then return end
        pcall(writefile, KEY_FILE, key .. "|" .. tostring(os.time()))
    end

    local function storedKeyIsValid()
        local k, ts = readStoredKey()
        if k ~= CORRECT_KEY then return false end
        if os.time() - ts > KEY_VALID_SECONDS then return false end
        return true
    end

    if not storedKeyIsValid() then
        local oldPrompt = PGui:FindFirstChild("velk_1_248_Key")
        if oldPrompt then oldPrompt:Destroy() end

        local signal   = Instance.new("BindableEvent")
        local attempts = 0

        local gui = I("ScreenGui", {
            Name = "velk_1_248_Key", ResetOnSpawn = false,
            DisplayOrder = 2000000, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = PGui,
        })

        I("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4,
            BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), Parent = gui,
        })

        local card = I("Frame", {
            BackgroundColor3 = Color3.fromRGB(18, 18, 18), BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 380, 0, 280), Parent = gui,
        })
        St(card)

        I("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0, 18), Size = UDim2.new(1, -36, 0, 26),
            Font = TH.FB, Text = "Enter Key",
            TextColor3 = Color3.fromRGB(230, 230, 230), TextSize = 20,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
        })

        I("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0, 48), Size = UDim2.new(1, -36, 0, 18),
            Font = TH.F, Text = "Required every 24 hours.",
            TextColor3 = Color3.fromRGB(148, 148, 148), TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
        })

        local box = I("TextBox", {
            BackgroundColor3 = Color3.fromRGB(26, 26, 26), BorderSizePixel = 0,
            Position = UDim2.new(0, 18, 0, 80), Size = UDim2.new(1, -36, 0, 34),
            Font = TH.F, Text = "",
            PlaceholderText = "paste key here",
            PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
            TextColor3 = Color3.fromRGB(230, 230, 230), TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false, Parent = card,
        })
        St(box)
        I("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = box })

        local statusLbl = I("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0, 122), Size = UDim2.new(1, -36, 0, 18),
            Font = TH.F, Text = "",
            TextColor3 = Color3.fromRGB(210, 70, 70), TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = false, Parent = card,
        })

        local submitBtn = I("TextButton", {
            BackgroundColor3 = Color3.fromRGB(0, 120, 215), BorderSizePixel = 0,
            Position = UDim2.new(0, 18, 0, 150), Size = UDim2.new(1, -36, 0, 38),
            Font = TH.FB, Text = "Submit Key",
            TextColor3 = Color3.new(1, 1, 1), TextSize = 14,
            AutoButtonColor = false, Parent = card,
        })

        local getBtn = I("TextButton", {
            BackgroundColor3 = Color3.fromRGB(26, 26, 26), BorderSizePixel = 0,
            Position = UDim2.new(0, 18, 0, 196), Size = UDim2.new(1, -36, 0, 34),
            Font = TH.F, Text = "Get Key",
            TextColor3 = Color3.fromRGB(230, 230, 230), TextSize = 13,
            AutoButtonColor = false, Parent = card,
        })
        St(getBtn)

        I("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 0, 238), Size = UDim2.new(1, -36, 0, 18),
            Font = TH.F, Text = GET_KEY_URL,
            TextColor3 = Color3.fromRGB(120, 120, 120), TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
        })

        submitBtn.MouseEnter:Connect(function()
            Tw(submitBtn, 0.1, { BackgroundColor3 = Color3.fromRGB(20, 140, 235) })
        end)
        submitBtn.MouseLeave:Connect(function()
            Tw(submitBtn, 0.1, { BackgroundColor3 = Color3.fromRGB(0, 120, 215) })
        end)
        getBtn.MouseEnter:Connect(function()
            Tw(getBtn, 0.1, { BackgroundColor3 = Color3.fromRGB(40, 40, 40) })
        end)
        getBtn.MouseLeave:Connect(function()
            Tw(getBtn, 0.1, { BackgroundColor3 = Color3.fromRGB(26, 26, 26) })
        end)

        local function tryOpenBrowser(url)
            local candidates = {
                function() return openbrowser(url) end,
                function() return openbrowserwindow(url) end,
                function() return openurl(url) end,
                function() return executor.openbrowser(url) end,
                function() return executor.open_url(url) end,
            }
            for _, f in ipairs(candidates) do
                if pcall(f) then return true end
            end
            return false
        end

        getBtn.MouseButton1Click:Connect(function()
            if tryOpenBrowser(GET_KEY_URL) then return end
            local copied = false
            if typeof(setclipboard) == "function" then
                copied = pcall(setclipboard, GET_KEY_URL)
            end
            statusLbl.TextColor3 = copied and TH.OK or TH.Warn
            statusLbl.Text = copied
                and "Browser blocked — link copied to clipboard."
                or ("Copy manually: " .. GET_KEY_URL)
            statusLbl.Visible = true
        end)

        local function attemptSubmit()
            local entered = (box.Text or ""):match("^%s*(.-)%s*$")
            if entered == CORRECT_KEY then
                writeStoredKey(entered)
                signal:Fire(true)
                return
            end

            attempts = attempts + 1
            if attempts >= MAX_ATTEMPTS then
                pcall(function() LP:Kick("Invalid key — 6 failed attempts.") end)
                signal:Fire(false)
                return
            end
            local left = MAX_ATTEMPTS - attempts
            statusLbl.TextColor3 = TH.Err
            statusLbl.Text = string.format(
                "Invalid key. %d attempt%s remaining.", left, left == 1 and "" or "s")
            statusLbl.Visible = true
            box.Text = ""
        end

        submitBtn.MouseButton1Click:Connect(attemptSubmit)
        box.FocusLost:Connect(function(enter) if enter then attemptSubmit() end end)

        local passed = signal.Event:Wait()
        gui:Destroy()
        signal:Destroy()

        if not passed then
            return
        end
    end
end

-- Registries
local ToggleReg, SliderReg, ALL_CHECKS, RECENT = {}, {}, {}, {}
local recentUI = nil
local function pushRecent(label)
    for i = #RECENT, 1, -1 do if RECENT[i] == label then table.remove(RECENT, i) end end
    table.insert(RECENT, 1, label)
    while #RECENT > 5 do table.remove(RECENT) end
    if recentUI and recentUI.update then recentUI.update() end
end

-- Tooltip
local tooltipFrame = nil
local function ensureTooltip(parent)
    if tooltipFrame then return tooltipFrame end
    tooltipFrame = I("TextLabel", { BackgroundColor3=Color3.fromRGB(20,20,20), BorderSizePixel=0,
        TextColor3=Color3.fromRGB(240,240,240), Font=TH.F, TextSize=12, TextWrapped=true, Visible=false,
        ZIndex=9999, Size=UDim2.new(0,220,0,40), Parent=parent })
    St(tooltipFrame, Color3.fromRGB(90,90,90), 1)
    I("UIPadding", { PaddingTop=UDim.new(0,5), PaddingBottom=UDim.new(0,5), PaddingLeft=UDim.new(0,7), PaddingRight=UDim.new(0,7), Parent=tooltipFrame })
    return tooltipFrame
end
local function showTooltip(text, parent)
    local host = parent or PGui:FindFirstChild("velk_1_248")
    if not host then return end
    local tf = ensureTooltip(host)
    tf.Text = text; tf.Visible = true
    local h = 24 + math.max(1, math.ceil(#text / 32)) * 14
    tf.Size = UDim2.new(0, 220, 0, h)
    local pos = UIS:GetMouseLocation()
    tf.Position = UDim2.fromOffset(pos.X + 16, pos.Y + 16)
end
local function hideTooltip()
    if tooltipFrame then tooltipFrame.Visible = false end
end
T(UIS.InputChanged:Connect(function()
    if tooltipFrame and tooltipFrame.Visible then
        local pos = UIS:GetMouseLocation()
        tooltipFrame.Position = UDim2.fromOffset(pos.X + 16, pos.Y + 16)
    end
end))

local function makeInfoIcon(parent, tooltipText)
    local btn = I("TextButton", { BackgroundColor3=TH.Off, BorderSizePixel=0,
        AnchorPoint=Vector2.new(1,0.5), Position=UDim2.new(1,-2,0.5,0), Size=UDim2.new(0,14,0,14),
        Font=TH.FB, Text="i", TextColor3=THEME.Acc, TextSize=11, AutoButtonColor=false, ZIndex=5, Parent=parent })
    themeIt(btn, "BackgroundColor3", "Off")
    I("UIStroke", { Color=THEME.Acc, Thickness=1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Parent=btn })
    I("UICorner", { CornerRadius=UDim.new(1,0), Parent=btn })
    btn.MouseEnter:Connect(function()
        Tw(btn, 0.12, { BackgroundColor3 = THEME.Acc })
        Tw(btn, 0.12, { TextColor3 = Color3.new(1,1,1) })
        showTooltip(tooltipText, PGui:FindFirstChild("velk_1_248"))
    end)
    btn.MouseLeave:Connect(function()
        Tw(btn, 0.12, { BackgroundColor3 = TH.Off })
        Tw(btn, 0.12, { TextColor3 = THEME.Acc })
        hideTooltip()
    end)
    return btn
end

-- Widgets
local function Checkbox(parent, label, default, cb, order, keep, regName, tooltip)
    local row = I("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,20), LayoutOrder=order or 0, Parent=parent })
    local box = I("TextButton", { BackgroundColor3=default and THEME.Acc or TH.Off, BorderSizePixel=0,
        Position=UDim2.new(0,0,0,3), Size=UDim2.new(0,14,0,14), Text="", AutoButtonColor=false, Parent=row })
    St(box, TH.BrdL, 1)
    local hasIcon = tooltip ~= nil
    local lbl = I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0,22,0,0),
        Size=UDim2.new(1, hasIcon and -44 or -22, 1, 0), Font=TH.F, Text=label,
        TextColor3=TH.Txt, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd, Parent=row })
    themeIt(lbl, "TextColor3", "Txt")
    if hasIcon then makeInfoIcon(row, tooltip) end
    local state = default
    themeIt(box, "BackgroundColor3", nil, function() return state and THEME.Acc or TH.Off end)
    local function set(s, silent)
        if state == s and silent ~= true then return end
        state = s
        Tw(box, 0.12, { BackgroundColor3=s and THEME.Acc or TH.Off })
        if cb and not silent then cb(s) end
        if not silent then pushRecent(label) end
    end
    table.insert(ALL_CHECKS, { set=set, keep=keep == true, label=label, row=row })
    if regName then ToggleReg[regName] = { get = function() return state end, set = set } end
    box.MouseButton1Click:Connect(function() set(not state) end)
    lbl.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            set(not state)
        end
    end)
    searchable(row, label, nil)
    return row, set
end

local function Slider(parent, label, min, max, default, cb, order, regName, tooltip)
    local wrap = I("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,38), LayoutOrder=order or 0, Parent=parent })
    local lblFrame = I("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,16), Parent=wrap })
    I("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1, tooltip and -22 or 0, 1, 0),
        Font=TH.F, Text=label, TextColor3=TH.Txt, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=lblFrame }).TextColor3 = TH.Txt
    if tooltip then makeInfoIcon(lblFrame, tooltip) end
    local bar = I("Frame", { BackgroundColor3=TH.Off, BorderSizePixel=0,
        Position=UDim2.new(0,0,0,17), Size=UDim2.new(1,0,0,18), Parent=wrap })
    themeIt(bar, "BackgroundColor3", "Off")
    St(bar, TH.BrdL, 1)
    local fill = I("Frame", { BackgroundColor3=THEME.Acc, BorderSizePixel=0, Size=UDim2.new(0,0,1,0), ZIndex=1, Parent=bar })
    themeIt(fill, "BackgroundColor3", "Acc")
    local vLbl = I("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
        Font=TH.F, Text=tostring(default).."/"..tostring(max), TextColor3=TH.Txt, TextSize=13, ZIndex=2, Parent=bar })
    themeIt(vLbl, "TextColor3", "Txt")
    local value = default
    local function setValue(v, silent, animate)
        value = math.clamp(math.floor(v+0.5), min, max)
        local rel = (value-min)/(max-min)
        local target = UDim2.new(rel,0,1,0)
        if animate then Tw(fill, 0.18, { Size=target }) else fill.Size = target end
        vLbl.Text = tostring(value).."/"..tostring(max)
        if cb and not silent then cb(value) end
    end
    setValue(default, true)
    if regName then SliderReg[regName] = { get = function() return value end, set = setValue } end
    local drag = false
    local function upX(x)
        if bar.AbsoluteSize.X <= 0 then return end
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        setValue(min + rel*(max-min))
    end
    bar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true; upX(inp.Position.X)
        end
    end)
    T(UIS.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            upX(inp.Position.X)
        end
    end))
    T(UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end))
    searchable(wrap, label, nil)
    return wrap, setValue
end

local function TextInput(parent, label, default, cb, order, regName)
    local wrap = I("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,46), LayoutOrder=order or 0, Parent=parent })
    I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,16),
        Font=TH.F, Text=label, TextColor3=TH.Txt, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=wrap }).TextColor3 = TH.Txt
    local box = I("TextBox", { BackgroundColor3=TH.Off, BorderSizePixel=0,
        Position=UDim2.new(0,0,0,20), Size=UDim2.new(1,0,0,22), Font=TH.F,
        Text=default or "", TextColor3=TH.Txt, TextSize=13, PlaceholderText="…",
        PlaceholderColor3=TH.TxtD, TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=false, Parent=wrap })
    themeIt(box, "BackgroundColor3", "Off")
    themeIt(box, "TextColor3", "Txt")
    themeIt(box, "PlaceholderColor3", "TxtD")
    St(box, TH.BrdL, 1)
    I("UIPadding", { PaddingLeft=UDim.new(0,6), Parent=box })
    box.FocusLost:Connect(function(enter) if enter and cb then cb(box.Text) end end)
    if regName then
        SliderReg[regName] = { get = function() return box.Text end,
            set = function(v, s) box.Text = tostring(v); if cb and not s then cb(tostring(v)) end end }
    end
    searchable(wrap, label, nil)
    return wrap, box
end

local function Button(parent, label, cb, order, height, width, xpos)
    local b = I("TextButton", { BackgroundColor3=TH.Sec, BorderSizePixel=0,
        Size=width or UDim2.new(1,0,0,height or 24), Position=xpos or UDim2.new(0,0,0,0),
        Font=TH.F, Text=label, TextColor3=TH.Txt, TextSize=13, AutoButtonColor=false,
        LayoutOrder=order or 0, Parent=parent })
    themeIt(b, "BackgroundColor3", "Sec")
    themeIt(b, "TextColor3", "Txt")
    St(b, TH.BrdL, 1)
    b.MouseEnter:Connect(function() Tw(b, 0.1, { BackgroundColor3=TH.Hov }) end)
    b.MouseLeave:Connect(function() Tw(b, 0.1, { BackgroundColor3=TH.Sec }) end)
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
    return b
end

local function Collapsible(parent, title, startOpen, order)
    local sec = I("Frame", { BackgroundColor3=TH.Sec, BorderSizePixel=0, Size=UDim2.new(1,0,0,22),
        AutomaticSize=Enum.AutomaticSize.Y, LayoutOrder=order or 0, Parent=parent })
    themeIt(sec, "BackgroundColor3", "Sec")
    St(sec)
    local head = I("TextButton", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,22), Text="", AutoButtonColor=false, Parent=sec })
    I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0,8,0,0), Size=UDim2.new(1,-30,1,0),
        Font=TH.FB, Text=title, TextColor3=TH.Txt, TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=head }).TextColor3 = TH.Txt
    local tog = I("TextButton", { BackgroundTransparency=1, AnchorPoint=Vector2.new(1,0.5),
        Position=UDim2.new(1,-6,0.5,0), Size=UDim2.new(0,18,0,18),
        Font=TH.FB, Text="−", TextColor3=THEME.Acc, TextSize=16, AutoButtonColor=false, Parent=head })
    local content = I("Frame", { BackgroundTransparency=1, Position=UDim2.new(0,0,0,22),
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, Visible=startOpen, Parent=sec })
    I("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4), Parent=content })
    I("UIPadding", { PaddingBottom=UDim.new(0,10), PaddingLeft=UDim.new(0,10),
        PaddingRight=UDim.new(0,10), PaddingTop=UDim.new(0,6), Parent=content })
    local open = startOpen
    local function setOpen(s) open = s; content.Visible = open; tog.Text = open and "−" or "+" end
    setOpen(startOpen)
    head.MouseButton1Click:Connect(function() setOpen(not open) end)
    return sec, content, setOpen
end

local function Section(parent, title, order)
    local sec = I("Frame", { BackgroundColor3=TH.Sec, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        LayoutOrder=order or 0, Parent=parent })
    themeIt(sec, "BackgroundColor3", "Sec")
    St(sec)
    local content = I("Frame", { BackgroundTransparency=1, Position=UDim2.new(0,0,0,24),
        Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, Parent=sec })
    I("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4), Parent=content })
    I("UIPadding", { PaddingBottom=UDim.new(0,10), PaddingLeft=UDim.new(0,10),
        PaddingRight=UDim.new(0,10), PaddingTop=UDim.new(0,6), Parent=content })
    if title then
        I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0,8,0,4),
            Size=UDim2.new(1,-16,0,18), Font=TH.FB, Text=title,
            TextColor3=TH.Txt, TextSize=14,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=sec }).TextColor3 = TH.Txt
    end
    return sec, content
end

-- State
local S = {
    lighting = { orig=nil, day=false, noFog=false, noShadows=false, noAtmo=false, noPostFX=false,
                 noBlur=true, tod=14, ambCol=Color3.fromRGB(140,140,140),
                 fogCol=Color3.fromRGB(192,192,192), fogStart=0, fogEnd=1000,
                 noSky=false, vig=false, cc=nil, skyOrig={}, cc_sat=0, cc_con=0 },
    render = { noParticles=false, noDecals=false, matOverride=false, matName="ForceField",
               noShadowCast=false, noDecor=false, noWater=false,
               noOtherAcc=false, noOwnAcc=false,
               originals={}, decalOrig={}, shadowOrig={}, partOrig={}, wOrig={} },
    camera = { tp=false, maxZoom=128, minZoom=0.5, fovOverride=false, fov=75,
               roll=0, freecam=false, lockAngle=false, lockCF=nil, _state={},
               fcYaw=0, fcPitch=0, fcPos=nil },
    esp = { box2d=false, name=false, dist=false, tracer=false, skeleton=false,
            headDot=false, lookArrow=false, sound=false, offscreen=false,
            boxCol=Color3.fromRGB(0,255,0), nameCol=Color3.fromRGB(255,255,255),
            tracerCol=Color3.fromRGB(0,255,0), skelCol=Color3.fromRGB(255,255,255),
            soundCol=Color3.fromRGB(255,80,80), offCol=Color3.fromRGB(255,80,80),
            maxDist=1000 },
    chams = { on=false, seeThrough=true, fill=0.5, includeSelf=false,
              rainbow=false, outlineOnly=false,
              pCol=Color3.fromRGB(0,255,0), oCol=Color3.fromRGB(0,200,0),
              hl={}, conns={} },
    shift = { on=false },
    fc    = { speed=50 },
    sound = { muted=false, musicOn=false, musicId="", musicVol=0.5, musicObj=nil, origVol={}, origSG={} },
    qol   = { uiScale=1 },
    rake  = { forceRed=true, track=false, showDist=true, alarm=false, alarmDist=60,
              targetingNotify=true, predict=true, bloodHourNotify=true,
              lastAlarm=0, _targeted=false,
              hlRef=nil, hlFill=0.5, modelRef=nil, lastScan=0, scanInterval=0.5,
              posHistory={}, lastSample=0 },
    keys  = { toggleUI=Enum.KeyCode.RightShift, freeMouse=Enum.KeyCode.RightControl,
              shiftlock=Enum.KeyCode.RightAlt, freecam=Enum.KeyCode.LeftAlt,
              unload=Enum.KeyCode.Delete, freecamToggle=Enum.KeyCode.C },
    _listening = false,
    _suppressNextKey = false,
    inspecting = false,
}

local DrawESP = { boxes = {}, skeletons = {}, traj = {}, available = HAS_DRAWING }
local SKEL_CONNECTIONS = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}
local function makeBoxFor(char)
    if not HAS_DRAWING then return nil end
    if DrawESP.boxes[char] then return DrawESP.boxes[char] end
    local box = Drawing.new("Square"); box.Thickness = 1; box.Filled = false
    box.Transparency = 1; box.Color = S.esp.boxCol; box.Visible = false
    DrawESP.boxes[char] = box; return box
end
local function destroyBoxFor(char)
    local b = DrawESP.boxes[char]
    if b then pcall(function() b:Remove() end); DrawESP.boxes[char] = nil end
end
local function makeSkeletonFor(char)
    if not HAS_DRAWING then return nil end
    if DrawESP.skeletons[char] then return DrawESP.skeletons[char] end
    local list = {}
    for i = 1, #SKEL_CONNECTIONS do
        local line = Drawing.new("Line"); line.Thickness = 1
        line.Color = S.esp.skelCol; line.Transparency = 1; line.Visible = false
        table.insert(list, line)
    end
    DrawESP.skeletons[char] = list; return list
end
local function destroySkeletonFor(char)
    local list = DrawESP.skeletons[char]
    if list then
        for _, line in ipairs(list) do pcall(function() line:Remove() end) end
        DrawESP.skeletons[char] = nil
    end
end
local function makeTrajFor(char)
    if not HAS_DRAWING then return nil end
    if DrawESP.traj[char] then return DrawESP.traj[char] end
    local lines = {}
    for i = 1, 3 do
        local line = Drawing.new("Line"); line.Thickness = 2
        line.Color = Color3.fromRGB(255, 60, 60); line.Transparency = 0.6; line.Visible = false
        table.insert(lines, line)
    end
    DrawESP.traj[char] = lines; return lines
end
local function destroyTrajFor(char)
    local list = DrawESP.traj[char]
    if list then
        for _, line in ipairs(list) do pcall(function() line:Remove() end) end
        DrawESP.traj[char] = nil
    end
end

-- Lighting
local POSTFX = { ColorCorrectionEffect=true, BloomEffect=true, BlurEffect=true, SunRaysEffect=true, DepthOfFieldEffect=true }
local BLUR = { BlurEffect=true, DepthOfFieldEffect=true }
local function captureLight()
    if S.lighting.orig then return end
    local o = { Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient, Brightness=Lighting.Brightness, ClockTime=Lighting.ClockTime,
                GlobalShadows=Lighting.GlobalShadows, FogEnd=Lighting.FogEnd, FogStart=Lighting.FogStart, FogColor=Lighting.FogColor,
                ExposureCompensation=Lighting.ExposureCompensation, AtmoDensity={}, FX={}, Blur={} }
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA("Atmosphere") then o.AtmoDensity[c]=c.Density end
        if POSTFX[c.ClassName] then o.FX[c]=c.Enabled end
        if BLUR[c.ClassName] then o.Blur[c]=c.Enabled end
    end
    S.lighting.orig = o
end

local function applySky()
    local Lg = S.lighting
    if Lg.noSky then
        for _, c in ipairs(Lighting:GetChildren()) do
            if c:IsA("Sky") and not Lg.skyOrig[c] then
                Lg.skyOrig[c] = true
                c.Parent = nil
            end
        end
    else
        for c, _ in pairs(Lg.skyOrig) do
            if c then c.Parent = Lighting end
        end
        Lg.skyOrig = {}
    end
end

local function applyLight()
    captureLight()
    local o = S.lighting.orig; local Lg = S.lighting
    if Lg.day then
        Lighting.Brightness=2; Lighting.Ambient=Lg.ambCol; Lighting.OutdoorAmbient=Lg.ambCol
        Lighting.ExposureCompensation=0
    else
        Lighting.Brightness=o.Brightness; Lighting.Ambient=o.Ambient
        Lighting.OutdoorAmbient=o.OutdoorAmbient; Lighting.ExposureCompensation=o.ExposureCompensation
    end
    Lighting.GlobalShadows = Lg.noShadows and false or o.GlobalShadows
    Lighting.ClockTime = Lg.tod
    if Lg.noFog then Lighting.FogEnd=1e6; Lighting.FogStart=1e6
    else Lighting.FogEnd=Lg.fogEnd; Lighting.FogStart=Lg.fogStart; Lighting.FogColor=Lg.fogCol end
    for a, orig in pairs(o.AtmoDensity) do if a.Parent then a.Density = Lg.noAtmo and 0 or orig end end
    for fx, orig in pairs(o.FX) do if fx.Parent then
        if Lg.noPostFX then fx.Enabled = false
        elseif BLUR[fx.ClassName] and Lg.noBlur then fx.Enabled = false
        else fx.Enabled = orig end
    end end
    for fx, orig in pairs(o.Blur) do if fx.Parent then fx.Enabled = (Lg.noPostFX or Lg.noBlur) and false or orig end end
    applySky()
    if not Lg.cc then
        local cc = Instance.new("ColorCorrectionEffect"); cc.Name="CUI_CC"
        cc.Parent = Lighting; Lg.cc = cc
    end
    Lg.cc.Enabled = true; Lg.cc.Saturation = Lg.cc_sat; Lg.cc.Contrast = Lg.cc_con
end
local postFXCached = {}
for _, c in ipairs(Lighting:GetChildren()) do if POSTFX[c.ClassName] then table.insert(postFXCached, c) end end
T(Lighting.ChildAdded:Connect(function(c)
    captureLight()
    if c:IsA("Atmosphere") then
        S.lighting.orig.AtmoDensity[c] = c.Density
        if S.lighting.noAtmo then c.Density = 0 end
    end
    if c:IsA("Sky") then
        if S.lighting.noSky then S.lighting.skyOrig[c] = true; c.Parent = nil end
    end
    if POSTFX[c.ClassName] then
        S.lighting.orig.FX[c] = c.Enabled
        if BLUR[c.ClassName] then S.lighting.orig.Blur[c] = c.Enabled end
        if S.lighting.noPostFX or (BLUR[c.ClassName] and S.lighting.noBlur) then c.Enabled = false end
        table.insert(postFXCached, c)
    end
end))
T(Lighting.ChildRemoved:Connect(function(c)
    local o = S.lighting.orig
    if not o then return end
    if o.AtmoDensity then o.AtmoDensity[c] = nil end
    if o.FX then o.FX[c] = nil end
    if o.Blur then o.Blur[c] = nil end
    if S.lighting.skyOrig then S.lighting.skyOrig[c] = nil end
    for i = #postFXCached, 1, -1 do if postFXCached[i] == c then table.remove(postFXCached, i) end end
end))
B("CUI_Light", 100000, function()
    local Lg = S.lighting
    if Lg.day then
        if Lighting.Brightness~=2 then Lighting.Brightness=2 end
        if Lighting.Ambient~=Lg.ambCol then Lighting.Ambient=Lg.ambCol end
        if Lighting.OutdoorAmbient~=Lg.ambCol then Lighting.OutdoorAmbient=Lg.ambCol end
        if Lighting.ExposureCompensation~=0 then Lighting.ExposureCompensation=0 end
    end
    if Lighting.ClockTime~=Lg.tod then Lighting.ClockTime=Lg.tod end
    if Lg.noFog and Lighting.FogEnd~=1e6 then Lighting.FogEnd=1e6; Lighting.FogStart=1e6 end
    if Lg.noShadows and Lighting.GlobalShadows then Lighting.GlobalShadows=false end
    if Lg.noBlur or Lg.noPostFX then
        for i = #postFXCached, 1, -1 do
            local c = postFXCached[i]
            if not c.Parent then table.remove(postFXCached, i)
            else
                if BLUR[c.ClassName] and c.Enabled then c.Enabled = false end
                if Lg.noPostFX and c.Enabled then c.Enabled = false end
            end
        end
    end
end)

-- Sound
local function muteAllSounds()
    for _, sg in ipairs(SS:GetDescendants()) do
        if sg:IsA("SoundGroup") then
            if S.sound.origSG[sg] == nil then S.sound.origSG[sg] = sg.Volume end
            sg.Volume = 0
        end
    end
    for _, d in ipairs(game:GetDescendants()) do
        if d:IsA("Sound") and d.Name ~= "CUI_Music" then
            if S.sound.origVol[d] == nil then S.sound.origVol[d] = d.Volume end
            d.Volume = 0
        end
    end
end
local function unmuteAllSounds()
    for sg, v in pairs(S.sound.origSG) do if sg.Parent then pcall(function() sg.Volume = v end) end end
    S.sound.origSG = {}
    for d, v in pairs(S.sound.origVol) do if d.Parent then pcall(function() d.Volume = v end) end end
    S.sound.origVol = {}
end
B("CUI_SoundMute", 99995, function()
    if not S.sound.muted then return end
    for _, d in ipairs(SS:GetDescendants()) do
        if d:IsA("Sound") and d.Name ~= "CUI_Music" and d.Volume > 0 then
            if S.sound.origVol[d] == nil then S.sound.origVol[d] = d.Volume end
            d.Volume = 0
        end
        if d:IsA("SoundGroup") and d.Volume > 0 then
            if S.sound.origSG[d] == nil then S.sound.origSG[d] = d.Volume end
            d.Volume = 0
        end
    end
end)

-- Vignette
local vigGui = I("ScreenGui", { Name="velk_1_248_Vig", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=999995, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Parent=PGui })
local vigFrames = {}
for _, sd in ipairs({
    { name="top", pos=UDim2.new(0,0,0,0), size=UDim2.new(1,0,0,120), rot=90 },
    { name="bottom", pos=UDim2.new(0,0,1,-120), size=UDim2.new(1,0,0,120), rot=270 },
    { name="left", pos=UDim2.new(0,0,0,0), size=UDim2.new(0,120,1,0), rot=0 },
    { name="right", pos=UDim2.new(1,-120,0,0), size=UDim2.new(0,120,1,0), rot=180 },
}) do
    local f = I("Frame", { BackgroundColor3=Color3.new(0,0,0), BorderSizePixel=0, Position=sd.pos, Size=sd.size, Visible=false, Parent=vigGui })
    I("UIGradient", { Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}), Rotation=sd.rot, Parent=f })
    vigFrames[sd.name] = f
end

-- Rendering helpers
local function isDecal(c) return c:IsA("Decal") or c:IsA("Texture") end
local function isParticle(c) return c:IsA("ParticleEmitter") or c:IsA("Fire") or c:IsA("Smoke") or c:IsA("Sparkles") or c:IsA("Trail") end
local function applyMaterialOverride()
    local R = S.render
    if R.matOverride then
        local m = Enum.Material[R.matName] or Enum.Material.ForceField
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                if R.originals[d] == nil then R.originals[d] = d.Material end
                d.Material = m
            end
        end
    else
        for p, mat in pairs(R.originals) do if p.Parent then pcall(function() p.Material = mat end) end end
        R.originals = {}
    end
end
local function cycleMaterial()
    local mats = {"ForceField","Neon","Glass","Plastic","SmoothPlastic","Metal"}
    local i = 1; for k, m in ipairs(mats) do if m == S.render.matName then i = k end end
    i = (i % #mats) + 1; S.render.matName = mats[i]
    if S.render.matOverride then
        local m = Enum.Material[S.render.matName] or Enum.Material.ForceField
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                if S.render.originals[d] == nil then S.render.originals[d] = d.Material end
                d.Material = m
            end
        end
    end
    Notify("Material", S.render.matName, "info", 1.2)
end
local function toggleParticles(on)
    local R = S.render
    for _, d in ipairs(workspace:GetDescendants()) do
        if isParticle(d) then
            if on then if R.partOrig[d] == nil then R.partOrig[d] = d.Enabled end; d.Enabled = false
            elseif R.partOrig[d] ~= nil then d.Enabled = R.partOrig[d] end
        end
    end
    if not on then R.partOrig = {} end
end
local function toggleDecals(on)
    local R = S.render
    for _, d in ipairs(workspace:GetDescendants()) do
        if isDecal(d) then
            if on then if R.decalOrig[d] == nil then R.decalOrig[d] = d.Transparency end; d.Transparency = 1
            elseif R.decalOrig[d] ~= nil then d.Transparency = R.decalOrig[d] end
        end
    end
    if not on then R.decalOrig = {} end
end
local function toggleShadows(on)
    local R = S.render
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            if on then if R.shadowOrig[d] == nil then R.shadowOrig[d] = d.CastShadow end; d.CastShadow = false
            elseif R.shadowOrig[d] ~= nil then d.CastShadow = R.shadowOrig[d] end
        end
    end
    if not on then R.shadowOrig = {} end
end
local function applyWater()
    if not Terrain then return end
    if S.render.noWater then
        if not S.render.wOrig.Tr then
            S.render.wOrig = { Tr=Terrain.WaterTransparency, Col=Terrain.WaterColor, WS=Terrain.WaterWaveSize, WV=Terrain.WaterWaveSpeed }
        end
        Terrain.WaterTransparency = 1; Terrain.WaterWaveSize = 0
    else
        local o = S.render.wOrig
        if o.Tr then
            Terrain.WaterTransparency = o.Tr; Terrain.WaterColor = o.Col
            Terrain.WaterWaveSize = o.WS; Terrain.WaterWaveSpeed = o.WV
            S.render.wOrig = {}
        end
    end
end
local function stripAccessories(char)
    if not char then return end
    for _, c in ipairs(char:GetChildren()) do if c:IsA("Accessory") then c:Destroy() end end
end
T(LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if S.render.noOwnAcc then stripAccessories(char) end
end))
T(Players.PlayerAdded:Connect(function(p)
    if p == LP then return end
    p.CharacterAdded:Connect(function(char)
        if S.render.noOtherAcc then task.wait(0.5); stripAccessories(char) end
    end)
    if S.render.noOtherAcc and p.Character then stripAccessories(p.Character) end
end))

-- FOV
local function enforceFOV()
    local C = S.camera
    if not C.fovOverride then return end
    local cam = workspace.CurrentCamera
    if cam and cam.FieldOfView ~= C.fov then cam.FieldOfView = C.fov end
end
T(LP:GetPropertyChangedSignal("CameraMode"):Connect(function()
    if S.camera.tp and LP.CameraMode ~= Enum.CameraMode.Classic then
        LP.CameraMode = Enum.CameraMode.Classic
    end
end))
T(LP:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(function()
    if S.camera.tp and LP.CameraMaxZoomDistance ~= S.camera.maxZoom then
        LP.CameraMaxZoomDistance = S.camera.maxZoom
    end
end))
T(LP:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(function()
    if S.camera.tp and LP.CameraMinZoomDistance ~= S.camera.minZoom then
        LP.CameraMinZoomDistance = S.camera.minZoom
    end
end))
B("CUI_FOV", 2000, function()
    enforceFOV()
    local C = S.camera; local cam = workspace.CurrentCamera
    if not cam then return end
    if C.tp then
        if LP.CameraMode ~= Enum.CameraMode.Classic then LP.CameraMode = Enum.CameraMode.Classic end
        if LP.CameraMaxZoomDistance ~= C.maxZoom then LP.CameraMaxZoomDistance = C.maxZoom end
        if LP.CameraMinZoomDistance ~= C.minZoom then LP.CameraMinZoomDistance = C.minZoom end
    end
    if C.roll ~= 0 then cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, math.rad(C.roll)) end
end)
local function hookCameraFOV()
    local cam = workspace.CurrentCamera
    if not cam then return end
    T(cam:GetPropertyChangedSignal("FieldOfView"):Connect(enforceFOV))
end
hookCameraFOV()
T(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() task.wait(0.1); hookCameraFOV() end))

B("CUI_LockCam", 2000, function()
    if not S.camera.lockAngle or not S.camera.lockCF then return end
    local cam = workspace.CurrentCamera
    if cam and cam.CFrame ~= S.camera.lockCF then cam.CFrame = S.camera.lockCF end
end)

-- Freecam
local fcInputs = {}
T(UIS.InputBegan:Connect(function(i, gp)
    if gp then return end
    if not S.camera.freecam then return end
    fcInputs[i.KeyCode] = true
end))
T(UIS.InputEnded:Connect(function(i) fcInputs[i.KeyCode] = nil end))
local function enterFreecam()
    if S.camera.freecam then return end
    S.camera.freecam = true
    local cam = workspace.CurrentCamera
    local ch = LP.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    S.camera._state.fcCamType = cam.CameraType
    S.camera._state.fcSubject = cam.CameraSubject
    S.camera._state.fcWalkSpeed = hum and hum.WalkSpeed
    S.camera._state.fcJumpPower = hum and hum.JumpPower
    S.camera._state.fcJumpHeight = hum and hum.JumpHeight
    if hum then hum.WalkSpeed = 0; hum.JumpPower = 0; hum.JumpHeight = 0 end
    cam.CameraType = Enum.CameraType.Scriptable
    S.camera.fcYaw = math.atan2(-cam.CFrame.LookVector.X, -cam.CFrame.LookVector.Z) * 180 / math.pi
    S.camera.fcPitch = math.asin(cam.CFrame.LookVector.Y) * 180 / math.pi
    S.camera.fcPos = cam.CFrame.Position
    UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
    UIS.MouseIconEnabled = false
    Notify("Freecam", "WASD · mouse look · Space/Ctrl · LeftShift 3x · toggle with key", "info", 4)
end
local function exitFreecam()
    if not S.camera.freecam then return end
    S.camera.freecam = false
    local cam = workspace.CurrentCamera
    local st = S.camera._state
    pcall(function() cam.CameraType = st.fcCamType or Enum.CameraType.Custom end)
    if st.fcSubject then pcall(function() cam.CameraSubject = st.fcSubject end) end
    local ch = LP.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = st.fcWalkSpeed or 16
        hum.JumpPower = st.fcJumpPower or 50
        hum.JumpHeight = st.fcJumpHeight or 7.2
    end
    S.camera.fcPos = nil
end
B("CUI_Freecam", 1999, function(dt)
    local C = S.camera
    if not C.freecam then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local ch = LP.Character
    if ch then
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.WalkSpeed ~= 0 then hum.WalkSpeed = 0 end
            if hum.JumpPower ~= 0 then hum.JumpPower = 0 end
            if hum.JumpHeight ~= 0 then hum.JumpHeight = 0 end
        end
    end
    if cam.CameraType ~= Enum.CameraType.Scriptable then cam.CameraType = Enum.CameraType.Scriptable end
    if UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then UIS.MouseBehavior = Enum.MouseBehavior.LockCenter end
    if UIS.MouseIconEnabled then UIS.MouseIconEnabled = false end
    local delta = UIS:GetMouseDelta()
    local sensitivity = 0.15
    C.fcYaw = C.fcYaw - delta.X * sensitivity
    C.fcPitch = math.clamp(C.fcPitch - delta.Y * sensitivity, -89, 89)
    local yawRad = math.rad(C.fcYaw); local pitchRad = math.rad(C.fcPitch)
    local look = Vector3.new(-math.sin(yawRad) * math.cos(pitchRad), math.sin(pitchRad), -math.cos(yawRad) * math.cos(pitchRad)).Unit
    local pos = C.fcPos or cam.CFrame.Position
    local move = Vector3.new()
    local right = look:Cross(Vector3.new(0,1,0)).Unit
    if fcInputs[Enum.KeyCode.W] then move = move + look end
    if fcInputs[Enum.KeyCode.S] then move = move - look end
    if fcInputs[Enum.KeyCode.A] then move = move - right end
    if fcInputs[Enum.KeyCode.D] then move = move + right end
    if fcInputs[Enum.KeyCode.Space] then move = move + Vector3.new(0,1,0) end
    if fcInputs[Enum.KeyCode.LeftControl] then move = move - Vector3.new(0,1,0) end
    if move.Magnitude > 0 then move = move.Unit end
    local speed = fcInputs[Enum.KeyCode.LeftShift] and S.fc.speed*3 or S.fc.speed
    pos = pos + move * speed * dt
    C.fcPos = pos
    cam.CFrame = CFrame.new(pos, pos + look)
end)

-- Mouse
local freeMouse = true
local function shiftOff(h) return h.RigType == Enum.HumanoidRigType.R15 and Vector3.new(1.75, 0.5, 0) or Vector3.new(1, 0.5, 0) end
local function applyMouseState()
    if S.camera.freecam then return end
    if S.inspecting then return end
    if S.shift.on then
        if UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then UIS.MouseBehavior = Enum.MouseBehavior.LockCenter end
        if UIS.MouseIconEnabled then UIS.MouseIconEnabled = false end
        local c = LP.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then local off = shiftOff(h); if h.CameraOffset ~= off then h.CameraOffset = off end end
        end
    elseif freeMouse then
        if UIS.MouseBehavior ~= Enum.MouseBehavior.Default then UIS.MouseBehavior = Enum.MouseBehavior.Default end
        if not UIS.MouseIconEnabled then UIS.MouseIconEnabled = true end
    else
        if UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then UIS.MouseBehavior = Enum.MouseBehavior.LockCenter end
        if UIS.MouseIconEnabled then UIS.MouseIconEnabled = false end
    end
end
B("CUI_Mouse", 100000, applyMouseState)

-- Chams
local function isRake(m)
    if not m or not m:IsA("Model") then return false end
    if m.Name == "Rake" then return true end
    if m.Parent and m.Parent.Name == "Rake" then return true end
    return false
end
local function chamsApply(char)
    local C = S.chams
    if not C.on or not char or not char:IsA("Model") then return end
    if not char:FindFirstChildOfClass("Humanoid") and not char:FindFirstChild("HumanoidRootPart") then return end
    if not C.includeSelf and char == LP.Character then return end
    if isRake(char) then return end
    if C.hl[char] then return end
    local hl = Instance.new("Highlight")
    hl.Name = "Chams_HL"; hl.Adornee = char
    hl.DepthMode = C.seeThrough and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    hl.FillTransparency = C.outlineOnly and 1 or C.fill
    hl.OutlineTransparency = 0
    hl.FillColor = C.pCol; hl.OutlineColor = C.oCol
    hl.Parent = char; C.hl[char] = hl
end
local function chamsRemove(char)
    local hl = S.chams.hl[char]
    if hl then pcall(function() hl:Destroy() end); S.chams.hl[char] = nil end
end
local function chamsScan()
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Humanoid") and d.Parent then chamsApply(d.Parent) end
    end
end
local function chamsEnable()
    local C = S.chams
    if C.on then return end
    C.on = true
    local function hook(p)
        if p == LP and not C.includeSelf then return end
        if p.Character then chamsApply(p.Character) end
        table.insert(C.conns, p.CharacterAdded:Connect(function(ch) ch:WaitForChild("Humanoid", 10); task.wait(0.1); chamsApply(ch) end))
    end
    for _, p in ipairs(Players:GetPlayers()) do hook(p) end
    table.insert(C.conns, Players.PlayerAdded:Connect(hook))
    table.insert(C.conns, workspace.DescendantAdded:Connect(function(d)
        if d:IsA("Humanoid") then task.defer(function() task.wait(0.15); if d.Parent then chamsApply(d.Parent) end end) end
    end))
    table.insert(C.conns, workspace.DescendantRemoving:Connect(function(d)
        if d:IsA("Model") and C.hl[d] then chamsRemove(d) end
    end))
    task.spawn(function() while C.on do task.wait(4); if C.on then chamsScan() end end end)
    chamsScan()
end
local function chamsDisable()
    local C = S.chams
    if not C.on then return end
    C.on = false
    for _, c in ipairs(C.conns) do pcall(function() c:Disconnect() end) end
    C.conns = {}
    for _, hl in pairs(C.hl) do pcall(function() hl:Destroy() end) end
    C.hl = {}
end

-- ESP
local espGui = I("ScreenGui", { Name="velk_1_248_ESP", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=999998, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Parent=PGui })
local bbg = {}
local function ensureBBG(char)
    if bbg[char] then return bbg[char] end
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not head then return nil end
    local gui = I("BillboardGui", { Name="CUI_BBG", Adornee=head, Size=UDim2.new(0,200,0,60),
        StudsOffsetWorldSpace=Vector3.new(0,2.5,0), AlwaysOnTop=true, Enabled=false, Parent=head })
    local nameLbl = I("TextLabel", { Name="Name", BackgroundTransparency=1, Size=UDim2.new(1,0,0,16),
        Font=TH.FB, Text="", TextColor3=S.esp.nameCol, TextSize=13, TextStrokeTransparency=0.4, Parent=gui })
    local distLbl = I("TextLabel", { Name="Dist", BackgroundTransparency=1, Position=UDim2.new(0,0,0,16),
        Size=UDim2.new(1,0,0,12), Font=TH.F, Text="", TextColor3=Color3.fromRGB(200,200,200),
        TextSize=11, TextStrokeTransparency=0.4, Parent=gui })
    bbg[char] = { gui=gui, name=nameLbl, dist=distLbl }
    return bbg[char]
end
local function removeBBG(char)
    local b = bbg[char]
    if b then pcall(function() b.gui:Destroy() end); bbg[char] = nil end
end
local linePool = {}
local LINE_MAX = 400
local function getLine()
    for _, l in ipairs(linePool) do if not l.inUse then l.inUse = true; return l end end
    if #linePool >= LINE_MAX then for _, l in ipairs(linePool) do l.inUse = true; return l end end
    local f = I("Frame", { BackgroundColor3=Color3.new(1,1,1), BorderSizePixel=0, Visible=false,
        AnchorPoint=Vector2.new(0,0.5), Parent=espGui })
    local rec = { frame=f, inUse=true }; table.insert(linePool, rec); return rec
end
local function releaseLines() for _, l in ipairs(linePool) do l.inUse = false; l.frame.Visible = false end end
local function drawLine(a, b, color, thick)
    if not a or not b then return end
    local l = getLine()
    local dx, dy = b.X - a.X, b.Y - a.Y
    local len = math.sqrt(dx*dx + dy*dy)
    local ang = math.deg(math.atan2(dy, dx))
    l.frame.Position = UDim2.fromOffset(a.X, a.Y)
    l.frame.Size = UDim2.fromOffset(len, thick or 1)
    l.frame.Rotation = ang; l.frame.BackgroundColor3 = color; l.frame.Visible = true
end
local function getCharParts(char)
    local parts = {}
    for _, c in ipairs(char:GetChildren()) do if c:IsA("BasePart") then parts[c.Name] = c end end
    return parts, char:FindFirstChildOfClass("Humanoid")
end
local function getCharColor(char)
    if Players:GetPlayerFromCharacter(char) then return S.esp.boxCol, S.esp.nameCol end
    return Color3.fromRGB(255,80,80), Color3.fromRGB(255,200,200)
end
local function w2s(p)
    local sp, onScreen = workspace.CurrentCamera:WorldToViewportPoint(p)
    if not onScreen then return nil end
    return Vector2.new(sp.X, sp.Y)
end
local charCache = {}
local function refreshCharCache()
    charCache = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then table.insert(charCache, p.Character) end
    end
    for _, d in ipairs(workspace:GetChildren()) do
        if d:IsA("Model") and not Players:GetPlayerFromCharacter(d) and d ~= LP.Character then
            if d:FindFirstChildOfClass("Humanoid") and not isRake(d) then
                table.insert(charCache, d)
            end
        end
    end
end
T(workspace.ChildAdded:Connect(function(c) if c:IsA("Model") and running then task.defer(refreshCharCache) end end))
T(workspace.ChildRemoved:Connect(function(c) if c:IsA("Model") and running then task.defer(refreshCharCache) end end))
task.spawn(function() while running do task.wait(3); if running then refreshCharCache() end end end)
refreshCharCache()

-- Rake helpers
local function rakeDead(m)
    local d = m:FindFirstChild("Dead"); if d and d:IsA("BoolValue") and d.Value then return true end
    local i = m:FindFirstChild("Inactive"); if i and i:IsA("BoolValue") and i.Value then return true end
    return false
end
local function rakeFind()
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and d.Name == "Rake" and not rakeDead(d) then return d end
    end
end
local function rakeRoot(m)
    return m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso") or m:FindFirstChild("Head")
end
local function rakeDist(m)
    local mr = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not mr then return nil end
    local r = rakeRoot(m); if not r then return nil end
    return (r.Position - mr.Position).Magnitude
end
local function rakeTargeting(m)
    local tv = m:FindFirstChild("TargetVal")
    if not tv then return false end
    if tv:IsA("ObjectValue") then
        local v = tv.Value
        if v == LP.Character then return true end
        if v and v.Parent == LP.Character then return true end
        if v and v:IsA("Humanoid") and v.Parent == LP.Character then return true end
    elseif tv:IsA("StringValue") then
        if tv.Value == LP.Name or tv.Value == LP.DisplayName then return true end
    end
    return false
end
local function rakeBloodHour(m)
    local bhm = m:FindFirstChild("BloodHourMode")
    if bhm and bhm:IsA("BoolValue") then return bhm.Value end
    return false
end
local function rakeVelocity(m)
    local h = S.rake.posHistory
    if #h < 2 then return Vector3.new() end
    local newest = h[#h]; local oldest = h[1]
    local dt = newest.t - oldest.t
    if dt <= 0 then return Vector3.new() end
    return (newest.p - oldest.p) / dt
end

local soundPulses = {}
task.spawn(function()
    while running do
        task.wait(0.1)
        if S.esp.sound then
            for _, char in ipairs(charCache) do
                for _, d in ipairs(char:GetDescendants()) do
                    if d:IsA("Sound") and d.IsPlaying and d.TimePosition > 0.01 then
                        soundPulses[char] = tick() + 0.4; break
                    end
                end
            end
        end
    end
end)

B("CUI_ESPDraw", 99998, function()
    releaseLines()
    local E = S.esp; local R = S.rake
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position
    local vp = workspace.CurrentCamera.ViewportSize
    local now = tick()

    if not R.modelRef or not R.modelRef.Parent or (now - R.lastScan) > R.scanInterval then
        R.modelRef = rakeFind()
        R.lastScan = now
        if not R.modelRef then R.posHistory = {} end
    end
    local rake = R.modelRef
    if rake and rake.Parent then
        local root = rakeRoot(rake); local dist = rakeDist(rake)
        if root and now - R.lastSample > 0.05 then
            R.lastSample = now
            table.insert(R.posHistory, { p = root.Position, t = now })
            while #R.posHistory > 20 do table.remove(R.posHistory, 1) end
        end
        if R.forceRed then
            if not R.hlRef or not R.hlRef.Parent or R.hlRef.Adornee ~= rake then
                local old = rake:FindFirstChild("CUI_RakeHL"); if old then old:Destroy() end
                local hl = Instance.new("Highlight")
                hl.Name = "CUI_RakeHL"; hl.Adornee = rake
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillTransparency = S.rake.hlFill; hl.OutlineTransparency = 0
                hl.FillColor = Color3.fromRGB(255,0,0); hl.OutlineColor = Color3.fromRGB(255,0,0)
                hl.Parent = rake; R.hlRef = hl
            end
        end
        if root and (R.track or R.showDist) then
            local b = ensureBBG(rake)
            if b then
                b.gui.Enabled = true
                b.name.Visible = true
                b.dist.Visible = R.showDist and dist ~= nil
                b.name.Text = "⚠ RAKE ⚠"
                b.name.TextColor3 = Color3.fromRGB(255,0,0)
                if R.showDist and dist then b.dist.Text = string.format("%d studs", math.floor(dist + 0.5)) end
            end
        end
        if R.track and root then
            local rakeScreen, rakeOn = workspace.CurrentCamera:WorldToViewportPoint(root.Position)
            if not rakeOn then
                local dir = (root.Position - workspace.CurrentCamera.CFrame.Position).Unit
                local rel = workspace.CurrentCamera.CFrame:VectorToObjectSpace(dir)
                local angle = math.atan2(rel.X, rel.Y)
                local edgeR = math.min(vp.X, vp.Y) * 0.4
                local cx, cy = vp.X/2, vp.Y/2
                drawLine(Vector2.new(cx, cy),
                    Vector2.new(cx + math.sin(angle)*edgeR, cy + math.cos(angle)*edgeR),
                    Color3.fromRGB(255, 40, 40), 3)
            end
        end
        if R.predict and root and HAS_DRAWING then
            local vel = rakeVelocity(rake)
            local lines = makeTrajFor(rake)
            if lines then
                local prevScreen = w2s(root.Position)
                local posList = { root.Position + vel*0.4, root.Position + vel*0.8, root.Position + vel*1.2 }
                for i = 1, 3 do
                    local nextScreen = w2s(posList[i])
                    local line = lines[i]
                    if prevScreen and nextScreen then
                        line.From = prevScreen; line.To = nextScreen; line.Visible = true
                    else line.Visible = false end
                    prevScreen = nextScreen
                end
            end
        else
            local lines = DrawESP.traj[rake]
            if lines then for _, line in ipairs(lines) do line.Visible = false end end
        end
        if R.alarm and dist and dist <= R.alarmDist and now - R.lastAlarm > 3 then
            R.lastAlarm = now
            Notify("⚠ PROXIMITY", string.format("Rake is %d studs away", math.floor(dist + 0.5)), "err", 2)
        end
        local targeting = rakeTargeting(rake)
        local bloodHour = rakeBloodHour(rake)
        local showTargeting = targeting and R.targetingNotify
        local showBloodHour = bloodHour and R.bloodHourNotify
        if showTargeting or showBloodHour then
            local title = showTargeting and "⚠ RAKE TARGETING YOU" or "⚠ RAKE — BLOOD HOUR"
            local body = string.format("Distance: %s", dist and (math.floor(dist+0.5) .. " studs") or "?")
            RakeAlert(title, body)
        else
            ClearRakeAlert()
        end
    else
        R.posHistory = {}
        ClearRakeAlert()
        if R.hlRef then pcall(function() R.hlRef:Destroy() end); R.hlRef = nil end
        for _, list in pairs(DrawESP.traj) do
            for _, line in ipairs(list) do line.Visible = false end
        end
    end

    local espActive = E.box2d or E.name or E.dist or E.tracer or E.skeleton or E.headDot or E.lookArrow or E.offscreen or E.sound
    if espActive then
        for _, char in ipairs(charCache) do
            if char.Parent and char ~= rake then
                local parts, hum = getCharParts(char)
                local root = parts["HumanoidRootPart"] or parts["Torso"] or parts["UpperTorso"] or parts["Head"]
                if root and (not hum or hum.Health > 0) then
                    local dist = myPos and (root.Position - myPos).Magnitude or 0
                    if dist <= E.maxDist then
                        local screenPt, onScreen = workspace.CurrentCamera:WorldToViewportPoint(root.Position)
                        local col, nameCol = getCharColor(char)
                        local b = ensureBBG(char)
                        if b then
                            b.gui.Enabled = E.name or E.dist
                            b.name.Visible = E.name
                            b.dist.Visible = E.dist
                            if E.name then
                                local plr = Players:GetPlayerFromCharacter(char)
                                b.name.Text = plr and plr.DisplayName or char.Name
                                b.name.TextColor3 = nameCol
                            end
                            if E.dist then b.dist.Text = string.format("%d studs", math.floor(dist+0.5)) end
                        end
                        if E.box2d and HAS_DRAWING then
                            local box = makeBoxFor(char)
                            if box then
                                local hrp = parts["HumanoidRootPart"] or root
                                local head = parts["Head"]
                                if hrp and head then
                                    local top, onT = workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                                    local bot, onB = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                                    if onT and onB then
                                        local h = math.abs(bot.Y - top.Y); local w = h / 2
                                        box.Size = Vector2.new(w, h)
                                        box.Position = Vector2.new(top.X - w/2, top.Y)
                                        box.Color = col; box.Visible = true
                                    else box.Visible = false end
                                else box.Visible = false end
                            end
                        end
                        if E.tracer and onScreen then
                            drawLine(Vector2.new(vp.X/2, vp.Y), Vector2.new(screenPt.X, screenPt.Y), E.tracerCol, 1)
                        end
                        if E.skeleton and HAS_DRAWING then
                            local lines = makeSkeletonFor(char)
                            if lines then
                                local index = 1
                                for _, pair in ipairs(SKEL_CONNECTIONS) do
                                    local p1 = char:FindFirstChild(pair[1])
                                    local p2 = char:FindFirstChild(pair[2])
                                    local line = lines[index]
                                    if line then
                                        if p1 and p2 and p1:IsA("BasePart") and p2:IsA("BasePart") then
                                            local v1, on1 = workspace.CurrentCamera:WorldToViewportPoint(p1.Position)
                                            local v2, on2 = workspace.CurrentCamera:WorldToViewportPoint(p2.Position)
                                            if on1 and on2 then
                                                line.From = Vector2.new(v1.X, v1.Y); line.To = Vector2.new(v2.X, v2.Y)
                                                line.Color = E.skelCol; line.Visible = true
                                            else line.Visible = false end
                                        else line.Visible = false end
                                    end
                                    index = index + 1
                                end
                            end
                        elseif DrawESP.skeletons[char] then
                            for _, line in ipairs(DrawESP.skeletons[char]) do
                                if line.Visible then line.Visible = false end
                            end
                        end
                        if onScreen then
                            if E.headDot and parts["Head"] then
                                local hp = w2s(parts["Head"].Position)
                                if hp then
                                    local dot = getLine()
                                    dot.frame.Position = UDim2.fromOffset(hp.X - 3, hp.Y - 3)
                                    dot.frame.Size = UDim2.fromOffset(6, 6)
                                    dot.frame.Rotation = 0
                                    dot.frame.BackgroundColor3 = col
                                    dot.frame.Visible = true
                                end
                            end
                            if E.lookArrow and parts["Head"] and parts["HumanoidRootPart"] then
                                local hp = parts["Head"].Position
                                local look = parts["HumanoidRootPart"].CFrame.LookVector
                                local from = w2s(hp); local to = w2s(hp + look * 3)
                                if from and to then drawLine(from, to, Color3.fromRGB(255,255,0), 2) end
                            end
                        elseif E.offscreen then
                            local dir = (root.Position - workspace.CurrentCamera.CFrame.Position).Unit
                            local rel = workspace.CurrentCamera.CFrame:VectorToObjectSpace(dir)
                            local angle = math.atan2(rel.X, rel.Y)
                            local edgeR = math.min(vp.X, vp.Y) * 0.4
                            local cx, cy = vp.X/2, vp.Y/2
                            drawLine(Vector2.new(cx, cy),
                                Vector2.new(cx + math.sin(angle)*edgeR, cy + math.cos(angle)*edgeR),
                                E.offCol, 2)
                        end
                    else
                        local box = DrawESP.boxes[char]; if box then box.Visible = false end
                        local lines = DrawESP.skeletons[char]
                        if lines then for _, line in ipairs(lines) do line.Visible = false end end
                    end
                else
                    removeBBG(char)
                    local box = DrawESP.boxes[char]; if box then box.Visible = false end
                    local lines = DrawESP.skeletons[char]
                    if lines then for _, line in ipairs(lines) do line.Visible = false end end
                end
            end
        end
        if E.sound then
            for char, expiry in pairs(soundPulses) do
                if expiry > now and char.Parent and char ~= rake then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local p = w2s(hrp.Position)
                        if p then
                            local ring = getLine()
                            ring.frame.Position = UDim2.fromOffset(p.X - 6, p.Y - 6)
                            ring.frame.Size = UDim2.fromOffset(12, 12)
                            ring.frame.Rotation = 45
                            ring.frame.BackgroundColor3 = E.soundCol
                            ring.frame.Visible = true
                        end
                    end
                elseif expiry <= now then soundPulses[char] = nil end
            end
        end
    else
        for _, char in ipairs(charCache) do
            removeBBG(char)
            local box = DrawESP.boxes[char]; if box then box.Visible = false end
            local lines = DrawESP.skeletons[char]
            if lines then for _, line in ipairs(lines) do line.Visible = false end end
        end
    end
    for c, _ in pairs(bbg) do if not c.Parent then removeBBG(c) end end
    for c, _ in pairs(DrawESP.boxes) do if not c.Parent then destroyBoxFor(c) end end
    for c, _ in pairs(DrawESP.skeletons) do if not c.Parent then destroySkeletonFor(c) end end
    for c, _ in pairs(DrawESP.traj) do if not c.Parent then destroyTrajFor(c) end end
end)

-- FPS
local fpsSamples = {}
B("CUI_FPS", 99997, function(dt)
    if dt > 0 then
        table.insert(fpsSamples, 1 / dt)
        if #fpsSamples > 60 then table.remove(fpsSamples, 1) end
    end
end)
local function getFPS()
    if #fpsSamples == 0 then return 0 end
    local s = 0; for _, v in ipairs(fpsSamples) do s = s + v end
    return math.floor(s / #fpsSamples + 0.5)
end

-- Window
local W, H = 640, 680
local THGT, TW = 28, 72

local SG = I("ScreenGui", { Name="velk_1_248", ResetOnSpawn=false, DisplayOrder=999999, IgnoreGuiInset=true, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, Parent=PGui })
local win = I("CanvasGroup", { BackgroundColor3=TH.Bg, BorderSizePixel=0, Position=UDim2.new(0,100,0,100),
    Size=UDim2.new(0,W,0,H), GroupTransparency=1, Parent=SG })
themeIt(win, "BackgroundColor3", "Bg")
St(win)

local tabBar = I("ScrollingFrame", { BackgroundColor3=TH.Bg, BorderSizePixel=0, Size=UDim2.new(1,0,0,THGT),
    CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.X,
    ScrollingDirection=Enum.ScrollingDirection.X, ScrollBarThickness=3,
    ScrollBarImageColor3=THEME.Acc, ScrollBarImageTransparency=0.4,
    ElasticBehavior=Enum.ElasticBehavior.Never, Parent=win })
themeIt(tabBar, "BackgroundColor3", "Bg")
local cArea = I("Frame", { BackgroundColor3=TH.Bg, BorderSizePixel=0, Position=UDim2.new(0,0,0,THGT),
    Size=UDim2.new(1,0,1,-THGT), Parent=win })
themeIt(cArea, "BackgroundColor3", "Bg")

local tabNames = {"Main","Players","Visuals","Rake","Sound","Utility","Config","QoL","Game Info","Settings"}
local tabBtns, tabCont, tabX, tabScrolls = {}, {}, {}, {}
local activeTab, tabHooks = nil, {}
local under = I("Frame", { BackgroundColor3=THEME.Acc, BorderSizePixel=0, Position=UDim2.new(0,0,1,-2),
    Size=UDim2.new(0,TW-6,0,2), Parent=tabBar })

local xo = 3
for _, name in ipairs(tabNames) do
    local b = I("TextButton", { BackgroundTransparency=1, Position=UDim2.new(0,xo,0,0),
        Size=UDim2.new(0,TW,1,0), Font=TH.F, Text=name, TextColor3=TH.TxtD,
        TextSize=12, AutoButtonColor=false, Parent=tabBar })
    themeIt(b, "TextColor3", "TxtD")
    tabX[name] = xo + 3; tabBtns[name] = b
    b.MouseButton1Click:Connect(function() setActiveTab(name) end)
    xo = xo + TW
end
for _, name in ipairs(tabNames) do
    local c = I("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,1,0), Visible=false, Parent=cArea })
    tabCont[name] = c
    local scroll = I("ScrollingFrame", { BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollBarThickness=4, ScrollBarImageColor3=THEME.Acc, ScrollBarImageTransparency=0.4,
        BorderSizePixel=0, Parent=c })
    I("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6), Parent=scroll })
    I("UIPadding", { PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,10),
        PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8), Parent=scroll })
    tabScrolls[name] = scroll
end

function setActiveTab(name)
    if activeTab == name then return end
    local prev = activeTab; activeTab = name
    Tw(under, 0.2, { Position=UDim2.new(0,tabX[name],1,-2) }, Enum.EasingStyle.Quint)
    for n, b in pairs(tabBtns) do Tw(b, 0.12, { TextColor3 = (n==name) and TH.Txt or TH.TxtD }) end
    if prev and tabCont[prev] then tabCont[prev].Visible = false end
    tabCont[name].Visible = true
    if tabHooks[name] then task.spawn(tabHooks[name]) end
end

-- MAIN
do
    local mainScroll = tabScrolls["Main"]
    local sec, c = Section(mainScroll, "velk 1.248", 1)
    I("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,120), Font=TH.F,
        Text="RightShift = UI\nRightControl = mouse\nLeftAlt = freecam\nC = toggle freecam\nRightAlt = shiftlock\nDelete = unload\n\nHover ⓘ icons for explanations.",
        TextColor3=TH.TxtD, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Top, TextWrapped=true, Parent=c })
    I("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,32), Font=TH.F,
        Text=HAS_DRAWING and "BETA VERSION" or "Drawing API: NOT available\n2D box + skeleton disabled",
        TextColor3=HAS_DRAWING and TH.OK or TH.Warn, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top, TextWrapped=true, Parent=c })
end

-- PLAYERS
local pScroll = tabScrolls["Players"]
local pList, pCount
do
    local hdr = I("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,22), LayoutOrder=1, Parent=pScroll })
    local t = I("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,-100,1,0), Font=TH.FB,
        Text="Players", TextColor3=TH.Txt, TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=hdr })
    themeIt(t, "TextColor3", "Txt")
    pCount = I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(1,-90,0,0),
        Size=UDim2.new(0,90,1,0), Font=TH.F, Text="0 / 0", TextColor3=TH.TxtD,
        TextSize=12, TextXAlignment=Enum.TextXAlignment.Right, Parent=hdr })
    themeIt(pCount, "TextColor3", "TxtD")
    pList = I("ScrollingFrame", { BackgroundColor3=TH.Sec, BorderSizePixel=0, Size=UDim2.new(1,0,0,500),
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollBarThickness=4, ScrollBarImageColor3=THEME.Acc, ScrollBarImageTransparency=0.4,
        LayoutOrder=2, Parent=pScroll })
    themeIt(pList, "BackgroundColor3", "Sec")
    St(pList)
    I("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,1), Parent=pList })
    I("UIPadding", { PaddingTop=UDim.new(0,4), PaddingLeft=UDim.new(0,4),
        PaddingRight=UDim.new(0,4), PaddingBottom=UDim.new(0,4), Parent=pList })
end
local function refreshPlayers()
    for _, c in ipairs(pList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position
    local list = Players:GetPlayers()
    if myPos then
        table.sort(list, function(a, b)
            local ar = a.Character and a.Character:FindFirstChild("HumanoidRootPart")
            local br = b.Character and b.Character:FindFirstChild("HumanoidRootPart")
            return (ar and (ar.Position - myPos).Magnitude or math.huge) < (br and (br.Position - myPos).Magnitude or math.huge)
        end)
    end
    pCount.Text = tostring(#list) .. " / " .. tostring(Players.MaxPlayers)
    local order = 0
    for _, p in ipairs(list) do
        order = order + 1
        local lp = (p == LP)
        local row = I("Frame", { BackgroundColor3 = lp and Color3.fromRGB(24,34,48) or Color3.fromRGB(22,22,24),
            BorderSizePixel=0, Size=UDim2.new(1,0,0,40), LayoutOrder=order, Parent=pList })
        I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0,8,0,4), Size=UDim2.new(0.55,-8,0,18),
            Font=TH.FB, Text=p.DisplayName .. (lp and "  (you)" or ""), TextColor3=TH.Txt,
            TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, Parent=row })
        I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0,8,0,21), Size=UDim2.new(0.55,-8,0,16),
            Font=TH.F, Text="@" .. p.Name .. "  ·  " .. tostring(p.UserId), TextColor3=TH.TxtD,
            TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=row })
        local pr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        local dTxt = "—"; if myPos and pr then dTxt = string.format("%d studs", (pr.Position - myPos).Magnitude) end
        local hTxt = "—"
        local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if h then hTxt = string.format("HP %d/%d", math.floor(h.Health+0.5), math.floor(h.MaxHealth+0.5)) end
        I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0.55,0,0,4), Size=UDim2.new(0.45,-8,0,16),
            Font=TH.F, Text=dTxt, TextColor3=TH.Txt, TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Right, Parent=row })
        I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0.55,0,0,21), Size=UDim2.new(0.45,-8,0,16),
            Font=TH.F, Text=hTxt, TextColor3=TH.TxtD, TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Right, Parent=row })
    end
end
tabHooks["Players"] = refreshPlayers
task.spawn(function() while running do task.wait(2); if SG.Parent and activeTab == "Players" then refreshPlayers() end end end)

-- VISUALS
do
    local vScroll = tabScrolls["Visuals"]
    local searchSec, searchContent = Section(vScroll, nil, 0)
    local searchBox = I("TextBox", { BackgroundColor3=TH.Off, BorderSizePixel=0,
        Position=UDim2.new(0,10,0,8), Size=UDim2.new(1,-20,0,22),
        Font=TH.F, Text="", TextColor3=TH.Txt, TextSize=12,
        PlaceholderText="search settings…", PlaceholderColor3=TH.TxtD,
        TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, Parent=searchSec })
    themeIt(searchBox, "BackgroundColor3", "Off")
    themeIt(searchBox, "TextColor3", "Txt")
    themeIt(searchBox, "PlaceholderColor3", "TxtD")
    St(searchBox, TH.BrdL, 1)
    I("UIPadding", { PaddingLeft=UDim.new(0,6), Parent=searchBox })

    local function filterAll(text)
        local needle = text:lower():match("^%s*(.-)%s*$")
        if needle == "" then
            for _, e in ipairs(SEARCH.rows) do
                e.row.Visible = true
                if e.section then e.section.Visible = true end
            end
            return
        end
        local anyMatch = false
        local sectionMatch = {}
        for _, e in ipairs(SEARCH.rows) do
            local match = e.text:find(needle, 1, true) ~= nil
            e.row.Visible = match
            if match then
                anyMatch = true
                if e.section then sectionMatch[e.section] = true end
            end
        end
        if not anyMatch then
            for _, e in ipairs(SEARCH.rows) do
                e.row.Visible = true
                if e.section then e.section.Visible = true end
            end
            return
        end
        for _, e in ipairs(SEARCH.rows) do
            if e.section then e.section.Visible = sectionMatch[e.section] == true end
        end
    end
    searchBox:GetPropertyChangedSignal("Text"):Connect(function() filterAll(searchBox.Text) end)

    local _, lgC = Collapsible(vScroll, "Lighting", false, 1)
    Checkbox(lgC, "Enforce Daylight", false, function(s) S.lighting.day = s; applyLight() end, 1, false, "light.day", "Brightness max + ambient gray. World fully lit.")
    Checkbox(lgC, "No Fog", false, function(s) S.lighting.noFog = s; applyLight() end, 2, false, "light.noFog", "Fog distance to 1,000,000 studs.")
    Checkbox(lgC, "Disable Global Shadows", false, function(s) S.lighting.noShadows = s; applyLight() end, 3, false, "light.noShadows", "Removes sun/moon shadows.")
    Checkbox(lgC, "Remove Atmosphere", false, function(s) S.lighting.noAtmo = s; applyLight() end, 4, false, "light.noAtmo", "Atmosphere density 0.")
    Checkbox(lgC, "Remove Post-FX", false, function(s) S.lighting.noPostFX = s; applyLight() end, 5, false, "light.noPostFX", "Disables all post-processing.")
    Checkbox(lgC, "Remove Blur / DoF", true, function(s) S.lighting.noBlur = s; applyLight() end, 6, true, "light.noBlur", "Kills Blur/DoF only. On by default.")
    Checkbox(lgC, "Vignette", false, function(s) S.lighting.vig = s; for _, f in pairs(vigFrames) do f.Visible = s end end, 7, false, "light.vig", "Dark screen edges.")
    Checkbox(lgC, "Remove Sky", false, function(s) S.lighting.noSky = s; applyLight() end, 8, false, "light.noSky", "Clears skybox.")
    Slider(lgC, "Time of Day", 0, 24, 14, function(v) S.lighting.tod = v; applyLight() end, 9, "light.tod", "0 midnight, 12 noon.")
    Slider(lgC, "Saturation", -100, 100, 0, function(v) S.lighting.cc_sat = v/100; applyLight() end, 10, "light.sat", "Color saturation.")
    Slider(lgC, "Contrast", -100, 100, 0, function(v) S.lighting.cc_con = v/100; applyLight() end, 11, "light.con", "Contrast.")

    local _, rnC = Collapsible(vScroll, "Rendering", false, 2)
    Checkbox(rnC, "Remove Particles", false, function(s) S.render.noParticles = s; toggleParticles(s) end, 1, false, "render.noParticles", "Disables particles/fire/smoke/trails.")
    Checkbox(rnC, "Remove Decals", false, function(s) S.render.noDecals = s; toggleDecals(s) end, 2, false, "render.noDecals", "Decals/Textures transparent.")
    Checkbox(rnC, "Disable Cast Shadows", false, function(s) S.render.noShadowCast = s; toggleShadows(s) end, 3, false, "render.noShadowCast", "CastShadow=false everywhere.")
    Checkbox(rnC, "Remove Terrain Decorations", false, function(s)
        S.render.noDecor = s
        if Terrain then for _, d in ipairs(Terrain:GetChildren()) do if d:IsA("Decoration") then d.Enabled = not s end end end
    end, 4, false, "render.noDecor", "Disables grass/rocks.")
    Checkbox(rnC, "Hide Water", false, function(s) S.render.noWater = s; applyWater() end, 5, false, "render.noWater", "Water invisible.")
    Checkbox(rnC, "Remove Other Players' Accessories", false, function(s)
        S.render.noOtherAcc = s
        if s then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then stripAccessories(p.Character) end
            end
        end
    end, 6, false, "render.noOtherAcc", "Also applies to players who join later.")
    Checkbox(rnC, "Remove Own Accessories", false, function(s) S.render.noOwnAcc = s; if s then stripAccessories(LP.Character) end end, 7, false, "render.noOwnAcc", "Permanent.")
    Checkbox(rnC, "Material Override", false, function(s) S.render.matOverride = s; applyMaterialOverride() end, 8, false, "render.matOverride", "Every BasePart to selected material.")
    Button(rnC, "Cycle Material", function() cycleMaterial() end, 9, 22)

    local _, cmC = Collapsible(vScroll, "Camera", false, 3)
    Checkbox(cmC, "Force Third Person", false, function(s)
        S.camera.tp = s
        if s then
            S.camera._state.mode = LP.CameraMode
            S.camera._state.maxZoom = LP.CameraMaxZoomDistance
            S.camera._state.minZoom = LP.CameraMinZoomDistance
        else
            if S.camera._state.mode then LP.CameraMode = S.camera._state.mode end
            if S.camera._state.maxZoom then LP.CameraMaxZoomDistance = S.camera._state.maxZoom end
            if S.camera._state.minZoom then LP.CameraMinZoomDistance = S.camera._state.minZoom end
        end
    end, 1, false, "cam.tp", "CameraMode Classic, re-applied every frame.")
    Checkbox(cmC, "Enforce FOV", false, function(s)
        S.camera.fovOverride = s
        if not s then local cam = workspace.CurrentCamera; if cam then cam.FieldOfView = 75 end end
    end, 2, false, "cam.fovOverride", "Locks FOV to slider.")
    Slider(cmC, "Field of View", 40, 140, 75, function(v) S.camera.fov = v; S.camera.fovOverride = true; enforceFOV() end, 3, "cam.fov", "70 default, 120 wide.")
    Slider(cmC, "Camera Roll", -45, 45, 0, function(v) S.camera.roll = v end, 4, "cam.roll", "Camera tilt.")
    Slider(cmC, "Max Zoom", 4, 500, 128, function(v) S.camera.maxZoom = v; if not S.camera.tp then LP.CameraMaxZoomDistance = v end end, 5, "cam.maxZoom", "Max CameraZoomDistance.")
    Slider(cmC, "Min Zoom", 0, 10, 0.5, function(v) S.camera.minZoom = v; if not S.camera.tp then LP.CameraMinZoomDistance = v end end, 6, "cam.minZoom", "Min CameraZoomDistance.")
    Checkbox(cmC, "Freecam", false, function(s)
        if s then enterFreecam() else exitFreecam() end
    end, 7, false, "cam.freecam", "Mouse rotates, WASD moves. Toggle with C.")
    Checkbox(cmC, "Lock Camera Angle", false, function(s)
        S.camera.lockAngle = s
        if s then S.camera.lockCF = workspace.CurrentCamera.CFrame else S.camera.lockCF = nil end
    end, 8, false, "cam.lockAngle", "Freezes CFrame.")

    local _, esC = Collapsible(vScroll, "ESP", false, 4)
    Checkbox(esC, "2D Box" .. (HAS_DRAWING and "" or " (unavailable)"), false, function(s)
        if s and not HAS_DRAWING then Notify("2D Box", "Drawing API not available", "err", 3); S.esp.box2d = false; return end
        S.esp.box2d = s
    end, 1, false, "esp.box2d", "Rectangle around each player. Requires Drawing API.")
    Checkbox(esC, "Name Tags", false, function(s) S.esp.name = s end, 2, false, "esp.name", "DisplayName above head.")
    Checkbox(esC, "Distance Text", false, function(s) S.esp.dist = s end, 3, false, "esp.dist", "Distance in studs.")
    Checkbox(esC, "Tracer Lines", false, function(s) S.esp.tracer = s end, 4, false, "esp.tracer", "Line from screen bottom to player.")
    Checkbox(esC, "Skeleton ESP" .. (HAS_DRAWING and "" or " (unavailable)"), false, function(s)
        if s and not HAS_DRAWING then Notify("Skeleton", "Drawing API not available", "err", 3); S.esp.skeleton = false; return end
        S.esp.skeleton = s
    end, 5, false, "esp.skeleton", "Lines connecting bones. R6 + R15.")
    Checkbox(esC, "Head Dot", false, function(s) S.esp.headDot = s end, 6, false, "esp.headDot", "Dot at head position.")
    Checkbox(esC, "Look-Direction Arrow", false, function(s) S.esp.lookArrow = s end, 7, false, "esp.lookArrow", "Yellow arrow showing facing.")
    Checkbox(esC, "Sound ESP", false, function(s) S.esp.sound = s end, 8, false, "esp.sound", "Square over players making sounds.")
    Checkbox(esC, "Off-Screen Arrows", false, function(s) S.esp.offscreen = s end, 9, false, "esp.offscreen", "Arrows toward off-screen players.")
    Slider(esC, "Max Distance", 50, 5000, 1000, function(v) S.esp.maxDist = v end, 10, "esp.maxDist", "Hide players beyond this distance.")

    local _, chC = Collapsible(vScroll, "Chams", false, 5)
    Checkbox(chC, "Enable Chams", false, function(s) if s then chamsEnable() else chamsDisable() end end, 1, false, "chams.on", "Highlight fill behind players.")
    Checkbox(chC, "See Through Walls", true, function(s) S.chams.seeThrough = s end, 2, false, "chams.seeThrough", "Highlight renders through walls.")
    Checkbox(chC, "Include Self", false, function(s) S.chams.includeSelf = s; if S.chams.on then chamsDisable(); chamsEnable() end end, 3, false, "chams.includeSelf", "Highlight yourself too.")
    Checkbox(chC, "Rainbow / Pulsing", false, function(s) S.chams.rainbow = s end, 4, false, "chams.rainbow", "Animated HSV cycle.")
    Checkbox(chC, "Outline-Only Mode", false, function(s) S.chams.outlineOnly = s end, 5, false, "chams.outlineOnly", "No fill, only outline.")
    Slider(chC, "Fill Transparency", 0, 100, 50, function(v) S.chams.fill = v/100 end, 6, "chams.fill", "0 solid, 100 invisible.")

    local _, acC = Collapsible(vScroll, "Actions", true, 6)
    Button(acC, "Re-Apply All", function() applyLight(); enforceFOV(); Notify("Actions", "Re-applied", "info", 1.5) end, 1, 24)
    Button(acC, "Revert All", function()
        for _, entry in ipairs(ALL_CHECKS) do
            if not entry.keep then entry.set(false, true) end
        end
        S.lighting.day=false; S.lighting.noFog=false; S.lighting.noShadows=false
        S.lighting.noAtmo=false; S.lighting.noPostFX=false; S.lighting.noSky=false
        S.lighting.vig=false
        for _, f in pairs(vigFrames) do f.Visible = false end
        S.render.matOverride=false; applyMaterialOverride()
        S.render.noWater=false; applyWater()
        toggleParticles(false); toggleDecals(false); toggleShadows(false)
        S.camera.tp=false; S.camera.fovOverride=false; S.camera.roll=0
        S.camera.freecam=false; S.camera.lockAngle=false; S.camera.lockCF=nil
        chamsDisable()
        S.esp.box2d=false; S.esp.name=false; S.esp.dist=false; S.esp.tracer=false
        S.esp.skeleton=false; S.esp.headDot=false; S.esp.lookArrow=false
        S.esp.sound=false; S.esp.offscreen=false
        ClearRakeAlert()
        S.lighting.tod = S.lighting.orig and S.lighting.orig.ClockTime or 14
        if S.lighting.cc then S.lighting.cc.Saturation=0; S.lighting.cc.Contrast=0 end
        applyLight()
        Notify("Actions", "Reverted", "warn", 2)
    end, 2, 24)
end

-- RAKE
do
    local rScroll = tabScrolls["Rake"]
    local sec, c = Section(rScroll, "Monster Tracker", 1)
    I("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,28), Font=TH.F,
        Text="Finds any model named 'Rake' at any depth. Filters Dead/Inactive.",
        TextColor3=TH.TxtD, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Top, TextWrapped=true, Parent=c })
    Checkbox(c, "Force Red Highlight", true, function(s)
        S.rake.forceRed = s
        if not s and S.rake.hlRef then pcall(function() S.rake.hlRef:Destroy() end); S.rake.hlRef = nil end
    end, 1, true, "rake.forceRed", "Persistent red outline on the Rake.")
    Checkbox(c, "Show Distance", true, function(s) S.rake.showDist = s end, 2, false, "rake.showDist", "Distance in studs above the Rake.")
    Checkbox(c, "Track Rake", false, function(s) S.rake.track = s end, 3, false, "rake.track", "Off-screen arrow points toward the Rake.")
    Checkbox(c, "Movement Prediction", true, function(s) S.rake.predict = s end, 4, false, "rake.predict", "3-dot trajectory line based on velocity. Requires Drawing API.")
    Checkbox(c, "Proximity Alarm", false, function(s) S.rake.alarm = s end, 5, false, "rake.alarm", "Alert when Rake is within range.")
    Checkbox(c, "Targeting Alert", true, function(s) S.rake.targetingNotify = s end, 6, true, "rake.targetingNotify", "Alert only while Rake is targeting YOU.")
    Checkbox(c, "Blood Hour Alert", true, function(s) S.rake.bloodHourNotify = s end, 7, true, "rake.bloodHourNotify", "Alert during Blood Hour.")
    Slider(c, "Alarm Distance", 10, 300, 60, function(v) S.rake.alarmDist = v end, 8, "rake.alarmDist", "Distance threshold for the alarm.")
    Slider(c, "Highlight Transparency", 0, 100, 50, function(v)
        S.rake.hlFill = v / 100
        if S.rake.hlRef and S.rake.hlRef.Parent then S.rake.hlRef.FillTransparency = S.rake.hlFill end
    end, 9, "rake.hlFill", "Rake highlight fill transparency.")

    -- ── Spectate Rake (drone attach) ──────────────────────────────────────
    local INS = {
        active       = false,
        source       = nil,
        clone        = nil,
        smoothedLook = nil,
        savedState   = {},
    }

    local INS_STEP = "CUI_Inspector"

    local DRONE_DIST   = 12
    local DRONE_HEIGHT = 6
    local LOOK_HEIGHT  = 3
    local LOOK_SMOOTH  = 0.12

    local inspectorStop
    local refreshButton

    local function destroyClone()
        if INS.clone then
            pcall(function() INS.clone:Destroy() end)
            INS.clone = nil
        end
        INS.source = nil
        INS.smoothedLook = nil
    end

    local function makeClone(source)
        if not source or not source:IsA("Model") then return nil end
        local clone = source:Clone()
        clone.Name = "velk_InspectorClone"

        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
                d:Destroy()
            end
        end

        local srcRoot = source:FindFirstChild("HumanoidRootPart")
            or source:FindFirstChild("Torso")
            or source:FindFirstChild("UpperTorso")
            or source:FindFirstChild("Head")
        local srcCF = srcRoot and srcRoot.CFrame or CFrame.new(0, 10, 0)

        if not clone.PrimaryPart then
            clone.PrimaryPart = clone:FindFirstChild("HumanoidRootPart")
                or clone:FindFirstChild("Torso")
                or clone:FindFirstChild("UpperTorso")
                or clone:FindFirstChildWhichIsA("BasePart")
        end

        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("BasePart") then
                d.Anchored   = true
                d.CanCollide = false
                d.CanQuery   = false
                d.CanTouch   = false
            end
        end

        local hum = clone:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.JumpHeight = 0
            hum.PlatformStand = true
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end

        local folder = workspace:FindFirstChild("velk_Inspector")
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = "velk_Inspector"
            folder.Parent = workspace
        end

        clone.Parent = folder
        clone:PivotTo(srcCF)
        return clone
    end

    local function freezePlayer()
        local cam = workspace.CurrentCamera
        local ch  = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")

        INS.savedState.camType    = cam.CameraType
        INS.savedState.camSubject = cam.CameraSubject
        INS.savedState.walkSpeed  = hum and hum.WalkSpeed
        INS.savedState.jumpPower  = hum and hum.JumpPower
        INS.savedState.jumpHeight = hum and hum.JumpHeight
        INS.savedState.autoRotate = hum and hum.AutoRotate

        if hum then
            hum.WalkSpeed  = 0
            hum.JumpPower  = 0
            hum.JumpHeight = 0
            hum.AutoRotate = false
        end
        cam.CameraType = Enum.CameraType.Scriptable
        UIS.MouseBehavior    = Enum.MouseBehavior.Default
        UIS.MouseIconEnabled = true
    end

    local function unfreezePlayer()
        local cam = workspace.CurrentCamera
        local st = INS.savedState

        pcall(function() cam.CameraType = st.camType or Enum.CameraType.Custom end)
        if st.camSubject then
            pcall(function() cam.CameraSubject = st.camSubject end)
        end

        local ch  = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed  = st.walkSpeed  or 16
            hum.JumpPower  = st.jumpPower  or 50
            hum.JumpHeight = st.jumpHeight or 7.2
            hum.AutoRotate = st.autoRotate ~= false
        end

        INS.savedState = {}
    end

    local function updateDrone()
        if not INS.active then return end
        local cam = workspace.CurrentCamera
        if not cam then return end

        if not INS.source or not INS.source.Parent then
            Notify("Spectate", "Rake despawned.", "warn", 2)
            task.defer(inspectorStop)
            return
        end

        local root = INS.source:FindFirstChild("HumanoidRootPart")
            or INS.source:FindFirstChild("Torso")
            or INS.source:FindFirstChild("UpperTorso")
            or INS.source:FindFirstChild("Head")
        if not root then return end

        local pos  = root.Position
        local look = root.CFrame.LookVector

        if INS.smoothedLook then
            INS.smoothedLook = INS.smoothedLook:Lerp(look, LOOK_SMOOTH)
            if INS.smoothedLook.Magnitude > 0 then
                INS.smoothedLook = INS.smoothedLook.Unit
            end
        else
            INS.smoothedLook = look
        end

        local dronePos  = pos - INS.smoothedLook * DRONE_DIST + Vector3.new(0, DRONE_HEIGHT, 0)
        local targetPos = pos + Vector3.new(0, LOOK_HEIGHT, 0)

        cam.CFrame = CFrame.new(dronePos, targetPos)

        if UIS.MouseBehavior ~= Enum.MouseBehavior.Default then
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end

    local MIRROR_PARTS = {
        "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso",
        "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
        "LeftUpperArm", "LeftLowerArm", "LeftHand",
        "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
        "RightUpperLeg", "RightLowerLeg", "RightFoot",
    }

    local function mirrorPose()
        if not INS.clone  or not INS.clone.Parent  then return end
        if not INS.source or not INS.source.Parent then return end

        for _, name in ipairs(MIRROR_PARTS) do
            local src = INS.source:FindFirstChild(name)
            local dst = INS.clone:FindFirstChild(name)
            if src and dst and src:IsA("BasePart") and dst:IsA("BasePart") then
                dst.CFrame = src.CFrame
            end
        end
    end

    local function inspectorStart()
        if INS.active then return end

        local source = S.rake.modelRef
        if not source or not source.Parent then source = rakeFind() end
        if not source then
            Notify("Spectate", "No Rake found in workspace.", "err", 3)
            return
        end

        INS.source = source
        INS.clone  = makeClone(source)
        if not INS.clone then
            Notify("Spectate", "Failed to clone the Rake.", "err", 3)
            INS.source = nil
            return
        end

        INS.active = true
        INS.smoothedLook = nil
        S.inspecting = true

        freezePlayer()

        pcall(function() RS:UnbindFromRenderStep(INS_STEP) end)
        RS:BindToRenderStep(INS_STEP, 99996, function()
            updateDrone()
            mirrorPose()
        end)

        Notify("Spectate", "Drone attached. Press Delete to exit.", "ok", 3)
        if refreshButton then refreshButton() end
    end

    inspectorStop = function()
        if not INS.active then return end
        INS.active = false
        S.inspecting = false

        pcall(function() RS:UnbindFromRenderStep(INS_STEP) end)

        destroyClone()

        local folder = workspace:FindFirstChild("velk_Inspector")
        if folder then
            for _, ch in ipairs(folder:GetChildren()) do
                pcall(function() ch:Destroy() end)
            end
            pcall(function() folder:Destroy() end)
        end

        unfreezePlayer()

        Notify("Spectate", "Detached.", "info", 2)
        if refreshButton then refreshButton() end
    end

    T(LP.CharacterAdded:Connect(function()
        if INS.active then inspectorStop() end
    end))

    local sec2, c2 = Section(rScroll, "Spectate Rake", 2)
    I("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 68),
        Font = TH.F,
        Text = "Clones the Rake and attaches a drone camera behind it. "
            .. "Mirrors the Rake's pose every frame so you see exactly what it's doing. "
            .. "Movement and input are disabled while spectating — press Delete to exit.",
        TextColor3 = TH.TxtD, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, Parent = c2,
    })

    local startBtn = Button(c2, "Spectate Rake", function() inspectorStart() end, 1, 30)
    Button(c2, "Stop Spectating", function() inspectorStop() end, 2, 30)

    refreshButton = function()
        startBtn.BackgroundColor3 = INS.active and THEME.Acc or TH.Sec
    end

    local prevHook = tabHooks["Rake"]
    tabHooks["Rake"] = function()
        if prevHook then prevHook() end
        refreshButton()
    end
end

-- SOUND
do
    local sScroll = tabScrolls["Sound"]
    local sec, c = Section(sScroll, "Ambient Music", 1)
    TextInput(c, "Sound ID", "", function(t) S.sound.musicId = t end, 1, "sound.musicId")
    Slider(c, "Volume", 0, 100, 50, function(v)
        S.sound.musicVol = v / 100
        if S.sound.musicObj then S.sound.musicObj.Volume = S.sound.musicVol end
    end, 2, "sound.musicVol")
    Button(c, "Play / Stop", function()
        if S.sound.musicOn then
            if S.sound.musicObj then S.sound.musicObj:Destroy(); S.sound.musicObj = nil end
            S.sound.musicOn = false
        else
            if S.sound.musicId == "" then return end
            local s = Instance.new("Sound")
            s.Name = "CUI_Music"; s.SoundId = "rbxassetid://" .. S.sound.musicId
            s.Volume = S.sound.musicVol; s.Looped = true; s.Parent = SS; s:Play()
            S.sound.musicObj = s; S.sound.musicOn = true
        end
    end, 3, 28)

    local sec2, c2 = Section(sScroll, "Game Audio", 2)
    Checkbox(c2, "Mute All Game Sounds", false, function(s)
        S.sound.muted = s
        if s then muteAllSounds() else unmuteAllSounds() end
    end, 1, false, "sound.muted", "Mutes every Sound and SoundGroup.")
end

-- UTILITY
do
    local uScroll = tabScrolls["Utility"]
    local friendsCache = {}
    local sec1, c1 = Section(uScroll, "Friends", 1)
    local fList = I("ScrollingFrame", { BackgroundColor3=TH.Off, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,190), CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=3,
        ScrollBarImageColor3=THEME.Acc, ScrollBarImageTransparency=0.4, LayoutOrder=1, Parent=c1 })
    themeIt(fList, "BackgroundColor3", "Off")
    I("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,2), Parent=fList })
    I("UIPadding", { PaddingTop=UDim.new(0,4), PaddingLeft=UDim.new(0,4),
        PaddingRight=UDim.new(0,4), PaddingBottom=UDim.new(0,4), Parent=fList })
    local function rebuild()
        for _, ch in ipairs(fList:GetChildren()) do
            if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
        end
        local order = 0
        for _, fr in ipairs(friendsCache) do
            if fr.Id ~= LP.UserId then
                order = order + 1
                local row = I("Frame", { BackgroundColor3=Color3.fromRGB(24,24,26), BorderSizePixel=0,
                    Size=UDim2.new(1,0,0,32), LayoutOrder=order, Parent=fList })
                I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0,6,0,2), Size=UDim2.new(0.6,-6,0,14),
                    Font=TH.FB, Text=fr.DisplayName or fr.Username, TextColor3=TH.Txt,
                    TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, Parent=row })
                I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0,6,0,17), Size=UDim2.new(0.6,-6,0,12),
                    Font=TH.F, Text="@"..fr.Username, TextColor3=TH.TxtD,
                    TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, Parent=row })
                local inServer = false
                for _, p in ipairs(Players:GetPlayers()) do if p.UserId == fr.Id then inServer = true end end
                Button(row, inServer and "In Server" or "Join", function()
                    if not inServer then pcall(function() TPS:TeleportToPlayer(fr.Id) end) end
                end, 1, 24, UDim2.new(0.36,-4,0,4), UDim2.new(0.62,0,0,4))
            end
        end
    end
    local btnHolder = I("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,26), LayoutOrder=2, Parent=c1 })
    Button(btnHolder, "Load Friends", function()
        task.spawn(function()
            local ok, result = pcall(function() return Players:GetFriendsAsync(LP.UserId) end)
            if not ok then return end
            friendsCache = {}
            local pages = result; local guard = 0
            while guard < 20 do
                guard = guard + 1
                for _, item in ipairs(pages:GetCurrentPage()) do
                    if item.Id ~= LP.UserId then
                        table.insert(friendsCache, { Id=item.Id, Username=item.Username, DisplayName=item.DisplayName })
                    end
                end
                if pages.IsFinished then break end
                local ok2 = pcall(function() pages:AdvanceToNextPageAsync() end)
                if not ok2 then break end
            end
            rebuild()
        end)
    end, 1, 24, UDim2.new(0.5,-6,0,24), UDim2.new(0,0,0,1))
    Button(btnHolder, "Refresh", function() rebuild() end, 2, 24, UDim2.new(0.5,-6,0,24), UDim2.new(0.5,6,0,1))

    local sec2, c2 = Section(uScroll, "Server", 2)
    Button(c2, "Rejoin Same Server", function() TPS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end, 1, 24)
    Button(c2, "Server Hop", function() pcall(function() TPS:Teleport(game.PlaceId, LP) end) end, 2, 24)

    local sec3, c3 = Section(uScroll, "Account", 3)
    local accRows = {}
    local function makeRow(key, order)
        local row = I("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,20), LayoutOrder=order, Parent=c3 })
        I("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0.42,0,1,0), Font=TH.F,
            Text=key, TextColor3=TH.TxtD, TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=row })
        local v = I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0.42,0,0,0),
            Size=UDim2.new(0.58,0,1,0), Font=TH.F, Text="—", TextColor3=TH.Txt,
            TextSize=12, TextXAlignment=Enum.TextXAlignment.Right, Parent=row })
        accRows[key] = v
    end
    makeRow("Display Name", 1); makeRow("Username", 2); makeRow("User ID", 3)
    makeRow("Account Age", 4); makeRow("Membership", 5); makeRow("Ping", 6)
    local function refresh()
        accRows["Display Name"].Text = LP.DisplayName
        accRows["Username"].Text = "@" .. LP.Name
        accRows["User ID"].Text = tostring(LP.UserId)
        accRows["Account Age"].Text = tostring(LP.AccountAge) .. " days"
        accRows["Membership"].Text = tostring(LP.MembershipType):gsub("Enum.MembershipType.", "")
        local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        accRows["Ping"].Text = ok and (math.floor(ping) .. " ms") or "—"
    end
    refresh()
    tabHooks["Utility"] = refresh
end

-- CONFIG
do
    local cfgScroll = tabScrolls["Config"]
    local CONFIG_FOLDER = "velk_1_248_Configs"
    local hasIO = (typeof(writefile) == "function") and (typeof(readfile) == "function")
    local function ensureFolder()
        if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
            if not isfolder(CONFIG_FOLDER) then pcall(makefolder, CONFIG_FOLDER) end
        end
    end
    local function cfgPath(name) return CONFIG_FOLDER .. "/" .. name .. ".json" end
    local function listConfigs()
        if typeof(listfiles) ~= "function" then return {} end
        ensureFolder()
        local ok, files = pcall(listfiles, CONFIG_FOLDER)
        if not ok or not files then return {} end
        local out = {}
        for _, f in ipairs(files) do
            local name = f:match("([^/\\]+)%.json$")
            if name then table.insert(out, name) end
        end
        table.sort(out); return out
    end
    local function serialize()
        local data = { version = 1, saved = os.time() }
        for k, entry in pairs(ToggleReg) do data[k] = entry.get() end
        for k, entry in pairs(SliderReg) do data[k] = entry.get() end
        data["_keys"] = {}
        for name, kc in pairs(S.keys) do data["_keys"][name] = kc.Name end
        return data
    end
    local function deserialize(data)
        if not data then return end
        for k, v in pairs(data) do
            if k ~= "version" and k ~= "saved" and k ~= "_keys" then
                if ToggleReg[k] then ToggleReg[k].set(v)
                elseif SliderReg[k] then SliderReg[k].set(v) end
            end
        end
        if data._keys then
            for name, kcName in pairs(data._keys) do
                local kc = Enum.KeyCode[kcName]
                if kc then S.keys[name] = kc end
            end
        end
    end

    local sec, c = Section(cfgScroll, "Config Manager", 1)
    I("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,30), Font=TH.F,
        Text=hasIO and "Ready. Saves to velk_1_248_Configs/." or "writefile not available in this executor.",
        TextColor3=hasIO and TH.TxtD or TH.Warn, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top,
        TextWrapped=true, Parent=c })
    local nameBox = I("TextBox", { BackgroundColor3=TH.Off, BorderSizePixel=0, Size=UDim2.new(1,0,0,24),
        Font=TH.F, Text="default", TextColor3=TH.Txt, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, LayoutOrder=1, Parent=c })
    themeIt(nameBox, "BackgroundColor3", "Off"); themeIt(nameBox, "TextColor3", "Txt")
    St(nameBox, TH.BrdL, 1)
    I("UIPadding", { PaddingLeft=UDim.new(0,6), Parent=nameBox })
    Button(c, "Save Current", function()
        if not hasIO then return end
        ensureFolder()
        pcall(writefile, cfgPath(nameBox.Text), Http:JSONEncode(serialize()))
        Notify("Config", "Saved: " .. nameBox.Text, "ok", 2)
    end, 2, 26)
    Button(c, "Load From Name", function()
        if not hasIO then return end
        local ok, content = pcall(readfile, cfgPath(nameBox.Text))
        if not ok then return end
        local ok2, data = pcall(function() return Http:JSONDecode(content) end)
        if not ok2 then return end
        deserialize(data); Notify("Config", "Loaded", "ok", 2)
    end, 3, 26)

    local sec2, c2 = Section(cfgScroll, "Saved Configs", 2)
    local cfgList = I("ScrollingFrame", { BackgroundColor3=TH.Off, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,240), CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=3,
        ScrollBarImageColor3=THEME.Acc, ScrollBarImageTransparency=0.4, LayoutOrder=1, Parent=c2 })
    themeIt(cfgList, "BackgroundColor3", "Off")
    I("UIListLayout", { SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,2), Parent=cfgList })
    I("UIPadding", { PaddingTop=UDim.new(0,4), PaddingLeft=UDim.new(0,4),
        PaddingRight=UDim.new(0,4), PaddingBottom=UDim.new(0,4), Parent=cfgList })
    local function rebuildList()
        for _, ch in ipairs(cfgList:GetChildren()) do
            if ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end
        end
        if not hasIO then
            I("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,22),
                Font=TH.F, Text="File IO unavailable.", TextColor3=TH.Warn, TextSize=12,
                TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=1, Parent=cfgList })
            return
        end
        local configs = listConfigs()
        if #configs == 0 then
            I("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,22),
                Font=TH.F, Text="No saved configs yet.", TextColor3=TH.TxtD,
                TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=1, Parent=cfgList })
            return
        end
        local order = 0
        for _, name in ipairs(configs) do
            order = order + 1
            local row = I("Frame", { BackgroundColor3=Color3.fromRGB(24,24,26), BorderSizePixel=0,
                Size=UDim2.new(1,0,0,28), LayoutOrder=order, Parent=cfgList })
            I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0,6,0,0),
                Size=UDim2.new(0.55,-6,1,0), Font=TH.F, Text=name,
                TextColor3=TH.Txt, TextSize=12,
                TextXAlignment=Enum.TextXAlignment.Left, Parent=row })
            Button(row, "Load", function()
                local ok, content = pcall(readfile, cfgPath(name))
                if not ok then return end
                local ok2, data = pcall(function() return Http:JSONDecode(content) end)
                if not ok2 then return end
                deserialize(data); nameBox.Text = name
                Notify("Config", "Loaded: " .. name, "ok", 2)
            end, 1, 22, UDim2.new(0.18,0,0,22), UDim2.new(0.58,0,0,3))
            Button(row, "Delete", function()
                if typeof(delfile) == "function" then pcall(delfile, cfgPath(name)) end
                Notify("Config", "Deleted: " .. name, "warn", 2)
                task.wait(0.1); rebuildList()
            end, 2, 22, UDim2.new(0.22,0,0,22), UDim2.new(0.78,0,0,3))
        end
    end
    Button(c2, "Refresh List", function() rebuildList() end, 2, 26)
    tabHooks["Config"] = rebuildList
end

-- QOL
do
    local qScroll = tabScrolls["QoL"]
    local sec, c = Section(qScroll, "Interface", 1)
    Slider(c, "UI Scale", 50, 150, 100, function(v)
        S.qol.uiScale = v / 100
        local us = win:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
        us.Scale = S.qol.uiScale; us.Parent = win
    end, 1, "qol.uiScale", "Scales the entire UI. 50% = half size.")
    Checkbox(c, "Dark Theme", true, function(s)
        THEME.Dark = s; applyTheme()
    end, 2, false, "qol.darkTheme", "Dark / light color scheme.")
    Button(c, "Cycle Accent Color", function()
        local cols = { Color3.fromRGB(0,120,215), Color3.fromRGB(60,190,90),
                       Color3.fromRGB(220,60,60), Color3.fromRGB(200,120,220),
                       Color3.fromRGB(255,180,30) }
        local i = 1; for k, col in ipairs(cols) do if col == THEME.Acc then i = k end end
        i = (i % #cols) + 1; THEME.Acc = cols[i]; applyTheme()
    end, 3, 24)

    local recentSec, recentContent = Section(qScroll, "Recently Toggled", 2)
    local recentLabels = {}
    local function updateRecent()
        for _, lbl in ipairs(recentLabels) do if lbl.Parent then lbl:Destroy() end end
        recentLabels = {}
        for i = 1, 5 do
            local text = RECENT[i] or "—"
            local lbl = I("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,18),
                LayoutOrder=i, Font=TH.F, Text=text,
                TextColor3=RECENT[i] and TH.Txt or TH.TxtD,
                TextSize=12, TextXAlignment=Enum.TextXAlignment.Left, Parent=recentContent })
            table.insert(recentLabels, lbl)
        end
    end
    recentUI = { update = updateRecent }
    updateRecent()
end

-- GAME INFO
do
    local giScroll = tabScrolls["Game Info"]
    local sec, c = Section(giScroll, nil, 1)
    local hdr = I("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,80), LayoutOrder=1, Parent=c })
    local thumb = I("ImageLabel", { BackgroundColor3=TH.Off, BorderSizePixel=0,
        Size=UDim2.new(0,80,0,80), Image="", ScaleType=Enum.ScaleType.Crop, Parent=hdr })
    themeIt(thumb, "BackgroundColor3", "Off")
    St(thumb, TH.BrdL, 1)
    local nm = I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0,92,0,0),
        Size=UDim2.new(1,-92,0,20), Font=TH.FB, Text="—", TextColor3=TH.Txt,
        TextSize=16, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd, Parent=hdr })
    themeIt(nm, "TextColor3", "Txt")

    local giRows = {}
    local function makeRow(key, order)
        local row = I("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,22), LayoutOrder=order, Parent=c })
        I("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0.45,0,1,0), Font=TH.F,
            Text=key, TextColor3=TH.TxtD, TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=row })
        local v = I("TextLabel", { BackgroundTransparency=1, Position=UDim2.new(0.45,0,0,0),
            Size=UDim2.new(0.55,0,1,0), Font=TH.F, Text="—", TextColor3=TH.Txt,
            TextSize=12, TextXAlignment=Enum.TextXAlignment.Right,
            TextTruncate=Enum.TextTruncate.AtEnd, Parent=row })
        giRows[key] = v
    end
    for i, k in ipairs({"Game Name","Place ID","Universe ID","Place Version","Creator ID",
        "Creator Type","Server Job ID","Server Uptime","Players","Max Players","Ping","FPS","Memory"}) do
        makeRow(k, i + 1)
    end
    local realName = game.Name
    task.spawn(function()
        local ok, info = pcall(function() return MPS:GetProductInfo(game.PlaceId, Enum.InfoType.Asset) end)
        if ok and info and info.Name then
            realName = info.Name
            giRows["Game Name"].Text = realName
            nm.Text = realName
        end
    end)
    local function refresh()
        local ping = 0; pcall(function() ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        local mem = 0; pcall(function() mem = Stats:GetTotalMemoryUsageMb() end)
        local up = math.floor(workspace.DistributedGameTime)
        giRows["Game Name"].Text = realName
        giRows["Place ID"].Text = tostring(game.PlaceId)
        giRows["Universe ID"].Text = tostring(game.GameId)
        giRows["Place Version"].Text = tostring(game.PlaceVersion)
        giRows["Creator ID"].Text = tostring(game.CreatorId)
        giRows["Creator Type"].Text = tostring(game.CreatorType):gsub("Enum.CreatorType.", "")
        giRows["Server Job ID"].Text = game.JobId ~= "" and game.JobId or "(solo)"
        giRows["Server Uptime"].Text = string.format("%dm %ds", math.floor(up/60), up%60)
        giRows["Players"].Text = tostring(#Players:GetPlayers())
        giRows["Max Players"].Text = tostring(Players.MaxPlayers)
        giRows["Ping"].Text = math.floor(ping) .. " ms"
        giRows["FPS"].Text = tostring(getFPS())
        giRows["Memory"].Text = math.floor(mem) .. " MB"
        nm.Text = realName
        thumb.Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.PlaceId) .. "&w=150&h=150"
    end
    tabHooks["Game Info"] = refresh
    task.spawn(function() while running do task.wait(1); if SG.Parent and activeTab == "Game Info" then refresh() end end end)
end

-- SETTINGS
do
    local setScroll = tabScrolls["Settings"]
    local awaitingBind = nil
    local keyDisplay = {
        [Enum.KeyCode.RightShift]="RightShift", [Enum.KeyCode.LeftShift]="LeftShift",
        [Enum.KeyCode.RightControl]="RightControl", [Enum.KeyCode.LeftControl]="LeftControl",
        [Enum.KeyCode.LeftAlt]="LeftAlt", [Enum.KeyCode.RightAlt]="RightAlt",
        [Enum.KeyCode.Insert]="Insert", [Enum.KeyCode.Delete]="Delete",
        [Enum.KeyCode.Home]="Home", [Enum.KeyCode.End]="End",
        [Enum.KeyCode.PageUp]="PageUp", [Enum.KeyCode.PageDown]="PageDown",
        [Enum.KeyCode.V]="V", [Enum.KeyCode.B]="B", [Enum.KeyCode.N]="N",
        [Enum.KeyCode.M]="M", [Enum.KeyCode.P]="P", [Enum.KeyCode.K]="K", [Enum.KeyCode.C]="C",
        [Enum.KeyCode.F1]="F1", [Enum.KeyCode.F2]="F2", [Enum.KeyCode.F3]="F3",
        [Enum.KeyCode.F4]="F4", [Enum.KeyCode.F5]="F5", [Enum.KeyCode.F6]="F6",
    }
    local function kn(kc) return keyDisplay[kc] or (kc and kc.Name) or "?" end
    local sec, c = Section(setScroll, "Keybinds (click to rebind)", 1)
    local bindRows = {}
    local function mk(key, label, order)
        local row = I("Frame", { BackgroundTransparency=1, Size=UDim2.new(1,0,0,22), LayoutOrder=order, Parent=c })
        I("TextLabel", { BackgroundTransparency=1, Size=UDim2.new(0.5,0,1,0), Font=TH.F,
            Text=label, TextColor3=TH.TxtD, TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=row })
        local btn = I("TextButton", { BackgroundColor3=TH.Off, BorderSizePixel=0,
            Position=UDim2.new(0.5,0,0,2), Size=UDim2.new(0.5,0,0,18),
            Font=TH.F, Text=kn(S.keys[key]), TextColor3=TH.Txt, TextSize=12,
            AutoButtonColor=false, Parent=row })
        themeIt(btn, "BackgroundColor3", "Off")
        themeIt(btn, "TextColor3", "Txt")
        St(btn, TH.BrdL, 1)
        bindRows[key] = btn
        btn.MouseButton1Click:Connect(function()
            if S._listening then return end
            S._listening = true; awaitingBind = key
            btn.Text = "[press a key]"; btn.TextColor3 = THEME.Acc
        end)
    end
    mk("toggleUI", "Toggle UI", 1)
    mk("freeMouse", "Toggle Free Mouse", 2)
    mk("shiftlock", "Shiftlock", 3)
    mk("freecam", "Freecam", 4)
    mk("freecamToggle", "Toggle Freecam", 5)
    mk("unload", "Unload Script", 6)

    T(UIS.InputBegan:Connect(function(input, gp)
        if not S._listening or not awaitingBind then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == Enum.KeyCode.Unknown then return end
        S.keys[awaitingBind] = input.KeyCode
        bindRows[awaitingBind].Text = kn(input.KeyCode)
        bindRows[awaitingBind].TextColor3 = TH.Txt
        Notify("Keybind", "Bound to " .. kn(input.KeyCode), "ok", 1.5)
        S._listening = false; awaitingBind = nil
        S._suppressNextKey = true
    end))

    local lifeSec, lifeContent = Section(setScroll, "Lifecycle", 2)
    Button(lifeContent, "Unload Now", function() unload() end, 1, 28)
end

-- Chams updater
T(RS.RenderStepped:Connect(function()
    local C = S.chams
    if next(C.hl) then
        local t = tick()
        for _, hl in pairs(C.hl) do
            if hl.Parent then
                if C.rainbow then
                    hl.FillColor = Color3.fromHSV((t*0.3) % 1, 0.8, 1)
                    hl.OutlineColor = Color3.fromHSV((t*0.3 + 0.5) % 1, 0.8, 1)
                else
                    if hl.FillColor ~= C.pCol then hl.FillColor = C.pCol end
                    if hl.OutlineColor ~= C.oCol then hl.OutlineColor = C.oCol end
                end
                local wf = C.outlineOnly and 1 or C.fill
                if hl.FillTransparency ~= wf then hl.FillTransparency = wf end
                local wd = C.seeThrough and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                if hl.DepthMode ~= wd then hl.DepthMode = wd end
            end
        end
    end
end))

-- Hotkeys
local uiVisible = true
local function setUIVisible(state)
    if uiVisible == state then return end
    uiVisible = state
    if state then
        SG.Enabled = true
        win.GroupTransparency = 1
        local cur = win.Position
        win.Position = UDim2.new(cur.X.Scale, cur.X.Offset, cur.Y.Scale, cur.Y.Offset+8)
        Tw(win, 0.22, { GroupTransparency=0,
            Position=UDim2.new(cur.X.Scale, cur.X.Offset, cur.Y.Scale, cur.Y.Offset) },
            Enum.EasingStyle.Quint)
        freeMouse = true
    else
        local cur = win.Position
        local t = Tw(win, 0.16, { GroupTransparency=1,
            Position=UDim2.new(cur.X.Scale, cur.X.Offset, cur.Y.Scale, cur.Y.Offset+8) },
            Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        t.Completed:Connect(function() if not uiVisible and SG then SG.Enabled = false end end)
    end
end

T(UIS.InputBegan:Connect(function(input, gp)
    if UIS:GetFocusedTextBox() then return end
    if S._listening then return end
    if S._suppressNextKey then S._suppressNextKey = false; return end
    if S.inspecting and input.KeyCode ~= S.keys.unload then return end
    local kc = input.KeyCode
    if kc == S.keys.toggleUI then setUIVisible(not uiVisible)
    elseif kc == S.keys.freeMouse then
        if not (S.camera.freecam and kc == Enum.KeyCode.LeftControl) then
            freeMouse = not freeMouse
            Notify("Mouse", freeMouse and "Unlocked" or "Locked", freeMouse and "ok" or "info", 1)
        end
    elseif kc == S.keys.shiftlock and not S.camera.freecam then
        S.shift.on = not S.shift.on
        if S.shift.on then freeMouse = false end
    elseif kc == S.keys.freecam then
        if S.camera.freecam then exitFreecam() else enterFreecam() end
    elseif kc == S.keys.freecamToggle then
        if S.camera.freecam then exitFreecam() else enterFreecam() end
    elseif kc == S.keys.unload then
        Notify("Unload", "Script unloaded", "warn", 1.5)
        task.wait(0.2); unload()
    end
end))

local dragging, dragStart, startPos
T(UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local p = input.Position
    local wp, ws = win.AbsolutePosition, win.AbsoluteSize
    if p.X < wp.X or p.X > wp.X + ws.X then return end
    if p.Y < wp.Y or p.Y > wp.Y + THGT then return end
    dragging = true; dragStart = p; startPos = win.Position
end))
T(UIS.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local d = input.Position - dragStart
    win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
end))
T(UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

-- Unload
function unload()
    running = false
    if S.camera.tp and S.camera._state then
        local st = S.camera._state
        if st.mode then pcall(function() LP.CameraMode = st.mode end) end
        if st.maxZoom then pcall(function() LP.CameraMaxZoomDistance = st.maxZoom end) end
        if st.minZoom then pcall(function() LP.CameraMinZoomDistance = st.minZoom end) end
    end
    if S.camera.freecam then pcall(exitFreecam) end
    if S.camera.fovOverride then
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = 75 end
    end
    S.camera.tp = false; S.camera.freecam = false; S.camera.fovOverride = false
    S.camera.lockAngle = false; S.camera.lockCF = nil
    S.shift.on = false
    chamsDisable()
    if S.lighting.orig then
        local o = S.lighting.orig
        Lighting.Brightness = o.Brightness; Lighting.Ambient = o.Ambient
        Lighting.OutdoorAmbient = o.OutdoorAmbient
        Lighting.ExposureCompensation = o.ExposureCompensation
        Lighting.GlobalShadows = o.GlobalShadows; Lighting.ClockTime = o.ClockTime
        Lighting.FogEnd = o.FogEnd; Lighting.FogStart = o.FogStart; Lighting.FogColor = o.FogColor
        for a, orig in pairs(o.AtmoDensity) do if a.Parent then pcall(function() a.Density = orig end) end end
        for fx, orig in pairs(o.FX) do if fx.Parent then pcall(function() fx.Enabled = orig end) end end
        for fx, orig in pairs(o.Blur) do if fx.Parent then pcall(function() fx.Enabled = orig end) end end
    end
    for c, _ in pairs(S.lighting.skyOrig) do if c then pcall(function() c.Parent = Lighting end) end end
    S.lighting.skyOrig = {}
    if S.lighting.cc then pcall(function() S.lighting.cc:Destroy() end) end
    S.lighting.day = false; S.lighting.noFog = false; S.lighting.noShadows = false
    S.lighting.noAtmo = false; S.lighting.noPostFX = false; S.lighting.noSky = false
    S.lighting.noBlur = false
    S.render.matOverride = false
    pcall(applyMaterialOverride)
    S.render.noWater = false
    pcall(applyWater)
    pcall(toggleParticles, false); pcall(toggleDecals, false); pcall(toggleShadows, false)
    if Terrain then
        for _, d in ipairs(Terrain:GetChildren()) do
            if d:IsA("Decoration") then pcall(function() d.Enabled = true end) end
        end
    end
    pcall(unmuteAllSounds)
    if S.sound.musicObj then pcall(function() S.sound.musicObj:Destroy() end) end
    ClearRakeAlert()
    for _, c in ipairs(Conn) do pcall(function() c:Disconnect() end) end
    Conn = {}
    for _, n in ipairs(Steps) do pcall(function() RS:UnbindFromRenderStep(n) end) end
    Steps = {}
    for c, _ in pairs(bbg) do pcall(function() bbg[c].gui:Destroy() end) end
    bbg = {}
    for _, l in ipairs(linePool) do pcall(function() l.frame:Destroy() end) end
    linePool = {}
    for _, hl in pairs(S.chams.hl) do pcall(function() hl:Destroy() end) end
    S.chams.hl = {}
    for c, box in pairs(DrawESP.boxes) do pcall(function() box:Remove() end) end
    DrawESP.boxes = {}
    for c, lines in pairs(DrawESP.skeletons) do
        for _, line in ipairs(lines) do pcall(function() line:Remove() end) end
    end
    DrawESP.skeletons = {}
    for c, lines in pairs(DrawESP.traj) do
        for _, line in ipairs(lines) do pcall(function() line:Remove() end) end
    end
    DrawESP.traj = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d.Name == "CUI_RakeHL" then pcall(function() d:Destroy() end) end
        if d.Name == "CUI_BBG" then pcall(function() d:Destroy() end) end
        if d.Name == "velk_InspectorClone" then pcall(function() d:Destroy() end) end
    end
    local insFolder = workspace:FindFirstChild("velk_Inspector")
    if insFolder then pcall(function() insFolder:Destroy() end) end
    for _, name in ipairs({"velk_1_248", "velk_1_248_Notifs", "velk_1_248_ESP", "velk_1_248_Vig", "velk_1_248_Key"}) do
        local g = PGui:FindFirstChild(name)
        if g then pcall(function() g:Destroy() end) end
    end
end

-- Boot
for _, c in ipairs(Lighting:GetChildren()) do
    if c:IsA("BlurEffect") or c:IsA("DepthOfFieldEffect") then
        if not S.lighting.orig then captureLight() end
        if S.lighting.orig then S.lighting.orig.Blur[c] = c.Enabled end
        c.Enabled = false
    end
end
win.GroupTransparency = 1
local cur = win.Position
win.Position = UDim2.new(cur.X.Scale, cur.X.Offset, cur.Y.Scale, cur.Y.Offset + 6)
Tw(win, 0.28, { GroupTransparency=0, Position=UDim2.new(cur.X.Scale, cur.X.Offset, cur.Y.Scale, cur.Y.Offset) }, Enum.EasingStyle.Quint)
setActiveTab("Main")
task.delay(0.5, function()
    Notify("velk 1.248", "Rake x4axq BETA Hover ⓘ for descriptions.", "ok", 4)
end)
