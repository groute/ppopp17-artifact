Groute Graph Dataset
====================

This dataset contains five graphs:

1. USA: USA Road Map.
   Obtained from 9th DIMACS Implementation Challenge: http://www.dis.uniroma1.it/challenge9/download.shtml

2. OSM-eur-k: OSM Europe Road Map Graph.
   Obtained from Karlsruhe Institute of Technology, OSM Europe Graph, 2014: http://i11www.iti.uni-karlsruhe.de/resources/roadgraphs.php

3. soc-LiveJournal1: LiveJournal Social Network Graph.
   Obtained from T. A. Davis and Y. Hu. The university of florida sparse matrix collection. ACM Trans. Math. Softw., 38(1):1:1–1:25, 2011.

4. twitter: Twitter Follower Graph (largest component), ICWSM 2010.
   Obtained from M. Cha, H. Haddadi, F. Benevenuto, and P. K. Gummadi. Measuring user influence in Twitter: The million follower fallacy. ICWSM, 10(10-17):30, 2010.

5. kron21.sym: logn21 Kronecker Generator Graph.
   Obtained from 10th DIMACS Implementation Challenge: http://www.cc.gatech.edu/dimacs10/archive/kronecker.shtml




The graphs were converted to Galois binary CSR graph format (.gr).

Each graph includes the graph file (graph.gr), graph metadata (graph.gr.metadata),
expected BFS results (bfs-graph.gr.txt) and expected SSSP results (sssp-graph.gr.txt).

The graph metadata contains information about the graph (number of connected components),
as well as information on which delta to use for soft-priority scheduling.



Graph Properties
----------------

|    Name             | Nodes | Edges  | Avg. Degree  |   Max Degree   | Size (GB) |
| --------------------|:-----:|:------:|:------------:|:--------------:|:---------:|
| USA                 |  24M  | 58M    |  2.41        |    9           | 0.62      |
| OSM-eur-k           | 174M  | 348M   |  2.00        |   15           | 3.90      |
| soc-LiveJournal1    |   5M  | 69M    | 14.23        | 20,293         | 0.56      |
| twitter             |  51M  | 1,963M | 38.37        | 779,958        | 16.00     |
| kron21.sym          |   2M  | 182M   | 86.82        | 213,904        | 1.40      |

