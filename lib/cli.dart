import 'repositories.dart';
import 'models.dart';
import 'dart:io';

void startCLI() {
  var personRepo = PersonRepository();
  var vehicleRepo = VehicleRepository();
  var parkingSpaceRepo = ParkingSpaceRepository();
  var parkingSessionRepo = ParkingSessionRepository();

  while (true) {
    print('\nVälj ett alternativ:');
    print('1. Hantera personer');
    print('2. Hantera fordon');
    print('3. Hantera parkeringsplatser');
    print('4. Hantera parkeringar');
    print('5. Avsluta programmet');
    var choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        handlePersons(personRepo);
        break;
      case '2':
        handleVehicles(vehicleRepo, personRepo);
        break;
      case '3':
        handleParkingSpaces(parkingSpaceRepo);
        break;
      case '4':
        handleParkingSessions(
            parkingSessionRepo, vehicleRepo, parkingSpaceRepo);
        break;
      case '5':
        print('Avslutar programmet...');
        return;
      default:
        print('Ogiltigt val, försök igen.');
    }
  }
}

void handlePersons(PersonRepository personRepo) {
  while (true) {
    print('\nHantera personer:');
    print('1. Skapa en ny person');
    print('2. Visa alla personer');
    print('3. Uppdatera en person');
    print('4. Ta bort en person');
    print('5. Tillbaka till huvudmenyn');
    var choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        print('Ange namn:');
        var name = stdin.readLineSync()!;
        print('Ange personnummer:');
        var personalNumber = stdin.readLineSync()!;
        var person = Person(name, personalNumber);

        if (person.isValid()) {
          personRepo.add(Person(name, personalNumber));
          print('Person tillagd.');
        } else {
          print('❌: Namn eller personnummer är felaktigt.');
        }
        break;

      case '2':
        print('Alla personer:');
        personRepo.getAll().forEach((p) => print(p));
        break;

      case '3':
        print('Ange personnummer för personen som ska uppdateras:');
        var personalNumber = stdin.readLineSync()!;
        var person = personRepo.getPersonById(personalNumber);
        if (person != null) {
          print('Ange nytt namn:');
          var newName = stdin.readLineSync()!;
          personRepo.update(Person(newName, personalNumber));
          print('Person uppdaterad.');
        } else {
          print('Person hittades inte.');
        }
        break;

      case '4':
        print('Ange personnummer för personen som ska tas bort:');
        var personalNumber = stdin.readLineSync()!;
        personRepo.delete(personalNumber);
        print('Person borttagen.');
        break;

      case '5':
        return;
      default:
        print('Ogiltigt val, försök igen.');
    }
  }
}

void handleVehicles(
    VehicleRepository vehicleRepo, PersonRepository personRepo) {
  while (true) {
    print('\nHantera fordon:');
    print('1. Skapa ett nytt fordon');
    print('2. Visa alla fordon');
    print('3. Uppdatera ett fordon');
    print('4. Ta bort ett fordon');
    print('5. Tillbaka till huvudmenyn');
    var choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        print('Ange registreringsnummer:');
        var regNum = stdin.readLineSync()!.toUpperCase();
        print('Ange fordonstyp:');
        var type = stdin.readLineSync()!.toUpperCase();
        print('Ange ägarens personnummer:');
        var ownerId = stdin.readLineSync()!;
        var owner = personRepo.getPersonById(ownerId);

        if (owner == null) {
          print('❌ Fel: Ägare hittades inte.');
          break;
        }

        var vehicle = Vehicle(regNum, type, owner);
        if (vehicle.isValid()) {
          vehicleRepo.add(Vehicle(regNum, type, owner));
          print('Fordon tillagt.');
        } else {
          print(
              '❌: Ogiltiga uppgifter, kontrollera registreringsnummer och fordonstyp.');
        }
        break;

      case '2':
        print('Alla fordon:');
        vehicleRepo.getAll().forEach((v) => print(v));
        break;

      case '3':
        print('Ange registreringsnummer för fordonet som ska uppdateras:');
        var regNum = stdin.readLineSync()!.toUpperCase();
        var vehicle = vehicleRepo.getVehicleById(regNum);
        if (vehicle != null) {
          print('Ange ny fordonstyp:');
          var newType = stdin.readLineSync()!;
          vehicleRepo.update(Vehicle(regNum, newType, vehicle.owner));
          print('Fordon uppdaterat.');
        } else {
          print('Fordon hittades inte.');
        }
        break;

      case '4':
        print('Ange registreringsnummer för fordonet som ska tas bort:');
        var regNum = stdin.readLineSync()!;
        vehicleRepo.delete(regNum);
        print('Fordon borttaget.');
        break;

      case '5':
        return;
      default:
        print('Ogiltigt val, försök igen.');
    }
  }
}

void handleParkingSpaces(ParkingSpaceRepository parkingSpaceRepo) {
  while (true) {
    print('\nHantera parkeringsplatser:');
    print('1. Skapa en ny parkeringsplats');
    print('2. Visa alla parkeringsplatser');
    print('3. Uppdatera en parkeringsplats');
    print('4. Ta bort en parkeringsplats');
    print('5. Tillbaka till huvudmenyn');
    var choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        print('Ange ID:');
        var id = stdin.readLineSync()!;
        print('Ange adress:');
        var address = stdin.readLineSync()!;
        print('Ange pris per timme:');
        var pricePerHour = double.parse(stdin.readLineSync()!);
        var parkingSpace = ParkingSpace(id, address, pricePerHour);

        if (parkingSpace.isValid()) {
          parkingSpaceRepo.add(ParkingSpace(id, address, pricePerHour));
          print('Parkeringsplats tillagd.');
        } else {
          print(
              '❌: Ogiltiga uppgifter, kontrollera parkerings-id, adress och pris');
        }
        break;

      case '2':
        print('Alla parkeringsplatser:');
        parkingSpaceRepo.getAll().forEach((s) => print(s));
        break;

      case '3':
        print('Ange ID för parkeringsplatsen som ska uppdateras:');
        var id = stdin.readLineSync()!;
        var space = parkingSpaceRepo.getSpaceById(id);
        if (space != null) {
          print('Ange ny adress:');
          var newAddress = stdin.readLineSync()!;
          print('Ange nytt pris per timme:');
          var newPrice = double.parse(stdin.readLineSync()!);
          parkingSpaceRepo.update(ParkingSpace(id, newAddress, newPrice));
          print('Parkeringsplats uppdaterad.');
        } else {
          print('Parkeringsplats hittades inte.');
        }
        break;

      case '4':
        print('Ange ID för parkeringsplatsen som ska tas bort:');
        var id = stdin.readLineSync()!;
        parkingSpaceRepo.delete(id);
        print('Parkeringsplats borttagen.');
        break;

      case '5':
        return;
      default:
        print('Ogiltigt val, försök igen.');
    }
  }
}

void handleParkingSessions(ParkingSessionRepository parkingSessionRepo,
    VehicleRepository vehicleRepo, ParkingSpaceRepository parkingSpaceRepo) {
  while (true) {
    print('\nHantera parkeringar:');
    print('1. Skapa en ny parkering');
    print('2. Visa alla parkeringar');
    print('3. Uppdatera en parkering');
    print('4. Ta bort en parkering');
    print('5. Tillbaka till huvudmenyn');
    var choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        print('Ange registreringsnummer för fordonet:');
        var regNum = stdin.readLineSync()!.toUpperCase();
        var vehicle = vehicleRepo.getVehicleById(regNum);
        if (vehicle == null) {
          print('Fordon hittades inte.');
          break;
        }
        print('Ange ID för parkeringsplatsen:');
        var spaceId = stdin.readLineSync()!;
        var space = parkingSpaceRepo.getSpaceById(spaceId);
        if (space == null) {
          print('Parkeringsplats hittades inte.');
          break;
        }
        var session = ParkingSession(vehicle, space, DateTime.now());
        if (session.isValid()) {
          parkingSessionRepo
              .add(ParkingSession(vehicle, space, DateTime.now()));
          print('Parkering startad.');
        } else {
          print('❌: Ogiltiga parkeringsuppgifter.');
        }
        break;

      case '2':
        print('Alla parkeringar:');
        parkingSessionRepo.getAll().forEach((p) => print(p));
        break;

      case '3':
        print('Ange registreringsnummer för fordonet som ska uppdateras:');
        var regNum = stdin.readLineSync()!.toUpperCase();
        print('Vill du avsluta parkeringen? (j/n)');
        var endParking = stdin.readLineSync()!.toLowerCase() == 'j';
        if (endParking) {
          if (parkingSessionRepo.update(regNum, endParking: true)) {
            print('Parkeringen avslutad.');
          } else {
            print('Ingen aktiv parkering hittades.');
          }
        } else {
          print('Ange ny sluttid (yyyy-MM-dd HH:mm):');
          var endTime = DateTime.parse(stdin.readLineSync()!);
          if (parkingSessionRepo.update(regNum, newEndTime: endTime)) {
            print('Parkeringen förlängd.');
          } else {
            print('Ingen aktiv parkering hittades.');
          }
        }
        break;

      case '4':
        print(
            'Ange registreringsnummer för fordonet vars parkering ska tas bort:');
        var regNum = stdin.readLineSync()!;
        if (parkingSessionRepo.delete(regNum)) {
          print('Parkering borttagen.');
        } else {
          print('Ingen parkering hittades.');
        }
        break;

      case '5':
        return;
      default:
        print('Ogiltigt val, försök igen.');
    }
  }
}
