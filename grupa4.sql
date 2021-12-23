/* Prikazati vozače (IDV, IMEV, PREZV), sortirane u opadajućem
redosledu prezimena vozača.*/

SELECT idv, imev, prezv 
FROM vozac 
ORDER BY prezv DESC;

/* Prikazati sve vozače (IDV, IMEV, PREZV) koji u svom imenu imaju
slovo L. */

SELECT idv, imev, prezv
FROM vozac
WHERE UPPER(imev) LIKE '%L%';

/* U tabelu Drzava, dodati kolonu GLGRAD koja predstavlja glavni grad
države. Za kolonu GLGRAD važi da su njene moguće vrednosti nizovi
karaktera maksimalne dužine 30. Kao podrazumevanu vrednost kolone
postaviti nedostajuću vrednost NULL. */

ALTER TABLE drzava 
ADD glgrad VARCHAR2(30) DEFAULT NULL;

/* Prikazati vozače (ime, prezime) koji su na nekoj od uspešno završenih
vožnji imali veću maksimalnu brzinu od prosečne maksimalne brzine svih
uspešno završenih vožnji. Ako je vozač više puta ostvario maksimalnu brzinu
veću od prosečne maksimalne brzine za završene vožnje, prikazati ga samo
jednom. Rezultat sortirati u rastućem redosledu imena vozača.*/

SELECT DISTINCT imev, prezv
FROM vozac v, rezultat r
WHERE v.idv = r.vozacr AND maksbrzina > (SELECT AVG(maksbrzina) FROM rezultat WHERE zavrsio = 'Y')
ORDER BY imev;

/* Prikazati vozače (ime, prezime i naziv države za koju nastupa vozač),
naziv staze, sezonu i naziv države u kojoj se staza nalazi za sve rezultate posle
sezone 2015. */

SELECT imev, prezv, d1.nazivd AS "drzava vozaca", nazivs, sezona, d2.nazivd AS "drzava staze"
FROM vozac v, drzava d1, staza s, drzava d2, rezultat r
WHERE v.drzv = d1.idd AND v.idv = r.vozacr AND 
    r.stazar = s.ids AND s.drzs = d2.idd AND r.sezona >= 2015;

/* Prikazati sve vozače koji su nastupali na stazi Hocnenheimring, a nisu
nastupali na stazi Monza */

SELECT DISTINCT idv, imev, prezv
FROM vozac v
WHERE v.idv IN (SELECT vozacr 
                FROM rezultat
                WHERE stazar = (SELECT ids FROM staza 
                                WHERE nazivs = 'Hocnenheimring'))
    AND v.idv NOT IN (SELECT vozacr 
                    FROM rezultat 
                    WHERE stazar = (SELECT ids FROM staza
                                    WHERE nazivs = 'Monza'));
                                    
/* Prikazati sve vozače (IDV, IMEV, PREZV) koji imaju zabeležene
rezultate iz najviše jedne različite sezone. Prikazati i vozače koji nemaju
zabeležen ni jedan rezultat.*/

SELECT idv, imev, prezv
FROM vozac v 
LEFT OUTER JOIN rezultat r
ON v.idv = r.vozacr 
GROUP BY idv, imev, prezv
HAVING COUNT(sezona) < 2;

/* Svakom vozaču promeniti ime tako da se na kraj imena doda prvo slovo
prezimena */

UPDATE vozac 
SET imev = CONCAT(imev, SUBSTR(prezv, 1, 1));
rollback;

/* Kreirati pogled Pogled_Vozac_Rezultat koji će za svakog vozača (IDV,
IMEV, PREZV) prikazati prosečnu maksimalnu brzinu. Pogled prikazuje
podatke samo za vozače koji imaju prosečnu maksimalnu brzinu manju od 350
km/h. Prosečnu maksimalnu brzinu zaokružiti na dva decimalna mesta. Ako
vozač nema nijedan zabeležen rezultat za vozača prikazati da je njegova
prosečna maksimalna brzina 0. */
    
CREATE OR REPLACE VIEW 
pogled_vozac_rezultat (id, ime, prezime, prosecna_maks_brzina) AS
SELECT idv, imev, prezv, NVL(ROUND(AVG(maksbrzina), 2), 0) 
FROM vozac v
LEFT OUTER JOIN rezultat r 
ON idv = vozacr
GROUP BY idv, imev, prezv
HAVING AVG(maksbrzina) < 350
ORDER BY idv;

SELECT * FROM pogled_vozac_rezultat;
DROP VIEW pogled_vozac_rezultat;

/* Za svaku različitu trku (staza i sezona u kojoj se vozilo na stazi) prikazati
prosečan osvojenih broj poena zaokružen na dve decimale. Rezultate sortirati u
opadajućem redosledu naziva staze. U upitu je neophodno izvršiti konverziju
bodova za sezonu 2019. Konverzija se vrši na način da se prvoplasiranim
dodeljuju još tri, drugoplasiranom dva, a trećeplasiranom jedan dodatni bod.
Za sve ostale rezultate se ne vrši konverzija. */

WITH konv AS (
SELECT stazar staza_id, vozacr vozac_id, 4 - NVL(plasman, 4) bonus_poeni 
FROM rezultat 
WHERE sezona = 2019
UNION
SELECT stazar staza_id, vozacr vozac_id, 0 bonus_poeni
FROM rezultat 
WHERE sezona != 2019
), konvertovani_poeni AS (
SELECT staza_id, r.sezona sezona_k, bodovi + k.bonus_poeni konvertovani
FROM rezultat r, konv k
WHERE r.vozacr = k.vozac_id AND r.stazar = k.staza_id
)
SELECT DISTINCT nazivs, stazar, sezona, ROUND(AVG(kp.konvertovani), 2) AS "prosjecan broj poena"
FROM rezultat r2, konvertovani_poeni kp, staza 
WHERE r2.stazar = kp.staza_id AND kp.sezona_k = sezona AND ids = r2.stazar
GROUP BY stazar, sezona, nazivs
ORDER BY nazivs DESC;

WITH konv AS (
SELECT stazar staza_id, vozacr vozac_id, 4 - NVL(plasman, 4) bonus_poeni 
FROM rezultat 
WHERE sezona = 2019
UNION
SELECT stazar staza_id, vozacr vozac_id, 0 bonus_poeni
FROM rezultat 
WHERE sezona != 2019
)
SELECT staza_id, vozacr, r.sezona sezona_k, bodovi + k.bonus_poeni konvertovani
FROM rezultat r, konv k
WHERE r.vozacr = k.vozac_id AND r.stazar = k.staza_id;

SELECT stazar, sezona, vozacr, bodovi 
FROM rezultat;