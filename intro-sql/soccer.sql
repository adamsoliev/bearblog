-- find rows where there are more columns than expected 
-- #!/opt/homebrew/bin/python3
-- import csv, sys

-- path = "/tmp/clubs.csv"; expected = 17
-- with open(path, newline='', encoding='utf-8') as f:
--     for i, row in enumerate(csv.reader(f), start=1):
--         if len(row) != expected:
--             print(f"Line {i}: {len(row)} cols ->", row)

-- meta
SELECT version();
SHOW data_directory;
SELECT inet_server_addr();


---------------------------------------------
-- appearances
---------------------------------------------
drop table if exists appearances;
CREATE TABLE appearances (
    appearance_id TEXT,
    game_id INTEGER,
    player_id INTEGER,
    player_club_id INTEGER,
    player_current_club_id INTEGER,
    appearance_date DATE,
    player_name TEXT,
    competition_id TEXT,
    yellow_cards INTEGER,
    red_cards INTEGER,
    goals INTEGER,
    assists INTEGER,
    minutes_played INTEGER
);


COPY appearances 
FROM '/tmp/appearances.csv' 
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');


-- sanity check
select * from appearances order by appearance_date DESC limit 3;


---------------------------------------------
-- club_games
---------------------------------------------
drop table if exists club_games;


create table club_games (
    game_id INTEGER,
    club_id INTEGER,
    own_goals INTEGER,
    own_position INTEGER,
    own_manager_name TEXT,
    opponent_id INTEGER,
    opponent_goals INTEGER,
    opponent_position INTEGER,
    opponent_manager_name TEXT,
    hosting TEXT,
    is_win INTEGER
);


COPY club_games 
FROM '/tmp/club_games.csv' 
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');


-- sanity check
select * from club_games limit 5;


---------------------------------------------
-- clubs
---------------------------------------------

drop table if exists clubs;


create table clubs (
    club_id INTEGER,
    club_code TEXT,
    club_name TEXT,
    domestic_competition_id TEXT,
    total_market_value TEXT, -- CONVERT TO MONEY
    squad_size SMALLINT,
    average_age FLOAT,
    foreigners_number INTEGER,
    foreigners_percentage FLOAT,
    national_team_players INTEGER,
    stadium_name TEXT,
    stadium_seats INTEGER,
    net_transfer_record TEXT, -- CONVERT TO MONEY
    coach_name TEXT,
    last_season INTEGER,
    filename TEXT,
    url TEXT
);


COPY clubs 
FROM '/tmp/clubs.csv' 
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');


-- sanity check
select * from clubs order by stadium_seats DESC NULLS LAST limit 5;