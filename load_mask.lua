local lgi = require("lgi")
local Rsvg = lgi.require("Rsvg", "2.0")
local cairo = lgi.cairo

local logo_path = ironbar.config_dir .. "/codex_widget/openai.svg"
local holes_dir = ironbar.config_dir .. "/codex_widget/holes"
local function create_mask(path, size)
  local handle, err = Rsvg.Handle.new_from_file(path)
  assert(handle, "SVG load failed: " .. tostring(err))

  local mask = cairo.ImageSurface.create(cairo.Format.A8, size, size)

  local mcr = cairo.Context(mask)

  assert(handle:render_document(
    mcr,
    Rsvg.Rectangle({
      x = 0,
      y = 0,
      width = size,
      height = size,
    })
  ))
  return mask
end

local function load_svg_once()
  local logo_mask = create_mask()

  local surface =
    cairo.ImageSurface.create(cairo.Format.ARGB32, size, size)

  local cr = cairo.Context(surface)

  cr:set_source_rgba(1, 1, 1, 0.5) -- 白
  cr:mask_surface(svg_mask, 0, 0)

  return surface
end

local function map(tbl, f)
  local t = {}
  for i, v in ipairs(tbl) do
    t[i] = f(v)
  end
  return t
end

return function(size)
  return {
    logo = create_mask(logo_path, size),
    holes = map({ 1, 2, 3, 4, 5, 6, 7 }, function(n)
      return create_mask(holes_dir .. "/hole" .. n .. ".svg", size)
    end),
  }
end
