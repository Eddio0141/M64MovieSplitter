SaveHandler = {
	FilePath = BASE .. "resources\\save"
}

function SaveHandler.SaveData(dataTable)
	local newData = {}
	for _, v in pairs(dataTable) do
		local var = v
		if type(v) == "boolean" then
			var = Helper.BoolToString(v)
		end
		table.insert(newData, var)
	end
	table.save(newData, SaveHandler.FilePath)
end
function SaveHandler.LoadData()
	if not Helper.FileExists(SaveHandler.FilePath) then return nil end
	local fileData = table.load(SaveHandler.FilePath)
	local newData = {}
	for _, v in pairs(fileData) do
		local var = v
		if v == "true" or v == "false" then
			var = Helper.StringToBool(v)
		end
		table.insert(newData, var)
	end
	return newData
end

function SaveHandler.SaveVariables()
	local content = {
		Settings.AutoSplitter,
		MovieHandler.M64Path,
		MovieHandler.MoviePlaying,
		Settings.SplitOnFadeOut,
		Settings.SplitOnLevelChange,
		Settings.SplitOnLevelChangeAND
	}
	SaveHandler.SaveData(content)
end
function SaveHandler.LoadVariables()
	local content = SaveHandler.LoadData()
	if content ~= nil then
		-- disgusting
		Settings.AutoSplitter = content[1]
		MovieHandler.M64Path = content[2]
		MovieHandler.MoviePlaying = content[3]
		Settings.SplitOnFadeOut = content[4]
		Settings.SplitOnLevelChange = content[5]
		Settings.SplitOnLevelChangeAND = content[6]
	end
end

function SaveHandler.DeleteSave()
	if Helper.FileExists(SaveHandler.FilePath) then
		os.remove(SaveHandler.FilePath)
	end
end