Mupen = {
	ConfigPath = MUP .. "mupen64.cfg"
}

function Mupen.GetConfigValue(key)
	if type(key) ~= "string" then return nil end
	local linez = File.GetLines(Mupen.ConfigPath)
	if not linez then return nil end
	for _, line in pairs(linez) do
		local result = string.find(line, key .. "=")
		if result then
			return string.gsub(line, key .. "=", "")
		end
	end
	return nil
end