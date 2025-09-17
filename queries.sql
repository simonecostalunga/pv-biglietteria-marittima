/* ======================================================================
   Project Work — Biglietteria marittima
   File: queries/queries.sql
   Scopo: cinque interrogazioni rappresentative della traccia.
   Uso: eseguire gli ESEMPI (coerenti con i dati demo) o duplicare le
        query sostituendo i valori letterali.
   Ultimo aggiornamento: 2025-09-15
   ====================================================================== */

-- Q1) Ricerca corse tra due porti in intervallo temporale (GENO→OLBI)
SELECT c.id_corsa, p1.nome AS porto_partenza, p2.nome AS porto_arrivo,
       c.partenza_ts, c.arrivo_ts
FROM public.corsa c
JOIN public.porto p1 ON p1.id_porto = c.id_porto_partenza
JOIN public.porto p2 ON p2.id_porto = c.id_porto_arrivo
WHERE p1.codice = 'GENO'
  AND p2.codice = 'OLBI'
  AND c.partenza_ts BETWEEN '2025-09-01 00:00' AND '2025-09-03 00:00'
ORDER BY c.partenza_ts;
-- Atteso (demo): 1 riga (id_corsa = 1).

-- Q2) Storico prenotazioni di un cliente (per email)
SELECT p.id_prenotazione, p.stato, p.created_at
FROM public.prenotazione p
JOIN public.pren_pax pp ON pp.id_prenotazione = p.id_prenotazione
JOIN public.passeggero x ON x.id_passeggero = pp.id_passeggero
WHERE x.email = 'giulia.rossi@example.com'
ORDER BY p.created_at DESC;
-- Atteso (demo): 1 riga (id_prenotazione = 1).

-- Q3) Verifica stato imbarco via codice QR
SELECT b.id_biglietto, b.stato,
       CASE WHEN MAX(v.evento_il) IS NULL THEN 'NON IMBARCATO'
            ELSE 'IMBARCATO' END AS stato_imbarco
FROM public.biglietto b
LEFT JOIN public.validazione v ON v.id_biglietto = b.id_biglietto
WHERE b.codice_qr = 'QR-MARE-0001'
GROUP BY b.id_biglietto, b.stato;
-- Atteso (demo): 'IMBARCATO' per QR-MARE-0001; 'NON IMBARCATO' per QR-MARE-0002.

-- Q4) Segmenti (scali) e sistemazioni di una prenotazione (1 riga/segmento)
SELECT seg.ordine_segmento,
       pi.nome AS porto_imbarco, ps.nome AS porto_sbarco,
       t.codice AS tariffa, ap.id_posto, po.sezione, po.numero
FROM public.segmento seg
JOIN public.itinerario it  ON it.id_itinerario = seg.id_itinerario
JOIN public.prenotazione p ON p.id_prenotazione = it.id_prenotazione
JOIN public.porto pi ON pi.id_porto = seg.porto_imbarco
JOIN public.porto ps ON ps.id_porto = seg.porto_sbarco
JOIN public.biglietto b    ON b.id_prenotazione = p.id_prenotazione
JOIN public.tariffa t      ON t.id_tariffa = b.id_tariffa
JOIN public.assegnazione_posto ap ON ap.id_biglietto = b.id_biglietto
JOIN public.posto po ON po.id_posto = ap.id_posto AND po.id_corsa = seg.id_corsa
WHERE p.id_prenotazione = 1
ORDER BY seg.ordine_segmento;
-- Atteso (demo): 2 righe (CABINA 401 su segmento 1; SALONE 05A su segmento 2).

-- Q5) Disponibilità posti/cabine su una corsa
SELECT c.id_corsa,
       COUNT(po.id_posto)                      AS posti_totali,
       COUNT(ap.id_posto)                      AS posti_occupati,
       COUNT(po.id_posto) - COUNT(ap.id_posto) AS posti_disponibili
FROM public.corsa c
JOIN public.posto po ON po.id_corsa = c.id_corsa
LEFT JOIN public.assegnazione_posto ap ON ap.id_posto = po.id_posto
WHERE c.id_corsa = 1
GROUP BY c.id_corsa;
-- Atteso (demo corsa=1): tot=3, occ=1, disp=2.
