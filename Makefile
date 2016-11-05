GIT_COMMIT ?= $(shell git rev-parse --verify HEAD)
SAIYAN_CONTAINERS = $(shell docker ps -aqf name=_saiyan_)
SAIYAN_NETWORKS = $(shell docker network ls -qf name=saiyan_)

##################################
# Container running
##################################

up:
	docker-compose up -d

down:
	docker-compose down -v

run:
	docker-compose run --rm saiyan /bin/bash

logs:
	docker logs -tf ${SAIYAN_CONTAINERS}

ssh:
	docker exec -it ${SAIYAN_CONTAINERS} /bin/bash

build:
	docker build \
		--build-arg GIT_COMMIT=${GIT_COMMIT} \
		-t saiyan:latest \
		-t saiyan:${GIT_COMMIT} \
		.

##################################
# Container maintenance
##################################

clean: stop-containers rm-containers rm-networks rm-volumes rm-images

stop-containers:
ifeq ($(shell uname -s),Linux)
	echo $(SAIYAN_CONTAINERS) | xargs -r docker stop
else
	echo $(SAIYAN_CONTAINERS) | xargs docker stop
endif

rm-containers:
ifeq ($(shell uname -s),Linux)
	echo $(SAIYAN_CONTAINERS) | xargs -r docker rm
else
	echo $(SAIYAN_CONTAINERS) | xargs docker rm
endif

rm-networks:
ifeq ($(shell uname -s),Linux)
	echo $(SAIYAN_NETWORKS) | xargs -r docker network rm
else
	echo $(SAIYAN_NETWORKS) | xargs docker network rm
endif

rm-images:
ifeq ($(shell uname -s),Linux)
	docker images --quiet --filter "dangling=true" | xargs -r docker rmi
else
	docker images --quiet --filter "dangling=true" | xargs docker rmi
endif

rm-volumes:
ifeq ($(shell uname -s),Linux)
	docker volume ls -q | egrep '^\w{64}$$' | xargs -r docker volume rm
else
	docker volume ls -q | egrep '^\w{64}$$' | xargs docker volume rm
endif
