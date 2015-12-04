serverUrl   = "http://192.168.0.11/"
watchFolder = "/DCIM/101CANON"
watchExt    = "JPG"

local function httpSuccess(code)
  local firstNum = string.sub(code, 1, 1)
  return (firstNum == '2' or firstNum == '1')
end

local function sendFileName(filePath)
  local message = cjson.encode({ file = filePath })
  print(filePath .. "->" .. serverUrl)
  body, code, header = fa.request { url = serverUrl
                                  , method = "POST"
                                  , headers = { ["Content-Length"] = string.len(message)
                                              , ["Content-Type"] = "application/json"
                                              }
                                  , body = message
                                  }
  if httpSuccess(code) then
    print("SENT " .. filePath)
  else
    print("FAILED " .. filePath)
  end

  collectgarbage()
end

local function checkDir()
  local newestFileDate = 0

  for file in lfs.dir(watchFolder) do
    local filePath = watchFolder..'/'..file
    local fileDate = lfs.attributes(filePath, 'modification')
    local fileExt  = string.sub(filePath, -3)
    if ((fileDate) and (fileDate > newestFileDate) and (watchExt == fileExt)) then
      newestFileDate = fileDate
      newestFilePath = filePath
    end
  end

  collectgarbage()
  return newestFilePath
end

local res = fa.ReadStatusReg()
if (string.sub(res, 13, 13) == "b") then
  sendFileName(checkDir())
end
