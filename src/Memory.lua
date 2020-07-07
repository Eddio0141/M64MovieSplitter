Memory = {
	Mario = {
	
	},
	Camera = {
	
	},
	Transition = {
	},
	Level = {
	},
	Version = 1
}

GameVersion = {
	U = 1,
	J = 2
}

function Memory.Refresh()
	Memory.CheckVersion()

	-- meh
	if not Memory.Transition.Progress then
		if Memory.Version == GameVersion.U then
			Memory.Transition.Progress = memory.readbyte(0xB30EC0)
			Memory.Transition.Type = memory.readword(0xB3BAB0)
		else
			Memory.Transition.Progress = memory.readbyte(0xB2ff60)
			Memory.Transition.Type = memory.readword(0xB3a740)
		end
		Memory.Transition.PrevProgress = Memory.Transition.Progress
		Memory.Transition.PrevType = Memory.Transition.Type
	end

	if Memory.Version == GameVersion.U then
		Memory.Transition.Progress = memory.readbyte(0xB30EC0)
		Memory.Transition.Type = memory.readword(0xB3BAB0)
		Memory.Level.ID = memory.readbyte(0xB3B249)
	else
		Memory.Transition.Progress = memory.readbyte(0xB2ff60)
		Memory.Transition.Type = memory.readword(0xB3a740)
		Memory.Level.ID = memory.readbyte(0xb39ed9)
	end
end

function Memory.CheckVersion()
	-- Checks Addr 0x80322B24:
		-- If U: 8F A6 00 1C 	LW a2 <- [sp+0x001C]		(OS func)
		-- If J: 46 00 60 04	SQRT.s f00.s = sqrt(f12.s) 	(sqrtf func)
	
	if memory.readdword(0x00B22B24) == 1174429700 then -- J version
		Memory.Version = GameVersion.J
	else -- U version
		Memory.Version = GameVersion.U
	end
end