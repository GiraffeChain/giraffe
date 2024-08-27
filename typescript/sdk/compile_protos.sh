#!/bin/sh

rm -r ./tmp/protobuf || true
rm -r ./lib/proto || true

mkdir -p ./tmp/protobuf || true

cd ../..
cp --parents `find -name \*.proto*` typescript/sdk/tmp/protobuf
cd typescript/sdk

mkdir -p ./lib/proto || true

# Compile the "google well-known type" protos
cd ./tmp/protobuf/external_proto
protoc \
    --plugin=../../../node_modules/.bin/protoc-gen-ts_proto \
    --ts_proto_out=../../../lib/proto \
    --ts_proto_opt=forceLong=long \
    --ts_proto_opt=esModuleInterop=true \
    $(find ./google -name '*.proto')

cd ../proto
protoc \
    --plugin=../../../node_modules/.bin/protoc-gen-ts_proto \
    --ts_proto_out=../../../lib/proto \
    --ts_proto_opt=forceLong=long \
    --ts_proto_opt=esModuleInterop=true \
    -I . \
    -I ../external_proto \
    $(find . -name '*.proto')

cd ../../..

rm -r ./tmp
