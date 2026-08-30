import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('null devuelve error', () {
      expect(Validators.required(null, 'Nombre'), 'Nombre es obligatorio');
    });

    test('vacío devuelve error', () {
      expect(Validators.required('   ', 'Nombre'), 'Nombre es obligatorio');
    });

    test('con valor devuelve null', () {
      expect(Validators.required('Juan', 'Nombre'), isNull);
    });
  });

  group('Validators.email', () {
    test('null devuelve error', () {
      expect(Validators.email(null), 'El correo electrónico es obligatorio');
    });

    test('vacío devuelve error', () {
      expect(Validators.email('  '), 'El correo electrónico es obligatorio');
    });

    test('email válido devuelve null', () {
      expect(Validators.email('juan@empresa.com'), isNull);
    });

    test('email sin dominio devuelve error', () {
      expect(Validators.email('juan@empresa'), 'Ingrese un correo electrónico válido');
    });

    test('email sin arroba devuelve error', () {
      expect(Validators.email('juanempresa.com'), 'Ingrese un correo electrónico válido');
    });

    test('email con espacios devuelve error', () {
      expect(Validators.email('juan @empresa.com'), 'Ingrese un correo electrónico válido');
    });
  });

  group('Validators.password', () {
    test('null devuelve error', () {
      expect(Validators.password(null), 'La contraseña es obligatoria');
    });

    test('vacío devuelve error', () {
      expect(Validators.password(''), 'La contraseña es obligatoria');
    });

    test('menos de 6 caracteres devuelve error', () {
      expect(Validators.password('12345'), 'La contraseña debe tener al menos 6 caracteres');
    });

    test('6 caracteres o más es válido', () {
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.dni', () {
    test('null devuelve error', () {
      expect(Validators.dni(null), 'El DNI es obligatorio');
    });

    test('vacío devuelve error', () {
      expect(Validators.dni('  '), 'El DNI es obligatorio');
    });

    test('con valor devuelve null', () {
      expect(Validators.dni('30123456'), isNull);
    });
  });

  group('Validators.cuit', () {
    test('null devuelve error', () {
      expect(Validators.cuit(null), 'El CUIT es obligatorio');
    });

    test('vacío devuelve error', () {
      expect(Validators.cuit('  '), 'El CUIT es obligatorio');
    });

    test('menos de 11 dígitos devuelve error', () {
      expect(Validators.cuit('2012345678'), 'El CUIT debe tener 11 dígitos');
    });

    test('más de 11 dígitos devuelve error', () => expect(
          Validators.cuit('201234567890'),
          'El CUIT debe tener 11 dígitos',
        ));

    test('acepta CUIT con guiones y espacios', () {
      // 20-12345678-6 es un CUIT válido (dígito verificador 6).
      expect(Validators.cuit('20-12345678-6'), isNull);
    });

    test('rechaza CUIT con dígito verificador incorrecto', () {
      expect(Validators.cuit('20123456789'), 'El CUIT no es válido');
    });

    test('rechaza CUIT con letras', () {
      // Al quitar los guiones quedan 10 dígitos → error de longitud.
      expect(Validators.cuit('20-12345678-A'), 'El CUIT debe tener 11 dígitos');
    });
  });

  group('Validators.latitud', () {
    test('null devuelve error', () {
      expect(Validators.latitud(null), 'La latitud es obligatoria');
    });

    test('valor válido devuelve null', () {
      expect(Validators.latitud(-34.6037), isNull);
      expect(Validators.latitud(0), isNull);
      expect(Validators.latitud(90), isNull);
      expect(Validators.latitud(-90), isNull);
    });

    test('fuera de rango devuelve error', () {
      expect(Validators.latitud(91), 'La latitud debe estar entre -90 y 90');
      expect(Validators.latitud(-91), 'La latitud debe estar entre -90 y 90');
    });
  });

  group('Validators.longitud', () {
    test('null devuelve error', () {
      expect(Validators.longitud(null), 'La longitud es obligatoria');
    });

    test('valor válido devuelve null', () {
      expect(Validators.longitud(-58.3816), isNull);
      expect(Validators.longitud(0), isNull);
      expect(Validators.longitud(180), isNull);
      expect(Validators.longitud(-180), isNull);
    });

    test('fuera de rango devuelve error', () {
      expect(Validators.longitud(181), 'La longitud debe estar entre -180 y 180');
      expect(Validators.longitud(-181), 'La longitud debe estar entre -180 y 180');
    });
  });
}
