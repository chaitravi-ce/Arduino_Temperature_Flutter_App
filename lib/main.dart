import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  late StreamSubscription _subscription;
  late StreamSubscription<ConnectionStateUpdate> _connection;
  late int temperature;
  String temperatureStr = "Hello";
  //bool kDebugMode = true;

  void _disconnect() async {
    _subscription.cancel();
    // ignore: unnecessary_null_comparison
    if (_connection != null) {
      await _connection.cancel();
    }
  }

  void _connectBLE() {
    setState(() {
      temperatureStr = 'Loading';
    });
    _disconnect();
    _subscription = _ble.scanForDevices(
        withServices: [],
        scanMode: ScanMode.lowLatency,
        requireLocationServicesEnabled: true).listen((device) {
      if (device.name == 'Nano33BLESENSE') {
        if (kDebugMode) {
          print('Nano33BLESENSE found!');
        }
        _connection = _ble.connectToDevice(
          id: device.id,
        ).listen((connectionState) async {
          // Handle connection state updates
          if (kDebugMode) {
            print('connection state:');
            print(connectionState.connectionState);
          }
          if (connectionState.connectionState == DeviceConnectionState.connected) {
            final characteristic = QualifiedCharacteristic(
                serviceId: Uuid.parse("181A"),
                characteristicId: Uuid.parse("2A6E"),
                deviceId: device.id);
            // ignore: prefer_typing_uninitialized_variables
            var response;
            for(int i=0; i<5; i++){
              response = await _ble.readCharacteristic(characteristic);
              if (kDebugMode) {
                print("=========================================Response");
                print(response);
              }
            }
            setState(() {
              temperature = response[0];
              temperatureStr = temperature.toString() + '°';
            });
            _disconnect();
            if (kDebugMode) {
              print('disconnected');
            }
          }
        }, onError: (dynamic error) {
          // Handle a possible error
          if (kDebugMode) {
            print(error.toString());
          }
        });
      }
    }, onError: (error) {
      if (kDebugMode) {
        print('error!');
        print(error.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xffffdf6f), Color(0xffeb2d95)])),
        child: Center(
          child: Text(
            temperatureStr,
            style: GoogleFonts.anton(
                textStyle: Theme.of(context)
                    .textTheme
                    .headline1!
                    .copyWith(color: Colors.white)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _connectBLE,
        tooltip: 'Increment',
        backgroundColor: const Color(0xFF74A4BC),
        child: const Icon(Icons.loop),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}