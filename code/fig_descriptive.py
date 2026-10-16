"""
Figures A11 (Panels A-B) and A12 (Panels A-C) from data/descriptive_figures_A11_A12.csv,
the hand-collected numbers with one source per row (see docs/Verification_list_Section4A_v2.docx).
Writes to output/figures/.
"""
import os, pandas as pd, numpy as np
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
from figstyle import ROOT, save

D = pd.read_csv(os.path.join(ROOT, "data", "descriptive_figures_A11_A12.csv"))
BLUE, ORANGE, INK, GREY = "#2a6496", "#c75b26", "#1f2a35", "#5a6570"

def frame(fig, title, subtitle, source, notes=()):
    fig.text(0.06, 0.94, title, fontsize=24, fontweight="bold", color=INK, ha="left", va="top")
    fig.text(0.06, 0.885, subtitle, fontsize=16, color=GREY, ha="left", va="top")
    y = 0.06
    for line in list(notes)[::-1]:
        fig.text(0.06, y, line, fontsize=12, color=GREY, ha="left"); y += 0.035
    fig.text(0.06, y, source, fontsize=12, color=GREY, ha="left")

def style(ax):
    ax.grid(axis="y", color="#e3e6e8", lw=1); ax.set_axisbelow(True)
    ax.spines["left"].set_visible(False); ax.tick_params(length=0, labelsize=13)

def sel(fig, panel, series):
    s = D[(D.figure == fig) & (D.panel == panel) & (D.series == series)]
    return s.period.tolist(), s.value.astype(float).tolist()

# ---- A11-A: bills referred to committees ----------------------------------------
fig = plt.figure(figsize=(14, 7.5)); ax = fig.add_axes([0.06, 0.2, 0.9, 0.6])
per, val = sel("A11", "A", "Bills referred to committees")
labels = ["Manmohan Singh\n2004–2009", "Manmohan Singh\n2009–2014", "Narendra Modi\n2014–2019", "Narendra Modi\n2019–2024"]
cols = [BLUE, BLUE, ORANGE, ORANGE]
ax.bar(range(4), val, color=cols, width=0.55)
for i, v in enumerate(val): ax.text(i, v + 2.5, f"{v:.0f}%", ha="center", fontsize=22, fontweight="bold", color=cols[i])
ax.axvline(1.5, color="#bbbbbb", ls=(0, (3, 3)), lw=1)
ax.set_xticks(range(4)); ax.set_xticklabels(labels, fontsize=14)
for t, c in zip(ax.get_xticklabels(), cols): t.set_color(c)
ax.set_ylim(0, 100); ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v:.0f}%")); style(ax)
frame(fig, "Bills sent to parliamentary committees", "Share of bills referred for review",
      "Source: PRS Legislative Research (2024), Functioning of the 17th Lok Sabha, p. 2.")
save(fig, "FigureA11A_bills_committees")

# ---- A11-B: politicians investigated ------------------------------------------------
fig = plt.figure(figsize=(14, 7.5))
for j, (agency, key) in enumerate([("Central Bureau of Investigation", "CBI"), ("Enforcement Directorate", "ED")]):
    ax = fig.add_axes([0.07 + 0.5 * j, 0.25, 0.4, 0.5])
    _, tot = sel("A11", "B", f"{key}: politicians investigated"); _, opp = sel("A11", "B", f"{key}: of which opposition")
    ax.bar([0, 1], tot, color=[BLUE, ORANGE], width=0.5)
    for i, (t, o) in enumerate(zip(tot, opp)):
        c = [BLUE, ORANGE][i]
        ax.text(i, t + 4, f"{t:.0f}", ha="center", fontsize=22, fontweight="bold", color=c)
        ax.text(i, -32, f"{100*o/t:.0f}% opposition", ha="center", fontsize=16, fontweight="bold", color=c)
        ax.text(i, -43, f"({o:.0f} of {t:.0f})", ha="center", fontsize=13, color=GREY)
    ax.set_xticks([0, 1]); ax.set_xticklabels(["Manmohan Singh\n2004–2014", "Narendra Modi\n2014–Sep. 2022"], fontsize=14)
    for t, c in zip(ax.get_xticklabels(), [BLUE, ORANGE]): t.set_color(c)
    ax.set_ylim(0, 150); ax.set_title(agency, fontsize=17, color=INK, pad=10); style(ax)
    if j == 0: ax.set_ylabel("Number of politicians", fontsize=14)
frame(fig, "Investigations of politicians", "Politicians identified by the Indian Express investigations",
      "Source: Tiwary (2022a, 2022b), The Indian Express. Shares rounded to whole percentages.",
      ["The periods differ in length; these are totals, not annual rates."])
save(fig, "FigureA11B_politicians_investigated")

# ---- A12-A: religious hate crimes, 2009-2018 ------------------------------------------
fig = plt.figure(figsize=(14, 7.5)); ax = fig.add_axes([0.08, 0.2, 0.86, 0.6])
yrs, inc = sel("A12", "A", "Religious hate-crime incidents"); _, dth = sel("A12", "A", "Religious hate-crime deaths")
yrs = [int(y) for y in yrs]; x = np.arange(len(yrs))
cols = [BLUE if y < 2014 else ORANGE for y in yrs]
ax.bar(x - 0.2, inc, width=0.4, color=cols, label="Incidents")
ax.bar(x + 0.2, dth, width=0.4, color=cols, alpha=0.45, label="Deaths")
for xi, v in zip(x, inc): ax.text(xi - 0.2, v + 1.5, f"{v:.0f}", ha="center", fontsize=13, fontweight="bold", color=cols[xi])
for xi, v in zip(x, dth): ax.text(xi + 0.2, v + 1.5, f"{v:.0f}", ha="center", fontsize=12, color=GREY)
ax.axvline(x[yrs.index(2014)] - 0.5, color="#bbbbbb", ls=(0, (3, 3)), lw=1)
ax.text(x[yrs.index(2014)] - 0.7, 92, "Manmohan Singh", ha="right", fontsize=15, color=BLUE)
ax.text(x[yrs.index(2014)] - 0.3, 92, "Narendra Modi", ha="left", fontsize=15, color=ORANGE)
ax.set_xticks(x); ax.set_xticklabels(yrs, fontsize=13); ax.set_ylim(0, 100); style(ax)
ax.set_ylabel("Number per year", fontsize=14)
ax.legend(frameon=False, loc="upper left", fontsize=14, bbox_to_anchor=(0.0, 0.85))
frame(fig, "Religious hate crimes", "Incidents and deaths recorded by Hate Crime Watch, 2009–2018",
      "Source: FactChecker / Hate Crime Watch, republished by The Wire, 27 Dec 2018.",
      ["Dashed line: May 2014. 2018 runs to 26 December. Counts come from media reports and are not exhaustive."])
save(fig, "FigureA12A_hate_crimes")

# ---- A12-B: FCRA registrations ---------------------------------------------------------
fig = plt.figure(figsize=(14, 7.5)); ax = fig.add_axes([0.08, 0.2, 0.86, 0.6])
dates, val = sel("A12", "B", "FCRA-registered organisations")
t = pd.to_datetime(pd.Series(dates), format="%d %b %Y"); tx = (t.dt.year + (t.dt.dayofyear - 1) / 365.25).to_numpy()
cut = 2014 + (31 + 28 + 31 + 30 + 26) / 365.25   # 26 May 2014
pre = tx < cut
ax.plot(tx[pre], np.array(val)[pre], color=BLUE, lw=3, marker="o", ms=8)
post_x = np.concatenate([[tx[pre][-1]], tx[~pre]]); post_y = np.concatenate([[np.array(val)[pre][-1]], np.array(val)[~pre]])
ax.plot(post_x, post_y, color=ORANGE, lw=3, marker="o", ms=8)
ax.axvline(cut, color="#bbbbbb", ls=(0, (3, 3)), lw=1)
for i in [0, 2, 4, 7]:
    ax.annotate(f"{val[i]:,.0f}", (tx[i], val[i]), xytext=(0, 12 if i in (0, 2) else -28), textcoords="offset points",
                ha="center", fontsize=20, fontweight="bold", color=BLUE if i == 0 else ORANGE)
ax.text(2009.5, 47000, "Manmohan Singh", ha="center", fontsize=16, color=BLUE)
ax.text(2019.5, 47000, "Narendra Modi", ha="center", fontsize=16, color=ORANGE)
ax.text(2017.5, 14000, f"{100*(1-val[7]/val[2]):.1f}% decline", fontsize=24, fontweight="bold", color=ORANGE, ha="center")
ax.text(2017.5, 9500, "July 2014–March 2023", fontsize=15, color=GREY, ha="center")
ax.set_xticks([2005, 2010, 2014, 2018, 2023]); ax.set_ylim(0, 50000)
ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v:,.0f}")); style(ax)
frame(fig, "Groups registered to receive foreign funding", "Number of organizations with FCRA registration",
      "Sources: Ministry of Home Affairs (2005, 2010, 2014, 2016, 2021, 2023); The Week (2022).",
      ["Dashed line: May 2014. Points are dated observations; lines connect them.",
       "Registration definitions may differ across dates; see the paper’s footnotes."])
save(fig, "FigureA12B_fcra_registrations")

# ---- A12-C: online blocking -------------------------------------------------------------
fig = plt.figure(figsize=(14, 7.5))
yrs, blocked = sel("A12", "C", "URLs/accounts ordered blocked"); yrs = [int(y) for y in yrs]
_, rate = sel("A12", "C", "Blocking orders per 10 million internet users")
ryrs, _ = sel("A12", "C", "Blocking orders per 10 million internet users"); ryrs = [int(y) for y in ryrs]
# yearly rate for every year: blocked / (internet share x population) x 1e7, with the shares and
# populations in the CSV interpolated linearly between the listed years
sy, sv = sel("A12", "C", "Internet users, share of population"); py, pv = sel("A12", "C", "Population")
share = np.interp(yrs, [int(y) for y in sy], sv); pop = np.interp(yrs, [int(y) for y in py], pv)
rate_all = np.array(blocked) / (share / 100 * pop) * 1e7
for j, (title, y, col, fmt) in enumerate([("Reported count", blocked, BLUE, "{:,.0f}"), ("Per 10 million internet users", rate_all, ORANGE, "{:.1f}")]):
    ax = fig.add_axes([0.08 + 0.5 * j, 0.22, 0.4, 0.52])
    ax.plot(yrs, y, color=col, lw=3, marker="o", ms=7)
    ax.axvline(2014.4, color="#bbbbbb", ls=(0, (3, 3)), lw=1)
    ax.set_title(title, fontsize=18, color=col, fontweight="bold", pad=12)
    ax.set_xticks([2013, 2016, 2020, 2023]); style(ax)
    ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v:,.0f}"))
    ax.annotate(fmt.format(y[0]), (yrs[0], y[0]), xytext=(0, 14), textcoords="offset points", ha="center", fontsize=18, fontweight="bold", color=col)
    ax.annotate(fmt.format(y[-1]), (yrs[-1], y[-1]), xytext=(-10, 14), textcoords="offset points", ha="center", fontsize=20, fontweight="bold", color=col)
    if j == 1:
        k = int(np.argmax(y)); ax.annotate("Peak in " + str(yrs[k]) + "\n" + fmt.format(y[k]), (yrs[k], y[k]), xytext=(0, 12),
                                            textcoords="offset points", ha="center", fontsize=15, color=col, fontweight="bold")
    ax.margins(y=0.25)
frame(fig, "Government blocking of online content", "Annual reported counts and rates, 2013–2023",
      "Sources: The Hindu (2024); Business Standard (2022); Manral (2024); World Bank WDI (2026).",
      ["Dashed lines: May 2014. Annual 2014 values cover both governments.",
       "Sources differ in counting orders, URLs and accounts; see the paper’s footnotes."])
save(fig, "FigureA12C_online_blocking")
print("A12-C rates (2013, 2020, 2023):", [round(rate_all[yrs.index(y)], 1) for y in (2013, 2020, 2023)], "listed:", rate)
