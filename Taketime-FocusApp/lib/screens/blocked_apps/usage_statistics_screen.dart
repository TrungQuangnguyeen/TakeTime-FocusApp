import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppUsageStatisticsScreen extends StatefulWidget {
  const AppUsageStatisticsScreen({super.key});

  @override
  State<AppUsageStatisticsScreen> createState() => _AppUsageStatisticsScreenState();
}

class _AppUsageStatisticsScreenState extends State<AppUsageStatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Map<String, dynamic>> _blockedApps;
  late Map<String, Map<String, int>> _dailyUsageData;
  int _selectedDayIndex = 6; // Mặc định hiển thị dữ liệu ngày hôm nay
  
  final List<String> _weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Khởi tạo dữ liệu mẫu
    _blockedApps = [];
    _dailyUsageData = {};
    
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final blockedAppsJson = prefs.getStringList('blocked_apps') ?? [];
    final usageHistoryJson = prefs.getStringList('usage_history') ?? [];
    
    final List<Map<String, dynamic>> loadedApps = [];
    
    // Tải danh sách ứng dụng bị chặn
    if (blockedAppsJson.isNotEmpty) {
      for (String jsonString in blockedAppsJson) {
        Map<String, dynamic> appData = json.decode(jsonString);
        
        // Chuyển đổi màu sắc từ JSON sang Color
        if (appData['color'] is String) {
          String colorString = appData['color'];
          int colorValue = int.parse(colorString.replaceAll('#', '0xFF'));
          appData['color'] = Color(colorValue);
        }
        
        loadedApps.add(appData);
      }
    } else {
      // Dữ liệu mẫu khi chưa có dữ liệu được lưu trữ
      loadedApps.addAll([
        {
          'name': 'Instagram',
          'packageName': 'com.instagram.android',
          'color': const Color(0xFFE4405F),
          'timeLimit': 45,
        },
        {
          'name': 'YouTube',
          'packageName': 'com.google.android.youtube',
          'color': const Color(0xFFFF0000),
          'timeLimit': 60,
        },
        {
          'name': 'TikTok',
          'packageName': 'com.zhiliaoapp.musically',
          'color': const Color(0xFF000000),
          'timeLimit': 20,
        },
      ]);
    }
    
    // Tạo dữ liệu sử dụng mẫu cho 7 ngày gần đây
    final Map<String, Map<String, int>> usageData = {};
    
    // Tải lịch sử sử dụng nếu có
    if (usageHistoryJson.isNotEmpty) {
      for (String jsonString in usageHistoryJson) {
        Map<String, dynamic> historyData = json.decode(jsonString);
        String date = historyData['date'];
        String packageName = historyData['packageName'];
        int minutes = historyData['minutes'];
        
        if (!usageData.containsKey(date)) {
          usageData[date] = {};
        }
        usageData[date]![packageName] = minutes;
      }
    } else {
      // Tạo dữ liệu sử dụng mẫu cho 7 ngày gần đây
      for (int i = 0; i < 7; i++) {
        String date = _getDateString(DateTime.now().subtract(Duration(days: 6 - i)));
        usageData[date] = {};
        
        for (Map<String, dynamic> app in loadedApps) {
          String packageName = app['packageName'];
          // Tạo dữ liệu ngẫu nhiên nhưng có xu hướng tăng dần
          int baseMinutes = 10 + (i * 2); // Tăng dần theo ngày gần đây
          int randomFactor = (DateTime.now().millisecondsSinceEpoch % 20) - 10; // Random factor -10 to 10
          int minutes = (baseMinutes + randomFactor).clamp(5, (app['timeLimit'] as int) * 1.5).toInt();
          usageData[date]![packageName] = minutes;
        }
      }
    }
    
    setState(() {
      _blockedApps = loadedApps;
      _dailyUsageData = usageData;
    });
  }
  
  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Thống kê sử dụng',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(
              text: 'Tổng quan',
              icon: Icon(Icons.bar_chart),
            ),
            Tab(
              text: 'Chi tiết',
              icon: Icon(Icons.pie_chart),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildDetailedTab(),
        ],
      ),
    );
  }
  
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          Text(
            'Tổng quan sử dụng',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Theo dõi thời gian bạn dành cho các ứng dụng trong tuần qua',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Biểu đồ sử dụng hàng ngày
          _buildDailyUsageChart(),
          const SizedBox(height: 32),
          
          // Thẻ tổng thời gian sử dụng
          _buildTotalUsageCard(),
          const SizedBox(height: 24),
          
          // Danh sách ứng dụng sử dụng nhiều nhất
          _buildMostUsedAppsSection(),
        ],
      ),
    );
  }
  
  Widget _buildDetailedTab() {
    final List<String> dateStrings = _dailyUsageData.keys.toList();
    dateStrings.sort(); // Sắp xếp theo ngày tăng dần
    
    // Lấy dữ liệu ngày được chọn
    String selectedDate = dateStrings.isNotEmpty 
      ? (_selectedDayIndex < dateStrings.length ? dateStrings[_selectedDayIndex] : dateStrings.last) 
      : _getDateString(DateTime.now());
    final Map<String, int> dayData = _dailyUsageData[selectedDate] ?? {};
    
    // Tính tổng thời gian sử dụng trong ngày
    int totalMinutes = 0;
    dayData.forEach((_, minutes) {
      totalMinutes += minutes;
    });
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề và chọn ngày
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chi tiết theo ngày',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<int>(
                value: _selectedDayIndex < 7 ? _selectedDayIndex : 6,
                items: List.generate(7, (index) {
                  DateTime date = DateTime.now().subtract(Duration(days: 6 - index));
                  String dayString = _weekdays[date.weekday - 1];
                  return DropdownMenuItem(
                    value: index,
                    child: Text(
                      index == 6 ? 'Hôm nay' : '$dayString, ${date.day}/${date.month}',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  );
                }),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedDayIndex = newValue;
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Biểu đồ tròn phân bổ thời gian
          _buildTimeDistributionPieChart(dayData),
          const SizedBox(height: 32),
          
          // Bảng chi tiết sử dụng ứng dụng
          _buildAppUsageDetailTable(dayData),
        ],
      ),
    );
  }
  
  Widget _buildDailyUsageChart() {
    final List<String> dateStrings = _dailyUsageData.keys.toList();
    dateStrings.sort(); // Sắp xếp theo ngày tăng dần
    
    // Tính tổng thời gian sử dụng theo ngày
    final List<int> dailyTotalMinutes = [];
    for (String date in dateStrings) {
      int total = 0;
      _dailyUsageData[date]?.forEach((_, minutes) {
        total += minutes;
      });
      dailyTotalMinutes.add(total);
    }
    
    // Nếu không có dữ liệu, tạo dữ liệu giả
    if (dailyTotalMinutes.isEmpty) {
      dailyTotalMinutes.addAll([10, 15, 20, 18, 25, 30, 22]);
      for (int i = 0; i < 7; i++) {
        String date = _getDateString(DateTime.now().subtract(Duration(days: 6 - i)));
        dateStrings.add(date);
      }
    }
    
    double maxY = dailyTotalMinutes.reduce((a, b) => a > b ? a : b) * 1.2;
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thời gian sử dụng hàng ngày',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: _bottomTitleWidgets,
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: _leftTitleWidgets,
                      reservedSize: 40,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: 30,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: List.generate(
                  dailyTotalMinutes.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: dailyTotalMinutes[index].toDouble(),
                        color: index == dailyTotalMinutes.length - 1
                            ? Theme.of(context).primaryColor
                            : Colors.blue.shade200,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    if (value % 30 != 0) {
      return Container();
    }
    
    return Text(
      '${value.toInt()}p', 
      style: GoogleFonts.poppins(
        fontSize: 10,
        color: Colors.grey[600],
      ),
    );
  }
  
  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    final List<String> dateStrings = _dailyUsageData.keys.toList();
    dateStrings.sort();
    
    if (value < 0 || value >= dateStrings.length) {
      return Container();
    }
    
    DateTime date;
    try {
      date = DateTime.parse(dateStrings[value.toInt()]);
    } catch (e) {
      date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
    }
    
    return Text(
      value.toInt() == dateStrings.length - 1
          ? 'Hôm nay'
          : '${date.day}/${date.month}',
      style: GoogleFonts.poppins(
        fontSize: 10,
        color: Colors.grey[600],
      ),
    );
  }
  
  Widget _buildTotalUsageCard() {
    // Tính tổng thời gian sử dụng trong tuần
    int totalWeeklyMinutes = 0;
    _dailyUsageData.forEach((date, appData) {
      appData.forEach((_, minutes) {
        totalWeeklyMinutes += minutes;
      });
    });
    
    // Tính thời gian sử dụng trung bình mỗi ngày
    int averageDailyMinutes = 
        _dailyUsageData.isEmpty ? 0 : totalWeeklyMinutes ~/ _dailyUsageData.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng thời gian trong tuần',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$totalWeeklyMinutes phút',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trung bình mỗi ngày',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$averageDailyMinutes phút',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMostUsedAppsSection() {
    // Tính tổng thời gian sử dụng cho từng ứng dụng
    Map<String, int> totalAppUsage = {};
    
    for (Map<String, dynamic> app in _blockedApps) {
      String packageName = app['packageName'];
      int totalMinutes = 0;
      
      _dailyUsageData.forEach((_, appData) {
        totalMinutes += appData[packageName] ?? 0;
      });
      
      totalAppUsage[packageName] = totalMinutes;
    }
    
    // Sắp xếp theo thời gian sử dụng giảm dần
    List<Map<String, dynamic>> sortedApps = List.from(_blockedApps);
    sortedApps.sort((a, b) {
      int aUsage = totalAppUsage[a['packageName']] ?? 0;
      int bUsage = totalAppUsage[b['packageName']] ?? 0;
      return bUsage.compareTo(aUsage);
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ứng dụng sử dụng nhiều nhất',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...sortedApps.take(3).map((app) {
          String packageName = app['packageName'];
          int totalMinutes = totalAppUsage[packageName] ?? 0;
          int limitMinutes = app['timeLimit'] ?? 0;
          double usagePercentage = limitMinutes > 0 ? (totalMinutes / (limitMinutes * 7)).clamp(0.0, 1.0) : 0.0;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // App icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (app['color'] as Color).withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForAppName(app['name']),
                          color: app['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // App details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$totalMinutes phút (${(usagePercentage * 100).toStringAsFixed(0)}% giới hạn)',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Usage time
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getColorByUsagePercentage(usagePercentage).withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getUsageStatusText(usagePercentage),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getColorByUsagePercentage(usagePercentage),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: usagePercentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getColorByUsagePercentage(usagePercentage),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildTimeDistributionPieChart(Map<String, int> dayData) {
    // Lọc và sắp xếp các ứng dụng theo thời gian sử dụng
    List<MapEntry<String, int>> sortedEntries = dayData.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    
    // Giới hạn chỉ hiển thị 5 ứng dụng hàng đầu + nhóm "Khác"
    final int threshold = 5;
    List<MapEntry<String, int>> topEntries = 
        sortedEntries.length > threshold ? sortedEntries.sublist(0, threshold) : sortedEntries;
    
    // Tính tổng thời gian "Khác"
    int otherMinutes = 0;
    if (sortedEntries.length > threshold) {
      for (int i = threshold; i < sortedEntries.length; i++) {
        otherMinutes += sortedEntries[i].value;
      }
    }
    
    // Tổng hợp dữ liệu cho biểu đồ tròn
    List<PieChartSectionData> sections = [];
    double totalMinutes = 0;
    List<Map<String, dynamic>> chartData = [];
    
    for (MapEntry<String, int> entry in topEntries) {
      totalMinutes += entry.value;
    }
    totalMinutes += otherMinutes;
    
    // Tạo các sections cho biểu đồ tròn và dữ liệu cho legend
    if (totalMinutes > 0) {
      for (int i = 0; i < topEntries.length; i++) {
        MapEntry<String, int> entry = topEntries[i];
        String packageName = entry.key;
        int minutes = entry.value;
        double percentage = minutes / totalMinutes;
        
        // Tìm thông tin ứng dụng từ danh sách đã lưu
        Map<String, dynamic>? appInfo;
        for (var app in _blockedApps) {
          if (app['packageName'] == packageName) {
            appInfo = app;
            break;
          }
        }
        
        if (appInfo != null) {
          Color appColor = appInfo['color'] as Color? ?? _getColorForIndex(i);
          
          // Thêm section vào biểu đồ tròn (không hiển thị nhãn % trên biểu đồ)
          sections.add(
            PieChartSectionData(
              value: minutes.toDouble(),
              title: '',
              color: appColor,
              radius: 45, // Điều chỉnh kích thước của biểu đồ
              badgeWidget: null,
              showTitle: false,
            ),
          );
          
          // Lưu thông tin cho legend
          chartData.add({
            'name': appInfo['name'],
            'minutes': minutes,
            'percentage': percentage,
            'color': appColor,
          });
        }
      }
      
      // Thêm phần "Khác" nếu có
      if (otherMinutes > 0) {
        double percentage = otherMinutes / totalMinutes;
        sections.add(
          PieChartSectionData(
            value: otherMinutes.toDouble(),
            title: '',
            color: Colors.grey,
            radius: 65,
            showTitle: false,
          ),
        );
        
        chartData.add({
          'name': 'Khác',
          'minutes': otherMinutes,
          'percentage': percentage,
          'color': Colors.grey,
        });
      }
    }
    
    // Nếu không có dữ liệu, hiển thị biểu đồ trống
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 1,
          title: '',
          color: Colors.grey.shade300,
          radius: 65,
          showTitle: false,
        ),
      );
      
      chartData.add({
        'name': 'Không có dữ liệu',
        'minutes': 0,
        'percentage': 1.0,
        'color': Colors.grey.shade300,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phân bổ thời gian sử dụng',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Biểu đồ tròn và chú thích
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Biểu đồ tròn
                  Expanded(
                    flex: 1,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: sections,
                          pieTouchData: PieTouchData(enabled: false),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Chú thích bên phải - Hiển thị giống với thiết kế mẫu
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: chartData.map((data) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              // Đốm màu tròn
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: data['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Tên ứng dụng
                              Expanded(
                                child: Text(
                                  data['name'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Phần trăm
                              Text(
                                '${(data['percentage'] * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Chi tiết thời gian - hiển thị dưới dạng các nút bo tròn
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chi tiết thời gian',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chartData.map((data) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      '${data['name']}: ${data['minutes']} phút',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAppUsageDetailTable(Map<String, int> dayData) {
    // Lọc và sắp xếp các ứng dụng theo thời gian sử dụng
    List<MapEntry<String, int>> sortedEntries = dayData.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết theo ứng dụng',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Ứng dụng',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Thời gian',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Giới hạn',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          
          // Rows
          ...sortedEntries.map((entry) {
            String packageName = entry.key;
            int minutes = entry.value;
            
            // Tìm thông tin ứng dụng từ danh sách đã lưu
            Map<String, dynamic>? appInfo;
            for (var app in _blockedApps) {
              if (app['packageName'] == packageName) {
                appInfo = app;
                break;
              }
            }
            
            if (appInfo == null) return const SizedBox.shrink();
            
            String appName = appInfo['name'];
            int limitMinutes = appInfo['timeLimit'] ?? 0;
            Color appColor = appInfo['color'] as Color? ?? Colors.grey;
            
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: appColor.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconForAppName(appName),
                            color: appColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$minutes phút',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: minutes > limitMinutes ? Colors.red : null,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$limitMinutes phút',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  IconData _getIconForAppName(String appName) {
    switch (appName.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'youtube':
        return Icons.play_circle_fill;
      case 'tiktok':
        return Icons.music_note;
      case 'twitter':
        return Icons.chat;
      default:
        return Icons.apps;
    }
  }
  
  Color _getColorForIndex(int index) {
    const List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    
    return colors[index % colors.length];
  }
  
  Color _getColorByUsagePercentage(double percentage) {
    if (percentage > 0.9) {
      return Colors.red;
    } else if (percentage > 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
  
  String _getUsageStatusText(double percentage) {
    if (percentage > 0.9) {
      return 'Quá mức';
    } else if (percentage > 0.7) {
      return 'Cao';
    } else if (percentage > 0.3) {
      return 'Trung bình';
    } else {
      return 'Thấp';
    }
  }
}