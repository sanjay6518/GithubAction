#!/bin/sh

echo "Building test environment from .env.test.template"

eval "echo \"$(cat .env.test.template)\"" > .env
