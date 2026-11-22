# Called by run_all.R with repository root as working directory.
p <- read.csv("data/participants.csv", stringsAsFactors = FALSE)
r <- read.csv("data/responses.csv", stringsAsFactors = FALSE)
key <- read.csv("data/scoring_key.csv", stringsAsFactors = FALSE)
diagnoses <- c("Dyslexia", "Dysorthography", "Dysgraphia", "Dyscalculia")
scales <- c("Vine_general", "Vine_reading", "Vine_writing", "Vine_calculation")
stopifnot(nrow(p) == 165, nrow(r) == 1320, nrow(key) == 32,
          !anyNA(p), !anyNA(r), !anyNA(key), !anyDuplicated(p$participant),
          !anyDuplicated(r[c("participant", "exercise")]),
          !anyDuplicated(key[c("exercise", "choice")]),
          all(unlist(p[diagnoses]) %in% c(0, 1)), all(r$TTS %in% c(0, 1)))
stopifnot(all(table(r$participant) == 8), all(tapply(r$TTS, r$participant, sum) == 4))
d <- merge(r, key, by = c("exercise", "choice"), all.x = TRUE, sort = FALSE)
stopifnot(nrow(d) == 1320, !anyNA(d))
d <- merge(d, p, by = "participant", all.x = TRUE, sort = FALSE)
d <- d[order(d$participant, d$exercise), ]
stopifnot(!anyNA(d), all(d$TTS == as.integer(
  (d$version == 1 & d$exercise %% 2 == 0) | (d$version == 2 & d$exercise %% 2 == 1))))
stopifnot(all(d$correct == 0 | (d$similar_correct == 1 & d$orientation_correct == 1)))
# The converse is deliberately not imposed: a wrong sign can coexist with
# correct recognition of infinity in Exercise 1.
p$profile <- ifelse(p$Dyscalculia == 0, "Reading/Writing",
  ifelse(rowSums(p[c("Dyslexia", "Dysorthography", "Dysgraphia")]) == 0,
         "Mathematics", "Mixed"))
p$profile <- factor(p$profile, levels = c("Reading/Writing", "Mathematics", "Mixed"))
d$profile <- p$profile[match(d$participant, p$participant)]
d$trial <- d$exercise
d$participant <- factor(d$participant)
d$exercise <- factor(d$exercise)
d$version <- factor(d$version)
d$response_id <- interaction(d$participant, d$exercise, drop = TRUE)
components <- rbind(
  transform(d, symbol_type = "similar", component_correct = similar_correct),
  transform(d, symbol_type = "orientation", component_correct = orientation_correct))
components$symbol_type <- factor(components$symbol_type, levels = c("similar", "orientation"))
dir.create("results", showWarnings = FALSE)
dir.create("results/main", recursive = TRUE, showWarnings = FALSE)
dir.create("results/supplementary", recursive = TRUE, showWarnings = FALSE)
write.csv(d, "results/scored_responses.csv", row.names = FALSE)
write.csv(components, "results/scored_components.csv", row.names = FALSE)
