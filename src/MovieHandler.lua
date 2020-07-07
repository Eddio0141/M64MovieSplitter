MovieHandler = {
	StopScriptRequest = false,
	M64Path = "",
	MoviePlaying = false,
	LastSplitFrame = 1,
	SplitCount = 0,
	SplitOnNextFrame = false,
	SplitLastLevel = -1,
	MainMovie = {
		-- format yep
		-- MovieUID = 0,
		-- VIFrames = 0,
		-- Rerecords = 0,
		-- NumOfControllers = 0,
		-- InputFrames = 0,
		-- MovieStartType = 0,
		-- ControllerFlags = 0,
		-- ASCII
		-- InternalROMName = "",
		-- ROMCRC32 = 0,
		-- ROMCountryCode = 0,
		-- ASCII
		-- NameOfVideoPlugin = "",
		-- ASCII
		-- NameOfSoundPlugin = "",
		-- ASCII
		-- NameOfInputPlugin = "",
		-- ASCII
		-- NameOfRSPPlugin = "",
		-- UTF-8
		-- AuthorName = "",
		-- UTF-8
		-- AuthorDesc = "",
		-- InputTables = {
			-- where the inputs live
			
			-- there will be tables in here that will be up to a specific size limit and it'll be split into multiple tables once it
			-- exceeds that size
			-- each index of the tables in here will be 4 bytes each
		-- }
	},
	
	TempStPath = RESOURCE .. "temp.st"
}

function MovieHandler.TempStateCreation()
	savestate.savefile(MovieHandler.TempStPath)
end

function MovieHandler.GetPlayingM64sSt()
	if MovieHandler.M64Path == "" or not MovieHandler.M64Path then return "" end
	if not MovieHandler.MainMovie then return "" end
	if MovieHandler.MainMovie.MovieStartType ~= 1 then return "" end
	local mainFileName = Helper.GetFilename(MovieHandler.M64Path)
	local results = string.find(MovieHandler.M64Path, mainFileName)
	if type(results) == "table" then results = results[#results] end
	local extension = string.find(mainFileName, "%.")
	if type(extension) == "table" then extension = extension[#extension] end
	if not extension then extension = string.len(mainFileName) + 1 end
	return string.sub(MovieHandler.M64Path, 1, results - 1) .. string.sub(mainFileName, 1, extension - 1) .. ".st"
end

function MovieHandler.SplitAtCurrentFrame(isAutoSplit)
	if not MovieHandler.MoviePlaying then return end
	-- format of naming m64s
	-- %original m64 name%_m64 - split %split number% - frames %start frame% to %end frame% (%length%)
	-- test_m64 - split 1 - frames 1 to 500 (500)
	local newM64Name = Helper.GetFilePathWithoutExtension(Helper.GetFileName(MovieHandler.M64Path)) .. "_m64 - split " .. MovieHandler.SplitCount + 1 .. " - frames "
	
	local firstSplitFrame = MovieHandler.LastSplitFrame
	if MovieHandler.LastSplitFrame > 1 then
		firstSplitFrame = firstSplitFrame + 1
	end
	local emusamplecount = emu.samplecount()
	if isAutoSplit then
		emusamplecount = emusamplecount + 1
	end
	
	newM64Name = newM64Name .. firstSplitFrame .. " to " .. emusamplecount .. " (" .. emusamplecount - firstSplitFrame .. ")"
	
	if Helper.FileExists(BASE .. newM64Name .. ".m64") then
		newM64Name = newM64Name .. " ("
		local newM64NameNum = 1
		while Helper.FileExists(BASE .. newM64Name .. newM64NameNum .. ").m64") do
			newM64NameNum = newM64NameNum + 1
		end
		newM64Name = newM64Name .. newM64NameNum .. ")"
	end
	
	local result = MovieHandler.Split(firstSplitFrame, emusamplecount, newM64Name)
	-- print("firstsplitframe " .. firstSplitFrame .. " emusamplecount " .. emusamplecount)
	if not result then return nil end
	if (Helper.FileExists(MovieHandler.TempStPath)) and ((MovieHandler.MainMovie.MovieStartType == 1) or (MovieHandler.MainMovie.MovieStartType == 2 and MovieHandler.SplitCount > 0)) then
		-- handle st file
		local newStPath = BASE .. newM64Name .. ".st"
		os.rename(MovieHandler.TempStPath, newStPath)
		Helper.ExtractFileWith7z(newStPath, RESOURCE .. "decompressed.st")
		-- changing st file property
		local f = io.open(RESOURCE .. "decompressed.st", "r+b")
		St.DisableMovieMode(f)
		f:close()
		os.remove(newStPath)
		Helper.CompressFileWith7z(RESOURCE .. "decompressed.st", newStPath)
		os.remove(RESOURCE .. "decompressed.st")
	elseif not MovieHandler.MainMovie.MovieStartType == 1 and MovieHandler.SplitCount == 0 then
		os.remove(BASE .. newM64Name .. ".m64")
	end
	
	-- success so set values
	MovieHandler.LastSplitFrame = emusamplecount
	-- if MovieHandler.MainMovie.MovieStartType == 2 and MovieHandler.SplitCount > 0 then
		-- MovieHandler.LastSplitFrame = MovieHandler.LastSplitFrame - 1
	-- end
	
	MovieHandler.SplitCount = MovieHandler.SplitCount + 1
	MovieHandler.TempStateCreation()
	MovieHandler.SplitLastLevel = Memory.Level.ID
end

function MovieHandler.LoadMainM64()
	if not Helper.FileExists(MovieHandler.M64Path) then return end
	local m64 = M64Helper.NewM64(MovieHandler.M64Path)
	if not m64 then
		emu.statusbar("Error playing main m64")
		MovieHandler.StopMoviePlaying()
	end
	MovieHandler.MainMovie = m64
end

function MovieHandler.SplitToTheEndOfM64()
	if not MovieHandler.MoviePlaying then return end
	-- format of naming m64s
	-- %original m64 name%_m64 - split %split number% - frames %start frame% to %end frame% (%length%)
	-- test_m64 - split 1 - frames 1 to 500 (500)
	local newM64Name = Helper.GetFilePathWithoutExtension(Helper.GetFileName(MovieHandler.M64Path)) .. "_m64 - split " .. MovieHandler.SplitCount + 1 .. " - frames "
	
	local firstSplitFrame = MovieHandler.LastSplitFrame
	if MovieHandler.LastSplitFrame > 1 then
		firstSplitFrame = firstSplitFrame + 1
	end
	local lastFrameIndex = (#MovieHandler.MainMovie.InputTables - 1) * M64Helper.CountForEachInputTable + #MovieHandler.MainMovie.InputTables[#MovieHandler.MainMovie.InputTables]
	
	newM64Name = newM64Name .. firstSplitFrame .. " to " .. lastFrameIndex .. " (" .. lastFrameIndex - firstSplitFrame .. ")"
	
	if Helper.FileExists(BASE .. newM64Name .. ".m64") then
		newM64Name = newM64Name .. " ("
		local newM64NameNum = 1
		while Helper.FileExists(BASE .. newM64Name .. newM64NameNum .. ").m64") do
			newM64NameNum = newM64NameNum + 1
		end
		newM64Name = newM64Name .. newM64NameNum .. ")"
	end

	local result = MovieHandler.Split(firstSplitFrame, lastFrameIndex, newM64Name)
	if not result then return nil end
	if (Helper.FileExists(MovieHandler.TempStPath)) and ((MovieHandler.MainMovie.MovieStartType == 1) or (MovieHandler.MainMovie.MovieStartType == 2 and MovieHandler.SplitCount > 0)) then
		-- handle st file
		local newStPath = BASE .. newM64Name .. ".st"
		os.rename(MovieHandler.TempStPath, newStPath)
		Helper.ExtractFileWith7z(newStPath, RESOURCE .. "decompressed.st")
		-- changing st file property
		local f = io.open(RESOURCE .. "decompressed.st", "r+b")
		St.DisableMovieMode(f)
		f:close()
		os.remove(newStPath)
		Helper.CompressFileWith7z(RESOURCE .. "decompressed.st", newStPath)
		os.remove(RESOURCE .. "decompressed.st")
	elseif not MovieHandler.MainMovie.MovieStartType == 1 and MovieHandler.SplitCount == 0 then
		os.remove(BASE .. newM64Name .. ".m64")
	end
	MovieHandler.StopMoviePlaying()
end

function MovieHandler.SaveCurrentSplitAtCurrentFrame()
	MovieHandler.SplitAtCurrentFrame()
	MovieHandler.StopMoviePlaying()
end

function MovieHandler.Split(frameFrom, frameTo, newM64Name)
	if type(frameFrom) ~= "number" or type(frameTo) ~= "number" or type(newM64Name) ~= "string" then return nil end
	if not MovieHandler.MoviePlaying then return nil end
	if frameFrom > frameTo then return nil end
	if frameFrom < 1 then return nil end
	local newM64 = Helper.DeepCopyTable(MovieHandler.MainMovie)
	newM64.VIFrames = 0x7fffffff
	local inputs = M64Helper.GetInputRange(newM64, frameFrom, frameTo)
	if not inputs then return nil end
	newM64.InputTables = Helper.DeepCopyTable(inputs)
	newM64.InputFrames = frameTo - frameFrom
	if MovieHandler.SplitCount > 0 then
		newM64.MovieStartType = 1
	end
	local tehCreationDate = 0
	if newM64.MovieStartType == 1 then
		tehCreationDate = os.time(os.date("!*t"))
	end
	newM64.MovieUID = tehCreationDate
	M64Helper.SaveM64ToFile(newM64, BASE .. newM64Name .. ".m64")
	return 0
end

function MovieHandler.CheckAutoEnd()
	if not MovieHandler.MoviePlaying then return end
	if not Settings.AutoSplitter then return end
	
	if emu.samplecount() >= MovieHandler.MainMovie.InputFrames then
		MovieHandler.SplitToTheEndOfM64()
		MovieHandler.StopMoviePlaying()
	end
end

function MovieHandler.StopMoviePlaying()
	MovieHandler.MoviePlaying = false
	MovieHandler.LastSplitFrame = 1
	MovieHandler.SplitCount = 0
	MovieHandler.M64Path = ""
	MovieHandler.SplitLastLevel = -1
end

function MovieHandler.CheckAutoSplitConditionAndSplit()
	if not MovieHandler.MoviePlaying then return end
	if not Settings.AutoSplitter then return end
	
	if MovieHandler.SplitOnNextFrame then
		MovieHandler.SplitAtCurrentFrame(true)
		MovieHandler.SplitOnNextFrame = false
	end
	
	if Settings.SplitOnFadeOut and not Settings.SplitOnLevelChange then
		if (Memory.Transition.PrevProgress ~= Memory.Transition.Progress) and (Memory.Transition.Type % 2 == 1) and (Memory.Transition.Progress == 0) then
			MovieHandler.SplitOnNextFrame = true
		end
	elseif Settings.SplitOnFadeOut and Settings.SplitOnLevelChange and Settings.SplitOnLevelChangeAND then
		if (Memory.Transition.PrevProgress ~= Memory.Transition.Progress) and (Memory.Transition.Type % 2 == 1) and (MovieHandler.SplitLastLevel ~= Memory.Level.ID) and (Memory.Transition.Progress == 0) then
			MovieHandler.SplitAtCurrentFrame(true)
			MovieHandler.SplitOnNextFrame = false
		end
	elseif Settings.SplitOnLevelChange and not Settings.SplitOnFadeOut then
		if MovieHandler.SplitLastLevel ~= Memory.Level.ID then
			MovieHandler.SplitAtCurrentFrame(true)
		end
	end
end