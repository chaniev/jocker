SHELL := /bin/bash

.PHONY: bt train-bot \
	bt-hard-smoke bt-hard-balanced bt-hard-battle \
	bt-normal-smoke bt-normal-balanced bt-normal-battle \
	bt-easy-smoke bt-easy-balanced bt-easy-battle \
	bt-hard-fullgame-smoke bt-hard-fullgame-balanced bt-hard-fullgame-battle bt-hard-final \
	bt-hard-fullgame-balanced-esab bt-hard-fullgame-battle-esab bt-hard-final-esab \
	joker-pack joker-pack-all joker-pack-list joker-pack-dry \
	stage6b-pack stage6b-pack-all stage6b-pack-list stage6b-pack-dry \
	bot-baseline bot-baseline-smoke bot-baseline-list bot-baseline-dry \
	bot-compare bot-compare-smoke bot-compare-list bot-compare-dry

TRAIN_SCRIPT := ./scripts/train_bot_tuning.sh
JOKER_REGRESSION_SCRIPT := ./scripts/run_joker_regression_pack.sh
STAGE6B_RANKING_GUARDRAILS_SCRIPT := ./scripts/run_stage6b_ranking_guardrails.sh
BOT_BASELINE_SCRIPT := ./scripts/run_bot_baseline_snapshot.sh
BOT_AB_COMPARE_SCRIPT := ./scripts/run_bot_ab_comparison_snapshot.sh
SMOKE_ARGS := --population-size 4 --generations 2 --games-per-candidate 4 --rounds-per-game 3 --player-count 4 --cards-min 2 --cards-max 6 --elite-count 1 --mutation-chance 0.30 --mutation-magnitude 0.12 --selection-pool-ratio 0.50 --use-full-match-rules false --rotate-candidate-across-seats false --fitness-underbid-loss-weight 0.0
BALANCED_ARGS := --population-size 12 --generations 12 --games-per-candidate 24 --rounds-per-game 8 --player-count 4 --cards-min 1 --cards-max 9 --elite-count 3 --mutation-chance 0.34 --mutation-magnitude 0.16 --selection-pool-ratio 0.55 --use-full-match-rules false --rotate-candidate-across-seats false --fitness-underbid-loss-weight 0.0
BATTLE_ARGS := --population-size 28 --generations 60 --games-per-candidate 200 --rounds-per-game 16 --player-count 4 --cards-min 1 --cards-max 9 --elite-count 5 --mutation-chance 0.28 --mutation-magnitude 0.10 --selection-pool-ratio 0.45 --use-full-match-rules false --rotate-candidate-across-seats false --fitness-underbid-loss-weight 0.0

FULLGAME_SMOKE_ARGS := --population-size 4 --generations 2 --games-per-candidate 3 --rounds-per-game 24 --player-count 4 --cards-min 1 --cards-max 9 --elite-count 1 --mutation-chance 0.30 --mutation-magnitude 0.16 --selection-pool-ratio 0.50 --use-full-match-rules true --rotate-candidate-across-seats true --fitness-win-rate-weight 1.0 --fitness-score-diff-weight 1.0 --fitness-underbid-loss-weight 0.85 --fitness-trump-density-underbid-weight 0.60 --fitness-notrump-control-underbid-weight 0.70 --score-diff-normalization 450 --underbid-loss-normalization 6000 --trump-density-underbid-normalization 2800 --notrump-control-underbid-normalization 2200
FULLGAME_BALANCED_ARGS := --population-size 10 --generations 10 --games-per-candidate 8 --rounds-per-game 24 --player-count 4 --cards-min 1 --cards-max 9 --elite-count 2 --mutation-chance 0.32 --mutation-magnitude 0.18 --selection-pool-ratio 0.55 --use-full-match-rules true --rotate-candidate-across-seats true --fitness-win-rate-weight 1.0 --fitness-score-diff-weight 1.0 --fitness-underbid-loss-weight 0.85 --fitness-trump-density-underbid-weight 0.60 --fitness-notrump-control-underbid-weight 0.70 --score-diff-normalization 450 --underbid-loss-normalization 6000 --trump-density-underbid-normalization 2800 --notrump-control-underbid-normalization 2200
FULLGAME_BATTLE_ARGS := --population-size 20 --generations 36 --games-per-candidate 16 --rounds-per-game 24 --player-count 4 --cards-min 1 --cards-max 9 --elite-count 4 --mutation-chance 0.28 --mutation-magnitude 0.14 --selection-pool-ratio 0.50 --use-full-match-rules true --rotate-candidate-across-seats true --fitness-win-rate-weight 1.0 --fitness-score-diff-weight 1.0 --fitness-underbid-loss-weight 0.85 --fitness-trump-density-underbid-weight 0.60 --fitness-notrump-control-underbid-weight 0.70 --score-diff-normalization 450 --underbid-loss-normalization 6000 --trump-density-underbid-normalization 2800 --notrump-control-underbid-normalization 2200
FINAL_ENSEMBLE_SEEDS := 20260220,20260221,20260222,20260223,20260224
AB_HOLDOUT_SEEDS := 20260226,20260227,20260228,20260301,20260302,20260303
PROGRESS_ARGS := --show-progress true --progress-candidate-step 5
EARLY_STOP_BALANCED_ARGS := --early-stop-patience 4 --early-stop-min-improvement 0.010 --early-stop-warmup-generations 4
EARLY_STOP_BATTLE_ARGS := --early-stop-patience 8 --early-stop-min-improvement 0.010 --early-stop-warmup-generations 12
AB_VALIDATE_BALANCED_ARGS := --ab-validate true --ab-validation-holdout-seed-list $(AB_HOLDOUT_SEEDS) --ab-validation-games-per-candidate 8
AB_VALIDATE_BATTLE_ARGS := --ab-validate true --ab-validation-holdout-seed-list $(AB_HOLDOUT_SEEDS) --ab-validation-games-per-candidate 12

joker-pack:
	@$(JOKER_REGRESSION_SCRIPT)

joker-pack-all:
	@$(JOKER_REGRESSION_SCRIPT) --include-probes

joker-pack-list:
	@$(JOKER_REGRESSION_SCRIPT) --list

joker-pack-dry:
	@$(JOKER_REGRESSION_SCRIPT) --include-probes --dry-run

stage6b-pack:
	@$(STAGE6B_RANKING_GUARDRAILS_SCRIPT)

stage6b-pack-all:
	@$(STAGE6B_RANKING_GUARDRAILS_SCRIPT) --include-flow-plumbing

stage6b-pack-list:
	@$(STAGE6B_RANKING_GUARDRAILS_SCRIPT) --list

stage6b-pack-dry:
	@$(STAGE6B_RANKING_GUARDRAILS_SCRIPT) --dry-run

bot-baseline:
	@$(BOT_BASELINE_SCRIPT)

bot-baseline-smoke:
	@$(BOT_BASELINE_SCRIPT) --profile smoke

bot-baseline-list:
	@$(BOT_BASELINE_SCRIPT) --list-config

bot-baseline-dry:
	@$(BOT_BASELINE_SCRIPT) --dry-run

bot-compare:
	@$(BOT_AB_COMPARE_SCRIPT)

bot-compare-smoke:
	@$(BOT_AB_COMPARE_SCRIPT) --profile smoke

bot-compare-list:
	@$(BOT_AB_COMPARE_SCRIPT) --list-config

bot-compare-dry:
	@$(BOT_AB_COMPARE_SCRIPT) --dry-run

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

bt-hard-fullgame-smoke:
	@$(TRAIN_SCRIPT) --difficulty hard --seed 20260220 $(FULLGAME_SMOKE_ARGS) $(PROGRESS_ARGS) --output .derivedData/bot-train-hard-fullgame-smoke.log

bt-hard-fullgame-balanced:
	@$(TRAIN_SCRIPT) --difficulty hard --seed 20260220 $(FULLGAME_BALANCED_ARGS) $(PROGRESS_ARGS) --output .derivedData/bot-train-hard-fullgame-balanced.log

bt-hard-fullgame-battle:
	@$(TRAIN_SCRIPT) --difficulty hard --seed 20260220 $(FULLGAME_BATTLE_ARGS) $(PROGRESS_ARGS) --output .derivedData/bot-train-hard-fullgame-battle.log

bt-hard-final:
	@$(TRAIN_SCRIPT) --difficulty hard --seed-list $(FINAL_ENSEMBLE_SEEDS) --ensemble-method median $(FULLGAME_BATTLE_ARGS) $(PROGRESS_ARGS) --output .derivedData/bot-train-hard-final-ensemble.log

bt-hard-fullgame-balanced-esab:
	@$(TRAIN_SCRIPT) --difficulty hard --seed 20260220 $(FULLGAME_BALANCED_ARGS) $(EARLY_STOP_BALANCED_ARGS) $(AB_VALIDATE_BALANCED_ARGS) $(PROGRESS_ARGS) --output .derivedData/bot-train-hard-fullgame-balanced-esab.log

bt-hard-fullgame-battle-esab:
	@$(TRAIN_SCRIPT) --difficulty hard --seed 20260220 $(FULLGAME_BATTLE_ARGS) $(EARLY_STOP_BATTLE_ARGS) $(AB_VALIDATE_BATTLE_ARGS) $(PROGRESS_ARGS) --output .derivedData/bot-train-hard-fullgame-battle-esab.log

bt-hard-final-esab:
	@$(TRAIN_SCRIPT) --difficulty hard --seed-list $(FINAL_ENSEMBLE_SEEDS) --ensemble-method median $(FULLGAME_BATTLE_ARGS) $(EARLY_STOP_BATTLE_ARGS) $(AB_VALIDATE_BATTLE_ARGS) $(PROGRESS_ARGS) --output .derivedData/bot-train-hard-final-ensemble-esab.log
