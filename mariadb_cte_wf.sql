
-- Les requêtes ci-dessous ont servi de base de travail pour la préparation
--  de l'article que j'ai publié dans GNU/Linux Magazine 211


-- Cumul des ventes par pays/ville/date

CREATE TABLE t_ventes (
  codpays VARCHAR(20),
  ville VARCHAR(20),
  mnt_vte DECIMAL(10,2),
  dat_vte DATE
);

INSERT INTO t_ventes
(codpays, ville, mnt_vte, dat_vte)
VALUES
('FR', 'Paris', 200, '2017-10-01'),
('FR', 'Paris', 800, '2017-09-01'),
('FR', 'Paris', 190, '2017-08-01'),
('FR', 'Paris', 230, '2017-10-03'),
('FR', 'Lyon', 200, '2017-10-05'),
('FR', 'Lyon', 390, '2017-09-05'),
('FR', 'Lyon', 720, '2017-08-05'),
('FR', 'Lyon', 110, '2017-10-05'),
('FR', 'Bordeaux', 160, '2017-08-03'),
('FR', 'Bordeaux', 500, '2017-10-05'),
('FR', 'Bordeaux', 330, '2017-09-05'),
('FR', 'Bordeaux', 120, '2017-08-05'),
('FR', 'Toulouse', 360, '2017-08-03'),
('FR', 'Toulouse', 600, '2017-10-05'),
('FR', 'Toulouse', 450, '2017-09-05'),
('FR', 'Toulouse', 720, '2017-08-05'),
('UK', 'Londres', 450, '2017-10-05'),
('UK', 'Londres', 530, '2017-09-05'),
('UK', 'Londres', 790, '2017-08-05'),
('UK', 'Londres', 330, '2017-07-05'),
('UK', 'Manchester', 200, '2017-08-01'),
('UK', 'Manchester', 330, '2017-07-01'),
('UK', 'Manchester', 120, '2017-10-03'),
('UK', 'Manchester', 640, '2017-09-03');



-- création d'une vue donnant le total des ventes par pays et ville
-- (permet de simplifier l'écriture des requêtes suivantes)
CREATE VIEW v_total_ventes AS
SELECT codpays, ville, sum(mnt_vte) AS tot_vte
FROM t_ventes 
GROUP BY codpays, ville;


-- La fonction RANK() classe les lignes en affectant à chacune un numéro d'ordre. Ce numéro est défini par l'addition du chiffre 1 au nombre de lignes distinctes précédant la 
-- ligne concernée dans le tri. S'il est impossible de déterminer l'ordre relatif de deux lignes ou plus contenant des valeurs de ligne identiques, le même numéro d'ordre leur est affecté. Dans ce cas, la numérotation du classement peut être discontinue. 


-- la colonne "rang" donne le classement des meilleures vente par ville
-- si deux villes ou plus ont le même total de ventes, alors elles ont 
-- le même "rang", elles sont donc à égalité dans le classement obtenu
SELECT ville, tot_vte,
   RANK() OVER (ORDER BY tot_vte DESC) AS rang
FROM v_total_ventes
ORDER BY rang;


-- la colonne "rank" fonctionne ici différemment, car elle est dépendante
-- de la clause PARTITION BY, qui appliquée à la colonne "codpays", 
-- déclenche une rupture sur cette colonne, on obtiendra donc un classement
-- distinct pour les ventes FR et UK
SELECT codpays, ville, tot_vte,
   RANK() OVER (PARTITION BY codpays ORDER BY tot_vte DESC) AS RANK
FROM v_total_ventes;


-- La fonction DENSE_RANK() classe les lignes en affectant à chacune un numéro d'ordre. Ce numéro est défini par l'addition du chiffre 1 au nombre total de lignes précédant la ligne concernée dans le classement. En conséquence, le classement sera séquentiel, sans discontinuités dans la numérotation. 

-- idem requête précédente, mais avec en plus la fonction DENSE_RANK()
SELECT codpays, ville, tot_vte,
   RANK() OVER (PARTITION BY codpays ORDER BY tot_vte DESC) AS RANK,
   DENSE_RANK() OVER (PARTITION BY codpays ORDER BY tot_vte DESC) AS DENSE_RANK
FROM v_total_ventes;



-- donne le top 3 des villes ayant eu les meilleurs ventes
WITH top_villes AS
(SELECT ville, tot_vte, RANK() OVER (ORDER BY tot_vte) AS RANK
FROM v_total_ventes)
SELECT * FROM top_villes
WHERE RANK <= 3;

-- le top des 4 meilleures ventes par pays 

WITH 
temp_ventes AS (
  SELECT codpays, ville, tot_vte,
  ROW_NUMBER() OVER (PARTITION BY codpays ORDER BY tot_vte DESC) AS RANK
  FROM v_total_ventes
),
temp_pays AS (
  SELECT DISTINCT codpays AS codpays FROM temp_ventes
)
SELECT A.codpays, B1.tot_vte AS tot_vte1, B2.tot_vte AS tot_vte2, 
       B3.tot_vte AS tot_vte3, B4.tot_vte AS tot_vte4

FROM temp_pays A
LEFT OUTER JOIN temp_ventes B1 ON A.codpays = B1.codpays AND B1.RANK = 1
LEFT OUTER JOIN temp_ventes B2 ON A.codpays = B2.codpays AND B2.RANK = 2
LEFT OUTER JOIN temp_ventes B3 ON A.codpays = B3.codpays AND B3.RANK = 3
LEFT OUTER JOIN temp_ventes B4 ON A.codpays = B4.codpays AND B4.RANK = 4
;



-- total des ventes par semaine 
WITH 
tmp_tot_ventes AS (
  SELECT codpays, ville, mnt_vte, dat_vte,  DATE_FORMAT(dat_vte, '%u') AS semaine
  FROM t_ventes
),
tmp_vte_sem AS (
  SELECT semaine, SUM(mnt_vte) AS tot_vte 
  FROM tmp_tot_ventes
  GROUP BY semaine
)
SELECT * FROM tmp_vte_sem



-- Ventes cumulées de l'année par numéro de semaine
-- générer des lignes à zéro pour les semaines pour lesquelles aucune vente n'a
-- été réalisée (au moyen d'une CTE récursive générant les 52 semaines)
WITH 
RECURSIVE tmp_gensem(nx) AS (
    SELECT 1 as n1
  UNION ALL
    SELECT nx+1 as n2 FROM tmp_gensem WHERE nx <= 52
),
tmp_tot_ventes AS (
  SELECT codpays, ville, mnt_vte, dat_vte,  DATE_FORMAT(dat_vte, '%u') AS semaine
  FROM t_ventes
),
tmp_vte_sem AS (
  SELECT semaine, SUM(mnt_vte) AS tot_vte 
  FROM tmp_tot_ventes
  GROUP BY semaine
)

SELECT A.nx AS sem, ifnull(B.tot_vte, 0) 
FROM tmp_gensem A
LEFT OUTER JOIN tmp_vte_sem B
  ON A.nx = B.semaine
ORDER BY A.nx


