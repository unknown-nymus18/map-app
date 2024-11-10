import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:maps/api.dart';
import 'package:maps/blur.dart';
import 'package:maps/weather_card.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  LatLng initial = const LatLng(23, 45);
  final MapController _mapController = MapController();
  Color containerColor = Colors.transparent;
  final TextEditingController _textEditingController = TextEditingController();
  double blurSize = 0;

  FocusNode focusNode = FocusNode();

  Future<LatLng?> _getLocation(String address) async {
    try {
      final res = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$address&APPID=$openWeatherAPIKey'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _animatedMoveToLocation(
            LatLng(data['coord']['lat'], data['coord']['lon']));
        return LatLng(data['coord']['lat'], data['coord']['lon']);
      } else {
        return null;
      }
    } catch (e) {
      throw e.toString();
    }
  }

  void _animatedMoveToLocation(LatLng location) {
    Duration duration = calculateSpeed(
        LatLng(_mapController.camera.center.latitude,
            _mapController.camera.center.longitude),
        location);
    Tween<double> latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: location.latitude - 0.006);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude, end: location.longitude);
    final zoomTween =
        Tween<double>(begin: _mapController.camera.zoom, end: 15.0);

    AnimationController controller =
        AnimationController(vsync: this, duration: duration);

    controller.addListener(() {
      _mapController.move(
          LatLng(latTween.evaluate(controller), lngTween.evaluate(controller)),
          zoomTween.evaluate(controller));
    });
    controller.forward();
  }

  Duration calculateSpeed(LatLng now, LatLng next) {
    double distance = sqrt(pow(next.latitude - now.latitude, 2) +
        pow(next.longitude - now.longitude, 2));
    // print(distance.ceil());
    return Duration(milliseconds: (distance.ceil() * 200));
  }

  void zoomIN() {
    AnimationController controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    controller.addListener(() {
      _mapController.move(
        LatLng(_mapController.camera.center.latitude,
            _mapController.camera.center.longitude),
        _mapController.camera.zoom + 0.1,
      );
    });
    controller.forward();
  }

  void zoomOut() {
    AnimationController controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    controller.addListener(() {
      _mapController.move(
        LatLng(_mapController.camera.center.latitude,
            _mapController.camera.center.longitude),
        _mapController.camera.zoom - 0.1,
      );
    });
    controller.forward();
  }

  Future<Map<String, dynamic>?> getForcast(String address) async {
    try {
      final res = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$address&APPID=$openWeatherAPIKey'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data;
      } else {
        return null;
      }
    } catch (e) {
      throw e.toString();
    }
  }

  Widget _weather() {
    return ValueListenableBuilder(
      valueListenable: _textEditingController,
      builder: (context, value, child) {
        return FutureBuilder(
          future: getForcast(value.text),
          builder: (context, snapshots) {
            if (value.text.isNotEmpty) {
              if (snapshots.hasError) {
                return const Center(
                  child: Text("There was an error"),
                );
              }
              if (snapshots.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshots.hasData) {
                List data = snapshots.data!['list'];
                return SizedBox(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          double temp = data[index]['main']['temp'];
                          int pressure = data[index]['main']['pressure'];
                          String desc = data[index]['weather'][0]['main'];
                          final date = data[index]['dt_txt'];
                          final time = DateTime.parse(date);

                          return WeatherCard(
                            temp: temp,
                            pressure: pressure,
                            desc: desc,
                            time: DateFormat.j().format(time),
                          );
                        },
                      ),
                    ),
                  ),
                );
              } else {
                return const Center(child: Text("Not found"));
              }
            } else {
              return Container();
            }
          },
        );
      },
    );
  }

  Widget customTextField() {
    return TextField(
      focusNode: focusNode,
      controller: _textEditingController,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          onPressed: () async {
            _getLocation(_textEditingController.text);
          },
          icon: const Icon(
            Icons.search,
            color: Colors.grey,
          ),
        ),
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            width: 0,
            color: Colors.transparent,
          ),
        ),
        fillColor: Colors.white38,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            width: 0,
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                  initialCenter: initial,
                  initialZoom: 3.2,
                  onTap: (postion, latlong) {
                    focusNode.unfocus();
                  }),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.map.app',
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Blur(
                        sigmaX: 5,
                        sigmaY: 5,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Center(
                                child: IconButton(
                                  hoverColor: Colors.transparent,
                                  onPressed: zoomIN,
                                  icon: const Icon(Icons.add),
                                ),
                              ),
                              Center(
                                child: IconButton(
                                  hoverColor: Colors.transparent,
                                  onPressed: zoomOut,
                                  icon: const Icon(CupertinoIcons.minus),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 350,
                  child: DraggableScrollableSheet(
                    minChildSize: 0.38,
                    initialChildSize: 0.38,
                    snap: true,
                    snapSizes: const [0.38, 1],
                    builder: (context, scrollController) {
                      return Blur(
                        sigmaX: 10,
                        sigmaY: 10,
                        borderRadius: BorderRadius.circular(20),
                        child: BottomSheet(
                          backgroundColor: Colors.transparent,
                          enableDrag: true,
                          showDragHandle: true,
                          animationController: controller,
                          onClosing: () {},
                          builder: (context) {
                            return Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: Column(
                                  children: [
                                    customTextField(),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    SizedBox(
                                      height: 200,
                                      child: _weather(),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
