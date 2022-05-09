
date=$(date '+%Y-%m-%d')

bq mk \
--table \
--expiration 82800 \
<dataset>.fb \
~/scripts/schema.json

bq load \
--source_format=NEWLINE_DELIMITED_JSON \
<dataset>.fb \
gs://<bucket>/<object folder>/$date.json
