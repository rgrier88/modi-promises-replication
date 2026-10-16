"""
Income figures from output/income_results/ (written by income_results.do):
  Figure 2  main model          (paths_main.csv,    pvals_main.csv)
  Figure 3  in-time placebo 2004 (paths_singh.csv,   pvals_singh.csv)
  Figure 4  all-lags model      (paths_alllags.csv, pvals_alllags.csv)
Each has Panel A (India and synthetic India, levels) and Panel B (yearly
effects with standardized placebo p-values). Writes to output/figures/.
"""
import os, pandas as pd, numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
from figstyle import OUT, save

SRC = os.path.join(OUT, "income_results")
MODELS = [
    ("main",    "Figure2", 2014, "A. Trends in real per-capita income", "Years since Modi became Prime Minister"),
    ("singh",   "Figure3", 2004, "A. Trends in real per-capita income, placebo treatment in 2004", "Years since placebo treatment (2004)"),
    ("alllags", "Figure4", 2014, "A. Trends in real per-capita income, all-lags specification", "Years since Modi became Prime Minister"),
]
fmt = FuncFormatter(lambda v, _: f"{v:,.0f}")

for stub, figno, trper, titleA, xlabB in MODELS:
    P = pd.read_csv(os.path.join(SRC, f"paths_{stub}.csv"))
    V = pd.read_csv(os.path.join(SRC, f"pvals_{stub}.csv"))

    fig, ax = plt.subplots(figsize=(10, 6))
    ax.plot(P.year, P.india, color="black", lw=2.8)
    ax.plot(P.year, P.synthetic, color="#9a9a9a", lw=2.8, ls=(0, (6, 3)))
    ax.axvline(trper - 0.5, color="black", ls=(0, (4, 3)), lw=1.3)
    last = P.iloc[-1]
    ax.annotate("India", (last.year, last.india), xytext=(6, 0), textcoords="offset points", va="center", fontsize=14)
    ax.annotate("Synthetic\nIndia", (last.year, last.synthetic), xytext=(6, 0), textcoords="offset points",
                va="center", fontsize=14, color="#777777")
    ax.set_title(titleA); ax.set_xlabel("Year"); ax.set_ylabel("Real per-capita income")
    ax.set_xticks(range(1984, int(P.year.max()) + 1, 6)); ax.yaxis.set_major_formatter(fmt)
    ax.set_xlim(P.year.min() - 1, P.year.max() + 3.5)
    fig.tight_layout()
    save(fig, f"{figno}A_income_{stub}")

    leads = V.lead.values; eff = V.effect.values; pv = V.pval.values
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.bar(leads, eff, width=0.5, color="#b8b8b8", edgecolor="#808080", lw=1)
    ax.axhline(0, color="black", lw=1.4)
    span = abs(eff).max()
    for x, e, p in zip(leads, eff, pv):
        ax.text(x, e - 0.04 * span if e < 0 else e + 0.04 * span, f"{p:.2f}",
                ha="center", va="top" if e < 0 else "bottom", fontsize=13)
    ax.set_title("B. Treatment effects and p-values")
    ax.set_xlabel(xlabB); ax.set_ylabel("Treatment effect")
    ax.set_xticks(leads); ax.yaxis.set_major_formatter(fmt); ax.margins(y=0.15)
    fig.tight_layout()
    save(fig, f"{figno}B_income_{stub}_pvalues")
