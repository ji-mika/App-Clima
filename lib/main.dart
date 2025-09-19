import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // lIbrería para hacer peticiones HTTP

void main() async {
  runApp(const ClimaApp());
}

class ClimaApp extends StatelessWidget {
  const ClimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clima App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(), // Pantalla Inicial
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _cityCtrl = TextEditingController(
    text: 'Ciudad de México',
  );

  // Lista de 10 ciudades extras
  final List<String> _ciudades = [
    'Osaka',
    'Ixmiquilpan',
    'Lima',
    'Florencia',
    'Barcelona',
    'Gunpo',
    'Beijing',
    'Santiago',
    'Buenos Aires',
    'Moscu',
  ];

  static const String _apiKey = 'eee1a33af8e60c44940ca4f0a46627f0';

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>?> _datosCiudades = [];

  // Busca el clima de todas las ciudades extras
  Future<void> _buscarClimaCiudades() async {
    setState(() {
      _loading = true;
      _error = null;
      _datosCiudades = List.filled(_ciudades.length, null);
    });

    try {
      final results = await Future.wait(
        _ciudades.map((city) async {
          final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
            'q': city,
            'appid': _apiKey,
            'units': 'metric',
            'lang': 'es',
          });
          final resp = await http.get(uri);
          if (resp.statusCode == 200) {
            return jsonDecode(resp.body) as Map<String, dynamic>;
          } else {
            return null;
          }
        }),
      );

      setState(() {
        _datosCiudades = results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error de red: $e';
        _loading = false;
      });
    }
  }

  // Función que busca el clima llamando a la API
  Future<void> _buscarClima() async {
    FocusScope.of(context).unfocus(); // Cierra el teclado
    final city = _cityCtrl.text.trim();

    if (city.isEmpty) {
      setState(() => _error = 'Escribe una ciudad.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'q': city,
      'appid': _apiKey,
      'units': 'metric', // Métricas → °C
      'lang': 'es', // Respuesta en español
    });
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _datosCiudades = [json];
          _loading = false;
        });
      } else {
        String msg = 'Error ${resp.statusCode}';
        try {
          final j = jsonDecode(resp.body);
          if (j is Map && j['message'] is String) msg = j['message'];
        } catch (_) {}
        setState(() {
          _error = 'No se pudo obtener el clima: $msg';
          _loading = false;
          _datosCiudades = [];
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de red: $e'; // Ej. sin Internet
        _loading = false;
        _datosCiudades = [];
      });
    } finally {}
  }

  @override
  Widget build(BuildContext context) {
    final hasData =
        _datosCiudades.isNotEmpty && _datosCiudades.any((d) => d != null);

    return Scaffold(
      appBar: AppBar(title: const Text('App del Clima'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Botón para buscar clima de ciudades predefinidas
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _buscarClima(),
                      decoration: const InputDecoration(
                        labelText: 'Ciudad',
                        hintText: 'Ej. Monterrey, Madrid, Tokyo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _loading ? null : _buscarClima,
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _loading ? null : _buscarClimaCiudades,
                    icon: const Icon(Icons.list),
                    label: const Text('10 ciudades'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_loading)
                const LinearProgressIndicator(), // Indicador de carga

              if (_error != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Lista de climas de ciudades predefinidas
              if (hasData)
                Expanded(
                  child: ListView.builder(
                    itemCount: _ciudades.length,
                    itemBuilder: (context, i) {
                      final data = _datosCiudades[i];
                      if (data == null) {
                        return ListTile(
                          title: Text(_ciudades[i]),
                          subtitle: const Text('No se pudo obtener el clima'),
                          leading: const Icon(Icons.error, color: Colors.red),
                        );
                      }
                      final nombreCiudad = data['name'] ?? _ciudades[i];
                      final pais = (data['sys']?['country'])?.toString() ?? '';
                      final weather = (data['weather'] as List?)
                          ?.cast<Map<String, dynamic>>();
                      final descripcion =
                          (weather != null && weather.isNotEmpty)
                          ? weather.first['description']?.toString() ?? ''
                          : '';
                      final icono = (weather != null && weather.isNotEmpty)
                          ? weather.first['icon']?.toString()
                          : null;
                      final main = data['main'] as Map<String, dynamic>?;
                      final temp = main?['temp']?.toDouble();
                      final tempMin = main?['temp_min']?.toDouble();
                      final tempMax = main?['temp_max']?.toDouble();
                      final sensacion = main?['feels_like']?.toDouble();
                      final humedad = main?['humidity']?.toInt();

                      return _ClimaCard(
                        ciudad: nombreCiudad,
                        pais: pais,
                        descripcion: descripcion,
                        iconCode: icono,
                        temp: temp,
                        tempMin: tempMin,
                        tempMax: tempMax,
                        sensacion: sensacion,
                        humedad: humedad,
                      );
                    },
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text(
                      'Busca una ciudad o consulta las 10 ciudades predefinidas',
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  'Desarrollado por Jesus Natanael Hernandez Martinez',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget tarjeta para mostrar clima actual
class _ClimaCard extends StatelessWidget {
  final String ciudad;
  final String pais;
  final String descripcion;
  final String? iconCode;
  final double? temp;
  final double? tempMin;
  final double? tempMax;
  final double? sensacion;
  final int? humedad;

  const _ClimaCard({
    required this.ciudad,
    required this.pais,
    required this.descripcion,
    required this.iconCode,
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.sensacion,
    required this.humedad,
  });

  @override
  Widget build(BuildContext context) {
    final iconUrl = iconCode != null
        ? 'https://openweathermap.org/img/wn/$iconCode@4x.png'
        : null;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    '$ciudad${pais.isNotEmpty ? ", $pais" : ""}',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (iconUrl != null)
                    Image.network(iconUrl, width: 120, height: 120),
                  const SizedBox(height: 8),
                  Text(
                    descripcion.isNotEmpty
                        ? (descripcion[0].toUpperCase() +
                              descripcion.substring(1))
                        : '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  if (temp != null)
                    Text(
                      '${temp!.toStringAsFixed(1)}°C',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (humedad != null)
                        _InfoChip(
                          icon: Icons.water_drop,
                          label: 'Humedad',
                          value: '$humedad%',
                        ),
                      if (sensacion != null)
                        _InfoChip(
                          icon: Icons.thermostat,
                          label: 'Sensación',
                          value: '${sensacion!.toStringAsFixed(1)}°C',
                        ),
                      if (tempMin != null)
                        _InfoChip(
                          icon: Icons.arrow_downward,
                          label: 'Mín',
                          value: '${tempMin!.toStringAsFixed(1)}°C',
                        ),
                      if (tempMax != null)
                        _InfoChip(
                          icon: Icons.arrow_upward,
                          label: 'Máx',
                          value: '${tempMax!.toStringAsFixed(1)}°C',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Chip reutilizable para mostrar pares "Etiqueta: Valor"
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon), label: Text('$label: $value'));
  }
}
