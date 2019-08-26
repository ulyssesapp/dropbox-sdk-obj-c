///
/// Copyright (c) 2016 Dropbox, Inc. All rights reserved.
///

#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>
#import <UIKit/UIKit.h>

#import "DBSharedApplicationProtocol.h"

#pragma mark - Shared application

NS_ASSUME_NONNULL_BEGIN

///
/// Platform-specific (here, iOS) shared application.
///
/// Renders OAuth flow and implements `DBSharedApplication` protocol.
///
@interface DBMobileSharedApplication : NSObject <DBSharedApplication>

///
/// Convenience constructor.
///
/// @param sharedApplication The `UIApplication` with which to render the OAuth flow.
/// @param controller The `UIViewController` with which to render the OAuth flow.
/// @param openURL A wrapper around app-extension unsafe `openURL` call.
///
/// @return An initialized instance.
///
- (instancetype)initWithSharedApplication:(UIApplication *)sharedApplication
							   controller:(UIViewController *)controller
								  openURL:(void (^_Nonnull)(NSURL *))openURL;

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
- (instancetype)initWithSharedApplication:(UIApplication *)sharedApplication
                               controller:(UIViewController *)controller
                                  openURL:(void (^_Nonnull)(NSURL *))openURL
					  presentationHandler:(void (^_Nullable)(UIViewController *))presentationHandler
						 dismissalHandler:(void (^_Nullable)(BOOL, UIViewController *))dismissalHandler
						   useBrowserAuth:(BOOL)useBrowserAuth;

+ (nullable DBMobileSharedApplication *)mobileSharedApplication;

+ (void)setMobileSharedApplication:(DBMobileSharedApplication *)mobileSharedApplication;

- (void)dismissAuthControllerWithSuccess:(BOOL)success;

@end

#pragma mark - Web view controller

///
/// Platform-specific (here, iOS) `UIViewController` for rendering OAuth flow.
///
@interface DBMobileSafariViewController : SFSafariViewController <SFSafariViewControllerDelegate>

- (instancetype)initWithUrl:(NSURL *)url cancelHandler:(DBOAuthCancelBlock)cancelHandler;

@end

NS_ASSUME_NONNULL_END
