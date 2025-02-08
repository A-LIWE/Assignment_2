class Person {
  String name;
  String personalNumber;

  Person(this.name, this.personalNumber);

  Map<String, dynamic> toJson() => {
        'name': name,
        'personalNumber': personalNumber,
      };

      factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      json['name'],
      json['personalNumber'],
    );
  }

  @override
  String toString() => '\nNamn: $name \nPersonnummer: $personalNumber';
}

class Vehicle {
  String registrationNumber;
  String vehicleType;
  Person owner;

  Vehicle(this.registrationNumber, this.vehicleType, this.owner);

  Map<String, dynamic> toJson() => {
        'registrationNumber': registrationNumber,
        'vehicleType': vehicleType,
        'owner': owner.toJson(),
      };

      factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      json['registrationNumber'],
      json['vehicleType'],
      Person.fromJson(json['owner']),
    );
  }
  
  @override
  String toString() => '\nRegnr: $registrationNumber, \nFordonstyp: $vehicleType, \nÄgare: $owner)';
}

class ParkingSpace{
  String id;
  String address;
  double pph;

  ParkingSpace(this.id, this.address, this.pph);

  Map<String, dynamic> toJson() => {
        'id': id,
        'address': address,
        'pph': pph,
      };

      factory ParkingSpace.fromJson(Map<String, dynamic> json) {
    return ParkingSpace(
      json['id'],
      json['address'],
      json['pph'],
    );
  }

   @override
  String toString() => '\nParkeringens id: $id, \nAdress: $address, \nPris: $pph kr per timme)';
}

class ParkingSession{
  Vehicle vehicle;
  ParkingSpace parkingSpace;
  DateTime startTime;
  DateTime? endTime;

  ParkingSession(this.vehicle, this.parkingSpace, this.startTime, [this.endTime]);

  Map<String, dynamic> toJson() => {
        'vehicle': vehicle.toJson(),
        'parkingSpace': parkingSpace.toJson(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
      };

      factory ParkingSession.fromJson(Map<String, dynamic> json) {
    return ParkingSession(
      Vehicle.fromJson(json['vehicle']),
      ParkingSpace.fromJson(json['parkingSpace']),
      DateTime.parse(json['startTime']),
      json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    );
  }

  @override
  String toString(){
    return '\nRegnr: ${vehicle.registrationNumber}, \nParkeringens id: ${parkingSpace.id}, \nParkeringen startad: $startTime, \nParkeringen avslutad: ${endTime ?? "ongoing"})';
  }
}