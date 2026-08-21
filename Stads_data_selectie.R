
wb2 <- loadWorkbook("indicatoren_selectie2.xlsx")

# Alle tabbladnamen ophalen
alle_bladen <- names(wb2)

# Uitsluiten van de gewenste tabbladen
uit_te_sluiten <- c("Overzichtstabel", "Bronnen", "Ruwe data", "Afkortingen")
te_lezen_bladen <- setdiff(alle_bladen, uit_te_sluiten)

# Elk tabblad inlezen en samenvoegen, met een DataSource-kolom
dataset <- map_dfr(te_lezen_bladen, function(blad) {
  df <- read.xlsx(wb, sheet = blad)
  df <- df %>% mutate(across(everything(), as.character))
  df$DataSource <- blad
  df
})
