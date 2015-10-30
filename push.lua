--Check if args are being passed to script when called on filesystem event.

if not (#arg == 0) then
  io.open("/log.txt", "w"):write(arg[1])
else
  io.open("/log.txt", "w"):write("No Args... :(")
end
