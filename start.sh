/run-php.sh &
/run-nginx.sh &
wait -n
exit $?