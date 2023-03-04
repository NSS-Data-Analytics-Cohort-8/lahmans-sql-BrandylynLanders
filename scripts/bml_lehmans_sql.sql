SELECT *
FROM teams
--Data validation--is super important in this project
--Intial steps should be to read the data dictionary and go over the schema and understand it. 

--1. What range of years for baseball games played does the provided database cover? 
SELECT COUNT(DISTINCT yearid) AS num_years, MIN(yearid) AS min_year, MAX(yearid) AS max_year
FROM teams; 
--146 years

--2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
SELECT namegiven, height
FROM people
WHERE height = (SELECT MIN(height) FROM people)
----edward carl--------now I need to see how many games he played in and what team he played for
SELECT p.namegiven, p.height, a.teamid, COUNT(a.g_all) AS games_played
FROM people p
INNER JOIN appearances a ON p.playerid = a.playerid
WHERE p.height = (SELECT MIN(height) FROM people)
GROUP BY p.namegiven, p.height, a.teamid;
--"Edward Carl"	43	"SLA"	1----------------------------------------------------------------------------

--3.Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
SELECT playerid, SUM(salary)
FROM SALARIES
GROUP BY playerid
ORDER BY SUM(salary) DESC;

SELECT p.playerid,p.namefirst,p.namelast,c.schoolid
FROM people AS p
INNER JOIN collegeplaying AS c
ON 	p.playerid=c.playerid
WHERE schoolid LIKE '%vandy%'
--tested a standard query and a subquery and then joined them below---------------
SELECT DISTINCT p.playerid,p.namefirst, p.namelast, subquery.total_salary
FROM people AS p
INNER JOIN collegeplaying AS c ON p.playerid = c.playerid
INNER JOIN (
  SELECT playerid, SUM(salary) AS total_salary
  FROM salaries
  GROUP BY playerid
) AS subquery ON p.playerid = subquery.playerid
WHERE c.schoolid LIKE '%vandy%'
ORDER BY subquery.total_salary DESC;
------David Price @ 81,851,296------------------------------------------------------

SELECT DISTINCT p.playerid, p.namefirst, p.namelast, SUM(s.salary) AS total_salary
FROM people AS p
INNER JOIN salaries AS s ON p.playerid = s.playerid
GROUP BY p.playerid, p.namefirst, p.namelast
ORDER BY total_salary DESC
LIMIT 25;
---top 25 earners just for grins---------------------------------------------------

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
SELECT 
CASE 
    WHEN Pos = 'OF' THEN 'Outfield' 
    WHEN Pos IN ('SS', '1B', '2B', '3B') THEN 'Infield' 
    WHEN Pos IN ('P', 'C') THEN 'Battery' END AS Position_Group, 
SUM(PO) AS Total_Putouts
FROM fielding 
WHERE yearID = 2016
GROUP BY Position_Group;
---------------run query for answer----------------------------------------------------
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
SELECT 
  CONCAT(CAST((yearID/10)*10 AS CHAR(4)), '-', CAST((yearID/10)*10+9 AS CHAR(4))) AS Decade, 
  ROUND(AVG(SO/G), 2) AS Average_Strikeouts_Per_Game
FROM pitching
WHERE yearID >= 1920
GROUP BY (yearID/10)
ORDER BY Decade;
---two ways to solve this date dilemma---
SELECT 
  CONCAT(FLOOR(yearID/10)*10, '-', FLOOR(yearID/10)*10+9) AS Decade, 
  ROUND(AVG(SO/G), 2) AS Average_Strikeouts_Per_Game
FROM pitching
WHERE yearID >= 1920
GROUP BY FLOOR(yearID/10)
ORDER BY Decade;

--Do the same for home runs per game. Do you see any trends?
SELECT 
  CONCAT(CAST((yearID/10)*10 AS CHAR(4)), '-', CAST((yearID/10)*10+9 AS CHAR(4))) AS Decade, 
  ROUND(AVG(HR/G), 2) AS Average_Home_Runs_Per_Game
FROM batting
WHERE yearID >= 1920
GROUP BY (yearID/10)
ORDER BY Decade;
------results on this query were questionable so I am going to inspect the data------
SELECT playerID, HR, G
FROM batting
GROUP BY playerID, HR, G
ORDER BY HR DESC
---------------------------------------------------------------------------------------
--Trying it a different way----------------
SELECT 
  batting.yearID, 
  SUM(batting.G) AS Total_Games_Played,
  SUM(batting.HR) AS Total_Home_Runs,
  ROUND(AVG(batting.HR/batting.G), 10) AS Average_Home_Runs_Per_Game
FROM batting
WHERE batting.yearID >= 1920
GROUP BY batting.yearID
ORDER BY batting.yearID;
---revised to show average homeruns per game without considering how many games were played-------
SELECT 
  CONCAT(CAST((yearID/10)*10 AS CHAR(4)), '-', CAST((yearID/10)*10+9 AS CHAR(4))) AS Decade, 
  ROUND(AVG(HR), 2) AS Average_Home_Runs_Per_Year
FROM batting
WHERE yearID >= 1920
GROUP BY (yearID/10)
ORDER BY Decade;
---the trend we were asked to observe is the fact that they are ever increasing

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
---below with CAST-------------------------------------------------------------------------------------
SELECT 
  subquery.playerID, 
  subquery.Stolen_Bases, 
  subquery.Caught_Stealing, 
  ROUND(CAST(subquery.Stolen_Bases AS NUMERIC)/CAST(subquery.Stolen_Bases+subquery.Caught_Stealing AS NUMERIC), 3) AS Success_Rate
FROM (
  SELECT 
    playerID, 
    SUM(SB) AS Stolen_Bases, 
    SUM(CS) AS Caught_Stealing
  FROM batting
  WHERE yearID = 2016 AND SB+CS >= 20
  GROUP BY playerID
) AS subquery
ORDER BY Success_Rate DESC
LIMIT 5;  --"owingch01"	21	2	0.913--
--below without CAST------------------------BIG DIFFERENCE---------------------------
SELECT 
  playerID, 
  SUM(SB) AS Stolen_Bases, 
  SUM(CS) AS Caught_Stealing, 
  ROUND(SUM(SB)/NULLIF(SUM(SB+CS), 0), 3) AS Success_Rate
FROM batting
WHERE yearID = 2016 AND SB+CS >= 20
GROUP BY playerID
ORDER BY Success_Rate DESC
LIMIT 5;

--FOR ENTERTAINMENT WHICH COLLEGES PRODUCED THE MAJORITY OF PLAYERS-----------
SELECT 
  schoolName, 
  COUNT(DISTINCT playerID) AS Player_Count 
FROM schools 
INNER JOIN collegeplaying ON schools.schoolID = collegeplaying.schoolID 
GROUP BY schoolName 
ORDER BY Player_Count DESC 
LIMIT 10;
----------------FUNS OVER-----BACK TO WORK

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

SELECT DISTINCT teamid,name, MAX(W) AS Max_Wins 
FROM teams 
WHERE yearID BETWEEN 1970 AND 2016 AND W < (SELECT MAX(W) FROM teams WHERE yearID BETWEEN 1970 AND 2016 AND WSWin='N')
GROUP BY teamid, name
ORDER BY max_wins DESC
-----114 wins by NYA---------

SELECT DISTINCT teamid,name, MIN(W) AS MIN_Wins 
FROM teams 
WHERE yearID BETWEEN 1970 AND 2016 AND W < (SELECT MIN(W) FROM teams WHERE yearID BETWEEN 1970 AND 2016 AND WSWin='Y')
GROUP BY teamid, name
ORDER BY min_wins ASC;

SELECT DISTINCT teamid, name, MIN(W) AS MIN_Wins 
FROM teams 
WHERE yearID BETWEEN 1970 AND 2016 AND WSWin='Y'
GROUP BY teamid, name
ORDER BY min_wins ASC
-IMIT 1;
----------------below excludes the problem year of 1981--------------player strike--------------
SELECT DISTINCT teamid,name, MAX(W) AS Max_Wins 
FROM teams 
WHERE yearID BETWEEN 1970 AND 2016 AND yearID != 1981 AND W < (SELECT MAX(W) FROM teams WHERE yearID BETWEEN 1970 AND 2016 AND WSWin='N' AND yearID != 1981)
GROUP BY teamid, name
ORDER BY max_wins DESC;

SELECT DISTINCT teamid, name, MIN(W) AS MIN_Wins 
FROM teams 
WHERE yearID BETWEEN 1970 AND 2016 AND yearID != 1981 AND W < (SELECT MIN(W) FROM teams WHERE yearID BETWEEN 1970 AND 2016 AND WSWin='Y' AND yearID != 1981)
GROUP BY teamid, name
ORDER BY min_wins ASC;

SELECT DISTINCT teamid, name, MIN(W) AS MIN_Wins 
FROM teams 
WHERE yearID BETWEEN 1970 AND 2016 AND yearID != 1981 AND WSWin='Y'
GROUP BY teamid, name
ORDER BY min_wins ASC
LIMIT 1;
-----determining how often from 1970-2016 the team with the most wins won the WS-----------------
SELECT COUNT(*) AS num_champs
FROM (
  SELECT teamid, MAX(W) AS max_wins
  FROM teams
  WHERE yearID BETWEEN 1970 AND 2016 AND yearID != 1981 AND WSWin='Y'
  GROUP BY teamid
) AS champ_wins
JOIN (
  SELECT MAX(W) AS max_wins
  FROM teams
  WHERE yearID BETWEEN 1970 AND 2016 AND yearID != 1981 AND WSWin='N'
) AS non_champ_wins
ON champ_wins.max_wins = non_champ_wins.max_wins;
---------------------------0-----------------------------------------------------------------------
-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


