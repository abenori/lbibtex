require "lbt-funcs"
require "lbt-template"
std_styles = require "lbt-style-std"
local icu = require "lbt-string"
local U = icu.ustring

BibTeX.macros[U"jan"] = U"Jan."
BibTeX.macros[U"feb"] = U"Feb."
BibTeX.macros[U"mar"] = U"Mar."
BibTeX.macros[U"apr"] = U"Apr."
BibTeX.macros[U"may"] = U"May"
BibTeX.macros[U"jun"] = U"June"
BibTeX.macros[U"jul"] = U"July"
BibTeX.macros[U"aug"] = U"Aug."
BibTeX.macros[U"sep"] = U"Sept."
BibTeX.macros[U"oct"] = U"Oct."
BibTeX.macros[U"nov"] = U"Nov."
BibTeX.macros[U"dec"] = U"Dec."
BibTeX.macros[U"acmcs"] = U"ACM Comput. Surv."
BibTeX.macros[U"acta"] = U"Acta Inf."
BibTeX.macros[U"cacm"] = U"Commun. ACM"
BibTeX.macros[U"ibmjrd"] = U"IBM J. Res. Dev."
BibTeX.macros[U"ibmsj"] = U"IBM Syst.~J."
BibTeX.macros[U"ieeese"] = U"IEEE Trans. Softw. Eng."
BibTeX.macros[U"ieeetc"] = U"IEEE Trans. Comput."
BibTeX.macros[U"ieeetcad"] = U"IEEE Trans. Comput.-Aided Design Integrated Circuits"
BibTeX.macros[U"ipl"] = U"Inf. Process. Lett."
BibTeX.macros[U"jacm"] = U"J.~ACM"
BibTeX.macros[U"jcss"] = U"J.~Comput. Syst. Sci."
BibTeX.macros[U"scp"] = U"Sci. Comput. Programming"
BibTeX.macros[U"sicomp"] = U"SIAM J. Comput."
BibTeX.macros[U"tocs"] = U"ACM Trans. Comput. Syst."
BibTeX.macros[U"tods"] = U"ACM Trans. Database Syst."
BibTeX.macros[U"tog"] = U"ACM Trans. Gr."
BibTeX.macros[U"toms"] = U"ACM Trans. Math. Softw."
BibTeX.macros[U"toois"] = U"ACM Trans. Office Inf. Syst."
BibTeX.macros[U"toplas"] = U"ACM Trans. Prog. Lang. Syst."
BibTeX.macros[U"tcs"] = U"Theoretical Comput. Sci."


BibTeX:read()
std_styles.CrossReference:modify_citations(BibTeX)
BibTeX:output_citation_check(LBibTeX.citation_check(BibTeX.cites))

function std_styles.Template.Formatter:nameformat(c) return "{f.~}{vv~}{ll}{, jj}" end

local f1 = std_styles.Template:make(std_styles.Template.Templates,std_styles.Template.Formatter)
local f2 = std_styles.Template:make(std_styles.CrossReference.Templates,std_styles.Template.Formatter)
local f = std_styles.CrossReference:make_formatter(f1,f2)
BibTeX:outputthebibliography(f)
