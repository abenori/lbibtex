require "lbt-funcs"
require "lbt-template"
std_styles = require "lbt-style-std"

for v,k in pairs(std_styles.macros) do
	BibTeX.macros[v] = k
end

BibTeX.cites = std_styles.CrossReference:modify_citations(BibTeX.cites,BibTeX)
BibTeX:output_citation_check(LBibTeX.citation_check(BibTeX.cites))

local f1 = std_styles.Template:make(std_styles.Template.Templates,std_styles.Template.Formatter)
local f2 = std_styles.Template:make(std_styles.CrossReference.Templates,std_styles.Template.Formatter)
local f = std_styles.CrossReference:make_formatter(f1,f2)
BibTeX:outputthebibliography(f)

