import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:linring_front_flutter/models/login_info.dart';
import 'package:linring_front_flutter/models/tagset_model.dart';
import 'package:http/http.dart' as http;
import 'package:linring_front_flutter/screens/tag_add_screen.dart';

class TagShowScreen extends StatefulWidget {
  final LoginInfo loginInfo;
  const TagShowScreen({required this.loginInfo, Key? key}) : super(key: key);

  @override
  State createState() => _TagShowScreenState();
}

class _TagShowScreenState extends State<TagShowScreen> {
  late Future<List<Tagset>> _futureTagsets;
  @override
  void initState() {
    super.initState();
    _futureTagsets = _callAPI();
  }

  Future<List<Tagset>> _callAPI() async {
    String apiAddress = dotenv.get("API_ADDRESS");
    final url = Uri.parse('$apiAddress/accounts/v2/tagset/');
    final token = widget.loginInfo.access;
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      List<Tagset> tagsets =
          body.map((dynamic e) => Tagset.fromJson(e)).toList();

      return tagsets;
    } else {
      throw Exception('Failed to load tagset.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xfffff6f4),
      child: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              viewportFraction: 1.0,
            ),
            items: [1, 2, 3, 4, 5].map(
              (i) {
                return Builder(
                  builder: (BuildContext context) {
                    return const SizedBox(
                      width: double.infinity,
                      child: Image(
                        fit: BoxFit.fitWidth,
                        image: AssetImage('assets/images/info_1.png'),
                      ),
                    );
                  },
                );
              },
            ).toList(),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Image(
                        width: 45,
                        image: AssetImage('assets/images/avartar_1.png'),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(108, 89, 22, 0.10),
                              offset: Offset(0, 0),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Text(
                          "안녕~ 오늘은 어떤 친구를 만날까?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const Text(
                "어떤 친구를 만나게 될까요?",
              ),
              FutureBuilder(
                future: _futureTagsets,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text("에러 ${snapshot.error}");
                  } else if (!snapshot.hasData) {
                    return const Text("데이터 없음.");
                  } else {
                    return CarouselSlider(
                      options: CarouselOptions(
                        height: 320.0,
                        enableInfiniteScroll: false,
                      ),
                      items: () {
                        List<Widget> carouselItems = [];

                        for (var tag in snapshot.data!) {
                          carouselItems.add(
                            Builder(
                              builder: (BuildContext context) {
                                return SizedBox(
                                  width: 400,
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${tag.place}에서\n${(tag.isSameDepartment) ? "같은 과" : "다른 과"} ${tag.person}랑\n${tag.method}하기",
                                            style:
                                                const TextStyle(fontSize: 24),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Text(
                                            tag.introduction != null
                                                ? "\"${tag.introduction}\""
                                                : "",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Color(0xff999999),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 64,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                children: [
                                                  const Text(
                                                    "상대방이 나를\n검색할 수 있어요.",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xff999999),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 80,
                                                    child: FittedBox(
                                                      fit: BoxFit.fill,
                                                      child: CupertinoSwitch(
                                                        activeColor:
                                                            const Color(
                                                                0xff57e554),
                                                        value: tag.isActive,
                                                        onChanged: (value) {},
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              const Icon(
                                                Icons.search_rounded,
                                                color: Color(0xfffec2b5),
                                                size: 37,
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                        if (snapshot.data!.length <= 2) {
                          carouselItems.add(
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TagAddScreen(
                                      loginInfo: widget.loginInfo,
                                    ),
                                  ),
                                ).then(
                                  (value) => setState(
                                    () {
                                      _futureTagsets = _callAPI();
                                    },
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 400,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  color: Colors.white,
                                  child: const Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "클릭해서\n태그 추가하기",
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w300,
                                                color: Color(0xff898989),
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              "태그는 3개까지 추가할 수 있어요.",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w300,
                                                color: Color(0xff898989),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 36,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Image(
                                              image: AssetImage(
                                                'assets/icons/add_circle.png',
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return carouselItems;
                      }(),
                    );
                  }
                },
              )
            ],
          )
        ],
      ),
    );
  }
}
