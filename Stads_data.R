library(stringr)
library(dplyr)

setwd("C:/Users/KaDeTroeyer/OneDrive - Universiteit Antwerpen/Stadsacademie")

stads_data = read.csv2( "VarDataReport_niet_beveiligd(VarDataReport).csv")

library(dplyr)
library(stringr)
library(tidyr)
library(purrr)

Sources = as.data.frame(unique(stads_data$DataSource)) %>%
  rename(DataSource = 'unique(stads_data$DataSource)') %>%
  mutate(
    # 1. Provincies in cijfers ja/nee
    provincies_in_cijfers = as.factor(if_else(
      str_detect(DataSource, "\\|\\s*provincies\\.incijfers\\.be"),
      "ja", "nee"
    )),
    rest = str_trim(str_remove(DataSource, "\\s*\\|\\s*provincies\\.incijfers\\.be")),
    
    # 2. Onderwerp: alles na eerste " - " of " – " (beide met spaties rondom)
    Onderwerp = str_trim(str_extract(rest, "(?<= [-–] ).*$")),
    rest = str_trim(str_remove(rest, "\\s+[-–]\\s+.*$")),
    # 3. Normaliseer " | " naar "," voor uniforme split
    rest = str_replace_all(rest, "\\s*\\|\\s*", ",")
  )

# Dynamisch splitsen: bepaal het maximale aantal subafdelingen
splits <- str_split(Sources$rest, "\\s*,\\s*")
max_parts <- max(map_int(splits, length))

# Kolomnamen aanmaken: Organisatie + Subafdeling1, Subafdeling2, ...
col_names <- c("Organisatie", paste0("Subafdeling", seq_len(max_parts - 1)))

# Splits uitvullen tot max_parts en als dataframe toevoegen
splits_df <- splits %>%
  map(~ `length<-`(.x, max_parts)) %>%  # NA-opvulling tot max lengte
  map(as.list) %>%
  map_dfr(as_tibble, .name_repair = ~ col_names)

# Samenvoegen met origineel dataframe
Sources <- Sources %>%
  select(-rest) %>%
  bind_cols(splits_df) %>%
  mutate(across(everything(), str_trim))

Sources <- Sources %>%
  mutate(
    .is_dep_zorg = Organisatie == "Vlaamse Gemeenschap" & coalesce(Subafdeling1, "") == "Departement Zorg",
    Organisatie  = if_else(.is_dep_zorg, "Departement Zorg", Organisatie),
    Subafdeling1 = if_else(.is_dep_zorg, Subafdeling2, Subafdeling1),
    Subafdeling2 = if_else(.is_dep_zorg, NA_character_, Subafdeling2)
  ) %>%
  select(-.is_dep_zorg)



# Opzoektabel: bronnen die hetzelfde zijn hetzelfde benoemen
# organisatie_mapping <- tribble(
#   ~Organisatie_raw,                  ~Organisatie_clean,
#   "Agentschap Zorg en Gezondheid",   "Departement Zorg",
#   "Departement Zorg",                "Departement Zorg",
#   "fod_financien",                   "FOD Financiën",
#   "FOD Financiën",                   "FOD Financiën",
#     "Centrum voor Kankeropsporing vzw", "Centrum voor Kankeropsporing",
#   "Centrum voor Kankeropsporing", "Centrum voor Kankeropsporing",
#   "Intermutualistisch Agentschap", 	"InterMutualistisch Agentschap",
#   "InterMutualistisch Agentschap", "InterMutualistisch Agentschap",
#   "Survey stadsmonitor", "Stadsmonitor",
#   "Stadsmonitor", "Stadsmonitor"
# )
# 
# Sources <- Sources %>%
#   left_join(organisatie_mapping, by = c("Organisatie" = "Organisatie_raw")) %>%
#   mutate(
#     Organisatie = if_else(!is.na(Organisatie_clean), Organisatie_clean, Organisatie)
#   ) %>%
#   select(-c(Organisatie_clean))
# 
# organisatie_hierarchie <- tibble::tribble(
#   ~Organisatie, ~Overheidsniveau,
#   "Instituut voor Natuur- en Bosonderzoek", "Vlaanderen",
#   "Kadaster en Rijksregister", "Federaal",
#   "FOD Financiën", "Federaal",
#   "Statbel", "Federaal",
#   "Kadaster", "Federaal",
#   "Vlaamse Milieumaatschappij", "Vlaanderen",
#   "Vlaamse Landmaatschappij", "Vlaanderen",
#   "Agentschap voor Natuur en Bos", "Vlaanderen",
#   "Stadsmonitor", "Stad Antwerpen",
#   "Stad Antwerpen", "Stad Antwerpen",
#   "Rijksregister", "Federaal",
#   "VDAB", "Vlaanderen",
#   "FOD Economie", "Federaal",
#   "OCMW", "Stad Antwerpen",
#   "VKBO", "Federaal",
#   "Centrum voor Kankeropsporing", "Vlaanderen",
#   "Kruispuntbank Sociale Zekerheid", "Federaal",
#   "Vlaamse Gemeenschap", "Vlaanderen",
#   "Vlaams Gewest", "Vlaanderen",
#   "", NA_character_,
#   "Rijksdienst voor Sociale Zekerheid", "Federaal",
#   "Statistiek Vlaanderen", "Vlaanderen",
#   "Steunpunt Werk", "Vlaanderen",
#   "RSZ en RSVZ", "Federaal",
#   "Rijksinstituut voor de Sociale Verzekeringen der Zelfstandigen", "Federaal",
#   "Nationale Bank van België", "Federaal",
#   "Federale Pensioendienst", "Federaal",
#   "CultuurNet Vlaanderen", "Vlaanderen",
#   "Vlaamse Nutsregulator", "Vlaanderen",
#   "Vlaams Energie- en Klimaatagentschap en Fluvius", "Vlaanderen",
#   "Eco-Movement via Departement Mobiliteit en Openbare Werken", "Vlaanderen",
#   "Directie-generaal Personen met een handicap & Vlaamse Sociale Bescherming", "Vlaanderen", # eerste deel is Federaal (FOD Sociale Zekerheid), tweede deel Vlaanderen - check zelf
#   "Vlaamse Sociale Bescherming", "Vlaanderen",
#   "Departement Zorg", "Vlaanderen",
#   "Datawarehouse arbeidsmarkt en sociale bescherming", "Federaal", # KSZ-initiatief
#   "FOD Sociale Zekerheid", "Federaal",
#   "ARCHIEF VDAB (NWWZ) en Rijksregister", "Vlaanderen",
#   "POD Maatschappelijke integratie", "Federaal",
#   "InterMutualistisch Agentschap", "Federaal",
#   "Vlaams Energie- en Klimaatagentschap", "Vlaanderen",
#   "Agentschap Wonen in Vlaanderen", "Vlaanderen",
#   "Opgroeien", "Vlaanderen",
#   "Onderwijs Vlaanderen", "Vlaanderen",
#   "Balanscentrale Nationale Bank", "Federaal",
#   "ARCHIEF VDAB en RVA", "Vlaanderen", # RVA is federaal, VDAB Vlaams - check
#   "Locatus", "Privaat/overig",
#   "Criminaliteitsstatistieken Federale Politie", "Federaal",
#   "Digitaal Vlaanderen", "Vlaanderen",
#   "ARCHIEF Watertoetskaart en Rijksregister", "Vlaanderen",
#   "Groenkaart Vlaanderen", "Vlaanderen",
#   "Federaal Agentschap voor de veiligheid van de voedselketen", "Federaal",
#   "Steunpunt Groene Zorg", "Vlaanderen",
#   "Agentschap Landbouw en Zeevisserij", "Vlaanderen",
#   "Vlaanderen", "Vlaanderen",
#   "Agentschap Landbouw en Zeevisserij o.b.v. Statbel", "Vlaanderen",
#   "UITDOVEND (28/4/2026) Onderwijs Vlaanderen", "Vlaanderen",
#   "De Lijn", "Vlaanderen",
#   "Departement Omgeving", "Vlaanderen",
#   "Fluvius en Vlaams Energie- en Klimaatagentschap", "Vlaanderen",
#   "Sodexo via Departement WSE", "Vlaanderen",
#   "ARCHIEF VDAB", "Vlaanderen",
#   "Agentschap Binnenlands Bestuur", "Vlaanderen",
#   "OPGELET: verouderde data", NA_character_,
#   "Antwerpen Studentenstad", "Stad Antwerpen",
#   "KAVA (Kon. Apothekersvereniging Antwerpen)", "Privaat/overig",
#   "Permamed", "Privaat/overig",
#   "Verbond der Vlaamse Tandartsen", "Privaat/overig",
#   "Rijksdienst voor Arbeidsvoorziening", "Federaal",
#   "Fluvius", "Vlaanderen", # intercommunale, valt onder Vlaams toezicht - check zelf
#   "Vlaams Woningfonds", "Vlaanderen",
#   "Provinciale toeristische organisaties", "Provincie",
#   "Openbare Vlaamse Afvalstoffenmaatschappij", "Vlaanderen",
#   "Meld Je Aan", "Stad Antwerpen",
#   "Studiedienst Vlaamse Regering", "Vlaanderen",
#   "Census 2011", "Federaal",
#   "kadaster_prijzenvastgoed", "Federaal",
#   "Databank Ondergrond Vlaanderen", "Vlaanderen",
#   "Monumentenwacht Vlaanderen vzw", "Vlaanderen",
#   "Visit Antwerpen", "Stad Antwerpen",
#   "VDAB en Rijksregister", "Vlaanderen",
#   "Toerisme Vlaanderen", "Vlaanderen",
#   "STR Global", "Privaat/overig",
#   "hotelrapport", "Privaat/overig",
#   "Antwerp Cruise Port/Visit Antwerpen", "Stad Antwerpen",
#   "Cropland mobile data", "Privaat/overig",
#   "zaalzoeker", "Stad Antwerpen",
#   "Vijf Vlaamse Provincies", "Provincie",
#   "Kind en Gezin", "Vlaanderen", # nu Opgroeien
#   "Futureproofed", "Privaat/overig",
#   "Antwerpse Gezondheidsenquete", "Stad Antwerpen",
#   "Stichting Kankerregister", "Federaal",
#   "FOD Volksgezondheid", "Federaal",
#   "POD Maatschappelijke Integratie", "Federaal",
#   "Departement WEWIS", "Vlaanderen",
#   "RIZIV", "Federaal",
#   "MIVB", "Federaal", # Brussels Gewest eigenlijk, niet Vlaams - check zelf
#   "Dierenwelzijn Vlaanderen", "Vlaanderen",
#   "RetailSonar", "Privaat/overig",
#   "ALZ en Dep. Omgeving", "Vlaanderen",
#   "Agentschap Onroerend Erfgoed", "Vlaanderen",
#   "Agentschap Natuur en Bos", "Vlaanderen",
#   "Federale Politie", "Federaal",
#   "Open Street Maps", "Privaat/overig",
#   "Agentschap Wonen in Vlaanderen en Vlaams Energie- en Klimaatagentschap", "Vlaanderen",
#   "Expertisecentrum Dementie Vlaanderen", "Vlaanderen",
#   "mvg_onderwijs", "Vlaanderen",
#   "brandweer Antwerpen", "Stad Antwerpen",
#   "Antwerpse Mobiliteitsenquête", "Stad Antwerpen",
#   "Lokale verkeerspolitie Antwerpen", "Stad Antwerpen",
#   "Waterlink", "Stad Antwerpen", # drinkwaterbedrijf regio Antwerpen
#   "Nationale Maatschappij der Belgische Spoorwegen", "Federaal",
#   "Aqualiner", "Privaat/overig",
#   "Autocars De Polder", "Privaat/overig",
#   "Agentschap Maritieme Dienstverlening en Kust", "Vlaanderen",
#   "The Retail Factory", "Privaat/overig",
#   "Emissie-inventaris", "Vlaanderen",
#   "Provincie Antwerpen", "Provincie",
#   "VITO", "Vlaanderen",
#   "Aquafin", "Vlaanderen",
#   "Stad in Cijfers", "Stad Antwerpen",
#   "mobiliteit_html", "Stad Antwerpen",
#   "Family proef", NA_character_
# )


df_final <- stads_data %>%
  left_join(Sources, by = "DataSource")


df_gezondheid = df_final %>%
  filter(Organisatie %in% c("Statbel","Stadsmonitor", "Stad Antwerpen", "Stadsmonitor", "OCMW","Statistiek Vlaanderen",
                            "Directie-generaal Personen met een handicap & Vlaamse Sociale Bescherming", "Departement Zorg",
                            "InterMutualistisch Agentschap", "Antwerpse Gezondheidsenquête", "Stichting Kankerregister",
                            "FOD Volksgezondheid", "Stad in Cijfers", "Vlaamse Sociale Bescherming", "POD Maatschappelijke integratie", "FOD volksgezondheid"))

for (org in unique(df_gezondheid$Organisatie)) {
  naam <- paste0("df_", tolower(gsub("[^a-zA-Z0-9]", "_", org)))
  assign(naam, df_gezondheid %>% filter(Organisatie == org))
}

Organisaties = unique(Sources$Organisatie)
# 
# writexl::write_xlsx(df_vlaamse_sociale_bescherming, 'df_vlaamse_sociale_bescherming.xlsx')




