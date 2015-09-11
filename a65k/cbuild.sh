#!/bin/sh

while true; do
	(cd src; make) 2>&1 | less
done;

