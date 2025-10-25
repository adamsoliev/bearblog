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
This section walks through 9 queries I wrote to answer questions from CMU 15-445’s Spring 2025 [homework 1](https://15445.courses.cs.cmu.edu/spring2025/homework1/). All questions are based on [MusicBrainz dataset](https://musicbrainz.org/doc/MusicBrainz_Database).

The following figure illustrates the schema of the tables:
<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/intro-sql/images/schema2023-v2.png?raw=true" alt="first example" height="600" style="border: 1px solid black;">
</div>

#### Q2
Find all artists in the `United States` born on July 4th who ever released music in language other than `English`. List them in alphabetical order.\
**Hints**: Only consider the artists with artist type `Person`. `United States` is an area name. If a release is in `[Multiple languages]`, consider it as not `English`.
```sql
WITH consts AS (        -- table with one row
  SELECT
    (SELECT id FROM area         WHERE name = 'United States') AS us_id,
    (SELECT id FROM language     WHERE name = 'English')       AS english_id,
    (SELECT id FROM artist_type  WHERE name = 'Person')        AS person_type_id
)
SELECT A.name AS artist_name
FROM artist AS A, consts AS C -- cross join 2M x 1
WHERE A.area = C.us_id
  AND A.begin_date_month = 7
  AND A.begin_date_day   = 4
  AND A.type             = C.person_type_id
  AND EXISTS (
    SELECT 1
    FROM artist_credit_name AS ACN
    JOIN release AS R ON R.artist_credit = ACN.artist_credit
    WHERE ACN.artist = A.id
      AND R.language IS DISTINCT FROM C.english_id  -- treats NULL as non-English
  )
ORDER BY A.name;
```

Query plan looks like this

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

3 `InitPlan`s do sequencial scan on 3 tables, cleanly mapping with `WITH consts`. Notable thing here is all reads here hit cache (`Buffers: shared X`). They all finish within 10 ms (`9.529`). are all three done by one thread? if so, why doesn't actual times follow linear time? 

`Parallel Seq Scan on artist a` is scanning the table artist with 2 workers using the filter condition. It spends ~56 ms (`61.018` - `4.875`) to do this and hits cache 2501 times (recall each pg page is 8KB and cache hit refers to this page), reading from disk 16291 times.  (given two workers (`Workers Launched: 2`), do `rows=32.33 loops=3` mean that each thread produced 32.33 rows per loop iteration and hence outputted 3 * 32.33 * 2 = 194 rows?)

Parent `Parallel Hash` means two workers are building a hashtable (#2) based on Parallel Seq Scan on `artist`. Hash table takes 103kB RAM and is partitioned into 1024 hash buckets. Note that the hash table stores the join key(s) (in the plan: `a.id`) and the associated row payload (the ~21-byte width row, or whichever columns are needed for the join/output). Since `actual time=61.299..61.299` and cache hit is the same with Parallel Seq Scan on `artist`, does it mean that hash table is being built while the sequential scan is ongoing? 

Similar to the above discussion, `Parallel Hash Join` builds a hashtable (#1) on `artist_credit_name` first and then probes it with the output of Parallel Seq Scan on `release`.  

`Parallel Hash Right Semi Join` then probes hashtable #2 (based on `artist`) with the `release x artist_credit_name` output.

`Gather` collects rows from all workers and merges them into a single output, after which `Sort` displays the result set in the specified order.

#### Q3
Find the ten latest collaborative releases. Only consider the releases with valid release date. Order the results by release date from newest to oldest, and then by release name alphabetically.\
**Details**: A release is collaborative if two or more artists are involved in it. A date is valid if it has non-null values for the year, month, and day. Format the release date in the result as `YYYY-MM-DD`, without adding leading zeros if the month or day is less than `10`.\
**Hints**: The `artist_count` field in `artist_credit` table denotes the number of artists involved in a release.
```sql
SELECT
  (ri.date_year || '-' || ri.date_month || '-' || ri.date_day) AS RELEASE_DATE,
  r.name AS RELEASE_NAME,
  ac.artist_count AS ARTIST_COUNT
FROM release AS r
JOIN artist_credit AS ac ON r.artist_credit = ac.id
JOIN release_info AS ri ON r.id = ri.release
WHERE
  ac.artist_count > 1
  AND ri.date_year IS NOT NULL
  AND ri.date_month IS NOT NULL
  AND ri.date_day IS NOT NULL
ORDER BY
  -- in most dbs, `order by` clause defaults to ASC
  ri.date_year DESC, ri.date_month DESC, ri.date_day DESC, r.name
LIMIT 10;
```

#### Q4
List the releases with the longest names in each CD-based medium format. Sort the result alphabetically by medium format name, and then release name. If there is a tie, include them all in the result.\
**Details**: A medium is considered CD-based if its format name contains the word `CD`.

```sql
WITH RankedReleases AS (
    SELECT
          mf.name AS format_name,
          r.name AS release_name,
          RANK() OVER(PARTITION BY mf.name ORDER BY LENGTH(r.name) DESC) as rnk
    FROM  release AS r
    JOIN  medium AS m ON r.id = m.release
    JOIN  medium_format AS mf ON m.format = mf.id
    WHERE mf.name LIKE '%CD%'
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

#### Q5
Find the 11 artists who released most christmas songs. For each artist, list their oldest five releases in November with valid release date. Organize the results by the number of each artist's christmas songs, highest to lowest. If two artists released the same number of christmas songs, order them alphabetically. After that, organize the release name alphabetically, and finally by the release date, oldest to newest.\
**Details**: Only consider `Person` artists. A release is a christmas song if its name contains the word `christmas`, case-insensitively. When finding the 11 artists, if there's a tie, artists who comes first in alphabetical order takes the priority. A date is valid if it has non-null values for the year, month, and day. When counting the number of christmas songs, simply count the number of distinct release IDs. However, when finding the five oldest releases in November, releases with same name and date are considered the same. If some of the 11 artists wrote releases less than five in November, just include all of them. Format release date in the result as `YYYY-MM-DD`, without adding a leading zero if the month or day is less than `10`.

```sql
-- Step 1: Use a CTE to find the top 11 artists based on their Christmas song count
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
      r.name LIKE '%christmas%'
    GROUP BY
      a.id, a.name
    ORDER BY
      christmas_song_count DESC, a.name ASC
    LIMIT 11
)
-- Step 2: For each artist from the CTE, find their 5 oldest November releases
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
-- Step 3: Apply the final, complex ordering
ORDER BY
    ta.christmas_song_count DESC,
    ta.artist_name ASC,
    nov_releases.release_name ASC,
    nov_releases.date_year ASC, nov_releases.date_month ASC, nov_releases.date_day ASC;
```

#### Q6
Find the artists in the `United States` whose last release and second last release were both in 1999. Order the result by artist name, last release name, and second last release name alphabetically.
**Details**: If there are releases with identical names and dates by the same artist, treat them as a single release and avoid duplicate entries. Only consider releases with a valid date. A date is valid if it has non-null values for the year, month, and day. If two releases occurred on the same date, we consider the release with the name that comes first in alphabetical order as the first release.

```sql
-- Step 1: Rank all releases for each artist in the US from newest to oldest
WITH AllRankedReleases AS (
    SELECT
        artist_name,
        release_name,
        release_year,
        ROW_NUMBER() OVER (
            PARTITION BY artist_id
            ORDER BY release_year DESC, release_month DESC, release_day DESC, release_name ASC
        ) as rn
    FROM (
        -- Inner query to get distinct releases
        SELECT DISTINCT
            a.id AS artist_id,
            a.name AS artist_name,
            r.name AS release_name,
            ri.date_year AS release_year,
            ri.date_month AS release_month,
            ri.date_day AS release_day
        FROM artist AS a
        JOIN area ON a.area = area.id
        JOIN artist_credit_name AS acn ON a.id = acn.artist
        JOIN release AS r ON acn.artist_credit = r.artist_credit
        JOIN release_info AS ri ON r.id = ri.release
        WHERE
            area.name = 'United States'
            AND ri.date_year IS NOT NULL
            AND ri.date_month IS NOT NULL
            AND ri.date_day IS NOT NULL
    )
),
-- Step 2: Pivot the top two releases and their years into a single row per artist
PivotedReleases AS (
    SELECT
        artist_name,
        MAX(CASE WHEN rn = 1 THEN release_name END) AS LAST_RELEASE_NAME,
        MAX(CASE WHEN rn = 2 THEN release_name END) AS SECOND_LAST_RELEASE_NAME,
        MAX(CASE WHEN rn = 1 THEN release_year END) AS LAST_RELEASE_YEAR,
        MAX(CASE WHEN rn = 2 THEN release_year END) AS SECOND_LAST_RELEASE_YEAR
    FROM AllRankedReleases
    WHERE rn <= 2
    GROUP BY artist_name
)
-- Step 3: Filter for artists whose top two releases were in 1999 and format the output
SELECT
    ARTIST_NAME,
    LAST_RELEASE_NAME,
    SECOND_LAST_RELEASE_NAME
FROM PivotedReleases
WHERE
    LAST_RELEASE_YEAR = 1999
    AND SECOND_LAST_RELEASE_YEAR = 1999
ORDER BY
    ARTIST_NAME,
    LAST_RELEASE_NAME,
    SECOND_LAST_RELEASE_NAME;
```

#### Q7
Find the ten youngest collaborators of the `Pittsburgh Symphony Orchestra`. Exclude the `Pittsburgh Symphony Orchestra` itself from the final result. Organize the result by the collaborator's begin date, youngest to oldest, and then alphabetical order on their names. Only consider the artists with valid `begin_date`.\
**Details**: An artist is considered a collaborator if they appear in the same artist credit. An artist is younger than another if they has later `begin_date`. A date is valid if it has non-null values for the year, month, and day. Format the begin date as `YYYY-MM-DD`, without adding a leading zero if the month or day is less than 10. Please always use the `name` field in the `artist` table when searching for a specific artist name.

```sql
-- Step 1: Find all artist_credit IDs that include the orchestra
WITH OrchestraCredits AS (
    SELECT
        acn.artist_credit
    FROM artist AS a
    JOIN artist_credit_name AS acn ON a.id = acn.artist
    WHERE a.name = 'Pittsburgh Symphony Orchestra'
),
-- Step 2: Find all unique artist IDs that share those credits, excluding the orchestra itself
CollaboratorIDs AS (
    SELECT DISTINCT
        acn.artist AS collaborator_id
    FROM artist_credit_name AS acn
    WHERE
        acn.artist_credit IN (SELECT artist_credit FROM OrchestraCredits)
        AND acn.artist != (SELECT id FROM artist WHERE name = 'Pittsburgh Symphony Orchestra')
)
-- Step 3: Select the collaborators' details, apply filters, and order the final result
SELECT
    a.name AS COLLABORATOR_NAME,
    (a.begin_date_year || '-' || a.begin_date_month || '-' || a.begin_date_day) AS BEGIN_DATE
FROM artist AS a
JOIN CollaboratorIDs AS c ON a.id = c.collaborator_id
WHERE
    a.begin_date_year IS NOT NULL
    AND a.begin_date_month IS NOT NULL
    AND a.begin_date_day IS NOT NULL
ORDER BY
    a.begin_date_year DESC,
    a.begin_date_month DESC,
    a.begin_date_day DESC,
    a.name ASC
LIMIT 10;
```

#### Q8
For each area, find the language with most releases from the artists in that area. Only include the areas where the most popular language has minimum of `5000` releases (inclusive). Arrange the results in descending order based on the release count (per language per area), and in alphabetical order by area name.\
**Details**: When counting the number of releases, count the number of distinct release ids. If two areas have different ids with same names, treat them as the same area. When selecting the most popular language for each area, if there is a tie, choose the one which its language name comes first alphabetically. Note that we are interested in the area of artists, not the area of releases.

```sql
-- Step 1: Count releases for each language in each ARTIST's area.
WITH LanguageCountsPerArea AS (
    SELECT
        ar.name AS area_name,
        l.name AS language_name,
        COUNT(DISTINCT r.id) AS release_count
    FROM area AS ar
    JOIN artist AS a ON ar.id = a.area
    JOIN artist_credit_name AS acn ON a.id = acn.artist
    JOIN release AS r ON acn.artist_credit = r.artist_credit
    JOIN language AS l ON r.language = l.id
    GROUP BY
        ar.name,
        l.name
),
-- Step 2: Rank languages within each area to find the most popular one, handling ties.
RankedLanguages AS (
    SELECT
        area_name,
        language_name,
        release_count,
        ROW_NUMBER() OVER(
            PARTITION BY area_name
            ORDER BY release_count DESC, language_name ASC
        ) as rn
    FROM LanguageCountsPerArea
)
-- Step 3: Select the top language for each area and apply the final filters and ordering.
SELECT
    AREA_NAME,
    LANGUAGE_NAME,
    RELEASE_COUNT
FROM RankedLanguages
WHERE
    rn = 1
    AND release_count >= 5000
ORDER BY
    release_count DESC,
    area_name ASC;
```

#### Q9
For each decade from 1950s to 2010s (inclusive), count the number of non-US artists who has a US release in the same decade with their retirement. Order the result by decade, from oldest to newest.\
**Details**: Print the decade in a string format like `1950s`. Use `end_date_year` to decide the retirement year.

```sql
-- Step 1: Identify non-US artists and their retirement decade from the 1950s to 2010s.
WITH ArtistDecade AS (
  SELECT
    id AS artist_id,
    CAST(FLOOR(end_date_year / 10) * 10 AS TEXT) || 's' AS retirement_decade
  FROM artist
  WHERE
    end_date_year BETWEEN 1950 AND 2019
    AND area != (
      SELECT
        id
      FROM area
      WHERE
        name = 'United States'
    )
),
-- Step 2: Identify US releases and the decade they were released in.
ReleaseDecade AS (
  SELECT
    T3.artist AS artist_id,
    CAST(FLOOR(T1.date_year / 10) * 10 AS TEXT) || 's' AS release_decade
  FROM release_info AS T1
  INNER JOIN release AS T2
    ON T1.release = T2.id
  INNER JOIN artist_credit_name AS T3
    ON T2.artist_credit = T3.artist_credit
  WHERE
    T1.area = (
      SELECT
        id
      FROM area
      WHERE
        name = 'United States'
    )
)
-- Step 3: Count the artists who appear in both CTEs for the same decade.
SELECT
  T1.retirement_decade AS DECADE,
  COUNT(DISTINCT T1.artist_id) AS RELEASE_COUNT
FROM ArtistDecade AS T1
INNER JOIN ReleaseDecade AS T2
  ON T1.artist_id = T2.artist_id
  AND T1.retirement_decade = T2.release_decade
GROUP BY
  T1.retirement_decade
ORDER BY
  T1.retirement_decade;
```

#### Q10
Find all releases before 1950 (inclusive) created by artists from multiple areas. Exclude if at least one of its artists are from the `United States`. For each release, print the release name, year, the number of distinct areas where its artists are from, and the list of area names in alphabetical order, separated by commas. Order the result by the area count, highest to lowest, and then by the release year, oldest to newest, and then by the release name alphabetically.

```sql
WITH ReleaseArtistInfo AS (
  -- By adding DISTINCT here, we ensure that for any given release,
  -- each artist area is listed only once.
  SELECT DISTINCT
    T1.name AS release_name,
    T2.date_year AS release_year,
    T6.name AS artist_area_name,
    T1.id AS release_id
  FROM release AS T1
  INNER JOIN release_info AS T2
    ON T1.id = T2.release
  INNER JOIN artist_credit AS T3
    ON T1.artist_credit = T3.id
  INNER JOIN artist_credit_name AS T4
    ON T3.id = T4.artist_credit
  INNER JOIN artist AS T5
    ON T4.artist = T5.id
  INNER JOIN area AS T6
    ON T5.area = T6.id
  WHERE
    T2.date_year <= 1950
)
-- Now, aggregate the unique information for each release.
SELECT
  release_name AS RELEASE_NAME,
  release_year AS RELEASE_YEAR,
  -- This COUNT still works as intended.
  COUNT(artist_area_name) AS ARTIST_AREA_COUNT,
  -- This GROUP_CONCAT no longer needs DISTINCT because the CTE already handled it.
  -- This avoids the syntax error.
  GROUP_CONCAT(artist_area_name, ', ') AS ARTIST_AREA_NAMES
FROM ReleaseArtistInfo
GROUP BY
  release_id,
  release_name,
  release_year
HAVING
  -- The logic for the HAVING clause remains the same and is still correct.
  COUNT(artist_area_name) > 1
  AND
  SUM(CASE WHEN artist_area_name = 'United States' THEN 1 ELSE 0 END) = 0
-- The final ordering is unchanged.
ORDER BY
  ARTIST_AREA_COUNT DESC,
  release_year ASC,
  release_name ASC;
```


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
