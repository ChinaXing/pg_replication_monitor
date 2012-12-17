#!/bin/env bash

./send_wangwang.pl -u "$(echo '云惺' | iconv -f utf8 -t gb2312)" -s "[PESYSTEM DB Monitor]" -m "$*"
