{smcl}
{* *! version ??? feb2018}{...}
{vieweralsosee "[R] ivregress" "help ivregress"}{...}
{viewerjumpto "Syntax" "ts2sls##syntax"}{...}
{viewerjumpto "Description" "ts2sls##description"}{...}
{viewerjumpto "Options" "ts2sls##options"}{...}
{viewerjumpto "Remarks" "ts2sls##remarks"}{...}
{viewerjumpto "Examples" "ts2sls##examples"}{...}
{viewerjumpto "Stored results" "ts2sls##results"}{...}
{viewerjumpto "Author" "ts2sls##author"}{...}
{viewerjumpto "References" "ts2sls##references"}{...}

{* ************************TITLE*************************}{...}
{title:Title}

{phang}
{cmd:ts2sls} {hline 2} Estimates two-sample two stage least squares where the samples may overlap

{* ************************SYNTAX*************************}{...}
{title:Syntax}

{p 8 17 2}
{cmd:ts2sls} {depvar} [{help varlist:{it:varlist1}}] {bf:({help varlist:{it:varlist2}} = {help varlist:{it:varlist_iv}})} {ifin} {it:{weight}}  [, {help ts2sls##options:options}]

{phang} {it:varlist1} is the list of exogenous variables. {p_end}

{phang} {it:varlist2} is the list of endogenous variables. {p_end}

{phang} {it:varlist_iv} is a list of the exogenous variables used with {it:varlist1} as instruments for {it:varlist2} {p_end}


{* ************************OPTIONS TABLE*************************}{...}
{synoptset tabbed}
{synopthdr}
{synoptline}
{* *****MODEL OPTIONS in brief *****}{...}
{syntab:Model {help ts2sls##opt_model:[+]}}
{synopt:{bf:iffirst}({it:str})}sample for first stage {p_end}
{synopt:{bf:ifsecond}({it:str})}sample for second stage {p_end}
{synopt:{bf:absorb({varlist}})}absorb {varlist} {p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}

{* *****SE/ROBUST OPTIONS in brief *****}{...}
{syntab:SE/Robust {help ts2sls##opt_se:[+]}}
{synopt:{opt rob:ust}}Eicker-White heteroskedastic robust standard errors {p_end}
{synopt:{opt clu:ster}({varname})}Standard errors clustered by {varname} {p_end}
{synopt:{opt independent}}Treat first stage and second stage samples as independent. Think carefully about this option if {opt cluster} specified and the first and second stage samples contain data drawn from the same cluster.{p_end}
{synopt:{opt small}}Apply Stata small sample adjustment to standard errors. {p_end}

{* *****REPORTING OPTIONS in brief *****}{...}
{syntab:Reporting}
{synopt:{opt noreport}}suppress reporting of regressions {p_end}
{synopt:{opt 2sls}}report 2sls variance matrix using sample at intersection of {opt iffirst} and {opt ifsecond}. {p_end}
{synoptline}
{p 4 6 2} {cmd:aweight}s, {cmd:fweight}s, {cmd:pweight}s, and {cmd:iweight}s are all allowed; see {help weight} {p_end}

{* ************************DESCRIPTION*************************}{...}
{marker description}
{title:Description}
{pstd} {cmd:ts2sls} performs two sample two-stage least squares regression. The first and second stage samples may be entirely separate or overlap. 
{cmd:ts2sls} allows for cross-sample dependence in the case of sample overlap through the clustering option.
Standard errors computed using the asymptotic formula given in Gabriel Chodorow-Reich and Johannes Wieland, "Secular Labor Reallocation and Business Cycles." {p_end}

{* ************************OPTIONS IN DEPTH*************************}{...}
{marker options}{...}
{title:Options}

{* *****MODEL OPTIONS in detail *****}{...}
{marker opt_model}{...}
{dlgtab:Model}
{phang}
{opt iffirst}({it:str}) takes a boolean argument; the first stage regression is run using only the observations where the argument is true. {p_end}

{phang}
{opt ifsecond}({it:str}) takes a boolean argument; the second stage regression is run using only the observations where the argument is true. {p_end}

{phang}
{opt absorb}({varlist}) takes a list of categorical variables to absorb; 
equivalent to including an indicator variable for each absorbed variable in both the first-stage and second-stage regressions.
Indicators will not be displayed in the regression output but will be listed under {hi: Absorbed variables} in each table’s upper left corner. {p_end}

{* *****SE/ROBUST OPTIONS in detail *****}{...}
{marker opt_se}{...}
{dlgtab:SE/Robust}
{phang}
{opt robust} reports Eicker-White robust standard errors, which are consistent under heteroskedasticity. See {opt robust} under {help vce_option##options:[R] vce_option} {p_end}

{phang}
{opt cluster}({varname}) allows for intragroup dependence in calculating standard errors, with groups defined by the categorical variable {varname}. See {opt cluster} under {help vce_option##options:[R] vce_option} {p_end}

{phang}
{opt independent} treats residuals from first and second stage as uncorrelated. Think carefully about this option if {opt cluster} specified and the first and second stage samples contain data drawn from the same cluster. {p_end}


{* ************************EXAMPLES*************************}{...}
{marker examples}
{title:Examples}
{hline}
{pstd}Setup{p_end}
{phang}{cmd:. sysuse nlsw88, clear}{p_end}
{phang}{cmd:. gen obs = _n}{p_end}
{phang}{cmd:. set seed 582094}{p_end}
{phang}{cmd:. gen ln_wage = ln(wage)}{p_end}
{phang}{cmd:. gen ln_education = ln(grade)}{p_end}
{phang}{cmd:. gen ln_experience = ln(ttl_exp)}{p_end}
{hline}
{pstd}Simple regression with clustering{p_end}
{phang}{cmd:. ts2sls ln_wage ln_education ln_experience (union=south) if !missing(ln_wage,union,south), cl(occupation)}{p_end}

{pstd}Different sample sizes using {opt iffirst} to manually drop some observations{p_end}
{phang}{cmd:. ts2sls ln_wage ln_education ln_experience (union=south) if !missing(ln_wage,union,south), cl(occupation) iffirst(obs<1500)}{p_end}

{pstd}Different sample sizes with some first-stage observations missing{p_end}
{phang}{cmd:. ts2sls ln_wage ln_education ln_experience (union=south), cl(occupation)}{p_end}

{* ************************STORED RESULTS*************************}{...}
{marker results}
{title:Stored Results}

{cmd: ts2sls} stores the following in {cmd: e()}:

{synoptset tabbed}{...}
{syntab: Scalars}
{synopt:{cmd:e(df_a)}}degrees of freedom used by {cmd:absorb}{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(r2)}}R-squared{p_end}
{synopt:{cmd:e(r2_a)}}adjusted R-squared{p_end}

{syntab: Matrices}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{syntab: Functions}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{* ************************AUTHOR*************************}{...}
{marker author}
{title:Author}
{pstd} Gabriel Chodorow-Reich {p_end}
{pstd} Harvard University {p_end}
{pstd} Email: chodorowreich@fas.harvard.edu {p_end}

{* ************************REFERENCES*************************}{...}
{marker references}
{title:References}
{pstd} Chodorow-Reich, Gabriel and Johannes Wieland. "Secular Labor Reallocation and Business Cycles." {p_end}
{pstd}
Drukker, David M. “Programming an estimation command in Stata: Adding robust and cluster-robust VCEs to our Mata-based OLS command.” {it:The Stata Blog}. 19 Jan. 2016.
{browse "https://blog.stata.com/2016/01/19/programming-an-estimation-command-in-stata-adding-robust-and-cluster-robust-vces-to-our-mata-based-ols-command/":[link]}{p_end}


