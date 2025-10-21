CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    joined_on DATE NOT NULL,
    membership_tier TEXT NOT NULL
);

CREATE TABLE library (
    library_id INTEGER PRIMARY KEY,
    branch_name TEXT NOT NULL,
    city TEXT NOT NULL,
    opened_on DATE NOT NULL
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    library_id INTEGER NOT NULL REFERENCES library (library_id),
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    genre TEXT NOT NULL,
    published_year INTEGER NOT NULL,
    checked_out_by INTEGER REFERENCES users (user_id)
);

INSERT INTO users (user_id, full_name, joined_on, membership_tier)
VALUES
    (1, 'Alice Smith', '2022-01-04', 'STANDARD'),
    (2, 'Brianna Diaz', '2022-03-12', 'PREMIUM'),
    (3, 'Chandra Iyer', '2022-07-19', 'PREMIUM'),
    (4, 'Dmitri Volkov', '2023-02-08', 'STANDARD'),
    (5, 'Evelyn Harper', '2023-05-23', 'STUDENT'),
    (6, 'Farah Nasser', '2023-09-14', 'STANDARD');

INSERT INTO library (library_id, branch_name, city, opened_on)
VALUES
    (1, 'Central Library', 'Boston', '2010-01-15'),
    (2, 'Riverside Branch', 'Portland', '2012-06-20'),
    (3, 'Innovation Hub', 'Austin', '2015-03-30'),
    (4, 'Harbor Reading Room', 'Seattle', '2016-11-05'),
    (5, 'Southside Learning Center', 'Chicago', '2018-04-18'),
    (6, 'Uptown Collection', 'Denver', '2019-09-09');

INSERT INTO books (book_id, library_id, title, author, genre, published_year, checked_out_by)
VALUES
    (1, 1, 'War and Peace', 'Leo Tolstoy', 'Literature', 1869, 2),
    (2, 1, 'Anna Karenina', 'Leo Tolstoy', 'Literature', 1877, NULL),
    (3, 2, 'Crime and Punishment', 'Fyodor Dostoevsky', 'Literature', 1866, 4),
    (4, 3, 'The Brothers Karamazov', 'Fyodor Dostoevsky', 'Literature', 1880, NULL),
    (5, 5, 'The Cherry Orchard', 'Anton Chekhov', 'Drama', 1904, 1),
    (6, 6, 'One Day in the Life of Ivan Denisovich', 'Alexander Solzhenitsyn', 'Historical Fiction', 1962, 3);


-- ////////////////////
-- select
-- ////////////////////
SELECT title, author FROM books;


SELECT
    title,
    'library dataset' AS dataset_label,
    published_year + 1 AS next_publication_year,
    upper(author) AS author_upper
FROM
    books;


SELECT
    b.title,
    upper(b.genre) AS genre_uppercase,
    replace(b.author, ' ', '_') AS author_slug,
    COALESCE(CAST(b.checked_out_by AS TEXT), 'Available') AS current_holder_id,
    CASE
        WHEN b.checked_out_by IS NULL THEN 'on shelf'
        ELSE 'checked out'
    END AS circulation_status,
    (make_date(b.published_year, 1, 1) + INTERVAL '150 years')::date AS public_domain_anniversary,
    to_char(make_date(b.published_year, 1, 1), 'YYYY-Mon-DD') AS publication_year_formatted
FROM books AS b;

-- ////////////////////
-- from
-- ////////////////////
-- old join vs sql92
SELECT
    b.title,
    u.full_name
FROM books AS b, users AS u
WHERE u.user_id = b.checked_out_by;

SELECT
    b.title,
    u.full_name
FROM books AS b
INNER JOIN users AS u
    ON u.user_id = b.checked_out_by;



SELECT
    b.title,
    u.full_name
FROM books AS b
    JOIN users AS u
    ON u.user_id = b.checked_out_by;


SELECT
    catalog.title,
    active_loans.checked_out_by
FROM
    (SELECT book_id, title FROM books) AS catalog
    JOIN
    (SELECT book_id, checked_out_by FROM books WHERE checked_out_by IS NOT NULL) AS active_loans
    USING (book_id);


SELECT
    catalog.title,
    active_loans.checked_out_by
FROM
    (SELECT book_id, title FROM books) AS catalog
    NATURAL JOIN
    (SELECT book_id, checked_out_by FROM books WHERE checked_out_by IS NOT NULL) AS active_loans;


-- ////////////////////
-- where
-- ////////////////////

select title
from books
where genre='Literature';


select title
from books
where genre='Literature' AND published_year=1869;


SELECT u.full_name
FROM users AS u
WHERE EXISTS (
    SELECT 1
    FROM books AS b
    WHERE b.checked_out_by = u.user_id
);

SELECT title
FROM books
where library_id IN (
    SELECT library_id
    FROM library
    WHERE city='Boston'
);

SELECT
    b.title
FROM books AS b
WHERE (b.library_id, b.genre, b.published_year) IN (
    SELECT
        l.library_id,
        'Literature' AS required_genre
    FROM library AS l
    WHERE l.city = 'Boston'
);


SELECT
    u.full_name
FROM users AS u
WHERE u.user_id NOT IN (
    SELECT b.checked_out_by
    FROM books AS b
);

SELECT
    b.title
FROM books AS b
WHERE b.published_year >= ALL (
    SELECT
        comparison.published_year
    FROM books AS comparison
    WHERE comparison.genre = 'Literature'
);

-- order by
SELECT title, author, published_year, checked_out_by
FROM books
ORDER BY
    checked_out_by IS NULL,
    published_year DESC;


SELECT title, author, checked_out_by
FROM books
ORDER BY checked_out_by NULLS FIRST;


-- group by

SELECT genre, COUNT(*)
FROM books
GROUP BY genre;


SELECT author, COUNT(*)
FROM books
GROUP BY author;


SELECT genre, COUNT(*)
FROM books
GROUP BY genre
HAVING COUNT(*) > 2;


SELECT genre, author, COUNT(*)
FROM books
GROUP BY
    GROUPING SETS (
        genre,
        author
    );


SELECT
    l.branch_name,
    b.genre,
    COUNT(*) AS book_count
FROM books AS b
JOIN library AS l ON l.library_id = b.library_id
GROUP BY ROLLUP (l.branch_name, b.genre);


-- cte

WITH hold_premium as (
    SELECT full_name, title, author, published_year
    FROM users
        JOIN books ON checked_out_by = user_id
    WHERE membership_tier = 'PREMIUM'
)
SELECT full_name as holder, title
FROM hold_premium
WHERE published_year < 1900;


WITH RECURSIVE branch_openings AS (
      SELECT
          l.library_id,
          l.branch_name,
          l.city,
          l.opened_on,
          1 AS open_order
      FROM library AS l
      WHERE l.opened_on = (SELECT MIN(opened_on) FROM library)

      UNION ALL

      SELECT
          next_branch.library_id,
          next_branch.branch_name,
          next_branch.city,
          next_branch.opened_on,
          bo.open_order + 1
      FROM branch_openings AS bo
      JOIN library AS next_branch
        ON next_branch.opened_on = (
           SELECT MIN(opened_on)
           FROM library
           WHERE opened_on > bo.opened_on
        )
  )
  SELECT branch_name, city, opened_on, open_order
  FROM branch_openings
  ORDER BY open_order;
