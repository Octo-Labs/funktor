#!/usr/bin/env bash

cp -r ../lib ./funktor

serverless deploy --stage dev -v
