#!/usr/bin/env bash

echo "starting nginx in daemon mode"
/usr/local/nginx/sbin/nginx -c /opt/nginx_test/etc/nginx/nginx.conf

cd /opt/nginx_test/var/log/

echo "GET http://localhost:8080/index.html?xyz=testnaxsitest"
curl http://localhost:8080/index.html?xyz=testnaxsitest

echo "GET http://localhost:8080/index.html?abc=--&def=--"
curl http://localhost:8080/index.html?abc=--&def=--

echo "The requests should have triggered HTTP code 418 responses and NAXSI messages in the error log (/opt/nginx_test/var/log/error.log)"

bash