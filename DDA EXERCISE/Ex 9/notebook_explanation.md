# 🗽 NYC Taxi Trips — Notebook Deep Dive (Ex 9)

> This notebook analyzes **NYC Yellow Taxi Trip data (January 2022)** using **Apache Spark (PySpark)** running inside a Dockerized JupyterHub. It covers distributed data processing, SQL queries, time-based analysis, and interactive map visualizations.

---

## 📦 Dataset

| File | Description |
|---|---|
| `yellow_tripdata_2022-01.parquet` | ~3M taxi trips in NYC, Jan 2022 |
| `taxi_zones.zip` + `.shp` | NYC geographic zone polygons (for maps) |
| `taxi_zone_lookup.csv` | Zone ID → Borough/Name lookup table |

**Key columns in the trips dataset:**

| Column | Type | Meaning |
|---|---|---|
| `VendorID` | int | Taxi vendor (1 or 2) |
| `tpep_pickup_datetime` | timestamp | Pickup time |
| `tpep_dropoff_datetime` | timestamp | Dropoff time |
| `passenger_count` | double | Number of passengers |
| `trip_distance` | double | Distance in miles |
| `PULocationID` | int | Pickup zone ID |
| `DOLocationID` | int | Dropoff zone ID |
| `fare_amount` | double | Fare charged ($) |
| `tip_amount` | double | Tip given ($) |
| `total_amount` | double | Total charged ($) |

---

## 🔧 Section 1 — Setup & Data Download

```python
base_directory = "./data"
# Downloads yellow_tripdata_2022-01.parquet → data/taxidata/
# Downloads taxi_zones.zip → data/taxizonesdata/
# Downloads taxi_zone_lookup.csv → data/taxizonesdata/
```

**What happens:** The notebook auto-downloads the data files from the NYC TLC open data CDN if they don't exist locally. This is only run once.

---

## ⚡ Section 2 — Spark Context Initialization

```python
import findspark
findspark.init(os.environ['SPARK_HOME'])  # Finds Spark at /opt/spark

from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("Python Spark Map Visualization of NYC taxi trips") \
    .getOrCreate()

sc = spark.sparkContext
```

**What is Spark?**

```
Your Python Code
      ↓
  SparkSession (entry point)
      ↓
  SparkContext (talks to cluster)
      ↓
  Worker Nodes (process data in parallel)
```

- **SparkSession** = the main entry point for DataFrame/SQL operations
- **SparkContext (sc)** = lower-level API for RDD operations
- **`findspark`** = helps Python find the Spark installation

Then the data is loaded:
```python
trips = spark.read.parquet(data_path)  # Reads the .parquet file as a Spark DataFrame
```

---

## 📊 Section 3 — GroupBy (Aggregation)

### How `groupBy` works:

```
trips DataFrame (millions of rows)
         ↓
  .groupBy("VendorID")     ← splits rows into groups
         ↓
  .count()                 ← counts rows per group
         ↓
  .show()                  ← prints result
```

**Example built-in demo:**
```python
trips.groupBy("VendorID").count().show()
# Output: VendorID 1 → N trips, VendorID 2 → M trips
```

---

## ✏️ Exercise 1 — Count trips by passenger count

**Task:** Group trips by number of passengers. Check for unexpected values.

**Solution:**
```python
# Cell [15]: empty — just a placeholder
# Cell [16]: the actual answer
trips.groupBy("passenger_count").count().orderBy("passenger_count").show()
```

**Why interesting:** You'll likely see:
- `passenger_count = 0` → ghost trips (no passengers?)
- `passenger_count = 7, 8, 9` → impossible for a standard taxi

**Unexpected values:** 0 passengers, very high counts (data quality issues).

---

## ✏️ Exercise 2 — Minimum trip distance per passenger group

**Task:** Find the minimum `trip_distance` for each `passenger_count` group.

**Solution:**
```python
from pyspark.sql.functions import min

trips.groupBy("passenger_count") \
     .agg(min("trip_distance").alias("min_distance")) \
     .orderBy("passenger_count") \
     .show()
```

**Why interesting:** Minimum distance will likely be `0.0` for most groups — meaning the taxi was booked but went nowhere (cancelled, data error, etc.)

---

## ✏️ Exercise 3 — Remove zero distances

**Task:** Remove all rows where `trip_distance == 0.0` from the previous result.

**Solution:**
```python
from pyspark.sql.functions import min

trips.filter(trips.trip_distance > 0.0) \
     .groupBy("passenger_count") \
     .agg(min("trip_distance").alias("min_distance")) \
     .orderBy("passenger_count") \
     .show()
```

**Key concept — filter vs where:**
```
trips (all rows)
   ↓ .filter(condition)   ← removes rows not matching condition
filtered trips (clean data)
   ↓ .groupBy(...)
   ↓ .agg(...)
result
```

---

## 🗄️ Section 4 — SQL Queries

Spark supports running raw SQL against DataFrames by registering them as **temporary views**:

```python
trips.createOrReplaceTempView("trips")  # Register as a virtual SQL table

# Now you can query it with SQL:
result = sqlContext.sql("SELECT fare_amount FROM trips WHERE trip_distance >= 10")
result.show()
```

**How it works internally:**
```
DataFrame (trips)
      ↓ createOrReplaceTempView("trips")
SQL Table "trips" (virtual, in-memory, distributed)
      ↓ sqlContext.sql("SELECT ...")
New DataFrame (result)
```

---

## ✏️ Exercise 4 — Rewrite SQL as functional API

**Task:** Rewrite `SELECT fare_amount FROM trips WHERE trip_distance >= 10` without SQL.

**Solution:**
```python
trips.filter(trips.trip_distance >= 10).select("fare_amount").show()
```

| SQL | PySpark Functional |
|---|---|
| `SELECT col` | `.select("col")` |
| `WHERE cond` | `.filter(condition)` |
| `GROUP BY` | `.groupBy()` |
| `ORDER BY` | `.orderBy()` |
| `LIMIT n` | `.limit(n)` |

---

## ✏️ Exercise 5 — SQL: trips with tip > $5

**Task:** Find trip distances where `tip_amount > 5`. Write as SQL query.

**Solution:**
```python
query = "SELECT trip_distance FROM trips WHERE tip_amount > 5"
sqlContext.sql(query).show()
```

---

## ✏️ Exercise 6 — SQL: total amount for long trips

**Task:** Get total trip amount for distances larger than 10 miles.

**Solution:**
```python
query = "SELECT total_amount FROM trips WHERE trip_distance > 10"
sqlContext.sql(query).show()
```

Or with aggregation:
```python
query = "SELECT SUM(total_amount) as total FROM trips WHERE trip_distance > 10"
sqlContext.sql(query).show()
```

---

## 📦 Section 5 — Summary Statistics

```python
trips.describe().show()
```

This gives `count`, `mean`, `std`, `min`, `max` for all numeric columns — like pandas `.describe()` but distributed across a Spark cluster.

---

## 📈 Exercise 7 — Box-and-Whisker Plots

**Task:** Create a boxplot for each numerical column using `matplotlib`.

**What is a boxplot?**

```
    ┌──────────────┐
────┤   Q1    Q3   ├────
    └──────────────┘
  whisker-lo   whisker-hi
      median (line in box)
```

| Component | Value |
|---|---|
| `whislo` | 5th percentile (or min) |
| `q1` | 25th percentile |
| `med` | 50th percentile (median) |
| `q3` | 75th percentile |
| `whishi` | 95th percentile (or max) |

**Solution:**
```python
for column in trips.dtypes:
    name = column[0]
    colType = column[1]
    if colType not in ('string', 'timestamp', 'timestamp_ntz'):
        columnQuantiles = trips.approxQuantile(name, [0.05, 0.25, 0.5, 0.75, 0.95], 0.0)
        print("{} quantiles: {}".format(name, columnQuantiles))
        stats = [{
            "whislo": columnQuantiles[0],
            "q1":     columnQuantiles[1],
            "med":    columnQuantiles[2],
            "q3":     columnQuantiles[3],
            "whishi": columnQuantiles[4]
        }]
        fig, axes = plt.subplots(nrows=1, ncols=1, figsize=(5,5), sharey=True)
        axes.bxp(bxpstats=stats, showfliers=False)
        axes.grid(True)
        axes.set_title(name)
```

**Key API:** `trips.approxQuantile(column, probabilities, relativeError)`
- `probabilities` = list of percentiles (0.0–1.0)
- `relativeError=0.0` = exact computation (slower but precise)

---

## 📅 Exercise 8 — Trips per Weekday (UDF)

**Task:** Show number of trips per day of the week.

**What is a UDF (User Defined Function)?**

Spark operates on distributed data — you can't just call `row.weekday()` directly. Instead you wrap your function as a UDF so Spark can apply it row-by-row across the cluster:

```
DataFrame row (timestamp) → UDF(weekday) → integer 0–6
```

**Solution:**
```python
from pyspark.sql.functions import udf, col
from pyspark.sql.types import IntegerType
import calendar

@udf
def weekdayStr(d):
    return calendar.day_name[d.weekday()]  # "Monday", "Tuesday", ...

@udf(returnType=IntegerType())
def weekday(d):
    return d.weekday()  # 0=Monday ... 6=Sunday

weekdayRows = trips.select(weekday(trips.tpep_dropoff_datetime).alias("weekday")) \
                   .groupBy("weekday") \
                   .count() \
                   .orderBy("weekday") \
                   .collect()

barchart(weekdayRows, "weekday")
```

**Python weekday() convention:**
| Return | Day |
|---|---|
| 0 | Monday |
| 1 | Tuesday |
| 2 | Wednesday |
| 3 | Thursday |
| 4 | Friday |
| 5 | Saturday |
| 6 | Sunday |

---

## 🕐 Exercise 9 — Trips per Hour

**Task:** Show number of trips for each hour of the day (0–23).

**Solution:**
```python
@udf(returnType=IntegerType())
def hour(d):
    return d.hour  # extracts hour from datetime

hourRows = trips.select(hour(trips.tpep_dropoff_datetime).alias("hour")) \
                .groupBy("hour") \
                .count() \
                .orderBy("hour") \
                .collect()

barchart(hourRows, "hour")
```

**Expected insight:** Peak taxi demand typically appears at **8–9 AM** (morning commute) and **5–8 PM** (evening rush hour).

---

## 🗺️ Section 6 — Map Visualizations (leafmap)

The notebook uses **leafmap** (a Python library built on Leaflet.js) to show NYC taxi zones on an interactive map.

```python
import leafmap

def getMap():
    map_args = {
        "google_map": "HYBRID",  # satellite view
        "center": [40.7128, -74.0060],  # NYC lat/lon
        "zoom": 11,
    }
    return leafmap.Map(**map_args)
```

The map layers:
1. **Base satellite layer** — NYC from above
2. **taxi_zones.shp** — polygon outlines of the 263 NYC taxi zones
3. **Color coding** — zones colored by trip intensity (heatmap)
4. **Trip lines** — drawn as GeoJSON LineStrings between pickup and dropoff zones

---

## ✏️ Exercise 10 — Trips per Zone (Pickup & Dropoff)

**Task:** Count how many trips start/end in each zone.

**Solution:**
```python
pickupData = trips.groupBy("PULocationID") \
                  .count() \
                  .collect()

dropoffData = trips.groupBy("DOLocationID") \
                   .count() \
                   .collect()

grouped_by_pickup_location  = {row["PULocationID"]: row["count"] for row in pickupData}
grouped_by_dropoff_location = {row["DOLocationID"]: row["count"] for row in dropoffData}
```

These dictionaries (`zone_id → count`) are then passed to the color function which shades each zone on the map — darker = more trips.

---

## ✏️ Exercise 11 — Top 10 Highest Tips with Zone Names

**Task:** Find the 10 trips with the highest tips. Join with zone lookup to get readable names. **Do not use `.collect()` on the full dataset** — use `.limit()` first.

**Solution:**
```python
# Load zone lookup table
zoneLookup = spark.read.csv(base_directory + "/taxizonesdata/taxi_zone_lookup.csv",
                            header=True, inferSchema=True)

# Filter out "Unknown" zones first
validZones = zoneLookup.filter(zoneLookup.Borough != "Unknown")

# Join trips with zone names for pickup and dropoff
temporary = trips \
    .join(validZones.withColumnRenamed("LocationID", "PULocationID")
                    .withColumnRenamed("Zone", "PUZone"),
          on="PULocationID", how="inner") \
    .join(validZones.withColumnRenamed("LocationID", "DOLocationID")
                    .withColumnRenamed("Zone", "DOZone"),
          on="DOLocationID", how="inner") \
    .orderBy(trips.tip_amount.desc())

# Cell [59]: filter Unknown values + get top 10
tripsWithHighestTips = temporary \
    .filter(temporary.Borough != "Unknown") \
    .limit(10)

tripsWithHighestTips
```

**Why `.limit()` before `.collect()`?**

```
Full Dataset: ~3 million rows
      ↓ .collect()  ← BAD: loads ALL 3M rows into driver RAM
      
Full Dataset: ~3 million rows
      ↓ .orderBy(tip_amount.desc()).limit(10)  ← GOOD: only brings 10 rows to driver
      ↓ .collect()
```

---

## 🧵 Full Notebook Flow (Bird's Eye View)

```
Setup & Download Data
       ↓
Initialize Spark Session
       ↓
Load Parquet → trips DataFrame
       ↓
┌─────────────────────────────────────────────┐
│ GroupBy Analysis:                           │
│  Ex1: Count by passenger_count              │
│  Ex2: Min distance per group                │
│  Ex3: Min distance (excluding 0.0 miles)    │
└─────────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────────┐
│ SQL Queries:                                │
│  Ex4: fare_amount WHERE distance >= 10      │
│  Ex5: trip_distance WHERE tip > $5          │
│  Ex6: total_amount WHERE distance > 10      │
└─────────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────────┐
│ Visualization:                              │
│  Ex7: Boxplots of all numeric columns       │
│  Ex8: Trips per weekday (bar chart)         │
│  Ex9: Trips per hour (bar chart)            │
└─────────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────────┐
│ Map Visualization:                          │
│  Ex10: Zone heatmap (pickup & dropoff)      │
│  Ex11: Top 10 highest-tip trips on map      │
└─────────────────────────────────────────────┘
```

---

## 💡 Key Spark Concepts Summary

| Concept | Explanation |
|---|---|
| **DataFrame** | Distributed table (like pandas, but across a cluster) |
| **lazy evaluation** | Spark doesn't run until you call `.show()` / `.collect()` |
| **`.collect()`** | Brings all data to driver — use sparingly on large datasets! |
| **`.show()`** | Prints first N rows — safe to call on large datasets |
| **UDF** | Custom function applied row-by-row in distributed fashion |
| **`groupBy().agg()`** | SQL GROUP BY equivalent |
| **`approxQuantile()`** | Computes percentiles efficiently across distributed data |
| **Temp View + SQL** | Register DataFrame as SQL table, then query with SQL strings |
| **`.join()`** | SQL JOIN between two DataFrames |

