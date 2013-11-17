#!/bin/sh
#
# 1st parameter is xslt file
# 2nd parameter is xml to process
# 3rd parameter is result file

# if -in is not used, stdin is used
xsl-c -xsl "$1" -html -in "$2" -out "$3"


