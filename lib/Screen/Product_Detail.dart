import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eshop_multivendor/Screen/CompareList.dart';
import 'package:eshop_multivendor/Screen/Seller_Details.dart';
import 'package:eshop_multivendor/widgets/star_rating.dart';
import 'package:html/dom.dart' as dom;
import 'package:flutter_html/flutter_html.dart';
import 'package:eshop_multivendor/Helper/AppBtn.dart';
import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/Helper/Constant.dart';
import 'package:eshop_multivendor/Helper/Session.dart';
import 'package:eshop_multivendor/Helper/SimBtn.dart';
import 'package:eshop_multivendor/Helper/SqliteData.dart';
import 'package:eshop_multivendor/Helper/String.dart';
import 'package:eshop_multivendor/Model/Section_Model.dart';
import 'package:eshop_multivendor/Model/User.dart';
import 'package:eshop_multivendor/Provider/CartProvider.dart';
import 'package:eshop_multivendor/Provider/FavoriteProvider.dart';
import 'package:eshop_multivendor/Provider/HomeProvider.dart';
import 'package:eshop_multivendor/Provider/ProductDetailProvider.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:eshop_multivendor/Screen/Cart.dart';
import 'package:eshop_multivendor/Screen/Favorite.dart';
import 'package:eshop_multivendor/Screen/HomePage.dart';
import 'package:eshop_multivendor/Screen/Product_Preview.dart';
import 'package:eshop_multivendor/Screen/Review_Gallary.dart';
import 'package:eshop_multivendor/Screen/Review_Preview.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Model/Faqs_Model.dart';
import '../Screen/FaqsProduct.dart';
import '../Screen/PromoCode.dart';
import '../widgets/productItemList.dart';

class ProductDetail extends StatefulWidget {
  final Product? model;

  final int? secPos, index;
  final bool? list;

  const ProductDetail(
      {Key? key, this.model, this.secPos, this.index, this.list})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => StateItem();
}

List<FaqsModel> faqsProductList = [];
int faqsOffset = 0;
int faqsTotal = 0;
bool isLoadingmore = true;
List<User> reviewList = [];
List<imgModel> revImgList = [];
int offset = 0;
int total = 0;
final TextEditingController _controller1 = TextEditingController();
FocusNode searchFocusNode = FocusNode();

class StateItem extends State<ProductDetail> with TickerProviderStateMixin {
  final edtFaqs = TextEditingController();
  final GlobalKey<FormState> faqsKey = GlobalKey<FormState>();
  bool _isFaqsLoading = true;
  int _curSlider = 0;
  final _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<int?> _selectedIndex = [];
  ChoiceChip? choiceChip, tagChip;
  Widget? choiceContainer;
  int _oldSelVarient = 0;
  bool _isLoading = true;

  var star1 = '0', star2 = '0', star3 = '0', star4 = '0', star5 = '0';
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  int notificationoffset = 0;
  late int totalProduct = 0;

  bool notificationisloadmore = true,
      notificationisgettingdata = false,
      notificationisnodata = false;

  bool notificationisgettingdata1 = false, notificationisnodata1 = false;
  List<Product> productList = [];
  List<Product> productList1 = [];
  bool seeView = false;
  late ShortDynamicLink shortenedLink;
  late String shareLink;
  late String curPin;
  late double growStepWidth, beginWidth, endWidth = 0.0;
  TextEditingController qtyController = TextEditingController();
  ScrollController controller = ScrollController();
  List<String?> sliderList = [];
  int? varSelected;

  List<Product> compareList = [];
  bool isBottom = false;
  var db = DatabaseHelper();
  bool qtyChange = false;
  bool? available, outOfStock;
  int? selectIndex = 0;
  List<String> proIds1 = [];
  List<Product> mostFavProList = [];
  String query = '';
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    isLoadingmore = true;
    checkProId();
    getProductFaqs();
    promocodeAPI('0');
//for faq
    faqsProductList.clear();
    faqsOffset = 0;

    controller = ScrollController(keepScrollOffset: true);
    controller.addListener(_scrollListener);
    _controller1.addListener(() {
      if (_controller1.text.isEmpty) {
        setState(() {
          query = '';
          faqsOffset = 0;
          isLoadingmore = true;

          getProductFaqs();
        });
      } else {
        query = _controller1.text;
        faqsOffset = 0;
        notificationisnodata = false;

        if (query.trim().isNotEmpty) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            if (query.trim().isNotEmpty) {
              isLoadingmore = true;
              faqsOffset = 0;

              getProductFaqs();
            }
          });
        }
      }
      ScaffoldMessenger.of(context).clearSnackBars();
    });

//========

    getProduct1();
    getProFavIds();
    sliderList.clear();
    sliderList.insert(0, widget.model!.image);

    addImage().then((value) {
      if (widget.model!.videType != '' &&
          widget.model!.video!.isNotEmpty &&
          widget.model!.video != '') {
        sliderList.insert(1, 'youtube');
      }
    });

    revImgList.clear();
    if (widget.model!.reviewList!.isNotEmpty) {
      for (int i = 0;
          i < widget.model!.reviewList![0].productRating!.length;
          i++) {
        for (int j = 0;
            j < widget.model!.reviewList![0].productRating![i].imgList!.length;
            j++) {
          imgModel m = imgModel.fromJson(
            i,
            widget.model!.reviewList![0].productRating![i].imgList![j],
          );
          revImgList.add(m);
        }
      }
    }

    getShare();
    _oldSelVarient = widget.model!.selVarient!;

    reviewList.clear();
    offset = 0;
    total = 0;
    getReview();
    getDeliverable();
    notificationoffset = 0;
    getProduct();

    compareList = context.read<ProductDetailProvider>().compareList;

    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(
      CurvedAnimation(
        parent: buttonController!,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ),
    );

    ///--------

    _selectedIndex.clear();
    if (widget.model!.stockType == '0' || widget.model!.stockType == '1') {
      if (widget.model!.availability == '1') {
        available = true;
        outOfStock = false;
        _oldSelVarient = widget.model!.selVarient!;
      } else {
        available = false;
        outOfStock = true;
      }
    } else if (widget.model!.stockType == '') {
      available = true;
      outOfStock = false;
      _oldSelVarient = widget.model!.selVarient!;
    } else if (widget.model!.stockType == '2') {
      if (widget
              .model!.prVarientList![widget.model!.selVarient!].availability ==
          '1') {
        available = true;
        outOfStock = false;
        _oldSelVarient = widget.model!.selVarient!;
      } else {
        available = false;
        outOfStock = true;
      }
    }

    List<String> selList = widget
        .model!.prVarientList![widget.model!.selVarient!].attribute_value_ids!
        .split(',');

    for (int i = 0; i < widget.model!.attributeList!.length; i++) {
      List<String> sinList = widget.model!.attributeList![i].id!.split(',');

      for (int j = 0; j < sinList.length; j++) {
        if (selList.contains(sinList[j])) {
          _selectedIndex.insert(i, j);
        }
      }

      if (_selectedIndex.length == i) _selectedIndex.insert(i, null);
    }
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        if (mounted) {
          setState(() {
            isLoadingmore = true;

            getProductFaqs();
          });
        }
      }
    }
  }

  Future<void> promocodeAPI(String save) async {
    _isNetworkAvail = await isNetworkAvailable();

    if (_isNetworkAvail) {
      try {
        var parameter = {USER_ID: CUR_USERID, SAVE_LATER: save};
        apiBaseHelper.postAPICall(getCartApi, parameter).then((getdata) {
          bool error = getdata['error'];
          if (!error) {
            var data = getdata['data'];

            List<SectionModel> cartList = (data as List)
                .map((data) => SectionModel.fromCart(data))
                .toList();

            context.read<CartProvider>().setCartlist(cartList);

            if (getdata.containsKey(PROMO_CODES)) {
              var promo = getdata[PROMO_CODES];
              promoList =
                  (promo as List).map((e) => Promo.fromJson(e)).toList();
            }
          } else {}
          if (mounted) {
            setState(() {});
          }
        }, onError: (error) {});
      } on TimeoutException catch (_) {}
    } else {
      if (mounted) {
        setState(
          () {
            _isNetworkAvail = false;
          },
        );
      }
    }
  }

  getProFavIds() async {
    proIds1 = (await db.getMostFav())!;
    getMostFavPro();
  }

  checkProId() async {
    await db.addMostFav(widget.model!.id!);
  }

  Future<void> getMostFavPro() async {
    if (proIds1.isNotEmpty) {
      _isNetworkAvail = await isNetworkAvailable();

      if (_isNetworkAvail) {
        try {
          var parameter = {'product_ids': proIds1.join(',')};

          apiBaseHelper.postAPICall(getProductApi, parameter).then(
              (getdata) async {
            bool error = getdata['error'];
            if (!error) {
              var data = getdata['data'];

              List<Product> tempList =
                  (data as List).map((data) => Product.fromJson(data)).toList();
              mostFavProList.clear();
              var extPro =
                  tempList.firstWhere((cp) => cp.id == widget.model!.id);
              if (extPro == null) {
                mostFavProList.addAll(tempList);
              } else {
                tempList
                    .removeWhere((element) => element.id == widget.model!.id);
                mostFavProList.addAll(tempList);
              }
            }
            if (mounted) {
              setState(() {
                context.read<HomeProvider>().setMostLikeLoading(false);
              });
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          context.read<HomeProvider>().setMostLikeLoading(false);
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
            context.read<HomeProvider>().setMostLikeLoading(false);
          });
        }
      }
    } else {
      context.read<CartProvider>().setCartlist([]);
      setState(() {
        context.read<HomeProvider>().setMostLikeLoading(false);
      });
    }
  }

  Future<void> setFaqsQue() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_ID: widget.model!.id,
          QUESTION: edtFaqs.text.trim()
        };
        apiBaseHelper.postAPICall(addProductFaqsApi, parameter).then((getdata) {
          bool error = getdata['error'];
          String? msg = getdata['message'];
          if (!error) {
            setSnackbar(msg!, context);
            edtFaqs.clear();
            Navigator.pop(context);
          } else {
            setSnackbar(msg!, context);
          }
          context.read<CartProvider>().setProgress(false);
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  postQues() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            getTranslated(context, 'Have any Query regarding this product?')!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.fontColor,
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: 10,
              bottom: 5,
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                openPostQueBottomSheet();
              },
              child: Container(
                width: double.maxFinite,
                height: 38.5,
                alignment: FractionalOffset.center,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .lightBlack
                          .withOpacity(0.4)),
                  borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                ),
                child: Text(
                  getTranslated(context, 'POST YOUR QUESTION')!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> getProductFaqs() async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (isLoadingmore) {
            if (mounted) {
              setState(
                () {
                  isLoadingmore = false;
                  if (_controller1.hasListeners &&
                      _controller1.text.isNotEmpty) {
                    _isLoading = true;
                  }
                },
              );
            }
            var parameter = {
              PRODUCT_ID: widget.model!.id,
              LIMIT: perPage.toString(),
              OFFSET: faqsOffset.toString(),
              SEARCH: query,
            };
            apiBaseHelper.postAPICall(getProductFaqsApi, parameter).then(
                (getdata) {
              bool error = getdata['error'];
              if (!error) {
                var data = getdata['data'];
                faqsProductList = (data as List)
                    .map((data) => FaqsModel.fromJson(data))
                    .toList();

                isLoadingmore = true;
                _isFaqsLoading = false;
                faqsOffset = faqsOffset + perPage;
                setState(() {});
              } else {
                isLoadingmore = false;
                _isFaqsLoading = false;
                setState(() {});
              }
              if (mounted) {
                setState(() {
                  _isFaqsLoading = false;
                });
                isLoadingmore = false;
                if (mounted) setState(() {});
              }
            }, onError: (error) {
              setSnackbar(error.toString(), context);
            });
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          if (mounted) {
            setState(() {
              isLoadingmore = false;
              _isFaqsLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isNetworkAvail = false;
          });
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  @override
  void dispose() {
    buttonController!.dispose();
    edtFaqs.dispose();
    super.dispose();
  }

  Future<void> addImage() async {
    if (widget.model!.otherImage != '' &&
        widget.model!.otherImage!.isNotEmpty) {
      sliderList.addAll(widget.model!.otherImage!);
    }

    for (int i = 0; i < widget.model!.prVarientList!.length; i++) {
      for (int j = 0; j < widget.model!.prVarientList![i].images!.length; j++) {
        sliderList.add(widget.model!.prVarientList![i].images![j]);
      }
    }
  }

  Future<void> createDynamicLink() async {
    String documentDirectory;

    if (Platform.isIOS) {
      documentDirectory = (await getApplicationDocumentsDirectory()).path;
    } else {
      documentDirectory = (await getExternalStorageDirectory())!.path;
    }

    final response1 = await get(Uri.parse(widget.model!.image!));
    final bytes1 = response1.bodyBytes;

    final File imageFile = File('$documentDirectory/temp.png');

    imageFile.writeAsBytesSync(bytes1);
    Share.shareFiles([imageFile.path],
        text:
            '${widget.model!.name}\n${shortenedLink.shortUrl.toString()}\n$shareLink');
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          noIntImage(),
          noIntText(context),
          noIntDec(context),
          AppBtn(
            title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
            btnAnim: buttonSqueezeanimation,
            btnCntrl: buttonController,
            onBtnSelected: () async {
              _playAnimation();

              Future.delayed(const Duration(seconds: 2)).then(
                (_) async {
                  _isNetworkAvail = await isNetworkAvailable();
                  if (_isNetworkAvail) {
                    Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                        builder: (BuildContext context) => super.widget,
                      ),
                    );
                  } else {
                    await buttonController!.reverse();
                    if (mounted) {
                      setState(
                        () {},
                      );
                    }
                  }
                },
              );
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isBottom
          ? Colors.transparent.withOpacity(0.5)
          : Theme.of(context).canvasColor,
      body: _isNetworkAvail
          ? Stack(
              children: <Widget>[
                _showContent(),
                Selector<CartProvider, bool>(
                  builder: (context, data, child) {
                    return showCircularProgress(
                      data,
                      colors.primary,
                    );
                  },
                  selector: (_, provider) => provider.isProgress,
                ),
              ],
            )
          : noInternet(context),
    );
  }

  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(
        handler(i, list[i]),
      );
    }

    return result;
  }

  Widget _slider() {
    return LayoutBuilder(builder: (context, constraints) {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ProductPreview(
                pos: _curSlider,
                secPos: widget.secPos,
                index: widget.index,
                id: widget.model!.id,
                imgList: sliderList,
                list: widget.list,
                video: widget.model!.video,
                videoType: widget.model!.videType,
                from: true,
              ),
            ),
          );
        },
        child: Stack(
          children: <Widget>[
            Hero(
              tag: '${widget.index}${widget.model!.id}',
              child: PageView.builder(
                itemCount: sliderList.length,
                scrollDirection: Axis.horizontal,
                controller: _pageController,
                reverse: false,
                onPageChanged: (index) {
                  setState(
                    () {
                      _curSlider = index;
                    },
                  );
                },
                itemBuilder: (BuildContext context, int index) {
                  return Stack(
                    children: [
                      sliderList[index] != 'youtube'
                          ? FadeInImage(
                              image: NetworkImage(
                                sliderList[index]!,
                              ),
                              placeholder: const AssetImage(
                                'assets/images/sliderph.png',
                              ),
                              fit: BoxFit.cover,
                              imageErrorBuilder: (context, error, stackTrace) =>
                                  erroWidget(deviceWidth! * 1),
                              height: constraints.maxHeight,
                              width: constraints.maxWidth,
                            )
                          : playIcon()
                    ],
                  );
                },
              ),
            ),
            Positioned.directional(
              textDirection: Directionality.of(context),
              bottom: 30,
              height: 20,
              width: deviceWidth,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: map<Widget>(
                  sliderList,
                  (index, url) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: _curSlider == index ? 14.0 : 14.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(
                        vertical: 2.0,
                        horizontal: 4.0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4)),
                        color: _curSlider == index
                            ? colors.primary
                            : Theme.of(context).colorScheme.lightWhite,
                      ),
                    );
                  },
                ),
              ),
            ),
            indicatorImage(),
          ],
        ),
      );
    });
  }

  indicatorImage() {
    String? indicator = widget.model!.indicator;
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: indicator == '1'
              ? SvgPicture.asset('assets/images/vag.svg')
              : indicator == '2'
                  ? SvgPicture.asset('assets/images/nonvag.svg')
                  : Container(),
        ),
      ),
    );
  }

  _rate() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 15.0,
              end: 5.0,
              top: 15.0,
              bottom: 15.0,
            ),
            child: StarRatingProductDetailPage(
              totalRating: widget.model!.rating!,
              noOfRatings: widget.model!.noOfRating!,
              needToShowNoOfRatings: true,
            ),
          ),
        ),
      ],
    );
  }

  _price(pos, from) {
    double price = double.parse(
      widget.model!.prVarientList![pos].disPrice!,
    );

    if (price == 0) {
      price = double.parse(
        widget.model!.prVarientList![pos].price!,
      );
    }

    if (price != 0) {
      double off = (double.parse(widget.model!.prVarientList![pos].price!) -
              double.parse(widget.model!.prVarientList![pos].disPrice!))
          .toDouble();
      off = off * 100 / double.parse(widget.model!.prVarientList![pos].price!);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '${getPriceFormat(context, price)!} ',
              style: Theme.of(context).textTheme.headline6!.copyWith(
                    color: Theme.of(context).colorScheme.blue,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.normal,
                    fontSize: 20.0,
                  ),
            ),
            const SizedBox(width: 10),
            Text(
              '${getPriceFormat(context, double.parse(widget.model!.prVarientList![pos].price!))!} ',
              style: Theme.of(context).textTheme.bodyText2!.copyWith(
                    decoration: TextDecoration.lineThrough,
                    letterSpacing: 0,
                    color: Theme.of(context)
                        .colorScheme
                        .fontColor
                        .withOpacity(0.7),
                    fontStyle: FontStyle.normal,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w300,
                  ),
            ),
            const SizedBox(width: 10),
            Text(
              ' ${off.toStringAsFixed(2)}% OFF',
              style: Theme.of(context).textTheme.overline!.copyWith(
                    color: colors.primary,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    fontSize: 18.0,
                  ),
            ),

            //=======================================================================
            from
                ? Selector<CartProvider, Tuple2<List<String?>, String?>>(
                    builder: (context, data, child) {
                      if (!qtyChange) {
                        if (data.item1.contains(widget.model!.id)) {
                          qtyController.text = data.item2.toString();
                        } else {
                          String qty = widget
                              .model!
                              .prVarientList![widget.model!.selVarient!]
                              .cartCount!;
                          if (qty == '0') {
                            qtyController.text =
                                widget.model!.minOrderQuntity.toString();
                          } else {
                            qtyController.text = qty;
                          }
                        }
                      } else {
                        qtyChange = false;
                      }

                      return Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 3.0,
                          bottom: 5,
                          top: 3,
                        ),
                        child: widget.model!.availability == '0'
                            ? Container()
                            : Row(
                                children: const [],
                              ),
                      );
                    },
                    selector: (_, provider) => Tuple2(
                      provider.cartIdList,
                      provider.qtyList(
                        widget.model!.id!,
                        widget.model!.prVarientList![0].id!,
                      ),
                    ),
                  )
                : Container(),

            //=======================================================================
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '${getPriceFormat(context, price)!} ',
              style: Theme.of(context).textTheme.headline6!.copyWith(
                    color: Theme.of(context).colorScheme.blue,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.normal,
                    fontSize: 20.0,
                  ),
            ),
          ],
        ),
      );
    }
  }

  Widget _brandname() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 15.0,
        right: 15.0,
        top: 16.0,
        bottom: 10.0,
      ),
      child: Text(
        widget.model!.name!,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.lightBlack,
          fontSize: textFontSize14,
        ),
      ),
    );
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 15.0,
        right: 15.0,
        bottom: 15.0,
      ),
      child: Text(
        widget.model!.shortDescription!,
        style: TextStyle(
          fontWeight: FontWeight.w400,
          color: Theme.of(context).colorScheme.black,
          fontSize: textFontSize16,
        ),
      ),
    );
  }

  _desc() {
    return widget.model!.desc != '' && widget.model!.desc != null
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Html(
              data: widget.model!.desc,
              onLinkTap: (String? url, RenderContext context,
                  Map<String, String> attributes, dom.Element? element) async {
                if (await canLaunch(url!)) {
                  await launch(
                    url,
                    forceSafariVC: false,
                    forceWebView: false,
                  );
                } else {
                  throw 'Could not launch $url';
                }
              },
            ),
          )
        : Container();
  }

  void _pincodeCheck() {
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      builder: (builder) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 30,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Form(
                    key: _formkey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  getTranslated(
                                    context,
                                    'CHECK_PRODUCT_AVAILABILITY',
                                  )!,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: const Icon(
                                  Icons.close,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        TextFormField(
                          keyboardType: TextInputType.number,
                          textCapitalization: TextCapitalization.words,
                          validator: (val) => validatePincode(
                            val!,
                            getTranslated(
                              context,
                              'PIN_REQUIRED',
                            ),
                          ),
                          onSaved: (String? value) {
                            if (value != null) curPin = value;
                          },
                          style: Theme.of(context)
                              .textTheme
                              .subtitle2!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                              ),
                          decoration: InputDecoration(
                            isDense: true,
                            prefixIcon: const Icon(Icons.location_on),
                            hintText: getTranslated(context, 'PINCODEHINT_LBL'),
                            suffix: GestureDetector(
                              onTap: () async {
                                if (validateAndSave()) {
                                  validatePin(curPin, false);
                                }
                              },
                              child:  Text(
                               getTranslated(context,  'Check')!,
                                style: const TextStyle(
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;

    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  addAndRemoveQty(String qty, int from, int totalLen, int itemCounter) {
    Product model = widget.model!;

    if (CUR_USERID != null || CUR_USERID != '') {
      if (from == 1) {
        if (int.parse(qty) >= totalLen) {
          qtyController.text = totalLen.toString();
          qtyChange = true;
          setSnackbar("${getTranslated(context, 'MAXQTY')!}  $qty", context);
        } else {
          qtyController.text = (int.parse(qty) + (itemCounter)).toString();
          qtyChange = true;
        }
      } else if (from == 2) {
        if (int.parse(qty) <= model.minOrderQuntity!) {
          qtyController.text = itemCounter.toString();
          qtyChange = true;
        } else {
          qtyController.text = (int.parse(qty) - itemCounter).toString();
          qtyChange = true;
        }
      } else {
        qtyController.text = qty;
        qtyChange = true;
      }
      context.read<CartProvider>().setProgress(false);
      setState(() {});
    } else {
      if (from == 1) {
        if (int.parse(qty) >= totalLen) {
          qtyController.text = totalLen.toString();
          setSnackbar("${getTranslated(context, 'MAXQTY')!}  $qty", context);
        } else {
          qtyController.text = (int.parse(qty) + (itemCounter)).toString();
          qtyChange = true;
        }
      } else if (from == 2) {
        if (int.parse(qty) <= model.minOrderQuntity!) {
          qtyController.text = itemCounter.toString();
          qtyChange = true;
        } else {
          qtyController.text = (int.parse(qty) - itemCounter).toString();
          qtyChange = true;
        }
      } else {
        qtyController.text = qty;
        qtyChange = true;
      }
      context.read<CartProvider>().setProgress(false);
      setState(
        () {},
      );
    }
  }

  cartTotalClear() {
    totalPrice = 0;
    taxPer = 0;
    delCharge = 0;
    addressList.clear();
    promoAmt = 0;
    remWalBal = 0;
    usedBal = 0;
    payMethod = '';
    isPromoValid = false;
    isPromoLen = false;
    isUseWallet = false;
    isPayLayShow = true;
    selectedMethod = null;
    selectedTime = null;
    selectedDate = null;
    selAddress = '';
    payMethod = '';
    selTime = '';
    selDate = '';
    promocode = '';
  }

  Future<void> addToCart(
      String qty, bool intent, bool from, Product product) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        setState(() {
          qtyChange = true;
        });
        if (CUR_USERID != null) {
          try {
            if (mounted) {
              setState(
                () {
                  context.read<CartProvider>().setProgress(true);
                },
              );
            }

            Product model = widget.model!;

            if (int.parse(qty) < model.minOrderQuntity!) {
              qty = model.minOrderQuntity.toString();
              setSnackbar(
                "${getTranslated(context, 'MIN_MSG')}$qty",
                context,
              );
            }
            var parameter = {
              USER_ID: CUR_USERID,
              PRODUCT_VARIENT_ID: model.prVarientList![_oldSelVarient].id,
              QTY: qty,
            };
            apiBaseHelper.postAPICall(manageCartApi, parameter).then(
              (getdata) {
                bool error = getdata['error'];
                String? msg = getdata['message'];
                if (!error) {
                  var data = getdata['data'];
                  widget.model!.prVarientList![_oldSelVarient].cartCount =
                      qty.toString();
                  if (from) {
                    context
                        .read<UserProvider>()
                        .setCartCount(data['cart_count']);
                    var cart = getdata['cart'];
                    List<SectionModel> cartList = [];
                    cartList = (cart as List)
                        .map((cart) => SectionModel.fromCart(cart))
                        .toList();
                    context.read<CartProvider>().setCartlist(cartList);
                    if (intent) {
                      cartTotalClear();
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const Cart(
                            fromBottom: false,
                          ),
                        ),
                      );
                    }
                  }
                } else {
                  setSnackbar(msg!, context);
                }
                if (mounted) {
                  setState(
                    () {
                      context.read<CartProvider>().setProgress(false);
                    },
                  );
                }

                if (msg == 'Cart Updated !') {
                  setSnackbar(getTranslated(context, 'Product Added Successfully')!, context);
                }
              },
              onError: (error) {
                setSnackbar(error.toString(), context);
              },
            );
          } on TimeoutException catch (_) {
            setSnackbar(getTranslated(context, 'somethingMSg')!, context);
            if (mounted) {
              setState(
                () {
                  context.read<CartProvider>().setProgress(false);
                },
              );
            }
          }
        } else {
          List<Product>? prList = [];
          prList.add(widget.model!);
          context.read<CartProvider>().addCartItem(
                SectionModel(
                  qty: qty,
                  productList: prList,
                  varientId: widget.model!.prVarientList![_oldSelVarient].id!,
                  id: widget.model!.id,
                ),
              );
          db.insertCart(
            widget.model!.id!,
            widget.model!.prVarientList![_oldSelVarient].id!,
            qty,
            context,
          );
          Future.delayed(const Duration(milliseconds: 100)).then(
            (_) async {
              if (from && intent) {
                cartTotalClear();
                await Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const Cart(
                      fromBottom: false,
                    ),
                  ),
                );
              }
            },
          );
        }
      } else {
        if (mounted) {
          setState(
            () {
              _isNetworkAvail = false;
            },
          );
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  Future<void> getReview() async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          var parameter = {
            PRODUCT_ID: widget.model!.id,
            LIMIT: perPage.toString(),
            OFFSET: offset.toString(),
          };
          apiBaseHelper.postAPICall(getRatingApi, parameter).then(
            (getdata) {
              bool error = getdata['error'];
              String? msg = getdata['message'];
              if (!error) {
                total = int.parse(getdata['total']);

                star1 = getdata['star_1'];
                star2 = getdata['star_2'];
                star3 = getdata['star_3'];
                star4 = getdata['star_4'];
                star5 = getdata['star_5'];
                if ((offset) < total) {
                  var data = getdata['data'];
                  reviewList = (data as List)
                      .map((data) => User.forReview(data))
                      .toList();

                  offset = offset + perPage;
                }
              } else {
                if (msg != 'No ratings found !') setSnackbar(msg!, context);
              }
              if (mounted) {
                setState(
                  () {
                    _isLoading = false;
                  },
                );
              }
            },
            onError: (error) {
              setSnackbar(error.toString(), context);
            },
          );
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          if (mounted) {
            setState(
              () {
                _isLoading = false;
              },
            );
          }
        }
      } else {
        if (mounted) {
          setState(
            () {
              _isNetworkAvail = false;
            },
          );
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  _setFav(int index, int from) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (mounted) {
            setState(
              () {
                index == -1
                    ? widget.model!.isFavLoading = true
                    : from == 1
                        ? productList[index].isFavLoading = true
                        : mostFavProList[index].isFavLoading = true;
              },
            );
          }

          var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: widget.model!.id};
          apiBaseHelper.postAPICall(setFavoriteApi, parameter).then(
            (getdata) {
              bool error = getdata['error'];
              String? msg = getdata['message'];
              if (!error) {
                index == -1
                    ? widget.model!.isFav = '1'
                    : from == 1
                        ? productList[index].isFav = '1'
                        : mostFavProList[index].isFav = '1';

                context.read<FavoriteProvider>().addFavItem(widget.model);
              } else {
                setSnackbar(msg!, context);
              }

              if (mounted) {
                setState(
                  () {
                    index == -1
                        ? widget.model!.isFavLoading = false
                        : productList[index].isFavLoading = false;
                  },
                );
              }
            },
            onError: (error) {
              setSnackbar(error.toString(), context);
            },
          );
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        }
      } else {
        if (mounted) {
          setState(
            () {
              _isNetworkAvail = false;
            },
          );
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  _removeFav(int index, int from) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (mounted) {
            setState(
              () {
                index == -1
                    ? widget.model!.isFavLoading = true
                    : from == 1
                        ? productList[index].isFavLoading = true
                        : mostFavProList[index].isFavLoading =
                            true; //mostFavProList
              },
            );
          }

          var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: widget.model!.id};
          apiBaseHelper.postAPICall(removeFavApi, parameter).then(
            (getdata) {
              bool error = getdata['error'];
              String? msg = getdata['message'];
              if (!error) {
                index == -1
                    ? widget.model!.isFav = '0'
                    : from == 1
                        ? productList[index].isFav = '1'
                        : mostFavProList[index].isFav = '1';
                context.read<FavoriteProvider>().removeFavItem(
                      widget.model!.prVarientList![0].id!,
                    );
              } else {
                setSnackbar(msg!, context);
              }

              if (mounted) {
                setState(
                  () {
                    index == -1
                        ? widget.model!.isFavLoading = false
                        : from == 1
                            ? productList[index].isFavLoading = false
                            : mostFavProList[index].isFavLoading = false;
                  },
                );
              }
            },
            onError: (error) {
              setSnackbar(error.toString(), context);
            },
          );
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        }
      } else {
        if (mounted) {
          setState(
            () {
              _isNetworkAvail = false;
            },
          );
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

//==============================================================================
//========================== get Silver App Bar ================================
  getSilverAppBar() {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.40,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.white,
      stretch: true,
      leading: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1a0400ff),
                  offset: Offset(0, 0),
                  blurRadius: 30,
                )
              ],
              color: Theme.of(context).colorScheme.white,
              borderRadius: BorderRadius.circular(7),
            ),
            width: 33,
            height: 33,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: colors.primary,
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(
            right: 10.0,
            bottom: 10.0,
            top: 10.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                circularBorderRadius7,
              ),
              color: Theme.of(context).colorScheme.white,
            ),
            width: 33,
            height: 33,
            child: Center(
              child: IconButton(
                icon: const Icon(
                  Icons.share,
                  size: 20.0,
                  color: colors.primary,
                ),
                onPressed: createDynamicLink,
              ),
            ),
          ),
        ),
        Selector<UserProvider, String>(
          builder: (context, data, child) {
            return Padding(
              padding: const EdgeInsets.only(
                right: 10.0,
                bottom: 10.0,
                top: 10.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(circularBorderRadius7),
                  color: Theme.of(context).colorScheme.white,
                ),
                width: 33,
                height: 33,
                child: IconButton(
                  icon: Stack(
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          '${imagePath}appbarCart.svg',
                          color: colors.primary,
                        ),
                      ),
                      (data != '' && data.isNotEmpty && data != '0')
                          ? Positioned(
                              bottom: 5,
                              right: 5,
                              child: Container(
                                height: 20,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.primary,
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Text(
                                      data,
                                      style: TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(context).colorScheme.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container()
                    ],
                  ),
                  onPressed: () {
                    cartTotalClear();
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const Cart(
                          fromBottom: false,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
          selector: (_, homeProvider) => homeProvider.curCartCount,
        ),
           Selector<FavoriteProvider, List<String?>>(
          builder: (context, data, child) {
            return   Padding(
          padding: const EdgeInsets.only(
            right: 10.0,
            bottom: 10.0,
            top: 10.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(circularBorderRadius7),
              color: Theme.of(context).colorScheme.white,
            ),
            width: 33,
            height: 33,
            child: IconButton(
              icon: Icon(
                    !data.contains(widget.model!.id)
                        ? Icons.favorite_border
                        : Icons.favorite,
                    size: 20,
                    color: colors.primary,
                  ),
              onPressed: () {
                  if (CUR_USERID != null) {
                      !data.contains(widget.model!.id)
                          ? _setFav(-1, -1)
                          : _removeFav(-1, -1);
                    } else {
                      if (!data.contains(widget.model!.id)) {
                        widget.model!.isFavLoading = true;
                        widget.model!.isFav = '1';
                        context
                            .read<FavoriteProvider>()
                            .addFavItem(widget.model);
                        db.addAndRemoveFav(widget.model!.id!, true);
                        widget.model!.isFavLoading = false;
                        setSnackbar(getTranslated(context, 'Added to favorite')!, context);
                      } else {
                        widget.model!.isFavLoading = true;
                        widget.model!.isFav = '0';
                        context
                            .read<FavoriteProvider>()
                            .removeFavItem(widget.model!.prVarientList![0].id!);
                        db.addAndRemoveFav(widget.model!.id!, false);
                        widget.model!.isFavLoading = false;
                        setSnackbar(getTranslated(context, 'Removed from favorite')!, context);
                      }
                      setState(
                        () {},
                      );
                    }
              },
            ),
          ),
         );
          },
          selector: (_, provider) => provider.favIdList,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _slider(),
      ),
    );
  }

  _showContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              getSilverAppBar(),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              color: Theme.of(context).colorScheme.white,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _brandname(),
                                  _title(),
                                  available! || outOfStock!
                                      ? _price(selectIndex, true)
                                      : _price(widget.model!.selVarient, false),
                                  _rate(),
                                ],
                              ),
                            ),
                            widget.model!.attributeList!.isNotEmpty
                                ? getDivider(2, context)
                                : Container(),
                            getvariantPart(),
                            getDivider(2, context),
                            promoList.isNotEmpty
                                ? saveExtraWithOffers()
                                : Container(),
                            promoList.isNotEmpty
                                ? getDivider(2, context)
                                : Container(),
                            productDetail(),
                            getDivider(2, context),
                            _deliverPincode(),
                            getDivider(2, context),
                            compareProduct(),
                            getDivider(2, context),
                            sellerDetail(),
                            getDivider(2, context),
                            _speciExtraBtnDetails(),
                          ],
                        ),
                        reviewList.isNotEmpty
                            ? getDivider(2, context)
                            : Container(),
                        reviewList.isNotEmpty
                            ? Container(
                                color: Theme.of(context).colorScheme.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _reviewTitle(),
                                    _reviewStar(),
                                    revImgList.isNotEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.only(
                                              right: 8.0,
                                              left: 8.0,
                                            ),
                                            child: Divider(),
                                          )
                                        : Container(),
                                    revImgList.isNotEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              right: 15.0,
                                              left: 15,
                                              top: 19,
                                              bottom: 5,
                                            ),
                                            child: Text(
                                                getTranslated(context, 'Real images and videos from customers')!,
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .black,
                                                    fontWeight: FontWeight.w500,
                                                    fontStyle: FontStyle.normal,
                                                    fontSize: 12.0),
                                                textAlign: TextAlign.left),
                                          )
                                        : Container(),
                                    _reviewImg(),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                          right: 8.0, left: 8.0),
                                      child: Divider(),
                                    ),
                                    _review(),
                                  ],
                                ),
                              )
                            : Container(),
                        faqsQuesAndAns(),
                        productList.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  getTranslated(context, 'MORE_PRODUCT')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                      ),
                                ),
                              )
                            : Container(),
                        productList.isNotEmpty
                            ? Container(
                                height: 230,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: NotificationListener<ScrollNotification>(
                                    onNotification:
                                        (ScrollNotification scrollInfo) {
                                      if (scrollInfo.metrics.pixels ==
                                          scrollInfo.metrics.maxScrollExtent) {
                                        getProduct();
                                      }
                                      return true;
                                    },
                                    child: ListView.builder(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      itemCount:
                                          (notificationoffset < totalProduct)
                                              ? productList.length + 1
                                              : productList.length,
                                      itemBuilder: (context, index) {
                                        return (index == productList.length &&
                                                !notificationisloadmore)
                                            ? simmerSingle()
                                            : productItem(
                                                index, productList, 1);
                                      },
                                    )))
                            : Container(
                                height: 0,
                              ),
                        _mostFav()
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        widget.model!.attributeList!.isEmpty
            ? widget.model!.availability != '0'
                ? Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.white,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.black26,
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              addToCart(
                                qtyController.text,
                                false,
                                true,
                                widget.model!,
                              );
                            },
                            child: Center(
                              child: Text(
                                getTranslated(context, 'ADD_CART')!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.normal,
                                    ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              String qty;
                              qty = qtyController.text;
                              addToCart(
                                qty,
                                true,
                                true,
                                widget.model!,
                              );
                            },
                            child: Container(
                              height: 55,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colors.grad1Color,
                                      colors.grad2Color
                                    ],
                                    stops: [
                                      0,
                                      1
                                    ]),
                              ),
                              child: Center(
                                child: Text(
                                  getTranslated(context, 'BUYNOW')!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color:
                                            Theme.of(context).colorScheme.white,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.normal,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.white,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.black26,
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        getTranslated(context, 'OUT_OF_STOCK_LBL')!,
                        style: Theme.of(context).textTheme.button!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.red,
                            ),
                      ),
                    ),
                  )
            : available!
                ? Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.white,
                      boxShadow: [
                        BoxShadow(
                            color: Theme.of(context).colorScheme.black26,
                            blurRadius: 10)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              addToCart(
                                qtyController.text,
                                false,
                                true,
                                widget.model!,
                              );
                            },
                            child: Center(
                              child: Text(getTranslated(context, 'ADD_CART')!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                          color: colors.primary,
                                          fontWeight: FontWeight.normal)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              String qty;
                              qty = qtyController.text;
                              addToCart(
                                qty,
                                true,
                                true,
                                widget.model!,
                              );
                            },
                            child: Container(
                              height: 55,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colors.grad1Color,
                                      colors.grad2Color
                                    ],
                                    stops: [
                                      0,
                                      1
                                    ]),
                              ),
                              child: Center(
                                child: Text(
                                  getTranslated(context, 'BUYNOW')!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color:
                                            Theme.of(context).colorScheme.white,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.normal,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : available == false || outOfStock == true
                    ? outOfStock == true
                        ? Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.black26,
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(
                                getTranslated(context, 'OUT_OF_STOCK_LBL')!,
                                style: Theme.of(context)
                                    .textTheme
                                    .button!
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                              ),
                            ),
                          )
                        : Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.black26,
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(
                               getTranslated(context, 'Varient not available')!,
                                style: Theme.of(context)
                                    .textTheme
                                    .button!
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                              ),
                            ),
                          )
                    : Container()
      ],
    );
  }

  _mostFav() {
    return mostFavProList.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                    padding: const EdgeInsetsDirectional.only(
                        start: 12.0, end: 15.0),
                    child: Text(getTranslated(context, 'You are looking for')! ,
                        style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor))),
                Container(
                  height: 230,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: mostFavProList.length,
                    itemBuilder: (context, index) {
                      return productItemView(
                        index,
                        mostFavProList,
                        context,
                        detail1Hero,
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  faqsQuesAndAns() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: 15,
          end: 15,
          bottom: 20,
          top: 15,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getTranslated(context, 'Customer Questions')!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.black,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Ubuntu',
                  fontStyle: FontStyle.normal,
                  fontSize: 16.0),
            ),
            faqsProductList.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      color: Theme.of(context).colorScheme.white,
                      child: Container(
                        color: Theme.of(context).colorScheme.white,
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25)),
                          height: 44,
                          child: TextField(
                            controller: _controller1,
                            autofocus: false,
                            focusNode: searchFocusNode,
                            enabled: true,
                            textAlign: TextAlign.left,
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.black),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.black),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0),
                                ),
                              ),
                              contentPadding:
                                  const EdgeInsets.fromLTRB(15.0, 5.0, 0, 5.0),
                              border: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10.0),
                                ),
                              ),
                              fillColor: Colors.transparent,
                              filled: true,
                              isDense: true,
                              hintText: getTranslated(context, 'Have a question? Search for answers'),
                              hintStyle: Theme.of(context)
                                  .textTheme
                                  .bodyText2!
                                  .copyWith(
                                      color: const Color(0xffa0a1a0),
                                      fontWeight: FontWeight.w300,
                                      fontFamily: 'Ubuntu',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 12.0),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 10.0),
                                child: Icon(
                                  Icons.search,
                                  size: 30,
                                  color: Theme.of(context).colorScheme.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(),
            _faqsQue(),
            const Divider(),
            CUR_USERID != '' && CUR_USERID != null
                ? faqsProductList.isNotEmpty
                    ? Container()
                    : postQues()
                : const SizedBox(),
            if (faqsProductList.isNotEmpty) _allQuesBtn()
          ],
        ),
      ),
    );
  }

  Widget bottomSheetHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: Theme.of(context).colorScheme.lightBlack),
            height: 5,
            width: MediaQuery.of(context).size.width * 0.3,
          ),
        ],
      ),
    );
  }

  void openPostQueBottomSheet() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40.0),
            topRight: Radius.circular(40.0),
          ),
        ),
        isScrollControlled: true,
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return Form(
              key: faqsKey,
              child: Wrap(
                children: [
                  bottomSheetHandle(context),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40.0),
                        topRight: Radius.circular(40.0),
                      ),
                      color: Theme.of(context).colorScheme.white,
                    ),
                    padding: EdgeInsetsDirectional.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 30.0, bottom: 20),
                          child: Text(
                            getTranslated(context, 'Write Question')!,
                            style: Theme.of(context)
                                .textTheme
                                .subtitle1!
                                .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .fontColor),
                          ),
                        ),
                        Flexible(
                          child: Padding(
                            padding:
                                const EdgeInsetsDirectional.only(top: 10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                      start: 20, end: 20),
                                  child: Container(
                                    height: MediaQuery.of(context).size.height *
                                        0.25,
                                    decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightWhite),
                                    child: TextFormField(
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .fontColor,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                          fontSize: 14.0),
                                      onChanged: (value) {},
                                      onSaved: ((String? val) {}),
                                      maxLines: null,
                                      validator: (val) {
                                        if (val!.isEmpty) {
                                          return getTranslated(context, 'Please provide more details on your question');
                                        }
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: getTranslated(context, 'Type your question'),
                                        contentPadding:
                                            const EdgeInsetsDirectional.all(
                                                25.0),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .colorScheme
                                            .lightWhite,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            borderSide: const BorderSide(
                                                width: 0.0,
                                                style: BorderStyle.none)),
                                      ),
                                      keyboardType: TextInputType.multiline,
                                      controller: edtFaqs,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.all(20),
                                  child: SimBtn(
                                    size: 0.5,
                                    borderRadius: 10,
                                    title:
                                        getTranslated(context, 'SUBMIT_LBL')!,
                                    height: 45,
                                    onBtnSelected: () {
                                      final form = faqsKey.currentState!;
                                      form.save();
                                      if (form.validate()) {
                                        context
                                            .read<CartProvider>()
                                            .setProgress(true);
                                        setFaqsQue();
                                      }
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  _allQuesBtn() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => FaqsProduct(widget.model!.id)),
          );
        },
        child: Row(
          children: [
            Text(
              getTranslated(context, 'See all answered questions')!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Ubuntu',
                  fontStyle: FontStyle.normal,
                  fontSize: 14.0),
            ),
            const Spacer(),
            Icon(
              Icons.keyboard_arrow_right,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            )
          ],
        ),
      ),
    );
  }

  Widget _faqsQue() {
    return _isFaqsLoading
        ? const Center(child: CircularProgressIndicator())
        : faqsProductList.isNotEmpty
            ? Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 0, end: 10, top: 15, bottom: 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      itemCount: faqsProductList.length >= 5
                          ? 5
                          : faqsProductList.length,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(),
                      itemBuilder: (context, index) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                            getTranslated(context, 'Que :')!+  ' ${faqsProductList[index].question!}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Ubuntu',
                                fontStyle: FontStyle.normal,
                                fontSize: 14.0,
                              ),
                              maxLines: 10,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: SizedBox(
                                width: deviceWidth! * 0.9,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                            getTranslated(context, 'Ans')!          +' : ',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .fontColor,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Ubuntu',
                                        fontStyle: FontStyle.normal,
                                        fontSize: 14.0,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        "${faqsProductList[index].answer ?? ""}",
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack,
                                          fontSize: 14,
                                        ),
                                        maxLines: 10,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 3.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    faqsProductList[index].ansBy ?? '',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack
                                            .withOpacity(0.5),
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Ubuntu',
                                        fontStyle: FontStyle.normal,
                                        fontSize: 12.0),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10.0, right: 10),
                                    child: Text(
                                      '|',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack
                                            .withOpacity(0.5),
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Ubuntu',
                                        fontStyle: FontStyle.normal,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    faqsProductList[index].dateAdded!,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightBlack
                                          .withOpacity(0.5),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Ubuntu',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        );
                      },
                    )
                  ],
                ),
              )
            : const SizedBox();
  }

  simmerSingle() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.simmerBase,
        highlightColor: Theme.of(context).colorScheme.simmerHigh,
        child: Container(
          width: deviceWidth! * 0.45,
          height: 250,
          color: Theme.of(context).colorScheme.white,
        ),
      ),
    );
  }

  shimmerCompare() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.gray,
      highlightColor: Theme.of(context).colorScheme.gray,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsetsDirectional.only(start: 8.0),
          child: Container(
            width: deviceWidth! * 0.45,
            height: 255,
            color: Theme.of(context).colorScheme.white,
          ),
        ),
        itemCount: 10,
      ),
    );
  }

  _madeIn() {
    String? madeIn = widget.model!.madein;

    return madeIn != '' && madeIn!.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListTile(
              trailing: Text(madeIn),
              dense: true,
              title: Text(
                getTranslated(context, 'MADE_IN')!,
                style: Theme.of(context).textTheme.subtitle2,
              ),
            ),
          )
        : Container();
  }

  getvariantPart() {
    return widget.model!.attributeList!.isNotEmpty
        ? Container(
            color: Theme.of(context).colorScheme.white,
            child: Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: ListView.builder(
                padding: const EdgeInsets.all(0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.model!.attributeList!.length,
                itemBuilder: (context, index) {
                  List<Widget?> chips = [];
                  List<String> att =
                      widget.model!.attributeList![index].value!.split(',');
                  List<String> attId =
                      widget.model!.attributeList![index].id!.split(',');
                  List<String> attSType =
                      widget.model!.attributeList![index].sType!.split(',');

                  List<String> attSValue =
                      widget.model!.attributeList![index].sValue!.split(',');

                  int? varSelected;

                  List<String> wholeAtt = widget.model!.attrIds!.split(',');
                  for (int i = 0; i < att.length; i++) {
                    Widget itemLabel;
                    if (attSType[i] == '1') {
                      String clr = (attSValue[i].substring(1));

                      String color = '0xff$clr';

                      itemLabel = Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedIndex[index] == (i)
                              ? colors.primary
                              : colors.black12,
                        ),
                        child: Center(
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(
                                int.parse(color),
                              ),
                            ),
                          ),
                        ),
                      );
                    } else if (attSType[i] == '2') {
                      itemLabel = Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _selectedIndex[index] == (i)
                                  ? [colors.grad1Color, colors.grad2Color]
                                  : [
                                      Theme.of(context).colorScheme.white,
                                      Theme.of(context).colorScheme.white,
                                    ],
                              stops: const [0, 1]),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          border: Border.all(
                            color: _selectedIndex[index] == (i)
                                ? const Color(0xfffc6a57)
                                : Theme.of(context).colorScheme.black,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            attSValue[i],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                erroWidget(80),
                          ),
                        ),
                      );
                    } else {
                      itemLabel = Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _selectedIndex[index] == (i)
                                ? [colors.grad1Color, colors.grad2Color]
                                : [
                                    Theme.of(context).colorScheme.white,
                                    Theme.of(context).colorScheme.white,
                                  ],
                            stops: const [0, 1],
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          border: Border.all(
                              color: _selectedIndex[index] == (i)
                                  ? Color(0xfffc6a57)
                                  : Theme.of(context).colorScheme.black,
                              width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 6,
                          ),
                          child: Text(
                            att[i],
                            style: TextStyle(
                              color: _selectedIndex[index] == (i)
                                  ? Theme.of(context).colorScheme.white
                                  : Theme.of(context).colorScheme.fontColor,
                            ),
                          ),
                        ),
                      );
                    }

                    if (_selectedIndex[index] != null &&
                        wholeAtt.contains(attId[i])) {
                      choiceContainer = Padding(
                        padding: const EdgeInsets.only(
                          right: 10,
                          // left: 5,
                        ),
                        child: InkWell(
                          onTap: () async {
                            if (att.length != 1) {
                              if (mounted) {
                                setState(
                                  () {
                                    widget.model!.selVarient = i;
                                    available = false;
                                    _selectedIndex[index] = i;
                                    List<int> selectedId =
                                        []; //list where user choosen item id is stored
                                    List<bool> check = [];
                                    for (int i = 0;
                                        i < widget.model!.attributeList!.length;
                                        i++) {
                                      List<String> attId = widget
                                          .model!.attributeList![i].id!
                                          .split(',');
                                      if (_selectedIndex[i] != null) {
                                        selectedId.add(
                                          int.parse(
                                            attId[_selectedIndex[i]!],
                                          ),
                                        );
                                      }
                                    }

                                    check.clear();
                                    late List<String> sinId;
                                    findMatch:
                                    for (int i = 0;
                                        i < widget.model!.prVarientList!.length;
                                        i++) {
                                      sinId = widget.model!.prVarientList![i]
                                          .attribute_value_ids!
                                          .split(',');

                                      for (int j = 0;
                                          j < selectedId.length;
                                          j++) {
                                        if (sinId.contains(
                                            selectedId[j].toString())) {
                                          check.add(true);

                                          if (selectedId.length ==
                                                  sinId.length &&
                                              check.length ==
                                                  selectedId.length) {
                                            varSelected = i;
                                            selectIndex = i;
                                            break findMatch;
                                          }
                                        } else {
                                          check.clear();
                                          selectIndex = null;
                                          break;
                                        }
                                      }
                                    }

                                    if (selectedId.length == sinId.length &&
                                        check.length == selectedId.length) {
                                      if (widget.model!.stockType == '0' ||
                                          widget.model!.stockType == '1') {
                                        if (widget.model!.availability == '1') {
                                          available = true;
                                          outOfStock = false;
                                          _oldSelVarient = varSelected!;
                                        } else {
                                          available = false;
                                          outOfStock = true;
                                        }
                                      } else if (widget.model!.stockType ==
                                          '') {
                                        available = true;
                                        outOfStock = false;
                                        _oldSelVarient = varSelected!;
                                      } else if (widget.model!.stockType ==
                                          '2') {
                                        if (widget
                                                .model!
                                                .prVarientList![varSelected!]
                                                .availability ==
                                            '1') {
                                          available = true;
                                          outOfStock = false;
                                          _oldSelVarient = varSelected!;
                                        } else {
                                          available = false;
                                          outOfStock = true;
                                        }
                                      }
                                    } else {
                                      available = false;
                                      outOfStock = false;
                                    }
                                    if (widget
                                        .model!
                                        .prVarientList![_oldSelVarient]
                                        .images!
                                        .isNotEmpty) {
                                      int oldVarTotal = 0;
                                      if (_oldSelVarient > 0) {
                                        for (int i = 0;
                                            i < _oldSelVarient;
                                            i++) {
                                          oldVarTotal = oldVarTotal +
                                              widget.model!.prVarientList![i]
                                                  .images!.length;
                                        }
                                      }
                                      int p = widget.model!.otherImage!.length +
                                          1 +
                                          oldVarTotal;

                                      _pageController.jumpToPage(p);
                                    }
                                  },
                                );
                                // }
                              }
                              if (available!) {
                                if (CUR_USERID != null) {
                                  if (widget
                                          .model!
                                          .prVarientList![_oldSelVarient]
                                          .cartCount! !=
                                      '0') {
                                    qtyController.text = widget
                                        .model!
                                        .prVarientList![_oldSelVarient]
                                        .cartCount!;
                                    qtyChange = true;
                                  } else {
                                    qtyController.text = widget
                                        .model!.minOrderQuntity
                                        .toString();
                                    qtyChange = true;
                                  }
                                } else {
                                  String qty = (await db.checkCartItemExists(
                                      widget.model!.id!,
                                      widget
                                          .model!
                                          .prVarientList![_oldSelVarient]
                                          .id!))!;
                                  if (qty == '0') {
                                    qtyController.text = widget
                                        .model!.minOrderQuntity
                                        .toString();
                                    qtyChange = true;
                                  } else {
                                    widget.model!.prVarientList![_oldSelVarient]
                                        .cartCount = qty;
                                    qtyController.text = qty;
                                    qtyChange = true;
                                  }
                                }
                              }
                            }
                          },
                          child: Container(
                            child: itemLabel,
                          ),
                        ),
                      );
                      chips.add(choiceContainer);
                    }
                  }

                  String value = _selectedIndex[index] != null &&
                          _selectedIndex[index]! <= att.length
                      ? att[_selectedIndex[index]!]
                      : getTranslated(context, 'VAR_SEL')!.substring(
                          2, getTranslated(context, 'VAR_SEL')!.length);
                  return chips.isNotEmpty
                      ? Container(
                          color: Theme.of(context).colorScheme.white,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 10.0,
                              end: 10.0,
                              //    top: 5.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 15.0),
                                  child: Text(
                                    '${widget.model!.attributeList![index].name!} : $value',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Wrap(
                                  alignment: WrapAlignment.start,
                                  children: chips.map<Widget>(
                                    (Widget? chip) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 15,
                                        ),
                                        child: chip,
                                      );
                                    },
                                  ).toList(),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container();
                },
              ),
            ),
          )
        : Container();
  }

  Widget productItem(int index, List<Product> produList, int from,
      [bool showDiscountAtSameLine = false]) {
    if (index < produList.length) {
      String? offPer;
      double price = double.parse(produList[index].prVarientList![0].disPrice!);
      if (price == 0) {
        price = double.parse(produList[index].prVarientList![0].price!);
      } else {
        double off =
            double.parse(produList[index].prVarientList![0].price!) - price;
        offPer = ((off * 100) /
                double.parse(produList[index].prVarientList![0].price!))
            .toStringAsFixed(2);
      }

      double width = deviceWidth! * 0.45;
      return SizedBox(
        height: 255,
        width: width,
        child: Card(
          elevation: 0.2,
          margin: const EdgeInsetsDirectional.only(bottom: 5, end: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Hero(
                          transitionOnUserGestures: true,
                          tag: '${produList[index].id}',
                          child: FadeInImage(
                            fadeInDuration: const Duration(milliseconds: 150),
                            image: CachedNetworkImageProvider(
                                produList[index].image!),
                            height: double.maxFinite,
                            width: double.maxFinite,
                            imageErrorBuilder: (context, error, stackTrace) =>
                                erroWidget(double.maxFinite),
                            fit: BoxFit.cover,
                            placeholder: placeHolder(width),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 10.0,
                        top: 15,
                      ),
                      child: Text(
                        produList[index].name!,
                        style: Theme.of(context).textTheme.caption!.copyWith(
                              color: Theme.of(context).colorScheme.lightBlack,
                              fontSize: textFontSize12,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.normal,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 8.0,
                        top: 5,
                      ),
                      child: Row(
                        children: [
                          Text(
                            ' ${getPriceFormat(context, price)!}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.blue,
                              fontSize: textFontSize14,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                          showDiscountAtSameLine
                              ? Expanded(
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      start: 10.0,
                                      top: 5,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Text(
                                          double.parse(produList[index]
                                                      .prVarientList![0]
                                                      .disPrice!) !=
                                                  0
                                              ? '${getPriceFormat(context, double.parse(productList[index].prVarientList![0].price!))}'
                                              : '',
                                          style: Theme.of(context)
                                              .textTheme
                                              .overline!
                                              .copyWith(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                letterSpacing: 0,
                                                fontSize: textFontSize10,
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                              ),
                                        ),
                                        Text(
                                          '  $offPer%',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .overline!
                                              .copyWith(
                                                color: colors.primary,
                                                letterSpacing: 0,
                                                fontSize: textFontSize10,
                                                fontWeight: FontWeight.w400,
                                                fontStyle: FontStyle.normal,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                    double.parse(produList[index]
                                    .prVarientList![0]
                                    .disPrice!) !=
                                0 &&
                            !showDiscountAtSameLine
                        ? Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 10.0,
                              top: 5,
                            ),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  double.parse(produList[index]
                                              .prVarientList![0]
                                              .disPrice!) !=
                                          0
                                      ? '${getPriceFormat(context, double.parse(productList[index].prVarientList![0].price!))}'
                                      : '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .overline!
                                      .copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        letterSpacing: 0,
                                        fontSize: textFontSize10,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.normal,
                                      ),
                                ),
                                Flexible(
                                  child: Text(
                                    '  $offPer%',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .overline!
                                        .copyWith(
                                          color: colors.primary,
                                          letterSpacing: 0,
                                          fontSize: textFontSize10,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.normal,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 10.0,
                        top: 10,
                        bottom: 5,
                      ),
                      child: produList[index].rating != '0.00'
                          ? StarRating(
                              totalRating: produList[index].rating!,
                              noOfRatings: produList[index].noOfRating!,
                              needToShowNoOfRatings: true,
                            )
                          : Container(
                              height: 20,
                            ),
                    )
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.white,
                      borderRadius: const BorderRadiusDirectional.only(
                        bottomStart: Radius.circular(circularBorderRadius10),
                        topEnd: Radius.circular(5),
                      ),
                    ),
                    child: produList[index].isFavLoading!
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 0.7,
                              ),
                            ),
                          )
                        : Selector<FavoriteProvider, List<String?>>(
                            builder: (context, data, child) {
                              return InkWell(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    !data.contains(produList[index].id)
                                        ? Icons.favorite_border
                                        : Icons.favorite,
                                    size: 20,
                                  ),
                                ),
                              onTap: () {
                  if (CUR_USERID != null) {
                                    !data.contains(produList[index].id)
                                        ? _setFav(index, from)
                                        : _removeFav(index, from);
                                  } else {
                                    if (!data.contains(produList[index].id)) {
                                      produList[index].isFavLoading = true;
                                      produList[index].isFav = '1';
                                      context
                                          .read<FavoriteProvider>()
                                          .addFavItem(produList[index]);
                                      db.addAndRemoveFav(
                                          produList[index].id!, true);
                                      produList[index].isFavLoading = false;
                                    } else {
                                      produList[index].isFavLoading = true;
                                      produList[index].isFav = '0';
                                      context
                                          .read<FavoriteProvider>()
                                          .removeFavItem(produList[index]
                                              .prVarientList![0]
                                              .id!);
                                      db.addAndRemoveFav(
                                          produList[index].id!, false);
                                      produList[index].isFavLoading = false;
                                    }
                                    setState(
                                      () {},
                                    );
                                  }
                  },
                              );
                            },
                            selector: (_, provider) => provider.favIdList,
                          ),
                  ),
                ),
              ],
            ),
            onTap: () {
              Product model = produList[index];
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => ProductDetail(
                      model: model, secPos: 0, index: index, list: false),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  Widget _review() {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            itemCount: reviewList.length >= 2 ? 2 : reviewList.length,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            color: Color(0xff048d63),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  reviewList[index].rating ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Ubuntu',
                                      fontStyle: FontStyle.normal,
                                      fontSize: 16.0),
                                ),
                                const Icon(
                                  Icons.star,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reviewList[index].comment ?? '',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.black,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Ubuntu',
                                fontStyle: FontStyle.normal,
                                fontSize: 14.0,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reviewList[index].username ?? '',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack
                                            .withOpacity(0.5),
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Ubuntu',
                                        fontStyle: FontStyle.normal,
                                        fontSize: 12.0),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10.0, right: 10),
                                    child: Text(
                                      '|',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack
                                              .withOpacity(0.5),
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Ubuntu',
                                          fontStyle: FontStyle.normal,
                                          fontSize: 12.0),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 5.0, right: 5),
                                    child: Text(
                                      reviewList[index].date!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack
                                              .withOpacity(0.5),
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Ubuntu',
                                          fontStyle: FontStyle.normal,
                                          fontSize: 12.0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  reviewImage(index),
                ],
              );
            },
          );
  }

  Future getProduct() async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          if (notificationisloadmore) {
            if (mounted) {
              setState(
                () {
                  notificationisloadmore = false;
                  notificationisgettingdata = true;
                  if (notificationoffset == 0) {
                    productList = [];
                  }
                },
              );
            }

            var parameter = {
              CATID: widget.model!.categoryId,
              LIMIT: perPage.toString(),
              OFFSET: notificationoffset.toString(),
              ID: widget.model!.id,
              IS_SIMILAR: '1'
            };

            if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;

            apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
              bool error = getdata['error'];
              notificationisgettingdata = false;
              if (notificationoffset == 0) notificationisnodata = error;
              if (!error) {
                totalProduct = int.parse(getdata['total']);
                if (mounted) {
                  Future.delayed(
                    Duration.zero,
                    () => setState(
                      () {
                        List mainlist = getdata['data'];

                        if (mainlist.isNotEmpty) {
                          List<Product> items = [];
                          List<Product> allitems = [];

                          items.addAll(mainlist
                              .map((data) => Product.fromJson(data))
                              .toList());

                          allitems.addAll(items);
                          for (Product item in items) {
                            productList.where((i) => i.id == item.id).map(
                              (obj) {
                                allitems.remove(item);
                                return obj;
                              },
                            ).toList();
                          }
                          productList.addAll(allitems);
                          notificationisloadmore = true;

                          notificationoffset = notificationoffset + perPage;
                        } else {
                          notificationisloadmore = false;
                        }
                      },
                    ),
                  );
                }
              } else {
                notificationisloadmore = false;
                if (mounted) {
                  setState(
                    () {},
                  );
                }
              }
            }, onError: (error) {
              setSnackbar(error.toString(), context);
            });
          }
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          if (mounted) {
            setState(
              () {
                notificationisloadmore = false;
              },
            );
          }
        }
      } else {
        if (mounted) {
          setState(
            () {
              _isNetworkAvail = false;
            },
          );
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  Future<void> getProduct1() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          CATID: widget.model!.categoryId,
          ID: widget.model!.id,
          IS_SIMILAR: '1'
        };

        if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID;

        apiBaseHelper.postAPICall(getProductApi, parameter).then(
          (getdata) {
            bool error = getdata['error'];

            if (!error) {
              context.read<ProductDetailProvider>().setProTotal(
                    int.parse(
                      getdata['total'],
                    ),
                  );

              List mainlist = getdata['data'];

              if (mainlist.isNotEmpty) {
                List<Product> items = [];
                List<Product> allitems = [];
                productList1 = [];

                items.addAll(
                  mainlist.map((data) => Product.fromJson(data)).toList(),
                );

                allitems.addAll(items);

                for (Product item in items) {
                  productList1.where((i) => i.id == item.id).map(
                    (obj) {
                      allitems.remove(item);
                      return obj;
                    },
                  ).toList();
                }
                productList1.addAll(allitems);

                context
                    .read<ProductDetailProvider>()
                    .setProductList(productList1);

                context.read<ProductDetailProvider>().setProOffset(
                      context.read<ProductDetailProvider>().offset + perPage,
                    );
              }
            } else {
              if (mounted) {
                setState(
                  () {
                    context
                        .read<ProductDetailProvider>()
                        .setProNotiLoading(false);
                  },
                );
              }
            }
          },
          onError: (error) {
            setSnackbar(error.toString(), context);
          },
        );
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        if (mounted) {
          setState(
            () {
              context.read<ProductDetailProvider>().setProNotiLoading(false);
            },
          );
        }
      }
    } else {
      if (mounted) {
        setState(
          () {
            _isNetworkAvail = false;
          },
        );
      }
    }
  }

  productDetail() {
    return widget.model!.attributeList!.isNotEmpty ||
            (widget.model!.desc != '' && widget.model!.desc != null) ||
            widget.model!.madein != '' && widget.model!.madein!.isNotEmpty
        ? Container(
            color: Theme.of(context).colorScheme.white,
            padding: const EdgeInsets.only(top: 10.0),
            child: InkWell(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 15.0,
                      end: 15.0,
                      bottom: 15,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            getTranslated(context, 'Product Details')!,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Ubuntu',
                                fontStyle: FontStyle.normal,
                                fontSize: 16.0,
                                color:
                                    Theme.of(context).colorScheme.lightBlack),
                          ),
                        ),
                      ],
                    ),
                  ),
                  !seeView
                      ? SizedBox(
                          height: 100,
                          width: deviceWidth! - 10,
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _desc(),
                                widget.model!.desc != '' &&
                                        widget.model!.desc != null
                                    ? const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.0,
                                        ),
                                        child: Divider(
                                          height: 3.0,
                                        ),
                                      )
                                    : Container(),
                                _attr(),
                                widget.model!.madein != '' &&
                                        widget.model!.madein!.isNotEmpty
                                    ? const Divider()
                                    : Container(),
                                _madeIn(),
                              ],
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _desc(),
                              widget.model!.desc != '' &&
                                      widget.model!.desc != null
                                  ? const Divider(
                                      height: 3.0,
                                    )
                                  : Container(),
                              _attr(),
                              widget.model!.madein != '' &&
                                      widget.model!.madein!.isNotEmpty
                                  ? const Divider()
                                  : Container(),
                              _madeIn(),
                            ],
                          ),
                        ),
                  Row(
                    children: [
                      InkWell(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                              start: 15, top: 10, end: 2, bottom: 15),
                          child: Text(
                            !seeView ? getTranslated(context, 'See More')! : getTranslated(context, 'See Less')!,
                            style: Theme.of(context)
                                .textTheme
                                .caption!
                                .copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Ubuntu',
                                    fontStyle: FontStyle.normal,
                                    fontSize: 14.0),
                          ),
                        ),
                        onTap: () {
                          setState(
                            () {
                              seeView = !seeView;
                            },
                          );
                        },
                      ),
                      Icon(
                        Icons.keyboard_arrow_right,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        : Container();
  }

  _deliverPincode() {
    String pin = context.read<UserProvider>().curPincode;

    return Container(
      padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
      color: Theme.of(context).colorScheme.white,
      child: InkWell(
        onTap: _pincodeCheck,
        child: ListTile(
          dense: true,
          title: Row(
            children: [
              Text(
                pin == ''
                    ? getTranslated(context, 'SELOC')!
                    : getTranslated(context, 'DELIVERTO')!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.black,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Ubuntu',
                    fontStyle: FontStyle.normal,
                    fontSize: 16.0),
              ),
              Text(
                pin == '' ? '' : pin,
                style: const TextStyle(
                  color: Color(0xffa0a1a0),
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Ubuntu',
                  fontStyle: FontStyle.normal,
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_right,
            size: 30,
            color: Theme.of(context).colorScheme.black,
          ),
        ),
      ),
    );
  }

  saveExtraWithOffers() {
    return Container(
      padding: const EdgeInsets.only(top: 5.0),
      color: Theme.of(context).colorScheme.white,
      child: InkWell(
        onTap: () async {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => const PromoCode(from: 'Profile'),
            ),
          );
        },
        child: ListTile(
          dense: true,
          title: Row(
            children: [
              Text(
                getTranslated(context, 'Save extra with offers')!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.black,
                    //  Color(0xff303031),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Ubuntu',
                    fontStyle: FontStyle.normal,
                    fontSize: 16.0),
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_right,
            size: 30,
            color: Theme.of(context).colorScheme.black,
          ),
        ),
      ),
    );
  }

  sellerDetail() {
    return Container(
      padding: const EdgeInsets.only(top: 5.0),
      color: Theme.of(context).colorScheme.white,
      child: InkWell(
        onTap: () async {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (BuildContext context) => SellerProfile(
                sellerID: widget.model!.seller_id!,
                sellerImage: widget.model!.seller_profile!,
                sellerName: widget.model!.seller_name!,
                sellerRating: widget.model!.seller_rating!,
                sellerStoreName: widget.model!.store_name!,
                storeDesc: widget.model!.store_description!,
              ),
            ),
          );
        },
        child: ListTile(
          dense: true,
          title: Row(
            children: [
              Text(
                getTranslated(context, 'Seller Details')!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.black,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Ubuntu',
                    fontStyle: FontStyle.normal,
                    fontSize: 16.0),
              ),
              const SizedBox(width: 10),
              Text(
                widget.model!.store_name ?? '',
                style: const TextStyle(
                  color: Color(0xfffc6a57),
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Ubuntu',
                  fontStyle: FontStyle.normal,
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_right,
            size: 30,
            color: Theme.of(context).colorScheme.black,
          ),
        ),
      ),
    );
  }

  compareProduct() {
    return Container(
      padding: const EdgeInsets.only(top: 5.0),
      color: Theme.of(context).colorScheme.white,
      child: InkWell(
        onTap: () {
          if (context.read<ProductDetailProvider>().compareList.length > 0 &&
              context
                  .read<ProductDetailProvider>()
                  .compareList
                  .contains(widget.model)) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (BuildContext context) => const CompareList(),
              ),
            );
          } else {
            context.read<ProductDetailProvider>().addCompareList(widget.model!);

            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (BuildContext context) => const CompareList(),
              ),
            );
          }
        },
        child: ListTile(
          dense: true,
          title: Row(
            children: [
              Text(
                getTranslated(context, 'COMPARE_PRO')!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.black,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Ubuntu',
                    fontStyle: FontStyle.normal,
                    fontSize: 16.0),
              ),
            ],
          ),
          trailing: Icon(
            Icons.keyboard_arrow_right,
            size: 30,
            color: Theme.of(context).colorScheme.black,
          ),
        ),
      ),
    );
  }

  getImageWithHeading(String image, String heading) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 7.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 5.0),
            child: ClipRRect(
              child: SvgPicture.asset(
                image,
                height: 32.0,
                width: 32.0,
                fit: BoxFit.cover,
                color: Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width * (0.22),
            child: Text(
              heading,
              style: const TextStyle(
                fontSize: textFontSize12,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 2, //
            ),
          ),
        ],
      ),
    );
  }

  _speciExtraBtnDetails() {
    String? cod = widget.model!.codAllowed;
    if (cod == '1') {
      cod = 'COD';
    } else {
      cod = getTranslated(context, 'COD Not Allowed');
    }

    String? cancellable = widget.model!.isCancelable;
    if (cancellable == '1') {
      cancellable =
          '${getTranslated(context, "Cancellable Till")!} ${widget.model!.cancleTill!}';
    } else {
      cancellable = getTranslated(context, 'No Cancellable');
    }

    String? returnable = widget.model!.isReturnable;
    if (returnable == '1') {
      returnable =
          '${RETURN_DAYS!} ${getTranslated(context, "Days Returnable")}';
    } else {
      returnable = getTranslated(context, 'No Returnable')!;
    }

    String? guarantee = widget.model!.gurantee;
    String? warranty = widget.model!.warranty;

    return Container(
      color: Theme.of(context).colorScheme.white,
      width: deviceWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        child: Row(
          children: [
            widget.model!.codAllowed == '1'
                ? Expanded(
                    child: getImageWithHeading(
                      'assets/images/cod.svg',
                      cod!,
                    ),
                  )
                : Container(
                    width: 0,
                  ),
            Expanded(
              child: getImageWithHeading(
                widget.model!.isCancelable == '1'
                    ? 'assets/images/cancelable.svg'
                    : 'assets/images/notcancelable.svg',
                cancellable!,
              ),
            ),
            Expanded(
              child: getImageWithHeading(
                widget.model!.isReturnable == '1'
                    ? 'assets/images/returnable.svg'
                    : 'assets/images/notreturnable.svg',
                returnable,
              ),
            ),
            guarantee != '' && guarantee!.isNotEmpty
                ? Expanded(
                    child: getImageWithHeading(
                      'assets/images/guarantee.svg',
                      '$guarantee Guarantee',
                    ),
                  )
                : Container(
                    width: 0,
                  ),
            warranty != '' && warranty!.isNotEmpty
                ? Expanded(
                    child: getImageWithHeading(
                      'assets/images/warranty.svg',
                      '$warranty Warranty',
                    ),
                  )
                : Container(
                    width: 0,
                  )
          ],
        ),
      ),
    );
  }

  _reviewTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: 5,
      ),
      child: Row(
        children: [
          Text(
            getTranslated(context, 'Product Ratings & Reviews')!,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontFamily: 'Ubuntu',
              fontStyle: FontStyle.normal,
              fontSize: 16.0,
              color: Theme.of(context).colorScheme.lightBlack,
            ),
          ),
        ],
      ),
    );
  }

  reviewImage(int i) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: SizedBox(
        height: reviewList[i].imgList!.isNotEmpty ? 60 : 0,
        child: ListView.builder(
          itemCount: reviewList[i].imgList!.length,
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 5,
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => ProductPreview(
                        pos: index,
                        secPos: widget.secPos,
                        index: widget.index,
                        id: '$index${reviewList[i].id}',
                        imgList: reviewList[i].imgList,
                        list: true,
                        from: false,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: '$index${reviewList[i].id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                    child: FadeInImage(
                      image: CachedNetworkImageProvider(
                        reviewList[i].imgList![index],
                      ),
                      height: 45.0,
                      width: 45.0,
                      fit: BoxFit.cover,
                      placeholder: placeHolder(45),
                      imageErrorBuilder: (context, error, stackTrace) =>
                          erroWidget(45),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  _attr() {
    return widget.model!.attributeList!.isNotEmpty
        ? ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.model!.attributeList!.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: EdgeInsetsDirectional.only(
                    start: 25.0,
                    top: 10.0,
                    bottom: widget.model!.madein != '' &&
                            widget.model!.madein!.isNotEmpty
                        ? 0.0
                        : 7.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        widget.model!.attributeList![i].name!,
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .fontColor
                                  .withOpacity(0.7),
                            ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 5.0),
                        child: Text(
                          widget.model!.attributeList![i].value!,
                          textAlign: TextAlign.start,
                          style: Theme.of(context)
                              .textTheme
                              .subtitle2!
                              .copyWith(
                                color: Theme.of(context).colorScheme.fontColor,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        : Container();
  }

  Future<void> getShare() async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: deepLinkUrlPrefix,
      link: Uri.parse(
          'https://$deepLinkName/?index=${widget.index}&secPos=${widget.secPos}&list=${widget.list}&id=${widget.model!.id}'),
      androidParameters: const AndroidParameters(
        packageName: packageName,
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: iosPackage,
        minimumVersion: '1',
        appStoreId: appStoreId,
      ),
    );

    /* final Uri longDynamicUrl = await parameters.buildUrl();*/

    shortenedLink =
        await FirebaseDynamicLinks.instance.buildShortLink(parameters);

    Future.delayed(
      Duration.zero,
      () {
        shareLink =
            "\n$appName\n${getTranslated(context, 'APPFIND')}$androidLink$packageName\n${getTranslated(context, 'IOSLBL')}\n$iosLink";
      },
    );
  }

  playIcon() {
    return Align(
      alignment: Alignment.center,
      child: (widget.model!.videType != '' &&
              widget.model!.video!.isNotEmpty &&
              widget.model!.video != '')
          ? const Icon(
              Icons.play_circle_fill_outlined,
              color: colors.primary,
              size: 35,
            )
          : Container(),
    );
  }

  _reviewImg() {
    return revImgList.isNotEmpty
        ? SizedBox(
            height: 60,
            child: ListView.builder(
              itemCount: revImgList.length > 6 ? 6 : revImgList.length,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 5,
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      if (index == 5) {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => ReviewGallary(
                              productModel: widget.model,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => ReviewPreview(
                              index: index,
                              productModel: widget.model,
                            ),
                          ),
                        );
                      }
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10.0)),
                          child: FadeInImage(
                            fadeInDuration: const Duration(milliseconds: 150),
                            image: CachedNetworkImageProvider(
                              revImgList[index].img!,
                            ),
                            height: 45.0,
                            width: 45.0,
                            fit: BoxFit.cover,
                            placeholder: placeHolder(45),
                            imageErrorBuilder: (context, error, stackTrace) =>
                                erroWidget(45),
                          ),
                        ),
                        index == 5
                            ? Container(
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                  color: colors.black54,
                                ),
                                height: 45.0,
                                width: 45.0,
                                child: Center(
                                  child: Text(
                                    '+${revImgList.length - 6}',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : Container()
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        : Container();
  }

  Future<void> validatePin(String pin, bool first) async {
    try {
      _isNetworkAvail = await isNetworkAvailable();
      if (_isNetworkAvail) {
        try {
          var parameter = {
            ZIPCODE: pin,
            PRODUCT_ID: widget.model!.id,
          };
          apiBaseHelper.postAPICall(checkDeliverableApi, parameter).then(
            (getdata) {
              bool error = getdata['error'];
              String? msg = getdata['message'];

              if (error) {
                curPin = '';
              } else {
                if (pin != context.read<UserProvider>().curPincode) {
                  context.read<HomeProvider>().setSecLoading(true);
                  getSection();
                }
                context.read<UserProvider>().setPincode(pin);
              }
              if (!first) {
                Navigator.pop(context);
                setSnackbar(msg!, context);
              }
            },
            onError: (error) {
              setSnackbar(error.toString(), context);
            },
          );
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        }
      } else {
        if (mounted) {
          setState(
            () {
              _isNetworkAvail = false;
            },
          );
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  void getSection() {
    try {
      Map parameter = {PRODUCT_LIMIT: '6', PRODUCT_OFFSET: '0'};

      if (CUR_USERID != null) parameter[USER_ID] = CUR_USERID!;
      String curPin = context.read<UserProvider>().curPincode;
      if (curPin != '') parameter[ZIPCODE] = curPin;

      apiBaseHelper.postAPICall(getSectionApi, parameter).then(
        (getdata) {
          bool error = getdata['error'];
          String? msg = getdata['message'];
          sectionList.clear();
          if (!error) {
            var data = getdata['data'];

            sectionList = (data as List)
                .map((data) => SectionModel.fromJson(data))
                .toList();
          } else {
            if (curPin != '') context.read<UserProvider>().setPincode('');
            setSnackbar(
              msg!,
              context,
            );
          }

          context.read<HomeProvider>().setSecLoading(false);
        },
        onError: (error) {
          setSnackbar(error.toString(), context);
          context.read<HomeProvider>().setSecLoading(false);
        },
      );
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  Future<void> getDeliverable() async {
    String pin = context.read<UserProvider>().curPincode;
    if (pin != '') {
      validatePin(pin, true);
    }
  }

  _reviewStar() {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Text(
                widget.model!.rating ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: colors.primary,
                ),
              ),
              Text(
                "${reviewList.length}  ${getTranslated(context, "RATINGS")!}",
                style: const TextStyle(
                    color: Color(0xffa0a1a0),
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Ubuntu',
                    fontStyle: FontStyle.normal,
                    fontSize: 10.0),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              getText(getTranslated(context, 'Excellent')!),
              getText(getTranslated(context, 'Very Good')!),
              getText(getTranslated(context, 'Good')!),
              getText(getTranslated(context, 'Average')!),
              getText(getTranslated(context, 'Poor')!),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                getRatingIndicator(int.parse(star5), 5),
                getRatingIndicator(int.parse(star4), 4),
                getRatingIndicator(int.parse(star3), 3),
                getRatingIndicator(int.parse(star2), 2),
                getRatingIndicator(int.parse(star1), 1),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getTotalStarRating(star5),
              getTotalStarRating(star4),
              getTotalStarRating(star3),
              getTotalStarRating(star2),
              getTotalStarRating(star1),
            ],
          ),
        ),
      ],
    );
  }

  getRatingIndicator(var totalStar, int index) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 5.0,
        left: 0.5,
        top: 8,
        bottom: 8,
      ),
      child: Stack(
        children: [
          Container(
            height: 4,
            width: MediaQuery.of(context).size.width * 0.53,
            decoration: BoxDecoration(
              color: const Color(0xfff0f0f0),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(3.0),
              border: Border.all(width: 0.5, color: const Color(0xfff0f0f0)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
              color: index == 5
                  ? const Color(0xff048d63)
                  : index == 4
                      ? const Color(0xff048d63)
                      : index == 3
                          ? const Color(0xff24ba75)
                          : index == 2
                              ? const Color(0xffed7114)
                              : const Color(0xfff0f0f0),
            ),
            width: (totalStar / reviewList.length) *
                MediaQuery.of(context).size.width *
                0.33,
            height: 4,
          ),
        ],
      ),
    );
  }

  getText(String text) {
    return // Excellent
        Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 5.0,
        vertical: 3.5,
      ),
      child: Text(
        text,
        style: TextStyle(
            color: Theme.of(context).colorScheme.black,
            fontWeight: FontWeight.w400,
            fontFamily: 'Ubuntu',
            fontStyle: FontStyle.normal,
            fontSize: 10.0),
        textAlign: TextAlign.left,
      ),
    );
  }

  getRatingBarIndicator(var ratingStar, var totalStars) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: RatingBarIndicator(
        textDirection: TextDirection.rtl,
        rating: ratingStar,
        itemBuilder: (context, index) => const Icon(
          Icons.star_rate_rounded,
          color: colors.yellow,
        ),
        itemCount: totalStars,
        itemSize: 20.0,
        direction: Axis.horizontal,
        unratedColor: Colors.transparent,
      ),
    );
  }

  getTotalStarRating(var totalStar) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Text(
        totalStar,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xffa0a1a0),
        ),
      ),
    );
  }
}

class AnimatedProgressBar extends AnimatedWidget {
  final Animation<double> animation;

  const AnimatedProgressBar({Key? key, required this.animation})
      : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5.0,
      width: animation.value,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.black,
      ),
    );
  }
}

// ignore_for_file: must_be_immutable

class StarRatingProductDetailPage extends StatelessWidget {
  String totalRating, noOfRatings;
  bool needToShowNoOfRatings;

  StarRatingProductDetailPage(
      {Key? key,
      required this.totalRating,
      required this.noOfRatings,
      required this.needToShowNoOfRatings})
      : super(key: key);

  getSVGImage(String svg) {
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: SvgPicture.asset(
        svg,
        height: 14,
        width: 14,
      ),
    );
  }

  getHalfStar(String value) {
    return value == '1' || value == '2' || value == '3'
        ? getSVGImage('assets/images/RattingIcons/d_star.svg')
        : value == '4' || value == '5' || value == '6'
            ? getSVGImage('assets/images/RattingIcons/c_star.svg')
            : value == '7' || value == '8' || value == '9'
                ? getSVGImage('assets/images/RattingIcons/b_star.svg')
                : getSVGImage('assets/images/RattingIcons/e_star.svg');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < 5; i++)
          totalRating[0] == '0'
              ? getHalfStar('emptystar')
              : totalRating[0] == '1'
                  ? i == 0
                      ? getSVGImage('assets/images/RattingIcons/a_star.svg')
                      : i == 1
                          ? getHalfStar(totalRating[2])
                          : getHalfStar('emptystar')
                  : totalRating[0] == '2'
                      ? i < 2
                          ? getSVGImage('assets/images/RattingIcons/a_star.svg')
                          : i == 2
                              ? getHalfStar(totalRating[2])
                              : getHalfStar('emptystar')
                      : totalRating[0] == '3'
                          ? i < 3
                              ? getSVGImage(
                                  'assets/images/RattingIcons/a_star.svg')
                              : i == 3
                                  ? getHalfStar(totalRating[2])
                                  : getHalfStar('emptystar')
                          : totalRating[0] == '4'
                              ? i < 4
                                  ? getSVGImage(
                                      'assets/images/RattingIcons/a_star.svg')
                                  : i == 4
                                      ? getHalfStar(totalRating[2])
                                      : getHalfStar('emptystar')
                              : totalRating[0] == '5'
                                  ? getSVGImage(
                                      'assets/images/RattingIcons/a_star.svg')
                                  : Container(),
        const SizedBox(
          width: 5.0,
        ),
        Flexible(
          child: Text(
            '$totalRating/5',
            style: TextStyle(
              color: Theme.of(context).colorScheme.black,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.normal,
              fontSize: 14.0,
            ),
          ),
        ),
        needToShowNoOfRatings
            ? const SizedBox(
                width: 10.0,
              )
            : Container(),
        needToShowNoOfRatings
            ? Flexible(
                child: Text(
                  '($noOfRatings  ${getTranslated(context, 'Rattings')!} )',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.lightBlack,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.normal,
                    fontSize: 14.0,
                  ),
                ),
              )
            : Container(),
      ],
    );
  }
}
