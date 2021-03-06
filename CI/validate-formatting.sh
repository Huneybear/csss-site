#!/bin/bash

# PURPOSE: used by jenkins to run the code past the linter

set -e -o xtrace

./csss-site/test/lineEndings.sh

echo ENVIRONMENT=${ENVIRONMENT}
echo COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME}

echo POSTGRES_DB_USER=${POSTGRES_DB_USER}
echo POSTGRES_DB_DBNAME=${POSTGRES_DB_DBNAME}
echo WALL_E_DB_USER=${WALL_E_DB_USER}
echo WALL_E_DB_DBNAME=${WALL_E_DB_DBNAME}

echo CONTAINER_HOME_DIR=${CONTAINER_HOME_DIR}
echo CONTAINER_TEST_DIR=${CONTAINER_TEST_DIR}
echo CONTAINER_SRC_DIR=${CONTAINER_SRC_DIR}

echo LOCALHOST_SRC_DIR=${LOCALHOST_SRC_DIR}
echo LOCALHOST_TEST_DIR=${LOCALHOST_TEST_DIR}
echo DOCKER_TEST_IMAGE=${DOCKER_TEST_IMAGE}
echo DOCKER_TEST_CONTAINER=${DOCKER_TEST_CONTAINER}
docker_test_image_lower_case=$(echo "$DOCKER_TEST_IMAGE" | awk '{print tolower($0)}')

docker rm -f ${DOCKER_TEST_CONTAINER} || true
docker image rm -f ${docker_test_image_lower_case} || true

rm -r ${LOCALHOST_TEST_DIR} || true
mkdir -p ${LOCALHOST_TEST_DIR}


echo "UNIT_TEST_RESULTS=${CONTAINER_TEST_DIR}"
echo "TEST_RESULT_FILE_NAME=${TEST_RESULT_FILE_NAME}"

docker build --no-cache -t ${docker_test_image_lower_case} \
    -f CI/Dockerfile.test \
    --build-arg CONTAINER_HOME_DIR=${CONTAINER_HOME_DIR} \
    --build-arg UNIT_TEST_RESULTS=${CONTAINER_TEST_DIR} \
    --build-arg TEST_RESULT_FILE_NAME=${TEST_RESULT_FILE_NAME} .

docker run -d --name ${DOCKER_TEST_CONTAINER} ${docker_test_image_lower_case}
sleep 20
docker cp ${DOCKER_TEST_CONTAINER}:${CONTAINER_TEST_DIR}/${TEST_RESULT_FILE_NAME} ${LOCALHOST_TEST_DIR}/${TEST_RESULT_FILE_NAME}

test_container_failed=$(docker inspect ${DOCKER_TEST_CONTAINER} --format='{{.State.ExitCode}}')
if [ "${test_container_failed}" -eq "1" ]; then
    docker logs ${DOCKER_TEST_CONTAINER}
    docker logs ${DOCKER_TEST_CONTAINER} --tail 12 &> ${DISCORD_NOTIFICATION_MESSAGE_FILE}
    docker stop ${DOCKER_TEST_CONTAINER} || true
    docker rm ${DOCKER_TEST_CONTAINER} || true
    docker image rm -f ${docker_test_image_lower_case} || true
    exit 1
fi

docker stop ${DOCKER_TEST_CONTAINER} || true
docker rm ${DOCKER_TEST_CONTAINER} || true
docker image rm -f ${docker_test_image_lower_case} || true
exit 0
