#### Table of Contents
* [What and why](#what-and-why)
* [Relational Model](#relational-model)
* [Relational algebra and calculus](#relational-algebra-and-calculus)
* [Basic queries walkthrough](#basic-queries-walkthrough)
  * [SELECT](#select)
  * [FROM](#from)
  * [WHERE](#where)
  * [ORDER BY](#order-by)
  * [GROUP BY](#group-by)
  * [COMMON TABLE EXPRESSION](#common-table-expression)
* [Advanced queries walkthrough](#advanced-queries-walkthrough)
* [Optimizations](#optimizations)
* [Conclusion](#conclusion)
* [References](#references)

---

# What and why
This is an introduction to SQL. Unlike the countless other intros, it quickly covers the core ideas from a database-theory perspective, then shifts to the user's point of view – walking through queries from basic to advanced. In the basic section, the emphasis is on understanding how SQL works – structure, syntax, and flow – before moving on to applying it to real business questions in the advanced section. It then shifts again, this time with a focus on SQL performance.

This blogpost was written primary for myself – to clarify what I understand about SQL. Along the way, I trimmed what’s easy to find elsewhere and kept what took effort to learn. If you have any feedback/thoughts, please reach out.

# Relational model

The relational model is built on a simple but powerful idea borrowed directly from mathematics: a relation is just a set of tuples.

Formally, given sets $S1$, $S2$, $\dots$, $Sn$ (called **domains**), a relation $R$ on these sets is any set of $n$-tuples where the first component comes from $S1$, the second from $S2$, and so on. In database terms, a relation is a **table**, a tuple is a **row**, and the sets $S1$, $S2$, $\dots$, $Sn$ define the permissible values for each column.

For example, imagine you have three sets:

* **$S_1 = \{12, 75, 32, 54, 98\}$** (a set of IDs)
* **$S_2 = \{"A", "B", "C", "D", "E"\}$** (a set of names)
* **$S_3 = \{2023$-$10$-$02, 2022$-$07$-$11, 2025$-$01$-$12, 2019$-$03$-$27, 2026$-$12$-$03\}$** (a set of dates)

A possible relation $R$ on these three sets could be:

| ID | Name | Date |
|---|---|---|
| 12 | "A" | 2023-10-02 |
| 75 | "C" | 2022-07-11 |
| 32 | "E" | 2019-03-27 |

Note $R$ is a named collection of three rows. Each row has the same set of named columns (`ID`, `Name`, `Date`), and each column is of a specific data type. Whereas columns have a fixed order in each row, the order of the rows within the table isn't guaranteed in any way (although they can be explicitly sorted for display).

To connect information across tables, the relational model relies on 'key' columns:
* A **primary key** uniquely identifies each row within a table (e.g., ID in the relation $R$).
* A **foreign key** creates a logical link to a primary key in another table, allowing data in one table to reference data in another.

This precise definition gives the relational model a solid theoretical foundation, ensuring clear, unambiguous concepts and avoiding ad-hoc exceptions. As a result, communication among users, developers, and researchers is far more consistent than in earlier, less formal database approaches.

In practice, the relational model deliberately stops short of access method and storage details, focusing on the logical structure of data. This separation has several consequences:

* Users can write applications against the logical model without being tied to how data is accessed and physically arranged.
* DBMS builders can innovate on access methods and storage to improve performance without breaking user programs.

# Relational algebra and calculus
Simply put, relational algebra and calculus are the mathematical languages of the relational model. They answer the question: if data is stored as tables, what does it mean to “operate” on them? Algebra provides a set of operators - SELECT, PROJECT - that transform relations step by step, like four basic operators (+, -, /, *) in arithmetic but with tables instead of numbers. Calculus, by contrast, describes the conditions rows must satisfy, without prescribing steps. SQL, that we know today, is the practical offspring of the relational model, inspired by both relational algebra and relational calculus. Yet SQL is not a strict disciple of either: it tolerates duplicates, NULLs, and ordering - features that stray from pure relational theory. It became the first successful language to operationalize Codd’s vision of separating “what” from “how”.

# Basic queries walkthrough

SQL covers several kinds of tasks, often grouped into four main categories:
- DQL (data query language) - Extracts data from tables. (e.g., `SELECT`)
- DDL (data definition language) - Defines and modifies database structures. (e.g., `CREATE`, `ALTER`, `DROP`)
- DCL (data control language) - Manages user access and permissions. (e.g., `GRANT`, `REVOKE`)
- DML (data manipulation language) - Inserts, updates, or deletes table data. (e.g., `INSERT`, `UPDATE`, `DELETE`)

In the rest of this blogpost, the focus is on DQL, since querying is where most of the real-world effort — and much of SQL’s expressive power — lies.

[env setup readme file in GitHub linked here]()

[explain dataset/columns and note that this is an important first step in answering business questions]()

[note that the order of evaluation talked below pertains to logical order; dbs are free to execute them in any order as long as the final result matches the logical view result]()

<!-- /////////////////// -->
<!-- SELECT -->
<!-- /////////////////// -->
### SELECT

Most people think of `SELECT` as “picking columns” from a table — and at the surface, that’s true. You write
```sql
SELECT title, author FROM books;
```
and get just those two columns. But under the hood, `SELECT` doesn’t actually retrieve columns — it produces rows. It’s the way of constructing a new table: starting from rows in the `FROM` clause, filtering them with `WHERE`, grouping them with `GROUP BY`, etc and finally returning the resulting rows. The columns you write in `SELECT` merely define the shape of those output rows.

Each "column" in `SELECT` can be sourced from a table, a literal value, an expression, an aggregate, or a function call. You can also rename any of them with an alias for clarity or reuse.

Modern databases make it easy to perform substantial data transformation right inside `SELECT`, reducing the need to handle that logic in application code.

<!-- /////////////////// -->
<!-- FROM -->
<!-- /////////////////// -->
### FROM

The `FROM` clause defines *where* your data comes from. Each source can be a base table (created with `CREATE TABLE`), a derived table (a subquery like `(SELECT …)`), a join, or a combination of these.

You can also specify *how* these sources relate to each other using a join condition — written with `ON`, or its shorthand forms `USING` and `NATURAL`:

```
T1 { [INNER] | { LEFT | RIGHT | FULL } [OUTER] } JOIN T2 ON boolean_expression
T1 { [INNER] | { LEFT | RIGHT | FULL } [OUTER] } JOIN T2 USING ( join column list )
T1 NATURAL { [INNER] | { LEFT | RIGHT | FULL } [OUTER] } JOIN T2
```
`INNER` and `OUTER` are optional; `INNER` is the default. `LEFT`, `RIGHT`, and `FULL` all imply outer joins.

#### Join types
* `INNER JOIN` keeps only rows that match on both sides.
* `LEFT JOIN` keeps all rows from the left table and fills-in columns from the right table only when you have a match, otherwise using NULL as the columns' value.
* `RIGHT JOIN` does the opposite: it keeps all rows from the right table.
* `FULL JOIN` keeps all rows from both sides, padding missing values with NULL.
* `LATERAL JOIN` allows a subquery that runs once per row of the outer table — like a loop over the left input.

#### Join conditions
* `ON` defines how rows from the two tables are matched. The condition must evaluate to a boolean — much like a `WHERE` clause — but it applies before the join output is produced.
* `USING` is syntactic sugar for equality joins: `USING(a,b)` expands to `ON left_table.a = right_table.a AND left_table.b = right_table.b`.
* `NATURAL` is syntactic sugar for a `USING` clause over all columns with the same name in both tables. If no such columns exist, it behaves like `ON TRUE`.

<!-- /////////////////// -->
<!-- WHERE -->
<!-- /////////////////// -->
### WHERE

`WHERE` clause filters rows produced by the `FROM` clause. Each row is checked against the condition: if it evaluates to true, the row is kept; if false or null, it's discarded.

You can combine conditions with `AND` and `OR`. `AND` allows short-circuit evaluation (stopping once one condition fails), while `OR` is more complex to optimize for – especially with respect to indexes.

#### Subquery expressions
* `EXISTS` checks whether the argument subquery returns any rows (ignoring the contents of those rows). It returns true if the result set has at least one row.
* `IN`/`NOT IN` evaluate the expression and compare it to each row of the subquery result. It returns true/false, respectively, if at least one equal subquery row is found.

If the expression consists of multiple columns, the subquery must return exactly as many columns.

Be careful about `NOT IN` with `NULL` because if the subquery result contains `NULL`, `NOT IN` evaluates to UNKNOWN (so effectively false for filtering).

* `ANY/SOME` allow using other comparison operators beyond `=` – such as `<>`, `>`, `<`, `>=`, `<=`. Recall that `IN` implicitly performs an `=` comparison.
* `ALL` is the opposite of `ANY`: the condition must hold true for every value returned by the subquery.

Keep filters simple so that the database can match them against indexes and avoid expensive full-table scans.

<!-- /////////////////// -->
<!-- ORDER BY -->
<!-- /////////////////// -->
### ORDER BY

`ORDER BY` defines the order in which the final result set is returned. It can sort by one or multiple columns, or by expressions derived from them. The sort direction is controlled with `ASC` (ascending, the default) or `DESC` (descending).

`NULLS FIRST` and `NULLS LAST` specify where `NULL` values appear in the order. By default, most databases treat `NULL` as larger than any non-null value — so they appear last when sorting ascending.

`ORDER BY` can also be used after set operations like `UNION`, `INTERSECT`, or `EXCEPT`, but in those cases it can only reference output column names or their positional numbers (not arbitrary expressions).

<!-- /////////////////// -->
<!-- LIMIT -->
<!-- /////////////////// -->
### LIMIT
* `limit` clause
  * for proper pagination, use `limit` with a range predicate (WHERE (x, y) > (x1, y1)) that matches your ordering columns; dont ever use `offset`.

<!-- /////////////////// -->
<!-- GROUP BY -->
<!-- /////////////////// -->
### GROUP BY

* `group by` clause introduces aggregates in SQL, and allows implementing much the same thing as map/reduce in other systems: map your data into dif- ferent groups, and in each group reduce the data set to a single value.
* `having clause` purpose is to filter the result set to only those groups that meet the having filtering condition, much as the where clause works for the individual rows selected for the result set.
    * A restriction with classic aggregates is that you can only run them through a single group definition at a time. In some cases, you want to be able to compute aggregates for several groups in parallel. For those cases, SQL provides the `grouping sets` feature.
    * The `rollup` clause generates permutations for each column of the grouping sets, one after the other. That’s useful mainly for hierarchical data sets, and it is still useful in our Formula One world of champions.
    * Another kind of grouping sets clause shortcut is named `cube`, which extends to all permutations available, including partial ones:

<!-- /////////////////// -->
<!-- COMMON TABLE EXPRESSION (CTE) -->
<!-- /////////////////// -->
### COMMON TABLE EXPRESSION

* `Common table expression` is the full name of the with clause that you see in effect
in the query. It allows us to run a subquery as a prologue, and then refer to its
result set like any other relation in the from clause of the main query.
* set operations
  * As expected with `union` you can assemble a result set from the result of several queries:
  * Here it’s also possible to work with the `intersect` operator in between result sets.
  * The `except` operator is very useful for writing test cases, as it allows us to compute a difference in between two result sets.


### example #1
A simple query that retrieves all books with an average rating above 4 looks like this:
```sql
SELECT *
FROM books
WHERE average_rating >= 4;
```
The image below presents visually what role each clause plays in producing the result specified by the query. The database first pulls all rows from `books` (`FROM`), then keeps only those that meet the condition (`WHERE average_rating >= 4`), and finally returns all their columns (`SELECT *`, where `*` means "all columns").

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/intro-sql/images/first_example.png?raw=true" alt="first example" height="400" style="border: 1px solid black;">
</div>

A more general template looks like:
```sql
SELECT column(s)
FROM table(s)
WHERE condition(s)
```
Conceptually, `FROM` first forms the Cartesian product (all possible row combinations) of the tables listed. `WHERE` narrows that down by applying one or more conditions (combined with `AND`, `OR`, and `NOT`). Finally, `SELECT` trims the output to just the columns you want.

> Notice the order of evaluation: FROM → WHERE → SELECT.

### example #2
This query is a bit more involved – it has more filtering conditions (`WHERE`), orders the results by popularity (`ORDER BY`) and returns specific columns.

```sql
SELECT
    title,
    authors,
    publisher,
    average_rating,
    ratings_count
FROM books
WHERE
    language_code = 'eng'
    AND publication_date > '2010-01-01'
    AND average_rating > 4.2
ORDER BY
    ratings_count DESC;
```
Conceptually, the flow remains the same – the database pulls all rows (`FROM`), filters them (`WHERE`), and then returns selected columns (`SELECT`). The only new step is at the end, where it sorts the final rows by `ratings_count` (`ORDER BY`).

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/intro-sql/images/second_example.png?raw=true" alt="first example" height="400" style="border: 1px solid black;">
</div>

> Notice the order of evaluation: FROM → WHERE → SELECT → ORDER BY.

### example #3
This query introduces aggregate functions (`COUNT`, `AVG`, `SUM`), which compute a single result from many rows. Used with `GROUP BY`, they summarize each group, and `HAVING` filters those groups (recall `WHERE`, as seen earlier, filters rows before grouping).

```sql
SELECT
    publisher,
    COUNT(*) AS hit_titles,
    AVG(average_rating) AS avg_rating,
    SUM(ratings_count) AS total_ratings
FROM
    books
WHERE
    (language_code = 'eng' OR language_code='en-US')
    AND publication_date > '2000-01-01'
    AND average_rating > 4.0
GROUP BY
    publisher
HAVING
    COUNT(*) >= 40
ORDER BY
    avg_rating DESC,
    total_ratings DESC;
```

After pulling all rows and filtering them, the database groups all remaining rows by `publisher`, creating one group per publisher (`GROUP BY`). It discards groups with fewer than 40 rows (`HAVING COUNT(*) >= 40`, where `*` counts every row in the group), calculates aggregate values (`COUNT`, `AVG`, `SUM`) and sorts the summarized results.

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/intro-sql/images/third_example.png?raw=true" alt="first example" height="400" style="border: 1px solid black;">
</div>

> Notice the order of evaluation: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY.

### example #4
This query is an intesting one because it introduces nested grouping (first level is done by `GROUP BY` and the second, inner one is done by `PARTITION BY` clause). Unlike `GROUP BY` that collapses a group of rows into one, `PARTITION BY` only segments or "windows" rows that share the same `language_code` to perform a calculation. The query also introduces `DISTINCT` in a aggregate function, which in this case means counting only unique values for `authors` column across all members of a group. Lastly, the query also uses multiple columns in `GROUP BY` clause, which means rows are grouped per each unique combination of `language_code` and `publisher`.

```sql
SELECT language_code,
       publisher,
       AVG(average_rating) AS avg_rating,
       RANK() OVER (PARTITION BY language_code
                    ORDER BY AVG(average_rating) DESC) AS publisher_rank,
       COUNT(DISTINCT authors) AS distinct_authors
FROM books
WHERE publisher IS NOT NULL AND language_code IS NOT NULL
GROUP BY language_code, publisher
ORDER BY language_code, publisher_rank;
```

### example #5
select literals
group by multiple columns
join
where with range condition

### example #6
join
where with membership condition

[old join syntax vs SQL92]()

[null pitfalls]()
```
null is the absence of a value;

When working with null, you should remember:
* An expression can be null, but it can never equal null.
* Two nulls are never equal to each other.

To test whether an expression is null, you need to use the is null operator
To test whether value is in range, you need to test that column to null as well
In aggregate functions like `COUNT`, using `*` means null is also counted
```

[explain the following template at the end of basic section]()
```sql
select 	[DISTINCT] [aggregate(column)] <columns|literals|exprs|funcs>
from 		<table>
		permanent, derived, temporary, virtual tables
join on 	<criteria>
where 	<condition(s)>
		condition - expression(s) combined with operator(s)
			equality, range, membership, matching
		expression - number|column|string|func|subquery|exprs
		operator - comparison, arithmetic, logical
group by 	<column(s)> [GROUPING SETS|ROLLUP|CUBE] [HAVING] <criteria>
order by 	<column(s)|position> <direction>
```

---

# Advanced queries walkthrough
[gemini biz questions suggestions](https://gemini.google.com/app/8c08a5cfd6b1587a)
[chatgpt biz question suggestions](https://chatgpt.com/c/68ec2f12-62f8-832a-8697-b9694460ca9f)

[EU soccer dataset](https://www.kaggle.com/datasets/hugomathien/soccer)

### pick a dataset and explore it as much as possible
### go over medium/hard examples of ‘ace data science interview‘ book

# Optimizations

# Conclusion

# References
[^1]: Codd, E.F (1970). "A Relational Model of Data for Large Shared Data Banks". Communications of the ACM. Classics. 13 (6): 377–87. doi:10.1145/362384.362685. S2CID 207549016.
