SHELL := /bin/bash

.PHONY: bt train-bot \
	bt-hard-smoke bt-hard-balanced bt-hard-battle \
	bt-normal-smoke bt-normal-balanced bt-normal-battle \
	bt-easy-smoke bt-easy-balanced bt-easy-battle

TRAIN_SCRIPT := ./scripts/train_bot_tuning.sh
SMOKE_ARGS := --population-size 4 --generations 2 --games-per-candidate 4 --rounds-per-game 3 --player-count 4 --cards-min 2 --cards-max 6 --elite-count 1 --mutation-chance 0.30 --mutation-magnitude 0.12 --selection-pool-ratio 0.50
BALANCED_ARGS := --population-size 12 --generations 12 --games-per-candidate 24 --rounds-per-game 8 --player-count 4 --cards-min 2 --cards-max 9 --elite-count 3 --mutation-chance 0.34 --mutation-magnitude 0.16 --selection-pool-ratio 0.55
BATTLE_ARGS := --population-size 28 --generations 40 --games-per-candidate 100 --rounds-per-game 12 --player-count 4 --cards-min 2 --cards-max 9 --elite-count 5 --mutation-chance 0.28 --mutation-magnitude 0.10 --selection-pool-ratio 0.45

bt train-bot:
	@$(TRAIN_SCRIPT) $(ARGS)

bt-hard-smoke:
	@$(TRAIN_SCRIPT) --difficulty hard --seed 20260220 $(SMOKE_ARGS) --output .derivedData/bot-train-hard-smoke.log

bt-hard-balanced:
	@$(TRAIN_SCRIPT) --difficulty hard --seed 20260220 $(BALANCED_ARGS) --output .derivedData/bot-train-hard-balanced.log

bt-hard-battle:
	@$(TRAIN_SCRIPT) --difficulty hard --seed 20260220 $(BATTLE_ARGS) --output .derivedData/bot-train-hard-battle.log

bt-normal-smoke:
	@$(TRAIN_SCRIPT) --difficulty normal --seed 20260221 $(SMOKE_ARGS) --output .derivedData/bot-train-normal-smoke.log

bt-normal-balanced:
	@$(TRAIN_SCRIPT) --difficulty normal --seed 20260221 $(BALANCED_ARGS) --output .derivedData/bot-train-normal-balanced.log

bt-normal-battle:
	@$(TRAIN_SCRIPT) --difficulty normal --seed 20260221 $(BATTLE_ARGS) --output .derivedData/bot-train-normal-battle.log

bt-easy-smoke:
	@$(TRAIN_SCRIPT) --difficulty easy --seed 20260222 $(SMOKE_ARGS) --output .derivedData/bot-train-easy-smoke.log

bt-easy-balanced:
	@$(TRAIN_SCRIPT) --difficulty easy --seed 20260222 $(BALANCED_ARGS) --output .derivedData/bot-train-easy-balanced.log

bt-easy-battle:
	@$(TRAIN_SCRIPT) --difficulty easy --seed 20260222 $(BATTLE_ARGS) --output .derivedData/bot-train-easy-battle.log
