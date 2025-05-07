import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class ActivityDetailsScreen extends StatefulWidget {
  const ActivityDetailsScreen({super.key});

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  // Dữ liệu mẫu cho biểu đồ
  final List<double> weeklyUsageData = [3.2, 2.8, 3.7, 4.5, 2.9, 3.8, 4.2];
  final List<String> weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  
  // Dữ liệu mẫu cho biểu đồ tròn thời gian dùng app
  final List<Map<String, dynamic>> appUsageData = [
    {'name': 'Facebook', 'time': 3.5, 'color': const Color(0xFF1877F2)},
    {'name': 'YouTube', 'time': 2.0, 'color': const Color(0xFFFF0000)},
    {'name': 'Instagram', 'time': 1.5, 'color': const Color(0xFFE4405F)},
    {'name': 'TikTok', 'time': 1.0, 'color': const Color(0xFF000000)},
    {'name': 'Khác', 'time': 0.5, 'color': const Color(0xFF9E9E9E)},
  ];
  
  // Dữ liệu mẫu cho danh sách hoạt động
  final List<Map<String, dynamic>> activities = [
    {
      'date': '28/04/2025',
      'activities': [
        {'time': '08:00 - 09:30', 'name': 'Học Flutter', 'duration': '1h 30m', 'category': 'Học tập', 'color': Colors.blue},
        {'time': '10:00 - 11:00', 'name': 'Họp dự án', 'duration': '1h', 'category': 'Công việc', 'color': Colors.green},
        {'time': '13:30 - 15:00', 'name': 'Thiết kế UI', 'duration': '1h 30m', 'category': 'Công việc', 'color': Colors.green},
        {'time': '16:00 - 17:30', 'name': 'Tập thể dục', 'duration': '1h 30m', 'category': 'Sức khỏe', 'color': Colors.orange},
      ]
    },
    {
      'date': '27/04/2025',
      'activities': [
        {'time': '08:30 - 10:00', 'name': 'Đọc sách', 'duration': '1h 30m', 'category': 'Học tập', 'color': Colors.blue},
        {'time': '10:30 - 12:00', 'name': 'Viết mã', 'duration': '1h 30m', 'category': 'Công việc', 'color': Colors.green},
        {'time': '14:00 - 16:00', 'name': 'Nghiên cứu', 'duration': '2h', 'category': 'Học tập', 'color': Colors.blue},
      ]
    }
  ];
  
  // Dữ liệu mẫu cho lịch sử sử dụng thiết bị theo ngày
  final List<Map<String, dynamic>> deviceUsageHistory = [
    {
      'date': '28/04/2025',
      'total_time': '8h 30m',
      'chart_data': [
        {'name': 'Facebook', 'time': 3.5, 'color': const Color(0xFF1877F2)},
        {'name': 'YouTube', 'time': 2.0, 'color': const Color(0xFFFF0000)},
        {'name': 'Instagram', 'time': 1.5, 'color': const Color(0xFFE4405F)},
        {'name': 'TikTok', 'time': 1.0, 'color': const Color(0xFF000000)},
        {'name': 'Khác', 'time': 0.5, 'color': const Color(0xFF9E9E9E)},
      ],
      'screen_on_count': 32,
      'unlock_count': 24,
    },
    {
      'date': '27/04/2025',
      'total_time': '7h 15m',
      'chart_data': [
        {'name': 'Facebook', 'time': 2.8, 'color': const Color(0xFF1877F2)},
        {'name': 'YouTube', 'time': 1.5, 'color': const Color(0xFFFF0000)},
        {'name': 'Instagram', 'time': 1.3, 'color': const Color(0xFFE4405F)},
        {'name': 'TikTok', 'time': 0.8, 'color': const Color(0xFF000000)},
        {'name': 'Khác', 'time': 0.85, 'color': const Color(0xFF9E9E9E)},
      ],
      'screen_on_count': 28,
      'unlock_count': 22,
    },
    {
      'date': '26/04/2025',
      'total_time': '6h 45m',
      'chart_data': [
        {'name': 'Facebook', 'time': 2.2, 'color': const Color(0xFF1877F2)},
        {'name': 'YouTube', 'time': 1.8, 'color': const Color(0xFFFF0000)},
        {'name': 'Instagram', 'time': 1.2, 'color': const Color(0xFFE4405F)},
        {'name': 'TikTok', 'time': 0.75, 'color': const Color(0xFF000000)},
        {'name': 'Khác', 'time': 0.8, 'color': const Color(0xFF9E9E9E)},
      ],
      'screen_on_count': 25,
      'unlock_count': 20,
    },
  ];
  
  String _selectedTimeFrame = 'Tuần này';
  final List<String> _timeFrames = ['Hôm nay', 'Tuần này', 'Tháng này', 'Năm nay'];
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chi tiết hoạt động',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Tab bar để chuyển đổi giữa các chế độ xem
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTabOption(0, 'Thống kê'),
                _buildTabOption(1, 'Lịch sử sử dụng')
              ],
            ),
          ),
          
          // Nội dung tab
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _selectedTabIndex == 0 
                    ? _buildStatisticsTab() 
                    : _buildHistoryTab(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget tạo các tùy chọn tab
  Widget _buildTabOption(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected 
                    ? const Color(0xFF4776E6) 
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? const Color(0xFF4776E6) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  // Tab thống kê
  Widget _buildStatisticsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phần thống kê tổng quan
        _buildOverviewCard(),
        
        const SizedBox(height: 20),
        
        // Biểu đồ tròn thống kê thời gian sử dụng app
        _buildPieChartSection(),
        
        const SizedBox(height: 20),
        
        // Phần biểu đồ thời gian tập trung
        _buildChartSection(),
      ],
    );
  }
  
  // Tab lịch sử sử dụng
  Widget _buildHistoryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Danh sách lịch sử sử dụng theo ngày
        ...deviceUsageHistory.map((dayData) => _buildDayUsageCard(dayData)),
      ],
    );
  }
  
  // Widget hiển thị card thống kê sử dụng theo ngày
  Widget _buildDayUsageCard(Map<String, dynamic> dayData) {
    // Tính tổng thời gian
    double totalHours = 0;
    for (var app in dayData['chart_data']) {
      totalHours += app['time'] as double;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với ngày và thống kê
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dayData['date'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Tổng: ${dayData['total_time']}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4776E6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.screen_lock_portrait,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Mở khóa: ${dayData['unlock_count']} lần',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bật màn hình: ${dayData['screen_on_count']} lần',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Hiển thị biểu đồ mini và danh sách ứng dụng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Biểu đồ tròn mini
                Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(5),
                  child: PieChart(
                    PieChartData(
                      sections: _createPieSections(dayData['chart_data']),
                      sectionsSpace: 2,
                      centerSpaceRadius: 20,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Danh sách ứng dụng
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var app in dayData['chart_data'])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: app['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                app['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${app['time']}h',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${((app['time'] as double) / totalHours * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Widget thống kê tổng quan
  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quát',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('25h', 'Thời gian tập trung'),
              _buildStatItem('85%', 'Mục tiêu đạt được'),
              _buildStatItem('17', 'Thành tích'),
            ],
          ),
        ],
      ),
    );
  }
  
  // Widget hiển thị biểu đồ tròn thời gian dùng app
  Widget _buildPieChartSection() {
    // Tính tổng số giờ
    double totalHours = 0;
    for (var app in appUsageData) {
      totalHours += app['time'] as double;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thời gian sử dụng ứng dụng',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTimeFrame,
                  isDense: true,
                  items: _timeFrames.map((timeFrame) {
                    return DropdownMenuItem<String>(
                      value: timeFrame,
                      child: Text(
                        timeFrame,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTimeFrame = value;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              // Hiển thị tổng thời gian
              Center(
                child: Text(
                  'Tổng cộng: ${totalHours.toStringAsFixed(1)}h',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4776E6),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Biểu đồ tròn
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sections: _createPieSections(appUsageData),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Có thể thêm xử lý khi người dùng chạm vào biểu đồ
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Chú thích biểu đồ
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: appUsageData.map((app) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: app['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${app['name']}: ${app['time']}h',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${((app['time'] as double) / totalHours * 100).toStringAsFixed(1)}%)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Tạo dữ liệu phần cho biểu đồ tròn
  List<PieChartSectionData> _createPieSections(List<dynamic> data) {
    double totalValue = 0;
    for (var item in data) {
      totalValue += item['time'];
    }
    
    return data.map((item) {
      final double percentage = (item['time'] / totalValue);
      final double fontSize = 12.0;
      
      return PieChartSectionData(
        color: item['color'],
        value: item['time'],
        title: '', // Không hiển thị nhãn trên biểu đồ
        radius: 50,
        titleStyle: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
  
  // Widget hiển thị thống kê con
  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  // Widget phần biểu đồ cột (thời gian tập trung theo tuần)
  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thời gian tập trung',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTimeFrame,
                  isDense: true,
                  items: _timeFrames.map((timeFrame) {
                    return DropdownMenuItem<String>(
                      value: timeFrame,
                      child: Text(
                        timeFrame,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTimeFrame = value;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 230,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: 5,
              minY: 0,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        weekDays[value.toInt()],
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                    reservedSize: 25,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value % 1 == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${value.toInt()}h',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 25,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                weeklyUsageData.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: weeklyUsageData[index],
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      width: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Widget danh sách hoạt động
  Widget _buildActivityList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử hoạt động',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        ...activities.map((dayData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  dayData['date'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: dayData['activities'].length,
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.grey.shade200,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final activity = dayData['activities'][index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: activity['color'].withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            _getIconForCategory(activity['category']),
                            color: activity['color'],
                            size: 20,
                          ),
                        ),
                      ),
                      title: Text(
                        activity['name'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${activity['time']} - ${activity['category']}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Text(
                        activity['duration'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        }),
      ],
    );
  }
  
  // Hàm trả về biểu tượng phù hợp với từng loại hoạt động
  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Học tập':
        return Icons.book;
      case 'Công việc':
        return Icons.work;
      case 'Sức khỏe':
        return Icons.fitness_center;
      case 'Giải trí':
        return Icons.movie;
      default:
        return Icons.event;
    }
  }
}