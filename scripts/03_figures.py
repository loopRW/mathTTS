#!/usr/bin/env python3
"""Create paper Figures 2/3 and optional figures from analysis CSVs.

Works with results/ after fitting, or reference_results/ without R.
All exports use a six-inch width and serif 12-point text. No captions are
embedded. Point intervals are unadjusted 95% intervals; relevant multiplicity
adjustments are applied in the analysis tables, not to the intervals.
"""
import argparse
import csv
from pathlib import Path
import math
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import FixedLocator, FuncFormatter, NullLocator

plt.rcParams.update({
    "font.family": "serif", "font.serif": ["Times New Roman", "Liberation Serif", "DejaVu Serif"],
    "font.size": 12, "axes.labelsize": 12, "xtick.labelsize": 12,
    "ytick.labelsize": 12, "pdf.fonttype": 42, "ps.fonttype": 42,
    "axes.spines.top": False, "axes.spines.right": False,
    "savefig.facecolor": "white",
})

def read(path):
    with path.open(newline="", encoding="utf-8") as stream:
        return list(csv.DictReader(stream))

def interval(row):
    for a, b in [("asymp.LCL", "asymp.UCL"), ("lower.CL", "upper.CL")]:
        if a in row:
            return float(row[a]), float(row[b])
    return (float(row["estimate"]) - 1.95996398454 * float(row["SE"]),
            float(row["estimate"]) + 1.95996398454 * float(row["SE"]))

def forest(labels, estimates, lows, highs, xlabel, destination,
           height=3, null=0, log=False, pvalues=None, xlim=None):
    fig, ax = plt.subplots(figsize=(6, height))
    left = 0.39 if max(map(len, labels)) > 23 else 0.30
    fig.subplots_adjust(left=left, right=.97, bottom=.29 if height <= 2.5 else .23, top=.96)
    ys = list(range(len(labels)))[::-1]
    for y, mid, lo, hi in zip(ys, estimates, lows, highs):
        ax.plot([lo, hi], [y, y], color="black", linewidth=1.2)
        ax.plot(mid, y, "o", color="black", markersize=5.5)
    ax.axvline(null, color=".6", linestyle="--", linewidth=1, zorder=0)
    ax.set_yticks(ys, labels)
    ax.tick_params(axis="y", length=0, pad=8)
    ax.spines["left"].set_visible(False)
    for label in ax.get_yticklabels():
        label.set_horizontalalignment("left")
        # Left-align labels in a fixed column, independent of label length.
        label.set_x(-(left - .025) / (.97 - left))
    ax.set_ylim(-.5, len(labels)-.5)
    if log:
        ax.set_xscale("log")
        lo, hi = ax.get_xlim()
        ticks = [v for v in [.25, .5, .75, 1, 1.5, 2, 2.5, 3, 4] if lo <= v <= hi]
        ax.xaxis.set_major_locator(FixedLocator(ticks))
        ax.xaxis.set_major_formatter(FuncFormatter(lambda value, pos: f"{value:g}"))
        ax.xaxis.set_minor_locator(NullLocator())
    if xlim:
        ax.set_xlim(*xlim)
    if pvalues is not None:
        for y, p in zip(ys, pvalues):
            text = "p < .001" if p < .001 else "p = " + f"{p:.3f}".lstrip("0")
            ax.text(1.65, y, text, va="center", ha="left", fontsize=12)
        ax.set_xticks([0, .5, 1, 1.5])
    fig.supxlabel(xlabel, x=.5, y=.025, fontsize=12)
    for ext in ("pdf", "png"):
        fig.savefig(destination.with_suffix("." + ext), dpi=300)
    plt.close(fig)

def probability_plot(rows, label_column, destination, labels_map):
    groups = list(dict.fromkeys(r.get(label_column, "all") for r in rows))
    fig, ax = plt.subplots(figsize=(6, 3.3))
    fig.subplots_adjust(left=.15, right=.97, bottom=.24, top=.95)
    for tts, offset, marker, color in [(0, -.10, "o", ".45"), (1, .10, "s", "black")]:
        for i, group in enumerate(groups):
            row = next(r for r in rows if r.get(label_column, "all") == group and int(float(r["TTS"])) == tts)
            mid = float(row["prob"]); lo, hi = interval(row)
            ax.errorbar(i+offset, mid*100, yerr=[[100*(mid-lo)], [100*(hi-mid)]],
                        fmt=marker, color=color, capsize=3, markersize=5,
                        label=("Without TTS" if tts == 0 else "With TTS") if i == 0 else None)
    ax.set_xticks(range(len(groups)), [labels_map.get(g, g) for g in groups])
    ax.set_ylabel("Estimated accuracy (%)")
    ax.set_ylim(0, 100)
    ax.set_xlim(-.6, len(groups)-.4)
    ax.legend(frameon=False, fontsize=12)
    for ext in ("pdf", "png"):
        fig.savefig(destination.with_suffix("." + ext), dpi=300)
    plt.close(fig)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--results", type=Path, default=Path("results"))
    parser.add_argument("--output", type=Path, default=Path("figures"))
    args = parser.parse_args()
    src, out = args.results, args.output
    (out/"paper").mkdir(parents=True, exist_ok=True)
    (out/"optional").mkdir(parents=True, exist_ok=True)
    data = read(src/"main/diagnosis_vinegrad_focused.csv")
    order = ["Dyslexia", "Dysorthography", "Dysgraphia", "Dyscalculia"]
    labels = ["Dyslexia – Reading", "Dysorthography – Writing", "Dysgraphia – Writing", "Dyscalculia – Calculation"]
    data.sort(key=lambda r: order.index(r["diagnosis"]))
    forest(labels, [float(r["standardized_difference_sd"]) for r in data],
           [float(r["standardized_ci_low"]) for r in data],
           [float(r["standardized_ci_high"]) for r in data],
           "Adjusted difference in Vinegrad+ score (SD)", out/"paper/figure_2_diagnosis_vinegrad",
           height=2.5, pvalues=[float(r["p_holm_4"]) for r in data], xlim=(-.3, 2.12))
    data = read(src/"main/exercise_contrasts.csv")
    data.sort(key=lambda r: int(r["exercise"]))
    ints = [interval(r) for r in data]
    forest(["Exercise "+r["exercise"] for r in data], [100*float(r["estimate"]) for r in data],
           [100*x[0] for x in ints], [100*x[1] for x in ints],
           "Estimated change in accuracy (percentage points)", out/"paper/figure_3_exercise_effects", height=3.5)
    probability_plot(read(src/"main/primary_probabilities.csv"), "unused",
                     out/"optional/overall_TTS_conditional_probabilities", {"all": "Full sample"})
    data = read(src/"main/symbol_contrasts.csv")
    ints = [interval(r) for r in data]
    forest(["Visually similar", "Orientation/direction"], [100*float(r["estimate"]) for r in data],
           [100*x[0] for x in ints], [100*x[1] for x in ints],
           "Estimated change in accuracy (percentage points)", out/"optional/symbol_effects_corrected", height=2.5)
    data = read(src/"main/diagnosis_interactions.csv")
    forest([r["term"].replace("TTS:", "") for r in data], [float(r["OR"]) for r in data],
           [float(r["CI_low"]) for r in data], [float(r["CI_high"]) for r in data],
           "TTS interaction odds ratio", out/"optional/diagnosis_interactions", height=2.7, null=1, log=True)
    probability_plot(read(src/"supplementary/profile_probabilities.csv"), "profile",
                     out/"optional/profile_conditional_probabilities",
                     {"Reading/Writing": "Reading/Writing", "Mathematics": "Mathematics", "Mixed": "Mixed"})
    data = read(src/"main/sensitivity_TTS.csv")
    names = {"primary": "Primary", "independent_slope": "Independent slope",
             "crossed_intercepts": "Random intercepts", "exercise_fixed": "Exercise fixed",
             "version_adjusted": "Version adjusted"}
    forest([names[r["model"]] for r in data], [float(r["OR"]) for r in data],
           [float(r["CI_low"]) for r in data], [float(r["CI_high"]) for r in data],
           "TTS odds ratio", out/"optional/sensitivity_models", height=3, null=1, log=True)
    data = read(src/"supplementary/vine_interactions.csv")
    forest([r["scale"].replace("Vine_", "").capitalize() for r in data], [float(r["OR"]) for r in data],
           [float(r["CI_low"]) for r in data], [float(r["CI_high"]) for r in data],
           "TTS interaction odds ratio (per SD)", out/"optional/vinegrad_interactions", height=2.7, null=1, log=True)
    print(f"Exported 8 figures as PNG and PDF to {out}")

if __name__ == "__main__":
    main()
