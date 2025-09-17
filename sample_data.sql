/* ======================================================================
   Project Work — Biglietteria marittima
   File: dml/sample_data.sql
   Scopo: popolamento minimo per test funzionali (dati dimostrativi).
   Ultimo aggiornamento: 2025-09-15
   ====================================================================== */

-- Porti
INSERT INTO public.porto (codice, nome, citta, lat, lon) VALUES
('GENO','Genova','Genova',44.404,8.933),
('OLBI','Olbia','Olbia',40.923,9.498),
('CIVI','Civitavecchia','Civitavecchia',42.093,11.792);

-- Navi
INSERT INTO public.nave (operatore, tipo, codice_nave) VALUES
('MareItalia','Traghetto','MI-TIRRENO'),
('MareItalia','Traghetto','MI-SARDEGNA');

-- Corse
INSERT INTO public.corsa (id_nave, id_porto_partenza, id_porto_arrivo, partenza_ts, arrivo_ts) VALUES
(1,1,2,'2025-09-01 21:00','2025-09-02 06:00'),   -- GENO→OLBI
(2,2,3,'2025-09-02 09:00','2025-09-02 13:00');   -- OLBI→CIVI

-- Posti/cabine
INSERT INTO public.posto (id_corsa, sezione, numero, classe) VALUES
(1,'CABINA','401','DELUXE'),
(1,'SALONE','12C','ECONOMY'),
(1,'SALONE','12D','ECONOMY'),
(2,'SALONE','05A','ECONOMY'),
(2,'CABINA','210','STANDARD');

-- Tariffe
INSERT INTO public.tariffa (codice, descrizione, regole_cambio, regole_rimborso) VALUES
('FLEX','Tariffa flessibile','Cambio gratuito fino a 2h prima','Rimborso 80% fino a 2h prima'),
('ECON','Tariffa economy','Cambio con penale 10€','Nessun rimborso dopo partenza');

-- Prenotazione demo
INSERT INTO public.prenotazione (stato, canale) VALUES ('PAGATA','WEB');

-- Passeggeri
INSERT INTO public.passeggero (nome, cognome, documento, email) VALUES
('Giulia','Rossi','ID123','giulia.rossi@example.com'),
('Luca','Bianchi','ID456','luca.bianchi@example.com');

-- Legame prenotazione-passeggeri
INSERT INTO public.pren_pax (id_prenotazione, id_passeggero, ruolo) VALUES
(1,1,'TITOLARE'),
(1,2,'ACCOMPAGNATO');

-- Itinerario con 2 segmenti (scalo a OLBI)
INSERT INTO public.itinerario (id_prenotazione) VALUES (1);
INSERT INTO public.segmento (id_itinerario, id_corsa, ordine_segmento, porto_imbarco, porto_sbarco, classe_servizio) VALUES
(1,1,1,1,2,'CABINA'),
(1,2,2,2,3,'SALONE');

-- Biglietti + assegnazioni posto
INSERT INTO public.biglietto (id_prenotazione, id_passeggero, id_tariffa, codice_qr, stato) VALUES
(1,1,1,'QR-MARE-0001','EMESSO'),
(1,2,2,'QR-MARE-0002','EMESSO');

INSERT INTO public.assegnazione_posto (id_biglietto, id_posto) VALUES
(1,1),   -- CABINA 401 su corsa 1
(2,4);   -- SALONE 05A su corsa 2

-- Pagamento e validazione
INSERT INTO public.pagamento (id_prenotazione, metodo, importo, esito, autorizzazione) VALUES
(1,'VISA',159.90,'OK','AUTHSEA1');

INSERT INTO public.validazione (id_biglietto, id_corsa, evento_il, esito, terminale) VALUES
(1,1,'2025-09-01 20:30','OK','GATE-GENOVA-01');
