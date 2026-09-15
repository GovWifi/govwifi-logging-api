DOCKER_COMPOSE = docker compose -f docker-compose.yml
ifdef DEPLOYMENT
	BUNDLE_FLAGS = --build-arg BUNDLE_WITHOUT='development test'
endif

DOCKER_BUILD_CMD = $(DOCKER_COMPOSE) build $(BUNDLE_FLAGS)

.DEFAULT_GOAL := help

.PHONY: help build serve lint test stop shell

help:
	@echo "Available targets:"
	@echo ""
	@echo "  stop               Stop and remove all containers and volumes"
	@echo "  build              Build the Docker image"
	@echo "  serve              Build and start the API server (detached)"
	@echo "  shell              Build, start services, and open a shell in the app"
	@echo "  test               Build, create test data, and run the test suite"
	@echo "  lint               Run the linter (rubocop)"
	@echo "  help               Show this help message"
	@echo ""
	@echo "Environment:"
	@echo "  DEPLOYMENT=1       Build without the test and development gems (deployment image)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Examples:"
	@echo "  make test          Run tests"
	@echo "  make lint          Run linters"
	@echo "  make serve         Start the development server"
	@echo "  make stop          Stop all containers"
	@echo ""

stop:
	$(DOCKER_COMPOSE) down -v

build:
	$(DOCKER_BUILD_CMD)

serve: build
	$(DOCKER_COMPOSE) up -d app

shell: serve
	$(DOCKER_COMPOSE) exec app ash

test: build
	$(DOCKER_COMPOSE) run --rm app /usr/src/app/create_user_details.sh
	$(DOCKER_COMPOSE) run --rm app bundle exec rspec --format documentation
	$(MAKE) stop

lint: build
	$(DOCKER_COMPOSE) run --no-deps --rm --entrypoint "" app bundle exec rubocop
