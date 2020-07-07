BASE = debug.getinfo(1).source:sub(2):match("(.*\\)")
PATH = BASE .. "src\\"
LIB = BASE .. "lib\\"
RESOURCE = BASE .. "resources\\"
MUP = io.popen"cd":read'*l' .. "\\"

local fileExecPriority = {
	"Drawing.lua",
	"Settings.lua",
	"File.lua",
	"Mupen.lua",
	"Helper.lua",
	"MovieHandler.lua",
	"SaveHandler.lua",
}

-- runs files in fileExecPriority here
for _, fileName in pairs(fileExecPriority) do dofile(PATH .. fileName) end

-- able to run functions from files in fileExecPriority
SaveHandler.LoadVariables()
Drawing.ResizeScreen()

-- automatically runs it all
for filename in io.popen('dir "'..PATH..'" /b'):lines() do
	local alreadyExecuted = false
	for _, v in pairs(fileExecPriority) do
		if v == filename then
			alreadyExecuted = true
			break
		end
	end
	if not alreadyExecuted then
		dofile(PATH .. filename)
	end
end
-- not nessesary but I hate leaving stuff like this ok?
fileExecPriority = nil

Memory.Refresh()
Drawing.paint()

--local testST = St.NewSTFromStFile([[C:\Users\eddio\Documents\mupen64-rerecording-v8\freerjunasdlfjkasd.st]])
--St.SaveSTToFile(testST, [[C:\Users\eddio\Documents\mupen64-rerecording-v8\lua\M64MovieSplitter\output.st]])

if MovieHandler.MoviePlaying then
	MovieHandler.LoadMainM64()
	Helper.CopyFile(MovieHandler.GetPlayingM64sSt(), MovieHandler.TempStPath)
end

function main()
	Memory.Transition.PrevProgress = Memory.Transition.Progress
	Memory.Transition.PrevType = Memory.Transition.Type
	Memory.Refresh()
	
	MovieHandler.CheckAutoSplitConditionAndSplit()
	MovieHandler.CheckAutoEnd()
end

function drawing()
	Drawing.paint()
end

function update()
	if Input.update() then
		Drawing.paint()
	end
end

function atstop()
	Drawing.UnResizeScreen()
	SaveHandler.SaveVariables()
end

emu.atinput(main)
emu.atvi(drawing, false)
emu.atinterval(update, false)
emu.atstop(atstop)

package.cpath = package.cpath .. ";" .. LIB .. "?.dll;"
--local a = package.loadlib(LIB .. "m64splitterlualib.dll", "GetInputs")([[C:\Users\eddio\Documents\mupen64-rerecording-v8\test.m64]], 0x40000)
--print(#a)

-- local m64 = M64Helper.NewM64([[C:\Users\eddio\Documents\mupen64-rerecording-v8\test.m64]])
-- -- --M64Helper.SaveM64ToFile(m64, [[C:\Users\eddio\Documents\mupen64-rerecording-v8\output.m64]])
-- local inputs = M64Helper.GetInputRange(m64, 1, (#m64.InputTables - 1) * M64Helper.CountForEachInputTable + #m64.InputTables[#m64.InputTables])
-- if inputs then
	-- print("about to deep copy")
	-- m64.InputTables = inputs
	-- M64Helper.SaveM64ToFile(m64, [[C:\Users\eddio\Documents\mupen64-rerecording-v8\output.m64]])
-- else
	-- print("inputs invaid")
-- end

-- print("")