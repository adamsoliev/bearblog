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
| title | genre.. | autho.. | curre.. | circu.. | publi.. | publi.. |
|-|-|-|-|-|-|-| 
| The Cherry Orchard | DRAMA | Anton_Chekhov | 1 | checked out | 2054-01-01 | 1904-Jan-01 |
| ... | ... | ... | ... | ... | ... | ... |

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

<!-- /////////////////// -->
<!-- COMMON TABLE EXPRESSION (CTE) -->
<!-- /////////////////// -->
### <a id="common-table-expressions" href="#table-of-contents">COMMON TABLE EXPRESSIONS</a>

`Common table expressions` (CTEs) let you define a named subquery, run it as a prologue, and then refer to its result set like any other relation in the main query’s `FROM`. So their value comes from breaking down complicated queries into simpler – or easier to follow – parts.

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

Only the recursive term may reference the CTE itself. The first term acts as the base case, and each subsequent iteration of the recursive term builds on the prior results until no new rows are produced or the condition is met.

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
<!-- NULL -->
<!-- /////////////////// -->
### <a id="null-pitfalls" href="#table-of-contents">NULL PITFALLS</a>

null is the absence of a value;

When working with null, you should remember:
* An expression can be null, but it can never equal null.
* Two nulls are never equal to each other.

To test whether an expression is null, you need to use the is null operator
To test whether value is in range, you need to test that column to null as well
In aggregate functions like `COUNT`, using `*` means null is also counted

---

# <a id="advanced-queries-walkthrough" href="#table-of-contents">Advanced queries walkthrough</a>
<!--<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/intro-sql/images/third_example.png?raw=true" alt="first example" height="400" style="border: 1px solid black;">
</div>-->

# <a id="optimizations" href="#table-of-contents">Optimizations</a>

#### WHERE
Keep filters simple so that the database can match them against indexes and avoid expensive full-table scans.

#### LIMIT AND OFFSET
Pagination is a common use case for `LIMIT` and `OFFSET`: fetching the first X rows with `LIMIT`, then skipping over previously retrieved ones in subsequent queries with `OFFSET`. This implementation is a subpar alternative when indexes exist on the ordering columns – the database must still process all preceding rows before skipping them.

A more efficient alternative is to use a top-N hint (recognized by most databases) for the initial set of results and then use `WHERE` based on specific key ranges for subsequent queries. This method, known as **keyset pagination**, allows the database to jump directly to the next page using indexed lookups.

# <a id="conclusion" href="#table-of-contents">Conclusion</a>

# <a id="references" href="#table-of-contents">References</a>
[^1]: Codd, E.F (1970). "A Relational Model of Data for Large Shared Data Banks". Communications of the ACM. Classics. 13 (6): 377–87. doi:10.1145/362384.362685. S2CID 207549016.
