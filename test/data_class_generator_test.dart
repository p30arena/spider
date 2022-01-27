/*
 * Copyright © 2020 Birju Vachhani
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';
import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:spider/src/dart_class_generator.dart';
import 'package:spider/src/process_terminator.dart';
import 'package:spider/src/utils.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

@GenerateMocks([ProcessTerminator])
void main() {
  final MockProcessTerminator processTerminatorMock = MockProcessTerminator();
  const Map<String, dynamic> testConfig = {
    "generate_tests": false,
    "no_comments": true,
    "export": true,
    "use_part_of": false,
    "use_references_list": false,
    "package": "resources",
    "groups": [
      {
        "path": "assets/images",
        "class_name": "Assets",
        "types": ["jpg", "jpeg", "png", "webp", "gif", "bmp", "wbmp"]
      }
    ]
  };

  group('process tests', () {
    setUp(() {
      ProcessTerminator.setMock(processTerminatorMock);
    });

    test('asset generation test #1', () async {
      createTestConfigs(testConfig);
      createTestAssets();

      var config = parseConfig('');
      expect(config, isNotNull,
          reason: 'valid config file should not return null but it did.');

      final generator =
          DartClassGenerator(config!.groups.first, config.globals);

      generator.process();
      verifyNever(processTerminatorMock.terminate(any, any));
      final genFile = File(p.join('lib', 'resources', 'assets.dart'));
      expect(genFile.existsSync(), isTrue);

      final classContent = genFile.readAsStringSync();

      expect(classContent, contains('class Assets'));
      expect(classContent, contains('static const String test1'));
      expect(classContent, contains('static const String test2'));
      expect(classContent, contains('assets/images/test1.png'));
      expect(classContent, contains('assets/images/test2.png'));
    });

    test('asset generation test - comments', () async {
      createTestConfigs(testConfig.copyWith({
        'no_comments': false,
      }));
      createTestAssets();

      var config = parseConfig('');
      expect(config, isNotNull,
          reason: 'valid config file should not return null but it did.');

      final generator =
          DartClassGenerator(config!.groups.first, config.globals);

      generator.process();
      verifyNever(processTerminatorMock.terminate(any, any));
      final genFile = File(p.join('lib', 'resources', 'assets.dart'));
      expect(genFile.existsSync(), isTrue);

      final classContent = genFile.readAsStringSync();

      expect(classContent, contains('class Assets'));
      expect(classContent, contains('static const String test1'));
      expect(classContent, contains('static const String test2'));
      expect(classContent, contains('assets/images/test1.png'));
      expect(classContent, contains('assets/images/test2.png'));
      expect(classContent, contains('// Generated by spider'));
    });

    test('asset generation test no list of references', () async {
      createTestConfigs(testConfig.copyWith({"use_references_list": true}));
      createTestAssets();

      var config = parseConfig('');
      expect(config, isNotNull,
          reason: 'valid config file should not return null but it did.');

      final generator =
          DartClassGenerator(config!.groups.first, config.globals);

      generator.process();
      verifyNever(processTerminatorMock.terminate(any, any));
      final genFile = File(p.join('lib', 'resources', 'assets.dart'));
      expect(genFile.existsSync(), isTrue);

      final classContent = genFile.readAsStringSync();

      expect(classContent, contains('class Assets'));
      expect(classContent, contains('static const String test1'));
      expect(classContent, contains('static const String test2'));
      expect(classContent, contains('assets/images/test1.png'));
      expect(classContent, contains('assets/images/test2.png'));
      expect(classContent, contains('static const List<String> values'));
    });

    test('asset generation test - watch', () async {
      createTestConfigs(testConfig.copyWith({
        'no_comments': false,
      }));
      createTestAssets();

      var config = parseConfig('');
      expect(config, isNotNull,
          reason: 'valid config file should not return null but it did.');

      final generator =
          DartClassGenerator(config!.groups.first, config.globals);

      void proc() async {
        generator.initAndStart(true, false);
      }

      proc();
      await Future.delayed(Duration(seconds: 5));

      verifyNever(processTerminatorMock.terminate(any, any));
      final genFile = File(p.join('lib', 'resources', 'assets.dart'));
      expect(genFile.existsSync(), isTrue);

      String classContent = genFile.readAsStringSync();

      expect(classContent, contains('class Assets'));
      expect(classContent, contains('static const String test1'));
      expect(classContent, contains('static const String test2'));
      expect(classContent, contains('assets/images/test1.png'));
      expect(classContent, contains('assets/images/test2.png'));
      expect(classContent, contains('// Generated by spider'));

      final newFile = File(p.join('assets', 'images', 'test3.png'));
      newFile.createSync();
      expect(newFile.existsSync(), isTrue);

      await Future.delayed(Duration(seconds: 5));
      classContent = genFile.readAsStringSync();

      expect(classContent, contains('static const String test3'));
      expect(classContent, contains('assets/images/test3.png'));

      generator.cancelSubscriptions();
    });

    test('asset generation test - smart watch', () async {
      createTestConfigs(testConfig.copyWith({
        'no_comments': false,
        "groups": [
          {
            "path": "assets/images",
            "class_name": "Assets",
            "types": ["jpg", "jpeg", "png", "webp", "gif", "bmp", "wbmp"]
          },
          {
            "path": "assets/fonts",
            "class_name": "Fonts",
          }
        ]
      }));
      createTestAssets();
      createMoreTestAssets();

      var config = parseConfig('');
      expect(config, isNotNull,
          reason: 'valid config file should not return null but it did.');

      final generator1 =
          DartClassGenerator(config!.groups.first, config.globals);

      final generator2 = DartClassGenerator(config.groups[1], config.globals);

      void proc1() async {
        generator1.initAndStart(false, true);
      }

      void proc2() async {
        generator2.initAndStart(false, true);
      }

      proc1();
      proc2();
      await Future.delayed(Duration(seconds: 5));

      verifyNever(processTerminatorMock.terminate(any, any));
      final genFile = File(p.join('lib', 'resources', 'fonts.dart'));
      expect(genFile.existsSync(), isTrue);

      String classContent = genFile.readAsStringSync();

      expect(classContent, contains('class Fonts'));
      expect(classContent, contains('static const String test1'));
      expect(classContent, contains('static const String test2'));
      expect(classContent, contains('assets/fonts/test1.otf'));
      expect(classContent, contains('assets/fonts/test2.otf'));

      final String timestamp = genFile.readAsLinesSync().first;

      final newFile = File(p.join('assets', 'images', 'test3.png'));
      newFile.createSync();
      expect(newFile.existsSync(), isTrue);

      await Future.delayed(Duration(seconds: 5));
      classContent =
          File(p.join('lib', 'resources', 'assets.dart')).readAsStringSync();

      expect(classContent, contains('static const String test3'));
      expect(classContent, contains('assets/images/test3.png'));

      final String newTimestamp = genFile.readAsLinesSync().first;
      expect(timestamp, equals(newTimestamp));

      generator1.cancelSubscriptions();
      generator2.cancelSubscriptions();
    });

    test('asset generation test - test cases', () async {
      createTestConfigs(testConfig.copyWith({
        'generate_tests': true,
      }));

      createTestAssets();
      var config = parseConfig('');
      expect(config, isNotNull,
          reason: 'valid config file should not return null but it did.');

      final generator =
          DartClassGenerator(config!.groups.first, config.globals);

      generator.process();
      verifyNever(processTerminatorMock.terminate(any, any));
      final genFile = File(p.join('lib', 'resources', 'assets.dart'));
      expect(genFile.existsSync(), isTrue);

      final classContent = genFile.readAsStringSync();

      expect(classContent, contains('class Assets'));
      expect(classContent, contains('static const String test1'));
      expect(classContent, contains('static const String test2'));
      expect(classContent, contains('assets/images/test1.png'));
      expect(classContent, contains('assets/images/test2.png'));

      final genTestFile = File(p.join('test', 'assets_test.dart'));
      expect(genTestFile.existsSync(), isTrue);

      addTearDown(() => genTestFile.deleteSync());

      final testContent = genTestFile.readAsStringSync();

      expect(testContent, contains("import 'dart:io';"));
      expect(testContent, contains("import 'package:test/test.dart';"));
      expect(testContent,
          contains("import 'package:spider/resources/assets.dart';"));
      expect(testContent, contains("void main()"));
      expect(testContent,
          contains("expect(File(Assets.test1).existsSync(), true);"));
      expect(testContent,
          contains("expect(File(Assets.test2).existsSync(), true);"));
    });

    tearDown(() {
      ProcessTerminator.clearMock();
      reset(processTerminatorMock);
      deleteTestAssets();
      deleteConfigFiles();
      deleteGeneratedRefs();
    });
  });
}
