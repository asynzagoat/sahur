_G.SahurEntry = "sahur.lua"
_G.SahurBundleRun = true
_G.SahurEntryURL = "https://raw.githubusercontent.com/asynzagoat/sahur/main/sahur.lua"
_G.SahurSrc = {
["sahur/lib/Library.lua"] = [=[
local Library = {
    Version = "1.2.0",
    Options = {},
    Toggles = {},
    Sliders = {},
    Buttons = {},
    Dropdowns = {},
    ColorPickers = {},
    KeyPickers = {},
    Labels = {},
    ForceCheckbox = false,
    NotifySide = "Right",
    NotificationOptions = {
        Enabled = true,
        Duration = 4,
        Fade = 0.35,
        Width = 260,
        MaxVisible = 6,
        OffsetY = 16,
        Spacing = 6,
        UseCallDuration = false,
    },
}
do
    for _, key in ipairs({ "Swangy", "Obsidian" }) do
        local L = _G[key]
        if L and L.__wm then
            pcall(function() L.__wm.bg:Remove() end)
            pcall(function() L.__wm.txt:Remove() end)
            L.__wm = nil
        end
    end
    local prev = _G.__swangy_instances
    if prev then
        for _, inst in ipairs(prev) do
            pcall(function() inst:Unload() end)
        end
    end
    if _G.__swangy_wms then
        for _, w in ipairs(_G.__swangy_wms) do
            pcall(function() w.bg:Remove() end)
            pcall(function() w.txt:Remove() end)
        end
    end
    _G.__swangy_wms = {}
    _G.__swangy_instances = {}
end
_G.Swangy = Library
_G.Obsidian = Library
local function hostGet(name)
    local v
    pcall(function() v = getfenv(1)[name] end)
    if v == nil then pcall(function() v = _G[name] end) end
    return v
end
local D = hostGet("Drawing") or Drawing
local RS = hostGet("RunService") or RunService
local UIS = hostGet("UserInputService") or UserInputService
local floor, abs, min, max, clamp = math.floor, math.abs, math.min, math.max, math.clamp
local clock, fmt = os.clock, string.format
local rgb = Color3.fromRGB
local Theme = {
    bg = rgb(15, 15, 15),
    main = rgb(25, 25, 25),
    accent = rgb(125, 85, 255),
    outline = rgb(40, 40, 40),
    text = rgb(255, 255, 255),
    subtext = rgb(130, 130, 130),
    dim = rgb(160, 160, 160),
    danger = rgb(255, 50, 50),
    destructive = rgb(220, 38, 38),
    white = rgb(255, 255, 255),
    dark = rgb(0, 0, 0),
    disabled = rgb(95, 95, 95),
}
Theme.panel, Theme.panel2, Theme.stroke, Theme.strokeLit = Theme.bg, Theme.main, Theme.outline, rgb(58, 58, 58)
Theme.track, Theme.sidebar = Theme.main, Theme.bg
Library.Theme = Theme
Library.CornerRadius = 4
local FONT = (D.Fonts and (D.Fonts.Monospace or D.Fonts.SystemBold)) or 5
local function rgbToHsv(c)
    local r, g, b = c.R, c.G, c.B
    local mx = max(r, g, b)
    local mn = min(r, g, b)
    local d = mx - mn
    local h
    if d == 0 then
        h = 0
    elseif mx == r then
        h = ((g - b) / d) % 6
    elseif mx == g then
        h = (b - r) / d + 2
    else
        h = (r - g) / d + 4
    end
    h = h / 6
    local s = (mx == 0) and 0 or (d / mx)
    return h, s, mx
end
local function u16(n)
    return string.char(n % 256, floor(n / 256) % 256)
end
local function u32(n)
    return string.char(n % 256, floor(n / 256) % 256, floor(n / 65536) % 256, floor(n / 16777216) % 256)
end
local GRID_W, GRID_H = 64, 48
local function buildSVBmp(hue)
    local rows = {}
    for y = GRID_H - 1, 0, -1 do
        local v = 1 - y / (GRID_H - 1)
        local row = {}
        for x = 0, GRID_W - 1 do
            local s = x / (GRID_W - 1)
            local c = Color3.fromHSV(hue, s, v)
            row[#row + 1] = string.char(floor(c.B * 255 + 0.5), floor(c.G * 255 + 0.5), floor(c.R * 255 + 0.5))
        end
        local pad = (4 - (GRID_W * 3) % 4) % 4
        rows[#rows + 1] = table.concat(row) .. string.rep("\0", pad)
    end
    local pixels = table.concat(rows)
    local dib = u32(40) .. u32(GRID_W) .. u32(GRID_H) .. u16(1) .. u16(24) .. u32(0)
        .. u32(#pixels) .. u32(2835) .. u32(2835) .. u32(0) .. u32(0)
    return "BM" .. u32(14 + 40 + #pixels) .. u32(0) .. u32(54) .. dib .. pixels
end
local LOGO_D =
    "M161.0 225.0 L129.5 191.0 L0.0 336.2 L62.2 336.0Z " ..
    "M51.0 139.5 L20.5 174.2 L67.8 226.8 L98.5 192.2Z " ..
    "M284.5 121.0 L253.5 155.5 L301.0 208.2 L331.8 173.5Z " ..
    "M0.0 11.2 L67.2 86.8 L98.5 52.8 L61.5 11.0Z " ..
    "M352.0 11.0 L290.8 11.0 L176.0 138.8 L145.0 103.8 L175.8 69.5 L192.5 87.2 " ..
    "L223.2 52.5 L175.8 0.0 L82.8 103.5 L207.2 243.2 L176.8 278.0 L159.8 260.5 " ..
    "L129.0 294.8 L175.8 347.8 L269.2 244.0 L207.5 173.2Z"
local LOGO_SUBS, LOGO_MINX, LOGO_MINY, LOGO_MAXX, LOGO_MAXY = {}, math.huge, math.huge, -math.huge, -math.huge
do
    local function numbers(s)
        local t = {}
        for n in s:gmatch("[-+]?%d*%.?%d+") do t[#t + 1] = tonumber(n) end
        return t
    end
    for cmd, body in LOGO_D:gmatch("([MLZ])([^MLZ]*)") do
        if cmd == "M" then
            local poly, ns = {}, numbers(body)
            for i = 1, #ns - 1, 2 do
                poly[#poly + 1] = { ns[i], ns[i + 1] }
            end
            LOGO_SUBS[#LOGO_SUBS + 1] = poly
        elseif cmd == "L" then
            local poly, ns = LOGO_SUBS[#LOGO_SUBS], numbers(body)
            for i = 1, #ns - 1, 2 do
                poly[#poly + 1] = { ns[i], ns[i + 1] }
            end
        end
    end
    for _, poly in ipairs(LOGO_SUBS) do
        for _, p in ipairs(poly) do
            if p[1] < LOGO_MINX then LOGO_MINX = p[1] end
            if p[2] < LOGO_MINY then LOGO_MINY = p[2] end
            if p[1] > LOGO_MAXX then LOGO_MAXX = p[1] end
            if p[2] > LOGO_MAXY then LOGO_MAXY = p[2] end
        end
    end
end
local function logoInside(sx, sy)
    local c = false
    for _, poly in ipairs(LOGO_SUBS) do
        local n = #poly
        for i = 1, n do
            local a, b = poly[i], poly[i % n + 1]
            if ((a[2] > sy) ~= (b[2] > sy)) then
                local xint = (b[1] - a[1]) * (sy - a[2]) / (b[2] - a[2]) + a[1]
                if sx < xint then c = not c end
            end
        end
    end
    return c
end
local function buildLogoBmp(size, bg, accent)
    local spanx = LOGO_MAXX - LOGO_MINX
    local spany = LOGO_MAXY - LOGO_MINY
    local rows = {}
    for py = 0, size - 1 do
        local row = {}
        local sy = LOGO_MINY + (py + 0.5) / size * spany
        for px = 0, size - 1 do
            local sx = LOGO_MINX + (px + 0.5) / size * spanx
            local r, g, b
            if logoInside(sx, sy) then
                local t = ((px + 0.5) + (py + 0.5)) / (2 * size)
                r = accent.R * t
                g = accent.G * t
                b = accent.B * t
            else
                r, g, b = bg.R, bg.G, bg.B
            end
            row[#row + 1] = string.char(floor(b * 255 + 0.5), floor(g * 255 + 0.5), floor(r * 255 + 0.5))
        end
        rows[size - py] = table.concat(row)
    end
    local pixels = table.concat(rows)
    local pad = (4 - (size * 3) % 4) % 4
    local padded = {}
    for i = 1, #rows do padded[i] = rows[i] .. string.rep("\0", pad) end
    pixels = table.concat(padded)
    local dib = u32(40) .. u32(size) .. u32(size) .. u16(1) .. u16(24) .. u32(0)
        .. u32(#pixels) .. u32(2835) .. u32(2835) .. u32(0) .. u32(0)
    return "BM" .. u32(14 + 40 + #pixels) .. u32(0) .. u32(54) .. dib .. pixels
end
local LogoImage, LogoKey
local function mix(a, b, t)
    return rgb(
        floor(a.R * 255 + (b.R * 255 - a.R * 255) * t + 0.5),
        floor(a.G * 255 + (b.G * 255 - a.G * 255) * t + 0.5),
        floor(a.B * 255 + (b.B * 255 - a.B * 255) * t + 0.5)
    )
end
local ALL = {}
Library.__all = ALL
local function newObj(kind, z)
    local d = D.new(kind)
    if kind == "Text" then
        pcall(function() d.Font = FONT end)
    end
    if z then pcall(function() d.ZIndex = z end) end
    pcall(function() d.Visible = false end)
    local o = { d = d, sc = { Visible = false }, isText = (kind == "Text") }
    ALL[#ALL + 1] = o
    return o
end
local function zset(o, z)
    local d = o and (o.d or o)
    if d then pcall(function() d.ZIndex = z end) end
end
local function ensureLogo()
    if LogoImage then return LogoImage end
    LogoImage = newObj("Image", 9)
    Library.__logo = LogoImage
    return LogoImage
end
local function put(o, k, v)
    if o.sc[k] ~= v then
        o.sc[k] = v
        o.d[k] = v
    end
end
local function putV(o, k, x, y)
    local c = o.sc[k]
    if not c or c[1] ~= x or c[2] ~= y then
        o.sc[k] = { x, y }
        o.d[k] = Vector2.new(x, y)
    end
end
local function putC(o, k, col)
    local c = o.sc[k]
    local r, g, b = col.R, col.G, col.B
    if not c or c[1] ~= r or c[2] ~= g or c[3] ~= b then
        o.sc[k] = { r, g, b }
        o.d[k] = col
    end
end
local function fill(o, x, y, w, h, color, alpha, radius)
    if w <= 0 or h <= 0 then
        put(o, "Visible", false)
        return
    end
    putV(o, "Position", x, y)
    putV(o, "Size", w, h)
    putC(o, "Color", color or Theme.main)
    put(o, "Transparency", alpha or 1)
    put(o, "Filled", true)
    put(o, "Corner", radius or 0)
    put(o, "Visible", true)
end
local function stroke(o, x, y, w, h, color, alpha, radius, thickness)
    if w <= 0 or h <= 0 then
        put(o, "Visible", false)
        return
    end
    putV(o, "Position", x, y)
    putV(o, "Size", w, h)
    putC(o, "Color", color or Theme.outline)
    put(o, "Transparency", alpha or 1)
    put(o, "Filled", false)
    put(o, "Thickness", thickness or 1)
    put(o, "Corner", radius or 0)
    put(o, "Visible", true)
end
local function text(o, x, y, str, size, color, alpha, center, outline)
    put(o, "Text", tostring(str))
    put(o, "Size", size or 14)
    putV(o, "Position", x, y)
    putC(o, "Color", color or Theme.text)
    put(o, "Transparency", alpha or 1)
    put(o, "Center", center == true)
    put(o, "Outline", outline == true)
    put(o, "Visible", true)
end
local function line(o, x1, y1, x2, y2, color, alpha, thickness)
    putV(o, "From", x1, y1)
    putV(o, "To", x2, y2)
    putC(o, "Color", color or Theme.outline)
    put(o, "Transparency", alpha or 1)
    put(o, "Thickness", thickness or 1)
    put(o, "Visible", true)
end
local MEAS = D.new("Text")
MEAS.Visible = false
pcall(function() MEAS.Font = FONT end)
local wcache, wcount = {}, 0
local function textW(str, size)
    str, size = tostring(str), size or 14
    local key = size .. "|" .. str
    local v = wcache[key]
    if v then return v end
    MEAS.Text = str
    MEAS.Size = size
    local w = MEAS.TextBounds.X
    wcount = wcount + 1
    if wcount > 900 then wcache, wcount = {}, 0 end
    wcache[key] = w
    return w
end
local function insideRect(r, x, y)
    return x and y and x >= r[1] and x <= r[1] + r[3] and y >= r[2] and y <= r[2] + r[4]
end
local function vc(y, h, size)
    return y + floor((h - size) / 2 + 0.5)
end
local function clipText(str, size, maxW)
    str = tostring(str)
    if maxW <= 0 then return "" end
    if textW(str, size) <= maxW then return str end
    local ell = "..."
    while #str > 0 and textW(str, size) > maxW - textW(ell, size) do
        str = str:sub(1, #str - 1)
    end
    return str .. ell
end
local function textC(o, cx, y, str, size, color, alpha, outline)
    str = tostring(str)
    text(o, cx - textW(str, size) / 2, y, str, size, color, alpha, false, outline)
end
local Players = _G.__swangy_players
if not Players then pcall(function() Players = game:GetService("Players") end) end
local Mouse = _G.__swangy_mouse
local function mouseAlive(m)
    if not m then return false end
    local ok, x = pcall(function() return m.X end)
    return ok and type(x) == "number"
end
local function getMouse()
    if mouseAlive(Mouse) then return Mouse end
    Mouse = nil
    if not Players then Players = _G.__swangy_players end
    if not Players then
        pcall(function() Players = game:GetService("Players") end)
    end
    if Players then
        _G.__swangy_players = Players
        local lp
        pcall(function() lp = Players.LocalPlayer end)
        if not lp then lp = _G.__swangy_localplayer end
        if lp then
            _G.__swangy_localplayer = lp
            pcall(function() Mouse = lp:GetMouse() end)
        end
    end
    if mouseAlive(Mouse) then
        _G.__swangy_mouse = Mouse
        return Mouse
    end
    Mouse = nil
    return nil
end
local mx, my
local m1 = { down = false, pressed = false, released = false }
local m2 = { down = false, pressed = false }
local m1prev = false
local m2prev = false
local m1latched = false
local m1lastDown = 0
local function poll()
    local m = getMouse()
    if m then
        local okx, xx = pcall(function() return m.X end)
        local oky, yy = pcall(function() return m.Y end)
        if okx and oky then mx, my = xx, yy end
    end
    local down = ismouse1pressed() and true or false
    if down then m1lastDown = clock() end
    if not down and (clock() - m1lastDown) > 0.08 then m1latched = false end
    m1prev = m1.down
    m1.down = down
    m1.pressed = down and not m1latched
    if m1.pressed then m1latched = true end
    m1.released = (not down) and m1prev
    local down2 = ismouse2pressed() and true or false
    m2prev = m2.down
    m2.down = down2
    m2.pressed = down2 and not m2prev
    Library.__mouse = { x = mx, y = my, down = m1.down, pressed = m1.pressed }
end
local kstate = {}
local function keyDown(vk)
    if vk == 1 then return ismouse1pressed() and true or false end
    if vk == 2 then return ismouse2pressed() and true or false end
    return iskeypressed(vk) and true or false
end
local function keyEdge(vk)
    local down = keyDown(vk)
    local was = kstate[vk]
    kstate[vk] = down
    return down and not was
end
local VK = {
    Backspace = 8, Tab = 9, Enter = 13, Shift = 16, Ctrl = 17, Alt = 18, CapsLock = 20, Escape = 27, Space = 32,
    PageUp = 33, PageDown = 34, End = 35, Home = 36, Left = 37, Up = 38, Right = 39, Down = 40,
    Insert = 45, Delete = 46,
    ["0"] = 48, ["1"] = 49, ["2"] = 50, ["3"] = 51, ["4"] = 52, ["5"] = 53, ["6"] = 54, ["7"] = 55, ["8"] = 56, ["9"] = 57,
    A = 65, B = 66, C = 67, D = 68, E = 69, F = 70, G = 71, H = 72, I = 73, J = 74, K = 75, L = 76, M = 77,
    N = 78, O = 79, P = 80, Q = 81, R = 82, S = 83, T = 84, U = 85, V = 86, W = 87, X = 88, Y = 89, Z = 90,
    F1 = 112, F2 = 113, F3 = 114, F4 = 115, F5 = 116, F6 = 117, F7 = 118, F8 = 119, F9 = 120, F10 = 121, F11 = 122, F12 = 123,
    LeftShift = 160, RightShift = 161, LeftCtrl = 162, RightCtrl = 163, LeftAlt = 164, RightAlt = 165,
    LeftControl = 162, RightControl = 163, Control = 17, Shift = 16, Alt = 18,
    NumLock = 144, ScrollLock = 145, CapsLockKey = 20, Menu = 93,
    LMB = 1, RMB = 2, MMB = 4, MB4 = 5, MB5 = 6,
}
local VK_NAME = {}
for n, c in pairs(VK) do if not VK_NAME[c] then VK_NAME[c] = n end end
local function keyToVk(k)
    if type(k) == "number" then return k end
    if type(k) ~= "string" or k == "" then return nil end
    if VK[k] then return VK[k] end
    local up = k:upper()
    if VK[up] then return VK[up] end
    if #k == 1 then return VK[up] end
    local norm = up:gsub("[%s_%-]", "")
    for name, code in pairs(VK) do
        if name:upper() == norm then return code end
    end
    return nil
end
local function vkName(vk) return VK_NAME[vk] or tostring(vk) end
local capturing
local focusedInput
local function shiftDown()
    return iskeypressed(16) or iskeypressed(160) or iskeypressed(161)
end
local function codeToChar(code)
    local shift = shiftDown()
    if code >= 65 and code <= 90 then
        local ch = string.char(code)
        return shift and ch or ch:lower()
    elseif code >= 97 and code <= 122 then
        local ch = string.char(code)
        return shift and ch:upper() or ch
    elseif code >= 48 and code <= 57 then
        return string.char(code)
    elseif code >= 96 and code <= 105 then
        return tostring(code - 96)
    elseif code == 32 then
        return " "
    elseif code == 189 then
        return shift and "_" or "-"
    elseif code == 190 then
        return "."
    elseif code == 191 then
        return "/"
    end
    return nil
end
local INPUT_CODES = { 8, 13, 27, 32, 189, 190, 191 }
for i = 48, 57 do INPUT_CODES[#INPUT_CODES + 1] = i end
for i = 65, 90 do INPUT_CODES[#INPUT_CODES + 1] = i end
for i = 96, 105 do INPUT_CODES[#INPUT_CODES + 1] = i end
local ALL_KEYS = {}
local seenKey = {}
for _, v in pairs(VK) do
    if type(v) == "number" and not seenKey[v] then
        seenKey[v] = true
        ALL_KEYS[#ALL_KEYS + 1] = v
    end
end
local hitList, activeDrag = {}, nil
local popupElements, openPopup = {}, nil
local function clearPopup(except)
    for _, el in ipairs(popupElements) do
        if el ~= except and el.popupOpen then el:ClosePopup() end
    end
end
local function newHit(x, y, w, h, hnd)
    hnd[1], hnd[2], hnd[3], hnd[4] = x, y, w, h
    hitList[#hitList + 1] = hnd
    return hnd
end
local function processInput()
    if not mx then activeDrag = nil return end
    local consumed = false
    if m1.pressed and openPopup then
        local r = openPopup:PopupRect()
        if r and not insideRect(r, mx, my) then
            openPopup:ClosePopup()
            consumed = true
            activeDrag = nil
        end
    end
    if m1.pressed and not consumed then
        local hit
        for i = #hitList, 1, -1 do
            local h = hitList[i]
            if insideRect(h, mx, my) then hit = h break end
        end
        activeDrag = hit
        if hit and hit.press then pcall(hit.press, mx, my) end
    end
    if activeDrag and activeDrag.drag and m1.down then pcall(activeDrag.drag, mx, my) end
    if m1.released then
        if activeDrag and activeDrag.release then pcall(activeDrag.release, mx, my) end
        activeDrag = nil
    end
end
local function hovered(x, y, w, h)
    return insideRect({ x, y, w, h }, mx, my)
end
local Windows = {}
local menuVk = VK.RightShift
local watermarkOn = true
local fps, frameCount, fpsClock = 0, 0, clock()
local notifs = {}
local function hideAll()
    for _, o in ipairs(ALL) do
        pcall(function()
            o.sc.Visible = false
            o.d.Visible = false
        end)
    end
end
function Library:SetMenuKey(k)
    local v = keyToVk(k)
    if v then menuVk = v end
    return self
end
function Library:SetAccent(c)
    Theme.accent = c
    return self
end
function Library:SetTheme(t)
    for k, v in pairs(t or {}) do if Theme[k] ~= nil then Theme[k] = v end end
    return self
end
function Library:SetWatermark(on)
    watermarkOn = on ~= false
    return self
end
function Library:GetWindow() return Windows[1] end
local FONT_CHOICES = {
    { "Monospace", D.Fonts and D.Fonts.Monospace },
    { "System", D.Fonts and (D.Fonts.System or D.Fonts.SystemBold) },
    { "Proxima Soft", D.Fonts and D.Fonts.ProximaSoftBold },
}
Library.Fonts = {}
Library.FontOrder = {}
for _, pair in ipairs(FONT_CHOICES) do
    if pair[2] ~= nil then
        Library.Fonts[pair[1]] = pair[2]
        Library.FontOrder[#Library.FontOrder + 1] = pair[1]
    end
end
function Library:SetFont(font)
    local fv = font
    if type(font) == "string" then fv = Library.Fonts[font] end
    if fv == nil then return self end
    FONT = fv
    pcall(function() MEAS.Font = FONT end)
    wcache, wcount = {}, 0
    for _, o in ipairs(ALL) do
        if o.isText then pcall(function() o.d.Font = FONT end) end
    end
    return self
end
local function removeDrawings(list)
    for _, o in ipairs(list) do pcall(function() o.d:Remove() end) end
end
local function removeNotif(n)
    removeDrawings({ { d = n.bg }, { d = n.bar }, { d = n.tt }, { d = n.mt } })
end
function Library:ClearNotifications()
    for i = #notifs, 1, -1 do
        removeNotif(notifs[i])
        table.remove(notifs, i)
    end
end
function Library:PreviewNotification(msg, title)
    local opts = Library.NotificationOptions
    local was = opts.Enabled
    opts.Enabled = true
    local n = Library:Notify(msg or "Preview notification", nil, title or "Preview")
    opts.Enabled = was
    return n
end
function Library:Notify(msg, duration, title)
    local opts = Library.NotificationOptions
    if not opts.Enabled then
        return nil
    end
    local dur = opts.UseCallDuration and duration or opts.Duration
    local n = {
        msg = tostring(msg), title = tostring(title or "Notification"),
        t = clock(), dur = dur or 4,
        bg = D.new("Square"), bar = D.new("Square"), tt = D.new("Text"), mt = D.new("Text"),
    }
    n.bg.Filled, n.bg.Corner = true, Library.CornerRadius
    n.bar.Filled, n.bar.Corner = true, 2
    n.tt.Size, n.mt.Size = 14, 14
    n.bg.Visible, n.bar.Visible, n.tt.Visible, n.mt.Visible = false, false, false, false
    pcall(function() n.tt.Font = FONT; n.mt.Font = FONT end)
    zset(n.bg, 200); zset(n.bar, 201); zset(n.tt, 202); zset(n.mt, 202)
    table.insert(notifs, 1, n)
    while #notifs > (opts.MaxVisible or 6) do
        removeNotif(table.remove(notifs))
    end
    return n
end
local function renderNotifs()
    local opts = Library.NotificationOptions
    local right = Library.NotifySide ~= "Left"
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local w = opts.Width or 260
    local x = right and (vp.X - w - 16) or 16
    local now = clock()
    for i = #notifs, 1, -1 do
        local n = notifs[i]
        local age = now - n.t
        if age > n.dur then
            removeNotif(n)
            table.remove(notifs, i)
        else
            local alpha = 1
            local fade = opts.Fade or 0
            if fade > 0 and (n.dur - age) < fade then
                alpha = (n.dur - age) / fade
            end
            local h = 56
            local yy = (opts.OffsetY or 16) + (i - 1) * (h + (opts.Spacing or 6))
            n.bg.Position, n.bg.Size = Vector2.new(x, yy), Vector2.new(w, h)
            n.bg.Color, n.bg.Transparency = Theme.main, alpha
            n.bg.Visible = true
            n.bar.Position, n.bar.Size = Vector2.new(x + 1, yy + 6), Vector2.new(3, h - 12)
            n.bar.Color, n.bar.Transparency = Theme.accent, alpha
            n.bar.Visible = true
            n.tt.Position, n.tt.Text, n.tt.Color, n.tt.Transparency = Vector2.new(x + 14, yy + 9), clipText(n.title, 14, w - 28), Theme.text, alpha
            n.tt.Visible = true
            n.mt.Position, n.mt.Text, n.mt.Color, n.mt.Transparency = Vector2.new(x + 14, yy + 30), clipText(n.msg, 14, w - 28), Theme.subtext, alpha
            n.mt.Visible = true
        end
    end
end
local Element = {}
Element.__index = Element
function Element:OnChanged(fn) table.insert(self.changed, fn) return self end
function Element:Fire(...)
    for _, fn in ipairs(self.changed) do pcall(fn, ...) end
    return self
end
function Element:SetVisible(b) self.visible = b ~= false return self end
function Element:SetDisabled(b) self.disabled = b == true return self end
function Element:Destroy()
    self.destroyed = true
    for _, o in ipairs(self.objects) do pcall(function() o.d:Remove() end) end
end
local function newElement(cls, id, label)
    local el = setmetatable({}, Element)
    for k, v in pairs(cls) do if el[k] == nil then el[k] = v end end
    el.id, el.text = id, label or id
    el.changed, el.objects = {}, {}
    el.visible, el.disabled = true, false
    el.addons = {}
    el.kind = cls.__kind
    return el
end
local function mkText(el, size)
    local o = newObj("Text", 30)
    o.d.Size = size or 14
    o.d.Outline = false
    table.insert(el.objects, o)
    return o
end
local function mkSq(el, z)
    local o = newObj("Square", z or 20)
    table.insert(el.objects, o)
    return o
end
local function mkLine(el, z)
    local o = newObj("Line", z or 20)
    table.insert(el.objects, o)
    return o
end
local function beginCapture(el)
    capturing = el
    for _, code in ipairs(ALL_KEYS) do
        kstate[code] = keyDown(code)
    end
end
local KeyPicker = {}
KeyPicker.__index = KeyPicker
KeyPicker.__kind = "KeyPicker"
KeyPicker.TypeKey = true
function KeyPicker:GetHeight() return 21 end
function KeyPicker:GetState() return self.state end
function KeyPicker:SetValue(v)
    if type(v) == "table" then
        local vk = keyToVk(v[1]); if vk then self.vk = vk end
        if v[2] then self.mode = v[2] end
    else
        local vk = keyToVk(v); if vk then self.vk = vk end
    end
    self.state = false
    self:Fire(self)
    return self
end
function KeyPicker:Capture(code)
    capturing = nil
    self.vk = code
    self.state = false
    if self.changedCallback then pcall(self.changedCallback, self) end
    self:Fire(self)
end
function KeyPicker:NotifyState(on)
    if self.syncParent and #(self.syncParent.changed or {}) > 0 then
        return
    end
    local label = (self.text and self.text ~= self.id) and self.text or vkName(self.vk)
    if Library and Library.Notify then
        Library:Notify(label .. (on and "  [ ON ]" or "  [ OFF ]"), 1.6, "Keybind")
    end
end
function KeyPicker:Evaluate()
    if capturing == self or not self.vk then return end
    if self.mode == "Always" then
        if not self.state then
            self.state = true
            self:Fire(self)
            self:NotifyState(true)
        end
        return
    end
    local down = keyDown(self.vk)
    if self.mode == "Hold" then
        if down ~= self.state then
            self.state = down
            self:Fire(self)
            self:NotifyState(down)
        end
    elseif keyEdge(self.vk) then
        self.state = not self.state
        self:Fire(self)
        self:NotifyState(self.state)
    end
end
function KeyPicker:AddKeyPicker() return self end
function KeyPicker:CloseModePopup()
    self.modeOpen = false
    if openPopup == self then openPopup = nil end
    if self.modeBg then put(self.modeBg, "Visible", false) end
    if self.modeBorder then put(self.modeBorder, "Visible", false) end
    for _, o in ipairs(self.modeTexts or {}) do put(o, "Visible", false) end
    for _, o in ipairs(self.modeCells or {}) do put(o, "Visible", false) end
end
function KeyPicker:ClosePopup() return self:CloseModePopup() end
function KeyPicker:PopupRect() return { self.mpx, self.mpy, self.mpw, self.mph } end
function KeyPicker:OpenModePopup()
    clearPopup(self)
    self.modeOpen = true
    openPopup = self
end
function KeyPicker:RenderPopup()
    if not self.modeOpen then return end
    local modes = { "Hold", "Toggle", "Always" }
    local rowH = 20
    local pw, ph = 88, rowH * #modes + 6
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local px, py = self.boxX or 0, (self.boxY or 0) + (self.boxH or 18) + 2
    if px + pw > vp.X - 8 then px = vp.X - pw - 8 end
    if py + ph > vp.Y - 8 then py = (self.boxY or 0) - ph - 2 end
    self.mpx, self.mpy, self.mpw, self.mph = px, py, pw, ph
    if not self.modeBg then
        self.modeBg, self.modeBorder = newObj("Square", 110), newObj("Square", 111)
        self.modeTexts, self.modeCells = {}, {}
        table.insert(self.objects, self.modeBg)
        table.insert(self.objects, self.modeBorder)
    end
    fill(self.modeBg, px, py, pw, ph, Theme.bg, 1, 4)
    stroke(self.modeBorder, px, py, pw, ph, Theme.outline, 1, 4, 1)
    put(self.modeBg, "Visible", true)
    put(self.modeBorder, "Visible", true)
    newHit(px, py, pw, ph, { press = function() end })
    for i, m in ipairs(modes) do
        local o = self.modeTexts[i]
        if not o then o = newObj("Text", 112) o.d.Size = 14 table.insert(self.objects, o) self.modeTexts[i] = o end
        local cell = self.modeCells[i]
        if not cell then cell = newObj("Square", 111) table.insert(self.objects, cell) self.modeCells[i] = cell end
        local ry = py + 3 + (i - 1) * rowH
        local hv = hovered(px + 3, ry, pw - 6, rowH)
        if hv then fill(cell, px + 3, ry, pw - 6, rowH, Theme.accent, 0.18, 2) else put(cell, "Visible", false) end
        text(o, px + 8, ry + 3, m, 14, self.mode == m and Theme.accent or Theme.text, 1, false, false)
        newHit(px + 3, ry, pw - 6, rowH, {
            press = function()
                self.mode = m
                self.state = false
                self:CloseModePopup()
                self:Fire(self)
            end,
        })
    end
end
function KeyPicker:RenderInline(x, y, h)
    local bw = 68
    local bx = x - bw
    self.boxX, self.boxY, self.boxW, self.boxH = bx, y, bw, h
    fill(self.bg, bx, y + (h - 15) / 2, bw, 15, Theme.main, 1, 2)
    stroke(self.border, bx, y + (h - 15) / 2, bw, 15, (capturing == self or self.modeOpen) and Theme.accent or Theme.outline, 1, 2, 1)
    local shown = capturing == self and "[...]" or vkName(self.vk)
    textC(self.keyText, bx + bw / 2, vc(y + (h - 15) / 2, 15, 14), clipText(shown, 14, bw - 6), 14, Theme.subtext, 1, false)
    if hovered(bx, y, bw, h) and m2.pressed then
        self:OpenModePopup()
    end
    newHit(bx, y, bw, h, {
        press = function()
            beginCapture(self)
            self:CloseModePopup()
        end,
    })
end
local Grid = { cells = {}, hue = {}, alpha = {}, hueKey = nil }
Library.__grid = Grid
local function ensureGrid()
    if Grid.cursor then return end
    Grid.svImage = newObj("Image", 102)
    for i = 1, 32 do Grid.hue[i] = newObj("Square", 101) end
    Grid.chk = {}
    for i = 1, 32 do Grid.chk[i] = newObj("Square", 101) end
    for i = 1, 16 do Grid.alpha[i] = newObj("Square", 102) end
    Grid.cursor = newObj("Square", 106)
    Grid.cursorH = newObj("Square", 106)
end
local function hideGrid()
    if Grid.svImage then
        Grid.svImage.sc.Visible = false
        Grid.svImage.d.Visible = false
    end
    for _, o in ipairs(Grid.hue) do put(o, "Visible", false) end
    for _, o in ipairs(Grid.alpha) do put(o, "Visible", false) end
    for _, o in ipairs(Grid.chk or {}) do put(o, "Visible", false) end
    if Grid.cursor then put(Grid.cursor, "Visible", false) end
    if Grid.cursorH then put(Grid.cursorH, "Visible", false) end
end
local ColorPicker = {}
ColorPicker.__index = ColorPicker
ColorPicker.__kind = "ColorPicker"
function ColorPicker:GetHeight() return 21 end
function ColorPicker:Color() return Color3.fromHSV(self.h or 0.72, self.s or 0.6, self.v or 1) end
function ColorPicker:SetValueRGB(c, t)
    self.value = c
    if t then self.alpha = 1 - t end
    self.h, self.s, self.v = rgbToHsv(c)
    self:Fire(self.value, self.alpha)
    return self
end
function ColorPicker:SetValue(hsv, t)
    if hsv then self.h, self.s, self.v = hsv.H or self.h, hsv.S or self.s, hsv.V or self.v end
    if t then self.alpha = 1 - t end
    self.value = self:Color()
    self:Fire(self.value, self.alpha)
    return self
end
function ColorPicker:Key(code)
    if not self.hexEditing then return end
    if code == 13 then
        local t = self.hexBuf or ""
        if #t == 6 then
            local ok, c = pcall(Color3.fromHex, t)
            if ok and c then
                self:SetValueRGB(c, 1 - (self.alpha or 1))
            end
        end
        self.hexEditing = false
        focusedInput = nil
    elseif code == 27 then
        self.hexEditing = false
        focusedInput = nil
    elseif code == 8 then
        self.hexBuf = (self.hexBuf or ""):sub(1, -2)
    else
        local ch
        if code >= 48 and code <= 57 then
            ch = string.char(code)
        elseif code >= 65 and code <= 70 then
            ch = string.char(code)
        elseif code >= 97 and code <= 102 then
            ch = string.char(code):upper()
        end
        if ch and #(self.hexBuf or "") < 6 then
            self.hexBuf = (self.hexBuf or "") .. ch
        end
    end
end
function ColorPicker:ClosePopup()
    self.popupOpen = false
    self.hexEditing = false
    if focusedInput == self then focusedInput = nil end
    if openPopup == self then openPopup = nil end
    put(self.popupBg, "Visible", false)
    put(self.popupBorder, "Visible", false)
    put(self.svBase, "Visible", false)
    hideGrid()
    for _, o in ipairs({ self.hexLabel, self.alphaBG, self.alphaSwatch, self.hexBg, self.hexBorder }) do put(o, "Visible", false) end
end
function ColorPicker:PopupRect() return { self.px, self.py, self.pw, self.ph } end
function ColorPicker:OpenPopup()
    clearPopup(self)
    self.popupOpen = true
    openPopup = self
end
function ColorPicker:RenderInline(x, y, h, anchorRight)
    local s = 18
    local sx = anchorRight and (x - s) or x
    fill(self.swatch, sx, y + (h - s) / 2, s, s, self:Color(), self.alpha or 1, 2)
    stroke(self.swatchBorder, sx, y + (h - s) / 2, s, s, Theme.outline, 1, 2, 1)
    newHit(sx, y, s, h, {
        press = function()
            if self.popupOpen then self:ClosePopup() else self:OpenPopup() end
        end,
    })
    self.hx, self.hy, self.hw = sx, y, s
end
function ColorPicker:RenderPopup()
    if not self.popupOpen then return end
    local pw, ph = 204, 182
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local px, py = self.hx - pw + 20, self.hy + 24
    if px < 8 then px = 8 end
    if px + pw > vp.X - 8 then px = vp.X - pw - 8 end
    if py + ph > vp.Y - 8 then py = self.hy - ph - 8 end
    if py < 8 then py = 8 end
    self.px, self.py, self.pw, self.ph = px, py, pw, ph
    fill(self.popupBg, px, py, pw, ph, Theme.bg, 1, 4)
    stroke(self.popupBorder, px, py, pw, ph, Theme.outline, 1, 4, 1)
    newHit(px, py, pw, ph, { press = function() end })
    ensureGrid()
    local gx, gy, gw, gh = px + 8, py + 8, pw - 16, 108
    fill(self.svBase, gx, gy, gw, gh, Color3.fromHSV(self.h, 1, 1), 1, 0)
    local hk = floor(self.h * 100 + 0.5)
    if Grid.hueKey ~= hk then
        Grid.hueKey = hk
        Grid.svImage.d.Data = buildSVBmp(self.h)
    end
    Grid.svImage.d.Position = Vector2.new(gx, gy)
    Grid.svImage.d.Size = Vector2.new(gw, gh)
    put(Grid.svImage, "Visible", true)
    fill(Grid.cursor, gx + self.s * gw - 3, gy + (1 - self.v) * gh - 3, 6, 6, Theme.white, 1, 0)
    local function svSet(xx, yy)
        self.s = clamp((xx - gx) / gw, 0, 1)
        self.v = clamp(1 - (yy - gy) / gh, 0, 1)
        self.value = self:Color()
        self:Fire(self.value, self.alpha)
    end
    newHit(gx, gy, gw, gh, { press = svSet, drag = svSet })
    local hx, hy, hw2, hh2 = px + 8, py + 124, pw - 16, 10
    local segs = 32
    for i = 1, segs do
        local o = Grid.hue[i]
        fill(o, hx + (i - 1) / segs * hw2, hy, hw2 / segs + 0.6, hh2, Color3.fromHSV((i - 0.5) / segs, 1, 1), 1, 0)
        put(o, "Visible", true)
    end
    fill(Grid.cursorH, hx + self.h * hw2 - 1, hy - 1, 2, hh2 + 2, Theme.white, 1, 0)
    local function hueSet(xx)
        self.h = clamp((xx - hx) / hw2, 0, 0.999)
        self.value = self:Color()
        self:Fire(self.value, self.alpha)
    end
    newHit(hx, hy, hw2, hh2, { press = hueSet, drag = function(xx) hueSet(xx) end })
    local ax, ay, aw = px + 8, py + 142, pw - 16
    local acount = 16
    local cc = self:Color()
    local CHK_A, CHK_B = Color3.fromRGB(200, 200, 200), Color3.fromRGB(120, 120, 120)
    for i = 1, 32 do
        local col, row = (i - 1) % 16, floor((i - 1) / 16)
        local o = Grid.chk[i]
        fill(o, ax + col / 16 * aw, ay + row * 5, aw / 16 + 0.6, 5, ((col + row) % 2 == 0) and CHK_A or CHK_B, 1, 0)
        put(o, "Visible", true)
    end
    for i = 1, acount do
        local o = Grid.alpha[i]
        fill(o, ax + (i - 1) / acount * aw, ay, aw / acount + 0.6, 10, cc, (i - 0.5) / acount, 0)
        put(o, "Visible", true)
    end
    local function alphaSet(xx)
        self.alpha = clamp((xx - ax) / aw, 0, 1)
        self.value = self:Color()
        self:Fire(self.value, self.alpha)
    end
    newHit(ax, ay, aw, 10, { press = alphaSet, drag = function(xx) alphaSet(xx) end })
    local c = self:Color()
    local hex = fmt("#%02X%02X%02X", floor(c.R * 255 + 0.5), floor(c.G * 255 + 0.5), floor(c.B * 255 + 0.5))
    local hx, hy, hw, hh = px + 8, py + 154, 96, 20
    if self.hexEditing and m1.pressed and not hovered(hx, hy, hw, hh) then
        self.hexEditing = false
        if focusedInput == self then focusedInput = nil end
    end
    fill(self.hexBg, hx, hy, hw, hh, Theme.main, 1, 2)
    put(self.hexBg, "Visible", true)
    stroke(self.hexBorder, hx, hy, hw, hh, self.hexEditing and Theme.accent or Theme.outline, 1, 2, 1)
    put(self.hexBorder, "Visible", true)
    local shown = self.hexEditing and ("#" .. (self.hexBuf or "") .. ((clock() % 1) < 0.5 and "|" or "")) or hex
    text(self.hexLabel, hx + 6, vc(hy, hh, 14), shown, 14, self.hexEditing and Theme.text or Theme.subtext, 1, false, false)
    put(self.hexLabel, "Visible", true)
    newHit(hx, hy, hw, hh, {
        press = function()
            self.hexEditing = true
            self.hexBuf = ""
            focusedInput = self
        end,
    })
    fill(self.alphaBG, px + pw - 26, py + 156, 18, 18, Theme.main, 1, 2)
    fill(self.alphaSwatch, px + pw - 26, py + 156, 18, 18, c, self.alpha or 1, 2)
    stroke(self.alphaBG, px + pw - 26, py + 156, 18, 18, Theme.outline, 1, 2, 1)
    put(self.alphaBG, "Visible", true)
    put(self.alphaSwatch, "Visible", true)
end
local Input = {}
Input.__index = Input
Input.__kind = "Input"
function Input:GetHeight() return 39 end
function Input:SetValue(v)
    self.value = tostring(v or "")
    self:Fire(self.value)
    return self
end
function Input:SetText(t) self.text = t return self end
function Input:Focus() focusedInput = self return self end
function Input:SetPlaceholder(t) self.placeholder = t return self end
function Input:Key(code)
    if code == 13 or code == 27 then
        self:Fire(self.value)
        focusedInput = nil
        return
    end
    if code == 8 then
        self.value = self.value:sub(1, -2)
        self:Fire(self.value)
        return
    end
    local ch = codeToChar(code)
    if ch then
        self.value = self.value .. ch
        self:Fire(self.value)
    end
end
function Input:Render(x, y, w)
    text(self.label, x, y, clipText(self.text, 14, w), 14, Theme.text, 0.85, false, false)
    local by = y + 18
    fill(self.bg, x, by, w, 21, Theme.main, 1, 2)
    stroke(self.border, x, by, w, 21, focusedInput == self and Theme.accent or Theme.outline, 1, 2, 1)
    local shown = (self.value ~= "" and self.value) or (self.placeholder or "")
    text(self.valueText, x + 6, vc(by, 21, 14), clipText(shown, 14, w - 14), 14, self.value ~= "" and Theme.text or Theme.subtext, 1, false, false)
    if focusedInput == self and (clock() % 1) < 0.5 then
        local cxp = x + 6 + textW(self.value, 14) + 1
        line(self.caret, cxp, by + 4, cxp, by + 17, Theme.text, 1, 1)
    else
        put(self.caret, "Visible", false)
    end
    if m1.pressed and not hovered(x, by, w, 21) and focusedInput == self then
        focusedInput = nil
    end
    newHit(x, by, w, 21, {
        press = function()
            focusedInput = self
        end,
    })
end
local function attachKeyPicker(parent, id, cfg)
    cfg = cfg or {}
    local el = newElement(KeyPicker, id, cfg.Text or id)
    el.vk = keyToVk(cfg.Default or "F") or VK.F
    el.mode = cfg.Mode or "Toggle"
    el.state = false
    el.changedCallback = cfg.ChangedCallback
    el.captureOnly = cfg.CaptureOnly == true
    if cfg.Callback then table.insert(el.changed, cfg.Callback) end
    el.bg, el.border = mkSq(el, 21), mkSq(el, 22)
    el.keyText = mkText(el, 14)
    el.inline = true
    el.modeOpen = false
    el.parent = parent
    if parent and parent.kind == "Toggle" and cfg.SyncToggleState ~= false then
        el.syncParent = parent
        table.insert(el.changed, function(self)
            if self.state ~= nil then parent:SetValue(self.state) end
        end)
    end
    if not el.captureOnly then table.insert(Library.__keybinds, el) end
    table.insert(popupElements, el)
    Library.Options[id] = el
    Library.KeyPickers[id] = el
    table.insert(parent.addons, el)
    return el
end
local function attachColorPicker(parent, id, cfg)
    cfg = cfg or {}
    local el = newElement(ColorPicker, id, cfg.Title or id)
    local c = cfg.Default or Theme.accent
    el.value = c
    el.alpha = 1 - (cfg.Transparency or 0)
    el.h, el.s, el.v = 0.72, 0.6, 1
    el.h, el.s, el.v = rgbToHsv(c)
    if cfg.Callback then table.insert(el.changed, cfg.Callback) end
    el.swatch = mkSq(el, 21)
    el.swatchBorder = mkSq(el, 22)
    el.popupBg = mkSq(el, 100)
    el.popupBorder = mkSq(el, 101)
    el.svBase = mkSq(el, 101)
    el.hexLabel = mkText(el, 14)
    el.hexBg, el.hexBorder = mkSq(el, 103), mkSq(el, 104)
    el.hexEditing = false
    el.alphaBG = mkSq(el, 103)
    el.alphaSwatch = mkSq(el, 104)
    zset(el.hexLabel, 107)
    el.inline = true
    el.parent = parent
    table.insert(popupElements, el)
    Library.Options[id] = el
    Library.ColorPickers[id] = el
    table.insert(parent.addons, el)
    el:Fire(el.value, el.alpha)
    return el
end
local function renderAddons(parent, x, y, w, h)
    local anchor = x + w
    for _, a in ipairs(parent.addons) do
        if a.TypeKey then
            a:RenderInline(anchor - 2, y, h)
            anchor = anchor - 72
        else
            a:RenderInline(anchor - 2, y, h, true)
            anchor = anchor - 24
        end
    end
    return anchor
end
local Toggle = {}
Toggle.__index = Toggle
Toggle.__kind = "Toggle"
Toggle.TypeKey = true
function Toggle:GetHeight() return 18 end
function Toggle:SetValue(v)
    v = v == true
    if self.value ~= v then self.value = v self:Fire(v) end
    return self
end
function Toggle:SetText(t) self.text = t return self end
function Toggle:AddKeyPicker(id, cfg) return attachKeyPicker(self, id, cfg) end
function Toggle:AddColorPicker(id, cfg) return attachColorPicker(self, id, cfg) end
function Toggle:Render(x, y, w)
    local h = 18
    if not self.disabled then
        newHit(x, y, w, h, { press = function() self:SetValue(not self.value) end })
    end
    local endX = w
    if #self.addons > 0 then
        endX = (renderAddons(self, x, y, w, h) - x)
    end
    local switchW = 32
    local labelW = endX - switchW - 8
    text(self.label, x, vc(y, h, 14), clipText(self.text, 14, labelW), 14, self.disabled and Theme.disabled or Theme.text, 0.85, false, false)
    local tx = x + endX - switchW
    fill(self.track, tx, y, switchW, h, self.value and Theme.accent or Theme.main, 1, h / 2)
    stroke(self.border, tx, y, switchW, h, Theme.outline, 1, h / 2, 1)
    local ks = 14
    local kx = self.value and (tx + switchW - ks - 2) or (tx + 2)
    fill(self.knob, kx, y + 2, ks, ks, Theme.white, 1, ks / 2)
end
local Slider = {}
Slider.__index = Slider
Slider.__kind = "Slider"
function Slider:GetHeight() return 33 end
function Slider:Format(v)
    local step = self.rounding or 1
    local shown
    if step > 0 and step < 1 then
        shown = string.format("%.2f", v)
    else
        shown = tostring(floor(v + 0.5))
    end
    return (self.prefix or "") .. shown .. (self.suffix or "")
end
function Slider:SetValue(v)
    v = clamp(tonumber(v) or self.min, self.min, self.max)
    local step = self.rounding or 1
    if step > 0 then
        v = floor(v / step + 0.5) * step
        if step >= 1 then
            v = floor(v + 0.5)
        else
            v = floor(v * 100 + 0.5) / 100
        end
    end
    if math.abs((self.value or 0) - v) > 1e-6 then
        self.value = v
        self:Fire(v)
    end
    return self
end
function Slider:SetMin(v) self.min = v return self end
function Slider:SetMax(v) self.max = v return self end
function Slider:SetText(t) self.text = t return self end
function Slider:Render(x, y, w)
    local by, bh = y + 18, 15
    text(self.label, x, y, clipText(self.text, 14, w), 14, self.disabled and Theme.disabled or Theme.text, 0.85, false, false)
    local frac = (self.max > self.min) and ((self.value - self.min) / (self.max - self.min)) or 0
    fill(self.bg, x, by, w, bh, Theme.main, 1, 2)
    fill(self.fill, x, by, w * frac, bh, self.disabled and Theme.disabled or Theme.accent, 1, 2)
    stroke(self.border, x, by, w, bh, Theme.outline, 1, 2, 1)
    local ts = 13
    local tpos = clamp(x + w * frac - ts / 2, x - 1, x + w - ts + 1)
    fill(self.thumb, tpos, by + (bh - ts) / 2, ts, ts, Theme.white, 1, ts / 2)
    textC(self.valueText, x + w / 2, vc(by, bh, 14), self:Format(self.value), 14, Theme.white, 1, true)
    if not self.disabled then
        local function set(xx)
            local f = clamp((xx - x) / max(1, w), 0, 1)
            self:SetValue(self.min + f * (self.max - self.min))
        end
        newHit(x, by, w, bh, { press = set, drag = function(xx) set(xx) end })
    end
end
local Button = {}
Button.__index = Button
Button.__kind = "Button"
function Button:GetHeight() return 21 end
function Button:SetText(t) self.text = t return self end
function Button:Render(x, y, w)
    local hv = hovered(x, y, w, 21)
    fill(self.bg, x, y, w, 21, hv and mix(Theme.main, Theme.accent, 0.18) or Theme.main, 1, 2)
    stroke(self.border, x, y, w, 21, Theme.outline, 1, 2, 1)
    textC(self.label, x + w / 2, vc(y, 21, 14), clipText(self.text, 14, w - 10), 14, Theme.text, 1, false)
    newHit(x, y, w, 21, {
        press = function()
            if self.func then pcall(self.func) end
        end,
    })
end
local Label = {}
Label.__index = Label
Label.__kind = "Label"
Label.TypeKey = true
function Label:Lines(w)
    local size = self.size or 14
    if not self.wrap then return { self.text } end
    local out, cur = {}, ""
    for word in tostring(self.text):gmatch("%S+") do
        local cand = cur == "" and word or (cur .. " " .. word)
        if textW(cand, size) <= w or cur == "" then cur = cand
        else out[#out + 1] = cur cur = word end
    end
    if cur ~= "" then out[#out + 1] = cur end
    if #out == 0 then out[1] = "" end
    return out
end
function Label:GetHeight(w)
    if self.wrap then
        local used = 0
        for _, a in ipairs(self.addons or {}) do
            used = used + (a.kind == "KeyPicker" and 72 or 24)
        end
        return #self:Lines(w - used) * 18
    end
    return 18
end
function Label:SetText(t) self.text = t return self end
function Label:AddKeyPicker(id, cfg) return attachKeyPicker(self, id, cfg) end
function Label:AddColorPicker(id, cfg) return attachColorPicker(self, id, cfg) end
function Label:Render(x, y, w)
    local endX = w
    if #self.addons > 0 then endX = (renderAddons(self, x, y, w, 18) - x) end
    local size = self.size or 14
    local lines = self:Lines(endX)
    for i, ln in ipairs(lines) do
        local o = self.lines[i]
        if not o then o = mkText(self, size) self.lines[i] = o end
        text(o, x, y + (i - 1) * 18, ln, size, self.color or Theme.text, 0.85, false, false)
    end
    for i = #lines + 1, #self.lines do put(self.lines[i], "Visible", false) end
end
local Divider = {}
Divider.__index = Divider
Divider.__kind = "Divider"
function Divider:GetHeight() return self.text and 30 or 6 end
function Divider:Render(x, y, w)
    if self.text and self.text ~= "" then
        textC(self.lbl, x + w / 2, vc(y, 24, 14), clipText(self.text, 14, w), 14, Theme.subtext, 1, false)
        line(self.ln, x, y + 24, x + w, y + 24, Theme.outline, 1, 1)
    else
        line(self.ln, x, y + 3, x + w, y + 3, Theme.outline, 1, 1)
        put(self.lbl, "Visible", false)
    end
end
local Dropdown = {}
Dropdown.__index = Dropdown
Dropdown.__kind = "Dropdown"
function Dropdown:GetHeight() return self.text and 39 or 21 end
function Dropdown:BuildOptions()
    local opts = {}
    local vals = self.values
    local isArray = true
    for k in pairs(vals) do
        if type(k) ~= "number" then isArray = false break end
    end
    if isArray then
        for _, v in ipairs(vals) do opts[#opts + 1] = { key = v, label = tostring(v) } end
    else
        local keys = {}
        for k in pairs(vals) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        for _, k in ipairs(keys) do opts[#opts + 1] = { key = k, label = tostring(vals[k]) } end
    end
    self.opts = opts
    if self.multi then
        if type(self.value) ~= "table" then self.value = {} end
    elseif self.value == nil and #opts > 0 then
        self.value = opts[1].key
    end
    return opts
end
function Dropdown:LabelFor(key)
    for _, o in ipairs(self.opts or {}) do if o.key == key then return o.label end end
    return tostring(key)
end
function Dropdown:Display()
    if self.multi then
        local parts = {}
        for k in pairs(self.value or {}) do parts[#parts + 1] = self:LabelFor(k) end
        table.sort(parts)
        if #parts == 0 then return self.placeholder or "..." end
        return table.concat(parts, ", ")
    end
    if self.value == nil then return self.placeholder or "..." end
    return self:LabelFor(self.value)
end
function Dropdown:SetValue(v) self.value = v self:Fire(self.value) return self end
function Dropdown:SetValues(t)
    self.values = t or {}
    self.optionArray = nil
    self:BuildOptions()
    if not self.multi and self.value ~= nil then
        local found = false
        for _, o in ipairs(self.opts or {}) do if o.key == self.value then found = true break end end
        if not found then self.value = self.opts and self.opts[1] and self.opts[1].key or nil end
    end
    return self
end
function Dropdown:AddValues(t)
    if type(t) ~= "table" then t = { t } end
    for k, v in pairs(t) do
        if type(k) == "number" then table.insert(self.values, v) else self.values[k] = v end
    end
    self.optionArray = nil
    self:BuildOptions()
    return self
end
function Dropdown:ClosePopup()
    self.popupOpen = false
    if openPopup == self then openPopup = nil end
    put(self.popupBg, "Visible", false)
    put(self.popupBorder, "Visible", false)
    if self.scrollTrack then put(self.scrollTrack, "Visible", false) end
    if self.scrollThumb then put(self.scrollThumb, "Visible", false) end
    for _, o in ipairs(self.optTexts) do put(o, "Visible", false) end
    for _, o in ipairs(self.selCells) do put(o, "Visible", false) end
end
function Dropdown:PopupRect() return { self.px, self.py, self.pw, self.ph } end
function Dropdown:OpenPopup() clearPopup(self) self.popupOpen = true openPopup = self end
function Dropdown:Render(x, y, w)
    local selY = y
    if self.text then
        text(self.label, x, y, clipText(self.text, 14, w - 24), 14, Theme.text, 0.65, false, false)
        selY = y + 18
    else
        put(self.label, "Visible", false)
    end
    local hv = hovered(x, selY, w, 21)
    fill(self.bg, x, selY, w, 21, Theme.main, 1, 2)
    stroke(self.border, x, selY, w, 21, self.popupOpen and Theme.accent or (hv and Theme.strokeLit or Theme.outline), 1, 2, 1)
    text(self.valueText, x + 6, vc(selY, 21, 14), clipText(self:Display(), 14, w - 26), 14, Theme.text, 1, false, false)
    local cx, cy = x + w - 12, selY + 9
    line(self.chev1, cx - 3, cy, cx, cy + 3, Theme.subtext, 1, 1)
    line(self.chev2, cx, cy + 3, cx + 3, cy, Theme.subtext, 1, 1)
    newHit(x, selY, w, 21, {
        press = function()
            if self.popupOpen then self:ClosePopup() else self:OpenPopup() end
        end,
    })
    self.hx, self.hy, self.hw = x, selY, w
end
function Dropdown:RenderPopup()
    if not self.popupOpen then return end
    local opts = self.opts or self:BuildOptions()
    local rowH = 21
    local total = #opts
    local vis = total
    if self.maxVisible and total > self.maxVisible then vis = self.maxVisible end
    local scrollMax = max(0, total - vis)
    self.scroll = clamp(self.scroll or 0, 0, scrollMax)
    local pw, ph = self.hw, rowH * vis + 8
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local px, py = self.hx, self.hy + 21 + 3
    if py + ph > vp.Y - 8 then py = self.hy - ph - 3 end
    self.px, self.py, self.pw, self.ph = px, py, pw, ph
    fill(self.popupBg, px, py, pw, ph, Theme.bg, 1, 4)
    stroke(self.popupBorder, px, py, pw, ph, Theme.outline, 1, 4, 1)
    newHit(px, py, pw, ph, { press = function() end })
    local showBar = total > vis
    local listW = pw - (showBar and 12 or 0)
    local first = self.scroll + 1
    for idx = 1, vis do
        local i = first + idx - 1
        local opt = opts[i]
        if not opt then break end
        local o = self.optTexts[idx]
        if not o then o = newObj("Text", 102) o.d.Size = 14 table.insert(self.objects, o) self.optTexts[idx] = o end
        local ry = py + 4 + (idx - 1) * rowH
        local selected = (self.multi and self.value and self.value[opt.key]) or (self.value == opt.key)
        local hv = hovered(px + 4, ry, listW - 8, rowH)
        local cell = self.selCells[idx]
        if hv then
            if not cell then cell = newObj("Square", 101) table.insert(self.objects, cell) self.selCells[idx] = cell end
            fill(cell, px + 4, ry, listW - 8, rowH, Theme.accent, 0.18, 2)
        elseif cell then
            put(cell, "Visible", false)
        end
        text(o, px + 8, ry + 3, clipText(opt.label, 14, listW - 18), 14, selected and Theme.accent or Theme.text, 1, false, false)
        newHit(px + 4, ry, listW - 8, rowH, {
            press = function()
                if self.multi then
                    self.value = self.value or {}
                    if self.value[opt.key] then self.value[opt.key] = nil else self.value[opt.key] = true end
                    self:Fire(self.value)
                else
                    self.value = opt.key
                    self:Fire(opt.key)
                    self:ClosePopup()
                end
            end,
        })
    end
    for i = vis + 1, #self.optTexts do put(self.optTexts[i], "Visible", false) end
    for i = vis + 1, #self.selCells do put(self.selCells[i], "Visible", false) end
    if showBar then
        local tx, ty, tw, th = px + pw - 9, py + 4, 6, ph - 8
        fill(self.scrollTrack, tx, ty, tw, th, Theme.main, 1, 3)
        put(self.scrollTrack, "Visible", true)
        local thumbH = max(18, floor(th * vis / total + 0.5))
        local frac = scrollMax > 0 and (self.scroll / scrollMax) or 0
        local thumbY = ty + (th - thumbH) * frac
        fill(self.scrollThumb, tx, thumbY, tw, thumbH, Theme.accent, 1, 3)
        put(self.scrollThumb, "Visible", true)
        local function scrollTo(yy)
            local f = clamp((yy - ty - thumbH / 2) / max(1, th - thumbH), 0, 1)
            self.scroll = floor(f * scrollMax + 0.5)
        end
        newHit(tx - 2, ty, tw + 4, th, {
            press = function(_, yy) scrollTo(yy) end,
            drag = function(_, yy) scrollTo(yy) end,
        })
    else
        put(self.scrollTrack, "Visible", false)
        put(self.scrollThumb, "Visible", false)
    end
end
local Groupbox = {}
Groupbox.__index = Groupbox
local function register(id, el, cat)
    Library.Options[id] = el
    if cat then cat[id] = el end
end
function Groupbox:AddToggle(id, cfg)
    cfg = cfg or {}
    local el = newElement(Toggle, id, cfg.Text or id)
    if cfg.Callback then table.insert(el.changed, cfg.Callback) end
    el.value = cfg.Default == true
    el.bg = mkSq(el, 20) el.label = mkText(el, 14) el.track = mkSq(el, 21) el.border = mkSq(el, 22) el.knob = mkSq(el, 23)
    table.insert(self.elements, el)
    register(id, el, Library.Toggles)
    if el.value then el:Fire(true) end
    return el
end
function Groupbox:AddCheckbox(id, cfg) return self:AddToggle(id, cfg) end
function Groupbox:AddSlider(id, cfg)
    cfg = cfg or {}
    local el = newElement(Slider, id, cfg.Text or id)
    if cfg.Callback then table.insert(el.changed, cfg.Callback) end
    el.min, el.max = cfg.Min or 0, cfg.Max or 100
    el.rounding = cfg.Rounding or 1
    el.prefix, el.suffix = cfg.Prefix, cfg.Suffix
    el.value = clamp(cfg.Default or el.min, el.min, el.max)
    el.bg, el.fill, el.border = mkSq(el, 20), mkSq(el, 21), mkSq(el, 22)
    el.label, el.valueText = mkText(el, 14), mkText(el, 14)
    el.thumb = mkSq(el, 23)
    table.insert(self.elements, el)
    register(id, el, Library.Sliders)
    el:Fire(el.value)
    return el
end
function Groupbox:AddButton(a, b)
    local id, cfg
    if type(a) == "table" and b == nil then cfg = a id = cfg.Id or cfg.Text or "Button"
    else id, cfg = a, b or {} end
    local el = newElement(Button, id, cfg.Text or id)
    el.func = cfg.Func or cfg.Callback
    el.bg, el.border, el.label = mkSq(el, 20), mkSq(el, 22), mkText(el, 14)
    table.insert(self.elements, el)
    register(id, el, Library.Buttons)
    return el
end
function Groupbox:AddLabel(a, b)
    local cfg = type(a) == "table" and a or { Text = a }
    local el = newElement(Label, cfg.Id or ("Label" .. #self.elements + 1), cfg.Text or "")
    el.wrap, el.size, el.color = cfg.DoesWrap == true, cfg.Size or 14, cfg.Color
    el.lines = {}
    table.insert(self.elements, el)
    return el
end
function Groupbox:AddDivider(cfg)
    if type(cfg) == "string" then cfg = { Text = cfg } end
    cfg = cfg or {}
    local el = newElement(Divider, "Divider" .. #self.elements + 1, cfg.Text or "")
    el.ln, el.lbl = mkLine(el), mkText(el, 14)
    table.insert(self.elements, el)
    return el
end
function Groupbox:AddDropdown(id, cfg)
    cfg = cfg or {}
    local el = newElement(Dropdown, id, cfg.Text or id)
    el.values = cfg.Values or cfg.Options or {}
    el.multi = cfg.Multi == true
    el.placeholder = cfg.Placeholder or "..."
    el.value = cfg.Default
    if type(el.value) == "number" and el.values[el.value] ~= nil then
        local opts = el:BuildOptions()
        el.value = opts[el.value] and opts[el.value].key or el.value
    else
        el:BuildOptions()
    end
    if cfg.Callback then table.insert(el.changed, cfg.Callback) end
    el.bg, el.border = mkSq(el, 20), mkSq(el, 22)
    el.label, el.valueText = mkText(el, 14), mkText(el, 14)
    el.chev1, el.chev2 = mkLine(el, 25), mkLine(el, 25)
    el.popupBg, el.popupBorder = mkSq(el, 100), mkSq(el, 101)
    el.scrollTrack, el.scrollThumb = mkSq(el, 101), mkSq(el, 102)
    el.maxVisible = cfg.MaxVisible
    el.scroll = 0
    el.optTexts, el.selCells = {}, {}
    table.insert(self.elements, el)
    table.insert(popupElements, el)
    register(id, el, Library.Dropdowns)
    return el
end
function Groupbox:AddInput(id, cfg)
    cfg = cfg or {}
    local el = newElement(Input, id, cfg.Text or id)
    el.value = tostring(cfg.Default or "")
    el.placeholder = cfg.Placeholder
    if cfg.Callback then table.insert(el.changed, cfg.Callback) end
    el.bg, el.border = mkSq(el, 20), mkSq(el, 22)
    el.label, el.valueText = mkText(el, 14), mkText(el, 14)
    el.caret = mkLine(el, 25)
    table.insert(self.elements, el)
    register(id, el, nil)
    return el
end
function Groupbox:AddKeyPicker(id, cfg)
    cfg = cfg or {}
    local el = newElement(KeyPicker, id, cfg.Text or id)
    el.vk = keyToVk(cfg.Default or "F") or VK.F
    el.mode = cfg.Mode or "Toggle"
    el.state = false
    el.changedCallback = cfg.ChangedCallback
    el.captureOnly = cfg.CaptureOnly == true
    if cfg.Callback then table.insert(el.changed, cfg.Callback) end
    el.bg, el.border, el.keyText = mkSq(el, 21), mkSq(el, 22), mkText(el, 14)
    el.label = mkText(el, 14)
    el.row = true
    el.modeOpen = false
    table.insert(self.elements, el)
    table.insert(popupElements, el)
    if not el.captureOnly then table.insert(Library.__keybinds, el) end
    register(id, el, Library.KeyPickers)
    return el
end
function Groupbox:AddColorPicker(id, cfg)
    cfg = cfg or {}
    local el = newElement(ColorPicker, id, cfg.Title or id)
    local c = cfg.Default or Theme.accent
    el.alpha = 1 - (cfg.Transparency or 0)
    el.swatch, el.swatchBorder = mkSq(el, 23), mkSq(el, 24)
    el.bg, el.border = mkSq(el, 20), mkSq(el, 22)
    el.label, el.hex = mkText(el, 14), mkText(el, 14)
    el.popupBg, el.popupBorder = mkSq(el, 100), mkSq(el, 101)
    el.svBase = mkSq(el, 101)
    el.hexLabel = mkText(el, 14)
    el.hexBg, el.hexBorder = mkSq(el, 103), mkSq(el, 104)
    el.hexEditing = false
    el.alphaBG, el.alphaSwatch = mkSq(el, 103), mkSq(el, 104)
    zset(el.hexLabel, 107)
    el.h, el.s, el.v = rgbToHsv(c)
    el.value = c
    el.row = true
    if cfg.Callback then table.insert(el.changed, cfg.Callback) end
    table.insert(self.elements, el)
    table.insert(popupElements, el)
    register(id, el, Library.ColorPickers)
    return el
end
function Groupbox:GetHeight(w)
    local h = 6 + 15 + (self.desc and self.desc ~= "" and 16 or 0) + 6
    local lw = w - 12
    for _, el in ipairs(self.elements) do
        if el.visible and not el.destroyed then h = h + el:GetHeight(lw) + 6 end
    end
    return h
end
function Groupbox:Render(x, y, w)
    local h = self:GetHeight(w)
    fill(self.bg, x, y, w, h, Theme.bg, 1, Library.CornerRadius)
    stroke(self.border, x, y, w, h, Theme.outline, 1, Library.CornerRadius, 1)
    text(self.title, x + 10, y + 6, clipText(self.name, 15, w - 20), 15, Theme.text, 1, false, false)
    if self.desc and self.desc ~= "" then
        text(self.descText, x + 10, y + 22, clipText(self.desc, 14, w - 20), 14, Theme.subtext, 1, false, false)
    else
        put(self.descText, "Visible", false)
    end
    local ey = y + 6 + 15 + (self.desc and self.desc ~= "" and 16 or 0) + 6
    for _, el in ipairs(self.elements) do
        if el.visible and not el.destroyed then
            local eh = el:GetHeight(w - 12)
            if el.row and el.RenderRow then
                el:RenderRow(x + 6, ey, w - 12, eh)
            else
                el:Render(x + 6, ey, w - 12)
            end
            ey = ey + eh + 6
        end
    end
    return h
end
function Groupbox:RenderPopups()
    for _, el in ipairs(self.elements) do
        if el.RenderPopup then el:RenderPopup() end
        for _, a in ipairs(el.addons or {}) do
            if a.RenderPopup then a:RenderPopup() end
        end
    end
end
function Groupbox:Show() self.visible = true return self end
function Groupbox:Hide() self.visible = false return self end
function Groupbox:SetVisible(b) self.visible = b ~= false return self end
function KeyPicker:RenderRow(x, y, w)
    local bx, bw = x + w - 74, 68
    self.boxX, self.boxY, self.boxW, self.boxH = bx, y + 3, bw, 15
    fill(self.bg, x, y, w, 21, Theme.main, 1, 2)
    stroke(self.border, x, y, w, 21, Theme.outline, 1, 2, 1)
    if self.label then
        text(self.label, x + 6, vc(y, 21, 14), clipText(self.text, 14, w - 90), 14, Theme.text, 0.85, false, false)
    end
    textC(self.keyText, bx + bw / 2, vc(y + 3, 15, 14), clipText(capturing == self and "[...]" or vkName(self.vk), 14, bw - 6), 14, Theme.subtext, 1, false)
    if not self.captureOnly and hovered(bx, y + 3, bw, 15) and m2.pressed then
        self:OpenModePopup()
    end
    newHit(x, y, w, 21, {
        press = function()
            beginCapture(self)
            self:CloseModePopup()
        end,
    })
end
function ColorPicker:RenderRow(x, y, w)
    fill(self.bg, x, y, w, 21, Theme.main, 1, 2)
    stroke(self.border, x, y, w, 21, Theme.outline, 1, 2, 1)
    local c = self:Color()
    local hex = fmt("#%02X%02X%02X", floor(c.R * 255 + 0.5), floor(c.G * 255 + 0.5), floor(c.B * 255 + 0.5))
    text(self.label, x + 6, vc(y, 21, 14), clipText(self.text, 14, w - 96), 14, Theme.text, 0.85, false, false)
    text(self.hex, x + w - 84, vc(y, 21, 14), hex, 14, Theme.subtext, 1, false, false)
    fill(self.swatch, x + w - 24, y + 3, 18, 18, c, self.alpha or 1, 2)
    stroke(self.swatchBorder, x + w - 24, y + 3, 18, 18, Theme.outline, 1, 2, 1)
    newHit(x, y, w, 21, { press = function() if self.popupOpen then self:ClosePopup() else self:OpenPopup() end end })
    self.hx, self.hy, self.hw = x + w - 24, y + 3, 18
end
Toggle.RenderRow = nil
Slider.RenderRow = nil
local Tab = {}
Tab.__index = Tab
function Tab:AddGroupbox(a, b)
    local cfg = type(a) == "table" and a or { Side = a, Name = b }
    local side = cfg.Side
    if side == nil then side = "Left" end
    if type(side) == "string" then side = side:lower() == "right" and "Right" or "Left" end
    if side == 2 then side = "Right" elseif side == 1 then side = "Left" end
    local gb = setmetatable({}, Groupbox)
    gb.name = cfg.Name or "Groupbox"
    gb.desc = cfg.Description
    gb.side = side
    gb.visible = cfg.Visible ~= false
    gb.elements = {}
    gb.bg = newObj("Square", 10)
    gb.border = newObj("Square", 11)
    gb.title = newObj("Text", 12)
    gb.title.d.Size = 15
    gb.descText = newObj("Text", 12)
    gb.descText.d.Size = 14
    table.insert(self.groups, gb)
    return gb
end
function Tab:AddLeftGroupbox(name, cfg)
    cfg = cfg or {} cfg.Name = name cfg.Side = "Left"
    return self:AddGroupbox(cfg)
end
function Tab:AddRightGroupbox(name, cfg)
    cfg = cfg or {} cfg.Name = name cfg.Side = "Right"
    return self:AddGroupbox(cfg)
end
function Tab:Render(x, y, w)
    local colW = w / 2 - 3
    local ly, ry = y, y
    for _, g in ipairs(self.groups) do
        if g.visible then
            if g.side == "Left" then ly = ly + g:Render(x, ly, colW) + 6
            else ry = ry + g:Render(x + colW + 6, ry, colW) + 6 end
        end
    end
end
function Tab:Hide()
    local function hideObj(o)
        o.sc.Visible = false
        o.d.Visible = false
    end
    for _, g in ipairs(self.groups) do
        hideObj(g.bg)
        hideObj(g.border)
        hideObj(g.title)
        hideObj(g.descText)
        for _, el in ipairs(g.elements) do
            for _, o in ipairs(el.objects) do hideObj(o) end
            for _, a in ipairs(el.addons or {}) do
                for _, o in ipairs(a.objects) do hideObj(o) end
            end
        end
    end
end
function Tab:SetVisible(b) self.visible = b ~= false return self end
function Tab:SetName(n) self.name = n return self end
local function iconCtx(tab, color, alpha)
    local P = tab.iconObjs
    local li, ci, si = 0, 0, 0
    local ctx = {}
    function ctx.line(x1, y1, x2, y2, th)
        li = li + 1; local o = P.lines[li]; if not o then return end
        putV(o, "From", x1, y1); putV(o, "To", x2, y2); putC(o, "Color", color)
        put(o, "Transparency", alpha); put(o, "Thickness", th or 1); put(o, "Visible", true)
    end
    function ctx.circ(cx, cy, r, filled, th)
        ci = ci + 1; local o = P.circles[ci]; if not o then return end
        putV(o, "Position", cx, cy); put(o, "Radius", r); put(o, "Filled", filled == true)
        put(o, "NumSides", 32); put(o, "Thickness", th or 1); putC(o, "Color", color)
        put(o, "Transparency", alpha); put(o, "Visible", true)
    end
    function ctx.rect(x, y, w, h, filled, th, cr)
        si = si + 1; local o = P.squares[si]; if not o then return end
        putV(o, "Position", x, y); putV(o, "Size", w, h); put(o, "Filled", filled == true)
        put(o, "Thickness", th or 1); put(o, "Corner", cr or 0); putC(o, "Color", color)
        put(o, "Transparency", alpha); put(o, "Visible", true)
    end
    function ctx.finish()
        for i = li + 1, #P.lines do put(P.lines[i], "Visible", false) end
        for i = ci + 1, #P.circles do put(P.circles[i], "Visible", false) end
        for i = si + 1, #P.squares do put(P.squares[i], "Visible", false) end
    end
    return ctx
end
local ICONS = {}
ICONS.aimbot = function(c, x, y, s)
    c.circ(x, y, s * 0.78, false, 1.5)
    c.line(x, y - s * 1.05, x, y - s * 0.5, 1.5)
    c.line(x, y + s * 0.5, x, y + s * 1.05, 1.5)
    c.line(x - s * 1.05, y, x - s * 0.5, y, 1.5)
    c.line(x + s * 0.5, y, x + s * 1.05, y, 1.5)
    c.circ(x, y, s * 0.16, true)
end
ICONS.esp = function(c, x, y, s)
    local e = s * 0.92
    local k = s * 0.42
    c.line(x - e, y - e, x - e + k, y - e, 1.5)
    c.line(x - e, y - e, x - e, y - e + k, 1.5)
    c.line(x + e, y - e, x + e - k, y - e, 1.5)
    c.line(x + e, y - e, x + e, y - e + k, 1.5)
    c.line(x - e, y + e, x - e + k, y + e, 1.5)
    c.line(x - e, y + e, x - e, y + e - k, 1.5)
    c.line(x + e, y + e, x + e - k, y + e, 1.5)
    c.line(x + e, y + e, x + e, y + e - k, 1.5)
    c.circ(x, y, s * 0.13, true)
end
ICONS.misc = function(c, x, y, s)
    local cell = s * 0.74
    local gp = s * 0.16
    local x0 = x - cell - gp * 0.5
    local y0 = y - cell - gp * 0.5
    c.rect(x0, y0, cell, cell, true, 1, 2)
    c.rect(x0 + cell + gp, y0, cell, cell, true, 1, 2)
    c.rect(x0, y0 + cell + gp, cell, cell, true, 1, 2)
    c.rect(x0 + cell + gp, y0 + cell + gp, cell, cell, true, 1, 2)
end
ICONS.settings = function(c, x, y, s)
    c.circ(x, y, s * 0.72, false, 1.5)
    c.circ(x, y, s * 0.30, false, 1.5)
    for i = 0, 7 do
        local a = i * (math.pi / 4)
        local ca, sa = math.cos(a), math.sin(a)
        c.line(x + ca * s * 0.72, y + sa * s * 0.72, x + ca * s * 1.02, y + sa * s * 1.02, 2)
    end
end
ICONS.config = function(c, x, y, s)
    local ys = { y - s * 0.6, y, y + s * 0.6 }
    local kx = { x - s * 0.45, x + s * 0.25, x - s * 0.1 }
    for i = 1, 3 do
        c.line(x - s * 0.85, ys[i], x + s * 0.85, ys[i], 1.5)
        c.circ(kx[i], ys[i], s * 0.22, true)
    end
end
ICONS.default = function(c, x, y, s)
    c.circ(x, y, s * 0.32, true)
end
local function drawTabIcon(tab, cx, cy, s, color, alpha)
    if not tab.iconObjs then return end
    local fn = ICONS[tab.iconKey] or ICONS.default
    local ctx = iconCtx(tab, color, alpha)
    fn(ctx, cx, cy, s)
    ctx.finish()
end
local Window = {}
Window.__index = Window
function Window:AddTab(a, icon, desc)
    local cfg = type(a) == "table" and a or { Name = a, Icon = icon, Description = desc }
    local tab = setmetatable({}, Tab)
    tab.window = self
    tab.name = cfg.Name or "Tab"
    tab.icon = cfg.Icon
    tab.iconKey = cfg.Icon
    tab.description = cfg.Description
    tab.groups = {}
    tab.visible = true
    tab.sel = newObj("Square", 6)
    tab.indicator = newObj("Square", 7)
    tab.label = newObj("Text", 8)
    tab.label.d.Size = 16
    tab.iconObjs = { lines = {}, circles = {}, squares = {} }
    for i = 1, 12 do tab.iconObjs.lines[i] = newObj("Line", 8) end
    for i = 1, 3 do tab.iconObjs.circles[i] = newObj("Circle", 8) end
    for i = 1, 4 do tab.iconObjs.squares[i] = newObj("Square", 8) end
    table.insert(self.tabs, tab)
    if not self.activeTab then self.activeTab = tab end
    return tab
end
function Window:SelectTab(tab)
    if type(tab) == "number" then tab = self.tabs[tab] end
    if not tab or tab.window ~= self then return self end
    if self.activeTab ~= tab then
        if self.activeTab then self.activeTab:Hide() end
        self.activeTab = tab
        clearPopup()
        focusedInput = nil
        capturing = nil
    end
    return self
end
function Window:SetTitle(t) self.title = tostring(t) return self end
function Window:ChangeTitle(t) return self:SetTitle(t) end
function Window:SetFooter(t) self.footer = tostring(t) return self end
function Window:Toggle(force)
    local v = force
    if v == nil then v = not self.visible end
    self.visible = v and true or false
    if not self.visible then
        hideAll()
        clearPopup()
        focusedInput = nil
        capturing = nil
    end
    pcall(setrobloxinput, true)
    return self
end
function Window:Open() return self:Toggle(true) end
function Window:Close() return self:Toggle(false) end
function Window:SetPos(px, py)
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    self.x = clamp(px, -self.w + 80, vp.X - 80)
    self.y = clamp(py, 0, vp.Y - 40)
    return self
end
function Window:SetSize(w, h)
    self.w, self.h = w, h
    self.sideW = floor(w * 0.3 + 0.5)
    return self
end
function Window:Center()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    self:SetPos((vp.X - self.w) / 2, (vp.Y - self.h) / 2)
    return self
end
function Window:Render()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local titleH = self.titleH
    local sideW = self.sideW
    fill(self.shadow, x - 3, y - 3, w + 6, h + 8, Theme.dark, 0.22, Library.CornerRadius + 4)
    fill(self.bg, x, y, w, h, Theme.bg, 1, Library.CornerRadius)
    stroke(self.border, x, y, w, h, Theme.outline, 1, Library.CornerRadius, 1)
    fill(self.hline, x + sideW, y + titleH, w - sideW, 1, Theme.outline, 1, 0)
    fill(self.vline, x + sideW, y + titleH, 1, h - titleH, Theme.outline, 1, 0)
    local lg = LogoImage or ensureLogo()
    local acc, bgc = Theme.accent, Theme.bg
    local lkey = floor(acc.R * 255) .. "," .. floor(acc.G * 255) .. "," .. floor(acc.B * 255)
        .. "|" .. floor(bgc.R * 255) .. "," .. floor(bgc.G * 255) .. "," .. floor(bgc.B * 255)
    if LogoKey ~= lkey then
        LogoKey = lkey
        lg.d.Data = buildLogoBmp(48, bgc, acc)
    end
    lg.d.Position = Vector2.new(x + 10, y + (titleH - 24) / 2)
    lg.d.Size = Vector2.new(24, 24)
    put(lg, "Visible", true)
    text(self.titleText, x + 40, vc(y, titleH, 15), clipText(self.title, 15, w - 88), 15, Theme.text, 1, false, false)
    put(self.footerText, "Visible", false)
    local cbx, cby = x + w - 20, vc(y, titleH, 8)
    local chv = hovered(cbx - 4, cby - 4, 20, 16)
    line(self.close1, cbx, cby, cbx + 8, cby + 8, chv and Theme.danger or Theme.subtext, 1, 1)
    line(self.close2, cbx + 8, cby, cbx, cby + 8, chv and Theme.danger or Theme.subtext, 1, 1)
    newHit(cbx - 6, cby - 6, 22, 20, { press = function() self:Toggle(false) end })
    local ty = y + titleH
    for _, tab in ipairs(self.tabs) do
        if tab.visible then
            local th = 40
            local active = (self.activeTab == tab)
            local hv = hovered(x, ty, sideW, th)
            if active then
                fill(tab.sel, x, ty, sideW, th, mix(Theme.bg, Theme.accent, 0.10), 1, 0)
                fill(tab.indicator, x, ty, 2, th, Theme.accent, 1, 0)
            elseif hv then
                fill(tab.sel, x, ty, sideW, th, Theme.main, 0.5, 0)
                put(tab.indicator, "Visible", false)
            else
                put(tab.sel, "Visible", false)
                put(tab.indicator, "Visible", false)
            end
            drawTabIcon(tab, x + 18, ty + th / 2, 8, active and Theme.accent or Theme.subtext, active and 1 or 0.6)
            text(tab.label, x + 36, ty + 11, clipText(tab.name, 16, sideW - 44), 16, active and Theme.text or Theme.subtext, active and 1 or 0.55, false, false)
            newHit(x, ty, sideW, th, {
                press = function()
                    self:SelectTab(tab)
                end,
            })
            ty = ty + th
        end
    end
    local cx, cy = x + sideW + 4, y + titleH + 4
    local cw, ch = w - sideW - 8, h - titleH - 8
    if self.activeTab then
        self.activeTab:Render(cx, cy, cw)
    end
    newHit(x, y, w - 28, titleH, {
        press = function(px, py) self.dragOff = { px - x, py - y } end,
        drag = function(px, py)
            if self.dragOff then self:SetPos(px - self.dragOff[1], py - self.dragOff[2]) end
        end,
        release = function() self.dragOff = nil end,
    })
    newHit(x + w - 16, y + h - 16, 16, 16, {
        press = function(px, py) self.sizeOff = { w - (px - x), h - (py - y) } end,
        drag = function(px, py)
            if self.sizeOff then
                self:SetSize(max(480, px - x + self.sizeOff[1]), max(360, py - y + self.sizeOff[2]))
            end
        end,
        release = function() self.sizeOff = nil end,
    })
end
Library.__keybinds = {}
function Library:BuildNotificationSettings(Tab)
    local opts = Library.NotificationOptions
    local group = Tab:AddGroupbox({ Side = "Left", Name = "Notifications" })
    group:AddToggle("Notify_Enabled", {
        Text = "Enable notifications",
        Default = opts.Enabled,
        Callback = function(v)
            Library.NotificationOptions.Enabled = v
        end,
    })
    group:AddSlider("Notify_Duration", {
        Text = "Duration",
        Default = opts.Duration,
        Min = 1, Max = 20, Rounding = 0.5, Suffix = "s",
        Callback = function(v)
            Library.NotificationOptions.Duration = v
            for _, n in ipairs(notifs) do n.dur = v end
        end,
    })
    group:AddSlider("Notify_Fade", {
        Text = "Fade time",
        Default = opts.Fade,
        Min = 0, Max = 2, Rounding = 0.05, Suffix = "s",
        Callback = function(v) Library.NotificationOptions.Fade = v end,
    })
    group:AddSlider("Notify_Width", {
        Text = "Width",
        Default = opts.Width,
        Min = 180, Max = 420, Rounding = 1, Suffix = "px",
        Callback = function(v) Library.NotificationOptions.Width = v end,
    })
    group:AddSlider("Notify_Max", {
        Text = "Max visible",
        Default = opts.MaxVisible,
        Min = 1, Max = 10, Rounding = 1,
        Callback = function(v)
            Library.NotificationOptions.MaxVisible = v
            while #notifs > v do removeNotif(table.remove(notifs)) end
        end,
    })
    group:AddSlider("Notify_OffsetY", {
        Text = "Top offset",
        Default = opts.OffsetY,
        Min = 0, Max = 200, Rounding = 1, Suffix = "px",
        Callback = function(v) Library.NotificationOptions.OffsetY = v end,
    })
    group:AddDropdown("Notify_Side", {
        Text = "Side",
        Values = { "Right", "Left" },
        Default = Library.NotifySide,
        Callback = function(v) Library.NotifySide = v end,
    })
    group:AddToggle("Notify_UseCall", {
        Text = "Per-call duration",
        Default = opts.UseCallDuration,
        Callback = function(v) Library.NotificationOptions.UseCallDuration = v end,
    })
    group:AddButton({
        Text = "Test Notification",
        Func = function() Library:Notify("This is a test notification.", nil, "Test") end,
    })
    group:AddButton({
        Text = "Preview (ignores Enabled)",
        Func = function() Library:PreviewNotification() end,
    })
    group:AddButton({
        Text = "Clear Notifications",
        Func = function() Library:ClearNotifications() end,
    })
    group:AddButton({
        Text = "Reset Defaults",
        Func = function()
            local function set(id, v)
                local el = Library.Options[id]
                if el then el:SetValue(v) end
            end
            set("Notify_Enabled", true)
            set("Notify_Duration", 4)
            set("Notify_Fade", 0.35)
            set("Notify_Width", 260)
            set("Notify_Max", 6)
            set("Notify_OffsetY", 16)
            set("Notify_UseCall", false)
            local side = Library.Options.Notify_Side
            if side then side:SetValue("Right") end
            Library.NotifySide = "Right"
        end,
    })
    return group
end
function Library:CreateWindow(cfg)
    cfg = cfg or {}
    if cfg.Accent then Theme.accent = cfg.Accent end
    if cfg.CornerRadius then Library.CornerRadius = cfg.CornerRadius end
    local win = setmetatable({}, Window)
    win.title = cfg.Title or "No Title"
    win.footer = cfg.Footer or ""
    win.w = cfg.Width or 720
    win.h = cfg.Height or 600
    win.titleH = 36
    win.sideW = floor(win.w * 0.3 + 0.5)
    win.x, win.y = 100, 100
    win.tabs, win.activeTab = {}, nil
    win.visible = cfg.AutoShow ~= false
    win.bg = newObj("Square", 2)
    win.border = newObj("Square", 3)
    win.shadow = newObj("Square", 1)
    win.hline = newObj("Square", 4)
    win.vline = newObj("Square", 4)
    win.titleText = newObj("Text", 6)
    win.titleText.d.Size = 15
    win.footerText = newObj("Text", 6)
    win.footerText.d.Size = 14
    win.close1 = newObj("Line", 7)
    win.close2 = newObj("Line", 7)
    table.insert(Windows, win)
    if cfg.Center ~= false then win:Center() end
    if cfg.ToggleKeybind then
        local vk = keyToVk(cfg.ToggleKeybind)
        if vk then menuVk = vk end
    end
    Library.NotifySide = cfg.NotifySide or "Right"
    pcall(setrobloxinput, true)
    return win
end
local stopped = false
local function resolveRS()
    local rs = hostGet("RunService") or RS
    if not rs then pcall(function() rs = game:GetService("RunService") end) end
    if not rs then pcall(function() rs = game.RunService end) end
    return rs
end
local function trySignal(sig, cb)
    if not sig then return nil end
    local ok, conn = pcall(function() return sig:Connect(cb) end)
    if ok and conn then return conn end
    local ok2, conn2 = pcall(function() return sig.Connect(sig, cb) end)
    if ok2 and conn2 then return conn2 end
    return nil
end
local function connectRender(cb)
    local rs = resolveRS()
    if rs then
        for _, name in ipairs({ "RenderStepped", "Heartbeat", "Stepped" }) do
            local sig
            pcall(function() sig = rs[name] end)
            local conn = trySignal(sig, cb)
            if conn then return conn, name end
        end
    end
    local alive = true
    local conn = { Disconnect = function() alive = false end }
    task.spawn(function()
        while alive and not stopped do cb(0) task.wait(1 / 60) end
    end)
    return conn, "poll"
end
local function win0Text()
    local win = Windows[1]
    return fmt("%s  |  %d fps", win and win.title or "Swangy", fps)
end
local function tickLoop()
    if stopped then return end
    local ok, err = pcall(function()
        poll()
        frameCount = frameCount + 1
        if clock() - fpsClock >= 0.5 then
            fps = floor(frameCount / (clock() - fpsClock) + 0.5)
            frameCount, fpsClock = 0, clock()
        end
        if capturing then
            for _, code in ipairs(ALL_KEYS) do
                if keyEdge(code) then
                    capturing:Capture(code)
                    break
                end
            end
        end
        if focusedInput == nil and not capturing and isrbxactive() and keyEdge(menuVk) then
            local win = Windows[1]
            if win then win:Toggle() end
        end
        for _, kb in ipairs(Library.__keybinds) do
            if not capturing and kb.visible and not kb.destroyed then kb:Evaluate() end
        end
        if focusedInput and not capturing then
            for _, code in ipairs(INPUT_CODES) do
                if keyEdge(code) then focusedInput:Key(code) end
            end
        end
        hitList = {}
        local anyVisible = false
        for _, win in ipairs(Windows) do
            if win.visible then anyVisible = true win:Render() end
        end
        if watermarkOn then
            local wm = Library.__wm
            if not wm then
                wm = { bg = D.new("Square"), txt = D.new("Text") }
                wm.bg.Filled, wm.bg.Corner = true, 2
                wm.txt.Size = 14
                pcall(function() wm.txt.Font = FONT wm.bg.ZIndex = 200 wm.txt.ZIndex = 201 end)
                Library.__wm = wm
                local reg = _G.__swangy_wms
                reg[#reg + 1] = wm
            end
            local cam = workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
            local pos = Library.__wmPos or { x = 10, y = 10 }
            local s = win0Text()
            local w, h = textW(s, 14) + 16, 22
            pos.x = clamp(pos.x, 0, max(0, vp.X - w))
            pos.y = clamp(pos.y, 0, max(0, vp.Y - h))
            Library.__wmPos = pos
            wm.bg.Position, wm.bg.Size = Vector2.new(pos.x, pos.y), Vector2.new(w, h)
            wm.bg.Color, wm.bg.Transparency, wm.bg.Visible = Theme.main, 0.9, true
            wm.txt.Position, wm.txt.Text, wm.txt.Color, wm.txt.Visible = Vector2.new(pos.x + 8, pos.y + 3), s, Theme.text, true
            newHit(pos.x, pos.y, w, h, {
                press = function(px, py) Library.__wmDrag = { dx = px - pos.x, dy = py - pos.y } end,
                drag = function(px, py)
                    local d = Library.__wmDrag
                    if d then
                        Library.__wmPos = {
                            x = clamp(px - d.dx, 0, max(0, vp.X - w)),
                            y = clamp(py - d.dy, 0, max(0, vp.Y - h)),
                        }
                    end
                end,
                release = function() Library.__wmDrag = nil end,
            })
        elseif Library.__wm then
            Library.__wm.bg.Visible, Library.__wm.txt.Visible = false, false
        end
        if anyVisible then
            local win = Windows[1]
            if win and win.activeTab then
                for _, g in ipairs(win.activeTab.groups) do g:RenderPopups() end
            end
        end
        Library.__hits = hitList
        processInput()
        renderNotifs()
    end)
    if not ok then
        local msg = tostring(err)
        _G.__swangy_err = msg
        if _G.__swangy_lastwarn ~= msg then
            _G.__swangy_lastwarn = msg
            warn("[Swangy] frame error: " .. msg)
        end
    end
    _G.__swangy_frames = (_G.__swangy_frames or 0) + 1
end
local uiConn, uiSignal
local connOk, connRes, connName = pcall(connectRender, tickLoop)
if connOk then uiConn, uiSignal = connRes, connName
else uiConn = { Disconnect = function() end } end
Library.RenderSignal = uiSignal
function Library:Unload()
    stopped = true
    focusedInput = nil
    capturing = nil
    pcall(function() uiConn:Disconnect() end)
    for _, o in ipairs(ALL) do pcall(function() o.d:Remove() end) end
    for _, n in ipairs(notifs) do
        removeDrawings({ { d = n.bg }, { d = n.bar }, { d = n.tt }, { d = n.mt } })
    end
    notifs = {}
    if Library.__wm then
        pcall(function() Library.__wm.bg:Remove() end)
        pcall(function() Library.__wm.txt:Remove() end)
        Library.__wm = nil
    end
    pcall(function() MEAS:Remove() end)
end
do
    local reg = _G.__swangy_instances
    reg[#reg + 1] = Library
end
return Library
]=],
["sahur/lib/SaveManager.lua"] = [=[
local SaveManager = {}
_G.SwangySaveManager = SaveManager
_G.ObsidianSaveManager = SaveManager
local Library
local Folder = "Swangy"
local SubFolder = "Configs"
local IgnoreIndexes = {}
local LoadingOrder = nil
local function jsonEncode(t)
    local hs
    pcall(function() hs = game:GetService("HttpService") end)
    if hs then
        local ok, res = pcall(function() return hs:JSONEncode(t) end)
        if ok then return res end
    end
    return nil, "JSONEncode unavailable"
end
local function jsonDecode(s)
    local hs
    pcall(function() hs = game:GetService("HttpService") end)
    if hs then
        local ok, res = pcall(function() return hs:JSONDecode(s) end)
        if ok then return res end
    end
    return nil, "JSONDecode unavailable"
end
local function base()
    return Folder .. "/" .. SubFolder
end
local function ensureTree()
    if not isfolder(Folder) then pcall(makefolder, Folder) end
    local p = base()
    if not isfolder(p) then pcall(makefolder, p) end
    return p
end
local function safeName(name)
    name = tostring(name or "default")
    name = name:gsub("[^%w%-_ ]", "")
    if name == "" then name = "default" end
    return name
end
function SaveManager:SetLibrary(lib)
    Library = lib
    return self
end
function SaveManager:SetFolder(f)
    Folder = tostring(f)
    return self
end
function SaveManager:SetSubFolder(f)
    SubFolder = tostring(f)
    return self
end
function SaveManager:GetPaths()
    return { ensureTree() }
end
function SaveManager:BuildFolderTree()
    ensureTree()
    return self
end
function SaveManager:CheckFolderTree()
    ensureTree()
    return self
end
function SaveManager:CheckSubFolder()
    ensureTree()
    return self
end
function SaveManager:SetIgnoreIndexes(list)
    IgnoreIndexes = {}
    for _, v in ipairs(list or {}) do IgnoreIndexes[v] = true end
    return self
end
function SaveManager:SetLoadingOrder(enabled, order)
    LoadingOrder = order
    return self
end
function SaveManager:IgnoreThemeSettings()
    return self
end
local function ignored(id)
    return IgnoreIndexes[id] == true
end
local function gather()
    local out = {}
    if not Library then return out end
    for id, el in pairs(Library.Options) do
        if not ignored(id) and el and not el.destroyed then
            local kind = el.kind
            if kind == "Toggle" then
                out[id] = { t = "Toggle", v = el.value == true }
            elseif kind == "Slider" then
                out[id] = { t = "Slider", v = el.value }
            elseif kind == "Dropdown" then
                out[id] = { t = "Dropdown", v = el.value }
            elseif kind == "KeyPicker" then
                out[id] = { t = "KeyPicker", v = el.vk, m = el.mode }
            elseif kind == "ColorPicker" then
                local c = el:Color()
                out[id] = { t = "Color", r = c.R, g = c.G, b = c.B, a = el.alpha or 1 }
            end
        end
    end
    return out
end
local function applyData(data)
    if not Library then return false end
    for id, d in pairs(data or {}) do
        local el = Library.Options[id]
        if el and not ignored(id) then
            local kind = d.t or el.kind
            if kind == "Toggle" then
                el:SetValue(d.v == true)
            elseif kind == "Slider" then
                el:SetValue(d.v)
            elseif kind == "Dropdown" then
                el:SetValue(d.v)
            elseif kind == "KeyPicker" then
                el.vk = d.v
                if d.m then el.mode = d.m end
                el.state = false
            elseif kind == "Color" then
                local c = Color3.new(d.r or 1, d.g or 1, d.b or 1)
                el:SetValueRGB(c, 1 - (d.a or 1))
            end
        end
    end
    return true
end
function SaveManager:RefreshConfigList()
    ensureTree()
    local out = {}
    local ok, files = pcall(listfiles, base())
    if ok then
        for _, path in ipairs(files or {}) do
            local name = tostring(path):match("([^/\\]+)%.json$")
            if name then out[#out + 1] = name end
        end
    end
    table.sort(out)
    return out
end
function SaveManager:Save(ConfigName)
    if not Library then return false, "library not set" end
    local name = safeName(ConfigName)
    local encoded, err = jsonEncode({ Options = gather() })
    if not encoded then return false, err end
    ensureTree()
    local ok, werr = pcall(writefile, base() .. "/" .. name .. ".json", encoded)
    if not ok then return false, tostring(werr) end
    return true
end
function SaveManager:Load(ConfigName)
    local name = safeName(ConfigName)
    local path = base() .. "/" .. name .. ".json"
    if not isfile(path) then return false, "config not found" end
    local ok, content = pcall(readfile, path)
    if not ok then return false, tostring(content) end
    local data, derr = jsonDecode(content)
    if not data then return false, derr end
    applyData(data.Options or data)
    return true
end
function SaveManager:Delete(ConfigName)
    local name = safeName(ConfigName)
    local path = base() .. "/" .. name .. ".json"
    if not isfile(path) then return false, "config not found" end
    local ok, err = pcall(delfile, path)
    if not ok then return false, tostring(err) end
    return true
end
function SaveManager:Rename(OldName, NewName)
    local old = base() .. "/" .. safeName(OldName) .. ".json"
    if not isfile(old) then return false, "config not found" end
    local newp = base() .. "/" .. safeName(NewName) .. ".json"
    if isfile(newp) then return false, "a config with that name exists" end
    local ok, content = pcall(readfile, old)
    if not ok then return false, tostring(content) end
    local wok, werr = pcall(writefile, newp, content)
    if not wok then return false, tostring(werr) end
    pcall(delfile, old)
    if self:GetAutoloadConfig() == safeName(OldName) then
        self:SaveAutoloadConfig(NewName)
    end
    return true
end
function SaveManager:GetAutoloadConfig()
    local path = base() .. "/autoload.txt"
    if not isfile(path) then return nil end
    local ok, content = pcall(readfile, path)
    if not ok then return nil end
    return (tostring(content):gsub("%s+$", ""))
end
function SaveManager:SaveAutoloadConfig(ConfigName)
    ensureTree()
    local ok, err = pcall(writefile, base() .. "/autoload.txt", safeName(ConfigName))
    if not ok then return false, tostring(err) end
    return true
end
function SaveManager:LoadAutoloadConfig()
    local name = self:GetAutoloadConfig()
    if not name or name == "" then return false, "no autoload config" end
    return self:Load(name)
end
function SaveManager:DeleteAutoLoadConfig()
    local path = base() .. "/autoload.txt"
    if not isfile(path) then return false, "no autoload config" end
    pcall(delfile, path)
    return true
end
function SaveManager:BuildConfigSection(Tab, IconName)
    local group = Tab:AddGroupbox({ Side = "Right", Name = "Configs" })
    local list = self:RefreshConfigList()
    local nameInput
    local dd = group:AddDropdown("SaveManager_ConfigList", {
        Text = "Config",
        Values = list,
        Default = list[1],
        MaxVisible = 6,
        Callback = function(v)
            if nameInput then nameInput:SetValue(v or "") end
        end,
    })
    nameInput = group:AddInput("SaveManager_ConfigName", {
        Text = "Config name",
        Default = list[1] or "",
        Placeholder = "type a name",
    })
    local autoloadLabel = group:AddLabel({ Text = "Autoload: none", DoesWrap = true })
    local function currentName()
        local n = nameInput.value
        if not n or n == "" then n = dd.value end
        return n
    end
    local function updateAutoload()
        local a = self:GetAutoloadConfig()
        autoloadLabel:SetText("Autoload: " .. ((a and a ~= "") and a or "none"))
    end
    local function refresh()
        local l = self:RefreshConfigList()
        dd:SetValues(l)
        if not dd.value and l[1] then dd.value = l[1] end
        updateAutoload()
        return l
    end
    local function notify(msg, ok)
        if Library then Library:Notify(msg, 3, ok and "Config" or "Config error") end
    end
    group:AddButton({
        Text = "Save / Overwrite",
        Func = function()
            local name = currentName()
            if not name or name == "" then return notify("Pick a config or type a name", false) end
            local ok, err = self:Save(name)
            refresh()
            if ok then dd:SetValue(name) end
            notify(ok and ("Saved " .. name) or ("Save failed: " .. tostring(err)), ok)
        end,
    })
    group:AddButton({
        Text = "Rename",
        Func = function()
            local old, new = dd.value, nameInput.value
            if not old then return notify("No config selected", false) end
            if not new or new == "" then return notify("Type the new name", false) end
            local ok, err = self:Rename(old, new)
            refresh()
            if ok then dd:SetValue(new) end
            notify(ok and ("Renamed to " .. new) or ("Rename failed: " .. tostring(err)), ok)
        end,
    })
    group:AddButton({
        Text = "Load",
        Func = function()
            if not dd.value then return notify("No config selected", false) end
            local ok, err = self:Load(dd.value)
            notify(ok and ("Loaded " .. dd.value) or ("Load failed: " .. tostring(err)), ok)
        end,
    })
    group:AddButton({
        Text = "Delete",
        Func = function()
            if not dd.value then return notify("No config selected", false) end
            local name = dd.value
            local ok, err = self:Delete(name)
            refresh()
            if ok and self:GetAutoloadConfig() == name then
                self:DeleteAutoLoadConfig()
                updateAutoload()
            end
            notify(ok and ("Deleted " .. name) or ("Delete failed: " .. tostring(err)), ok)
        end,
    })
    group:AddButton({
        Text = "Set Autoload",
        Func = function()
            local name = currentName() or dd.value
            if not name or name == "" then return notify("Select a config first", false) end
            if not isfile(base() .. "/" .. safeName(name) .. ".json") then
                return notify("Save the config before setting autoload", false)
            end
            self:SaveAutoloadConfig(name)
            updateAutoload()
            notify("Autoload set to " .. name, true)
        end,
    })
    group:AddButton({
        Text = "Clear Autoload",
        Func = function()
            self:DeleteAutoLoadConfig()
            updateAutoload()
            notify("Autoload cleared", true)
        end,
    })
    group:AddButton({ Text = "Refresh", Func = refresh })
    group:AddLabel({ Text = "Configs are stored as JSON in " .. base() .. ".", DoesWrap = true })
    updateAutoload()
    pcall(function() self:LoadAutoloadConfig() end)
    return group
end
return SaveManager
]=],
["sahur/modules/i18n.lua"] = [=[
local I = {
    lang = "en",
    choices = { { "English", "en" }, { "Português", "pt" } },
}
_G.SahurI18N = I
I.strings = {
    en = {
        tab_aimbot = "Aimbot", tab_esp = "ESP", tab_misc = "Misc",
        tab_config = "Config", tab_settings = "Settings",
        wip = "Work in progress.",
        grp_interface = "Interface", menu_key = "Menu key", language = "Language", font = "Font",
        grp_appearance = "Appearance", accent = "Accent color", watermark = "Watermark",
        grp_script = "Script", unload = "Unload",
        unload_desc = "Removes the menu and stops every background loop.",
        version_lbl = "sahur %s",
        grp_about = "About", about_desc = "Save and load your settings as named configs.",
        loaded = "sahur loaded. Press the menu key to toggle.",
        lang_set = "Language changed.",
        unloaded = "sahur unloaded.",
        grp_tank_esp = "Tank ESP",
        esp_enabled = "Enabled", esp_teamcheck = "Team check", esp_names = "Names",
        esp_box = "Box",
        esp_class = "Vehicle class", esp_distance = "Distance", esp_maxdist = "Max distance",
        esp_crewcount = "Crew count", esp_reload = "Reload status", esp_col_reload = "Reload color", esp_textbg = "Text background",
        grp_tank_chams = "Tank chams", chams_ammo = "Ammo", chams_engine = "Engine", chams_crew = "Crew", chams_barrel = "Barrel", chams_tracks = "Tracks", esp_boxstyle = "Box style",
        chams_box = "Box outline", chams_dist = "Chams distance",
        grp_aimbot = "Aimbot", aim_enabled = "Enabled", aim_key = "Aim key", aim_fov = "FOV",
        aim_smooth = "Smoothing", aim_lead = "Lead target", aim_drop = "Bullet drop",
        aim_shellms = "Shell speed", aim_target = "Target", aim_showfov = "Show FOV", aim_teamcheck = "Team check",
        aim_predict = "Aimbot Prediction", aim_sticky = "Sticky aim", aim_fov_color = "FOV color", aim_deadzone = "Deadzone",
        aim_inherit = "Shell carries tank speed", aim_shellfb = "Shell speed (fallback)",
        aim_dropmul = "Drop multiplier", aim_leadmul = "Lead multiplier", aim_speedcomp = "Speed compensation",
        aim_readout = "Ballistics readout",
        esp_degraded = "Roblox client is outdated - class labels off. Restart Roblox to update.",
        grp_misc = "Misc", misc_barrel = "Barrel line", misc_line_len = "Line length",
        misc_heli = "Heli ballistic computer", misc_heli_color = "Path color", misc_heli_marker = "Impact marker", misc_missile = "Missile ESP",
        aim_reloadpause = "Pause while reloading", aim_hulldamp = "Hull-motion damping (DEV TEST)", aim_classic = "Classic aim (DEV TEST)", aim_hill = "Hill & elevation logic (DEV TEST)", aim_reticle = "Reticle aim (DEV TEST)", chams_infov = "Only inside FOV",
        esp_col_box = "Box color", esp_col_name = "Name color", esp_col_dist = "Distance color", esp_col_crew = "Crew color",
        chams_col_ammo = "Ammo color", chams_col_engine = "Engine color", chams_col_crew = "Crew color", chams_col_barrel = "Barrel color", chams_col_tracks = "Tracks color",
        misc_fov = "FOV circle", misc_fov_radius = "FOV radius",
    },
    pt = {
        tab_aimbot = "Aimbot", tab_esp = "ESP", tab_misc = "Misc",
        tab_config = "Config", tab_settings = "Settings",
        wip = "Em desenvolvimento.",
        grp_interface = "Interface", menu_key = "Tecla do menu", language = "Idioma", font = "Fonte",
        grp_appearance = "Aparência", accent = "Cor de destaque", watermark = "Marca d'água",
        grp_script = "Script", unload = "Descarregar",
        unload_desc = "Remove o menu e encerra todos os processos em segundo plano.",
        version_lbl = "sahur %s",
        grp_about = "Sobre", about_desc = "Salve e carregue suas configurações como perfis.",
        loaded = "sahur carregado. Use a tecla do menu para abrir.",
        lang_set = "Idioma alterado.",
        unloaded = "sahur descarregado.",
        grp_tank_esp = "ESP de Tanques",
        esp_enabled = "Ativado", esp_teamcheck = "Checar time", esp_names = "Nomes",
        esp_box = "Caixa",
        esp_class = "Classe do veículo", esp_distance = "Distância", esp_maxdist = "Distância máxima",
        esp_crewcount = "Tripulantes", esp_reload = "Status de recarga", esp_col_reload = "Cor da recarga", esp_textbg = "Fundo do texto",
        grp_tank_chams = "Chams do tanque", chams_ammo = "Munição", chams_engine = "Motor", chams_crew = "Tripulação", chams_barrel = "Cano", chams_tracks = "Esteiras", esp_boxstyle = "Estilo da caixa",
        chams_box = "Contorno", chams_dist = "Distância chams",
        grp_aimbot = "Aimbot", aim_enabled = "Ativado", aim_key = "Tecla de mira", aim_fov = "FOV",
        aim_smooth = "Suavização", aim_lead = "Prever alvo", aim_drop = "Queda do projétil",
        aim_shellms = "Velocidade", aim_target = "Alvo", aim_showfov = "Mostrar FOV", aim_teamcheck = "Checar time",
        aim_predict = "Predição do aimbot", aim_sticky = "Mira fixa", aim_fov_color = "Cor do FOV", aim_deadzone = "Zona morta",
        aim_inherit = "Projétil herda velocidade", aim_shellfb = "Velocidade (reserva)",
        aim_dropmul = "Multiplicador de queda", aim_leadmul = "Multiplicador de avanço", aim_speedcomp = "Compensação de velocidade",
        aim_readout = "Dados balísticos",
        esp_degraded = "Cliente do Roblox desatualizado - classes desligadas. Reinicie o Roblox.",
        grp_misc = "Diversos", misc_barrel = "Linha do cano", misc_line_len = "Comprimento",
        misc_heli = "Computador balístico (heli)", misc_heli_color = "Cor da trajetória", misc_heli_marker = "Marcador de impacto", misc_missile = "ESP de mísseis",
        aim_reloadpause = "Pausar ao recarregar", aim_hulldamp = "Amortecimento do casco (DEV TEST)", aim_classic = "Mira clássica (DEV TEST)", aim_hill = "Lógica de morros e elevação (DEV TEST)", aim_reticle = "Mira pelo retículo (DEV TEST)", chams_infov = "Só dentro do FOV",
        esp_col_box = "Cor da caixa", esp_col_name = "Cor do nome", esp_col_dist = "Cor da distância", esp_col_crew = "Cor da tripulação",
        chams_col_ammo = "Cor da munição", chams_col_engine = "Cor do motor", chams_col_crew = "Cor da tripulação", chams_col_barrel = "Cor do cano", chams_col_tracks = "Cor das esteiras",
        misc_fov = "Círculo FOV", misc_fov_radius = "Raio do FOV",
    },
}
function I:Set(code) if self.strings[code] then self.lang = code end return self end
function I:Get() return self.lang end
function I.t(key, ...)
    local s = I.strings[I.lang]
    local v = (s and s[key]) or I.strings.en[key] or key
    if select("#", ...) > 0 then
        local ok, out = pcall(string.format, v, ...)
        if ok then return out end
    end
    return v
end
return I
]=],
["sahur/modules/tanks.lua"] = [=[
local R = {
    list = {}, byAddr = {}, myAddr = nil, myTank = nil, attrOK = true,
    stats = { builds = 0, lastTickMs = 0, maxTickMs = 0 },
}
_G.SahurTanks = R
local Players   = game:GetService("Players")
local Workspace = workspace
local clock = os.clock
local BUILD_BUDGET = 0.004
local RR_PER_TICK  = 1
local TICK         = 0.1
local LIVE_EVERY   = 0.2
local TEAM_EVERY   = 8
local RESCAN_EVERY = 2
local OCC_R        = 12
local CREW_R       = 14
local MOVE_OCC     = 3
local CREW_GONE    = 5
local TURRET_Y     = 3.0
local DM_CHECK     = 3
do
    local ok, res = pcall(httpget, "https://clientsettings.roblox.com/v2/client-version/WindowsPlayer")
    local live
    if ok and type(res) == "string" then
        local dok, data = pcall(function() return game:GetService("HttpService"):JSONDecode(res) end)
        if dok and type(data) == "table" then live = data.clientVersionUpload end
    end
    local vok, mine = pcall(getrbxversion)
    if type(live) == "string" and vok and type(mine) == "string" and mine:find("version-", 1, true) and mine ~= live then R.attrOK = false end
end
R.TRACE = false
local function tr(msg) if R.TRACE then pcall(appendfile, "sahur_trace.txt", tostring(msg) .. "\n") end end
local BB_FILE, bbLines = "sahur_blackbox.txt", 0
do
    local ok, old = pcall(readfile, BB_FILE)
    if ok and type(old) == "string" and #old > 0 then pcall(writefile, "sahur_blackbox_prev.txt", old) end
    pcall(writefile, BB_FILE, "start\n")
end
local function bb(msg)
    bbLines = bbLines + 1
    if bbLines > 6000 then return end
    pcall(appendfile, BB_FILE, string.format("%.1f %s\n", clock(), tostring(msg)))
end
R.bb = bb
R.tr = tr
local perf = {}
function _G.SahurPerfAdd(name, t0) perf[name] = (perf[name] or 0) + (clock() - t0) * 1000 end
R.perf = perf
local RT = {}
pcall(function()
    local src = (_G.SahurSrc and _G.SahurSrc["sahur/data/roundtypes.lua"]) or readfile("sahur/data/roundtypes.lua")
    local f = src and loadstring(src)
    if f then f() end
    if type(_G.SahurRoundTypes) == "table" then RT = _G.SahurRoundTypes end
end)
local rtCache = {}
function _G.SahurRoundType(nm)
    if type(nm) ~= "string" or nm == "" or nm == "Unloaded" then return nil end
    local c = rtCache[nm]
    if c ~= nil then return c or nil end
    local s = RT[nm]
    if not s then
        for k, v in pairs(RT) do if #k >= 4 and nm:sub(1, #k) == k then s = v; break end end
    end
    if not s then
        local u = nm:upper()
        if u:find("APFSDS") or u:find("^3BM") or u:find("^M8[23]%d") then s = "APFSDS"
        elseif u:find("HEAT") or u:find("^3BK") then s = "HEAT"
        elseif u:find("APDS") then s = "APDS"
        elseif u:find("HESH") then s = "HESH"
        elseif u:find("^3OF") or u:find("HE") then s = "HE"
        elseif u:find("SMOKE") then s = "SMOKE"
        else s = u:sub(1, 8) end
    end
    rtCache[nm] = s
    return s
end
local function calOf(n) return tonumber(tostring(n):match("^(%d+%.?%d*)")) or 0 end
function R.mainLoaded(e)
    if e.loadObj then return e.loadObj end
    local now = clock()
    if now - (e.loadFindAt or -1e9) < 3 then return nil end
    e.loadFindAt = now
    local ok, obj = pcall(function()
        local tf = e.v:FindFirstChild("Turrets")
        if not tf then return nil end
        local best, bestScore
        for _, t in ipairs(tf:GetChildren()) do
            local w = t:FindFirstChild("Weapons")
            if w then
                for _, g in ipairs(w:GetChildren()) do
                    local cl = g:FindFirstChild("CurrentlyLoaded")
                    local nm = g.Name:lower()
                    if cl and not nm:find("smoke") and not nm:find("flare") then
                        local ty = g:FindFirstChild("Type")
                        local tv = ty and ty.Value
                        if tv ~= "MG" then
                            local score = calOf(g.Name) + ((tv == "LOAD" or tv == "AUTO") and 10000 or 0)
                            if not bestScore or score > bestScore then best, bestScore = cl, score end
                        end
                    end
                end
            end
        end
        return best
    end)
    e.loadObj = ok and obj or nil
    return e.loadObj
end
local function getAttr(inst, name)
    if not R.attrOK then return nil end
    bb("attr " .. tostring(name))
    local ok, v = pcall(function() return inst:GetAttribute(name) end)
    if ok then return v end
    return nil
end
local CLASS_ABBR = {
    ["Main Battle Tank"] = "MBT", ["Medium Tank"] = "MT", ["Light Tank"] = "LT", ["Heavy Tank"] = "HT",
    ["Tank Destroyer"] = "TD", ["Infantry Fighting Vehicle"] = "IFV", ["Armoured Personnel Carrier"] = "APC",
    ["Armored Personnel Carrier"] = "APC", ["Self Propelled Anti Aircraft"] = "SPAA",
    ["Self Propelled Artillery"] = "SPG", ["Self Propelled Howitzer"] = "SPH", ["Self Propelled Gun"] = "SPG",
    ["Attack Helicopter"] = "HELI", ["Scout Helicopter"] = "HELI", ["Transport Helicopter"] = "HELI",
    ["Transport Vehicle"] = "APC",
}
local function boxCorners(sz, extraUp)
    local hx, hy, hz = sz.X * 0.5, sz.Y * 0.5, sz.Z * 0.5
    local top = hy + (extraUp or 0)
    return {
        { -hx, -hy, -hz }, { hx, -hy, -hz }, { -hx, -hy, hz }, { hx, -hy, hz },
        { -hx, top, -hz }, { hx, top, -hz }, { -hx, top, hz }, { hx, top, hz },
    }
end
local function toWorld(cf, c)
    local p, r, u, l = cf.Position, cf.RightVector, cf.UpVector, cf.LookVector
    return p + r * c[1] + u * c[2] - l * c[3]
end
local function toMassLocal(massCF, partCF, corners)
    local mp, mr, mu, ml = massCF.Position, massCF.RightVector, massCF.UpVector, massCF.LookVector
    local out = {}
    local sx, sy, sz = 0, 0, 0
    for i = 1, 8 do
        local d = toWorld(partCF, corners[i]) - mp
        local x, y, z = d:Dot(mr), d:Dot(mu), -d:Dot(ml)
        out[i] = { x, y, z }; sx = sx + x; sy = sy + y; sz = sz + z
    end
    return out, { sx / 8, sy / 8, sz / 8 }
end
R.toWorld = toWorld
local function build(v)
    tr("build start " .. tostring(v.Name))
    bb("build " .. tostring(v.Name))
    local hull = v:FindFirstChild("Hull")
    local mass = hull and hull:FindFirstChild("Mass")
    if not mass then return false end
    local okm, massCF = pcall(function() return mass.CFrame end)
    local oks, massSz = pcall(function() return mass.Size end)
    if not okm or not massCF or not oks or not massSz then return false end
    local e = {
        v = v, name = v.Name, mass = mass, massCorners = boxCorners(massSz),
        mods = {}, racks = {}, owner = v:FindFirstChild("Owner"),
        enemy = true, occupied = false, everOcc = false, crew = 0, liveAmmo = {}, dead = false,
    }
    e.vclass = nil; e.classTried = false
    e.teamAt = -1e9
    local function partRec(p, kind, fixed, extraUp)
        local okc, pcf = pcall(function() return p.CFrame end)
        local okz, psz = pcall(function() return p.Size end)
        if not okc or not pcf or not okz or not psz then return nil end
        local corners = boxCorners(psz, extraUp)
        local rec = { part = p, kind = kind, fixed = fixed, vol = psz.X * psz.Y * psz.Z }
        if fixed then rec.corners, rec.lc = toMassLocal(massCF, pcf, corners)
        else rec.corners = corners end
        rec.baseLocal = (massCF:Inverse() * pcf).Position
        return rec
    end
    local vals = v:FindFirstChild("Values")
    local hp = vals and vals:FindFirstChild("DamageModule")
    local dm = v:FindFirstChild("DamageModules")
    local mdls = dm and dm:GetChildren() or {}
    if #mdls > 80 then tr("  too many modules " .. #mdls); return false end
    if dm then
        for _, mdl in ipairs(mdls) do
            tr("  module " .. tostring(mdl.Name))
            local mname = mdl.Name
            local ammoObj = mdl:FindFirstChild("AmmoValue")
            local inHull = mname:find("Hull", 1, true) ~= nil
            local rack = ammoObj and { ammoObj = ammoObj, name = mname, parts = {} } or nil
            local mparts = mdl:GetChildren()
            if #mparts > 200 then tr("  too many parts " .. #mparts); return false end
            for _, p in ipairs(mparts) do
                local pn = p.Name
                local cn = p.ClassName
                if cn == "MeshPart" or cn == "Part" then
                    if pn == "Engine" then
                        local r = partRec(p, "eng", true)
                        if r then e.mods[#e.mods + 1] = r; e.engine = r end
                    elseif pn:match("^Turret%d+Barrel$") then
                        local r = partRec(p, "barrel", false)
                        if r then e.mods[#e.mods + 1] = r end
                    elseif pn == "LeftTrack" or pn == "RightTrack" then
                        local r = partRec(p, "track", true)
                        if r then e.mods[#e.mods + 1] = r end
                    elseif pn:match("^AmmoModel%d+$") then
                        local r = partRec(p, "ammo", inHull)
                        if r then
                            e.mods[#e.mods + 1] = r
                            r.hpObj = hp and hp:FindFirstChild(pn)
                            if rack then rack.parts[#rack.parts + 1] = r end
                        end
                    end
                end
            end
            if rack and #rack.parts > 0 then
                local lname = mname:lower()
                if inHull then rack.turret, rack.sure = false, true
                elseif lname:find("turret", 1, true) or lname:find("bustle", 1, true) then rack.turret, rack.sure = true, true
                else
                    local y = rack.parts[1].baseLocal and rack.parts[1].baseLocal.Y or 0
                    rack.turret, rack.sure = (y > TURRET_Y), false
                end
                for _, r in ipairs(rack.parts) do r.turret = rack.turret end
                e.racks[#e.racks + 1] = rack
            end
        end
    end
    tr("  seats")
    local seats = v:FindFirstChild("Seats")
    if seats then
        local g = seats:FindFirstChild("Gunner"); local gp = g and g.Value
        if gp then local r = partRec(gp, "crew", false, 3.5) if r then e.mods[#e.mods + 1] = r; e.gunner = r end end
        local d = seats:FindFirstChild("Driver"); local dp = d and d.Value
        if dp then local r = partRec(dp, "crew", true, 3.5) if r then e.mods[#e.mods + 1] = r end end
    end
    e.dmCount = #mdls; e.dmCheckAt = clock()
    tr("build done " .. tostring(e.name))
    bb("built " .. tostring(e.name))
    R.stats.builds = R.stats.builds + 1
    return e
end
local playerPos = {}
local PLAYER_LIST, PLAYER_POS = 6, 2
local hrpList, hrpAt, myName = {}, -1e9, nil
local function refreshPlayers()
    local now = clock()
    if now - hrpAt >= PLAYER_LIST then
        hrpAt = now
        local lp = Players.LocalPlayer
        if not myName then local okm, mn = pcall(function() return lp.Name end); myName = okm and mn or nil end
        local list = {}
        local ok, plist = pcall(function() return Players:GetPlayers() end)
        if ok and plist then
            for _, p in ipairs(plist) do
                local okn, nm = pcall(function() return p.Name end)
                if okn and nm ~= myName then
                    local okh, hrp = pcall(function() local ch = p.Character; return ch and ch:FindFirstChild("HumanoidRootPart") end)
                    if okh and hrp then list[#list + 1] = hrp end
                end
            end
        end
        hrpList = list
    end
    local out = {}
    for i = 1, #hrpList do
        local h = hrpList[i]
        local okp, pos = pcall(function() return h.Position end)
        if okp and pos then out[#out + 1] = pos end
    end
    playerPos = out
end
local function lpTeamName() local lp = Players.LocalPlayer return lp and lp.Team and lp.Team.Name end
local function refreshLive(e)
    tr("live start " .. tostring(e.name))
    local now = clock()
    if now - (e.teamAt or -1e9) >= TEAM_EVERY then
        e.teamAt = now
        local ov = e.owner and e.owner.Value
        local tn = ov and ov.Team and ov.Team.Name
        local me = lpTeamName()
        e.enemy = (not tn or not me) and true or (tn ~= me)
        local lp = Players.LocalPlayer
        local okn, own = pcall(function() return ov and lp and ov.Name == lp.Name end)
        if okn and own then e.enemy = true end
    end
    local okp, mp = pcall(function() return e.mass.Position end)
    local n, near = 0, false
    if okp and mp then
        for i = 1, #playerPos do
            local dist = (playerPos[i] - mp).Magnitude
            if dist < CREW_R then n = n + 1 end
            if dist < OCC_R then near = true end
        end
    end
    e.crew = n
    local moving = false
    if okp and mp then
        if e._occP and now - e._occT > 0.05 then moving = (mp - e._occP).Magnitude / (now - e._occT) > MOVE_OCC end
        e._occP, e._occT = mp, now
    end
    local occ = near or moving
    e.occupied = occ
    if near then e.everOcc = true end
    if occ then e.unoccAt = nil elseif not e.unoccAt then e.unoccAt = now end
    tr("  live racks")
    local live, partsWithHp, partsDestroyed = {}, 0, 0
    for _, rack in ipairs(e.racks) do
        local oka, ammo = pcall(function() return rack.ammoObj.Value end)
        ammo = (oka and tonumber(ammo)) or 0
        for _, r in ipairs(rack.parts) do
            local h
            if r.hpObj then local okh, hv = pcall(function() return r.hpObj.Value end) if okh then h = tonumber(hv) end end
            if h then partsWithHp = partsWithHp + 1; if h <= 0 then partsDestroyed = partsDestroyed + 1 end end
            if ammo > 0 and (h == nil or h > 0) then live[#live + 1] = r end
        end
    end
    e.liveAmmo = live
    if now - (e.dmCheckAt or 0) >= DM_CHECK then
        e.dmCheckAt = now
        local dm = e.v:FindFirstChild("DamageModules")
        local okc, cnt = pcall(function() return dm and #dm:GetChildren() or 0 end)
        if okc and cnt ~= e.dmCount then e.stale = true end
        local okm, mcf = pcall(function() return e.mass.CFrame end)
        if okm and mcf then
            for _, rack in ipairs(e.racks) do
                if not rack.sure and not rack.turret then
                    local r = rack.parts[1]
                    local okp, pcf = pcall(function() return r.part.CFrame end)
                    if okp and pcf and r.baseLocal and ((mcf:Inverse() * pcf).Position - r.baseLocal).Magnitude > 0.3 then
                        rack.turret, rack.sure = true, true
                        for _, rr2 in ipairs(rack.parts) do rr2.turret = true end
                    end
                end
            end
        end
    end
    tr("live done")
    e.dead = (partsWithHp > 0 and partsDestroyed == partsWithHp)
        or (e.everOcc and not e.occupied and e.unoccAt ~= nil and now - e.unoccAt >= CREW_GONE)
    if e.dead ~= e._deadLogged then
        e._deadLogged = e.dead
        if e.dead then bb(string.format("dead %s racks=%d/%d occ=%s", tostring(e.name), partsDestroyed, partsWithHp, tostring(e.occupied))) end
    end
end
local loopRunning = false
local rr = 0
local lastPlayers = 0
R._build, R._refreshLive, R._refreshPlayers = build, refreshLive, refreshPlayers
function R.start()
    if loopRunning then return R end
    loopRunning = true
    local lastCount, lastRescan, pending = -1, -1e9, false
    local lastMapCheck, lastMapKey = 0, nil
    local failAt = {}
    local lastBeat = 0
    local inTankObj, inTankAt, svObj, svAt = nil, -1e9, nil, -1e9
    local buildQ = {}
    local lastLive = -1e9
    local sec, secT = {}, 0
    local function lap(name) local t = clock(); sec[name] = (sec[name] or 0) + (t - secT) * 1000; secT = t end
    R.sec = sec
    task.spawn(function()
        while loopRunning do
            local t0 = clock()
            secT = t0
            local okT, errT = pcall(function()
                local lp = Players.LocalPlayer
                if not inTankObj or t0 - inTankAt > 5 then
                    inTankAt = t0
                    local okI, io = pcall(function() return lp and lp:FindFirstChild("InTank") end)
                    inTankObj = okI and io or nil
                end
                local it = inTankObj
                local okV, mv = pcall(function() return it and it.Value end)
                if not okV then mv = nil; inTankObj = nil end
                local okA, ma = pcall(function() return mv and mv.Address end)
                R.myAddr = (okA and ma) or nil
                lap("me")
                if t0 - lastPlayers > PLAYER_POS then refreshPlayers(); lastPlayers = t0 end
                lap("players")
                if t0 - lastMapCheck >= 1 then
                    lastMapCheck = t0
                    local okM, mapName = pcall(function() return Workspace.Map.CurrentlyLoaded.Value end)
                    local okA2, mapAddr = pcall(function() return Workspace.Map.Address end)
                    local key = tostring(okM and mapName) .. "|" .. tostring(okA2 and mapAddr)
                    if lastMapKey and key ~= lastMapKey then
                        bb("map change " .. key)
                        R.list, R.byAddr, R.myTank = {}, {}, nil
                        for k in pairs(failAt) do failAt[k] = nil end
                        buildQ, svObj, inTankObj = {}, nil, nil
                        lastCount, pending = -1, true
                        R.epoch = (R.epoch or 0) + 1
                        R.stats.mapChanges = (R.stats.mapChanges or 0) + 1
                    end
                    lastMapKey = key
                end
                lap("map")
                if not svObj or t0 - svAt > 5 then
                    svAt = t0
                    local okS, so = pcall(function() return Workspace:FindFirstChild("SpawnedVehicles") end)
                    svObj = okS and so or nil
                end
                local sv = svObj
                local ok, kids = pcall(function() return sv and sv:GetChildren() end)
                if not ok then svObj = nil end
                if not ok or not kids then R.list = {}; return end
                if #kids > 400 then R.stats.tickErr = "SpawnedVehicles returned " .. #kids .. " children (garbage read?)"; return end
                for fa, at in pairs(failAt) do if t0 >= at then failAt[fa] = nil; if R.byAddr[fa] == false then R.byAddr[fa] = nil end end end
                local built = false
                lap("kids")
                local due = #kids ~= lastCount or t0 - lastRescan >= RESCAN_EVERY
                    or (#buildQ > 0 and t0 - lastRescan > 1) or (pending and #buildQ == 0)
                if due then
                    buildQ = {}
                    lastCount, lastRescan, pending = #kids, t0, false
                    local seen, list = {}, {}
                    for _, v in ipairs(kids) do
                        local okv, a = pcall(function() return v.Address end)
                        if okv and a then
                            seen[a] = true
                            local e = R.byAddr[a]
                            if e == nil then buildQ[#buildQ + 1] = { a = a, v = v }
                            elseif e then list[#list + 1] = e end
                        end
                    end
                    for a in pairs(R.byAddr) do if not seen[a] then R.byAddr[a] = nil end end
                    R.list = list
                end
                local tb = clock()
                while #buildQ > 0 and (not built or clock() - tb < BUILD_BUDGET) do
                    local q = table.remove(buildQ, 1)
                    if R.byAddr[q.a] == nil then
                        local okB, res = pcall(build, q.v)
                        local e
                        if okB then e = res else e = false; R.stats.buildErr = tostring(res) end
                        if e then
                            e.addr = q.a
                            local okL, errL = pcall(refreshLive, e); if not okL then R.stats.liveErr = tostring(errL) end
                            R.list[#R.list + 1] = e
                        end
                        R.byAddr[q.a] = e
                        if e == false then failAt[q.a] = t0 + 2 end
                        built = true
                    end
                end
                if #buildQ > 0 then pending = true end
                lap(built and "build" or "rescan")
                R.myTank = R.myAddr and R.byAddr[R.myAddr] or nil
                local list = R.list
                local n = #list
                if not built and n > 0 and t0 - lastLive >= LIVE_EVERY then
                    lastLive = t0
                    for _ = 1, math.min(RR_PER_TICK, n) do
                        rr = rr % n + 1
                        local e = list[rr]
                        if e then
                            pcall(refreshLive, e)
                            if e.stale then R.byAddr[e.addr] = nil; pending = true end
                        end
                    end
                    lap("live")
                    if R.attrOK then
                        for _, e in ipairs(list) do
                            if not e.classTried then
                                e.classTried = true
                                local c = getAttr(e.v, "VehicleClass")
                                c = (c ~= nil) and tostring(c) or ""
                                e.vclass = (c ~= "") and (CLASS_ABBR[c] or c) or nil
                                break
                            end
                        end
                        lap("attr")
                    end
                end
            end)
            if not okT then R.stats.tickErr = tostring(errT) end
            local ms = (clock() - t0) * 1000
            R.stats.lastTickMs = ms
            if ms > R.stats.maxTickMs then R.stats.maxTickMs = ms end
            if t0 - lastBeat >= 2 then
                lastBeat = t0
                local A, H = _G.SahurAim, _G.SahurHeli
                local parts = {}
                for k, v in pairs(sec) do parts[#parts + 1] = string.format("%s=%.0f", k, v); sec[k] = 0 end
                for k, v in pairs(perf) do parts[#parts + 1] = string.format("%s=%.0f", k:upper(), v); perf[k] = 0 end
                bb(string.format("hb tanks=%d me=%s tick=%.1fms max=%.1f aimF=%s lock=%s heliF=%s err=%s sec[%s]",
                    #R.list, tostring(R.myTank and R.myTank.name), ms, R.stats.maxTickMs,
                    tostring(A and A._frames), tostring(A and A._why),
                    tostring(H and H._frames), tostring(R.stats.tickErr), table.concat(parts, " ")))
            end
            task.wait(TICK)
        end
    end)
    return R
end
function R.stop()
    loopRunning = false
    R.list, R.byAddr, R.myTank, R.myAddr = {}, {}, nil, nil
    return R
end
return R
]=],
["sahur/modules/esp.lua"] = [=[
local ESP = {
    Config = {
        Enabled = true, TeamCheck = true, Box = true, Names = true, Class = true,
        Distance = true, CrewCount = false, MaxDist = 4000,
        Reload = true,
        BoxStyle = "Full",
        Barrel = false, Tracks = false,
        Engine = false, Ammo = false, Crew = false, ChamsBox = false, ChamsDist = 500,
        ChamsInFov = false,
    },
}
_G.SahurESP = ESP
local Config = ESP.Config
local RunService = game:GetService("RunService")
local Workspace  = workspace
local floor, huge = math.floor, math.huge
local V2, V3 = Vector2.new, Vector3.new
local WTS = WorldToScreen
local STUDS_TO_M = 1 / 2.7777778
local FONT = (Drawing.Fonts and Drawing.Fonts.System) or 1
local COL_BOX    = Color3.fromRGB(255, 255, 255)
local COL_NAME   = Color3.fromRGB(255, 255, 255)
local COL_DIST   = Color3.fromRGB(140, 220, 255)
local COL_CREW   = Color3.fromRGB(150, 210, 255)
local COL_RELOAD = Color3.fromRGB(255, 210, 90)
local ALPHA = { Box = 1, Name = 1, Distance = 1, Crew = 1, Reload = 1 }
local FILL_A = 0.5
local CORNER = 0.25
local RL_EVERY   = 0.5
local KIND_COL = { eng = Color3.fromRGB(255, 140, 0), ammo = Color3.fromRGB(255, 40, 40), crew = Color3.fromRGB(90, 200, 255),
    barrel = Color3.fromRGB(255, 230, 90), track = Color3.fromRGB(170, 170, 170) }
local KIND_A   = { eng = 0.4, ammo = 0.4, crew = 0.4, barrel = 0.4, track = 0.4 }
local KIND_ON  = { eng = "Engine", ammo = "Ammo", crew = "Crew", barrel = "Barrel", track = "Tracks" }
local BoxEdges = { {1,2},{3,4},{1,3},{2,4},{5,6},{7,8},{5,7},{6,8},{1,5},{2,6},{3,7},{4,8} }
local POOL, MODCAP, NTRI = 20, 240, 6
local function mkTxt() local t = Drawing.new("Text"); t.Size = 13; t.Center = true; t.Outline = true; t.Visible = false; pcall(function() t.Font = FONT end) return t end
local slots, modSlots = {}, {}
for i = 1, POOL do
    local s = { lines = {} }
    for j = 1, 24 do local l = Drawing.new("Line"); l.Thickness = 1; l.Color = COL_BOX; l.Transparency = 1; l.Visible = false; s.lines[j] = l end
    s.tris = {}
    for j = 1, NTRI do local tr = Drawing.new("Triangle"); tr.Filled = true; tr.Color = COL_BOX; tr.Transparency = FILL_A; tr.Visible = false; s.tris[j] = tr end
    s.name = mkTxt(); s.dist = mkTxt(); s.crew = mkTxt(); s.rl = mkTxt()
    s.name.Color = COL_NAME; s.dist.Color = COL_DIST; s.crew.Color = COL_CREW
    slots[i] = s
end
local function newModSlot()
    local ms = { lines = {}, tris = {}, kind = nil }
    for j = 1, 12 do local l = Drawing.new("Line"); l.Thickness = 1; l.Visible = false; ms.lines[j] = l end
    for j = 1, NTRI do local tr = Drawing.new("Triangle"); tr.Filled = true; tr.Visible = false; ms.tris[j] = tr end
    modSlots[#modSlots + 1] = ms
    return ms
end
for _ = 1, 24 do newModSlot() end
local function hideSlot(s) for j = 1, 24 do s.lines[j].Visible = false end for j = 1, NTRI do s.tris[j].Visible = false end s.name.Visible = false; s.dist.Visible = false; s.crew.Visible = false; s.rl.Visible = false end
local function hideMod(ms) for j = 1, 12 do ms.lines[j].Visible = false end for j = 1, NTRI do ms.tris[j].Visible = false end end
local function setModKind(ms, kind)
    if ms.kind == kind then return end
    ms.kind = kind
    local col, al = KIND_COL[kind], KIND_A[kind]
    for j = 1, NTRI do ms.tris[j].Color = col; ms.tris[j].Transparency = al end
    local la = math.min(1, al * 2.5)
    for j = 1, 12 do ms.lines[j].Color = col; ms.lines[j].Transparency = la end
end
local function setTxt(field, c, a)
    for _, s in ipairs(slots) do local t = s[field]; t.Color = c; t.Transparency = a; t.Outline = a >= 0.75 end
end
function ESP.SetColor(key, c, a)
    if ALPHA[key] and a then ALPHA[key] = a end
    local al = ALPHA[key]
    if key == "Box" then
        COL_BOX = c
        for _, s in ipairs(slots) do
            for j = 1, 24 do s.lines[j].Color = c; s.lines[j].Transparency = al end
            for j = 1, NTRI do s.tris[j].Color = c; s.tris[j].Transparency = FILL_A * al end
        end
    elseif key == "Name" then COL_NAME = c; setTxt("name", c, al)
    elseif key == "Distance" then COL_DIST = c; setTxt("dist", c, al)
    elseif key == "Crew" then COL_CREW = c; setTxt("crew", c, al)
    elseif key == "Reload" then COL_RELOAD = c; setTxt("rl", c, al)
    else
        local k = (key == "Engine" and "eng") or (key == "Ammo" and "ammo") or (key == "CrewChams" and "crew")
            or (key == "Barrel" and "barrel") or (key == "Tracks" and "track")
        if k then KIND_COL[k] = c; if a then KIND_A[k] = a end; for _, ms in ipairs(modSlots) do ms.kind = nil end end
    end
end
ESP.colors = function() return { Box = COL_BOX, Name = COL_NAME, Distance = COL_DIST, Crew = COL_CREW, Reload = COL_RELOAD,
    Engine = KIND_COL.eng, Ammo = KIND_COL.ammo, CrewChams = KIND_COL.crew, Barrel = KIND_COL.barrel, Tracks = KIND_COL.track } end
ESP.alphas = function() return { Box = ALPHA.Box, Name = ALPHA.Name, Distance = ALPHA.Distance, Crew = ALPHA.Crew,
    Reload = ALPHA.Reload, Engine = KIND_A.eng, Ammo = KIND_A.ammo, CrewChams = KIND_A.crew, Barrel = KIND_A.barrel, Tracks = KIND_A.track } end
local PTS, FRONT = {}, {}
local PJ = { ok = false, cx = 0, cy = 0, k = 1, W = 1920, H = 1080,
    px = 0, py = 0, pz = 0, rx = 1, ry = 0, rz = 0, ux = 0, uy = 1, uz = 0, lx = 0, ly = 0, lz = -1 }
local vpAt, vpW, vpH = -1e9, 1920, 1080
local function calibrate(cam, ccf, now)
    PJ.ok = false
    if now - vpAt > 1 then
        local okv, vp = pcall(function() return cam.ViewportSize end)
        if okv and vp then vpW, vpH, vpAt = vp.X, vp.Y, now end
    end
    local okf, fov = pcall(function() return cam.FieldOfView end)
    if not okf or not fov then return end
    local pos, r, u, l = ccf.Position, ccf.RightVector, ccf.UpVector, ccf.LookVector
    PJ.px, PJ.py, PJ.pz = pos.X, pos.Y, pos.Z
    PJ.rx, PJ.ry, PJ.rz = r.X, r.Y, r.Z
    PJ.ux, PJ.uy, PJ.uz = u.X, u.Y, u.Z
    PJ.lx, PJ.ly, PJ.lz = l.X, l.Y, l.Z
    PJ.W, PJ.H = vpW, vpH
    local th = math.tan(math.rad(fov) / 2)
    local c = pos + l * 500
    local w0, on0 = WTS(c)
    local w1, on1 = WTS(c + r * (250 * th))
    if on0 and on1 and w0 and w1 and th > 0 then
        PJ.cx, PJ.cy, PJ.k = w0.X, w0.Y, (w1.X - w0.X) / (0.5 * th)
    else
        PJ.cx, PJ.cy, PJ.k = vpW / 2, vpH / 2, (vpH / 2) / th * 0.988
    end
    PJ.ok = PJ.k > 1
end
local function projectBox(cf, corners, pts, front)
    local pos = cf.Position; local rv, uv, lv = cf.RightVector, cf.UpVector, cf.LookVector
    local px, py, pz = pos.X - PJ.px, pos.Y - PJ.py, pos.Z - PJ.pz
    local rx, ry, rz = rv.X, rv.Y, rv.Z
    local ux, uy, uz = uv.X, uv.Y, uv.Z
    local lx, ly, lz = lv.X, lv.Y, lv.Z
    local crx, cry, crz, cux, cuy, cuz, clx, cly, clz = PJ.rx, PJ.ry, PJ.rz, PJ.ux, PJ.uy, PJ.uz, PJ.lx, PJ.ly, PJ.lz
    local k, cx, cy, W, H = PJ.k, PJ.cx, PJ.cy, PJ.W, PJ.H
    local anyVis, minY, topX = false, huge, 0
    for c = 1, 8 do
        local lc = corners[c]; local ax, ay, az = lc[1], lc[2], lc[3]
        local dx = px + rx*ax + ux*ay - lx*az
        local dy = py + ry*ax + uy*ay - ly*az
        local dz = pz + rz*ax + uz*ay - lz*az
        local z = dx*clx + dy*cly + dz*clz
        local vis = false
        if z > 0.1 then
            local sx = cx + k * (dx*crx + dy*cry + dz*crz) / z
            local sy = cy - k * (dx*cux + dy*cuy + dz*cuz) / z
            if sx >= 0 and sx <= W and sy >= 0 and sy <= H then
                vis = true
                pts[c] = V2(floor(sx + 0.5), floor(sy + 0.5)); front[c] = true; anyVis = true
                if sy < minY then minY = sy; topX = sx end
            end
        end
        if not vis then front[c] = false end
    end
    return anyVis, minY, topX
end
local function poseOf(obj, readFn, now, iv, feedE)
    local c = obj._ecf
    if c and now - obj._ecfT < iv then
        local v = obj._ev
        if v then
            local ok, c2 = pcall(function() return c + v * (now - obj._ecfT) end)
            if ok and c2 then return c2 end
        end
        return c
    end
    local cf = readFn()
    if c and obj._ecfT then
        local dt = now - obj._ecfT
        local v = (dt > 0.01 and dt < 0.6) and (cf.Position - c.Position) / dt or nil
        obj._ev = (v and v.Magnitude < 150) and v or nil
    end
    obj._ecf, obj._ecfT = cf, now
    if feedE then
        local A = _G.SahurAim
        if A and A.feed then pcall(A.feed, feedE, cf.Position, now) end
    end
    return cf
end
local function drawEdges(lines, pts, front)
    for j = 1, 12 do
        local e = BoxEdges[j]; local l = lines[j]
        if front[e[1]] and front[e[2]] then l.From = pts[e[1]]; l.To = pts[e[2]]; l.Visible = true
        else l.Visible = false end
    end
end
local function drawCorners(lines, pts, front)
    for j = 1, 12 do
        local e = BoxEdges[j]; local a, b = e[1], e[2]
        local l1, l2 = lines[2 * j - 1], lines[2 * j]
        if front[a] and front[b] then
            local pa, pb = pts[a], pts[b]
            local dx, dy = (pb.X - pa.X) * CORNER, (pb.Y - pa.Y) * CORNER
            l1.From = pa; l1.To = V2(pa.X + dx, pa.Y + dy); l1.Visible = true
            l2.From = pb; l2.To = V2(pb.X - dx, pb.Y - dy); l2.Visible = true
        else l1.Visible = false; l2.Visible = false end
    end
end
local sX, sY, hX, hY = {}, {}, {}, {}
local function drawHullFill(tris, pts, front)
    local m = 0
    for c = 1, 8 do if front[c] then local p = pts[c]; m = m + 1; sX[m] = p.X; sY[m] = p.Y end end
    if m < 3 then for j = 1, NTRI do tris[j].Visible = false end return end
    for i = 2, m do
        local x, y = sX[i], sY[i]; local j = i - 1
        while j >= 1 and (sX[j] > x or (sX[j] == x and sY[j] > y)) do
            sX[j + 1] = sX[j]; sY[j + 1] = sY[j]; j = j - 1
        end
        sX[j + 1] = x; sY[j + 1] = y
    end
    local k = 0
    for i = 1, m do
        while k >= 2 and ((hX[k] - hX[k-1]) * (sY[i] - hY[k-1]) - (hY[k] - hY[k-1]) * (sX[i] - hX[k-1])) <= 0 do k = k - 1 end
        k = k + 1; hX[k] = sX[i]; hY[k] = sY[i]
    end
    local lo = k + 1
    for i = m - 1, 1, -1 do
        while k >= lo and ((hX[k] - hX[k-1]) * (sY[i] - hY[k-1]) - (hY[k] - hY[k-1]) * (sX[i] - hX[k-1])) <= 0 do k = k - 1 end
        k = k + 1; hX[k] = sX[i]; hY[k] = sY[i]
    end
    local hn = k - 1
    if hn < 3 then for j = 1, NTRI do tris[j].Visible = false end return end
    local a = V2(hX[1], hY[1])
    local nt = 0
    for i = 2, hn - 1 do
        nt = nt + 1; if nt > NTRI then break end
        local tr = tris[nt]
        tr.PointA = a; tr.PointB = V2(hX[i], hY[i]); tr.PointC = V2(hX[i + 1], hY[i + 1]); tr.Visible = true
    end
    for j = nt + 1, NTRI do tris[j].Visible = false end
end
local loopRunning = false
local conn
local lastSlots, lastMods = 0, 0
local drawn, modDrawn = 0, 0
local camPos, camLook = V3(0, 0, 0), V3(0, 0, -1)
local chamsOn = false
local function drawTank(e, now)
    local mass = e.mass
    local cf = poseOf(e, function() return mass.CFrame end, now, e._eIv or 0, e)
    local mpos = cf.Position
    local rel = mpos - camPos
    local d = rel.Magnitude * STUDS_TO_M
    e._eIv = (d < 250 and 0) or (d < 1000 and 0.1) or 0.25
    if d > Config.MaxDist then return end
    if rel:Dot(camLook) < -30 then return end
    local anyVis, minY, topX = projectBox(cf, e.massCorners, PTS, FRONT)
    if not anyVis then return end
    drawn = drawn + 1
    local s = slots[drawn]
    if Config.Box then
        local st = Config.BoxStyle
        if st == "Corners" then
            drawCorners(s.lines, PTS, FRONT)
            for j = 1, NTRI do s.tris[j].Visible = false end
        else
            drawEdges(s.lines, PTS, FRONT)
            for j = 13, 24 do s.lines[j].Visible = false end
            if st == "Filled" then drawHullFill(s.tris, PTS, FRONT) else for j = 1, NTRI do s.tris[j].Visible = false end end
        end
    else
        for j = 1, 24 do s.lines[j].Visible = false end
        for j = 1, NTRI do s.tris[j].Visible = false end
    end
    local nameStr = ""
    if Config.Names then nameStr = e.name or "" end
    if Config.Class and e.vclass then nameStr = (nameStr ~= "" and (nameStr .. " ") or "") .. "[" .. e.vclass .. "]" end
    local showCrew = Config.CrewCount and e.crew and e.crew > 0
    local rlTxt = nil
    if Config.Reload then
        local now = os.clock()
        if now - (e._rlAt or -1e9) >= RL_EVERY then
            e._rlAt = now
            local R = _G.SahurTanks
            local obj = R and R.mainLoaded and R.mainLoaded(e)
            local ok, v = pcall(function() return obj and obj.Value end)
            v = ok and v or nil
            if v == "Unloaded" or v == "" then e._rlTxt, e._rlBusy = "UNLOADED", true
            elseif v then e._rlTxt, e._rlBusy = (_G.SahurRoundType and _G.SahurRoundType(v)) or v, false
            else e._rlTxt = nil end
        end
        rlTxt = e._rlTxt
    end
    local rows = (nameStr ~= "" and 1 or 0) + (Config.Distance and 1 or 0) + (showCrew and 1 or 0) + (rlTxt and 1 or 0)
    local y = minY - 3 - rows * 14
    if nameStr ~= "" then s.name.Text = nameStr; s.name.Position = V2(topX, y); s.name.Visible = true; y = y + 14 else s.name.Visible = false end
    if Config.Distance then s.dist.Text = floor(d) .. "m"; s.dist.Position = V2(topX, y); s.dist.Visible = true; y = y + 14 else s.dist.Visible = false end
    if showCrew then s.crew.Text = e.crew .. " crew"; s.crew.Position = V2(topX, y); s.crew.Visible = true; y = y + 14 else s.crew.Visible = false end
    if rlTxt then
        s.rl.Text = rlTxt
        s.rl.Position = V2(topX, y); s.rl.Visible = true
    else s.rl.Visible = false end
    local chamsHere = chamsOn and d <= Config.ChamsDist
    if chamsHere and Config.ChamsInFov then
        local ring = _G.SahurAim and _G.SahurAim.ring
        chamsHere = false
        if ring and ring.on then
            local sp, vis = WTS(mpos)
            if vis and sp then
                local dx, dy = sp.X - ring.x, sp.Y - ring.y
                chamsHere = dx * dx + dy * dy <= ring.r * ring.r
            end
        end
    end
    if chamsHere then
        local mods = e.mods
        for mi = 1, #mods do
            if modDrawn >= MODCAP then break end
            local m = mods[mi]
            local kind = m.kind
            if Config[KIND_ON[kind] or ""] then
                local mv
                if m.fixed then mv = projectBox(cf, m.corners, PTS, FRONT)
                else
                    local part = m.part
                    mv = projectBox(poseOf(m, function() return part.CFrame end, now, e._eIv or 0), m.corners, PTS, FRONT)
                end
                if mv then
                    modDrawn = modDrawn + 1
                    local ms = modSlots[modDrawn] or newModSlot()
                    setModKind(ms, kind)
                    drawHullFill(ms.tris, PTS, FRONT)
                    if Config.ChamsBox then drawEdges(ms.lines, PTS, FRONT) else for j = 1, 12 do ms.lines[j].Visible = false end end
                end
            end
        end
    end
end
local function hideAll()
    for i = 1, lastSlots do hideSlot(slots[i]) end
    for i = 1, lastMods do hideMod(modSlots[i]) end
    lastSlots, lastMods = 0, 0
end
function ESP.start()
    if loopRunning then return ESP end
    loopRunning = true
    local function frameBody()
        local R = _G.SahurTanks
        if not Config.Enabled or not R then hideAll(); return end
        local cam = Workspace.CurrentCamera
        local okc, ccf = pcall(function() return cam.CFrame end)
        if not okc or not ccf then hideAll(); return end
        camPos, camLook = ccf.Position, ccf.LookVector
        local now = os.clock()
        calibrate(cam, ccf, now)
        if not PJ.ok then hideAll(); return end
        chamsOn = Config.Engine or Config.Ammo or Config.Crew or Config.Barrel or Config.Tracks
        local list, myAddr, teamCheck = R.list, R.myAddr, Config.TeamCheck
        drawn, modDrawn = 0, 0
        for ti = 1, #list do
            if drawn >= POOL then break end
            local e = list[ti]
            if e.addr ~= myAddr and (not teamCheck or e.enemy) then
                local before = drawn
                local ok = pcall(drawTank, e, now)
                if not ok and drawn > before then hideSlot(slots[drawn]) end
            end
        end
        for i = drawn + 1, lastSlots do hideSlot(slots[i]) end
        for i = modDrawn + 1, lastMods do hideMod(modSlots[i]) end
        lastSlots, lastMods = drawn, modDrawn
    end
    conn = RunService.RenderStepped:Connect(function() local t0 = os.clock(); frameBody(); local P = _G.SahurPerfAdd; if P then P("esp", t0) end end)
    return ESP
end
function ESP.stop()
    loopRunning = false
    if conn then pcall(function() conn:Disconnect() end); conn = nil end
    for _, s in ipairs(slots) do for j = 1, 24 do pcall(function() s.lines[j]:Remove() end) end for j = 1, NTRI do pcall(function() s.tris[j]:Remove() end) end pcall(function() s.name:Remove() end); pcall(function() s.dist:Remove() end); pcall(function() s.crew:Remove() end); pcall(function() s.rl:Remove() end) end
    for _, ms in ipairs(modSlots) do for j = 1, 12 do pcall(function() ms.lines[j]:Remove() end); pcall(function() ms.tris[j]:Remove() end) end end
    return ESP
end
function ESP.count() local R = _G.SahurTanks return R and #R.list or 0 end
return ESP
]=],
["sahur/modules/hud.lua"] = [=[
local HUD = { Config = { Enabled = true } }
_G.SahurHUD = HUD
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local D          = Drawing
local floor      = math.floor
local frameN, frameClock, FPS = 0, os.clock(), 0
local fpsConn
local FONT      = (D.Fonts and D.Fonts.Monospace) or 5
local FONTB     = (D.Fonts and D.Fonts.SystemBold) or FONT
local TEAM_COL = {
    ["Eagle Federation"] = Color3.fromRGB(74, 170, 96),
    ["Hawk Republic"]    = Color3.fromRGB(220, 60, 60),
}
local function teamTag(name)
    if not name then return "??" end
    local a, b = name:match("^(%S)%S*%s+(%S)")
    if a and b then return (a .. b):upper() end
    return name:sub(1, 2):upper()
end
local function teamCol(name) return TEAM_COL[name] or Color3.fromRGB(150, 150, 150) end
local PX, PY, H = 12, 10, 26
local obj = {}
local function mk(kind, z)
    local d = D.new(kind)
    pcall(function() d.ZIndex = z or 90 end)
    if kind == "Text" then pcall(function() d.Font = FONT end) end
    d.Visible = false
    obj[#obj + 1] = d
    return d
end
local bg      = mk("Square", 90)
local fChip   = mk("Square", 91)
local eChip   = mk("Square", 91)
local fTag    = mk("Text", 92); fTag.Size = 12; pcall(function() fTag.Font = FONTB end)
local eTag    = mk("Text", 92); eTag.Size = 12; pcall(function() eTag.Font = FONTB end)
local fCount  = mk("Text", 92); fCount.Size = 14
local eCount  = mk("Text", 92); eCount.Size = 14
local vsTxt   = mk("Text", 92); vsTxt.Size = 14
local sepTxt  = mk("Text", 92); sepTxt.Size = 14
local timeTxt = mk("Text", 92); timeTxt.Size = 14
local fpsTxt  = mk("Text", 92); fpsTxt.Size = 14
local MEAS    = D.new("Text"); MEAS.Visible = false; pcall(function() MEAS.Font = FONT end)
local function tw(txt, size)
    MEAS.Size = size or 14
    MEAS.Text = tostring(txt)
    local ok, b = pcall(function() return MEAS.TextBounds.X end)
    if ok and b and b > 0 then return b end
    return #tostring(txt) * (size or 14) * 0.6
end
local function matchStatus()
    if HUD._ms then return HUD._ms end
    local lp = Players.LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    local hud = pg and pg:FindFirstChild("MatchHud")
    local sa = hud and hud:FindFirstChild("SafeArea")
    local ms = sa and sa:FindFirstChild("MatchStatus")
    HUD._ms = ms
    return ms
end
local function sideTeamName(ms, sideName)
    local side = ms and ms:FindFirstChild(sideName)
    if not side then return nil end
    for _, o in ipairs(side:GetChildren()) do
        local nm = o.Name:match("^(.-)Flag$") or o.Name:match("^(.-)Score$")
        if nm and nm ~= "" then return nm end
    end
    return nil
end
local function timerText()
    local ms = matchStatus()
    local tw_ = ms and ms:FindFirstChild("TimerWindow")
    local tl = tw_ and tw_:FindFirstChild("Timer")
    if tl then
        local ok, t = pcall(function() return tl.Text end)
        if ok and type(t) == "string" and t ~= "" then return t end
    end
    return "--:--"
end
local teamCache, teamAt = nil, -1e9
local function teams()
    local now = os.clock()
    if teamCache and now - teamAt < 2 then return teamCache[1], teamCache[2], teamCache[3], teamCache[4] end
    local f, e, fc, ec = HUD._teamsRaw()
    teamCache, teamAt = { f, e, fc, ec }, now
    return f, e, fc, ec
end
function HUD._teamsRaw()
    local lp = Players.LocalPlayer
    local friendly = lp and lp.Team and lp.Team.Name
    local ms = matchStatus()
    local f2 = sideTeamName(ms, "FriendlySide")
    local e2 = sideTeamName(ms, "EnemySide")
    friendly = friendly or f2
    local enemy = e2
    if not enemy and friendly then
        enemy = (friendly == "Eagle Federation") and "Hawk Republic" or "Eagle Federation"
    end
    local fc, ec = 0, 0
    for _, p in ipairs(Players:GetPlayers()) do
        local tn = p.Team and p.Team.Name
        if tn == friendly then fc = fc + 1 elseif tn == enemy then ec = ec + 1 end
    end
    return friendly or "Eagle Federation", enemy or "Hawk Republic", fc, ec
end
local function hideAll()
    for _, d in ipairs(obj) do d.Visible = false end
end
local function render()
    local fName, eName, fc, ec = teams()
    local ts = timerText()
    local fTagS, eTagS = teamTag(fName), teamTag(eName)
    local chipW, chipH, pad, gap = 22, 16, 8, 7
    local ty = PY + floor((H - 14) / 2 + 0.5)
    local cy = PY + floor((H - chipH) / 2 + 0.5)
    local cx = PX + pad
    fChip.Position = Vector2.new(cx, cy); fChip.Size = Vector2.new(chipW, chipH)
    fChip.Color = teamCol(fName); fChip.Filled = true; fChip.Corner = 3; fChip.Transparency = 1; fChip.Visible = true
    fTag.Text = fTagS
    fTag.Position = Vector2.new(cx + chipW / 2 - tw(fTagS, 12) / 2, PY + floor((H - 12) / 2 + 0.5))
    fTag.Color = Color3.fromRGB(255, 255, 255); fTag.Visible = true
    cx = cx + chipW + gap
    fCount.Text = tostring(fc); fCount.Position = Vector2.new(cx, ty)
    fCount.Color = teamCol(fName); fCount.Visible = true
    cx = cx + tw(fc, 14) + gap
    vsTxt.Text = "vs"; vsTxt.Position = Vector2.new(cx, ty)
    vsTxt.Color = Color3.fromRGB(170, 170, 170); vsTxt.Visible = true
    cx = cx + tw("vs", 14) + gap
    eCount.Text = tostring(ec); eCount.Position = Vector2.new(cx, ty)
    eCount.Color = teamCol(eName); eCount.Visible = true
    cx = cx + tw(ec, 14) + gap
    eChip.Position = Vector2.new(cx, cy); eChip.Size = Vector2.new(chipW, chipH)
    eChip.Color = teamCol(eName); eChip.Filled = true; eChip.Corner = 3; eChip.Transparency = 1; eChip.Visible = true
    eTag.Text = eTagS
    eTag.Position = Vector2.new(cx + chipW / 2 - tw(eTagS, 12) / 2, PY + floor((H - 12) / 2 + 0.5))
    eTag.Color = Color3.fromRGB(255, 255, 255); eTag.Visible = true
    cx = cx + chipW + gap + 2
    sepTxt.Text = "|"; sepTxt.Position = Vector2.new(cx, ty)
    sepTxt.Color = Color3.fromRGB(90, 90, 90); sepTxt.Visible = true
    cx = cx + tw("|", 14) + gap
    timeTxt.Text = ts; timeTxt.Position = Vector2.new(cx, ty)
    timeTxt.Color = Color3.fromRGB(240, 240, 240); timeTxt.Visible = true
    cx = cx + tw(ts, 14) + gap
    local fstr = FPS .. " fps"
    fpsTxt.Text = fstr; fpsTxt.Position = Vector2.new(cx, ty)
    fpsTxt.Color = Color3.fromRGB(150, 210, 150); fpsTxt.Visible = true
    cx = cx + tw(fstr, 14) + pad
    bg.Position = Vector2.new(PX, PY); bg.Size = Vector2.new(cx - PX, H)
    bg.Color = Color3.fromRGB(18, 18, 18); bg.Filled = true; bg.Corner = 4
    bg.Transparency = 0.86; bg.Visible = true
end
local loopRunning = false
function HUD.start()
    if loopRunning then return HUD end
    loopRunning = true
    frameN, frameClock = 0, os.clock()
    fpsConn = RunService.RenderStepped:Connect(function() frameN = frameN + 1 end)
    task.spawn(function()
        while loopRunning do
            local now = os.clock()
            local el = now - frameClock
            if el >= 0.5 then FPS = floor(frameN / el + 0.5); frameN = 0; frameClock = now end
            if HUD.Config.Enabled then
                local ok, err = pcall(render)
                if not ok then HUD._err = tostring(err) end
            else
                hideAll()
            end
            task.wait(0.5)
        end
    end)
    return HUD
end
function HUD.stop()
    loopRunning = false
    if fpsConn then pcall(function() fpsConn:Disconnect() end); fpsConn = nil end
    for _, d in ipairs(obj) do pcall(function() d:Remove() end) end
    pcall(function() MEAS:Remove() end)
    return HUD
end
return HUD
]=],
["sahur/modules/aimbot.lua"] = [=[
local Aim = {
    Config = {
        Enabled = false, Key = 6, FOV = 120, Smooth = 4, ShowFOV = true, TeamCheck = true,
        Sticky = true,
        Target = "ammo", Deadzone = 2, Predict = true, ShellSpeed = 1500,
        Readout = true,
        ReloadPause = false,
        HullDamping = false,
        ReticleAim = true,
        HillLogic = false,
        ClassicAim = true,
    },
}
_G.SahurAim = Aim
Aim.ring = { x = 0, y = 0, r = 0, on = false }
local RunService = game:GetService("RunService")
local sqrt, floor, exp, abs = math.sqrt, math.floor, math.exp, math.abs
local clock = os.clock
local WTS = WorldToScreen
local Config = Aim.Config
local STUD_PER_M = 2.7777778
local G = 9.81 * STUD_PER_M
local UP = Vector3.new(0, 1, 0)
local ZERO3 = Vector3.new(0, 0, 0)
local Players = game:GetService("Players")
local SELECT_EVERY = 0.1
local KEEP_RATIO   = 0.6
local INHERIT      = 1.0
local SPEED_SCALE  = 0.985
local ACC_CAP      = 15
local VEL_LAG      = 0.2
local RELOAD_SETTLE = 0.6
local reloadUntil = 0
local HOLD_M       = 0.15
local function keyHeld(vk)
    if vk == 1 then return ismouse1pressed() and true or false end
    if vk == 2 then return ismouse2pressed() and true or false end
    return iskeypressed(vk) and true or false
end
local function caliber(name)
    local mm = name:match("(%d+%.?%d*)mm"); if mm then return tonumber(mm) end
    local cal = name:match("(%d+%.?%d*)%s*[Cc]al"); if cal then return tonumber(cal) / 100 * 25.4 end
    return 0
end
local function weaponsOf(veh)
    local f = veh and veh:FindFirstChild("Turrets")
    local t1 = f and f:FindFirstChild("Turret1")
    local w = t1 and t1:FindFirstChild("Weapons")
    if w or not veh then return w end
    for _, c in ipairs(veh:GetChildren()) do
        if c.ClassName == "Folder" then
            local t = c:FindFirstChild("Turret1")
            w = t and t:FindFirstChild("Weapons")
            if w then return w end
        end
    end
end
local function linkPart(o)
    for _ = 1, 4 do
        if not o then return nil end
        local okc, cf = pcall(function() return o.CFrame end)
        if okc and cf then return o end
        local okv, v = pcall(function() return o.Value end)
        if okv and v then o = v
        else
            local inner = o:FindFirstChild("Muzzle")
            o = inner
        end
    end
end
local function gunMuzzle(e, gun)
    local mo = gun:FindFirstChild("Muzzle")
    local mz = mo and linkPart(mo)
    if not mz then mz = linkPart(gun:FindFirstChild("CurrentMuzzle")) end
    if not mz then return nil, 1 end
    local okc, cf = pcall(function() return mz.CFrame end)
    local okm, mp = pcall(function() return e.mass.Position end)
    if not okc or not cf then return nil, 1 end
    local sign = 1
    if okm and mp then sign = (cf.LookVector:Dot(cf.Position - mp) < 0) and -1 or 1 end
    return mz, sign
end
local function resolveGuns(e)
    local w1 = weaponsOf(e.v)
    if not w1 then return nil end
    local container = w1.Parent and w1.Parent.Parent
    local list = {}
    local turrets = container and container:GetChildren() or { w1.Parent }
    for _, t in ipairs(turrets) do
        local w = t:FindFirstChild("Weapons")
        if w then
            for _, g in ipairs(w:GetChildren()) do
                local mz, s = gunMuzzle(e, g)
                if mz then
                    list[#list + 1] = { gun = g, name = g.Name, cal = caliber(g.Name), mz = mz, sign = s,
                        loaded = g:FindFirstChild("CurrentlyLoaded"), main = (t == w1.Parent),
                        rocket = (function() local ty = g:FindFirstChild("Type"); local ok, v = pcall(function() return ty and ty.Value end); return ok and v == "ROCKET" end)() }
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.cal > b.cal end)
    return (#list > 0) and list or nil, w1.Parent
end
local selObj
local function selectedName()
    if not selObj then
        local ok, o = pcall(function()
            return game:GetService("ReplicatedFirst").NewGuiData.Gunner.Weapons.Data.CurrentlySelected
        end)
        if ok and o then selObj = o else return nil end
    end
    local ok, v = pcall(function() return selObj.Value end)
    if not ok or not v then return nil end
    local okn, n = pcall(function() return v.Name end)
    return okn and n or nil
end
local shellMap = {}
local function buildShellMap()
    local lp = Players.LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    local cg = pg and pg:FindFirstChild("CrewGui")
    if not cg then return end
    for _, d in ipairs(cg:GetDescendants()) do
        if d.Name == "AmmoName" and d.ClassName == "TextLabel" then
            local okT, txt = pcall(function() return d.Text end)
            local entry = d.Parent
            local dtab = entry and entry:FindFirstChild("DataTable")
            local vl = dtab and dtab:FindFirstChild("Velocity")
            if okT and txt and txt ~= "" and vl then
                local okV, vt = pcall(function() return vl.Text end)
                local v = okV and tonumber(tostring(vt):match("(%d+%.?%d*)"))
                if v and v > 0 then shellMap[txt] = v end
            end
        end
    end
end
local CENTER = { center = true }
local BEST1 = {}
local function candidates(e)
    local t = Config.Target
    if t == "ammo" then
        local live = e.liveAmmo
        local best, bv
        if live then
            for i = 1, #live do
                local r = live[i]
                if not bv or (r.vol or 0) > bv then best, bv = r, r.vol or 0 end
            end
        end
        if best then BEST1[1] = best; return BEST1 end
        return { CENTER }
    elseif t == "ammonear" then
        local live, out = e.liveAmmo, {}
        if live then for i = 1, #live do out[#out + 1] = live[i] end end
        if #out == 0 then out[1] = CENTER end
        return out
    elseif t == "engine" then return { e.engine or CENTER }
    elseif t == "crew" then return { e.gunner or CENTER }
    end
    return { CENTER }
end
local function candPos(e, rec, massCF)
    if rec.center then return massCF.Position end
    if rec.fixed then
        local lc = rec.lc
        return massCF.Position + massCF.RightVector * lc[1] + massCF.UpVector * lc[2] - massCF.LookVector * lc[3]
    end
    if rec.kind == "crew" then
        local pcf = rec.part.CFrame
        return pcf.Position + pcf.UpVector * 1.75
    end
    return rec.part.Position
end
local fovCircle = Drawing.new("Circle")
fovCircle.Filled = false; fovCircle.Thickness = 1.5; fovCircle.NumSides = 48
fovCircle.Color = Color3.fromRGB(240, 24, 43); fovCircle.Transparency = 1; fovCircle.Visible = false
local readout = Drawing.new("Text")
readout.Size = 13; readout.Center = true; readout.Outline = true; readout.Visible = false
readout.Color = Color3.fromRGB(255, 255, 255)
pcall(function() readout.Font = (Drawing.Fonts and Drawing.Fonts.System) or 1 end)
function Aim.SetFovColor(c) pcall(function() fovCircle.Color = c end) end
Aim.SetAccent = Aim.SetFovColor
local loopRunning = false
local conn
local muzAddr, muzzle, sign = nil, nil, 1
local lock = nil
local lastSel = 0
local mouseAccX, mouseAccY = 0, 0
local mpos, bdir, shellStuds = nil, nil, 0
local loadedObj, curShellName, curShellMs, lastMapScan = nil, nil, nil, -1e9
local gunName, curShellSrc = nil, nil
local myVel, tauCtrl, lastT = nil, 0, 0
local myVelSm = nil
local reticleActive = false
local lastBookT, IDLE_BOOK = -1e9, 0.05
local TRIM_RATE   = 2.5
local TRIM_MAX    = 0.015
local TRIM_GATE   = 0.012
local TRIM_STOP   = 1.5
local TRIM_GATE_M = 2.0
local TRIM_MAX_M  = 1.5
local TRIM_BLEED  = 0.5
local TRIM_PX     = 12
local TRIM_SETTLE = 0.6
local trimX, trimY, trimLock, trimFrom, lastUnloadedAt = 0, 0, nil, 0, -1e9
local myUp, elevClamped = nil, false
local ERR_FILTER  = 0.04
local RATE_FILTER = 0.08
local TURRET_LAG  = 0.08
local RATE_CAP    = 1.1
local ctlLock, fx, fy, vx, vy = nil, 0, 0, 0, 0
local BOUNCE_REF  = 6
local BOUNCE_HOLD = 0.4
local hullRateV, hullRateH = 0, 0
local lastHullUp, lastHullFlat = nil, nil
local HULL_BASE = 0.15
local hullHist = {}
local stickySpent = false
local trav = { h = 40, v = 40, sh = 1, sv = 1, src = "default" }
local degPerCount = 0.103
local sentX, sentY = 0, 0
local guns, activeGun = nil, nil
local aimEpoch = 0
local KEY_GRACE = 0.25
local keyDownAt, lastKeyDown, keyFlips = -1e9, false, 0
local lastCamYaw, lastCamPitch = nil, nil
local travCache = {}
local function readTraverse(turretFolder, key)
    if key and travCache[key] then return travCache[key] end
    local m = turretFolder and turretFolder:FindFirstChild("TurretInfo")
    if not m then return nil end
    local ok, src = pcall(decompile, m)
    if not ok or type(src) ~= "string" then return nil end
    local al = src:match('%["anglelimits"%]%s*=%s*(%b{})')
    local function third(blk)
        if not blk then return nil end
        local a, b, c = blk:match('^{%s*([^,]*),%s*([^,]*),%s*([^,}]*)')
        return tonumber(c)
    end
    local h = third(al and al:match('%["horizontal"%]%s*=%s*(%b{})'))
    local vblk = al and al:match('%["vertical"%]%s*=%s*(%b{})')
    local v = third(vblk)
    local vmin, vmax
    if vblk then
        local a, b = vblk:match('^{%s*([^,]*),%s*([^,]*),')
        vmin, vmax = tonumber(a), tonumber(b)
    end
    local sh, sv = src:match('%["StabRatio"%]%s*=%s*{%s*([%d%.]+)%s*,%s*([%d%.]+)')
    local t = { h = (h and h > 0) and h or 40, v = (v and v > 0) and v or 40, vmin = vmin, vmax = vmax,
        sh = tonumber(sh) or 0, sv = tonumber(sv) or 0, src = (h or v) and "TurretInfo" or "default" }
    if key then travCache[key] = t end
    return t
end
local ELEV_MARGIN = 0.3
local function clampElevation(p)
    if not Config.HillLogic then return p, false end
    if not (myUp and trav.vmin and trav.vmax) then return p, false end
    local d = p - mpos
    local D = d.Magnitude
    if D < 1 then return p, false end
    local u = d / D
    local sUp = u:Dot(myUp)
    local e = math.deg(math.asin(math.max(-1, math.min(1, sUp))))
    local lo, hi = trav.vmin + ELEV_MARGIN, trav.vmax - ELEV_MARGIN
    if e >= lo and e <= hi then return p, false end
    if bdir then
        local be = math.deg(math.asin(math.max(-1, math.min(1, bdir:Dot(myUp)))))
        if e < lo and be > trav.vmin + 1.0 then return p, false end
        if e > hi and be < trav.vmax - 1.0 then return p, false end
    end
    local h = u - myUp * sUp
    if h.Magnitude < 1e-3 then return p, false end
    h = h.Unit
    local ec = math.rad(e < lo and lo or hi)
    return mpos + (h * math.cos(ec) + myUp * math.sin(ec)) * D, true
end
local RET_HALF = 13
local retFrame, retEpoch = nil, -1
local retVpAt, retVpW, retVpH = -1e9, nil, nil
local guiScale = nil
local retParams, retParamsFor = nil, nil
local SIGHT_FOV, SIGHT_DIST = 35, 12
local sightFrame, sightVal = -1, false
local function inSight()
    local tNow = clock()
    if tNow - sightFrame < 0.05 then return sightVal end
    sightFrame = tNow
    local ok, s = pcall(function()
        local cam = workspace.CurrentCamera
        if cam.FieldOfView < SIGHT_FOV then return true end
        local R = _G.SahurTanks
        local my = R and R.myTank
        if my then return (cam.CFrame.Position - my.mass.CFrame.Position).Magnitude < SIGHT_DIST end
        return false
    end)
    sightVal = ok and s or false
    return sightVal
end
Aim.inSight = inSight
local function reticlePoint()
    if inSight() then return nil end
    local R = _G.SahurTanks
    local ep = R and R.epoch or 0
    if not retFrame or retEpoch ~= ep then
        retEpoch = ep
        local ok, f = pcall(function()
            return Players.LocalPlayer.PlayerGui.SoloReticle:FindFirstChild("Frame")
        end)
        retFrame = ok and f or nil
    end
    if not retFrame then return nil end
    local ok, p = pcall(function() return retFrame.AbsolutePosition end)
    if not ok or not p or (p.X <= 1 and p.Y <= 1) then return nil end
    local now = clock()
    if now - retVpAt > 1 then
        retVpAt = now
        local okv, vp = pcall(function() return workspace.CurrentCamera.ViewportSize end)
        if okv and vp then
            if retVpW and vp.X ~= retVpW then guiScale = nil end
            retVpW, retVpH = vp.X, vp.Y
        end
    end
    if not guiScale and retVpW then
        local raw = (retVpW / 2) / (p.X + RET_HALF)
        local snap = floor(raw * 4 + 0.5) / 4
        if snap >= 1 and snap <= 3 and abs(raw - snap) < 0.02 then guiScale = snap; Aim.guiScale = snap end
    end
    local sc = guiScale or 1
    return (p.X + RET_HALF) * sc, (p.Y + RET_HALF) * sc
end
local addonCache, addonCacheN = {}, 0
local function inAddons(inst)
    if not inst then return false end
    local oka, addr = pcall(function() return inst.Address end)
    local key = oka and addr or nil
    if key ~= nil and addonCache[key] ~= nil then return addonCache[key] end
    local res, o = false, inst
    for _ = 1, 7 do
        local okp, par = pcall(function() return o.Parent end)
        if not okp or not par then break end
        local okn, nm = pcall(function() return par.Name end)
        if okn and nm == "Addons" then res = true; break end
        if okn and nm == "SpawnedVehicles" then break end
        o = par
    end
    if key ~= nil then
        if addonCacheN > 4000 then addonCache, addonCacheN = {}, 0 end
        addonCache[key] = res; addonCacheN = addonCacheN + 1
    end
    return res
end
local function reticleErr(pos)
    local rx, ry = reticlePoint()
    if not rx then return nil end
    local okc, ccf = pcall(function() return workspace.CurrentCamera.CFrame end)
    if not okc or not ccf then return nil end
    local d = pos - mpos
    local D = d.Magnitude
    if D < 1 then return nil end
    local u = d / D
    local Q = mpos + u * 15000
    local R = _G.SahurTanks
    local myV = R and R.myTank and R.myTank.v
    if not myV then
        retParams, retParamsFor = nil, nil
    elseif retParamsFor ~= R.myAddr then
        retParamsFor = R.myAddr
        local okp, rp = pcall(function() return RaycastParams.new() end)
        retParams = okp and rp or nil
        if retParams then
            local okf = pcall(function() retParams.FilterDescendantsInstances = { myV } end)
            if not okf then retParams = nil end
        end
    end
    local origin, remain = mpos + u * 4, 15000
    for _ = 1, 4 do
        local okh, hit = pcall(function() return workspace:Raycast(origin, u * remain, retParams) end)
        if not (okh and hit and hit.Position) then break end
        if not inAddons(hit.Instance) then Q = hit.Position; break end
        local step = (hit.Position - origin).Magnitude + 0.2
        origin, remain = origin + u * step, remain - step
        if remain <= 0 then break end
    end
    local tp, on = WTS(Q)
    if not on or not tp then return nil end
    local ex, ey = tp.X - rx, tp.Y - ry
    return ex, ey, sqrt(ex * ex + ey * ey), D
end
local function pxPerRad()
    local ok, cf = pcall(function() return workspace.CurrentCamera.CFrame end)
    if not ok or not cf then return nil end
    local p = cf.Position + cf.LookVector * 1000
    local a, oa = WTS(p)
    local b, ob = WTS(p + cf.RightVector * 10)
    if not (oa and ob) then return nil end
    local k = abs(b.X - a.X) / 0.01
    return k > 1 and k or nil
end
local function boreErr(pos)
    local D = (pos - mpos).Magnitude
    local bs, onb = WTS(mpos + bdir * D)
    local ts, ont = WTS(pos)
    if not (onb and ont) then return nil end
    local ex, ey = ts.X - bs.X, ts.Y - bs.Y
    return ex, ey, sqrt(ex * ex + ey * ey), D
end
local VEL_WIN = 0.5
local ATAN2 = math.atan2 or function(y, x) return math.atan(y, x) end
local ACC_CAP_C, VEL_LAG_C = 15, 0.06
local ACC_WIN = 0.8
local function fitAccel(h, now)
    local n = #h
    if n < 6 or h[n].t - h[1].t < 0.4 then return nil end
    local ref = h[n].p
    local S1, S2, S3, S4 = 0, 0, 0, 0
    local B0, B1, B2 = ZERO3, ZERO3, ZERO3
    for i = 1, n do
        local tau = h[i].t - now
        local tau2 = tau * tau
        local p = h[i].p - ref
        S1, S2, S3, S4 = S1 + tau, S2 + tau2, S3 + tau2 * tau, S4 + tau2 * tau2
        B0, B1, B2 = B0 + p, B1 + p * tau, B2 + p * tau2
    end
    local S0 = n
    local det = S0 * (S2 * S4 - S3 * S3) - S1 * (S1 * S4 - S2 * S3) + S2 * (S1 * S3 - S2 * S2)
    if abs(det) < 1e-12 then return nil end
    local c2 = (B0 * (S1 * S3 - S2 * S2) - B1 * (S0 * S3 - S1 * S2) + B2 * (S0 * S2 - S1 * S1)) / det
    return c2 * 2
end
local TRACK_STALE = 0.5
local LOCK_GONE = 1.0
local TRACK_KEYS = { "_sv", "_sa", "_svT", "_tp", "_tt", "_fitP", "_fitV", "_fitT", "_fitAt", "_qh", "_hist", "_vel", "_velAt" }
local function dropStale(e, now)
    if e._tt and now - e._tt > TRACK_STALE then
        e._sv, e._sa, e._svT, e._tp, e._tt = nil, nil, nil, nil, nil
        e._fitP, e._fitAt = nil, nil
        e._qh, e._hist = nil, nil
    end
end
local function trackVelClassic(e, pos, now)
    dropStale(e, now)
    local h = e._qh
    if not h then h = {}; e._qh = h end
    local last = h[#h]
    if not last or (pos - last.p).Magnitude > 0.01 or now - last.t >= 0.1 then
        h[#h + 1] = { t = now, p = pos }
        while #h > 2 and now - h[1].t > ACC_WIN do table.remove(h, 1) end
    end
    if e._tp and e._tt then
        local dt = now - e._tt
        if dt >= 0.03 then
            local inst = (pos - e._tp) / dt
            if inst.Magnitude < 400 then
                local old = e._sv
                e._sv = old and old:Lerp(inst, 0.35) or inst
            end
            local a = fitAccel(h, now)
            if a then
                e._sa = e._sa and e._sa:Lerp(a, 0.3) or a
                local am = e._sa.Magnitude
                if am > ACC_CAP_C then e._sa = e._sa * (ACC_CAP_C / am) end
            end
            e._tp, e._tt = pos, now
        end
    else
        e._tp, e._tt = pos, now
    end
end
local function trackVel(e, pos, now)
    if Config.ClassicAim then return trackVelClassic(e, pos, now) end
    dropStale(e, now)
    local h = e._hist
    if not h then h = {}; e._hist = h end
    local n = #h
    local last = h[n]
    if not last or (pos - last[2]).Magnitude > 0.01 or now - last[1] >= 0.1 then
        if last and (pos - last[2]).Magnitude / math.max(now - last[1], 1e-3) > 400 then
            for k = n, 1, -1 do h[k] = nil end
            n = 0
        end
        n = n + 1; h[n] = { now, pos }
        while n > 2 and now - h[1][1] > VEL_WIN do table.remove(h, 1); n = n - 1 end
        if n >= 2 then
            local span = h[n][1] - h[1][1]
            if span >= 0.12 then
                local tm = 0
                for k = 1, n do tm = tm + h[k][1] end
                tm = tm / n
                local pm = ZERO3
                for k = 1, n do pm = pm + h[k][2] end
                pm = pm / n
                local num, den = ZERO3, 0
                for k = 1, n do
                    local dtk = h[k][1] - tm
                    num = num + (h[k][2] - pm) * dtk
                    den = den + dtk * dtk
                end
                local v = (den > 1e-6) and (num / den) or ((h[n][2] - h[1][2]) / span)
                e._fitT, e._fitP, e._fitV, e._fitAt = tm, pm, v, now
                local old = e._sv
                e._sv = old and old:Lerp(v, 0.5) or v
                if old and e._svT then
                    local dtA = now - e._svT
                    if dtA > 0 then
                        local a = (e._sv - old) / dtA
                        e._sa = e._sa and e._sa:Lerp(a, 0.05) or a * 0.05
                        local am = e._sa.Magnitude
                        if am > ACC_CAP then e._sa = e._sa * (ACC_CAP / am) end
                    end
                end
                e._svT = now
            end
        end
    end
    e._tt = now
end
local function velOf(e)
    if not e then return nil end
    if e._sv and e._tt and clock() - e._tt < 0.5 then return e._sv end
    local now = clock()
    if e._velAt and now - e._velAt < 0.05 then return e._vel end
    local ok, v = pcall(function() return e.mass.AssemblyLinearVelocity end)
    e._vel = (ok and v) or nil; e._velAt = now
    return e._vel
end
local BALL = {}
local GUIDED = {}
local curGuided = false
pcall(function()
    local src = (_G.SahurSrc and _G.SahurSrc["sahur/data/ballistics.lua"]) or readfile("sahur/data/ballistics.lua")
    local f = src and loadstring(src)
    if f then f() end
    local t = _G.SahurBallistics
    if type(t) == "table" then BALL = t end
    if type(_G.SahurGuided) == "table" then GUIDED = _G.SahurGuided end
end)
Aim.ball = BALL
local curG = G
local VT_DEAD, VM_DEAD, AT_DEAD = 1.0, 0.6, 1.5
local function soft(v, d)
    local m = v.Magnitude
    if m <= d then return ZERO3 end
    if m >= 2 * d then return v end
    return v * ((m - d) / d)
end
local function predicted(e, pos)
    if curGuided then lastT = 0; return pos end
    if shellStuds <= 1 then return pos end
    local rel = pos - mpos
    local t = rel.Magnitude / shellStuds
    local vt, vm = ZERO3, ZERO3
    local lin, half = ZERO3, ZERO3
    if Config.Predict then
        vt = soft(velOf(e) or ZERO3, VT_DEAD)
        vm = soft(myVel or ZERO3, VM_DEAD)
        local at = soft(e._sa or ZERO3, AT_DEAD)
        if not Config.HillLogic then
            vt = Vector3.new(vt.X, 0, vt.Z); vm = Vector3.new(vm.X, 0, vm.Z); at = Vector3.new(at.X, 0, at.Z)
        end
        vt = vt + at * (Config.ClassicAim and VEL_LAG_C or VEL_LAG)
        lin = vt - vm * INHERIT
        half = at * 0.5
    end
    if not Config.Predict then lastT = t; return pos end
    half = half + UP * (0.5 * curG)
    for _ = 1, 5 do
        t = (rel + lin * t + half * (t * t)).Magnitude / shellStuds
    end
    local aim = pos + lin * t + half * (t * t)
    if Config.Predict and not reticleActive then aim = aim + (vt - vm) * tauCtrl end
    lastT = t
    return aim
end
local function eligible(e, myAddr)
    return e.addr ~= myAddr and not e.dead and (not Config.TeamCheck or e.enemy)
end
local selRx, selRy = nil, nil
local function selErr(pt)
    if selRx then
        local s, on = WTS(pt)
        if not on or not s then return nil end
        local ex, ey = s.X - selRx, s.Y - selRy
        return ex, ey, sqrt(ex * ex + ey * ey)
    end
    return boreErr(pt)
end
local lastWarm = -1e9
local WARM_FED, WARM_MAX = 0.3, 6
local warmRR = 0
function Aim.feed(e, pos, now) e._fedAt = now; trackVel(e, pos, now) end
local function warmTrack(R, now)
    if now - lastWarm < SELECT_EVERY then return end
    lastWarm = now
    local myAddr = R.myAddr
    local list, n, reads = R.list, #R.list, 0
    for _ = 1, n do
        if reads >= WARM_MAX then break end
        warmRR = warmRR % n + 1
        local e = list[warmRR]
        if e and eligible(e, myAddr) and now - (e._fedAt or -1e9) > WARM_FED then
            reads = reads + 1
            local okc, massCF = pcall(function() return e.mass.CFrame end)
            if okc and massCF then trackVel(e, massCF.Position, now) end
        end
    end
end
local function selectTarget(R)
    local myAddr = R.myAddr
    selRx, selRy = nil, nil
    if Config.ReticleAim then selRx, selRy = reticlePoint() end
    local stickyE = Config.Sticky and lock and lock.e or nil
    local best, bestErr = nil, stickyE and math.huge or Config.FOV
    local lockErr = nil
    for _, e in ipairs(R.list) do
        if eligible(e, myAddr) and (not stickyE or e == stickyE) then
            local okc, massCF = pcall(function() return e.mass.CFrame end)
            if okc and massCF then
                trackVel(e, massCF.Position, clock())
                for _, rec in ipairs(candidates(e)) do
                    local okp, pos = pcall(candPos, e, rec, massCF)
                    if okp and pos then
                        local _, _, err = selErr(pos)
                        if err then
                            if lock and lock.addr == e.addr and lock.rec == rec then lockErr = err end
                            if err < bestErr then bestErr = err; best = { e = e, rec = rec, addr = e.addr } end
                        end
                    end
                end
            end
        end
    end
    if stickyE then
        if not best or best.rec == lock.rec then return end
        if lockErr and bestErr > lockErr * KEEP_RATIO then return end
        lock.rec = best.rec
        return
    end
    if lock and lockErr and lockErr < Config.FOV * 1.3 then
        if not best or best.addr == lock.addr and best.rec == lock.rec or bestErr > lockErr * KEEP_RATIO then return end
    end
    lock = best
end
local function isGuided(gun, nm)
    local gt = gun and GUIDED[gun]
    if not gt then return false end
    if gt[nm] then return true end
    for g in pairs(gt) do if nm:sub(1, #g) == g then return true end end
    return false
end
local function refreshShell()
    if not loadedObj then return end
    local ok, nm = pcall(function() return loadedObj.Value end)
    if ok and type(nm) == "string" and nm ~= "" and nm ~= "Unloaded" then
        curShellName = nm
        curGuided = isGuided(gunName, nm)
        if not curGuided and activeGun and activeGun.rocket and not (BALL[gunName] and BALL[gunName][nm]) then curGuided = true end
        local w = gunName and BALL[gunName]
        local rd = w and w[nm]
        if tonumber(rd) then
            curShellMs, curShellSrc = tonumber(rd), "wiki"
        else
            if not shellMap[nm] and clock() - lastMapScan > 3 then
                lastMapScan = clock(); pcall(buildShellMap)
            end
            curShellMs = shellMap[nm]
            curShellSrc = curShellMs and "panel" or "fallback"
        end
    end
end
local function selectGun(g)
    if not g then return end
    activeGun = g
    muzzle, sign, loadedObj, gunName = g.mz, g.sign, g.loaded, g.name
    curShellMs, curShellName, curGuided = nil, nil, false
    reloadUntil = 0
    refreshShell()
end
local lastSelPoll = 0
local function pollGuns()
    if not guns or #guns < 2 then return end
    local now = clock()
    if now - lastSelPoll < 0.1 then return end
    lastSelPoll = now
    local nm = selectedName()
    if not nm or (activeGun and activeGun.name == nm) then return end
    for i = 1, #guns do
        if guns[i].name == nm then selectGun(guns[i]); return end
    end
end
function Aim.start()
    if loopRunning then return Aim end
    loopRunning = true
    task.spawn(function()
        while loopRunning do
            local R = _G.SahurTanks
            if R then
                if R.myAddr ~= muzAddr or (R.myAddr and not muzzle) then
                    muzzle, sign, loadedObj, guns, activeGun = nil, 1, nil, nil, nil
                    local heli = false
                    if R.myTank then
                        local okh, hv = pcall(function() return R.myTank.v:FindFirstChild("MainRotor") ~= nil or R.myTank.v:FindFirstChild("RotorFolder") ~= nil end)
                        heli = okh and hv
                    end
                    if R.myTank and not heli then
                        local ok, list, turretFolder = pcall(resolveGuns, R.myTank)
                        if ok and list then
                            guns = list; muzAddr = R.myAddr
                            selectGun(list[1])
                            local okt, t = pcall(readTraverse, turretFolder, R.myTank.name)
                            trav = (okt and t) or { h = 40, v = 40, sh = 0, sv = 0, src = "default" }
                        end
                    elseif not R.myAddr then muzAddr = nil end
                end
                refreshShell()
            end
            task.wait(0.3)
        end
    end)
    local function frameBody(dt)
        dt = dt or (1 / 240)
        Aim._frames = (Aim._frames or 0) + 1
        local R = _G.SahurTanks
        if R and (R.epoch or 0) ~= aimEpoch then
            aimEpoch = R.epoch or 0
            muzzle, loadedObj, guns, activeGun, muzAddr, lock, ctlLock = nil, nil, nil, nil, nil, nil, nil
            lastHullUp, lastHullFlat, hullRateV, hullRateH = nil, nil, 0, 0
            for k = #hullHist, 1, -1 do hullHist[k] = nil end
        end
        if not R or not R.myAddr or not muzzle then Aim._why = (R and R.myAddr) and "nomuzzle" or "notank"; fovCircle.Visible = false; readout.Visible = false; lock = nil; Aim.ring.on = false; return end
        local nowF = clock()
        local hot = Config.Enabled and (keyHeld(Config.Key) or nowF - keyDownAt <= KEY_GRACE + 0.3)
        local now0 = nowF
        if hot or nowF - lastBookT >= IDLE_BOOK then
        local dtB = hot and dt or math.min(nowF - lastBookT, 0.1)
        lastBookT = nowF
        pcall(pollGuns)
        local okc, cf = pcall(function() return muzzle.CFrame end)
        if not okc or not cf then fovCircle.Visible = false; Aim.ring.on = false; return end
        mpos = cf.Position
        bdir = cf.LookVector * sign
        shellStuds = ((curShellMs and curShellMs > 0) and curShellMs or Config.ShellSpeed) * STUD_PER_M * SPEED_SCALE
        tauCtrl = 1 / 12
        if R.myTank then
            local okp, mcf = pcall(function() return R.myTank.mass.CFrame end)
            if okp and mcf then
                trackVel(R.myTank, mcf.Position, clock()); myUp = mcf.UpVector
                local lk = mcf.LookVector
                local fl = Vector3.new(lk.X, 0, lk.Z)
                if fl.Magnitude > 0.01 then fl = fl.Unit end
                local decay = exp(-dtB / BOUNCE_HOLD)
                local nowH = clock()
                local hb = hullHist
                hb[#hb + 1] = { nowH, myUp, fl }
                while #hb > 2 and nowH - hb[2][1] >= HULL_BASE do table.remove(hb, 1) end
                local old = hb[1]
                local span = nowH - old[1]
                if span >= HULL_BASE * 0.6 then
                    local aV = math.deg(ATAN2(myUp:Cross(old[2]).Magnitude, myUp:Dot(old[2]))) / span
                    local aH = math.deg(ATAN2(fl:Cross(old[3]).Magnitude, fl:Dot(old[3]))) / span
                    hullRateV = math.max(aV, hullRateV * decay)
                    hullRateH = math.max(aH, hullRateH * decay)
                end
                lastHullUp, lastHullFlat = myUp, fl
            else myUp = nil end
        end
        do
            local okv, av = false, nil
            if R.myTank then okv, av = pcall(function() return R.myTank.mass.AssemblyLinearVelocity end) end
            local wv = velOf(R.myTank)
            if okv and av and av.Magnitude < 1 and wv and wv.Magnitude > 3 then okv = false end
            if Config.ClassicAim then okv = false end
            if okv and av and av.Magnitude < 400 then
                local a = 1 - exp(-dtB / 0.06)
                myVelSm = myVelSm and myVelSm:Lerp(av, a) or av
                myVel = myVelSm
            else
                myVel = wv
            end
        end
        local okk, look = false, nil
        if hot then okk, look = pcall(function() return workspace.CurrentCamera.CFrame.LookVector end) else lastCamYaw = nil end
        if okk and look then
            local yaw = math.deg(math.atan2(look.X, look.Z))
            local pitch = math.deg(math.asin(math.max(-1, math.min(1, look.Y))))
            if lastCamYaw then
                local dyaw = (yaw - lastCamYaw + 180) % 360 - 180
                local dp = pitch - lastCamPitch
                local s
                if abs(sentX) >= 2 and abs(sentX) >= abs(sentY) then s = abs(dyaw) / abs(sentX)
                elseif abs(sentY) >= 2 then s = abs(dp) / abs(sentY) end
                if Config.ClassicAim then
                    if s and s > 0.01 and s < 1 then degPerCount = degPerCount + (s - degPerCount) * 0.1 end
                elseif s and s > 0.05 and s < 0.25 then
                    degPerCount = degPerCount + (s - degPerCount) * 0.02
                    if degPerCount < 0.07 then degPerCount = 0.07 elseif degPerCount > 0.15 then degPerCount = 0.15 end
                end
            end
            lastCamYaw, lastCamPitch = yaw, pitch
        end
        sentX, sentY = 0, 0
        if loadedObj then
            local okl, lv = pcall(function() return loadedObj.Value end)
            if okl and (lv == "Unloaded" or lv == "" or lv == nil) then
                lastUnloadedAt = now0
                if Config.ReloadPause then reloadUntil = now0 + RELOAD_SETTLE end
            end
        end
        end
        local reloading = now0 < reloadUntil
        local ringDist = 400
        local down = Config.Enabled and keyHeld(Config.Key) and isrbxactive()
        if down ~= lastKeyDown then keyFlips = keyFlips + 1; lastKeyDown = down end
        if down then keyDownAt = now0 end
        local aiming = Config.Enabled and (now0 - keyDownAt) <= KEY_GRACE and not reloading
        if aiming then
            if lock then
                local cur = R.byAddr[lock.addr]
                if cur and cur ~= lock.e then
                    for _, k in ipairs(TRACK_KEYS) do if cur[k] == nil then cur[k] = lock.e[k] end end
                    lock.e = cur
                    local okc, cs = pcall(candidates, cur)
                    if okc and cs and cs[1] then lock.rec = cs[1] end
                    lock.goneAt = nil
                elseif not cur then
                    lock.goneAt = lock.goneAt or now0
                else
                    lock.goneAt = nil
                end
                if lock.e.dead or (lock.goneAt and now0 - lock.goneAt > LOCK_GONE) then
                    lock = nil
                    if Config.Sticky then stickySpent = true end
                end
            end
            local now = clock()
            if not stickySpent and (not lock or now - lastSel >= SELECT_EVERY) then lastSel = now; pcall(selectTarget, R) end
            Aim._why = lock and ("lock:" .. tostring(lock.e.name) .. (lock.goneAt and "(gone)" or "")) or (stickySpent and "spent" or "nolock")
            if inSight() then Aim._why = Aim._why .. "/sight" end
            if Aim._why ~= Aim._whyLogged then Aim._whyLogged = Aim._why; if R.bb then pcall(R.bb, "aim " .. Aim._why) end end
            if lock and not lock.goneAt then
                local okm, massCF = pcall(function() return lock.e.mass.CFrame end)
                if okm and massCF then trackVel(lock.e, massCF.Position, clock()) end
                local okp, pos = false, nil
                if okm and massCF then okp, pos = pcall(candPos, lock.e, lock.rec, massCF) end
                local le = lock.e
                if not Config.ClassicAim and okp and pos and le._fitP and le._fitAt and clock() - le._fitAt < 0.5 then
                    local shift = (le._fitP + le._fitV * (clock() - le._fitT)) - massCF.Position
                    if shift.Magnitude < 12 then pos = pos + shift end
                end
                if okp and pos then
                    reticleActive = Config.ReticleAim and reticlePoint() ~= nil
                    local aimPt = predicted(lock.e, pos)
                    aimPt, elevClamped = clampElevation(aimPt)
                    Aim._shot = Aim._shot or {}
                    Aim._shot.aim, Aim._shot.pos, Aim._shot.e, Aim._shot.t, Aim._shot.mpos, Aim._shot.T = aimPt, pos, lock.e, clock(), mpos, lastT
                    Aim._shot.vm = myVel
                    Aim._shot.bdir = bdir
                    local ex, ey, err, D
                    local usingRet = false
                    if Config.ReticleAim then
                        ex, ey, err, D = reticleErr(aimPt)
                        usingRet = ex ~= nil
                    end
                    if usingRet then
                        local pxr = pxPerRad()
                        if lock.addr ~= trimLock then trimLock = lock.addr; trimX, trimY = 0, 0; trimFrom = now + TRIM_SETTLE end
                        local bx, by = boreErr(aimPt)
                        if pxr and bx then
                            local bxr, byr = bx / pxr, by / pxr
                            local atStop = false
                            if myUp and trav.vmin and trav.vmax and bdir then
                                local be = math.deg(math.asin(math.max(-1, math.min(1, bdir:Dot(myUp)))))
                                atStop = be < trav.vmin + TRIM_STOP or be > trav.vmax - TRIM_STOP
                            end
                            local Dm = math.max((D or 0) / STUD_PER_M, 1)
                            local gate = math.max(TRIM_GATE * Dm, TRIM_GATE_M)
                            local lim = math.max(TRIM_MAX * Dm, TRIM_MAX_M)
                            local mx, my = bxr * Dm, byr * Dm
                            local small = mx * mx + my * my < gate * gate
                            if now >= trimFrom and now - lastUnloadedAt > TRIM_SETTLE
                                and abs(ex) < TRIM_PX and abs(ey) < TRIM_PX
                                and hullRateH < BOUNCE_REF and hullRateV < BOUNCE_REF
                                and small and not atStop then
                                trimX = math.clamp(trimX + mx * TRIM_RATE * dt, -lim, lim)
                                trimY = math.clamp(trimY + my * TRIM_RATE * dt, -lim, lim)
                            elseif atStop or not small then
                                local k = exp(-dt / TRIM_BLEED)
                                trimX, trimY = trimX * k, trimY * k
                            end
                            ex, ey = ex + trimX / Dm * pxr, ey + trimY / Dm * pxr
                            err = sqrt(ex * ex + ey * ey)
                        end
                    end
                    if not ex then ex, ey, err, D = boreErr(aimPt) end
                    if ex then
                        ringDist = D
                        local dz = Config.Deadzone
                        local okr, cr = pcall(function() return workspace.CurrentCamera.CFrame.RightVector end)
                        if okr and cr then
                            local a0, on0 = WTS(aimPt)
                            local a1, on1 = WTS(aimPt + cr * (HOLD_M * STUD_PER_M))
                            if on0 and on1 then
                                local hx, hy = a1.X - a0.X, a1.Y - a0.Y
                                local holdPx = sqrt(hx * hx + hy * hy)
                                if holdPx < dz then dz = holdPx end
                            end
                        end
                        local calmV = 1 / (1 + hullRateV / BOUNCE_REF)
                        local calmH = 1 / (1 + hullRateH / BOUNCE_REF)
                        calmV = calmV ^ (1 + 2 * (trav.sv or 0))
                        calmH = calmH ^ (1 + 2 * (trav.sh or 0))
                        if not Config.HullDamping or Config.ClassicAim or not Config.HillLogic then calmV, calmH = 1, 1 end
                        if lock.addr ~= ctlLock then ctlLock = lock.addr; fx, fy, vx, vy = ex, ey, 0, 0 end
                        local aFx = 1 - exp(-dt * calmH / ERR_FILTER)
                        local aFy = 1 - exp(-dt * calmV / ERR_FILTER)
                        local nfx, nfy = fx + (ex - fx) * aFx, fy + (ey - fy) * aFy
                        local aV = 1 - exp(-dt / RATE_FILTER)
                        vx = vx + ((nfx - fx) / dt - vx) * aV
                        vy = vy + ((nfy - fy) / dt - vy) * aV
                        fx, fy = nfx, nfy
                        local leadT = usingRet and 0 or TURRET_LAG
                        local cx, cy = fx + vx * leadT * calmH, fy + vy * leadT * calmV
                        if err > dz then
                            local alpha = 1 - exp(-(Config.Smooth * 1.2) * dt)
                            if alpha < 0.03 then alpha = 0.03 elseif alpha > 1 then alpha = 1 end
                            local sx, sy = cx * alpha * calmH, cy * alpha * calmV
                            local capX = trav.h * dt / degPerCount * RATE_CAP
                            local capY = trav.v * dt / degPerCount * RATE_CAP
                            if sx > capX then sx = capX elseif sx < -capX then sx = -capX end
                            if sy > capY then sy = capY elseif sy < -capY then sy = -capY end
                            mouseAccX = mouseAccX + sx
                            mouseAccY = mouseAccY + sy
                            local mx, my = floor(mouseAccX), floor(mouseAccY)
                            mouseAccX = mouseAccX - mx; mouseAccY = mouseAccY - my
                            if (mx ~= 0 or my ~= 0) and not Aim.DRY then pcall(mousemoverel, mx, my); Aim._moves = (Aim._moves or 0) + 1; sentX, sentY = mx, my end
                        end
                        if Aim.TRACE then
                            local tn = clock()
                            if tn - (Aim._trT or 0) >= 0.05 then
                                Aim._trT = tn
                                local lead = aimPt - pos
                                Aim._trBuf = Aim._trBuf or {}
                                Aim._trBuf[#Aim._trBuf + 1] = string.format(
                                    "%.2f trim=(%.1f,%.1f)mm err=%.1f ex=%.1f ey=%.1f f=(%.1f,%.1f) v=(%.0f,%.0f) calm=(%.2f,%.2f) hull=(%.1f,%.1f) sent=(%d,%d) D=%.0fm lead=(%.1f,%.1f,%.1f) lim=%s dpc=%.3f mz=%s sign=%d bore=(%.2f,%.2f,%.2f) gun=%s g=%s rel=%s lock=%s@%s key=%s flips=%d ret=%s",
                                    tn, trimX * 1000, trimY * 1000, err, ex, ey, fx, fy, vx, vy, calmV, calmH, hullRateV, hullRateH, sentX, sentY, D / STUD_PER_M,
                                    lead.X, lead.Y, lead.Z, tostring(elevClamped), degPerCount, tostring(muzzle and muzzle.Name), sign,
                                    bdir.X, bdir.Y, bdir.Z, tostring(gunName), tostring(curGuided), tostring(reloading),
                                    tostring(lock.e.name), tostring(lock.addr), tostring(down), keyFlips, tostring(usingRet))
                                if tn - (Aim._trF or 0) >= 1 then
                                    Aim._trF = tn
                                    pcall(appendfile, "aimtrace.txt", table.concat(Aim._trBuf, "\n") .. "\n")
                                    Aim._trBuf = {}
                                end
                            end
                        end
                        Aim._dbg = { tank = lock.e.name, part = lock.rec.center and "center" or (lock.rec.part and lock.rec.part.Name), err = floor(err),
                            distM = floor(D / STUD_PER_M), flightT = floor(lastT * 1000) / 1000, dropM = floor(0.5 * (curG / STUD_PER_M) * lastT * lastT * 100) / 100, dz = dz }
                    end
                end
            end
        else
            lock = nil; ctlLock = nil; stickySpent = false; elevClamped = false; trimLock = nil
            mouseAccX, mouseAccY = 0, 0
            Aim._why = reloading and "reload" or (Config.Enabled and "keyup" or "off")
            if Config.Enabled and Config.Predict then pcall(warmTrack, R, now0) end
        end
        local rp, onr
        local crx, cry
        if Config.ReticleAim then crx, cry = reticlePoint() end
        if crx then rp, onr = Vector2.new(crx, cry), true
        else rp, onr = WTS(mpos + bdir * ringDist) end
        local ring = Aim.ring
        if onr then
            ring.x, ring.y, ring.r, ring.on = floor(rp.X + 0.5), floor(rp.Y + 0.5), Config.FOV, true
        else ring.on = false end
        if Config.ShowFOV and onr then
            fovCircle.Position = Vector2.new(ring.x, ring.y); fovCircle.Radius = Config.FOV; fovCircle.Visible = true
        else fovCircle.Visible = false end
        local d = Aim._dbg
        if Config.Readout and aiming and lock and d and ring.on then
            local rt = _G.SahurRoundType and _G.SahurRoundType(curShellName) or nil
            readout.Text = string.format("%s  %dm%s%s", tostring(d.tank or "?"), d.distM or 0, rt and ("  " .. rt) or "", elevClamped and "  LIMIT" or "")
            readout.Position = Vector2.new(ring.x, ring.y + Config.FOV + 6); readout.Visible = true
        else readout.Visible = false end
    end
    conn = RunService.RenderStepped:Connect(function(dt) local t0 = os.clock(); frameBody(dt); local P = _G.SahurPerfAdd; if P then P("aim", t0) end end)
    return Aim
end
function Aim.stop()
    loopRunning = false
    if conn then pcall(function() conn:Disconnect() end); conn = nil end
    pcall(function() fovCircle:Remove() end)
    pcall(function() readout:Remove() end)
    lock = nil
    return Aim
end
function Aim.inTank() local R = _G.SahurTanks return (R and R.myAddr ~= nil) or false end
function Aim.count() local R = _G.SahurTanks return R and #R.list or 0 end
function Aim.debug()
    local R = _G.SahurTanks
    local out = { muzzle = muzzle and muzzle.Name or nil, sign = sign, lock = lock and lock.e.name or nil,
        trav = string.format("h=%s v=%s elev=%s..%s stab=%s/%s (%s)", tostring(trav.h), tostring(trav.v), tostring(trav.vmin), tostring(trav.vmax), tostring(trav.sh), tostring(trav.sv), tostring(trav.src)),
        degPerCount = degPerCount, nguns = guns and #guns or 0,
        shell = curShellName, shellMs = curShellMs, shellMap = shellMap, src = curShellSrc, gun = gunName }
    if R then
        local t = {}
        for _, e in ipairs(R.list) do
            local live = {}
            for _, r in ipairs(e.liveAmmo or {}) do live[#live + 1] = r.part.Name end
            t[#t + 1] = string.format("%s%s dead=%s enemy=%s occ=%s liveAmmo=[%s]", e.name,
                e.addr == R.myAddr and "(MINE)" or "", tostring(e.dead), tostring(e.enemy), tostring(e.occupied), table.concat(live, ","))
        end
        out.tanks = t
    end
    return out
end
return Aim
]=],
["sahur/modules/misc.lua"] = [=[
local Misc = {
    Config = {
        BarrelLine = false,
        LineLength = 150,
    },
}
_G.SahurMisc = Misc
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = workspace
local floor = math.floor
local WTS = WorldToScreen
local ACCENT = Color3.fromRGB(240, 24, 43)
local function caliber(name)
    local mm = name:match("(%d+%.?%d*)mm")
    if mm then return tonumber(mm) end
    local cal = name:match("(%d+%.?%d*)%s*[Cc]al")
    if cal then return tonumber(cal) / 100 * 25.4 end
    return 0
end
local function weaponsOf(veh)
    local f = veh and veh:FindFirstChild("Turrets")
    local t1 = f and f:FindFirstChild("Turret1")
    local w = t1 and t1:FindFirstChild("Weapons")
    if w or not veh then return w end
    for _, c in ipairs(veh:GetChildren()) do
        if c.ClassName == "Folder" then
            local t = c:FindFirstChild("Turret1")
            w = t and t:FindFirstChild("Weapons")
            if w then return w end
        end
    end
end
local function mainGun(veh)
    local w = weaponsOf(veh)
    if not w then return nil end
    local best, bestCal
    for _, g in ipairs(w:GetChildren()) do
        local c = caliber(g.Name)
        if c >= 20 and (not bestCal or c > bestCal) then best = g; bestCal = c end
    end
    return best
end
local function gunMuzzle(gun)
    local mo = gun and gun:FindFirstChild("Muzzle")
    if mo and mo.Value and mo.Value.CFrame then return mo.Value end
    local cm = gun and gun:FindFirstChild("CurrentMuzzle")
    local inner = cm and cm.Value and cm.Value:FindFirstChild("Muzzle")
    if inner and inner.Value then return inner.Value end
    return nil
end
local function barrelFallback(veh)
    local dm = veh:FindFirstChild("DamageModules")
    local bm = dm and dm:FindFirstChild("BarrelModel")
    if not bm then return nil end
    for _, p in ipairs(bm:GetDescendants()) do
        if p:IsA("BasePart") and p.Name:lower():find("barrel") then return p end
    end
    return nil
end
local function hullCenter(veh)
    local hull = veh:FindFirstChild("Hull")
    local mass = hull and hull:FindFirstChild("Mass")
    if mass then return mass.Position end
    return nil
end
local function hullMass(v) local h = v:FindFirstChild("Hull") return h and h:FindFirstChild("Mass") end
local function isTank(v) local ok, h = pcall(function() return v:FindFirstChild("Chassis") ~= nil end) return ok and h end
local lastGate = "?"
local function ownVehicle()
    local lp = Players.LocalPlayer
    if not lp then lastGate = "no-lp"; return nil end
    local it = lp:FindFirstChild("InTank")
    local veh = it and it.Value
    if veh then
        local okp = pcall(function() return veh.Parent end)
        if okp and veh.Parent and isTank(veh) then lastGate = "InTank"; return veh end
    end
    lastGate = "not-in-tank"
    return nil
end
local dot = Drawing.new("Circle")
dot.Filled = true; dot.NumSides = 24; dot.Radius = 4.5
dot.Color = ACCENT; dot.Transparency = 1; dot.Visible = false
local dotRing = Drawing.new("Circle")
dotRing.Filled = false; dotRing.Thickness = 1.5; dotRing.NumSides = 24; dotRing.Radius = 6
dotRing.Color = Color3.fromRGB(255, 255, 255); dotRing.Transparency = 1; dotRing.Visible = false
local line = Drawing.new("Line")
line.Thickness = 1.8; line.Color = ACCENT; line.Transparency = 1; line.Visible = false
function Misc.SetAccent(c)
    ACCENT = c
    pcall(function() dot.Color = c; line.Color = c end)
end
local function hideAll() dot.Visible = false; dotRing.Visible = false; line.Visible = false end
local muzzle, sign = nil, 1
local loopRunning = false
local conn
function Misc.start()
    if loopRunning then return Misc end
    loopRunning = true
    task.spawn(function()
        while loopRunning do
            local m, s = nil, 1
            if Misc.Config.BarrelLine then
                pcall(function()
                    local veh = ownVehicle()
                    if not veh then return end
                    local gun = mainGun(veh)
                    m = gunMuzzle(gun) or barrelFallback(veh)
                    if m then
                        local cf = m.CFrame
                        local center = cf and hullCenter(veh)
                        if cf and center then
                            s = (cf.LookVector:Dot(cf.Position - center) < 0) and -1 or 1
                        end
                    end
                end)
            end
            muzzle, sign = m, s
            task.wait(0.3)
        end
    end)
    local function frameBody()
        if not Misc.Config.BarrelLine or not muzzle then hideAll(); return end
        local ok, cf = pcall(function() return muzzle.CFrame end)
        if not ok or not cf then hideAll(); return end
        local o = cf.Position
        local dir = cf.LookVector * sign
        local tip = o + dir * Misc.Config.LineLength
        local sO, onO = WTS(o)
        local sT, onT = WTS(tip)
        if not onO then hideAll(); return end
        local ox, oy = floor(sO.X + 0.5), floor(sO.Y + 0.5)
        dot.Position = Vector2.new(ox, oy); dot.Visible = true
        dotRing.Position = Vector2.new(ox, oy); dotRing.Visible = true
        if onT then
            line.From = Vector2.new(ox, oy); line.To = Vector2.new(floor(sT.X + 0.5), floor(sT.Y + 0.5)); line.Visible = true
        else
            line.Visible = false
        end
    end
    conn = RunService.RenderStepped:Connect(function() local t0 = os.clock(); frameBody(); local P = _G.SahurPerfAdd; if P then P("misc", t0) end end)
    return Misc
end
function Misc.debug()
    return { on = Misc.Config.BarrelLine, gate = lastGate, hasMuzzle = muzzle ~= nil,
        muzzle = muzzle and muzzle.Name, sign = sign, len = Misc.Config.LineLength }
end
function Misc.stop()
    loopRunning = false
    if conn then pcall(function() conn:Disconnect() end); conn = nil end
    pcall(function() dot:Remove() end)
    pcall(function() dotRing:Remove() end)
    pcall(function() line:Remove() end)
    return Misc
end
return Misc
]=],
["sahur/modules/heli.lua"] = [=[
local Heli = {
    Config = { Enabled = true, MaxTime = 6, Color = Color3.fromRGB(240, 24, 43),
        Marker = "+",
    },
}
_G.SahurHeli = Heli
local Config = Heli.Config
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local floor, clock = math.floor, os.clock
local WTS = WorldToScreen
local V2 = Vector2.new
local STUD_PER_M = 2.7777778
local G = 9.81 * STUD_PER_M
local SPEED_SCALE = 0.985
local STEP = 0.05
local NSEG = 120
local DOWN = Vector3.new(0, -1, 0)
local segs = {}
for i = 1, NSEG do local l = Drawing.new("Line"); l.Thickness = 1.5; l.Transparency = 0.85; l.Color = Config.Color; l.Visible = false; segs[i] = l end
local pip = Drawing.new("Circle"); pip.Filled = false; pip.Thickness = 2; pip.NumSides = 32; pip.Radius = 9; pip.Transparency = 1; pip.Visible = false
local pipDot = Drawing.new("Circle"); pipDot.Filled = true; pipDot.NumSides = 12; pipDot.Radius = 2; pipDot.Transparency = 1; pipDot.Visible = false
local mk1 = Drawing.new("Line"); mk1.Thickness = 2; mk1.Transparency = 1; mk1.Visible = false
local mk2 = Drawing.new("Line"); mk2.Thickness = 2; mk2.Transparency = 1; mk2.Visible = false
local FONT = (Drawing.Fonts and Drawing.Fonts.System) or 1
local function mkText(col)
    local t = Drawing.new("Text"); t.Size = 13; t.Center = true; t.Outline = true; t.Color = col or Color3.fromRGB(255, 255, 255); t.Visible = false
    pcall(function() t.Font = FONT end)
    return t
end
local txt = mkText()
function Heli.SetColor(c) Config.Color = c end
local function hideMarker() pip.Visible = false; pipDot.Visible = false; mk1.Visible = false; mk2.Visible = false end
local function hideAll()
    for i = 1, NSEG do segs[i].Visible = false end
    hideMarker(); txt.Visible = false
end
local function drawMarker(c, col)
    local st = Config.Marker
    pipDot.Position = c; pipDot.Color = col; pipDot.Visible = true
    if st == "Circle" then
        pip.Position = c; pip.Color = col; pip.Visible = true
        mk1.Visible = false; mk2.Visible = false
    elseif st == "— —" then
        pip.Visible = false
        mk1.From = V2(c.X - 16, c.Y); mk1.To = V2(c.X - 5, c.Y); mk1.Color = col; mk1.Visible = true
        mk2.From = V2(c.X + 5, c.Y); mk2.To = V2(c.X + 16, c.Y); mk2.Color = col; mk2.Visible = true
    else
        pip.Visible = false
        mk1.From = V2(c.X - 10, c.Y); mk1.To = V2(c.X + 10, c.Y); mk1.Color = col; mk1.Visible = true
        mk2.From = V2(c.X, c.Y - 10); mk2.To = V2(c.X, c.Y + 10); mk2.Color = col; mk2.Visible = true
    end
end
local function isHeli(v)
    local ok, r = pcall(function() return v:FindFirstChild("MainRotor") ~= nil or v:FindFirstChild("RotorFolder") ~= nil end)
    return ok and r
end
local function turretsOf(v)
    local f = v:FindFirstChild("Turrets")
    if f then return f end
    for _, c in ipairs(v:GetChildren()) do
        if c.ClassName == "Folder" then
            local t = c:FindFirstChild("Turret1")
            if t and t:FindFirstChild("Weapons") then return c end
        end
    end
end
local function muzzleOf(g)
    local mo = g:FindFirstChild("Muzzle")
    local cm = g:FindFirstChild("CurrentMuzzle")
    local cur
    if cm then
        local ok, v = pcall(function() return cm.Value end)
        if ok and v and v.ClassName == "ObjectValue" then cur = cm end
    end
    local fixed = (mo and mo.Value) and mo or ((not cur and cm and cm.Value) and cm or nil)
    if cur or fixed then return { cur = cur, fixed = fixed } end
end
local function resolvePart(link)
    local o = link
    for _ = 1, 3 do
        local ok, v = pcall(function() return o.Value end)
        if not ok or not v then return nil end
        local okc, cf = pcall(function() return v.CFrame end)
        if okc and cf then return v, cf end
        o = v
    end
end
local function weaponsOf(v)
    local list = {}
    local tf = turretsOf(v)
    if not tf then return list end
    for _, t in ipairs(tf:GetChildren()) do
        local w = t:FindFirstChild("Weapons")
        if w then
            for _, g in ipairs(w:GetChildren()) do
                local mz = muzzleOf(g)
                local ty = g:FindFirstChild("Type")
                local okt, tv = pcall(function() return ty and ty.Value end)
                if mz and g.Name ~= "Flares" and g.Name ~= "Smoke Grenade" then
                    list[#list + 1] = { gun = g, name = g.Name, mz = mz, loaded = g:FindFirstChild("CurrentlyLoaded"), type = okt and tv or nil }
                end
            end
        end
    end
    return list
end
local selObj
local function selectedName()
    if not selObj then
        local ok, o = pcall(function() return game:GetService("ReplicatedFirst").NewGuiData.Gunner.Weapons.Data.CurrentlySelected end)
        if ok and o then selObj = o else return nil end
    end
    local ok, v = pcall(function() return selObj.Value end)
    if not ok or not v then return nil end
    local okn, n = pcall(function() return v.Name end)
    return okn and n or nil
end
local function guided(gun, round)
    local gt = _G.SahurGuided and _G.SahurGuided[gun]
    if not gt then return false end
    if round and gt[round] then return true end
    if round then for g in pairs(gt) do if round:sub(1, #g) == g then return true end end end
    local ball = _G.SahurBallistics and _G.SahurBallistics[gun]
    if ball then
        local all = true
        for r in pairs(ball) do if not gt[r] then all = false; break end end
        return all
    end
    return false
end
local function roundSpeed(gun, round)
    local b = _G.SahurBallistics and _G.SahurBallistics[gun]
    local v = b and round and tonumber(b[round])
    if v then return v end
    if b then for _, x in pairs(b) do if tonumber(x) then return tonumber(x) end end end
    return nil
end
local loopRunning, conn = false, nil
local veh, mass, weapons, active = nil, nil, {}, nil
local heliEpoch = 0
local cam
local speedMs, isGuided, roundName = nil, false, nil
local path, npath, impact, impactDist = {}, 0, nil, nil
local lastTrace = 0
local rparams = nil
local function trace()
    npath, impact, impactDist = 0, nil, nil
    if not active or not speedMs or isGuided then return end
    local _, cf
    if active.mz.cur then _, cf = resolvePart(active.mz.cur) end
    if not cf and active.mz.fixed then _, cf = resolvePart(active.mz.fixed) end
    if not cf then return end
    local dir = cf.LookVector
    local ref
    if cam then local okk, ccf = pcall(function() return cam.CFrame end); if okk and ccf then ref = ccf.LookVector end end
    if not ref and mass then local okm, mp = pcall(function() return mass.Position end); if okm and mp then ref = cf.Position - mp end end
    if ref and dir:Dot(ref) < 0 then dir = -dir end
    local vel = dir * (speedMs * STUD_PER_M * SPEED_SCALE)
    if mass then local okv, hv = pcall(function() return mass.AssemblyLinearVelocity end); if okv and hv then vel = vel + hv end end
    local p = cf.Position + dir * 2
    local origin = p
    path[1] = p; npath = 1
    local maxSeg = math.min(NSEG, floor(Config.MaxTime / STEP))
    for _ = 1, maxSeg do
        local np = p + vel * STEP + DOWN * (0.5 * G * STEP * STEP)
        vel = vel + DOWN * (G * STEP)
        local hit = workspace:Raycast(p, np - p, rparams)
        if hit then
            npath = npath + 1; path[npath] = hit.Position
            impact = hit.Position
            impactDist = (impact - origin).Magnitude / STUD_PER_M
            return
        end
        npath = npath + 1; path[npath] = np
        p = np
    end
end
function Heli.start()
    if loopRunning then return Heli end
    loopRunning = true
    task.spawn(function()
        while loopRunning do
            pcall(function()
                local R = _G.SahurTanks
                if R and (R.epoch or 0) ~= heliEpoch then heliEpoch = R.epoch or 0; veh, active, weapons, npath, impact = nil, nil, {}, 0, nil end
                local lp = Players.LocalPlayer
                local it = lp and lp:FindFirstChild("InTank")
                local v = it and it.Value
                if not Config.Enabled or not v or not isHeli(v) then veh, active = nil, nil; return end
                local okA, a1 = pcall(function() return v.Address end)
                local okB, a2 = pcall(function() return veh and veh.Address end)
                if not veh or not (okA and okB and a1 == a2) then
                    veh = v
                    local h = v:FindFirstChild("Hull"); mass = h and h:FindFirstChild("Mass")
                    cam = v:FindFirstChild("VehicleCam")
                    weapons = weaponsOf(v)
                    local okp, rp = pcall(function() return RaycastParams.new() end)
                    rparams = okp and rp or nil
                    if rparams then pcall(function() rparams.FilterDescendantsInstances = { v } end) end
                end
                local nm = selectedName()
                local pick
                for _, w in ipairs(weapons) do if w.name == nm then pick = w; break end end
                active = pick
                if active then
                    local okl, rv = pcall(function() return active.loaded and active.loaded.Value end)
                    roundName = (okl and type(rv) == "string" and rv ~= "" and rv ~= "Unloaded") and rv or nil
                    isGuided = guided(active.name, roundName)
                    speedMs = roundSpeed(active.name, roundName)
                end
            end)
            task.wait(0.25)
        end
    end)
    local function frameBody()
        Heli._frames = (Heli._frames or 0) + 1
        if not Config.Enabled or not veh or not active or isGuided or not speedMs then hideAll(); return end
        local now = clock()
        if now - lastTrace >= 1 / 30 then lastTrace = now; pcall(trace) end
        local col = Config.Color
        local prev, prevOn = nil, false
        local used = 0
        for i = 1, npath do
            local sp, on = WTS(path[i])
            if i > 1 and used < NSEG then
                used = used + 1
                local l = segs[used]
                if on and prevOn then l.From = prev; l.To = V2(sp.X, sp.Y); l.Color = col; l.Visible = true else l.Visible = false end
            end
            prev, prevOn = on and V2(sp.X, sp.Y) or nil, on
        end
        for i = used + 1, NSEG do segs[i].Visible = false end
        local shown = false
        if impact then
            local sp, on = WTS(impact)
            if on then
                shown = true
                local c = V2(floor(sp.X + 0.5), floor(sp.Y + 0.5))
                drawMarker(c, col)
                txt.Text = string.format("%dm  %s", floor(impactDist or 0), tostring(roundName or active.name))
                txt.Position = V2(c.X, c.Y + 14); txt.Visible = true
            end
        end
        if not shown then hideMarker(); txt.Visible = false end
    end
    conn = RunService.RenderStepped:Connect(function() local t0 = os.clock(); frameBody(); local P = _G.SahurPerfAdd; if P then P("heli", t0) end end)
    return Heli
end
function Heli.debug()
    return { veh = veh and veh.Name, active = active and active.name, round = roundName, speed = speedMs,
        guided = isGuided, npath = npath, impact = impact and tostring(impact), dist = impactDist,
        weapons = (function() local s = {} for _, w in ipairs(weapons) do s[#s + 1] = w.name .. "(" .. tostring(w.type) .. ")" end return table.concat(s, ", ") end)() }
end
function Heli.stop()
    loopRunning = false
    if conn then pcall(function() conn:Disconnect() end); conn = nil end
    for i = 1, NSEG do pcall(function() segs[i]:Remove() end) end
    pcall(function() pip:Remove() end); pcall(function() pipDot:Remove() end); pcall(function() txt:Remove() end)
    pcall(function() mk1:Remove() end); pcall(function() mk2:Remove() end)
    veh, active = nil, nil
    return Heli
end
return Heli
]=],
["sahur/modules/missile.lua"] = [=[
local MSL = {
    Config = { Enabled = true },
}
_G.SahurMissile = MSL
local Config = MSL.Config
local RunService = game:GetService("RunService")
local floor, clock, sqrt = math.floor, os.clock, math.sqrt
local WTS = WorldToScreen
local V2 = Vector2.new
local STUDS_TO_M = 1 / 2.7777778
local SCAN_EVERY = 0.15
local MOVE2      = 4
local INCOMING_COS = 0.96
local POOL = 16
local COL = {
    AA = Color3.fromRGB(255, 60, 60), ATGM = Color3.fromRGB(255, 170, 40), AGM = Color3.fromRGB(255, 120, 40),
    Rocket = Color3.fromRGB(255, 220, 80), Bomb = Color3.fromRGB(255, 60, 60),
}
local COL_IN = Color3.fromRGB(255, 30, 30)
local PROJ = {}
do
    local function P(label, names) for _, n in ipairs(names) do PROJ[n:lower()] = label end end
    P("AA",     { "SAM", "SAM1", "SAM2", "SAM3", "StingerRocket", "PATRIOTProj", "aim9m", "kugelblitz" })
    P("ATGM",   { "wireatgm", "roketatgm", "KornetATGMModel", "302ATM", "DragonATGM", "nlawmis", "STURM", "SS.11", "losat", "testatgm", "Brimstone" })
    P("AGM",    { "agm65", "kh25ml", "kh35", "kh38mle" })
    P("Rocket", { "MLRSRocket", "RP3RocketModel", "RP3Rocket", "RGB-60", "roket", "roketbeg", "RPG", "IskanderRocket", "HERO-120" })
    P("Bomb",   { "Bomb", "fab500m62", "mk842000lbs" })
end
local catCache = {}
local function catOf(name)
    local c = catCache[name]
    if c == nil then c = PROJ[name:lower()] or false; catCache[name] = c end
    return c
end
local FONT = (Drawing.Fonts and Drawing.Fonts.System) or 1
local slots = {}
for i = 1, POOL do
    local mk = Drawing.new("Circle"); mk.Filled = false; mk.Thickness = 2; mk.NumSides = 16; mk.Radius = 6; mk.Transparency = 1; mk.Visible = false
    local tag = Drawing.new("Text"); tag.Size = 13; tag.Center = true; tag.Outline = true; tag.Visible = false
    pcall(function() tag.Font = FONT end)
    slots[i] = { mk = mk, tag = tag }
end
local function hideSlot(s) s.mk.Visible = false; s.tag.Visible = false end
local loopRunning, conn = false, nil
local tracks = {}
local list = {}
local containers = {}
local lastDrawn = 0
local mslEpoch = 0
local function findContainers()
    containers = {}
    local ter = workspace:FindFirstChild("Terrain")
    if ter then containers[#containers + 1] = ter end
    local ok, f = pcall(function() return game:GetService("ReplicatedStorage").PHRST.Shells:FindFirstChild("PhysicalBullets") end)
    if ok and f then containers[#containers + 1] = f end
end
local SCAN_WIN, TRACK_IDLE = 64, 1.5
local known = {}
local function scan()
    local now = clock()
    local alive = {}
    for _, cont in ipairs(containers) do
        local ok, kids = pcall(function() return cont:GetChildren() end)
        if ok and kids then
            local n = #kids
            local from = n - SCAN_WIN + 1
            if from < 1 then from = 1 end
            for i = from, n do
                local c = kids[i]
                local oka, ad = pcall(function() return c.Address end)
                if oka and ad then
                    local cat = known[ad]
                    if cat == nil then
                        local okn, nm = pcall(function() return c.Name end)
                        cat = (okn and nm and catOf(nm)) or false
                        known[ad] = cat
                    end
                    alive[ad] = true
                    if cat then
                        local t = tracks[ad]
                        if not t then
                            local okc, anchor = pcall(function()
                                local cn = c.ClassName
                                return (cn == "Model") and c.PrimaryPart or c
                            end)
                            if okc and anchor then t = { anchor = anchor, cat = cat, still = now }; tracks[ad] = t end
                        end
                        if t then
                            local okp, pp = pcall(function() return t.anchor.Position end)
                            if okp and pp then
                                if t.p then
                                    local d = pp - t.p
                                    local dt = now - t.t
                                    if dt > 0 then t.v = d / dt end
                                    t.moving = (d.X * d.X + d.Y * d.Y + d.Z * d.Z) > MOVE2
                                end
                                t.p, t.t = pp, now
                                if t.moving then t.still = now end
                            end
                        end
                    end
                end
            end
        end
    end
    for ad in pairs(known) do if not alive[ad] then known[ad] = nil end end
    local out = {}
    for ad, t in pairs(tracks) do
        if not alive[ad] or now - t.still > TRACK_IDLE then tracks[ad] = nil
        elseif t.moving and t.p then out[#out + 1] = t end
    end
    list = out
end
function MSL.start()
    if loopRunning then return MSL end
    loopRunning = true
    findContainers()
    task.spawn(function()
        while loopRunning do
            local R = _G.SahurTanks
            if R and (R.epoch or 0) ~= mslEpoch then
                mslEpoch = R.epoch or 0
                tracks, list, known = {}, {}, {}
                pcall(findContainers)
            end
            if Config.Enabled then local t0 = os.clock(); pcall(scan); local P = _G.SahurPerfAdd; if P then P("mslScan", t0) end elseif #list > 0 then list = {}; tracks = {} end
            task.wait(Config.Enabled and SCAN_EVERY or 0.5)
        end
    end)
    local function frameBody()
        local drawn = 0
        if Config.Enabled and #list > 0 then
            local me
            local R = _G.SahurTanks
            if R and R.myTank then local ok, p = pcall(function() return R.myTank.mass.Position end); if ok then me = p end end
            local cam = workspace.CurrentCamera
            local okc, ccf = pcall(function() return cam.CFrame end)
            local eye = okc and ccf and ccf.Position
            me = me or eye
            for i = 1, #list do
                if drawn >= POOL then break end
                local t = list[i]
                local ok, pos = pcall(function() return t.p + (t.v or Vector3.new()) * (os.clock() - t.t) end)
                if ok and pos then
                    local sp, vis = WTS(pos)
                    if vis and sp then
                        drawn = drawn + 1
                        local s = slots[drawn]
                        local incoming = false
                        if me and t.v then
                            local to = me - pos
                            local dl, vl = to.Magnitude, t.v.Magnitude
                            if dl > 1 and vl > 5 then incoming = (t.v:Dot(to) / (dl * vl)) > INCOMING_COS end
                        end
                        local col = incoming and COL_IN or COL[t.cat] or COL.Rocket
                        local x, y = floor(sp.X + 0.5), floor(sp.Y + 0.5)
                        s.mk.Position = V2(x, y); s.mk.Color = col; s.mk.Radius = incoming and 9 or 6; s.mk.Visible = true
                        local dist = eye and floor((pos - eye).Magnitude * STUDS_TO_M) or 0
                        s.tag.Text = (incoming and "INCOMING " or "") .. t.cat .. "  " .. dist .. "m"
                        s.tag.Color = col; s.tag.Position = V2(x, y - 20); s.tag.Visible = true
                    end
                end
            end
        end
        for i = drawn + 1, lastDrawn do hideSlot(slots[i]) end
        lastDrawn = drawn
    end
    conn = RunService.RenderStepped:Connect(function() local t0 = os.clock(); frameBody(); local P = _G.SahurPerfAdd; if P then P("msl", t0) end end)
    return MSL
end
function MSL.debug()
    local n = 0; for _ in pairs(tracks) do n = n + 1 end
    return { tracked = n, moving = #list, containers = #containers }
end
function MSL.stop()
    loopRunning = false
    if conn then pcall(function() conn:Disconnect() end); conn = nil end
    for i = 1, POOL do pcall(function() slots[i].mk:Remove() end); pcall(function() slots[i].tag:Remove() end) end
    tracks, list = {}, {}
    return MSL
end
return MSL
]=],
["sahur/data/ballistics.lua"] = [=[
_G.SahurBallistics = {
  [".30 cal M1919"]={["AP"]=800},
  [".303 Vickers K"]={["AP"]=760},
  ["100mm 2A70"]={["9M117"]=370,["3OF32"]=250},
  ["100mm 2A70M"]={["3OF70-1"]=355,["3OF70"]=355,["9M117M1"]=400},
  ["100mm 2A70M BMD-4M"]={["3OF70-1"]=355,["3OF70"]=355,["9M117M1"]=400},
  ["100mm D-10S"]={["OF-412"]=785,["BR-412B"]=895},
  ["100mm D-10T"]={["BR-412B"]=895,["3BK-5"]=900,["BR-412D"]=887,["M309"]=1430,["OF-412"]=900},
  ["100mm D-10TS2"]={["3BK17M"]=1085,["3BM-8"]=1415,["BR-412D"]=887,["OF-412"]=900,["9M117"]=370},
  ["100mm ZPL04"]={["APS03"]=370,["3OF70"]=355,["3OF70-1"]=355},
  ["105 mm KwK L/68"]={["Sprgr. L/4.4"]=900,["PzGr 40"]=1150,["PzGr. 39"]=1005},
  ["105 mm L74"]={["slpprj m/66"]=1450,["Shell L35"]=720,["rökgr m/61"]=330,["slpprj m/80"]=1455,["slsgr m/61A"]=680},
  ["105 mm M4"]={["M84"]=472,["M67 shot"]=381,["M1 shell"]=472},
  ["105mm JSW"]={["M416"]=732,["Type 75"]=760,["Type 91"]=1150,["Type 93"]=1501},
  ["105mm KM68A1"]={["M416"]=732,["M456A1"]=1173,["K274"]=1495,["M393A2"]=732},
  ["105mm M2A1"]={["M84"]=472,["M67 shot"]=381,["M1 shell"]=472},
  ["105mm M68"]={["M416"]=732,["M728"]=1426,["M393A2"]=732,["M456"]=1174},
  ["105mm M68A1"]={["M774"]=1509,["M393A2"]=732,["M456A2"]=1174,["M900"]=1505,["M833"]=1485},
  ["105mm M68A1E4"]={["M393A3"]=720,["M900"]=1505,["M456A2"]=1174},
  ["105mm M68E1"]={["M774"]=1509,["M416"]=732,["M393A2"]=732,["M456A2"]=1174,["M735"]=1501},
  ["105mm Modele F2"]={["OCC 105 F3"]=1120,["OFL 105 F3"]=1400,["O-FUM-PH-105 F3"]=800,["OE 105 F3"]=800},
  ["105mm Sharir"]={["M152"]=1174,["M111"]=1455,["M156"]=731,["M416"]=732,["M413"]=1455},
  ["105mm T5E2"]={["T13"]=900,["T29E3"]=1128,["T46"]=945,["T30E1"]=945},
  ["105mm XM35"]={["M456A2"]=1174,["M416"]=732,["M900"]=1505,["M393A2"]=732},
  ["105mm ZPL94"]={["DTW2-105"]=1530,["M393A2"]=732,["M456A2"]=1174},
  ["106mm M40A1C"]={["M344A1"]=503,["M361A1"]=498},
  ["107mm ZIS-6"]={["B-420"]=800,["OF-420"]=720},
  ["114mm Psv.H/18"]={["hkr 42/C"]=357,["akr 32/41"]=350},
  ["115mm D-68"]={["3BK15M"]=1060,["3BM6"]=1680,["3OF18"]=750},
  ["115mm U-5TS"]={["3BK4"]=950,["3BM6"]=1680,["3BM3"]=1615,["3BK15M"]=1060,["9M117"]=370,["3OF11"]=905,["3BM28"]=1600},
  ["12.7 mm L21A1"]={["API-T"]=929},
  ["12.7mm CRC F1"]={["API-T"]=929},
  ["12.7mm DSHK"]={["12.7mm API-T"]=820},
  ["12.7mm KORD"]={["12.7mm API-T"]=820},
  ["12.7mm M2"]={["API-T"]=929},
  ["12.7mm M3P"]={["API-T"]=929},
  ["12.7mm M85"]={["API-T"]=929},
  ["12.7mm M8C"]={["AI"]=503},
  ["12.7mm NSVT"]={["12.7mm API-T"]=820},
  ["12.7mm QJC88A"]={["12.7mm API-T"]=820},
  ["12.7mm RMG"]={["API-T"]=929},
  ["12.7mm Type 54"]={["12.7mm API-T"]=820},
  ["12.7mm YAK-B"]={["12.7mm API-T"]=825},
  ["12.7mm ksp 88"]={["API-T"]=900},
  ["120mm CN08"]={["KSTAM-II"]=1410,["K279"]=1760,["K277"]=1130,["K280 Proxy"]=1410,["K280 PD"]=1410},
  ["120mm CTG L/50"]={["DM53"]=1680,["DM12A1"]=1190,["XH 45"]=1760},
  ["120mm Cannon Type 71"]={["120-HE"]=940,["120-II"]=1580,["120-HEAT"]=1000},
  ["120mm GIAT CN120-26 F1"]={["M3M PDD"]=1120,["OFL 120 F2"]=1740,["M3M PD"]=1120,["OE 120 F1"]=1050,["M3M VT"]=1120,["OFL 120 F1"]=1790,["OEFC F1"]=1410,["SHARD®"]=1720,["POLYNEGE"]=600,["OCC 120 G1"]=1100},
  ["120mm IMI MG251"]={["M339 PDD"]=900,["M338"]=1680,["M339 VT"]=900,["LAHAT"]=285,["M339 PD"]=900,["DM12A1"]=1078},
  ["120mm KBM-2"]={["KONUS"]=445,["MKE MOD 290"]=1705,["MKE MOD 300"]=1015,["MKE MOD 310"]=1140},
  ["120mm KM256"]={["K276"]=1700,["K277"]=1130},
  ["120mm L11A5"]={["Shot L15A3"]=1372,["Shell L34A2"]=670,["Shot L23A1"]=1535,["Shell L31A7"]=670},
  ["120mm L30A1"]={["Shell L34A2"]=670,["Shell L31A7"]=670,["L26A1"]=1650,["L27A1"]=1590},
  ["120mm LLR L/47"]={["DM53"]=1670,["DM11 VT"]=1015,["DM11 PD"]=1015,["XH 45"]=1700,["DM11 PDD"]=1015},
  ["120mm M256"]={["M830A1 PD"]=1410,["MKE MOD 290"]=1705,["DM33"]=1650,["M830A1 Proxy"]=1410,["M1147 PDD"]=1150,["M829A2"]=1680,["KE-W"]=1585,["M1147 VT"]=1150,["M829A3"]=1555,["M1028"]=1410,["M829"]=1670,["M1147 PD"]=1150,["M829A4"]=1650},
  ["120mm OTO Breda 120/44"]={["CL3143"]=1705,["DM12"]=1140,["DM33"]=1650,["Rh31"]=980},
  ["120mm RUAG L50"]={["OCC 120 G1"]=1100,["OFL 120 F1"]=1780},
  ["120mm Rh120 L/44"]={["IM HE-T PDD"]=1000,["DM33"]=1650,["DM12"]=1140,["DM13"]=1650,["M1028"]=1410,["IM HE-T PD"]=1000,["DM53A1"]=1650},
  ["120mm Rh120 L/55"]={["DM53"]=1750,["DM12"]=1140,["DM43A1"]=1810},
  ["120mm Rh120 L/55 A1"]={["DM73"]=1780,["DM11 PD"]=1015,["DM11 PDD"]=1015,["DM11 VT"]=1015},
  ["120mm TKG"]={["Type 10"]=1780,["JM12A1"]=1140},
  ["120mm Type 90 L/44"]={["JM33"]=1650,["JM12A1"]=1140},
  ["120mm XM360"]={["M1147 VT"]=1150,["M1147 PDD"]=1150,["M1147 PD"]=1150,["M829A4"]=1650},
  ["122mm A-19C"]={["BR-471B"]=795,["OF-471"]=795},
  ["122mm D-25T"]={["BR-471D"]=795,["BR-471"]=795,["BR-471B"]=795,["OF-471"]=795},
  ["122mm D-30"]={["3OF56 High Charge"]=690,["3BK-10"]=726,["3OF56 Medium Charge"]=350,["3OF56 Low Charge"]=175},
  ["122mm D-30T"]={["BR-471B"]=795,["OF-471"]=795},
  ["122mm Grad"]={["9M22/M21 HE-Frag"]=180},
  ["122mm M-62-T2S"]={["BR-472"]=950,["3BK-9"]=920,["3BM-11"]=1620,["OF-472"]=865},
  ["125 mm KBA-3"]={["3OF26"]=850,["3BM42"]=1700,["KOMBAT ATGM"]=445,["3BK18M"]=905},
  ["125mm 2A46"]={["3OF26"]=850,["3BM15"]=1780,["3BK12M"]=905,["3BM22"]=1760},
  ["125mm 2A46M"]={["3BM42"]=1700,["3BM60"]=1660,["3OF26"]=850,["3BM32"]=1710,["9M119"]=445,["3BK18M"]=905},
  ["125mm 2A46M-1"]={["3OF26 VT"]=850,["3BM42"]=1700,["9M119M1"]=445,["3BM60"]=1660,["3BM9"]=1800,["9M112"]=400,["KOMBAT ATGM"]=445,["3OF26"]=850,["3BM15"]=1780,["3BM32"]=1710,["3BM46"]=1700,["9M119"]=445,["3BK18M"]=905,["3OF26 PD"]=850},
  ["125mm 2A46M-5"]={["3OF26 VT"]=850,["3BM42"]=1700,["9M119M1"]=445,["3BM59"]=1610,["3OF26"]=850,["9M119"]=445,["3BM60"]=1660,["3BM46"]=1700,["3BK18M"]=905,["3OF26 PD"]=850},
  ["125mm 2A46M-5 Bustle AP"]={["9M119M1"]=445,["3BM60"]=1660,["3BK18M"]=905,["3OF26 PD"]=850,["3OF26 VT"]=850},
  ["125mm 2A46MS"]={["3OF26"]=850,["Ryś"]=1690,["P99 TAPNA"]=1690,["3BK12M"]=905,["3BM15"]=1780},
  ["125mm 2A46NK"]={["UnHE"]=878,["JoHEAT"]=943,["KiAP"]=1680},
  ["125mm 2A47"]={["3OF26"]=850,["3BK12M"]=905,["9M112"]=400,["3BM22"]=1760},
  ["125mm 2A75"]={["3OF26"]=850,["3BK18M"]=905,["3BM60"]=1660,["9M119M1"]=445},
  ["125mm 2A82"]={["3BM70"]=1750,["9M119M1"]=445,["3BM69"]=1696,["3BK18M"]=905,["3OF26 PD"]=850,["3OF26 VT"]=850},
  ["125mm 2A82-1M"]={["3UBK21"]=450,["3BM69"]=1696,["3BK18M"]=905,["3OF26 PD"]=850,["3OF26 VT"]=850},
  ["125mm D-126"]={["BUR"]=380,["Rubin"]=550},
  ["125mm Type 88C"]={["DTC10-125"]=1760,["DTB-125"]=850,["DTP-125"]=905,["125-II"]=1740},
  ["125mm Type 99A"]={["DTC10-125"]=1760,["DTP-125"]=905,["DTB12-125 VT"]=850,["GP125"]=405,["DTB12-125 PD"]=850},
  ["125mm ZPT98"]={["DTP-125"]=905,["DTB12-125 VT"]=850,["GP125"]=405,["DTB12-125 PD"]=850,["APFSDS/T"]=1730},
  ["128 mm KwK44"]={["Sprgr. L/5"]=750,["PzGr 43"]=940},
  ["128 mm L/66"]={["Sprgr. L/5"]=780,["PzGr 43"]=1000},
  ["128 mm PaK44"]={["Sprgr. L/5"]=750,["PzGr 43"]=940},
  ["130mm M-65"]={["BR-482B"]=1000,["OF-482M"]=900},
  ["130mm Rh130 L/51"]={["DM13"]=1848,["DM12A1"]=1190,["DM11 PD"]=1015,["DM11 VT"]=1015,["DM11 PDD"]=1015},
  ["130mm S-70"]={["BR-482B"]=900,["OF-482M"]=900},
  ["14.5mm KPVT"]={["BST"]=1000},
  ["140mm RUAG L/47"]={["140mm Pz Kan HL Pat MZ HEAT-MP VT"]=1410,["140mm Pz Kan Pfeil Pat APFSDS"]=1900,["140mm Pz Kan HL Pat MZ HEAT-MP PD"]=1410},
  ["140mm XM291"]={["XM965 PD"]=1500,["XM965 Proxy"]=1500,["XM964"]=1850},
  ["150 mm Wgr.41 Spr rocket"]={["15 cm Wurfgranate 41 Spreng"]=340},
  ["152.4mm BL-8"]={["BR-540B"]=850,["OF-540"]=880},
  ["152mm 2A64"]={["3OF45 Proxy High Charge"]=828,["3OF45 Proxy Low Charge"]=207,["3OF45 Proxy Medium Charge"]=414,["3OF45 Low Charge"]=207,["3OF45 Medium Charge"]=414,["3OF45 High Charge"]=828},
  ["152mm 2A64M"]={["3OF61 Medium Charge"]=414,["3OF61 Proxy High Charge"]=828,["3OF61 Proxy Low Charge"]=207,["3VO28 Low Charge"]=207,["3OF61 High Charge"]=828,["3OF61 Low Charge"]=207,["3VO28 Medium Charge"]=414,["3OF61 Proxy Medium Charge"]=414,["3VO28 High Charge"]=828},
  ["152mm 2A73"]={["Grifel-3"]=850,["APFSDS"]=1980},
  ["152mm 2A83"]={["Grifel-3 VT"]=850,["Grifel-1"]=1726,["Grifel-2"]=1780,["Grifel-3 PD"]=850},
  ["152mm LP-83"]={["APFSDS"]=1980,["HE"]=920},
  ["152mm M-10T"]={["OF-530"]=530,["PB-35"]=436},
  ["152mm M-69"]={["3OF31"]=960,["3BM16"]=1750,["3BK20"]=1000},
  ["152mm M162"]={["MGM-51B Shillelagh"]=286,["M625A1"]=1410,["M409A1"]=682,["M657A2"]=682},
  ["152mm M81E1"]={["MGM-51B Shillelagh"]=286,["M625A1"]=1410,["M409A1"]=682,["M657A2"]=682},
  ["152mm ML-20S"]={["BR-540B"]=600,["OF-540"]=655},
  ["152mm XM150E5"]={["MGM-51C"]=286,["M409A1"]=754,["XM578E4"]=1509},
  ["155mm L62"]={["DM121 Medium Charge"]=506,["DM702A1 High Charge"]=1015,["DM121 Low Charge"]=254,["DM702A1"]=1015,["DM702A1 Medium Charge"]=506,["DM121 High Charge"]=1015,["DM121 Proxy Medium Charge"]=506,["DM702A1 Low Charge"]=254,["DM121 Proxy High Charge"]=1015,["DM121 Proxy Low Charge"]=254},
  ["155mm M185"]={["M107 Low Charge"]=171,["M107 High Charge VT"]=684,["M107 Low Charge VT"]=171,["M107 High Charge"]=684,["M107 Medium Charge"]=342,["M107 Low Charge PF"]=171,["M110 High Charge"]=684,["M110 Medium Charge"]=342,["M110 Low Charge"]=171,["M107 Medium Charge VT"]=342,["M107 Medium Charge PF"]=342,["M107 High Charge PF"]=684},
  ["155mm M284"]={["M107 Low Charge"]=171,["M107 High Charge VT"]=684,["M107 Low Charge VT"]=171,["M107 High Charge"]=684,["M107 Medium Charge"]=342,["M107 Low Charge PF"]=171,["M110 High Charge"]=684,["M110 Medium Charge"]=342,["M110 Low Charge"]=171,["M107 Medium Charge VT"]=342,["M107 Medium Charge PF"]=342,["M107 High Charge PF"]=684},
  ["155mm T180"]={["T152"]=563,["T267"]=826},
  ["183mm L4"]={["Shell L1"]=716},
  ["203mm 2A44"]={["2VG11"]=864,["3VOF34 Low Charge"]=194,["3VO15 Low Charge"]=194,["3VOF34 Medium Charge"]=388,["3VO15 High Charge"]=775,["3VO15 Medium Charge"]=388,["3VOF34 High Charge"]=775},
  ["20mm M168"]={["M53"]=1030,["M56A3"]=1030},
  ["20mm NC 621"]={["HE-T"]=1100,["AP"]=1150},
  ["20mm Oerlikon KAA"]={["AP-T"]=1150,["HE-T"]=1100},
  ["20mm Rh202"]={["DM51A2"]=1045,["DM43"]=1150,["DM63"]=1150},
  ["20mm Solothurn S-18/1000"]={["Paulina AP-T"]=910},
  ["20mm TNSh"]={["FI"]=800,["API HV"]=892},
  ["212mm RBU-6000"]={["RGB-60"]=400},
  ["220mm TOS-1A"]={["Thermobaric"]=180,["Incendiary"]=180,["Blast fragmentation"]=180},
  ["227mm M269"]={["M26A1 Low Charge"]=180,["M31A2 High Charge"]=420,["M26A1 High Charge"]=420,["M31A2 Medium Charge"]=300,["M26A1 Medium Charge"]=300,["M31A2 Low Charge"]=180},
  ["23mm GSh-23L"]={["HEF-I "]=710,["API-T "]=710},
  ["25mm DBTSU"]={["DBTSU AP"]=970,["DBTSU HE"]=980},
  ["25mm GAU-12U"]={["HVAP"]=1036,["HEI"]=1085},
  ["25mm LW25"]={["HE PD"]=436,["HEDP"]=436,["HE VT"]=436},
  ["25mm M242 Bushmaster"]={["M791"]=1345,["M919"]=1429,["M792"]=1100},
  ["25mm M242AA Bushmaster"]={["M791"]=1345,["M792"]=1100},
  ["302 Anti-tank Missile"]={["302 Anti-tank Missile"]=220},
  ["30mm 2A38"]={["AP-T"]=970,["HEF-I"]=960},
  ["30mm 2A42"]={["3UOF8"]=960,["3UBR8"]=1120},
  ["30mm 2A42M"]={["3UBR11"]=1260,["3UOF8"]=960,["M929"]=1260},
  ["30mm 2A42M (BMPT AP)"]={["3UBR11"]=1260},
  ["30mm 2A42M (BMPT HE)"]={["3UOF23 VT"]=960,["3UOF23 PD"]=960},
  ["30mm 2A72"]={["3UBR11"]=1260,["3UOF8"]=960,["3UBR8"]=1120},
  ["30mm AG-30"]={["VOG-17M"]=185},
  ["30mm AGS-17"]={["VOG-17M"]=185},
  ["30mm GSh-30-2K"]={["HEF-I "]=845,["AP-T "]=845},
  ["30mm HSS 831L"]={["HE"]=1080,["APHE"]=1080},
  ["30mm L21A1"]={["HE-L13"]=1080,["APSE-L5"]=1080,["APDS-L14"]=1175},
  ["30mm M230E-1"]={["M789"]=801},
  ["30mm M230LF"]={["M789"]=839,["XM1211"]=839},
  ["30mm MK 30-2/ABM"]={["DM21 VT"]=1100,["MK266"]=1080,["DM33"]=1405,["DM21 PDD"]=1100},
  ["30mm Treemaster"]={["Mk310 VT"]=1235,["MK258"]=1430,["MK238"]=1080,["Mk310 PD"]=1235},
  ["30mm Type 625"]={["HE PDD"]=1100,["HE VT"]=1100,["HE"]=1100,["APDS"]=1345},
  ["30mm ZPL02"]={["DTY02-30"]=960,["DTC041A-30"]=1190},
  ["30mm ZPZ02"]={["HEF-I"]=960,["DTC10-30"]=1260},
  ["30mm ZTM-1"]={["3UBR11"]=1260,["3UOF8"]=960},
  ["30mm ZTM-2"]={["3UOF8"]=960,["3UBR11"]=1260},
  ["35mm Oerlikon KDA"]={["DM13"]=1175,["DM23"]=1400,["DM11A1"]=1175},
  ["35mm Oerlikon KDE"]={["DM23"]=1400,["DM11A1"]=1175},
  ["37mm M5"]={["M63 shell"]=792,["M51B1 shot"]=883},
  ["37mm M6"]={["M63 shell"]=792,["M51B1 shot"]=883},
  ["380mm RW61"]={["38 cm R Spgr.4581"]=150},
  ["3M7 Drakon"]={["3M7"]=228},
  ["40mm Akan m/70B"]={["slsgr m/90"]=988,["3P-HV VT"]=1100,["slpprj m/90"]=1465,["kulsgr m/90"]=1015,["slpprj m/01"]=1495,["3P-HV PF"]=1100,["3P-HV PD"]=1100},
  ["40mm Bofors L/70"]={["3P-HV VT"]=1100,["3P-HV PF"]=1100,["AP-T"]=1025,["3P-HV PD"]=1100},
  ["40mm Dual Automatic Gun M2"]={["AP-T"]=875,["FI-T"]=874},
  ["40mm MK-19"]={["M383"]=241,["M430A1"]=241},
  ["40mm QF 2-Pounder"]={["Shot Mk.IXB"]=792,["Shell Mk.1"]=792,["Shot APSV Mk.1"]=1280},
  ["45mm 20-K"]={["BR-240"]=760,["BR-240SP"]=757},
  ["5.56mm MG4"]={["AP"]=920},
  ["5.8mm QJT"]={["AP"]=865},
  ["50 mm KwK39"]={["Sprgr. 38"]=870,["PzGr 39"]=835},
  ["57mm 2A90"]={["3UO8"]=1000,["OR-281U"]=1000,["BR-281U"]=1000,["3UBM22"]=1500},
  ["57mm 2A94"]={["3UBM21"]=1350,["VBOF-57"]=300},
  ["57mm AU-220"]={["BR-281U"]=1000,["OR-281U"]=1000},
  ["57mm Ch-51M"]={["BR-271M"]=1020,["O-271"]=700},
  ["57mm L/70"]={["57х438 HE-VT"]=1020,["57х438 AP-T"]=950,["57х438 APFS-DS"]=1350,["57х438 HE-T"]=1020,["57х438 SAP-T"]=950},
  ["57mm M1"]={["M86"]=822,["M70"]=900},
  ["57mm S-68"]={["OR-281U"]=1000,["BR-281U"]=1000,["UOR-281U"]=1000},
  ["57mm ZiS-4"]={["BR-271"]=990,["O-271"]=700},
  ["60 mm Soltam Mortar"]={["Blast-frag Medium Charge"]=80,["Smoke"]=30,["Blast-frag High Charge"]=150,["Blast-frag Low Charge"]=30},
  ["60mm IMI HVMS"]={["OTO HE"]=1000,["M-54"]=1620,["OTO HE-VT"]=1000},
  ["7.2 in T37"]={["7.2 in T37"]=49},
  ["7.5 cm PaK 40 L/46"]={["Sprgr. 34"]=550,["PzGr 39"]=750,["PzGr 40"]=930},
  ["7.5 cm StuK40 L48 cannon"]={["Sprgr. 34"]=550,["PzGr 39"]=750,["PzGr 40"]=930},
  ["7.5 mm MAC 31"]={["AP"]=900},
  ["7.5cm KwK44/1 L/70"]={["PzGr 40/42"]=1120,["PzGr 39/42"]=935,["Sprgr.42"]=700},
  ["7.5cm PaK39 L48 cannon"]={["Sprgr. 34"]=550,["PzGr 39"]=750,["Hl.Gr 38B"]=450},
  ["7.62 Beretta MG42/59"]={["AP"]=820},
  ["7.62 mm FN MAG 60-40"]={["AP"]=853},
  ["7.62 mm L94A1"]={["AP"]=800},
  ["7.62mm A-A-F1N"]={["AP"]=640},
  ["7.62mm DT-28"]={["AP"]=640},
  ["7.62mm L37A1"]={["AP"]=800},
  ["7.62mm L37A2"]={["AP"]=800},
  ["7.62mm L3A1"]={["AP"]=853},
  ["7.62mm L8A1"]={["AP"]=800},
  ["7.62mm L8A2"]={["AP"]=800},
  ["7.62mm M134"]={["AP-T"]=800},
  ["7.62mm M1919A4"]={["AP"]=800},
  ["7.62mm M1919A4E1"]={["AP"]=800},
  ["7.62mm M1919E4"]={["AP"]=800},
  ["7.62mm M240"]={["AP"]=640},
  ["7.62mm M60D"]={["AP"]=800},
  ["7.62mm M60E2-1"]={["AP"]=800},
  ["7.62mm M73"]={["AP"]=625},
  ["7.62mm MG3"]={["AP"]=853},
  ["7.62mm NATTER"]={["AP"]=840},
  ["7.62mm PKT"]={["AP"]=800},
  ["7.62mm RP-46"]={["AP"]=640},
  ["7.62mm SGMT"]={["AP"]=800},
  ["7.62mm Type 59"]={["AP"]=640},
  ["7.62mm Type 74"]={["AP"]=640},
  ["7.62mm Type 86"]={["AP"]=750},
  ["7.62mm UKM 2000C"]={["AP"]=840},
  ["7.62mm ksp 39 C"]={["AP"]=720},
  ["7.62mm ksp 58"]={["AP"]=900},
  ["7.92 mm BESA"]={["AP"]=823},
  ["7.92mm MG34"]={["7.92×57mm"]=765},
  ["7.92mm StG 44"]={["7.92×33mm"]=690},
  ["73mm 2A28"]={["PG-9"]=665,["OG-9"]=290},
  ["75 mm KwK40 L48"]={["Hl.Gr 38B"]=450,["PzGr 39"]=750,["PzGr 40"]=930,["Sprgr. L/4.5"]=550},
  ["75 mm KwK42"]={["PzGr 40/42"]=1120,["Sprgr.42"]=700,["PzGr 39/42"]=935,["Pfeilgeschoss 3/7,5"]=1400},
  ["75 mm KwK44"]={["Hl.Gr 38C"]=450,["Sprgr. 34"]=550},
  ["75mm ADMAG"]={["XM884 Proxy-Fuze"]=924,["XM885"]=1463,["XM884"]=924},
  ["75mm M1897A4"]={["M61 shot"]=618,["M89"]=259,["M48 shell"]=463},
  ["75mm M2"]={["M61 shot"]=618,["M89"]=259,["M48 shell"]=463},
  ["75mm M3"]={["M61 shot"]=618,["M89"]=259,["M48 shell"]=463},
  ["75mm M6"]={["M61 shot"]=618,["M64"]=603,["M48 shell"]=463},
  ["75mm OQF Mk.V"]={["M61 shot"]=618,["M89"]=259,["M48 shell"]=610},
  ["75mm SA50 L/57"]={["PCOT-51P"]=1000,["OE Mle 1951"]=753},
  ["76.2 mm D-56TM"]={["BR-354"]=655,["OF-350M"]=680,["BK-354M"]=700},
  ["76mm F-34"]={["BR-350B"]=655,["OF-350M"]=680},
  ["76mm M1"]={["M93 shot"]=1036,["M62 shot"]=792,["M88"]=274,["M42A1 shell"]=823},
  ["76mm M1A1C"]={["M93 shot"]=1036,["M62 shot"]=792,["M88"]=274,["M42A1 shell"]=823},
  ["76mm M32"]={["M331A2 shot"]=1257,["M361"]=274,["M352 shell"]=732},
  ["76mm M7"]={["M62 shot"]=792,["M93 shot"]=1036,["M42A1 shell"]=823},
  ["76mm QF 17-pounder"]={["Shot SV Mk.1"]=1204,["Shell Mk.1"]=883,["Shell SS Mk.1"]=229,["Shot Mk.8"]=883},
  ["77mm OQF Mk.II"]={["Shot SV Mk.1"]=1036,["Shell Mk.1"]=495,["Shot Mk.8"]=785},
  ["8.8 cm Pak 43/1"]={["PzGr 40/43"]=1130,["HI.Gr 39"]=600,["Sprgr.43"]=750,["PzGr 39/43"]=1000},
  ["8.8cm KwK43 L/71"]={["PzGr 40/43"]=1130,["HI.Gr 39"]=600,["Sprgr.43"]=750,["PzGr 39/43"]=1000},
  ["85mm 2A62"]={["3BK7"]=925,["3BM31"]=1600,["OF-372"]=1010},
  ["85mm D-58"]={["BR-372"]=1040,["OF-372"]=1010,["3BK7"]=925},
  ["85mm D-5S"]={["BR-365P"]=1050,["BR-365"]=792,["O-365K"]=785},
  ["85mm F-30"]={["BR-365P"]=1050,["BR-365"]=792,["O-365K"]=785},
  ["85mm ZIS-S-53"]={["BR-365P"]=1050,["BR-365"]=792,["O-365K"]=785},
  ["88 mm KwK36"]={["Sprgr. L/4.5"]=810,["PzGr 39"]=780},
  ["88 mm PaK 43/2 L/71"]={["PzGr 40/43"]=1130,["Sprgr.43"]=750,["PzGr 39/43"]=1000},
  ["88 mm PaK43/4 L/71"]={["PzGr 40/43"]=1130,["Sprgr.43"]=750,["PzGr 39/43"]=1000},
  ["8mm Breda M37"]={["AP"]=800},
  ["90mm D915"]={["OE 90 F1"]=650,["OFUM PH90-F2"]=645,["OCC 90-62"]=800},
  ["90mm M3"]={["M71 shell"]=823,["M304 shot"]=1021,["M348 shell"]=853,["M82 shot"]=853},
  ["90mm M41"]={["M332 shot"]=1249,["M431 shell"]=1216,["M71 shell"]=823,["M313"]=821},
  ["90mm T15E1"]={["T41"]=975,["T44 shot"]=1143,["T42 shell"]=975},
  ["90mm T15E2"]={["T41"]=975,["T44 shot"]=1143,["T42 shell"]=975},
  ["9M113 Konkurs"]={["9M113"]=208},
  ["9M113M Konkurs"]={["9M113M"]=208},
  ["9M114 Shturm"]={["9M114"]=550},
  ["9M120 Ataka"]={["9M120-1F"]=550,["9M120-1"]=550},
  ["9M127 Vikhr"]={["9M121 Vikhr"]=600,["9M121 Vikhr Proxy-Fuze"]=600},
  ["9M127M Vikhr-1"]={["9A4172 Vikhr-1"]=600,["9A4172 Vikhr-1 Proxy-Fuze"]=600},
  ["9M133 Kornet"]={["9M133"]=300,["9M133F-1"]=320},
  ["9M134 Bulat"]={["9M134"]=300},
  ["9M14M"]={["9M14M MCLOS"]=140},
  ["9M17M"]={["9M17M MCLOS"]=230},
  ["9M311"]={["9M311"]=910},
  ["9M37M"]={["9M37M"]=700},
  ["9M39"]={["9M39"]=1000},
  ["AGM-114K Hellfire II"]={["AGM-114K Hellfire II"]=425},
  ["ATO-41 Flamethrower"]={["Napalm"]=60},
  ["B-13L"]={["S-13OF"]=530},
  ["BGM-71A TOW"]={["TOW"]=299},
  ["BGM-71C I-TOW"]={["I-TOW"]=296},
  ["BGM-71F TOW 2A/B"]={["TOW-2A"]=329,["TOW-2B"]=309},
  ["Brimstone"]={["Brimstone Fire & Forget Mode"]=325,["Brimstone Manual Guide Mode"]=325},
  ["Bulsae-3"]={["9D135"]=300,["9T135"]=320},
  ["FB-10A"]={["FB-10A"]=700},
  ["FGM-148"]={["FGM-148F"]=430},
  ["FIM-92K Stinger"]={["FIM-92K Stinger"]=670},
  ["FZ225"]={["FZ71"]=739},
  ["GT-3B 105mm"]={["DM12"]=1174,["DM512"]=732,["DM23"]=1455},
  ["Grenade Mortar"]={["Frag"]=30,["Smoke"]=30},
  ["H5 Flamethrower"]={["Napalm"]=40},
  ["HERO-120"]={["Anti-Tank drone"]=50},
  ["HJ-10"]={["HJ-10 Manual Guide Mode"]=150,["HJ-10 Fire & Forget Mode"]=150},
  ["L7A1 105mm"]={["Shell L35"]=720,["Shot L28A1"]=1478},
  ["L7A3 105mm"]={["DM13"]=1478,["DM33"]=1455,["DM23"]=1455,["DM12"]=1174,["DM512"]=732},
  ["L9A1 165mm"]={["L33A1"]=259},
  ["LAU-105A"]={["AIM-9M"]=1000},
  ["LFK SS.11"]={["LFK S.11"]=220},
  ["LOSAT/MGM-166"]={["MGM-166"]=1520},
  ["Loitering Drone"]={["Anti-Tank drone"]=50},
  ["M2 Howitzer"]={["M66"]=304,["M48 shell"]=381},
  ["M229 Hydra-70"]={["M247 Rocket"]=739},
  ["M8 Rocket"]={["HE Rockets"]=260},
  ["MIM146 Launcher"]={["MIM146 Anti-Tank Mode"]=1027,["MIM146 Anti-Air Mode"]=1027},
  ["Milan 2"]={["Milan 2"]=185},
  ["Milan ER"]={["Milan ER"]=200},
  ["QN201DD"]={["QN201DD"]=450},
  ["QN502CDD"]={["ATGM"]=125},
  ["RP-3 Rocket"]={["RP-3"]=260},
  ["Rbs 56 ATGM"]={["BILL 2 Impact"]=250,["BILL 2 OTA"]=250},
  ["Rocketetet"]={["HE Rockets"]=150},
  ["S-8KO"]={["S-8KOM"]=650},
  ["Spike ATGM"]={["Spike LR F&F"]=180,["Spike LR Manual Mode"]=180},
  ["Spike-LR2MR"]={["Spike LR2 Manual Mode"]=180,["Spike LR2 F&F"]=180},
  ["Stugna-P"]={["R-2"]=320},
  ["TT-250 Tank Torpedo"]={["TT-250 Rocket"]=135},
  ["Type 79 ATGM"]={["Type 79"]=200,["Type 79 ASM"]=200},
  ["UB-32"]={["S-5K1"]=650},
  ["X7 Rotkäppchen"]={["HEAT ATGM"]=100},
}
_G.SahurGuided = {
  ["100mm 2A70"]={["9M117"]=true},
  ["100mm 2A70M"]={["9M117M1"]=true},
  ["100mm 2A70M BMD-4M"]={["9M117M1"]=true},
  ["100mm D-10TS2"]={["9M117"]=true},
  ["100mm ZPL04"]={["APS03"]=true},
  ["115mm U-5TS"]={["9M117"]=true},
  ["120mm GIAT CN120-26 F1"]={["POLYNEGE"]=true},
  ["120mm IMI MG251"]={["LAHAT"]=true},
  ["120mm KBM-2"]={["KONUS"]=true},
  ["125 mm KBA-3"]={["KOMBAT ATGM"]=true},
  ["125mm 2A46M"]={["9M119"]=true},
  ["125mm 2A46M-1"]={["9M119M1"]=true,["9M112"]=true,["KOMBAT ATGM"]=true,["9M119"]=true},
  ["125mm 2A46M-5"]={["9M119M1"]=true,["9M119"]=true},
  ["125mm 2A46M-5 Bustle AP"]={["9M119M1"]=true},
  ["125mm 2A47"]={["9M112"]=true},
  ["125mm 2A75"]={["9M119M1"]=true},
  ["125mm 2A82"]={["9M119M1"]=true},
  ["125mm 2A82-1M"]={["3UBK21"]=true},
  ["125mm D-126"]={["Rubin"]=true},
  ["125mm Type 99A"]={["GP125"]=true},
  ["125mm ZPT98"]={["GP125"]=true},
  ["152mm M162"]={["MGM-51B Shillelagh"]=true},
  ["152mm M81E1"]={["MGM-51B Shillelagh"]=true},
  ["152mm XM150E5"]={["MGM-51C"]=true},
  ["302 Anti-tank Missile"]={["302 Anti-tank Missile"]=true},
  ["3M7 Drakon"]={["3M7"]=true},
  ["9M113 Konkurs"]={["9M113"]=true},
  ["9M113M Konkurs"]={["9M113M"]=true},
  ["9M114 Shturm"]={["9M114"]=true},
  ["9M120 Ataka"]={["9M120-1"]=true},
  ["9M127 Vikhr"]={["9M121 Vikhr"]=true},
  ["9M127M Vikhr-1"]={["9A4172 Vikhr-1"]=true},
  ["9M133 Kornet"]={["9M133"]=true,["9M133F-1"]=true},
  ["9M134 Bulat"]={["9M134"]=true},
  ["9M14M"]={["9M14M MCLOS"]=true},
  ["9M17M"]={["9M17M MCLOS"]=true},
  ["9M311"]={["9M311"]=true},
  ["9M37M"]={["9M37M"]=true},
  ["9M39"]={["9M39"]=true},
  ["AGM-114K Hellfire II"]={["AGM-114K Hellfire II"]=true},
  ["BGM-71A TOW"]={["TOW"]=true},
  ["BGM-71C I-TOW"]={["I-TOW"]=true},
  ["BGM-71F TOW 2A/B"]={["TOW-2A"]=true,["TOW-2B"]=true},
  ["Brimstone"]={["Brimstone Fire & Forget Mode"]=true,["Brimstone Manual Guide Mode"]=true},
  ["Bulsae-3"]={["9D135"]=true},
  ["FB-10A"]={["FB-10A"]=true},
  ["FGM-148"]={["FGM-148F"]=true},
  ["FIM-92K Stinger"]={["FIM-92K Stinger"]=true},
  ["HERO-120"]={["Anti-Tank drone"]=true},
  ["HJ-10"]={["HJ-10 Manual Guide Mode"]=true,["HJ-10 Fire & Forget Mode"]=true},
  ["LAU-105A"]={["AIM-9M"]=true},
  ["LFK SS.11"]={["LFK S.11"]=true},
  ["LOSAT/MGM-166"]={["MGM-166"]=true},
  ["Loitering Drone"]={["Anti-Tank drone"]=true},
  ["MIM146 Launcher"]={["MIM146 Anti-Tank Mode"]=true,["MIM146 Anti-Air Mode"]=true},
  ["Milan 2"]={["Milan 2"]=true},
  ["Milan ER"]={["Milan ER"]=true},
  ["QN201DD"]={["QN201DD"]=true},
  ["QN502CDD"]={["ATGM"]=true},
  ["Rbs 56 ATGM"]={["BILL 2 OTA"]=true},
  ["Spike ATGM"]={["Spike LR F&F"]=true,["Spike LR Manual Mode"]=true},
  ["Spike-LR2MR"]={["Spike LR2 Manual Mode"]=true,["Spike LR2 F&F"]=true},
  ["Stugna-P"]={["R-2"]=true},
  ["Type 79 ATGM"]={["Type 79"]=true},
  ["X7 Rotkäppchen"]={["HEAT ATGM"]=true},
}
]=],
["sahur/data/roundtypes.lua"] = [=[
_G.SahurRoundTypes = {
["12.7mm API-T"]="MG",
["120-HE"]="HE",
["120-HEAT"]="HEATFS",
["120-II"]="APFSDS",
["125-II"]="APFSDS",
["140mm Pz Kan HL Pat MZ HEAT-MP PD"]="HEATFS",
["140mm Pz Kan HL Pat MZ HEAT-MP VT"]="TIME",
["140mm Pz Kan Pfeil Pat APFSDS"]="APFSDS",
["15 cm Wurfgranate 41 Spreng"]="ROCKET",
["2VG11"]="SAPHE",
["302 Anti-tank Missile"]="ATGM",
["38 cm R Spgr.4581"]="HE",
["3BK-10"]="HEATFS",
["3BK-5"]="HEATFS",
["3BK-9"]="HEATFS",
["3BK12M"]="HEATFS",
["3BK15M"]="HEATFS",
["3BK17M"]="HEATFS",
["3BK18M"]="HEATFS",
["3BK20"]="HEATFS",
["3BK4"]="HEATFS",
["3BK7"]="HEATFS",
["3BM-11"]="APDS",
["3BM-8"]="APDS",
["3BM15"]="APFSDS",
["3BM16"]="APFSDS",
["3BM22"]="APFSDS",
["3BM28"]="APFSDS",
["3BM3"]="APFSDS",
["3BM31"]="APFSDS",
["3BM32"]="APFSDS",
["3BM42"]="APFSDS",
["3BM46"]="APFSDS",
["3BM59"]="APFSDS",
["3BM6"]="APFSDS",
["3BM60"]="APFSDS",
["3BM69"]="APFSDS",
["3BM70"]="APFSDS",
["3BM9"]="APFSDS",
["3M7"]="ATGM",
["3OF11"]="HE",
["3OF18"]="HE",
["3OF26"]="HE",
["3OF26 PD"]="HE",
["3OF26 VT"]="TIME",
["3OF31"]="HE",
["3OF32"]="HE",
["3OF45 High Charge"]="HE",
["3OF45 Low Charge"]="HE",
["3OF45 Medium Charge"]="HE",
["3OF45 Proxy High Charge"]="PROX",
["3OF45 Proxy Low Charge"]="PROX",
["3OF45 Proxy Medium Charge"]="PROX",
["3OF56 High Charge"]="HE",
["3OF56 Low Charge"]="HE",
["3OF56 Medium Charge"]="HE",
["3OF61 High Charge"]="HE",
["3OF61 Low Charge"]="HE",
["3OF61 Medium Charge"]="HE",
["3OF61 Proxy High Charge"]="PROX",
["3OF61 Proxy Low Charge"]="PROX",
["3OF61 Proxy Medium Charge"]="PROX",
["3OF70"]="HE",
["3OF70-1"]="PROX",
["3P-HV PD"]="HE",
["3P-HV PF"]="PROX",
["3P-HV VT"]="TIME",
["3UBK21"]="ATGM",
["3UBM21"]="APFSDS",
["3UBM22"]="APFSDS",
["3UBR11"]="APFSDS",
["3UBR8"]="APDS",
["3UO8"]="TIME",
["3UOF23 PD"]="HE",
["3UOF23 VT"]="TIME",
["3UOF8"]="HE",
["3VO15 High Charge"]="CLUSTER",
["3VO15 Low Charge"]="CLUSTER",
["3VO15 Medium Charge"]="CLUSTER",
["3VO28 High Charge"]="CLUSTER",
["3VO28 Low Charge"]="CLUSTER",
["3VO28 Medium Charge"]="CLUSTER",
["3VOF34 High Charge"]="HE",
["3VOF34 Low Charge"]="HE",
["3VOF34 Medium Charge"]="HE",
["57х438 AP-T"]="AP",
["57х438 APFS-DS"]="APFSDS",
["57х438 HE-T"]="HE",
["57х438 HE-VT"]="PROX",
["57х438 SAP-T"]="SAPHE",
["7.2 in T37"]="ROCKET",
["7.92×33mm"]="MG",
["7.92×57mm"]="MG",
["9A4172 Vikhr-1"]="ATGM",
["9A4172 Vikhr-1 Proxy-Fuze"]="ATGM",
["9D135"]="ATGM",
["9M112"]="ATGM",
["9M113"]="ATGM",
["9M113M"]="ATGM",
["9M114"]="ATGM",
["9M117"]="ATGM",
["9M117M1"]="ATGM",
["9M119"]="ATGM",
["9M119M1"]="ATGM",
["9M120-1"]="ATGM",
["9M120-1F"]="ATGM",
["9M121 Vikhr"]="ATGM",
["9M121 Vikhr Proxy-Fuze"]="ATGM",
["9M133"]="ATGM",
["9M133F-1"]="ATGM",
["9M134"]="ATGM",
["9M14M MCLOS"]="ATGM",
["9M17M MCLOS"]="ATGM",
["9M22/M21 HE-Frag"]="ROCKET",
["9M311"]="AAM",
["9M37M"]="AAM",
["9M39"]="AAM",
["9T135"]="ATGM",
["AGM-114K Hellfire II"]="ATGM",
["AI"]="MG",
["AIM-9M"]="AAM",
["AP"]="MG",
["AP-T"]="AP",
["AP-T "]="AP",
["APDS"]="APDS",
["APDS-L14"]="APDS",
["APFSDS"]="APFSDS",
["APFSDS/T"]="APFSDS",
["APHE"]="APHE",
["API HV"]="AP",
["API-T"]="MG",
["API-T "]="AP",
["APS03"]="ATGM",
["APSE-L5"]="APHE",
["ATGM"]="ATGM",
["Anti-Tank drone"]="ATGM",
["B-420"]="APHE",
["BILL 2 Impact"]="ATGM",
["BILL 2 OTA"]="ATGM",
["BK-354M"]="HEATFS",
["BR-240"]="APHE",
["BR-240SP"]="AP",
["BR-271"]="APHE",
["BR-271M"]="APHE",
["BR-281U"]="APHE",
["BR-350B"]="APHE",
["BR-354"]="APHE",
["BR-365"]="APHE",
["BR-365P"]="APCR",
["BR-372"]="APHE",
["BR-412B"]="APHE",
["BR-412D"]="APHE",
["BR-471"]="APHE",
["BR-471B"]="APHE",
["BR-471D"]="APHE",
["BR-472"]="APHE",
["BR-482B"]="APHE",
["BR-540B"]="APHE",
["BST"]="MG",
["BUR"]="HE",
["Blast fragmentation"]="ROCKET",
["Blast-frag High Charge"]="HE",
["Blast-frag Low Charge"]="HE",
["Blast-frag Medium Charge"]="HE",
["Brimstone Fire & Forget Mode"]="ATGM",
["Brimstone Manual Guide Mode"]="ATGM",
["CL3143"]="APFSDS",
["DBTSU AP"]="AP",
["DBTSU HE"]="HE",
["DM11 PD"]="HE",
["DM11 PDD"]="SAPHE",
["DM11 VT"]="TIME",
["DM11A1"]="HE",
["DM12"]="HEATFS",
["DM121 High Charge"]="HE",
["DM121 Low Charge"]="HE",
["DM121 Medium Charge"]="HE",
["DM121 Proxy High Charge"]="PROX",
["DM121 Proxy Low Charge"]="PROX",
["DM121 Proxy Medium Charge"]="PROX",
["DM12A1"]="HEATFS",
["DM13"]="APFSDS",
["DM21 PDD"]="APHE",
["DM21 VT"]="TIME",
["DM23"]="APDS",
["DM33"]="APFSDS",
["DM43"]="APCR",
["DM43A1"]="APFSDS",
["DM512"]="HESH",
["DM51A2"]="HE",
["DM53"]="APFSDS",
["DM53A1"]="APFSDS",
["DM63"]="APDS",
["DM702A1"]="ATGM",
["DM702A1 High Charge"]="SMOKE",
["DM702A1 Low Charge"]="SMOKE",
["DM702A1 Medium Charge"]="SMOKE",
["DM73"]="APFSDS",
["DTB-125"]="HE",
["DTB12-125 PD"]="HE",
["DTB12-125 VT"]="TIME",
["DTC041A-30"]="APFSDS",
["DTC10-125"]="APFSDS",
["DTC10-30"]="APFSDS",
["DTP-125"]="HEATFS",
["DTW2-105"]="APFSDS",
["DTY02-30"]="HE",
["FB-10A"]="AAM",
["FGM-148F"]="ATGM",
["FI"]="HE",
["FI-T"]="APHE",
["FIM-92K Stinger"]="AAM",
["FZ71"]="ROCKET",
["Frag"]="HE",
["GP125"]="ATGM",
["Grifel-1"]="APFSDS",
["Grifel-2"]="APFSDS",
["Grifel-3"]="HE",
["Grifel-3 PD"]="HE",
["Grifel-3 VT"]="TIME",
["HE"]="HE",
["HE PD"]="HE",
["HE PDD"]="APHE",
["HE Rockets"]="ROCKET",
["HE VT"]="TIME",
["HE-L13"]="HE",
["HE-T"]="HE",
["HEAT ATGM"]="ATGM",
["HEDP"]="HEAT",
["HEF-I"]="HE",
["HEF-I "]="HE",
["HEI"]="HE",
["HI.Gr 39"]="HEAT",
["HJ-10 Fire & Forget Mode"]="ATGM",
["HJ-10 Manual Guide Mode"]="ATGM",
["HVAP"]="APCR",
["Hl.Gr 38B"]="HEAT",
["Hl.Gr 38C"]="HEAT",
["I-TOW"]="ATGM",
["IM HE-T PD"]="HE",
["IM HE-T PDD"]="SAPHE",
["Incendiary"]="INC",
["JM12A1"]="HEATFS",
["JM33"]="APFSDS",
["JoHEAT"]="HEATFS",
["K274"]="APFSDS",
["K276"]="APFSDS",
["K277"]="HEATFS",
["K279"]="APFSDS",
["K280 PD"]="HEATFS",
["K280 Proxy"]="PROX",
["KE-W"]="APFSDS",
["KOMBAT ATGM"]="ATGM",
["KONUS"]="ATGM",
["KSTAM-II"]="ATGM",
["KiAP"]="APFSDS",
["L26A1"]="APFSDS",
["L27A1"]="APFSDS",
["L33A1"]="HESH",
["LAHAT"]="ATGM",
["LFK S.11"]="ATGM",
["M-54"]="APFSDS",
["M1 shell"]="HE",
["M1028"]="CANISTER",
["M107 High Charge"]="HE",
["M107 High Charge PF"]="PROX",
["M107 High Charge VT"]="TIME",
["M107 Low Charge"]="HE",
["M107 Low Charge PF"]="PROX",
["M107 Low Charge VT"]="TIME",
["M107 Medium Charge"]="HE",
["M107 Medium Charge PF"]="PROX",
["M107 Medium Charge VT"]="TIME",
["M110 High Charge"]="SMOKE",
["M110 Low Charge"]="SMOKE",
["M110 Medium Charge"]="SMOKE",
["M111"]="APFSDS",
["M1147 PD"]="HE",
["M1147 PDD"]="SAPHE",
["M1147 VT"]="TIME",
["M152"]="HEATFS",
["M156"]="HESH",
["M247 Rocket"]="ROCKET",
["M26A1 High Charge"]="CLUSTER",
["M26A1 Low Charge"]="CLUSTER",
["M26A1 Medium Charge"]="CLUSTER",
["M304 shot"]="APCR",
["M309"]="APFSDS",
["M313"]="SMOKE",
["M31A2 High Charge"]="ROCKET",
["M31A2 Low Charge"]="ROCKET",
["M31A2 Medium Charge"]="ROCKET",
["M331A2 shot"]="APDS",
["M332 shot"]="APCR",
["M338"]="APFSDS",
["M339 PD"]="HE",
["M339 PDD"]="SAPHE",
["M339 VT"]="TIME",
["M344A1"]="HEAT",
["M348 shell"]="HEATFS",
["M352 shell"]="HE",
["M361"]="SMOKE",
["M361A1"]="HESH",
["M383"]="HE",
["M393A2"]="HESH",
["M393A3"]="HESH",
["M3M PD"]="HE",
["M3M PDD"]="SAPHE",
["M3M VT"]="TIME",
["M409A1"]="HEAT",
["M413"]="APFSDS",
["M416"]="SMOKE",
["M42A1 shell"]="HE",
["M430A1"]="HEAT",
["M431 shell"]="HEATFS",
["M456"]="HEATFS",
["M456A1"]="HEATFS",
["M456A2"]="HEATFS",
["M48 shell"]="HE",
["M51B1 shot"]="AP",
["M53"]="AP",
["M56A3"]="HE",
["M61 shot"]="APHE",
["M62 shot"]="APHE",
["M625A1"]="CANISTER",
["M63 shell"]="HE",
["M64"]="SMOKE",
["M657A2"]="HE",
["M66"]="HEAT",
["M67 shot"]="HEAT",
["M70"]="AP",
["M71 shell"]="HE",
["M728"]="APDS",
["M735"]="APFSDS",
["M774"]="APFSDS",
["M789"]="HEAT",
["M791"]="APDS",
["M792"]="HE",
["M82 shot"]="APHE",
["M829"]="APFSDS",
["M829A2"]="APFSDS",
["M829A3"]="APFSDS",
["M829A4"]="APFSDS",
["M830A1 PD"]="HEATFS",
["M830A1 Proxy"]="PROX",
["M833"]="APFSDS",
["M84"]="SMOKE",
["M86"]="APHE",
["M88"]="SMOKE",
["M89"]="SMOKE",
["M900"]="APFSDS",
["M919"]="APFSDS",
["M929"]="APFSDS",
["M93 shot"]="APCR",
["MGM-166"]="ATGM",
["MGM-51B Shillelagh"]="ATGM",
["MGM-51C"]="ATGM",
["MIM146 Anti-Air Mode"]="ATGM",
["MIM146 Anti-Tank Mode"]="ATGM",
["MK238"]="HE",
["MK258"]="APFSDS",
["MK266"]="HE",
["MKE MOD 290"]="APFSDS",
["MKE MOD 300"]="HE",
["MKE MOD 310"]="HEATFS",
["Milan 2"]="ATGM",
["Milan ER"]="ATGM",
["Mk310 PD"]="HE",
["Mk310 VT"]="TIME",
["Napalm"]="MG",
["O-271"]="HE",
["O-365K"]="HE",
["O-FUM-PH-105 F3"]="SMOKE",
["OCC 105 F3"]="HEATFS",
["OCC 120 G1"]="HEATFS",
["OCC 90-62"]="HEATFS",
["OE 105 F3"]="HE",
["OE 120 F1"]="HE",
["OE 90 F1"]="HE",
["OE Mle 1951"]="HE",
["OEFC F1"]="CANISTER",
["OF-350M"]="HE",
["OF-372"]="HE",
["OF-412"]="HE",
["OF-420"]="HE",
["OF-471"]="HE",
["OF-472"]="HE",
["OF-482M"]="HE",
["OF-530"]="HE",
["OF-540"]="HE",
["OFL 105 F3"]="APFSDS",
["OFL 120 F1"]="APFSDS",
["OFL 120 F2"]="APFSDS",
["OFUM PH90-F2"]="SMOKE",
["OG-9"]="HE",
["OR-281U"]="HE",
["OTO HE"]="HE",
["OTO HE-VT"]="PROX",
["P99 TAPNA"]="APFSDS",
["PB-35"]="SAPHE",
["PCOT-51P"]="AP",
["PG-9"]="HEAT",
["POLYNEGE"]="ATGM",
["Paulina AP-T"]="AP",
["Pfeilgeschoss 3/7,5"]="APFSDS",
["PzGr 39"]="APHE",
["PzGr 39/42"]="APHE",
["PzGr 39/43"]="APHE",
["PzGr 40"]="APCR",
["PzGr 40/42"]="APCR",
["PzGr 40/43"]="APCR",
["PzGr 43"]="APHE",
["PzGr. 39"]="APHE",
["QN201DD"]="ATGM",
["R-2"]="ATGM",
["RGB-60"]="ROCKET",
["RP-3"]="ROCKET",
["Rh31"]="HE",
["Rubin"]="ATGM",
["Ryś"]="APFSDS",
["S-13OF"]="ROCKET",
["S-5K1"]="ROCKET",
["S-8KOM"]="ROCKET",
["SHARD®"]="APFSDS",
["Shell L1"]="HESH",
["Shell L31A7"]="HESH",
["Shell L34A2"]="SMOKE",
["Shell L35"]="HESH",
["Shell Mk.1"]="APHE",
["Shell SS Mk.1"]="SMOKE",
["Shot APSV Mk.1"]="APCR",
["Shot L15A3"]="APDS",
["Shot L23A1"]="APFSDS",
["Shot L28A1"]="APDS",
["Shot Mk.8"]="AP",
["Shot Mk.IXB"]="AP",
["Shot SV Mk.1"]="APDS",
["Smoke"]="SMOKE",
["Spike LR F&F"]="ATGM",
["Spike LR Manual Mode"]="ATGM",
["Spike LR2 F&F"]="ATGM",
["Spike LR2 Manual Mode"]="ATGM",
["Sprgr. 34"]="HE",
["Sprgr. 38"]="HE",
["Sprgr. L/4.4"]="HE",
["Sprgr. L/4.5"]="HE",
["Sprgr. L/5"]="HE",
["Sprgr.42"]="HE",
["Sprgr.43"]="HE",
["T13"]="APHE",
["T152"]="HESH",
["T267"]="HEAT",
["T29E3"]="APCR",
["T30E1"]="HE",
["T41"]="APHE",
["T42 shell"]="HE",
["T44 shot"]="APCR",
["T46"]="SMOKE",
["TOW"]="ATGM",
["TOW-2A"]="ATGM",
["TOW-2B"]="ATGM",
["TT-250 Rocket"]="ROCKET",
["Thermobaric"]="TBG",
["Type 10"]="APFSDS",
["Type 75"]="HESH",
["Type 79"]="ATGM",
["Type 79 ASM"]="ATGM",
["Type 91"]="HEATFS",
["Type 93"]="APFSDS",
["UOR-281U"]="PROX",
["UnHE"]="HE",
["VBOF-57"]="HESH",
["VOG-17M"]="HE",
["XH 45"]="APFSDS",
["XM1211"]="PROX",
["XM578E4"]="APFSDS",
["XM884"]="HE",
["XM884 Proxy-Fuze"]="PROX",
["XM885"]="APFSDS",
["XM964"]="APFSDS",
["XM965 PD"]="HEATFS",
["XM965 Proxy"]="PROX",
["akr 32/41"]="HE",
["hkr 42/C"]="HEAT",
["kulsgr m/90"]="PROX",
["rökgr m/61"]="SMOKE",
["slpprj m/01"]="APFSDS",
["slpprj m/66"]="APDS",
["slpprj m/80"]="APFSDS",
["slpprj m/90"]="APFSDS",
["slsgr m/61A"]="HE",
["slsgr m/90"]="HE",
}
]=],
}
local VERSION = "2.0"
if _G.Sahur and _G.Sahur.stop then pcall(_G.Sahur.stop) end
if readfile then
    _G.Swangy, _G.Obsidian = nil, nil
    _G.SwangySaveManager, _G.ObsidianSaveManager = nil, nil
    _G.SahurI18N, _G.SahurESP, _G.SahurHUD, _G.SahurAim, _G.SahurMisc = nil, nil, nil, nil, nil
    _G.SahurTanks, _G.SahurHeli, _G.SahurMissile = nil, nil, nil
end
if not _G.SahurBundleRun then _G.SahurSrc, _G.SahurEntry, _G.SahurEntryURL = nil, nil, nil end
_G.SahurBundleRun = nil
local function need(globalName, path)
    if _G[globalName] then return _G[globalName] end
    local src = (_G.SahurSrc and _G.SahurSrc[path]) or readfile(path)
    assert(type(src) == "string" and #src > 100, "could not read " .. path)
    loadstring(src)()
    assert(_G[globalName], path .. " did not export _G." .. globalName)
    return _G[globalName]
end
local Library     = need("Swangy", "sahur/lib/Library.lua")
local I18N        = need("SahurI18N", "sahur/modules/i18n.lua")
need("SwangySaveManager", "sahur/lib/SaveManager.lua")
local SaveManager = _G.SwangySaveManager
local Tanks       = need("SahurTanks", "sahur/modules/tanks.lua")
local ESP         = need("SahurESP", "sahur/modules/esp.lua")
local HUD         = need("SahurHUD", "sahur/modules/hud.lua")
local Aim         = need("SahurAim", "sahur/modules/aimbot.lua")
local Misc        = need("SahurMisc", "sahur/modules/misc.lua")
local Heli        = need("SahurHeli", "sahur/modules/heli.lua")
local Missile     = need("SahurMissile", "sahur/modules/missile.lua")
local t           = I18N.t
local ACCENT = Color3.fromRGB(240, 24, 43)
local relabelers = {}
local function onRelabel(fn) relabelers[#relabelers + 1] = fn end
local function relabelAll() for _, fn in ipairs(relabelers) do pcall(fn) end end
local Window = Library:CreateWindow({
    Title = "sahur",
    Width = 720,
    Height = 600,
    Center = true,
    ToggleKeybind = "LeftAlt",
    NotifySide = "Right",
    Accent = ACCENT,
})
Library:SetAccent(ACCENT)
Library:SetWatermark(false)
local function addTab(key, iconKey)
    local tab = Window:AddTab(t(key), iconKey)
    onRelabel(function() tab:SetName(t(key)) end)
    return tab
end
local Tabs = {
    Aimbot   = addTab("tab_aimbot", "aimbot"),
    ESP      = addTab("tab_esp", "esp"),
    Misc     = addTab("tab_misc", "misc"),
    Config   = addTab("tab_config", "config"),
    Settings = addTab("tab_settings", "settings"),
}
local function group(tab, side, nameKey)
    local g = tab:AddGroupbox({ Side = side, Name = t(nameKey) })
    onRelabel(function() g.name = t(nameKey) end)
    return g
end
local function label(g, key)
    local el = g:AddLabel({ Text = t(key), DoesWrap = true })
    onRelabel(function() el:SetText(t(key)) end)
    return el
end
local MiscG = group(Tabs.Misc, "Left", "grp_misc")
local heliTog = MiscG:AddToggle("misc_heli", {
    Text = t("misc_heli"), Default = Heli.Config.Enabled,
    Callback = function(v) Heli.Config.Enabled = v end,
})
onRelabel(function() heliTog:SetText(t("misc_heli")) end)
heliTog:AddColorPicker("misc_heli_color", {
    Title = t("misc_heli_color"), Default = Heli.Config.Color,
    Callback = function(c) Heli.SetColor(c) end,
})
local markerDD = MiscG:AddDropdown("misc_heli_marker", {
    Text = t("misc_heli_marker"), Values = { "+", "Circle", "— —" }, Default = "+",
    Callback = function(v) Heli.Config.Marker = v end,
})
onRelabel(function() markerDD:SetText(t("misc_heli_marker")) end)
local mslTog = MiscG:AddToggle("misc_missile", {
    Text = t("misc_missile"), Default = Missile.Config.Enabled,
    Callback = function(v) Missile.Config.Enabled = v end,
})
onRelabel(function() mslTog:SetText(t("misc_missile")) end)
local AimG = group(Tabs.Aimbot, "Left", "grp_aimbot")
local function aimToggle(id, key, field)
    local el = AimG:AddToggle(id, {
        Text = t(key), Default = Aim.Config[field],
        Callback = function(v) Aim.Config[field] = v end,
    })
    onRelabel(function() el:SetText(t(key)) end)
    return el
end
local function aimSlider(id, key, field, mn, mx, rnd, suf)
    local el = AimG:AddSlider(id, {
        Text = t(key), Default = Aim.Config[field], Min = mn, Max = mx, Rounding = rnd, Suffix = suf,
        Callback = function(v) Aim.Config[field] = v end,
    })
    onRelabel(function() el:SetText(t(key)) end)
    return el
end
aimToggle("aim_enabled", "aim_enabled", "Enabled")
local aimKey = AimG:AddKeyPicker("aim_key", {
    Text = t("aim_key"), Default = "MB5", CaptureOnly = true,
    ChangedCallback = function(el) Aim.Config.Key = el.vk end,
})
onRelabel(function() aimKey:SetText(t("aim_key")) end)
Aim.Config.Key = aimKey.vk or Aim.Config.Key
local tgtDD = AimG:AddDropdown("aim_target", {
    Text = t("aim_target"), Values = { "Ammo", "Nearest ammo", "Engine", "Crew", "Center" }, Default = "Ammo",
    Callback = function(v) v = tostring(v); Aim.Config.Target = (v == "Nearest ammo") and "ammonear" or v:lower() end,
})
onRelabel(function() tgtDD:SetText(t("aim_target")) end)
aimSlider("aim_fov", "aim_fov", "FOV", 10, 500, 1, "px")
aimSlider("aim_smooth", "aim_smooth", "Smooth", 1, 40, 1, "")
local showFov = aimToggle("aim_showfov", "aim_showfov", "ShowFOV")
showFov:AddColorPicker("aim_fov_color", {
    Title = t("aim_fov_color"), Default = ACCENT,
    Callback = function(c) Aim.SetFovColor(c) end,
})
aimToggle("aim_teamcheck", "aim_teamcheck", "TeamCheck")
aimToggle("aim_sticky", "aim_sticky", "Sticky")
aimToggle("aim_reloadpause", "aim_reloadpause", "ReloadPause")
aimToggle("aim_reticle", "aim_reticle", "ReticleAim")
aimToggle("aim_hill", "aim_hill", "HillLogic")
aimToggle("aim_classic", "aim_classic", "ClassicAim")
aimToggle("aim_hulldamp", "aim_hulldamp", "HullDamping")
aimToggle("aim_predict", "aim_predict", "Predict")
aimSlider("aim_deadzone", "aim_deadzone", "Deadzone", 0, 20, 1, "px")
local EspG = group(Tabs.ESP, "Left", "grp_tank_esp")
local function espToggle(id, key, field)
    local el = EspG:AddToggle(id, {
        Text = t(key),
        Default = ESP.Config[field],
        Callback = function(v) ESP.Config[field] = v end,
    })
    onRelabel(function() el:SetText(t(key)) end)
    return el
end
espToggle("esp_enabled", "esp_enabled", "Enabled")
espToggle("esp_teamcheck", "esp_teamcheck", "TeamCheck")
local espCols, espAlpha = ESP.colors(), ESP.alphas()
local function colorOn(el, id, key, which)
    el:AddColorPicker(id, { Title = t(key), Default = espCols[which], Transparency = 1 - (espAlpha[which] or 1),
        Callback = function(c, a) ESP.SetColor(which, c, a) end })
end
colorOn(espToggle("esp_box", "esp_box", "Box"), "esp_col_box", "esp_col_box", "Box")
local boxStyle = EspG:AddDropdown("esp_boxstyle", {
    Text = t("esp_boxstyle"), Values = { "Full", "Corners", "Filled" }, Default = ESP.Config.BoxStyle,
    Callback = function(v) ESP.Config.BoxStyle = tostring(v) end,
})
onRelabel(function() boxStyle:SetText(t("esp_boxstyle")) end)
colorOn(espToggle("esp_names", "esp_names", "Names"), "esp_col_name", "esp_col_name", "Name")
espToggle("esp_class", "esp_class", "Class")
colorOn(espToggle("esp_distance", "esp_distance", "Distance"), "esp_col_dist", "esp_col_dist", "Distance")
colorOn(espToggle("esp_crewcount", "esp_crewcount", "CrewCount"), "esp_col_crew", "esp_col_crew", "Crew")
colorOn(espToggle("esp_reload", "esp_reload", "Reload"), "esp_col_reload", "esp_col_reload", "Reload")
local maxDistSlider = EspG:AddSlider("esp_maxdist", {
    Text = t("esp_maxdist"),
    Default = ESP.Config.MaxDist,
    Min = 100, Max = 8000, Rounding = 1, Suffix = "m",
    Callback = function(v) ESP.Config.MaxDist = v end,
})
onRelabel(function() maxDistSlider:SetText(t("esp_maxdist")) end)
local ChamsG = group(Tabs.ESP, "Right", "grp_tank_chams")
local function chamsToggle(id, key, field)
    local el = ChamsG:AddToggle(id, {
        Text = t(key), Default = ESP.Config[field],
        Callback = function(v) ESP.Config[field] = v end,
    })
    onRelabel(function() el:SetText(t(key)) end)
    return el
end
colorOn(chamsToggle("chams_ammo", "chams_ammo", "Ammo"), "chams_col_ammo", "chams_col_ammo", "Ammo")
colorOn(chamsToggle("chams_engine", "chams_engine", "Engine"), "chams_col_engine", "chams_col_engine", "Engine")
colorOn(chamsToggle("chams_crew", "chams_crew", "Crew"), "chams_col_crew", "chams_col_crew", "CrewChams")
colorOn(chamsToggle("chams_barrel", "chams_barrel", "Barrel"), "chams_col_barrel", "chams_col_barrel", "Barrel")
colorOn(chamsToggle("chams_tracks", "chams_tracks", "Tracks"), "chams_col_tracks", "chams_col_tracks", "Tracks")
chamsToggle("chams_infov", "chams_infov", "ChamsInFov")
local chamsBox = ChamsG:AddToggle("chams_box", {
    Text = t("chams_box"), Default = ESP.Config.ChamsBox,
    Callback = function(v) ESP.Config.ChamsBox = v end,
})
onRelabel(function() chamsBox:SetText(t("chams_box")) end)
local chamsDist = ChamsG:AddSlider("chams_dist", {
    Text = t("chams_dist"), Default = ESP.Config.ChamsDist,
    Min = 50, Max = 2000, Rounding = 1, Suffix = "m",
    Callback = function(v) ESP.Config.ChamsDist = v end,
})
onRelabel(function() chamsDist:SetText(t("chams_dist")) end)
local Interface = group(Tabs.Settings, "Left", "grp_interface")
local menuKey = Interface:AddKeyPicker("sahur_menukey", {
    Text = t("menu_key"),
    Default = "LeftAlt",
    CaptureOnly = true,
    ChangedCallback = function(el) Library:SetMenuKey(el.vk) end,
})
onRelabel(function() menuKey:SetText(t("menu_key")) end)
local langNames = {}
for _, pair in ipairs(I18N.choices) do langNames[#langNames + 1] = pair[1] end
local function codeFor(name)
    for _, pair in ipairs(I18N.choices) do if pair[1] == name then return pair[2] end end
    return "en"
end
local function nameFor(code)
    for _, pair in ipairs(I18N.choices) do if pair[2] == code then return pair[1] end end
    return "English"
end
local langDD = Interface:AddDropdown("sahur_language", {
    Text = t("language"),
    Values = langNames,
    Default = nameFor(I18N:Get()),
    Callback = function(v)
        I18N:Set(codeFor(v))
        relabelAll()
        Library:Notify(t("lang_set"), 3, "sahur")
    end,
})
onRelabel(function() langDD:SetText(t("language")) end)
if #(Library.FontOrder or {}) > 0 then
    local fontDD = Interface:AddDropdown("sahur_font", {
        Text = t("font"),
        Values = Library.FontOrder,
        Default = Library.FontOrder[1],
        Callback = function(v) Library:SetFont(v) end,
    })
    onRelabel(function() fontDD:SetText(t("font")) end)
end
local Appearance = group(Tabs.Settings, "Left", "grp_appearance")
Appearance:AddColorPicker("sahur_accent", {
    Title = t("accent"),
    Default = ACCENT,
    Callback = function(c) Library:SetAccent(c); pcall(function() Misc.SetAccent(c) end) end,
})
Appearance:AddToggle("sahur_watermark", {
    Text = t("watermark"),
    Default = true,
    Callback = function(on) HUD.Config.Enabled = on end,
})
local Script = group(Tabs.Settings, "Right", "grp_script")
local unloadDesc = label(Script, "unload_desc")
Script:AddButton({ Text = t("unload"), Func = function() if _G.Sahur then _G.Sahur.stop() end end })
local verLbl = Script:AddLabel({ Text = t("version_lbl", VERSION), DoesWrap = true })
onRelabel(function() verLbl:SetText(t("version_lbl", VERSION)) end)
local About = group(Tabs.Config, "Left", "grp_about")
label(About, "about_desc")
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("sahur")
SaveManager:BuildConfigSection(Tabs.Config)
_G.Sahur = {
    version = VERSION,
    Library = Library,
    relabel = relabelAll,
    stop = function()
        pcall(function() ESP.stop() end)
        pcall(function() Aim.stop() end)
        pcall(function() HUD.stop() end)
        pcall(function() Misc.stop() end)
        pcall(function() Heli.stop() end)
        pcall(function() Missile.stop() end)
        pcall(function() Tanks.stop() end)
        pcall(function() Library:Unload() end)
    end,
}
if not _G.SahurQueued then
    _G.SahurQueued = true
    local entry = _G.SahurEntry or "sahur/main.lua"
    local url = _G.SahurEntryURL
    pcall(queue_on_teleport, [[
task.spawn(function()
    local t0 = os.clock()
    repeat task.wait(1) until (workspace:FindFirstChild("Map") and workspace:FindFirstChild("SpawnedVehicles")
        and game:GetService("Players").LocalPlayer) or os.clock() - t0 > 180
    task.wait(3)
    if _G.Sahur then return end
    local entry, url = ]] .. string.format("%q", entry) .. [[, ]] .. (url and string.format("%q", url) or "nil") .. [[
    local ok = pcall(function()
        if isfile and not isfile(entry) then error("no local file") end
        loadstring(readfile(entry))()
    end)
    if not ok and url and not _G.Sahur then pcall(function() loadstring(game:HttpGet(url))() end) end
end)
]])
end
Tanks.start()
ESP.start()
HUD.start()
Aim.start()
Misc.start()
Heli.start()
Missile.start()
Misc.SetAccent(ACCENT)
pcall(function() Aim.SetFovColor(ACCENT) end)
Window:SelectTab(Tabs.Settings)
Library:Notify(t("loaded"), 5, "sahur")
