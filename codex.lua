package.path = package.path
  .. ";"
  .. ironbar.config_dir
  .. "/codex_widget/?.lua"
local lgi = require("lgi")
local Rsvg = lgi.require("Rsvg", "2.0")
local cairo = lgi.cairo

-- Resolve colors once when this script is loaded.
local function read_color(name, fallback)
  local value = ironbar:var_get("codex_color_" .. name)
  if not value then
    return fallback
  end
  local r, g, b, a = value:match("^%s*([^,]+),([^,]+),([^,]+),([^,]+)%s*$")
  local rgba = { tonumber(r), tonumber(g), tonumber(b), tonumber(a) }
  for i = 1, 4 do
    local component = rgba[i]
    if not component or component ~= component or component < 0 or component > 1 then
      return fallback
    end
  end
  return rgba
end

local colors = {
  logo = read_color("logo", { 0, 0, 0, 1 }),
  primary = read_color("primary", { 0.3, 1, 0.3, 0.7 }),
  secondary = read_color("secondary", { 1, 0.3, 0.3, 0.7 }),
  hands = read_color("hands", { 1, 1, 1, 1 }),
}

local status = assert(
  loadfile(ironbar.config_dir .. "/codex_widget/codex_status.lua")
)()
local masks

---@param cr cairo.Context
local function draw(cr, width, height)
  local size = math.min(width, height) * 0.95
  if not masks then
    masks = assert(require("load_mask")(size))
  end
  local angle = (os.date("*t")["sec"] / 60 * 2 * math.pi)
    % (2 * math.pi)
  local anglem = (
    (os.date("*t")["sec"] + ironbar:unixtime().subsec_millis / 1000)
    / 60
    * 2
    * math.pi
  ) % (2 * math.pi)
  cr:translate(width / 2, height / 2)

  cr:save()
  cr:rotate(-anglem)
  cr:set_source_rgba(unpack(colors.logo))
  cr:mask_surface(masks.logo, -size / 2, -size / 2)
  cr:fill()
  cr:restore()

  local pper = status.primary_window.used_percent
  local sper = status.secondary_window.used_percent
  cr:save()
  cr:rectangle(-size / 2, -size / 2 + size * pper / 100, size, size)
  cr:clip()
  cr:rotate(-anglem)
  -- sper=0
  cr:set_source_rgba(unpack(colors.primary))
  -- cr:set_source_rgba(1, 0.3, 0.3, 0.7)
  cr:mask_surface(masks.holes[1], -size / 2, -size / 2)
  cr:mask_surface(masks.holes[2], -size / 2, -size / 2)
  cr:mask_surface(masks.holes[3], -size / 2, -size / 2)
  -- cr:mask_surface(masks.holes[4], -size / 2, -size / 2)
  cr:mask_surface(masks.holes[5], -size / 2, -size / 2)
  cr:mask_surface(masks.holes[6], -size / 2, -size / 2)
  cr:mask_surface(masks.holes[7], -size / 2, -size / 2)
  cr:fill()
  cr:restore()

  cr:save()
  cr:rectangle(-size / 2, -size / 2 + size * sper / 100, size, size)
  cr:clip()
  cr:rotate(-anglem)
  -- sper=0
  -- cr:set_source_rgba(0.3, 1, 0.3, 0.7)
  cr:set_source_rgba(unpack(colors.secondary))
  cr:mask_surface(masks.holes[1], -size / 2, -size / 2)
  cr:mask_surface(masks.holes[2], -size / 2, -size / 2)
  cr:mask_surface(masks.holes[3], -size / 2, -size / 2)
  -- cr:mask_surface(masks.holes[4], -size / 2, -size / 2)
  cr:mask_surface(masks.holes[5], -size / 2, -size / 2)
  cr:mask_surface(masks.holes[6], -size / 2, -size / 2)
  cr:mask_surface(masks.holes[7], -size / 2, -size / 2)
  cr:fill()
  cr:restore()
  local t = os.date("*t", status.primary_window.reset_at)
  local s = t["sec"]
  local m = t["min"] + s / 60
  local h = t["hour"] + m / 60
  cr:save()
  cr:rotate(h / 12 * 2 * math.pi)
  cr:set_source_rgba(unpack(colors.hands))
  cr:set_line_width(size / 20)
  cr:move_to(0, 0)
  cr:line_to(0, -size / 2 * 0.8)
  cr:stroke()
  cr:arc(0, 0, size / 25, 0, 2 * math.pi)
  cr:fill()
  cr:restore()

  cr:save()
  cr:rotate(m / 60 * 2 * math.pi)
  cr:set_source_rgba(unpack(colors.hands))
  cr:set_line_width(size / 30)
  cr:move_to(0, 0)
  cr:line_to(0, -size / 2)
  cr:stroke()
  cr:restore()

  return 0
end

return draw
