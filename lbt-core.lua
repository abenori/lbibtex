local icu = require "lbt-string"
local U = icu.ustring

if LBibTeX == nil then LBibTeX = {} end

require "lbt-database"

-- bblを表す構造
-- LBibTeX.LBibTeX.aux, LBibTeX.LBibTeX.style, LBibTeX.LBibTeX.cites, LBibTeX.LBibTeX.bibs, LBibTeX.LBibTeX.bbl (stream)

LBibTeX.LBibTeX = {}
setmetatable(LBibTeX.LBibTeX,{__index = LBibTeX.Database})

function LBibTeX.LBibTeX.new()
	local obj = LBibTeX.Database.new()
	obj.style = ""
	obj.aux = ""
	obj.cites = {}
	obj.bibs = {}
	obj.bbl = nil
	obj.blg = nil
	return setmetatable(obj,{__index = LBibTeX.LBibTeX})
end

function LBibTeX.LBibTeX:load_aux(file)
	local aux = LBibTeX.LBibTeX.read_aux(file)
	self.style = aux.style
	self.aux = aux.aux
	self.cites = aux.cites
	self.bibs = aux.bibs
	self.bbl = icu.ufile.open(U.encode(aux.bbl),"w")
	self.blg = icu.ufile.open(U.encode(aux.blg),"w")
	self.warning_count = 0
	for i = 1,#self.bibs do
		local bibfile = kpse.find_file(self.bibs[i],"bib")
		if bibfile == nil or self:read(bibfile) == false then
			self:dispose()
			return false,"Cannot find Database file " .. self.bibs[i]
		else
			self:message(U"Database file #" .. U(tostring(i)) .. U": " .. self.bibs[i])
		end
	end
	if self.cites == nil then
		-- \cite{*}
		self.cites = {}
		for k,v in pairs(self.db) do
			self.cites[#self.cites + 1] = v
		end
	else
		local n = #self.cites
		local i = 1
		while i <= n do
			local k = self.cites[i].key
			if self.db[k] == nil then
				self:warning(U"I don't find a database entry for \"" .. k .. U"\"")
				table.remove(self.cites,i)
				i = i - 1
				n = n - 1
			else
				self.cites[i] = self.db[k]
			end
			i = i + 1
		end
	end
	return true
end

local function includeskey(table,key)
	for i = 1, #table do
		if key == table[i].key then return true end
	end
	return false
end

local function getargument(str)
	local start = str:find(U"{")
	if start == nil then return nil end
	start = start + 1
	local r = start
	local nest = 0;
	while true do
		r = str:find(U"[{}]",r + 1)
		if r == nil then return nil end
		local s = str:sub(r,r)
		if s == "{" then
			nest = nest + 1;
		elseif s == U"}" then
			if nest == 0 then
				return str:sub(start,r - 1)
			else
				nest = nest - 1
			end
		end
	end
end

-- style/aux/cites/bibs/bbl/blg
function LBibTeX.LBibTeX.read_aux(file)
	local citation = {}
	local database = {}
	local bbl = {}
	local citeall = false
	local f
	local style
	if type(file) ~= "string" then f = U.encode(file)
	else f = file  file = U(file) end
	local fp,msg = io.open(f,"r")
	if fp == nil then return nil,msg end
	fp:close()
	fp = icu.ufile.open(f,"r","UTF-8")
	for line in fp:lines() do
		local r = line:find(U"\\citation{")
		if r ~= nil then
			local a = getargument(line:sub(r))
			if a == U"*" then
				citeall = true
			else
				if not includeskey(citation,a) then
					local c = LBibTeX.Citation.new()
					c.key = a
					table.insert(citation,c)
				end
			end
		end
		r = line:find(U"\\bibstyle{")
		if r ~= nil then
			style = getargument(line:sub(r))
		end
		r = line:find(U"\\bibdata{")
		if r ~= nil then
			local p = 1
			local a = getargument(line:sub(r))
			while true do
				local q = a:find(U",",p)
				if q == nil then
					table.insert(database,a:sub(p))
					break
				else
					table.insert(database,a:sub(p,q - 1))
				end
				p = q + 1;
			end
		end
	end
	fp:close()
	local obj = {}
	obj.style = style
	local r = file:find(U"%.[^./]*$")
	local bbl,blg
	if r == nil then
		bbl = file .. U".bbl"
		blg = file .. U".blg"
	else
		bbl = file:sub(1,r) .. U"bbl"
		blg = file:sub(1,r) .. U"blg"
	end
	obj.aux = file
	if citeall then obj.cites = nil
	else obj.cites = citation end
	obj.bibs = database
	obj.bbl = bbl
	obj.blg = blg
	return obj;
end

local function table_connect(a,b)
	for i = 1,#b do
		table.insert(a,b[i])
	end
	return a
end

function LBibTeX.LBibTeX:dispose()
	if self.warning_count == 1 then self:message("(There was a warning.)")
	elseif self.warning_count > 0 then self:message("(There were " .. tostring(self.warning_count) .. " warnings.)")
	end
	if self.bbl ~= nil then self.bbl:close() self.bbl = nil end
	if self.blg ~= nil then self.blg:close() self.blg = nil end
end

function LBibTeX.LBibTeX:get_longest_label()
	local max_len = 0
	local max_len_label = nil
	for i = 1, #self.cites do
		local label
		if self.cites[i].label ~= nil then
			label = self.cites[i].label
			if label:len() > max_len then
				max_len = label:len()
				max_len_label = label
			end
		end
	end
	return max_len_label
end

function LBibTeX.LBibTeX:output(s)
	if type(s) == "string" then s = U(s) end
	self.bbl:write(s)
end

function LBibTeX.LBibTeX:outputline(s)
	if type(s) == "string" then s = U(s) end
	self.bbl:write(s .. U"\n")
end

local emptystr = U""
local trim_str1 = U"^[ \n\t]*"
local trim_str2 = U"[ \n\t]*$"
local function trim(str)
--	return str:gsub(U"^[ \n\t]*(.-)[ \n\t]*$",U"%1")
	return str:gsub(trim_str1,emptystr):gsub(trim_str2,emptystr)
end


function LBibTeX.LBibTeX:outputcites(formatter)
	for i = 1, #self.cites do
		local t = self.cites[i].type
		if t ~= nil then
			local f = formatter[t]
			if f == nil then f = formatter[tostring(t)] end
			if f == nil then
				self:warning(U"no style is defined for " .. t)
				f = formatter[U""]
				if f == nil then f = formatter[""] end
				if f == nil then self:error(U"default style is not defined") end
			else
				local s = U"\\bibitem"
				local label = self.cites[i].label
				if label ~= nil then
					if type(label) == "string" then label = U(label) end
					s = s .. U"[" .. label .. U"]"
				end
				local key = self.cites[i].key
				if type(key) == "string" then key = U(key) end
				s = s .. U"{" .. key .. U"}"
				self:outputline(s)
				s = f(self.cites[i])
				if type(s) == "string" then s = U(s)
				elseif s.toustring ~= nil then s = s:toustring()
				end
				self:outputline(trim(s:gsub(U"  +",U" ")))
				self:outputline(emptystr)
			end
		end
	end
end

function LBibTeX.LBibTeX:outputthebibliography(formatter)
	local longest_label = self:get_longest_label()
	if longest_label == nil then longest_label = U(tostring(#self.cites)) end
	self:outputline(self.preamble)
	self:outputline(U"\\begin{thebibliography}{" .. longest_label .. U"}")
	self:outputcites(formatter)
	self:outputline(U"\\end{thebibliography}")
end

local equal = U"="

-- key に = が入っていると失敗する．
local function getkeyval(str)
	local eq = str:find(equal)
	if eq == nil then return str,nil end
	local key = trim(str:sub(1,eq-1))
	local val = trim(str:sub(eq+1))
	return key,val
end

function LBibTeX.LBibTeX:warning(s)
	self.warning_count = self.warning_count + 1
	if type(s) == "string" then s = U(s) end
	print(U"LBibTeX warning: " .. s)
	if self.blg ~= nil then self.blg:write(U"LBibTeX warning: " .. s .. U"\n") end
end

function LBibTeX.LBibTeX:error(s,exit_code)
	if type(s) == "string" then s = U(s) end
	print(U"LBibTeX error: " .. s .. U"\n")
	if self.blg ~= nil then self.blg:write(U"LBibTeX error: " .. s .. U"\n") end
	if exit_code == nil then exit_code = 1 end
	self:dispose()
	os.exit(exit_code)
end

function LBibTeX.LBibTeX:log(s)
	if type(s) == "string" then s = U(s) end
	if self.blg ~= nil then self.blg:write(s .. U"\n") end
end

function LBibTeX.LBibTeX:message(s)
	print(s)
	if type(s) == "string" then s = U(s) end
	if self.blg ~= nil then self.blg:write(s .. U"\n") end
end

---------------------------------------------------
LBibTeX.debug = {}
function LBibTeX.debug.outputarray(a)
	print("array size = " .. tostring(#a) .. "\n")
	for i = 1, #a do
		print("i = " .. tostring(i) .. ", type = " .. type(a[i]) .. "\n" .. tostring(a[i]))
	end
end


