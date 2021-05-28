import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namu_diary/api.dart';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';

extension filterTreeName on String {
  bool isTreeName(List<String> treeDict) {
    final data = treeDict;
    var i = 0;
    for (; i < data.length && !(data[i] == this || this.contains("나무")); ++i);
    if (i < data.length) {
      return true;
    } else {
      return false;
    }
  }
}

class DictionaryProvider extends ChangeNotifier {
  Map<String, String> dictionary = {};
  List<String> treeDict = [];
  List<String> treeNames = [];
  List<String> treeExplanation = [];
  bool isTreeNameLoading = false;

  Future loadDic() async {
    treeDict = (await rootBundle.loadString('assets/treename.txt')).split('\n');
    final List<String> treedic =
        (await rootBundle.loadString('assets/treedic.txt')).split(', ');
    for (var keyVal in treedic) {
      final splitted = keyVal.split(': ');
      if (splitted.length > 1) {
        final key = splitted[0];
        final value = splitted[1];
        dictionary.putIfAbsent(key, () => value);
      }
    }
  }

  Future identify(filePath) async {
    treeNames.clear();
    isTreeNameLoading = true;
    final bytes = File(filePath).readAsBytesSync();
    String img64 = base64Encode(bytes);
    final response = await http.post(
      Uri.https('api.plant.id', '/v2/identify'),
      headers: {"Content-Type": "application/json", "Api-Key": apiKey},
      body: jsonEncode(
        {
          "images": [img64],
          "modifiers": ["similar_images"],
          "plant_details": [
            "common_names",
            "url",
            "wiki_description",
            "taxonomy"
          ]
        },
      ),
    );
    final suggestions = json.decode(response.body)['suggestions'];
    for (var i = 0; i < suggestions.length; ++i) {
      final xml2json = Xml2Json();
      final _res = await http.get(
        Uri.http(
          'openapi.nature.go.kr',
          '/openapi/service/rest/PlantService/plntIlstrSearch',
          {
            'serviceKey': treeSearchApiKey,
            'st': '2',
            'sw': suggestions[i]['plant_name'],
            'dateGbn': '',
            'dateFrom': '',
            'numOfRows': '10',
            'pageNo': '1',
          },
        ),
      );
      xml2json.parse(utf8.decode(_res.bodyBytes));
      final data =
          json.decode(xml2json.toBadgerfish())['response']['body']['items'];
      if (data.length > 0) {
        for (var item in Map.castFrom(data).values) {
          try {
            for (var _item in item) {
              treeNames.add(Map.from(_item['plantGnrlNm']).values.elementAt(0));
            }
          } catch (e) {
            treeNames.add(
                Map.from(Map.from(item)['plantGnrlNm']).values.elementAt(0));
          }
        }
      }
      try {
        final _suggestions = suggestions[i]['plant_details']['common_names'];
        if (_suggestions != null && _suggestions.length > 0) {
          for (var name in _suggestions) {
            final response = await http.get(
              Uri.https(
                'ko.wikipedia.org',
                '/w/api.php',
                {
                  'action': 'query',
                  'prop': 'extracts',
                  'origin': '*',
                  'format': 'json',
                  'generator': 'search',
                  'gsrnamespace': '0',
                  'gsrlimit': '1',
                  'gsrsearch': name,
                },
              ),
            );
            final explanation = Map.castFrom(json.decode(response.body)).values;
            if (explanation.length > 1) {
              for (var el in explanation) {
                if (el.runtimeType != String) {
                  final boom = Map.castFrom(el);
                  if (boom.containsKey('pages')) {
                    final Map gatheredInfo =
                        Map.castFrom(Map.castFrom(boom['pages']).values.first);
                    if ((gatheredInfo['title'] as String)
                        .isTreeName(treeDict)) {
                      treeNames.add(gatheredInfo['title']);
                    }
                  }
                }
              }
            }
          }
        } else {
          print('null array cannot be iterated!');
        }
      } on Exception catch (e) {
        print("Fetch failed!");
        isTreeNameLoading = false;
      }
    }
    treeNames = treeNames.toSet().toList();
  }

  Future<List<String>> postSearch() async {
    treeExplanation.clear();
    for (var name in treeNames) {
      final response = await http.get(
        Uri.https(
          'ko.wikipedia.org',
          '/w/api.php',
          {
            'action': 'query',
            'prop': 'extracts',
            'origin': '*',
            'format': 'json',
            'generator': 'search',
            'gsrnamespace': '0',
            'gsrlimit': '1',
            'gsrsearch': name,
          },
        ),
      );
      final explanation = Map.castFrom(json.decode(response.body)).values;
      if (explanation.length > 1) {
        final searchList = List.from(explanation);
        String found;
        var i = 0;
        for (; i < searchList.length; ++i) {
          found = '';
          if (searchList[i].runtimeType != String) {
            final boom = Map.castFrom(searchList[i]);
            if (boom.containsKey('pages')) {
              final gatheredInfo =
                  Map.castFrom(Map.castFrom(boom['pages']).values.first);
              if (gatheredInfo['title'] == name) {
                found = gatheredInfo['extract'];
                break;
              }
            }
          }
        }
        if (i < searchList.length) {
          treeExplanation.add(found);
        } else {
          treeExplanation.add('검색결과 없음');
        }
      } else {
        treeExplanation.add('검색결과 없음');
      }
    }
    return treeExplanation;
  }

  clearTreeList() {
    treeNames.clear();
    isTreeNameLoading = false;
    notifyListeners();
  }

  findTree(filePath) async {
    await identify(filePath);
    isTreeNameLoading = false;
    notifyListeners();
  }
}
