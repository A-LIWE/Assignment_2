class Person {
  String name;
  String personalNumber;

  Person(this.name, this.personalNumber);

  @override
  String toString() => 'Person(name: $name, personalNumber: $personalNumber)';
}

class Vehicle {
  String registrationNumber;
  String vehicleType;
  Person owner;

  Vehicle(this.registrationNumber, this.vehicleType, this.owner);
  
  @override
  String toString() => 'Vehicle(registrationNumber: $registrationNumber, vehicleType: $vehicleType, owner: $owner)';
}

class ParkingSpace{
  String id;
  String address;
  double pph;

  ParkingSpace(this.id, this.address, this.pph);

   @override
  String toString() => 'ParkingSpace(id: $id, address: $address, pph: $pph)';
}

class ParkingSession{
  Vehicle vehicle;
  ParkingSpace parkingSpace;
  DateTime startTime;
  DateTime? endTime;

  ParkingSession(this.vehicle, this.parkingSpace, this.startTime, [this.endTime]);

  @override
  String toString(){
    return 'ParkingSession(vehicle: ${vehicle.registrationNumber}, parkingSpace: ${parkingSpace.id}, startTime: $startTime, endTime: ${endTime ?? "ongoing"})';
  }
}