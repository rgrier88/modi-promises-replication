# Replication package: "Populism in Power: Governance and Income in Modi’s India"

**Kevin Grier and Robin Grier** (Texas Tech University)

- Working paper: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=7248338
- Companion site: https://rgrier88.github.io/modi-promises/

This repository holds the data, code, logs and figures behind every table and figure in the October 2026 draft. The two analysis panels contain only the variables the paper uses. Every number in the paper traces to a line in one of the Stata logs in `output/`.

## Layout

```
data/      the two analysis panels (.dta and .csv) and the hand-collected descriptive data
code/      four Stata scripts (estimation) and four Python scripts (figures)
output/    one folder per Stata script, each with its log and CSV exports; figures/ holds every figure
docs/      the Section 4A verification list, the governance tables, and the Stata version of Table A1
```

## Requirements

- Stata 16 or later with `synth` and `synth_runner`:
  `ssc install synth, replace` and `net install synth_runner, from(https://raw.github.com/bquistorff/synth_runner/master/) replace`
- `ppsynth` 2.6.1 (Grier 2026), from https://github.com/angusgrier/PPSYNTH (commit 42a9ab7, 25 Aug 2026). Copy the `.ado`, `.sthlp` and `.py` files to your PERSONAL ado folder and run `ppsynth_setup` once; it needs Python 3.10–3.13 with numpy, scipy and numba, and installs them itself.
- For the figure scripts: Python 3 with pandas and matplotlib. EB Garamond is bundled in `code/fonts/`.

## How to run

Each Stata script starts with a `global root` line; set it to this folder. Scripts write only to their own folder under `output/`.

| Script | What it estimates | Produces | Run time |
|---|---|---|---|
| `code/income_results.do` | Main income model, 2004 in-time placebo, all-lags model (synth + synth_runner, nested) | Table 2; Figures 2–4 | hours |
| `code/income_loo_alllags.do` | All-lags model with Bangladesh, China or Ethiopia left out | Table A1; Figure 5 | hours |
| `code/governance_ppsynth.do` | Partially pooled synthetic control, ten V-Dem outcomes jointly (ppsynth) | Table 1; Figure 1; Figures A1–A10; donor weights in Appendix A | 3 minutes |
| `code/governance_synth_appendixB.do` | One-outcome-at-a-time synth with covariates | Table B1 | hours |

Then the figures, from the `code/` folder: `python fig_income.py`, `python fig5_income_leave_one_out.py`, `python fig_governance.py`, `python fig_descriptive.py`. Each reads the CSVs its Stata script wrote and writes PDF and PNG to `output/figures/`.

## Where each exhibit comes from

| Exhibit | Script | Log | Numbers to check |
|---|---|---|---|
| Table 1 (governance, 2023 gaps and p-values) | `governance_ppsynth.do` | `output/governance_ppsynth/governance_ppsynth.log` | polyarchy −0.352, liberal democracy −0.285, corruption +0.302, religion −1.117; strict p = 0.00 on seven outcomes, 0.05 on corruption and equal protection, 0.11 on religion |
| Appendix A weights and RMSPEs | same | same | mean weights GRC 35.1%, ARG 20.0%, MYS 13.2%, LKA 10.8%; pre-RMSPE 0.0145 (polyarchy), 0.0113 (liberal democracy) |
| Figure 1; Figures A1–A10 | same, then `fig_governance.py` | same | per-period p-values: 53 of 100 at 0.00, 75 at 0.05 or less |
| Table 2 (income predictor balance) | `income_results.do` | `output/income_results/income_pol18.log` | India / synthetic income 1986: 1333.15 / 1385.94; investment share 0.22 / 0.20; synth RMSPE 57.68 |
| Figure 2 (main income model) | same, then `fig_income.py` | same | 2023 effect −1,095.5, p 0.06; weights ETH .363, BGD .313, CHN .262 |
| Figure 3 (in-time placebo, 2004) | same | same | 2013 effect −475.1, p 0.28; joint p 0.33 |
| Figure 4 (all-lags) | same | same | 2023 effect −592.7, p 0.06; pre-RMSPE 47.4 |
| Table A1; Figure 5 (leave-one-out) | `income_loo_alllags.do`, then `fig5_income_leave_one_out.py` | `output/income_loo_alllags/income_loo_alllags.log` | 2023 effects −593 / −461 / −498 / −851; ranks 2 of 18, 1 of 17, 3 of 17, 1 of 16 |
| Table B1 (synth per outcome) | `governance_synth_appendixB.do` | `output/governance_synth/governance_results.log` | polyarchy 2023 −0.377, joint p 0.00; equality before the law joint p 0.06 |
| Figures A11–A12 (descriptive) | `fig_descriptive.py` | — (`data/descriptive_figures_A11_A12.csv`, one source per row) | see `docs/Verification_list_Section4A_v2.docx` |

The logs in `output/` are the runs behind the paper: `income_pol18.log` (19 Sep 2026) and `governance_results.log` (18 Sep 2026) were run from earlier versions of the scripts with the same estimation commands; `governance_ppsynth.log` and `income_loo_alllags.log` (13–14 Oct 2026) were run from the scripts in `code/`. The CSVs next to each log are what the figure scripts read. Figures 2–4 in `output/figures/` are from the September run; `fig_income.py` redraws them once `income_results.do` has been rerun and written its CSVs.

## Data

Both panels cover India and eighteen donors, 1984–2023 (760 country-years), identified by `iso3code` and `year`, with `country_name` for readability.

**`data/income_panel`** — donors CHN IDN BRA BGD PAK MEX VNM PHL THA TUR EGY KOR ETH ZAF ARG MMR COD POL, chosen by population and income relative to the United States in 1984 (paper, Section 3).

| Variable | Definition | Source |
|---|---|---|
| `rgdppc` | Real GDP per capita, expenditure side (rgdpe / pop), 2017 PPP dollars | Penn World Table 11.0 |
| `csh_i` | Share of gross capital formation in GDP at current PPPs | PWT 11.0 |
| `csh_x` | Share of merchandise exports in GDP at current PPPs | PWT 11.0 |
| `csh_g` | Share of government consumption in GDP at current PPPs | PWT 11.0 |
| `hc` | Human capital index (years of schooling and returns to education) | PWT 11.0 |

**`data/governance_panel`** — donors ARG BRA COL GHA IDN MYS MEX PER PHL ZAF LKA BEN DOM GRC POL ROU THA ZMB, chosen by income and population in 2013 and the EIU democracy index 2010–13 (paper, Section 3; Chile excluded because V-Dem has no legislative-constraints score for it in 1984–89).

| Variable | Definition | Source |
|---|---|---|
| `v2x_polyarchy` | Electoral democracy index | V-Dem |
| `v2x_libdem` | Liberal democracy index | V-Dem |
| `v2xlg_legcon` | Legislative constraints on the executive | V-Dem |
| `v2x_jucon` | Judicial constraints on the executive | V-Dem |
| `v2x_corr` | Political corruption index (higher = more corruption) | V-Dem |
| `v2xcl_rol` | Equality before the law and individual liberty | V-Dem |
| `v2x_frassoc_thick` | Freedom of association (thick) | V-Dem |
| `v2x_freexp_altinf` | Freedom of expression and alternative sources of information | V-Dem |
| `v2clrelig` | Freedom of religion (ordinal, measurement-model scale) | V-Dem |
| `v2xeg_eqprotec` | Equal protection index | V-Dem |
| `gini`, `csh_g`, `hc` | Covariates for Appendix B only; `gini` is missing for every country in 2023 (not used: predictors average over 1984–2013) | WIID (see note); PWT 11.0 |

Note on the Gini: the master file's merge flag and companion variables (decile means, S80/S20) identify the UNU-WIDER World Income Inequality Database (WIID); the paper's Table B1 note cites the World Inequality Database. Confirm which before publication.

**`data/descriptive_figures_A11_A12.csv`** — the 62 hand-collected numbers behind Figures A11–A12 (bills referred to committees, CBI/ED investigations, hate-crime counts, FCRA registrations, blocking orders, internet users, population), one row per number with its source. The document, page and sentence for each row are in `docs/Verification_list_Section4A_v2.docx`.

## Notes on inference

- `ppsynth` (Table 1) reports strict placebo p-values: the count of placebo units whose post/pre RMSPE ratio exceeds India's, divided by 19 (18 placebos plus India). The attainable values are 0.00, 0.05, 0.11, ….
- `synth_runner` (Table A1, Figures 2–4, Table B1) divides by the number of placebos it completed, and drops any placebo whose nested optimization fails: 17 of 18 in the full income pool and all-lags model, 16 of 17 without Bangladesh or China, 15 of 17 without Ethiopia, 18 of 18 for the 2004 in-time placebo. The logs record the count for every run.
- The PPSYNTH results were cross-checked by running the same engine directly in Python on `data/governance_panel.dta`; the two agree to machine precision (`output/governance_ppsynth/python_crosscheck/`).

## License

See `LICENSE`. Data are redistributed under the terms of their sources (Penn World Table, V-Dem, UNU-WIDER).
