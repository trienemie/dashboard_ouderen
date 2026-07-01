# ==============================================================================
# Stads_data.R
# Parse the Stad in Cijfers variable catalogue and filter to health indicators
#
# PURPOSE
# -------
# This script is the entry point for the older-adults health indicator dashboard
# for the City of Antwerp. It parses the free-text DataSource field of the
# variable catalogue into a structured organisation hierarchy, then filters the
# full catalogue to the subset of indicators relevant to public health and welfare
# of older adults. The result is a clean, joined indicator table ready for
# downstream analysis and visualisation.
#
# DATA PROVENANCE
# ---------------
# Input:  VarDataReport_niet_beveiligd.csv
#         Provided by Jerry Ruys (Stad in Cijfers, June 2026) as
#         VarDataReport_niet_beveiligd.xlsx; converted to CSV externally.
#         Contains 24,440 indicator rows across 274 unique DataSource values.
#         813 rows carry a blank DataSource; all derived columns for these are NA.
#
# Output: output/sources_parsed.csv  — one row per unique DataSource value (274);
#                                      used by all downstream analysis scripts for
#                                      provider-level filtering and grouping.
#         output/df_health.csv       — health-relevant indicator subset (~8,932 rows);
#                                      used by downstream analysis and visualisation
#                                      scripts.
#
# METHODOLOGY
# -----------
# ## Established frameworks used as anchors
#
# | Framework | Role in this script |
# |---|---|
# | None | This script is a data-preparation pipeline, not a statistical analysis. |
#
# ## Own methodological additions
#
# | Choice | Justification |
# |---|---|
# | Split DataSource on " - " / " – " to extract topic | First occurrence of either separator consistently delimits organisation from topic in the raw field |
# | Treat "\|" and "," as equivalent hierarchy delimiters | Both are used interchangeably in the raw field; normalising to "," enables a single split step |
# | Promote "Vlaamse Gemeenschap > Departement Zorg" to top-level "Departement Zorg" | The department operates independently in practice; its parent is an administrative artefact in the catalogue |
# | Normalise capitalisation variants (IMA, POD, FOD) | Identified by frequency inspection of unique organisation values; ensures consistent grouping |
# | Health organisation selection (14 organisations) | Agreed in consultation with the Health department of Stad Antwerpen and Stad in Cijfers (README.md, STAP 3) |
# | Case-insensitive health filter | Guards against future capitalisation drift without requiring duplicate list entries |
# ==============================================================================

library(here)
library(dplyr)
library(stringr)
library(tidyr)
library(purrr)

# === LOAD RAW DATA ===========================================
# INTENT: Read the variable data report so all downstream sections
# work from a single, consistently loaded source.

stads_data <- read.csv2(here::here("VarDataReport_niet_beveiligd.csv"))

# === PARSE DATA SOURCES ======================================
# INTENT: Determine which organisation (and sub-division) is
# responsible for each data source, so indicators can later be
# filtered by provider without re-parsing the DataSource string.
# Own addition: splitting on " - " / " – " to extract topic, then
# on "|" to separate organisation levels, follows the naming
# convention observed in the raw DataSource field.

sources <- data.frame(DataSource = unique(stads_data$DataSource)) |>
  mutate(
    # Own addition: flag records originating from provincies.incijfers.be
    provinces_in_figures = as.factor(if_else(
      str_detect(DataSource, "\\|\\s*provincies\\.incijfers\\.be"),
      "yes", "no"
    )),
    rest  = str_trim(str_remove(DataSource, "\\s*\\|\\s*provincies\\.incijfers\\.be")),
    # Topic: everything after the first " - " or " – "
    topic = str_trim(str_extract(rest, "(?<= [-–] ).*$")),
    rest  = str_trim(str_remove(rest, "\\s+[-–]\\s+.*$")),
    # Normalise " | " to "," for uniform splitting
    rest  = str_replace_all(rest, "\\s*\\|\\s*", ",")
  )

# === SPLIT ORGANISATION HIERARCHY ============================
# INTENT: Establish how many sub-division levels exist across all
# sources, then widen into a rectangular structure so each level
# occupies its own column.
# Own addition: the pipe "|" and comma "," are both used as hierarchy
# delimiters in DataSource; after normalisation they are treated
# identically. Known limitations (not fixed — require domain knowledge):
#   - Multiple " - " in one string: intermediate segment lands in topic
#     rather than a subdivision column (~5 sources affected).
#   - Comma used as co-author separator (not hierarchy) is
#     indistinguishable from a hierarchy delimiter (~5 sources).
#   - 813 blank DataSource rows → all derived columns are NA.

splits    <- str_split(sources$rest, "\\s*,\\s*")
max_parts <- max(map_int(splits, length))

col_names <- c("organisation", paste0("subdivision_", seq_len(max_parts - 1)))

splits_df <- splits |>
  map(\(x) `length<-`(x, max_parts)) |>
  map(as.list) |>
  map_dfr(as_tibble, .name_repair = \(...) col_names)

sources <- sources |>
  select(-rest) |>
  bind_cols(splits_df) |>
  mutate(across(everything(), str_trim))

# === NORMALISE DEPARTEMENT ZORG ==============================
# INTENT: Collapse "Vlaamse Gemeenschap > Departement Zorg" into a
# single top-level organisation so it is counted consistently as one
# provider across all analyses.
# Own addition: the department operates with a degree of independence
# despite its administrative parent, justifying promotion to top level.

sources <- sources |>
  mutate(
    .is_dep_zorg   = organisation == "Vlaamse Gemeenschap" &
                     coalesce(subdivision_1, "") == "Departement Zorg",
    organisation   = if_else(.is_dep_zorg, "Departement Zorg", organisation),
    subdivision_1  = if_else(.is_dep_zorg, subdivision_2, subdivision_1),
    subdivision_2  = if_else(.is_dep_zorg, NA_character_, subdivision_2)
  ) |>
  select(-.is_dep_zorg)

# === NORMALISE ORGANISATION NAMES ============================
# INTENT: Collapse known capitalisation variants into a single
# canonical form at source, so that all downstream grouping and
# filtering on `organisation` yields consistent results.
# Own addition: variants identified by inspecting unique values in
# the raw DataSource field.

sources <- sources |>
  mutate(
    organisation = case_when(
      str_to_lower(organisation) == "intermutualistisch agentschap" ~ "Intermutualistisch Agentschap",
      str_to_lower(organisation) == "pod maatschappelijke integratie" ~ "POD Maatschappelijke Integratie",
      str_to_lower(organisation) == "fod volksgezondheid" ~ "FOD Volksgezondheid",
      str_to_lower(organisation) == "Agentschap Zorg en Gezondheid" ~ "Departement Zorg",
      str_to_lower(organisation) == "Centrum voor Kankeropsporing vzw" ~ "Centrum voor Kankeropsporing",
      str_to_lower(organisation) == "fod_financien" ~ "FOD Financi�n" ,

            .default = organisation
    )
  )

# === JOIN SOURCES TO INDICATOR DATA ==========================
# INTENT: Attach organisation metadata to every indicator row so
# downstream scripts can filter by provider.

df_final <- stads_data |>
  left_join(sources, by = "DataSource")

# === FILTER HEALTH INDICATORS ================================
# INTENT: Isolate the subset of indicators provided by organisations
# relevant to public health and social welfare of older adults.
# Own addition: the list of 14 organisations was agreed in consultation
# with the Health department of Stad Antwerpen and Stad in Cijfers
# (README.md, STAP 3; Katrien De Troeyer, June 2026).

health_organisations <- c(
  "Statbel",
  "Stadsmonitor",
  "Stad Antwerpen",
  "OCMW",
  "Statistiek Vlaanderen",
  "Directie-generaal Personen met een handicap & Vlaamse Sociale Bescherming",
  "Departement Zorg",
  "Intermutualistisch Agentschap",
  "Antwerpse Gezondheidsenquete",     # raw data has no accent ê
  "Stichting Kankerregister",
  "FOD Volksgezondheid",
  "Stad in Cijfers",
  "Vlaamse Sociale Bescherming",
  "POD Maatschappelijke Integratie", 
  "Expertisecentrum Dementie Vlaanderen"
)

# Own addition: case-insensitive match guards against future capitalisation
# drift in the raw DataSource field without requiring duplicate list entries.
df_health <- df_final |>
  filter(str_to_lower(organisation) %in% str_to_lower(health_organisations))

# Split into one data frame per organisation for exploratory use
for (org in unique(df_health$organisation)) {
  obj_name <- paste0("df_", tolower(gsub("[^a-zA-Z0-9]", "_", org)))
  assign(obj_name, df_health |> filter(organisation == org))
}

# <<<<<<< HEAD
Organisaties = unique(sources$Organisatie)
# 
# writexl::write_xlsx(df_vlaamse_sociale_bescherming, 'df_vlaamse_sociale_bescherming.xlsx')



# =======
organisations <- unique(sources$organisation)
# >>>>>>> 71e124ed7a6928f9f233d80d4bc90b484403096f

# === EXPORT ==================================================
# INTENT: Persist parsed source metadata and health subset for
# inspection outside R and for use in downstream reporting tools.

dir.create(here::here("output"), showWarnings = FALSE)

# Columns — output/sources_parsed.csv (one row per unique DataSource value):
#   DataSource           — raw string as it appears in the input file; primary key
#   provinces_in_figures — factor "yes"/"no"; "yes" if sourced via provincies.incijfers.be
#   topic                — substring after the first " - " or " – "; NA if absent
#   organisation         — top-level provider name; NA for blank DataSource rows
#   subdivision_1        — first sub-level of organisation hierarchy; NA if absent
#   subdivision_2        — second sub-level; NA if absent
#   subdivision_3        — third sub-level; NA if absent (only 3 sources reach this depth)
write.csv(sources, here::here("output", "sources_parsed.csv"), row.names = FALSE)

# Columns — output/df_health.csv (one row per indicator, health organisations only):
#   [all original columns from VarDataReport_niet_beveiligd.csv, plus:]
#   provinces_in_figures — see sources_parsed.csv
#   topic                — see sources_parsed.csv
#   organisation         — canonical provider name after normalisation
#   subdivision_1/2/3    — provider sub-levels; NA if absent
write.csv(df_health, here::here("output", "df_health.csv"), row.names = FALSE)

# ============================================================

message(
  "Stads_data.R complete.\n",
  "  Total indicator rows:              ", nrow(stads_data), "\n",
  "  Unique data sources parsed:        ", nrow(sources), "\n",
  "  Unique organisations:              ", length(organisations), "\n",
  "  Health-relevant rows:              ", nrow(df_health), "\n",
  "  Organisations in health subset:    ", length(unique(df_health$organisation)), "\n",
  "  Exported: output/sources_parsed.csv, output/df_health.csv"
)
