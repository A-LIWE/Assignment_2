import 'models.dart';

class PersonRepository {
  final List<Person> _people = [];

  void add(Person person) => _people.add(person);

  List<Person> getAll() => _people;

 Person? getPersonById(String personalNumber) {
  try {
    return _people.firstWhere((p) => p.personalNumber == personalNumber);
  } catch (e) {
    return null;
  }
}
  void update(Person updatedPerson) {
    int index = _people
        .indexWhere((p) => p.personalNumber == updatedPerson.personalNumber);
    if (index != -1) _people[index] = updatedPerson;
  }
  void delete(String personalNumber) => _people.removeWhere((p) => p.personalNumber == personalNumber);
}

class VehicleRepository {
  final List<Vehicle> _vehicles = [];

  void add (Vehicle vehicle) => _vehicles.add(vehicle);
  List <Vehicle> getAll() => _vehicles;
  Vehicle? getVehicleById(String registrationNumber) {
  try {
    return _vehicles.firstWhere((v) => v.registrationNumber == registrationNumber);
  } catch (e) {
    return null;
  } 
}
void update(Vehicle updatedVehicle){
  int index = _vehicles
       .indexWhere((v) => v.registrationNumber == updatedVehicle.registrationNumber);
       if (index != -1) _vehicles [index] =updatedVehicle;
}
void delete (String registrationNumber) => _vehicles.removeWhere((v) => v.registrationNumber == registrationNumber);
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
    return _parkings.firstWhere((p) => p.vehicle.registrationNumber == registrationNumber && p.endTime == null);
  } catch (e) {
    return null;
  } 
}
  bool update(String registrationNumber, {DateTime? newEndTime, bool endParking = false}) {
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
    _parkings.removeWhere((p) => p.vehicle.registrationNumber == registrationNumber);
    return _parkings.length < initialCount;
  }
}