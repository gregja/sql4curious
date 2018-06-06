-- Exemple de génération d'un tableau d'amortissement généré intégralement 
--  en SQL (amortissement linéaire)


-- tableau d'amortissement d'immobilisation

WITH
tmp_valinitiales (capital, taux, annee_depart, nb_mois_an1, nb_annuites) AS (
 SELECT CAST(100000 AS DECIMAL(11, 0)), -- capital initial
   CAST((10+0.0) / 100 AS DECIMAL(5, 2)), -- taux d'amortissment
   CAST(2001 AS INTEGER), -- année de départ
   CAST(6 AS INTEGER), -- nbre mois pour calcul 1ère annuitée
   CAST(10 AS INTEGER) -- nombre d'années d'amortissement
),
-- Conversion de certaines valeurs initiales en format décimal et précalcul de certaines données
tmp_valdepart (capital, taux, annee_depart, nb_mois_an1, prorata, nb_annuites) AS (
 SELECT capital, taux, annee_depart, nb_mois_an1,
   CAST( CAST(nb_mois_an1 AS DEC(2, 0)) / 12.0 AS DEC(5, 4)) as prorata, -- prorata de la première annuité au format décimal
   CASE WHEN nb_mois_an1 = 12 THEN nb_annuites ELSE nb_annuites + 1 END AS nb_annuites -- nombre d'années d'amortissement de type entier
 FROM tmp_valinitiales
),
-- Génération des lignes du tableau
gen_lignes AS (
    SELECT cast(nx as integer) as val_inc FROM (
        WITH RECURSIVE gen_ids(nx) AS (
            SELECT 1 as n1 
            UNION ALL
            SELECT nx+1 as n2 FROM gen_ids WHERE nx < (SELECT nb_annuites FROM  tmp_valdepart)
        ) SELECT nx FROM gen_ids
    ) AS X
),
-- Calcul d'un premier tableau d'annuités théoriques
tmp_tableau1 as (
 SELECT val_inc, (SELECT taux FROM tmp_valdepart) AS taux,
   (SELECT capital FROM tmp_valdepart) AS capital_initial,
   CASE WHEN val_inc = 1 THEN
     -- la première année n'est pas forcément une année pleine, d'où application d'un prorata temporis sur la mensualité
     (SELECT capital FROM tmp_valdepart) * (SELECT taux FROM tmp_valdepart) * (SELECT prorata FROM tmp_valdepart)
   ELSE
     -- mensualité théorique pour une année pleine
     (SELECT capital FROM tmp_valdepart) * (SELECT taux FROM tmp_valdepart)
   END AS annuites  
 FROM gen_lignes
),
-- Second tableau théorique incluant le calcul du CRD
tmp_tableau2 AS (
 SELECT a.val_inc, a.capital_initial, a.annuites,
    a.capital_initial - (SELECT SUM(annuites) FROM tmp_tableau1 x WHERE x.val_inc <= a.val_inc) AS crd
 FROM tmp_tableau1 a
),
-- Rattrapage de la dernière annuité si CRD négatif sur la dernière année
tmp_tableau3 AS (
 SELECT a.val_inc + (SELECT annee_depart FROM tmp_valdepart) - 1 AS annee,
    CASE WHEN crd < 0 THEN
       a.annuites + crd
    ELSE
       a.annuites
    END AS annuite,
    CASE WHEN crd < 0 THEN
       0
    ELSE
       a.crd
    END AS vnc_fin_exercice
    FROM tmp_tableau2 a
)
SELECT annee, vnc_fin_exercice + annuite AS vnc_debut_exercice, annuite, vnc_fin_exercice
FROM tmp_tableau3
;

