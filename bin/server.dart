import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'dart:convert';

void main() async {
  final app = Router();

  List<Map<String, dynamic>> persons = []; // Lista för att lagra personer

  // Endpoint för att hämta alla personer
  app.get('/api/persons', (Request request) async {
    return Response.ok(jsonEncode([]), headers: {'Content-Type': 'application/json'});
  });

  // Endpoint för att lägga till en person
  app.post('/api/persons', (Request request) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);
  
  persons.add(data); // Spara personen i listan
  print('Ny person tillagd: $data');
  return Response(201, body: jsonEncode({'message': 'Person tillagd'}), headers: {'Content-Type': 'application/json'});
});

  // Endpoint för att hämta en specifik person
  app.get('/api/persons/<id>', (Request request, String id) async {
    return Response.ok(jsonEncode({'id': id, 'name': 'Exempel Namn'}), headers: {'Content-Type': 'application/json'});
  });

  // Endpoint för att uppdatera en person
  app.put('/api/persons/<id>', (Request request, String id) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);
    print('Uppdaterar person $id med data: $data');
    return Response.ok(jsonEncode({'message': 'Person uppdaterad'}), headers: {'Content-Type': 'application/json'});
  });

  // Endpoint för att ta bort en person
  app.delete('/api/persons/<id>', (Request request, String id) async {
    print('Person med ID $id raderad');
    return Response(204, body: jsonEncode({'message': 'Person borttagen'}), headers: {'Content-Type': 'application/json'});
  });

  final handler = Pipeline().addMiddleware(logRequests()).addHandler(app.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, 3000);
  print('✅ Servern körs på http://${server.address.host}:${server.port}');
}
