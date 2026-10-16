"""
Governance figures from the PPSYNTH run (output/governance_ppsynth/, written by
governance_ppsynth.do):
  Figure 1          ten gap paths (India minus synthetic India), one panel each
  Figures A1-A10    Panel A: India and synthetic India in levels
                    Panel B: yearly treatment effects with strict placebo p-values
Reads paths_india_synthetic.csv and pp_pvals.csv. Writes to output/figures/.
"""
import os, pandas as pd, numpy as np
import matplotlib.pyplot as plt
from figstyle import OUT, OUTCOMES, DO_ORDER, save

P = pd.read_csv(os.path.join(OUT, "governance_ppsynth", "paths_india_synthetic.csv"))
PP = pd.read_csv(os.path.join(OUT, "governance_ppsynth", "pp_pvals.csv"))   # 10 rows (2014-2023) x 10 cols (do-file order)
years = P.year.values
post = years >= 2014

# ---- Figure 1: 5 x 2 grid of gap paths ----------------------------------------
fig, axes = plt.subplots(5, 2, figsize=(10, 13.5), sharex=True)
for ax, (v, short, _) in zip(axes.ravel(), OUTCOMES):
    ax.axhline(0, color="#999999", lw=1.2)
    ax.plot(years, P[f"{v}_gap"], color="black", lw=2.4)
    ax.axvline(2013.5, color="black", ls=(0, (4, 3)), lw=1.3)
    ax.set_title(short, fontsize=16)
    ax.set_ylabel("India minus synthetic", fontsize=12)
    ax.set_xticks([1984, 1994, 2004, 2014, 2023])
    ax.tick_params(labelsize=12)
fig.tight_layout(h_pad=1.5, w_pad=2)
save(fig, "Figure1_governance_gaps")

# ---- Figures A1-A10 ------------------------------------------------------------
for i, (v, short, long) in enumerate(OUTCOMES, start=1):
    k = DO_ORDER.index(v)
    # Panel A: levels
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.plot(years, P[f"{v}_india"], color="black", lw=2.8, label="India")
    ax.plot(years, P[f"{v}_synth"], color="#9a9a9a", lw=2.8, ls=(0, (6, 3)), label="Synthetic India")
    ax.axvline(2013.5, color="black", ls=(0, (4, 3)), lw=1.3)
    ax.set_title(f"A. Trends in {long}")
    ax.set_xlabel("Year"); ax.set_ylabel(long)
    ax.set_xticks(range(1984, 2024, 6))
    ax.legend(frameon=False, loc="best")
    fig.tight_layout()
    save(fig, f"FigureA{i}A_{v}_india_synthetic")

    # Panel B: yearly effects with p-values
    eff = P.loc[post, f"{v}_gap"].values
    pv = PP[f"pp_{k+1}"].values
    leads = np.arange(1, 11)
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.bar(leads, eff, width=0.5, color="#b8b8b8", edgecolor="#808080", lw=1)
    ax.axhline(0, color="black", lw=1.4)
    span = max(abs(eff).max(), 1e-6)
    for x, e, p in zip(leads, eff, pv):
        ax.text(x, e - 0.04 * span if e < 0 else e + 0.04 * span, f"{p:.2f}",
                ha="center", va="top" if e < 0 else "bottom", fontsize=13)
    ax.set_title("B. Treatment effects and p-values")
    ax.set_xlabel("Years since Modi became Prime Minister"); ax.set_ylabel("Treatment effect")
    ax.set_xticks(leads)
    ax.margins(y=0.15)
    fig.tight_layout()
    save(fig, f"FigureA{i}B_{v}_effects_pvalues")
