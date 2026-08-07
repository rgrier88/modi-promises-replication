# Replication package: "Promises, Promises: Governance and Growth in India under Modi and the BJP"

**Kevin Grier and Robin Grier** (Texas Tech University)

- Working paper: [SSRN link — TODO]
- Data companion site: https://rgrier88.github.io/modi-promises/

This repository contains the complete data and Stata code to reproduce every figure and table in the paper. Nothing is hand-edited: all results regenerate from the two do-files below.

## Contents

| File | What it does |
|---|---|
| `code/income_results.do` | Income results: Figures 2, 3, 6, 7, 8; leave-one-out robustness (paper footnote 15) |
| `code/governance_results.do` | Governance results: Figures 4, 5, Table 2, Appendix Figures A1–A10 |
| `data/income_panel.dta` | Income analysis panel (Penn World Table 11.0 + covariates): India and the 14 donor countries, 1984–2023 |
| `data/governance_panel.dta` | Governance analysis panel (V-Dem + covariates): India and the 12 donor democracies, 1984–2023 |

## Requirements

- Stata 17 or later (earlier versions likely work but are untested)
- User-written packages: `synth` and `synth_runner`

```stata
ssc install synth, replace
net install synth_runner, from(https://raw.github.com/bquistorff/synth_runner/master/) replace
```

- Figures use the Garamond font (`graph set window fontface`). If Garamond is not installed, Stata falls back to its default font; results are unaffected.

## How to run

1. Open either do-file and edit the single `global root` line at the top to point to this repository's folder on your machine.
2. Run the file. Each is organized in independent parts:
   - **Part 1 — Estimation** (slow: nested `synth`/`synth_runner` runs; expect [TODO: fill in your observed runtimes] on a modern machine). Saves all estimates to disk in `output/gaps/`.
   - **Part 2 — Figures** (fast; runs standalone once Part 1 has completed once).
   - **Part 3** — income: leave-one-out donor robustness; governance: fills Table 2 and exports `Table2_values.xlsx`.

Output folders (`output/gaps/`, `output/figures/`, `output/web/`) are created automatically. Because Part 1's estimates persist on disk, figures and tables can be regenerated indefinitely without re-estimation.

## Figure and table map

| Paper exhibit | Produced by | Output file |
|---|---|---|
| Figure 2 (income donor pool) | income | `Fig2_donorpool_income` |
| Figure 3 (polyarchy, economic pool) | income | `Fig3_polyarchy_econpool` |
| Figure 4 (polyarchy, alternative pool) | governance | `Fig4_polyarchy_altpool` |
| Figure 5 (10-panel governance effects) | governance | `Fig5_governance_smallmultiples` |
| Figure 6 (income: trends, effects) | income | `Fig6a_…`, `Fig6b_…` |
| Figure 7 (all-lags specification) | income | `Fig7a_…`, `Fig7b_…` |
| Figure 8 (in-time placebo) | income | `Fig8a_…`, `Fig8b_…` |
| Table 2 (governance summary) | governance | `Table2_values.xlsx` |
| Appendix Figures A1–A10 | governance | `FigA1a_…` … `FigA10b_…` |
| Leave-one-out robustness (fn. 15) | income | `Robust_income_noETH_…` |

## Data sources

- **Governance indicators**: Varieties of Democracy (V-Dem), version [TODO: version number]. Coppedge, Michael, et al. [TODO: full V-Dem citation used in the paper].
- **Income and covariates**: Penn World Table 11.0. Feenstra, Robert C., Robert Inklaar and Marcel P. Timmer (2015), "The Next Generation of the Penn World Table," *American Economic Review* 105(10): 3150–3182.
- [TODO: Gini source citation for the governance covariates]

The `.dta` files in `data/` are the authors' derived analysis panels constructed from these sources; original data remain the property of their providers under their respective terms.

## Citation

> Grier, Kevin and Robin Grier (2026). "Promises, Promises: Governance and Growth in India under Modi and the BJP." Working paper, Texas Tech University. [SSRN link — TODO]

## License

Code is released under the MIT License (see `LICENSE`). The derived data files are provided for replication; please cite the original data providers listed above in any reuse.

## Contact

Kevin Grier — https://www.kevinbgrier.com · Robin Grier — https://www.robinmgrier.com
