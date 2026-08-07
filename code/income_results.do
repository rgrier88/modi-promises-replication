********************************************************************************
* income_results.do
* Replication code for the income results in:
*   Grier, Kevin and Robin Grier, "Promises, Promises: Governance and Growth
*   in India under Modi and the BJP."
*
* Produces manuscript Figures 2, 3, 6, 7, and 8, and the leave-one-out donor
* robustness reported in footnote 15.
*
* Specification: income_panel.dta, outcome rgdppc, 14-donor pool,
*   sample 1984+, outcome lags 1986-2011, covariates csh_g hc csh_x csh_i.
*
* Requirements: Stata with the user-written packages synth and synth_runner.
*
* SETUP: set the global `root' below to the path of this replication folder.
*   All output directories are created automatically.
*
* Structure:
*   PART 1 -- estimation (slow). Saves all estimates to output/gaps.
*   PART 2 -- figures (fast; runs standalone once PART 1 has completed).
*   PART 3 -- leave-one-out donor robustness (footnote 15).
*   Every figure exports twice: PDF -> output/figures, PNG -> output/web.
********************************************************************************

clear all
set scheme s1mono
graph set window fontface "Garamond"

* --- set this one path, then run -------------------------------------------------
global root "REPLACE-WITH-PATH-TO-THIS-FOLDER"

global data    "$root/data/income_panel.dta"
global gapdir  "$root/output/gaps"
global figures "$root/output/figures"
global web     "$root/output/web"

capture mkdir "$root/output"
capture mkdir "$gapdir"
capture mkdir "$figures"
capture mkdir "$web"

* --- helper: rebuild the income panel (paper spec) ------------------------------
capture program drop load_master
program define load_master
    use "$data", clear
    gen byte donor_core = inlist(iso3code,"CHN","IDN","BGD","PAK","VNM") ///
                        | inlist(iso3code,"THA","PHL","EGY","BRA","MEX") ///
                        | inlist(iso3code,"TUR","ETH","ZAF","MYS")
    keep if iso3code == "IND" | donor_core == 1
    keep if year > 1983
    egen id = group(iso3code)
    tsset id year
end

* --- helper: save effects + standardized p-values to disk ----------------------
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
    gen lead = _n                     // 1 = treatment year
    gen pvals_std = .
    forvalues j = 1/`K' {
        quietly replace pvals_std = `P'[1,`j'] in `j'
    }
    replace pvals_std = round(pvals_std, .01)
    keep year lead effect pvals_std
    save "$gapdir/pvals_`stub'", replace
end

* --- helper: India + donors "spaghetti" figure, pre-treatment period ------------
* Paper style: no box, no title (heading lives in the Word file), rotated
* ytitle, India thick black with black IND label, donors thin gray with gray
* labels at the final year.
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
* labyear: year at which the in-graph "India"/"Synthetic India" labels sit;
*   -1 (default) = automatic (xln + 5); 0 = no labels (placebo figure).
* Whichever series is higher at labyear gets its label above the line, the
* other below, offset by 7% of the joint y-range.
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
* PART 1 -- ESTIMATION (slow)
********************************************************************************

tempname jph
postfile `jph' str16 model double joint_p using "$gapdir/income_joint_pvals.dta", replace

* ---------- (1) MAIN MODEL (paper spec, verbatim) -------------------------------
load_master
quietly levelsof id if iso3code == "IND", local(tr)

#delimit ;
synth rgdppc
    rgdppc(1986) rgdppc(1991) rgdppc(1996)
    rgdppc(2001) rgdppc(2006) rgdppc(2011)
    csh_g hc csh_x csh_i,
    trunit(`tr') trperiod(2014) nested
    keep("$gapdir/keep_inc_main") replace ;
#delimit cr

load_master
quietly levelsof id if iso3code == "IND", local(tr)

#delimit ;
synth_runner rgdppc
    rgdppc(1986) rgdppc(1991) rgdppc(1996)
    rgdppc(2001) rgdppc(2006) rgdppc(2011)
    csh_g hc csh_x csh_i,
    trunit(`tr') trperiod(2014) nested
    keep("$gapdir/runner_inc_main") replace ;
#delimit cr

post `jph' ("main") (e(pval_joint_post_std))
save_pvals inc_main 2014

* ---------- (2) IN-TIME PLACEBO: treatment 2001, sample ends 2010 ---------------
load_master
drop if year > 2010
quietly levelsof id if iso3code == "IND", local(tr)

#delimit ;
synth rgdppc
    rgdppc(1986) rgdppc(1991) rgdppc(1996) rgdppc(2000)
    csh_g hc csh_x csh_i,
    trunit(`tr') trperiod(2001) nested
    keep("$gapdir/keep_inc_placebo") replace ;
#delimit cr

load_master
drop if year > 2010
quietly levelsof id if iso3code == "IND", local(tr)

#delimit ;
synth_runner rgdppc
    rgdppc(1986) rgdppc(1991) rgdppc(1996) rgdppc(2000)
    csh_g hc csh_x csh_i,
    trunit(`tr') trperiod(2001) nested
    keep("$gapdir/runner_inc_placebo") replace ;
#delimit cr

post `jph' ("placebo") (e(pval_joint_post_std))
save_pvals inc_placebo 2001

* ---------- (3) ALL-LAGS MODEL: every pre-treatment lag, no covariates ----------
local laglist ""
forvalues y = 1984/2013 {
    local laglist `laglist' rgdppc(`y')
}

load_master
quietly levelsof id if iso3code == "IND", local(tr)

#delimit ;
synth rgdppc
    `laglist',
    trunit(`tr') trperiod(2014) nested
    keep("$gapdir/keep_inc_alllags") replace ;
#delimit cr

load_master
quietly levelsof id if iso3code == "IND", local(tr)

#delimit ;
synth_runner rgdppc
    `laglist',
    trunit(`tr') trperiod(2014) nested
    keep("$gapdir/runner_inc_alllags") replace ;
#delimit cr

post `jph' ("alllags") (e(pval_joint_post_std))
save_pvals inc_alllags 2014

postclose `jph'
use "$gapdir/income_joint_pvals.dta", clear
format joint_p %9.2f
display as result "Joint post-treatment standardized p-values (income models):"
list, noobs

********************************************************************************
* PART 2 -- FIGURES (fast; runs standalone once Part 1 has completed)
********************************************************************************

* normalize lead from year order: 1 = treatment year (2014).
foreach s in inc_main inc_placebo inc_alllags {
    use "$gapdir/pvals_`s'", clear
    sort year
    replace lead = _n
    save "$gapdir/pvals_`s'", replace
}

* ---------- Figure 2: India and the donor pool, pre-treatment (income) -----------
donor_spaghetti, yvar(rgdppc) ytit("Real GDP per capita") ///
    xlabopt("1984(5)2014") exportname(Fig2_donorpool_income)

* ---------- Figure 3: polyarchy, ECONOMIC donor pool ------------------------------
* (Figure 4, the alternative-pool version, is produced by
*  governance_results.do.)
donor_spaghetti, yvar(v2x_polyarchy) ytit("Polyarchy Index") ///
    xlabopt("1984(5)2014") exportname(Fig3_polyarchy_econpool)

* ---------- Figure 6: main income model -------------------------------------------
trend_fig, stub(inc_main) xln(2013) ///
    figtitle("A. Trends in real per-capita income") ///
    ytit("Real per-capita income") ///
    xlabopt("1984(6)2020") ylabopt("2000(2000)10000") labyear(2018) ///
    exportname(Fig6a_income_trends)

pval_fig, stub(inc_main) ///
    figtitle("B. Treatment effects and p-values") ///
    xtit("Years since Modi became Prime Minister") ///
    ylabopt("-1200(200)0") ///
    exportname(Fig6b_income_pvals)

* ---------- Figure 7: all-lags specification --------------------------------------
trend_fig, stub(inc_alllags) xln(2013) ///
    figtitle("A. Trends in real per-capita income") ///
    ytit("Real per-capita income") ///
    xlabopt("1986(10)2016") ylabopt("2000(2000)10000") labyear(2018) ///
    exportname(Fig7a_income_alllags_trends)

pval_fig, stub(inc_alllags) ///
    figtitle("B. Treatment effects and p-values") ///
    xtit("Years since Modi became Prime Minister") ///
    ylabopt("-1000(200)0") ///
    exportname(Fig7b_income_alllags_pvals)

* ---------- Figure 8: in-time placebo (treatment 2001) ----------------------------
* No in-graph line labels (labyear(0)), matching the manuscript.
trend_fig, stub(inc_placebo) xln(2000) ///
    figtitle("A. Trends in real per-capita income") ///
    ytit("Real per-capita income") ///
    xlabopt("1985(5)2010") ylabopt("1000(1000)5000") labyear(0) ///
    exportname(Fig8a_income_placebo_trends)

pval_fig, stub(inc_placebo) ///
    figtitle("B. Annual treatment effects and p-values") ///
    xtit("Years since placebo treatment") ///
    ylabopt("-1000(200)0") ///
    exportname(Fig8b_income_placebo_pvals)


********************************************************************************
* PART 3 -- DONOR-POOL ROBUSTNESS (leave-one-out for the two largest donors)
* Reported in footnote 15. Produced as standalone figures with descriptive
* baked-in titles (they do not appear in the manuscript).
********************************************************************************

* ---------- (4) MAIN MODEL WITHOUT ETHIOPIA --------------------------------------
load_master
drop if iso3code == "ETH"
quietly levelsof id if iso3code == "IND", local(tr)

#delimit ;
synth rgdppc
    rgdppc(1986) rgdppc(1991) rgdppc(1996)
    rgdppc(2001) rgdppc(2006) rgdppc(2011)
    csh_g hc csh_x csh_i,
    trunit(`tr') trperiod(2014) nested
    keep("$gapdir/keep_inc_noETH") replace ;
#delimit cr

load_master
drop if iso3code == "ETH"
quietly levelsof id if iso3code == "IND", local(tr)

#delimit ;
synth_runner rgdppc
    rgdppc(1986) rgdppc(1991) rgdppc(1996)
    rgdppc(2001) rgdppc(2006) rgdppc(2011)
    csh_g hc csh_x csh_i,
    trunit(`tr') trperiod(2014) nested
    keep("$gapdir/runner_inc_noETH") replace ;
#delimit cr

display as result "Joint p-value (standardized), Ethiopia excluded: " %5.2f e(pval_joint_post_std)
save_pvals inc_noETH 2014

* normalize leads for the robustness pvals as well
foreach s in inc_noETH {
    use "$gapdir/pvals_`s'", clear
    sort year
    replace lead = _n
    save "$gapdir/pvals_`s'", replace
}

* ---------- figures (titled; standalone handouts, not manuscript figures) --------

trend_fig, stub(inc_noETH) xln(2013) ///
    figtitle("Trends in real per-capita income (Ethiopia excluded)") ///
    ytit("Real per-capita income") labyear(2018) ///
    exportname(Robust_income_noETH_trends)

pval_fig, stub(inc_noETH) ///
    figtitle("Annual treatment effects and p-values (Ethiopia excluded)") ///
    xtit("Years since Modi became Prime Minister") ///
    exportname(Robust_income_noETH_pvals)
