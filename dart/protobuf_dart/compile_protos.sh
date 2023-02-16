#!/bin/sh

rm -r ./tmp/protobuf || true
rm -r ./lib || true

mkdir -p ./tmp/protobuf || true

cd ../..
cp --parents `find -name \*.proto*` dart/protobuf_dart/tmp/protobuf
cd dart/protobuf_dart

mkdir -p ./lib || true
cd ./tmp/protobuf/proto

protoc \
    --dart_out=grpc:../../../lib \
    -I . \
    -I ../external_proto \
    $(find . -name '*.proto')

cd ../../..

rm -r ./tmp
