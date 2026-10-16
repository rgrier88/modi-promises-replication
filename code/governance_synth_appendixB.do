********************************************************************************
* governance_synth_appendixB.do -- Appendix B: one-outcome-at-a-time synthetic
* controls (synth / synth_runner) for the ten V-Dem outcomes, EIU-rule pool
* Pool: GDP per capita below half the US level in 2013; population >= 10m in
* 2013; average EIU democracy index >= 6 over 2010-2013 (EIU's "flawed
* democracy" boundary). 19 countries qualify; Chile is dropped because V-Dem
* has no legislative-constraints score for it under Pinochet (1984-89), which
* lets all ten outcomes run from 1984. Donors:
* ARG BRA COL GHA IDN MYS MEX PER PHL ZAF LKA BEN DOM GRC POL ROU THA ZMB
* Same spec as the paper: five-year outcome lags 1986-2011 + gini csh_g hc,
* nested allopt, treatment 2014, sample 1984-2023 for every outcome.
* Donors with the outcome missing in any sample year are dropped for that
* outcome (named in the log) -- none expected.
*
* This is the script that produced output/governance_synth/governance_results.log
* (18 Sep 2026) and Appendix Table B1, with paths pointed at the repository,
* the Stata figure blocks removed (the paper's governance figures come from
* governance_ppsynth.do) and CSV exports added.
*
* Requires: synth and synth_runner. Set $root to the repository folder.
* Reads data/governance_panel.dta; writes output/governance_synth/.
* Run time: ten synth_runner calls with nested optimization -- hours.
********************************************************************************

clear all
global root "/Users/ttufmi169d/Dropbox/Modi-Mania/modi-replication"   // <- edit
global data "$root/data/governance_panel.dta"
global out  "$root/output/governance_synth"
capture mkdir "$out"
capture log close
log using "$out/governance_synth_appendixB.log", replace text

global donors "ARG BRA COL GHA IDN MYS MEX PER PHL ZAF LKA BEN DOM GRC POL ROU THA ZMB"
global covs   "gini csh_g hc"

local outcomesA v2x_polyarchy v2x_libdem v2x_corr v2xcl_rol v2x_frassoc_thick ///
                v2x_freexp_altinf v2clrelig v2xeg_eqprotec
local outcomesB v2xlg_legcon v2x_jucon

* display names, Table B1 names, axis specs and file slugs
local y_v2x_polyarchy     "Polyarchy Index"
local y_v2x_libdem        "Liberal Democracy Index"
local y_v2xlg_legcon      "Legislative constraints on the executive"
local y_v2x_jucon         "Judicial constraints"
local y_v2x_corr          "Political Corruption Index"
local y_v2xcl_rol         "Rule of Law"
local y_v2x_frassoc_thick "Freedom of Association"
local y_v2x_freexp_altinf "Freedom of Expression"
local y_v2clrelig         "Freedom of Religion"
local y_v2xeg_eqprotec    "Equal Rights Protection Index"

local n_v2x_polyarchy     "Polyarchy"
local n_v2x_libdem        "Liberal democracy"
local n_v2xlg_legcon      "Legislative constraints"
local n_v2x_jucon         "Judicial constraints"
local n_v2x_corr          "Political corruption"
local n_v2xcl_rol         "Equality before the law"
local n_v2x_frassoc_thick "Freedom of association"
local n_v2x_freexp_altinf "Freedom of expression"
local n_v2clrelig         "Freedom of religion"
local n_v2xeg_eqprotec    "Equal protection"

local xl_v2x_polyarchy     "1984(10)2024"
local xl_v2x_libdem        "1984(10)2024"
local xl_v2xlg_legcon      "1991(5)2021"
local xl_v2x_jucon         "1991(5)2021"
local xl_v2x_corr          "1984(5)2024"
local xl_v2xcl_rol         "1984(6)2020"
local xl_v2x_frassoc_thick "1984(10)2024"
local xl_v2x_freexp_altinf "1984(5)2019"
local xl_v2clrelig         "1984(10)2024"
local xl_v2xeg_eqprotec    "1984(10)2024"

local f_v2x_polyarchy     "polyarchy"
local f_v2x_libdem        "libdem"
local f_v2xlg_legcon      "legcon"
local f_v2x_jucon         "jucon"
local f_v2x_corr          "corruption"
local f_v2xcl_rol         "eqlaw"
local f_v2x_frassoc_thick "frassoc"
local f_v2x_freexp_altinf "freexp"
local f_v2clrelig         "freerelig"
local f_v2xeg_eqprotec    "eqprotect"

* --- load India + donors, dropping donors with the outcome missing anywhere ---------
capture program drop load24
program define load24
    args v startyr
    use "$data", clear
    gen byte keepme = iso3code == "IND"
    foreach c of global donors {
        replace keepme = 1 if iso3code == "`c'"
    }
    keep if keepme & year >= `startyr' & year <= 2023
    gen byte miss = `v' >= .
    bysort iso3code: egen anymiss = max(miss)
    quietly levelsof iso3code if anymiss & iso3code != "IND", local(dropped) clean
    if "`dropped'" != "" display as error "`v': dropped for missing outcome in some sample year: `dropped'"
    drop if anymiss & iso3code != "IND"
    drop miss anymiss
    egen id = group(iso3code)
    tsset id year
end

* --- summary table collector -------------------------------------------------------
tempname T
postfile `T' str32 indicator str16 v double(pre_rmspe eff_2014 eff_2023 joint_p n_placebos) ///
    using "$out/tableB1_values.dta", replace

* --- one outcome ------------------------------------------------------------------------
capture program drop run24
program define run24
    args v startyr lags ytit name slug xl

    display as result _newline(2) "==================== `v' (`ytit'), sample `startyr'-2023 ===================="

    load24 `v' `startyr'
    quietly levelsof id if iso3code == "IND", local(tr)
    synth `v' `lags' $covs, trunit(`tr') trperiod(2014) nested allopt ///
        keep("$out/keep_`v'") replace

    load24 `v' `startyr'
    synth_runner `v' `lags' $covs, trunit(`tr') trperiod(2014) nested allopt
    local jp = e(pval_joint_post_std)
    local np = e(n_pl_used)
    local nt = e(n_pl)
    matrix P = e(pvals_std)

    * annual effects + p-values
    use "$out/keep_`v'", clear
    keep _time _Y_treated _Y_synthetic
    drop if _time == .
    rename _time year
    gen effect = _Y_treated - _Y_synthetic
    gen pre2 = effect^2 if year < 2014
    quietly summarize pre2
    local rmspe = sqrt(r(mean))
    keep if year >= 2014
    gen lead = _n
    gen pval = .
    forvalues j = 1/`=colsof(P)' {
        quietly replace pval = round(P[1,`j'], .01) in `j'
    }
    quietly summarize effect if year == 2014
    local e14 = r(mean)
    quietly summarize effect if year == 2023
    local e23 = r(mean)
    keep year lead effect pval
    save "$out/pvals_`v'", replace
    export delimited "$out/pvals_`v'.csv", replace

    display as result "pre-treatment RMSPE = " %7.4f `rmspe' ///
        "   joint p (std) = " %5.2f `jp' "   placebos used = `np' of `nt'"
    format effect %8.3f
    list year effect pval, noobs sep(0)
    post $T ("`name'") ("`v'") (`rmspe') (`e14') (`e23') (`jp') (`np')

    * named weights
    use "$out/keep_`v'", clear
    keep _Co_Number _W_Weight
    drop if _Co_Number == . | _W_Weight < .001
    rename _Co_Number id
    tempfile w
    save `w'
    load24 `v' `startyr'
    keep id iso3code
    duplicates drop
    merge 1:1 id using `w', nogenerate keep(match)
    gsort -_W_Weight
    format _W_Weight %6.3f
    list iso3code _W_Weight, noobs sep(0)
    export delimited "$out/weights_`v'.csv", replace
end
* (Stata figure blocks removed: the paper's governance figures are drawn from the
*  PPSYNTH results by code/fig_governance.py)

********************************************************************************
* RUN
********************************************************************************

global T `T'
foreach v of local outcomesA {
    run24 `v' 1984 "`v'(1986) `v'(1991) `v'(1996) `v'(2001) `v'(2006) `v'(2011)" ///
        "`y_`v''" "`n_`v''" "`f_`v''" "`xl_`v''"
}
foreach v of local outcomesB {
    run24 `v' 1984 "`v'(1986) `v'(1991) `v'(1996) `v'(2001) `v'(2006) `v'(2011)" ///
        "`y_`v''" "`n_`v''" "`f_`v''" "`xl_`v''"
}
postclose `T'

* --- Table B1 values ----------------------------------------------------------------------
use "$out/tableB1_values.dta", clear
format pre_rmspe %7.4f
format eff_2014 eff_2023 %7.3f
format joint_p %5.2f
display as result _newline "Table B1 values, 18-donor EIU-rule pool:"
list indicator pre_rmspe eff_2014 eff_2023 joint_p n_placebos, noobs sep(0) abbreviate(24)
export delimited "$out/tableB1_values.csv", replace

display as result _newline "Done. Everything in $out"
log close
