serverUrl   = "http://192.168.0.11/"
watchFolder = "/DCIM/101CANON"
watchExt    = "JPG"

local function httpSuccess(code)
  local firstNum = string.sub(code, 1, 1)
  return (firstNum == '2' or firstNum == '1')
end

local function sendFile(fileName)
  local filePath = watchFolder .. "/" .. fileName
  local filesize = lfs.attributes(filePath, "size")

  if filesize then
    local serverPath = serverUrl .. fileName
    print(fileName .. " -> " .. serverPath)
    body, code, header = fa.request { url = serverPath
                                    , method = "PUT"
                                    , headers = {["Content-Length"] = filesize}
                                    , file = filePath
                                    , bufsize = 1460*10
                                    }
    if httpSuccess(code) then
      print("UPLOADED " .. filePath)
    else
      print("FAILED " .. filePath)
    end
  end

  collectgarbage()
end

local function checkDir()
  local newestFileDate = 0
  local newestFilePath = nil

  for file in lfs.dir(watchFolder) do
    local filePath = watchFolder..'/'..file
    local fileDate = lfs.attributes(filePath, 'modification')
    local fileExt  = string.sub(filePath, -3)
    if ((fileDate) and (fileDate > newestFileDate) and (watchExt == fileExt)) then
      newestFileDate = fileDate
      newestFileName = file
    end
  end

  collectgarbage()
  return newestFileName
end

local res = fa.ReadStatusReg()
if (string.sub(res, 13, 13) == "b") then
  sendFile(checkDir())
end
