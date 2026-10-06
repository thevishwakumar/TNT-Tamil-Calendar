import os

form_code = '''import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../services/supabase_service.dart';
import '../models/personal_event_model.dart';
import '../repositories/personal_event_repository.dart';

class PersonalEventForm extends StatefulWidget {
  final DateTime initialDate;
  final PersonalEvent? existingEvent;
  final VoidCallback onSaved;

  const PersonalEventForm({
    Key? key,
    required this.initialDate,
    this.existingEvent,
    required this.onSaved,
  }) : super(key: key);

  @override
  _PersonalEventFormState createState() => _PersonalEventFormState();
}

class _PersonalEventFormState extends State<PersonalEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _repository = PersonalEventRepository();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _isAllDay = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final ev = widget.existingEvent;
    _titleController = TextEditingController(text: ev?.title ?? '');
    _descController = TextEditingController(text: ev?.description ?? '');
    _startDate = ev?.startTime ?? widget.initialDate;
    _endDate = ev?.endTime ?? widget.initialDate;
    _startTime = ev != null ? TimeOfDay.fromDateTime(ev.startTime) : const TimeOfDay(hour: 9, minute: 0);
    _endTime = ev != null ? TimeOfDay.fromDateTime(ev.endTime) : const TimeOfDay(hour: 10, minute: 0);
    _isAllDay = ev?.isAllDay ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initTime = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final sDt = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
    final eDt = DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);
    
    if (!sDt.isBefore(eDt) && !_isAllDay) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = SupabaseService().client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final ev = PersonalEvent(
        id: widget.existingEvent?.id ?? '',
        userId: user.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        startTime: sDt,
        endTime: eDt,
        isAllDay: _isAllDay,
        timezone: 'Asia/Kolkata',
        category: widget.existingEvent?.category ?? 'Personal',
        isCompleted: widget.existingEvent?.isCompleted ?? false,
      );

      if (widget.existingEvent != null) {
        await _repository.updateEvent(ev);
      } else {
        await _repository.createEvent(ev);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existingEvent == null ? 'Add Event' : 'Edit Event',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('All Day'),
                value: _isAllDay,
                onChanged: (val) => setState(() => _isAllDay = val),
              ),
              Row(
                children: [
                  Expanded(child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text('\/\/\'),
                    onTap: () => _pickDate(true),
                  )),
                  if (!_isAllDay) Expanded(child: ListTile(
                    title: const Text('Start Time'),
                    subtitle: Text(_startTime.format(context)),
                    onTap: () => _pickTime(true),
                  )),
                ],
              ),
              Row(
                children: [
                  Expanded(child: ListTile(
                    title: const Text('End Date'),
                    subtitle: Text('\/\/\'),
                    onTap: () => _pickDate(false),
                  )),
                  if (!_isAllDay) Expanded(child: ListTile(
                    title: const Text('End Time'),
                    subtitle: Text(_endTime.format(context)),
                    onTap: () => _pickTime(false),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: TNTColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SAVE EVENT'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
'''

os.makedirs(r'C:\Users\Vishw\Downloads\TNT\lib\features\personal_calendar\widgets', exist_ok=True)
with open(r'C:\Users\Vishw\Downloads\TNT\lib\features\personal_calendar\widgets\personal_event_form.dart', 'w', encoding='utf-8') as f:
    f.write(form_code)

path = r'C:\Users\Vishw\Downloads\TNT\lib\features\personal_calendar\screens\personal_calendar_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

import_form = "import '../widgets/personal_event_form.dart';\n"
if import_form not in code:
    code = code.replace("import '../repositories/personal_event_repository.dart';", "import '../repositories/personal_event_repository.dart';\n" + import_form)

old_add = '''Future<void> _addEvent() async {
    final user = SupabaseService().client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }
    
    // In a full implementation, this opens a form. For now, it inserts a mock event.
    final newEvent = PersonalEvent(
      id: '',
      userId: user.id,
      title: 'New Personal Event',
      startTime: _selectedDate,
      endTime: _selectedDate.add(const Duration(hours: 1)),
      isAllDay: false,
      timezone: 'Asia/Kolkata',
      category: 'Personal',
      isCompleted: false,
    );
    
    await _repository.createEvent(newEvent);
    _loadEvents();
  }'''

new_add = '''Future<void> _addEvent() async {
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
  }'''

code = code.replace(old_add, new_add)

# Make list tiles tappable
code = code.replace(
'''return ListTile(
                        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(timeStr),
                        leading: Container(width: 4, color: TNTColors.primary),
                      );''',
'''return ListTile(
                        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(timeStr),
                        leading: Container(width: 4, color: TNTColors.primary),
                        onTap: () => _editEvent(event),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteEvent(event)),
                      );'''
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Form added and screen patched.")
