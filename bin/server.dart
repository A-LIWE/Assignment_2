import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';
import 'package:supabase/supabase.dart';

// Supabase instans
final supabase = SupabaseClient('https://ywvoteqcrohgusjawaqg.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl3dm90ZXFjcm9oZ3VzamF3YXFnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAxNDM3NjUsImV4cCI6MjA1NTcxOTc2NX0.3mnwht5XOgYNM6Zn5qK-qft_5FJZvTtP-13AggbUycw');

void main() async {
  final app = Router();

  // Endpoint för att hämta alla personer från Supabase
  app.get('/api/persons', (Request request) async {
    final response = await supabase.from('persons').select();
    return Response.ok(jsonEncode(response),
        headers: {'Content-Type': 'application/json'});
  });

  // Endpoint för att lägga till en person i Supabase
  app.post('/api/persons', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      print('DEBUG: Tar emot ny person: $data');
      print('🔍 DEBUG: Skickar person till Supabase: ${jsonEncode(data)}');

      // 🔹 Se till att 'personalNumber' hanteras som en sträng
      final response = await supabase.from('persons').insert({
        'name': data['name'],
        'personal_number':
            data['personal_number'].toString(), // 🔥 Konvertera till String
      }).select();

      return Response(
        201,
        body: jsonEncode({'message': 'Person tillagd', 'data': response}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stacktrace) {
      print('🚨 SERVER ERROR: $e');
      print('🚨 STACKTRACE: $stacktrace');

      // 🛑 Om felet är en PostgrestException med kod 23505 (unique constraint violation)
      if (e is PostgrestException && e.code == '23505') {
        return Response(
          409,
          body: jsonEncode({'error': '❌ Personen finns redan i systemet.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.internalServerError(
        body: jsonEncode({'error': 'Serverfel, vänligen försök igen.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // Endpoint för att hämta en specifik person från Supabase
  app.get('/api/persons/<personal_number>',
      (Request request, String personalNumber) async {
    final response = await supabase
        .from('persons')
        .select()
        .eq('personal_number', personalNumber)
        .single();
    return Response(200,
        body: jsonEncode(response),
        headers: {'Content-Type': 'application/json'});
  });

  // Endpoint för att uppdatera en person i Supabase
  app.put('/api/persons/<personal_number>',
      (Request request, String personalNumber) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      final response = await supabase
          .from('persons')
          .update({
            'name': data['name'],
          })
          .eq('personal_number', personalNumber)
          .select();

      if (response.isEmpty) {
        return Response(404,
            body: jsonEncode(
                {'error': 'Ingen person hittades med det personnumret.'}),
            headers: {'Content-Type': 'application/json'});
      }

      return Response(200,
          body: jsonEncode({'message': 'Person uppdaterad', 'data': response}),
          headers: {'Content-Type': 'application/json'});
    } catch (e, stacktrace) {
      print('🚨 SERVER ERROR: $e');
      print('🚨 STACKTRACE: $stacktrace');
      return Response.internalServerError(
          body: jsonEncode({'error': 'Serverfel vid uppdatering av person'}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  // Endpoint för att ta bort en person från Supabase
  app.delete('/api/persons/<personal_number>',
      (Request request, String personalNumber) async {
    try {
      // Steg 1: Försök radera personen och få tillbaka den raderade raden.
      // .select('*') returnerar raderna som raderades
      final deletedRows = await supabase
          .from('persons')
          .delete()
          .eq('personal_number', personalNumber)
          .select('*');

      // Om inga rader raderades -> 404
      if (deletedRows.isEmpty) {
        return Response(
          404,
          body: jsonEncode({
            'error': 'Ingen person hittades med personnummer $personalNumber.'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // deletedRows är en lista av rader, men i ditt fall förväntar du dig
      // normalt sett max en rad. Vi plockar ut den första.
      final deletedPerson = deletedRows.first;

      // Exempel: deletedPerson['name'], deletedPerson['personalNumber']
      final name = deletedPerson['name'] ?? 'Okänt namn';

      // Steg 2: Returnera 200 OK och skicka med JSON med namn, personnummer etc.
      return Response.ok(
        jsonEncode({'name': name, 'personal_number': personalNumber}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stacktrace) {
      print('Server error: $e\n$stacktrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Serverfel vid radering'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

//VEHICLES

// 🚀 **Lägg till ett fordon**
  app.post('/api/vehicles', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      // 🔍 Hämta ägarens UUID baserat på personal_number
      final ownerQuery = await supabase
          .from('persons')
          .select('id') // Vi hämtar endast ID
          .eq('personal_number', data['owner']['personal_number'])
          .single(); // Förväntar att endast en person matchar

      if (ownerQuery.isEmpty) {
        return Response(
          404,
          body: jsonEncode({'error': '❌ Ägare hittades inte.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final ownerUuid = ownerQuery['id']; // Hämta UUID från resultatet

      print('DEBUG: Skickar till Supabase: ${jsonEncode(data)}');

      // 🔹 Infogar ett nytt fordon i Supabase
      final response = await supabase.from('vehicles').insert({
        'registration_number':
            data['registration_number'].toString(), // 🔥 Konvertera till String
        'vehicle_type': data['vehicle_type'].toString(),
        'owner': ownerUuid, // skicka ägarens uuid
      }).select();

      return Response(
        201,
        body: jsonEncode({'message': 'Fordon tillagt', 'data': response}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stacktrace) {
      print('🚨 SERVER ERROR: $e');
      print('🚨 STACKTRACE: $stacktrace');

      // 🛑 Hantera unikt registreringsnummer (dublettfel)
      if (e is PostgrestException && e.code == '23505') {
        return Response(
          409,
          body: jsonEncode({'error': '❌ Fordonet finns redan i systemet.'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.internalServerError(
        body: jsonEncode({'error': 'Serverfel, vänligen försök igen.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

// 🚀 **Hämta alla fordon**
  app.get('/api/vehicles', (Request request) async {
    try {
      // 🔹 Hämtar vehicles med inbäddad persons-data
      final response = await supabase.from('vehicles').select(
          'uuid, registration_number, vehicle_type, owner: persons(name, personal_number)');
      return Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('🚨 FEL: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Misslyckades att hämta fordon'}),
      );
    }
  });

  app.get('/api/vehicles/<registration_number>', (Request request, String regNumber) async {
  try {
    // 🔹 Hämtar exakt en post från 'vehicles' där 'registration_number' matchar 'regNumber'
    final response = await supabase
        .from('vehicles')
        .select()
        .eq('registration_number', regNumber)
        .maybeSingle(); // 🏆 Returnerar ett enda objekt eller null

    // 🔎 Om responsen är null → inget fordon hittades
    if (response == null) {
      return Response.notFound(
        jsonEncode({'error': 'Fordon med registreringsnummer $regNumber hittades inte.'}),
      );
    }

    // ✅ Hittade fordon → returnera 200 OK
    return Response.ok(
      jsonEncode(response),
      headers: {'Content-Type': 'application/json'},
    );

  } catch (e, stacktrace) {
    print('🚨 SERVER ERROR: $e');
    print('🚨 STACKTRACE: $stacktrace');

    // ❌ Vid oväntade fel → returnera 500
    return Response.internalServerError(
      body: jsonEncode({'error': 'Serverfel vid hämtning av fordon.'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
});


  app.put('/api/vehicles/<registration_number>', (Request request, String regNumber) async {
  try {
    // 1. Läser in JSON från requesten
    final payload = await request.readAsString();
    final data = jsonDecode(payload);
    print('DEBUG: Fick data: $data');

    // 2. Uppdaterar kolumnen 'vehicle_type' baserat på registreringsnummer
    final response = await supabase
        .from('vehicles')
        .update({
          'vehicle_type': data['vehicle_type'], // 🔥 Byter fordonstyp
        })
        .eq('registration_number', regNumber)
        .select();

    // 3. Om inget fordon uppdaterades -> returnera 404
    if (response.isEmpty) {
      return Response(
        404,
        body: jsonEncode({'error': 'Inget fordon hittades med registreringsnummer: $regNumber'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // 4. Om allt gick bra -> returnera 200 OK
    return Response(
      200,
      body: jsonEncode({
        'message': 'Fordon uppdaterat',
        'data': response,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e, stacktrace) {
    print('🚨 SERVER ERROR: $e');
    print('🚨 STACKTRACE: $stacktrace');
    return Response.internalServerError(
      body: jsonEncode({'error': 'Serverfel vid uppdatering av fordon'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
});


app.delete('/api/vehicles/<registration_number>', (Request request, String regNumber) async {
  try {
    // 🔹 Raderar fordon där 'registration_number' matchar 'regNumber'.
    //    .select() returnerar en lista med raderna som raderats.
    final response = await supabase
        .from('vehicles')
        .delete()
        .eq('registration_number', regNumber)
        .select();

    // 🔎 Om listan är tom → inget fordon matchade
    if (response.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'Fordon med regnr $regNumber hittades inte.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // 🏆 Vi har raderat minst ett fordon → plocka ut det första
    //    (Vanligtvis bara 1 rad om 'registration_number' är unikt.)
    final Map<String, dynamic> deletedVehicle = response.first;
    final String vehicleType = deletedVehicle['vehicle_type'];

    // ✅ Returnera 200 OK + JSON med 'vehicleType'
    return Response(
      200,
      body: jsonEncode({
        'vehicleType': vehicleType,
      }),
      headers: {'Content-Type': 'application/json'},
    );

  } catch (e, stacktrace) {
    print('🚨 SERVER ERROR: $e');
    print('🚨 STACKTRACE: $stacktrace');
    // ❌ Ovänatat fel → 500
    return Response.internalServerError(
      body: jsonEncode({'error': 'Serverfel vid borttagning av fordon.'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
});

// PARKING SPACES

  app.post('/api/parking_spaces', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      // ✅ Skapa Insert-objektet
      final insertData = {
        'id': '${data['id']}',
        'address': '${data['address']}',
        'pph': data['pph'],
      };

      final response =
          await supabase.from('parking_spaces').insert(insertData).select();

      return Response(
        201,
        body: jsonEncode({
          'message': 'Parkeringsplats tillagd',
          'data': response,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } on PostgrestException catch (pgex, stacktrace) {
      print('🚨 PostgrestException: $pgex');
      print('🚨 STACKTRACE: $stacktrace');

      // Om det är en dubblett
      if (pgex.code == '23505') {
        return Response(
          409,
          body: jsonEncode({
            'error': 'Parkeringsplats med detta ID existerar redan',
            'details': pgex.details
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Annat PostgrestException-fel
      return Response.internalServerError(
        body: jsonEncode({'error': 'Serverfel: $pgex'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    // 🔥 Fångar alla andra typer av undantag
    catch (e, stacktrace) {
      print('🚨 SERVER ERROR: $e');
      print('🚨 STACKTRACE: $stacktrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Serverfel: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

// 🔹 Hämta alla parkeringsplatser
  app.get('/api/parking_spaces', (Request request) async {
    try {
      final response = await supabase.from('parking_spaces').select();
      return Response.ok(jsonEncode(response),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Serverfel: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  // 🔹 Hämta en specifik parkeringsplats med ID
  app.get('/api/parking_spaces/<id>', (Request request, String id) async {
    try {
      final response = await supabase
          .from('parking_spaces')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return Response.notFound(
            jsonEncode({'error': 'Parkeringsplats hittades inte'}));
      }

      return Response.ok(jsonEncode(response),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Serverfel: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  // 🔹 Uppdatera en parkeringsplats
  app.put('/api/parking_spaces/<id>', (Request request, String id) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      final response = await supabase
          .from('parking_spaces')
          .update({
            'address': data['address'],
            'pph': data['pph'],
          })
          .eq('id', id)
          .select();

      if (response.isEmpty) {
        return Response.notFound(
            jsonEncode({'error': 'Parkeringsplats hittades inte'}));
      }

      return Response.ok(jsonEncode({'message': 'Parkeringsplats uppdaterad'}));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Serverfel: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  // 🔹 Ta bort en parkeringsplats
  app.delete('/api/parking_spaces/<id>', (Request request, String id) async {
    try {
      // Utför raderingen och returnera de raderade posterna
      final response =
          await supabase.from('parking_spaces').delete().eq('id', id).select();

      // Om listan är tom, hittades ingen post med angivet id
      if (response.isEmpty) {
        return Response(404, headers: {'Content-Type': 'application/json'});
      }

      // Vid lyckad borttagning returnera 200 success
      return Response(200, headers: {'Content-Type': 'application/json'});
    } catch (e) {
      // Logga gärna felet här om du har ett loggningssystem
      return Response.internalServerError(
        body: jsonEncode({'error': 'Serverfel: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });


  // PARKINGSESSIONS

  // 🟢 1. Hämta alla parkeringar
  app.get('/api/parking_sessions', (Request request) async {
  try {
    // 🔹 Vi gör en nested select på fordon & parkeringsplats
    //    Supabase genererar automagiskt "owner: persons(...)"-liknande struktur.
    final response = await supabase
        .from('parking_sessions')
        .select('uuid, start_time, end_time, vehicle: vehicles(*), parking_space: parking_spaces(*)');

    // Nu får vi en lista av sessions, där 
    // "vehicle" är inbäddat från "vehicles"-tabellen 
    // och "parking_space" från "parking_spaces"

    return Response.ok(
      jsonEncode(response),
      headers: {'Content-Type': 'application/json'},
    );

  } catch (e, stacktrace) {
    print('🚨 SERVER ERROR: $e');
    print('🚨 STACKTRACE: $stacktrace');

    return Response.internalServerError(
      body: jsonEncode({'error': 'Misslyckades att hämta parkeringar.'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
});


  // 🟢 2. Starta en ny parkering
  app.post('/api/parking_sessions', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      print('🔍 Data innan insert: $data');

      final response = await supabase.from('parking_sessions').insert({
        'vehicle': data[
            'vehicle']['registration_number'], // 🔗 Antag att detta är en relation till "vehicles"
        'parking_space': data[
            'parking_space']['id'], // 🔗 Antag att detta är en relation till "parking_spaces"
        'start_time': data['start_time'],
      }).select();

      return Response(
        201,
        body: jsonEncode({'message': 'Parkering startad', 'data': response}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stacktrace) {
      print('🚨 SERVER ERROR: $e');
      print('🚨 STACKTRACE: $stacktrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Serverfel, vänligen försök igen.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // 🟢 Hämta en specifik parkering via registreringsnummer
  app.get('/api/parking_sessions/<registration_number>', (Request request, String regNumber) async {
  try {
    // 🔹 Hämtar en parkering där 'vehicle' matchar registreringsnumret
    final response = await supabase
        .from('parking_sessions')
        .select()
        .eq('vehicle', regNumber)
        .maybeSingle(); // 🔍 Returnerar en rad eller null
        print(response);

    // 🚨 Om ingen rad hittades → return 404
    if (response == null) {
      return Response.notFound(
        jsonEncode({
          'error':
              'Ingen aktiv parkering hittades för fordonet med registreringsnummer $regNumber.'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    // 🟢 Annars → 200 OK med parkeringen i JSON
    return Response.ok(
      jsonEncode({'message': 'Parkering hittad', 'data': response}),
      headers: {'Content-Type': 'application/json'},
    );

  } catch (e, stacktrace) {
    print('🚨 SERVER ERROR: $e');
    print('🚨 STACKTRACE: $stacktrace');

    return Response.internalServerError(
      body: jsonEncode({'error': 'Serverfel, vänligen försök igen.'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
});


  // 🟢 4. Uppdatera en parkering (t.ex. avsluta parkeringen)
  app.put('/api/parking_sessions/<registration_number>',
      (Request request, String registrationNumber) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      final updateData = <String, dynamic>{};

      if (data.containsKey('end_time')) {
        updateData['end_time'] = data['end_time']; // Avsluta parkeringen
      }

      final response = await supabase
          .from('parking_sessions')
          .update(updateData)
          .eq('vehicle', registrationNumber);

      if (response == null || response.isEmpty) {
        return Response.notFound(
            jsonEncode({'error': 'Ingen aktiv parkering hittades'}));
      }

      return Response.ok(
          jsonEncode({'message': 'Parkering uppdaterad', 'data': response}),
          headers: {'Content-Type': 'application/json'});
    } catch (e, stacktrace) {
      print('🚨 SERVER ERROR: $e');
      print('🚨 STACKTRACE: $stacktrace');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Serverfel, vänligen försök igen.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // 🟢 5. Ta bort en parkering
  app.delete('/api/parking_sessions/<registration_number>',
      (Request request, String registrationNumber) async {
    final response = await supabase
        .from('parking_sessions')
        .delete()
        .eq('vehicle', registrationNumber);

    if (response == null || response.isEmpty) {
      return Response.notFound(
          jsonEncode({'error': 'Ingen parkering hittades'}));
    }

    return Response(204);
  });

  final handler = Pipeline().addMiddleware(logRequests()).addHandler(app.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 3000);
  print('✅ Servern körs på http://${server.address.host}:${server.port}');
}
