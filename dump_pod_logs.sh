#!/bin/bash

ROOT_OUTPUT_DIR="/tmp"
OUTPUT_DIR_NAME="$(kubectl config current-context)_$(date +%s)"
OUTPUT_DIR="${ROOT_OUTPUT_DIR}/${OUTPUT_DIR_NAME}"
EXTENSION="log"
echo "Using output dir $OUTPUT_DIR"
mkdir "$OUTPUT_DIR"

kubectl get po -A --no-headers | while read -r line; do
    NAMESPACE=$(echo "$line" | awk '{print $1}')
    POD_NAME=$(echo "$line" | awk '{print $2}')
    for CONTAINER in $(kubectl get po -n "$NAMESPACE" "$POD_NAME" -o jsonpath="{.spec.containers[*].name}"); do
        FILENAME_PREFIX="${OUTPUT_DIR}/${NAMESPACE}.${POD_NAME}.${CONTAINER}"
        FILENAME="${FILENAME_PREFIX}.current.${EXTENSION}"
        echo "$FILENAME"
        kubectl logs -n "$NAMESPACE" "$POD_NAME" "$CONTAINER" > "$FILENAME"
        FILENAME="${FILENAME_PREFIX}.previous.${EXTENSION}"
        echo "$FILENAME"
        kubectl logs -p -n "$NAMESPACE" "$POD_NAME" "$CONTAINER" > "$FILENAME" 2> /dev/null
    done
done

CWD=$(pwd)
cd $ROOT_OUTPUT_DIR || exit 1

TARBALL_FILE_NAME="${OUTPUT_DIR_NAME}.tar.gz"
tar -czvf "./${TARBALL_FILE_NAME}" "./${OUTPUT_DIR_NAME}"
mv "./${TARBALL_FILE_NAME}" "$OUTPUT_DIR"

echo "Files located at $OUTPUT_DIR"
echo "Tarball located at ${OUTPUT_DIR}/${TARBALL_FILE_NAME}"

cd "$CWD" || exit 1