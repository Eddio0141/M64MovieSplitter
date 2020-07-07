M64Helper = {
	CountForEachInputTable = 0x100000
}

-- returns new m64 from a path
-- returns nil if error'd
function M64Helper.NewM64(path)
	--local t1 = Helper.GetTimeInMS()
	if type(path) ~= "string" then return nil end
	if not Helper.FileExists(path) then return nil end
	
	local f = io.open(path, "rb")
	if not f then return nil end
	local fileSize = Helper.GetFileSize(f)

	-- error checking
	if fileSize < 0x404 then
		return nil
	end
	if not (Helper.BytesToASCII2(Helper.GetByteArrayFromFileInRange(f, 0x0, 3)) and Helper.GetByteArrayFromFileInRange(f, 0x3, 1)[1] == 0x1a) then
		return nil
	end
	if Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0x4, 4), true, false) ~= 3 then
		return nil
	end
	if Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0x16, 2), true, false) ~= 0 then
		return nil
	end
	local startType = Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0x1c, 2), true, false)
	if not (startType == 1 or startType == 2) then
		return nil
	end
	if Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0x1e, 2), true, false) ~= 0 then
		return nil
	end
	local range = Helper.GetByteArrayFromFileInRange(f, 0x24, 160)
	for i, v in pairs(range) do
		if v ~= 0 then
			return nil
		end
	end
	range = Helper.GetByteArrayFromFileInRange(f, 0xea, 56)
	for _, v in pairs(range) do
		if v ~= 0 then
			return nil
		end
	end
	local inputFrames = Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0x18, 4), true, false)
	local numOfControllers = Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0x15, 1), true, false)
	if inputFrames == 0 then
		return nil
	end
	local numOfFramesData = (fileSize - 0x400) / 4 / numOfControllers
	if not Helper.IsInt(numOfFramesData) then
		return nil
	end	
	if numOfFramesData < inputFrames then
		return nil
	end
	
	-- writing values
	local m64 = {}
	m64.MovieUID = Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0x8, 4), true, false)
	m64.VIFrames = Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0xc, 4), true, false)
	m64.Rerecords = Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0x10, 4), true, false)
	m64.NumOfControllers = numOfControllers
	m64.InputFrames = inputFrames
	m64.MovieStartType = startType
	m64.ControllerFlags = Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0x20, 4), true, false)
	m64.InternalROMName = Helper.BytesToASCII2(Helper.GetByteArrayFromFileInRange(f, 0xc4, 32))
	m64.ROMCRC32 = Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0xe4, 4), true, false)
	m64.ROMCountryCode = Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0xe8, 2), true, false)
	m64.NameOfVideoPlugin = Helper.BytesToASCII2(Helper.GetByteArrayFromFileInRange(f, 0x122, 64))
	m64.NameOfSoundPlugin = Helper.BytesToASCII2(Helper.GetByteArrayFromFileInRange(f, 0x162, 64))
	m64.NameOfInputPlugin = Helper.BytesToASCII2(Helper.GetByteArrayFromFileInRange(f, 0x1a2, 64))
	m64.NameOfRSPPlugin = Helper.BytesToASCII2(Helper.GetByteArrayFromFileInRange(f, 0x1e2, 64))
	m64.AuthorName = Helper.BytesToUTF82(Helper.GetByteArrayFromFileInRange(f, 0x222, 222))
	m64.AuthorDesc = Helper.BytesToUTF82(Helper.GetByteArrayFromFileInRange(f, 0x300, 256))
	
	-- setting inputs (error handling already done so remember that)
	local numOfFrames = m64.InputFrames / m64.NumOfControllers
	
	local floor = math.floor
	local frameofsamplelength = 4 * numOfControllers
	
	-- needs to adapt to input sections that are over 16mb
	-- to get past this issue, I make a new input table whenever im about to run out of space in the input table
	
	-- each input table index has 4 bytes of data
	local inputtables = {}
	local countforeachinputtable = M64Helper.CountForEachInputTable
	
	-- make tables before filling them in
	for i = 1, math.ceil((fileSize - 0x400 / 4) / countforeachinputtable), 1 do
		inputtables[i] = {}
	end
	
	local inputTableIndex = 1
	local inputBytesCount = floor((fileSize - 0x400) / 4)
	local buffTable = {}
	local currentTableIndexMinusOne
	if inputBytesCount > countforeachinputtable then
		for i = 1, inputBytesCount, 1 do
			currentTableIndexMinusOne = (i - 1) % countforeachinputtable
			if currentTableIndexMinusOne == 0 then
				inputtables[inputTableIndex] = buffTable
				inputTableIndex = inputTableIndex + 1
				buffTable = {}
			end
			buffTable[currentTableIndexMinusOne + 1] = Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0x400 + (i - 1) * 4, 4), false, false)
		end
	else
		for i = 1, inputBytesCount, 1 do
			buffTable[i] = Helper.GetBytes2(Helper.GetByteArrayFromFileInRange(f, 0x400 + (i - 1) * 4, 4), false, false)
		end
		inputtables[1] = buffTable
	end
	m64.InputTables = Helper.DeepCopyTable(inputtables)
	--local t2 = Helper.GetTimeInMS()
	
	--print(t2 - t1 .. "ms to load m64")

	f:close()
	return m64
end

function M64Helper.SaveM64ToFile(m64, path)
	--local t1 = Helper.GetTimeInMS()
	if type(m64) ~= "table" or type(path) ~= "string" then return end
	
	if Helper.FileExists(path) then os.remove(path) end
	local f = io.open(path, "ab")
	if not f then return nil end
	
	Helper.AppendByteArrayToFile(Helper.ASCIIToBytes("M64", -1), f)
	Helper.AppendByteArrayToFile({0x1a}, f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(3, 4, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(m64.MovieUID, 4, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(m64.VIFrames, 4, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(m64.Rerecords, 4, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(60, 1, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(m64.NumOfControllers, 1, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(0, 2, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(m64.InputFrames, 4, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(m64.MovieStartType, 2, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(0, 2, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(m64.ControllerFlags, 4, true, false), f)
	local arr = {}
	for i = 1, 160, 1 do
		arr[i] = 0
	end
	Helper.AppendByteArrayToFile(arr, f)
	Helper.AppendByteArrayToFile(Helper.ASCIIToBytes(m64.InternalROMName, 32), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(m64.ROMCRC32, 4, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(m64.ROMCountryCode, 2, true, false), f)
	arr = {}
	for i = 1, 56, 1 do
		arr[i] = 0
	end
	Helper.AppendByteArrayToFile(arr, f)
	Helper.AppendByteArrayToFile(Helper.ASCIIToBytes(m64.NameOfVideoPlugin, 64), f)
	Helper.AppendByteArrayToFile(Helper.ASCIIToBytes(m64.NameOfSoundPlugin, 64), f)
	Helper.AppendByteArrayToFile(Helper.ASCIIToBytes(m64.NameOfInputPlugin, 64), f)
	Helper.AppendByteArrayToFile(Helper.ASCIIToBytes(m64.NameOfRSPPlugin, 64), f)
	Helper.AppendByteArrayToFile(Helper.ASCIIToBytes(m64.AuthorName, 222), f)
	Helper.AppendByteArrayToFile(Helper.ASCIIToBytes(m64.AuthorDesc, 256), f)
	for _, inputTable in pairs(m64.InputTables) do
		for _, inputBytes in pairs(inputTable) do
			Helper.AppendByteArrayToFile(Helper.GetByteArray(inputBytes, 4, false, false), f)
		end
	end
	--local t2 = Helper.GetTimeInMS()
	
	--print(t2 - t1 .. "ms to save m64 to a file")
	f:close()
end

function M64Helper.GetInputRange(m64, startIndex, endIndex)
	--local t1 = Helper.GetTimeInMS()
	local countforeachinputtable = M64Helper.CountForEachInputTable
	local floor = math.floor

	if not m64 then return nil end
	if endIndex - startIndex < 0 then return nil end
	if endIndex > (#m64.InputTables - 1) * countforeachinputtable + #m64.InputTables[#m64.InputTables] then return nil end
	if startIndex < 1 then return nil end
	
	if startIndex == endIndex then
		return {{m64.InputTables[(math.floor((startIndex - 1) / countforeachinputtable)) + 1][((startIndex - 1) % countforeachinputtable) + 1]}}
	end
	
	local inputs = {}
	for i = 1, math.ceil((endIndex - startIndex) / countforeachinputtable), 1 do
		inputs[i] = {}
	end
	-- print("length = " .. length)
	-- print("inputs table size = " .. #inputs)
	local inputTablesIndex = floor(startIndex / countforeachinputtable) + 1
	local newInputTablesIndex = 1
	local j = 1
	local buffTable = {}
	
	-- idk im tired
	for i = startIndex, endIndex - 1, 1 do
		inputs[newInputTablesIndex][((j - 1) % countforeachinputtable) + 1] = m64.InputTables[inputTablesIndex][i % countforeachinputtable]
		newInputTablesIndex = floor(j / countforeachinputtable) + 1
		inputTablesIndex = floor(i / countforeachinputtable) + 1
		j = j + 1
	end
	--local t2 = Helper.GetTimeInMS()
	
	--print(t2 - t1 .. "ms to split input")
	
	return inputs
end