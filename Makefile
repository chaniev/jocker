SHELL := /bin/bash

.PHONY: bt train-bot

bt train-bot:
	@./scripts/train_bot_tuning.sh $(ARGS)
