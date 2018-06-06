
drop table occupants;
create table occupants (
 ref_logement char(10) default null,
 date_entree date default null,
 date_sortie date default null
) ;

insert into occupants 
( ref_logement, date_entree, date_sortie ) 
values 
( '11492', '2016–09–01', null ),
( '11492', '2016–05–15', '2016–07–31' ),
( '11492', '2016–02–01', '2016–04–30' ),
( '11481', '2016–12–15', '2017–03–31' ),
( '11481', '2016–08–01', '2016–10–31' ),
( '11481', '2016–02–01', '2016–02–29' ),
( '11182', '2016–11–15', '2017–01–31' ),
( '11182', '2016–01–01', '2016–10–31' )
;



with 
cte_step1 as (
select * from occupants 
     where date_entree is not null and date_sortie is not null 
     order by ref_logement, date_entree
),
cte_step2 as (
  select ref_logement, date_entree, date_sortie, 
   row_number() over(partition by ref_logement order by ref_logement, 
                     date_entree) as rupture
  from cte_step1 a
  order by ref_logement, date_entree
) 
,
cte_step3 as (
   select a.*, a.rupture+1 as next_rupture from cte_step2 a
)
, 
cte_step4 as (
   select a.ref_logement, DATE_ADD(a.date_sortie, INTERVAL + 1 DAY) as dat_deb_vacance, 
     DATE_ADD(b.date_entree, INTERVAL -1 DAY) as dat_fin_vacance, 
     DATEDIFF(b.date_entree, a.date_sortie) - 1  as vacance 
     from (select * from cte_step3 order by ref_logement, date_entree) a
     inner join (select * from cte_step3 order by ref_logement, date_entree) b 
        on a.ref_logement = b.ref_logement and a.next_rupture = b.rupture
)
select * from cte_step4 where vacance > 0 ;