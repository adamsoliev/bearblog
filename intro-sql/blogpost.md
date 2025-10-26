#### Table of Contents
* [What and why](#what-and-why)
* [Relational Model](#relational-model)
* [Relational algebra and calculus](#relational-algebra-and-calculus)
* [Basic SQL](#basic-sql)
  * [SELECT](#select)
  * [FROM](#from)
  * [WHERE](#where)
  * [ORDER BY](#order-by)
  * [LIMIT AND OFFSET](#limit-and-offset)
  * [GROUP BY](#group-by)
  * [COMMON TABLE EXPRESSIONS](#common-table-expressions)
  * [WINDOW FUNCTIONS](#window-functions)
  * [NULL PITFALLS](#null-pitfalls)
* [Advanced queries walkthrough](#advanced-queries-walkthrough)
* [Optimizations](#optimizations)
* [Conclusion](#conclusion)
* [References](#references)

---

# <a id="what-and-why" href="#table-of-contents">What and why</a>
This is my introduction to SQL. I start from the relational model — the theory SQL is built on — then shift to the user’s point of view, walking through queries from basic to advanced. In the basic section, I explain each clause using a simple query and how that clause fits into SQL’s logical flow. In the advanced section, I break down complex queries visually and step by step. The post ends with a look at SQL performance.

I wrote this mostly to clarify my own understanding. Along the way, I cut what’s easy to find elsewhere and kept what took effort to learn. If you have thoughts or feedback, I’d love to hear them.

# <a id="relational-model" href="#table-of-contents">Relational model</a>

The relational model is built on a simple idea borrowed from mathematics: a relation is just a set of tuples.

Formally, given sets $S1$, $S2$, $\dots$, $Sn$ (called **domains**), a relation $R$ on these sets is any set of $n$-tuples where each tuple’s first value comes from $S1$, its second from $S2$, and so on. In database terms, a relation is a **table**, a tuple is a **row**, and the sets $S1$, $S2$, $\dots$, $Sn$ define the permissible values for each column.

For example, imagine you have three sets:

* **$S_1 = \{12, 75, 32, 54, 98\}$** (a set of IDs)
* **$S_2 = \{"A", "B", "C", "D", "E"\}$** (a set of names)
* **$S_3 = \{2023$-$10$-$02, 2022$-$07$-$11, 2025$-$01$-$12, 2019$-$03$-$27, 2026$-$12$-$03\}$** (a set of dates)

A possible table $R$ on these three sets could be:

| ID | Name | Date |
|---|---|---|
| 12 | "A" | 2023-10-02 |
| 75 | "C" | 2022-07-11 |
| 32 | "E" | 2019-03-27 |

Here, $R$ has three rows – each consisting of the same columns (`ID`, `Name`, `Date`). Each column is of a specific data type (`INTEGER`, `TEXT`, `DATE`). Whereas columns have a fixed order in each row, the order of the rows within the table isn't guaranteed in any way (although they can be explicitly sorted for display).

To connect information across tables, the relational model relies on 'key' columns:
* a **primary key** uniquely identifies each row within a table (e.g., ID in the relation $R$).
* a **foreign key** creates a logical link to a primary key in another table, allowing data in one table to reference data in another.

With this solid theoretical foundation and some practical departures from pure theory, the relational model achieved the right abstraction that enabled two defining properties in database systems:
* **declarative querying**: users specify what data they want, not how to retrieve it.
* **data independence**: applications describe data logically, while the database decides how to store and access it.

# <a id="relational-algebra-and-calculus" href="#table-of-contents">Relational algebra and calculus</a>
Simply put, relational algebra (RA) and calculus (RC) are the mathematical languages of the relational model. They answer the question: if data is stored as tables, what does it mean to “operate” on them? 

RA provides a set of operators - `SELECT`, `PROJECT` and others - that transform relations step by step, much like +, -, /, * in arithmetic, except that they act on tables rather than numbers. RC, by contrast, describes the conditions rows must satisfy, without prescribing steps. 

SQL was inspired by both RA and RC. Yet SQL is not a strict disciple of either: it allows duplicates rows, NULLs, and implicit ordering - features absent from the original theory. It became the first successful language to separate “what” and “how”.

# <a id="basic-sql" href="#table-of-contents">Basic SQL</a>

SQL covers several kinds of tasks, often grouped into four main categories:
- DQL (data query language) - Extracts data from tables. (e.g., `SELECT`)
- DDL (data definition language) - Defines and modifies database structures. (e.g., `CREATE`, `ALTER`, `DROP`)
- DCL (data control language) - Manages user access and permissions. (e.g., `GRANT`, `REVOKE`)
- DML (data manipulation language) - Inserts, updates, or deletes table data. (e.g., `INSERT`, `UPDATE`, `DELETE`)

In the rest of this blogpost, the focus is on DQL, since querying is where most of the real-world effort — and much of SQL’s expressive power — lies. The examples rely on the following library lending dataset, consisting of `users`, `library`, and `books` tables. 

```sql
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
```

<!-- /////////////////// -->
<!-- SELECT -->
<!-- /////////////////// -->
### <a id="select" href="#table-of-contents">SELECT</a>

Most people think of `SELECT` as “picking columns” from a table — and at the surface, that’s true. You write
```sql
SELECT title, author 
FROM books;
```
and get just those two columns. But under the hood, `SELECT` doesn’t actually retrieve columns — it produces rows. It’s the way of constructing a new table: starting from rows in the `FROM` clause, filtering them with `WHERE`, grouping them with `GROUP BY`, etc and finally returning the resulting rows. The columns you write in `SELECT` merely define the shape of those output rows.

Each "column" in `SELECT` can be sourced from a base table (created with `CREATE TABLE`), a literal value, an expression or an aggregate/scalar function. You can also rename any column using `AS` with an alias for clarity or reuse. For example, 
```sql
SELECT
    title,                                              -- base column
    'library dataset' AS dataset_label,                 -- literal value
    published_year + 1 AS next_publication_year,        -- expression
    upper(author) AS author_upper                       -- scalar function
FROM
    books;
```

Modern databases make it easy to perform substantial data transformation right inside `SELECT`, reducing the need to handle that logic in application code. Suppose you want to surface who currently has each book and render a status with some additional info:
```sql
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
```

The result table now contains transformed values like 
| | | | | | | |
|-|-|-|-|-|-|-| 
| The Cherry Orchard | DRAMA | Anton_Chekhov | 1 | checked out | 2054-01-01 | 1904-Jan-01 |

<!-- /////////////////// -->
<!-- FROM -->
<!-- /////////////////// -->
### <a id="from" href="#table-of-contents">FROM</a>

The `FROM` clause defines *where* your data comes from. Each source can be a base table, a derived table (created with a subquery like `(SELECT …)`), a join, or a combination of these.

You can also specify *how* these sources relate to each other using a join condition — written with `ON`, or its shorthand forms `USING` and `NATURAL`:

```
T1 { [INNER] | { LEFT | RIGHT | FULL } [OUTER] } JOIN T2 ON boolean_expression
T1 { [INNER] | { LEFT | RIGHT | FULL } [OUTER] } JOIN T2 USING ( join column list )
T1 NATURAL { [INNER] | { LEFT | RIGHT | FULL } [OUTER] } JOIN T2
```
`INNER` and `OUTER` are optional; `INNER` is the default. `LEFT`, `RIGHT`, and `FULL` all imply outer joins.

#### Join types
* `INNER JOIN` keeps only rows that match on both sides.
* `LEFT JOIN` keeps all rows from the left table and fills in columns from the right table only when you have a match, otherwise using NULL as the column values.
* `RIGHT JOIN` does the opposite: it keeps all rows from the right table.
* `FULL JOIN` keeps all rows from both sides, padding missing values with NULL.
* `CROSS JOIN` returns every possible combination of rows from both tables, so the result size is the product of their row counts.
* `LATERAL JOIN` allows a subquery that runs once per row of the outer table — like a loop over the left input.

#### Old join syntax vs SQL92

> This distinction still surfaces in older tutorials and legacy code, so it’s worth being aware.

Before SQL-92, joins were written by listing tables separated with commas and moving the join condition to the `WHERE` clause:

```sql
SELECT
    b.title,
    u.full_name
FROM books AS b, users AS u
WHERE u.user_id = b.checked_out_by;
```

It works, but the relationship between tables is easy to miss and outer joins require vendor-specific extensions. SQL-92 introduced explicit join operators that keep the join condition next to the tables being combined:

```sql
SELECT
    b.title,
    u.full_name
FROM books AS b
INNER JOIN users AS u
    ON u.user_id = b.checked_out_by;
```

#### Join conditions
* `ON` defines how rows from the two tables are matched and filtered. In contrast, `WHERE` (covered next) is also a filter, but it applies after the join output is produced. Here’s a basic `ON` example that pairs each checked-out book with its holder and displays those in the literature genre.
  ```sql
  SELECT *
  FROM books AS b
      JOIN library AS l ON b.library_id = l.library_id AND b.genre = 'Literature';  
  ```
* `USING` is syntactic sugar for equality joins: `USING(a,b)` expands to `ON left_table.a = right_table.a AND left_table.b = right_table.b`. For example,
  ```sql
  SELECT *
  FROM books
      JOIN library USING(library_id);
  ```
* `NATURAL` is syntactic sugar for `USING` over all columns with the same name in both tables. If no such columns exist, it behaves like `ON TRUE`, meaning every row pairs with every other (a Cartesian product). The `USING` example can also be written as:
  ```sql
  SELECT *
  FROM books
      NATURAL JOIN library;  
  ```
  
<!-- /////////////////// -->
<!-- WHERE -->
<!-- /////////////////// -->
### <a id="where" href="#table-of-contents">WHERE</a>

`WHERE` clause filters rows produced by the `FROM` clause. Each row is checked against the condition: if it evaluates to true, the row is kept; if false or null, it's discarded.

```sql
SELECT title
FROM books
WHERE genre='Literature';
```

You can combine conditions with `AND` and `OR`. `AND` allows short-circuit evaluation (stopping once one condition fails), while `OR` is more complex to optimize for – especially with respect to indexes.

```sql
SELECT title
FROM books
WHERE genre='Literature' AND published_year=1869;
```

#### Subquery expressions
* `EXISTS` checks whether a subquery returns at least one row for the current row of the outer query.
    ```sql
    SELECT u.full_name
    FROM users AS u
    WHERE EXISTS (
        SELECT 1
        FROM books AS b
        WHERE b.checked_out_by = u.user_id
    );
    ```
    `SELECT 1` is a common placeholder because `EXISTS` only cares about the existence of a row, not the data within it.
* `IN`/`NOT IN` evaluate the expression and compare it to each row of the subquery single-column result. They return true/false, respectively, if at least one equal subquery row is found.
  ```sql
  SELECT title
  FROM books
  where library_id IN (
      SELECT library_id
      FROM library
      WHERE city='Boston'
  );
  ```
  If the expression consists of multiple columns, the subquery must return exactly as many columns. For example, the following query results in a `subquery has too few columns` error. 
  ```sql
  SELECT
      b.title
  FROM books AS b
  WHERE (b.library_id, b.genre, b.published_year) IN (  -- 3 expected
      SELECT                                            -- 2 returned 
          l.library_id,
          'Literature' AS required_genre
      FROM library AS l
      WHERE l.city = 'Boston'
  );
  ```

  Be careful about `NOT IN` with `NULL` because if the subquery result contains `NULL`, `NOT IN` evaluates to UNKNOWN (so effectively false for filtering). For instance:

  ```sql
  SELECT 1 
  WHERE 5 NOT IN (1, 2, 3, NULL); 
  ```
  Because the result set includes `NULL`, this query returns zero rows even though you expect to get `1` back.
* `ANY/SOME` allow using other comparison operators beyond `=`, such as `<>`, `>`, `<`, `>=`, `<=`. Recall that `IN` implicitly performs an `=` comparison.
  ```sql
  SELECT
      b.title, b.published_year
  FROM books AS b
  WHERE b.published_year > ANY (
      SELECT
          comparison.published_year
      FROM books AS comparison
      WHERE comparison.author = 'Fyodor Dostoevsky'
  );  
  ```
  This returns every book published after at least one of Dostoevsky's books.
* `ALL` is the opposite of `ANY`: the condition must hold true for every value returned by the subquery.
  ```sql
  SELECT
      b.title, b.published_year
  FROM books AS b
  WHERE b.published_year > ALL (
      SELECT
          comparison.published_year
      FROM books AS comparison
      WHERE comparison.author = 'Fyodor Dostoevsky'
  );  
  ```
  This returns every book published after all of Dostoevsky’s books (i.e., later than his most recent one).
  
--- 

==Now that you understand `FROM` (which tables to get data from), `WHERE` (how to filter rows), and `SELECT` (which columns to output), what do you think is the logical order in which a database executes them?==[^1]

---

<!-- /////////////////// -->
<!-- ORDER BY -->
<!-- /////////////////// -->
### <a id="order-by" href="#table-of-contents">ORDER BY</a>

`ORDER BY` defines the order in which the final result set is returned. It can sort by one or multiple columns, or by expressions derived from them. The sort direction is controlled with `ASC` (ascending, the default) or `DESC` (descending).

```sql
SELECT title, author, published_year, checked_out_by
FROM books
ORDER BY 
    checked_out_by IS NULL,
    published_year DESC;
```

`NULLS FIRST` and `NULLS LAST` specify where `NULL` values appear in the order. By default, most databases treat `NULL` as larger than any non-null value — so they appear last when sorting ascending.
```sql
SELECT title, author, checked_out_by
FROM books
ORDER BY checked_out_by NULLS FIRST;
```

`ORDER BY` can also be used after set operations like `UNION`, `INTERSECT`, or `EXCEPT`, but in those cases it can only reference output column names or their positional numbers (not arbitrary expressions).

<!-- /////////////////// -->
<!-- LIMIT and OFFSET -->
<!-- /////////////////// -->
### <a id="limit-and-offset" href="#table-of-contents">LIMIT and OFFSET</a>

`LIMIT` restricts the number of rows returned by a query, while `OFFSET` skips a given number of rows before starting to return results. These two are often paired with `ORDER BY` to guarantee a consistent and predictable order of results.
```sql
SELECT title, author, published_year
FROM books
ORDER BY published_year DESC
LIMIT 2;
```

<!-- /////////////////// -->
<!-- GROUP BY -->
<!-- /////////////////// -->
### <a id="group-by" href="#table-of-contents">GROUP BY</a>

`GROUP BY` takes rows with identical values in one or more columns and collapses them into a single summary row. It is almost always paired with aggregates, including `COUNT()` and `AVG()`, which compute one result per group. For example, to know how many books there are per genre or author, you could try:
```sql
-- count per genre
SELECT genre, COUNT(*) 
FROM books
GROUP BY genre;

-- count per author
SELECT author, COUNT(*) 
FROM books
GROUP BY author;
```

`HAVING` checks the summary row of every group against the condition: if it evaluates to true, the summary row is kept; if false or null, it's discarded. In other words, `HAVING` is a group-level filter (recall that `WHERE` is a row-level one).
```sql
SELECT genre, COUNT(*) 
FROM books
GROUP BY genre
HAVING COUNT(*) > 2;
```

`GROUPING SETS` is syntactic sugar for running multiple `GROUP BY`s in parallel. By using `GROUPING SETS`, you can combine various aggregations into a single query. The main advantage here is that you read data only once while producing many different aggregation sets at the same time.

For example, to count the number of books per genre and author simultaneously, you could use:
```sql
SELECT genre, author, COUNT(*) 
FROM books
GROUP BY 
    GROUPING SETS (
        genre,
        author
    );
```

`ROLLUP` is syntactic sugar for running a specific type of `GROUPING SETS`, where one column is removed at each step.
```sql
...
GROUP BY
    ROLLUP (a, b)

-- is equal to

...
GROUP BY
    GROUPING SET (
        (a, b),
        (a),
        ()
    )
```

It is useful for hierarchical summaries like branch → genre → total.
```sql
SELECT
    l.branch_name,
    b.genre,
    COUNT(*) AS book_count
FROM books AS b
    JOIN library AS l ON l.library_id = b.library_id
GROUP BY ROLLUP (l.branch_name, b.genre);
```
This returns genre totals per branch, a branch subtotal (with `genre` set to `NULL`), and a final grand total.

`CUBE` is syntactic sugar for running another type of `GROUPING SETS`, where you enumerate every combination of the listed columns.
```sql
...
GROUP BY
    CUBE (a, b);

-- is equal to

...
GROUP BY
    GROUPING SET (
        (a, b),
        (a),
        (b),
        ()
    );
```

This query includes summary of every combination: branch+genre, branch-only, genre-only, and the overall total.
```sql
SELECT
    l.branch_name,
    b.genre,
    COUNT(*) AS book_count
FROM books AS b
    JOIN library AS l ON l.library_id = b.library_id
GROUP BY CUBE (l.branch_name, b.genre);
```

---

==Now that you understand `ORDER BY`, `LIMIT/OFFSET`, and `GROUP BY` in addition to `FROM`, `SELECT` and `WHERE`, what do you think is the logical order in which a database executes all of them?==[^2]

---

<!-- /////////////////// -->
<!-- COMMON TABLE EXPRESSION (CTE) -->
<!-- /////////////////// -->
### <a id="common-table-expressions" href="#table-of-contents">COMMON TABLE EXPRESSIONS</a>

`Common table expressions` (CTEs) let you define a named subquery, run it as a prologue, and then refer to its result set like any other relation in the main query’s `FROM`. CTEs' value comes from breaking down complicated queries into simpler, and easier to follow, parts.

```sql
WITH hold_premium as (
    SELECT full_name, title, author, published_year
    FROM users
        JOIN books ON checked_out_by = user_id
    WHERE membership_tier = 'PREMIUM'
)
SELECT full_name as holder, title
FROM hold_premium
WHERE published_year < 1900;
```

The optional `RECURSIVE` keyword turns a CTE from a mere syntactic convenience into a feature where the CTE query can refer to its own output. A recursive CTE has the general form:
```
non-recursive term
UNION or UNION ALL
recursive term
```

The first term acts as the base case and each subsequent iteration of the recursive term builds on the prior results until no new rows are produced or the condition is met. Only the recursive term may reference the CTE itself. 

In a recursive CTE, the UNION or UNION ALL operator combines rows vertically, stacking the initial anchor query results with the iterative results from the recursive member. A good mental model is an iterative loop: the anchor query runs once, its results are used by the recursive query, and those new results are added to the set for the next iteration until no new rows are returned. UNION ALL is faster because it simply concatenates all rows, while UNION performs an additional, costly step to remove duplicates.

Here is the query that uses the library table to walk through branches in the order they opened:
```sql
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
```

Recursive CTEs are most often used to work with hierarchical or graph-like data.

<!-- /////////////////// -->
<!-- Window functions -->
<!-- /////////////////// -->
### <a id="window-functions" href="#table-of-contents">WINDOW FUNCTIONS</a>

A window function performs a calculation across a set of rows that are somehow related to the current row. It's similar to an aggregate function, except that it does not collapse rows into a single result. It operates on rows of the "virtual table" produced by the query's FROM clause as filtered by its WHERE, GROUP BY, and HAVING clauses if any.

General form:
```sql
FUNCTION_NAME(arguments) OVER ( [PARTITION BY ...] [ORDER BY ...] [ROWS/RANGE/GROUPS ...] )
```

At a high level:
* `FUNCTION_NAME` is the operation you're performing - e.g., `SUM(column)`, `RANK()`, etc. 
* `OVER` defines *which rows* are considered part of the calculation ("window").
```sql
SELECT 
    full_name,
    membership_tier,
    DENSE_RANK() OVER ()  -- window includes all rows
FROM users;
```

`PARTITION BY` divides the rows into groups ("partitions") that share the same values of the `PARTITION BY` expression(s). Each partition is processed independently, and the function result “resets” when moving between partitions.
```sql
SELECT 
    full_name,
    membership_tier,
    DENSE_RANK() OVER (PARTITION BY membership_tier)    -- window per membership_tier
FROM users;
```

`ORDER BY` defines the logical ordering of rows *within* each partition. This ordering matters for ranking functions  and for window frames that depend on order (like a running total).
```sql
SELECT 
    full_name,
    membership_tier,
    DENSE_RANK() OVER (PARTITION BY membership_tier ORDER BY joined_on)
FROM users;
```

`ROWS/RANGE/GROUPS` defines a sliding window ("frame") within the ordered partition, relative to the current row. 
```sql
SELECT
    author,
    title,
    published_year,
    AVG(published_year) OVER (
        PARTITION BY author
        ORDER BY published_year
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS rolling_avg_year
FROM books
ORDER BY author, published_year;
```
`ROWS BETWEEN 1 PRECEDING AND CURRENT ROW` limits the window to at most two rows per author: the current book plus the prior one in publication order. Swapping `ROWS` for `RANGE` would include every peer that shares the same `published_year`, while `GROUPS` treats each distinct `published_year` as a single unit. In other words, `GROUPS BETWEEN 1 PRECEDING AND CURRENT ROW` would bring in every title from the current year and every title from the immediately previous year for that author.

If `ROWS/RANGE/GROUPS` is omitted, most databases default to:
```sql
RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW   -- all rows from the start of the partition up to the current one
```

> Note: The concept of a “current row” only makes sense when an `ORDER BY` is present. 
> Without `ORDER BY`, there is no defined order within a partition, so the window frame automatically includes all rows in the partition.

PostgreSQL (and the SQL standard) support `FILTER` ( `WHERE` filter_clause ) that lets you apply a condition inside an aggregate or window function:
```sql
SUM(amount)  FILTER (WHERE type = 'sale') OVER (...)                -- PostgreSQL

SUM(CASE WHEN type = 'sale' THEN amount ELSE NULL END) OVER (...)   -- generalized, including Oracle/MySQL
```
As you can see above, `FILTER` is syntactic sugar for a conditional aggregation using a `CASE` statement inside the function.

`WINDOW` allows you to predefine a window and use it in various places in the query. 
```sql
SELECT
    b.author,
    b.title,
    b.published_year,
    COUNT(*) OVER author_titles AS titles_per_author,
    DENSE_RANK() OVER author_chronology AS publication_rank
FROM books AS b
WINDOW
    author_titles AS (PARTITION BY b.author),
    author_chronology AS (author_titles ORDER BY b.published_year);
```
This keeps queries concise and consistent when several functions share the same window definition.

<!-- /////////////////// -->
<!-- NULL -->
<!-- /////////////////// -->
### <a id="null-pitfalls" href="#table-of-contents">NULL PITFALLS</a>

`NULL` is SQL's way of saying "unknown". Its presence changes logic from two-valued (true/false) to three-valued logic (true/false/null). Any expression involving `NULL` evalutes to `NULL` and in conditional contexts, that means false. For example, `WHERE x = NULL` will never match any row, because the result of `x = NULL` is `NULL`, not true. 

This leads to some unintuitive outcomes and the need for special operators.
* `IS NULL`/`IS NOT NULL` is the only correct way to test if a value is or isn't `NULL`.
  ```sql
  ...
  WHERE checked_out_by IS NULL
  ```
Using `=` or `<>` won’t work, since `NULL` is never equal or not equal to anything.
* `IS DISTINCT FROM`/`IS NOT DISTINCT FROM` are equality operators that treat two `NULL`s as equal.
  ```sql
  ...
  WHERE NULL IS DISTINCT FROM NULL                  -- false
  
  ...
  WHERE NULL IS NOT DISTINCT FROM 'Leo Tolstoy'     -- false
  ```

A few important takeaways:
* An expression can be `NULL`, but it can never equal `NULL`.
* Two `NULL`s are not equal in normal comparisons, but are equal under `IS [NOT] DISTINCT FROM`.
* When testing numeric ranges, you must handle nulls explicitly.
* Aggregate functions ignore nulls except `COUNT(*)`, which counts every row regardless of column nulls.

To prevent `NULL` values in the first place, declare columns as `NOT NULL` in `CREATE TABLE`, even if you also provide a default value. This constraint enforces that the column can never store unknown data.

---

# <a id="advanced-queries-walkthrough" href="#table-of-contents">Advanced queries walkthrough</a>
This section walks through queries I wrote to answer some of the questions from CMU 15-445’s Spring 2025 [homework 1](https://15445.courses.cs.cmu.edu/spring2025/homework1/). All questions are based on [MusicBrainz dataset](https://musicbrainz.org/doc/MusicBrainz_Database).

The following figure illustrates the schema of the tables:
<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/intro-sql/images/schema2023-v2.png?raw=true" alt="first example" height="600" style="border: 1px solid black;">
</div>

#### Q2
Find all artists in the `United States` born on July 4th who ever released music in language other than `English`. List them in alphabetical order.\
**Hints**: Only consider the artists with artist type `Person`. `United States` is an area name. If a release is in `[Multiple languages]`, consider it as not `English`.
```sql
WITH consts AS (                                        -- table with one row
  SELECT
    (SELECT id FROM area         WHERE name = 'United States') AS us_id,
    (SELECT id FROM language     WHERE name = 'English')       AS english_id,
    (SELECT id FROM artist_type  WHERE name = 'Person')        AS person_type_id
)
SELECT A.name AS artist_name
FROM artist AS A, consts AS C                           -- cross join 2M x 1
WHERE A.area = C.us_id
  AND A.begin_date_month = 7
  AND A.begin_date_day   = 4
  AND A.type             = C.person_type_id
  AND EXISTS (
    SELECT 1
    FROM artist_credit_name AS ACN
    JOIN release AS R ON R.artist_credit = ACN.artist_credit
    WHERE ACN.artist = A.id
      AND R.language IS DISTINCT FROM C.english_id      -- treats NULL as non-English
  )
ORDER BY A.name;
```

Logically, here’s what the database is doing: 
* Performs a cross join – the `FROM artist AS A, consts AS C` clause logically creates a Cartesian product (cross join) of the two tables.
* Filters – the four simple `WHERE` conditions (`A.area`, `A.begin_date_month`, etc.) are applied, filtering down the massive result from the cross join.
* Applies a filter – the `EXISTS` clause is applied to each row that passed the previous step. It executes the correlated subquery, and if that subquery finds at least one row, `EXISTS` returns `TRUE` and the outer row is kept.
* Sorts – the `ORDER BY A.name` clause is applied last, sorting all the rows that passed all the filters.

Physically, the database executes things differently than the above conceptual evaluation for efficiency. You can see that by examining the execution plan (generated by prefixing the query with `EXPLAIN ANALYZE`):
```
Sort  (cost=184307.73..184307.74 rows=1 width=13) (actual time=402.189..410.001 rows=21.00 loops=1)
  Sort Key: a.name
  Sort Method: quicksort  Memory: 25kB
  Buffers: shared hit=15312 read=61239, temp read=16865 written=17192
  InitPlan 1
    ->  Seq Scan on area  (cost=0.00..2240.03 rows=1 width=8) (actual time=0.029..9.529 rows=1.00 loops=1)
          Filter: (name = 'United States'::text)
          Rows Removed by Filter: 118241
          Buffers: shared hit=762
  InitPlan 2
    ->  Seq Scan on artist_type  (cost=0.00..25.00 rows=6 width=8) (actual time=0.015..0.016 rows=1.00 loops=1)
          Filter: (name = 'Person'::text)
          Rows Removed by Filter: 5
          Buffers: shared hit=1
  InitPlan 3
    ->  Seq Scan on language  (cost=0.00..146.04 rows=1 width=8) (actual time=0.714..0.716 rows=1.00 loops=1)
          Filter: (name = 'English'::text)
          Rows Removed by Filter: 7842
          Buffers: shared hit=48
  ->  Gather  (cost=98439.57..181896.66 rows=1 width=13) (actual time=324.264..409.943 rows=21.00 loops=1)
            Workers Planned: 2
            Workers Launched: 2
            Buffers: shared hit=15312 read=61239, temp read=16865 written=17192
            ->  Parallel Hash Right Semi Join  (cost=97439.57..180896.56 rows=1 width=13) (actual time=315.113..387.673 rows=7.00 loops=3)
                  Hash Cond: (acn.artist = a.id)
                  Buffers: shared hit=14501 read=61239, temp read=16865 written=17192
                  ->  Parallel Hash Join  (cost=64622.65..137838.70 rows=2730912 width=8) (actual time=238.040..315.214 rows=341033.33 loops=3)
                        Hash Cond: (r.artist_credit = acn.artist_credit)
                        Buffers: shared hit=12000 read=44948, temp read=16865 written=17192
                        ->  Parallel Seq Scan on release r  (cost=0.00..42855.11 rows=1070437 width=8) (actual time=0.111..50.559 rows=286687.33 loops=3)
                              Filter: (language IS DISTINCT FROM (InitPlan 3).col1)
                              Rows Removed by Filter: 577000
                              Buffers: shared hit=3979 read=25381
                        ->  Parallel Hash  (cost=41112.73..41112.73 rows=1352473 width=16) (actual time=156.983..156.983 rows=1081978.67 loops=3)
                              Buckets: 262144  Batches: 32  Memory Usage: 6880kB
                              Buffers: shared hit=8021 read=19567, temp written=14024
                              ->  Parallel Seq Scan on artist_credit_name acn  (cost=0.00..41112.73 rows=1352473 width=16) (actual time=0.083..58.443 rows=1081978.67 loops=3)
                                    Buffers: shared hit=8021 read=19567
                  ->  Parallel Hash  (cost=32816.91..32816.91 rows=1 width=21) (actual time=61.299..61.299 rows=32.33 loops=3)
                        Buckets: 1024  Batches: 1  Memory Usage: 104kB
                        Buffers: shared hit=2501 read=16291
                        ->  Parallel Seq Scan on artist a  (cost=0.00..32816.91 rows=1 width=21) (actual time=4.875..61.018 rows=32.33 loops=3)
                              Filter: ((area = (InitPlan 1).col1) AND (begin_date_month = 7) AND (begin_date_day = 4) AND (type = (InitPlan 2).col1))
                              Rows Removed by Filter: 560964
                              Buffers: shared hit=2501 read=16291
Planning:
Buffers: shared hit=16
Planning Time: 0.380 ms
Execution Time: 410.072 ms
(49 rows)
```

Here’s what’s actually happening under the hood:
* Prepares constants — it runs three sequential scans to find the IDs for *United States*, *English*, and *Person*. These correspond exactly to the subqueries inside the `WITH consts` clause.
* Builds two hash tables — one from `artist_credit_name`, and another from `artist`.
* Scans and probes in parallel — While scanning the `release` table, PostgreSQL probes the `artist_credit_name` hash table to find which releases belong to which artists.
* Joins results — the combined `release × artist_credit_name` output is then used to probe the second hash table built from `artist`, returning only those artists that have at least one release in a non-English language.
* Gathers and sorts — finally, all worker threads send their results to the main process (`Gather`), which merges them and sorts the artist names alphabetically.

Note that the database is doing many things in parallel, which you can tell from the overlap of `actual time`s. 
> The actual time is presented as a range: `actual time=STARTUP_TIME..TOTAL_TIME`.\
> `STARTUP_TIME`: This is the time, in ms, it took a plan node to produce its first output row.\
> `TOTAL_TIME`: This is the time, in ms, it took a plan node to produce all its output rows.

#### Q4
List the releases with the longest names in each CD-based medium format. Sort the result alphabetically by medium format name, and then release name. If there is a tie, include them all in the result.\
**Details**: A medium is considered CD-based if its format name contains the word CD.
```sql
WITH RankedReleases AS (
    SELECT
        mf.name AS format_name,
        r.name AS release_name,
        RANK() OVER(PARTITION BY mf.name ORDER BY LENGTH(r.name) DESC) as rnk
    FROM
        release AS r
    JOIN
        medium AS m ON r.id = m.release
    JOIN
        medium_format AS mf ON m.format = mf.id
    WHERE
        mf.name LIKE '%CD%'
)
SELECT
    format_name,
    release_name
FROM
    RankedReleases
WHERE
    rnk = 1
ORDER BY
    format_name,
    release_name;
```

Logically, here's what the database is doing:
* Performs 2 JOIN operations across 3 tables (release → medium → medium_format) using inner joins
* Filters the joined result set to rows where `mf.name LIKE '%CD%'` (CD-based formats only)
* In the `RankedReleases` CTE, calculates a window function that:
  * Partitions the filtered data by `mf.name` (grouping by format)
  * Within each partition, assigns ranks using `RANK()` based on `LENGTH(r.name) DESC` (longest names first)
  * Note: `RANK()` assigns the same rank to releases with identical name lengths and creates gaps in the sequence (e.g., if two releases tie at rank 1, the next rank is 3)
* The outer query filters to `rnk = 1`, selecting all releases that have the longest name(s) within each CD format partition
* *Important*: If multiple releases within a format have the same maximum name length, all of them are included (not just one per format)
* Orders the final result set by `format_name ASC, release_name ASC`

```
Incremental Sort  (cost=157071.39..267558.33 rows=3704 width=32) (actual time=704.939..951.069 rows=103.00 loops=1)
   Sort Key: rankedreleases.format_name, rankedreleases.release_name
   Presorted Key: rankedreleases.format_name
   Full-sort Groups: 2  Sort Method: quicksort  Average Memory: 32kB  Peak Memory: 32kB
   Pre-sorted Groups: 3  Sort Method: quicksort  Average Memory: 25kB  Peak Memory: 25kB
   Buffers: shared hit=4294 read=49531, temp read=29883 written=30190
   ->  Subquery Scan on rankedreleases  (cost=157041.59..267391.65 rows=3704 width=32) (actual time=703.503..951.028 rows=103.00 loops=1)
            Filter: (rankedreleases.rnk = 1)
            Buffers: shared hit=4294 read=49531, temp read=29883 written=30190
            ->  WindowAgg  (cost=157041.59..258132.00 rows=740772 width=44) (actual time=703.502..951.020 rows=103.00 loops=1)
                  Window: w1 AS (PARTITION BY mf.name ORDER BY (length(r.name)) ROWS UNBOUNDED PRECEDING)
                  Run Condition: (rank() OVER w1 <= 1)
                  Storage: Memory  Maximum Storage: 18kB
                  Buffers: shared hit=4294 read=49531, temp read=29883 written=30190
                  ->  Gather Merge  (cost=157041.45..243316.56 rows=740772 width=36) (actual time=703.496..892.753 rows=1535653.00 loops=1)
                        Workers Planned: 2
                        Workers Launched: 2
                        Buffers: shared hit=4294 read=49531, temp read=29883 written=30190
                        ->  Sort  (cost=156041.43..156813.07 rows=308655 width=36) (actual time=695.186..745.311 rows=511884.33 loops=3)
                              Sort Key: mf.name, (length(r.name)) DESC
                              Sort Method: external merge  Disk: 20840kB
                              Buffers: shared hit=4294 read=49531, temp read=29883 written=30190
                              Worker 0:  Sort Method: external merge  Disk: 21160kB
                              Worker 1:  Sort Method: external merge  Disk: 20552kB
                              ->  Parallel Hash Join  (cost=61034.52..119456.83 rows=308655 width=36) (actual time=399.280..533.544 rows=511884.33 loops=3)
                                    Hash Cond: (m.release = r.id)
                                    Buffers: shared hit=4264 read=49531, temp read=22064 written=22344
                                    ->  Hash Join  (cost=2.31..44210.47 rows=308655 width=19) (actual time=1.204..134.570 rows=511884.33 loops=3)
                                          Hash Cond: (m.format = mf.id)
                                          Buffers: shared hit=3 read=24432
                                          ->  Parallel Seq Scan on medium m  (cost=0.00..36569.90 rows=1213790 width=16) (actual time=1.146..67.148 rows=971031.67 loops=3)
                                                Buffers: shared read=24432
                                          ->  Hash  (cost=2.03..2.03 rows=23 width=19) (actual time=0.050..0.050 rows=24.00 loops=3)
                                                Buckets: 1024  Batches: 1  Memory Usage: 10kB
                                                Buffers: shared hit=3
                                                ->  Seq Scan on medium_format mf  (cost=0.00..2.03 rows=23 width=19) (actual time=0.029..0.034 rows=24.00 loops=3)
                                                      Filter: (name ~~ '%CD%'::text)
                                                      Rows Removed by Filter: 58
                                                      Buffers: shared hit=3
                                    ->  Parallel Hash  (cost=40156.09..40156.09 rows=1079609 width=29) (actual time=184.892..184.892 rows=863687.33 loops=3)
                                          Buckets: 131072  Batches: 32  Memory Usage: 6176kB
                                          Buffers: shared hit=4261 read=25099, temp written=16280
                                          ->  Parallel Seq Scan on release r  (cost=0.00..40156.09 rows=1079609 width=29) (actual time=0.199..49.597 rows=863687.33 loops=3)
                                                Buffers: shared hit=4261 read=25099
Planning:
Buffers: shared hit=71 read=20
Planning Time: 6.842 ms
Execution Time: 952.429 ms
(48 rows)
```

Physically, here’s what’s happening:
* Builds hash tables – PostgreSQL first scans `medium_format`, filters to names matching `'%CD%'`, and builds a small in-memory hash table. It then scans `release` in parallel, building a much larger hash table that’s partially spilled to disk.
* Scans and probes in parallel – Multiple workers scan `medium`, probing the `medium_format` hash table first and then the `release` hash table, producing joined rows for CD-related releases.
* Sorts intermediate results – Each worker sorts its output by `mf.name` and `length(r.name)` (descending), using external merge sort due to size.
* Merges and ranks – The sorted outputs are merged (`Gather Merge`), and the `WindowAgg` node computes `RANK()` per `mf.name`, keeping only `rnk = 1`.
* Final incremental sort – The remaining rows are incrementally sorted by `format_name` and `release_name`, producing the final ordered result.

#### Q5
Find the 11 artists who released most christmas songs. For each artist, list their oldest five releases in November with valid release date. Organize the results by the number of each artist's christmas songs, highest to lowest. If two artists released the same number of christmas songs, order them alphabetically. After that, organize the release name alphabetically, and finally by the release date, oldest to newest.

**Details**: Only consider `Person` artists. A release is a `christmas` song if its name contains the word christmas, case-insensitively. When finding the 11 artists, if there's a tie, artists who comes first in alphabetical order takes the priority. A date is valid if it has non-null values for the year, month, and day. When counting the number of christmas songs, simply count the number of distinct release IDs. However, when finding the five oldest releases in November, releases with same name and date are considered the same. If some of the 11 artists wrote releases less than five in November, just include all of them. Format release date in the result as `YYYY-MM-DD`, without adding a leading zero if the month or day is less than `10`.

```sql
-- Use a CTE to find the top 11 artists based on their Christmas song count
WITH TopArtists AS (
    SELECT
        a.id AS artist_id,
        a.name AS artist_name,
        COUNT(DISTINCT r.id) AS christmas_song_count
    FROM
      artist AS a
    JOIN
      artist_type AS at ON a.type = at.id
    JOIN
      artist_credit_name AS acn ON a.id = acn.artist
    JOIN
      release AS r ON acn.artist_credit = r.artist_credit
    WHERE
      at.name = 'Person' AND
      r.name ILIKE '%christmas%'
    GROUP BY
      a.id, a.name
    ORDER BY
      christmas_song_count DESC, a.name ASC
    LIMIT 11
)
-- For each artist from the CTE, find their 5 oldest November releases
SELECT
    ta.artist_name,
    nov_releases.release_name,
    nov_releases.release_date
FROM TopArtists AS ta,
LATERAL (
    SELECT
        t.release_name,
        t.release_date,
        t.date_year, t.date_month, t.date_day
    FROM (
        SELECT DISTINCT -- Ensures releases with the same name and date are treated as one
            r.name as release_name,
            (ri.date_year || '-' || ri.date_month || '-' || ri.date_day) AS release_date,
            ri.date_year, ri.date_month, ri.date_day
        FROM artist_credit_name acn
        JOIN release r ON acn.artist_credit = r.artist_credit
        JOIN release_info ri ON r.id = ri.release
        WHERE acn.artist = ta.artist_id -- This correlation is the key part of the LATERAL join
            AND ri.date_month = 11
            AND ri.date_year IS NOT NULL AND ri.date_month IS NOT NULL AND ri.date_day IS NOT NULL
    ) AS t
    ORDER BY t.date_year ASC, t.date_month ASC, t.date_day ASC
    LIMIT 5
) AS nov_releases
-- Apply the final, complex ordering
ORDER BY
    ta.christmas_song_count DESC,
    ta.artist_name ASC,
    nov_releases.release_name ASC,
    nov_releases.date_year ASC, nov_releases.date_month ASC, nov_releases.date_day ASC;
```

Logically, here's what the database is doing:

* In the `TopArtists` CTE, it performs 3 JOIN operations across 4 tables (artist → artist_type, artist → artist_credit_name → release)
* Filters to artists where `at.name = 'Person'` and their releases match `r.name ILIKE '%christmas%'`
* Groups by `a.id, a.name` and counts distinct Christmas releases per artist
* Orders by `christmas_song_count DESC, a.name ASC` and selects the top 11 artists
* For each of these 11 artists, it executes a correlated LATERAL subquery that:
  * Performs 2 JOIN operations across 3 tables (artist_credit_name → release → release_info)
  * Filters to November releases (`ri.date_month = 11`) with complete dates (year, month, and day all NOT NULL)
  * Applies DISTINCT to deduplicate releases with identical names and dates
  * Orders by complete date ascending (`date_year ASC, date_month ASC, date_day ASC`)
  * Returns up to the 5 oldest November releases for that artist
* Because the LATERAL join is an inner join, artists with fewer than 5 (or zero) November releases will contribute fewer rows (or no rows) to the final result
* Finally, orders the complete result set by: `christmas_song_count DESC, artist_name ASC, release_name ASC, date_year ASC, date_month ASC, date_day ASC`

```
Incremental Sort  (cost=210454.47..862909.81 rows=33 width=98) (actual time=2904.868..3329.382 rows=42.00 loops=1)
   Sort Key: (count(DISTINCT r.id)) DESC, a.name, r_1.name, ri.date_year, ri.date_month, ri.date_day
   Presorted Key: (count(DISTINCT r.id)), a.name
   Full-sort Groups: 2  Sort Method: quicksort  Average Memory: 28kB  Peak Memory: 28kB
   Buffers: shared hit=140916 read=325624
   ->  Nested Loop  (cost=145209.00..862908.91 rows=33 width=98) (actual time=859.597..3329.328 rows=42.00 loops=1)
         Buffers: shared hit=140916 read=325624
         ->  Limit  (cost=73439.06..73439.09 rows=11 width=29) (actual time=599.792..600.172 rows=11.00 loops=1)
               Buffers: shared hit=42685 read=52939
               ->  Sort  (cost=73439.06..73439.10 rows=16 width=29) (actual time=599.791..600.170 rows=11.00 loops=1)
                     Sort Key: (count(DISTINCT r.id)) DESC, a.name
                     Sort Method: top-N heapsort  Memory: 26kB
                     Buffers: shared hit=42685 read=52939
                     ->  GroupAggregate  (cost=73438.42..73438.74 rows=16 width=29) (actual time=598.714..599.921 rows=3107.00 loops=1)
                           Group Key: a.id, a.name
                           Buffers: shared hit=42685 read=52939
                           ->  Sort  (cost=73438.42..73438.46 rows=16 width=29) (actual time=598.706..599.204 rows=5606.00 loops=1)
                                 Sort Key: a.id, a.name, r.id
                                 Sort Method: quicksort  Memory: 461kB
                                 Buffers: shared hit=42685 read=52939
                                 ->  Nested Loop  (cost=44852.80..73438.10 rows=16 width=29) (actual time=502.098..597.789 rows=5606.00 loops=1)
                                        Join Filter: (a.type = at.id)
                                        Rows Removed by Join Filter: 7903
                                        Buffers: shared hit=42685 read=52939
                                        ->  Gather  (cost=44852.80..73353.87 rows=658 width=37) (actual time=502.071..595.713 rows=13509.00 loops=1)
                                              Workers Planned: 2
                                              Workers Launched: 2
                                              Buffers: shared hit=42684 read=52939
                                              ->  Parallel Hash Join  (cost=43852.80..72288.07 rows=274 width=37) (actual time=496.189..589.757 rows=4503.00 loops=3)
                                                    Hash Cond: (a.id = acn.artist)
                                                    Buffers: shared hit=42684 read=52939
                                                    ->  Parallel Seq Scan on artist a  (cost=0.00..25804.45 rows=701245 width=29) (actual time=0.540..66.144 rows=560996.33 loops=3)
                                                          Buffers: shared hit=212 read=18580
                                                    ->  Parallel Hash  (cost=43849.38..43849.38 rows=274 width=16) (actual time=495.424..495.425 rows=4503.00 loops=3)
                                                          Buckets: 16384 (originally 1024)  Batches: 1 (originally 1)  Memory Usage: 920kB
                                                          Buffers: shared hit=42472 read=34359
                                                          ->  Nested Loop  (cost=0.43..43849.38 rows=274 width=16) (actual time=1.113..395.339 rows=4503.00 loops=3)
                                                                Buffers: shared hit=42472 read=34359
                                                                ->  Parallel Seq Scan on release r  (cost=0.00..42855.11 rows=108 width=16) (actual time=0.736..274.984 rows=3950.67 loops=3)
                                                                      Filter: (name ~~* '%christmas%'::text)
                                                                      Rows Removed by Filter: 859737
                                                                      Buffers: shared hit=1455 read=27905
                                                                ->  Index Scan using idx_16602_ix_artist_credit_name on artist_credit_name acn  (cost=0.43..9.18 rows=3 width=16) (actual time=0.030..0.030 rows=1.14 loops=11852)
                                                                      Index Cond: (artist_credit = r.artist_credit)
                                                                      Index Searches: 11852
                                                                      Buffers: shared hit=41017 read=6454
                                        ->  Materialize  (cost=0.00..25.03 rows=6 width=8) (actual time=0.000..0.000 rows=1.00 loops=13509)
                                              Storage: Memory  Maximum Storage: 17kB
                                              Buffers: shared hit=1
                                              ->  Seq Scan on artist_type at  (cost=0.00..25.00 rows=6 width=8) (actual time=0.012..0.012 rows=1.00 loops=1)
                                                    Filter: (name = 'Person'::text)
                                                    Rows Removed by Filter: 5
                                                    Buffers: shared hit=1
        ->  Limit  (cost=71769.94..71769.94 rows=3 width=77) (actual time=248.102..248.103 rows=3.82 loops=11)
              Buffers: shared hit=98231 read=272685
              ->  Sort  (cost=71769.94..71769.94 rows=3 width=77) (actual time=248.101..248.101 rows=3.82 loops=11)
                    Sort Key: ri.date_year, ri.date_month, ri.date_day
                    Sort Method: top-N heapsort  Memory: 26kB
                    Buffers: shared hit=98231 read=272685
                    ->  Unique  (cost=71769.88..71769.91 rows=3 width=77) (actual time=248.090..248.096 rows=23.91 loops=11)
                          Buffers: shared hit=98231 read=272685
                          ->  Sort  (cost=71769.88..71769.88 rows=3 width=77) (actual time=248.089..248.090 rows=46.09 loops=11)
                                Sort Key: r_1.name, ((((((ri.date_year)::text || '-'::text) || (ri.date_month)::text) || '-'::text) || (ri.date_day)::text)), ri.date_year, ri.date_day
                                Sort Method: quicksort  Memory: 47kB
                                Buffers: shared hit=98231 read=272685
                                ->  Nested Loop  (cost=0.86..71769.85 rows=3 width=77) (actual time=14.636..248.033 rows=46.09 loops=11)
                                      Buffers: shared hit=98231 read=272685
                                      ->  Nested Loop  (cost=0.43..71692.47 rows=57 width=29) (actual time=7.436..134.629 rows=948.00 loops=11)
                                            Buffers: shared hit=68942 read=261975
                                            ->  Seq Scan on artist_credit_name acn_1  (cost=0.00..68162.20 rows=28 width=8) (actual time=2.361..118.269 rows=549.18 loops=11)
                                                  Filter: (artist = a.id)
                                                  Rows Removed by Filter: 3245387
                                                  Buffers: shared hit=51362 read=252106
                                            ->  Index Scan using idx_16637_ix_release_artist_credit on release r_1  (cost=0.43..125.74 rows=34 width=37) (actual time=0.024..0.029 rows=1.73 loops=6041)
                                                  Index Cond: (artist_credit = acn_1.artist_credit)
                                                  Index Searches: 6041
                                                  Buffers: shared hit=17580 read=9869
                                      ->  Index Scan using idx_16642_ix_release_info_release on release_info ri  (cost=0.43..1.35 rows=1 width=32) (actual time=0.119..0.119 rows=0.05 loops=10428)
                                            Index Cond: (release = r_1.id)
                                            Filter: ((date_year IS NOT NULL) AND (date_month IS NOT NULL) AND (date_day IS NOT NULL) AND (date_month = 11))
                                            Rows Removed by Filter: 1
                                            Index Searches: 10428
                                            Buffers: shared hit=29289 read=10710
Planning:
Buffers: shared hit=48
Planning Time: 1.404 ms
Execution Time: 3329.541 ms
(87 rows)
```

> A "Materialize" node in an `EXPLAIN ANALYZE` output indicates that the output of a sub-plan is being stored in a temporary area (usually memory or disk) for later reuse by an upstream node.

# <a id="optimizations" href="#table-of-contents">Optimizations</a>

#### WHERE
Keep filters simple so that the database can match them against indexes and avoid expensive full-table scans.

#### LIMIT AND OFFSET
Pagination is a common use case for `LIMIT` and `OFFSET`: fetching the first X rows with `LIMIT`, then skipping over previously retrieved ones in subsequent queries with `OFFSET`. This implementation is a subpar alternative when indexes exist on the ordering columns – the database must still process all preceding rows before skipping them.

A more efficient alternative is to use a top-N hint (recognized by most databases) for the initial set of results and then use `WHERE` based on specific key ranges for subsequent queries. This method, known as **keyset pagination**, allows the database to jump directly to the next page using indexed lookups.

# <a id="conclusion" href="#table-of-contents">Conclusion</a>

# <a id="references" href="#table-of-contents">References</a>
[^1]: FROM → WHERE → SELECT
[^2]: FROM → WHERE → GROUP BY → SELECT → ORDER BY → LIMIT/OFFSET
[^3]: Codd, E.F (1970). "A Relational Model of Data for Large Shared Data Banks". Communications of the ACM. Classics. 13 (6): 377–87. doi:10.1145/362384.362685. S2CID 207549016.
