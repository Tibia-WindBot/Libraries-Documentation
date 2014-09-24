-- could also be improved to create alternate invocations
-- when receiving rettype with {type|type} behavior

-- fucking functions to run
function string.ltrim(self, chars)
	chars = chars or '%s'
	if type(chars) == 'table' then
		chars = '[' .. table.concat(chars, '') .. ']'
	end
	chars = chars:gsub('%.', '%%.')
	return self:gsub('^' .. chars .. '*(.-)$', '%1')
end
function string.rtrim(self, chars)
	chars = chars or '%s'
	if type(chars) == 'table' then
		chars = '[' .. table.concat(chars, '') .. ']'
	end
	chars = chars:gsub('%.', '%%.')
	return self:gsub('^(.-)' .. chars .. '*$', '%1')
end
function string.trim(self, chars)
	return self:ltrim(chars):rtrim(chars)
end
function string.explode(self, delimiter)
	local result = {}
	self:gsub('[^'.. delimiter ..'*]+', function(s) table.insert(result, (string.gsub(s, '^%s*(.-)%s*$', '%1'))) end)
	return result
end
sf = string.format
-- funcking patterns
local JSON_PAT = [[{
	"name": %q,
	"invocations": [
		{
			"rettype": %q,
			"args": [%s],
			"description": %q
		}
	]
}
]]

local ARGS_PAT = [[				{
					"type": %q,
					"name": %q
				}]]

-- fucking code
local file, str = io.open("C:\\Program Files (x86)\\WindBot\\libs\\Raphael.lua", 'r')

if file then
	str = file:read("*a")
	file:close()
else
	print("No such file, wrong directory or shit happened.")
end

for doc, func in str:sub(200):gmatch('%-%-%[%[(\n %*.-\n)%-%-%]%]\nfunction (.-)%(') do
	local desc, rest = doc:match('(.-)\n %* @since(.+)')
	desc = desc:gsub("\n %*", "")
	local pars, rettype = {}, "null"

	if doc:find("@para") then
		for par in rest:gmatch("param(.-)@") do
			local ptype, pname, pdesc = par:match("(%b{})%s+(.-)%s+%-%s+(.-)")
			local opt = false

			if ptype and pname and pdesc then
				ptype = ptype:gsub("[^%a]+", "")

				pdesc = pdesc:gsub("\n %*%s+", "")

				if pname:sub(1, 1) == '[' then
					opt = true
					pname = pname:gsub("[^%a]+", "")
				end

				pname = pname:gsub("any", "various")

				table.insert(pars, {name = pname, ret = ptype, desc = pdesc, opt = opt})
			end
		end
	end

	if doc:find("@returns") then
		rettype = rest:match("@returns%s+(%b{})"):gsub("[^%a]+", "")
		rettype = rettype:gsub("any", "various")
	end

	local fl = io.open(func .. ".json", "w+")

	if fl then
		local tempp = ''

		for i = 1, #pars do
			local p = pars[i]
			
			if i > 1 then
				tempp = tempp .. ",\n"
			end
			
			tempp = tempp .. sf(ARGS_PAT, (p.opt and "optional " or '') .. p.ret, p.name)
		end

		if #pars > 0 then
			tempp = "\n" .. tempp .. "\n				"
		end

		local txt = sf(JSON_PAT, func, rettype, tempp:sub(1, -2), desc:trim()):gsub([["rettype": "null",]], [["rettype": null,]])
		fl:write(txt)
		fl:flush()
		fl:close()
	end
end
