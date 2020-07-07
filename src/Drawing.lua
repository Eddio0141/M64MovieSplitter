Drawing = {
	WIDTH_OFFSET = 451,
	Screen = {
		Width = 0,
		Height = 0
	}
}

function Drawing.ResizeScreen()
	Drawing.DetectScreenSize()
	wgui.resize(Drawing.Screen.Width + Drawing.WIDTH_OFFSET, Drawing.Screen.Height)
end

function Drawing.UnResizeScreen()
	wgui.resize(Drawing.Screen.Width, Drawing.Screen.Height)
end

function Drawing.DetectScreenSize()
    local widthConfig = Mupen.GetConfigValue("Width")
    local heightConfig = Mupen.GetConfigValue("Height")
    local widthFinal, heightFinal
    local screen = wgui.info()
    if widthConfig then widthConfig = tonumber(widthConfig) else widthConfig = 0 end
    if heightConfig then heightConfig = tonumber(heightConfig) else heightConfig = 0 end
    if widthConfig ~= screen.width and (widthConfig ~= screen.width - Drawing.WIDTH_OFFSET or width ~= screen.width + Drawing.WIDTH_OFFSET) then
        widthFinal = screen.width
    else
        widthFinal = widthConfig
    end
    if heightConfig ~= screen.height then
        heightFinal = screen.height
    else
        heightFinal = heightConfig
    end
    
    if widthConfig == 0 then
        local width10 = screen.width % 10
        if width10 == 0 or width10 == 4 or width10 == 8 then
            widthFinal = screen.width
        else
            widthFinal = screen.width - Drawing.WIDTH_OFFSET
        end
    end
    Drawing.Screen.Width = widthFinal
    Drawing.Screen.Height = heightFinal
end

function Drawing.paint()
	wgui.setbrush("black")
	wgui.setpen("black")
	wgui.rect(Drawing.Screen.Width, 0, Drawing.Screen.Width + Drawing.WIDTH_OFFSET, Drawing.Screen.Height - 23)
	wgui.setbrush("#CCCCFF")
	wgui.setpen("#CCCCFF")
	wgui.rect(Drawing.Screen.Width + 10, 10, Drawing.Screen.Width + Drawing.WIDTH_OFFSET - 10, Drawing.Screen.Height - 33)
	wgui.setcolor("black")
	wgui.setfont(16,"Arial","")
	if MovieHandler.StopScriptRequest then
		wgui.setfont(20,"Arial","")
		wgui.text(Drawing.Screen.Width + 20, 20, "please restart the lua script")
		wgui.text(Drawing.Screen.Width + 20, 50, "with the movie running")
	else
		wgui.setfont(18,"Arial","")
		wgui.text(Drawing.Screen.Width + 20, 20, "M64 Movie Splitter")
		if MovieHandler.MoviePlaying then
			wgui.setfont(14,"Arial","")
			wgui.text(Drawing.Screen.Width + 220, 20, "- movie playing")
			local lastSplitFrame
			if MovieHandler.SplitCount > 0 then
				lastSplitFrame = MovieHandler.LastSplitFrame
			else
				lastSplitFrame = "N/A"
			end
			wgui.text(Drawing.Screen.Width + 20, 400, "Last split frame - " .. lastSplitFrame)
			wgui.text(Drawing.Screen.Width + 20, 430, "Split count - " .. MovieHandler.SplitCount)
			wgui.setfont(18,"Arial","")
		end
		for _, button in pairs(Buttons) do
			if button.enabled() then
				if button.type == ButtonType.button then
					Drawing.drawButton(button.box[1], button.box[2], button.box[3], button.box[4], button.text, button.pressed())
				else
					Drawing.drawTextArea(button.box[1], button.box[2], button.box[3], button.box[4], string.format("%0".. Buttons[i].inputSize .."d", Buttons[i].value()), Buttons[i].enabled(), Buttons[i].editing())
				end
			end
		end
	end
	wgui.setfont(10,"Arial","")
end

function Drawing.drawButton(x, y, width, length, text, pressed)
	if (pressed) then wgui.setcolor("white") else wgui.setcolor("black") end
	wgui.setfont(10,"Courier","")
	wgui.setbrush("#888888")
	wgui.setpen("#888888")
	wgui.rect(x + 1, y + 1, x + width + 1, y + length + 1)
	if (pressed) then wgui.setbrush("#FF0000") else wgui.setbrush("#F2F2F2") end
	if (pressed) then wgui.setpen("#EE8888") else wgui.setpen("#888888") end
	wgui.rect(x, y, x + width, y + length)
	if (pressed) then wgui.setbrush("#EE0000") else wgui.setbrush("#E8E8E8") end
	if (pressed) then wgui.setpen("#EE0000") else wgui.setpen("#E8E8E8") end
	wgui.rect(x+1, y+1 + length/2, x-1 + width, y-1 + length)
	wgui.text(x + width/2 - 4.5 * string.len(text), y + length/2 - 7, text)
end

function Drawing.drawTextArea(x, y, width, length, text, enabled, editing)
	wgui.setcolor("black")
	wgui.setfont(16,"Courier","b")
	if (editing) then wgui.setbrush("#FFFF00") elseif (enabled) then wgui.setbrush("#FFFFFF") else wgui.setbrush("#AAAAAA") end
	wgui.setpen("#000000")
	wgui.rect(x + 1, y + 1, x + width + 1, y + length + 1)
	wgui.setpen("#888888")
	wgui.line(x+2,y+2,x+2,y+length)
	wgui.line(x+2,y+2,x+width,y+2)
	if (editing) then
		selectedChar = Settings.Layout.TextArea.selectedChar
		text = string.sub(text,1, selectedChar - 1) .. "_" .. string.sub(text, selectedChar + 1, string.len(text))
	end
	wgui.text(x + width/2 - 6.5 * string.len(text), y + length/2 - 8, text)
end