
date=$(date '+%Y-%m-%d')

bq mk \
--table \
--expiration 82800 \
facebook_data.fb \
~/scripts/schema.json

bq load \
--source_format=NEWLINE_DELIMITED_JSON \
facebook_data.fb \
gs://blended_ingestion/facebook/$date.json