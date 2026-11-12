import 'package:hybstockadvisor/theme/format.dart';

/// The `signal` object from `/api/forecast` and `/api/insights`.
///
/// A signal is only shown when the backend marks it available and the data is
/// not stale. The base rate (the share of 10-session windows in the training
/// period that ended positive) is read from `prior_probability_positive` if the
/// backend sends it, otherwise from the evidence line the model writes.
class ResearchSignal {
  final bool available;

  /// 'published', 'not_validated' or 'stale_data'.
  final String status;

  /// 'positive' or 'negative' when available.
  final String? direction;
  final int horizon;
  final int horizonMin;
  final int horizonMax;
  final double? probability;
  final double? baseRate;
  final DateTime? asOf;
  final List<String> evidence;
  final SignalValidation? validation;

  const ResearchSignal({
    required this.available,
    required this.status,
    this.direction,
    this.horizon = 10,
    this.horizonMin = 5,
    this.horizonMax = 20,
    this.probability,
    this.baseRate,
    this.asOf,
    this.evidence = const [],
    this.validation,
  });

  static const unavailable = ResearchSignal(available: false, status: 'not_validated');

  bool get isPositive => direction == 'positive';

  /// Probability minus base rate, when both are known.
  double? get edge =>
      probability != null && baseRate != null ? probability! - baseRate! : null;

  factory ResearchSignal.fromJson(Object? raw, {bool dataStale = false}) {
    if (raw is! Map) return unavailable;
    final horizon = raw['horizon'] is Map ? raw['horizon'] as Map : const {};
    final evidence = raw['evidence'] is List
        ? (raw['evidence'] as List).map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : <String>[];
    final p = raw['probability_positive'];
    final prior = raw['prior_probability_positive'];
    return ResearchSignal(
      available: raw['available'] == true && !dataStale,
      status: dataStale ? 'stale_data' : (raw['status']?.toString() ?? 'not_validated'),
      direction: raw['direction']?.toString(),
      horizon: (horizon['primary'] as num?)?.toInt() ?? 10,
      horizonMin: (horizon['min'] as num?)?.toInt() ?? 5,
      horizonMax: (horizon['max'] as num?)?.toInt() ?? 20,
      probability: p is num ? p.toDouble() : null,
      baseRate: prior is num ? prior.toDouble() : _baseRateFrom(evidence),
      asOf: Fmt.parse(raw['as_of']),
      evidence: evidence,
      validation: SignalValidation.fromJson(raw['validation']),
    );
  }

  static double? _baseRateFrom(List<String> evidence) {
    final re = RegExp(r'prior positive-return rate:\s*([0-9]*\.?[0-9]+)', caseSensitive: false);
    for (final line in evidence) {
      final m = re.firstMatch(line);
      if (m != null) return double.tryParse(m.group(1)!);
    }
    return null;
  }
}

/// Review and track record for the model behind a published signal.
class SignalValidation {
  final String? modelVersion;
  final String? reviewer;
  final DateTime? reviewedAt;
  final int? paperSamples;
  final double? paperHitRate;
  final double? paperBrier;
  final double? paperBaselineBrier;
  final double? paperMeanReturnPct;
  final double? backtestBrier;
  final double? backtestBaselineBrier;
  final double? backtestExcessPct;

  const SignalValidation({
    this.modelVersion,
    this.reviewer,
    this.reviewedAt,
    this.paperSamples,
    this.paperHitRate,
    this.paperBrier,
    this.paperBaselineBrier,
    this.paperMeanReturnPct,
    this.backtestBrier,
    this.backtestBaselineBrier,
    this.backtestExcessPct,
  });

  static SignalValidation? fromJson(Object? raw) {
    if (raw is! Map) return null;
    double? d(String k) => (raw[k] as num?)?.toDouble();
    return SignalValidation(
      modelVersion: raw['model_version']?.toString(),
      reviewer: raw['reviewer']?.toString(),
      reviewedAt: Fmt.parse(raw['reviewed_at']),
      paperSamples: (raw['paper_samples'] as num?)?.toInt(),
      paperHitRate: d('paper_hit_rate'),
      paperBrier: d('paper_brier_score'),
      paperBaselineBrier: d('paper_prior_baseline_brier_score'),
      paperMeanReturnPct: d('paper_mean_net_directional_return_pct'),
      backtestBrier: d('backtest_brier_score'),
      backtestBaselineBrier: d('backtest_prior_baseline_brier_score'),
      backtestExcessPct: d('backtest_mean_net_excess_vs_matched_benchmark_pct'),
    );
  }
}
