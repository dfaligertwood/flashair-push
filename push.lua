logFilePath     = "/lua/sent_files.txt"
errorFilePath   = "/lua/failed_files.txt"
bufferFilePath  = "/lua/unsent_files.txt"
newestFilePath  = "/lua/newest_file.txt"
serverUrl       = "http://192.168.0.11:8080"
watchFolder     = "/DCIM/101_CANON"


local function httpSuccess(code)
  local firstNum = string.sub(code, 1, 1)
  return (firstNum == '2' or firstNum == '1')
end

local function sendFile(filePath)
  local filesize = lfs.attributes(filePath, "size")

  if filesize then
    local body, code, header = fa.request { url = serverPath
                                          , method = "PUT"
                                          , headers = {["Content-Length"] = filesize}
                                          , file = filePath
                                          }
    if httpSuccess(code) then
      logFile:write(filePath)
      logFile:flush()
    else
      errorFile:write(filePath..' Code: '..code..'\n')
      errorFile:flush()
    end
  else
    errorFile:write(filePath..' does not exist.'..'\n')
    errorFile:flush()
  end
end

local function sendFiles(filePaths)
  for i = 1, #filePaths do
    sendFile(filePaths[i])
  end
end

local function checkDir()
  local f = io.open(newestFilePath)
  local newestFileDate = 0

  if f then
    local newestFile = f:read()
    f:close()
    if newestFile then
      newestFileDate = lfs.attributes(newestFile, 'modification')
    end
  end

  local filePath = nil
  local newFile = nil
  for file in lfs.dir(watchFolder) do
    filePath = watchFolder..'/'..file
    local fileModDate = lfs.attributes(filePath, 'modification')
    print(fileModDate)
    if fileModDate and (fileModDate > newestFileDate) then
      break
    else
      filePath = nil
    end
  end

  if filePath then
    local f = io.open(newestFilePath, 'w+')
    f:write(filePath)
    f:close()
  end

  collectgarbage()
  return newFile
end

local function bufferedFiles(newFile)
  local t = {}
  for f in io.lines(bufferFile) do
    if f then table.insert(t, f) end
  end
  table.insert(t, newFile)
  io.open(bufferFile, 'w+'):close()
  return t
end

local newFile = checkDir()
print(newFile)
if newFile then
  local res = fa.ReadStatusReg()
  if (string.sub(res, 13, 13) == "b") then
    logFile   = io.open(logFilePath, 'a+')
    errorFile = io.open(errorFilePath, 'a+')
    sendFiles(bufferedFiles(newFile))
    logFile:close()
    errorFile:close()
  else
    local bufferFile = io.open(bufferFilePath, 'a+')
    bufferFile:write(newFile..'\n')
    bufferFile:close()
  end
end
