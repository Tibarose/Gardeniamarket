import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart' as intl;
import '../../main.dart';
import '../core/config/supabase_config.dart';
import '../homescreen/thememanager.dart';

class HousesManagementPage extends StatefulWidget {
  const HousesManagementPage({super.key});

  @override
  _HousesManagementPageState createState() => _HousesManagementPageState();
}

class _HousesManagementPageState extends State<HousesManagementPage> {
  List<Map<String, dynamic>> _houses = [];
  List<Map<String, dynamic>> _filteredHouses = [];
  bool _isLoading = true;
  String? _error;

  // Filter variables
  String? _selectedStatus;
  String? _selectedZone;
  String? _searchPhone;
  RangeValues _rentPriceRange = const RangeValues(0, 100000);
  RangeValues _spaceRange = const RangeValues(0, 500);
  String? _selectedPeriod;
  String? _selectedRoom;
  String? _selectedBathroom;
  String? _selectedFloor;
  String? _selectedFurnished;
  String? _selectedPresenter;
  List<String> _selectedAmenities = [];
  DateTimeRange? _expiryDateRange;
  DateTimeRange? _createdAtRange;

  final List<String> _amenitiesOptions = [
    'حديقة خاصة',
    'عداد كهرباء',
    'عداد مياه',
    'غاز طبيعي',
    'تليفون أرضي',
    'اسانسير',
    'انترنت منزلي',
  ];

  @override
  void initState() {
    super.initState();
    _fetchHouses();
  }

  Future<void> _fetchHouses() async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('houses')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _houses = List<Map<String, dynamic>>.from(response);
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل في تحميل الشقق: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _houses;

    // Filter by status
    if (_selectedStatus != null) {
      filtered = filtered.where((house) => house['status'] == _selectedStatus).toList();
    }

    // Filter by zone
    if (_selectedZone != null) {
      filtered = filtered.where((house) => house['zone']?.toString() == _selectedZone).toList();
    }

    // Search by phone
    if (_searchPhone != null && _searchPhone!.isNotEmpty) {
      filtered = filtered
          .where((house) => house['phone']?.toString().contains(_searchPhone!) ?? false)
          .toList();
    }

    // Filter by rent price range
    filtered = filtered.where((house) {
      final rentPrice = (house['rent_price'] as num?)?.toDouble() ?? 0;
      return rentPrice >= _rentPriceRange.start && rentPrice <= _rentPriceRange.end;
    }).toList();

    // Filter by space range
    filtered = filtered.where((house) {
      final space = (house['space'] as num?)?.toDouble() ?? 0;
      return space >= _spaceRange.start && space <= _spaceRange.end;
    }).toList();

    // Filter by period
    if (_selectedPeriod != null) {
      filtered = filtered.where((house) => house['period'] == _selectedPeriod).toList();
    }

    // Filter by rooms
    if (_selectedRoom != null) {
      filtered = filtered
          .where((house) => house['room']?.toString() == _selectedRoom)
          .toList();
    }

    // Filter by bathrooms
    if (_selectedBathroom != null) {
      filtered = filtered
          .where((house) => house['bathroom']?.toString() == _selectedBathroom)
          .toList();
    }

    // Filter by floor
    if (_selectedFloor != null) {
      filtered = filtered.where((house) => house['floor'] == _selectedFloor).toList();
    }

    // Filter by furnished
    if (_selectedFurnished != null) {
      filtered = filtered.where((house) => house['furnished'] == _selectedFurnished).toList();
    }

    // Filter by presenter
    if (_selectedPresenter != null) {
      filtered = filtered.where((house) => house['presenter'] == _selectedPresenter).toList();
    }

    // Filter by amenities
    if (_selectedAmenities.isNotEmpty) {
      filtered = filtered.where((house) {
        final amenities = house['amenities'] != null
            ? List<String>.from(house['amenities'])
            : [];
        return _selectedAmenities.every((amenity) => amenities.contains(amenity));
      }).toList();
    }

    // Filter by expiry date range
    if (_expiryDateRange != null) {
      filtered = filtered.where((house) {
        final expiryDateStr = house['expiry_date']?.toString();
        if (expiryDateStr == null) return false;
        try {
          final expiryDate = intl.DateFormat('d/M/yyyy').parse(expiryDateStr);
          return expiryDate.isAfter(_expiryDateRange!.start.subtract(const Duration(days: 1))) &&
              expiryDate.isBefore(_expiryDateRange!.end.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Filter by created at range
    if (_createdAtRange != null) {
      filtered = filtered.where((house) {
        final createdAtStr = house['created_at']?.toString();
        if (createdAtStr == null) return false;
        try {
          final createdAt = DateTime.parse(createdAtStr);
          return createdAt.isAfter(_createdAtRange!.start.subtract(const Duration(days: 1))) &&
              createdAt.isBefore(_createdAtRange!.end.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
    }

    setState(() {
      _filteredHouses = filtered;
    });
  }

  Future<void> _deleteHouse(String id) async {
    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      await supabaseConfig.secondaryClient
          .from('houses')
          .delete()
          .eq('id', id);

      await _fetchHouses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم الحذف بنجاح',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: ThemeManager().currentTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل في الحذف: $e',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? house}) {
    showDialog(
      context: context,
      builder: (context) => AddEditHouseDialog(
        house: house,
        onSave: () async {
          await _fetchHouses();
        },
      ),
    );
  }

  void _showFilterDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeManager().currentTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تصفية الشقق',
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: ThemeManager().currentTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFilterDropdown(
                          label: 'الحالة',
                          value: _selectedStatus,
                          items: ['Active', 'Pending'],
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value;
                              this.setState(() => _applyFilters());
                            });
                          },
                          theme: ThemeManager().currentTheme,
                          isMandatory: false,
                        ),
                        const SizedBox(height: 16),
                        _buildFilterDropdown(
                          label: 'الزوون',
                          value: _selectedZone,
                          items: List.generate(11, (index) => (index + 1).toString()),
                          onChanged: (value) {
                            setState(() {
                              _selectedZone = value;
                              this.setState(() => _applyFilters());
                            });
                          },
                          theme: ThemeManager().currentTheme,
                          isMandatory: false,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'البحث برقم الهاتف',
                            labelStyle: GoogleFonts.cairo(
                              color: ThemeManager().currentTheme.secondaryTextColor,
                              fontSize: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.search),
                          ),
                          style: GoogleFonts.cairo(
                            color: ThemeManager().currentTheme.textColor,
                            fontSize: 16,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchPhone = value.trim();
                              this.setState(() => _applyFilters());
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildRangeSlider(
                          label: 'نطاق الإيجار (جنيه)',
                          range: _rentPriceRange,
                          min: 0,
                          max: 100000,
                          divisions: 100,
                          onChanged: (value) {
                            setState(() {
                              _rentPriceRange = value;
                              this.setState(() => _applyFilters());
                            });
                          },
                          theme: ThemeManager().currentTheme,
                        ),
                        const SizedBox(height: 16),
                        _buildRangeSlider(
                          label: 'نطاق المساحة (م²)',
                          range: _spaceRange,
                          min: 0,
                          max: 500,
                          divisions: 50,
                          onChanged: (value) {
                            setState(() {
                              _spaceRange = value;
                              this.setState(() => _applyFilters());
                            });
                          },
                          theme: ThemeManager().currentTheme,
                        ),
                        const SizedBox(height: 16),
                        _buildFilterDropdown(
                          label: 'فترة الإيجار',
                          value: _selectedPeriod,
                          items: [
                            '6 شهور',
                            'سنة',
                            'سنة ونصف',
                            'سنتين',
                            'ثلاث سنوات',
                            'قابل للتفاوض'
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPeriod = value;
                              this.setState(() => _applyFilters());
                            });
                          },
                          theme: ThemeManager().currentTheme,
                          isMandatory: false,
                        ),
                        const SizedBox(height: 16),
                        _buildFilterDropdown(
                          label: 'غرف النوم',
                          value: _selectedRoom,
                          items: List.generate(3, (index) => (index + 1).toString()),
                          onChanged: (value) {
                            setState(() {
                              _selectedRoom = value;
                              this.setState(() => _applyFilters());
                            });
                          },
                          theme: ThemeManager().currentTheme,
                          isMandatory: false,
                        ),
                        const SizedBox(height: 16),
                        _buildFilterDropdown(
                          label: 'عدد الحمامات',
                          value: _selectedBathroom,
                          items: List.generate(2, (index) => (index + 1).toString()),
                          onChanged: (value) {
                            setState(() {
                              _selectedBathroom = value;
                              this.setState(() => _applyFilters());
                            });
                          },
                          theme: ThemeManager().currentTheme,
                          isMandatory: false,
                        ),
                        const SizedBox(height: 16),
                        _buildFilterDropdown(
                          label: 'الدور',
                          value: _selectedFloor,
                          items: [
                            'الأرضي',
                            'الأول',
                            'الثاني',
                            'الثالث',
                            'الرابع',
                            'الخامس',
                            'السادس'
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedFloor = value;
                              this.setState(() => _applyFilters());
                            });
                          },
                          theme: ThemeManager().currentTheme,
                          isMandatory: false,
                        ),
                        const SizedBox(height: 16),
                        _buildFilterDropdown(
                          label: 'مفروشة؟',
                          value: _selectedFurnished,
                          items: ['نعم', 'لا'],
                          onChanged: (value) {
                            setState(() {
                              _selectedFurnished = value;
                              this.setState(() => _applyFilters());
                            });
                          },
                          theme: ThemeManager().currentTheme,
                          isMandatory: false,
                        ),
                        const SizedBox(height: 16),
                        _buildFilterDropdown(
                          label: 'المعلن',
                          value: _selectedPresenter,
                          items: ['مالك الشقة', 'شركة عقارية'],
                          onChanged: (value) {
                            setState(() {
                              _selectedPresenter = value;
                              this.setState(() => _applyFilters());
                            });
                          },
                          theme: ThemeManager().currentTheme,
                          isMandatory: false,
                        ),
                        const SizedBox(height: 16),
                        _buildMultiSelectionFilter(
                          theme: ThemeManager().currentTheme,
                          setState: setState,
                        ),
                        const SizedBox(height: 16),
                        _buildDateRangePicker(
                          label: 'نطاق تاريخ الانتهاء',
                          range: _expiryDateRange,
                          onPicked: (range) {
                            setState(() {
                              _expiryDateRange = range;
                              this.setState(() => _applyFilters());
                            });
                          },
                          theme: ThemeManager().currentTheme,
                        ),
                        const SizedBox(height: 16),
                        _buildDateRangePicker(
                          label: 'نطاق تاريخ الإنشاء',
                          range: _createdAtRange,
                          onPicked: (range) {
                            setState(() {
                              _createdAtRange = range;
                              this.setState(() => _applyFilters());
                            });
                          },
                          theme: ThemeManager().currentTheme,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedStatus = null;
                                  _selectedZone = null;
                                  _searchPhone = null;
                                  _rentPriceRange = const RangeValues(0, 100000);
                                  _spaceRange = const RangeValues(0, 500);
                                  _selectedPeriod = null;
                                  _selectedRoom = null;
                                  _selectedBathroom = null;
                                  _selectedFloor = null;
                                  _selectedFurnished = null;
                                  _selectedPresenter = null;
                                  _selectedAmenities = [];
                                  _expiryDateRange = null;
                                  _createdAtRange = null;
                                  this.setState(() => _applyFilters());
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'مسح التصفية',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ThemeManager().currentTheme.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'تطبيق',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'إدارة الشقق',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 4,
          actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.filter),
              onPressed: _showFilterDrawer,
              tooltip: 'تصفية',
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.plus),
              onPressed: () => _showAddEditDialog(),
              tooltip: 'إضافة شقة جديدة',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _fetchHouses,
          color: theme.primaryColor,
          child: _isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: theme.primaryColor,
            ),
          )
              : _error != null
              ? Center(
            child: Text(
              _error!,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          )
              : _filteredHouses.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.home_outlined,
                  size: 60,
                  color: theme.secondaryTextColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد شقق تطابق المعايير',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            itemCount: _filteredHouses.length,
            itemBuilder: (context, index) {
              final house = _filteredHouses[index];
              final createdAt = DateTime.parse(house['created_at']).toLocal();
              final formattedCreatedAt =
              intl.DateFormat('d/M/yyyy HH:mm').format(createdAt);

              List<dynamic> images = house['images'] ?? [];
              String? firstImage =
              images.isNotEmpty ? images.first.toString() : null;

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        theme.cardBackground,
                        theme.cardBackground.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                      vertical: 12,
                    ),
                    leading: firstImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        firstImage,
                        width: isMobile ? 50 : 60,
                        height: isMobile ? 50 : 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.home,
                          size: isMobile ? 40 : 50,
                          color: theme.primaryColor,
                        ),
                      ),
                    )
                        : Icon(
                      Icons.home,
                      size: isMobile ? 40 : 50,
                      color: theme.primaryColor,
                    ),
                    title: Text(
                      'شقة ${house['space'] ?? 'غير متوفر'} م² - زوون ${house['zone'] ?? 'غير متوفر'}',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: theme.textColor,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          icon: Icons.monetization_on,
                          label: 'الإيجار',
                          value: '${house['rent_price'] ?? 'غير متوفر'} جنيه (${house['selected_period'] ?? 'غير محدد'})',
                          theme: theme,
                          isMobile: isMobile,
                        ),
                        _buildInfoRow(
                          icon: Icons.security,
                          label: 'التأمين',
                          value: '${house['insurance'] ?? 'غير متوفر'} جنيه',
                          theme: theme,
                          isMobile: isMobile,
                        ),
                        _buildInfoRow(
                          icon: Icons.timer,
                          label: 'المدة',
                          value: house['period'] ?? 'غير متوفر',
                          theme: theme,
                          isMobile: isMobile,
                        ),
                        _buildInfoRow(
                          icon: Icons.account_circle,
                          label: 'المعلن',
                          value: house['presenter'] ?? 'غير متوفر',
                          theme: theme,
                          isMobile: isMobile,
                        ),
                        _buildInfoRow(
                          icon: Icons.phone,
                          label: 'التواصل',
                          value: house['contact'] ?? 'غير متوفر',
                          theme: theme,
                          isMobile: isMobile,
                        ),
                        _buildInfoRow(
                          icon: Icons.event_busy,
                          label: 'تاريخ الانتهاء',
                          value: house['expiry_date'] ?? 'غير متوفر',
                          theme: theme,
                          isMobile: isMobile,
                          highlight: true,
                        ),
                        _buildInfoRow(
                          icon: Icons.info,
                          label: 'الحالة',
                          value: house['status'] ?? 'غير متوفر',
                          theme: theme,
                          isMobile: isMobile,
                        ),
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          label: 'تاريخ الإنشاء',
                          value: formattedCreatedAt,
                          theme: theme,
                          isMobile: isMobile,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIconButton(
                          icon: FontAwesomeIcons.edit,
                          color: theme.primaryColor,
                          tooltip: 'تعديل',
                          onPressed: () => _showAddEditDialog(house: house),
                        ),
                        _buildIconButton(
                          icon: FontAwesomeIcons.trash,
                          color: Colors.red,
                          tooltip: 'حذف',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => Directionality(
                                textDirection: TextDirection.rtl,
                                child: AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  backgroundColor: theme.cardBackground,
                                  title: Text(
                                    'تأكيد الحذف',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700,
                                      color: theme.textColor,
                                    ),
                                  ),
                                  content: Text(
                                    'هل أنت متأكد من حذف هذه الشقة؟',
                                    style: GoogleFonts.cairo(
                                      color: theme.textColor,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'إلغاء',
                                        style: GoogleFonts.cairo(
                                          color: theme.secondaryTextColor,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteHouse(house['id']);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'حذف',
                                        style: GoogleFonts.cairo(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _fetchHouses,
          backgroundColor: theme.primaryColor,
          child: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'تحديث القائمة',
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required AppTheme theme,
    required bool isMobile,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isMobile ? 16 : 18,
            color: highlight ? Colors.red : theme.secondaryTextColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 14 : 16,
                      color: highlight ? Colors.red : theme.secondaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 14 : 16,
                      color: highlight ? Colors.red : theme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FaIcon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required AppTheme theme,
    bool isMandatory = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(
          color: theme.secondaryTextColor,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('الكل'),
        ),
        ...items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: theme.textColor,
            ),
          ),
        )),
      ],
      onChanged: onChanged,
      style: GoogleFonts.cairo(
        fontSize: 14,
        color: theme.textColor,
      ),
      icon: FaIcon(
        FontAwesomeIcons.arrowDown,
        color: theme.primaryColor,
        size: 16,
      ),
    );
  }

  Widget _buildRangeSlider({
    required String label,
    required RangeValues range,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<RangeValues> onChanged,
    required AppTheme theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${range.start.round()} - ${range.end.round()}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        RangeSlider(
          values: range,
          min: min,
          max: max,
          divisions: divisions,
          labels: RangeLabels(
            range.start.round().toString(),
            range.end.round().toString(),
          ),
          activeColor: theme.primaryColor,
          inactiveColor: theme.secondaryTextColor.withOpacity(0.3),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMultiSelectionFilter({
    required AppTheme theme,
    required StateSetter setState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الملحقات والمرافق',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _amenitiesOptions.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return ChoiceChip(
              label: Text(
                amenity,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : theme.textColor,
                ),
              ),
              selected: isSelected,
              selectedColor: theme.primaryColor,
              backgroundColor: theme.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.primaryColor.withOpacity(0.2)),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                  this.setState(() => _applyFilters());
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangePicker({
    required String label,
    required DateTimeRange? range,
    required Function(DateTimeRange?) onPicked,
    required AppTheme theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                range != null
                    ? '${intl.DateFormat('d/M/yyyy').format(range.start)} - ${intl.DateFormat('d/M/yyyy').format(range.end)}'
                    : 'اختر النطاق',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: theme.secondaryTextColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: range,
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: ColorScheme.light(
                          primary: theme.primaryColor,
                          onPrimary: Colors.white,
                          surface: theme.cardBackground,
                          onSurface: theme.textColor,
                        ),
                        dialogBackgroundColor: theme.cardBackground,
                      ),
                      child: child!,
                    );
                  },
                );
                onPicked(picked);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                range == null ? 'اختيار' : 'تغيير',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            if (range != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () => onPicked(null),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class AddEditHouseDialog extends StatefulWidget {
  final Map<String, dynamic>? house;
  final VoidCallback onSave;

  const AddEditHouseDialog({super.key, this.house, required this.onSave});

  @override
  _AddEditHouseDialogState createState() => _AddEditHouseDialogState();
}

class _AddEditHouseDialogState extends State<AddEditHouseDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isImageUploading = false;
  bool _isLayoutReady = false;

  final List<String> _amenitiesOptions = [
    'حديقة خاصة',
    'عداد كهرباء',
    'عداد مياه',
    'غاز طبيعي',
    'تليفون أرضي',
    'اسانسير',
    'انترنت منزلي',
  ];

  List<String> _selectedAmenities = [];

  // Text editing controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _spaceController = TextEditingController();
  final TextEditingController _rentPriceController = TextEditingController();
  final TextEditingController _insuranceController = TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();

  // Dropdown selections
  String? _selectedZone;
  String? _selectedRoom;
  String? _bathroom;
  String? _floor;
  String? _furnished;
  String? _selectedPeriod;
  String? _presenter;
  String? _contact;
  String? _status;

  // Image data
  List<Uint8List?> _imageBytes = List.filled(7, null);
  List<String> _imageUrls = List.filled(7, '');

  static const String imgbbApiKey = '58ab634078d0d68de4c2c172a6538e84';

  @override
  void initState() {
    super.initState();
    if (widget.house != null) {
      _phoneController.text = widget.house!['phone']?.toString() ?? '';
      _spaceController.text = widget.house!['space']?.toString() ?? '';
      _rentPriceController.text = widget.house!['rent_price']?.toString() ?? '';
      _insuranceController.text = widget.house!['insurance']?.toString() ?? '';
      _periodController.text = widget.house!['period']?.toString() ?? '';
      _notesController.text = widget.house!['notes']?.toString() ?? '';
      _expiryDateController.text = widget.house!['expiry_date']?.toString() ?? '';
      _selectedZone = widget.house!['zone']?.toString();
      _selectedRoom = widget.house!['room']?.toString();
      _bathroom = widget.house!['bathroom']?.toString();
      _floor = widget.house!['floor']?.toString();
      _furnished = widget.house!['furnished']?.toString();
      _selectedPeriod = widget.house!['selected_period']?.toString();
      _presenter = widget.house!['presenter']?.toString();
      _contact = widget.house!['contact']?.toString();
      _status = widget.house!['status']?.toString();
      _selectedAmenities = widget.house!['amenities'] != null
          ? List<String>.from(widget.house!['amenities'])
          : [];
      if (widget.house!['images'] != null) {
        List<dynamic> images = widget.house!['images'];
        for (int i = 0; i < images.length && i < _imageUrls.length; i++) {
          _imageUrls[i] = images[i].toString();
        }
      }
    } else {
      _expiryDateController.text = intl.DateFormat('d/M/yyyy').format(
        DateTime.now().add(const Duration(days: 30)),
      );
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLayoutReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _spaceController.dispose();
    _rentPriceController.dispose();
    _insuranceController.dispose();
    _periodController.dispose();
    _notesController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _uploadImage(int index) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        setState(() => _isImageUploading = true);
        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;
        final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');
        var request = http.MultipartRequest('POST', uri)
          ..fields['name'] = fileName
          ..files.add(http.MultipartFile.fromBytes('image', fileBytes, filename: fileName));
        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);
        if (jsonData['success']) {
          setState(() {
            _imageUrls[index] = jsonData['data']['url'];
            _imageBytes[index] = fileBytes;
          });
        }
        setState(() => _isImageUploading = false);
      }
    } catch (e) {
      setState(() => _isImageUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في رفع الصورة: $e',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveHouse() async {
    if (!_isLayoutReady || !_formKey.currentState!.validate()) return;

    if (_imageUrls.every((url) => url.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى رفع صورة واحدة على الأقل',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final filteredImageUrls = _imageUrls.where((url) => url.isNotEmpty).toList();

      final data = {
        'phone': _phoneController.text.trim(),
        'space': _spaceController.text.isNotEmpty ? int.parse(_spaceController.text) : null,
        'rent_price': int.parse(_rentPriceController.text),
        'insurance':
        _insuranceController.text.isNotEmpty ? int.parse(_insuranceController.text) : null,
        'period': _periodController.text,
        'zone': _selectedZone,
        'room': _selectedRoom != null ? int.parse(_selectedRoom!) : null,
        'bathroom': _bathroom != null ? int.parse(_bathroom!) : null,
        'floor': _floor,
        'furnished': _furnished,
        'amenities': _selectedAmenities,
        'images': filteredImageUrls,
        'selected_period': _selectedPeriod,
        'presenter': _presenter,
        'contact': _contact,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'status': _status,
        'expiry_date': _expiryDateController.text,
      };

      if (widget.house == null) {
        await supabaseConfig.secondaryClient.from('houses').insert(data);
      } else {
        await supabaseConfig.secondaryClient
            .from('houses')
            .update(data)
            .eq('id', widget.house!['id']);
      }

      widget.onSave();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.house == null ? 'تم الإضافة بنجاح' : 'تم التعديل بنجاح',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: ThemeManager().currentTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل في الحفظ: $e',
            style: GoogleFonts.cairo(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager().currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: theme.cardBackground,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.house == null ? 'إضافة شقة' : 'تعديل شقة',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: theme.textColor,
                  fontSize: 20,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: screenWidth * 0.9,
            height: screenHeight * 0.6,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف *',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال رقم الهاتف';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _spaceController,
                      label: 'المساحة (م²) *',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال المساحة';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _rentPriceController,
                      label: 'مبلغ الإيجار *',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال مبلغ الإيجار';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _insuranceController,
                      label: 'مبلغ التأمين *',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال مبلغ التأمين';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _expiryDateController,
                      label: 'تاريخ الانتهاء (يوم/شهر/سنة) *',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال تاريخ الانتهاء';
                        }
                        try {
                          intl.DateFormat('d/M/yyyy').parse(value);
                        } catch (e) {
                          return 'يرجى إدخال تاريخ صالح (يوم/شهر/سنة)';
                        }
                        return null;
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'فترة الإيجار المطلوبة *',
                      value: _periodController.text.isEmpty ? null : _periodController.text,
                      items: [
                        '6 شهور',
                        'سنة',
                        'سنة ونصف',
                        'سنتين',
                        'ثلاث سنوات',
                        'قابل للتفاوض'
                      ],
                      onChanged: (value) => setState(() => _periodController.text = value!),
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'الزوون *',
                      value: _selectedZone,
                      items: List.generate(11, (index) => (index + 1).toString()),
                      onChanged: (value) => setState(() => _selectedZone = value),
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'غرف النوم',
                      value: _selectedRoom,
                      items: List.generate(3, (index) => (index + 1).toString()),
                      onChanged: (value) => setState(() => _selectedRoom = value),
                      theme: theme,
                      isMandatory: false,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'عدد الحمامات',
                      value: _bathroom,
                      items: List.generate(2, (index) => (index + 1).toString()),
                      onChanged: (value) => setState(() => _bathroom = value),
                      theme: theme,
                      isMandatory: false,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'الدور',
                      value: _floor,
                      items: [
                        'الأرضي',
                        'الأول',
                        'الثاني',
                        'الثالث',
                        'الرابع',
                        'الخامس',
                        'السادس'
                      ],
                      onChanged: (value) => setState(() => _floor = value),
                      theme: theme,
                      isMandatory: false,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'مفروشة؟',
                      value: _furnished,
                      items: ['نعم', 'لا'],
                      onChanged: (value) => setState(() => _furnished = value),
                      theme: theme,
                      isMandatory: false,
                    ),
                    const SizedBox(height: 16),
                    _buildMultiSelectionField(theme),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'معدل دفع الإيجار *',
                      value: _selectedPeriod,
                      items: ['يوميًا', 'أسبوعيًا', 'شهريًا', 'سنويًا'],
                      onChanged: (value) => setState(() => _selectedPeriod = value),
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'المعلن *',
                      value: _presenter,
                      items: ['مالك الشقة', 'شركة عقارية'],
                      onChanged: (value) => setState(() => _presenter = value),
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'تفضل التواصل من خلال *',
                      value: _contact,
                      items: ['المستأجر مباشرة فقط', 'المستأجر أو سماسرة'],
                      onChanged: (value) => setState(() => _contact = value),
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      label: 'الحالة *',
                      value: _status,
                      items: ['Active', 'Pending'],
                      onChanged: (value) => setState(() => _status = value),
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _notesController,
                      label: 'ملاحظات',
                      theme: theme,
                      isMandatory: false,
                      minLines: 3,
                      maxLines: null,
                    ),
                    const SizedBox(height: 16),
                    _buildImageUploadSection(isMobile, theme),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isSubmitting || !_isLayoutReady ? null : () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: theme.secondaryTextColor,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isSubmitting || !_isLayoutReady ? null : _saveHouse,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                'حفظ',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required AppTheme theme,
    bool isMandatory = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int minLines = 1,
    int? maxLines,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(
          color: theme.secondaryTextColor,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        errorStyle: GoogleFonts.cairo(
          color: Colors.red,
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      style: GoogleFonts.cairo(
        color: theme.textColor,
        fontSize: 16,
      ),
      validator: validator ??
          (isMandatory
              ? (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label مطلوب';
            }
            return null;
          }
              : null),
      minLines: minLines,
      maxLines: maxLines,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required AppTheme theme,
    bool isMandatory = true,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(
          color: theme.secondaryTextColor,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: GoogleFonts.cairo(
          color: Colors.red,
          fontSize: 12,
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(
        value: item,
        child: Text(
          item,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: theme.textColor,
          ),
        ),
      ))
          .toList(),
      onChanged: _isLayoutReady ? onChanged : null,
      style: GoogleFonts.cairo(
        fontSize: 14,
        color: theme.textColor,
      ),
      icon: FaIcon(
        FontAwesomeIcons.arrowDown,
        color: theme.primaryColor,
        size: 16,
      ),
      validator: isMandatory
          ? (value) {
        if (value == null) {
          return '$label مطلوب';
        }
        return null;
      }
          : null,
    );
  }

  Widget _buildMultiSelectionField(dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الملحقات والمرافق',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _amenitiesOptions.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return ChoiceChip(
              label: Text(
                amenity,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : theme.textColor,
                ),
              ),
              selected: isSelected,
              selectedColor: theme.primaryColor,
              backgroundColor: theme.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.primaryColor.withOpacity(0.2)),
              ),
              onSelected: _isLayoutReady
                  ? (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
              }
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection(bool isMobile, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صور الشقة (اختر صورة واحدة على الأقل، بحد أقصى 7 صور) *',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_imageUrls.length, (index) {
            return GestureDetector(
              onTap: _isImageUploading ? null : () => _uploadImage(index),
              child: Container(
                width: isMobile ? 80 : 100,
                height: isMobile ? 80 : 100,
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      theme.cardBackground,
                      theme.cardBackground.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _imageUrls[index].isEmpty
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isImageUploading
                        ? CircularProgressIndicator(
                      color: theme.primaryColor,
                      strokeWidth: 2,
                    )
                        : FaIcon(
                      FontAwesomeIcons.camera,
                      color: theme.primaryColor,
                      size: isMobile ? 20 : 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'إضافة',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 10 : 12,
                        color: theme.secondaryTextColor,
                      ),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _imageUrls[index],
                    fit: BoxFit.cover,
                    width: isMobile ? 80 : 100,
                    height: isMobile ? 80 : 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}