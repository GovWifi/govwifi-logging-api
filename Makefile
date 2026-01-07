BUNDLE_FLAGS = --build-arg BUNDLE_INSTALL_CMD='bundle install --jobs 1 --retry 5'
DOCKER_COMPOSE = docker compose -f docker-compose.yml

ifdef DEPLOYMENT
	BUNDLE_FLAGS = --build-arg BUNDLE_INSTALL_CMD='bundle install --without test, vscodedev'
endif

DOCKER_BUILD_CMD = $(DOCKER_COMPOSE) build $(BUNDLE_FLAGS)

build: stop
	$(DOCKER_BUILD_CMD)

prebuild:
	$(DOCKER_BUILD_CMD)
	$(DOCKER_COMPOSE) up --no-start

serve: build
	$(DOCKER_COMPOSE) up -d app

lint: build
	$(DOCKER_COMPOSE) run --no-deps --rm app bundle exec rubocop

lint-local:
	bundle exec rubocop

test: serve
	$(DOCKER_COMPOSE) run --rm app /usr/src/app/create_user_details.sh
	$(DOCKER_COMPOSE) run --rm app rspec
	$(MAKE) stop

stop:
	$(DOCKER_COMPOSE) down
	$(DOCKER_COMPOSE) kill
	$(DOCKER_COMPOSE) rm -f

shell: serve
	docker exec -it `docker-compose ps -q app | awk 'END{print}'` ash

update: stop
	bundle lock --update
	$(MAKE) test

.PHONY: build test serve stop lint shell
