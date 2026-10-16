********************************************************************************
* governance_ppsynth.do
* Partially pooled synthetic control (PPSYNTH, Grier 2026) for the ten V-Dem
* outcomes on the EIU-rule donor pool (18 donors; Chile excluded for missing
* legislative-constraints data 1984-89). All outcomes 1984-2023, treatment 2014.
* Data-chosen partial pooling (aggregate method), no covariates, strict
* (synth_runner-style) placebo p-values.
*
* Produces: Table 1 (2023 gaps, rank, p-value), Figure 1 (gap paths), the donor
* weights and pre-treatment RMSPEs quoted in Appendix A, and the India /
* synthetic India paths for Figures A1-A10.
*
* Requires: ppsynth 2.6.1 (github.com/angusgrier/PPSYNTH, commit 42a9ab7,
* 25 Aug 2026) on the adopath, Stata 16+, Python 3.10-3.13 with numpy, scipy,
* numba. Run "ppsynth_setup" once before this script.
*
* Set $root to the repository folder. Reads data/governance_panel.dta; writes
* everything to output/governance_ppsynth/.
*
* Run time: the placebo inference reruns the whole pipeline for each of the
* 18 donors and blocks Stata's interface for its duration (roughly 10-15
* minutes; the beachball / "not responding" is normal, do not force-quit).
********************************************************************************

clear all
global root "/Users/ttufmi169d/Dropbox/Modi-Mania/modi-replication"   // <- edit
global data "$root/data/governance_panel.dta"
global out  "$root/output/governance_ppsynth"
capture mkdir "$out"
capture log close
log using "$out/governance_ppsynth.log", replace text

local outcomes v2x_polyarchy v2x_libdem v2x_corr v2xcl_rol v2x_frassoc_thick ///
               v2x_freexp_altinf v2clrelig v2xeg_eqprotec v2xlg_legcon v2x_jucon

use "$data", clear
keep iso3code year `outcomes'
egen id = group(iso3code)
quietly levelsof id if iso3code == "IND", local(tr)
tsset id year

* data check: 19 countries x 40 years, no missing outcomes
quietly count
assert r(N) == 760
foreach v of local outcomes {
    quietly count if `v' >= .
    if r(N) > 0 display as error "`v': `r(N)' missing country-years"
}
display as result "Treated unit id = `tr'; donors = 18; T0 = 30 (1984-2013)"

* donor id -> iso3code lookup, for labelling the weights
preserve
    keep id iso3code
    duplicates drop
    sort id
    save "$out/id_lookup", replace
restore

* --- main run: data-chosen partial pooling, strict p-values -------------------
display as result _newline "==== PPSYNTH: data-chosen partial pooling (aggregate) ===="
ppsynth `outcomes', trunit(`tr') trperiod(2014) id(id) time(year) ///
    method(aggregate) inference convention(strict) massprofile effects ///
    saving("$out/ppsynth_partial")

* copy EVERYTHING ppsynth returns before any other command runs: Stata clears
* r() at the next r-class command, after which r(name) silently evaluates to a
* 1x1 missing matrix.
matrix G  = r(gamma)          // donors x outcomes
matrix YT = r(y_treated)      // years x outcomes
matrix YS = r(y_synth)
matrix AP = r(att_path)
matrix TM = r(times)
matrix PO = r(p_outcome)'     // returned as 1 x K row vectors; transpose
matrix PR = r(pre_rmspe)'
capture matrix PP = r(pp_pvals)
local have_pp = (_rc == 0)
local realized_pooling = r(realized_pooling)
local p_joint_max  = r(p_joint_max)
local p_joint_mean = r(p_joint_mean)
assert colsof(YT) == 10 & rowsof(YT) == 40 & rowsof(G) == 18
display as result "realized pooling = " %5.1f `realized_pooling' "%" ///
    "   joint p (max) = " %5.2f `p_joint_max' "   joint p (mean) = " %5.2f `p_joint_mean'

* --- save the returned matrices as .dta / .csv --------------------------------
* donor weights: one row per donor, one column per outcome
preserve
    clear
    svmat double G, names(w_)
    local k = 1
    foreach v of local outcomes {
        rename w_`k' `v'
        local ++k
    }
    * r(gamma) rows are the donors in id order; the row names are the ids
    gen id = .
    local rn : rownames G
    local n = 1
    foreach r of local rn {
        quietly replace id = `r' in `n'
        local ++n
    }
    merge 1:1 id using "$out/id_lookup", nogenerate keep(match)
    order iso3code id
    egen mean_weight = rowmean(`outcomes')
    gsort -mean_weight
    format `outcomes' mean_weight %6.3f
    list iso3code mean_weight, noobs sep(0)
    save "$out/donor_weights", replace
    export delimited "$out/donor_weights.csv", replace
restore

* India, synthetic India, and the gap, by year, for every outcome
preserve
    clear
    svmat double TM, names(year)
    rename year1 year
    svmat double YT, names(ind_)
    svmat double YS, names(syn_)
    svmat double AP, names(gap_)
    local k = 1
    foreach v of local outcomes {
        rename ind_`k' `v'_india
        rename syn_`k' `v'_synth
        rename gap_`k' `v'_gap
        local ++k
    }
    save "$out/paths_india_synthetic", replace
    export delimited "$out/paths_india_synthetic.csv", replace
    display as result _newline "2023 gaps (Table 1):"
    list year *_gap if year == 2023, noobs
restore

* per-outcome placebo p-values and pre-treatment RMSPEs (1 x K row vectors)
preserve
    clear
    svmat double PO, names(p_strict)
    svmat double PR, names(pre_rmspe)
    rename p_strict1 p_strict
    rename pre_rmspe1 pre_rmspe
    gen outcome = ""
    local k = 1
    foreach v of local outcomes {
        quietly replace outcome = "`v'" in `k'
        local ++k
    }
    order outcome
    format p_strict %5.2f
    format pre_rmspe %7.4f
    list, noobs
    save "$out/p_outcome", replace
    export delimited "$out/p_outcome.csv", replace
restore

* per-period p-values (from the effects option) if returned
if `have_pp' {
    preserve
        clear
        svmat double PP, names(pp_)
        save "$out/pp_pvals", replace
        export delimited "$out/pp_pvals.csv", replace
    restore
}

* --- optional comparison runs (not in the paper): no pooling / full pooling ---
local comparison 0        // set to 1 to run both (another 20-30 minutes)
if `comparison' {
    display as result _newline "==== PPSYNTH: lambda = 0 (separate fits) ===="
    ppsynth `outcomes', trunit(`tr') trperiod(2014) id(id) time(year) ///
        lambda(0) inference convention(strict) effects saving("$out/ppsynth_lam0")
    display as result _newline "==== PPSYNTH: lambda = inf (full pooling) ===="
    ppsynth `outcomes', trunit(`tr') trperiod(2014) id(id) time(year) ///
        lambda(inf) inference convention(strict) effects saving("$out/ppsynth_laminf")
}

display as result _newline "Expected (Python engine, verified 13 Oct 2026): realized pooling 20.5%;" ///
    " 2023 gaps polyarchy -0.352, libdem -0.285, corruption +0.302, religion -1.117;" ///
    " mean weights GRC 35.1%, ARG 20.0%, MYS 13.2%, LKA 10.8%, DOM 7.1%;" ///
    " India ranks 1st on 7 outcomes, 2nd on corruption and equal protection, 3rd on religion."
log close
