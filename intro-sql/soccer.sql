-- meta
SELECT version();
SHOW data_directory;
SELECT inet_server_addr();


---------------------------------------------
-- appearances
---------------------------------------------
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

select * from appearances order by appearance_date DESC limit 3;
