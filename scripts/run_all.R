#!/usr/bin/env Rscript
# Run from any directory: Rscript /path/to/repository/scripts/run_all.R
arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
if (!length(arg)) stop("Run this script using Rscript.")
root <- dirname(dirname(normalizePath(sub("^--file=", "", arg[[1]]))))
setwd(root)
required <- c("lme4", "emmeans")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Missing R packages: ", paste(missing, collapse = ", "),
                         ". Run Rscript scripts/install_packages.R first.")
source("scripts/01_prepare_data.R")
source("scripts/02_analysis.R")
if ("--no-figures" %in% commandArgs(TRUE)) {
  message("Figures skipped (--no-figures).")
} else {
  python <- Sys.getenv("TTS_PYTHON", unset = "python3")
  status <- system2(python, c("scripts/03_figures.py", "--results", "results", "--output", "figures"))
  if (status != 0) stop("Analyses completed; figure generation failed. See README for Python setup.")
}
message("Completed. Outputs: results/ and figures/.")
