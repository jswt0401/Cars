# Cars — History Log
**Senest opdateret:** 22-04-2026

---

## GitHub Setup
- Projekt pushed til https://github.com/jswt0401/Cars
- 42 filer committed (PBIP-format: rapport + semantisk model + temaer)
- `.gitignore` oprettet med PBI-, Windows- og credential-regler
- **Auto-push watcher** oprettet (`watch-and-push.ps1`)
  - Starter automatisk ved Windows login via `cars-watcher.vbs` i Startup-mappen
  - Gem i Power BI → GitHub opdateres automatisk inden for ~10 sekunder

---

## Power BI Model — Rettelser

### M-Query fix
- **Problem:** `factbiler` importerede al data i én `Column1` (semikolon-separator ignoreret)
- **Fix:** M-query opdateret til `Csv.Document` med `Delimiter=";"` → 20 kolonner korrekt indlæst

### Slettet
- Beregnet kolonne `Dækningsbidrag` på `factbiler` — brudt (referencerede ikke-eksisterende kolonner `Salgspris` og `Antal`)

### Measures rettet (5)
| Measure | Før | Efter |
|---|---|---|
| Total Omsaetning | `SUM(factbiler[Salgspris])` ❌ | `SUM(factbiler[Pris])` ✅ |
| Gns Salgspris | `AVERAGE(factbiler[Salgspris])` ❌ | `AVERAGE(factbiler[Pris])` ✅ |
| Total Daekningsbidrag | `SUM(factbiler[Dækningsbidrag])` ❌ | `SUM(factbiler[Nettopris])` ✅ |
| Antal Biler Solgt | `SUM(factbiler[Antal])` ❌ | `COUNTROWS(factbiler)` ✅ |
| Antal Salg | `COUNTROWS(factbiler)` ✅ | uændret |

### Relationer oprettet (3)
| Fra | Til | Type |
|---|---|---|
| `factbiler[Status]` | `DimLagerstatusTbl[LagerStatus]` | M:1 |
| `factbiler[DatoDateID]` | `DimDateTbl[DateID]` | M:1 |
| `factbiler[Model]` | `DimCarmodelTbl[Model]` | M:1 |

- Calculated column `DatoDateID` tilføjet til `factbiler` (konverterer "DD-MM" → 20250501-format)

---

## Kendte begrænsninger
- `DimCarmodelTbl` har kun 20 rækker (Tesla-modeller + få andre) — mange biler i Biler matcher ikke
- Kolonnenavnet `Mærke` i Biler har encoding-fejl (Windows-1252 vs UTF-8) — værdier er uberørte da alle bilmærker er ASCII

---

## Session 2 — 22-04-2026

### Dim-tabeller konverteret: DAX → M-kode

**Baggrund:** De 3 dim-tabeller var oprettet som DAX Calculated Tables. Dette er suboptimalt — DAX calculated tables kan ikke hente data udefra, understøtter ikke inkrementel refresh, og partition-typen kan ikke ændres via XMLA.

**Problem undervejs:** `partition_operations → Update` returnerede fejl: *"Det er ikke tilladt at ændre partitionstypen fra eller til PartitionType.Calculated"* — XMLA tillader ikke in-place konvertering.

**Løsning:** Slet tabellerne (cascade-slettede også relationer) → genopret med `table_operations → Create` med explicit kolonner + M-kode.

**Fejl ved genoprettelse:** Første forsøg med kun `mExpression` fejlede: *"Columns are required. The schema cannot be automatically inferred"* — explicit `columns`-array er påkrævet.

### Tabeller gendannet som M-kode

| Tabel | Type | Kolonner | Rækker |
|---|---|---|---|
| `DimDateTbl` | M-kode (Power Query) | Date, DateID, År, Måned, MånedNavn, Kvartal, UgeDag | 730 (2024–2025) |
| `DimLagerstatusTbl` | M-kode (Power Query) | LagerStatus, StatusBeskrivelse | 5 |
| `DimCarmodelTbl` | M-kode (Power Query) | Model, Mærke, Karosseri, Drivlinje | 20 |

### Relationer gendannet (3)

| Fra | Til | Type |
|---|---|---|
| `Biler[Status]` | `DimLagerstatusTbl[LagerStatus]` | M:1 |
| `Biler[DatoDateID]` | `DimDateTbl[DateID]` | M:1 |
| `Biler[Model]` | `DimCarmodelTbl[Model]` | M:1 |

### Tabellen omdøbt (af bruger)
- `factbiler` → `Biler` (omdøbt direkte i Power BI Desktop — measures auto-opdateret)

---

## Kendte begrænsninger (opdateret)
- `DimCarmodelTbl` dækker kun EV-modeller — mange biler i `Biler` matcher ikke på Model-kolonnen
- `Biler[Mærke]` har encoding-fejl (kolonnens *navn* er "MÃ¦rke" internt) pga. Windows-1252 vs UTF-8 ved CSV-import — selve værdier er korrekte (ASCII)
- Auto-push watcher (`watch-and-push.ps1`) kræver at PowerShell-processen kører — tjek at den er aktiv efter Windows-genstart
