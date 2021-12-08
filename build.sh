#!/bin/bash

REPL_USER=replicator
REPL_PWD=secret

section() {
    echo "----------------------------$@----------------------------"
}
sectionEnd() {
    echo "------------------------------------------------------------"
}

create-repl-user() {
    section "Create repl user $@"
    # Create repl user statement
    CREATE_REPL_STMT='GRANT REPLICATION SLAVE ON *.* TO "'$REPL_USER'"@"%" IDENTIFIED BY "'$REPL_PWD'"; FLUSH PRIVILEGES;'

    echo "$@" "export MYSQL_PWD=111; mysql -u root -e '$CREATE_REPL_STMT'"

    # Create replication user on legacy
    docker exec "$@" sh -c "export MYSQL_PWD=111; mysql -u root -e '$CREATE_REPL_STMT'"
    sectionEnd
}

docker-ip() {
    docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$@"
}

show-master-status() {
    section "SHOW MASTER STATUS"
    MS_STATUS=`docker exec "$@" sh -c 'export MYSQL_PWD=111; mysql -u root -e "SHOW MASTER STATUS"'`
    CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`
    CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`
    echo $CURRENT_LOG $CURRENT_POS
    sectionEnd
}

setup-master() {
    section "SETUP $1"
    start_slave_stmt="STOP SLAVE; CHANGE MASTER TO MASTER_HOST='$(docker-ip $2)',MASTER_USER='$REPL_USER',MASTER_PASSWORD='$REPL_PWD',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
    start_slave_cmd='export MYSQL_PWD=111; mysql -u root -e "'
    start_slave_cmd+="$start_slave_stmt"
    start_slave_cmd+='"'
    echo "$start_slave_cmd"
    docker exec "$1" sh -c "$start_slave_cmd"
    docker exec "$1" sh -c "export MYSQL_PWD=111; mysql -u root -e 'SHOW SLAVE STATUS \G'"
    sectionEnd
}

init-service() {
    section $@
    until docker exec "$@" sh -c 'export MYSQL_PWD=111; mysql -u root -e ";"'
    do
        echo "Waiting for "$@" database connection..."
        sleep 10
    done
    sectionEnd
}

reset() {
    docker-compose down
    rm -rf ./legacy/data/*
    rm -rf ./cloud/data/*
    docker-compose build
    docker-compose up -d
}

main() {
    reset
    init-service $1
    create-repl-user $1
    init-service $2
    create-repl-user $2
    show-master-status $1
    setup-master $2 $1
    show-master-status $2
    setup-master $1 $2
}

main "$@"