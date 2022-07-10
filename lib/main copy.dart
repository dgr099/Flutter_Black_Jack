import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Black Jack Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double aBet;
  int _counter = 0; /*contador de puntos*/
  int _dealer = 0; /*puntos del dealer */
  double money = 200.0;
  double bet = 0.0;
  double multiplier = 0;
  bool turn = true; /*para saber de quien es el turno*/
  bool win = true; /*variable para definir si ha ganado, perdido, o en juego*/
  bool finish = false;
  bool hitPhase = false;
  Random r = new Random(); /*generador de randoms*/
  GestureDetector hit;
  GestureDetector stand;
  bool pres = false;

  @override
  void initState() {
    turn = true;
    win = false;
    finish = false;
    aBet = 0;
    _counter = 0;
    _dealer = 0;
    money = 200.0;
    bet = 0.0;
    hit = GestureDetector(
        child: Text(
          'Hit',
          textDirection: TextDirection.ltr,
        ),
        onTap: () {
          _incrementCounter();
          hitPhase = true;
        });

    stand = GestureDetector(
      child: Text(
        'Stand',
        textDirection: TextDirection.rtl,
      ),
      onTap: croupierTurn,
    );
    super.initState();
  }

  Widget mensajePerder(BuildContext context) {
    return AlertDialog(
      title: Text(
        "You lose",
        textDirection: TextDirection.ltr,
      ),
      content: Text(
        "To win at black jack you must get closer to 21 points than the dealer, if you go over or stay further than him, you lose",
        textDirection: TextDirection.ltr,
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(end); /*no actualiza el estado hasta que no da en ok*/
            },
            child: Text(
              "OK",
              textDirection: TextDirection.ltr,
            )),
      ],
    );
  }

  void mostrarMensajePerder() {
    /*showDialog(context: context, 
        builder: mensajePerder,
        barrierDismissible: false,
      );*/
  }

  int addRandomCart() {
    return r.nextInt(12) + 1; /*añade una carta al jugado*/
  }

  void addCartPlayer() {
    _counter += addRandomCart();
  }

  void addCartDealer() {
    _dealer += addRandomCart();
  }

  void end() {
    _counter = 0;
    _dealer = 0;
    turn = true;
    win = false;
    finish = false;
    hitPhase = false;
    bet = 0.0;
    multiplier = 0.0;
  }

  void _incrementCounter() async {
    if (!turn) return; /*si no es tu turno no hace nada*/
    setState(addCartPlayer);
    if (_counter > 21) {
      /*Si te pasas de los 21 muestra el mensaje de que ha perdido*/
      setState(() {
        turn = false;
        win = false;
        finish = true;
      });
      await Future.delayed(const Duration(seconds: 1, microseconds: 100));
      setState(end);
    }
  }

  void croupierTurn() async {
    setState(() {
      turn = false;
    }); /*simplemente para que se quiten los controles*/
    while (true) {
      await Future.delayed(const Duration(seconds: 1, microseconds: 100));
      setState(addCartDealer); /**añade una carta al dealer */
      /*si gana el dealer*/
      if (_dealer > 21) {
        /**si pierde el dealer */
        setState(() {
          win = true;
          money += bet * multiplier;
          finish = true;
        });
        break;
      } else if (_dealer >= _counter) {
        setState(() {
          win = false;
          finish = true;
        });
        break;
      }
    }
    await Future.delayed(const Duration(seconds: 1, microseconds: 100));
    setState(end);
  }

  void addBet() async {
    if (aBet == 0 || aBet == null || !turn) {
      return;
    }
    if (pres == true)
      return; /*semáforo (no conozco como es en dart, problemas de concurrencia :( )*/
    pres = true;
    while (pres == true) {
      if (aBet > this.money) {
        return;
      }
      this.money -= aBet;
      this.bet += aBet;
      double d = (log(this.bet) / log(2));
      multiplier = 1 + d * 0.05;
      setState(() {});
      await Future.delayed(Duration(
          milliseconds: 200)); /*espero para que actualice la interfaz gráfica*/
    }
    pres = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.red[900],
        bottomNavigationBar: Container(
          height: 100,
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "You: $_counter",
                  textDirection: TextDirection.ltr,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                ),
                Text(
                  "Dealer: $_dealer",
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
            this.turn
                ? Column(children: [
                    Row(
                        //crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          this.hit,
                          Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.0)),
                          this.stand,
                        ]),
                    !this.hitPhase
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              //Padding(padding: EdgeInsets.only(left: 50)),
                              Padding(padding: EdgeInsets.only(left: 10)),
                              Listener(
                                onPointerDown: (details) {
                                  this.addBet();
                                },
                                onPointerUp: (details) {
                                  this.pres = false;
                                },
                                child: Container(
                                  height: 50,
                                  width: 30,
                                  decoration: new BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.greenAccent[100]),
                                  child: Icon(Icons.add),
                                ),
                              ),
                              Padding(padding: EdgeInsets.only(right: 10)),
                              Expanded(
                                  //width: 50.0,
                                child: TextField(
                                  autofocus: true,
                                  //decoration: new InputDecoration(
                                  //labelText: "Enter the amount to add to the bet"),
                                  keyboardType: TextInputType.number,
                                  onChanged: (texto) {
                                  aBet = double.parse(texto);
                                },
                              ))
                            ],
                          )
                        : Container()
                  ])
                : Container(),
          ]),
        ),
        body: Column(children: [
          SafeArea(
            child: Row(
              children: [
                Text(
                  "Money: " + money.toStringAsPrecision(3),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                ),
                Text(
                  "x " + multiplier.toStringAsPrecision(3),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                )
              ],
              mainAxisAlignment: MainAxisAlignment.spaceAround,
            ),
          ),
          Text(
            "Bet: $bet",
            textDirection: TextDirection.ltr,
          ),
          Center(
            child: /*!finish
                ? Container()
                : Container(
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: win
                          ? Text(
                              "You Win :))",
                              textDirection: TextDirection.ltr,
                            )
                          : Text("You Lose :))",
                              textDirection: TextDirection.ltr),
                    ),
                    width: MediaQuery.of(context).size.width * 3 / 4,
                  ),*/
                  Container(
                    width: 100,
                    child:
                  PlayingCardView(card: PlayingCard(Suit.diamonds, CardValue.eight), showBack: true,))
          )
        ]));
  }

}
