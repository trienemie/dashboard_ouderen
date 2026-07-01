
## Code conventions

- **Language:** British English throughout — comments, labels, axis titles,
  variable names where readable.
- **Pipe:** native R pipe (`|>`) for all data transformations.
- **Path management:** `here::here()` for all file paths; never use relative
  paths with `./` or hardcoded absolute paths.
- **Style:** `theme_minimal()`, `ggsave()` with explicit `device = "pdf"` and
  `height`/`width` in inches.
- **Section headers:** every `# ===` section includes a `# INTENT` comment
  explaining the analytical purpose — not what the code does, but what
  question it answers.
- **Inline references:** every weight, threshold, or structural choice cites
  the legal article, regulation, or paper that justifies it — or is explicitly
  labelled `# Own addition:` with a justification.
- **Cross-script dependencies:** if a script saves an `.rds` for downstream
  use, document this at the top of both scripts (producer: "saves X for
  analyses A, B"; consumer: "requires X produced by script N").
- **Terminal message:** every script ends with a `message()` call reporting
  key statistics (record counts, edge counts, coverage percentages, FTE
  estimates) so the analyst can verify results without opening every output
  file.
- **No silent dependencies:** before finalising any classifier, filter, or
  weight vector, verify that every referenced label actually occurs in the
  data — run `count(data, label_col)` and cross-check against the filter list.

---

## Script header structure

Every analysis script must open with the following header before any code.
Data-preparation scripts (no figure output) may omit INTERPRETATION and OUTPUTS
but must retain PURPOSE, DATA PROVENANCE, and METHODOLOGY.

```r
# ==============================================================================
# script_name.R
# <Short description of what this script produces>
#
# PURPOSE
# -------
# <What question does this script answer? One paragraph.>
#
# DATA PROVENANCE
# ---------------
# Input:  <file path and how it was produced / which script produced it>
# Output: <file path(s) saved by this script and consumed by which scripts>
# <Filters applied at this level and their justification>
#
# METHODOLOGY
# -----------
# ## Established frameworks used as anchors
#
# | Framework | Role in this script |
# |---|---|
# | <Author Year, title, DOI or legal article> | <role> |
#
# ## Own methodological additions
#
# | Choice | Justification |
# |---|---|
# | <choice> | <justification> |
#
# INTERPRETATION
# --------------
# <How should the reader interpret the output?
#  What patterns are expected vs. surprising?
#  What actionable conclusion follows from each pattern?>
#
# OUTPUTS
# -------
# output/<descriptor>.csv
# output/<descriptor>.pdf
# ==============================================================================
```

Both methodology tables must always be present. If no published framework anchors
a choice, the own-additions table must still appear and explain each choice.

---

## Methodology and references

### Anchor every choice in an established framework

Do not invent methodology from scratch. Identify published or legally established
frameworks that define the relevant hierarchy or technique, and align choices to
those frameworks. Document the alignment in the METHODOLOGY table of the script
header.

### Separate framework-derived choices from own additions

For every methodological choice, ask: *does this follow from a framework, or is
it my own decision?*

- **Framework-derived:** cite the legal article, regulation, or paper inline.
- **Own addition:** label with `# Own addition:` inline and include the choice
  and justification in the own-additions table in the script header.

### Verify labels against the actual data

Any classifier, weight vector, or filter that references string labels must be
verified against the actual data before finalising. Run a frequency table and
cross-check:

```r
count(data, label_column) |> arrange(desc(n))
```

This guards against silent zero-scores caused by label mismatches (e.g.
capitalisation differences, encoding variants, or terminology drift between the
data source and the filter list).

---

## Exports and column documentation

Every figure must have a corresponding CSV export in `output/`. Scripts that
produce only console output must still export a CSV containing all model inputs
and outputs.

**Why:** reproducibility (exact data behind each figure is recorded
independently of the R environment), downstream use (a later analyst can
filter and join without re-running R), and auditability (every number in a
report can be traced to a CSV row).

Add column descriptions as comments **directly above** each `write.csv()` call:

```r
# Columns — output/descriptor.csv:
#   col_a — what it represents; NA means …
#   col_b — what it represents; 0 means …; unit: count / share / …
#   col_c — primary key / derived metric / label
write.csv(df, here::here("output", "descriptor.csv"), row.names = FALSE)
```

Document for each column: what it represents, what an empty / zero / NA / FALSE
value means, and the unit where applicable.

---

## Verification checklist

Before considering a script complete, verify:

- [ ] Script header contains PURPOSE, DATA PROVENANCE, METHODOLOGY
      (framework table + own-additions table), and — for analysis scripts —
      INTERPRETATION and OUTPUTS.
- [ ] Every `# ===` section has an `# INTENT` comment.
- [ ] Every own methodological choice has a `# Own addition:` inline comment
      that matches an entry in the header own-additions table.
- [ ] Every figure has a corresponding `write.csv()` with column documentation
      directly above the call.
- [ ] All labels in classifiers, weight vectors, and filters have been verified
      against a frequency table of the actual data.
- [ ] The script runs end-to-end without errors from a clean R session
      (`source(here::here("script_name.R"))`).
- [ ] The terminal `message()` output is substantively plausible (record counts,
      coverage percentages, and any other key statistics look correct).
