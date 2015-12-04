serverUrl   = "http://192.168.0.11/"
watchFolder = "/DCIM/101CANON"

local function httpSuccess(code)
  local firstNum = string.sub(code, 1, 1)
  return (firstNum == '2' or firstNum == '1')
end

local function sendDir(dirContents)
  local message = cjson.encode(dirContents)
  print("->" .. serverUrl)
  body, code, header = fa.request { url = serverUrl
                                  , method = "POST"
                                  , headers = { ["Content-Length"] = string.len(message)
                                              , ["Content-Type"] = "application/json"
                                              }
                                  , body = message
                                  }
  if httpSuccess(code) then
    print("SUCCESS")
  else
    print("FAILURE")
  end

  collectgarbage()
end

local function checkDir()
  local dirContents = {}

  for file in lfs.dir(watchFolder) do
    local filePath = watchFolder..'/'..file
    local fileDate = lfs.attributes(filePath, 'modification')
    table.insert(dirContents, {file = filePath, mod_date = fileDate})
  end

  collectgarbage()
  return dirContents
end

local res = fa.ReadStatusReg()
if (string.sub(res, 13, 13) == "b") then
  sendDir(checkDir())
end
