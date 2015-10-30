logFile     = "/lua/sent_files.txt"
watchFolder = "/DCIM/101_CANON"

test = io.popen("help")
output = test:read()
print(output)
test.close()

