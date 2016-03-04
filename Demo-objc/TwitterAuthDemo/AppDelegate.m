//
//  AppDelegate.m
//  TwitterAuthDemo
//
//  Created by Daniel Khamsing on 3/1/16.
//  Copyright © 2016 Daniel Khamsing. All rights reserved.
//

#import "AppDelegate.h"

#import "TwitterSafariViewControllerAuth.h"
#import "ViewController.h"

@interface AppDelegate ()

@property (nonatomic, strong) ViewController *viewController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    self.viewController = [storyboard instantiateInitialViewController];
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    [[TwitterSafariViewControllerAuth sharedInstance] handleOpenUrl:url options:options success:^(NSDictionary *results) {
        NSLog(@"Results: %@", results);
        
        [self.viewController.startButton setTitle:@"🐦 Logged In" forState:UIControlStateNormal];
        [self.viewController.startButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        
        NSString *title = @"🐦🎉";
        NSString *message = ({
            __block NSString *temp = @"";
            [results enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                temp = [temp stringByAppendingString: [NSString stringWithFormat:@"%@:\n%@ \n\n", key, obj] ];
            }];
            temp;
        });
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        {
            NSString *title = @"OK";
            UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleCancel handler:nil];
            [alertController addAction:action];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        });
    } failure:^(NSError *error) {
        NSLog(@"Error: %@", error);
        
        [self.viewController.startButton setTitle:@"There was an error 😢" forState:UIControlStateNormal];
        self.viewController.startButton.userInteractionEnabled = YES;
    }];
    
    return NO;
}

@end
