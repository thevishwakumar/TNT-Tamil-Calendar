import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../models/horoscope_model.dart';
import '../services/horoscope_service.dart';

class JathagamScreen extends StatefulWidget {
  final String initialRasiId;
  final String initialNakshatraId;
  final int initialPada;

  const JathagamScreen({
    super.key,
    this.initialRasiId = 'mesham',
    this.initialNakshatraId = 'ashwini',
    this.initialPada = 1,
  });

  @override
  State<JathagamScreen> createState() => _JathagamScreenState();
}

class _JathagamScreenState extends State<JathagamScreen> {
  late String _selectedRasiId;
  late String _selectedNakshatraId;
  late int _selectedPada;
  final DateTime _selectedDate = DateTime(2026, 9, 28);
  DailyHoroscopeReading? _reading;
  bool _isLoading = false;
  final String _activeCategory = 'all';

  @override
  void initState() {
    super.initState();
    _selectedRasiId = widget.initialRasiId;
    _selectedNakshatraId = widget.initialNakshatraId;
    _selectedPada = widget.initialPada;
    _fetchHoroscope();
  }

  Future<void> _fetchHoroscope() async {
    setState(() => _isLoading = true);
    final reading = await HoroscopeService.getDailyHoroscope(
      rasiId: _selectedRasiId,
      nakshatraId: _selectedNakshatraId,
      pada: _selectedPada,
      date: _selectedDate,
    );
    setState(() {
      _reading = reading;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rasis = HoroscopeService.rasis;
    final activeRasi = rasis.firstWhere((r) => r.id == _selectedRasiId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ஜாதகம் & தினசரி ராசிபலன்'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [ const TNTBrandHeader(), 
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHoroscope,
            tooltip: 'புதுப்பி',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rasi Horizontal Selector
            Text(
              'ராசியைத் தேர்ந்தெடுக்கவும்',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: rasis.length,
                itemBuilder: (context, idx) {
                  final rasi = rasis[idx];
                  final isSelected = rasi.id == _selectedRasiId;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRasiId = rasi.id;
                        _selectedNakshatraId = rasi.nakshatras.first.id;
                        _selectedPada = 1;
                      });
                      _fetchHoroscope();
                    },
                    child: Container(
                      width: 76,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.amber.shade50 : Colors.white,
                        border: Border.all(
                          color: isSelected ? Colors.amber.shade600 : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(rasi.symbol, style: const TextStyle(fontSize: 18)),
                          Text(
                            rasi.nameTa,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.amber.shade900 : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Nakshatra Dropdown & Pada Selector
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedNakshatraId,
                    decoration: InputDecoration(
                      labelText: 'நட்சத்திரம்',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: activeRasi.nakshatras.map((n) {
                      return DropdownMenuItem(
                        value: n.id,
                        child: Text(n.nameTa, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedNakshatraId = val);
                        _fetchHoroscope();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedPada,
                    decoration: InputDecoration(
                      labelText: 'பாதம்',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [1, 2, 3, 4].map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('$p-ஆம் பாதம்', style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPada = val);
                        _fetchHoroscope();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reading Content
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_reading != null) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.amber.shade50,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_reading!.rasiNameTa} · ${_reading!.nakshatraNameTa}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown),
                              ),
                              Text(
                                'அதிபதி: ${activeRasi.lordTa} | தத்துவம்: ${activeRasi.elementTa}',
                                style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_reading!.luckyPercentage}% சுபம்',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        _reading!.generalPredictionTa,
                        style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Category predictions and Lucky elements
            ],
          ],
        ),
      ),
    );
  }
}
