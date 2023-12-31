import 'dart:convert';
import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/svg.dart';
import 'package:linring_front_flutter/models/login_info.dart';
import 'package:linring_front_flutter/models/tagset_model.dart';
import 'package:http/http.dart' as http;
import 'package:linring_front_flutter/screens/matching_loading_screen.dart';
import 'package:linring_front_flutter/screens/tag_add_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class TagShowScreen extends StatefulWidget {
  final LoginInfo loginInfo;
  const TagShowScreen({required this.loginInfo, super.key});

  @override
  State createState() => _TagShowScreenState();
}

class _TagShowScreenState extends State<TagShowScreen> {
  late Future<List<Tagset>> _futureTagsets;
  @override
  void initState() {
    super.initState();
    updateRandomGreeting();
    _futureTagsets = _callAPI();
  }

  void refreshTagsets() {
    setState(() {
      _futureTagsets = _callAPI();
    });
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

  final List<String> greetings = [
    "안녕~ 나는 푸링이야\n태그를 추가해서 친구를 찾아볼까?",
    "좋은 하루~\n오늘은 어떤 친구를 만나게 될까?",
    "옆으로 넘기면\n새로운 태그를 추가할 수 있어",
    "태그는 3개까지 추가할 수 있어",
    "검색 토글을 꺼두면\n상대가 나를 검색 할 수 없어",
    "오늘은 누굴 만나게 될까?\n넘 기대돼!",
    "점 세 개를 누르면\n태그를 삭제할 수 있어",
    "날 보니까 푸딩이 먹고 싶다고?\n이런...",
    "무례한 친구를 만나면\n꼭 신고하도록 해",
    "다른 친구에게 채팅이 오면\n반갑게 맞이 해줘",
  ];

  String randomGreeting = "안녕~ 오늘은 어떤 친구를 만날까?";

  void updateRandomGreeting() {
    final random = Random();
    final index = random.nextInt(greetings.length);
    setState(
      () {
        randomGreeting = greetings[index];
      },
    );
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
            items: [
              {
                'index': 1,
                'url':
                    'https://possible-rowboat-b63.notion.site/1-9b881e69b70041f3a83b5df842dccfa0'
              },
              {
                'index': 2,
                'url':
                    'https://possible-rowboat-b63.notion.site/2-e0e5abaa8519470dbec0b1932455f5b6'
              },
            ].map(
              (item) {
                return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () => launchUrl(Uri.parse(item['url'].toString())),
                      child: SizedBox(
                        width: double.infinity,
                        child: Image(
                          fit: BoxFit.fitWidth,
                          image: AssetImage(
                              'assets/images/info_${item['index']}.png'),
                        ),
                      ),
                    );
                  },
                );
              },
            ).toList(),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    height: 110,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: SvgPicture.asset(
                              'assets/images/characters/char_puring.svg'),
                        ),
                        Container(
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
                          child: GestureDetector(
                            onTap: () {
                              updateRandomGreeting();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Text(
                                randomGreeting,
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 10),
                    child: const Text(
                      "나의 태그",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  FutureBuilder(
                    future: _futureTagsets,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                          color: Color(0xfffec2b5),
                        ));
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
                                TagCard(
                                  tag: tag,
                                  loginInfo: widget.loginInfo,
                                  onTagDeleted: refreshTagsets,
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
                                        borderRadius:
                                            BorderRadius.circular(20.0),
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
                                                    height: 1.5,
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
                                                alignment:
                                                    Alignment.centerRight,
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
              ),
            ),
          )
        ],
      ),
    );
  }
}

class TagCard extends StatefulWidget {
  final Tagset tag;
  final LoginInfo loginInfo;
  final Function onTagDeleted;

  const TagCard(
      {super.key,
      required this.tag,
      required this.loginInfo,
      required this.onTagDeleted});

  @override
  _TagCardState createState() => _TagCardState();
}

class _TagCardState extends State<TagCard> {
  late bool isActive;

  @override
  void initState() {
    super.initState();
    isActive = widget.tag.isActive;
  }

  Future<bool> _updateActiveState(Tagset tag) async {
    String apiAddress = dotenv.get("API_ADDRESS");
    final url = Uri.parse('$apiAddress/accounts/v2/tagset/${tag.id}/');
    final token = widget.loginInfo.access;
    final body = jsonEncode({
      "place": tag.place,
      "isSameDepartment": tag.isSameDepartment,
      "person": tag.person,
      "method": tag.method,
      "is_active": !(tag.isActive),
      "introduction": tag.introduction,
      "owner": widget.loginInfo.user.id
    });
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: body,
    );
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  void _deleteTag(int id) async {
    String apiAddress = dotenv.get("API_ADDRESS");
    final url = Uri.parse('$apiAddress/accounts/v2/tagset/$id/');
    final token = widget.loginInfo.access;

    await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );

    widget.onTagDeleted();
  }

  @override
  Widget build(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${widget.tag.place}에서\n${(widget.tag.isSameDepartment) ? "같은 과" : "다른 과"} ${widget.tag.person}랑\n${widget.tag.method}${widget.tag.method == "카페" ? "가기" : "하기"}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 24,
                          height: 1.5,
                        ),
                      ),
                      PopupMenuButton<int>(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 1,
                            child: Text('삭제하기'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 1) {
                            _deleteTag(widget.tag.id);
                          }
                        },
                        icon: const Icon(Icons.more_vert),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    widget.tag.introduction != null
                        ? "\"${widget.tag.introduction}\""
                        : "",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xff999999),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    children: [
                      const Text(
                        "상대방이 나를\n검색할 수 있어요.",
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xff999999),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: 80,
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: CupertinoSwitch(
                            activeColor: const Color(0xff57e554),
                            value: isActive,
                            onChanged: (value) {
                              isActive = value;
                              _updateActiveState(widget.tag);
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MatchingLoadingScreen(
                                  loginInfo: widget.loginInfo,
                                  myTagSet: widget.tag,
                                )),
                      );
                    },
                    child: const Icon(
                      Icons.search_rounded,
                      color: Color(0xfffec2b5),
                      size: 37,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
