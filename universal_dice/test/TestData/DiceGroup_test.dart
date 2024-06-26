import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:universal_dice/Data/Dice.dart';
import 'package:universal_dice/Data/DiceGroup.dart';

import '../DatabaseForTests.dart';
import 'equalsData.dart';

void main() async {
  Future<Directory> createDiceGroupDirByNumber(Database database, int number) {
    return Directory("${database.dir.path}/$number").create(recursive: true);
  }

  Future<DiceGroup> createDiceGroup(Database database, int number) async {
    Directory diceDir = await createDiceGroupDirByNumber(database, number);

    return DiceGroup.creatingNewDiceGroup(diceDir);
  }

  Future<DiceGroup> createFillDiceGroup(Database database, int length) {
    return createDiceGroup(database, 2).then((diceGroup) {
      return Future.forEach(List<Future<void> Function()>.generate(length, (index) => diceGroup.addStandardDice), (asyncFoo) => asyncFoo()).then((_) => diceGroup);
    });
  }

  Future<DiceGroup> createModifiedDiceGroup(Database database, int length) {
    expect(length, greaterThan(2), reason: "ошибка при createModifiedDiceGroup() слишком маленькая длина");
    return createFillDiceGroup(database, length).then((diceGroup) => diceGroup.removeDiceAt(0).then((_) => diceGroup.addStandardDice().then((_) => diceGroup)));
  }

  test("Создание стандартной группы DiceGroup.creatingNewDiceGroup()", () async {
    Database database = await Database.createRand();
    DiceGroup diceGroup = await createDiceGroup(database, 0);

    expect(diceGroup.length, 0);
    expect(diceGroup.name, "Группа 1");
    Directory diceDir = await createDiceGroupDirByNumber(database, 0);
    expect(diceGroup.dirThisDiceGroup.path, equals(diceDir.path));

    await database.clear();
  });

  test("Изменение названия на нормальное DiceGroup.setName()", () async {
    Database database = await Database.createRand();
    DiceGroup diceGroup = await createDiceGroup(database, 0);

    await diceGroup.setName("Новое имя");

    expect(diceGroup.name, "Новое имя");

    await database.clear();
  });

  test("Изменение названия на пустое DiceGroup.setName()", () async {
    Database database = await Database.createRand();
    DiceGroup diceGroup = await createDiceGroup(database, 0);

    await diceGroup.setName("");

    expect(diceGroup.name, "");

    await database.clear();
  });

  test("Добавление стандартного кубик DiceGroup.addStandardDice", () async {
    Database database = await Database.createRand();
    DiceGroup diceGroup = await createDiceGroup(database, 0);

    expect(diceGroup.length, 0);
    await diceGroup.addStandardDice();

    expect(diceGroup.length, 1, reason: "Стандартный кубик не добавился так как length не изменился");

    await database.clear();
  });

  test("Изменение состояния DiceGroup.invertState()", () async {
    Database database = await Database.createRand();
    int number = 3;
    DiceGroup diceGroup = await createFillDiceGroup(database, number);

    expect(diceGroup.length, number);
    for (int i = 0; i < number; i++) {
      expect(diceGroup[i].state, false, reason: "не совпадает state у кубика номер $i перед изменением}");
    }

    await diceGroup.invertState();

    for (int i = 0; i < number; i++) {
      expect(diceGroup[i].state, true, reason: "не совпадает state у кубика номер $i после изменения}");
    }

    await database.clear();
  });

  test("Изменение состояния DiceGroup.setState()", () async {
    Database database = await Database.createRand();

    int number = 3;
    DiceGroup diceGroup = await createFillDiceGroup(database, number);

    expect(diceGroup.length, number);
    for (int i = 0; i < number; i++) {
      expect(diceGroup[i].state, false, reason: "не совпадает state у кубика номер $i перед изменением}");
    }

    await diceGroup.setState(true);

    for (int i = 0; i < number; i++) {
      expect(diceGroup[i].state, true, reason: "не совпадает state у кубика номер $i после изменения}");
    }

    await diceGroup.setState(true);

    for (int i = 0; i < number; i++) {
      expect(diceGroup[i].state, true, reason: "не совпадает state у кубика номер $i после второго изменения}");
    }

    await database.clear();
  });

  test("Удаление кубиков DiceGroup.removeDiceAt()", () async {
    Database database = await Database.createRand();
    int startNumber = 3;
    DiceGroup diceGroup = await createFillDiceGroup(database, startNumber);

    await diceGroup[1].setState(true);
    int numberFacesDeleted = 3;
    await diceGroup[1].setNumberFaces(numberFacesDeleted);
    bool res = await diceGroup.removeDiceAt(1);

    expect(diceGroup.length, startNumber - 1, reason: "количество кубиков не уменьшилось");
    expect(res, true, reason: "Удаляемый кубик остался");
    expect(diceGroup[1].numberFaces, 6, reason: "Удаляемый кубик остался");

    await database.clear();
  });

  test("Создание группы из файлов DiceGroup.creatingFromFiles()", () async {
    Database database = await Database.createRand();
    int number = 3;
    DiceGroup diceGroupOrigin = await createModifiedDiceGroup(database, number);

    DiceGroup diceGroupNew = await DiceGroup.creatingFromFiles(diceGroupOrigin.dirThisDiceGroup);

    equalsDiceGroup(diceGroupNew, diceGroupOrigin);

    await database.clear();
  });

  test("Замена кубиков DiceGroup.replaceDiceAt()", () async {
    Database database = await Database.createRand();
    int startNumber = 3;
    DiceGroup diceGroup = await createFillDiceGroup(database, startNumber);

    Database databaseNewDice = await Database.createRand();
    Dice newDice = await Dice.creatingNewDice(databaseNewDice.dir);
    int numberFacesNew = 2;
    await newDice.setNumberFaces(numberFacesNew);

    int numberFacesReplaced = 3;
    await diceGroup[1].setNumberFaces(numberFacesReplaced);
    await diceGroup.replaceDiceAt(1, newDice);

    expect(diceGroup.length, startNumber, reason: "количество кубиков изменилось");
    expect(diceGroup[1].numberFaces, numberFacesNew, reason: "Заменяемый кубик не изменился");

    await database.clear();
    await databaseNewDice.clear();
  });

  test("Дублирование кубиков DiceGroup.duplicateDice()", () async {
    Database database = await Database.createRand();
    int number = 7;
    DiceGroup diceGroup = await createFillDiceGroup(database, number);

    int numberFacesDuplicate = 4;
    await diceGroup[1].setNumberFaces(numberFacesDuplicate);

    await diceGroup.duplicateDice(1);

    expect(diceGroup.length, number + 1, reason: "length не изменился");
    expect(diceGroup[diceGroup.length - 1].numberFaces, numberFacesDuplicate, reason: "кубик не такой же как дублируемый");
    await database.clear();
  });

  test("Получить список всех активных кубиков get DiceGroup.allSelectedDice", () async {
    Database database = await Database.createRand();
    DiceGroup diceGroup = await createModifiedDiceGroup(database, 4);

    int numberTes = 0;
    Future<void> checkSelectedDice(List<int> list) async {
      await diceGroup.setState(false);
      for (int index in list) {
        await diceGroup[index].setState(true);
      }
      List<Dice> selectedDice = diceGroup.allSelectedDice;

      expect(selectedDice.length, list.length, reason: "length не совпадают. Возможно были выбраны не все активные кубики в подтесте номер $numberTes");

      int i = 0;
      for (int index in list) {
        expect(selectedDice[i].dirThisDice.path, diceGroup[index].dirThisDice.path, reason: "Выбраны кубики, которые не были активными. Не был активным кубик норме $index в подтесте номер $numberTes");
        i++;
      }
      numberTes++;
    }

    await checkSelectedDice([0, 1, 3]);
    await checkSelectedDice([1, 2]);

    database.clear();
  });
}
