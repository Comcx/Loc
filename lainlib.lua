
local lain = {}

--set default parameter--
lain.setDefaultParam = function(param, defaultValue)

	if (param == nil) then
		param = defaultValue
	end

	return param
end

--print table(dict)--
lain.printDict = function(dict)

	for key, value in pairs(dict) do
		print(key..":\t"..value)

	end

end





return lain
