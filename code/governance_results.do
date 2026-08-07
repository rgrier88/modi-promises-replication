********************************************************************************
* governance_results.do
* Replication code for the governance results in:
*   Grier, Kevin and Robin Grier, "Promises, Promises: Governance and Growth
*   in India under Modi and the BJP."
*
* Produces manuscript Figure 4, Figure 5, Table 2, and Appendix Figures
* A1-A10 (Panel A trends and Panel B annual effects for each of the ten
* governance outcomes).
*
* Specification: masteranalysis3.dta, 12-donor governance pool (IDN BRA MEX
*   ZAF PHL MYS LKA GHA COL PER CHL ARG), sample 1984+, covariates gini
*   csh_g hc. Group A outcomes: lags 1986-2011. Group B (legcon, jucon):
*   data from 1991, lags 1991-2011.
*
* Requirements: Stata with the user-written packages synth and synth_runner.
*
* SETUP: set the global `root' below to the path of this replication folder.
*   All output directories are created automatically.
*
* Structure:
*   PART 1 -- estimation (slow: 10 outcomes x nested synth + synth_runner).
*             Saves all estimates to output/gaps.
*   PART 2 -- figures (fast; runs standalone once PART 1 has completed).
*   PART 3 -- fills Table 2 and exports Table2_values.xlsx.
*   Every figure exports twice: PDF -> output/figures, PNG -> output/web.
********************************************************************************

clear all
set scheme s1mono
graph set window fontface "Garamond"

* --- set this one path, then run -------------------------------------------------
global root "REPLACE-WITH-PATH-TO-THIS-FOLDER"

global data    "$root/data/masteranalysis3.dta"
global gapdir  "$root/output/gaps"
global figures "$root/output/figures"
global web     "$root/output/web"

capture mkdir "$root/output"
capture mkdir "$gapdir"
capture mkdir "$figures"
capture mkdir "$web"

* --- outcomes -------------------------------------------------------------------
local outcomesA v2x_polyarchy v2x_libdem v2x_corr v2xcl_rol ///
                v2x_freexp_altinf v2x_frassoc_thick v2clrelig v2xeg_eqprotec
local outcomesB v2xlg_legcon v2x_jucon

* --- helper: rebuild the governance panel (paper spec) ---------------------------
capture program drop load_master
program define load_master
    use "$data", clear
    gen byte donor_core = inlist(iso3code,"IDN","BRA","MEX","ZAF","PHL","MYS") ///
                        | inlist(iso3code,"LKA","GHA","COL","PER","CHL","ARG")
    keep if iso3code == "IND" | donor_core == 1
    keep if year > 1983
    egen id = group(iso3code)
    tsset id year
end

* --- helper: save effects + standardized p-values to disk ------------------------
capture program drop save_pvals
program define save_pvals
    args stub trper
    tempname P
    matrix `P' = e(pvals_std)
    local K = colsof(`P')

    use "$gapdir/keep_`stub'", clear
    rename _time year
    gen effect = _Y_treated - _Y_synthetic
    keep if year >= `trper' & effect < .
    sort year
    gen lead = _n                     // 1 = treatment year (2014)
    gen pvals_std = .
    forvalues j = 1/`K' {
        quietly replace pvals_std = `P'[1,`j'] in `j'
    }
    replace pvals_std = round(pvals_std, .01)
    keep year lead effect pvals_std
    save "$gapdir/pvals_`stub'", replace
end

* --- helper: India + donors "spaghetti" figure, pre-treatment period ------------
capture program drop donor_spaghetti
program define donor_spaghetti
    syntax , YVar(string) YTit(string) EXportname(string) [XLABopt(string)]
    load_master
    local startyr 1984
    local endyr   2013

    local xl ""
    if `"`xlabopt'"' != "" local xl `"xlabel(`xlabopt')"'

    local graphcmd ""
    local graphcmd `graphcmd' ///
        (line `yvar' year if iso3code=="IND" & inrange(year, `startyr', `endyr'), ///
            lwidth(thick) lcolor(black))
    quietly levelsof iso3code if iso3code != "IND", local(donors)
    foreach c of local donors {
        local graphcmd `graphcmd' ///
            (line `yvar' year if iso3code=="`c'" & inrange(year, `startyr', `endyr'), ///
                lwidth(vthin) lcolor(gs10))
    }

    twoway `graphcmd' ///
        (scatter `yvar' year if year==`endyr' & iso3code=="IND", ///
            msymbol(none) mlabel(iso3code) mlabpos(3) mlabcolor(black)) ///
        (scatter `yvar' year if year==`endyr' & iso3code!="IND", ///
            msymbol(none) mlabel(iso3code) mlabpos(3) mlabcolor(gs8)), ///
        ytitle("`ytit'") ///
        xtitle("Year") ///
        `xl' ///
        legend(off) ///
        plotregion(style(none)) ///
        graphregion(color(white))
    graph export "$figures/`exportname'.pdf", as(pdf) replace
    graph export "$web/`exportname'.png", width(2400) replace
end

* --- helper: trends figure (India vs Synthetic India), paper style --------------
* labyear: -1 (default) = automatic (xln + 5); 0 = no in-graph labels.
capture program drop trend_fig
program define trend_fig
    syntax , STub(string) XLN(real) YTit(string) EXportname(string) ///
        [FIGTitle(string) LABYear(real -1) XLABopt(string) YLABopt(string)]

    use "$gapdir/keep_`stub'", clear
    rename _Y_synthetic synth
    rename _Y_treated India
    rename _time time
    keep synth India time
    drop if India == .

    local topt ""
    if `"`figtitle'"' != "" local topt `"title("`figtitle'", size(medium))"'
    local xl ""
    if `"`xlabopt'"' != "" local xl `"xlabel(`xlabopt')"'
    local yl ""
    if `"`ylabopt'"' != "" local yl `"ylabel(`ylabopt')"'

    local tlab ""
    if `labyear' != 0 {
        local ly = `labyear'
        if `ly' == -1 local ly = `xln' + 5
        quietly summarize India if time == `ly'
        local yI = r(mean)
        quietly summarize synth if time == `ly'
        local yS = r(mean)
        quietly summarize India
        local mn = r(min)
        local mx = r(max)
        quietly summarize synth
        if r(min) < `mn' local mn = r(min)
        if r(max) > `mx' local mx = r(max)
        local off = .07*(`mx' - `mn')
        if `yI' >= `yS' {
            local yIl = `yI' + `off'
            local ySl = `yS' - `off'
        }
        else {
            local yIl = `yI' - `off'
            local ySl = `yS' + `off'
        }
        local tlab `"text(`yIl' `ly' "India", size(medsmall)) text(`ySl' `ly' "Synthetic India", size(medsmall))"'
    }

    twoway ///
        (line India time, lcolor(black) lwidth(medthick)) ///
        (line synth time, lpattern(dash) lcolor(gs10) lwidth(medthick)), ///
        `topt' ///
        xline(`xln', lpattern(dash)) ///
        xtitle("Year") ///
        ytitle("`ytit'") ///
        `xl' `yl' `tlab' ///
        legend(off) ///
        plotregion(style(none)) ///
        graphregion(color(white))
    graph export "$figures/`exportname'.pdf", as(pdf) replace
    graph export "$web/`exportname'.png", width(2400) replace
end

* --- helper: treatment-effect / p-value bars, paper style ------------------------
capture program drop pval_fig
program define pval_fig
    syntax , STub(string) XTit(string) EXportname(string) ///
        [FIGTitle(string) YLABopt(string)]
    use "$gapdir/pvals_`stub'", clear

    local topt ""
    if `"`figtitle'"' != "" local topt `"title("`figtitle'", size(medium))"'
    local yl ""
    if `"`ylabopt'"' != "" local yl `"ylabel(`ylabopt')"'
    quietly summarize lead
    local kmax = r(max)

    twoway ///
        (bar effect lead, base(0) barwidth(.5) fcolor(gs11) lcolor(gs8)) ///
        (scatter effect lead, mlabel(pvals_std) mlabcolor(black) ///
            msymbol(i) mlabpos(6)), ///
        `topt' ///
        xtitle("`xtit'") ///
        ytitle("Treatment Effect") ///
        xlabel(1(1)`kmax') ///
        `yl' ///
        yline(0, lcolor(black)) ///
        legend(off) ///
        plotregion(style(none)) ///
        graphregion(color(white))
    graph export "$figures/`exportname'.pdf", as(pdf) replace
    graph export "$web/`exportname'.png", width(2400) replace
end

********************************************************************************
* PART 1 -- ESTIMATION (slow). Run once; everything is saved to $gapdir.
********************************************************************************

tempname ph
postfile `ph' str32 outcome double pval using "$gapdir/joint_pvals.dta", replace

foreach v of local outcomesA {
    load_master
    quietly levelsof id if iso3code == "IND", local(tr)

    #delimit ;
    synth `v'
        `v'(1986) `v'(1991) `v'(1996) `v'(2001) `v'(2006) `v'(2011)
        gini csh_g hc,
        trunit(`tr') trperiod(2014) nested
        keep("$gapdir/keep_`v'") replace ;
    #delimit cr

    load_master
    quietly levelsof id if iso3code == "IND", local(tr)

    #delimit ;
    synth_runner `v'
        `v'(1986) `v'(1991) `v'(1996) `v'(2001) `v'(2006) `v'(2011)
        gini csh_g hc,
        trunit(`tr') trperiod(2014) nested
        keep("$gapdir/runner_`v'") replace ;
    #delimit cr

    post `ph' ("`v'") (e(pval_joint_post_std))
    save_pvals `v' 2014
}

foreach v of local outcomesB {
    load_master
    keep if year > 1990
    quietly levelsof id if iso3code == "IND", local(tr)

    #delimit ;
    synth `v'
        `v'(1991) `v'(1996) `v'(2001) `v'(2006) `v'(2011)
        gini csh_g hc,
        trunit(`tr') trperiod(2014) nested
        keep("$gapdir/keep_`v'") replace ;
    #delimit cr

    load_master
    keep if year > 1990
    quietly levelsof id if iso3code == "IND", local(tr)

    #delimit ;
    synth_runner `v'
        `v'(1991) `v'(1996) `v'(2001) `v'(2006) `v'(2011)
        gini csh_g hc,
        trunit(`tr') trperiod(2014) nested
        keep("$gapdir/runner_`v'") replace ;
    #delimit cr

    post `ph' ("`v'") (e(pval_joint_post_std))
    save_pvals `v' 2014
}

postclose `ph'

********************************************************************************
* PART 2 -- FIGURES (fast; runs standalone once Part 1 has completed)
********************************************************************************

* normalize lead from year order: 1 = treatment year (2014).
local allten v2x_polyarchy v2x_libdem v2xlg_legcon v2x_jucon v2x_corr ///
             v2xcl_rol v2x_frassoc_thick v2x_freexp_altinf v2clrelig v2xeg_eqprotec
foreach s of local allten {
    use "$gapdir/pvals_`s'", clear
    sort year
    replace lead = _n
    save "$gapdir/pvals_`s'", replace
}

* --- per-outcome figure specifications --------------------------------------------
* appendix order
local order v2x_polyarchy v2x_libdem v2xlg_legcon v2x_jucon v2x_corr ///
            v2xcl_rol v2x_frassoc_thick v2x_freexp_altinf v2clrelig v2xeg_eqprotec

* small-multiple panel display names
local t_v2x_polyarchy     "Polyarchy"
local t_v2x_libdem        "Liberal democracy"
local t_v2x_corr          "Political corruption"
local t_v2xcl_rol         "Equality before the law"
local t_v2xlg_legcon      "Legislative constraints"
local t_v2x_jucon         "Judicial constraints"
local t_v2x_freexp_altinf "Freedom of expression"
local t_v2x_frassoc_thick "Freedom of association"
local t_v2clrelig         "Freedom of religion"
local t_v2xeg_eqprotec    "Equal protection"

* Panel A titles (as in the manuscript)
local tt_v2x_polyarchy     "A. Trends in polyarchy"
local tt_v2x_libdem        "A. Trends in liberal democracy"
local tt_v2xlg_legcon      "A. Trends in legislative constraints"
local tt_v2x_jucon         "A. Trends in Judicial Constraints on the Executive"
local tt_v2x_corr          "A. Trends in political corruption"
local tt_v2xcl_rol         "A. Trends in the equality before the law and individual liberty"
local tt_v2x_frassoc_thick "A. Trends in the Freedom of Association"
local tt_v2x_freexp_altinf "A. Trends in the freedom of expression"
local tt_v2clrelig         "A. Trends in the freedom of religion"
local tt_v2xeg_eqprotec    "A. Trends in the equal protection under the law"

* Panel A y-axis titles
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

* Panel A x-axis ticks
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

* Panel A y-axis ticks
local yl_v2x_polyarchy     ".4(.1).8"
local yl_v2x_libdem        ".3(.1).7"
local yl_v2xlg_legcon      ".5(.1)1"
local yl_v2x_jucon         ".7(.05).9"
local yl_v2x_corr          ".2(.1).8"
local yl_v2xcl_rol         ".55(.05).75"
local yl_v2x_frassoc_thick ".5(.1)1"
local yl_v2x_freexp_altinf ".4(.1).9"
local yl_v2clrelig         "-.5(.5)1.5"
local yl_v2xeg_eqprotec    ".5(.05).75"

* appendix numbers and file slugs
local a_v2x_polyarchy     "A1"
local a_v2x_libdem        "A2"
local a_v2xlg_legcon      "A3"
local a_v2x_jucon         "A4"
local a_v2x_corr          "A5"
local a_v2xcl_rol         "A6"
local a_v2x_frassoc_thick "A7"
local a_v2x_freexp_altinf "A8"
local a_v2clrelig         "A9"
local a_v2xeg_eqprotec    "A10"

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

* ---------- Figure 4: polyarchy spaghetti, alternative donor pool -----------------
donor_spaghetti, yvar(v2x_polyarchy) ytit("Polyarchy Index") ///
    xlabopt("1984(5)2014") exportname(Fig4_polyarchy_altpool)

* ---------- Figure 5: 10-panel small multiples ------------------------------------
* Reading order of the combined figure (2 cols x 5 rows)
local sm_order v2x_polyarchy v2x_libdem v2x_corr v2xcl_rol ///
               v2xlg_legcon v2x_jucon v2x_freexp_altinf v2x_frassoc_thick ///
               v2clrelig v2xeg_eqprotec

use "$gapdir/joint_pvals.dta", clear
forvalues i = 1/`=_N' {
    local o = outcome[`i']
    local p_`o' : display %4.2f pval[`i']
}

local panels ""
foreach v of local sm_order {
    use "$gapdir/keep_`v'", clear
    rename _time year
    gen gap = _Y_treated - _Y_synthetic
    drop if gap == .

    * ylabel(#4) keeps the panel tick labels legible at small size
    twoway line gap year,                              ///
        lcolor(black) lwidth(medthick)                 ///
        yline(0, lcolor(gs8))                          ///
        xline(2013, lpattern(dash) lcolor(gs8))        ///
        xscale(range(1984 2023))                       ///
        xlabel(1985(5)2020, labsize(small))            ///
        ylabel(#4, labsize(small))                     ///
        title("`t_`v''", size(medsmall))               ///
        subtitle("joint p = `p_`v''", size(small))     ///
        xtitle("") ytitle("")                          ///
        plotregion(style(none))                        ///
        graphregion(color(white))                      ///
        name(g_`v', replace) nodraw

    local panels `panels' g_`v'

    * export each panel individually. PNG export rasterizes, so the
    * graph must be displayed first (a nodraw graph throws r(693)).
    graph display g_`v'
    graph export "$web/panel_`f_`v''.png", width(1600) replace
}

#delimit ;
graph combine `panels',
    rows(5) cols(2)
    note("Each panel plots India minus its synthetic counterfactual. Dashed line marks 2013,"
         "the last pre-treatment year. Joint p = standardized post-treatment p-value from"
         "randomization inference (synth_runner).", size(vsmall))
    xsize(6.5) ysize(9) iscale(.55) imargin(small)
    graphregion(color(white)) ;
#delimit cr

graph export "$figures/Fig5_governance_smallmultiples.pdf", as(pdf) replace
graph export "$web/Fig5_governance_smallmultiples.png", width(3200) replace

* ---------- Figures A1-A10: Panel A (trends) + Panel B (effects/p-values) ---------
foreach v of local order {
    trend_fig, stub(`v') xln(2013) ///
        figtitle("`tt_`v''") ///
        ytit("`y_`v''") ///
        xlabopt("`xl_`v''") ylabopt("`yl_`v''") ///
        exportname(Fig`a_`v''a_`f_`v''_trends)

    pval_fig, stub(`v') ///
        figtitle("B. Annual treatment effects and p-values") ///
        xtit("Years since Modi became Prime Minister") ///
        exportname(Fig`a_`v''b_`f_`v''_pvals)
}

********************************************************************************
* PART 3 -- TABLE 2 (Summary of governance treatment effects)
* Built from the files PART 1 saved; no re-estimation needed.
********************************************************************************

local stubs  v2x_polyarchy v2x_libdem v2xlg_legcon v2x_jucon v2x_corr ///
             v2xcl_rol v2x_frassoc_thick v2x_freexp_altinf v2clrelig v2xeg_eqprotec
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

tempname T
postfile `T' str32 indicator double(final_gap pct_of_2013 joint_p) ///
    using "$gapdir/table2_values.dta", replace

foreach v of local stubs {
    use "$gapdir/keep_`v'", clear
    rename _time year
    gen gap = _Y_treated - _Y_synthetic
    quietly summarize year if gap < .
    local lastyr = r(max)
    quietly summarize gap if year == `lastyr'
    local fgap = r(mean)
    quietly summarize _Y_treated if year == 2013
    local lvl13 = r(mean)
    local pct = 100 * `fgap' / `lvl13'

    use "$gapdir/joint_pvals.dta", clear
    quietly levelsof pval if outcome == "`v'", local(jp)

    post `T' ("`n_`v''") (`fgap') (`pct') (`jp')
}
postclose `T'

use "$gapdir/table2_values.dta", clear
format final_gap %9.3f
format pct_of_2013 %9.1f
format joint_p %9.2f
list, noobs sep(0) abbreviate(32)

export excel using "$gapdir/Table2_values.xlsx", firstrow(variables) replace
display as result "Saved: $gapdir/Table2_values.xlsx"

* NOTES
* - final_gap is in the units of each index (signed): negative = India below
*   its synthetic. Political corruption should come out POSITIVE.
* - pct_of_2013 = final-year gap as a percent of India's own 2013 level.
* - Expected values (paper Table 2): polyarchy -0.391 / -60.2%,
*   corruption +0.272 / +46.8%, expression -0.488 / -56.2%,
*   religion -1.407 / -168.7%, all joint p = 0.00.
