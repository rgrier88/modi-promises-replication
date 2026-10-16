"""
Figure 5: real per-capita income in India and synthetic India, all-lags model,
full 18-donor pool and leaving out Bangladesh, China or Ethiopia.
Reads output/income_loo_alllags/figure5_paths.csv (written by income_loo_alllags.do).
Writes output/figures/Figure5_income_alllags_leave_one_out_levels.{pdf,png}.
"""
import os, sys, pandas as pd, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager
from matplotlib.ticker import FuncFormatter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
for f in os.listdir(os.path.join(ROOT, "code", "fonts")):
    if f.endswith(".ttf"): font_manager.fontManager.addfont(os.path.join(ROOT, "code", "fonts", f))
plt.rcParams.update({"font.family": "EB Garamond", "font.size": 15, "axes.spines.top": False,
                     "axes.spines.right": False, "pdf.fonttype": 42})

d = pd.read_csv(os.path.join(ROOT, "output", "income_loo_alllags", "figure5_paths.csv"))
y23 = d[d.year == 2023].iloc[0]
fig, ax = plt.subplots(figsize=(10, 6.2))
ax.plot(d.year, d.india, color="black", lw=3.2, label="India")
ax.plot(d.year, d.synth_all,   color="#555555", lw=2.4, ls=(0, (6, 3)),             label=f"Synthetic India, all 18 donors (2023: {y23.synth_all:,.0f})")
ax.plot(d.year, d.synth_noBGD, color="#8a8a8a", lw=2.4, ls=(0, (6, 2, 1, 2)),       label=f"Synthetic India without Bangladesh (2023: {y23.synth_noBGD:,.0f})")
ax.plot(d.year, d.synth_noCHN, color="#b5b5b5", lw=2.4, ls=(0, (5, 2, 1, 2, 1, 2)), label=f"Synthetic India without China (2023: {y23.synth_noCHN:,.0f})")
ax.plot(d.year, d.synth_noETH, color="#6f6f6f", lw=2.8, ls=(0, (1.5, 2)),           label=f"Synthetic India without Ethiopia (2023: {y23.synth_noETH:,.0f})")
ax.axvline(2013.5, color="black", ls=(0, (5, 4)), lw=1.3)
ax.set_xlabel("Year"); ax.set_ylabel("Real per-capita income")
ax.set_xticks(range(1984, 2024, 6)); ax.set_xlim(1982.5, 2024.5); ax.set_ylim(900, 10100)
ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v:,.0f}"))
ax.legend(loc="upper left", frameon=False, handlelength=3.2, labelspacing=0.9, fontsize=14)
fig.tight_layout()
out = os.path.join(ROOT, "output", "figures", "Figure5_income_alllags_leave_one_out_levels")
fig.savefig(out + ".pdf"); fig.savefig(out + ".png", dpi=200)
print("wrote", out, "| 2023:", {k: round(y23[k]) for k in ["india","synth_all","synth_noBGD","synth_noCHN","synth_noETH"]})
