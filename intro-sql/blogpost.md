#### Table of Contents
* [What and why](#what-and-why)
* [Relational Model](#relational-model)
* [Basic SQL](#basic-sql)
  * [SELECT-FROM-WHERE](#select-from-where)
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
This is my introduction to SQL. Unlike countless other intros, I try to explain the language in a less superficial way, starting from the relational model and then shifting to the user’s point of view, walking through queries from basic to advanced. I use basic queries to explain different clauses and how each fits into SQL’s logical flow. In the advanced section, I break down how complex queries are executed: first logically (the conceptual, step-by-step order of operations) and then physically (what databases actually execute). The post ends with a look at SQL performance.

I wrote this mostly to clarify my thinking. Along the way, I cut what’s easy to find elsewhere and kept what took effort to learn. If you have thoughts or feedback, please reach out :)

# <a id="relational-model" href="#table-of-contents">Relational model</a>

The relational model is built on a simple idea borrowed from mathematics: a relation is just a set of tuples.

Formally, given sets $S1$, $S2$, $\dots$, $Sn$ (called **domains**), a relation $R$ on these sets is any set of $n$-tuples where each tuple’s first value comes from $S1$, its second from $S2$, and so on. In database terms, a relation is a **table**, a tuple is a **row**, and the sets $S1$, $S2$, $\dots$, $Sn$ define the permissible values for each column.

For example, imagine you have three sets:

* **$S_1 = \{12, 75, 32, 54, 98\}$** (a set of IDs)
* **$S_2 = \{"John", "Michael", "Saun"\}$** (a set of names)
* **$S_3 = \{2023$-$10$-$02, 2022$-$07$-$11, 2025$-$01$-$12, 2019$-$03$-$27, 2026$-$12$-$03\}$** (a set of dates)

A possible table $R$ on these three sets could be:

| ID | Name | Date |
|---|---|---|
| 12 | Michael | 2023-10-02 |
| 75 | Michael | 2022-07-11 |
| 32 | John | 2022-07-11 |

Each of the three rows of $R$ consist of the same columns (`ID`, `Name`, `Date`). Each column is of a specific data type (`INTEGER`, `TEXT`, `DATE`). Whereas columns have a fixed order in each row, the order of the rows within the table isn't guaranteed in any way (although they can be explicitly sorted for display).

The relational model would treat the `ID` column in $R$ as the **primary key** because it uniquely identifies each row. In practice, a primary key can also span multiple columns, as long as their combination remains unique. Another table, say $N$, could include a column that stores values matching `ID` in $R$. This column would serve as a **foreign key**, creating a logical link between a row in $R$ and a row in $N$.

Formally, the relational model is much more involved but its practical application boils down to the above ideas, namely: 
* data is organized as tables 
* each row within a table is unique 
* the order of columns is fixed
* tables reference each other using foreign keys

This turned out to be the right abstaction for databases, providing a maximum degree of data independence (separating the logical view of data from its physical storage) and effectively solves issues of data inconsistency.

This data independence then provided a basis for high-level query languages. This evolution started with languages like COLARD and RIL, which were based on predicate calculus. These later inspired SQUARE, which still relied on the terse mathematical notation [sequel paper](), and eventually led to SEQUEL (now SQL), which introduced the accessible, English-keyword template form used today.

# <a id="basic-sql" href="#table-of-contents">Basic SQL</a>

SQL is often divided into four sublanguages:
- extracting data from tables (eg `SELECT`).
- defining and modifying database objects (eg `CREATE`, `ALTER`, `DROP`).
- managing user access and permissions (eg `GRANT`, `REVOKE`).
- inserting, updating, or deleting table data (eg `INSERT`, `UPDATE`, `DELETE`).

In this intro, I mainly focus on the first, as that's where most of the complexity and confusion lie. All examples will use the PostgreSQL dialect of SQL and rely on the following schema.

```sql
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    joined_on DATE NOT NULL,
    membership_tier TEXT NOT NULL                       -- standard, premium, student
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
    checked_out_by INTEGER REFERENCES users (user_id)   -- null if unchecked
);
```

<!-- /////////////////// -->
<!-- SELECT-FROM-WHERE -->
<!-- /////////////////// -->
### <a id="select-from-where" href="#table-of-contents">SELECT-FROM-WHERE</a>

#### SELECT

In SQL, the `SELECT-FROM-WHERE` block forms a basic query by specifying which columns to `SELECT` from a particular table (`FROM`) and filtering for rows that satisfy one or more conditions (`WHERE`).

```sql
SELECT title, author 
FROM books
WHERE genre='Non-fiction';
```

Each column in `SELECT` can be sourced from a base table (created with `CREATE TABLE`), a literal value, an expression or an aggregate/scalar function. You can also rename any column using `AS` with an alias for clarity or reuse. For example, 
```sql
SELECT
    title,                                              -- base column
    'library dataset' AS dataset_label,                 -- literal value
    published_year + 1 AS next_publication_year,        -- expression
    upper(author) AS author_upper                       -- scalar function
FROM
    books
WHERE genre='Non-fiction';
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
FROM books AS b
WHERE genre='Non-fiction';
```

#### FROM

Each table in `FROM` can be a base table, a derived table (created with a subquery like `(SELECT …)`), a join, or a combination of these.

You can also specify *how* these tables relate to each other using a join condition — written with `ON`, or its shorthand forms `USING` and `NATURAL`:

```
T1 { [INNER] | { LEFT | RIGHT | FULL } [OUTER] } JOIN T2 ON boolean_expression
T1 { [INNER] | { LEFT | RIGHT | FULL } [OUTER] } JOIN T2 USING ( join column list )
T1 NATURAL { [INNER] | { LEFT | RIGHT | FULL } [OUTER] } JOIN T2
```
`INNER` and `OUTER` are optional; `INNER` is the default. `LEFT`, `RIGHT`, and `FULL` all imply outer joins.

Join types
* `INNER JOIN` keeps only rows that match on both sides.
* `LEFT JOIN` keeps all rows from the left table and fills in columns from the right table only when you have a match, otherwise using NULL as the column values.
* `RIGHT JOIN` does the opposite: it keeps all rows from the right table.
* `FULL JOIN` keeps all rows from both sides, padding missing values with NULL.
* `CROSS JOIN` returns every possible combination of rows from both tables, so the result size is the product of their row counts.
* `LATERAL JOIN` allows a subquery that runs once per row of the outer table — like a loop over the left input.

> Before the SQL-92 standard introduced the `JOIN...ON` syntax, tables were joined by listing them in the `FROM` clause and placing the join logic in the `WHERE` clause.

Join conditions
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
  
#### WHERE

`WHERE` clause filters rows produced by the `FROM` clause. Each row is checked against the condition: if it evaluates to true, the row is kept; if false or **null**, it's discarded.

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

Subquery expressions
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

The first term acts as the base case and each subsequent iteration of the recursive term builds on the prior results until no new rows are produced or the condition is met. Only the recursive term may reference the CTE itself. UNION or UNION ALL operators can be thought of as combining the base query results and the iterative results vertically. Note that UNION ALL is faster because it simply concatenates all rows, while UNION performs an additional, costly step to remove duplicates.

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

> The concept of a “current row” only makes sense when an `ORDER BY` is present. 
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
* When testing numeric ranges, you must handle `NULL`s explicitly.
* Aggregate functions ignore `NULL`s except `COUNT(*)`, which counts every row regardless of column nulls.

To prevent `NULL` values in the first place, declare columns as `NOT NULL` in `CREATE TABLE`, even if you provide a default value. This constraint enforces that the column can never store unknown data.

---

# <a id="advanced-queries-walkthrough" href="#table-of-contents">Advanced queries walkthrough</a>
In this section, I break down two queries I wrote to answer two questions from CMU 15-445’s Spring 2025 [Homework 1](https://15445.courses.cs.cmu.edu/spring2025/homework1/).  Both questions are based on [MusicBrainz dataset](https://musicbrainz.org/doc/MusicBrainz_Database), which has the following schema:
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
FROM artist AS A, consts AS C
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

Logically, here's what the database is doing:
* Creates a `consts` CTE containing a single row with three scalar subqueries that look up IDs for `United States`, `English`, and `Person` type
* Performs a cross join between `artist` and `consts` (comma syntax: `FROM artist AS A, consts AS C`)
  * *Note*: Since `consts` yields exactly 1 row, this effectively makes the constant values available to each artist row without creating a large intermediate result set
* Applies four WHERE clause equality filters to select US-based artists of type Person born on July 4th
* For each row that passes the above filters, evaluates a correlated EXISTS subquery that:
  * Joins `artist_credit_name` → `release`
  * Filters to releases credited to the current artist (`ACN.artist = A.id`)
  * Checks if `R.language IS DISTINCT FROM C.english_id` (returns TRUE if the language is not English OR if language is NULL, treating NULL as non-English)
  * Returns TRUE if at least one such non-English (or NULL language) release exists for this artist
* Keeps only artists where the EXISTS subquery returns TRUE
* Orders the final result set by `A.name ASC`

The database's actual execution differs from the conceptual evaluation described above. You can see that by examining the execution plan (generated by prefixing the query with `EXPLAIN ANALYZE`), which is illustrated below:
<div style="text-align: left;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/intro-sql/images/advanced_example1_query_plan.png?raw=true" alt="first example" height="600" style="border: 1px solid black;">
</div>

<details>
<summary>Click to view the full query plan</summary>
<div class="highlight">
<pre>
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
</pre>
</div>
</details>

Here’s what’s actually happening under the hood:
* Prepares constants — it runs three sequential scans to find the IDs for *United States*, *English*, and *Person*. These correspond exactly to the subqueries inside the `WITH consts` clause
* Builds two hash tables — one from `artist_credit_name`, and another from `artist`
* Scans and probes in parallel — While scanning the `release` table, the database probes the `artist_credit_name` hash table to find which releases belong to which artists
* Joins results — the combined `release × artist_credit_name` output is then used to probe the second hash table built from `artist`, returning only those artists that have at least one release in a non-English language
* Gathers and sorts — finally, all worker threads send their results to the `Gather` process, which merges them and sorts the artist names alphabetically

A couple of things to note in the full query plan. First, the `Filter` node is the least efficient way to filter data. It means PostgreSQL is reading every single row from the table and only then checking if the row matches the `WHERE` clause conditions, discarding most of them after doing all the work to read them. A much better alternative, which a proper index would enable, is for the database to apply those conditions at the index level either as access predicate or filter predicate:   
* Access Predicates: If your `WHERE` clause uses the leading column(s) of an index (e.g., `WHERE A = value1` on an `(A, B, C)` index), the database uses `A = value1` as an access predicate. It can instantly seek within the B-tree to the exact start and end of the relevant data. This is the most efficient way to limit the search space.
* Filter Predicates: This is what happens when your `WHERE` clause uses a non-leading column without constraining all the columns before it (e.g., `WHERE A = value1 AND C = value2` on an `(A, B, C)` index). The database uses `A = value1` as an access predicate to find the range of index entries to scan. Then, as it scans through that range, it applies `C = value2` as a filter predicate. It checks the value of `C` within each index entry and discards those that don't match before it ever fetches the corresponding row from the main table.

Second, this plan illustrates the three fundamental decisions the query planner makes when building an execution plan. The first is the scan method, where you can see it chose `Sequential Scans` for all tables, meaning it's reading the table from top to bottom. The second key decision is the join method; it exclusively selected `Hash Joins` over other options like `Nested Loop` or `Merge Joins`. Finally, and most importantly, is the join order, where the database opted to join `release` and `artist_credit_name` first, before joining that combined result with the `artist` table.

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

Logically, 
* Performs 2 JOIN operations across 3 tables (release → medium → medium_format) using inner joins
* Filters the joined result set to rows where `mf.name LIKE '%CD%'` (CD-based formats only)
* In the `RankedReleases` CTE, calculates a window function that:
  * Partitions the filtered data by `mf.name` (grouping by format)
  * Within each partition, assigns ranks using `RANK()` based on `LENGTH(r.name) DESC` (longest names first)
  * Note: `RANK()` assigns the same rank to releases with identical name lengths and creates gaps in the sequence (e.g., if two releases tie at rank 1, the next rank is 3)
* The outer query filters to `rnk = 1`, selecting all releases that have the longest name(s) within each CD format partition
* Orders the final result set by `format_name ASC, release_name ASC`

Physically, 
<div style="text-align: left;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/intro-sql/images/advanced_example2_query_plan.png?raw=true" alt="first example" height="600" style="border: 1px solid black;">
</div>

<details>
<summary>Click to view the full query plan</summary>
<div class="highlight">
<pre>
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
</pre>
</div>
</details>

* Builds hash tables – the database first scans `medium_format`, filters to names matching `'%CD%'`, and builds a small in-memory hash table. It then scans `release` in parallel, building a much larger hash table that’s partially spilled to disk
* Scans and probes in parallel – scans `medium`, probing the `medium_format` hash table and then the combined `medium × medium_format` output is used to probe the `release` hash table, producing joined rows for CD-related releases
* Sorts intermediate results – each worker sorts its output by `mf.name` and `length(r.name)` (descending), using external merge sort due to size
* Merges and ranks – the sorted outputs are merged (`Gather Merge`), and the `WindowAgg` node computes `RANK()` per `mf.name`, keeping only `rnk = 1`
* Final incremental sort – the remaining rows are incrementally sorted by `format_name` and `release_name`, producing the final ordered result

# <a id="optimizations" href="#table-of-contents">Optimizations</a>

This section covers optimizing data retrieval operations like `SELECT` queries. Performance for these operations is solely reliant on proper indexing. An index here is a separate data structure that speeds up lookups, much like the index at the end of a book. It consumes disk space, storing a copy of the indexed column(s) and a pointer to the full row.

The most common and important index is the B-Tree. The figure below shows a simplified example.

<div style="text-align: left;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/intro-sql/images/btree.png?raw=true" alt="first example" style="border: 1px solid black;">
</div>

At the bottom of the B-tree are the leaf nodes, which contain the logically-ordered indexed column values and row references. These leaf nodes form a doubly linked list, allowing the database to efficiently support both point queries (finding a single value) and range queries (finding all values between two bounds).

Above the leaves is a balanced tree of branch (internal) nodes, which guide the search. The database starts at the root, follows the appropriate branches based on value comparisons, and eventually reaches the correct leaf.

For example, to find a row with column value 56, the database:
1. Starts at the root, examining 45 and 78,
2. Follows the branch for 78, checking 51 and 60,
3. Follows 60 to the leaf node, landing on 53 and finally finding 56,
4. Retrieves the row from the main table using the row ID (`dk1`) stored in the leaf.

In short, each query using an index typically performs:
1. A tree traversal to locate the search range,
2. A leaf-node chain scan (especially for range queries), and
3. A table lookup to fetch the full row data.

Effective optimization means designing indexes that minimize unnecessary work in steps (2) and (3).

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
