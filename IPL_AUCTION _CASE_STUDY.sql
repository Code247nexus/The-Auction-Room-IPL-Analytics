-- =====================================================================
--  THE AUCTION ROOM: an IPL data case study in SQL
--  Author : Aditya Jha
--  Table  : ipl_data  (ball-by-ball IPL data, one row per delivery)
--  Needs  : MySQL 8.0+  (CTEs and window functions)
-- =====================================================================
--
--  THE SITUATION
--  A franchise owner is about to walk into the IPL auction. The purse
--  is limited, every squad spot matters, and a wrong bid on a player
--  is hard to undo. The owner does not want opinions, they want
--  numbers. I am the analyst sitting next to them with this dataset.
--
--  THE QUESTIONS THE OWNER ASKED ME
--    1. What does the league look like, and how do teams score?
--    2. Which batters are worth bidding for?
--    3. Which bowlers are worth bidding for?
--    4. Who are we up against, and where do matches get decided?
--    5. Give me one final list I can take into the room.


--  HOW I ANSWER THEM
--  20 SQL queries in five acts. Each one starts with the owner's
--  question and ends with the decision it supports. Tools used:
--  aggregation, CASE, WHERE, GROUP BY, HAVING, CTEs, subqueries,
--  and window functions including RANK() and ROW_NUMBER().
--
--  WHAT THE DATA CAN'T TELL ME
--  This is delivery data only. There is no player price, age, pace or
--  spin split, no match result and no season column. So the analysis
--  shows how players performed, not what they will cost or whether
--  they will fit the budget. The owner has to match my shortlist
--  against the auction price sheet.
--
--  Columns I use:
--    ID (match id), innings, overs (0-19), ballnumber, batter, bowler,
--    extra_type, batsman_run, extras_run, total_run, non_boundary,
--    isWicketDelivery, player_out, kind (dismissal type), BattingTeam
--  Run  DESCRIBE ipl_data;  first and rename anything that differs.
-- =====================================================================
-- Setup
USE ipl;

UPDATE ipl_data SET extra_type = NULL WHERE extra_type IN ('NaN', '');
UPDATE ipl_data SET player_out = NULL WHERE player_out IN ('NaN', '');
UPDATE ipl_data SET kind       = NULL WHERE kind IN ('NaN', '');

SELECT COUNT(*) AS total_rows FROM ipl_data;



-- =====================================================================
--  ACT 1: KNOW THE LEAGUE
--  Before bidding on anyone, the owner needs to know what normal looks
--  like: how much teams score, when, and how.
-- =====================================================================

 -- KPI 1: League overview
-- Owner asks : "How big is this data? Can I trust what it says?"
-- Decision   : If the data covers a good number of matches, the numbers
--              below are solid enough to bid on.

SELECT COUNT(*)AS total_deliveries,
COUNT(DISTINCT ID) AS total_matches,
COUNT(DISTINCT batter) AS total_batters,
COUNT(DISTINCT bowler) AS total_bowlers,
SUM(total_run) AS total_runs,
SUM(isWicketDelivery) AS total_wickets
FROM ipl_data;



-- KPI 2: What each franchise scores per match
-- Owner asks : "How many runs do my rivals put up? What is the bar?"
-- Decision   : Sets the scoring benchmark my batting line-up has to beat.

SELECT BattingTeam,COUNT(DISTINCT ID) AS matches_played,
SUM(total_run) AS total_runs,ROUND(SUM(total_run) / COUNT(DISTINCT ID), 1) AS runs_per_match
FROM ipl_data
GROUP BY BattingTeam
ORDER BY runs_per_match DESC;


-- KPI 3: Dot ball percentage in every over
-- Owner asks : "In which overs do batters struggle to score?"
-- Decision   : Overs with lots of dot balls are where bowlers build
--              pressure. They also show where I need batters who
--              can rotate the strike.
-- (a dot ball = a delivery with zero runs of any kind)

SELECT overs + 1 AS over_number,COUNT(*)  AS deliveries,
ROUND(SUM(CASE WHEN total_run = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS dot_ball_pct
FROM ipl_data
GROUP BY overs
ORDER BY overs;
 
 

-- KPI 4: Rank franchises by average runs per match
-- Owner asks : "Which franchises have the highest scoring average?"
-- Level      : Moderate | Uses: CTE, AVG, GROUP BY, RANK()
-- Decision   : Helps compare franchise scoring output and identify
--              teams with strong batting performance.

WITH team_scores AS (SELECT BattingTeam,ID,SUM(total_run) AS total_runs
    FROM ipl_data
    GROUP BY BattingTeam, ID),
team_average AS (SELECT BattingTeam,ROUND(AVG(total_runs), 2) AS avg_runs_per_match
    FROM team_scores
    GROUP BY BattingTeam
)
SELECT BattingTeam,avg_runs_per_match,
RANK() OVER (ORDER BY avg_runs_per_match DESC) AS team_rank
FROM team_average
ORDER BY team_rank;

 
-- KPI 5: How much of a team's score comes from boundaries
-- Owner asks : "Do teams score by hitting or by running?"
-- Decision   : A high boundary share means the line-up leans on power
--              hitters, so I know how much hitting I need to buy.
SELECT BattingTeam,
SUM(batsman_run) AS bat_runs,
SUM(CASE WHEN batsman_run IN (4, 6) AND non_boundary = 0 THEN batsman_run ELSE 0 END) AS boundary_runs,
ROUND(SUM(CASE WHEN batsman_run IN (4, 6) AND non_boundary = 0 THEN batsman_run ELSE 0 END)* 100.0 / SUM(batsman_run), 2) AS boundary_pct
FROM ipl_data
GROUP BY BattingTeam
ORDER BY boundary_pct DESC;
 
 
-- =====================================================================
--  ACT 2: THE BATTERS
--  Now the first shopping list. Not every top scorer is a good buy,
--  so I look at volume, speed, power and consistency separately.
-- =====================================================================
 
-- KPI 6: Top 10 run scorers
-- Owner asks : "Who has scored the most runs?"
-- Level      : Easy | Uses: GROUP BY, ORDER BY, LIMIT
-- Decision   : The obvious names. Good starting list, but runs alone can
--              hide slow scoring, which the next queries check.
-- (batsman_run only, so extras are not given to the batter)
SELECT batter,SUM(batsman_run) AS total_runs
FROM ipl_data
GROUP BY batter
ORDER BY total_runs DESC
LIMIT 10;
 
 
-- KPI 7: Top 10 six hitters (and their fours)
-- Owner asks : "Who clears the ropes?"
-- Decision   : Finisher shortlist. Sixes win close matches.
-- non_boundary = 1 means the 4 was run (or came off an overthrow), so
-- a four is only counted when it is 0.

SELECT batter,SUM(CASE WHEN batsman_run = 6 THEN 1 ELSE 0 END) AS sixes,
SUM(CASE WHEN batsman_run = 4 AND non_boundary = 0 THEN 1 ELSE 0 END) AS fours
FROM ipl_data
GROUP BY batter
ORDER BY sixes DESC
LIMIT 10;
 
 
-- KPI 8: Best strike rates (minimum 150 balls faced)
-- Owner asks : "Who scores fast, not just a lot?"
-- Level      : Moderate | Uses: HAVING
-- Decision   : Separates quick scorers from players who just stayed in
--              for years. The 150-ball minimum keeps a 10-ball cameo
--              from topping the list.
-- Balls faced = every delivery except wides.
SELECT batter,SUM(batsman_run) AS runs,
COUNT(*) AS balls_faced,ROUND(SUM(batsman_run) * 100.0 / COUNT(*), 2) AS strike_rate
FROM ipl_data
WHERE extra_type IS NULL OR extra_type <> 'wides'
GROUP BY batter
HAVING COUNT(*) >= 150
ORDER BY strike_rate DESC
LIMIT 10;

-- KPI 9: Fifties and hundreds per batter
-- Owner asks : "Who turns starts into big scores?"
-- Level      : Moderate-Hard | Uses: CTE, CASE
-- Decision   : Consistency check. A player with many fifties is safer
--              money than one with a single lucky hundred.
-- A fifty = 50-99 runs in a match, a hundred = 100 or more.
WITH match_scores AS (SELECT ID, batter, SUM(batsman_run) AS runs
						FROM ipl_data
						GROUP BY ID, batter)
SELECT batter,(SELECT COUNT(*) FROM match_scores 
				AS m2 WHERE m2.batter = m1.batter
				AND m2.runs BETWEEN 50 AND 99) AS fifties,
          (SELECT COUNT(*) FROM match_scores AS m2 WHERE m2.batter = m1.batter AND m2.runs >= 100) AS hundreds,
    MAX(runs) AS best_score
FROM match_scores AS m1
GROUP BY batter
HAVING fifties + hundreds > 0
ORDER BY hundreds DESC, fifties DESC
LIMIT 10;


-- KPI 10: Biggest individual scores in a single match
-- Owner asks : "Who can win a game on their own?"
-- Level      : Moderate | Uses: CTE
-- Decision   : Match-winner list. Step 1 adds up each batter's runs per
--              match, step 2 picks the biggest ones.
WITH match_scores AS (SELECT ID AS match_id,batter,
        BattingTeam,SUM(batsman_run) AS runs
    FROM ipl_data
    GROUP BY ID, batter, BattingTeam
)
SELECT *
FROM match_scores
ORDER BY runs DESC
LIMIT 10;
 
-- =====================================================================
--  ACT 3: THE BOWLERS
--  Bowling wins tournaments, and good bowlers go for big money. So I
--  check who takes wickets, who stays cheap, and who wins matches.
-- =====================================================================
 

-- KPI 11: Top 10 bowler-credited wicket takers
-- Owner asks : "Which bowlers take the most wickets?"
-- Level      : Easy | Uses: WHERE, IN, GROUP BY, ORDER BY
-- Decision   : Identifies bowlers with the highest number of
--              dismissals credited to their bowling.

SELECT bowler,COUNT(*) AS wickets
FROM ipl_data
WHERE isWicketDelivery = 1 AND kind IN ('bowled','caught','caught and bowled','lbw','stumped','hit wicket')
GROUP BY bowler
ORDER BY wickets DESC
LIMIT 10;

-- KPI 12: How wickets actually fall
-- Owner asks : "What kind of dismissals should I plan around?"
-- Level      : Moderate | Uses: window function over an aggregate
-- Decision   : If most wickets are catches, fielding quality matters as
--              much as bowling. SUM(COUNT(*)) OVER () puts the grand
--              total next to every row, so the percentage needs no
--              second query.
SELECT kind AS dismissal_type,COUNT(*) AS dismissals,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_all
FROM ipl_data
WHERE isWicketDelivery = 1 AND kind IS NOT NULL
GROUP BY kind
ORDER BY dismissals DESC;


-- KPI 13: The cost of extras
-- Owner asks : "How many free runs do bowlers hand out, and of what kind?"
-- Level      : Easy-Moderate | Uses: WHERE IS NOT NULL, GROUP BY
-- Decision   : Wides and no-balls are pure indiscipline. A bowler who
--              leaks extras is less valuable than his economy suggests.
SELECT extra_type,COUNT(*) AS times_bowled,SUM(extras_run)  AS extra_runs
FROM ipl_data
WHERE extra_type IS NOT NULL
GROUP BY extra_type
ORDER BY extra_runs DESC;

-- KPI 14: Which bowlers have taken wickets in the most matches?
-- Owner asks : "Which bowlers take wickets consistently across matches?"
-- Level      : Easy-Moderate | Uses: WHERE, COUNT(DISTINCT), GROUP BY
-- Decision   : Helps identify bowlers who contribute wickets across
--              multiple matches, rather than relying only on total wickets.

SELECT bowler,COUNT(DISTINCT ID) AS matches_with_wickets
FROM ipl_data
WHERE isWicketDelivery = 1
  AND kind IN (
      'bowled', 'caught', 'caught and bowled',
      'lbw', 'stumped', 'hit wicket'
  )
GROUP BY bowler
ORDER BY matches_with_wickets DESC
LIMIT 10;

-- =====================================================================
--  ACT 4: THE RIVALS AND THE MATCH SITUATION
--  The owner needs to understand opposition scoring, leading batters,
--  and how runs build up during an innings.
-- =====================================================================


-- KPI 15: The 10 highest team totals in the dataset
-- Owner asks : "Which teams have recorded the highest innings totals?"
-- Decision   : Helps the owner understand high-scoring benchmarks and
--              prepare a batting lineup capable of setting or chasing
--              competitive totals.

SELECT ID AS match_id,innings,BattingTeam,
SUM(total_run) AS team_total,
SUM(isWicketDelivery) AS wicket_deliveries
FROM ipl_data
GROUP BY ID, innings, BattingTeam
ORDER BY team_total DESC
LIMIT 10;

-- KPI 16: The leading run scorer of every franchise
-- Owner asks : "Who is the top run scorer for each franchise?"
-- Level      : Moderate | Uses: CTE, ROW_NUMBER(), PARTITION BY
-- Decision   : Helps identify the leading run scorer associated with
--              each franchise in the available dataset.

WITH team_batter_runs AS (
    SELECT
        BattingTeam,
        batter,
        SUM(batsman_run) AS total_runs
    FROM ipl_data
    GROUP BY BattingTeam, batter
),
ranked_batters AS (SELECT BattingTeam,batter,total_runs,
			ROW_NUMBER() OVER (
            PARTITION BY BattingTeam
            ORDER BY total_runs DESC, batter) AS rn
    FROM team_batter_runs
)
SELECT BattingTeam,batter,total_runs
FROM ranked_batters
WHERE rn = 1
ORDER BY BattingTeam;

-- KPI 17: Runs scored in each over of the first match's first innings
-- Owner asks : "How did the scoring change from over to over?"
-- Decision   : Helps identify high-scoring and low-scoring overs in
--              one innings. The match can be changed to study another
--              innings.
-- Note       : The query uses the smallest match ID in the dataset.

WITH over_runs AS (SELECT overs,SUM(total_run) AS runs
FROM ipl_data
WHERE ID = (SELECT MIN(ID) FROM ipl_data) AND innings = 1
GROUP BY overs)
SELECT overs + 1 AS over_number,runs
FROM over_runs
ORDER BY overs;


-- KPI 18: Average runs scored in each over across matches
-- Owner asks : "During which overs do teams score the most runs?"
-- Decision   : Helps identify the overs where scoring is typically
--              strongest. This can guide decisions about power hitters
--              and bowling resources.

WITH over_runs AS (SELECT ID,innings,overs,
	SUM(total_run) AS runs
    FROM ipl_data
    GROUP BY ID, innings, overs
)
SELECT overs + 1 AS over_number,
ROUND(AVG(runs), 2) AS average_runs
FROM over_runs
GROUP BY overs
ORDER BY average_runs DESC;


-- =====================================================================
--  ACT 5: THE LIST FOR THE ROOM
--  The final section creates a simple shortlist of batters for further
--  evaluation before making auction decisions.
-- =====================================================================

-- KPI 19: Top 15 batters by runs, with a minimum of 150 deliveries
-- Owner asks : "Which batters have scored the most runs after facing
--               at least 150 counted deliveries?"
-- Level      : Moderate | Uses: CTE, WHERE, GROUP BY, HAVING
-- Decision   : Creates an initial shortlist based on total runs and
--              batting opportunities. The list can later be improved
--              by adding strike rate, average, and boundary percentage.
-- Note       : Wides are excluded from the delivery count. This is a
--              preliminary shortlist, not a complete auction ranking.

WITH batter_stats AS (SELECT batter,SUM(batsman_run) AS total_runs,
COUNT(*) AS deliveries
FROM ipl_data
WHERE extra_type IS NULL OR extra_type <> 'wides'
GROUP BY batter)
SELECT batter,total_runs,deliveries
FROM batter_stats
WHERE deliveries >= 150
ORDER BY total_runs DESC
LIMIT 15;


-- =====================================================================
--  MY RECOMMENDATIONS TO THE OWNER
--  (Complete this section after running the queries and reviewing the
--   actual results.)
--
--  1. Batting : Identify 3 to 5 batters for further evaluation using
--               total runs, scoring rate, and batting consistency.
--
--  2. Bowling : Identify 3 to 5 bowlers using wicket-taking ability,
--               runs conceded, and bowling performance.
--
--  3. Phase   : Use over-by-over scoring patterns to identify where
--               the team needs stronger batters or specialist bowlers.
--
--  4. Rivals  : Review the highest team totals and leading batters to
--               understand opposition strengths.
--
--  5. Caution : Auction prices, current squads, and available budgets
--               are not included in this dataset. Verify these details
--               before making actual bidding recommendations.
-- =====================================================================
