import 'models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PersonRepository {
  final String baseUrl = 'http://localhost:3000/api/persons';

  Future<void> add(Person person) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(person.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Misslyckades att lägga till person');
    }
  }

  Future<List<Person>> getAll() async {
    final response = await http.get(Uri.parse(baseUrl));

    print('DEBUG: Response status code: ${response.statusCode}');
  print('DEBUG: Response body: ${response.body}');

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      print('DEBUG: Parsed data: $data'); // Se vad som faktiskt parsas
      
      return data.map((e) => Person.fromJson(e)).toList();
    } else {
      throw Exception('Misslyckades att hämta personer');
    }
  }

  Future<Person?> getPersonById(String personalNumber) async {
    final response = await http.get(Uri.parse('$baseUrl/$personalNumber'));
    if (response.statusCode == 200) {
      return Person.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<void> update(Person person) async {
    final response = await http.put(
      Uri.parse('$baseUrl/${person.personalNumber}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(person.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Misslyckades att uppdatera person');
    }
  }

  Future<void> delete(String personalNumber) async {
    final response = await http.delete(Uri.parse('$baseUrl/$personalNumber'));
    if (response.statusCode != 200) {
      throw Exception('Misslyckades att radera person');
    }
  }
}

class VehicleRepository {
  final List<Vehicle> _vehicles = [];

  void add(Vehicle vehicle) => _vehicles.add(vehicle);

  Future<List<Vehicle>> getAll() async {
    await Future.delayed(Duration(seconds: 1));
    return _vehicles;
  }

  Vehicle? getVehicleById(String registrationNumber) {
    try {
      return _vehicles
          .firstWhere((v) => v.registrationNumber == registrationNumber);
    } catch (e) {
      return null;
    }
  }

  void update(Vehicle updatedVehicle) {
    int index = _vehicles.indexWhere(
        (v) => v.registrationNumber == updatedVehicle.registrationNumber);
    if (index != -1) _vehicles[index] = updatedVehicle;
  }

  void delete(String registrationNumber) =>
      _vehicles.removeWhere((v) => v.registrationNumber == registrationNumber);
}

class ParkingSpaceRepository {
  final List<ParkingSpace> _spaces = [];

  void add(ParkingSpace space) => _spaces.add(space);
  List<ParkingSpace> getAll() => _spaces;
  ParkingSpace? getSpaceById(String id) {
    try {
      return _spaces.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  void update(ParkingSpace updatedSpace) {
    int index = _spaces.indexWhere((s) => s.id == updatedSpace.id);
    if (index != -1) _spaces[index] = updatedSpace;
  }

  void delete(String id) => _spaces.removeWhere((s) => s.id == id);
}

class ParkingSessionRepository {
  final List<ParkingSession> _parkings = [];

  void add(ParkingSession parking) => _parkings.add(parking);
  List<ParkingSession> getAll() => _parkings;
  ParkingSession? getActiveParkingByRegistration(String registrationNumber) {
    try {
      return _parkings.firstWhere((p) =>
          p.vehicle.registrationNumber == registrationNumber &&
          p.endTime == null);
    } catch (e) {
      return null;
    }
  }

  bool update(String registrationNumber,
      {DateTime? newEndTime, bool endParking = false}) {
    var parking = getActiveParkingByRegistration(registrationNumber);

    if (parking == null) return false;

    if (endParking) {
      parking.endTime = DateTime.now();
    } else if (newEndTime != null) {
      parking.endTime = newEndTime;
    }

    return true;
  }

  bool delete(String registrationNumber) {
    int initialCount = _parkings.length;
    _parkings
        .removeWhere((p) => p.vehicle.registrationNumber == registrationNumber);
    return _parkings.length < initialCount;
  }
}
