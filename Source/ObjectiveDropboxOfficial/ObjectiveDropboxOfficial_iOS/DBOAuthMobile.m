///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import "DBOAuth.h"
#import "DBOAuthMobile.h"

#pragma mark - Shared application

@interface DBMobileSharedApplication ()

@property (nonatomic, readonly) UIApplication * _Nullable sharedApplication;
@property (nonatomic, readonly) UIViewController * _Nullable controller;
@property (nonatomic, readonly, nullable) void (^openURL)(NSURL * _Nullable);
@property (nonatomic, readonly, nullable) void (^presentationHandler)(UIViewController * _Nonnull);
@property (nonatomic, readonly, nullable) void (^dismissalHandler)(BOOL, UIViewController * _Nonnull);

@end

@implementation DBMobileSharedApplication

- (instancetype)init:(UIApplication *)sharedApplication
          controller:(UIViewController *)controller
             openURL:(void (^)(NSURL *))openURL {
  return [self init:sharedApplication controller:controller openURL:openURL presentationHandler:nil dismissalHandler:nil];
}

- (instancetype)init:(UIApplication *)sharedApplication
					controller:(UIViewController *)controller
						 openURL:(void (^)(NSURL *))openURL
 presentationHandler:(void (^_Nullable)(UIViewController * _Nonnull))presentationHandler
		dismissalHandler:(void(^_Nullable)(BOOL, UIViewController * _Nonnull))dismissalHandler {
	self = [super init];
	if (self) {
		// fields saved for app-extension safety
		_sharedApplication = sharedApplication;
		_controller = controller;
		_openURL = openURL;
		_presentationHandler = presentationHandler;
		_dismissalHandler = dismissalHandler;
	}
	return self;
}

- (void)presentErrorMessage:(NSString *)message title:(NSString *)title {
  UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:(UIAlertControllerStyle)UIAlertControllerStyleAlert];
  [_controller presentViewController:alertController
                            animated:YES
                          completion:^{
                            [NSException raise:@"FatalError" format:@"%@", message];
                          }];
}

- (void)presentErrorMessageWithHandlers:(NSString * _Nonnull)message
                                  title:(NSString * _Nonnull)title
                         buttonHandlers:(NSDictionary<NSString *, void (^)()> * _Nonnull)buttonHandlers {
  UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:title
                                          message:message
                                   preferredStyle:(UIAlertControllerStyle)UIAlertControllerStyleAlert];

  [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                      style:(UIAlertActionStyle)UIAlertActionStyleCancel
                                                    handler:nil]];
  [alertController addAction:[UIAlertAction actionWithTitle:@"Retry"
                                                      style:(UIAlertActionStyle)UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
#pragma unused(action)
                                                      buttonHandlers[@"Retry"]();
                                                    }]];

  [_controller presentViewController:alertController
                            animated:YES
                          completion:^{
                          }];
}

- (BOOL)presentPlatformSpecificAuth:(NSURL * _Nonnull)authURL {
  [self presentExternalApp:authURL];
  return YES;
}

- (void)presentWebViewAuth:(NSURL * _Nonnull)authURL
			 tryInterceptHandler:(BOOL (^_Nonnull)(NSURL * _Nonnull))tryInterceptHandler
						 cancelHandler:(void (^_Nonnull)(void))cancelHandler {
	DBMobileWebViewController *webViewController = [[DBMobileWebViewController alloc] init:authURL
																																		 tryInterceptHandler:tryInterceptHandler
																																					 cancelHandler:cancelHandler
																																				dismissalHandler:_dismissalHandler];
	
	if (_presentationHandler) {
		_presentationHandler(webViewController);
	} else {
  UINavigationController *navigationController =
		[[UINavigationController alloc] initWithRootViewController:webViewController];
		
  [_controller presentViewController:navigationController animated:YES completion:nil];
	}
}
- (void)presentBrowserAuth:(NSURL * _Nonnull)authURL {
  [self presentExternalApp:authURL];
}

- (void)presentExternalApp:(NSURL * _Nonnull)url {
  _openURL(url);
}

- (BOOL)canPresentExternalApp:(NSURL * _Nonnull)url {
  return [_sharedApplication canOpenURL:url];
}

@end

#pragma mark - Web view controller

@interface DBMobileWebViewController ()

@property (nonatomic, readonly) WKWebView * _Nullable webView;
@property (nonatomic, readonly, nullable) void (^onWillDismiss)(BOOL);
@property (nonatomic, readonly, nullable) BOOL (^tryInterceptHandler)(NSURL * _Nullable);
@property (nonatomic, readonly, nullable) void (^dismissalHandler)(BOOL, UIViewController * _Nonnull);
@property (nonatomic, readonly) UIBarButtonItem * _Nullable cancelButton;
@property (nonatomic, readonly, nullable) void (^cancelHandler)(void);
@property (nonatomic, readonly) UIActivityIndicatorView * _Nullable indicator;
@property (nonatomic, readonly, copy) NSURL * _Nullable startURL;

@end

@implementation DBMobileWebViewController

- (instancetype)init {
  return [super initWithNibName:nil bundle:nil];
}

- (instancetype)init:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (instancetype)init:(NSURL *)URL
 tryInterceptHandler:(BOOL (^)(NSURL *))tryInterceptHandler
			 cancelHandler:(void (^)(void))cancelHandler {
	return [self init:URL tryInterceptHandler:tryInterceptHandler cancelHandler:cancelHandler];
}

- (instancetype)init:(NSURL *)URL
 tryInterceptHandler:(BOOL (^)(NSURL *))tryInterceptHandler
			 cancelHandler:(void (^)(void))cancelHandler
		dismissalHandler:(void(^_Nullable)(BOOL, UIViewController * _Nonnull))dismissalHandler {
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		_tryInterceptHandler = tryInterceptHandler;
		_cancelHandler = cancelHandler;
		_dismissalHandler = dismissalHandler;
		_indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		_startURL = URL;

    self.title = @"Link to Dropbox";
  }
	return self;
}
- (void)viewDidLoad {
  [super viewDidLoad];
  _webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
  _webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);

  _indicator.center = self.view.center;
  _indicator.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin);
  [_webView addSubview:_indicator];
  [_indicator startAnimating];

  [self.view addSubview:_webView];

  _webView.navigationDelegate = self;

  self.view.backgroundColor = [UIColor whiteColor];

  _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                target:self
                                                                action:@selector(cancel:)];
  self.navigationItem.rightBarButtonItem = _cancelButton;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  // For smaller views, use iPhone user agent to ensure mobile login page is used
  if (CGRectGetWidth(self.view.bounds) < 600 && UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
    _webView.customUserAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0 like Mac OS X) AppleWebKit/602.1.38 (KHTML, like Gecko) Version/10.0 Mobile/14A300 Safari/602.1";
  }
  
  if (![_webView canGoBack]) {
    if (_startURL != nil) {
      [self loadURL:_startURL];
    } else {
      [_webView loadHTMLString:@"There is no `startURL`" baseURL:nil];
    }
  }
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
#pragma unused(webView)
  if (navigationAction.request.URL && _tryInterceptHandler) {
    if (_tryInterceptHandler(navigationAction.request.URL)) {
      [self dismiss:YES];
      return decisionHandler(WKNavigationActionPolicyCancel);
    }
  }
  return decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
#pragma unused(webView)
#pragma unused(navigation)
  [_indicator stopAnimating];
  [_indicator removeFromSuperview];
}

- (void)loadURL:(NSURL *)url {
  [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)showHideBackButton:(BOOL)show {
  if (show) {
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                                                      target:self
                                                      action:@selector(goBack:)];
  } else {
    self.navigationItem.leftBarButtonItem = nil;
  }
}

- (void)goBack:(id)sender {
#pragma unused(sender)
  [_webView goBack];
}

- (void)cancel:(id)sender {
  [self dismiss:YES animated:(sender != nil)];
  _cancelHandler();
}

- (void)dismiss:(BOOL)animated {
  [self dismiss:NO animated:animated];
}

- (void)dismiss:(BOOL)asCancel animated:(BOOL)animated {
  [_webView stopLoading];

  if (_onWillDismiss) {
    _onWillDismiss(asCancel);
  }
	if (self.dismissalHandler) {
		self.dismissalHandler(!asCancel, self);
	}
	else if (self.presentingViewController) {
		[self.presentingViewController dismissViewControllerAnimated:animated completion:nil];
	}
}

@end
