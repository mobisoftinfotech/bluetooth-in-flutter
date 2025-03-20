import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;
  final Map<Guid, List<int>> readValues = <Guid, List<int>>{};

  DeviceScreen({super.key, required this.device});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {

  final _writeController = TextEditingController();
  List<BluetoothService> services = [];

  @override
  void initState() {
    super.initState();
    discoverServices();
  }

  @override
  void dispose() {
    widget.device.disconnect();
    super.dispose();
  }

  void discoverServices() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    setState(() {
      this.services = services;
    });
  }

  void readValueOfCharacteristic(BluetoothCharacteristic characteristic) async {
    var sub = characteristic.lastValueStream.listen((value) {
      setState(() {
        widget.readValues[characteristic.uuid] = value;
      });
    });
    await characteristic.read();
    sub.cancel();
  }

  void writeValueToCharacteristic(BluetoothCharacteristic characteristic) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Write"),
            content: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _writeController,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              ElevatedButton(
                child: Text("Send"),
                onPressed: () {
                  characteristic.write(utf8 .encode(_writeController.value.text));
                  Navigator.pop(context);
                },
              ),
              ElevatedButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  void setNotifyToCharacteristic(BluetoothCharacteristic characteristic) async {
    characteristic.lastValueStream.listen((value) {
      widget.readValues[characteristic.uuid] = value;
    });
    await characteristic.setNotifyValue(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.advName)),
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, serviceIndex) {
          return ListTile(
            title: Text('Service: ${services[serviceIndex].uuid.toString()}'),
            subtitle: SizedBox(
              height: services[serviceIndex].characteristics.length * 120,
              child: ListView.builder(
                itemCount: services[serviceIndex].characteristics.length,
                itemBuilder: (context, charIndex) {
                  return SizedBox(
                    height: 120,
                      child: Column(
                        spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Characteristics: ${services[serviceIndex].characteristics[charIndex].uuid}'),
                        Visibility(
                          visible: services[serviceIndex].characteristics[charIndex].properties.read,
                            child:
                        Text('Value: ${utf8.decode(widget.readValues[services[serviceIndex].characteristics[charIndex].uuid] ?? utf8.encode(""))}')
                        ),
                        Row(
                          children: [
                            Visibility(
                              visible: services[serviceIndex].characteristics[charIndex].properties.read,
                              child: ElevatedButton(
                                onPressed: () async {
                                  readValueOfCharacteristic(services[serviceIndex].characteristics[charIndex]);
                                },
                                child: Text('Read'),
                              ),
                            ),
                            Visibility(
                              visible: services[serviceIndex].characteristics[charIndex].properties.write,
                              child: ElevatedButton(
                                onPressed: () async {
                                  writeValueToCharacteristic(services[serviceIndex].characteristics[charIndex]);
                                },
                                child: Text('Write'),
                              ),
                            ),
                            Visibility(
                              visible: services[serviceIndex].characteristics[charIndex].properties.notify,
                              child: ElevatedButton(
                                onPressed: () async {
                                  setNotifyToCharacteristic(services[serviceIndex].characteristics[charIndex]);
                                },
                                child: Text('Notify'),
                              ),
                            ),
                          ],
                        )
                      ],
                      ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}