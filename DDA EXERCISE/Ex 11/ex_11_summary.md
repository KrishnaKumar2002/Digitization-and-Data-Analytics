# DDA Exercise 11: Distributed Computing III - Scalability with Apache Spark (In-Depth Guide)

This document provides a **very detailed** breakdown of all theoretical concepts, computational frameworks, and tasks required for Exercise 11. The core focus is on understanding scalability within distributed systems using Apache Spark, evaluated through the computationally intensive Monte Carlo method for estimating $\pi$.

---

## 1. Mathematical Foundation: Monte Carlo Estimation of $\pi$

The **Monte Carlo method** is a broad class of computational algorithms that rely on repeated random sampling to obtain numerical results. In this exercise, it is used to estimate the value of Pi ($\pi$).

### 1.1 The Geometric Theory
Imagine a circle of radius $r$ inscribed perfectly inside a square with side length $2r$. 
- The **area of the circle** is $A_{circle} = \pi r^2$.
- The **area of the square** is $A_{square} = (2r)^2 = 4r^2$.

The ratio of the area of the circle to the area of the square is:
$$ \frac{A_{circle}}{A_{square}} = \frac{\pi r^2}{4r^2} = \frac{\pi}{4} $$

### 1.2 The Computational Algorithm
If you randomly scatter uniformly distributed points ("darts") over the area of the square, the probability that a dart falls inside the circle is proportional to the ratio of their areas:
$$ P(\text{inside circle}) = \frac{\pi}{4} $$

To compute this programmatically:
1. Generate pairs of random coordinates $(x, y)$ where both $x$ and $y$ are uniformly distributed between $0$ and $1$. This represents the top-right quadrant of the square.
2. Check if the point falls inside the unit circle by applying the Pythagorean theorem: $x^2 + y^2 < 1$.
3. Keep a tally of `points_inside_circle` versus `total_points`.
4. Calculate $\pi$ as:
$$ \pi \approx 4 \times \frac{\text{points\_inside\_circle}}{\text{total\_points}} $$

*The more points you generate, the closer your estimation gets to the true value of $\pi$ (Law of Large Numbers).*

![](http://www.physics.smu.edu/fattarus/pi.png)

---

## 2. Distributed Computing Framework: Apache Spark

Apache Spark is a unified analytics engine for large-scale data processing. It is designed to be fast, fault-tolerant, and easy to use.

### 2.1 Resilient Distributed Datasets (RDDs)
The fundamental data structure in Spark is the RDD. An RDD is an immutable, distributed collection of objects that can be operated on in parallel. When we generate `total_points` for the Monte Carlo estimation, Spark distributes these points across the CPU cores as an RDD.

### 2.2 Transformations vs. Actions
Spark operations are strictly divided into two categories:
- **Transformations (e.g., `map`, `filter`):** These operations create a *new* RDD from an existing one. In our exercise, `map` applies the logic `is_point_inside_unit_circle(p)` to every element in the RDD.
- **Actions (e.g., `reduce`, `count`, `collect`):** These operations return a final value to the driver program or write data to an external storage system. `reduce(add)` aggregates the results of the map function to count the total darts inside the circle.

### 2.3 Lazy Evaluation and the DAG
When measuring computation time, you will observe a massive discrepancy between `mapTime` and `reduceTime`.
- **Why is `mapTime` so short?** Spark uses **lazy evaluation**. When you call `map`, Spark does *not* execute the function. Instead, it merely records the operation by appending it to a **Directed Acyclic Graph (DAG)**—a logical execution plan. Recording a step in the DAG takes fractions of a millisecond.
- **Why is `reduceTime` so long?** When you call `reduce`, which is an **Action**, Spark finally submits the DAG to the cluster for execution. The cluster now generates the data (`parallelize`), runs the checking function on every data point (`map`), and aggregates the results (`reduce`). Thus, `reduceTime` encapsulates the duration of the *entire computation pipeline*.

---

## 3. Scalability Theory

Scalability is the property of a system to handle a growing amount of work by adding resources.

### 3.1 Scale-Up (Vertical Scaling)
Scale-up means adding more resources (CPU cores, RAM) to a **single node or machine**. 
- **Pros:** Easier to manage, less network overhead, no complex distributed architecture needed.
- **Cons:** Hardware limitations (a single motherboard can only hold so many CPUs/RAM), diminishing returns, and a single point of failure.

### 3.2 Scale-Out (Horizontal Scaling)
Scale-out means adding **more nodes (machines)** to the cluster.
- **Pros:** Theoretically infinite scalability, high availability, fault tolerance (if one node dies, others take over).
- **Cons:** High network overhead (data must be shuffled across the network), requires complex resource managers (like YARN or Slurm).

### 3.3 Amdahl's Law and Speed-up
**Speed-up** ($S$) measures how much faster a parallel algorithm executes compared to a sequential one:
$$ S = \frac{T_1}{T_p} $$
Where $T_1$ is the execution time using 1 processor, and $T_p$ is the execution time using $p$ processors.

**Amdahl's Law** states that the theoretical maximum speed-up using multiple processors is limited by the sequential fraction of the program (the part that *cannot* be parallelized). 
$$ S_{max} = \frac{1}{(1 - P) + \frac{P}{N}} $$
Where $P$ is the proportion of the program that can be parallelized, and $N$ is the number of processors. In Exercise 3, plotting Speed-up vs. Parallelism will visually demonstrate Amdahl's Law, as the speed-up curve will eventually flatten out ("diminishing returns") due to network overhead and sequential bottlenecks.

---

## 4. HPC Environment and Scripts Architecture

When executing Exercise 3.4 on the High-Performance Computing (HPC) Barnard Cluster, we utilize Slurm (Simple Linux Utility for Resource Management) to submit batch jobs.

### Cluster Initialization Diagram
![Screenshot_20260713_105631.png](/Users/krishnakumarm/.gemini/antigravity-ide/brain/51e6c8ad-e338-43a3-b1d7-f4b999c1783d/Screenshot_20260713_105631.png)

### The Script Pipeline
The execution relies on three interconnected scripts:
```text
main.sh (Job Orchestrator)
    |
    ├─> spark.sh (Cluster Setup & Job Submission)
    │   |
    │   └─> app.py (The PySpark Application)
    │
    └─> post_process.py (Data Analysis & Visualization)
```

#### Detailed Breakdown of Scripts:
1. **`main.sh`:** This is the orchestrator. It uses `sbatch` to request resources (nodes and CPUs) from the Slurm cluster. It submits multiple jobs sequentially (chaining) to test different parallelism levels, and finally queues `post_process.py` to run only after all Spark jobs finish.
2. **`spark.sh`:** Once Slurm allocates the nodes, this script starts the Spark Master on the primary node and Spark Workers on all other allocated nodes. It sets up the environment variables (`SPARK_WORKER_CORES`, `SPARK_MASTER_HOST`), and executes `spark-submit` to run our python code against the cluster.
3. **`app.py`:** The actual Spark application. It connects to the `SparkContext`, creates an RDD of $10^8$ or $10^9$ points, runs the Monte Carlo `map` and `reduce`, and appends the calculated time, node count, and parallelism settings to an output text file.
4. **`post_process.py`:** Reads the raw output text file generated by `app.py`. It computes the average processing times, calculates the Speed-up relative to the baseline (1 core), and uses `matplotlib` to generate and save graphs (Parallelism vs. Time, Parallelism vs. Speed-up).

---

## 5. Detailed Exercise Tasks

### Exercises 3.1 - 3.3: Scale-Up 
**Goal:** Understand how adding more CPU cores on a single machine affects performance.
- **Task 1:** Edit `app.py` to use Python's `time.time()` to measure the duration of `map()` versus `reduce()`.
- **Task 2:** Understand how `SparkSession.builder` configures the application. Modify the `spark.sparkContext.defaultParallelism` or adjust the `local[X]` master string to explicitly define how many threads Spark uses.
- **Task 3a:** Run the estimation multiple times with increasing parallelism (e.g., 1, 2, 4, 8 cores). Log the times and plot them. Find the "sweet spot" where adding more cores no longer yields significant time improvements.
- **Task 3b:** Calculate the speed-up for each core count and plot it. Analyze how it conforms to Amdahl's Law.

### Exercise 3.4: Scale-Out (HPC Only)
**Goal:** Distribute the workload across entirely separate physical machines on the Barnard cluster.
- **Task 1-3:** Same application logic as the Scale-up phase.
- **Task 4:** Modify `main.sh` to loop through different `--nodes` configurations in Slurm instead of just `--cpus-per-task`. 
- **Execution:** Run `./main.sh -h` to see how to trigger the pipeline.
- **Analysis:** Compare the Scale-out speed-up curve with the Scale-up speed-up curve. You will likely observe that Scale-out introduces more overhead (network communication between nodes) compared to Scale-up (inter-process communication on a shared memory bus), significantly affecting the ideal speed-up ratio.
