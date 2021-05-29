--1--
SELECT tb2.match_id, player.player_name, tb2.team_name, tb2.wickets FROM player INNER JOIN (SELECT * FROM (SELECT bbb.match_id, bbb.bowler, bbb.team_bowling as team, COUNT(bbb.bowler) as wickets FROM ball_by_ball AS bbb INNER JOIN wicket_taken as wt
ON CONCAT(bbb.match_id,bbb.over_id,bbb.ball_id,bbb.innings_no) =  CONCAT(wt.match_id,wt.over_id,wt.ball_id,wt.innings_no) WHERE wt.kind_out NOT IN (3,5,9) AND bbb.innings_no NOT IN (3,4)
GROUP BY bbb.match_id, bbb.team_bowling, bbb.bowler) AS tb1 INNER JOIN team on tb1.team = team.team_id WHERE tb1.wickets >= 5) AS tb2
ON player.player_id=tb2.bowler ORDER BY tb2.wickets DESC,player.player_name,tb2.team_name ASC;

--2--
SELECT player_name, tb2.num_matches FROM player INNER JOIN (SELECT tb1.man_of_the_match, COUNT(tb1.man_of_the_match) AS num_matches FROM player_match INNER JOIN
((SELECT match_id, team_1 AS team_lost, man_of_the_match FROM match WHERE match_winner = team_2 )
UNION 
(SELECT match_id, team_2 AS team_lost, man_of_the_match FROM match WHERE match_winner = team_1)) AS tb1
ON CONCAT(player_match.match_id, player_match.team_id, player_match.player_id) = CONCAT(tb1.match_id,tb1.team_lost, tb1.man_of_the_match)
GROUP BY tb1.man_of_the_match) AS tb2
ON player.player_id = tb2.man_of_the_match ORDER BY num_matches DESC, player_name ASC LIMIT 3;

--3--
SELECT player_name FROM player INNER JOIN 
(SELECT season_year,tb2.fielders, COUNT(tb2.fielders) AS catches FROM season INNER JOIN 
(SELECT season_id, tb1.fielders FROM match INNER JOIN 
(SELECT match_id, fielders FROM wicket_taken as wt WHERE wt.kind_out=1 AND wt.innings_no NOT IN (3,4)) as tb1 
ON match.match_id = tb1.match_id) AS tb2 ON season.season_id = tb2.season_id WHERE season_year = 2012 GROUP BY season_year, tb2.fielders) 
AS tb3 ON player.player_id = tb3.fielders ORDER BY catches DESC LIMIT 1;

--4--
SELECT tb2.season_year, player_name, tb2.num_matches FROM player INNER JOIN 
(SELECT season_year,player_id, COUNT(season.season_id) AS num_matches FROM season INNER JOIN (SELECT match.season_id, match.match_id, player_match.player_id 
FROM match INNER JOIN player_match 
ON match.match_id = player_match.match_id) AS tb1
ON CONCAT(season.season_id,season.purple_cap) =CONCAT(tb1.season_id,tb1.player_id) GROUP BY season.season_id, player_id) AS tb2
ON player.player_id = tb2.player_id ORDER BY season_year ASC;

--5--
SELECT DISTINCT player_name FROM player INNER JOIN
(SELECT striker FROM ball_by_ball AS bbb INNER JOIN batsman_scored AS bs
ON CONCAT(bbb.match_id, bbb.innings_no, bbb.over_id, bbb.ball_id) = CONCAT(bs.match_id, bs.innings_no, bs.over_id, bs.ball_id)
WHERE bbb.innings_no NOT IN (3,4) AND team_batting NOT IN (SELECT match_winner FROM match WHERE match_id = bbb.match_id)
GROUP BY bbb.match_id,team_batting, striker HAVING SUM(runs_scored) > 50) AS tb1
ON player.player_id = tb1.striker ORDER BY player_name;

--6--
SELECT tb4.season_year, tb4.team_name, tb4.rank, tb4.pcount FROM
(SELECT tb3.*, ROW_NUMBER() OVER (PARTITION BY season_year ORDER BY tb3.pcount DESC, tb3.team_name) AS rank FROM
(SELECT season_year, team_name, COUNT(team_name) AS pcount FROM season
INNER JOIN 
(SELECT DISTINCT season_id, team_id, player_id FROM match
INNER JOIN
(SELECT match_id, player_id,team_id FROM player_match as pm WHERE 
player_id IN 
(SELECT player_id FROM player WHERE 
player.batting_hand IN 
(SELECT batting_id FROM batting_style WHERE batting_hand = 'Left-hand bat') 
AND player.country_id NOT IN (SELECT country_id FROM country WHERE country_name = 'India'))) AS tb1
ON match.match_id = tb1.match_id) AS tb2
ON season.season_id = tb2.season_id
INNER JOIN team
ON team.team_id = tb2.team_id
GROUP BY season_year, team_name) AS tb3) tb4 WHERE rank <=5;

--7--
SELECT team_name FROM team INNER JOIN
(SELECT match_winner, COUNT(match_winner) AS match_won FROM match WHERE match_winner is NOT NULL 
AND season_id IN (SELECT season_id FROM season WHERE season_year = 2009) GROUP BY match_winner) AS tb1
ON team.team_id = tb1.match_winner ORDER BY match_won DESC, team_name;

--8--
SELECT team_name, player_name, runs FROM
(SELECT team_name, player_name, tb1.runs, ROW_NUMBER() OVER(PARTITION BY team_name ORDER BY runs DESC) AS rn FROM team INNER JOIN
(SELECT team_batting, striker, SUM(bs.runs_scored) AS runs FROM ball_by_ball AS bbb INNER JOIN batsman_scored AS bs
ON CONCAT(bbb.match_id,bbb.innings_no,bbb.over_id,bbb.ball_id) = CONCAT(bs.match_id,bs.innings_no,bs.over_id,bs.ball_id) 
WHERE bbb.innings_no NOT IN (3,4) 
AND bbb.match_id IN (SELECT match_id FROM  match WHERE season_id IN(SELECT season_id FROM season WHERE season_year = 2010))
GROUP BY team_batting, striker) AS tb1
ON team.team_id = tb1.team_batting
INNER JOIN player ON player.player_id = tb1.striker) AS tb2 WHERE rn=1 ORDER BY team_name, player_name;
  
--9--
 SELECT tb4.team_name,team.team_name AS Opponent_team_name,tb4.number_of_sixes FROM team INNER JOIN 
(SELECT team_name,tb3.team_bowling,tb3.number_of_sixes FROM team INNER JOIN 
(SELECT DISTINCT ON(tb2.team_batting) tb2.team_batting,team_bowling,tb2.number_of_sixes FROM season INNER JOIN 
(SELECT season_id,tb1.team_batting,tb1.team_bowling,tb1.number_of_sixes FROM match INNER JOIN 
(SELECT bbb.match_id,bbb.team_batting,bbb.team_bowling,COUNT(bs.runs_scored) AS number_of_sixes FROM ball_by_ball AS bbb INNER JOIN 
(SELECT * FROM batsman_scored WHERE runs_scored = 6) AS bs ON 
CONCAT(bbb.match_id,bbb.innings_no,bbb.over_id,bbb.ball_id) = CONCAT(bs.match_id,bs.innings_no,bs.over_id,bs.ball_id) 
WHERE bbb.innings_no NOT IN(3,4)
GROUP BY bbb.match_id,bbb.team_batting,bbb.team_bowling) AS tb1
ON match.match_id = tb1.match_id) AS tb2 ON season.season_id = tb2.season_id WHERE season.season_year = 2008 
 ORDER BY tb2.team_batting,tb2.number_of_sixes DESC) AS tb3 
 ON team.team_id = tb3.team_batting ORDER BY number_of_sixes DESC,team_name ASC LIMIT 3) AS tb4 
 ON tb4.team_bowling = team.team_id ORDER BY tb4.team_name;
 
 --10--
SELECT AVG(wickets) FROM
(SELECT bowler, COUNT(bowler) AS wickets FROM ball_by_ball AS bbb INNER JOIN wicket_taken AS wt
ON CONCAT(bbb.match_id, bbb.innings_no, bbb.over_id, bbb.ball_id) = CONCAT(wt.match_id, wt.innings_no, wt.over_id, wt.ball_id)
WHERE wt.kind_out NOT IN (3,5,9) GROUP BY bowler) AS tb1;
 
 --11--
SELECT s.season_year, pl.player_name,num_wickets,b1.runs FROM season AS s
INNER JOIN
(SELECT a1.season_id, a1.player_id, a2.runs, a3.wickets AS num_wickets FROM
(SELECT season_id, player_id, COUNT(player_id) AS total_matches FROM player_match 
INNER JOIN match 
ON player_match.match_id = match.match_id 
WHERE player_id IN (SELECT player_id FROM player WHERE batting_hand IN (SELECT batting_id FROM batting_style WHERE batting_hand = 'Left-hand bat'))
GROUP BY season_id, player_id HAVING COUNT(player_id) >= 10) AS a1
INNER JOIN
(SELECT season_id, tb1.player_id, SUM(tb1.run_match) AS runs FROM match INNER JOIN 
(SELECT bbb.match_id, striker AS player_id, SUM(runs_scored) AS run_match FROM ball_by_ball AS bbb INNER JOIN batsman_scored AS bs
ON CONCAT(bbb.match_id, bbb.innings_no, bbb.over_id, bbb.ball_id) = CONCAT(bs.match_id, bs.innings_no, bs.over_id, bs.ball_id) WHERE bs.innings_no NOT IN(3,4)
GROUP BY bbb.match_id, striker) AS tb1
ON tb1.match_id = match.match_id GROUP BY season_id,tb1.player_id HAVING SUM(tb1.run_match) >= 150) AS a2
ON CONCAT(a1.season_id, a1.player_id) = CONCAT(a2.season_id,a2.player_id)
INNER JOIN
(SELECT season_id, tb2.player_id, SUM(tb2.sw) AS wickets FROM match INNER JOIN 
(SELECT bbb.match_id, bowler AS player_id, COUNT(bowler) AS sw FROM ball_by_ball AS bbb INNER JOIN wicket_taken AS wt
ON CONCAT(bbb.match_id, bbb.innings_no, bbb.over_id, bbb.ball_id) = CONCAT(wt.match_id, wt.innings_no, wt.over_id, wt.ball_id) WHERE wt.kind_out NOT IN (3,5,9) AND wt.innings_no NOT IN (3,4)
GROUP BY bbb.match_id, bowler) AS tb2
ON tb2.match_id = match.match_id GROUP BY season_id,tb2.player_id HAVING SUM(tb2.sw) >= 5) AS a3
ON CONCAT(a3.season_id, a3.player_id) = CONCAT(a2.season_id,a2.player_id)) AS b1
ON b1.season_id =s.season_id 
INNER JOIN player AS pl 
ON pl.player_id = b1.player_id ORDER BY num_wickets DESC, runs DESC, pl.player_name;

--12--
SELECT tb1.match_id, player.player_name, team.team_name, tb1.sw AS num_wickets, season.season_year FROM player INNER JOIN
(SELECT bbb.match_id, bowler, bbb.team_bowling, COUNT(bowler) AS sw FROM ball_by_ball AS bbb INNER JOIN wicket_taken AS wt
ON CONCAT(bbb.match_id, bbb.innings_no, bbb.over_id, bbb.ball_id) = CONCAT(wt.match_id, wt.innings_no, wt.over_id, wt.ball_id) WHERE wt.kind_out NOT IN (3,5,9) AND wt.innings_no NOT IN(3,4)
GROUP BY bbb.match_id, bbb.team_bowling,bowler) AS tb1 
ON player.player_id = tb1.bowler 
INNER JOIN team 
ON team.team_id = tb1.team_bowling 
INNER JOIN match 
ON match.match_id = tb1.match_id 
INNER JOIN season 
ON match.season_id = season.season_id ORDER BY num_wickets DESC, player.player_name, tb1.match_id;

--13--
SELECT player_name FROM player INNER JOIN 
(SELECT player_id  FROM (SELECT season_id, player_id, COUNT(player_id) FROM player_match INNER JOIN
match ON match.match_id = player_match.match_id GROUP BY season_id, player_id) AS tb1 
GROUP BY player_id HAVING COUNT(season_id) =8) AS tb2 
ON player.player_id = tb2.player_id ORDER BY player_name;

--14--
SELECT season_year, match_id, team_name FROM team INNER JOIN
(SELECT season_id, tb2.match_id, tb2.team_batting, total_with_fifty_plus, ROW_NUMBER() OVER(PARTITION BY season_id ORDER BY total_with_fifty_plus DESC) AS rn FROM
(SELECT season_id, tb1.match_id, tb1.team_batting, COUNT(tb1.striker) AS total_with_fifty_plus FROM match
INNER JOIN
(SELECT bbb.match_id, bbb.team_batting, bbb.striker FROM ball_by_ball AS bbb INNER JOIN batsman_scored AS bs
ON CONCAT(bbb.match_id,bbb.innings_no, bbb.over_id, bbb.ball_id) = CONCAT(bs.match_id,bs.innings_no, bs.over_id, bs.ball_id) WHERE bs.innings_no NOT IN(3,4)
GROUP BY bbb.match_id, bbb.team_batting, bbb.striker HAVING SUM(runs_scored) >= 50) AS tb1
ON (match.match_id, match.match_winner) = (tb1.match_id, tb1.team_batting)
GROUP BY season_id,tb1.match_id, tb1.team_batting) AS tb2) AS tb3
ON team.team_id = tb3.team_batting
INNER JOIN season
ON season.season_id = tb3.season_id WHERE tb3.rn <= 3 ORDER BY season_year,team_name;

--15--
SELECT tmp1.season_year, top_batsman,max_runs,top_bowler, max_wickets FROM
(
SELECT season_year,top_batsman, max_runs FROM season INNER JOIN
(SELECT tb3.season_id, top_batsman, max_runs, ROW_NUMBER() OVER(PARTITION BY tb3.season_id ORDER BY tb3.max_runs DESC) AS rn FROM 
(SELECT season_id, player_name AS top_batsman, max_runs FROM player INNER JOIN   
(SELECT season_id, tb1.striker, SUM(tb1.match_run) AS max_runs FROM match INNER JOIN 
(SELECT bbb.match_id, striker, SUM(runs_scored) AS match_run FROM ball_by_ball AS bbb INNER JOIN batsman_scored AS bs
ON CONCAT(bbb.match_id, bbb.innings_no, bbb.over_id, bbb.ball_id) = CONCAT(bs.match_id, bs.innings_no, bs.over_id, bs.ball_id) WHERE bs.innings_no NOT IN(3,4) GROUP BY bbb.match_id, striker) AS tb1 
 ON match.match_id = tb1.match_id GROUP BY season_id, tb1.striker) AS tb2
 ON player.player_id = tb2.striker ORDER BY top_batsman) AS tb3) AS tb4
 ON season.season_id = tb4.season_id 
WHERE tb4.rn=2

) AS tmp1
INNER JOIN
(
SELECT season_year,top_bowler, max_wickets FROM season INNER JOIN
(SELECT tb3.season_id, top_bowler, max_wickets, ROW_NUMBER() OVER(PARTITION BY tb3.season_id ORDER BY tb3.max_wickets DESC) AS rn FROM 
(SELECT season_id, player_name AS top_bowler, max_wickets FROM player INNER JOIN   
(SELECT season_id, tb1.bowler, SUM(tb1.match_wicket) AS max_wickets FROM match INNER JOIN 
(SELECT bbb.match_id, bowler, COUNT(bowler) AS match_wicket FROM ball_by_ball AS bbb INNER JOIN wicket_taken AS wt
ON CONCAT(bbb.match_id, bbb.innings_no, bbb.over_id, bbb.ball_id) = CONCAT(wt.match_id, wt.innings_no, wt.over_id, wt.ball_id) WHERE wt.kind_out NOT IN (3,5,9) AND wt.innings_no NOT IN(3,4)
GROUP BY bbb.match_id, bowler) AS tb1 
 ON match.match_id = tb1.match_id GROUP BY season_id, tb1.bowler) AS tb2
 ON player.player_id = tb2.bowler ORDER BY top_bowler) AS tb3) AS tb4
 ON season.season_id = tb4.season_id 
WHERE tb4.rn=2
) AS tmp2
ON tmp1.season_year = tmp2.season_year;

--16--
SELECT team_name FROM team INNER JOIN
(SELECT match_winner, COUNT(match_winner) AS wins FROM match WHERE match_id IN 
 ((SELECT match_id FROM match WHERE season_id IN ((SELECT season_id FROM season WHERE season_year = 2008)))) AND
 match_winner IS NOT NULL AND match_winner NOT IN 
((SELECT team_id FROM team WHERE team_name = 'Royal Challengers Bangalore')) 
AND 
 (team_1 IN ((SELECT team_id FROM team WHERE team_name = 'Royal Challengers Bangalore')) 
  OR 
  team_2 IN ((SELECT team_id FROM team WHERE team_name = 'Royal Challengers Bangalore')))  GROUP BY match_winner
 ) AS tb1
 ON team.team_id = match_winner ORDER BY wins DESC, team_name;
 
 --17--
 SELECT DISTINCT ON (team_name) team_name, player_name, count FROM player INNER JOIN
(SELECT team_id, player_id, COUNT(player_id) as count FROM player_match INNER JOIN match
ON CONCAT(player_match.match_id,player_match.player_id) = CONCAT(match.match_id,match.man_of_the_match) GROUP BY team_id, player_id ORDER BY team_id, count DESC) 
AS tb1 
ON player.player_id = tb1.player_id
INNER JOIN team 
ON team.team_id = tb1.team_id ORDER BY team_name, count DESC; 

--18--
SELECT player_name FROM player INNER JOIN
(SELECT player_id, tb2.times FROM 
(SELECT player_id FROM (SELECT DISTINCT player_id, team_id FROM player_match) AS tb1
GROUP BY player_id HAVING COUNT(team_id) >=3) AS tb3 INNER JOIN
(SELECT bowler, COUNT(bowler) AS times FROM
(SELECT bowler FROM ball_by_ball AS bbb INNER JOIN batsman_scored AS bs 
ON CONCAT(bbb.match_id, bbb.innings_no, bbb.over_id, bbb.ball_id) = CONCAT(bs.match_id, bs.innings_no, bs.over_id, bs.ball_id)
 GROUP BY bbb.match_id, bbb.innings_no, bbb.over_id, bowler HAVING SUM(runs_scored) > 20) AS tb1 GROUP BY bowler) AS tb2
 ON tb3.player_id = tb2.bowler) AS tmp
 ON tmp.player_id = player.player_id ORDER BY tmp.times DESC, player_name LIMIT 5;
 ;
 
 --19--
 SELECT team_name, tb2.avg_runs FROM team INNER JOIN 
(SELECT team_batting, CAST(AVG (per_match_total) AS DECIMAL (12,2)) AS avg_runs FROM
(SELECT team_batting, bbb.match_id, SUM(bs.runs_scored) AS per_match_total FROM ball_by_ball AS bbb INNER JOIN batsman_scored AS bs
ON CONCAT(bbb.match_id, bbb.innings_no, bbb.over_id, bbb.ball_id) = CONCAT(bs.match_id, bs.innings_no, bs.over_id, bs.ball_id) WHERE bs.innings_no NOT IN(3,4) AND
 bbb.match_id IN ((SELECT match_id FROM match WHERE season_id IN((SELECT season_id FROM season WHERE season_year = 2010)))) 
GROUP BY bbb.team_batting, bbb.match_id) AS tb1 GROUP BY team_batting) AS tb2
ON team.team_id = tb2.team_batting ORDER BY team_name;

--20--
SELECT player_name FROM player INNER JOIN 
(SELECT player_out, COUNT(player_out) AS times FROM wicket_taken WHERE over_id = 1 GROUP BY player_out) AS tb1
ON player.player_id = tb1.player_out ORDER BY tb1.times DESC,player_name LIMIT 10;

--21--
SELECT match_id, team1.team_name AS team_1_name, team2.team_name AS team_2_name, team3.team_name AS match_winner_name, number_of_boundaries FROM
(SELECT match.match_id,team_1, team_2,match_winner, number_of_boundaries FROM match INNER JOIN  
(SELECT bbb.match_id, bbb.team_batting, COUNT(bbb.team_batting) AS number_of_boundaries  FROM ball_by_ball AS bbb INNER JOIN batsman_scored AS bs
ON CONCAT(bbb.match_id, bbb.innings_no, bbb.over_id, bbb.ball_id) = CONCAT(bs.match_id, bs.innings_no, bs.over_id, bs.ball_id) WHERE bs.innings_no NOT IN(3,4) AND 
bs.runs_scored IN (4,6) GROUP BY bbb.match_id, bbb.team_batting) AS tb1
ON match.match_id = tb1.match_id WHERE match.win_id IN ((SELECT win_id FROM win_by WHERE win_type = 'wickets'))) AS tb2
INNER JOIN team team1 ON tb2.team_1 = team1.team_id
INNER JOIN team team2 ON tb2.team_2 = team2.team_id
INNER JOIN team team3 ON tb2.match_winner = team3.team_id
ORDER BY number_of_boundaries, match_winner_name, team_1_name,team_2_name LIMIT 3;

 --22--
SELECT country_name FROM country INNER JOIN
player ON player.country_id = country.country_id
INNER JOIN
(SELECT tb1.bowler,  (tb2.runs / tb1.wickets) AS avg FROM 
(SELECT bowler, COUNT(bowler) AS wickets FROM ball_by_ball AS bbb INNER JOIN wicket_taken AS wt
ON CONCAT(bbb.match_id, bbb.innings_no, bbb.over_id, bbb.ball_id)=CONCAT(wt.match_id, wt.innings_no, wt.over_id, wt.ball_id) WHERE wt.innings_no NOT IN(3,4) AND 
kind_out NOT IN (3,5,9) GROUP BY bowler HAVING COUNT(bowler) >0 )AS tb1 
INNER JOIN
(SELECT bowler, SUM(runs_scored) AS runs FROM ball_by_ball AS bbb INNER JOIN batsman_scored AS bs
ON CONCAT(bbb.match_id, bbb.innings_no, bbb.over_id, bbb.ball_id)=CONCAT(bs.match_id, bs.innings_no, bs.over_id, bs.ball_id) WHERE bs.innings_no NOT IN(3,4)
GROUP BY bowler HAVING SUM(runs_scored) >0) AS tb2
ON tb1.bowler = tb2.bowler) AS tb3
ON player.player_id = tb3.bowler
ORDER BY tb3.avg, player_name LIMIT 3;
