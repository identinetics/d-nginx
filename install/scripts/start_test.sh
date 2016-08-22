#!/usr/bin/env bash

echo "starting nginx in daemon mode"
/usr/local/nginx/sbin/nginx -c /opt/nginx_test/etc/nginx/nginx.conf

cd /opt/nginx_test/var/log/

echo "HEAD http://localhost:8080/index.html?xyz=testnaxsitest"
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/index.html?xyz=testnaxsitest

echo "GET http://localhost:8080/index.html?abc=--&def=--"
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/index.html?abc=--&def=--

sleep 1
echo "The requests should have triggered HTTP code 418 responses and NAXSI messages in the error log (/opt/nginx_test/var/log/error.log)"
ls -l
bash