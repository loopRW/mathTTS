# Manuscript to output map

Paths below are relative to newly generated results/. Frozen originals and plot-ready reference tables are under reference_results/.

| Manuscript result | New output |
| --- | --- |
| 3.1 Four diagnosis–domain regressions | main/diagnosis_vinegrad_focused.csv |
| 3.2 Observed 45.3% / 55.3% accuracy | main/observed_accuracy.csv |
| 3.2 Primary TTS OR about 1.77 | main/primary_fixed_effects.csv |
| 3.2 Exercise interaction chi-square about 8.50, df=7 | main/exercise_interaction_lrt.csv |
| 3.2 Exercise 4 difference about 24.2 percentage points | main/exercise_contrasts.csv |
| 3.2 Corrected symbol interaction OR about .87, p about .445 | main/symbol_interaction_fixed_effects.csv |
| 3.2 Corrected symbol differences about 10.0 / 6.7 percentage points | main/symbol_contrasts.csv |
| 3.3 Four diagnostic interactions | main/diagnosis_interactions.csv |
| 3.3 Profile main effect chi-square about 26.85, df=2 | main/profile_main_lrt.csv |
| 3.3 Profile interaction chi-square about 1.71, df=2 | main/profile_interaction_lrt.csv |
| 3.4 TTS OR about 1.73–1.77 across specifications | main/sensitivity_TTS.csv |
| 3.4 Version-adjusted profile interaction p about .432 | main/profile_version_interaction_lrt.csv |
| 3.4 TTS × trial p about .513 | main/order_sensitivity_fixed_effects.csv |
| Model convergence/singularity | model_diagnostics.csv |
| Approximate agreement with key reference estimates | reproduction_checks.csv |

The primary model is explicitly specified. It is not selected according to the TTS p-value. Alternative models are sensitivity analyses. Trial and exercise identity coincide; the linear trial interaction is not an independent test of fatigue or learning.

The supplementary sequential MANOVA reproduces the historical exploratory approach; its term tests depend on predictor order. Additional reduced-versus-full Pillai tests are exported to provide associations adjusted for the other diagnoses. Neither is required for the four focused associations in Section 3.1.
