#!/bin/bash

unset GIT_DIR
cd /srv/checkout/tradenomiitti

git fetch origin
git reset --hard origin/master
