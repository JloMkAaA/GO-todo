include .env
export


export PROJECT_ROOT=${shell pwd}

env-up:
	@docker compose up -d TODO-postgres

env-down:
	@docker compose down TODO-postgres

env-cleanup:
	@read -p "Очистить все volume файлы окружения? [y/N ]: " ans; \
	if [ "$$ans" = "y" ]; then \
		docker compose down TODO-postgres && \
		sudo chown -R $$USER:$$USER out/pgdata; \
		rm -rf out/pgdata $$ \
		echo "Файлы окружения очищены"; \
	else \
		echo "Очистка отменена"; \
	fi

migrate-create:
	@if [ -z  "$(seq)" ]; then \
		echo "Отсутствует seq make migrate-create seq=init"; \
		exit 1; \
	fi; \
	docker-compose run --rm postgres-migrate \
		create \
		-ext sql \
		-dir /migrations \
		-seq "$(seq)"; \

	sudo chown -R $$USER:$$USER migrations;

migrate-up:
	@make migrate-action action=up

migrate-down:
	@make migrate-action action=down

migrate-action:
	@if [ -z  "$(action)" ]; then \
		echo "Отсутствует action. Пример make migrate-action action=up"; \
		exit 1; \
	fi; \
	docker-compose run --rm postgres-migrate \
		-path /migrations \
		-database postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@TODO-env-postgres:5432/${POSTGRES_DB}?sslmode=disable \
		"$(action)"

todoapp-run:
	@export LOGGER_FOLDER=${PROJECT_ROOT}/out/logs && \
	export POSTGRES_HOST=localhost && \
	go mod tidy && \
	go run cmd/todoapp/main.go