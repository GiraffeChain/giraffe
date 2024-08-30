#!/bin/sh

rm -r ./tmp/protobuf || true
rm -r ./lib/src/proto || true

mkdir -p ./tmp/protobuf || true

cd ../..
cp --parents `find -name \*.proto*` dart/sdk/tmp/protobuf
cd dart/sdk

mkdir -p ./lib/src/proto || true

# Compile the "google well-known type" protos
cd ./tmp/protobuf/external_proto
protoc \
    --dart_out=grpc:../../../lib/src/proto \
    $(find ./google -name '*.proto')

cd ../proto
protoc \
    --dart_out=grpc:../../../lib/src/proto \
    -I . \
    -I ../external_proto \
    $(find . -name '*.proto')

cd ../../..

rm -r ./tmp
