import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ScanResult> _recordList = [];

  void searchForDevices() async {
    if (await FlutterBluePlus.isSupported == false) {
      debugPrint("Bluetooth not supported by this device");
      return;
    } else {
      startScanning();
    }
  }

  void startScanning() async {
    _recordList.clear();

    await FlutterBluePlus.startScan(timeout: Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!_recordList.contains(result)) {
          _recordList.add(result);
          debugPrint(result.device.advName);
        }
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("BLE Demo"),
        actions: [
          IconButton(
            onPressed: searchForDevices,
            icon: const Icon(Icons.bluetooth_searching),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ListView.builder(
                  itemCount: _recordList.length,
                  itemBuilder: (context, index) {
                    if (index < _recordList.length) {
                      final bleDevice = _recordList[index];
                      return Container(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide()),
                          ),
                          height: 70,
                          child: ListTile(
                              onTap: () {
                                var device = _recordList[index].device;
                                if (device.isConnected) {
                                  device.disconnect();
                                } else {
                                  connectToDevice(device, context);
                                }
                              },
                              title: Text(
                                  bleDevice.advertisementData.advName == ''
                                      ? "(Unknown Device)"
                                      : bleDevice.advertisementData.advName),
                              subtitle: Text(bleDevice.device.remoteId.str)));
                    } else {
                      return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text('No Devices Discoverable'),
                          ));
                    }
                  }),
            ),
            ElevatedButton(
              onPressed: () {
                searchForDevices();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  textStyle:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              child: const Text('SCAN'),
            ),
            const SizedBox(height: 30)
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void connectToDevice(BluetoothDevice device, BuildContext context) async {
    FlutterBluePlus.stopScan();

    await device.connect();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceScreen(device: device),
      ),
    );
  }
}
