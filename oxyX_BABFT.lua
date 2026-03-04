local u="https://raw.githubusercontent.com/johsua092-ui/babft-script/main/oxyX_BABFT.lua"
local s=loadstring(game:HttpGet(u))
if not s then
  local r=(syn and syn.request or request or http_request)({Url=u,Method="GET"})
  s=loadstring(r and r.Body or "")
end
assert(s,"load failed")()
