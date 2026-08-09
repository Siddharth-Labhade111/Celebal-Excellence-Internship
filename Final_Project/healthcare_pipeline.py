from pyspark import pipelines as dp
from pyspark.sql import functions as F

# ---------- BRONZE ----------
@dp.table(name="bronze_patients", comment="Raw patient data, ingested as-is")
def bronze_patients():
    df = (
        spark.read.option("header", True)
        .csv("s3://healthcare-raw-data-siddharth/raw/patients/")
    )
    renamed = [c.replace(" ", "_") for c in df.columns]
    df = df.toDF(*renamed)
    return (
        df
        .withColumn("_ingestion_timestamp", F.current_timestamp())
        .withColumn("_source_file", F.lit("patients_records.csv"))
        # Deterministic unique key: hash of every original column together.
        # Two rows only collide if literally every field matches — which
        # is what "duplicate record" should actually mean.
        .withColumn("patient_record_id", F.sha2(F.concat_ws("||", *renamed), 256))
    )

# ---------- SILVER (cleaned, pre-SCD) ----------
@dp.table(name="silver_patients_clean", comment="Cleaned, deduplicated patient data")
@dp.expect_or_drop("valid_age", "Age BETWEEN 0 AND 120")
@dp.expect_or_drop("valid_billing", "Billing_Amount >= 0")
@dp.expect_or_drop("has_name", "Name IS NOT NULL")
@dp.expect_or_drop("has_admission_date", "Date_of_Admission IS NOT NULL")
def silver_patients_clean():
    return (
        dp.read("bronze_patients")
        .dropDuplicates(["Name", "Age", "Gender", "Date_of_Admission", "Hospital", "Doctor"])
        .withColumn("Name", F.initcap(F.trim(F.col("Name"))))
        .withColumn("Hospital", F.initcap(F.trim(F.col("Hospital"))))
        .withColumn("Doctor", F.initcap(F.trim(F.col("Doctor"))))
        .withColumn("Age", F.col("Age").cast("int"))
        .withColumn("Billing_Amount", F.round(F.col("Billing_Amount").cast("double"), 2))
        .withColumn("Date_of_Admission", F.to_date("Date_of_Admission", "yyyy-MM-dd"))
        .withColumn("Discharge_Date", F.to_date("Discharge_Date", "yyyy-MM-dd"))
    )

# ---------- SILVER (SCD Type 2, native — no manual MERGE needed) ----------
dp.create_streaming_table(
    name="silver_patients",
    comment="SCD Type 2 dimension tracking patient admission history"
)

dp.create_auto_cdc_flow(
    target="silver_patients",
    source="silver_patients_clean",
    keys=["patient_record_id"],   # was: ["Name", "Date_of_Admission"]
    sequence_by="_ingestion_timestamp",
    stored_as_scd_type=2
)

# ---------- GOLD ----------
@dp.table(name="gold_condition_contribution")
def gold_condition_contribution():
    return (
        dp.read("silver_patients")
        .filter("__END_AT IS NULL")   # current version only, SCD2's built-in flag
        .groupBy("Medical_Condition")
        .agg(
            F.count("*").alias("patient_count"),
            F.round(F.avg("Billing_Amount"), 2).alias("avg_billing")
        )
    )

@dp.table(name="gold_hospital_ranking")
def gold_hospital_ranking():
    return (
        dp.read("silver_patients")
        .filter("__END_AT IS NULL")
        .groupBy("Hospital")
        .agg(
            F.count("*").alias("patient_count"),
            F.round(F.avg("Billing_Amount"), 2).alias("avg_billing")
        )
        .withColumn("rank_by_volume", F.rank().over(
            __import__("pyspark.sql.window", fromlist=["Window"]).Window.orderBy(F.desc("patient_count"))
        ))
    )