#!/bin/bash

udp=(
4789
8053
)

tcp=(
10250
10256
15672
15673
179
1936
2049
2181
2182
2379
2380
25672
25673
25684:25694
2888:3888
3000
3002
3333
3514
4369
443
4739
4789
4888:5888
514
5269
53
5672
5673
5920
5921
5995
6343
6379
6389
7000
7001
7010
7011
7012
7013
7014
7200
7201
7204
80
80
8053
8080
8081
8082
8083
8084
8085
8086
8087
8088
8089
8090
8091
8092
8093
8094
8096
8097
8100
8101
8102
8103
8104
8108
8112
8113
8114
8143
8180
8181
8443
8444
9000:10000
9041
9042
9044
9053
9090
9091
9092
9160
9161
9164
)

function accept(){
  local proto=$1
  local p
  local table=$proto[@]
  for p in ${!table}; do
    echo "INFO: add udp $p into itables"
    iptables -t filter -I INPUT 1 -w 5 -W 100000 -p $proto --dport $p -j ACCEPT
  done
}

accept tcp
accept udp
