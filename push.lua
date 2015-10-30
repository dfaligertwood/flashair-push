--Check if args are being passed to script when called on filesystem event.

if not (#arg == 0) then
  local file = io.open("/log.txt", "w")
  file:write(arg[1])
  file:close()
else
  local file = io.open("/log.txt", "w")
  file:write("No Args... :(")
  file:close()
end
