import 'package:flutter/material.dart';

import 'package:universal_dice/Decoration/styles.dart';
import 'package:universal_dice/Decoration/icons.dart';

import 'package:universal_dice/Data/Dice.dart';
import 'package:universal_dice/Data/DiceGroup.dart';
import 'package:universal_dice/Data/DiceGroupList.dart';

import 'package:universal_dice/Widgets/ConfirmationBox.dart';
import 'package:universal_dice/Widgets/EditingDice.dart';
import 'package:universal_dice/Widgets/EditingDiceGroup.dart';

class DiceChooserView extends StatefulWidget {
  DiceChooserView({super.key, required this.onSelect, required this.onDelete, required this.onChange});

  final void Function() onSelect;
  final void Function() onDelete;
  final void Function() onChange;

  final List<bool> _displayedDictGroup = List<bool>.filled(diceGroupList.length, false, growable: true);

  Future<void> addStandardGroup_addDisplayedDictGroup([bool displayedState = true]) {
    _displayedDictGroup.add(displayedState);
    return diceGroupList.addStandardGroup();
  }

  Future<void> duplicateDiceGroup_addDisplayedDictGroup(int index, [bool displayedState = true]) {
    _displayedDictGroup.add(displayedState);
    return diceGroupList.duplicateDiceGroup(index);
  }

  Future<void> removeDiceGroupAt_removeDisplayedDictGroupAt(int index) {
    _displayedDictGroup.removeAt(index);
    return diceGroupList.removeDiceGroupAt(index);
  }

  @override
  _DiceChooserView createState() => _DiceChooserView();
}

class _DiceChooserView extends State<DiceChooserView> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildTitle(),
          _buildDictGroupList(),
          _buildingFooter(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 25, 10, 10),
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: Text(
          "Выберите используемые кубики",
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDictGroupList() {
    return Expanded(
      child: SingleChildScrollView(
        child: ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              widget._displayedDictGroup[index] = !widget._displayedDictGroup[index];

              /*for(int i = 0; i < diceGroupList.length; i++){
                print("i = $i: ${diceGroupList[i].name}");
              }*/
            });
          },
          children: List<ExpansionPanel>.generate(diceGroupList.length, (index) {
            DiceGroup diceGroup = diceGroupList[index];
            return ExpansionPanel(
              canTapOnHeader: true,
              isExpanded: widget._displayedDictGroup[index],
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  title: Text(diceGroup.name, textAlign: TextAlign.center),
                  titleTextStyle: Theme.of(context).textTheme.titleMedium,
                  leading: PopupMenuButton<int>(
                    position: PopupMenuPosition.under,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                    child: const Icon(iconButtonModeDiceGroup),
                    itemBuilder: (context) => [
                      _buildingMoreMenuElement(
                          icon: Icon(iconButtonEditDiceGroup, color: ColorButtonForeground),
                          text: "Редактировать",
                          buttonStyle: buttonStyleDefault,
                          onPressed: () {
                            showEditingDiceGroup(context, diceGroup).then((status) {
                              if (status) {
                                Navigator.pop(context);
                                setState(() {});
                                widget.onChange();
                              }
                            });
                          }),
                      _buildingMoreMenuElement(
                        icon: const Icon(iconButtonDuplicateDiceGroup, color: ColorButtonPressedOK),
                        text: "Дублировать",
                        buttonStyle: buttonStyleOK,
                        onPressed: () {
                          Navigator.pop(context);
                          widget.duplicateDiceGroup_duplicateDisplayedDictGroup(index).then((_) {
                            setState(() {});
                            widget.onChange();
                          });
                        },
                      ),
                      _buildingMoreMenuElement(
                        icon: const Icon(iconButtonDeleteDiceGroup, color: ColorButtonPressedOFF),
                        text: "Удалить",
                        buttonStyle: buttonStyleOFF,
                        onPressed: () {
                          showConfirmationBox(
                              context: context,
                              titleText: 'Удалить группу кубиков?',
                              contentText: "Группа \"${diceGroup.name}\" будет удалена со всем содержимым.",
                              textOK: 'Удалить группу',
                              textOFF: 'Отмена',
                              functionOK: () {
                                widget.removeDiceGroupAt_removeDisplayedDictGroupAt(index).then((_) {
                                  Navigator.pop(context);
                                  setState(() {});
                                  widget.onDelete();
                                });
                              });
                        },
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: diceGroup.state
                        ? Icon(
                            iconRadioButtonChecked,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : Icon(
                            iconRadioButtonUnchecked,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    onPressed: () => setState(() {
                      diceGroup.invertState();
                      if (diceGroup.state) {
                        widget._displayedDictGroup[index] = true;
                      }
                      widget.onSelect();
                    }),
                  ),
                );
              },
              body: _buildDictList(diceGroup), //Expanded(child: Text("lol")),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDictList(DiceGroup diceGroup) {
    return Container(
        padding: const EdgeInsets.only(left: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(diceGroup.length, (int index) {
                Dice dice = diceGroup[index];
                return ListTile(
                  title: Container(
                    alignment: Alignment.center,
                    child: dice.getFace(dimension: Theme.of(context).textTheme.titleSmall!.fontSize!),
                  ),
                  leading: PopupMenuButton<int>(
                    position: PopupMenuPosition.under,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                    child: const Icon(iconButtonModeDice),
                    itemBuilder: (context) => [
                      _buildingMoreMenuElement(
                          icon: Icon(iconButtonEditDice, color: ColorButtonForeground),
                          text: "Редактировать",
                          buttonStyle: buttonStyleDefault,
                          onPressed: () {
                            showEditingDice(context, diceGroup, index).then((status) {
                              if (status) {
                                Navigator.pop(context);
                                setState(() {});
                                widget.onChange();
                              }
                            });
                          }),
                      _buildingMoreMenuElement(
                        icon: const Icon(iconButtonDuplicateDice, color: ColorButtonPressedOK),
                        text: "Дублировать",
                        buttonStyle: buttonStyleOK,
                        onPressed: () {
                          Navigator.pop(context);
                          diceGroup.duplicateDice(index).then((_) {
                            setState(() {});
                            widget.onChange();
                          });
                        },
                      ),
                      _buildingMoreMenuElement(
                        icon: const Icon(iconButtonDeleteDice, color: ColorButtonPressedOFF),
                        text: "Удалить",
                        buttonStyle: buttonStyleOFF,
                        onPressed: () {
                          showConfirmationBox(
                              context: context,
                              titleText: 'Удалить кубик?',
                              contentText: "Кубик с ${dice.numberFaces} гранями будет удалён.",
                              textOK: 'Удалить',
                              textOFF: 'Отмена',
                              functionOK: () {
                                diceGroup.removeDiceAt(index).then((_) {
                                  Navigator.pop(context);
                                  setState(() {});
                                  widget.onDelete();
                                });
                              });
                        },
                      ),
                    ],
                  ),
                  trailing: dice.state
                      ? Icon(
                          iconRadioButtonChecked,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Icon(
                          iconRadioButtonUnchecked,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  selected: dice.state,
                  onTap: () {
                    setState(() {
                      dice.invertState();
                    });
                    widget.onSelect();
                  },
                );
              }) +
              [
                TextButton(
                  style: buttonStyleOK.merge(
                    IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  child: ListTile(
                    title: Text("Новый кубик", textAlign: TextAlign.center),
                    titleTextStyle: Theme.of(context).textTheme.titleSmall?.merge(TextStyle(color: ColorButtonForeground)),
                    trailing: Icon(iconButtonAddDice, color: ColorButtonForeground),
                    leading: Icon(iconButtonAddDice, color: ColorButtonForeground),
                  ),
                  onPressed: () {
                    diceGroup.addStandardDice().then((_) {
                      setState(() {});
                      widget.onChange();
                    });
                  },
                ),
              ],
        ));
  }

  PopupMenuItem<int> _buildingMoreMenuElement({required Icon icon, required String text, required ButtonStyle buttonStyle, required void Function() onPressed}) {
    return PopupMenuItem<int>(
      enabled: false,
      child: TextButton(
        style: buttonStyle.merge(IconButton.styleFrom(padding: const EdgeInsets.fromLTRB(10, 0, 0, 3))),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            icon,
            const SizedBox(width: 10, height: 10),
            Text(text, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildingFooter() {
    return Container(
      padding: const EdgeInsets.only(bottom: 5),
      // color: ColorBackground,
      child: TextButton(
        style: buttonStyleOK.merge(
          IconButton.styleFrom(
            padding: EdgeInsets.zero,
          ),
        ),
        child: ListTile(
          title: const Text("Новая группа", textAlign: TextAlign.center),
          titleTextStyle: Theme.of(context).textTheme.titleSmall?.merge(TextStyle(color: ColorButtonForeground)),
          trailing: Icon(iconButtonAddDiceGroup, color: ColorButtonForeground),
          leading: Icon(iconButtonAddDiceGroup, color: ColorButtonForeground),
        ),
        onPressed: () {
          widget.addStandardGroup_addDisplayedDictGroup().then((_) {
            setState(() {});
            widget.onChange();
          });
        },
      ),
    );
  }
}