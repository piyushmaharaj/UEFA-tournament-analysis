--CREATING GOALS TABLE

DROP TABLE IF EXISTS goals;

CREATE TABLE goals (
    goal_id     VARCHAR(20),
    match_id    VARCHAR(20),
    pid         VARCHAR(20),
    duration    INT,
    assist      VARCHAR(20),
    goal_desc   VARCHAR(100)
);

--CREATING TABLE MATCHES

DROP TABLE IF EXISTS matches;

CREATE TABLE matches (
    match_id           VARCHAR(20),
    season             VARCHAR(20),
    match_date         DATE,
    home_team          VARCHAR(50),
    away_team          VARCHAR(50),
    stadium            VARCHAR(100),
    home_team_score    INT,
    away_team_score    INT,
    penalty_shoot_out  INT,
    attendance         INT
);

--CREATING PLAYERS TABLE

DROP TABLE IF EXISTS players;

CREATE TABLE players (
    player_id      VARCHAR(20),
    first_name     VARCHAR(50),
    last_name      VARCHAR(50),
    nationality    VARCHAR(50),
    dob            DATE,
    team           VARCHAR(50),
    jersey_number  INT,
    position       VARCHAR(30),
    height         FLOAT,
    weight         FLOAT,
    foot           VARCHAR(5)
);

--CREATING TEAMS TABLE

DROP TABLE IF EXISTS teams;

CREATE TABLE teams (
    team_name     VARCHAR(50),
    country       VARCHAR(50),
    home_stadium  VARCHAR(100)
);

--CREATING TABLES STADIUM

DROP TABLE IF EXISTS stadiums;

CREATE TABLE stadiums (
    name      VARCHAR(100),
    city      VARCHAR(50),
    country   VARCHAR(50),
    capacity  INT
);

--GOAL ANALYSIS--

--1.Which player scored the most goals in a each season?

SELECT season,
       p.player_id,
       p.first_name,
	   p.last_name,
       goals_scored
FROM (
    SELECT m.season,
           g.pid,
           COUNT(*) AS goals_scored,
           RANK() OVER (PARTITION BY m.season ORDER BY COUNT(*) DESC) AS rnk
    FROM goals g
    JOIN matches m
      ON g.match_id = m.match_id
    GROUP BY m.season, g.pid
) g
LEFT JOIN players p
  ON g.pid = p.player_id
WHERE rnk = 1
ORDER BY season;

--2.How many goals did each player score in a given season?

SELECT m.season,
       CONCAT(p.first_name, ' ', p.last_name) AS player_name,
       COUNT(*) AS total_goals
FROM goals g
JOIN matches m
  ON g.match_id = m.match_id
LEFT JOIN players p
  ON g.pid = p.player_id
GROUP BY m.season, player_name
ORDER BY m.season, total_goals DESC;


--3.What is the total number of goals scored in ‘mt403’ match?

SELECT COUNT(*) AS total_goals
FROM goals
WHERE match_id = 'mt403';

--4.Which player assisted the most goals in a each season?

SELECT season,
       CONCAT(p.first_name, ' ', p.last_name) AS player_name,
       assist_count
FROM (
    SELECT m.season,
           g.assist,
           COUNT(*) AS assist_count,
           RANK() OVER (PARTITION BY m.season ORDER BY COUNT(*) DESC) AS rnk
    FROM goals g
    JOIN matches m
      ON g.match_id = m.match_id
    WHERE g.assist IS NOT NULL
    GROUP BY m.season, g.assist
) g
LEFT JOIN players p
  ON g.assist = p.player_id
WHERE rnk = 1
ORDER BY season;


--5.Which players have scored goals in more than 10 matches?

SELECT CONCAT(p.first_name, ' ', p.last_name) AS player_name, 
       p.player_id,
       COUNT(DISTINCT g.match_id) AS matches_scored
FROM goals g
LEFT JOIN players p
  ON g.pid = p.player_id
GROUP BY player_name,player_id
HAVING COUNT(DISTINCT g.match_id) > 10
ORDER BY matches_scored DESC;

--6.What is the average number of goals scored per match in a given season?

SELECT m.season,
       AVG(goal_count) AS avg_goals_per_match
FROM (
    SELECT match_id,
           COUNT(*) AS goal_count
    FROM goals
    GROUP BY match_id
) g
JOIN matches m
  ON g.match_id = m.match_id
GROUP BY m.season;

--7.Which player has the most goals in a single match?

SELECT CONCAT(p.first_name, ' ', p.last_name) AS player_name,
       g.match_id,
       COUNT(*) AS goals_scored
FROM goals g
LEFT JOIN players p
  ON g.pid = p.player_id
GROUP BY player_name, g.match_id
ORDER BY goals_scored DESC
LIMIT 1;


--8.Which team scored the most goals in the all seasons?

SELECT team_id,
       COUNT(*) AS total_goals
FROM (
    SELECT m.home_team AS team_id
    FROM goals g
    JOIN matches m
      ON g.match_id = m.match_id
    UNION ALL
    SELECT m.away_team AS team_id
    FROM goals g
    JOIN matches m
      ON g.match_id = m.match_id
) t
GROUP BY team_id
ORDER BY total_goals DESC
LIMIT 1;

--9.Which stadium hosted the most goals scored in a single season?


SELECT s.name AS stadium_name,
       m.season,
       COUNT(*) AS total_goals
FROM goals g
JOIN matches m
  ON g.match_id = m.match_id
JOIN stadiums s
  ON m.stadium = s.name
GROUP BY s.name, m.season
ORDER BY total_goals DESC
LIMIT 1;

--MATCH ANALYSIS--

--10.What was the highest-scoring match in a particular season?

SELECT season, match_id, total_goals
FROM (
    SELECT m.season,
           m.match_id,
           COUNT(g.goal_id) AS total_goals,
           RANK() OVER (PARTITION BY m.season ORDER BY COUNT(g.goal_id) DESC) AS rnk
    FROM matches m
    JOIN goals g
      ON m.match_id = g.match_id
    GROUP BY m.season, m.match_id
) t
WHERE rnk = 1
ORDER BY season;

--11.How many matches ended in a draw in a given season?


SELECT season,
       COUNT(*) AS draw_matches
FROM matches
WHERE home_team_score = away_team_score
GROUP BY season
ORDER BY season;


--12.Which team had the highest average score (home and away) in the season 2021-2022?

SELECT team,
       AVG(goals_scored) AS avg_score
FROM (
    SELECT home_team AS team,
           home_team_score AS goals_scored
    FROM matches
    WHERE season = '2021-2022'

    UNION ALL

    SELECT away_team AS team,
           away_team_score AS goals_scored
    FROM matches
    WHERE season = '2021-2022'
) t
GROUP BY team
ORDER BY avg_score DESC
LIMIT 1;


--13.How many penalty shootouts occurred in a each season?

SELECT season,
       COUNT(*) AS penalty_shootouts
FROM matches
WHERE penalty_shoot_out = 1
GROUP BY season
ORDER BY season;


--14.What is the average attendance for home teams in the 2021-2022 season?


SELECT AVG(attendance) AS avg_attendance
FROM matches
WHERE season = '2021-2022';

--15.Which stadium hosted the most matches in a each season?

SELECT season, stadium, total_matches
FROM (
    SELECT season,
           stadium,
           COUNT(*) AS total_matches,
           RANK() OVER (PARTITION BY season ORDER BY COUNT(*) DESC) AS rnk
    FROM matches
    GROUP BY season, stadium
) t
WHERE rnk = 1
ORDER BY season;

--16.What is the distribution of matches played in different countries in a season?

SELECT m.season,
       s.country,
       COUNT(*) AS total_matches
FROM matches m
JOIN stadiums s
  ON m.stadium = s.name
GROUP BY m.season, s.country
ORDER BY m.season, total_matches DESC;

--17.What was the most common result in matches (home win, away win, draw)?

SELECT result,
       COUNT(*) AS total_matches
FROM (
    SELECT
        CASE
            WHEN home_team_score > away_team_score THEN 'Home Win'
            WHEN home_team_score < away_team_score THEN 'Away Win'
            ELSE 'Draw'
        END AS result
    FROM matches
) t
GROUP BY result
ORDER BY total_matches DESC
LIMIT 1;


--PLAYER ANALYSIS--

--18.Which players have the highest total goals scored (including assists)?

SELECT player,
       COUNT(*) AS total_contribution
FROM (
    SELECT pid AS player
    FROM goals
    WHERE pid IS NOT NULL

    UNION ALL

    SELECT assist AS player
    FROM goals
    WHERE assist IS NOT NULL
) t
GROUP BY player
ORDER BY total_contribution DESC
LIMIT 1;


--19.What is the average height and weight of players per position?

SELECT position,
       AVG(height) AS avg_height,
       AVG(weight) AS avg_weight
FROM players
GROUP BY position
ORDER BY position;

--20.Which player has the most goals scored with their left foot?

SELECT pid AS player,
       COUNT(*) AS left_foot_goals
FROM goals
WHERE goal_desc LIKE '%left-footed%'
GROUP BY pid
ORDER BY left_foot_goals DESC
LIMIT 1;

--21.What is the average age of players per team?

SELECT team,
       AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE,dob))) AS avg_age
FROM players
GROUP BY team
ORDER BY team;

--22.How many players are listed as playing for a each team in a season?

SELECT team,
       COUNT(*) AS total_players
FROM players
GROUP BY team
ORDER BY team;

--23.Which player has played in the most matches in the each season?

SELECT season, player, matches_played
FROM (
    SELECT m.season,
           g.pid AS player,
           COUNT(DISTINCT g.match_id) AS matches_played,
           RANK() OVER (PARTITION BY m.season ORDER BY COUNT(DISTINCT g.match_id) DESC) AS rnk
    FROM goals g
    JOIN matches m
      ON g.match_id = m.match_id
    GROUP BY m.season, g.pid
) t
WHERE rnk = 1
ORDER BY season;

--24.What is the most common position for players across all teams?

SELECT position,
       COUNT(*) AS total_players
FROM players
GROUP BY position
ORDER BY total_players DESC
LIMIT 1;

--25.Which players have never scored a goal?

SELECT p.player_id,
       CONCAT(p.first_name, ' ', p.last_name) AS player_name
FROM players p
WHERE p.player_id NOT IN (
    SELECT DISTINCT pid
    FROM goals
    WHERE pid IS NOT NULl);

--TEAM ANALYSIS--

--26.Which team has the largest home stadium in terms of capacity?

SELECT t.team_name,
       s.name AS stadium,
       s.capacity
FROM teams t
JOIN stadiums s
  ON t.home_stadium = s.name
ORDER BY s.capacity DESC
LIMIT 1;

--27.Which teams from a each country participated in the UEFA competition in a season?

SELECT DISTINCT m.season,
       t.country,
       t.team_name
FROM teams t
JOIN matches m
  ON t.team_name = m.home_team
     OR t.team_name = m.away_team
ORDER BY m.season, t.country;

--28.Which team scored the most goals across home and away matches in a given season?

SELECT team,
       SUM(goals) AS total_goals
FROM (
    SELECT home_team AS team,
           home_team_score AS goals
    FROM matches
    WHERE season = '2021-2022'
    UNION ALL
    SELECT away_team AS team,
           away_team_score AS goals
    FROM matches
    WHERE season = '2021-2022'
) t
GROUP BY team
ORDER BY total_goals DESC
LIMIT 1;

--29.How many teams have home stadiums in a each city or country?

SELECT s.country,
       COUNT(t.team_name) AS total_teams
FROM teams t
JOIN stadiums s
  ON t.home_stadium = s.name
GROUP BY s.country
ORDER BY total_teams DESC;

--30.Which teams had the most home wins in the 2021-2022 season?

SELECT home_team,
       COUNT(*) AS home_wins
FROM matches
WHERE season = '2021-2022'
  AND home_team_score > away_team_score
GROUP BY home_team
ORDER BY home_wins DESC
LIMIT 1;

--STADIUM ANALYSIS--

--31.Which stadium has the highest capacity?

SELECT name,
       capacity
FROM stadiums
ORDER BY capacity DESC
LIMIT 1;

--32.How many stadiums are located in a ‘Russia’ country or ‘London’ city?

SELECT COUNT(*) AS total_stadiums
FROM stadiums
WHERE country = 'Russia'
   OR city = 'London';

--33.Which stadium hosted the most matches during a season?

SELECT m.stadium,
       COUNT(*) AS total_matches
FROM matches m
WHERE season = '2021-2022'
GROUP BY m.stadium
ORDER BY total_matches DESC
LIMIT 1;

--34.What is the average stadium capacity for teams participating in a each season?

SELECT m.season,
       AVG(s.capacity) AS avg_capacity
FROM matches m
JOIN stadiums s
  ON m.stadium = s.name
GROUP BY m.season
ORDER BY m.season;

--35.How many teams play in stadiums with a capacity of more than 50,000?

SELECT COUNT(*) AS total_teams
FROM teams t
JOIN stadiums s
  ON t.home_stadium = s.name
WHERE s.capacity > 50000;

--36.Which stadium had the highest attendance on average during a season?

SELECT m.stadium,
       AVG(m.attendance) AS avg_attendance
FROM matches m
WHERE season = '2021-2022'
GROUP BY m.stadium
ORDER BY avg_attendance DESC
LIMIT 1;

--37.What is the distribution of stadium capacities by country?

SELECT country,
       COUNT(*) AS total_stadiums,
       AVG(capacity) AS avg_capacity
FROM stadiums
GROUP BY country
ORDER BY country;


--38.Which players scored the most goals in matches held at a specific stadium?

SELECT g.pid,
       COUNT(*) AS total_goals
FROM goals g
JOIN matches m
  ON g.match_id = m.match_id
WHERE m.stadium = 'Wembley Stadium'
GROUP BY g.pid
ORDER BY total_goals DESC
LIMIT 1;

--39.Which team won the most home matches in the season 2021-2022 (based on match scores)?

SELECT home_team,
       COUNT(*) AS home_wins
FROM matches
WHERE season = '2021-2022'
  AND home_team_score > away_team_score
GROUP BY home_team
ORDER BY home_wins DESC
LIMIT 1;

--40.Which players played for a team that scored the most goals in the 2021-2022 season?

SELECT team
FROM (
    SELECT home_team AS team, SUM(home_team_score) AS goals
    FROM matches
    WHERE season = '2021-2022'
    GROUP BY home_team
    UNION ALL
    SELECT away_team AS team, SUM(away_team_score)
    FROM matches
    WHERE season = '2021-2022'
    GROUP BY away_team
) t
GROUP BY team
ORDER BY SUM(goals) DESC
LIMIT 1;


--41.How many goals were scored by home teams in matches where the attendance was above 50,000?

SELECT SUM(home_team_score) AS total_home_goals
FROM matches
WHERE attendance > 50000;

--42.Which players played in matches where the score difference (home team score - away team score) was the highest?

SELECT DISTINCT g.pid
FROM goals g
JOIN matches m
  ON g.match_id = m.match_id
WHERE ABS(m.home_team_score - m.away_team_score) = (
    SELECT MAX(ABS(home_team_score - away_team_score))
    FROM matches
);

--43.How many goals did players score in matches that ended in penalty shootouts?

SELECT COUNT(*) AS total_goals
FROM goals g
JOIN matches m
  ON g.match_id = m.match_id
WHERE m.penalty_shoot_out = 1;

--44.What is the distribution of home team wins vs away team wins by country for all seasons?

SELECT s.country,
       SUM(CASE WHEN m.home_team_score > m.away_team_score THEN 1 ELSE 0 END) AS home_wins,
       SUM(CASE WHEN m.away_team_score > m.home_team_score THEN 1 ELSE 0 END) AS away_wins
FROM matches m
JOIN stadiums s
  ON m.stadium = s.name
GROUP BY s.country;

--45.Which team scored the most goals in the highest-attended matches?

SELECT team,
       SUM(goals) AS total_goals
FROM (
    SELECT home_team AS team,
           home_team_score AS goals
    FROM matches
    WHERE attendance = (SELECT MAX(attendance) FROM matches)
    UNION ALL
    SELECT away_team,
           away_team_score
    FROM matches
    WHERE attendance = (SELECT MAX(attendance) FROM matches)
) t
GROUP BY team
ORDER BY total_goals DESC
LIMIT 1;

--46.Which players assisted the most goals in matches where their team lost(you can include 3)?

SELECT g.assist AS player_id,
       COUNT(*) AS total_assists
FROM goals g
JOIN matches m
  ON g.match_id = m.match_id
WHERE g.assist IS NOT NULL
  AND (
      (m.home_team_score < m.away_team_score)
      OR
      (m.away_team_score < m.home_team_score)
  )
GROUP BY g.assist
ORDER BY total_assists DESC
LIMIT 3;

--47.What is the total number of goals scored by players who are positioned as defenders?

SELECT COUNT(*) AS total_goals
FROM goals g
JOIN players p
  ON g.pid = p.player_id
WHERE p.position = 'Defender';

--48.Which players scored goals in matches that were held in stadiums with a capacity over 60,000?

SELECT DISTINCT g.pid
FROM goals g
JOIN matches m
  ON g.match_id = m.match_id
JOIN stadiums s
  ON m.stadium = s.name
WHERE s.capacity > 60000;

--49.How many goals were scored in matches played in cities with specific stadiums in a season?

SELECT COUNT(*) AS total_goals
FROM goals g
JOIN matches m
  ON g.match_id = m.match_id
JOIN stadiums s
  ON m.stadium = s.name
WHERE s.city = 'London'
  AND m.season = '2021-2022';


--50.Which players scored goals in matches with the highest attendance (over 100,000)?


SELECT DISTINCT g.pid
FROM goals g
JOIN matches m
  ON g.match_id = m.match_id
WHERE m.attendance > 100000;


--ADDITIONAL COMPLEX QUERIES COMBINING MULTIPLE ASPECTS


--51.What is the average number of goals scored by each team in the first 30 minutes of a match?

SELECT p.team,
       AVG(team_goals) AS avg_goals_first_30
FROM (
    SELECT g.match_id,
           p.team,
           COUNT(*) AS team_goals
    FROM goals g
    JOIN players p
      ON g.pid = p.player_id
    WHERE g.duration <= 30
    GROUP BY g.match_id, p.team
) t
GROUP BY p.team;

--52.Which stadium had the highest average score difference between home and away teams?

SELECT stadium,
       AVG(ABS(home_team_score - away_team_score)) AS avg_score_diff
FROM matches
GROUP BY stadium
ORDER BY avg_score_diff DESC
LIMIT 1;


--53.How many players scored in every match they played during a given season?

SELECT g.pid
FROM goals g
JOIN matches m
  ON g.match_id = m.match_id
WHERE m.season = '2021-2022'
GROUP BY g.pid
HAVING COUNT(DISTINCT g.match_id) = (
    SELECT COUNT(DISTINCT m.match_id)
    FROM goals g2
    JOIN matches m2
      ON g2.match_id = m2.match_id
    WHERE g2.pid = g.pid
      AND m2.season = '2021-2022');

--54.Which teams won the most matches with a goal difference of 3 or more in the 2021-2022 season?

SELECT home_team AS team,
       COUNT(*) AS big_wins
FROM matches
WHERE season = '2021-2022'
  AND home_team_score - away_team_score >= 3
GROUP BY home_team
ORDER BY big_wins DESC
LIMIT 1;

--55.Which player from a specific country has the highest goals per match ratio?

SELECT p.player_id,
       ROUND(
           COUNT(g.goal_id)::numeric / COUNT(DISTINCT g.match_id),
           2
       ) AS goals_per_match
FROM players p
JOIN goals g
  ON p.player_id = g.pid
JOIN teams t
  ON p.team = t.team_name
WHERE t.country = 'England'
GROUP BY p.player_id
ORDER BY goals_per_match DESC
LIMIT 1;

