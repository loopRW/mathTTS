# Text-to-speech and mathematical notation decoding

Reproducibility materials for **The Impact of Text-to-Speech on the Decoding of Mathematical Formulae in Students with Specific Learning Disorders**.

This repository contains response-level data from 165 participants, the scoring key, analyses corresponding to Sections 3.1–3.4 of the revised manuscript, supplementary analyses, and figure-generation code. Each participant completed eight exercises: four with TTS and four without (1,320 answers; 2,640 symbol-component observations).

## Quick start

From the repository root, install the dependencies once:

```sh
Rscript scripts/install_packages.R
python3 -m pip install -r requirements.txt
```

Then reproduce the analyses and figures:

```sh
Rscript scripts/run_all.R
```

Requirements: R 4.1 or later, the R packages `lme4` and `emmeans`, and Python 3.9 or later with Matplotlib. Model fitting may take several minutes. The analysis script writes to `results/`; figures go to `figures/`. Set `TTS_PYTHON` if the Python executable is not called `python3`. For example, on some Windows installations use `TTS_PYTHON=python` in your environment.

To run only the statistical analyses:

```sh
Rscript scripts/run_all.R --no-figures
```

To regenerate figures without fitting models, using the supplied frozen reference outputs:

```sh
python3 scripts/03_figures.py --results reference_results --output figures_regenerated
```

To regenerate figures from a new analysis run:

```sh
python3 scripts/03_figures.py --results results --output figures_regenerated
```

To check the packaged data, corrected scoring, key reference estimates, and file hashes without R:

```sh
python3 scripts/check_release.py
```

## Folder contents

| Path | Contents |
| --- | --- |
| `data/participants.csv` | One row per participant: questionnaire version, overlapping diagnoses, aggregated Vinegrad+ scale scores |
| `data/responses.csv` | One row per participant and exercise: TTS condition and selected fixed answer option |
| `data/scoring_key.csv` | All 32 observed answer options, with whole-answer and component scores |
| `data/exercises.csv` | Formula labels, symbol contrasts, matched pairs, public TTS video links |
| `scripts/01_prepare_data.R` | Input checks, scoring-key joins, diagnostic profiles, component data |
| `scripts/02_analysis.R` | Main, diagnostic, symbol, profile, sensitivity, and supplementary analyses |
| `scripts/03_figures.py` | Both paper figures and six optional figures; PNG and vector PDF |
| `reference_results/` | Frozen outputs from the analyses previously executed, including corrected symbol results |
| `figures/paper/` | Figure 2 (diagnosis–Vinegrad+) and Figure 3 (exercise-specific TTS changes) |
| `figures/optional/` | Additional figures corresponding to analyses not used as manuscript figures |
| `docs/` | Data dictionary, model map, scoring decisions and figure captions |
| `validation/` | Packaging checks and file hashes |

## Analysis scope

1. **Section 3.1:** Three outcome-specific linear regressions including all four diagnostic indicators. Four focused diagnosis–domain associations are expressed in outcome-SD units; Holm correction applies to those four p-values. Selecting these associations was part of manuscript revision and is not presented as preregistration.
2. **Section 3.2:** Binomial-logit mixed model with TTS, participant and exercise random intercepts, and a participant random slope for TTS. Exercise moderation uses exercise fixed effects and a participant random intercept; the seven interaction terms are assessed jointly by likelihood ratio. The symbol-component model uses the corrected scoring key, TTS × symbol type, and participant, exercise, and original-answer random intercepts.
3. **Section 3.3:** Simultaneous overlapping diagnoses with four TTS interactions (Wald tests, Holm correction). Separate three-profile models test the profile main effect and TTS × profile interaction by likelihood ratio.
4. **Section 3.4:** Alternative random-effect structures, exercise fixed effects, questionnaire-version adjustment, version-adjusted profile moderation, and the linear TTS × trial-position sensitivity model.
5. **Supplementary:** All 16 diagnosis–Vinegrad+ associations, the earlier multivariate profile analysis, Vinegrad+ moderation, profile probabilities and contrasts, diagnostic prevalence and comorbidity combinations.

Superseded aggregated t-tests/correlations and the version × TTS interaction are not part of the revised analysis pipeline. The latter cannot be identified independently of exercise parity under an exercise-fixed specification. The repository does not use it to infer differences between allocation sequences.

## Scoring corrections incorporated

The release incorporates both confirmed corrections. Exercise 1 treats recognition of infinity separately from the sign: both “meno infinito” and “più infinito” correctly recognize infinity for the infinity-versus-eight component. Exercise 8 assigns implication to the visually similar component and proportionality to the orientation component. Whole-answer correctness is unchanged.

Relative to the superseded component dataset, these corrections change 19 component scores in Exercise 1 and swap the two component scores for 72 answers in Exercise 8. The supplied reference symbol model has interaction OR approximately 0.870, 95% CI [0.609, 1.243], p approximately .445. Superseded symbol-model output is excluded.

See `docs/SCORING.md` for exact coding and interpretation.

## Estimates and intervals

The odds ratios are conditional mixed-model estimates. Probability predictions from `emmeans` set random effects to zero; they do not integrate over the random-effects distribution and should not be described as population-marginal probabilities. Probability contrasts are on the response scale and are multiplied by 100 only for the percentage-point figure axes.

Intervals are unadjusted 95% intervals (Wald intervals for mixed-model estimates; t intervals for linear regressions). Holm corrections apply to p-values within the declared test families. A significant within-exercise or within-profile TTS contrast does not establish a between-exercise or between-profile difference; use the interaction tests for that question.

## Figure conventions

Figure numbering follows the manuscript: Figure 1 is the task illustration and is not a statistical plot. The two analytical paper figures are Figures 2 and 3. All statistical figures are exported at six inches (15.24 cm) wide with serif 12-point text. Insert at that width to preserve font size. Figure 2 is 2.5 inches high and Figure 3 is 3.5 inches high. Captions are separate from the images; no repeated Holm/CI footnotes are embedded. The serif font is chosen from installed Times New Roman, Liberation Serif, or DejaVu Serif, in that order.

## Provenance and verification

`reference_results/original_runs/` preserves selected pre-existing model outputs with their original column names and labels. Canonical figure inputs in `reference_results/main/` and `reference_results/supplementary/` use the release terminology. Reference outputs originate from separate analysis runs; they are not represented as the output of a newly executed release pipeline.

The packaging environment did not provide R. The consolidated R pipeline has therefore not been executed end to end in that environment. Input integrity, scoring corrections, participant counts, assignment consistency, and figure generation from reference outputs were checked. All eight supplied figure pairs were regenerated using the included Python script. After an R run, check `results/model_diagnostics.csv`, `results/reproduction_checks.csv`, and `results/sessionInfo.txt`; minor optimizer-dependent numeric differences are possible. Package installation uses available versions, while historical software information is retained where it was supplied with the corrected symbol run. No exact historical package lockfile is claimed.

## Data handling and publication

The release uses study-local participant codes and contains no names, email addresses, timestamps, institutions, age, gender, or unrestricted free-text answers. The `choice` strings are fixed experimental response options. The diagnostic indicators and questionnaire scores remain sensitive participant-level information; the codes are pseudonyms, not a guarantee of irreversible anonymization. Source spreadsheets and clinical records are not included. Vinegrad+ item wording and item-level questionnaire responses are not distributed.

This folder is prepared for author review and upload; no GitHub publication is performed by these scripts. No software or data license is assigned in this package. The authors should select the intended license and verify that the planned public sharing is covered by their consent and ethics arrangements before publishing. The statistical scripts do not require the linked external videos to execute.
