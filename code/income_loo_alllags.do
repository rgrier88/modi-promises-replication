********************************************************************************
* income_loo_alllags.do -- leave-one-out for the all-lags income model
*
* Re-estimates the all-lags specification (every pre-treatment year of rgdppc
* as a predictor, 1984-2013; nested allopt; treatment 2014; 1984-2023) on the
* rule-based 18-donor pool, then three more times dropping Bangladesh, China
* and Ethiopia in turn. Each model is run twice: synth for the point estimate
* and donor weights, synth_runner for the placebo p-values -- the same
* conventions as income_results.do (the run that produced income_pol18.log).
*
* Produces: Table A1 (yearly effects, standardized yearly p-values,
* pre-treatment RMSPE, post/pre RMSPE-ratio rank and p) and the paths for
* Figure 5 (India and the four synthetic Indias in levels).
*
* Requires: synth and synth_runner (ssc install synth; ssc install synth_runner).
* Set $root to the repository folder. Reads data/income_panel.dta; writes to
* output/income_loo_alllags/.
*
* Run time: four synth_runner calls with nested optimization and 17-18
* placebos each. Expect it to take a good while (tens of minutes); Stata may
* show the beachball during each synth_runner call. Do not force-quit.
********************************************************************************

clear all
global root "/Users/ttufmi169d/Dropbox/Modi-Mania/modi-replication"   // <- edit
global data "$root/data/income_panel.dta"
global out  "$root/output/income_loo_alllags"
capture mkdir "$out"
capture log close
log using "$out/income_loo_alllags.log", replace text

global donors "CHN IDN BRA BGD PAK MEX VNM PHL THA TUR EGY KOR ETH ZAF ARG MMR COD POL"

* --- load India + donors, 1984-2023, optionally dropping one donor ---------------
capture program drop load18
program define load18
    args dropc
    use "$data", clear
    gen byte keepme = iso3code == "IND"
    foreach c of global donors {
        replace keepme = 1 if iso3code == "`c'"
    }
    if "`dropc'" != "" replace keepme = 0 if iso3code == "`dropc'"
    keep if keepme & year >= 1984 & year <= 2023
    egen id = group(iso3code)
    tsset id year
end

* --- all-lags predictor list -----------------------------------------------------
local lags ""
forvalues y = 1984/2013 {
    local lags `lags' rgdppc(`y')
}

* --- one run: synth (weights, paths), synth_runner (p-values), save results -------
capture program drop loo18
program define loo18
    args stub dropc pred

    * 1. synth: point estimate, weights, India / synthetic paths
    load18 `dropc'
    quietly levelsof id if iso3code == "IND", local(tr)
    quietly count if year == 1984
    local ndon = r(N) - 1
    display as result _newline "==== all-lags model, dropping: `dropc' (`ndon' donors) ===="
    synth rgdppc `pred', trunit(`tr') trperiod(2014) nested allopt ///
        keep("$out/keep_loo_`stub'") replace

    * 2. synth_runner: standardized yearly p-values and RMSPE-ratio p-value
    load18 `dropc'
    synth_runner rgdppc `pred', trunit(`tr') trperiod(2014) nested allopt
    local jp_std   = e(pval_joint_post_std)
    local jp_ratio = e(pval_joint_post)
    local np = e(n_pl_used)
    local nt = e(n_pl)
    matrix P = e(pvals_std)
    * synth_runner's "std" p-values divide post-period gaps by the unit's own
    * pre-treatment RMSPE, so pval_joint_post_std is the post/pre RMSPE-ratio
    * test. Rank = placebos with a larger ratio + 1, among np + 1 units.
    local rank = round(`jp_std' * `np') + 1

    * 3. yearly effects and p-values (Table A1 column for this model)
    use "$out/keep_loo_`stub'", clear
    keep _time _Y_treated _Y_synthetic
    drop if _time == .
    rename _time year
    gen effect = _Y_treated - _Y_synthetic
    gen pre2 = effect^2 if year < 2014
    quietly summarize pre2
    local rmspe = sqrt(r(mean))
    preserve
        keep if year >= 2014
        gen lead = _n
        gen pval = .
        forvalues j = 1/`=colsof(P)' {
            quietly replace pval = round(P[1,`j'], .01) in `j'
        }
        keep year lead effect pval
        gen model = "`stub'"
        save "$out/pvals_loo_`stub'", replace
        display as result "pre-treatment RMSPE = " %6.1f `rmspe' ///
            "   joint p (std) = " %5.2f `jp_std' ///
            "   post/pre ratio: rank `rank' of `=`np'+1' (p = " %4.2f `jp_std' ")" ///
            "   placebos used = `np' of `nt'"
        format effect %8.1f
        list year effect pval, noobs sep(0)
    restore
    * India and synthetic India in levels, for Figure 5
    rename _Y_treated india
    rename _Y_synthetic synth_`stub'
    gen gap_`stub' = effect
    keep year india synth_`stub' gap_`stub'
    save "$out/paths_loo_`stub'", replace

    * 4. donor weights, named
    use "$out/keep_loo_`stub'", clear
    keep _Co_Number _W_Weight
    drop if _Co_Number == . | _W_Weight < .001
    rename _Co_Number id
    tempfile w
    save `w'
    load18 `dropc'
    keep id iso3code
    duplicates drop
    merge 1:1 id using `w', nogenerate keep(match)
    gsort -_W_Weight
    format _W_Weight %6.3f
    list iso3code _W_Weight, noobs sep(0)
    gen model = "`stub'"
    save "$out/weights_loo_`stub'", replace
end

********************************************************************************
* RUN
********************************************************************************

loo18 all   ""    "`lags'"
loo18 noBGD "BGD" "`lags'"
loo18 noCHN "CHN" "`lags'"
loo18 noETH "ETH" "`lags'"

* --- Table A1 as one file: year x (effect, p) for the four models ----------------
use "$out/pvals_loo_all", clear
rename (effect pval) (effect_all p_all)
drop model
foreach s in noBGD noCHN noETH {
    merge 1:1 year using "$out/pvals_loo_`s'", nogenerate
    rename (effect pval) (effect_`s' p_`s')
    drop model
}
drop lead
format effect_* %8.1f
display as result _newline "==== Table A1: yearly effects and standardized p-values ===="
list, noobs sep(0)
save "$out/tableA1_loo", replace
export delimited "$out/tableA1_loo.csv", replace

* --- Figure 5 paths as one file: India and the four synthetic Indias -------------
use "$out/paths_loo_all", clear
foreach s in noBGD noCHN noETH {
    merge 1:1 year using "$out/paths_loo_`s'", nogenerate   // india is identical across files; master values kept
}
order year india synth_all synth_noBGD synth_noCHN synth_noETH gap_*
save "$out/figure5_paths", replace
export delimited "$out/figure5_paths.csv", replace
display as result _newline "2023 levels (Figure 5 legend):"
list year india synth_* if year == 2023, noobs

* --- all weights in one file -----------------------------------------------------
use "$out/weights_loo_all", clear
foreach s in noBGD noCHN noETH {
    append using "$out/weights_loo_`s'"
}
export delimited "$out/weights_loo_all_models.csv", replace

display as result _newline "Figure 4 (Stata, income_pol18.log) all-lags 2023 effect = -592.7, p = 0.06," ///
    " pre-RMSPE 47.4, joint p (std) 0.06, 17 of 17 placebos: the all-donors column" ///
    " here should match it. The printed Table A1 (Python, 13 Oct draft) had -597 / 0.05."
log close
