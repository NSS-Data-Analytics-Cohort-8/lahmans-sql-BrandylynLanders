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
JOIN appearances a ON p.playerid = a.playerid
WHERE p.height = (SELECT MIN(height) FROM people)
GROUP BY p.namegiven, p.height, a.teamid;
--"Edward Carl"	43	"SLA"	1---------------------------------------------------------