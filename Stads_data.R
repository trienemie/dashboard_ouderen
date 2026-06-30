# ============================================================
# Stads_data.R
# ============================================================
# Cross-script dependencies:
#   Produces: df_final     — full indicator table with organisation
#                            metadata; used by downstream analyses.
#             df_health    — health-relevant subset of df_final.
#             df_<org>     — one data frame per health organisation,
#                            for exploratory use.
# ============================================================

library(here)
library(dplyr)
library(stringr)
library(tidyr)
library(purrr)

# === LOAD RAW DATA ===========================================
# INTENT: Read the variable data report so all downstream sections
# work from a single, consistently loaded source.

stads_data <- read.csv(here::here("VarDataReport_niet_beveiligd.csv"))

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

# === JOIN SOURCES TO INDICATOR DATA ==========================
# INTENT: Attach organisation metadata to every indicator row so
# downstream scripts can filter by provider.

df_final <- stads_data |>
  left_join(sources, by = "DataSource")

# === FILTER HEALTH INDICATORS ================================
# INTENT: Isolate the subset of indicators provided by organisations
# relevant to public health and social welfare, as required by the
# older-adults dashboard.
# Own addition: the list of organisations reflects the thematic scope
# of the project as scoped in the project brief.

health_organisations <- c(
  "Statbel",
  "Stadsmonitor",
  "Stad Antwerpen",
  "OCMW",
  "Statistiek Vlaanderen",
  "Directie-generaal Personen met een handicap & Vlaamse Sociale Bescherming",
  "Departement Zorg",
  "InterMutualistisch Agentschap",
  "Antwerpse Gezondheidsenquête",
  "Stichting Kankerregister",
  "FOD Volksgezondheid",
  "FOD volksgezondheid",
  "Stad in Cijfers",
  "Vlaamse Sociale Bescherming",
  "POD Maatschappelijke integratie"
)

df_health <- df_final |>
  filter(organisation %in% health_organisations)

# Split into one data frame per organisation for exploratory use
for (org in unique(df_health$organisation)) {
  obj_name <- paste0("df_", tolower(gsub("[^a-zA-Z0-9]", "_", org)))
  assign(obj_name, df_health |> filter(organisation == org))
}

organisations <- unique(sources$organisation)

# ============================================================

message(
  "Stads_data.R complete.\n",
  "  Total indicator rows:              ", nrow(stads_data), "\n",
  "  Unique data sources parsed:        ", nrow(sources), "\n",
  "  Unique organisations:              ", length(organisations), "\n",
  "  Health-relevant rows:              ", nrow(df_health), "\n",
  "  Organisations in health subset:    ", length(unique(df_health$organisation))
)
