
lain = require "lainlib"



--Module loca--
local loc = {}


----Some tool functions in loca----*
getToken = function(line, i_fromIndex, div)

	i_fromIndex = i_fromIndex or 1
	div = div or " "

	local str_ans = ""
	local flag = true
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

	local ans = ""
	local cutFlag = false

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


getPreDir = function(str_path)

	local ans = ""
	local flag = false
	for i = 1, #str_path do

		if (flag == true) then
			ans = str_path:sub(-i, -i)..ans

		elseif (str_path:sub(-i, -i) == "\\" or str_path:sub(-i, -i) == "/") then
			flag = true

		end
	end

	if (ans ~= "") then
		ans = ans .. "/"
	end
	return ans
end


removePreDir = function(str_path)

	local ans = ""
	for i = 1, #str_path do

		if (str_path:sub(-i, -i) ~= "\\" and str_path:sub(-i, -i) ~= "/") then
			ans = str_path:sub(-i, -i)..ans

		else
			break
		end
	end

	return ans

end











----Config in loc---------------------------------------------------------------



loc.Config = function(str_startFile, t_filterLinks)

	local this = {}
	this.str_startFile = str_startFile or "unknown"
	this.t_filterLinks = filterLinks or "none"

	if (this.t_filterLinks ~= "none") then

		local t_tmp = {}
		local index = "abcdefghijklmnopqrstuvwxyz"
		for i = 1, 26 do
			t_tmp[index:sub(i, i)] = {}
			t_tmp[index:sub(i, i)]["nr"] = 0
			t_tmp[string.upper(index:sub(i, i))] = {}
			t_tmp[string.upper(index:sub(i, i))]["nr"] = 0
		end

		for k, v in pairs(filterLinks) do
			table.insert(t_tmp[v:sub(1, 1)], 1, v)
			t_tmp[v:sub(1, 1)]["nr"] = t_tmp[v:sub(1, 1)]["nr"] + 1
		end

		this.t_filterLinks = t_tmp
	end

	return this
end






----class Loc in loc------------------------------------------------------------



loc.Loc = function(config)

	---parameters---
	local this = {}

	this.config = config


	---Tree to save links---*

	this.linkTree = nil


	---open file---
	this.getLinesFrom = function(self, str_path)

		--self:debug_printSearchPath(str_path, "unkonwn")
		return assert(io.lines(str_path))
	end

	----locate tool function----*
	this.locateOrder = function(self, str, str_preKey, str_afterKey)

		local x, y = str:find(str_preKey)
		if (x and y) then
			local str_next = getToken(str, y+2)
			if (str_next == str_afterKey) then
				return x
			end
		end
		return nil
	end--locateOrder

	this.locateKey = function(self, str, str_key)

		local x, y = str:find(str_key)
		if (x and y) then
			return x, y
		end
	end


	---get whole file---
	this.getAllFrom = function(self, str_path)

		local iter_lines = self:getLinesFrom(str_path)
		local str_ans = ""
		for line in iter_lines do
			str_ans = str_ans .. line .. "\n"
		end

		return str_ans
	end


	----link functions----*

	---get links---*
	this.getLinksFrom = function(self, str_path)

		local iter_lines = self:getLinesFrom(str_path)

		local links = {}
		for line in iter_lines do

			local x, y = self:locateKey(line, "#include")
			if (x and y) then

				str_tmpLink = strip(getToken(line, y + 2, ' '), '"')
				table.insert(links, 1, getPreDir(str_path)..str_tmpLink)
			end
		end
		--lain.printDict(links)
		links = self:filterLinks(links)

		return links
	end

	---filter useless links---
	this.filterLinks = function(self, t_testLinks)

		local res = {}
		local res_counter = 0
		local flag = true		--if true we leave it in
		for k, v in pairs(t_testLinks) do

			tmp_v = removePreDir(v)
			if (tmp_v:sub(1,1) == "<" or tmp_v:sub(-1,-1) == ">") then
				break
			end
			--print(tmp_v:sub(1,1))
			if (self.config.t_filterLinks[tmp_v:sub(1,1)]["nr"] ~= 0) then

				for k_, v_ in pairs(self.config.t_filterLinks[tmp_v:sub(1,1)]) do
					--print(removePreDir(v))
					if (tmp_v == v_) then
						flag = false
					end
				end
			end

			if (flag == true) then

				table.insert(res, 1, v)
			else
				flag = true
			end

		end

		return res
	end



	----some powerful functions----*



	---locate any type definition!---
	this.locateType = function(self, str_type)


		local from
		from =  function(str_filePath, str_key)

			local findFlag = false
			local ans = {}

			--first we scan startFile, trying to find key in it--
			local iter_lines = self:getLinesFrom(str_filePath)

			local lineCounter = 1
			for line in iter_lines do
				local x = self:locateOrder(line, str_type, str_key)
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

					self:debug_printSearchPath(v, str_filePath)
					ans = from(v, str_key)
					if (ans.lineNr ~= nil) then
						break
					end
				end--for

			end

			if (ans == nil) then
				print("-> failed to find"..str_key)
			end
			return ans

		end--from

		return from
	end


	---locate class definition!---
	this.locateClassFrom = function(self, str_filePath, str_key)

		local findFlag = false
		local ans = {}

		--first we scan startFile, trying to find key in it--
		local iter_lines = self:getLinesFrom(str_filePath)

		local lineCounter = 1
		for line in iter_lines do
			local x = self:locateOrder(line, "class", str_key)
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

				self:debug_printSearchPath(v)
				ans = self:locateClassFrom(v, str_key)
				if (ans.lineNr ~= nil) then
					break
				end
			end--for

		end

		return ans
	end--locateClassFrom


	---locate macro definition!---
	this.locateMacroFrom = function(self, str_filePath, str_key)

		local findFlag = false
		local ans = {}

		--first we scan startFile, trying to find key in it--
		local iter_lines = self:getLinesFrom(str_filePath)

		local lineCounter = 1
		for line in iter_lines do

			local x = self:locateOrder(line, "#define", str_key)
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


	---locate function definition!---
	this.locateFunctionFrom = function(self, str_key)

		local findFlag = false
		local ans = {}
		local types = {
			"int", "double", "float", "unsigned"
		}

		--first we scan startFile, trying to find key in it--
		local iter_lines = self:getLinesFrom(str_filePath)

		local lineCounter = 1
		for line in iter_lines do

			local x = self:locateKey(line, str_key)
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


	----debug functions----*

	this.debug_printSearchPath = function(self, str_linkPath, str_fromPath)

		print(str_linkPath.."\t<-\t"..str_fromPath)
	end




	return this
end---class Loc---








----test-----------------------------------------------------------------------------


filterLinks = {
	"irrlicht.h",
	"irrTypes.h",
	"string",
	"map",
	"IVideoDriver.h",
	"aabbox3d.h",
	"irrlichttypes_extrabloated.h",
	"enriched_string.h",
	"test.h",
	"cmake_config.h",
	"android_version.h",
	"irr_v3d.h",
	"database.h",
	"porting.h",
	"irrlichttypes.h",
	"socket.h",
	"stdafx.h",
	"lainlib.h"
}


config = loc.Config("test/player.cpp", filterLinks)

test = loc.Loc(config)
--print(test:getAllFrom("test/player.cpp"))


res = test:locateType("class")("test/player.cpp", "Player")
print("----------------result-----------------")
lain.printDict(res)






