#/bin/bash

S3_NAME=$1

if [[ $( aws s3 ls | grep $S3_NAME) ]]; then
    echo "S3 bucket already created..."
else
    echo "Creating S3 bucket..."
fi
