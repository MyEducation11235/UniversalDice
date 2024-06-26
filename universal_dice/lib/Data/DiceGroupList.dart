import 'dart:io';

import 'package:universal_dice/Functions/FileReading.dart';

import 'package:universal_dice/Data/Dice.dart';
import 'package:universal_dice/Data/DiceGroup.dart';

/// Класс - список всех групп
class DiceGroupList {
  /// Приватный конструктор
  DiceGroupList._(Directory dirThisDiceGroupList) : _dirThisDiceGroupList = dirThisDiceGroupList {
    _diceGroupList = List<DiceGroup>.empty(growable: true);
  }

  /// Конструктор читающий данные из памяти
  static Future<DiceGroupList> creatingFromFiles(Directory dirThisDiceGroupList) async {
    DiceGroupList resultDiceGroupList = DiceGroupList._(dirThisDiceGroupList);
    return Future.wait([
      resultDiceGroupList._readDiceGroupList(),
    ]).then((_) async {
      if (resultDiceGroupList.length == 0) {
        // добавление стандартной группы если ни одного кубика не существует
        await resultDiceGroupList.addNewDiceGroup();

        await resultDiceGroupList[0].addStandardDice();
        await resultDiceGroupList[0].addStandardDice();
        await resultDiceGroupList[0].addStandardDice();

        return Future.wait([
          resultDiceGroupList[0].setName("Стандартная группа"),
          resultDiceGroupList[0][0].setNumberFaces(2),
          resultDiceGroupList[0][2].setNumberFaces(10),
        ]).then((value) => resultDiceGroupList);
      }

      return resultDiceGroupList;
    });
  }

  /// Чтение всех групп
  Future<void> _readDiceGroupList() {
    final List<FileSystemEntity> entities = _dirThisDiceGroupList.listSync(recursive: false).toList();
    final List<Directory> allDirDiceGroup = entities.whereType<Directory>().toList();

    List<DiceGroup?> tmpDiceGroupList = List<DiceGroup?>.filled(allDirDiceGroup.length, null, growable: true);

    return Future.wait(Iterable<Future<void>>.generate(allDirDiceGroup.length, (i) {
      int? numberFromDirName = getNumberFromFileSystemEntityName(allDirDiceGroup[i]);
      if (numberFromDirName != null) {
        return DiceGroup.creatingFromFiles(allDirDiceGroup[i]).then(
          (diceGroup) {
            if (numberFromDirName >= tmpDiceGroupList.length) {
              tmpDiceGroupList.length = numberFromDirName + 1;
            }
            tmpDiceGroupList[numberFromDirName] = diceGroup;
            // print("Read dirDiceGroup: ${allDirDiceGroup[i].path} to $numberFromDirName");
          },
        );
      }
      return Future(() => null);
    })).then((_) {
      for (DiceGroup? tmpDiceGroup in tmpDiceGroupList) {
        // копирование списка с убиранием null значений
        if (tmpDiceGroup != null) {
          // print("copy ${tmpDiceGroup.dirThisDiceGroup.path}");
          _diceGroupList.add(tmpDiceGroup);
        }
      }
      // print("all Read!");
    });
  }

  /// Дублирование группы и добавление её в конец списка
  Future<DiceGroup> duplicateDiceGroup(int index) {
    Directory newDir = _getDirNewDiceGroup();
    return copyDirectory(_diceGroupList[index].dirThisDiceGroup, newDir).then((_) {
      return DiceGroup.creatingFromFiles(newDir).then((diceGroup) {
        _diceGroupList.add(diceGroup);
        return diceGroup;
      });
    });
  }

  /// Добавление в конец списка пустой группы
  Future<DiceGroup> addNewDiceGroup() {
    return _getDirNewDiceGroup().create().then((dir) => DiceGroup.creatingNewDiceGroup(dir).then(
          (diceGroup) {
            _diceGroupList.add(diceGroup);
            return _diceGroupList.last;
          },
        ));
  }

  /// Полное удаление группы из списка
  Future<bool> removeDiceGroupAt([int? index]) {
    index ??= _diceGroupList.length - 1;
    return _diceGroupList[index].dirThisDiceGroup.delete(recursive: true).then((_) {
      bool res = _diceGroupList[index!].state;
      _diceGroupList.removeAt(index);
      return res;
    });
  }

  /// Получить путь до группы по индексу
  Directory _getDirNewDiceGroup() {
    return _getDirDiceGroup(length);
  }

  Directory _getDirDiceGroup(int index) {
    final int fileNumber = _diceGroupList.isEmpty ? 0 : index - length + 1 + getNumberFromFileSystemEntityName(_diceGroupList.last.dirThisDiceGroup)!; // получить номер в названии файла
    return Directory("${_dirThisDiceGroupList.path}/$fileNumber");
  }

  /// Получить группу
  DiceGroup operator [](int index) {
    return _diceGroupList[index];
  }

  /// Получить список всех выбранных граней в формате удобном для вывода
  List<SelectedDiceGroup> get allSelectedDiceGroup {
    List<SelectedDiceGroup> resultAllSelectedDiceGroup = List<SelectedDiceGroup>.empty(growable: true);
    for (DiceGroup diceGroup in _diceGroupList) {
      List<Dice> allSelectedDice = diceGroup.allSelectedDice;
      if (allSelectedDice.isNotEmpty) {
        resultAllSelectedDiceGroup.add(SelectedDiceGroup(
          diceGroup: diceGroup,
          allDice: allSelectedDice,
        ));
      }
    }
    return resultAllSelectedDiceGroup;
  }

  /// Получить количество граней
  int get length {
    return _diceGroupList.length;
  }

  late List<DiceGroup> _diceGroupList; // список всех групп
  final Directory _dirThisDiceGroupList; // директория со всеми группами
}

/// Структура - необходимые для отображения данные использованной группы
class SelectedDiceGroup {
  SelectedDiceGroup({required this.diceGroup, required this.allDice});

  int get length {
    return allDice.length;
  }

  DiceGroup diceGroup;
  List<Dice> allDice;
}

late DiceGroupList diceGroupList; // список всех групп. Единственный и неповторимый
