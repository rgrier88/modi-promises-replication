"""Shared settings for the figure scripts: paths, EB Garamond, outcome names."""
import os, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "output")
FIG = os.path.join(OUT, "figures")
os.makedirs(FIG, exist_ok=True)

for f in os.listdir(os.path.join(ROOT, "code", "fonts")):
    if f.endswith(".ttf"):
        font_manager.fontManager.addfont(os.path.join(ROOT, "code", "fonts", f))

plt.rcParams.update({
    "font.family": "EB Garamond", "font.size": 15,
    "axes.spines.top": False, "axes.spines.right": False,
    "axes.titlesize": 17, "pdf.fonttype": 42, "savefig.dpi": 200,
})

# Table 1 / Figure 1 order and display names
OUTCOMES = [
    ("v2x_polyarchy",     "Polyarchy",               "Polyarchy index"),
    ("v2x_libdem",        "Liberal democracy",       "Liberal democracy index"),
    ("v2xlg_legcon",      "Legislative constraints", "Legislative constraints on the executive"),
    ("v2x_jucon",         "Judicial constraints",    "Judicial constraints on the executive"),
    ("v2x_corr",          "Political corruption",    "Political corruption index"),
    ("v2xcl_rol",         "Equality before the law", "Equality before the law and individual liberty"),
    ("v2x_frassoc_thick", "Freedom of association",  "Freedom of association"),
    ("v2x_freexp_altinf", "Freedom of expression",   "Freedom of expression"),
    ("v2clrelig",         "Freedom of religion",     "Freedom of religion"),
    ("v2xeg_eqprotec",    "Equal protection",        "Equal protection index"),
]
# order of the ten outcomes in governance_ppsynth.do (= column order of pp_pvals.csv)
DO_ORDER = ["v2x_polyarchy", "v2x_libdem", "v2x_corr", "v2xcl_rol", "v2x_frassoc_thick",
            "v2x_freexp_altinf", "v2clrelig", "v2xeg_eqprotec", "v2xlg_legcon", "v2x_jucon"]

def save(fig, name):
    fig.savefig(os.path.join(FIG, name + ".pdf"))
    fig.savefig(os.path.join(FIG, name + ".png"))
    plt.close(fig)
    print("wrote", name)
