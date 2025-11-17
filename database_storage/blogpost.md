#### Table of Contents

- [Database Storage](#db-storage)
- [OLTP](#oltp)
  - [B+tree storage engines](#b-plus-se)
  - [LSM tree storage engines](#lsm-tree-se)
  - [LSH table storage engines](#lsh-table-se)
- [OLAP](#olap)
- [Design knobs](#design-knobs)
- [References](#references)

---

# <a id="db-storage" href="#table-of-contents">Database storage</a>

There’s plenty of material online about storage engines (eg see [this](tab:https://www.yugabyte.com/blog/a-busy-developers-guide-to-database-storage-engines-the-basics/) and [its follow-up](tab:https://www.yugabyte.com/blog/a-busy-developers-guide-to-database-storage-engines-advanced-topics/)).

tl;dr:

A storage engine is the component of a database that handles CRUD operations, interfacing with the underlying memory and storage systems. It usually relies on two primary types of indexes: B+trees and Log-Structured Merge-Trees (LSM-trees). The former provides balanced read and write performance, while the latter is optimized for high write throughput. In addition to the workload type, other factors, such as concurrency control, also have a significant impact on storage engine performance (eg see [this](tab:https://www.cs.cmu.edu/~pavlo/blog/2023/04/the-part-of-postgresql-we-hate-the-most.html))

My goal here is to build on that summary and shallowly sketch the current storage-engine landscape. In this regard, two broad workload types dominate: OLTP and OLAP (bear with me for a second for the terminology). OLTP workloads issue many short reads and/or writes that touch only a few records at a time. OLAP workloads run long, complex analytical queries that scan large segments of a dataset. Given this contrast between workloads, storage-engine designs follow suit.

# <a id="oltp" href="#table-of-contents">OLTP</a>

Shopping on an e-commerce site is a good example of a balanced read-write OLTP workload. This activity involves a mix of reading data (browsing products) and writing data (placing an order). In contrast, application logging and analytics use cases are much more write-heavy, requiring significantly higher write throughput. Taking this idea to an extreme, consider the massive, high-speed data ingestion from edge devices or IoT sensors, which demands extremely high write throughput.

While all of these are OLTP use cases, their vastly different write requirements are best served by different storage engines. Based on these needs, one way to classify OLTP storage engines is:

- **B+tree-based**: ideal for balanced read-write workloads.
- **LSM (Log-Structured Merge) tree-based**: optimized for write-heavy workloads.
- **LSH (Log-Structured Hash) table-based**: designed for extremely high-ingest workloads.

#### B+tree-based

B+tree-based storage engines maintain a global sorted order (via self-balancing tree) and typically update data in place. Given B‐tree data structure [^1] [^2] was invented in 1970, many relational databases use this design, including Postgres. Its architecture[^3] is shown below and the dashed red box roughly corresponds to its "storage engine".

<div style="text-align: left;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/postgres_se.png?raw=true" alt="first example" height="600" style="border: 1px solid black;">
</div>

Looking at MySQL's InnoDB [^4],

<div style="text-align: left;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/innodb_se.png?raw=true" alt="first example" height="600" style="border: 1px solid black;">
</div>

#### LSM-tree-based

LSM (Log-Structured Merge) tree was introduced in academic literature in 1996. LSM-tree based storage engines buffer updates in memory and flush out sorted runs, relaxing strict in‐place updates and global order maintenance, thereby optimizing for write throughput (common in internet scale, write‐heavy applications). Compared to B+ tree storage engines, LSM ones achieve better writes but give up some read performance (eg for short-range queries) and memory amplification. [^5]

#### LSH-table-based

LSH (Log-Structured Hash) table-based storage engines forwent ordering entirely (no global/local sort order) and instead use a hash approach, optimizing for very high ingest throughput. Compared to LSM tree based storage engines, LSH table ones achieve even better writes but give up some more read performance (eg range queries) and memory amplification. [^5]

# <a id="olap" href="#table-of-contents">OLAP</a>

Storage engines that are optimized for analytics use a column-oriented storage layout with compression that minimizes the amount of data that such a query needs to read off disk.

# <a id="design-knobs" href="#table-of-contents">Design knobs</a>

### In-memory data structures

### In-disk data structures

### Modern Storage Hardware

- disk
- SSD
- persistent memory

### Modern Storage APIs

- io_uring

### Design knobs around working with the underlying memory/storage

- work with OS's file system
- work with mmap
- work directly with storage hardware
- work with remote storage

storage engines that are optimized for more advanced queries, such as text retrieval

# <a id="references" href="#table-of-contents">References</a>

[^1]: Bayer, Rudolf, and Edward McCreight. "Organization and maintenance of large ordered indices."

[^2]: Dicken, Ben. "B-trees and database indexes." PlanetScale, 9 Sept. 2024, https://planetscale.com/blog/btrees-and-database-indexes.

[^3]: Freund, Andres. "Pluggable table storage in PostgreSQL.", June 25. 2019, https://anarazel.de/talks/2019-06-25-pgvision-pluggable-table-storage/pluggable.pdf.

[^4]: Oracle. (2025). Figure 17.1 InnoDB Architecture. In MySQL 9.5 Reference Manual. https://dev.mysql.com/doc/refman/9.5/en/innodb-architecture.html

[^5]: Idreos, Stratos, and Mark Callaghan. "Key-value storage engines."
