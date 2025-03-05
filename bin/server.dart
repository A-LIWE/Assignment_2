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
  app.delete('/api/persons/<personal_number>', (Request request, String personalNumber) async {
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
        body: jsonEncode({'error': 'Ingen person hittades med personnummer $personalNumber.'}),
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
      'registration_number': data['registration_number'].toString(), // 🔥 Konvertera till String
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
    final response = await supabase.from('vehicles').select();

    return Response.ok(jsonEncode(response), headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': 'Misslyckades att hämta fordon'}));
  }
});

 





// PARKING SPACES

// 🔹 Hämta alla parkeringsplatser
  app.get('/api/parkingspaces', (Request request) async {
    try {
      final response = await supabase.from('parkingspaces').select();
      return Response.ok(jsonEncode(response),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Serverfel: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  // 🔹 Lägg till en ny parkeringsplats
  app.post('/api/parkingspaces', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      // Infogar ny parkeringsplats
      final response = await supabase.from('parkingspaces').insert({
        'id': data['id'].toString(),
        'address': data['address'],
        'price_per_hour': data['pricePerHour'],
      }).select();

      return Response(
        201,
        body: jsonEncode({'message': 'Parkeringsplats tillagd', 'data': response}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Serverfel: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  // 🔹 Hämta en specifik parkeringsplats med ID
  app.get('/api/parkingspaces/<id>', (Request request, String id) async {
    try {
      final response = await supabase
          .from('parkingspaces')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return Response.notFound(jsonEncode({'error': 'Parkeringsplats hittades inte'}));
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
  app.put('/api/parkingspaces/<id>', (Request request, String id) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      final response = await supabase
          .from('parkingspaces')
          .update({
            'address': data['address'],
            'price_per_hour': data['pricePerHour'],
          })
          .eq('id', id);

      if (response == null) {
        return Response.notFound(jsonEncode({'error': 'Parkeringsplats hittades inte'}));
      }

      return Response.ok(jsonEncode({'message': 'Parkeringsplats uppdaterad'}));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Serverfel: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  });

  // 🔹 Ta bort en parkeringsplats
  app.delete('/api/parkingspaces/<id>', (Request request, String id) async {
    try {
      final response = await supabase.from('parkingspaces').delete().eq('id', id);

      if (response == null) {
        return Response.notFound(jsonEncode({'error': 'Parkeringsplats hittades inte'}));
      }

      return Response(204);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Serverfel: $e'}),
          headers: {'Content-Type': 'application/json'});
    }
  });


  // 🟢 1. Hämta alla parkeringar
  app.get('/api/parking_sessions', (Request request) async {
    final response = await supabase.from('parking_sessions').select();
    return Response.ok(jsonEncode(response),
        headers: {'Content-Type': 'application/json'});
  });

  // 🟢 2. Starta en ny parkering
  app.post('/api/parking_sessions', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      final response = await supabase.from('parking_sessions').insert({
        'vehicle': data['vehicle'], // 🔗 Antag att detta är en relation till "vehicles"
        'parking_space': data['parking_space'], // 🔗 Antag att detta är en relation till "parking_spaces"
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

  // 🟢 3. Hämta en specifik parkering via registreringsnummer
  app.get('/api/parking_sessions/<registration_number>', (Request request, String registration_number) async {
    final response = await supabase
        .from('parking_sessions')
        .select()
        .eq('vehicle', registration_number)
        .maybeSingle(); // 🔍 Hämtar en parkering om den finns

    if (response == null) {
      return Response.notFound(jsonEncode({'error': 'Ingen aktiv parkering hittades'}));
    }

    return Response.ok(jsonEncode(response),
        headers: {'Content-Type': 'application/json'});
  });

  // 🟢 4. Uppdatera en parkering (t.ex. avsluta parkeringen)
  app.put('/api/parking_sessions/<registration_number>', (Request request, String registration_number) async {
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
          .eq('vehicle', registration_number);

      if (response == null || response.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Ingen aktiv parkering hittades'}));
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
  app.delete('/api/parking_sessions/<registration_number>', (Request request, String registration_number) async {
    final response = await supabase
        .from('parking_sessions')
        .delete()
        .eq('vehicle', registration_number);

    if (response == null || response.isEmpty) {
      return Response.notFound(jsonEncode({'error': 'Ingen parkering hittades'}));
    }

    return Response(204);
  });





   final handler = Pipeline().addMiddleware(logRequests()).addHandler(app.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 3000);
  print('✅ Servern körs på http://${server.address.host}:${server.port}');
}