-- dataset: https://www.kaggle.com/datasets/davidcariboo/player-scores
-- download it and move every csv file into /tmp/ directory


---------------------------------------------
-- tools
---------------------------------------------
/* find rows where there are more columns than expected 

#!/opt/homebrew/bin/python3
import csv, sys

path = "/tmp/clubs.csv"; expected = 17
with open(path, newline='', encoding='utf-8') as f:
    for i, row in enumerate(csv.reader(f), start=1):
        if len(row) != expected:
            print(f"Line {i}: {len(row)} cols ->", row)
*/


---------------------------------------------
-- meta
---------------------------------------------
SELECT version();
SHOW data_directory;
SELECT inet_server_addr();


---------------------------------------------
-- appearances
---------------------------------------------
drop table if exists appearances;
CREATE TABLE appearances (
    appearance_id TEXT PRIMARY KEY,
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
    is_win INTEGER,
    PRIMARY KEY (game_id, club_id)
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
    club_id INTEGER PRIMARY KEY,
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


---------------------------------------------
-- competitions
---------------------------------------------
drop table if exists competitions;

create table competitions (
    competition_id TEXT PRIMARY KEY,
    competition_code TEXT,
    name TEXT,
    sub_type TEXT,
    type TEXT,
    country_id INTEGER,
    country_name TEXT,
    domestic_league_code TEXT,
    confederation TEXT,
    url TEXT,
    is_major_national_league BOOLEAN
);


COPY competitions 
FROM '/tmp/competitions.csv' 
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');


-- sanity check
select * from competitions limit 5;


---------------------------------------------
-- game_events
---------------------------------------------
drop table if exists game_events;


create table game_events (
    game_event_id TEXT PRIMARY KEY,
    date DATE,
    game_id INTEGER,
    minute INTEGER,
    type TEXT,
    club_id INTEGER,
    player_id INTEGER,
    description TEXT,
    player_in_id TEXT,
    player_assist_id TEXT
);


COPY game_events 
FROM '/tmp/game_events.csv' 
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');


-- sanity check
select * from game_events limit 5;


---------------------------------------------
-- game_lineups
---------------------------------------------
drop table if exists game_lineups;


create table game_lineups (
    game_lineups_id TEXT PRIMARY KEY,
    date DATE,
    game_id INTEGER,
    player_id INTEGER,
    club_id INTEGER,
    player_name TEXT,
    type TEXT,
    position TEXT,
    number TEXT,
    team_captain INTEGER
);


COPY game_lineups 
FROM '/tmp/game_lineups.csv' 
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');


-- sanity check
select * from game_lineups limit 5;


---------------------------------------------
-- games
---------------------------------------------
drop table if exists games;


create table games (
    game_id INTEGER PRIMARY KEY,
    competition_id TEXT,
    season INTEGER,
    round TEXT,
    date DATE,
    home_club_id INTEGER,
    away_club_id INTEGER,
    home_club_goals INTEGER,
    away_club_goals INTEGER,
    home_club_position TEXT,
    away_club_position TEXT,
    home_club_manager_name TEXT,
    away_club_manager_name TEXT,
    stadium TEXT,
    attendance TEXT,
    referee TEXT,
    url TEXT,
    home_club_formation TEXT,
    away_club_formation TEXT,
    home_club_name TEXT,
    away_club_name TEXT,
    aggregate TEXT,
    competition_type TEXT
);


COPY games 
FROM '/tmp/games.csv' 
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');


-- sanity check
select * from games limit 5;


---------------------------------------------
-- player_valuations
---------------------------------------------
drop table if exists player_valuations;


create table player_valuations (
    player_id INTEGER,
    date DATE,
    market_value_in_eur NUMERIC,
    current_club_id INTEGER,
    player_club_domestic_competition_id TEXT,
    PRIMARY KEY (player_id, date)
);


COPY player_valuations 
FROM '/tmp/player_valuations.csv' 
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');


-- sanity check
select * from player_valuations order by date DESC limit 5;


---------------------------------------------
-- players
---------------------------------------------
drop table if exists players;


create table players (
    player_id INTEGER PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    name TEXT,
    last_season INTEGER,
    current_club_id INTEGER,
    player_code TEXT,
    country_of_birth TEXT,
    city_of_birth TEXT,
    country_of_citizenship TEXT,
    date_of_birth TEXT,
    sub_position TEXT,
    position TEXT,
    foot TEXT,
    height_in_cm TEXT,
    contract_expiration_date TEXT,
    agent_name TEXT,
    image_url TEXT,
    url TEXT,
    current_club_domestic_competition_id TEXT,
    current_club_name TEXT,
    market_value_in_eur TEXT,
    highest_market_value_in_eur TEXT
);


COPY players 
FROM '/tmp/players.csv' 
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');


-- sanity check
select * from players limit 5;


---------------------------------------------
-- transfers
---------------------------------------------
drop table if exists transfers;


create table transfers (
    player_id INTEGER,
    transfer_date DATE,
    transfer_season TEXT,
    from_club_id INTEGER,
    to_club_id INTEGER,
    from_club_name TEXT,
    to_club_name TEXT,
    transfer_fee TEXT,
    market_value_in_eur TEXT,
    player_name TEXT,
    PRIMARY KEY (player_id, transfer_date, from_club_id, to_club_id)
);


COPY transfers 
FROM '/tmp/transfers.csv' 
WITH (FORMAT CSV, HEADER TRUE, DELIMITER ',');


-- sanity check
select * from transfers limit 5;


---------------------------------------------
-- constraints
---------------------------------------------
ALTER TABLE clubs
    ADD CONSTRAINT clubs_domestic_competition_fk
    FOREIGN KEY (domestic_competition_id) REFERENCES competitions (competition_id);

ALTER TABLE games
    ADD CONSTRAINT games_competition_fk
    FOREIGN KEY (competition_id) REFERENCES competitions (competition_id),
    ADD CONSTRAINT games_home_club_fk
    FOREIGN KEY (home_club_id) REFERENCES clubs (club_id),
    ADD CONSTRAINT games_away_club_fk
    FOREIGN KEY (away_club_id) REFERENCES clubs (club_id);

ALTER TABLE club_games
    ADD CONSTRAINT club_games_game_fk
    FOREIGN KEY (game_id) REFERENCES games (game_id),
    ADD CONSTRAINT club_games_club_fk
    FOREIGN KEY (club_id) REFERENCES clubs (club_id),
    ADD CONSTRAINT club_games_opponent_fk
    FOREIGN KEY (opponent_id) REFERENCES clubs (club_id);

ALTER TABLE appearances
    ADD CONSTRAINT appearances_game_fk
    FOREIGN KEY (game_id) REFERENCES games (game_id),
    ADD CONSTRAINT appearances_player_fk
    FOREIGN KEY (player_id) REFERENCES players (player_id),
    ADD CONSTRAINT appearances_player_club_fk
    FOREIGN KEY (player_club_id) REFERENCES clubs (club_id),
    ADD CONSTRAINT appearances_player_current_club_fk
    FOREIGN KEY (player_current_club_id) REFERENCES clubs (club_id),
    ADD CONSTRAINT appearances_competition_fk
    FOREIGN KEY (competition_id) REFERENCES competitions (competition_id);

ALTER TABLE game_events
    ADD CONSTRAINT game_events_game_fk
    FOREIGN KEY (game_id) REFERENCES games (game_id),
    ADD CONSTRAINT game_events_club_fk
    FOREIGN KEY (club_id) REFERENCES clubs (club_id),
    ADD CONSTRAINT game_events_player_fk
    FOREIGN KEY (player_id) REFERENCES players (player_id);

ALTER TABLE game_lineups
    ADD CONSTRAINT game_lineups_game_fk
    FOREIGN KEY (game_id) REFERENCES games (game_id),
    ADD CONSTRAINT game_lineups_player_fk
    FOREIGN KEY (player_id) REFERENCES players (player_id),
    ADD CONSTRAINT game_lineups_club_fk
    FOREIGN KEY (club_id) REFERENCES clubs (club_id);

ALTER TABLE player_valuations
    ADD CONSTRAINT player_valuations_player_fk
    FOREIGN KEY (player_id) REFERENCES players (player_id),
    ADD CONSTRAINT player_valuations_current_club_fk
    FOREIGN KEY (current_club_id) REFERENCES clubs (club_id),
    ADD CONSTRAINT player_valuations_competition_fk
    FOREIGN KEY (player_club_domestic_competition_id) REFERENCES competitions (competition_id);

ALTER TABLE players
    ADD CONSTRAINT players_current_club_fk
    FOREIGN KEY (current_club_id) REFERENCES clubs (club_id),
    ADD CONSTRAINT players_current_competition_fk
    FOREIGN KEY (current_club_domestic_competition_id) REFERENCES competitions (competition_id);

ALTER TABLE transfers
    ADD CONSTRAINT transfers_player_fk
    FOREIGN KEY (player_id) REFERENCES players (player_id),
    ADD CONSTRAINT transfers_from_club_fk
    FOREIGN KEY (from_club_id) REFERENCES clubs (club_id),
    ADD CONSTRAINT transfers_to_club_fk
    FOREIGN KEY (to_club_id) REFERENCES clubs (club_id);


---------------------------------------------
-- meta: size diagnostics
---------------------------------------------
-- table sizes
SELECT 
    schemaname,
    relname,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS table_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS index_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;


-- database size
SELECT current_database() AS database_name,
       pg_size_pretty(pg_database_size(current_database())) AS database_size;
