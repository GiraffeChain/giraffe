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
  @override
  Map<String, dynamic> toJson() {
    return {
      "status": "running",
    };
  }
}

class SimulationStatus_Completed extends SimulationStatus {
  @override
  Map<String, dynamic> toJson() {
    return {
      "status": "completed",
    };
  }
}
