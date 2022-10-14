
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TestDialog extends StatefulWidget {
  String? title;
  String? message;

  TestDialog({Key? key, this.title, this.message}) : super(key: key);

  @override
  _TestDialogState createState() => _TestDialogState();
}

class _TestDialogState extends State<TestDialog> {
  String titleMain = "";
  String messageMain = "";
  double _width = 0.0;

  @override
  void initState() {
    super.initState();
    setState(() {
      titleMain = widget.title!;
      messageMain = widget.message!;
    });
  }

  @override
  Widget build(BuildContext context) {
    _width = MediaQuery.of(context).size.width;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 0.0,
      insetPadding: EdgeInsets.all(10),
      backgroundColor: Colors.white,
      child: dialogContent(context),
    );
  }

  dialogContent(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.all(20),
                width: _width,
                child: Column(
                  children: [
                    Text(
                      titleMain,
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      messageMain,
                    ),
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
