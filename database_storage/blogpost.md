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

## <a id="db-storage" href="#table-of-contents">Database storage</a>

There’s plenty of material online about storage engines (eg see [this](tab:https://www.yugabyte.com/blog/a-busy-developers-guide-to-database-storage-engines-the-basics/) and [its follow-up](tab:https://www.yugabyte.com/blog/a-busy-developers-guide-to-database-storage-engines-advanced-topics/)).

tl;dr:

A storage engine is the component of a database that handles CRUD operations, interfacing with the underlying memory and storage systems. It usually relies on two primary types of indexes: B+trees and Log-Structured Merge-Trees (LSM-trees). The former provides balanced read and write performance, while the latter is optimized for high write throughput. In addition to the workload type, other factors, such as concurrency control, also have a significant impact on storage engine performance (eg see [this](tab:https://www.cs.cmu.edu/~pavlo/blog/2023/04/the-part-of-postgresql-we-hate-the-most.html))

My goal here is to build on that summary and shallowly sketch the current storage-engine landscape. In this regard, two broad workload types dominate: OLTP and OLAP (bear with me for a second for the terminology). OLTP workloads issue many short reads and/or writes that touch only a few records at a time. OLAP workloads run long, complex analytical queries that scan large segments of a dataset. Given this contrast between workloads, storage-engine designs follow suit.

## <a id="oltp" href="#table-of-contents">OLTP</a>

Shopping on an e-commerce site is a good example of a balanced read-write OLTP workload. This activity involves a mix of reading data (browsing products) and writing data (placing an order). In contrast, application logging and analytics use cases are much more write-heavy, requiring significantly higher write throughput. Taking this idea to an extreme, consider the massive, high-speed data ingestion from edge devices or IoT sensors, which demands extremely high write throughput.

While all of these are OLTP use cases, their vastly different write requirements are best served by different storage engines. Based on these needs, one way to classify OLTP storage engines is:

- **B+tree-based**: ideal for balanced read-write workloads.
- **LSM (Log-Structured Merge) tree-based**: optimized for write-heavy workloads.
- **LSH (Log-Structured Hash) table-based**: designed for extremely high-ingest workloads.

#### B+tree-based

B+tree-based storage engines maintain a global sorted order via a self-balancing tree and typically update data in place. The B-tree data structure was introduced in the early 1970s [^1] [^2] [^3], so most relational databases rely on it for their primary and secondary indexes.

MySQL's InnoDB is a good example of such a storage engine. Its architecture[^5] is shown below. An interesting piece there is `File-Per-Table Tablespaces`, which encapsulate table data files.

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/innodb_se.png?raw=true" alt="first example" style="border: 0px solid black; width: 70%; height: auto;">
</div>

Each file stores table data and indexes. Primary key is used as a clustered key, where leaf nodes of B+tree has the actual rows of the table., so rows stay physically ordered by the primary key and secondary indexes point back to that ordering. The figure below shows a simplified example of how those indexes organize tuples.

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/mysql_btree.png?raw=true" alt="first example" style="border: 0px solid black; width: 100%; height: auto;">
</div>

PostgreSQL, for example, stores table data in heap files but uses B-tree indexes by default for primary keys and many secondary indexes. Its architecture[^4] is shown below and the dashed red box roughly corresponds to its "storage engine".

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/postgres_se.png?raw=true" alt="first example" style="border: 0px solid black; width: 80%; height: auto;">
</div>

In PostgreSQL, each table or index lives in its own file, accompanied by two auxiliary forks for the free space map (FSM) and visibility map (VM). Relations larger than 1GB are split into 1GB segments (name.1, name.2, etc.) to accommodate filesystem limits. The main fork is divided into 8KB pages; for heap tables the pages are all interchangeable so a row can be stored anywhere, whereas indexes dedicate the first block to metadata and maintain different page types depending on the access method. The generic page layout is shown below:

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/pg_page_layout.png?raw=true" alt="first example" style="border: 0px solid black; width: 60%; height: auto;">
</div>

While PostgreSQL itself is a heap-storage engine, every PRIMARY KEY (and most unique constraints) automatically creates a B+tree index, so you typically end up with one file per table plus at least one more for its B-tree index. The figure below shows a simplified example of how those indexes organize tuples.

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/btree.png?raw=true" alt="first example" style="border: 0px solid black; width: 100%; height: auto;">
</div>

#### LSM-tree-based

LSM (Log-Structured Merge) tree was introduced in academic literature in 1996. LSM-tree based storage engines buffer updates in memory and flush out sorted runs, relaxing strict in‐place updates and global order maintenance, thereby optimizing for write throughput (common in internet scale, write‐heavy applications). Compared to B+ tree storage engines, LSM ones achieve better writes but give up some read performance (eg for short-range queries) and memory amplification. [^6]

[RocksDB storage engine](https://github.com/facebook/rocksdb/wiki/RocksDB-Overview)

#### LSH-table-based

LSH (Log-Structured Hash) table-based storage engines forwent ordering entirely (no global/local sort order) and instead use a hash approach, optimizing for very high ingest throughput. Compared to LSM tree based storage engines, LSH table ones achieve even better writes but give up some more read performance (eg range queries) and memory amplification. [^6]

[F2 at Microsoft](https://arxiv.org/abs/2305.01516)
[Garnet at Microsoft](https://microsoft.github.io/garnet/docs/research/papers)

## <a id="olap" href="#table-of-contents">OLAP</a>

Storage engines that are optimized for analytics use a column-oriented storage layout with compression that minimizes the amount of data that such a query needs to read off disk.

## <a id="design-knobs" href="#table-of-contents">Design knobs</a>

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

## <a id="references" href="#table-of-contents">References</a>

[^1]: Bayer, Rudolf, and Edward McCreight. "Organization and maintenance of large ordered indices."

[^2]: Dicken, Ben. "B-trees and database indexes." PlanetScale, 9 Sept. 2024, https://planetscale.com/blog/btrees-and-database-indexes.

[^3]: Congdon, Ben. "B-Trees: More Than I Thought I'd Want to Know." 17 August. 2021, https://benjamincongdon.me/blog/2021/08/17/B-Trees-More-Than-I-Thought-Id-Want-to-Know.

[^4]: Freund, Andres. "Pluggable table storage in PostgreSQL.", June 25. 2019, https://anarazel.de/talks/2019-06-25-pgvision-pluggable-table-storage/pluggable.pdf.

[^5]: Oracle. (2025). Figure 17.1 InnoDB Architecture. In MySQL 9.5 Reference Manual. https://dev.mysql.com/doc/refman/9.5/en/innodb-architecture.html

[^6]: Idreos, Stratos, and Mark Callaghan. "Key-value storage engines."
