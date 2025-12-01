/*************************************************************************************************************
This ado-file estimates two-sample two stage least squares where one sample is a subset of the other sample.
Citation: Chodorow-Reich, Gabriel and Johannes Wieland. 2020. "Secular Labor Reallocation and Business Cycles." Journal of Political Economy.

Written by Gabriel Chodorow-Reich and provided without any warranty
This version: February 2018

Some code borrowed from: https://blog.stata.com/2016/01/19/programming-an-estimation-command-in-stata-adding-robust-and-cluster-robust-vces-to-our-mata-based-ols-command/

Options:
iffirst: sample for first stage
ifsecond: sample for second stage
robust: Eicker-White heteroskedastic robust standard errors.
cluster: Standard errors clustered by varname
independent: treat first stage and second stage samples as independent. 
small: apply small sample adjustment to standard errors
absorb: absorb varlist
noreport: suppress reporting of regressions
2sls: report 2sls variance matrix using sample at intersection of iffirst and ifsecond.

Notation:
e: first stage residual
u: second stage residual
eta: structural residual
N1: first stage sample size
N2: second stage sample size
Z: matrix with fitted values and included instruments


*************************************************************************************************************/

cap program drop ts2sls
program define ts2sls, eclass
version 12.1
syntax [anything (name=0)] [aweight fweight pweight iweight] [if] [in], [iffirst(string) ifsecond(string) ROBust CLuster(varname) small noCONStant absorb(varlist) independent noreport 2sls debug tsset]

/*************************************************************************************************************
Prelinaries.
*************************************************************************************************************/
/*Save cmdline*/
local cmdline ts2sls `*'

/*Reporting*/
if `"`report'"'==`"noreport"' local quireport qui
if `"`debug'"'==`""' local quidebug qui

/*Mark samples*/
marksample touse, strok
tempvar touse1 touse2 touse12 _n
if substr(strtrim(`"`iffirst'"'),1,1)==`"&"' gen byte `touse1' = `touse' `iffirst'
else if `"`iffirst'"'!=`""' gen byte `touse1' = `touse' & `iffirst'
else gen byte `touse1' = `touse'
if substr(strtrim(`"`ifsecond'"'),1,1)==`"&"' gen byte `touse2' = `touse' `ifsecond'
else if `"`ifsecond'"'!=`""' gen byte `touse2' = `touse' & `ifsecond'
else gen byte `touse2' = `touse'
gen `_n' = _n

/*Parse list of variables in regression*/
local lhs: word 1 of `0'
if regexm(`"`0'"',`"(\()(.*)(\))"') local endogenousexcluded = regexs(2)
else {
	di as error "Illegal syntax: specify (endogenous=excluded)"
	exit 
}
local endogenous = strtrim(regexr(`"`endogenousexcluded'"',`"=.*$"',`""'))
local excluded = strtrim(regexr(`"`endogenousexcluded'"',`"^.*="',`""'))
local included = strtrim(regexr(regexr(`"`0'"',`"`lhs'"',`""'),`"\(`endogenousexcluded'\)"',`""'))

/*Confirm endogenous and excluded instruments specified*/
if `"`endogenous'"'==`""' {
	di as error `"Endogenous varlist required"'
	exit
}
if `"`excluded'"'==`""' {
	di as error `"Excluded instrument varlist required"'
	exit
}

/*Expand varlists*/
foreach varlist in endogenous excluded included {
	fvexpand ``varlist''
	local `varlist' `r(varlist)'
	`quidebug' di `"`varlist': ``varlist''"'
}

/*Absorb variables*/
if `"`absorb'"'!=`""' & `"`2sls'"'!=`""' {
	di as error `"Cannot specify 2sls with absorb"'
	exit
}
else if `"`absorb'"'!=`""' {
	local absorbvars absorb(`absorb')
	local regcmd areg
}
else local regcmd reg

/*VCE*/
if `"`cluster'"'!=`""' { 
	tempvar cluster_n
	cap confirm numeric variable `cluster'
	if _rc!=0 qui egen `cluster_n' = group(`cluster')
	else qui clonevar `cluster_n' = `cluster'
	local vce cluster
}
else if `"`robust'"'!=`""' local vce robust
else local vce ols
`quidebug' di `"VCE: `vce' `cluster'"'

/*Weights*/
if `"`weight'"'!=`""' local wtname = regexr(`"`exp'"',`"= "',`""')


/*************************************************************************************************************
Estimate first stage.
*************************************************************************************************************/
local ee = 0
foreach var of local endogenous {
	if regexm(`"`var'"',`"[0-9]+[bn]*\."') { /*Factor variables not allowed as dependent variable*/
		tempvar fslhs
		gen `fslhs' = `var'
		local cmd `quireport' `regcmd' `fslhs' `excluded' `included' if `touse1' [`weight'`exp'], vce(`vce' `cluster_n') `absorbvars' `constant'
	}
	else local cmd `quireport' `regcmd' `var' `excluded' `included' if `touse1' [`weight'`exp'], vce(`vce' `cluster_n') `absorbvars' `constant'
	local ee = `ee'+1
	`quireport' di "First stage results"
	`quidebug' di `"`cmd'"'
	`cmd'
	`quireport' replace `touse1' = e(sample)
	tempvar e_`ee'
	qui predict `e_`ee'' if `touse1', resid
	local e `e' `e_`ee''
	tempvar hat_`ee'
	qui predict `hat_`ee'' if `touse', xb
	local fitted `fitted' `hat_`ee''
}
if `:word count `endogenous''==1 { /*Single endogenous variable*/
	`quireport' testparm `excluded'
	local widstat = r(F)
	if `:word count `excluded''==1 local fscoef = _b[`excluded'] /*Single endogenous variable and single instrument*/
}

/*************************************************************************************************************
Estimate second stage.
*************************************************************************************************************/
local cmd `quireport' `regcmd' `lhs' `fitted' `included' if `touse2' [`weight'`exp'], vce(`vce' `cluster_n') `absorbvars' `constant'
`quireport' di "Second stage results, uncorrected standard errors"
`quidebug' di `"`cmd'"'
`cmd'
`quireport' replace `touse2' = e(sample)
tempvar u
qui predict `u' if e(sample), resid
tempname gamma b
mat `b' = e(b) 
*if `"`absorb'"'!=`""' & `"`constant'"'!=`"noconstant"' mat `b'= `b'[1,1..`=colsof(`b')-1'] /*Drop constant from coefficient matrix if absorb*/
foreach var of varlist `fitted' {
	mat `gamma' = (nullmat(`gamma') \ _b[`var'])
}
local N_clust = e(N_clust)
local r2_ss = e(r2)
local r2_a_ss = e(r2_a)
gen byte `touse12' = `touse1' & `touse2'

/*************************************************************************************************************
Partial out variables in absorb from fitted first stage variables and included instruments.
*************************************************************************************************************/
if `"`absorb'"'!=`""' {
	tempvar _cons
	gen byte `_cons'=1
	foreach var in `fitted' `included' `_cons' {
		local v = `v'+1
		tempvar absorblhs
		if regexm(`"`var'"',`"[0-9]+[bn]*\."') qui gen `absorblhs' = `var' /*Factor variables not allowed as dependent variable*/
		else qui clonevar `absorblhs' = `var'
		foreach sample in 1 2 12 {
			local cmd cap areg `absorblhs' if `touse`sample'' [`weight'`exp'], `absorbvars'
			`quidebug' di `"`cmd'"'
			`cmd'
			if _rc!=0 continue /*No observations with variable and absorb variables*/
			tempvar Z`sample'_`v'
			qui predict `Z`sample'_`v'' if e(sample), resid
			local Z`sample' `Z`sample'' `Z`sample'_`v''
			if `"`df_a`sample''"'==`""' local df_a`sample' = e(df_a) + 1 /*Degrees of freedom used by absorb + constant*/
		}
	}
	local constant noconstant	
	if `"`debug'"'!=`""' sum `Z2' `fitted' `included' if `touse2'
	if `"`debug'"'!=`""' reg `lhs' `Z2' if `touse2', vce(`vce' `cluster_n') `constant'
}
else {			
	foreach sample in 1 2 12 {
		local Z`sample' `fitted' `included'
		local df_a`sample' = 0
	}
}

/*************************************************************************************************************
Estimate 2sls and save VCV.
*************************************************************************************************************/
if `"`vce'"'==`"ols"' local vce unadjusted
if (`"`2sls'"'!=`""' | `"`debug'"'!=`""') & (`"`absorb'"'==`""') {
	local cmd `quireport' ivregress 2sls `lhs' (`endogenous'=`excluded') `included' if `touse12' [`weight'`exp'], vce(`vce' `cluster_n') `constant'
	`quireport' di "TSLS results on overlapping sample"
	`quidebug' di `"`cmd'"'
	`cmd'
	tempname V_2sls
	mat `V_2sls' = e(V)
	if `"`debug'"'!=`""' {
		tempvar eta
		qui predict `eta' if e(sample), resid
	}
}

/*************************************************************************************************************
Estimate quadratic forms in Mata.
*************************************************************************************************************/
tempname ZpOmega_eZ N1 ZpZi1 ZpOmega_uZ N2 ZpZi2 ZpOmega_ueZ ZpOmega_euZ ZpOmega_etaZ N12 ZpZi12 ZpZi dfr1 dfr2 dfr12 sizeadj1 sizeadj2 sizeadj12
`quidebug' di `"`fitted' `included'"'
`quidebug' di `"`Z2'"'
if `"`cluster'"'!=`""' qui sort `cluster_n' `_n' /*So that cluster submatrices get defined appropriately*/

/*Z'Omega_{e}Z*/
mata: mywork(`"`e'"', `"`gamma'"', `"`e'"', `"`gamma'"', `"`Z1'"', `"`wtname'"', `"`touse1'"', `"`constant'"', `df_a1',    ///
   "`vce'", "`cluster_n'",                                  /// 
   "`ZpOmega_eZ'", "`ZpZi1'", "`N1'", `"`dfr1'"', `"`sizeadj1'"', `"`small'"', `"`debug'"') 

/*Z'Omega_{u}Z*/   
mata: mywork(`"`u'"', `""', `"`u'"', `""', `"`Z2'"', `"`wtname'"', `"`touse2'"', `"`constant'"', `df_a2',    ///
   "`vce'", "`cluster_n'",                                  /// 
   "`ZpOmega_uZ'", "`ZpZi2'", "`N2'", `"`dfr2'"', `"`sizeadj2'"', `"`small'"', `"`debug'"')     

/*Z'Omega_{ue}Z*/   
if `"`independent'"'==`""' mata: mywork(`"`u'"', `""', `"`e'"', `"`gamma'"', `"`Z12'"', `"`wtname'"', `"`touse12'"', `"`constant'"', `df_a12',    ///
   "`vce'", "`cluster_n'",                                  /// 
   "`ZpOmega_ueZ'", "`ZpZi12'", "`N12'", `"`dfr12'"', `"`sizeadj12'"', `"`small'"', `"`debug'"')      

/*Z'Omega_{eu}Z*/   
if `"`independent'"'==`""' mata: mywork(`"`e'"', `"`gamma'"', `"`u'"', `""', `"`Z12'"', `"`wtname'"', `"`touse12'"', `"`constant'"', `df_a12',    ///
   "`vce'", "`cluster_n'",                                  /// 
   "`ZpOmega_euZ'", "`ZpZi12'", "`N12'", `"`dfr12'"', `"`sizeadj12'"', `"`small'"', `"`debug'"')   
   
/*Z'Omega_{eta}Z*/   
if (`"`debug'"'!=`""') & (`"`absorb'"'==`""') {
	di `"mata: mywork(`"`eta'"', `""', `"`eta'"', `""', `"`Z12'"', `"`wtname'"', `"`touse12'"', `"`constant'"', `df_a12', "`vce'", "`cluster_n'", "`ZpOmega_etaZ'", "`ZpZi12'", "`N12'", `"`dfr12'"', `"`sizeadj12'"', `"`small'"', `"`debug'"') "'
	mata: mywork(`"`eta'"', `""', `"`eta'"', `""', `"`fitted' `included'"', `"`wtname'"', `"`touse12'"', `"`constant'"', `df_a12',    ///
   "`vce'", "`cluster_n'",                                  /// 
   "`ZpOmega_etaZ'", "`ZpZi12'", "`N12'", `"`dfr12'"', `"`sizeadj12'"', `"`small'"', `"`debug'"')     
}
   
/*************************************************************************************************************
Construct coefficient covariance matrix.
*************************************************************************************************************/
if `N2'>`N1' mat `ZpZi' = `ZpZi2'
else mat `ZpZi' = `ZpZi1'
local alpha = `N2'/`N1'

/*Sandwich and meat matrices*/
`quidebug' mat list `ZpZi'
`quidebug' mat list `ZpOmega_uZ'
`quidebug' mat list `ZpOmega_eZ'
if `"`independent'"'==`""' `quidebug' mat list `ZpOmega_ueZ'
if `"`independent'"'==`""' `quidebug' mat list `ZpOmega_euZ'

/*Matrix names*/
tempname V V_ratio V_debug

/*Covariance formula*/
if `"`independent'"'==`""' {
	 mat `V' = `ZpZi' * (`ZpOmega_uZ' + `alpha'*`ZpOmega_eZ' - sqrt(`alpha')*(`ZpOmega_ueZ'+`ZpOmega_euZ')) * `ZpZi' * `sizeadj2'
}
else mat `V' = `ZpZi' * (`ZpOmega_uZ' + `alpha'*`ZpOmega_eZ')                                               * `ZpZi' * `sizeadj2'
if `"`debug'"'!=`""' & (`"`absorb'"'==`""') { 
	mat `V_debug' = `ZpZi12' * `ZpOmega_etaZ' * `ZpZi12' * `sizeadj2'
	mat list `V_debug'
}
	
/*Ratio of adjusted and 2sls variance matrices*/
if (`"`2sls'"'!=`""' | `"`debug'"'!=`""') & (`"`absorb'"'==`""') mata: st_matrix("`V_ratio'", st_matrix("`V'"):/st_matrix("`V_2sls'"))

/*Add labels to matrices*/
local cnames `endogenous' `included' 
if "`constant'" == "" local _cons _cons
mat colnames `V' = `cnames' `_cons'
mat rownames `V' = `cnames' `_cons'
if (`"`2sls'"'!=`""' | `"`debug'"'!=`""') & (`"`absorb'"'==`""') mat colnames `V_ratio' = `cnames' `_cons'
if (`"`2sls'"'!=`""' | `"`debug'"'!=`""') & (`"`absorb'"'==`""') mat rownames `V_ratio' = `cnames' `_cons'
mat colnames `b' = `cnames' `_cons'

/*Report b and V matrices*/
if `"`debug'"'!=`""' {
	mat list `b'
	mat list `V'
}

/*************************************************************************************************************
Post results.
*************************************************************************************************************/
ereturn post `b' `V', esample(`touse2') buildfvinfo
ereturn scalar N1 = `N1'
ereturn scalar N = `N2'
ereturn scalar N_clust = `N_clust'
ereturn scalar df_r   = `dfr2'
if `:word count `endogenous''==1 ereturn scalar widstat = `widstat'
if `:word count `endogenous''==1 & `:word count `excluded''==1 ereturn scalar fscoef = `fscoef'
ereturn scalar r2_ss = `r2_ss'
ereturn scalar r2_a_ss = `r2_a_ss'
if (`"`2sls'"'!=`""' | `"`debug'"'!=`""') & (`"`absorb'"'==`""') {
	ereturn matrix V_2sls = `V_2sls'
	ereturn matrix V_ratio = `V_ratio'
}
ereturn local  vce      "`vce'"
ereturn local depvar `"`lhs'"'
ereturn local  clustvar "`cluster'"
ereturn local  cmd      "ts2sls"
ereturn local  cmdline      "`cmdline'"

di "Second stage results, corrected standard errors"
_coef_table_header
_coef_table, 
_prefix_footnote

if `"`cluster'"'!=`""' & `"`tsset'"'==`""' qui sort `_n'
else if `"`tsset'"'!=`""' qui tsset

end

/*************************************************************************************************************
Mata code to estimate OLS regression and construct VCV matrices.
*************************************************************************************************************/
mata:

void mywork( string scalar residual1, string scalar coefficient1,  string scalar residual2, string scalar coefficient2, string scalar indepvars, string scalar weight, 
             string scalar touse,   string scalar constant,   real scalar df_a,  
             string scalar vcetype, string scalar clustervar,
             string scalar Omeganame,  string scalar ZpZname,  string scalar nname,  string scalar dfrname,  string scalar sizeadjname,
			 string scalar small, string scalar debug) 
{

    real vector    r1r2, cvar, r1i, r2i 
    real matrix    r1, r2, Z, M, info, zi, nonemptyZ  
    real scalar    n, p, k, nc, i, dfr, sizeadj

	/*Sample size*/
	n = rows(st_data(., indepvars, touse))
	
	/*Weight*/
	if (weight!=`""') { /*Weighted regression*/
		W = diag(st_data(., weight, touse)) /*Matrix with raw weights on main diagonal*/
		W = W*n/trace(W) /*Matrix with weights on main diagonal scaled to sum to number of observations*/
		rootW = matpowersym(W,0.5) /*Square root of scaled weighting matrix*/
	}	
	else rootW = I(n)
	
	/*Main variable matrices*/
    r1   = rootW * st_data(., residual1, touse) /*First residuals matrix multiplied by square root of scaled weighting matrix*/
    r2   = rootW * st_data(., residual2, touse) /*Second residuals matrix multiplied by square root of scaled weighting matrix*/
	Z    = st_data(., indepvars, touse)	
	if (debug == "debug") {
		nonemptyZ = selectindex(colmaxabs(Z):!=0) /*Non-zero columns, for example omitted levels of factor expansion*/
		nonemptyZ
	}
    if (constant == "") Z = Z,J(n,1,1) /*Add constant*/	
    Z    = rootW * Z /*Regressors in second stage multiplied by square root of scaled weighting matrix*/	
	if (coefficient1!="") r1 = r1 * st_matrix(coefficient1) /*Multiply residuals by coefficient vector*/
	if (coefficient2!="") r2 = r2 * st_matrix(coefficient2) /*Multiply residuals by coefficient vector*/	
	
	/*Degrees of freedom*/
	p    = cols(Z)
    k    = p - diag0cnt(quadcross(Z, Z)) + df_a
	
	
 	/*Cross-product*/
   ZpZi = quadcross(Z, Z)
    ZpZi = invsym(ZpZi) /*Note: if Z'Z is singular (perfect multicollinearity), function invsym will automatically set enough columns of (Z'Z)^{-1} to zero. 
	These columns may not correspond to the omitted columns in the Stata regression. Standard errors for fixed effects may not be correct.*/
	
    r1r2   = r1:*r2
    if (vcetype == "robust") { /*Eicker-White covariance matrix*/
        M    = quadcross(Z, r1r2, Z)
        dfr  = n - k
		if (small=="small") sizeadj = n/dfr
		else sizeadj = 1
	}
    else if (vcetype == "cluster") { /*Clustered covariance matrix*/
        cvar = st_data(., clustervar, touse)
        info = panelsetup(cvar, 1)
        nc   = rows(info)
        M    = J(p, p, 0)
        dfr  = nc - 1
        for(i=1; i<=nc; i++) {
            zi = panelsubmatrix(Z,i,info)
            r1i = panelsubmatrix(r1,i,info)
            r2i = panelsubmatrix(r2,i,info)
            M  = M + zi'*(r1i*r2i')*zi
        }
		if (small=="small") sizeadj = ((n-1)/(n-k))*(nc/(nc-1))
		else sizeadj = 1
    }
    else {                 /*Homoskedastic covariance matrix*/
        M    = quadcross(Z, Z) * quadsum(r1r2)
        dfr  = n - k
		if (small=="small") sizeadj = 1/dfr
		else sizeadj = 1/n
   }

    st_matrix(Omeganame, M)
    st_matrix(ZpZname, ZpZi)
    st_numscalar(nname, n)
	st_numscalar(dfrname, dfr)
	st_numscalar(sizeadjname, sizeadj)

}

end
