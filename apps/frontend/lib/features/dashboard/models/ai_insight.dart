enum InsightLevel { positive, warning, critical }

class AIInsight {
  const AIInsight({
    required this.title,
    required this.message,
    required this.level,
  });

  final String title;
  final String message;
  final InsightLevel level;

  AIInsight copyWith({String? title, String? message, InsightLevel? level}) {
    return AIInsight(
      title: title ?? this.title,
      message: message ?? this.message,
      level: level ?? this.level,
    );
  }
}
