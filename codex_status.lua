#!/usr/bin/luajit
-- -- loop:run()

local lgi = require("lgi")
local Soup = lgi.require("Soup", "3.0")
local Json = lgi.require("Json", "1.0")
local GLib = lgi.GLib
local session = Soup.Session()

local status = {
  limit_reached = false,
  primary_window = { reset_at = 0.0, used_percent = 0.0 },
  secondary_window = { reset_at = 0.0, used_percent = 0.0 },
}

local function refresh()
  local p = Json.Parser()
  assert(p:load_from_file(os.getenv("HOME") .. "/.codex/auth.json"))

  local t =
    assert(p:get_root():get_object():get_object_member("tokens"))

  local m = Soup.Message({
    method = "GET",
    uri = GLib.Uri.parse(
      "https://chatgpt.com/backend-api/wham/usage",
      0
    ),
  })

  local h = m:get_request_headers()

  h:replace(
    "Authorization",
    "Bearer " .. t:get_string_member("access_token")
  )

  h:replace("ChatGPT-Account-Id", t:get_string_member("account_id"))

  session:send_and_read_async(
    m,
    GLib.PRIORITY_HIGH_IDLE,
    nil,
    function(_, res)
      local bytes = assert(session:send_and_read_finish(res))

      assert(
        m:get_status() == "OK",
        "HTTP " .. tostring(m:get_status())
      )

      if not p:load_from_data(bytes:get_data(), -1) then
        return
      end

      local r = assert(
        p:get_root():get_object():get_object_member("rate_limit")
      )

      local a = assert(r:get_object_member("primary_window"))
      local b = assert(r:get_object_member("secondary_window"))

      status.limit_reached = r:get_boolean_member("limit_reached")

      status.primary_window.reset_at = a:get_int_member("reset_at")

      status.primary_window.used_percent =
        a:get_double_member("used_percent")

      status.secondary_window.reset_at = b:get_int_member("reset_at")

      status.secondary_window.used_percent =
        b:get_double_member("used_percent")
    end
  )
end

refresh()

GLib.timeout_add_seconds(0, 300, function()
  refresh()
  return true
end)

return status
