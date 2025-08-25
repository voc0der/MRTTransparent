-- Makes MRT's "Raid cooldowns" frame transparent and hides its title.
-- v1.3: removes illegal '...' usage; pcall-guards all C API calls; stable out of raid/login.

local cfg = {
  alpha     = 0.0,               -- 0 fully transparent, 1 opaque
  hideTitle = true,              -- hide the "Raid cooldowns" header text
  match     = "raid cooldowns",  -- case-insensitive substring of the frame's title
  debug     = false,
}

-- Safe wrappers (no '...' usage)
local function safeGetObjectType(obj)
  if not obj then return nil end
  local ok, ty = pcall(function() return obj:GetObjectType() end)
  return ok and ty or nil
end

local function safeGetText(fontString)
  if not fontString then return nil end
  local ok, t = pcall(function() return fontString:GetText() end)
  return ok and t or nil
end

local function safeGetRegions(frame)
  if not frame then return nil end
  local ok, regions = pcall(function()
    -- Capture varargs into a table *inside* the closure (Lua 5.1-safe)
    return { frame:GetRegions() }
  end)
  if not ok or type(regions) ~= "table" then return nil end
  -- filter out nils so #regions is correct
  local out, n = {}, 0
  for i = 1, #regions do
    local r = regions[i]
    if r ~= nil then n = n + 1; out[n] = r end
  end
  return out
end

local function matchesTitleText(text)
  return text and cfg.match and text:lower():find(cfg.match, 1, true)
end

local function findCooldownsFrame()
  local f = EnumerateFrames()
  while f do
    -- Skip forbidden frames if API exists
    if not (f.IsForbidden and f:IsForbidden()) then
      if safeGetObjectType(f) == "Frame" then
        local regions = safeGetRegions(f)
        if regions and #regions > 0 then
          for i = 1, #regions do
            local r = regions[i]
            if r and safeGetObjectType(r) == "FontString" then
              local t = safeGetText(r)
              if t and matchesTitleText(t) then
                return f, r -- parent + title fontstring
              end
            end
          end
        end
      end
    end
    f = EnumerateFrames(f)
  end
end

local function skinFrame(frame, titleFS)
  if not frame then return end

  -- Hide title text safely
  if cfg.hideTitle and titleFS then pcall(function() titleFS:Hide() end) end

  -- Backdrop soften (old/new API variants)
  pcall(function() frame:SetBackdropColor(0, 0, 0, cfg.alpha) end)
  pcall(function() frame:SetBackdropBorderColor(0, 0, 0, 0) end)

  -- Fade top-level textures (borders/background); bars/icons are child frames and untouched
  local regions = safeGetRegions(frame)
  if regions then
    for i = 1, #regions do
      local r = regions[i]
      if r and safeGetObjectType(r) == "Texture" then
        pcall(function() r:SetAlpha(cfg.alpha) end)
      end
    end
  end

  if cfg.debug then
    local ok, name = pcall(function() return frame:GetName() end)
    print("MRTCD: Skinned", (ok and name) or "<unnamed>")
  end
end

local function skinOnce()
  local frame, title = findCooldownsFrame()
  if frame then skinFrame(frame, title) end
end

-- Re-apply when UI changes or MRT rebuilds its window
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("GROUP_ROSTER_UPDATE")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and type(arg1) == "string" and arg1:lower():find("mrt", 1, true) then
    C_Timer.After(0.3, skinOnce)
  else
    C_Timer.After(0.3, skinOnce)
  end
end)

C_Timer.NewTicker(2.0, skinOnce)

-- Slash commands
SLASH_MRTCD1 = "/mrtcd"
SlashCmdList.MRTCD = function(msg)
  msg = (msg or ""):lower()

  local a = msg:match("^alpha%s+([%d%.]+)")
  if a then
    cfg.alpha = math.min(1, math.max(0, tonumber(a) or 0))
    skinOnce()
    print(("MRTCD: alpha=%.2f"):format(cfg.alpha))
    return
  end

  local sw = msg:match("^title%s+(on|off)")
  if sw then
    cfg.hideTitle = (sw ~= "on")
    skinOnce()
    print("MRTCD: title " .. (cfg.hideTitle and "hidden" or "shown"))
    return
  end

  local m = msg:match("^match%s+(.+)")
  if m and m ~= "" then
    cfg.match = m
    skinOnce()
    print("MRTCD: title match set to '" .. cfg.match .. "'")
    return
  end

  if msg == "debug on" then cfg.debug = true; print("MRTCD: debug on"); return end
  if msg == "debug off" then cfg.debug = false; print("MRTCD: debug off"); return end

  print("MRTCD: /mrtcd alpha <0-1> | title on|off | match <text> | debug on|off")
end
