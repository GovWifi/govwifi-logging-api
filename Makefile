.DEFAULT_GOAL := help

DOCKER_COMPOSE = docker compose -f docker-compose.yml
BUNDLE_FLAGS=

ifdef DEPLOYMENT
	BUNDLE_FLAGS = --build-arg BUNDLE_INSTALL_CMD='bundle install --without test, vscodedev'
endif

DOCKER_BUILD_CMD = $(DOCKER_COMPOSE) build $(BUNDLE_FLAGS)

.PHONY: help build serve lint test stop shell update

help:
	@echo "Available targets:"
	@echo ""
	@echo "  build              Build the Docker image"
	@echo "  serve              Build and start the API server (detached)"
	@echo "  lint               Run the linter (rubocop)"
	@echo "  test               Build, create test data, and run the test suite"
	@echo "  shell              Build, start services, and open a shell in the app"
	@echo "  update             Update the lockfile and run the test suite"
	@echo "  stop               Stop and remove all containers and volumes"
	@echo "  help               Show this help message"
	@echo ""
	@echo "Environment:"
	@echo "  DEPLOYMENT=1       Build without the test/vscodedev gems (deployment image)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Examples:"
	@echo "  make test          Run tests"
	@echo "  make lint          Run linters"
	@echo "  make serve         Start the development server"
	@echo "  make stop          Stop all containers"
	@echo ""

build:
	$(DOCKER_BUILD_CMD)

serve: build
	$(DOCKER_COMPOSE) up -d app

lint: build
	$(DOCKER_COMPOSE) run --no-deps --rm app bundle exec rubocop

test: build
	$(DOCKER_COMPOSE) run --rm app /usr/src/app/create_user_details.sh
	$(DOCKER_COMPOSE) run --rm app rspec
	$(MAKE) stop

shell: serve
	$(DOCKER_COMPOSE) exec app bash

update: stop
	bundle lock --update
	$(MAKE) test

stop:
	$(DOCKER_COMPOSE) down -v
	$(DOCKER_COMPOSE) rm -fsv
