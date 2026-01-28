#!/usr/bin/env bash

## bash script to run the ingestion container
echo "Running data ingestion for November 2025..."

docker build -t taxi_ingest:v001 .

docker run -it --rm \
  taxi_ingest:v001 \
  --year=2025 \
  --month=11 \
  --pg-user=root \
  --pg-pass=root \
  --pg-host=pgdatabase \
  --pg-port=5432 \
  --pg-db=ny_taxi \
  --chunksize=100000 \
  --target-table=yellow_taxi_trips