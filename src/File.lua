File = {

}

function File.Exists(path)
	local f = io.open(path, "rb")
	if f then f:close() return true else return false end
end

function File.GetLines(path)
	if not File.Exists(path) then return nil end
	local t = {}
	for line in io.lines(path) do 
		t[#t + 1] = line
	end
	return t
end