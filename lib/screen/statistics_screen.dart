import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../app_theme.dart';

enum StatsType { byUniversity, byEvent, byDate }

class StatisticsScreen extends StatefulWidget {
  final StatsType initialStatsType;
  const StatisticsScreen({super.key, required this.initialStatsType});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _attendanceDataFuture;
  late StatsType _selectedStatsType;

  @override
  void initState() {
    super.initState();
    _attendanceDataFuture = _apiService.fetchAllAttendanceForStats();
    _selectedStatsType = widget.initialStatsType;
  }

  Map<String, int> _processData(List<Map<String, dynamic>> data) {
    Map<String, int> statsMap = {};

    for (var record in data) {
      String key;
      // SỬA: Truy cập vào đúng cấu trúc dữ liệu mới
      final eventData = record['event'];
      final studentData = record['student'];

      if (studentData == null)
        continue; // Bỏ qua nếu không có thông tin sinh viên

      switch (_selectedStatsType) {
        case StatsType.byUniversity:
          key = studentData['university']?['name'] ?? 'Không rõ';
          break;
        case StatsType.byEvent:
          key = eventData?['title'] ?? 'Không rõ';
          break;
        case StatsType.byDate:
          final date =
              eventData?['start_date']; // Dùng start_date từ bảng event
          if (date != null) {
            key = DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
          } else {
            key = 'Không rõ';
          }
          break;
      }
      statsMap[key] = (statsMap[key] ?? 0) + 1;
    }
    return statsMap;
  }

  String _getChartTitle() {
    switch (_selectedStatsType) {
      case StatsType.byUniversity:
        return 'Thống kê theo Trường/Đơn vị';
      case StatsType.byEvent:
        return 'Thống kê theo Sự kiện';
      case StatsType.byDate:
        return 'Thống kê theo Ngày';
    }
  }

  // ... Phần còn lại của file (Widget build) giữ nguyên, không cần thay đổi ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê chi tiết'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<StatsType>(
              segments: const [
                ButtonSegment(
                  value: StatsType.byUniversity,
                  label: Text('Theo Trường'),
                  icon: Icon(Icons.school),
                ),
                ButtonSegment(
                  value: StatsType.byEvent,
                  label: Text('Theo Sự kiện'),
                  icon: Icon(Icons.event),
                ),
                ButtonSegment(
                  value: StatsType.byDate,
                  label: Text('Theo Ngày'),
                  icon: Icon(Icons.date_range),
                ),
              ],
              selected: {_selectedStatsType},
              onSelectionChanged: (Set<StatsType> newSelection) {
                setState(() {
                  _selectedStatsType = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: AppColors.primary,
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _attendanceDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Không có dữ liệu để thống kê.'),
                  );
                }

                final statsData = _processData(snapshot.data!);

                final sortedData = statsData.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                if (sortedData.isEmpty) {
                  return const Center(
                    child: Text('Không có dữ liệu hợp lệ để hiển thị.'),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY:
                          (sortedData.isNotEmpty
                              ? sortedData.first.value.toDouble()
                              : 10.0) *
                          1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${sortedData[group.x.toInt()].key}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: rod.toY.round().toString(),
                                  style: const TextStyle(
                                    color: Colors.yellow,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 100,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= sortedData.length) return const SizedBox.shrink();
                              final text = sortedData[index].key;
                              return Text(
                                text,
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: sortedData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: data.value.toDouble(),
                              color: AppColors.primary,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return const FlLine(
                            color: Colors.grey,
                            strokeWidth: 0.5,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _getChartTitle(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}
