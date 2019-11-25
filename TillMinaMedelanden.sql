with inputFracted as (
    select (SELECT master.dbo.FracToDec(andel)) 'fra',
           CAST(FNR AS int)             as      FNR,
           CAST(BETECKNING AS nvarchar) as      BETECKNING,
           CAST(ärndenr AS nvarchar)            'arndenr',
           CAST(Namn AS nvarchar)       as      Namn,
           CAST(Adress AS nvarchar)     as      Adress,
           CAST(POSTNUMMER AS nvarchar) as      POSTNUMMER,
           CAST(postOrt AS nvarchar)    as      postOrt,
           CAST(PERSORGNR AS nvarchar)  as      PERSORGNR
    from tempExcel.dbo.InputPlusGeofir
),
     withRowNr as (select outerT.fra,
                          outerT.POSTORT,
                          outerT.POSTNUMMER,
                          outerT.ADRESS,
                          outerT.NAMN,
                          outerT.BETECKNING,
                          outerT.arndenr,
                          outerT.PERSORGNR,
                          ROW_NUMBER() OVER ( PARTITION BY outerT.arndenr ORDER BY outerT.fra desc) RowNum
                   from inputFracted as outerT
                            INNER JOIN inputFracted innerT
                                       ON outerT.arndenr = innerT.arndenr and outerT.namn = innerT.namn),

     filterSmallOwnersBadAdress as (
         select fra,
                POSTORT,
                POSTNUMMER,
                ADRESS,
                NAMN,
                BETECKNING,
                arndenr,
                PERSORGNR,
                RowNum
         from (
                  select fra,
                         POSTORT,
                         POSTNUMMER,
                         ADRESS,
                         NAMN,
                         BETECKNING,
                         arndenr,
                         PERSORGNR,
                         RowNum
                  from withRowNr
                  WHERE RowNum = 1
                  union
                  select fra,
                         POSTORT,
                         POSTNUMMER,
                         ADRESS,
                         NAMN,
                         BETECKNING,
                         arndenr,
                         PERSORGNR,
                         RowNum
                  from withRowNr
                  WHERE RowNum > 1
                    and RowNum < 4
                    AND fra > 0.3) as combined
         where not ('' in (postOrt, POSTNUMMER, Adress)
             OR Namn is null))
        ,
     toComplete as (select fra,
                           POSTORT,
                           POSTNUMMER,
                           ADRESS,
                           NAMN,
                           BETECKNING,
                           arndenr,
                           PERSORGNR,
                           RowNum
                    from withRowNr
                    where (RowNum = 1 AND fra = 1)
                      AND ('' in (postOrt, POSTNUMMER, Adress) OR Namn is null)),

     adressCompl as (select fra,
                            AdressComplettering.POSTORT,
                            AdressComplettering.POSTNUMMER,
                            AdressComplettering.ADRESS,
                            AdressComplettering.NAMN,
                            BETECKNING,
                            toComplete.arndenr,
                            PERSORGNR,
                            RowNum
                     from toComplete
                              left outer join tempExcel.dbo.AdressComplettering
                                              on AdressComplettering.arndenr = toComplete.arndenr)
select *
from adressCompl
union
select *
from filterSmallOwnersBadAdress
order by arndenr, RowNum



