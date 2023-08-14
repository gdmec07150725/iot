import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

Dio dio = Dio();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showWaterHeater = false; // 是否显示设备
  bool _active = false;
  List _equipmentList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      getEquimentData();
    });
  }

  Future<void> getEquimentData() async {
    Response response;
    showLoadingDialog();
    response = await dio.get("http://42.192.168.165:8001/equipmentArray");
    Navigator.of(context).pop();
    print(response.data);
    if (response.data?.length > 0) {
      setState(() {
        _showWaterHeater = true;
        _equipmentList = response.data;
      });
    } else {
      // 隔一秒重新获取
      Future.delayed(const Duration(seconds: 5))
          .then((value) => {getEquimentData()});
    }
  }

  // 打开或者关闭设备
  Future<void> changeStatus(bool status) async {
    dynamic bodyParams;
    print(_equipmentList[0]);
    dynamic equip = _equipmentList[0]; // 目前只取第一个设备
    String action = status ? "open" : "close";
    bodyParams = {"action": action, "addr": equip["addr"], "id": equip["id"]};
    await dio.post("http://42.192.168.165:8001/", data: bodyParams);
    setState(() {
      _active = status;
    });
    if (action == "open") {
      autoCloseEquip();
    }
  }

  // 开启定时器，10分钟后自动关闭设备
  void autoCloseEquip() {
    Future.delayed(const Duration(minutes: 10)).then((value) {
      print("执行自动关闭设备");
      changeStatus(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "设备",
          style: TextStyle(fontSize: 16.0),
        ),
        centerTitle: true,
      ),
      body: _showWaterHeater
          ? Flex(
              direction: Axis.horizontal,
              children: [
                Expanded(
                    flex: 1,
                    child: Container(
                      alignment: Alignment.center,
                      height: 200.0,
                      // decoration: BoxDecoration(),
                      color: Colors.white,
                      child: Column(children: [
                        Image.asset(
                          "./images/waterHeater.jpg",
                          width: 150.0,
                        ),
                        Flex(
                          direction: Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Switch(
                                // inactiveTrackColor: Colors.pink,
                                inactiveThumbColor: Colors.blue,
                                activeColor: Colors.blue,
                                value: _active,
                                onChanged: (bool val) {
                                  changeStatus(val);
                                }),
                          ],
                        )
                      ]),
                    )),
                Expanded(
                    flex: 1,
                    child: Container(
                      alignment: Alignment.center,
                      height: 200.0,
                      // decoration: BoxDecoration(),
                      color: Colors.white,
                      // child: Text('liao'),
                    )),
              ],
            )
          : const Center(
              child: Text("暂无设备在线~"),
            ),
    );
  }

  showLoadingDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const UnconstrainedBox(
            // 修改弹窗的默认大小
            constrainedAxis: Axis.vertical,
            child: SizedBox(
                width: 300,
                child: AlertDialog(
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    Padding(
                      padding: EdgeInsets.only(top: 26.0),
                      child: Text("正在加载设备, 请稍后..."),
                    )
                  ]),
                )),
          );
        });
  }
}
