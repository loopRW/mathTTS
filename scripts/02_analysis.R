library(lme4)
library(emmeans)
ctrl <- glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 200000))
model_status <- list()
write_table <- function(x, name) write.csv(x, file.path("results", paste0(name, ".csv")), row.names = FALSE)
save_model <- function(model, name) {
  capture.output(summary(model), file = file.path("results", paste0(name, ".txt")))
  if (inherits(model, "merMod")) {
    b <- fixef(model); se <- sqrt(diag(vcov(model)))
    tab <- data.frame(term = names(b), beta = unname(b), SE = unname(se),
      OR = exp(b), CI_low = exp(b - qnorm(.975) * se),
      CI_high = exp(b + qnorm(.975) * se), p_value = 2 * pnorm(-abs(b / se)), row.names = NULL)
    msg <- model@optinfo$conv$lme4$messages
    model_status[[name]] <<- data.frame(model = name, singular = isSingular(model),
      convergence_message = if (is.null(msg)) "none" else paste(msg, collapse = "; "))
    write_table(tab, paste0(name, "_fixed_effects"))
    return(tab)
  }
}
lrt <- function(a, b, name) {
  x <- as.data.frame(anova(a, b, test = "Chisq"))
  write_table(data.frame(model = rownames(x), x, row.names = NULL, check.names = FALSE), name)
}
predictions <- function(model, specs, name) {
  # These predictions set random effects to zero. They are not integrated
  # population-average probabilities. Regridding permits response-scale contrasts.
  e <- emmeans(model, specs, at = list(TTS = c(0, 1)), regrid = "response")
  write_table(as.data.frame(summary(e, infer = c(TRUE, TRUE))), paste0(name, "_probabilities"))
  x <- as.data.frame(summary(contrast(e, "revpairwise"), infer = c(TRUE, TRUE), adjust = "none"))
  write_table(x, paste0(name, "_contrasts"))
  x
}

# 3.1: outcome-standardized adjusted differences; Holm across FOUR focused tests.
assoc <- list()
for (outcome in scales) {
  m <- lm(reformulate(diagnoses, response = outcome), data = p)
  capture.output(summary(m), file = paste0("results/supplementary/model_", outcome, ".txt"))
  co <- coef(summary(m))[diagnoses, , drop = FALSE]
  ci <- confint(m)[diagnoses, , drop = FALSE]
  ysd <- sd(p[[outcome]])
  assoc[[outcome]] <- data.frame(outcome = outcome, diagnosis = diagnoses,
    raw_difference = co[, 1], raw_ci_low = ci[, 1], raw_ci_high = ci[, 2],
    standardized_difference_sd = co[, 1] / ysd,
    standardized_ci_low = ci[, 1] / ysd, standardized_ci_high = ci[, 2] / ysd,
    p_value = co[, 4], row.names = NULL)
}
all_assoc <- do.call(rbind, assoc)
all_assoc$p_holm_16 <- p.adjust(all_assoc$p_value, "holm")
write_table(all_assoc, "supplementary/diagnosis_vinegrad_all_16")
write_table(data.frame(diagnosis = diagnoses, VIF = vapply(diagnoses, function(dx) {
  aux <- lm(reformulate(setdiff(diagnoses, dx), response = dx), data = p)
  1 / (1 - summary(aux)$r.squared)
}, numeric(1))), "supplementary/diagnosis_VIF")
focused <- subset(all_assoc,
  (diagnosis == "Dyslexia" & outcome == "Vine_reading") |
  (diagnosis %in% c("Dysorthography", "Dysgraphia") & outcome == "Vine_writing") |
  (diagnosis == "Dyscalculia" & outcome == "Vine_calculation"))
focused$p_holm_4 <- p.adjust(focused$p_value, "holm")
write_table(focused, "main/diagnosis_vinegrad_focused")

# Supplementary earlier multivariate analysis. Pillai tests are adjusted for
# the other diagnoses, by comparing reduced and full response-matrix models.
ymat <- as.matrix(p[scales])
full_mlm <- lm(ymat ~ Dyslexia + Dysorthography + Dysgraphia + Dyscalculia, data = p)
capture.output(summary(manova(full_mlm), test = "Pillai"),
               file = "results/supplementary/manova_sequential_pillai.txt")
for (dx in diagnoses) {
  reduced <- lm(reformulate(setdiff(diagnoses, dx), response = "ymat"), data = p)
  capture.output(anova(reduced, full_mlm, test = "Pillai"),
    file = paste0("results/supplementary/pillai_adjusted_", dx, ".txt"))
}

# Descriptives and comorbidity.
write_table(data.frame(diagnosis = diagnoses,
  present = colSums(p[diagnoses]), absent = nrow(p) - colSums(p[diagnoses])), "main/diagnosis_prevalence")
write_table(as.data.frame(table(diagnosis_count = rowSums(p[diagnoses]))), "main/comorbidity_counts")
combination <- apply(p[diagnoses], 1, function(x) paste(diagnoses[x == 1], collapse = " + "))
write_table(as.data.frame(table(combination)), "supplementary/diagnosis_combinations")
write_table(as.data.frame(table(profile = p$profile)), "main/profile_counts")
raw_summary <- function(data, by) {
  spl <- split(data, interaction(data[by], drop = TRUE))
  do.call(rbind, lapply(spl, function(x) data.frame(x[1, by, drop = FALSE],
    responses = nrow(x), correct_responses = sum(x$correct), accuracy = mean(x$correct))))
}
write_table(raw_summary(d, "TTS"), "main/observed_accuracy")
write_table(raw_summary(d, c("exercise", "TTS")), "main/observed_accuracy_exercise")
write_table(raw_summary(d, c("profile", "TTS")), "main/observed_accuracy_profile")

# 3.2: primary model is specified in advance here, not selected by significance.
primary <- glmer(correct ~ TTS + (1 + TTS | participant) + (1 | exercise),
                 data = d, family = binomial, control = ctrl)
primary_tab <- save_model(primary, "main/primary")
predictions(primary, ~ TTS, "main/primary")
item_add <- glmer(correct ~ TTS + exercise + (1 | participant), data = d,
                  family = binomial, control = ctrl)
item_int <- glmer(correct ~ TTS * exercise + (1 | participant), data = d,
                  family = binomial, control = ctrl)
save_model(item_int, "main/exercise_interaction")
lrt(item_add, item_int, "main/exercise_interaction_lrt")
item_effects <- predictions(item_int, ~ TTS | exercise, "main/exercise")
item_effects$p_holm <- p.adjust(item_effects$p.value, "holm")
write_table(item_effects, "main/exercise_contrasts")
symbol <- glmer(component_correct ~ TTS * symbol_type +
  (1 | participant) + (1 | exercise) + (1 | response_id),
  data = components, family = binomial, control = ctrl)
symbol_tab <- save_model(symbol, "main/symbol_interaction")
predictions(symbol, ~ TTS | symbol_type, "main/symbol")

# 3.3: overlapping diagnoses simultaneously entered, Wald interaction tests.
diagnostic <- glmer(correct ~ TTS * (Dyslexia + Dysorthography + Dysgraphia + Dyscalculia) +
  (1 | participant) + (1 | exercise), data = d, family = binomial, control = ctrl)
dx_tab <- save_model(diagnostic, "main/diagnosis_moderation")
dx_interaction <- dx_tab[grepl("^TTS:", dx_tab$term), ]
dx_interaction$p_holm <- p.adjust(dx_interaction$p_value, "holm")
write_table(dx_interaction, "main/diagnosis_interactions")
for (dx in diagnoses) {
  predictions(diagnostic, as.formula(paste("~ TTS |", dx)),
              paste0("supplementary/TTS_by_", dx))
}
profile_add <- glmer(correct ~ TTS + profile + (1 + TTS | participant) + (1 | exercise),
  data = d, family = binomial, control = ctrl)
profile_int <- glmer(correct ~ TTS * profile + (1 + TTS | participant) + (1 | exercise),
  data = d, family = binomial, control = ctrl)
save_model(profile_add, "main/profile_additive")
save_model(profile_int, "main/profile_interaction")
lrt(primary, profile_add, "main/profile_main_lrt")
lrt(profile_add, profile_int, "main/profile_interaction_lrt")
predictions(profile_int, ~ TTS | profile, "supplementary/profile")
profile_logit <- emmeans(profile_int, ~ TTS | profile, at = list(TTS = c(0, 1)))
write_table(as.data.frame(summary(contrast(profile_logit, "revpairwise"),
  type = "response", infer = c(TRUE, TRUE))), "supplementary/profile_TTS_OR")
profile_means <- emmeans(profile_int, ~ profile | TTS, at = list(TTS = c(0, 1)))
write_table(as.data.frame(summary(pairs(profile_means, adjust = "holm"),
  type = "response", infer = c(TRUE, TRUE))), "supplementary/profile_pairwise_OR_holm")

# 3.4: sensitivity models.
independent <- glmer(correct ~ TTS + (1 + TTS || participant) + (1 | exercise),
  data = d, family = binomial, control = ctrl)
intercepts <- glmer(correct ~ TTS + (1 | participant) + (1 | exercise),
  data = d, family = binomial, control = ctrl)
group_adjusted <- update(primary, . ~ . + version)
profile_group_add <- update(profile_add, . ~ . + version)
profile_group_int <- update(profile_int, . ~ . + version)
order_model <- glmer(correct ~ TTS * trial + (1 | participant) + (1 | exercise),
  data = d, family = binomial, control = ctrl)
sensitivity_models <- list(primary = primary, independent_slope = independent,
  crossed_intercepts = intercepts, exercise_fixed = item_add, version_adjusted = group_adjusted)
sens <- lapply(names(sensitivity_models), function(name) {
  tab <- save_model(sensitivity_models[[name]], paste0("main/sensitivity_", name))
  data.frame(model = name, tab[tab$term == "TTS", ], row.names = NULL)
})
write_table(do.call(rbind, sens), "main/sensitivity_TTS")
save_model(profile_group_add, "main/profile_version_additive")
save_model(profile_group_int, "main/profile_version_interaction")
save_model(order_model, "main/order_sensitivity")
lrt(primary, group_adjusted, "main/version_adjustment_lrt")
lrt(profile_group_add, profile_group_int, "main/profile_version_interaction_lrt")

# Supplement: continuous perceived difficulty moderators. Historical scaling on
# response rows is retained to reproduce the original estimates exactly.
for (j in seq_along(scales)) d[[paste0("z", j)]] <- as.numeric(scale(d[[scales[j]]]))
vine <- glmer(correct ~ TTS * (z1 + z2 + z3 + z4) + (1 | participant) + (1 | exercise),
  data = d, family = binomial, control = ctrl)
vine_tab <- save_model(vine, "supplementary/vine_moderation")
vine_int <- vine_tab[grepl("^TTS:", vine_tab$term), ]
vine_int$scale <- scales
vine_int$p_holm <- p.adjust(vine_int$p_value, "holm")
write_table(vine_int, "supplementary/vine_interactions")

write_table(do.call(rbind, model_status), "model_diagnostics")
capture.output(sessionInfo(), file = "results/sessionInfo.txt")
# Compact verification against published/reference values; platform differences
# can cause minor optimizer variation. This reports differences without selecting models.
checks <- data.frame(metric = c("primary_TTS_OR", "symbol_interaction_OR", "symbol_interaction_p"),
  reference = c(1.7684, 0.8699737656, 0.4446913842),
  reproduced = c(primary_tab$OR[primary_tab$term == "TTS"],
    symbol_tab$OR[symbol_tab$term == "TTS:symbol_typeorientation"],
    symbol_tab$p_value[symbol_tab$term == "TTS:symbol_typeorientation"]))
checks$absolute_difference <- abs(checks$reference - checks$reproduced)
write_table(checks, "reproduction_checks")
print(checks)
