#### Table of Contents

- [Database Storage](#db-storage)
- [OLTP](#oltp)
  - [B+tree storage engines](#b-plus-se)
  - [LSM tree storage engines](#lsm-tree-se)
  - [LSH table storage engines](#lsh-table-se)
- [OLAP](#olap)
- [Hardware](#hardware)
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

B+tree-based storage engines maintain a global sorted order via a self-balancing tree and typically update data in place. The B-tree data structure was introduced in the early 1970s [^1] [^2] [^3], so most relational databases rely on it for primary and secondary indexes.

MySQL's InnoDB is a good example of such a storage engine. Its architecture [^4] is shown below. `File-Per-Table Tablespaces` is where table data and indexes are stored.

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/innodb_se.png?raw=true" alt="first example" style="border: 0px solid black; width: 70%; height: auto;">
</div>

With file-per-table enabled, each `.ibd` file stores the table’s clustered index and all its secondary indexes [^5]. InnoDB clusters the table on the primary key: the leaf pages of the primary B+tree contain entire rows, ordered by that key. Secondary indexes store key values plus the primary-key columns as the logical row locator. The figure below shows a simplified primary index layout.

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/mysql_btree.png?raw=true" alt="first example" style="border: 0px solid black; width: 100%; height: auto;">
</div>

PostgreSQL takes a different approach. It uses a heap-storage engine: table data goes into heap files and indexes live in their own files. PostgreSQL's architecture[^6] is shown below; the dashed red box roughly corresponds to its "storage engine".

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/postgres_se.png?raw=true" alt="first example" style="border: 0px solid black; width: 80%; height: auto;">
</div>

Each Postgres table or index is stored in its own file, accompanied by two auxiliary forks for the free space map (FSM) and visibility map (VM). Tables larger than 1GB are split into 1GB segments (name.1, name.2, etc.) to accommodate filesystem limits. The main fork is divided into 8KB pages; for heap tables, all pages are interchangeable, so a row can be stored anywhere. Indexes dedicate the first block to metadata and maintain different page types depending on the access method. The generic page layout is shown below:

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/pg_page_layout.png?raw=true" alt="first example" style="border: 0px solid black; width: 60%; height: auto;">
</div>

By default, a primary key or unique constraint creates a B+tree index, so you typically end up with at least one file per table plus at least one more for its B+tree index. The figure below shows how the table and its B+tree primary index are related.

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/btree.png?raw=true" alt="first example" style="border: 0px solid black; width: 100%; height: auto;">
</div>

#### LSM-tree-based

The Log-Structured Merge (LSM) tree was introduced in academic literature in 1996. LSM storage engines buffer writes in memory, periodically flush sorted runs to disk, and merge those runs in the background. This trades the strict in-place updates and globally ordered layout of B+trees for batched sequential I/O, yielding much higher write throughput, especially in internet-scale workloads. The trade-off is extra read latency (e.g., short-range lookups may hit multiple levels) and higher space/memory amplification. [^7]

RocksDB is one of the state-of-the-art LSM-tree based storage engines. See its [wiki](tab:https://github.com/facebook/rocksdb/wiki/RocksDB-Overview) for an overview.

#### LSH-table-based

The Log-Structured Hash (LSH) tables push the LSM idea to its extreme by dropping order maintenance entirely. Instead, they rely on an in-memory index, eg hash table, for efficient key-value lookups. New records are buffered in memory and then flushed to disk as new segments in a single, ever-growing log.

This design makes writes almost entirely sequential, supporting extremely high ingest rates. The main downsides are inefficient range scans, which must either scan multiple log segments or resort to a full table scan, and higher memory amplification compared to LSM-trees, as the in-memory index must hold all keys. [^7]

Faster [^8] and its follow ups are good examples of such a system.

## <a id="olap" href="#table-of-contents">OLAP</a>

[TODO]()

Storage engines that are optimized for analytics use a column-oriented storage layout with compression that minimizes the amount of data that such a query needs to read off disk.

## <a id="hardware" href="#table-of-contents">Hardware</a>

### Modern Storage Hardware

The below figure [^10] shows different types of storage hardware currently in use and their related advantages and disadvantages in terms of performance, capacity, and price. General principle is that lower latency hardware is more expensive and has smaller capacity.

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/storage_hierarchy.png?raw=true" alt="first example" style="border: 0px solid black; width: 80%; height: auto;">
</div>

Registers are at the top of the memory hierarchy, and provide the fastest way to access data.

Most CPUs have the main hierarchy of multiple cache levels (L1, L2, often L3, and rarely even L4), with the separate instruction-specific (I-cache) and data-specific (D-cache) caches at level 1. The different levels are implemented in different areas of the chip; L1 is located as close to a CPU core as possible and thus offers the highest speed due to short signal paths, but requires careful design. L2 caches are physically separate from the CPU and operate slower, but place fewer demands on the chip designer and can be made much larger without impacting the CPU design. L3 caches are generally shared among multiple CPU cores. Cache memory is typically implemented with SRAM, which requires multiple transistors to store a single bit, making it much faster to read/write but also more expensive than DRAM.

Main memory is storage directly accessible to the CPU via memory bus. The CPU continuously reads instructions stored there and executes them as required. Any data actively operated on is also stored there in a uniform manner. Main memory is usually implemented with DRAM, which requires only one transistor and one capacitor per bit.

Nonvolatile storage has a rich history [^10], largely dominated by HDDs. They read/write data stored on the magnetic surface using a read-write head, as shown in the image below.

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/hdd_3d.png?raw=true" alt="first example" style="border: 0px solid black; width: 60%; height: auto;">
</div>

This mechanical limitation is one of the primary reasons SSDs (have no moving parts and based on 3D NAND flash) have gained popularity in recent years and now largely overtaken HDDs for many use cases. They offer more than 3 orders of magnitude performance improvement (1000X+) for random read/write IOPS and at least similar power efficiency since their power consumption roughly stays the same. That said, they have their own limitations, such as read/write asymmetry and short service life [^11]. To be specific about the former, write performance suffers after the SSD is used for a period because SSDs cannot overwrite a page (eg 4KB) directly and must erase entire blocks (eg 128 pages) to reuse them, a process that involves relocating valid data to a new block before the old one can be erased. The latter is related to NAND flash memory cells only withstanding a finite number of program/erase cycles before they begin to fail. Then garbage collection (GC) process contributes to the wear and tear of an SSD, which does affect its total potential service life.

HDD performance

- number of random (4KB) block reads per second: ~100
  - this means that random access time is ~10 ms
- number of sequential (4KB) block reads per second: ~40k
  - this means throughput is ~150 MB/s

SSD performance

- number of random (4KB) block reads per second at QD-32:
  - SSDs with SATA reach ~100k
  - NVMe over PCIe ~1M
  - Performance figures are typically labeled as QD-x (queue depth x) with QD-32 being the standard reference point
- number of random (4KB) block writes per second at QD-32:
  - SSDs with SATA reach ~80k
  - NVMe (PCIe 5) ~800k
- data transfer rate (seq read/write):
  - SATA SSDs ~500 MB/s (~125k ops/s)
  - NVMe (PCIe 5) ~14 GB/s (~3.5M ops/s)
  - data transfer rate is usually limited by the interconnect

Persistent memory combining the speed of traditional RAM with the durability of storage. It offers fast, byte-addressable access [^12]

This is so called memory hierachy is one of the most important factors a storage engine is optimized around.

### Modern Storage APIs

[google scholar – search 1](https://scholar.google.com/scholar_labs/search/session/11574651912704045173?hl=en)

libaio vs SPDK API vs io_uring

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

[^3]: Congdon, Ben. "B-Trees: More Than I Thought I'd Want to Know." 17 Aug. 2021, https://benjamincongdon.me/blog/2021/08/17/B-Trees-More-Than-I-Thought-Id-Want-to-Know.

[^4]: Oracle. (2025). Figure 17.1 InnoDB Architecture. In MySQL 9.5 Reference Manual. https://dev.mysql.com/doc/refman/9.5/en/innodb-architecture.html

[^5]: Cole, Jeremy. "The basics of InnoDB space file layout." 3 Jan. 2013, https://blog.jcole.us/2013/01/03/the-basics-of-innodb-space-file-layout.

[^6]: Freund, Andres. "Pluggable table storage in PostgreSQL." 25 Jun. 2019, https://anarazel.de/talks/2019-06-25-pgvision-pluggable-table-storage/pluggable.pdf.

[^7]: Idreos, Stratos, and Mark Callaghan. "Key-value storage engines."

[^8]: Chandramouli, Badrish, et al. "Faster: A concurrent key-value store with in-place updates."

[^9]: Oracle. File-Per-Table Tablespaces. In MySQL 9.5 Reference Manual. https://dev.mysql.com/doc/refman/9.5/en/innodb-file-per-table-tablespaces.html

[^10]: Data Storage Architecture and Technologies

[^10]: https://en.wikipedia.org/wiki/Mass_storage

[^11]: https://www.alibabacloud.com/blog/storage-system-design-analysis-factors-affecting-nvme-ssd-performance-1_594375

[^12]: How to use Persistent Memory in your Database
