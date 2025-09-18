import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const ElkApp());
}

class ElkApp extends StatelessWidget {
  const ElkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elk',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const ElkWebView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ElkWebView extends StatefulWidget {
  const ElkWebView({super.key});

  @override
  State<ElkWebView> createState() => _ElkWebViewState();
}

class _ElkWebViewState extends State<ElkWebView> {
  InAppWebViewController? webViewController;
  late PullToRefreshController pullToRefreshController;
  bool isLoading = true;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _initializePullToRefresh();
  }

  void _initializePullToRefresh() {
    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.blue,
        backgroundColor: Colors.white,
        distanceToTriggerSync: 100,
        slingshotDistance: 150,
      ),
      onRefresh: () async {
        if (webViewController != null) {
          await webViewController!.reload();
        }
      },
    );
  }

  Future<bool> _onWillPop() async {
    if (_canGoBack && webViewController != null) {
      await webViewController!.goBack();
      final canGoBack = await webViewController!.canGoBack();
      setState(() {
        _canGoBack = canGoBack;
      });
      return false;
    }

    return await _showExitDialog() ?? false;
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uygulamadan Çık'),
        content: const Text('Elk uygulamasından çıkmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Çık'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri('https://elk.zone')),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  allowsBackForwardNavigationGestures: true,
                  useShouldOverrideUrlLoading: false,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  useHybridComposition: true,
                  hardwareAcceleration: true,
                  supportZoom: false,
                  builtInZoomControls: false,
                  displayZoomControls: false,
                  horizontalScrollBarEnabled: false,
                  verticalScrollBarEnabled: false,
                  cacheEnabled: true,
                  databaseEnabled: true,
                ),
                pullToRefreshController: pullToRefreshController,
                onWebViewCreated: (controller) => webViewController = controller,
                onLoadStart: (controller, url) => setState(() => isLoading = true),
                onLoadStop: (controller, url) async {
                  setState(() => isLoading = false);
                  final canGoBack = await controller.canGoBack();
                  setState(() => _canGoBack = canGoBack);
                  pullToRefreshController.endRefreshing();
                },
                onReceivedError: (controller, request, error) {
                  debugPrint('WebView error: ${error.description}');
                  pullToRefreshController.endRefreshing();
                },
                onReceivedHttpError: (controller, request, errorResponse) {
                  debugPrint('HTTP error: ${errorResponse.statusCode}');
                  pullToRefreshController.endRefreshing();
                },
              ),
              if (isLoading)
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Colors.blue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
