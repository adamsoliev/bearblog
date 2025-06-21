Have you ever had a feature "click" for you, where you suddenly shift from taking it for granted to seeing it everywhere? That was my experience with search. This shift from passive user to curious techie person led me down a rabbit hole, and the complexity I found underneath that simple search box is what I'll be sharing here.

For simplicity, let's view search as two distinct processes. The first is **indexing**, which is the entire preparatory workflow that ingests, cleans, and structures data for fast and relevant retrieval.

This journey starts by collecting data from public or private sources. This raw data is then passed through a processing pipeline to be normalized—a critical step that usually involves splitting text into words, converting it to lowercase, removing common "stopwords," and reducing words to their root form (stemming/lemmatization).

Once the data is clean, the system builds one or more indexes based on the intended use case. This could be an inverted index for full-text search, a vector index for semantic understanding, or a geospatial index for location-aware queries. This is also the stage where knowledge graphs can be created to add contextual richness. The final step is to store all the resulting artifacts—the raw data, the normalized version, and the indexes themselves—in a durable storage system.

------------

we don't generally notice search; when we do, we see it everywhere. after realizing that, I got curious and delved deep into it and found out something, which I tell the reader in the rest of the post.

For simplicity's sake, we can think of search as two processes. First is indexing process, where you have start with public/private data sources, stream or batch ingest them and process them, feeding indexing pipeline with the results. Processing stage might differ based on the use case but for majority it involves splitting on whitespace and punctuation, lowercasing, removing stopwords, and possibly stemming or lemmatization (reducing words to their root form).

Indexing pipeline takes cleaned data and indexes them - based on use case, creating inverted index for full-text search, vector index for semantic search, geospatial index for geosearch and traditional indexes for range/analytical workloads. Knowledge graphs, which adds more context to search queries by providing information about things, people, or places, are also created in this stage.

Final step of indexing process is storage, where raw, cleaned and indexes are stored in appropriate storages.

Second is search/query process. You start with a user query, clean it (Word stemming and spell correction), understand and potentially rewrite it where related words and synonyms are added and unimportant words are removed. Next step is retrieval or candidate generation where you try to get millions or billions of documents related to the user query. A next step is ranking where you try to ensure that the best results rise to the top (since only top 10 or 20 are returned). These two last steps heavily make use of the indexes that got created earlier. Personalization, business rules related filtering or boosting are mixed with the last two steps to ensure for example that a user gets only the results that he has access to.

| Tier (top → bottom) | Representative items | What it really means |
|---------------------|---------------------|---------------------|
| Shallow | keyword match, stop-lists, BM25 rank | Classic “search box” plumbing—vector math so simple you can still read log files by eye. |
| Comfortable | stemming, synonyms, query grammar | Start normalizing words and parsing operators; recall goes up, debugging relevance goes down. |
| Intermediate | 1-s refresh, incremental/NRT commits | Lucene’s second-scale refresh and log-friendly index structures make new docs searchable almost instantly. |
| Advanced | shard/replica orchestration, WAL replay | Distributed indexes stay live by copying segments and replaying writes when primaries crash. |
| Deep | ANN vector search, hybrid fusion | Dense embeddings meet sparse terms; engines juggle HNSW graphs and BM25 in one shot. |
| Abyss | Kafka → ES streaming, ILM hot-warm-cold, segment warming | Pipelines pump millions of events per second while index-lifecycle and pre-copy merges keep latency flat. |
| Eldritch | learned index structures, self-tuning layouts | Replace B-trees with neural models that “predict” where postings live—fast, fragile, and still a lab project. |
| Ocean floor | reciprocal-rank fusion (RRF), multi-stage rank mixing | Fuse dense, sparse, and rule-based ranks without score normalization—black magic that can both rescue and ruin relevance. |
