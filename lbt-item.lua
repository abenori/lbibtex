require "lbt-core"
local icu = require "lbt-string"
local U = icu.ustring

function U:toustring()
	return self
end

local function addperiod(s)
	if s:find(U"%.[ ~]*$") == nil then return s .. U"."
	else return s end
end

LBibTeX.bibitem = {}
function LBibTeX.bibitem.new(ref,label)
	local obj = {ref = ref, label = label}
	return setmetatable(obj,{__index = LBibTeX.bibitem, __tostring = LBibTeX.bibitem.tostring})
end

function LBibTeX.bibitem:toustring()
	local r = U"\\bibitem"
	if self.label ~= nil then r = r .. U"[" .. self.label .. U"]" end
	return r .. U"{" .. self.ref .. U"}"
end

function LBibTeX.bibitem:tostring()
	return tostring(self:toustring())
end

LBibTeX.block = {}
function LBibTeX.block.new(sep, las, c)
	if type(sep) == "string" then sep = U(sep) end
	if type(las) == "string" then las = U(las) end
	local obj = {defaultseparator = sep, last = las, contents = c, separators={}}
	if obj.defaultseparator == nil then obj.defaultseparator = U"" end
	if obj.last == nil then obj.last = U"" end
	if obj.contents == nil then obj.contents = {} end
	return setmetatable(obj,{__index = LBibTeX.block, __tostring = LBibTeX.block.tostring});
end

function LBibTeX.block:additem(c)
	table.insert(self.contents,c)
end

function LBibTeX.block:addarrayitem(c)
	for i = 1,#c do
		self:additem(c[i])
	end
end

function LBibTeX.block:setseparator(i,s)
	self.separators[i] = s
end

function LBibTeX.block:tostring()
	return tostring(self:toustring())
end

function LBibTeX.block:toustring()
	local r = U""
	for i = 1,#self.contents do
		local sep
		if self.separators[i] == nil then sep = self.defaultseparator
		else sep = self.separators[i] end
		if sep.toustring ~= nil then sep = sep:toustring()
		elseif type(sep) == "string" then sep = U(sep)
		end
		local periodfirst = false
		if sep ~= U"" then
			if sep:sub(1,1) == U"." then
				periodfirst = true
				sep = sep:sub(2)
			elseif sep:sub(1,1) == U"\\" then
				sep = sep:sub(2)
			end
		end
		local c = self.contents[i]
		local s
		if c.toustring ~= nil then s = c:toustring()
		else s = U(tostring(c)) end
		if s ~= U"" then
			if r == U"" then
				r = s
			else
				if periodfirst then
					r = addperiod(r) .. sep .. s
				else
					r = r .. sep .. s
				end
			end
		end
	end
	if r == U"" then return U"" end
	if self.last:sub(1,1) == U"." then
		r = addperiod(r) .. self.last:sub(2)
	else
		r = r .. self.last
	end
	return r
end


