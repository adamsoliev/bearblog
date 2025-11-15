#### Table of Contents
* [Database Storage](#db-storage)
* [OLTP](#oltp)
  * [B+tree storage engines](#b-plus-se)
  * [LSM tree storage engines](#lsm-tree-se)
  * [LSH table storage engines](#lsh-table-se)
* [OLAP](#olap)
* [Other](#other)
* [References](#references)

---

# <a id="db-storage" href="#table-of-contents">Database storage</a>
you input data certain way (data model) -> database stores it certain way (storage - write part)

you query data certain way (query language) -> database fetches it certain way (storage - read part)

# <a id="oltp" href="#table-of-contents">OLTP</a>
Storage engines optimized for transactional (OLTP) workloads can be broadly classified into:
* B+ tree-based 
* LSM (Log-Structured Merge) tree-based
* LSH (Log-Structured Hash) table-based

B+ tree-based storage engines — these maintain a global sorted order (tree) and typically update data in place. The B‐tree data structure was invented in 1970. Many classic relational engines use this design.

LSM (Log-Structured Merge) tree-based storage engines — introduced in academic literature in 1996. These engines buffer updates in memory and flush out sorted runs, relaxing strict in‐place updates and global tree maintenance, thereby optimizing for high ingestion/write throughput (common in internet scale, write‐heavy applications). Compared to B+ tree storage engines, LSM ones achieve better writes but give up some read performance (eg for short-range queries) and memory amplification. [^1]

LSH (Log-Structured Hash) table-based storage engines — forwent ordering entirely (no global/local sort order) and instead use a hash approach, optimizing for very high ingest throughput. Compared to LSM tree based storage engines, LSH table ones achieve even better writes but give up some more read performance (eg range queries) and memory amplification. [^1]

Looking at Postgres, 
<div style="text-align: left;">
<img src="https://github.com/adamsoliev/bearblog/blob/main/database_storage/images/postgres_se.png?raw=true" alt="first example" height="600" style="border: 1px solid black;">
</div>


# <a id="olap" href="#table-of-contents">OLAP</a>
Storage engines that are optimized for for analytics (OLAP)

# <a id="other" href="#table-of-contents">Other</a>
storage engines that are optimized for more advanced queries, such as text retrieval

# <a id="references" href="#table-of-contents">References</a>
[^1]: key-value storage engines paper
