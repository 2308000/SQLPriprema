/* Prikazati vozače (IDV, IMEV, PREZV), sortirane u rastućem redosledu
imena vozača. */

SELECT idv, imev, prezv 
FROM vozac
ORDER BY imev;

/* Prikazati sve vozače (IDV, IMEV, PREZV, GODRODJ) čija godina
rođenja je u opsegu [1970, 1985]. */

SELECT idv, imev, prezv, godrodj 
FROM vozac
WHERE godrodj BETWEEN 1970 AND 1985;

/* U tabelu Drzava, dodati kolonu BROJSTAN koja predstavlja broj
stanovnika države. Kao podrazumevanu vrednost kolone postaviti nedostajuću
vrednost NULL. */
ALTER TABLE drzava
ADD brojstan NUMBER;

SELECT * FROM drzava;
ALTER TABLE drzava
DROP COLUMN brojstan;

/* Prikazati staze (identifikacionu oznaku staze, naziv staze i naziv države u
kojoj se staza nalazi) na kojima je barem jedan vozač ostvario veću
maksimalnu brzinu od prosečne maksimalne brzine nezavršenih vožnji.
Ukoliko je na stazi bilo dve ili više ovakve vožnje, stazu prikazati samo
jednom. */

SELECT DISTINCT ids, nazivs, nazivd 
FROM staza, drzava, rezultat, vozac
WHERE drzs = idd AND vozacr = idv AND stazar = ids 
    AND maksbrzina > (SELECT AVG(maksbrzina) 
                        FROM rezultat 
                        WHERE zavrsio = 'N');
                        
/* Za svaki zabeleženi rezultat iz 2019. godine prikazati naziv staze, državu
u kojoj se nalazi staza, ime i prezime vozača, kao i državu za koju nastupa
vozač. */

SELECT nazivs, d1.nazivd AS "drzava staze", imev, prezv, d2.nazivd AS "drzava vozaca"
FROM staza, drzava d1, vozac, drzava d2, rezultat
WHERE drzs = d1.idd AND vozacr = idv AND ids = stazar 
    AND drzv = d2.idd AND sezona = 2019;

/* Prikazati sve staze na kojima je nastupao vozač sa prezimenom
Raikkonen, a nije nastupao vozač sa prezimenom Vettel. */

SELECT DISTINCT ids, nazivs
FROM staza, rezultat
WHERE ids = stazar AND 
    ids IN (SELECT stazar FROM rezultat, vozac 
            WHERE vozacr = idv AND prezv = 'Raikkonen') AND
    ids NOT IN (SELECT stazar FROM rezultat, vozac 
            WHERE vozacr = idv AND prezv = 'Vettel');  
            

/* Za svaku stazu(IDS, NAZIVS) prikazati prosečnu maksimalnu brzinu.
Prikazati samo one staze čija prosečna maksimalna brzina je manja od 350
km/h. Ako za stazu nema zabeleženih rezultata, za prosečnu maksimalnu
brzinu staze prikazati 0. */

SELECT ids, nazivs, ROUND(AVG(maksbrzina), 2) AS "prosecna_max_brzina"
FROM staza, rezultat
WHERE ids = stazar 
GROUP BY ids, nazivs
HAVING AVG(maksbrzina) < 350
UNION
SELECT ids, nazivs, 0 AS "prosecna_max_brzina"
FROM staza
WHERE ids NOT IN (SELECT stazar FROM rezultat);

/* Svakom vozaču postaviti zadnje slovo prezimena da bude veliko.  */

UPDATE vozac
SET prezv = SUBSTR(prezv, 1, LENGTH(prezv) - 1) || UPPER(SUBSTR(prezv, LENGTH(prezv), LENGTH(prezv)));

SELECT prezv FROM vozac;
rollback;

/* Kreirati pogled Pogled_Vozac_Pobede koji će za svakog vozača (IDV,
IMEV, PREZV) rođenog pre 1986. godine prikazati ukupan broj rezultata gde
se vozač plasirao na prvu poziciju. Ako nema nijedan zabeležen rezultat za
vozača prikazati da je njegov ukupan broj pobeda 0. */

CREATE OR REPLACE VIEW 
pogled_vozac_pobede (idv, imev, prezv, broj_pobeda) AS
SELECT idv, imev, prezv, COUNT(vozacr) 
FROM vozac, rezultat
WHERE plasman = 1 AND idv = vozacr AND godrodj < 1986
GROUP BY idv, imev, prezv
UNION 
SELECT idv, imev, prezv, 0
FROM vozac 
WHERE godrodj < 1986 AND idv NOT IN (SELECT vozacr FROM rezultat);

SELECT * FROM pogled_vozac_pobede;
DROP VIEW pogled_vozac_pobede;

/* Za svakog vozača prikazati njegovu najveću maksimalnu brzinu
zaokruženu na dva decimalna mesta i jedinicu u kojoj je izražena maksimalna
brzina koju je ostvario u toku karijere. Rezultate sortirati u opadajućem
redosledu imena vozača. Ako za vozača nisu zabeleženi rezultati u ispisu
prikazati da je njegova najveća maksimalna brzina 0, a kao jedinicu prikazati
znak crtica(-). U upitu je neophodno izvršiti konverziju maksimalne brzine na
način da se jedinica kilometara na sat prebaci milja na sat za vozače koji
dolaze iz Nemačke i Velike Britanije (1 km/h = 0.62 mp/h). Kao jedinicu za
vozače iz Nemačke i Velike Britanije prikazati mp/h, a za ostale vozače km/h. */

WITH konvertovane_maks_brzine AS 
(
SELECT r1.vozacr id_vozaca, ROUND(maksbrzina * 0.62, 2) max_v, 'mp/h' jedinica
FROM rezultat r1, vozac
WHERE vozacr = idv AND drzv IN (SELECT idd FROM drzava WHERE nazivd IN ('Germany', 'Great Britain')) AND 
    maksbrzina = (SELECT MAX(maksbrzina) 
                    FROM rezultat r2 
                    WHERE r1.vozacr = r2.vozacr
                    GROUP BY r2.vozacr)
UNION 
SELECT r1.vozacr id_vozaca, ROUND(maksbrzina, 2) max_v, 'km/h' jedinica
FROM rezultat r1, vozac
WHERE vozacr = idv AND drzv NOT IN (SELECT idd FROM drzava WHERE nazivd IN ('Germany', 'Great Britain')) AND 
    maksbrzina = (SELECT MAX(maksbrzina) 
                    FROM rezultat r2 
                    WHERE r1.vozacr = r2.vozacr
                    GROUP BY r2.vozacr)
UNION
SELECT idv id_vozaca, 0 max_v, '-' jedinica
FROM vozac
WHERE idv NOT IN (SELECT vozacr FROM rezultat)
)
SELECT imev, prezv, id_vozaca, max_v, jedinica
FROM vozac, konvertovane_maks_brzine
WHERE idv = id_vozaca
ORDER BY imev DESC;
