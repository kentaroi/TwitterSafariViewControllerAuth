//
//  TwitterSafariViewControllerAuth.h
//
//  Created by Daniel Khamsing on 2/29/16.
//  Copyright © 2016 Daniel Khamsing. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIViewController;

/* Twitter Safari View Controller Auth. */
@interface TwitterSafariViewControllerAuth : NSObject

/**
 Shared instance of Twitter Safari View Controller 🐦.
 @return Shared instance.
 */
+ (instancetype)sharedInstance;

/**
 Configure Twitter Safari View Controller.
 @param consumerKey Twitter app consumer key.
 @param consumerSecret Twitter app consumer secret.
 @param urlScheme iOS app url scheme (redirect / OAuth callback).
 */
- (void)configureConsumerKey:(NSString *)clientId consumerSecret:(NSString *)consumerSecret urlScheme:(NSString *)urlScheme;

/**
 Configure Twitter Safari View Controller with the (first) URL scheme from the app bundle plist.
 @param consumerKey Twitter app consumer key.
 @param consumerSecret Twitter app consumer secret.
 */
- (void)configureConsumerKey:(NSString *)clientId consumerSecret:(NSString *)consumerSecret;

/**
 App delegate helper to get access token for - application:openURL:options:.
 @param url Open url.
 @param options Open url options.
 @param success Success completion block that takes a results parameter (OAuth token, OAuth token secret, Twitter screen name, etc..)
 @param failure Failure block.
 */
- (void)handleOpenUrl:(NSURL *)url options:(NSDictionary *)options success:(void (^)(NSDictionary *results))success failure:(void (^)(NSError *error))failure;

/**
 Present Twitter OAuth login controller (Safari View Controller).
 @param controller Controller to present Twitter OAuth login controller from.
 */
- (void)presentOAuthLoginFromController:(UIViewController *)controller;

@end
