/* ======================================================================
   Project Work — Biglietteria marittima
   File: ddl/schema.sql
   DBMS: PostgreSQL 14+
   Scopo: schema logico-relazionale a supporto di prenotazione, emissione
          e validazione dei biglietti per servizi marittimi (con scali).
   Convenzioni:
   - snake_case; PK come id_<entità>; FK omonime della PK referenziata.
   - Vincoli di integrità su chiavi, coerenza temporale e univocità risorse.
   Normalizzazione: fino a 3FN; denormalizzazioni non applicate.
   Performance: indici sulle chiavi di ricerca tipiche.
   Ultimo aggiornamento: 2025-09-15
   ====================================================================== */

-- =========================
-- Entità di dominio
-- =========================
CREATE TABLE public.porto (
  id_porto  SERIAL PRIMARY KEY,                  -- Identificativo porto
  codice    VARCHAR(10) UNIQUE NOT NULL,         -- Sigla (es. GENO, OLBI)
  nome      VARCHAR(100) NOT NULL,
  citta     VARCHAR(100) NOT NULL,
  lat       NUMERIC(9,6),
  lon       NUMERIC(9,6)
);

CREATE TABLE public.nave (
  id_nave     SERIAL PRIMARY KEY,
  operatore   VARCHAR(60) NOT NULL,              -- Compagnia/armatore
  tipo        VARCHAR(40) NOT NULL,              -- Traghetto/Aliscafo/...
  codice_nave VARCHAR(20) UNIQUE NOT NULL
);

-- =========================
-- Offerta di trasporto
-- =========================
CREATE TABLE public.corsa (
  id_corsa           BIGSERIAL PRIMARY KEY,
  id_nave            INTEGER  NOT NULL REFERENCES public.nave(id_nave),
  id_porto_partenza  INTEGER  NOT NULL REFERENCES public.porto(id_porto),
  id_porto_arrivo    INTEGER  NOT NULL REFERENCES public.porto(id_porto),
  partenza_ts        TIMESTAMP NOT NULL,         -- Orario partenza previsto
  arrivo_ts          TIMESTAMP NOT NULL,         -- Orario arrivo previsto
  CHECK (arrivo_ts > partenza_ts)                -- Coerenza temporale
);

-- =========================
-- Ciclo di vendita
-- =========================
CREATE TABLE public.prenotazione (
  id_prenotazione BIGSERIAL PRIMARY KEY,
  stato           VARCHAR(20) NOT NULL CHECK (stato IN ('CREATA','PAGATA','ANNULLATA')),
  canale          VARCHAR(20) NOT NULL,          -- WEB/APP/AGENZIA/SPORTELLO
  created_at      TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE public.passeggero (
  id_passeggero BIGSERIAL PRIMARY KEY,
  nome          VARCHAR(80)  NOT NULL,
  cognome       VARCHAR(80)  NOT NULL,
  documento     VARCHAR(40),
  email         VARCHAR(120)
);

-- Relazione N:M tra prenotazioni e passeggeri
CREATE TABLE public.pren_pax (
  id_prenotazione BIGINT NOT NULL REFERENCES public.prenotazione(id_prenotazione) ON DELETE CASCADE,
  id_passeggero   BIGINT NOT NULL REFERENCES public.passeggero(id_passeggero)     ON DELETE RESTRICT,
  ruolo           VARCHAR(20) NOT NULL DEFAULT 'TITOLARE', -- TITOLARE/ACCOMPAGNATO
  PRIMARY KEY (id_prenotazione, id_passeggero)
);

CREATE TABLE public.tariffa (
  id_tariffa     SERIAL PRIMARY KEY,
  codice         VARCHAR(20) UNIQUE NOT NULL,    -- Es. FLEX/ECON
  descrizione    VARCHAR(120) NOT NULL,
  regole_cambio  TEXT,
  regole_rimborso TEXT
);

CREATE TABLE public.biglietto (
  id_biglietto    BIGSERIAL PRIMARY KEY,
  id_prenotazione BIGINT   NOT NULL REFERENCES public.prenotazione(id_prenotazione) ON DELETE CASCADE,
  id_passeggero   BIGINT   NOT NULL REFERENCES public.passeggero(id_passeggero),
  id_tariffa      INTEGER  NOT NULL REFERENCES public.tariffa(id_tariffa),
  codice_qr       VARCHAR(64) UNIQUE NOT NULL,   -- Token/QR per validazione
  stato           VARCHAR(20) NOT NULL CHECK (stato IN ('EMESSO','IMBARCATO','RIMBORSATO','ANNULLATO')),
  emesso_il       TIMESTAMP NOT NULL DEFAULT now()
);

-- Itinerario e segmenti (scali)
CREATE TABLE public.itinerario (
  id_itinerario   BIGSERIAL PRIMARY KEY,
  id_prenotazione BIGINT NOT NULL UNIQUE REFERENCES public.prenotazione(id_prenotazione) ON DELETE CASCADE
);

CREATE TABLE public.segmento (
  id_segmento     BIGSERIAL PRIMARY KEY,
  id_itinerario   BIGINT   NOT NULL REFERENCES public.itinerario(id_itinerario) ON DELETE CASCADE,
  id_corsa        BIGINT   NOT NULL REFERENCES public.corsa(id_corsa),
  ordine_segmento SMALLINT NOT NULL,             -- Ordine nella sequenza (1..n)
  porto_imbarco   INTEGER  NOT NULL REFERENCES public.porto(id_porto),
  porto_sbarco    INTEGER  NOT NULL REFERENCES public.porto(id_porto),
  classe_servizio VARCHAR(20),
  UNIQUE(id_itinerario, ordine_segmento)
);

-- Disponibilità puntuale (sedute/cabine) per corsa
CREATE TABLE public.posto (
  id_posto BIGSERIAL PRIMARY KEY,
  id_corsa BIGINT NOT NULL REFERENCES public.corsa(id_corsa) ON DELETE CASCADE,
  sezione  VARCHAR(20) NOT NULL,                 -- CABINA/SALONE/PONTE
  numero   VARCHAR(20) NOT NULL,                 -- Es. 401, 12C, ...
  classe   VARCHAR(20) NOT NULL,                 -- ECONOMY/STANDARD/DELUXE
  UNIQUE(id_corsa, sezione, numero)
);

-- Assegnazione posto a biglietto (1:1 per corsa)
CREATE TABLE public.assegnazione_posto (
  id_biglietto BIGINT NOT NULL REFERENCES public.biglietto(id_biglietto) ON DELETE CASCADE,
  id_posto     BIGINT NOT NULL REFERENCES public.posto(id_posto)         ON DELETE CASCADE,
  PRIMARY KEY (id_biglietto, id_posto)
);
ALTER TABLE public.assegnazione_posto
  ADD CONSTRAINT uq_asseg_posto_unico UNIQUE (id_posto); -- Un posto assegnato al più una volta

-- Pagamenti
CREATE TABLE public.pagamento (
  id_pagamento    BIGSERIAL PRIMARY KEY,
  id_prenotazione BIGINT NOT NULL REFERENCES public.prenotazione(id_prenotazione) ON DELETE CASCADE,
  metodo          VARCHAR(20) NOT NULL,          -- VISA/PayPal/...
  importo         NUMERIC(10,2) NOT NULL,
  valuta          CHAR(3) NOT NULL DEFAULT 'EUR',
  esito           VARCHAR(20) NOT NULL,          -- OK/KO
  autorizzazione  VARCHAR(64),
  created_at      TIMESTAMP NOT NULL DEFAULT now()
);

-- Validazioni (imbarco) del biglietto su una specifica corsa
CREATE TABLE public.validazione (
  id_validazione BIGSERIAL PRIMARY KEY,
  id_biglietto   BIGINT NOT NULL REFERENCES public.biglietto(id_biglietto) ON DELETE CASCADE,
  id_corsa       BIGINT NOT NULL REFERENCES public.corsa(id_corsa),
  evento_il      TIMESTAMP NOT NULL,
  esito          VARCHAR(20) NOT NULL,           -- OK/KO
  terminale      VARCHAR(40)                     -- Identificativo lettore/gate
);

-- Cambi e rimborsi
CREATE TABLE public.cambio (
  id_cambio        BIGSERIAL PRIMARY KEY,
  id_biglietto_orig BIGINT NOT NULL REFERENCES public.biglietto(id_biglietto),
  id_biglietto_new  BIGINT REFERENCES public.biglietto(id_biglietto),
  motivo           VARCHAR(120),
  delta_importo    NUMERIC(10,2),
  ts               TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE public.rimborso (
  id_rimborso   BIGSERIAL PRIMARY KEY,
  id_biglietto  BIGINT NOT NULL REFERENCES public.biglietto(id_biglietto),
  motivo        VARCHAR(120),
  importo       NUMERIC(10,2) NOT NULL,
  stato         VARCHAR(20) NOT NULL,
  ts            TIMESTAMP NOT NULL DEFAULT now()
);

-- =========================
-- Indici di supporto
-- =========================
CREATE INDEX idx_corsa_partenza        ON public.corsa (partenza_ts);
CREATE INDEX idx_corsa_ricerca         ON public.corsa (id_porto_partenza, id_porto_arrivo, partenza_ts);
CREATE INDEX idx_segmento_it_ordine    ON public.segmento (id_itinerario, ordine_segmento);
CREATE INDEX idx_biglietto_qr          ON public.biglietto (codice_qr);
CREATE INDEX idx_validazione_biglietto ON public.validazione (id_biglietto, evento_il);
