-- In these exercises, you'll explore a couple of other advanced features of PostgreSQL. 
--------------------------------------------------------------------------------
-- 1. In this question, you'll get to practice correlated subqueries and learn about the LATERAL keyword. Note: This could be done using window functions, but we'll do it in a different way in order to revisit correlated subqueries and see another keyword - LATERAL.

-- a. First, write a query utilizing a correlated subquery to find the team with the most wins from each league in 2016.

--If you need a hint, you can structure your query as follows:

SELECT DISTINCT lgid, ( <Write a correlated subquery here that will pull the teamid for the team with the highest number of wins from each league> )
FROM teams t
WHERE yearid = 2016;


SELECT 
    DISTINCT lgid, 
    (SELECT 
        name
        FROM teams t2
        WHERE t2.lgid = t.lgid
        AND t2.yearid = 2016
        ORDER BY w DESC
        LIMIT 1
        )
FROM teams t
WHERE yearid = 2016;


-- b. One downside to using correlated subqueries is that you can only return exactly one row and one column. This means, for example that if we wanted to pull in not just the teamid but also the number of wins, we couldn't do so using just a single subquery. (Try it and see the error you get). Add another correlated subquery to your query on the previous part so that your result shows not just the teamid but also the number of wins by that team.


SELECT 
    DISTINCT lgid, 
    (SELECT 
        name
        FROM teams t2
        WHERE t2.lgid = t.lgid
        AND t2.yearid = 2016
        ORDER BY w DESC
        LIMIT 1
        ),
    (SELECT 
        w
        FROM teams t3
        WHERE t3.lgid = t.lgid
        AND t3.yearid = 2016
        ORDER BY w DESC
        LIMIT 1
    )
FROM teams t
WHERE yearid = 2016;


-- c. If you are interested in pulling in the top (or bottom) values by group, you can also use the DISTINCT ON expression (https://www.postgresql.org/docs/9.5/sql-select.html#SQL-DISTINCT). Rewrite your previous query into one which uses DISTINCT ON to return the top team by league in terms of number of wins in 2016. Your query should return the league, the teamid, and the number of wins.

SELECT 
    DISTINCT ON (lgid) lgid,
    name,
    w
FROM teams t
WHERE yearid = 2016
ORDER BY lgid, w DESC;


-- d. If we want to pull in more than one column in our correlated subquery, another way to do it is to make use of the LATERAL keyword (https://www.postgresql.org/docs/9.4/queries-table-expressions.html#QUERIES-LATERAL). This allows you to write subqueries in FROM that make reference to columns from previous FROM items. This gives us the flexibility to pull in or calculate multiple columns or multiple rows (or both). Rewrite your previous query using the LATERAL keyword so that your result shows the teamid and number of wins for the team with the most wins from each league in 2016. 



SELECT *
FROM (SELECT DISTINCT lgid 
	  FROM teams
	  WHERE yearid = 2016) AS leagues,
	  LATERAL (
        SELECT name, w
        FROM teams
        WHERE yearid = 2016
            AND lgid = leagues.lgid
        ORDER BY w DESC
        LIMIT 1
       ) as top_teams
ORDER BY w DESC;



-- If you want a hint, you can structure your query as follows:

SELECT *
FROM (SELECT DISTINCT lgid 
	  FROM teams
	  WHERE yearid = 2016) AS leagues,
	  LATERAL ( <Fill in a subquery here to retrieve the teamid and number of wins> ) as top_teams;
	  
-- e. Finally, another advantage of the LATERAL keyword over using correlated subqueries is that you return multiple result rows. (Try to return more than one row in your correlated subquery from above and see what type of error you get). Rewrite your query on the previous problem sot that it returns the top 3 teams from each league in term of number of wins. Show the teamid and number of wins.

SELECT *
FROM (SELECT DISTINCT lgid 
	  FROM teams
	  WHERE yearid = 2016) AS leagues,
	  LATERAL (
        SELECT name, w
        FROM teams
        WHERE yearid = 2016
            AND lgid = leagues.lgid
        ORDER BY w DESC
        LIMIT 3
       ) as top_teams
ORDER BY w DESC;

--------------------------------------------------------------------------------
-- 2. Another advantage of lateral joins is for when you create calculated columns. In a regular query, when you create a calculated column, you cannot refer it it when you create other calculated columns. This is particularly useful if you want to reuse a calculated column multiple times. For example,

SELECT 
	teamid,
	w,
	l,
	w + l AS total_games,
	w*100.0 / total_games AS winning_pct
FROM teams
WHERE yearid = 2016
ORDER BY winning_pct DESC;

-- results in the error that "total_games" does not exist. However, I can restructure this query using the LATERAL keyword.

SELECT
	teamid,
	w,
	l,
	total_games,
	w*100.0 / total_games AS winning_pct
FROM teams t,
LATERAL (
	SELECT w + l AS total_games
) AS tg
WHERE yearid = 2016
ORDER BY winning_pct DESC;

-- a. Write a query which, for each player in the player table, assembles their birthyear, birthmonth, and birthday into a single column called birthdate which is of the date type.

SELECT
    namefirst||' '||namelast AS playername,
    CAST(birthyear||'-'||birthmonth||'-'||birthday AS TEXT)::DATE AS birthdate
FROM people AS p 
GROUP BY playerid;


-- b. Use your previous result inside a subquery using LATERAL to calculate for each player their age at debut and age at retirement. (Hint: It might be useful to check out the PostgreSQL date and time functions https://www.postgresql.org/docs/8.4/functions-datetime.html).

SELECT 
    p.playerid, 
    dates.playername,
    dates.birthdate,
    dates.debut_date,
    EXTRACT(YEAR FROM AGE(dates.debut_date, dates.birthdate)) AS age_at_debut,
    EXTRACT(YEAR FROM AGE(dates.retirement_date, dates.birthdate)) AS age_at_retirement
FROM people p,
LATERAL (
    SELECT
        namefirst||' '||namelast AS playername,
        CAST(birthyear||'-'||birthmonth||'-'||birthday AS DATE) AS birthdate,
        debut::DATE AS debut_date,
        finalgame::DATE AS retirement_date
    FROM people 
    WHERE playerid = p.playerid
        AND birthyear IS NOT NULL 
        AND birthmonth IS NOT NULL 
        AND birthday IS NOT NULL 
        AND debut IS NOT NULL
        AND finalgame IS NOT NULL
    LIMIT 1
) dates;






-- c. Who is the youngest player to ever play in the major leagues?

-- Joe Nuxhall debuted at 15 years old, and retired at 38 years old. 

SELECT 
    p.playerid, 
    dates.playername,
    dates.birthdate,
    dates.debut_date,
    EXTRACT(YEAR FROM AGE(dates.debut_date, dates.birthdate)) AS age_at_debut,
    EXTRACT(YEAR FROM AGE(dates.retirement_date, dates.birthdate)) AS age_at_retirement
FROM people p,
LATERAL (
    SELECT
        namefirst||' '||namelast AS playername,
        CAST(birthyear||'-'||birthmonth||'-'||birthday AS DATE) AS birthdate,
        debut::DATE AS debut_date,
        finalgame::DATE AS retirement_date
    FROM people 
    WHERE playerid = p.playerid
        AND birthyear IS NOT NULL 
        AND birthmonth IS NOT NULL 
        AND birthday IS NOT NULL 
        AND debut IS NOT NULL
        AND finalgame IS NOT NULL
    LIMIT 1
) dates
ORDER BY age_at_debut
LIMIT 1;
-- d. Who is the oldest player to player in the major leagues? You'll likely have a lot of null values resulting in your age at retirement calculation. Check out the documentation on sorting rows here https://www.postgresql.org/docs/8.3/queries-order.html about how you can change how null values are sorted.

-- Satchel Paige retired at 59 years old
SELECT 
    p.playerid, 
    dates.playername,
    dates.birthdate,
    dates.debut_date,
    EXTRACT(YEAR FROM AGE(dates.debut_date, dates.birthdate)) AS age_at_debut,
    EXTRACT(YEAR FROM AGE(dates.retirement_date, dates.birthdate)) AS age_at_retirement
FROM people p,
LATERAL (
    SELECT
        namefirst||' '||namelast AS playername,
        CAST(birthyear||'-'||birthmonth||'-'||birthday AS DATE) AS birthdate,
        debut::DATE AS debut_date,
        finalgame::DATE AS retirement_date
    FROM people 
    WHERE playerid = p.playerid
        AND birthyear IS NOT NULL 
        AND birthmonth IS NOT NULL 
        AND birthday IS NOT NULL 
        AND debut IS NOT NULL
        AND finalgame IS NOT NULL
    LIMIT 1
) dates
ORDER BY age_at_retirement DESC;


--------------------------------------------------------------------------------
-- 3. For this question, you will want to make use of RECURSIVE CTEs (see https://www.postgresql.org/docs/13/queries-with.html). The RECURSIVE keyword allows a CTE to refer to its own output. Recursive CTEs are useful for navigating network datasets such as social networks, logistics networks, or employee hierarchies (who manages who and who manages that person). To see an example of the last item, see this tutorial: https://www.postgresqltutorial.com/postgresql-recursive-query/. 
-- In the next couple of weeks, you'll see how the graph database Neo4j can easily work with such datasets, but for now we'll see how the RECURSIVE keyword can pull it off (in a much less efficient manner) in PostgreSQL. (Hint: You might find it useful to look at this blog post when attempting to answer the following questions: https://data36.com/kevin-bacon-game-recursive-sql/.)

-- a. Willie Mays holds the record of the most All Star Game starts with 18. How many players started in an All Star Game with Willie Mays? (A player started an All Star Game if they appear in the allstarfull table with a non-null startingpos value).

-- b. How many players didn't start in an All Star Game with Willie Mays but started an All Star Game with another player who started an All Star Game with Willie Mays? For example, Graig Nettles never started an All Star Game with Willie Mayes, but he did star the 1975 All Star Game with Blue Vida who started the 1971 All Star Game with Willie Mays.

-- c. We'll call two players connected if they both started in the same All Star Game. Using this, we can find chains of players. For example, one chain from Carlton Fisk to Willie Mays is as follows: Carlton Fisk started in the 1973 All Star Game with Rod Carew who started in the 1972 All Star Game with Willie Mays. Find a chain of All Star starters connecting Babe Ruth to Willie Mays. 

-- d. How large a chain do you need to connect Derek Jeter to Willie Mays?