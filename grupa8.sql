/*Prikazati države (IDD, NAZIVD), sortirane u rastućem redosledu
naziva države*/ 

SELECT idd, nazivd 
FROM drzava 
ORDER BY nazivd;

/*Prikazati sve vozače (IDV, IMEV, PREZV) koji u imenu malo slovo
‘n’ ili veliko slovo ‘L’.*/

SELECT idv, imev, prezv 
FROM vozac 
WHERE imev LIKE '%n%' OR prezv LIKE '%L%';

/*U tabelu Staza, dodati kolone GEO_SIRINA i GEO_DUZINA koje
predstavljaju decimalnu predstavu geografke širine i dužine na kojima se staza
nalazi. Kao podrazumevanu vrednost kolona postaviti nedostajuću vrednost
NULL*/

ALTER TABLE staza
ADD (
    geo_sirina DECIMAL(10, 2) DEFAULT NULL,
    geo_duzina DECIMAL(10, 2) DEFAULT NULL
);

/*Prikazati staze (idenfikacionu oznaku staze, naziv staze i naziv države u
kojoj se staza nalazi) na kojima je barem jedan vozač 2019. godine ostvario
broj poena manji od prosečnog broja poena za sve vožnje iz 2019. godine.
Ukoliko su na nekoj stazi dva ili više vozača ostvarila takav broj bodova, stazu
prikazati samo jednom.*/

SELECT DISTINCT ids, nazivs, nazivd
FROM staza, drzava, rezultat
WHERE ids = stazar AND drzs = idd AND 
    sezona = 2019 AND bodovi < (SELECT AVG(bodovi) 
                                FROM rezultat
                                WHERE sezona = 2019);

/*Prikazati sve staze (idenfikaciona oznaka staze, naziv staze i naziv
države u kojoj se staza nalazi) na kojim je barem jednom pobedio domaći
vozač (vozač koji nastupa za istu državu u kojoj se staza nalazi). Ukoliko je na
nekoj stazi više sezona pobedio domaći vozač, stazu prikazati samo jednom.*/

SELECT DISTINCT ids, nazivs, nazivd
FROM staza, drzava, vozac, rezultat
WHERE ids = stazar AND drzs = idd AND idv = vozacr AND
    drzv = idd AND plasman = 1;

/*Prikazati sve staze na kojima je nastupao barem jedan vozač koji
nastupa za državu sa nazivom Germany, a nije nastupao ni jedan vozač koji
nastupa za državu sa nazivom Finland. */

SELECT ids, nazivs
FROM staza, vozac, rezultat
WHERE ids = stazar AND idv = vozacr AND 
    idv IN (SELECT idv FROM vozac, drzava 
            WHERE drzv = idd AND nazivd = 'Germany') AND
    idv NOT IN (SELECT idv FROM vozac, drzava
                WHERE drzv = idd AND nazivd = 'Findland');

/*Za svaku stazu (IDS, NAZIVS) prikazati broj različitih pobednika.
Prikazati samo one staze na kojima su pobeđivala najviše dva različita
vozača. Za staze za koje nisu uneseni rezultati prikazati 0.*/

SELECT DISTINCT ids, nazivs, COUNT(DISTINCT idv) AS "broj pobjednika"
FROM staza
LEFT OUTER JOIN rezultat 
ON ids = stazar
LEFT OUTER JOIN vozac
ON vozacr = idv
WHERE plasman = 1
GROUP BY ids, nazivs
HAVING COUNT(DISTINCT ids) < 3
UNION 
SELECT ids, nazivs, 0 AS "broj pobjednika"
FROM staza
WHERE ids NOT IN (SELECT stazar FROM rezultat);

/* Promeniti naziv staze tako da svako slovo u nazivu bude veliko, osim
poslednjeg slova.*/

UPDATE staza 
SET nazivs = UPPER(SUBSTR(nazivs, 1, LENGTH(nazivs) - 1)) || SUBSTR(nazivs, LENGTH(nazivs), LENGTH(nazivs));

SELECT nazivs FROM staza;
rollback;

/* Kreirati pogled Pogled_Drzava_Nastupi koji za državu (IDD, NAZIVD)
prikazuje ukupan broj nastupa vozača države na trkama. Pogled treba da
prikazuje podatke samo za države u kojima postoji barem jedna staza. Ukoliko
za državu nije zabeležen nastup nijednog njenog vozača, prikazati da je
ukupan broj nastupa vozača za tu državu 0.*/

CREATE OR REPLACE VIEW 
pogled_drzava_nastupi(id_drzave, naziv_drzave, broj_nastupa_vozaca) AS
SELECT idd, nazivd, COUNT(vozacr)
FROM rezultat, vozac, drzava
WHERE vozacr = idv AND drzv = idd AND idd IN (SELECT drzs FROM staza)
GROUP BY idd, nazivd
UNION 
SELECT DISTINCT idd, nazivd, 0
FROM rezultat, vozac, staza, drzava
WHERE stazar = ids AND drzs = idd AND idd NOT IN (SELECT NVL(drzv, 0) FROM vozac);

SELECT * FROM pogled_drzava_nastupi;

/*Za svaku stazu prikazati idenfikacionu oznaku staze, naziv staze, dužinu
jednog kruga na stazi, jedinicu u kojoj je dužina iskazana i ukupan broj
različitih vozača koji je na njoj vozio. Za dužinu kruga staze je neophodno
uraditi konverziju na sledeći način: ukoliko je na stazi vozilo više od 4
različita vozača dužinu kruga staze je neophodno prebaciti u milje. Jedan
kilometar ima 0.62 milja. U svim ostalim slučajevima dužinu kruga staze je
neophodno prikazati u kilometrima. Kao jedinicu za staze gde je izvršena
konverzija prikazati „miles“, a ukoliko nije „km“. Ako za stazu nema
zabeleženih rezultata za ukupan broj vozača koji su nastupali na stazi prikazati
0.*/

WITH konvertovana_duzina AS (
SELECT stazar staza_id, duzkrug * 0.62 duzina_kruga, COUNT(vozacr) broj_vozaca, 'miles' jedinica  
FROM rezultat, staza
WHERE stazar = ids 
GROUP BY stazar, duzkrug
HAVING COUNT(vozacr) > 4
UNION 
SELECT stazar staza_id, duzkrug duzina_kruga, COUNT(vozacr) broj_vozaca, 'km' jedinica
FROM rezultat, staza
WHERE stazar = ids 
GROUP BY stazar, duzkrug
HAVING COUNT(vozacr) <= 4
UNION 
SELECT ids staza_id, duzkrug duzina_kruga, 0 broj_vozaca , 'km' jedinica
FROM staza
WHERE ids NOT IN (SELECT stazar FROM rezultat)
GROUP BY ids, duzkrug
)
SELECT ids, nazivs, duzina_kruga, jedinica, broj_vozaca
FROM staza, konvertovana_duzina
WHERE ids = staza_id;

