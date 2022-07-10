import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart';
import 'package:flip/flip.dart';
import 'package:flutter_launcher_icons/android.dart';
import 'package:flutter_launcher_icons/constants.dart';
import 'package:flutter_launcher_icons/custom_exceptions.dart';
import 'package:flutter_launcher_icons/ios.dart';
import 'package:flutter_launcher_icons/main.dart';
import 'package:flutter_launcher_icons/utils.dart';
import 'package:flutter_launcher_icons/xml_templates.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Black Jack',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  BorderSide tapeteBorder = BorderSide(color: Colors.black, width: 1.5);
  bool anim = false;
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

  Animation<double> tAnimationSize;

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
          card: cartas[(index + 1)%52],
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
    
    tAnimationSize = Tween<double>(begin: 1, end: (120.00/138)).animate(aController);
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
        child: Container(
          width: 100,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white38,
            borderRadius: BorderRadius.all(
    		      Radius.circular(10)
    	      ),
            border: Border.all()
          ),
          child: Center(
            child: Text(
              'HIT',
              textDirection: TextDirection.ltr,
              textScaleFactor: 1.5,
            ),
          ),
        ),
        onTap: () {
          if(bet==0){
            mostrarMensaje(builder: mensajeBet, bDismissible: true, disp: true);
            return;
          }
          if(!anim){
            anim=true;
            _incrementCounter();
            hitPhase = true;
          }
        });

    stand = GestureDetector(
              child: Container(
          width: 100,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white38,
            borderRadius: BorderRadius.all(
    		      Radius.circular(10)
    	      ),
            border: Border.all()
          ),
          child: Center(
            child: Text(
              'STAND',
              textDirection: TextDirection.ltr,
              textScaleFactor: 1.5,
            ),
          ),
        ),
      onTap: (){
        setState(() { ///actualiza para no permitir seguir pidiendo cartas
          turn = false;
        });
        croupierTurn();
      }
    );
    super.initState();
  }

  AlertDialog mensajeAce(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      title: Text(
        "Ace",
        textDirection: TextDirection.ltr,
      ),
      content: Text(
        "Choose the value of the ace",
        textDirection: TextDirection.ltr,
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
              _counter += 1;
                  if (_counter > 21) {
                  ///Si te pasas de los 21 muestra el mensaje de que ha perdido      setState(() {
                    turn = false;
                    win = false;
                    finish = true;
                    setState(end);
                    return;
                  }
                  setState((){});
              ///no actualiza el estado hasta que no da en ok
            },
            child: Text(
              "1",
              textDirection: TextDirection.ltr,
            )),
        TextButton(
            onPressed: () {
              Navigator.pop(context);
              _counter += 11;
                  if (_counter > 21) {
                  ///Si te pasas de los 21 muestra el mensaje de que ha perdido      setState(() {
                    turn = false;
                    win = false;
                    finish = true;
                    setState(end);
                    return;
                  }
                  setState((){});
            },
            child: Text(
              "11",
              textDirection: TextDirection.ltr,
            )),
      ],
    );
  }

  AlertDialog mensajeBet(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      title: Text(
        "No Bet",
        textDirection: TextDirection.ltr,
      ),
      content: Text(
        "Sorry, you must bet money to continue playing",
        textDirection: TextDirection.ltr,
      ),
      /*actions: [
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
      ],*/
    );
  }

  void mostrarMensaje({Widget Function(BuildContext) builder, bool disp, bool bDismissible}) {
    showDialog(
      barrierColor: Colors.transparent,
      context: _scaffoldKey.currentContext,
      builder: (BuildContext context){

        if(disp)
          Future.delayed(Duration(seconds: 2,milliseconds: 500), () {
                            Navigator.of(context).pop(true);
          });
        return builder(context);
      },
      barrierDismissible: bDismissible,
    );
  }

  ///Método para dar una carta
  ///Retorna el valor de la carta dada
  int addRandomCard(List<Widget> mazo) {
    index = ((index + 1) % 52);
    mazo.add( 
      Positioned(
        child: Container(
            child: PlayingCardView(
              card: cartas[index],
              shape: shape,
            ),
            height: 120),
        left: (mazo.length * 20.0),
      ),
    );
    if(cartas.elementAt(index).value == CardValue.ace){
      if(turn){
        mostrarMensaje(builder: mensajeAce, disp: false, bDismissible: false);
        return 0;
      }
      else{
        if(_dealer+11>21){
          return 1;
        }else{
          return 11;
        }
      }
    }
    return min(cartas.elementAt(index).value.index + 2, 10);
  }

  ///Método para dar una carta al jugador
  void addCardPlayer() {
    _counter += addRandomCard(miMazo);
    tAnimationX = Tween<double>(
            begin: 0,
            end: getOffset(keyCarta, keyMiMazo).dx - miMazo.length * 20.0 + (MediaQuery.of(context).orientation == Orientation.portrait ? 26.2 : 5))
        .animate(aController);
    tAnimationY =
        Tween<double>(begin: 0, end: getOffset(keyCarta, keyMiMazo).dy+ 9.5)
            .animate(aController);
    this.aController.forward();
  }

  ///Método para
  void addCardDealer() {
    _dealer += addRandomCard(dealerMazo);
        tAnimationX = Tween<double>(
            begin: 0,
            end: getOffset(keyCarta, keyMazoDealer).dx - dealerMazo.length * 20.0 + (MediaQuery.of(context).orientation == Orientation.portrait ? 26.2 : 5))
        .animate(aController);
    tAnimationY =
        Tween<double>(begin: 0, end: getOffset(keyCarta, keyMazoDealer).dy+ 9.5)
            .animate(aController);
    this.aController.forward();
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
      anim=false;
      return;
    }
    await Future.delayed(timeWait + Duration(microseconds: 50));
    setState(() {});
    anim=false;
    aController.reset();
    fController.isFront = true;
    //fController.flip();
  }

  ///función para el turno del dealer
  void croupierTurn() async {
    await Future.delayed(Duration(milliseconds: 200));
    ///simplemente para que se quiten los controles
    while (true) {
      addCardDealer(); //añade la carta
      await Future.delayed(Duration(milliseconds: 200));
      fController.flip(); /*hace el flip*/
      await Future.delayed(timeWait + Duration(microseconds: 50));
      ///*añade una carta al dealer
      setState(() {});
      aController.reset();
      fController.flip();
      await Future.delayed(Duration(milliseconds: 300));
      ///si gana el dealer
      if (_dealer > 21) {
        setState(() {
          win = true;
          money += bet * multiplier;
          finish = true;
        });
        break;
      } else if (_dealer >= _counter) { ///si gana el dealer
        setState(() {
          win = false;
          finish = true;
        });
        break;
      }
    }
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
      key: _scaffoldKey,
        backgroundColor: Colors.red[900],
        resizeToAvoidBottomInset: false,
        bottomNavigationBar: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: Container(
              height: 130,
              width: MediaQuery.of(context).size.width,
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
                                  )),
                                  GestureDetector(
                                    child: Container(
                                      height: 50,
                                      width: 30,
                                      decoration: new BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.greenAccent[100]),
                                      child: Icon(Icons.remove),
                                    ),
                                    onTap: (){
                                      setState((){
                                          if(aBet>bet){
                                            money+=bet;
                                            bet=0;
                                          }else{
                                            bet-=aBet;
                                            money+=aBet;
                                          }
                                        }
                                      );
                                    },
                                  ),
                                  Padding(padding: EdgeInsets.only(right: 10)),
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
          Container(
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: SafeArea(
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
                Container(
                  //color: Colors.blue,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height-200,
                  child: Stack(
                    alignment: Alignment.topCenter,
              ///esto es para que siempre se vea una carta en el mazo
              children: [
                    Positioned(
                    bottom: 0,
                    child: SizedBox(
                      height: 120,
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Stack(
                                key: keyMiMazo,
                                children: miMazo,
                              ),
                              width: MediaQuery.of(context).size.width / 2 -
                                  MediaQuery.of(context).size.width / 10,
                              height: 120,
                              decoration: BoxDecoration(border: Border(bottom: tapeteBorder)),
                            ),
                            Container(
                              child: Stack(
                                key: keyMazoDealer,
                                children: dealerMazo,
                              ),
                              width: MediaQuery.of(context).size.width / 2 -
                                  MediaQuery.of(context).size.width / 10,
                              height: 120,
                              decoration: BoxDecoration(border: Border(bottom: tapeteBorder)),
                            ),
                          ]),
                    ),
                  ),
                  Positioned(
                    top: 8.5,
                    child: AnimatedBuilder(
                      key: keyCarta,
                      child: (this.card = Flip(
                        firstChild: cartaMazoAnimada(cartaMazo(true, 138)),
                        secondChild: cartaMazoAnimada(cartaMazo(false, 138)),
                        controller: fController,
                        flipDuration: timeWait - Duration(milliseconds: 200),
                      )),
                      animation: aController,
                      builder: (BuildContext context, Widget child) {
                        return Transform.translate(
                            offset:
                                Offset(-tAnimationX.value, -tAnimationY.value),
                            child: Transform.scale(scale: tAnimationSize.value, child: Transform.rotate(child: child, angle: MediaQuery.of(context).orientation==Orientation.landscape ? Tween<double>(begin: 0, end: 3*pi / 2).animate(aController).value : 0,)));
                      },
                    ),
                  ),
                  Positioned(top: 0, child: cartaMazoAnimada(cartaMazo(true, 150))),

              ],
            ),
                ),
          )
        ]));
  }
} 