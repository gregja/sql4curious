
--
-- Base de données exemple accompagnant l'article consacré 
-- à la manipulation en SQL de données soumises à date d'effet 
-- 
-- Créé par Grégory Jarrige le 25/10/2017
-- pour les éditions Diamond (publié dans GNU/Linux 213)
--

-- --------------------------------------------------------

--
-- Structure de la table gco_produit
--

CREATE TABLE gco_produit (
  id integer UNSIGNED NOT NULL AUTO_INCREMENT,
  code_produit char(30) NOT NULL DEFAULT '',
  PRIMARY KEY(id),
  UNIQUE KEY (code_produit)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
--
-- Données de la table gco_produit
--

INSERT INTO gco_produit 
(id, code_produit) 
VALUES
(80, 'BR 500'),
(81, 'BR 550'),
(82, 'BR 600'),
(83, 'BT 121 C'),
(31, 'BT 45'),
(27, 'BT 46'),
(121, 'FR 130 T');


-- --------------------------------------------------------

--
-- Structure de la table gco_prixvte
--

CREATE TABLE gco_prixvte (
  id integer UNSIGNED NOT NULL AUTO_INCREMENT,
  produit_id integer UNSIGNED NOT NULL,
  date_effet date NOT NULL,
  prix decimal(11,5) NOT NULL DEFAULT 0,
  PRIMARY KEY(id),
  UNIQUE KEY (produit_id, date_effet)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Données de la table gco_prixvte
--

INSERT INTO gco_prixvte 
(id, produit_id, date_effet, prix) 
VALUES
(1, 80, '2017-01-01', 459),
(2, 81, '2017-01-01', 500),
(3, 82, '2017-01-01', 584),
(4, 83, '2017-01-01', 1109),
(5, 31, '2017-01-01', 1325),
(6, 27, '2017-01-01', 1620),
(7, 121, '2017-01-01', 2390),
(8, 80, '2017-07-01', 481.95),
(9, 81, '2017-07-01', 525),
(10, 82, '2017-07-01', 613.20),
(11, 83, '2017-07-01', 1164.45),
(12, 31, '2017-07-01', 1391.25),
(15, 80, '2017-12-01', 491.589),
(16, 81, '2017-12-01', 535.500),
(17, 82, '2017-12-01', 625.464),
(18, 83, '2017-12-01', 1187.739),
(19, 31, '2017-12-01', 1419.075),
(20, 27, '2017-12-01', 1652.400),
(21, 121, '2017-12-01', 2437.80);

-- --------------------------------------------------------

--
-- Structure de la table gco_prixvte2
--

CREATE TABLE gco_prixvte2 (
  id integer UNSIGNED NOT NULL AUTO_INCREMENT,
  produit_id integer UNSIGNED NOT NULL,
  date_eff_deb date NOT NULL,
  date_eff_fin date NOT NULL,
  prix decimal(11,5) NOT NULL DEFAULT 0,
  PRIMARY KEY(id),
  UNIQUE KEY (produit_id, date_eff_deb, date_eff_fin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Données de la table gco_prixvte2
--

INSERT INTO gco_prixvte2 
(id, produit_id, date_eff_deb, date_eff_fin, prix) 
VALUES
(1, 80, '2017-01-01', '2017-12-31', 459),
(2, 81, '2017-01-01', '2017-12-31', 500),
(3, 82, '2017-01-01', '2017-12-31', 584),
(4, 83, '2017-01-01', '2017-12-31', 1109),
(5, 31, '2017-01-01', '2017-12-31', 1325),
(6, 27, '2017-01-01', '2017-12-31', 1620),
(7, 121, '2017-01-01', '2017-12-31', 2390),
(8, 80, '2017-07-01', '2017-12-31', 481.95),
(9, 81, '2017-07-01', '2017-12-31', 525),
(10, 82, '2017-07-01', '2017-12-31', 613.20),
(11, 83, '2017-07-01', '2017-12-31', 1164.45),
(12, 31, '2017-07-01', '2017-12-31', 1391.25),
(15, 80, '2017-12-01', '2017-12-31', 491.589),
(16, 81, '2017-12-01', '2017-12-31', 535.50),
(17, 82, '2017-12-01', '2017-12-31', 625.464),
(18, 83, '2017-12-01', '2017-12-31', 1187.739),
(19, 31, '2017-12-01', '2017-12-31', 1419.075),
(20, 27, '2017-12-01', '2017-12-31', 1652.40),
(21, 121, '2017-12-01', '2017-12-31', 2437.80),
(22, 80, '2017-12-01', '2017-12-15', 490);



-- augmentation de tarif
INSERT INTO gco_prixvte (produit_id, date_effet, prix)
SELECT pxvt.produit_id, '2017-12-01' as new_date, pxvt.prix * 1.02 as new_price
FROM gco_produit prod
INNER JOIN gco_prixvte pxvt
  ON prod.id = pxvt.produit_id
WHERE pxvt.date_effet = 
  (SELECT max(tmp.date_effet) FROM gco_prixvte tmp
  WHERE tmp.produit_id = prod.id 
  AND tmp.date_effet <= '2017-08-01')



-- affichage des prix applicables au 15 décembre :

SELECT prod.code_produit, pxvt.date_effet, pxvt.prix
FROM gco_produit prod
INNER JOIN gco_prixvte pxvt
  ON prod.id = pxvt.produit_id
WHERE pxvt.date_effet = ( SELECT max(tmp.date_effet) FROM gco_prixvte tmp
                          WHERE tmp.produit_id = prod.id 
                          AND tmp.date_effet <= '2017-12-15')
ORDER BY prod.code_produit, pxvt.date_effet


-- variante permettant d'obtenir le même résultat

SELECT prod.code_produit, pxvt.date_effet, pxvt.prix
FROM gco_produit prod
INNER JOIN gco_prixvte pxvt
   ON prod.id = pxvt.produit_id
WHERE pxvt.date_effet = 
    ( SELECT tmp.date_effet 
      FROM gco_prixvte tmp
      WHERE tmp.produit_id = prod.id 
      AND tmp.date_effet <= '2017-12-15'
      ORDER BY tmp.date_effet DESC
      LIMIT 1)
ORDER BY prod.code_produit, pxvt.date_effet



-- variante de table pour la gestion de chevauchement de dates

CREATE TABLE gco_prixvte2 (
  id integer UNSIGNED NOT NULL AUTO_INCREMENT,
  produit_id integer UNSIGNED NOT NULL,
  date_eff_deb date NOT NULL,
  date_eff_fin date NOT NULL,
  prix decimal(11,5) NOT NULL DEFAULT 0,
  PRIMARY KEY(id),
  UNIQUE KEY (produit_id, date_eff_deb, date_eff_fin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- affichage des prix dans le cas de chevauchements de dates

SELECT prod.code_produit, pxvt.date_eff_deb, pxvt.date_eff_fin, pxvt.prix
FROM gco_produit prod
INNER JOIN gco_prixvte2 pxvt
  ON prod.id = pxvt.produit_id
WHERE (pxvt.date_eff_deb, pxvt.date_eff_fin) = 
( SELECT tmp.date_eff_deb, tmp.date_eff_fin 
   FROM gco_prixvte2 tmp
   WHERE tmp.produit_id = prod.id 
   AND tmp.date_eff_deb <= '2017-12-16'
   AND tmp.date_eff_fin >= '2017-12-16'
   ORDER BY tmp.date_eff_deb DESC, tmp.date_eff_fin ASC
   LIMIT 1
)
ORDER BY prod.code_produit, pxvt.date_eff_deb


