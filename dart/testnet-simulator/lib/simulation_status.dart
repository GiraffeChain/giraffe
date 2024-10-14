import 'simulation_record.dart';

abstract class SimulationStatus {
  const SimulationStatus();

  Map<String, dynamic> toJson();
}

class SimulationStatus_Initializing extends SimulationStatus {
  @override
  Map<String, dynamic> toJson() {
    return {
      "status": "initializing",
    };
  }
}

class SimulationStatus_Running extends SimulationStatus {
  final List<SimulationRecord> records;

  const SimulationStatus_Running({required this.records}) : super();

  @override
  Map<String, dynamic> toJson() {
    return {
      "status": "running",
      "records": records.map((r) => r.toJson()).toList(),
    };
  }
}

class SimulationStatus_Completed extends SimulationStatus {
  final List<SimulationRecord> records;

  const SimulationStatus_Completed({required this.records}) : super();
  @override
  Map<String, dynamic> toJson() {
    return {
      "status": "completed",
      "records": records.map((r) => r.toJson()).toList(),
    };
  }
}
