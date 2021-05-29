--PREAMBLE--
CREATE EXTENSION intarray;
CREATE VIEW inter_state_flight AS
(
	SELECT tb1.flightid FROM airports INNER JOIN
	(SELECT flightid, airports.state AS sstate, destairportid FROM flights INNER JOIN airports
	ON airports.airportid = originairportid) AS tb1
	ON airports.airportid = tb1.destairportid
	WHERE tb1.sstate <> airports.state
);

CREATE VIEW possible_path AS
( SELECT t.airportid AS originairportid, p.airportid AS destairportid FROM airports AS t, airports AS p
	WHERE t.airportid <> p.airportid
);

CREATE VIEW ny_airports AS (SELECT airportid FROM airports WHERE state='New York');

CREATE VIEW papercitations AS
WITH RECURSIVE citations(paperid2,paperid1,paperlist) AS
(
	SELECT paperid2,paperid1,ARRAY[paperid1] FROM citationlist 
	UNION
	SELECT citations.paperid2,citationlist.paperid1,paperlist||citationlist.paperid1 FROM citations INNER JOIN 
	citationlist ON citations.paperid1 = citationlist.paperid2
) SELECT authorid,paperid,tb1.cl,array_length(tb1.cl,1) AS count FROM authorpaperlist INNER JOIN 
(SELECT paperid2,array_agg(paperid1) AS cl FROM citations GROUP BY paperid2) AS tb1 ON
authorpaperlist.paperid = paperid2;

CREATE VIEW authorcitations AS
(
	SELECT authordetails.authorid, CASE WHEN totalcite IS NULL THEN 0 ELSE totalcite END FROM authordetails LEFT OUTER JOIN
	(SELECT authorid,SUM(count) AS totalcite FROM papercitations 
	GROUP BY authorid) AS tb1
	ON authordetails.authorid = tb1.authorid
);

CREATE VIEW graph AS 
(
	SELECT tb2.*, gender AS sgender, age AS sage, city AS scity FROM
	(SELECT tb1.fauthorid, gender AS fgender, age AS fage, city AS fcity, tb1.sauthorid FROM
	(SELECT f.authorid AS fauthorid, s.authorid AS sauthorid FROM authorpaperlist AS f INNER JOIN authorpaperlist AS s
	ON f.paperid = s.paperid WHERE f.authorid <> s.authorid) AS tb1
	INNER JOIN authordetails ON tb1.fauthorid = authordetails.authorid) AS tb2
	INNER JOIN authordetails ON tb2.sauthorid = authordetails.authorid
);

CREATE VIEW author_author_cite AS
SELECT tb1.authorid AS f, appl.authorid AS s, COUNT(appl.authorid) AS count FROM authorpaperlist as appl INNER JOIN
(SELECT apl.authorid, apl.paperid, cl.paperid2 FROM authorpaperlist AS apl INNER JOIN citationlist AS cl
ON apl.paperid = cl.paperid1) AS tb1
ON appl.paperid = tb1.paperid2 GROUP BY tb1.authorid, appl.authorid;

--1--
WITH RECURSIVE fromAlberqurque AS 
(
    SELECT originairportid,destairportid,carrier FROM flights 
	WHERE originairportid = 10140
    UNION 
    SELECT fromAlberqurque.originairportid,fli.destairportid,fli.carrier 
    FROM fromAlberqurque INNER JOIN flights AS fli ON 
    fromAlberqurque.destairportid = fli.originairportid WHERE 
	fli.carrier = fromAlberqurque.carrier
) SELECT distinct city AS name FROM airports INNER JOIN fromAlberqurque 
ON airports.airportid = fromAlberqurque.destairportid ORDER BY name; 

--2--
WITH RECURSIVE fromAlberqurque AS 
(
    SELECT originairportid,destairportid,dayofweek FROM flights 
	WHERE originairportid = 10140
    UNION 
    SELECT fromAlberqurque.originairportid,fli.destairportid,fli.dayofweek
	FROM fromAlberqurque INNER JOIN flights AS fli
	ON fromAlberqurque.destairportid = fli.originairportid
	WHERE fli.dayofweek = fromAlberqurque.dayofweek
) SELECT distinct city AS name FROM airports INNER JOIN fromAlberqurque 
ON airports.airportid = fromAlberqurque.destairportid ORDER BY city;

--3--
WITH RECURSIVE fromAlberqurque AS 
(
    SELECT originairportid,destairportid, ARRAY[originairportid,destairportid] AS path FROM flights 
	WHERE originairportid = 10140
    UNION 
    SELECT fromAlberqurque.originairportid,fli.destairportid, path || fli.destairportid 
	FROM fromAlberqurque INNER JOIN flights AS fli
	ON fromAlberqurque.destairportid = fli.originairportid
	WHERE (NOT fli.destairportid = ANY(path)) OR fli.destairportid = 10140
) SELECT city AS name FROM airports INNER JOIN fromAlberqurque 
ON airports.airportid = fromAlberqurque.destairportid
GROUP BY city HAVING COUNT(city) = 1 ORDER BY city;

--4--
WITH RECURSIVE fromAlberqurque(originairportid, destairportid, path) AS 
(
	SELECT originairportid, destairportid, ARRAY[destairportid] FROM
	flights WHERE originairportid = 10140
	UNION
	SELECT fromAlberqurque.originairportid, fli.destairportid, path || fli.destairportid
	FROM fromAlberqurque INNER JOIN flights AS fli 
	ON fromAlberqurque.destairportid = fli.originairportid 
	WHERE NOT fli.destairportid = ANY(path)
)
SELECT array_length(path,1) AS length FROM fromAlberqurque
WHERE fromAlberqurque.destairportid=10140;

 --5--
WITH RECURSIVE fromAlberqurque(originairportid, destairportid, path) AS 
(
	SELECT originairportid, destairportid, ARRAY[destairportid] FROM flights 
	UNION
	SELECT fromAlberqurque.originairportid, fli.destairportid, path || fli.destairportid
	FROM fromAlberqurque INNER JOIN flights AS fli
	ON fromAlberqurque.destairportid = fli.originairportid 
	WHERE NOT fli.destairportid = ANY(path) 
) 
SELECT array_length(path,1) AS length  
FROM fromAlberqurque WHERE fromAlberqurque.originairportid = fromAlberqurque.destairportid
ORDER BY length DESC LIMIT 1;

--6--
WITH RECURSIVE fromAlberqurque(originairportid, destairportid, path) AS 
(
	SELECT originairportid, destairportid, ARRAY[destairportid] FROM flights 
	WHERE originairportid IN (SELECT airportid FROM airports WHERE city='Albuquerque') 
	AND flightid IN (SELECT * FROM inter_state_flight)
	UNION
	SELECT fromAlberqurque.originairportid, fli.destairportid, path || fli.destairportid
	FROM fromAlberqurque INNER JOIN flights AS fli
	ON fromAlberqurque.destairportid = fli.originairportid 
	WHERE (NOT fli.destairportid = ANY(path)) AND fli.flightid IN (SELECT * FROM inter_state_flight)	
) 
SELECT COUNT(*) AS count  
FROM fromAlberqurque WHERE fromAlberqurque.destairportid 
IN (SELECT airportid FROM airports WHERE city='Chicago');

--7--
WITH RECURSIVE fromAlberqurque(originairportid, destairportid, path) AS 
(
	SELECT originairportid, destairportid, ARRAY[destairportid] FROM flights 
	WHERE originairportid IN (SELECT airportid FROM airports WHERE city='Albuquerque')
	UNION
	SELECT fromAlberqurque.originairportid, fli.destairportid, path || fli.destairportid
	FROM fromAlberqurque INNER JOIN flights AS fli
	ON fromAlberqurque.destairportid = fli.originairportid 
	WHERE NOT fli.destairportid = ANY(path)	
) 
SELECT COUNT(*) AS count
FROM fromAlberqurque WHERE
fromAlberqurque.destairportid IN (SELECT airportid FROM airports WHERE city='Chicago')
AND (SELECT airportid FROM airports WHERE city='Washington') = ANY(path);

--8--
WITH RECURSIVE path AS 
(
    SELECT DISTINCT originairportid,destairportid FROM flights 
    UNION 
    SELECT DISTINCT path.originairportid,fli.destairportid
	FROM path INNER JOIN flights AS fli 
	ON path.destairportid = fli.originairportid 
	WHERE path.originairportid <> fli.destairportid
) 
 SELECT tb2.name1,city AS name2 FROM airports INNER JOIN 
 (SELECT city AS name1,tb1.destairportid FROM airports INNER JOIN  
 (SELECT * FROM possible_path EXCEPT (SELECT * FROM path)) AS tb1 ON
 airports.airportid = tb1.originairportid) AS tb2 ON 
 airports.airportid= tb2.destairportid ORDER BY name1,name2;
 
--9--
WITH RECURSIVE days(n) AS
(
	SELECT 1 
	UNION
	SELECT n+1 FROM days WHERE n+1 <= 31
) SELECT dayofmonth AS day FROM (SELECT n AS dayofmonth ,CASE WHEN tb1.totaldelay IS NULL THEN 0 ELSE tb1.totaldelay END 
FROM days LEFT OUTER JOIN  
(SELECT dayofmonth,SUM(departuredelay+arrivaldelay) AS totaldelay FROM flights 
WHERE originairportid = 10140 GROUP BY dayofmonth ORDER BY totaldelay,dayofmonth ) AS tb1 ON
days.n = tb1.dayofmonth ORDER BY totaldelay, dayofmonth) AS tb2;

--10--
SELECT city AS name FROM airports INNER JOIN
(SELECT originairportid, COUNT(originairportid) AS count FROM
(SELECT DISTINCT originairportid, destairportid FROM flights 
WHERE
originairportid IN (SELECT * FROM ny_airports) 
AND
destairportid IN (SELECT * FROM ny_airports)) AS tb1
GROUP BY originairportid) AS tb2
ON airports.airportid = tb2.originairportid
WHERE tb2.count >= (SELECT COUNT(*) FROM ny_airports) -1 ORDER BY city;

--11--
WITH RECURSIVE fromAlberqurque AS 
(
    SELECT originairportid,destairportid,departuredelay+arrivaldelay AS delay FROM flights 
    UNION 
    SELECT fromAlberqurque.originairportid,fli.destairportid,fli.departuredelay+fli.arrivaldelay AS delay
    FROM fromAlberqurque INNER JOIN flights AS fli
	ON fromAlberqurque.destairportid=fli.originairportid 
	WHERE fromAlberqurque.delay < fli.departuredelay+fli.arrivaldelay
) 
SELECT name1,city AS name2 FROM (SELECT city AS name1,fromAlberqurque.destairportid,delay FROM airports 
INNER JOIN fromAlberqurque ON fromAlberqurque.originairportid = airportid ORDER BY delay) AS tb1
INNER JOIN airports ON tb1.destairportid = airports.airportid ORDER BY name1,name2;

--12--
WITH RECURSIVE traverse(fauthorid, sauthorid, path) AS
(
	SELECT fauthorid, sauthorid, ARRAY[sauthorid] FROM graph WHERE fauthorid = 1235
	UNION
	SELECT traverse.fauthorid, graph.sauthorid,traverse.path || graph.sauthorid FROM traverse
	INNER JOIN graph ON traverse.sauthorid = graph.fauthorid
	WHERE NOT graph.sauthorid=ANY(traverse.path)
)
SELECT tb1.authorid, CASE WHEN tb1.d IS NULL THEN -1 ELSE tb1.d END AS length FROM
(SELECT ad.authorid, array_length(traverse.path,1) AS d FROM authordetails AS ad
LEFT OUTER JOIN traverse ON ad.authorid = traverse.sauthorid
WHERE ad.authorid <> 1235 ) AS tb1 ORDER BY length, tb1.authorid;

--13--
WITH RECURSIVE traverse(fauthorid, sauthorid, sgender) AS
(
	SELECT fauthorid, sauthorid, sgender FROM graph
	WHERE (sage > 35 OR sauthorid=2826) AND fauthorid = 1558
	UNION
	SELECT traverse.fauthorid, graph.sauthorid, graph.sgender 
	FROM traverse INNER JOIN graph
	ON traverse.sauthorid = graph.fauthorid
	WHERE graph.sauthorid= 2826 OR (graph.sgender <> traverse.sgender AND graph.sage > 35)
)
SELECT CASE WHEN count=0 THEN -1 ELSE count END FROM
(SELECT COUNT(*) AS count FROM traverse WHERE sauthorid = 2826) AS tb1;

--14--
WITH RECURSIVE traverse(fauthorid, sauthorid, path) AS
(
	SELECT fauthorid, sauthorid, ARRAY[sauthorid] FROM graph WHERE fauthorid = 704
	UNION
	SELECT traverse.fauthorid, graph.sauthorid, traverse.path || graph.sauthorid 
	FROM traverse INNER JOIN graph
	ON traverse.sauthorid = graph.fauthorid
	WHERE NOT graph.sauthorid=ANY(traverse.path)
)
SELECT CASE WHEN count=0 THEN -1 ELSE count END FROM
(SELECT COUNT(*) AS count FROM traverse WHERE traverse.sauthorid = 102
AND (SELECT authorid FROM papercitations WHERE 126 = ANY(cl)) = ANY(path) 
) AS tb2;


--15--
WITH RECURSIVE traverse(fauthorid, sauthorid, path, clist) AS
(
	SELECT fauthorid, sauthorid, ARRAY[sauthorid], ARRAY[totalcite] FROM graph
	INNER JOIN authorcitations ON authorcitations.authorid = sauthorid
	WHERE fauthorid = 1745
	UNION
	SELECT traverse.fauthorid, graph.sauthorid, traverse.path || graph.sauthorid, traverse.clist || totalcite
	FROM traverse INNER JOIN graph
	ON traverse.sauthorid = graph.fauthorid
	INNER JOIN authorcitations ON authorcitations.authorid = graph.sauthorid
	WHERE NOT graph.sauthorid=ANY(traverse.path)
)
SELECT COUNT(*) AS count FROM 
(SELECT clist[:array_length(clist,1)-1] AS cl FROM traverse WHERE sauthorid=456) AS tb1
WHERE sort_asc(cl) = cl OR sort_desc(cl) = cl;

--16--
SELECT f,count FROM author_author_cite AS aac
WHERE NOT EXISTS (SELECT aac1.f, aac1.s FROM author_author_cite AS aac1 WHERE aac1.f =aac.s AND aac1.s = aac.f )
ORDER BY count DESC,f;

--17--
--17--
WITH RECURSIVE traverse(fauthorid, sauthorid, path) AS
(
	SELECT fauthorid, sauthorid, ARRAY[sauthorid] FROM graph
	UNION
	SELECT traverse.fauthorid, graph.sauthorid, traverse.path || graph.sauthorid 
	FROM traverse INNER JOIN graph
	ON traverse.sauthorid = graph.fauthorid
	WHERE NOT graph.sauthorid=ANY(traverse.path)
)
SELECT tb2.authorid FROM
(SELECT tb1.fauthorid AS authorid, MAX(ac.totalcite) AS tc FROM authorcitations AS ac INNER JOIN
(SELECT DISTINCT fauthorid, path[3] AS third FROM traverse WHERE array_length(path,1) >= 3 AND fauthorid <> path[3]) AS tb1
ON ac.authorid = tb1.third GROUP BY tb1.fauthorid) AS tb2 ORDER BY tc DESC, tb2.authorid;

--18--
WITH RECURSIVE traverse(fauthorid, sauthorid, path) AS
(
	SELECT fauthorid, sauthorid, ARRAY[fauthorid,sauthorid] FROM author_view WHERE fauthorid = 3552
	UNION
	SELECT traverse.fauthorid, av.sauthorid, traverse.path || av.sauthorid 
	FROM traverse INNER JOIN author_view AS av
	ON traverse.sauthorid = av.fauthorid
	WHERE NOT av.sauthorid=ANY(traverse.path)
) SELECT CASE WHEN count=0 THEN -1 ELSE count END FROM
(SELECT COUNT(*) AS count FROM traverse WHERE sauthorid=321 AND (1436=ANY(path) OR 562=ANY(path) OR 921=ANY(path))) AS tb1;


--19--

--20--

--21--

--22--

--CLEANUP--
DROP VIEW inter_state_flight;
DROP VIEW possible_path;
DROP VIEW ny_airports;
DROP VIEW graph;
DROP VIEW authorcitations;
DROP VIEW papercitations;
DROP VIEW author_author_cite;
DROP EXTENSION intarray;