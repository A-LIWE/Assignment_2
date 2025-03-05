import 'repositories.dart';
import 'models.dart';
import 'dart:io';

Future<void> startCLI() async {
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
        await handlePersons(personRepo);
        break;
      case '2':
        await handleVehicles(vehicleRepo, personRepo);
        break;
      case '3':
        await handleParkingSpaces(parkingSpaceRepo);
        break;
      case '4':
        await handleParkingSessions(
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

Future<void> handlePersons(PersonRepository personRepo) async {
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
          await personRepo.add(person);
        } else {
          print('❌: Namn eller personnummer är felaktigt.');
        }
        break;

      case '2':
        var people = await personRepo.getAll();
        if (people.isEmpty) {
          print('❌ Listan är tom.');
        } else {
          print('Alla personer:');
          for (var person in people) {
            print(person);
          }
        }
        stdin.readLineSync();
        break;

      case '3':
        print('Ange personnummer för personen som ska uppdateras:');
        var personalNumber = stdin.readLineSync()!;
        var person = await personRepo.getPersonById(personalNumber);
        if (person != null) {
          print('Ange nytt namn:');
          var newName = stdin.readLineSync()!;
          await personRepo.update(Person(newName, personalNumber));
          print('Person uppdaterad.');
        } else {
          print('Person hittades inte.');
        }
        break;

      case '4':
        print('Ange personnummer för personen som ska tas bort:');
        var personalNumber = stdin.readLineSync()!;
        try {
          await personRepo.delete(personalNumber);
        } catch (e) {
          print(e);
        }
        break;

      case '5':
        return;
      default:
        print('Ogiltigt val, försök igen.');
    }
  }
}

Future<void> handleVehicles(
    VehicleRepository vehicleRepo, PersonRepository personRepo) async {
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

        var owner = await personRepo.getPersonById(ownerId);
        if (owner == null) {
          print('❌ Fel: Ägare hittades inte.');
          break;
        }

        var vehicle = Vehicle(regNum, type, owner);
        if (vehicle.isValid()) {
          await vehicleRepo.add(vehicle); 
        } else {
          print(
              '❌: Ogiltiga uppgifter, kontrollera registreringsnummer och fordonstyp.');
        }
        break;

      case '2':
        print('Laddar fordon...');
        var vehicles = await vehicleRepo.getAll();
        if (vehicles.isEmpty) {
          print('❌ Inga fordon hittades.');
        } else {
          print('Alla fordon:');
          for (var vehicle in vehicles) {
            print(vehicle);
          }
        }
        stdin.readLineSync();
        break;

      case '3':
        print('Ange registreringsnummer för fordonet som ska uppdateras:');
        var regNum = stdin.readLineSync()!.toUpperCase();
        var vehicle = await vehicleRepo.getVehicleByRegistrationN(regNum);

        if (vehicle != null) {
          print('Ange ny fordonstyp:');
          var newType = stdin.readLineSync()!.toUpperCase();
          vehicleRepo.update(Vehicle(regNum, newType, vehicle.owner));
          print('Fordon uppdaterat.');
        } else {
          print('Fordon hittades inte.');
        }
        break;

      case '4':
        print('Ange registreringsnummer för fordonet som ska tas bort:');
        var regNum = stdin.readLineSync()!.toUpperCase();
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

Future<void> handleParkingSpaces(
    ParkingSpaceRepository parkingSpaceRepo) async {
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
        var id = stdin.readLineSync()!.toUpperCase();
        print('Ange adress:');
        var address = stdin.readLineSync()!;
        print('Ange pris per timme:');
        var pricePerHour = double.parse(stdin.readLineSync()!);
        var parkingSpace = ParkingSpace(id, address, pricePerHour);

        if (parkingSpace.isValid()) {
          try {
            await parkingSpaceRepo.add(parkingSpace);
            print('✅ Parkeringsplats tillagd.');
          } catch (e) {
            print('❌ Fel vid tillägg av parkeringsplats: $e');
          }
        } else {
          print('❌: Ogiltiga uppgifter, kontrollera parkerings-ID, adress och pris.');
        }
        break;

      case '2':
        print('Alla parkeringsplatser:');
        try {
          var spaces = await parkingSpaceRepo.getAll();
          if (spaces.isEmpty) {
            print('❌ Inga parkeringsplatser hittades.');
          } else {
            for (var space in spaces) {
              print(space);
            }
          }
        } catch (e) {
          print('❌ Misslyckades att hämta parkeringsplatser: $e');
        }
        break;

      case '3':
        print('Ange ID för parkeringsplatsen som ska uppdateras:');
        var id = stdin.readLineSync()!.toUpperCase();
        try {
          var space = await parkingSpaceRepo.getSpaceById(id);
          if (space != null) {
            print('Ange ny adress:');
            var newAddress = stdin.readLineSync()!;
            print('Ange nytt pris per timme:');
            var newPrice = double.parse(stdin.readLineSync()!);
            await parkingSpaceRepo.update(ParkingSpace(id, newAddress, newPrice));
            print('✅ Parkeringsplats uppdaterad.');
          } else {
            print('❌ Parkeringsplats hittades inte.');
          }
        } catch (e) {
          print('❌ Fel vid uppdatering av parkeringsplats: $e');
        }
        break;

      case '4':
        print('Ange ID för parkeringsplatsen som ska tas bort:');
        var id = stdin.readLineSync()!.toUpperCase();
         try {
          await parkingSpaceRepo.delete(id);
          print('✅ Parkeringsplats borttagen.');
        } catch (e) {
          print('❌ Fel vid radering av parkeringsplats: $e');
        }
        break;

      case '5':
        return;
      default:
        print('Ogiltigt val, försök igen.');
    }
  }
}

Future<void> handleParkingSessions(
    ParkingSessionRepository parkingSessionRepo,
    VehicleRepository vehicleRepo,
    ParkingSpaceRepository parkingSpaceRepo) async {
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
        var vehicle = await vehicleRepo.getVehicleByRegistrationN(regNum);
        if (vehicle == null) {
          print('❌ Fordon hittades inte.');
          break;
        }

        print('Ange ID för parkeringsplatsen:');
        var spaceId = stdin.readLineSync()!.toUpperCase();
        var space = await parkingSpaceRepo.getSpaceById(spaceId);
        if (space == null) {
          print('❌ Parkeringsplats hittades inte.');
          break;
        }

        var session = ParkingSession(vehicle, space, DateTime.now());

        if (session.isValid()) {
          await parkingSessionRepo.add(session);
          print('✅ Parkering startad.');
        } else {
          print('❌: Ogiltiga parkeringsuppgifter.');
        }
        break;

      case '2':
        var parkings = await parkingSessionRepo.getAll();
        if (parkings.isEmpty) {
          print('❌ Inga parkeringar hittades.');
        } else {
          print('Alla parkeringar:');
          for (var parking in parkings) {
            print(parking);
          }
        }
        break;

       case '3':
        print('Ange registreringsnummer för fordonet som ska uppdateras:');
        var regNum = stdin.readLineSync()!.toUpperCase();
        var parking = await parkingSessionRepo.getParkingByRegistrationN(regNum);

        if (parking == null) {
          print('❌ Ingen aktiv parkering hittades.');
          break;
        }

        print('Vill du avsluta parkeringen? (j/n)');
        var endParking = stdin.readLineSync()!.toLowerCase() == 'j';

        if (endParking) {
          await parkingSessionRepo.update(regNum, endParking: true);
          print('✅ Parkeringen avslutad.');
        } else {
          print('Ange ny sluttid (yyyy-MM-dd HH:mm):');
          try {
            var endTime = DateTime.parse(stdin.readLineSync()!);
            await parkingSessionRepo.update(regNum, newEndTime: endTime);
            print('✅ Parkeringen förlängd.');
          } catch (e) {
            print('❌ Ogiltigt format. Ange datum i formatet yyyy-MM-dd HH:mm.');
          }
        }
        break;

      case '4':
        print('Ange registreringsnummer för fordonet vars parkering ska tas bort:');
        var regNum = stdin.readLineSync()!.toUpperCase();
        try {
          await parkingSessionRepo.delete(regNum);
          print('✅ Parkering borttagen.');
        } catch (e) {
          print('❌ Ingen parkering hittades.');
        }
        break;

      case '5':
        return;
      default:
        print('Ogiltigt val, försök igen.');
    }
  }
}
