import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:stripe_terminal/stripe_terminal.dart';
import 'package:stripe_terminal_example/test_dialog.dart';
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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String baseUrl = 'https://api.stripe.com/v1/';
  String tokenStrip =
      'sk_test_51LDv95DtFeh76SVYd1mESKcpUahHmF7iAmbHk9xVLIzEXHGFH5XrCjV7IflhdEli4EhLDdkcpS2AAHTZpYxuMgcM00QRK8cgda';
  String tokenStrip2 =
      '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';
  late String secretKey = '';

  Future<String> getConnectionString2() async {
    var header = {'Authorization': 'Bearer $tokenStrip'};
    String fUrl = baseUrl + 'terminal/connection_tokens';
    final response = await http.post(Uri.parse(fUrl), headers: header);
    print('RESPONSE  ${jsonDecode(response.body)["secret"]}');
    return jsonDecode(response.body)["secret"];
  }

  Future<void> _pushLogs(StripeLog log) async {
    debugPrint(log.code);
    debugPrint(log.message);
  }

  Future<String> createPaymentIntent() async {
    var header = {
      'Authorization': 'Bearer $tokenStrip',
      "Accept": "application/json",
      "Content-Type": "application/x-www-form-urlencoded"
    };
    String fUrl = baseUrl + 'payment_intents';
    var match = {
      "amount": '100',
      "currency": 'eur',
      'payment_method_types[]': 'card_present',
      "capture_method": "manual"
    };
    final response = await http.post(
      Uri.parse(fUrl),
      headers: header,
      body: match,
      encoding: Encoding.getByName("utf-8"),
    );
    print('RESPONSE  ${jsonDecode(response.body)["client_secret"]}');
    return jsonDecode(response.body)["client_secret"];
  }

  late StripeTerminal stripeTerminal;

  @override
  void initState() {
    super.initState();
    setState(() {
      secretKey = simulated ? tokenStrip : tokenStrip2;
    });
    _initStripe();
  }

  _initStripe() {
    stripeTerminal = StripeTerminal(
      fetchToken: getConnectionString2,
    );
    stripeTerminal.onNativeLogs.listen(_pushLogs);
  }

  bool simulated = true;
  StreamSubscription? _sub;
  List<StripeReader>? readers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: Column(
          children: [
            ListTile(
              onTap: () {
                setState(() {
                  simulated = !simulated;
                  _initStripe();
                });
              },
              title: const Text("Scanning mode"),
              trailing: Text(simulated ? "Simulator" : "Real"),
            ),
            TextButton(
              child: const Text("Init Stripe"),
              onPressed: () async {
                _initStripe();
              },
            ),
            TextButton(
              child: const Text("Get Connection Token"),
              onPressed: () async {
                String connectionToken = await getConnectionString2();
                _showSnackbar(connectionToken);
              },
            ),
            if (_sub == null)
              TextButton(
                child: const Text("Scan Devices"),
                onPressed: () async {
                  setState(() {
                    readers = [];
                  });
                  /* _sub = await platform.invokeMethod("discoverReaders#start", {
                    "simulated": simulated,
                  });*/
                  _sub = stripeTerminal
                      .discoverReaders(simulated: simulated)
                      .listen((readers) {
                    setState(() {
                      this.readers = readers;
                    });
                  });
                },
              ),
            if (_sub != null)
              TextButton(
                child: const Text("Stop Scanning"),
                onPressed: () async {
                  setState(() {
                    _sub?.cancel();
                    _sub = null;
                  });
                },
              ),
            TextButton(
              child: const Text("Connection Status"),
              onPressed: () async {
                stripeTerminal.connectionStatus().then((status) {
                  _showSnackbar("Connection status: ${status.toString()}");
                });
              },
            ),
            TextButton(
              child: const Text("Connected Device"),
              onPressed: () async {
                stripeTerminal
                    .fetchConnectedReader()
                    .then((StripeReader? reader) {
                  _showSnackbar("Connection Device: ${reader?.toJson()}");
                });
              },
            ),
            if (readers != null)
              ...readers!.map(
                    (e) => ListTile(
                  title: Text(e.serialNumber),
                  trailing: Text(describeEnum(e.batteryStatus)),
                  leading: Text(e.locationId ?? "No Location Id"),
                  onTap: () async {
                    print('------->>>>${e.locationId}');
                    /*try {
                       await platform.invokeMethod('connectToReader',{
                        "locationId":  e.locationId,
                        "readerSerialNumber":  e.serialNumber,
                      });
                    } on PlatformException catch (e) {
                      //logPrint('exception', e.toString());
                    }*/
                    await stripeTerminal
                        .connectToReader(e.serialNumber,
                        locationId: e
                            .locationId //'tml_ErY8WQLvnFVajB', //"tml_EoMcZwfY6g8btZ",
                    )
                        .then((value) {
                      _showSnackbar("Connected to a device");
                    }).catchError((e) {
                      if (e is PlatformException) {
                        _showSnackbar(e.message ?? e.code);
                      }
                    });
                  },
                  subtitle: Text(describeEnum(e.deviceType)),
                ),
              ),
            Text(readers != null
                ? "total reader ${readers!.length}"
                : "no reader found"),
            // TextButton(
            //   child: const Text("Read Reusable Card Detail"),
            //   onPressed: () async {
            //     stripeTerminal
            //         .readReusableCardDetail()
            //         .then((StripePaymentMethod paymentMethod) {
            //       _showSnackbar(
            //         "A card was read: ${paymentMethod.card?.toJson()}",
            //       );
            //     });
            //   },
            // ),
            TextButton(
              child: const Text("Capture Payment"),
              onPressed: () async {
                String paymentIntent = await createPaymentIntent();
                stripeTerminal
                    .collectPaymentMethod(paymentIntent)
                    .then((StripePaymentIntent paymentMethod) {
                  if (paymentMethod.id != null &&
                      paymentMethod.status ==
                          PaymentIntentStatus.requiresCapture) {
                    capturePayment(paymentMethod);
                  } else {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return TestDialog(
                            title: 'Payment Error',
                            message: '${paymentMethod.toJson()}',
                          );
                        });
                  }
                  _showSnackbar(
                    "A payment method was captured--${paymentMethod.toString()}",
                  );
                });
              },
            ),
            TextButton(
              child: const Text("Misc Button"),
              onPressed: () async {
                StripeReader.fromJson(
                  {
                    "locationStatus": 2,
                    "deviceType": 3,
                    "serialNumber": "STRM26138003393",
                    "batteryStatus": 0,
                    "simulated": false,
                    "availableUpdate": false
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  void capturePayment(StripePaymentIntent paymentMethod) async {
    var header = {
      'Authorization': 'Bearer $secretKey',
    };
    String fUrl = baseUrl + 'payment_intents/${paymentMethod.id}/capture';
    final response = await http.post(
      Uri.parse(fUrl),
      headers: header,
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print('RESPONSE---${jsonDecode(response.body)}');
      showDialog(
          context: context,
          //barrierDismissible: false,
          builder: (BuildContext context) {
            return TestDialog(
              title: 'Payment 1111',
              message: '${jsonDecode(response.body)}',
            );
          });
    } else {
      showDialog(
          context: context,
          //barrierDismissible: false,
          builder: (BuildContext context) {
            return TestDialog(
              title: 'Payment Error',
              message: '${jsonDecode(response.body)}',
            );
          });
    }
  }
}
