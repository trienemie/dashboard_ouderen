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
> totaal). Het effectieve aantal benoemde databronnen bedraagt dus **273**.

---

### STAP 2 — Herstructurering van de kolom *DataSource*

De kolom **`DataSource`** werd geautomatiseerd herwerkt om de informatie overzichtelijker
te structureren (`Stads_data.R`):

- Er werd een extra kolom toegevoegd die aangeeft of de gegevens afkomstig zijn van
  **Provincies in Cijfers** (`provinces_in_figures`: yes/no).
- De overige informatie werd opgesplitst in afzonderlijke velden:
  **data_owner**, **topic**, **subdivision\_1**, **subdivision\_2** en **subdivision\_3**.
- Data-eigenaars die onder verschillende benamingen of kapitalisaties voorkwamen, werden
  uniform gecodeerd (o.a. *Intermutualistisch Agentschap*, *POD Maatschappelijke
  Integratie*, *FOD Volksgezondheid*).

Na herstructurering zijn er **121 benoemde organisaties** (plus 1 categorie zonder
bronvermelding).


---

### STAP 3 — Selectie van gezondheidsgerelateerde organisaties

Op basis van de gestructureerde bronnenlijst werden, uit de 121 benoemde data-eigenaars,
de data-eigenaars geselecteerd die mogelijk gegevens aanleveren over de gezondheid en/of
het welzijn van ouderen. Bovendien werden enkel deze variabelen geselecteerd waarvan er gegevens beschikbaar zijn na 2024 (TE BESPREKEN MET DE STAD!!).Deze selectie gebeurde in nauw overleg met de dienst Gezondheid
van de Stad Antwerpen en met *Stad in Cijfers*.

De selectie omvat **10 data-eigenaars** en resulteert in een subset van **1.433 variabelen**. 
Daarnaast worden **4 data-eigenaars** ook verder geïnspecteerd omdat zij mogelijks ook gezondheids-gerelateerde informatie van ouderen bevatten. Hierbij werden variabelen geselecteerd die gegevens hebben na 2018 (TE BESPREKEN MET DE STAD!!). Hierbij gaat het over een subset van **3785 variabelen**.

---

### STAP 4 — Codering per variabele

Voor elke geselecteerde data-eigenaar werd een afzonderlijk tabblad aangemaakt. Per
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
