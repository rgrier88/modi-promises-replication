********************************************************************************
* income_results.do -- income results on the rule-based 18-donor pool
*
* Three synthetic-control models for real per-capita income (PWT rgdpe/pop):
*   main     treatment 2014, sample 1984-2023; predictors: rgdppc in 1986,
*            1991, 1996, 2001, 2006, 2011 and pre-period means of csh_g, hc,
*            csh_x, csh_i                           -> Table 2, Figure 2
*   singh    in-time placebo: treatment 2004, sample 1984-2013; same predictors
*            with 2003 in place of 2006 and 2011    -> Figure 3
*   alllags  treatment 2014, sample 1984-2023; predictors: rgdppc in every
*            year 1984-2013, no covariates           -> Figure 4
* Each model runs synth (point estimate, weights, paths) then synth_runner
* (standardized yearly placebo p-values), both with nested allopt.
*
* This is the script that produced output/income_results/income_pol18.log
* (19 Sep 2026), with paths pointed at the repository and CSV exports added.
* Donor pool: GDP per capita and population relative to the US in 1984; see
* the paper, Section 3. Poland was the last donor added (18th).
*
* Requires: synth and synth_runner. Set $root to the repository folder.
* Reads data/income_panel.dta; writes output/income_results/.
*
* Run time: three synth_runner calls with nested optimization and 17-18
* placebos each -- expect hours, not minutes. Stata shows the beachball
* during each call; do not force-quit.
********************************************************************************

clear all
global root "/Users/ttufmi169d/Dropbox/Modi-Mania/modi-replication"   // <- edit
global data "$root/data/income_panel.dta"
global out  "$root/output/income_results"
capture mkdir "$out"
capture log close
log using "$out/income_results.log", replace text

global donors "CHN IDN BRA BGD PAK MEX VNM PHL THA TUR EGY KOR ETH ZAF ARG MMR COD POL"
global covs   "csh_g hc csh_x csh_i"

* --- load India + donors, 1984 to endyr ------------------------------------------
capture program drop load18
program define load18
    args endyr
    use "$data", clear
    gen byte keepme = iso3code == "IND"
    foreach c of global donors {
        replace keepme = 1 if iso3code == "`c'"
    }
    keep if keepme & year >= 1984 & year <= `endyr'
    egen id = group(iso3code)
    tsset id year
end

* --- data check ------------------------------------------------------------------
load18 2023
foreach c in IND $donors {
    quietly count if iso3code == "`c'"
    local n = r(N)
    quietly count if iso3code == "`c'" & ///
        (rgdppc >= . | csh_g >= . | hc >= . | csh_x >= . | csh_i >= .)
    if `n' == 0       display as error "`c': not in data"
    else if r(N) > 0  display as error "`c': `r(N)' country-years with missing data"
    else              display as text  "`c': ok"
}

* --- estimate one model, print and save results ----------------------------------
capture program drop run18
program define run18
    args stub trper endyr pred

    * 1. synth: point estimate, weights, paths
    load18 `endyr'
    quietly levelsof id if iso3code == "IND", local(tr)
    synth rgdppc `pred', trunit(`tr') trperiod(`trper') nested allopt ///
        keep("$out/keep_`stub'") replace

    * 2. synth_runner: standardized yearly placebo p-values
    load18 `endyr'
    synth_runner rgdppc `pred', trunit(`tr') trperiod(`trper') nested allopt
    local jp = e(pval_joint_post_std)
    local np = e(n_pl_used)
    local nt = e(n_pl)
    matrix P = e(pvals_std)
    local rank = round(`jp' * `np') + 1

    * 3. yearly effects and p-values
    use "$out/keep_`stub'", clear
    keep _time _Y_treated _Y_synthetic
    drop if _time == .
    rename _time year
    gen effect = _Y_treated - _Y_synthetic
    gen pre2 = effect^2 if year < `trper'
    quietly summarize pre2
    local rmspe = sqrt(r(mean))
    preserve
        keep if year >= `trper'
        gen lead = _n
        gen pval = .
        forvalues j = 1/`=colsof(P)' {
            quietly replace pval = round(P[1,`j'], .01) in `j'
        }
        keep year lead effect pval
        save "$out/pvals_`stub'", replace
        export delimited "$out/pvals_`stub'.csv", replace
        display as result _newline "=== `stub' (18 donors): treatment `trper', 1984-`endyr' ==="
        display as result "pre-treatment RMSPE = " %6.1f `rmspe' ///
            "   joint p (std) = " %5.2f `jp' ///
            "   post/pre ratio: rank `rank' of `=`np'+1'" ///
            "   placebos used = `np' of `nt'"
        format effect %8.1f
        list year effect pval, noobs sep(0)
    restore
    * India and synthetic India in levels (Panel A of the figures)
    rename _Y_treated india
    rename _Y_synthetic synthetic
    rename effect gap
    keep year india synthetic gap
    export delimited "$out/paths_`stub'.csv", replace

    * 4. donor weights, named
    use "$out/keep_`stub'", clear
    keep _Co_Number _W_Weight
    drop if _Co_Number == . | _W_Weight < .001
    rename _Co_Number id
    tempfile w
    save `w'
    load18 `endyr'
    keep id iso3code
    duplicates drop
    merge 1:1 id using `w', nogenerate keep(match)
    gsort -_W_Weight
    format _W_Weight %6.3f
    list iso3code _W_Weight, noobs sep(0)
    export delimited "$out/weights_`stub'.csv", replace
end

********************************************************************************
* RUN
********************************************************************************

local main_pred "rgdppc(1986) rgdppc(1991) rgdppc(1996) rgdppc(2001) rgdppc(2006) rgdppc(2011) $covs"
local lags ""
forvalues y = 1984/2013 {
    local lags `lags' rgdppc(`y')
}

run18 main    2014 2023 "`main_pred'"
run18 singh   2004 2013 "rgdppc(1986) rgdppc(1991) rgdppc(1996) rgdppc(2001) rgdppc(2003) $covs"
run18 alllags 2014 2023 "`lags'"

* --- Table 2: predictor balance for the main model --------------------------------
* synth's keep() file stores the predictor-balance table in its header rows:
* _Co_Number, _W_Weight, then _Y_treated/_Y_synthetic by _time. The balance
* table (India, synthetic India, donor mean) is printed by synth above; the
* values in Table 2 are read from that printout. The India and synthetic
* columns can also be recomputed from the weights in weights_main.csv.

display as result _newline "Expected (income_pol18.log, 19 Sep 2026):" ///
    _newline "  main:    2023 effect -1095.5, p 0.06, pre-RMSPE 60.0, joint p 0.06, 17 of 17 placebos;" ///
    " weights ETH .363 BGD .313 CHN .262 PAK .056 KOR .006" ///
    _newline "  singh:   2013 effect -475.1, p 0.28, pre-RMSPE 32.7, joint p 0.33, 18 of 18 placebos" ///
    _newline "  alllags: 2023 effect -592.7, p 0.06, pre-RMSPE 47.4, joint p 0.06, 17 of 17 placebos;" ///
    " weights ETH .471 VNM .205 CHN .153 BGD .079 PAK .054 MMR .023 KOR .015"
log close
