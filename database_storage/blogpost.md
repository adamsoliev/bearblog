#### Table of Contents

- [Database Storage](#db-storage)
- [OLTP](#oltp)
  - [B+tree storage engines](#b-plus-se)
  - [LSM tree storage engines](#lsm-tree-se)
  - [LSH table storage engines](#lsh-table-se)
- [OLAP](#olap)
- [Other](#other)
- [References](#references)

---

# <a id="db-storage" href="#table-of-contents">Database storage</a>

There’s plenty of material online about storage engines (eg see [this](tab:https://www.yugabyte.com/blog/a-busy-developers-guide-to-database-storage-engines-the-basics/) and [its follow-up](tab:https://www.yugabyte.com/blog/a-busy-developers-guide-to-database-storage-engines-advanced-topics/)). My goal here is to update and expand on those pieces. Their tl;dr:

A storage engine is the component of a database that handles CRUD operations, interfacing with the underlying memory and storage systems. It is agnostic to the data model (relational vs. non-relational) and usually relies on two primary types of indexes: B+trees and Log-Structured Merge-Trees (LSM-trees). The former provides balanced read and write performance, while the latter is optimized for high write throughput. In addition to the workload type, other factors, such as concurrency control, also have a significant impact on storage engine performance (eg see [this](tab:https://www.cs.cmu.edu/~pavlo/blog/2023/04/the-part-of-postgresql-we-hate-the-most.html))

# <a id="oltp" href="#table-of-contents">OLTP</a>

Storage engines optimized for transactional (OLTP) workloads can be broadly classified into:

- B+ tree-based
- LSM (Log-Structured Merge) tree-based
- LSH (Log-Structured Hash) table-based

B+ tree-based storage engines — these maintain a global sorted order (tree) and typically update data in place. The B‐tree data structure was invented in 1970. Many classic relational engines use this design.

Looking at Postgres [^2],

<div style="text-align: left;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/postgres_se.png?raw=true" alt="first example" height="600" style="border: 1px solid black;">
</div>

Looking at MySQL's InnoDB [^3],

<div style="text-align: left;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/innodb_se.png?raw=true" alt="first example" height="600" style="border: 1px solid black;">
</div>

LSM (Log-Structured Merge) tree-based storage engines — introduced in academic literature in 1996. These engines buffer updates in memory and flush out sorted runs, relaxing strict in‐place updates and global tree maintenance, thereby optimizing for high ingestion/write throughput (common in internet scale, write‐heavy applications). Compared to B+ tree storage engines, LSM ones achieve better writes but give up some read performance (eg for short-range queries) and memory amplification. [^1]

LSH (Log-Structured Hash) table-based storage engines — forwent ordering entirely (no global/local sort order) and instead use a hash approach, optimizing for very high ingest throughput. Compared to LSM tree based storage engines, LSH table ones achieve even better writes but give up some more read performance (eg range queries) and memory amplification. [^1]

# <a id="olap" href="#table-of-contents">OLAP</a>

Storage engines that are optimized for for analytics (OLAP)

# <a id="other" href="#table-of-contents">Other</a>

storage engines that are optimized for more advanced queries, such as text retrieval

# <a id="references" href="#table-of-contents">References</a>

[^1]: Idreos, Stratos, and Mark Callaghan. "Key-value storage engines."

[^2]: Freund, A. (2019, June 25). Pluggable table storage in PostgreSQL [Presentation slides]. https://anarazel.de/talks/2019-06-25-pgvision-pluggable-table-storage/pluggable.pdf

[^3]: Oracle. (2025). Figure 17.1 InnoDB Architecture. In MySQL 9.5 Reference Manual. https://dev.mysql.com/doc/refman/9.5/en/innodb-architecture.html
