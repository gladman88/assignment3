--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]]

Board = Class{}

function Board:init(x, y, level)
	-- particles
	
	local img = love.graphics.newImage('/graphics/shine.png')
 
	psystem = love.graphics.newParticleSystem(img, 5)
	-- lasts between 1-1.5 seconds seconds
    psystem:setParticleLifetime(1,1.5)
    psystem:setEmissionRate(1.5)

    -- spread of particles; normal looks more natural than uniform
    psystem:setAreaSpread('uniform', 14, 14)
    
    psystem:setSpin( 3, 5 )
    
	psystem:setColors(255, 255, 255, 255, 150, 255, 255, 150) -- Fade to transparency.
	psystem:setSizes(0.3,1,0)
	
	-- particles end
	
    self.x = x
    self.y = y
    self.matches = {}
    self.superMatchesCounter = 0
    self.level = level or 1
    
    self.hint = false
    
    -- choose 8 colors for colorSet from 18 total colors, randomly
    self.colorSet = createColorSet()
    
    self:initializeTiles()
end

function Board:update(dt)
    Timer.update(dt)
	-- particles
    psystem:update(dt)
    -- particles end
end

function Board:initializeTiles()

    self.tiles = {}

    for tileY = 1, 8 do
        
        -- empty table that will serve as a new row
        table.insert(self.tiles, {})

        for tileX = 1, 8 do
            -- create a new tile at X,Y with a random color and variety
            table.insert(self.tiles[tileY], generateTileAccordingLevel(tileX, tileY, self.colorSet, self.level))
        end
    end

    while self:calculateMatches() do
        
        -- recursively initialize if matches were returned so we always have
        -- a matchless board on start
        self:initializeTiles()
    end
    
    while not self:isMatchesExist() do
    	-- recursively initialize if no chance for matches
        -- a matchless board on start
        self:initializeTiles()
    end
end

--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color. Doesn't need to check the last tile in every row or column if the 
    last two haven't been a match.
]]
function Board:calculateMatches()
    local matches = {}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1
        
        -- every horizontal tile
        for x = 2, 8 do
            
            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                
                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}

                    -- go backwards from here by matchNum
                    for x2 = x - 1, x - matchNum, -1 do
                        
                        -- add each tile to the match that's in that match
                        table.insert(match, self.tiles[y][x2])
                        if self.tiles[y][x2].shiny then
                        	match = {}
                        	for x3 = 1, 8 do
                        		self.tiles[y][x3].frozen = true
                        		table.insert(match, self.tiles[y][x3])
                        	end
                        	break
                        end
                    end

                    -- add this match to our total matches table
                    table.insert(matches, match)
                end
                
                if matchNum >= 4 then
                	self.superMatchesCounter = self.superMatchesCounter + 1
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for x = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
                
                if self.tiles[y][x].shiny then
                    match = {}
                    for x2 = 1, 8 do
                        self.tiles[y][x2].frozen = true
                        table.insert(match, self.tiles[y][x2])
                    end
                    break
                end
            end

            table.insert(matches, match)
        end
                
        if matchNum >= 4 then
            self.superMatchesCounter = self.superMatchesCounter + 1
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}

                    for y2 = y - 1, y - matchNum, -1 do
                        table.insert(match, self.tiles[y2][x])
                        if self.tiles[y2][x].shiny then
                        	match = {}
                        	for y3 = 1, 8 do
                        		self.tiles[y3][x].frozen = true
                        		table.insert(match, self.tiles[y3][x])
                        	end
                        	break
                        end
                    end

                    table.insert(matches, match)
                end
                
                if matchNum >= 4 then
                	self.superMatchesCounter = self.superMatchesCounter + 1
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for y = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
                
                if self.tiles[y][x].shiny then
                    match = {}
                    for y2 = 1, 8 do
                        self.tiles[y2][x].frozen = true
                        table.insert(match, self.tiles[y2][x])
                    end
                    break
                end
            end

            table.insert(matches, match)
        end
                
        if matchNum >= 4 then
            self.superMatchesCounter = self.superMatchesCounter + 1
        end
    end

    -- store matches for later reference
    self.matches = matches

    -- return matches table if > 0, else just return false
    return #self.matches > 0 and self.matches or false
end

--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches()
    for k, match in pairs(self.matches) do
        for k, tile in pairs(match) do
            self.tiles[tile.gridY][tile.gridX] = nil
        end
    end

    self.matches = nil
end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do
            
            -- if our last tile was a space...
            local tile = self.tiles[y][x]
            
            if space then
                
                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then
                    
                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true
                
                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end
	
	local sizeOfTweensNew = 0
	-- new only tiles
	local tweensNew = {}
	      
    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                -- new tile with random color and variety
                local tile = generateTileAccordingLevel(x,y,self.colorSet,self.level)
                
                tile.y = -32
                self.tiles[y][x] = tile
                
                -- create a new tween to return for this tile to fall down
                tweensNew[tile] = {
                    y = (tile.gridY - 1) * 32
                }
                
                sizeOfTweensNew = sizeOfTweensNew + 1
                
            end
        end
    end
	
	local indexes = getRandomIndexes(self.superMatchesCounter,sizeOfTweensNew)
	
	tweensNew = makeShinyByIndexes(tweensNew,indexes)
	
	-- add tweenNew table to tween table
	for k, tweenNew in pairs(tweensNew) do
		tweens[k] = {
        	y = tweenNew['y']
        }
	end
    
    -- reset counter
    self.superMatchesCounter = 0

    return tweens
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)    
			-- particles
			if self.tiles[y][x].shiny then
				love.graphics.setColor(255, 255, 255, 180)
				love.graphics.draw(psystem, self.x + self.tiles[y][x].x + 16, self.y + self.tiles[y][x].y + 16)
			end
			-- particles end
        end
    end
end

function generateTileAccordingLevel(x,y,colorSet,level)
    return Tile(x, y, colorSet[math.random(#colorSet)], math.min(6,math.random(1 + math.floor(level/2))))
end

function getRandomIndexes(indexNum,maxValue)
	local indexes = {}   
	
	-- randomly choose indexes of tiles from tweens table, must be unique of course 
	if indexNum == 1 then
		indexes[1] = math.random(maxValue)
	elseif indexNum > 1 then		
		for k = 1, indexNum do
			while #indexes ~= k do
				--create random index from 1 to number of elements in table tween
				local index = math.random(maxValue)
				
				-- if we already have indexes in table indexes then check unique of variable index
				if #indexes > 0 then
					local unique = true
					for k2 = 1, #indexes do
						if index == indexes[k2] then
							-- if we already have this random index - change bool var unique to false
							unique = false
						end
					end
					-- if index unique - add it to table
					if unique then
						indexes[k] = index
					end
				-- if shinyTilesIndexes == 0 - add index in table
				else
					indexes[k] = index
				end
			end
		end
	end
	
	return indexes
end

function makeShinyByIndexes(table,indexes)
	if #indexes > 0 then
		for k = 1, #indexes do
			counter = 1
			for key, row in pairs(table) do
				if counter == indexes[k] then
					key.shiny = true
					break
				else
					counter = counter + 1
				end
			end
		end
	end
	
	return table
end

function createColorSet()
	local colorSet = {}
	local colors = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18}
    local counter = 1
    
    while counter <= 8 do
    	local randomIndex = math.random(#colors)
    	colorSet[counter] = colors[randomIndex]
    	table.remove(colors,randomIndex)
    	counter = counter + 1
    end
    
    return colorSet
end

function Board:isMatchesExist()
	local matchExist = false
	
	for x = 1,8 do
		if matchExist then break end
		for y = 1,8 do
			if matchExist then break end
			if x <= 7 and y <= 6 then
				if isTilesEquel(self.tiles, {x, y}, {x, y+1}, {x+1, y+2}) then
					matchExist = {x+1, y+2}
					break
				elseif isTilesEquel(self.tiles, {x+1, y}, {x+1, y+1}, {x, y+2}) then
					matchExist = {x, y+2}
					break
				elseif isTilesEquel(self.tiles, {x, y}, {x+1, y+1}, {x+1, y+2}) then
					matchExist = {x, y}
					break
				elseif isTilesEquel(self.tiles, {x+1, y}, {x, y+1}, {x, y+2}) then
					matchExist = {x+1, y}
					break
				elseif isTilesEquel(self.tiles, {x, y}, {x+1, y+1}, {x, y+2}) then
					matchExist = {x+1, y+1}
					break
				elseif isTilesEquel(self.tiles, {x+1, y}, {x, y+1}, {x+1, y+2}) then
					matchExist = {x, y+1}
					break
				end
			end
			if x <= 6 and y <= 7 then
				if isTilesEquel(self.tiles, {x, y}, {x+1, y}, {x+2, y+1}) then
					matchExist = {x+2, y+1}
					break
				elseif isTilesEquel(self.tiles, {x, y+1}, {x+1, y}, {x+2, y}) then
					matchExist = {x, y+1}
					break
				elseif isTilesEquel(self.tiles, {x, y}, {x+1, y+1}, {x+2, y+1}) then
					matchExist = {x, y}
					break
				elseif isTilesEquel(self.tiles, {x, y+1}, {x+1, y+1}, {x+2, y}) then
					matchExist = {x+2, y}
					break
				elseif isTilesEquel(self.tiles, {x, y+1}, {x+1, y}, {x+2, y+1}) then
					matchExist = {x+1, y}
					break
				elseif isTilesEquel(self.tiles, {x, y}, {x+1, y+1}, {x+2, y}) then
					matchExist = {x+1, y+1}
					break
				end
			end
			if y <= 5 then
				if isTilesEquel(self.tiles, {x, y}, {x, y+1}, {x, y+3}) then
					matchExist = {x, y+3}
					break
				elseif isTilesEquel(self.tiles, {x, y}, {x, y+2}, {x, y+3}) then
					matchExist = {x, y}
					break
				end
			end
			if x <= 5 then
				if isTilesEquel(self.tiles, {x, y}, {x+1, y}, {x+3, y}) then
					matchExist = {x+3, y}
					break
				elseif isTilesEquel(self.tiles, {x, y}, {x+2, y}, {x+3, y}) then
					matchExist = {x, y}
					break
				end
			end
		end
	end
	
	self.hint = matchExist
	
	if matchExist then
		return true
	else
		return false
	end
end

function isTilesEquel(tiles, tile1GridXY, tile2GridXY, tile3GridXY )
	if tiles[tile1GridXY[2]][tile1GridXY[1]].color == tiles[tile2GridXY[2]][tile2GridXY[1]].color and
		tiles[tile1GridXY[2]][tile1GridXY[1]].color == tiles[tile3GridXY[2]][tile3GridXY[1]].color then
		return true
	else
		return false
	end
end