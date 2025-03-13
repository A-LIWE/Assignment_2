import 'package:uuid/uuid.dart';

class Person {
  String uuid;
  String name;
  String personalNumber;

  Person(this.name, this.personalNumber) : uuid = Uuid().v4();

  Map<String, dynamic> toJson() => {
        'name': name,
        'personal_number': personalNumber,
      };

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      json['name'],
      json['personal_number'],
    );
  }

  @override
  String toString() => '\nNamn: $name \nPersonnummer: $personalNumber';

  bool isValid() {
    return _isValidName() && _isValidPersonalNumber();
  }

  bool _isValidName() {
    return name.isNotEmpty;
  }

  bool _isValidPersonalNumber() {
    final regex = RegExp(r'^\d{6,8}-?\d{4}$');
    return regex.hasMatch(personalNumber);
  }
}

class Vehicle {
  String uuid;
  String registrationNumber;
  String vehicleType;
  Person? owner; // 🔥 Kan nu vara null

  Vehicle(this.registrationNumber, this.vehicleType, this.owner)
      : uuid = Uuid().v4();

  Map<String, dynamic> toJson() => {
        'registration_number': registrationNumber,
        'vehicle_type': vehicleType,
        // 🔥 Lägg till ägaren om den inte är null
        if (owner != null) 'owner': owner!.toJson(),
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // 🔍 Hämta ev. ägarobjekt ur JSON
    final ownerJson = json['owner'];
    Person? person;

    // Om `owner` är en Map -> parse:ar vi den med Person.fromJson(...)
    // Om inte -> owner blir null
    if (ownerJson is Map<String, dynamic>) {
      person = Person.fromJson(ownerJson);
    } else {
      person = null;
    }

    return Vehicle(
      json['registration_number'],
      json['vehicle_type'],
      person,
    );
  }

  @override
  String toString() =>
      '\nRegnr: $registrationNumber \nFordonstyp: $vehicleType \nÄgare: $owner';

  bool isValid() {
    return _isValidRegistrationNumber() &&
        _isValidVehicleType() &&
        (owner == null || owner!.isValid());
  }

  bool _isValidRegistrationNumber() {
    final regex = RegExp(r'^[A-Z]{3}\d{2}[A-Z0-9]$');
    return regex.hasMatch(registrationNumber);
  }

  bool _isValidVehicleType() {
    return vehicleType.isNotEmpty;
  }
}

class ParkingSpace {
  String uuid;
  String id;
  String address;
  double pph;

  ParkingSpace(this.id, this.address, this.pph) : uuid = Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'address': address,
        'pph': pph,
      };

  factory ParkingSpace.fromJson(Map<String, dynamic> json) {
    return ParkingSpace(
      json['id'],
      json['address'],
      (json['pph'] as num).toDouble(),
    );
  }

  @override
  String toString() =>
      '\nParkeringens id: $id, \nAdress: $address, \nPris: $pph kr per timme';

  bool isValid() {
    return _isValidId() && _isValidAddress() && _isValidPrice();
  }

  bool _isValidId() {
    final regex = RegExp(r'^[A-Za-z0-9]{3,}$');
    return regex.hasMatch(id);
  }

  bool _isValidAddress() {
    return address.isNotEmpty;
  }

  bool _isValidPrice() {
    return pph > 0;
  }
}

class ParkingSession {
  String uuid;
  Vehicle vehicle;
  ParkingSpace parkingSpace;
  DateTime startTime;
  DateTime? endTime;

  ParkingSession(this.vehicle, this.parkingSpace, this.startTime,
      [this.endTime])
      : uuid = Uuid().v4();

  Map<String, dynamic> toJson() => {
        'vehicle': vehicle.toJson(),
        'parking_space': parkingSpace.toJson(),
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
      };

  factory ParkingSession.fromJson(Map<String, dynamic> json) {
    if (json['vehicle'] == null || json['parking_space'] == null) {
      throw Exception('Missing vehicle or parking_space in JSON');
    }

    final vehicleMap = json['vehicle'] as Map<String, dynamic>;
    final parkingSpaceMap = json['parking_space'] as Map<String, dynamic>;

    return ParkingSession(
      Vehicle.fromJson(vehicleMap),
      ParkingSpace.fromJson(parkingSpaceMap),
      DateTime.parse(json['start_time']),
      json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
    );
  }

  @override
  String toString() {
    return '\nFordonstyp: ${vehicle.vehicleType} \nRegnr: ${vehicle.registrationNumber} \nParkeringens id: ${parkingSpace.id} \nParkeringen startad: $startTime \nParkeringen avslutad: ${endTime ?? "pågående"}';
  }

  bool isValid() {
    return vehicle.isValid() &&
        parkingSpace.isValid() &&
        _isValidStartTime() &&
        _isValidEndTime();
  }

  bool _isValidStartTime() {
    return startTime.isBefore(DateTime.now());
  }

  bool _isValidEndTime() {
    if (endTime == null) return true;
    return endTime!.isAfter(startTime);
  }
}
