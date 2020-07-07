St = {

}

function St.NewSTFromStFile(path)
	if not Helper.FileExists(path) then return nil end
	if Helper.FileExists(RESOURCE .. "extracted.st") then
		os.remove(RESOURCE .. "extracted.st")
	end
	Helper.ExtractFileWith7z(path, RESOURCE .. "extracted.st")
	return St.NewST(Helper.GetByteArrayFromFile(RESOURCE .. "extracted.st"))
end

function St.NewST(byteArray)
	--local time1 = Helper.GetTimeInMS()
	if type(byteArray) ~= "table" then return nil end
	
	-- error checking
	if #byteArray < 0xA02BBC then
		return nil
	end
	local eventQueueOffset = 0
	if Helper.GetBytes(byteArray, 0xA02BB4, 4, true, false) == 0xFFFFFFFF then
		eventQueueOffset = eventQueueOffset + 4
	else
		local result
		while true do
			result = Helper.GetBytes(byteArray, 0xA02BB4 + eventQueueOffset, 4, true, false)
			if not result then
				return nil
			elseif result == 0xFFFFFFFF then
				eventQueueOffset = eventQueueOffset + 4
				break
			end
			eventQueueOffset = eventQueueOffset + 4
		end
	end
	local isStForMovie = (Helper.GetBytes(byteArray, 0xA02BB4 + eventQueueOffset, 4, true, false) ~= 0)
	if isStForMovie then
		if #byteArray < 0xA02BD4 + eventQueueOffset then
			return nil
		end
		if Helper.GetBytes(byteArray, 0xA02BB8 + eventQueueOffset, 4, true, false) ~= #byteArray - (0xA02BBC + eventQueueOffset) then
			return nil
		end
		local inputFrameCount = Helper.GetBytes(byteArray, 0xA02BC0 + eventQueueOffset, 4, true, false)
		local lengthSamples = Helper.GetBytes(byteArray, 0xA02BC8 + eventQueueOffset, 4, true, false)
		local inputsLen = #byteArray - (0xA02BCC + eventQueueOffset)
		local calcNumOfControllers = lengthSamples / inputFrameCount
		local calcInputFrameCount = inputsLen / 4 / calcNumOfControllers
		if not Helper.IsInt(calcNumOfControllers) then
			return nil
		end
		if calcNumOfControllers < 1 or calcNumOfControllers > 4 then
			return nil
		end
		if not Helper.IsInt(calcInputFrameCount) then
			return nil
		end
		if calcInputFrameCount - 1 ~= inputFrameCount then
			return nil
		end
		if calcInputFrameCount - 1 ~= lengthSamples / calcNumOfControllers then
			return nil
		end
	end
	
	local UNPACK = unpack
	local t = {}
	
	-- all numbers bigger than 8 bytes will be stored as a byte array or 4 byte array depending on the alignment
	local st = {}
	st.ROMHash = {UNPACK(byteArray, 0x1, 0x20)}
	st.RDRAMRegister = {UNPACK(byteArray, 0x21, 0x48)}
	st.MIRegister = {UNPACK(byteArray, 0x49, 0x48 + 36)}
	st.PIRegister = {UNPACK(byteArray, 0x6d, 0x6c + 52)}
	st.SPRegister = {UNPACK(byteArray, 0xa0 + 1, 0xa0 + 52)}
	st.RSPRegister = Helper.GetBytes(byteArray, 0xd4, 8, true, false)
	st.SIRegister = {UNPACK(byteArray, 0xdc + 1, 0xdc + 16)}
	st.VIRegister = {UNPACK(byteArray, 0xec + 1, 0xec + 60)}
	st.RIRegister = {UNPACK(byteArray, 0x128 + 1, 0x128 + 32)}
	st.AIRegister = {UNPACK(byteArray, 0x148 + 1, 0x148 + 40)}
	st.DPCRegister = {UNPACK(byteArray, 0x170 + 1, 0x170 + 48)}
	st.DPSRegister = {UNPACK(byteArray, 0x1a0 + 1, 0x1a0 + 16)}
	--local time1 = Helper.GetTimeInMS()
	for i = 0, 0x7FFFFF, 1 do
		t[i + 1] = byteArray[0x1b1 + i]
	end
	--local time2 = Helper.GetTimeInMS()
	-- byte array
	st.RDRAM = t
	st.SPDMEM = {UNPACK(byteArray, 0x8001B0 + 1, 0x8001B0 + 4096)}
	st.SPIMEM = {UNPACK(byteArray, 0x8011B0 + 1, 0x8011B0 + 4096)}
	st.PIFRAM = {UNPACK(byteArray, 0x8021B0 + 1, 0x8021B0 + 64)}
	st.Flashram = {}
	st.Flashram.UsesFlashram = Helper.GetBytes(byteArray, 0x8021f0, 4, true, false)
	st.Flashram.Mode = Helper.GetBytes(byteArray, 0x8021f4, 4, true, false)
	st.Flashram.Status = Helper.GetBytes(byteArray, 0x8021f8, 8, true, false)
	st.Flashram.EraseOffset = Helper.GetBytes(byteArray, 0x802200, 4, true, false)
	st.Flashram.WritePointer = Helper.GetBytes(byteArray, 0x802204, 4, true, false)
	--local time3 = Helper.GetTimeInMS()
	-- raw data, properly handle it to use it
	-- its still a 4 bytes array but as little endian
	t = {}
	for i = 0, 0xFFFFF, 1 do
		t[i + 1] = byteArray[0x802209 + i]
	end
	st.TLBLUTR = t
	-- raw data, properly handle it to use it
	-- its still a 4 bytes array but as little endian
	for i = 0, 0xFFFFF, 1 do
		t[i + 1] = byteArray[0x902209 + i]
	end
	st.TLBLUTW = t
	--local time4 = Helper.GetTimeInMS()
	st.LLBitRegister = Helper.GetBytes(byteArray, 0xa02208, 4, true, false)
	st.CPURegister = {UNPACK(byteArray, 0xa0220c + 1, 0xa0220c + 256, true, false)}
	st.MMURegister = {UNPACK(byteArray, 0xa0230c + 1, 0xa0230c + 256)}
	st.loRegister = Helper.GetBytes(byteArray, 0xa0240c, 8, true, false)
	st.hiRegister = Helper.GetBytes(byteArray, 0xa02414, 8, true, false)
	st.FPURegister = {UNPACK(byteArray, 0xa0241c + 1, 0xa0241c + 256)}
	st.FCR0Register = Helper.GetBytes(byteArray, 0xa0251c, 4, true, false)
	st.FCR31Register = Helper.GetBytes(byteArray, 0xa02520, 4, true, false)
	st.TLBE = {UNPACK(byteArray, 0xa02524 + 1, 0xa02524 + 1664)}
	st.PCRegister = Helper.GetBytes(byteArray, 0xa02ba4, 4, true, false)
	st.NextInterrupt = Helper.GetBytes(byteArray, 0xa02ba8, 4, true, false)
	st.NextVI = Helper.GetBytes(byteArray, 0xa02bac, 4, true, false)
	st.VIField = Helper.GetBytes(byteArray, 0xa02bb0, 4, true, false)
	--local time5 = Helper.GetTimeInMS()
	-- 4 byte array
	st.EventQueue = {true,true,true,true}
	for i = 1, eventQueueOffset / 4, 1 do
		st.EventQueue[i] = Helper.GetBytes(byteArray, 0xa02bb4 + (i - 1) * 4, 4, true, false)
	end
	--local time6 = Helper.GetTimeInMS()
	st.IsStForMovie = isStForMovie
	if isStForMovie then
		st.Movie = {}
		st.Movie.UID = Helper.GetBytes(byteArray, 0xa02bbc + eventQueueOffset, 4, true, false)
		st.Movie.InputFrameCount = Helper.GetBytes(byteArray, 0xa02bc0 + eventQueueOffset, 4, true, false)
		st.Movie.VIFrameCount = Helper.GetBytes(byteArray, 0xa02bc4 + eventQueueOffset, 4, true, false)
		st.Movie.LengthSamples = Helper.GetBytes(byteArray, 0xa02bc8 + eventQueueOffset, 4, true, false)
		-- input data is a 4 bytes
		st.Movie.InputData = {}
		local numOfControllers = st.Movie.LengthSamples / st.Movie.InputFrameCount
		for i = 1, #byteArray - (0xa02bcc + eventQueueOffset) / 4 + 1, 1 do
			st.Movie.InputData[i] = Helper.GetBytes(byteArray, 0xa02bcc + eventQueueOffset + ((i - 1) * 4), 4, true, false)
		end
	end
	--local time2 = Helper.GetTimeInMS()
	--local time7 = Helper.GetTimeInMS()
	--print(time2 - time1 .. " " .. time3 - time2 .. " " .. time4 - time3 .. " " .. time5 - time4 .. " " .. time6 - time5 .. " " .. time7 - time6)
	--print(time2 - time1 .. "ms")
	return st
end

function St.SaveSTToFile(st, path)
	if type(st) ~= "table" or type(path) ~= "string" then return end

	local tempPath = RESOURCE .. "tempOutST"
	if Helper.FileExists(tempPath) then os.remove(tempPath) end
	local f = io.open(tempPath, "ab")

	Helper.AppendByteArrayToFile(st.ROMHash, f)
	Helper.AppendByteArrayToFile(st.RDRAMRegister, f)
	Helper.AppendByteArrayToFile(st.MIRegister, f)
	Helper.AppendByteArrayToFile(st.PIRegister, f)
	Helper.AppendByteArrayToFile(st.SPRegister, f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.RSPRegister, 8, true, false), f)
	Helper.AppendByteArrayToFile(st.SIRegister, f)
	Helper.AppendByteArrayToFile(st.VIRegister, f)
	Helper.AppendByteArrayToFile(st.RIRegister, f)
	Helper.AppendByteArrayToFile(st.AIRegister, f)
	Helper.AppendByteArrayToFile(st.DPCRegister, f)
	Helper.AppendByteArrayToFile(st.DPSRegister, f)
	Helper.AppendByteArrayToFile(st.RDRAM, f)
	Helper.AppendByteArrayToFile(st.SPDMEM, f)
	Helper.AppendByteArrayToFile(st.SPIMEM, f)
	Helper.AppendByteArrayToFile(st.PIFRAM, f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.Flashram.UsesFlashram, 4, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.Flashram.Mode, 4, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.Flashram.Status, 8, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.Flashram.EraseOffset, 4, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.Flashram.WritePointer, 4, true, false), f)
	Helper.AppendByteArrayToFile(st.TLBLUTR, f)
	Helper.AppendByteArrayToFile(st.TLBLUTW, f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.LLBitRegister, 4, true, false), f)
	Helper.AppendByteArrayToFile(st.CPURegister, f)
	Helper.AppendByteArrayToFile(st.MMURegister, f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.loRegister, 8, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.hiRegister, 8, true, false), f)
	Helper.AppendByteArrayToFile(st.FPURegister, f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.FCR0Register, 4, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.FCR31Register, 4, true, false), f)
	Helper.AppendByteArrayToFile(st.TLBE, f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.PCRegister, 4, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.NextInterrupt, 4, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.NextVI, 4, true, false), f)
	Helper.AppendByteArrayToFile(Helper.GetByteArray(st.VIField, 4, true, false), f)
	for _, v in pairs(st.EventQueue) do
		Helper.AppendByteArrayToFile(Helper.GetByteArray(v, 4, true, false), f)
	end
	local isformovie = 1
	if not st.IsStForMovie then
		isformovie = 0
	end
	Helper.AppendByteArrayToFile(Helper.GetByteArray(isformovie, 4, true, false), f)
	if isStForMovie then
		local numOfControllers = st.Movie.LengthSamples / st.Movie.InputFrameCount
		Helper.AppendByteArrayToFile(Helper.GetByteArray(16 + #st.Movie.InputData * numOfControllers, 4, true, false), f)
		Helper.AppendByteArrayToFile(Helper.GetByteArray(st.Movie.UID, 4, true, false), f)
		Helper.AppendByteArrayToFile(Helper.GetByteArray(st.Movie.InputFrameCount, 4, true, false), f)
		Helper.AppendByteArrayToFile(Helper.GetByteArray(st.Movie.VIFrameCount, 4, true, false), f)
		Helper.AppendByteArrayToFile(Helper.GetByteArray(st.Movie.LengthSamples, 4, true, false), f)
		for i = 1, #st.Movie.InputData, 1 do
			Helper.AppendByteArrayToFile(Helper.GetByteArray(st.Movie.InputData[i], 4, true, false), f)
		end
	end
	Helper.CompressFileWith7z(RESOURCE .. "tempOutST", path)
end

-- file handle needs to be opened with r+b mode
function St.DisableMovieMode(fileHandle)
	if not fileHandle then return nil end
	fileHandle:seek("set", 0xA02BB4)
	local buff = ""
	local buffArr
	local eventQueueOffset = 0
	repeat
		buff = fileHandle:read(4)
		if buff then
			eventQueueOffset = eventQueueOffset + 4
			buffArr = {}
			for ch in (buff or ''):gmatch'.' do
				buffArr[#buffArr + 1] = string.byte(ch)
			end
			buff = Helper.GetBytes2(buffArr, false, false)
			if buff == 0xFFFFFFFF then
				break
			end
		end
	until not buff
	fileHandle:seek("set", 0xA02BB4 + eventQueueOffset)
	fileHandle:write(string.char(0))
	fileHandle:write(string.char(0))
	fileHandle:write(string.char(0))
	fileHandle:write(string.char(0))
end