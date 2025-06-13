class AlarmModel {
  final int id;
  DateTime time; // give date and time
  final String tone;
  bool isActive;

  AlarmModel({
    required this.id,
    required this.time,
    required this.tone,
    this.isActive = true,
  });
}
