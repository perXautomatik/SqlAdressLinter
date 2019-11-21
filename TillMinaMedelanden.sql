WITH
     FracToDec AS (SELECT (SELECT master.dbo.FracToDec(andel)) 'fra',FNR,BETECKNING,ärndenr 'arndenr',Namn,Adress,POSTNUMMER,postOrt,PERSORGNR FROM tempExcel.dbo.InputPlusGeofir),

     RowNrByBeteckning as (SELECT q.fra,q.POSTORT,q.POSTNUMMER,q.ADRESS,q.NAMN,q.BETECKNING,q.arndenr,q.PERSORGNR,
                                         ROW_NUMBER() OVER (PARTITION BY q.BETECKNING ORDER BY q.fra DESC) RowNum
                                  FROM FracToDec AS q
                                           INNER JOIN FracToDec thethree
                                                      ON q.arndenr = thethree.arndenr AND q.namn = thethree.namn),

     giveRowNrFilterBad as (SELECT fra,POSTORT,POSTNUMMER,ADRESS,NAMN,BETECKNING,arndenr,PERSORGNR,RowNum
                            FROM RowNrByBeteckning
                            WHERE RowNrByBeteckning.postOrt <> ''
                              AND RowNrByBeteckning.POSTNUMMER <> ''
                              AND RowNrByBeteckning.Adress <> ''
                              AND RowNrByBeteckning.Namn IS NOT NULL),


     filterSmallOwnersBadAdress AS (select * from giveRowNrFilterBad where  giveRowNrFilterBad.RowNum = 1
                                    UNION
                                    select * from  giveRowNrFilterBad where giveRowNrFilterBad.RowNum > 1 AND giveRowNrFilterBad.RowNum < 4 AND fra > 0.3 ),


     adressCompl AS (SELECT fra,AdressComplettering.POSTORT,AdressComplettering.POSTNUMMER,AdressComplettering.ADRESS,AdressComplettering.NAMN,BETECKNING,toComplete.arndenr,PERSORGNR,RowNum
                     FROM (SELECT fra,POSTORT,POSTNUMMER,ADRESS,NAMN,BETECKNING,arndenr,PERSORGNR,RowNum
                           FROM RowNrByBeteckning WHERE postOrt = '' OR POSTNUMMER = '' OR Adress = '' OR Namn IS NULL) AS toComplete LEFT OUTER JOIN tempExcel.dbo.AdressComplettering ON AdressComplettering.arndenr = toComplete.arndenr)





--SELECT DISTINCT adressCompl.fra,adressCompl.POSTORT,adressCompl.POSTNUMMER,adressCompl.ADRESS,adressCompl.NAMN,adressCompl.BETECKNING,adressCompl.arndenr,adressCompl.PERSORGNR FROM adressCompl UNION(SELECT filterSmallOwnersBadAdress.fra,filterSmallOwnersBadAdress.POSTORT,filterSmallOwnersBadAdress.POSTNUMMER,filterSmallOwnersBadAdress.ADRESS,filterSmallOwnersBadAdress.NAMN,filterSmallOwnersBadAdress.BETECKNING,filterSmallOwnersBadAdress.arndenr,filterSmallOwnersBadAdress.PERSORGNR FROM filterSmallOwnersBadAdress WHERE postOrt <> '' AND POSTNUMMER <> '' AND Adress <> '' AND Namn IS NOT NULL)ORDER BY arndenr;

select * from filterSmallOwnersBadAdress