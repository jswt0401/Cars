# Cars — History Log
**Dato:** 22-04-2026

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
- `DimCarmodelTbl` har kun 20 rækker (Tesla-modeller + få andre) — mange biler i factbiler matcher ikke
- Kolonnenavnet `Mærke` i factbiler har encoding-fejl (Windows-1252 vs UTF-8) — værdier er uberørte da alle bilmærker er ASCII
