import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../services/shastra_sync_service.dart';

class AdminPanchangamSyncScreen extends StatefulWidget {
  const AdminPanchangamSyncScreen({Key? key}) : super(key: key);

  @override
  _AdminPanchangamSyncScreenState createState() => _AdminPanchangamSyncScreenState();
}

class _AdminPanchangamSyncScreenState extends State<AdminPanchangamSyncScreen> {
  final PanchangamSyncService _syncService = PanchangamSyncService();
  String _selectedCity = 'chennai';
  int _selectedYear = 2027;
  bool _syncFestivals = true;
  bool _syncPanchangam = false;

  bool _isLoading = false;
  SyncPreviewResult? _previewResult;
  String? _statusMessage;

  void _fetchPreview() async {
    setState(() {
      _isLoading = true;
      _previewResult = null;
      _statusMessage = null;
    });

    try {
      if (_syncFestivals) {
        _previewResult = await _syncService.previewFestivals(_selectedCity, _selectedYear);
      }
    } catch (e) {
      _statusMessage = 'Error fetching preview: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmSync() async {
    if (_previewResult == null) return;
    
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    bool success = await _syncService.commitSync(_previewResult!, 'festivals');
    
    setState(() {
      _isLoading = false;
      if (success) {
        _statusMessage = 'SUCCESS: Successfully synced ${_previewResult!.pendingInserts.length} inserts and ${_previewResult!.pendingUpdates.length} updates.';
        _previewResult = null;
      } else {
        _statusMessage = 'PARTIAL/FAILED: Error committing sync.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TNT Panchangam Sync', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TNTColors.primary)),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'chennai', child: Text('Chennai')),
                    DropdownMenuItem(value: 'coimbatore', child: Text('Coimbatore')),
                    DropdownMenuItem(value: 'bengaluru', child: Text('Bengaluru')),
                  ],
                  onChanged: (val) => setState(() => _selectedCity = val!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                  items: [2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                  onChanged: (val) => setState(() => _selectedYear = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          const Text('Data to Sync:', style: TextStyle(fontWeight: FontWeight.bold)),
          CheckboxListTile(
            title: const Text('Festivals (Shastra API)'),
            value: _syncFestivals,
            onChanged: (val) => setState(() => _syncFestivals = val!),
            activeColor: TNTColors.primary,
          ),
          CheckboxListTile(
            title: const Text('Panchangam & Timings (Navamsha API - TBD)'),
            value: _syncPanchangam,
            onChanged: (val) => setState(() => _syncPanchangam = val!),
            activeColor: TNTColors.primary,
          ),
          
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.preview),
            label: const Text('Fetch Preview'),
            style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary, foregroundColor: Colors.white),
            onPressed: _isLoading ? null : _fetchPreview,
          ),
          
          if (_statusMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              color: _statusMessage!.contains('SUCCESS') ? Colors.green.shade100 : Colors.red.shade100,
              child: Text(_statusMessage!, style: TextStyle(color: _statusMessage!.contains('SUCCESS') ? Colors.green.shade900 : Colors.red.shade900)),
            ),
          ],
          
          if (_previewResult != null) ...[
            const SizedBox(height: 30),
            const Text('Preview Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fetched API Records: ${_previewResult!.fetched}'),
                    Text('Valid for $_selectedYear: ${_previewResult!.valid}'),
                    const Divider(),
                    Text('New Records (to insert): ${_previewResult!.newRecords}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    Text('Updated Records: ${_previewResult!.updatedRecords}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    Text('Skipped (unchanged): ${_previewResult!.skipped}'),
                    Text('Errors: ${_previewResult!.errors}', style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _previewResult = null),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _confirmSync,
                  child: const Text('Confirm Sync'),
                ),
              ],
            )
          ],
        ],
      ),
    );
  }
}
