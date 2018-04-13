
lain = require("lainlib")


--Module loca--
local loc = {}


--Some tool functions in loca--*
getToken = function(line, i_fromIndex, div)

	i_fromIndex = lain.setDefaultParam(i_fromIndex, 1)
	div = lain.setDefaultParam(div, " ")

	str_ans = ""
	flag = true
	for i = i_fromIndex, string.len(line) do

		for j = 1, #div do
			if (line:sub(i, i) ~= div:sub(j, j)) then
				str_ans = str_ans .. line:sub(i, i)
			else
				flag = false
			end

		end

		if (flag == false) then
			break
		end
	end

	return str_ans
end--getToken


strip = function(str, cut)

	ans = ""
	cutFlag = false

	for i = 1, #str do
		for j = 1, #cut do
			if (str:sub(i, i) == cut:sub(j, j)) then
				cutFlag = true
			end
		end

		if (cutFlag == false) then
			ans = ans..str:sub(i, i)
		else
			cutFlag = false
		end
	end

	return ans
end








--class Loc in loc------------------------------------------------------------

loc.Loc = function(str_startFile)

	---parameters---
	this = {}
	this.str_path = path
	this.str_startFile = lain.setDefaultParam(str_startFile, "unknown")

	--open file--
	this.getLinesFrom = function(self, str_path)

		return io.lines(str_path)
	end

	---locate tool function---*
	this.locateOrder = function(self, str, str_preKey, str_afterKey)

		x, y = str:find(str_preKey)
		if (x and y) then
			str_next = getToken(str, y+2)
			if (str_next == str_afterKey) then
				return x
			end
		end

	end--locateOrder

	this.locateKey = function(self, str, str_key)

		x, y = str:find(str_key)
		if (x and y) then
			return x, y
		end
	end


	--get whole file--
	this.getAllFrom = function(self, str_path)

		iter_lines = self:getLinesFrom(str_path)
		str_ans = ""
		for line in iter_lines do
			str_ans = str_ans .. line .. "\n"
		end

		return str_ans
	end

	--get links--*
	this.getLinksFrom = function(self, str_path)

		iter_lines = self:getLinesFrom(str_path)

		links = {}
		counter = 1
		for line in iter_lines do
			x, y = self:locateKey(line, "#include")
			if (x and y) then
				links[counter] = strip(getToken(line, y + 2, ' '), '"<>')
				counter = counter + 1
			end
		end

		return links
	end





	---some powerful functions---*

	--locate class definition!--
	this.locateClassFrom = function(self, str_filePath, str_key)

		findFlag = false
		ans = {}

		--first we scan startFile, trying to find key in it--
		iter_lines = self:getLinesFrom(str_filePath)

		lineCounter = 1
		for line in iter_lines do
			x = self:locateOrder(line, "class", str_key)
			if (x ~= nil) then
				ans.str_path = str_filePath
				ans.lineNr = lineCounter
				findFlag = true
			end

			lineCounter = lineCounter + 1
		end

		--if we failed to find class in startFile--
		if (findFlag == false) then

			links = self:getLinksFrom(str_filePath)
			for k, v in ipairs(links) do
				ans = self:locateClassFrom(v, str_key)
				if (ans.lineNr ~= nil) then
					break
				end
			end--for

		end

		return ans
	end--locateClassFrom


	--locate macro definition!--
	this.locateMacroFrom = function(self, str_filePath, str_key)

		findFlag = false
		ans = {}

		--first we scan startFile, trying to find key in it--
		iter_lines = self:getLinesFrom(str_filePath)

		lineCounter = 1
		for line in iter_lines do

			x = self:locateOrder(line, "#define", str_key)
			if (x ~= nil) then
				ans.str_path = str_filePath
				ans.lineNr = lineCounter
				findFlag = true
			end

			lineCounter = lineCounter + 1
		end

		--if we failed to find class in startFile--
		if (findFlag == false) then

			links = self:getLinksFrom(str_filePath)
			for k, v in ipairs(links) do
				ans = self:locateMacroFrom(v, str_key)
				if (ans.lineNr ~= nil) then
					break
				end
			end--for

		end


		return ans
	end


	--locate function definition!--
	this.locateFunctionFrom = function(self, str_key)

		findFlag = false
		ans = {}
		types = {
			"int", "double", "float", "unsigned"
		}

		--first we scan startFile, trying to find key in it--
		iter_lines = self:getLinesFrom(str_filePath)

		lineCounter = 1
		for line in iter_lines do

			x = self:locateKey(line, str_key)
			if (x ~= nil) then
				params = getToken(line, x+#str_key+1, "){")
				if (self:locateKey(param, "int")) then

				end
				ans.str_path = str_filePath
				ans.lineNr = lineCounter
				findFlag = true
			end

			lineCounter = lineCounter + 1
		end

		--if we failed to find class in startFile--
		if (findFlag == false) then

			links = self:getLinksFrom(str_filePath)
			for k, v in ipairs(links) do
				ans = self:locateMacroFrom(v, str_key)
				if (ans.lineNr ~= nil) then
					break
				end
			end--for

		end


		return ans

	end--locate function


	this.debug_searchPath = function()

	end




	return this
end--class Loc--










test = loc.Loc("player.cpp")

--str = test:getAllFrom("player.cpp")
--links = test:getLinksFrom("player.cpp")

--[[
for k, v in ipairs(links) do
	print(v)
end]]--

ans = test:locateClassFrom("player.cpp", "Player")
lain.printDict(ans)





