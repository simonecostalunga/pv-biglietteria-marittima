[README.md.txt](https://github.com/user-attachments/files/22392241/README.md.txt)
# Project Work — Schema dati biglietteria marittima

**Obiettivo.** Progettare il modello di persistenza a supporto del processo di vendita biglietti per un operatore di trasporto marittimo (gestione tratte, scali, emissione, validazione).

## Struttura
- `ddl/schema.sql` — definizione tabelle, vincoli e indici (PostgreSQL 14+).
- `dml/sample_data.sql` — dati minimi coerenti con lo schema.
- `queries/queries.sql` — 5 query rappresentative con esempi ed esiti attesi.
- `docs/ER.mmd/ER.png` — diagramma ER in formato Mermaid (testuale) ed in formato png.
- `dump/pw_biglietteria_mare_dump.sql` — dump completo (schema + dati).

## Ripristino rapido (CLI)
```bash
createdb pw_biglietteria_mare
psql -d pw_biglietteria_mare -f dump/pw_biglietteria_mare_dump.sql
```
> In alternativa: eseguire `ddl/schema.sql` e poi `dml/sample_data.sql` da DBeaver.

## Note progettuali sintetiche
- **DBMS**: PostgreSQL per robustezza ACID, ricchezza SQL, tooling maturo.
- **Integrità**: vincoli PK/FK, CHECK temporale tra partenza e arrivo, univocità `posto` per corsa.
- **Normalizzazione**: schema in 3FN per ridurre ridondanze e anomalie.
- **Performance**: indici su ricerche tipiche (rotta+partenza_ts, sequenza segmenti, QR).
- **Scalabilità**: partizionamento temporale/rotta su `corsa` valutabile in evoluzione.

_Ultimo aggiornamento: 2025-09-15._
