CREATE DATABASE vmarkets;

USE vmarkets;

CREATE TABLE
    vegetables (
        v_id INT,
        v_type TEXT,
        CONSTRAINT vegetables_pk PRIMARY KEY (v_id)
    );

INSERT INTO
    vegetables (v_type, v_id)
VALUES
    ('Tomatos', 1),
    ('Salad', 2);

INSERT INTO
    vegetables (v_type, v_id)
VALUES
    ('Taters', 3);

COPY vegetables (v_type, v_id)
FROM
    '/PATH/TO/additional_vegetables.csv'
WITH
    (FORMAT csv, HEADER false);

CREATE EXTENSION IF NOT EXISTS file_fdw;

CREATE SERVER csv_server FOREIGN DATA WRAPPER file_fdw;

CREATE FOREIGN TABLE markets_csv (market_name TEXT, market_id INT) SERVER csv_server OPTIONS (
    filename '/PATH/TO/markets.csv',
    format 'csv',
    header 'true'
);

ALTER TABLE vegetables
ADD COLUMN market_id INT;

UPDATE vegetables
SET market_id = 
CASE
    WHEN (v_id % 2) = 0 THEN 1
    ELSE 2
END;

CREATE TABLE
    markets AS
SELECT
    *
FROM
    markets_csv;

ALTER TABLE markets ADD CONSTRAINT markets_pk PRIMARY KEY (market_id);

ALTER TABLE vegetables ADD CONSTRAINT vegetables_markets_fk FOREIGN KEY (market_id) REFERENCES markets (market_id);

SELECT
    m.market_name,
    COUNT(v.v_id)
FROM
    markets m
    JOIN vegetables v ON m.market_id = v.market_id
GROUP BY
    m.market_name;

SELECT
    m.market_name,
    COUNT(v.v_id)
FROM
    markets m
    JOIN vegetables v ON m.market_id = v.market_id
GROUP BY
    m.market_name
HAVING
    COUNT(v.v_id) >= 2;

CREATE TYPE point2d AS (
    id INT,
    x DOUBLE PRECISION,
    y DOUBLE PRECISION
);

ALTER TABLE markets ADD COLUMN loc point2d;

UPDATE markets SET loc = ROW(1, 2.22, 3.33)::point2d;

CREATE OR REPLACE FUNCTION euclidean_distance(p1 point2d, p2 point2d)
RETURNS DOUBLE PRECISION AS $$
BEGIN
    RETURN sqrt(power(p1.x - p2.x, 2) + power(p1.y - p2.y, 2));
END;
$$ LANGUAGE plpgsql IMMUTABLE;
