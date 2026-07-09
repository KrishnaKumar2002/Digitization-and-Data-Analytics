# DDA Exercise 10 — NYC Taxi Trips with Apache Spark: Complete Solutions

## 📋 Exercise Overview

| Exercise | Topic | Key Concept |
|---|---|---|
| 1 | Trips by passenger count | `groupBy().count()` + data quality |
| 2 | Min distance per group | `.agg(min())` |
| 3 | Filter zeros, recompute min | `.filter()` + chaining |
| 4 | Rewrite SQL as DataFrame API | `.filter().select()` |
| 5 | SQL: distance for tips > $5 | SQL `WHERE` clause |
| 6 | SQL: total_amount for dist > 30 | SQL `WHERE` clause |
| 7 | Box-and-whisker plots | `approxQuantile()` + `bxp()` |
| 8 | Trips per weekday | UDFs + `groupBy().count()` |
| 9 | Trips per hour | UDFs + `groupBy().count()` |
| 10 | Trips per pickup/dropoff zone | `groupBy().count()` + map viz |
| 11 | Top 10 highest-tip trips | `join()` + `filter()` + `orderBy().limit()` |

---

## 🔥 What is Apache Spark?

Apache Spark is a **distributed data processing engine**. It can process datasets that are too large to fit in a single machine's memory by splitting the work across many nodes.

```
Your Python Code
      ↓
  SparkSession  ← entry point
      ↓
  DataFrame     ← distributed table (like pandas but across a cluster)
      ↓
  Lazy Execution ← operations are NOT run until you call .show(), .collect(), etc.
      ↓
  Results
```

### Key concepts:

| Term | Meaning |
|---|---|
| `SparkSession` | The main entry point — creates DataFrames, runs SQL |
| `DataFrame` | Distributed table of rows with named, typed columns |
| `Transformation` | Lazy operation: `.filter()`, `.select()`, `.groupBy()` |
| `Action` | Triggers execution: `.show()`, `.count()`, `.collect()` |
| `Parquet` | Columnar binary file format — much faster than CSV for analytics |
| `UDF` | User Defined Function — apply a Python function to each row |

### Why lazy evaluation?

```python
# None of these actually run yet:
result = trips.filter(trips.trip_distance > 5).select("fare_amount")

# This triggers execution — Spark computes only what's needed:
result.show()
```

Lazy evaluation lets Spark **optimize the full query** before running it.

---

## ✅ Exercise 1 — Count Trips by Passenger Count

```python
trips.groupBy("passenger_count").count().orderBy("passenger_count").show()
```

**Equivalent SQL:**
```sql
SELECT passenger_count, COUNT(*) as count
FROM trips
GROUP BY passenger_count
ORDER BY passenger_count
```

**Unexpected values to discuss:**

| Value | Interpretation |
|---|---|
| `0` | Ghost trip — cancelled, repositioning, meter error |
| `NULL` | Vendor didn't record passenger count |
| `7`, `8`, `9` | Data entry error — NYC yellow taxis max capacity is 6 |

**NYC TLC Data Dictionary:** passenger_count is driver-entered and optional, so missing/zero values are common.

---

## ✅ Exercise 2 — Minimum Distance per Group

```python
from pyspark.sql import functions as F

trips.groupBy("passenger_count") \
     .agg(F.min("trip_distance").alias("min_distance")) \
     .orderBy("passenger_count") \
     .show()
```

**Result:** Almost every group will show `0.0` as the minimum.

**Why?** Many trips have `trip_distance = 0.0` — these are the anomalous trips.

---

## ✅ Exercise 3 — Remove Zeros, Recompute

```python
trips.filter(trips.trip_distance > 0.0) \
     .groupBy("passenger_count") \
     .agg(F.min("trip_distance").alias("min_nonzero_distance")) \
     .orderBy("passenger_count") \
     .show()
```

**After filtering:** Minimum values are now small but real (e.g., 0.01–0.1 miles) — these are very short but valid trips (crossing a block in Manhattan).

**Chaining pattern:** In PySpark you can chain operations — `.filter()` returns a DataFrame, so you immediately call `.groupBy()` on the result.

---

## ✅ Exercise 4 — SQL → DataFrame API

**SQL version:**
```sql
SELECT fare_amount FROM trips WHERE trip_distance >= 5
```

**Three equivalent DataFrame API approaches:**

```python
# Method 1: Column reference
trips.filter(trips.trip_distance >= 5).select("fare_amount").show()

# Method 2: SQL string condition
trips.where("trip_distance >= 5").select("fare_amount").show()

# Method 3: col() function (most flexible — works in complex expressions)
from pyspark.sql.functions import col
trips.filter(col("trip_distance") >= 5).select(col("fare_amount")).show()
```

**When to use which?**
- SQL string: quick ad-hoc queries
- `col()`: when building conditions programmatically

---

## ✅ Exercise 5 — SQL: Trip Distance for Tips > $5

```python
query = "SELECT trip_distance FROM trips WHERE tip_amount > 5"
sqlContext.sql(query).show()
```

**Insight:** High-tip trips tend to be longer distances (airport runs, suburban trips).

**Extended query to get summary:**
```sql
SELECT
    COUNT(*)           AS num_trips,
    AVG(trip_distance) AS avg_dist,
    MAX(trip_distance) AS max_dist
FROM trips
WHERE tip_amount > 5
```

---

## ✅ Exercise 6 — SQL: Total Amount for Distances > 30 miles

```python
query = "SELECT total_amount FROM trips WHERE trip_distance > 30"
sqlContext.sql(query).show()
```

**Insight:** Trips > 30 miles are typically:
- Airport runs (JFK is ~15–20 miles, but can be 30+ in traffic routing)
- Suburban long-haul trips
- Expect `total_amount` of $60–200+

---

## ✅ Exercise 7 — Box-and-Whisker Plots

### The 5-Number Summary

A box plot needs 5 numbers for each column:

```
whislo ───── Q0  (minimum, or lower fence)
  q1   ─┐
         │ IQR = Q75 - Q25
  med   ─┤  Q50 (median — middle value)
         │
  q3   ─┘  Q75
whishi ───── Q100 (maximum, or upper fence)
```

### Computing Quantiles in PySpark

```python
# approxQuantile(column, probabilities, relativeError)
# Returns list of values at each probability level
columnQuantiles = trips.stat.approxQuantile(
    "trip_distance",
    [0.0, 0.25, 0.5, 0.75, 1.0],
    0.01   # 1% relative error — fast approximation
)
# [min, Q25, median, Q75, max]
```

**Why approximate?** Exact quantiles require a full sort of the data — expensive for billions of rows. `relativeError=0.01` gives 1% accuracy with much less computation.

### Building the Plot

```python
stats = [{
    "whislo": columnQuantiles[0],   # Q0
    "q1":     columnQuantiles[1],   # Q25
    "med":    columnQuantiles[2],   # Q50
    "q3":     columnQuantiles[3],   # Q75
    "whishi": columnQuantiles[4],   # Q100
}]
axes.bxp(bxpstats=stats, showfliers=False)
```

**What the plots reveal:**
- `trip_distance`: Heavily right-skewed — most trips are under 5 miles, rare very long ones
- `fare_amount`: Similar right skew, with median around $10
- `tip_amount`: Many zero-tip trips (cash fares); positive skew in credit card tips
- `passenger_count`: Mostly 1–2 passengers

---

## ✅ Exercise 8 — Trips per Weekday

### UDFs — User Defined Functions

A **UDF** wraps a Python function so Spark can apply it to each row in a distributed way.

```python
# Decorator @udf registers the function with Spark
@udf(returnType=StringType())
def weekdayStr(d):
    # d is a Python datetime object (from the timestamp column)
    return calendar.day_name[d.weekday()]  # "Monday", "Tuesday", etc.

@udf(returnType=IntegerType())
def weekday(d):
    return d.weekday()  # 0=Monday, 6=Sunday
```

### Solution pattern:

```python
weekdayRows = (
    trips
    .select(weekdayStr(trips.tpep_dropoff_datetime).alias("weekday"))
    .groupBy("weekday")
    .count()
    .orderBy("count", ascending=False)
    .collect()  # bring small result to Python
)
```

**Key:** `.collect()` brings data from Spark (distributed) to Python (local). Only use it when results are small — here we have 7 rows (one per day).

**Expected pattern for January 2022:**
- Friday/Saturday: most trips (nightlife, end of week)
- Sunday/Monday: fewer trips (quieter days)

---

## ✅ Exercise 9 — Trips per Hour

Same pattern as Exercise 8, but extract `.hour` from datetime:

```python
@udf(returnType=IntegerType())
def hour(d):
    return d.hour   # 0-23

hourRows = (
    trips
    .select(hour(trips.tpep_dropoff_datetime).alias("hour"))
    .groupBy("hour")
    .count()
    .orderBy("count", ascending=False)
    .collect()
)
```

**Expected NYC taxi pattern:**
```
3-5 AM    ████ (lowest — overnight)
6-7 AM    ████████ (morning ramp-up)
8-9 AM    ████████████████ (morning rush)
12-13 PM  █████████████ (lunch)
17-19 PM  ████████████████████ (evening rush — peak)
20-23 PM  ████████████████ (evening out)
```

---

## ✅ Exercise 10 — Trip Counts per Zone (Map Visualization)

### Grouping by Location ID

```python
# Pickup counts: {zone_id → count}
pickupData = trips.groupBy("PULocationID").count().collect()
grouped_by_pickup_location = {row["PULocationID"]: row["count"] for row in pickupData}

# Dropoff counts: {zone_id → count}
dropoffData = trips.groupBy("DOLocationID").count().collect()
grouped_by_dropoff_location = {row["DOLocationID"]: row["count"] for row in dropoffData}
```

**Why `.collect()` is safe here:** There are only 265 taxi zones, so the result is tiny.

### Color mapping logic

```python
# Red channel (0-255) scaled by trip density:
"fillColor": '#%02X0000' % (int(taxizoneIntensity * 255 / maximum_intensity))
# Maximum zone → pure red (#FF0000)
# Empty zone   → black (#000000)
```

**Expected result:**
- Midtown Manhattan and JFK Airport area: darkest red (most trips)
- Outer boroughs: lighter (fewer trips)
- Pickup and dropoff maps look similar — people who get dropped off somewhere also get picked up there

---

## ✅ Exercise 11 — Top 10 Highest-Tip Trips (Excluding Unknown Zones)

### Why Filter Unknown Zones?

Zone `264` = "Unknown" in the TLC lookup table. Trips with Unknown pickup/dropoff don't have valid geographic coordinates — we can't draw lines for them on the map.

### Join Strategy

We need to join `trips` with `zoneLookup` **twice** — once for pickup zone, once for dropoff:

```python
# Alias to avoid column name conflicts
pu_lookup = zoneLookup.withColumnRenamed("LocationID", "PU_ID") \
                       .withColumnRenamed("Borough", "PU_Borough")
do_lookup = zoneLookup.withColumnRenamed("LocationID", "DO_ID") \
                       .withColumnRenamed("Borough", "DO_Borough")

temporary = (
    trips
    .join(pu_lookup, trips.PULocationID == pu_lookup.PU_ID, how="left")
    .join(do_lookup, trips.DOLocationID == do_lookup.DO_ID, how="left")
    .filter(
        (col("PU_Borough") != "Unknown") &
        (col("DO_Borough") != "Unknown")
    )
)
```

### Get Top 10

```python
tripsWithHighestTips = (
    temporary
    .orderBy(col("tip_amount"), ascending=False)   # sort descending
    .limit(10)                                      # take top 10
    .collect()                                      # bring to Python
)
```

**Key methods:**
- `.orderBy(col, ascending=False)` → sort descending
- `.limit(N)` → keep only first N rows (much better than `.collect()` then slicing)
- `.join(df2, condition, how="left")` → SQL-style join; `how="left"` = keep all trips even if no zone match

### Visualization as GeoJSON

Each trip becomes a **GeoJSON LineString** from the pickup zone centroid to the dropoff zone centroid:

```python
def trip_to_geojson(trip):
    start = to_lon_and_lat(zoneCenters[trip["PULocationID"]])  # [lon, lat]
    end   = to_lon_and_lat(zoneCenters[trip["DOLocationID"]])
    return Feature(geometry=LineString([start, end]), properties={...})
```

**Expected result:** High-tip trips are often airport runs (Midtown → JFK/LaGuardia) — visible as long red lines on the map.

---

## 🔑 Key PySpark Patterns Summary

### Grouping and Aggregation

```python
# Count per group
trips.groupBy("VendorID").count()

# Multiple aggregations
trips.groupBy("passenger_count").agg(
    F.min("trip_distance").alias("min_dist"),
    F.max("trip_distance").alias("max_dist"),
    F.avg("trip_distance").alias("avg_dist"),
    F.count("*").alias("n_trips")
)
```

### Filtering

```python
trips.filter(trips.trip_distance > 0)           # column reference
trips.filter("trip_distance > 0")               # SQL string
trips.filter(col("trip_distance") > 0)          # col() function
trips.filter((col("a") > 0) & (col("b") > 0))  # multiple conditions
```

### SQL Queries

```python
trips.createOrReplaceTempView("trips")          # register as SQL table
spark.sql("SELECT * FROM trips WHERE ...").show()
```

### User Defined Functions

```python
from pyspark.sql.functions import udf
from pyspark.sql.types import IntegerType

@udf(returnType=IntegerType())
def my_func(value):
    return some_python_computation(value)

# Apply to a column
df.select(my_func(df.my_column).alias("result"))
```

### Joins

```python
# Inner join
trips.join(zoneLookup, trips.PULocationID == zoneLookup.LocationID, how="inner")

# Left join (keep all rows from left DataFrame)
trips.join(zoneLookup, trips.PULocationID == zoneLookup.LocationID, how="left")
```

### Collecting results

```python
df.show()               # print first 20 rows (stays in Spark)
df.collect()            # returns List[Row] (bring to Python — use only for small results)
df.count()              # return integer count
df.first()              # first row as Row object
df.toPandas()           # convert to pandas DataFrame (only for small DataFrames!)
```

---

## 📊 DataFrame API vs SQL — When to Use What?

| Scenario | Use |
|---|---|
| Quick exploration | SQL string (`spark.sql(...)`) |
| Programmatic column names | `col()` + DataFrame API |
| Complex multi-step pipelines | DataFrame API (chainable) |
| Joins and aggregations | Both work — DataFrame API is more composable |
| Window functions | Both work |

Both produce the **same execution plan** — choose readability.
