# Gegevens *Stad in Cijfers*

## Exploratie voor dashboard ouderen

**Opgesteld door:** Katrien De Troeyer, epidemioloog, Universiteit Antwerpen  
**Datum:** juni 2026

---

### STAP 1 — Aanlevering ruwe data

Het bestand **`VarDataReport_niet_beveiligd.xlsx`** werd aangeleverd door Jerry Ruys van
*Stad in Cijfers*. Dit bestand bevat **24.440 unieke variabelen** (*Code*), afkomstig uit
**273 inhoudelijke databronnen** (*DataSource*).

> **Datakwaliteit — DataSource:**
> De kolom *DataSource* bevat 274 unieke waarden, maar één daarvan is een lege string
> (geen bronvermelding). Die lege waarde is gekoppeld aan 813 rijen (~3,3 % van het
> totaal); alle afgeleide velden (*organisation*, *topic*, *subdivision*) zijn voor
> deze rijen NA. Het effectieve aantal benoemde databronnen bedraagt dus **273**.

---

### STAP 2 — Herstructurering van de kolom *DataSource*

De kolom **`DataSource`** werd geautomatiseerd herwerkt om de informatie overzichtelijker
te structureren (`Stads_data.R`):

- Er werd een extra kolom toegevoegd die aangeeft of de gegevens afkomstig zijn van
  **Provincies in Cijfers** (`provinces_in_figures`: yes/no).
- De overige informatie werd opgesplitst in afzonderlijke velden:
  **organisation**, **topic**, **subdivision\_1**, **subdivision\_2** en **subdivision\_3**.
- Organisaties die onder verschillende benamingen of kapitalisaties voorkwamen, werden
  uniform gecodeerd (o.a. *Intermutualistisch Agentschap*, *POD Maatschappelijke
  Integratie*, *FOD Volksgezondheid*).

Na herstructurering zijn er **123 benoemde organisaties** (plus 1 categorie zonder
bronvermelding).

> **Noot:** de originele telling vermeldde 123 organisaties. Het verschil is te wijten
> aan de geautomatiseerde normalisatie van kapitalisatievarianten, waarbij dubbele
> vermeldingen werden samengevoegd.

---

### STAP 3 — Selectie van gezondheidsgerelateerde organisaties

Op basis van de gestructureerde bronnenlijst werden, uit de 123 benoemde organisaties,
de organisaties geselecteerd die mogelijk gegevens aanleveren over de gezondheid en/of
het welzijn van ouderen. Deze selectie gebeurde in nauw overleg met de dienst Gezondheid
van de Stad Antwerpen en met *Stad in Cijfers*.

De selectie omvat **15 organisaties** en resulteert in een subset van **8.933 variabelen**.

---

### STAP 4 — Codering per variabele

Voor elke geselecteerde organisatie werd een afzonderlijk tabblad aangemaakt. Per
variabele werd aangegeven of deze informatie bevat over ouderen:

- **Ja** (groen): de variabele bevat informatie over ouderen.
- **Nee** (rood): de variabele bevat geen informatie over ouderen.
- **Met extra informatie** (oranje): de variabele kan informatie over ouderen opleveren
  indien bijkomende gegevens beschikbaar worden gesteld, bijvoorbeeld een opsplitsing
  naar leeftijdscategorie.

---

### STAP 5 — Resultaat

Dit resulteerde in een overzichtstabel met alle variabelen waarover de stad beschikt
met betrekking tot ouderen. Op basis van deze tabel kan een selectie worden gemaakt
van de meest relevante indicatoren voor het dashboard.
