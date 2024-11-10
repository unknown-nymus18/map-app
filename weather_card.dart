import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  final String time;
  final double temp;
  final int pressure;
  final String desc;
  const WeatherCard({
    super.key,
    required this.temp,
    required this.pressure,
    required this.desc,
    required this.time,
  });

  Widget weatherIcon(String desc) {
    if (desc == 'Rain') {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'lib/assets/images/rainy.png',
          width: 60,
          height: 60,
        ),
      );
    }
    if (desc == 'Clouds') {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'lib/assets/images/cloudy.png',
          width: 60,
          height: 60,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset(
        'lib/assets/images/sun.png',
        width: 60,
        height: 60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: 160,
      child: Card(
        color: Colors.grey,
        elevation: 12,
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Align(
              alignment: Alignment.center,
              child: Text(time.toString()),
            ),
            weatherIcon(desc),
            Align(
              alignment: Alignment.center,
              child: Text(
                desc,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
