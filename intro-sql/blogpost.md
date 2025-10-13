#### Table of Contents
* [What and why](#what-and-why)
* [Relational Model](#relational-model)
* [Relational algebra and calculus](#relational-algebra-and-calculus)
* [Basic queries walkthrough](#basic-queries-walkthrough)
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

In the rest of this blogpost, the focus is on DQL, since querying is where most of the real-world effort—and much of SQL’s expressive power—lies.

[env setup readme file in GitHub linked here]()

[explain dataset/columns and note that this is an important first step in answering business questions]()

[note that the order of evaluation talked below pertains to logical order; dbs are free to execute them in any order as long as the final result matches the logical view result]()

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

> *Notice the order of evaluation: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY*.

---

# Advanced queries walkthrough
[gemini biz questions suggestions](https://gemini.google.com/app/8c08a5cfd6b1587a)
[chatgpt biz question suggestions](https://chatgpt.com/c/68ec2f12-62f8-832a-8697-b9694460ca9f)

[EU soccer dataset](https://www.kaggle.com/datasets/hugomathien/soccer)

### pick a dataset and explore it as much as possible
### go over medium/hard examples of ‘ace data science interview‘ book

# Optimizations

# Conclusion

<!--
![image](https://github.com/adamsoliev/Ganymede/blob/master/references/arty_a7.jpg?raw=true)
-->

# References
[^1]: Codd, E.F (1970). "A Relational Model of Data for Large Shared Data Banks". Communications of the ACM. Classics. 13 (6): 377–87. doi:10.1145/362384.362685. S2CID 207549016.

