import 'package:tnt_tamil_calendar/widgets/tnt_brand_header.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../services/supabase_service.dart';
import '../models/personal_event_model.dart';
import '../repositories/personal_event_repository.dart';
import '../widgets/personal_event_form.dart';


class PersonalCalendarScreen extends StatefulWidget {
  const PersonalCalendarScreen({super.key});

  @override
  State<PersonalCalendarScreen> createState() => _PersonalCalendarScreenState();
}

class _PersonalCalendarScreenState extends State<PersonalCalendarScreen> {
  final PersonalEventRepository _repository = PersonalEventRepository();
  DateTime _selectedDate = DateTime.now();
  List<PersonalEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final events = await _repository.getEventsForMonth(_selectedDate.year, _selectedDate.month);
    if (mounted) {
      setState(() {
        _events = events;
        _isLoading = false;
      });
    }
  }

  List<PersonalEvent> _getEventsForSelectedDate() {
    return _events.where((e) => 
      e.startTime.year == _selectedDate.year &&
      e.startTime.month == _selectedDate.month &&
      e.startTime.day == _selectedDate.day
    ).toList();
  }

  Future<void> _addEvent() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TNTColors.surface,
      builder: (ctx) => PersonalEventForm(
        initialDate: _selectedDate,
        onSaved: _loadEvents,
      ),
    );
  }

  void _editEvent(PersonalEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TNTColors.surface,
      builder: (ctx) => PersonalEventForm(
        initialDate: _selectedDate,
        existingEvent: event,
        onSaved: _loadEvents,
      ),
    );
  }

  Future<void> _deleteEvent(PersonalEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true) {
      await _repository.deleteEvent(event.id);
      _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyEvents = _getEventsForSelectedDate();

    return Scaffold(
      backgroundColor: TNTColors.background,
      appBar: AppBar(
        title: const Text('My Calendar'),
        backgroundColor: TNTColors.surface,
        actions: [ const TNTBrandHeader(), 
          IconButton(icon: const Icon(Icons.add), onPressed: _addEvent),
        ],
      ),
      body: Column(
        children: [
          // Basic Month/Day Selector
          Container(
            color: TNTColors.surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
                    });
                    _loadEvents();
                  },
                ),
                Text(
                  '${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
                    });
                    _loadEvents();
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : dailyEvents.isEmpty
                ? const Center(child: Text('No events for this day.'))
                : ListView.builder(
                    itemCount: dailyEvents.length,
                    itemBuilder: (context, index) {
                      final e = dailyEvents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(e.title),
                          subtitle: Text('${e.startTime.hour}:${e.startTime.minute.toString().padLeft(2, '0')}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _repository.deleteEvent(e.id);
                              _loadEvents();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
