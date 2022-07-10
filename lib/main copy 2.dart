import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';
import 'package:flip/flip.dart';

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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  Orientation last;
  GlobalKey keyMiMazo = GlobalKey();
  GlobalKey keyMazoDealer = GlobalKey();
  GlobalKey keyCarta = GlobalKey();
  Flip card;
  FlipController fController = FlipController(
    isFront: true,
  );

  ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.black, width: 1));

  AnimationController aControllerAngle;

  AnimationController aController;

  AnimationController aControllerSize;

  //Animation Controller

  Animation<double> tAnimationR;

  Animation<double> tAnimationAngle;

  Animation<double> tAnimationKeyBoard;

  Animation<double> tAnimationX;

  Animation<double> tAnimationY;

  Duration timeWait = Duration(microseconds: 700, milliseconds: 800);

  ///tiempo de espera entre que saca cartas el dealer

  double aBet;

  ///dinero establecido para añadir a la apuesta

  int _counter = 0;

  ///contador de puntos

  int _dealer = 0;

  ///puntos del dealer

  double money = 200.0;

  ///dinero del jugador

  double bet = 0.0;

  ///dinero apostado

  double multiplier = 0;

  ///multiplicador de apuesta

  bool turn = true;

  ///para saber de quien es el turno

  bool win = true;

  ///variable para definir si ha ganado, perdido, o en juego

  bool finish = false;

  ///variable para saber si ha terminado el juego

  bool hitPhase = false;

  ///variable para saber si ya terminó de apostar y está en la fase de pedir cartas

  Random r = new Random();

  ///generador de randoms

  GestureDetector hit;

  ///para el botón de hit

  GestureDetector stand;

  ///para el botón de stand

  bool pres = false;

  ///para saber si se mantiene presionado el boton

  List<PlayingCard> cartas = [];

  ///lista con todas las cartas cartas

  int index = 0;

  ///indice de donde sacar las cartas

  List<Widget> miMazo = [];

  ///Lista de cartas del mazo del jugador (con positioned para hacer el mazo)

  List<Widget> dealerMazo = [];

  Widget cartaMazo(bool back, double size) {
    return Container(
        height: size,
        child: PlayingCardView(
          card: cartas[index + 1],
          showBack: back,
          shape: shape,
        ));
  }

  Offset getOffset(GlobalKey origen, GlobalKey destino) {
    RenderBox box = origen.currentContext.findRenderObject();
    RenderBox box2 = destino.currentContext.findRenderObject();
    //if(box==null || box2==null) return Offset(0,0);
    Offset position1 = box.localToGlobal(Offset.zero);
    Offset position2 = box2.localToGlobal(Offset.zero);

    return position1 - position2;
  }

  AnimatedBuilder cartaMazoAnimada(Widget child) {
    return AnimatedBuilder(
      animation: aControllerAngle,
      builder: (BuildContext context, Widget child) {
        return Transform.rotate(
          angle: tAnimationAngle.value,
          child: Transform.translate(
              offset: Offset(tAnimationR.value, 0),
              child: AnimatedBuilder(
                  animation: aControllerSize,
                  builder: (BuildContext context, Widget child) {
                    return Transform.translate(
                      offset: Offset(-tAnimationKeyBoard.value, 0),
                      child: child,
                    );
                  },
                  child: child)),
        );
      },
      child: child,
    );
  }

  ///Lista de cartas del mazo del dealer (con positioned para hacer el mazo)
  ///
  ///para inicializar botones del hit, stand y las variables
  @override
  void initState() {
    aController = AnimationController(
      duration: timeWait,
      vsync: this,
    );

    aControllerAngle = AnimationController(
      duration: Duration(milliseconds: 580),
      vsync: this,
    );

    aControllerSize = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    tAnimationAngle =
        Tween<double>(begin: 0, end: pi / 2).animate(aControllerAngle);

    tAnimationR = Tween<double>(begin: 0, end: -25).animate(aControllerAngle);

    tAnimationKeyBoard =
        Tween<double>(begin: 0, end: 500).animate(aControllerSize);
    tAnimationKeyBoard =
        Tween<double>(begin: 0, end: 500).animate(aControllerSize);
    tAnimationX = Tween<double>(begin: 0, end: 0).animate(aController);
    tAnimationY = Tween<double>(begin: 0, end: 0).animate(aController);
    for (Suit s in Suit.values)

      ///añadimos todas las cartas a la baraja
      for (CardValue v in CardValue.values) cartas.add(PlayingCard(s, v));
    cartas.shuffle();

    ///barajamos los elementos de la baraja
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

  ///mensaje que se muestra cuando has perdido
  ///TODO
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
              setState(end);

              ///no actualiza el estado hasta que no da en ok
            },
            child: Text(
              "OK",
              textDirection: TextDirection.ltr,
            )),
      ],
    );
  }

  void mostrarMensajePerder() {
    showDialog(
      context: context,
      builder: mensajePerder,
      barrierDismissible: false,
    );
  }

  ///Método para dar una carta
  ///Retorna el valor de la carta dada
  int addRandomCard(List<Widget> mazo) {
    ++index;
    mazo.add(
      Positioned(
        child: Container(
            child: PlayingCardView(
              card: cartas[index],
              shape: shape,
            ),
            height: 120),
        left: mazo.length * 15.0,
      ),
    );
    return min(cartas.elementAt(index).value.index + 2, 10);
  }

  ///Método para dar una carta al jugador
  void addCardPlayer() {
    _counter += addRandomCard(miMazo);
    tAnimationX = Tween<double>(
            begin: 0,
            end: getOffset(keyCarta, keyMiMazo).dx - miMazo.length * 15.0)
        .animate(aController);
    tAnimationY =
        Tween<double>(begin: 0, end: getOffset(keyCarta, keyMiMazo).dy)
            .animate(aController);
    this.aController.forward();
  }

  ///Método para
  void addCardDealer() {
    _dealer += addRandomCard(dealerMazo);
  }

  ///reinicia los datos para la siguiente partida
  void end() {
    cartas.shuffle();
    _counter = 0;
    _dealer = 0;
    turn = true;
    win = false;
    finish = false;
    hitPhase = false;
    bet = 0.0;
    multiplier = 0.0;
    miMazo.clear();
    dealerMazo.clear();
  }

  ///para el hit
  void _incrementCounter() async {
    if (!turn) return;

    ///si no es tu turno no hace nada
    addCardPlayer();
    await Future.delayed(Duration(milliseconds: 200));
    fController.flip();
    if (_counter > 21) {
      ///Si te pasas de los 21 muestra el mensaje de que ha perdido
      await Future.delayed(timeWait);
      setState(() {
        turn = false;
        win = false;
        finish = true;
      });
      aController.reset();
      fController.flip();
      setState(end);
      return;
    }
    await Future.delayed(timeWait);
    setState(() {});
    aController.reset();
    fController.flip();
  }

  ///función para el turno del dealer
  void croupierTurn() async {
    setState(() {
      turn = false;
    });

    ///simplemente para que se quiten los controles
    while (true) {
      await Future.delayed(timeWait);
      setState(addCardDealer);

      ///*añade una carta al dealer
      ///si gana el dealer
      if (_dealer > 21) {
        ///*si pierde el dealer
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
    await Future.delayed(timeWait);
    setState(end);
  }

  void addBet() async {
    if (aBet == 0 || aBet == null || !turn) {
      return;
    }
    if (pres == true) return;

    ///semáforo (no conozco como es en dart, problemas de concurrencia :( )
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
      await Future.delayed(Duration(milliseconds: 200));

      ///espero para que actualice la interfaz gráfica
    }
    pres = false;
  }

  @override
  Widget build(BuildContext context) {
    if (last == null) {
      last = MediaQuery.of(context).orientation;
      if (last == Orientation.portrait) {
        aControllerAngle.reverse();
      } else {
        aControllerAngle.forward();
      }
    }

    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      if (MediaQuery.of(context).orientation != last) {
        /**si se ha cambiado la orientacion */
        last = MediaQuery.of(context).orientation;
        aControllerAngle.forward();
      }
      if (MediaQuery.of(context).viewInsets.bottom != 0) {
        aControllerSize.forward();
      } else {
        aControllerSize.reverse();
      }
    } else {
      if (MediaQuery.of(context).orientation != last) {
        /**si se ha cambiado la orientacion */
        last = MediaQuery.of(context).orientation;
        aControllerAngle.reverse();
      }
    }

    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
        backgroundColor: Colors.red[900],
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: Container(
              height: 220,
              width: MediaQuery.of(context).size.width,
              child: Column(children: [
                SizedBox(
                  height: 120,
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(
                          key: keyMiMazo,
                          child: Stack(
                            children: miMazo,
                          ),
                          width: MediaQuery.of(context).size.width / 2 -
                              MediaQuery.of(context).size.width / 10,
                          height: 120,
                        ),
                        SizedBox(
                          child: Stack(
                            key: keyMazoDealer,
                            children: dealerMazo,
                          ),
                          width: MediaQuery.of(context).size.width / 2 -
                              MediaQuery.of(context).size.width / 10,
                          height: 120,
                        ),
                      ]),
                ),
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
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 20.0)),
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
                                      child: TextFormField(
                                    initialValue: aBet.toString(),
                                    autofocus: false,
                                    //decoration: new InputDecoration(
                                    //labelText: "Enter the amount to add to the bet"),
                                    keyboardType: TextInputType.number,
                                    showCursor: false,
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
          ),
        ),
        body: Column(children: [
          SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
            child:
                /*!finish
                ? Container()
                : Container(
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: win
                          ? Text(
                              "You Win :))",
                              textDirection: TextDirection.ltr,
                            )
                          : Text("You Lose :()",
                              textDirection: TextDirection.ltr),
                    ),
                    width: MediaQuery.of(context).size.width * 3 / 4,
                  ),*/
                /*Para mostrar el mazo de cartas*/
                Stack(
              ///esto es para que siempre se vea una carta en el mazo
              children: [
                Positioned(
                  top: 5,
                  left: 5,
                  child: AnimatedBuilder(
                    key: keyCarta,
                    child: (this.card = Flip(
                      firstChild: cartaMazoAnimada(cartaMazo(true, 140)),
                      secondChild: cartaMazoAnimada(cartaMazo(false, 140)),
                      controller: fController,
                      flipDuration: timeWait - Duration(milliseconds: 200),
                    )),
                    animation: aController,
                    builder: (BuildContext context, Widget child) {
                      return Transform.translate(
                          offset:
                              Offset(-tAnimationX.value, -tAnimationY.value),
                          child: child);
                    },
                  ),
                ),
                cartaMazoAnimada(cartaMazo(true, 150)),
              ],
            ),
          )
        ]));
  }
}
