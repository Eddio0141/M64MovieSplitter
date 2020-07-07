ButtonType = {
	button = 0,
		-- text : button text
		-- box : total size of the button
	textArea = 1
}

Buttons = {
	{
		type = ButtonType.button,
		text = "Start new",
		box = {
			Drawing.Screen.Width + 20,
			60,
			100,
			20
		},
		enabled = function()
			return true
		end,
		pressed = function()
			return false
		end,
		onclick = function(self)
			local inputResult = input.prompt("Enter the M64 movie path")
			if inputResult then
				if Helper.FileExists(inputResult) then
					if Helper.GetFileExtension(inputResult) == ".m64" then
						for k, v in pairs(Buttons) do
							Buttons[k].enabled = function() return false end
						end
						MovieHandler.M64Path = inputResult
						MovieHandler.StopScriptRequest = true
						MovieHandler.MoviePlaying = true
						SaveHandler.SaveVariables()
					else
						emu.statusbar("please input an m64 file path")
					end
				else
					emu.statusbar("please input a valid m64 file path")
				end
			else
				emu.statusbar("please input an m64 file path")
			end
		end
	},
	{
		type = ButtonType.button,
		text = " Auto Splitter",
		box = {
			Drawing.Screen.Width + 20,
			110,
			120,
			30
		},
		enabled = function()
			return true
		end,
		pressed = function()
			local bool = Settings.AutoSplitter
			return bool
		end,
		onclick = function(self)
			Settings.AutoSplitter = not Settings.AutoSplitter
		end
	},
	{
		type = ButtonType.button,
		text = "Split",
		box = {
			Drawing.Screen.Width + 20,
			150,
			80,
			30
		},
		enabled = function()
			return MovieHandler.MoviePlaying
		end,
		pressed = function()
			return false
		end,
		onclick = function(self)
			MovieHandler.SplitAtCurrentFrame(false)
		end
	},
	{
		type = ButtonType.button,
		text = "     End movie split and save rest of m64",
		box = {
			Drawing.Screen.Width + 20,
			200,
			300,
			30
		},
		enabled = function()
			return MovieHandler.MoviePlaying
		end,
		pressed = function()
			return false
		end,
		onclick = function(self)
			MovieHandler.SplitToTheEndOfM64()
			MovieHandler.StopMoviePlaying()
			SaveHandler.SaveVariables()
		end
	},
	{
		type = ButtonType.button,
		text = "End movie split at current frame",
		box = {
			Drawing.Screen.Width + 20,
			240,
			300,
			30
		},
		enabled = function()
			return MovieHandler.MoviePlaying
		end,
		pressed = function()
			return false
		end,
		onclick = function(self)
			MovieHandler.SaveCurrentSplitAtCurrentFrame()
			MovieHandler.StopMoviePlaying()
			SaveHandler.SaveVariables()
		end
	},
	{
		type = ButtonType.button,
		text = "End movie splitter",
		box = {
			Drawing.Screen.Width + 20,
			280,
			200,
			30
		},
		enabled = function()
			return MovieHandler.MoviePlaying
		end,
		pressed = function()
			return false
		end,
		onclick = function(self)
			MovieHandler.StopMoviePlaying()
			SaveHandler.SaveVariables()
		end
	},
	{
		type = ButtonType.button,
		text = " on fade out",
		box = {
			Drawing.Screen.Width + 150,
			110,
			110,
			30
		},
		enabled = function()
			return true
		end,
		pressed = function()
			return Settings.SplitOnFadeOut
		end,
		onclick = function(self)
			Settings.SplitOnFadeOut = not Settings.SplitOnFadeOut
		end
	},
	{
		type = ButtonType.button,
		text = "  on level change",
		box = {
			Drawing.Screen.Width + 270,
			110,
			130,
			30
		},
		enabled = function()
			return true
		end,
		pressed = function()
			return Settings.SplitOnLevelChange
		end,
		onclick = function(self)
			Settings.SplitOnLevelChange = not Settings.SplitOnLevelChange
		end
	},
	{
		type = ButtonType.button,
		text = "and",
		box = {
			Drawing.Screen.Width + 270 + 45,
			85,
			40,
			20
		},
		enabled = function()
			return true
		end,
		pressed = function()
			return Settings.SplitOnLevelChangeAND
		end,
		onclick = function(self)
			Settings.SplitOnLevelChangeAND = not Settings.SplitOnLevelChangeAND
		end
	}
}