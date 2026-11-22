# Data dictionary

CSV files use UTF-8 encoding and a header row. There are no missing values in the released analytic fields.

## participants.csv

| Field | Meaning |
| --- | --- |
| participant | Study-local pseudonymous code P001–P165; links the two data tables |
| version | 1: TTS on even-numbered exercises; 2: TTS on odd-numbered exercises. Allocation alternated by access, with repeat accesses retaining the version |
| Dyslexia | Self-reported diagnostic indicator, 0 absent / 1 present |
| Dysorthography | Self-reported diagnostic indicator, 0 absent / 1 present |
| Dysgraphia | Self-reported diagnostic indicator, 0 absent / 1 present |
| Dyscalculia | Self-reported diagnostic indicator, 0 absent / 1 present |
| Vine_general | Aggregated general Vinegrad+ difficulty score, 0–8 |
| Vine_reading | Aggregated Reading score, 0–6 |
| Vine_writing | Aggregated Writing score, 0–6 |
| Vine_calculation | Aggregated Calculation score, 0–6 |

Higher Vinegrad+ scores indicate more perceived difficulty. Diagnoses overlap. Canonical release spellings replace the historical source fields `Disorthography`, `Disgraphy`, and `Discalculia`; no values change.

Derived profiles are Reading/Writing (no Dyscalculia), Mathematics (Dyscalculia only), and Mixed (Dyscalculia plus at least one other diagnosis), with n=47, 17, and 101 respectively. They describe the same overall SLD population.

## responses.csv

| Field | Meaning |
| --- | --- |
| participant | Link to participants.csv |
| exercise | Exercise number 1–8; also trial position because presentation order was fixed |
| TTS | 0 without TTS / 1 with TTS, on the initial text; the question expression and answer options were presented without TTS |
| choice | Selected Italian answer text; exact join key with exercise in scoring_key.csv |

Every participant has eight responses, with four TTS=0 and four TTS=1.

## scoring_key.csv

`exercise` and `choice` jointly identify an option. `correct` is 1 for the complete correct reading and 0 otherwise. `similar_correct` and `orientation_correct` are separate binary scores for the two target components. All four options per exercise occur in the observed data. Whitespace in an option is preserved because it forms part of the exact join key; use the released CSVs together.

## exercises.csv

Exercise labels and formulas are human-readable metadata, not a rendering engine for the stimuli. `pair` identifies the adjacent pairs used for text/answer-length matching. Symbol/distractor labels follow the authors' confirmed classification. The full administered materials and English translations are in the manuscript appendix; videos are linked for context.
