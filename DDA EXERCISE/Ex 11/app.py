from pyspark.sql import SparkSession

import os
import sys
import time
from operator import add
from random import random
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def is_point_inside_unit_circle(p):
    x, y = random(), random()
    return 1 if x*x + y*y < 1 else 0

def functionToMeasure(sc, total_darts=10**8):
    #########################################################
    # Task
    #########################################################
    darts = sc.parallelize(range(0, total_darts))
    
    t0 = time.time()
    count = darts.map(is_point_inside_unit_circle)
    mapTime = time.time() - t0
    
    t1 = time.time()
    darts_inside = count.reduce(add) 
    reduceTime = time.time() - t1

    pi_val=darts_inside*4/total_darts
    return mapTime, reduceTime, pi_val

output_dir=sys.argv[1]    

if len(sys.argv) == 3:
    total_darts=sys.argv[2]
else:
    total_darts = 10**9

#########################################################
# Task
#########################################################
# ??? initialize spark conf with only app name and submit it to spark context
spark = SparkSession.builder.appName("MonteCarloPi_HPC").getOrCreate()
sc = spark.sparkContext

sc.setLogLevel("INFO")

logger.info(f"Successfully created SparkContext with app name: {sc.appName}")

mapTime, reduceTime, pi_val = functionToMeasure(sc,total_darts)

# Save results to a file
with open(f"{output_dir}/results.txt", "a") as file:
    file.write(f"{os.environ['SLURM_NNODES']},{reduceTime},{sc.defaultParallelism},{pi_val}\n")

#########################################################
# Task
#########################################################
sc.stop()
spark.stop()


