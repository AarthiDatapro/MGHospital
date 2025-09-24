import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:excel/excel.dart' as excel_package;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Endometrium adjuvant treatment calculator',
      theme: ThemeData(
        fontFamily: GoogleFonts.lato().fontFamily,
        textTheme: GoogleFonts.latoTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFF9A8D4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Color(0xFFFFF1F5),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => RiskCalculatorScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8BBD9), // Baby pink background
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 7, // 70% of available space
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1), // 10% left and right margin
                child: Center(
                  child: Image.asset(
                    'assets/doctorsBehind.jpeg',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.image_not_supported,
                          size: 100,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3, // 30% for bottom section
              child: Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Validated by Dr. Priyalice',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Optional: Add a loading indicator
                    Container(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFC5187)),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class RiskCalculatorScreen extends StatefulWidget {
  @override
  _RiskCalculatorScreenState createState() => _RiskCalculatorScreenState();
}


class _RiskCalculatorScreenState extends State<RiskCalculatorScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, String>> csvData = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Dropdown options
  List<String> ages = [];
  List<String> lvsiStatuses = [];
  List<String> grades = [];
  List<String> molecularSubtypes = [];
  List<String> stages = [];
  List<String> riskGroups = [];

  // Selected values
  String? selectedAge;
  String? selectedLVSI;
  String? selectedGrade;
  String? selectedSubtype;
  String? selectedStage;
  String? selectedRisk;

  // Result
  String? recurrenceRisk;
  String? therapyAdvised;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    loadExcelData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadExcelData() async {
    try {
      final ByteData data = await rootBundle.load('assets/data.xlsx');
      final bytes = data.buffer.asUint8List();
      final excel = excel_package.Excel.decodeBytes(bytes);
      final sheet = excel.tables.keys.first;
      final table = excel.tables[sheet]!;
      if (table.rows.isEmpty) {
        print("⚠️ Excel file is empty");
        return;
      }
      final headers = table.rows[0].map((cell) => cell?.value?.toString().trim() ?? '').toList();
      print("📋 Headers: $headers");
      csvData.clear();
      for (var i = 1; i < table.rows.length; i++) {
        try {
          final row = table.rows[i];
          final rowData = <String, String>{};
          for (var j = 0; j < headers.length && j < row.length; j++) {
            final cellValue = row[j]?.value?.toString().trim() ?? '';
            if (cellValue.isNotEmpty) {
              rowData[headers[j]] = cellValue;
            }
          }
          if (rowData.isNotEmpty) {
            csvData.add(rowData);
          }
        } catch (e) {
          print("⚠️ Error processing row ${i + 1}: $e");
        }
      }
      setState(() {
        ages = _getUniqueValues('Age');
        lvsiStatuses = _getUniqueValues('LVSI Status');
        grades = _getUniqueValues('Grade');
        molecularSubtypes = _getUniqueValues('Molecular Subtype');
        stages = _getUniqueValues('Stage');
        riskGroups = _getUniqueValues('Risk Group');
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      print("❌ Error loading CSV: $e");
      setState(() => isLoading = false);
    }
  }

  List<String> _getUniqueValues(String column) {
    try {
      if (csvData.isEmpty) {
        print("⚠️ No data available when getting unique values for column: $column");
        return [];
      }
      final values = csvData
          .map((e) => e[column]?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      print("📊 Found ${values.length} unique values for $column: $values");
      return values;
    } catch (e) {
      print("⚠️ Error getting unique values for $column: $e");
      return [];
    }
  }

  void getResult() {
    if (selectedAge == null || selectedLVSI == null || selectedGrade == null ||
        selectedSubtype == null || selectedStage == null) {
      _showErrorDialog('Please select all options before getting results.');
      return;
    }

    var match = csvData.where((row) =>
        row['Age'] == selectedAge &&
        row['LVSI Status'] == selectedLVSI &&
        row['Grade'] == selectedGrade &&
        row['Molecular Subtype'] == selectedSubtype &&
        row['Stage'] == selectedStage).toList();

    setState(() {
      if (match.isNotEmpty) {
        recurrenceRisk = match.first['Estimated Recurrence Risk'] ?? 'Not available';
        therapyAdvised = match.first['Therapy Advised'] ?? 'Not available';
        selectedRisk = match.first['Risk Group'] ?? 'Not available';
      } else {
        recurrenceRisk = "No results found";
        therapyAdvised = "No therapy recommendation available";
        selectedRisk = 'Not available';
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEC4899)),
            SizedBox(width: 8),
            Text('Alert', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(message, style: TextStyle(color: Color(0xFF475569), fontSize: 15, fontWeight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFFF472B6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('OK', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }


  Widget _labelWithIcon(String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(left: 0, right: 0, top: 0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFFE4EF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Color(0xFFF06292), size: 18),
          ),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildDropdown(
  String label,
  List<String> items,
  String? selected,
  void Function(String?) onChanged,
  IconData icon,
  Color iconColor,
) {
  return Container(
    margin: EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF000000).withOpacity(0.05),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Padding(
      padding: EdgeInsets.all(20), // padding for the whole container
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelWithIcon(label, icon),
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: DropdownButtonFormField2<String>(
              isExpanded: true,
              value: selected,
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Color(0xFFE9E9EA), width: 1.2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Color(0xFFE9E9EA), width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Color(0xFFE9E9EA), width: 1.2),
                ),
                filled: true,
                fillColor: Color(0xFFFDFDFD),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                hintText: 'Select $label',
                hintStyle: TextStyle(
                    color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              ),
              hint: Text(
                'Select $label',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),

              // 👇 Dropdown menu customization
              dropdownStyleData: DropdownStyleData(
                // Let dropdown match the button width for better alignment
                // width: defaults to button width when not specified
                maxHeight: MediaQuery.of(context).size.height * 0.4, // 40% height
                offset: const Offset(0, 8), // small gap below the button
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
              ),
              menuItemStyleData: MenuItemStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              iconStyleData: IconStyleData(
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF64748B)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF1F5),
      body: isLoading 
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFC5187),
                    Color(0xFFFF6377),
                    Color(0xFFFF8696),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Loading By Scope...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFC5187),
                    Color(0xFFFF6377),
                    Color(0xFFFF8696),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          width: 82,
                                          height: 72,
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(0),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 8,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.asset(
                                              'assets/logo.jpeg', 
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.local_hospital_outlined,
                                                  size: 36,
                                                  color: Color(0xFF475569),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
  child: Text(
    "Endometrium adjuvant treatment calculator",
    style: TextStyle(
      fontSize: 20,
      color: Colors.white.withOpacity(0.9),
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
    maxLines: 2,           // allows wrapping
    overflow: TextOverflow.visible,
    softWrap: true,        // enables auto line break
  ),
),
                                      ],
                                    ),
                                  ),
                                  
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 0),
                          ),
                          Container(
                            padding: EdgeInsets.all(0),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [],
                            ),
                            child: Column(
                              children: [
                                _buildDropdown("Age", ages, selectedAge, (val) => setState(() => selectedAge = val), Icons.person_outline, Color(0xFF475569)),
                                _buildDropdown("LVSI Status", lvsiStatuses, selectedLVSI, (val) => setState(() => selectedLVSI = val), Icons.bloodtype_outlined, Color(0xFF475569)),
                                _buildDropdown("Grade", grades, selectedGrade, (val) => setState(() => selectedGrade = val), Icons.workspace_premium_outlined, Color(0xFF475569)),
                                _buildDropdown("Molecular Subtype", molecularSubtypes, selectedSubtype, (val) => setState(() => selectedSubtype = val), Icons.science_outlined, Color(0xFF475569)),
                                _buildDropdown("Stage", stages, selectedStage, (val) => setState(() => selectedStage = val), Icons.flag_outlined, Color(0xFF475569)),
                                SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF000000).withOpacity(0.08),
                                        blurRadius: 12,
                                        offset: Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: getResult,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFFC5187),
                    Color(0xFFFF6377),
                    Color(0xFFFF8696),],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.calculate_outlined, color: Colors.white, size: 22),
                                            SizedBox(width: 12),
                                            Text(
                                              "Generate Prediction",
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 0.2,
                                                
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Replace the result cards section (starting from "if (recurrenceRisk != null && therapyAdvised != null)")
// with this improved version:
// Replace the result cards section (starting from "if (recurrenceRisk != null && therapyAdvised != null)")
// with this improved version:

if (recurrenceRisk != null && therapyAdvised != null)
  Container(
    margin: EdgeInsets.only(top: 24),
    child: Column(
      children: [
        // Compact Header
        Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFC5187),
                    Color(0xFFFF6377),
                    Color(0xFFFF8696),],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFF472B6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.assessment_outlined, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                "Assessment Results",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),

        // First Row - Risk Group and Recurrence Risk
        Row(
          children: [
            // Risk Group
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF000000).withOpacity(0.04),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFDCFDF7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.health_and_safety_outlined, color: Color(0xFF059669), size: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Risk Group',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      selectedRisk ?? 'N/A',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            // Recurrence Risk  
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF000000).withOpacity(0.04),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.trending_up_outlined, color: Color(0xFFD97706), size: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Recurrence Risk',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      recurrenceRisk ?? 'N/A',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        // Second Row - Therapy (Full Width)
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF000000).withOpacity(0.04),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.healing_outlined, color: Color(0xFF7C3AED), size: 20),
              ),
              SizedBox(height: 12),
              Text(
                'Recommended Therapy',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFC5187),
                    Color(0xFFFF6377),
                    Color(0xFFFF8696),],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFDDD6FE), width: 1),
                ),
                child: Text(
                  therapyAdvised ?? 'Not available',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF5B21B6)),
                  textAlign: TextAlign.center,
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
                  ),
                ],
              ),
            ),
    );
  }
}