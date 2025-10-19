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

# Basic SQL

SQL covers several kinds of tasks, often grouped into four main categories:
- DQL (data query language) - Extracts data from tables. (e.g., `SELECT`)
- DDL (data definition language) - Defines and modifies database structures. (e.g., `CREATE`, `ALTER`, `DROP`)
- DCL (data control language) - Manages user access and permissions. (e.g., `GRANT`, `REVOKE`)
- DML (data manipulation language) - Inserts, updates, or deletes table data. (e.g., `INSERT`, `UPDATE`, `DELETE`)

In the rest of this blogpost, the focus is on DQL, since querying is where most of the real-world effort — and much of SQL’s expressive power — lies.

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

Each "column" in `SELECT` can be sourced from a base table (created with `CREATE TABLE`), a literal value, an expression, an aggregate, or a function call. You can also rename any of them with an alias for clarity or reuse.

Modern databases make it easy to perform substantial data transformation right inside `SELECT`, reducing the need to handle that logic in application code.

<!-- /////////////////// -->
<!-- FROM -->
<!-- /////////////////// -->
### FROM

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
* `LEFT JOIN` keeps all rows from the left table and fills-in columns from the right table only when you have a match, otherwise using NULL as the columns' value.
* `RIGHT JOIN` does the opposite: it keeps all rows from the right table.
* `FULL JOIN` keeps all rows from both sides, padding missing values with NULL.
* `LATERAL JOIN` allows a subquery that runs once per row of the outer table — like a loop over the left input.

<!-- FIXME -->
[old join syntax vs SQL92]()

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
<!-- LIMIT and OFFSET -->
<!-- /////////////////// -->
### LIMIT and OFFSET
`LIMIT` restricts the number of rows returned by a query, while `OFFSET` skips a given number of rows before starting to return results. These two are often paired with `ORDER BY` to guarantee a consistent and predictable order of results.

Pagination is a common use case for `LIMIT` and `OFFSET`: fetching the first X rows with `LIMIT`, then skipping over previously retrieved ones in subsequent queries with `OFFSET`. This implementation is a subpar alternative when indexes exist on the ordering columns – the database must still process all preceding rows before skipping them.

A more efficient alternative is to use a top-N hint (recognized by most databases) for the initial set of results and then use `WHERE` based on specific key ranges for subsequent queries. This method, known as **keyset pagination**, allows the database to jump directly to the next page using indexed lookups.

<!-- /////////////////// -->
<!-- GROUP BY -->
<!-- /////////////////// -->
### GROUP BY

`GROUP BY` takes rows with identical values in one or more columns and collapses them into a single summary row. It is almost always used alongside aggregate functions, such as `COUNT()`, `SUM()`, `AVG()`. These functions perform a calculation on each group, returning a single value.

`HAVING` checks the summary row of every group against the condition: if it evaluates to true, the summary row is kept; if false or null, it's discarded. In other words, `HAVING` is a group-level filter (recall that `WHERE` is a row-level one).

`GROUPING SETS` is syntactic sugar for running multiple `GROUP BY`s in parallel.
```sql
...
group by
    a

...
group by
    b

-- two accomplished in one

...
group by
    grouping set (
        (a),
        (b)
    )
```

`ROLLUP` is syntactic sugar for running a specific type of `GROUPING SETS`, where one column is removed from `GROUP BY` clause at each step. It is useful for data with a clear hierarchy.

```sql
...
group by
    rollup (a, b)

-- is equal to

...
group by
    grouping set (
        (a, b),
        (a),
        ()
    )
```

`CUBE` is syntactic sugar for running a specific type of `GROUPING SETS`, where you run `GROUP BY` for every possible combination of the columns.
```sql
...
group by
    cube (a, b)

-- is equal to

...
group by
    grouping set (
        (a, b),
        (a),
        (b),
        ()
    )
```

<!-- /////////////////// -->
<!-- COMMON TABLE EXPRESSION (CTE) -->
<!-- /////////////////// -->
### COMMON TABLE EXPRESSION

`COMMON TABLE EXPRESSIONS or CTEs` allows you to define a named subquery and run it as a prologue, and then refer to its result set like any other relation in `FROM` of the main query.

The optional `RECURSIVE` keyword turns a CTE from a mere syntactic convenience into a feature where CTE query can refer to its own output. A recursive CTE has the general form:
```
non-recursive term
UNION or UNION ALL
recursive term
```

Only the recursive term may reference CTE itself. The first term acts as the base case, and each subsequent iteration of the recursive term builds on the prior results until no new rows are produced or the condition is met.

Recursive CTEs are most often used to work with hierarchical or graph-like data.

<!-- FIXME -->
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
---

# Advanced queries walkthrough
<!--<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/intro-sql/images/third_example.png?raw=true" alt="first example" height="400" style="border: 1px solid black;">
</div>-->

# Optimizations

# Conclusion

# References
[^1]: Codd, E.F (1970). "A Relational Model of Data for Large Shared Data Banks". Communications of the ACM. Classics. 13 (6): 377–87. doi:10.1145/362384.362685. S2CID 207549016.
