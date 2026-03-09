//
//  TrainingRunResultFormatter.swift
//  Jocker
//
//  Pure helper for progress and summary string building. Order and format are
//  deterministic and testable without running the CLI.
//

import Foundation

enum TrainingProgressStage {
    case started
    case baselineCompleted
    case generationStarted
    case candidateEvaluated
    case generationCompleted
    case finished
}

struct TrainingProgressSnapshot {
    let stage: TrainingProgressStage
    let generationIndex: Int?
    let totalGenerations: Int
    let evaluatedCandidatesInGeneration: Int?
    let populationSize: Int
    let currentFitness: Double?
    let generationBestFitness: Double?
    let overallBestFitness: Double?
    let totalWorkUnits: Int
    let elapsedSeconds: Double
    let estimatedRemainingSeconds: Double?
}

struct TrainingRunResultSummarySnapshot {
    let baselineFitness: Double
    let bestFitness: Double
    let baselineLegacyFitness: Double
    let bestLegacyFitness: Double
    let baselinePrimaryFitness: Double
    let bestPrimaryFitness: Double
    let baselineGuardrailPenalty: Double
    let bestGuardrailPenalty: Double
    let baselineFinalFitness: Double
    let bestFinalFitness: Double
    let improvement: Double
    let completedGenerations: Int
    let stoppedEarly: Bool
    let generationBestFitness: [Double]
}

enum TrainingRunResultFormatter {
    // MARK: - Progress

    /// Builds a single progress line for the given event, or nil if the event should be skipped (e.g. candidate step filtering).
    /// Same logic as CLI progress output; deterministic for same (seed, event, candidateStep).
    static func formatProgressLine(
        seed: UInt64,
        event: TrainingProgressSnapshot,
        candidateStep: Int
    ) -> String? {
        switch event.stage {
        case .started:
            return "[progress] seed=\(seed) started work=\(event.totalWorkUnits) units"
        case .baselineCompleted:
            return "[progress] seed=\(seed) baseline fitness=\(fmt(event.currentFitness ?? 0.0)) elapsed=\(fmtDuration(event.elapsedSeconds)) eta=\(fmtDuration(event.estimatedRemainingSeconds))"
        case .generationStarted:
            let generation = (event.generationIndex ?? 0) + 1
            return "[progress] seed=\(seed) generation \(generation)/\(event.totalGenerations) started"
        case .candidateEvaluated:
            let generation = (event.generationIndex ?? 0) + 1
            let candidate = event.evaluatedCandidatesInGeneration ?? 0
            let shouldPrint = candidate == 1 ||
                candidate == event.populationSize ||
                (candidate % candidateStep == 0)
            guard shouldPrint else { return nil }
            return "[progress] seed=\(seed) g=\(generation)/\(event.totalGenerations) candidate=\(candidate)/\(event.populationSize) fitness=\(fmt(event.currentFitness ?? 0.0)) genBest=\(fmt(event.generationBestFitness ?? 0.0)) overallBest=\(fmt(event.overallBestFitness ?? 0.0)) elapsed=\(fmtDuration(event.elapsedSeconds)) eta=\(fmtDuration(event.estimatedRemainingSeconds))"
        case .generationCompleted:
            let generation = (event.generationIndex ?? 0) + 1
            return "[progress] seed=\(seed) generation \(generation)/\(event.totalGenerations) done genBest=\(fmt(event.generationBestFitness ?? 0.0)) overallBest=\(fmt(event.overallBestFitness ?? 0.0)) elapsed=\(fmtDuration(event.elapsedSeconds)) eta=\(fmtDuration(event.estimatedRemainingSeconds))"
        case .finished:
            return "[progress] seed=\(seed) finished overallBest=\(fmt(event.overallBestFitness ?? 0.0)) elapsed=\(fmtDuration(event.elapsedSeconds))"
        }
    }

    // MARK: - Run result summary (deterministic subset for testing)

    /// Summary lines that depend only on the selected run result and config.
    /// Order is fixed: selectedSeed, baseline/best metrics, then generationBestFitness by generation index.
    /// Same run result produces identical output regardless of sequential vs parallel mode (only maxParallelEvaluations differs elsewhere).
    static func formatRunResultSummaryLines(
        selectedSeed: UInt64,
        result: TrainingRunResultSummarySnapshot,
        _ fmtNumber: @escaping (Double) -> String = { String(format: "%.6f", $0) }
    ) -> [String] {
        let f = fmtNumber
        return [
            "selectedSeed=\(selectedSeed)",
            "baselineFitness=\(f(result.baselineFitness))",
            "bestFitness=\(f(result.bestFitness))",
            "baselineLegacyFitness=\(f(result.baselineLegacyFitness))",
            "bestLegacyFitness=\(f(result.bestLegacyFitness))",
            "baselinePrimaryFitness=\(f(result.baselinePrimaryFitness))",
            "bestPrimaryFitness=\(f(result.bestPrimaryFitness))",
            "baselineGuardrailPenalty=\(f(result.baselineGuardrailPenalty))",
            "bestGuardrailPenalty=\(f(result.bestGuardrailPenalty))",
            "baselineFinalFitness=\(f(result.baselineFinalFitness))",
            "bestFinalFitness=\(f(result.bestFinalFitness))",
            "improvement=\(f(result.improvement))",
            "generationCount=\(result.completedGenerations)",
            "completedGenerations=\(result.completedGenerations)",
            "stoppedEarly=\(result.stoppedEarly)",
            "generationBestFitness=[\(result.generationBestFitness.map(f).joined(separator: ", "))]"
        ]
    }

    // MARK: - Helpers

    private static func fmt(_ value: Double) -> String {
        String(format: "%.6f", value)
    }

    private static func fmtDuration(_ seconds: Double?) -> String {
        guard let seconds else { return "--:--:--" }
        let clamped = max(0, Int(seconds.rounded()))
        let hours = clamped / 3600
        let minutes = (clamped % 3600) / 60
        let secs = clamped % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}
