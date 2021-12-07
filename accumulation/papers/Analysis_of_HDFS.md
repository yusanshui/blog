### Analysis of HDFS Under HBase: A Facebook Messages Case Study

#### authors

Tyler Harter: 威斯康星大学麦迪逊分校讲师
FAST:美国高等计算系统协会(USENIX)主办的顶级国际会议，也是中国计算机学会CCF推荐的A类国际学术会议,代表了存储行业最高水平。

#### Abstract

Present a multilayer study of the Facebook Messages stack, which is based on HBase and HDFS. collect and analyze HDFS traces to identify potential improvements, which we then evaluate via simulation

#### Introduction

1. Large-scale distributed storage systems are exceedingly complex and time consuming to design, implement, and operate. Engineers often opt for layered architectures
2. Layered disadvantages:  decreased performance, lowered reliability, or other related issues
3. question：is HDFS an effective storage backend for HBase
4. FM is a messaging system that enables Facebook users to send chat and email-like messages to one another, FM stores its information within HBase
5. 实验得出的结论进行概括描述

#### Background

1. HBase sparse-table abstraction
HBase, like BigTable [3], provides aversioned sparsetable interface, but with two major differences:
(1)  keys are ordered (2) keys have semantic meaning which influences how HBase treats the data

2. Messages Architecture
Users of FM interact with a web layer, which is backed by an application cluster, which in turn stores data in a separate HBase cluster.
Large objects (e.g., message attachments) are an exception; these are stored in Haystack because HBase is inefficient for large data

#### Methodly

1. Trace Collection and Analysis
Build a new trace framework, HTFS(Hadoop Trace File System) to collect these details.Some data, though (e.g., the contents of a write), is not recorded;This makes traces smaller and (more importantly) protects user privacy.

2. Modeling and Simulation
* ![Figure 1:Tracing, analysis, and simulation.](../resources/Analysis_of_HDFS/1.png)
* We evaluate changes to the storage stack via simulation.Our simulations are based on two models (illustrated in Figure1): a model which determines how the HDFS I/O translates to local I/O and a model of local storage.
* This simplified model of replication could lead to errors for load balancing studies, but we believe little generality is lost for caching simulations and our other experiments
* We assume some locality between requests to non-adjacent offsets in the same file; for these, the seek time is min{10ms, distance/(100MB/s)}.

3. Simulation Validity
* does ignoring network latency skew our results? 
    + ![Statistic Sensitivity.](../resources/Analysis_of_HDFS/table1.png)
    + we explore our assumption about constant network latency by adding random jitter to the timing of requests and observing how important statistics change.
    + conclusion: Differences are quite small and are never greater than 6.4%,

4. Confidentiality
* disclose how large the sample is as a fraction of all the FM clusters

#### Workload Behavior

1. Multilayer Overview

* ![I/O across layers.](../resources/Analysis_of_HDFS/2.png)
* ![Data across layers.](../resources/Analysis_of_HDFS/3.png)
* conclusion: FM is very read-heavy, but logging,compaction, replication, and caching amplify write I/O,causing writes to dominate disk I/O. We also observe that while the HDFS dataset accessed by core I/O is relatively small, on disk the dataset is very large (120TB) and very cold (two thirds is never touched). Thus, architectures to support this workload should consider its hot/cold nature

2. Data Types

* ![Schema.](../resources/Analysis_of_HDFS/table2.png)
* ![File types.](../resources/Analysis_of_HDFS/4.png)
* conclusion: FM uses significant space to store messages and does a significant amount of I/O on these messages; however, both space and I/O are dominated by helper data (i.e., metadata, indexes, and logs). Relatively little data is both written and read during tracing; this suggests caching writes is of little value.

3. File Size

* ![File-size distribution.](../resources/Analysis_of_HDFS/5.png)
* ![Size/life correlation.](../resources/Analysis_of_HDFS/6.png)
* conclusion: Traditional HDFS workloads operate on very large files. While most FM data lives in large, long-lived files, most files are small and short-lived. This has metadata-management implications; HDFS manages all file metadata with a single NameNode because the data-to-metadata ratio is assumed to be high. For FM, this assumption does not hold; perhaps distributing HDFS metadata management should be reconsidered.

4. I/O Patterns

* ![Reads: locality map.](../resources/Analysis_of_HDFS/7.png)
* ![Read heat.](../resources/Analysis_of_HDFS/8.png)
* conclusion: At the HDFS level, FM exhibits relatively little sequentiality, suggesting high-bandwidth,high-latency storage mediums (e.g., disk) are not idealfor serving reads. The workload also shows very little spatial locality, suggesting additional prefetching would not help, possibly because FM already chooses for itself what data to prefetch. However, despite application-level and HBase-level caching, some of the HDFS data is particularly hot; thus, additional caching could help.

#### Tiered Storage: Adding Flash

1. Performance without Flash

* ![Disk performance.](../resources/Analysis_of_HDFS/9.png)
* ![Cache hit rate.](../resources/Analysis_of_HDFS/10.png)
* conclusion: The FM workload exhibits relatively little sequentiality or parallelism, so adding more disks or higher-bandwidth disks is of limited utility. Fortunately, the same data is often repeatedly read (§4.4), so a very large cache (i.e., a few hundred GBs in size) can service nearly 80% of the reads. The usefulness of a very large cache suggests that storing at least some of the hot data in flash may be most cost effective. 

2. Flash as Cache

* ![Tiered hit rates.](../resources/Analysis_of_HDFS/11.png)
* ![Flash lifetime.](../resources/Analysis_of_HDFS/12.png)
* ![Crash simulations.](../resources/Analysis_of_HDFS/13.png)
* conclusion: Adding flash to RAM can greatly improve the caching hit rate; furthermore (due to persistence) a hybrid flash/RAM cache can eliminate half of the extra disk reads that usually occur after a crash. However, using flash raises concerns about wear. Shuffling data between flash and RAM to keep the hottest data in RAM improves performance but can easily decrease SSD lifetime by a factor of 2x relative to a wear-aware policy. Fortunately, larger SSDs tend to have long life-times for FM, so wear may be a small concern (e.g.,120GB+ SSDs last over 5 years regardless of policy).

3. Flash as Buffer

* ![Flash Buffer.](../resources/Analysis_of_HDFS/14.png)
* conclusion: Using flash to buffer all writes results in much worse performance than using flash only as a cache. Ifflash is usedforbothcachingandbuffering,and if policies are tuned to only buffer files of the right size, thenperformancecanbeslightlyimproved. We conclude that these small gains are probably not worth the added complexity, so flash should be for caching only.

4. Is Flash worth the Money?

* ![Cost Model.](../resources/Analysis_of_HDFS/table3.png)
* ![Capex/latency tradeoff.](../resources/Analysis_of_HDFS/15.png)
* conclusion: Not only does adding a flash tier to the FM stack greatly improveperformance,but it is the most cost-effective way of improving performance. In some cases, adding a small SSD can triple performance while only increasing monetary costs by 5%.

#### Layering: Pitfalls and Solutions

1. Layering Background

* ![Layered architectures.](../resources/Analysis_of_HDFS/16.png)

2. Local Compaction
* ![Local-compaction architecture.](../resources/Analysis_of_HDFS/17.png)
* ![Local-compaction results.](../resources/Analysis_of_HDFS/18.png)
* Conclusion:Doing local compaction by bypassing the replication layer turns over half the network I/O into disk reads. This is a good tradeoff as network I/O is generally more expensive than sequential disk I/O

3. Combined Logging

* ![Combined-logging architecture.](../resources/Analysis_of_HDFS/19.png)
* ![Combined logging results.](../resources/Analysis_of_HDFS/20.png)
*Conclusion:Merging multiple HBase logs on a dedicated disk reduces logging latencies by a factor of 6. However,putrequests do not currently block until data is flushed to disks, and the performance impact on foreground reads is negligible. Thus,theadditionalcomplexity of combined logging is likely not worthwhile given the current durability guarantees. However, combined logging could enable HBase, at little performance cost, to give the additional guarantee that data is on disk before aputreturns. Providing such a guarantee would make logging a foreground activity.

#### Related Work

1. MapReduce study is broad, analyzing traces of coarse-grained events.our study is deep, analyzing traces of fine-grained events
2. Detailed trace analysis Apple desktop applications
3. A recent photo-caching study by Huanget al. focuses, much like our work, on I/O patterns across multiple layers of the stack.The photo-caching study correlated I/O across levels by tracing at each layer,  whereas our approach was to trace at a single layer and infer I/O at each underlying layer via simulation
4. trace-driven analysis and simulation is inspired by Kaushiket al.[16], a study of Hadoop traces from Yahoo!
5. We are not the first to suggest the methods we evaluated for better HDFS integrationour contribution is to quantify how useful these techniques are for the FM workload.

#### Conclusion 

1. a detailed multilayer study of storage I/O for Facebook Messages. 
2. First, the special handling received by writes make them surprisingly expensive.
3. Second, the GFS-style architecture is based on workload assumptions such as “high sustained bandwidth is more important than low latency”. For FM, many of these assumptions no longer hold. 
4. Unfortunately, we find that the benefits of simple layering are not free. additional network I/O and increases workload randomness at the disk layer. 
5. Fourth,  we find that for FM, flash is not a suitable replacement for disk. a small flash tier have a positive cost/performance tradeoff compared to systems built on disk and RAM alone.