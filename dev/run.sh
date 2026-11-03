#!/bin/sh
# Runs notebooks in place inside the image, so the outputs they keep are the ones this
# environment produces: every notebook, or only those named.
set -eu

cd "$(dirname "$0")/.."

if [ "$#" -eq 0 ]; then
    set -- 0*/*.ipynb
fi

for notebook in "$@"; do
    echo "$notebook"
    jupyter nbconvert --log-level=WARN --to notebook --execute --inplace \
        --ExecutePreprocessor.timeout=-1 --ExecutePreprocessor.record_timing=False \
        "$notebook"
done
