///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#import "DBOAuth.h"
#import "DBSharedApplicationProtocol.h"

#pragma mark - Shared application

///
/// Platform-specific (here, iOS) shared application.
///
/// Renders OAuth flow and implements `DBSharedApplication` protocol.
///
@interface DBMobileSharedApplication : NSObject <DBSharedApplication>

///
/// Convenience constructor.
///
/// @param sharedApplication The `UIApplication` with which to render the
/// OAuth flow.
/// @param controller The `UIViewController` with which to render the OAuth
/// flow.
/// @param openURL A wrapper around app-extension unsafe `openURL` call.
///
/// @return An initialized instance.
///
- (nonnull instancetype)init:(UIApplication * _Nonnull)sharedApplication
                  controller:(UIViewController * _Nonnull)controller
                     openURL:(void (^_Nonnull)(NSURL * _Nonnull))openURL;

///
/// Full constructor.
///
/// @param sharedApplication The `UIApplication` with which to render the
/// OAuth flow.
/// @param controller The `UIViewController` with which to render the OAuth
/// flow.
/// @param openURL A wrapper around app-extension unsafe `openURL` call.
/// @param presentationHandler Block to set up the passed view controller
/// for presentation.
/// @param dismissalHandler Block to handle dissmissal of the passed view
/// controller.
///
/// @return An initialized instance.
///
- (nonnull instancetype)init:(UIApplication * _Nonnull)sharedApplication
				  controller:(UIViewController * _Nonnull)controller
					 openURL:(void (^_Nonnull)(NSURL * _Nonnull))openURL
		 presentationHandler:(void (^_Nullable)(UIViewController * _Nonnull))presentationHandler
			dismissalHandler:(void (^_Nullable)(BOOL, UIViewController * _Nonnull))dismissalHandler;

@end

#pragma mark - Web view controller

///
/// Platform-specific (here, iOS) `UIViewController` for rendering OAuth flow.
///
@interface DBMobileWebViewController : UIViewController <WKNavigationDelegate>

///
/// Convenience constructor.
///
/// @param tryInterceptHandler The navigation handler for the view controller.
/// Will check if exit URL (for redirect back to main app) can be successfully
/// navigated to.
/// @param cancelHandler Handler for auth cancellation. Will redirect back to
/// main app with special cancel url, so that cancellation can be detected.
/// flow.
///
/// @return An initialized instance.
///
- (nonnull instancetype)init:(NSURL * _Nonnull)url
         tryInterceptHandler:(BOOL (^_Nonnull)(NSURL * _Nonnull))tryInterceptHandler
               cancelHandler:(void (^_Nonnull)(void))cancelHandler;

///
/// Full constructor.
///
/// @param tryInterceptHandler The navigation handler for the view controller.
/// Will check if exit URL (for redirect back to main app) can be successfully
/// navigated to.
/// @param cancelHandler Handler for auth cancellation. Will redirect back to
/// main app with special cancel url, so that cancellation can be detected.
/// flow.
/// @param dismissalHandler Block to handle dissmissal of the passed view
/// controller.
///
/// @return An initialized instance.
///
- (nonnull instancetype)init:(NSURL * _Nonnull)url
		 tryInterceptHandler:(BOOL (^_Nonnull)(NSURL * _Nonnull))tryInterceptHandler
			   cancelHandler:(void (^_Nonnull)(void))cancelHandler
			dismissalHandler:(void (^_Nullable)(BOOL, UIViewController * _Nonnull))dismissalHandler;

@end
