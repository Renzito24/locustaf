import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/features/workplaces/presentation/widgets/workplace_map_picker.dart';

void main() {
  group('WorkplaceMapPicker Tests', () {
    testWidgets('renders search field and map picker correctly', (tester) async {
      // ignore: unused_local_variable
      double? lat;
      // ignore: unused_local_variable
      double? lng;
      // ignore: unused_local_variable
      String? address;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkplaceMapPicker(
              onLatitudeChanged: (v) => lat = v,
              onLongitudeChanged: (v) => lng = v,
              onAddressChanged: (v) => address = v,
            ),
          ),
        ),
      );

      // Verify search field exists
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Buscar dirección'), findsOneWidget);

      // Verify "Usar mi ubicación" button exists
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('renders with initial values correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WorkplaceMapPicker(
              initialLatitude: -34.6037,
              initialLongitude: -58.3816,
              initialAddress: 'Obelisco, Buenos Aires',
            ),
          ),
        ),
      );

      expect(find.text('Lat: -34.603700, Lng: -58.381600'), findsOneWidget);
    });
  });
}
