#### Table of Contents

- [What and why](#what-and-why)
- [OLTP](#oltp)
  - [B+tree storage engines](#b-plus-se)
  - [LSM tree storage engines](#lsm-tree-se)
  - [LSH table storage engines](#lsh-table-se)
- [OLAP](#olap)
- [Hardware](#hardware)
- [References](#references)

---

## <a id="what-and-why" href="#table-of-contents">What and why</a>

There’s plenty of material online about storage engines (eg see [this](tab:https://www.yugabyte.com/blog/a-busy-developers-guide-to-database-storage-engines-the-basics/) and [its follow-up](tab:https://www.yugabyte.com/blog/a-busy-developers-guide-to-database-storage-engines-advanced-topics/)).

Their tl;dr is:

A storage engine is the component of a database that handles CRUD operations, interfacing with the underlying memory and storage systems. It usually relies on two primary types of indexes: B+trees and Log-Structured Merge-Trees (LSM-trees). The former provides balanced read and write performance, while the latter is optimized for high write throughput. In addition to the workload type, other factors, such as concurrency control, also have a significant impact on storage engine performance (eg see [this](tab:https://www.cs.cmu.edu/~pavlo/blog/2023/04/the-part-of-postgresql-we-hate-the-most.html))

My goal here is to build on that summary and shallowly sketch the current storage-engine landscape. In this regard, two broad workload types dominate: OLTP and OLAP. The former workloads issue many short reads and/or writes that touch only a few records at a time. The latter workloads run long, complex analytical queries that scan large segments of a dataset. Given this contrast between workloads, storage-engine designs follow suit.

## <a id="oltp" href="#table-of-contents">OLTP</a>

Shopping on an e-commerce site is a good example of a balanced read-write OLTP workload. This activity involves a mix of reading data (browsing specific products) and writing data (placing an order). In contrast, application logging and analytics use cases are much more write-heavy, requiring significantly higher write throughput. Taking this idea to an extreme, consider the massive, high-speed data ingestion from edge devices or IoT sensors, which demands extremely high write throughput.

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

The Log-Structured Merge (LSM) tree was introduced in academic literature in 1996. LSM storage engines buffer writes in memory, periodically flush sorted runs to disk, and merge those runs in the background. This trades the strict in-place updates and globally ordered layout of B+trees for batched sequential I/O, yielding much higher write throughput, especially in internet-scale workloads. The trade-off is extra read latency (eg short-range lookups may hit multiple levels) and higher space/memory amplification. [^7]

RocksDB is one of the state-of-the-art LSM-tree based storage engines. See its [wiki](tab:https://github.com/facebook/rocksdb/wiki/RocksDB-Overview) for an overview.

#### LSH-table-based

The Log-Structured Hash (LSH) tables push the LSM idea to its extreme by dropping order maintenance entirely. Instead, they rely on an in-memory index, eg hash table, for efficient key-value lookups. New records are buffered in memory and then flushed to disk as new segments in a single, ever-growing log.

This design makes writes almost entirely sequential, supporting extremely high ingest rates. The main downsides are inefficient range scans, which must either scan multiple log segments or resort to a full table scan, and higher memory amplification compared to LSM-trees, as the in-memory index must hold all keys [^7]. Faster and its follow ups are good examples of such a system [^8].

## <a id="olap" href="#table-of-contents">OLAP</a>

[TODO]()

Storage engines that are optimized for analytics use a column-oriented storage layout with compression that minimizes the amount of data that such a query needs to read off disk.

## <a id="hardware" href="#table-of-contents">Hardware</a>

### Modern Storage Hardware

The figure below [^9] illustrates the different types of storage hardware currently in use, highlighting the trade-offs between performance, capacity, and price. One of the key principles of the memory hierarchy is that lower latency hardware is inevitably more expensive and limited in capacity.

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/storage_hierarchy.png?raw=true" alt="first example" style="border: 0px solid black; width: 80%; height: auto;">
</div>

Registers sit at the very top of the hierarchy, providing the CPU with the fastest possible access to data.

CPU Caches follow immediately after. Most modern CPUs employ a multi-level cache hierarchy (L1, L2, and often L3).

- L1 Cache: Located closest to the CPU core, L1 offers the highest speed. It is usually split into instruction-specific (I-cache) and data-specific (D-cache) units.
- L2 & L3 Caches: L2 is physically separate and slightly slower, while L3 is generally shared across multiple cores.

Cache memory is typically implemented using SRAM (Static Random Access Memory). SRAM requires multiple transistors to store a single bit, making it faster to read and write but also more expensive and less dense than DRAM (Dynamic Random Access Memory).

Main Memory (RAM) is the primary storage directly accessible to the CPU via the memory bus. The CPU fetches instructions and active data from here. Main memory is usually implemented with DRAM, which uses only one transistor and one capacitor per bit, allowing for higher density at a lower cost than SRAM.

Non-volatile Storage has a rich history, largely dominated by Hard Disk Drives (HDDs) until recently [^10]. HDDs read and write data using a magnetic read-write head that floats just nanometers above a rapidly spinning, magnetically-coated platter, as shown below.

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/hdd_3d.png?raw=true" alt="first example" style="border: 0px solid black; width: 60%; height: auto;">
</div>

The mechanical nature of HDDs imposes physical latency limits. This is why Solid State Drives (SSDs)—based on 3D NAND flash with no moving parts—have largely overtaken HDDs for many use cases. SSDs offer a massive performance leap, providing over 1,000x better random read/write IOPS than HDDs with similar or better power efficiency. However, they introduce their own specific complexities [^11]:

- Read/Write Asymmetry: While reads are fast, writes can degrade over time. SSDs cannot overwrite a single page (eg 4KB) directly; they must erase an entire block (eg 128 pages) to reuse it. This requires relocating valid data to a new block before erasing the old one—a process known as "Write Amplification."

- Service Life: NAND flash cells withstand a finite number of program/erase cycles before failing. The internal Garbage Collection (GC) process required to manage blocks further contributes to this wear.

For performance comparison, consider the following rough metrics for random and sequential access:

- HDD:
  - Random Reads (4KB): ~100 IOPS (approx. 10ms latency).
  - Sequential Reads: ~40k IOPS, translating into ~150 MB/s throughput.

- SSD (QD-32):
  - _Note that performance is typically measured at Queue Depth 32 (QD-32)_.
  - Random Reads (4KB): ~100k IOPS (SATA) to ~1M IOPS (NVMe PCIe 5).
  - Random Writes (4KB): ~80k IOPS (SATA) to ~800k IOPS (NVMe PCIe 5).
  - Sequential Reads: ~125k IOPS (SATA) to ~3.5M IOPS (NVMe PCIe 5). In throughput terms, ~500 MB/s (SATA) to ~14 GB/s (NVMe PCIe 5). Note that throughput is often bottlenecked by the interconnect (bus).

Emerging persistent memory technologies bridge the gap between volatile RAM and non-volatile storage. They combine the durability of storage with the byte-addressable access speeds of traditional RAM [^12].

Navigating this memory hierarchy is one of the primary challenges a database storage engine must solve to optimize performance.

### Modern Storage APIs

The below shows currently available Linux storage I/O interfaces [^13]. (a) and (b) are the oldest where (a) is blocking I/O API while (b) is asynch I/O. SPDK was developed by Intel in 2010s while io_uring is the latest addition to this list.

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/linux_io_interfaces.png?raw=true" alt="first example" style="border: 0px solid black; width: 60%; height: auto;">
</div>

In POSIX (a), you submit your read request to the kernel with `pread` syscall. The kernel puts it into the queue, fetches data from the SSD and interrupts your application when the response is ready.

libaio relies on two syscalls – `io_submit` to submit one or more requests and `io_get_events` to retrieve the completed I/O requests. This two syscall per I/O request is an important factor in its performance limitation.

SPDK essentially maps storage hardware driver's queues to the user-space, allowing the application to directly submit I/O requests to the SQs and poll completed requests from the CQs without the need for interrupts or system calls.

io_uring is somewhere in the middle between libaio and SPDK, having multiple modes to operate on. Its unique feature is having two ring data structures that are mapped into user space and shared with the kernel. Its modes of operation are shown below [^14].

<div style="text-align: center;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/io_uring_modes.png?raw=true" alt="first example" style="border: 0px solid black; width: 60%; height: auto;">
</div>

- (a) the application makes two `io_uring_enter` syscalls – one to notify kernel about I/O request(s) and another to get results of the completed I/O requests.
- (b) similar to (a) but in this case, the application instructs the kernel to rely on polling instead of interrupts when the kernel is talking to SSD driver.
- $(c$) the application asks the kernel to create a separate kernel thread per io_uring context to poll on both sides. Notice that this doesn't involve any syscalls.

Interestingly, most popular relational databases use POSIX with `O_DIRECT` option or its equivalent.

## <a id="references" href="#table-of-contents">References</a>

[^1]: Bayer, Rudolf, and Edward McCreight. "Organization and maintenance of large ordered indices."

[^2]: Dicken, Ben. "B-trees and database indexes." PlanetScale, 9 Sept. 2024, https://planetscale.com/blog/btrees-and-database-indexes.

[^3]: Congdon, Ben. "B-Trees: More Than I Thought I'd Want to Know." 17 Aug. 2021, https://benjamincongdon.me/blog/2021/08/17/B-Trees-More-Than-I-Thought-Id-Want-to-Know.

[^4]: Oracle. (2025). Figure 17.1 InnoDB Architecture. In MySQL 9.5 Reference Manual. https://dev.mysql.com/doc/refman/9.5/en/innodb-architecture.html

[^5]: Cole, Jeremy. "The basics of InnoDB space file layout." 3 Jan. 2013, https://blog.jcole.us/2013/01/03/the-basics-of-innodb-space-file-layout.

[^6]: Freund, Andres. "Pluggable table storage in PostgreSQL." 25 Jun. 2019, https://anarazel.de/talks/2019-06-25-pgvision-pluggable-table-storage/pluggable.pdf.

[^7]: Idreos, Stratos, and Mark Callaghan. "Key-value storage engines."

[^8]: Chandramouli, Badrish, et al. "Faster: A concurrent key-value store with in-place updates."

[^9]: "Persistent Memory Primer." Oracle Database Insider, 20 May 2020, blogs.oracle.com/database/persistent-memory-primer.

[^10]: "Mass storage." Wikipedia, 26 Aug. 2025, en.wikipedia.org/wiki/Mass_storage.

[^11]: Alibaba Clouder. "Storage System Design Analysis: Factors Affecting NVMe SSD Performance (1)." Alibaba Cloud Community Blog, 15 Jan. 2019, www.alibabacloud.com/blog/storage-system-design-analysis-factors-affecting-nvme-ssd-performance-1_594375.

[^12]: Koutsoukos, Dimitrios, et al. "How to use persistent memory in your database." arXiv preprint arXiv:2112.00425 (2021).

[^13]: Haas, Gabriel, and Viktor Leis. "What modern nvme storage can do, and how to exploit it: High-performance i/o for high-performance storage engines."

[^14]: Didona, Diego, et al. "Understanding modern storage APIs: a systematic study of libaio, SPDK, and io_uring."
