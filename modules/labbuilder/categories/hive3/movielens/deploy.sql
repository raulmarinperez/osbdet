-- Database creation
DROP DATABASE IF EXISTS movielens CASCADE;
CREATE DATABASE movielens;
USE movielens;

-- Raw table creation and simple queries
--

-- movies_raw table
CREATE EXTERNAL TABLE movies_raw
(movieId STRING, 
 title STRING, 
 genres STRING)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' 
STORED AS textfile 
LOCATION '/user/osbdet/datalake/raw/movielens/movies/'
TBLPROPERTIES ("skip.header.line.count"="1");

SELECT * FROM movies_raw LIMIT 10;

-- ratings_raw table
CREATE EXTERNAL TABLE ratings_raw
(userId STRING, 
 movieId STRING, 
 rating STRING,
 `timestamp` STRING)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' 
STORED AS textfile 
LOCATION '/user/osbdet/datalake/raw/movielens/ratings/'
TBLPROPERTIES ("skip.header.line.count"="1");

SELECT * FROM ratings_raw LIMIT 10;

-- links_raw table
CREATE EXTERNAL TABLE links_raw
(movieId STRING, 
 imdbId STRING, 
 tmdbId STRING)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' 
STORED AS textfile 
LOCATION '/user/osbdet/datalake/raw/movielens/links/'
TBLPROPERTIES ("skip.header.line.count"="1");

SELECT * FROM links_raw  LIMIT 10;

-- Parquet table creation and simple queries
--

-- movies_std table
CREATE EXTERNAL TABLE movies_std
(movieId BIGINT, 
 title STRING, 
 year INT, 
 genres ARRAY<STRING>)
STORED AS parquet 
LOCATION '/user/osbdet/datalake/std/movielens/movies/';

INSERT INTO movies_std
  SELECT movieId, 
         regexp_extract (title,'^(.*)\\(([0-9]{4})\\)$',1) AS title,
         regexp_extract (title,'^(.*)\\(([0-9]{4})\\)$',2) AS year,
         split(genres,'\\|') AS genres
  FROM movies_raw;

SELECT * FROM movies_std LIMIT 10;

-- ratings_std table
CREATE EXTERNAL TABLE ratings_std
(userId  BIGINT, 
 movieId  BIGINT, 
 rating DOUBLE, 
 `timestamp` TIMESTAMP)
STORED AS parquet 
LOCATION '/user/osbdet/datalake/std/movielens/ratings/';

INSERT INTO ratings_std
  SELECT userId, movieId, cast(rating AS DOUBLE),
         from_unixtime(cast (`timestamp` AS BIGINT)) 
  FROM ratings_raw;

SELECT * FROM ratings_std LIMIT 10;

-- links_std table
CREATE EXTERNAL TABLE links_std
(movieId BIGINT,  
 imdbId STRING, 
 tmdbId STRING)
STORED AS parquet 
LOCATION '/user/osbdet/datalake/std/movielens/links/';

INSERT INTO links_std
  SELECT movieId, 
         concat('http://www.imdb.com/title/tt',imdbId, '/'),
         concat('https://www.themoviedb.org/movie/',tmdbId,'/')
  FROM links_raw;

SELECT * FROM links_std LIMIT 10;

-- Some queries
--

-- how many movies are there per genre?
SELECT genre, count(*) AS total
FROM movies_std LATERAL VIEW explode(genres) g AS genre 
GROUP BY genre 
ORDER BY total DESC;

-- average rating per movie
SELECT movieId, avg(rating) AS avg_rating, count(*) AS rating_counter  
FROM ratings_std
GROUP BY movieId;

