enum CashRegisterState { closed, open }

enum ShoppingGameState { lottery, playing, correct, incorrect, won }

enum PaymentIntroState {
  waiting,
  incomingAtStart,
  incoming,
  outgoingAtCenter,
  outgoing,
  complete,
}

class ShoppingPosition {
  final double x;
  final double y;

  const ShoppingPosition(this.x, this.y);
}

class ShoppingSize {
  final double width;
  final double height;

  const ShoppingSize(this.width, this.height);
}

class ShoppingGood {
  final int price;
  final String assetPath;
  final ShoppingSize originalSize;

  const ShoppingGood(this.price, this.assetPath, this.originalSize);
}

class ShoppingPayment {
  final int value;
  final String handAssetPath;
  final ShoppingSize handOriginalSize;
  final String noteAssetPath;
  final ShoppingSize noteOriginalSize;

  const ShoppingPayment({
    required this.value,
    required this.handAssetPath,
    required this.handOriginalSize,
    required this.noteAssetPath,
    required this.noteOriginalSize,
  });
}

class ShoppingBalanceDenomination {
  final int value;
  final String assetPath;
  final ShoppingSize originalSize;

  const ShoppingBalanceDenomination({
    required this.value,
    required this.assetPath,
    required this.originalSize,
  });
}

class ShoppingBalanceNote {
  final int id;
  final ShoppingBalanceDenomination denomination;

  const ShoppingBalanceNote({required this.id, required this.denomination});
}

class ShoppingGameConfig {
  final ShoppingSize stageSize;
  final double spriteScale;
  final ShoppingSize cashRegisterSize;
  final ShoppingPosition cashRegisterClosedCenter;
  final ShoppingPosition cashRegisterOpenCenter;
  final Duration cashRegisterAnimationDuration;
  final double goodsScale;
  final int displayedGoodsCount;
  final List<ShoppingPosition> goodsPositions;
  final List<ShoppingGood> goods;
  final List<ShoppingPayment> payments;
  final ShoppingSize emptyHandSize;
  final ShoppingPosition paymentStartPosition;
  final ShoppingPosition paymentEndPosition;
  final Duration paymentAnimationDuration;
  final Duration paymentAnimationStartDelay;
  final double cashRegisterDenominationAreaFraction;
  final List<ShoppingBalanceDenomination> balanceDenominations;
  final double balanceNoteScale;
  final ShoppingPosition balanceFirstPosition;
  final double balancePositionSpacing;
  final int winningScore;
  final Duration goodsLotteryDuration;
  final Duration goodsLotteryInterval;
  final Duration feedbackDuration;

  const ShoppingGameConfig({
    this.stageSize = const ShoppingSize(480, 640),
    this.spriteScale = 0.8,
    this.cashRegisterSize = const ShoppingSize(236, 555),
    this.cashRegisterClosedCenter = const ShoppingPosition(0, -376.64),
    this.cashRegisterOpenCenter = const ShoppingPosition(0, -225.6),
    this.cashRegisterAnimationDuration = const Duration(milliseconds: 300),
    this.goodsScale = 0.4,
    this.displayedGoodsCount = 3,
    this.goodsPositions = const [
      ShoppingPosition(-150, 150),
      ShoppingPosition(0, 150),
      ShoppingPosition(150, 150),
    ],
    this.goods = const [
      ShoppingGood(
        1000,
        'assets/images/shopping_game/goods/1k banana.png',
        ShoppingSize(373, 309),
      ),
      ShoppingGood(
        2000,
        'assets/images/shopping_game/goods/2k apple.png',
        ShoppingSize(353, 322),
      ),
      ShoppingGood(
        2000,
        'assets/images/shopping_game/goods/2k guava.png',
        ShoppingSize(375, 342),
      ),
      ShoppingGood(
        2000,
        'assets/images/shopping_game/goods/2k mango.png',
        ShoppingSize(375, 284),
      ),
      ShoppingGood(
        3000,
        'assets/images/shopping_game/goods/3k orange.png',
        ShoppingSize(375, 348),
      ),
      ShoppingGood(
        3000,
        'assets/images/shopping_game/goods/3k passion.png',
        ShoppingSize(375, 331),
      ),
      ShoppingGood(
        3000,
        'assets/images/shopping_game/goods/3k pineapple.png',
        ShoppingSize(375, 274),
      ),
      ShoppingGood(
        4000,
        'assets/images/shopping_game/goods/4k papaya.png',
        ShoppingSize(375, 301),
      ),
      ShoppingGood(
        4000,
        'assets/images/shopping_game/goods/4k watermelon.png',
        ShoppingSize(375, 253),
      ),
      ShoppingGood(
        5000,
        'assets/images/shopping_game/goods/5k avocado.png',
        ShoppingSize(375, 315),
      ),
      ShoppingGood(
        5000,
        'assets/images/shopping_game/goods/5k jackfruit.png',
        ShoppingSize(375, 315),
      ),
    ],
    this.payments = const [
      ShoppingPayment(
        value: 5000,
        handAssetPath: 'assets/images/shopping_game/paid/05k hand.png',
        handOriginalSize: ShoppingSize(694, 320),
        noteAssetPath: 'assets/images/shopping_game/paid/05k.png',
        noteOriginalSize: ShoppingSize(303, 249),
      ),
      ShoppingPayment(
        value: 10000,
        handAssetPath: 'assets/images/shopping_game/paid/10k hand.png',
        handOriginalSize: ShoppingSize(692, 316),
        noteAssetPath: 'assets/images/shopping_game/paid/10k.png',
        noteOriginalSize: ShoppingSize(302, 249),
      ),
      ShoppingPayment(
        value: 20000,
        handAssetPath: 'assets/images/shopping_game/paid/20k hand.png',
        handOriginalSize: ShoppingSize(689, 318),
        noteAssetPath: 'assets/images/shopping_game/paid/20k.png',
        noteOriginalSize: ShoppingSize(306, 252),
      ),
      ShoppingPayment(
        value: 50000,
        handAssetPath: 'assets/images/shopping_game/paid/50k hand.png',
        handOriginalSize: ShoppingSize(698, 316),
        noteAssetPath: 'assets/images/shopping_game/paid/50k.png',
        noteOriginalSize: ShoppingSize(313, 249),
      ),
    ],
    this.emptyHandSize = const ShoppingSize(556, 195),
    this.paymentStartPosition = const ShoppingPosition(480, -30),
    this.paymentEndPosition = const ShoppingPosition(-60, -30),
    this.paymentAnimationDuration = const Duration(seconds: 1),
    this.paymentAnimationStartDelay = const Duration(milliseconds: 100),
    this.cashRegisterDenominationAreaFraction = 0.8,
    this.balanceDenominations = const [
      ShoppingBalanceDenomination(
        value: 1000,
        assetPath: 'assets/images/shopping_game/balance/01k.png',
        originalSize: ShoppingSize(157, 283),
      ),
      ShoppingBalanceDenomination(
        value: 2000,
        assetPath: 'assets/images/shopping_game/balance/02k.png',
        originalSize: ShoppingSize(154, 274),
      ),
      ShoppingBalanceDenomination(
        value: 5000,
        assetPath: 'assets/images/shopping_game/balance/05k.png',
        originalSize: ShoppingSize(152, 286),
      ),
      ShoppingBalanceDenomination(
        value: 10000,
        assetPath: 'assets/images/shopping_game/balance/10k.png',
        originalSize: ShoppingSize(157, 281),
      ),
      ShoppingBalanceDenomination(
        value: 20000,
        assetPath: 'assets/images/shopping_game/balance/20k.png',
        originalSize: ShoppingSize(154, 286),
      ),
      ShoppingBalanceDenomination(
        value: 50000,
        assetPath: 'assets/images/shopping_game/balance/50k.png',
        originalSize: ShoppingSize(158, 294),
      ),
    ],
    this.balanceNoteScale = 0.8,
    this.balanceFirstPosition = const ShoppingPosition(-180, -60),
    this.balancePositionSpacing = 30,
    this.winningScore = 10,
    this.goodsLotteryDuration = const Duration(milliseconds: 1200),
    this.goodsLotteryInterval = const Duration(milliseconds: 100),
    this.feedbackDuration = const Duration(seconds: 2),
  });
}
