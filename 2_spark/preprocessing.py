#!/usr/bin/env python3
"""
Data Preprocessing Example using PySpark
This script demonstrates data loading, cleaning, and transformation
"""

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, when, lit, count, avg, sum as spark_sum
import sys

def main():
    # Create Spark session
    spark = SparkSession.builder \
        .appName("DataPreprocessing") \
        .getOrCreate()
    
    print("=" * 60)
    print("Starting Data Preprocessing Job")
    print("=" * 60)
    
    # Storage paths - configured for the system
    nvme_path = "/mnt/nvme"
    hdd_path = "/mnt/hdd"
    gcs_path = "/mnt/gcs"
    
    # Example: Create sample data
    print("\nCreating sample data...")
    data = [
        (1, "Alice", 28, "Engineering", 75000),
        (2, "Bob", 35, "Sales", 65000),
        (3, "Charlie", None, "Engineering", 80000),
        (4, "David", 42, "Marketing", None),
        (5, "Eve", 31, "Engineering", 90000),
        (6, "Frank", 29, "Sales", 60000),
    ]
    
    columns = ["id", "name", "age", "department", "salary"]
    df = spark.createDataFrame(data, columns)
    
    print("\nOriginal Data:")
    df.show()
    
    # Data cleaning
    print("\nCleaning data...")
    df_cleaned = df.fillna({
        "age": 30,  # Fill missing age with default
        "salary": 70000  # Fill missing salary with default
    })
    
    print("\nCleaned Data:")
    df_cleaned.show()
    
    # Data transformation
    print("\nTransforming data...")
    df_transformed = df_cleaned.withColumn(
        "salary_category",
        when(col("salary") >= 80000, "High")
        .when(col("salary") >= 65000, "Medium")
        .otherwise("Low")
    )
    
    print("\nTransformed Data:")
    df_transformed.show()
    
    # Aggregation
    print("\nAggregating by department...")
    df_agg = df_transformed.groupBy("department").agg(
        count("*").alias("employee_count"),
        avg("salary").alias("avg_salary"),
        avg("age").alias("avg_age")
    )
    
    print("\nAggregation Results:")
    df_agg.show()
    
    # Save results to different storage locations
    print("\nSaving results...")
    
    # Save to NVME (fast storage for hot data)
    output_nvme = f"{nvme_path}/spark-output/preprocessed_data"
    print(f"Saving to NVME: {output_nvme}")
    df_transformed.write.mode("overwrite").parquet(output_nvme)
    
    # Save aggregated data to HDD (cold storage)
    output_hdd = f"{hdd_path}/spark-output/aggregated_data"
    print(f"Saving to HDD: {output_hdd}")
    df_agg.write.mode("overwrite").parquet(output_hdd)
    
    # Save summary to GCS (archive storage)
    output_gcs = f"{gcs_path}/spark-output/summary"
    print(f"Saving to GCS: {output_gcs}")
    df_agg.write.mode("overwrite").json(output_gcs)
    
    print("\n" + "=" * 60)
    print("Data Preprocessing Job Completed Successfully")
    print("=" * 60)
    
    spark.stop()

if __name__ == "__main__":
    main()
