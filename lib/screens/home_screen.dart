import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/alarm_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AlarmModel> alarms = [];
  int _alarmIdCounter = 0;

  Timer? _timer;
  AlarmModel? _ringingAlarm;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startAlarmChecker();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startAlarmChecker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();

      if (_ringingAlarm != null) return; // Already ringing

      for (var alarm in alarms) {
        if (alarm.isActive &&
            alarm.time.year == now.year &&
            alarm.time.month == now.month &&
            alarm.time.day == now.day &&
            alarm.time.hour == now.hour &&
            alarm.time.minute == now.minute) {
          _triggerAlarm(alarm);
          break;
        }
      }
    });
  }

  Future<void> _triggerAlarm(AlarmModel alarm) async {
    setState(() {
      _ringingAlarm = alarm;
    });

    // Play alarm sound (make sure you add your own file in assets)
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('alarm_sound.mp3'), volume: 1.0);

    // Show dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => AlertDialog(
              title: const Text('Alarm ringing!'),
              content: Text('Alarm for ${_formatDateTime(alarm.time)}'),
              actions: [
                TextButton(
                  onPressed: () {
                    _snoozeAlarm();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Snooze'),
                ),
                TextButton(
                  onPressed: () {
                    _dismissAlarm();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Dismiss'),
                ),
              ],
            ),
      );
    }
  }

  void _snoozeAlarm() {
    if (_ringingAlarm == null) return;
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    setState(() {
      _ringingAlarm!.time = snoozeTime;
      _ringingAlarm = null;
    });
    _audioPlayer.stop();
  }

  void _dismissAlarm() {
    if (_ringingAlarm == null) return;
    setState(() {
      _ringingAlarm!.isActive = false;
      _ringingAlarm = null;
    });
    _audioPlayer.stop();
  }

  void _addAlarm() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      DateTime alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      final newAlarm = AlarmModel(
        id: _alarmIdCounter++,
        time: alarmTime,
        tone: 'default',
      );

      setState(() {
        alarms.add(newAlarm);
      });
    }
  }

  void _toggleAlarm(AlarmModel alarm, bool active) {
    setState(() {
      alarm.isActive = active;
    });
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('hh:mm a • EEE, MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final time = DateFormat('hh:mm:ss a').format(now);
    final date = DateFormat('EEE, MMM d').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Clock'),
        backgroundColor: const Color.fromARGB(255, 136, 6, 217),
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Text(time, style: Theme.of(context).textTheme.displayMedium),
          Text(date, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          Expanded(
            child:
                alarms.isEmpty
                    ? const Center(child: Text('No alarms set'))
                    : ListView.builder(
                      itemCount: alarms.length,
                      itemBuilder: (context, index) {
                        final alarm = alarms[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.alarm,
                              color: Colors.deepPurple,
                            ),
                            title: Text(_formatDateTime(alarm.time)),
                            subtitle: Text('Tone: ${alarm.tone}'),
                            trailing: Switch(
                              value: alarm.isActive,
                              onChanged: (value) => _toggleAlarm(alarm, value),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromARGB(255, 186, 158, 234),
        onPressed: _addAlarm,
        label: const Text('Add Alarm'),
        icon: const Icon(Icons.add_alarm),
      ),
    );
  }
}
