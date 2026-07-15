import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/event_model.dart';
import '../services/event_recommendation_service.dart';
import '../services/student_service.dart';
import '../domain/entities/Student.dart';

class RecommendedEventsScreen extends StatefulWidget {
  final int userId;

  const RecommendedEventsScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  State<RecommendedEventsScreen> createState() =>
      _RecommendedEventsScreenState();
}

class _RecommendedEventsScreenState extends State<RecommendedEventsScreen> {
  final _recommendService = EventRecommendationService();
  final _studentService = StudentService();

  List<RecommendedEvent> _recommendations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final studentRow = await _studentService.supabase
          .from('student')
          .select()
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (studentRow == null) {
        setState(() {
          _error = 'Không tìm thấy thông tin sinh viên.';
          _isLoading = false;
        });
        return;
      }

      final student = Student.fromJson(studentRow);
      final recommendations = await _recommendService.getRecommendations(
        studentId: student.studentId,
        userId: widget.userId,
        limit: 20,
      );

      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải gợi ý: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('✨ Gợi ý cho bạn'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendations,
            tooltip: 'Làm mới gợi ý',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecommendations,
        child: _buildBody(theme, colorScheme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadRecommendations,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy,
                  size: 80,
                  color: colorScheme.onSurface.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'Chưa có gợi ý nào',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hãy đăng ký và đánh giá một số sự kiện để nhận gợi ý phù hợp hơn!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final rec = _recommendations[index];
        return _RecommendationCard(
          recommended: rec,
          index: index,
        );
      },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final RecommendedEvent recommended;
  final int index;

  const _RecommendationCard({
    required this.recommended,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final event = recommended.event;
    final score = recommended.score;

    // Màu gradient theo điểm số
    final List<Color> gradientColors = score > 0.6
        ? [const Color(0xFF1B5E20), const Color(0xFF388E3C)]
        : score > 0.3
            ? [const Color(0xFF1565C0), const Color(0xFF1976D2)]
            : [const Color(0xFF4A148C), const Color(0xFF7B1FA2)];

    final dateStr = DateFormat('dd/MM/yyyy').format(event.startDate.toLocal());
    final scorePercent = (score * 100).clamp(0, 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header gradient
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rank badge + reason tag
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: gradientColors[0].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            recommended.reason,
                            style: TextStyle(
                              fontSize: 12,
                              color: gradientColors[0],
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tên sự kiện
                  Text(
                    event.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Mô tả
                  if (event.description.isNotEmpty)
                    Text(
                      event.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),

                  // Thông tin thêm
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        icon: Icons.calendar_today,
                        label: dateStr,
                        color: Colors.blue,
                      ),
                      if (event.organizer.isNotEmpty)
                        _InfoChip(
                          icon: Icons.business,
                          label: event.organizer,
                          color: Colors.orange,
                        ),
                      if (event.location != null && event.location!.isNotEmpty)
                        _InfoChip(
                          icon: Icons.location_on,
                          label: event.location!,
                          color: Colors.red,
                        ),
                      if (event.category != null && event.category!.isNotEmpty)
                        _InfoChip(
                          icon: Icons.label,
                          label: event.category!,
                          color: Colors.purple,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Thanh điểm phù hợp
                  Row(
                    children: [
                      Text(
                        'Độ phù hợp: $scorePercent%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: score.clamp(0.0, 1.0),
                            backgroundColor:
                                colorScheme.onSurface.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              gradientColors[1],
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}
