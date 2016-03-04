//
//  UnitTests.m
//  UnitTests
//
//  Created by Daniel Khamsing on 3/1/16.
//  Copyright © 2016 Daniel Khamsing. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TwitterSafariViewControllerAuth.h"

static NSString *const kConsumerKey    = @"pxVUnHa52dzSXmkgZZ9kjPCfL";
static NSString *const kConsumerSecret = @"nhOETEJHhtyhIV0mRQ9qs5esZIBceoAOp1K3kbaqCJecCHfp8v";
static NSString *const kUrlScheme      = @"TwitterAuthDemo://";

@interface NSString (Testing)

- (NSString *)URLEncodedString_ch;

@end

@interface TwitterSafariViewControllerAuth (Testing)

@property (nonatomic, strong) NSString *consumerSecret;

@property (nonatomic, strong) NSString *consumerKey;

@property (nonatomic, strong) NSString *redirectUri;

- (NSString *)createOAuthHeaderWithToken:(NSString *)tokenString tokenSecret:(NSString *)tokenSecretString verifier:(NSString *)verifierString urlString:(NSString *)urlString consumerKey:(NSString *)consumerKey nonce:(NSString *)nonce timestamp:(NSString *)timestamp;

- (void)getAuthUrlWithCompletion:(void (^)(NSURL *))completion;

- (NSString *)UUID;

@end

@interface UnitTests : XCTestCase

@end

@implementation UnitTests

- (void)setUp {
    [super setUp];
    
    [[TwitterSafariViewControllerAuth sharedInstance] configureConsumerKey:kConsumerKey consumerSecret:kConsumerSecret urlScheme:kUrlScheme];
}

- (void)testConfigure {
    XCTAssertEqual([TwitterSafariViewControllerAuth sharedInstance].consumerKey, kConsumerKey);
    XCTAssertEqual([TwitterSafariViewControllerAuth sharedInstance].consumerSecret, kConsumerSecret);
    XCTAssertEqual([TwitterSafariViewControllerAuth sharedInstance].redirectUri, kUrlScheme);
}

- (void)testGetAuthUrl {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Auth URL"];

    [[TwitterSafariViewControllerAuth sharedInstance] getAuthUrlWithCompletion:^(NSURL *authUrl) {
        XCTAssertNotNil(authUrl);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        if (error != nil) {
            NSLog(@"Error: %@", error.localizedDescription);
        }
    }];
}

- (void)testHandleOpenUrlDeny {
    NSString *urlString = @"twitterauthdemo://?denied=HupSXgAAAAAAt5yJAAABUzgfLc0";
    NSURL *url = [NSURL URLWithString:urlString];
    [[TwitterSafariViewControllerAuth sharedInstance] handleOpenUrl:url options:nil success:nil failure:^(NSError *error) {
        XCTAssertNotNil(error);
    }];
}

- (void)testUrlEncodedString {
    [self helperForUrlEncodedString:@"https://api.twitter.com/oauth/request_token" expect:@"https%3A%2F%2Fapi.twitter.com%2Foauth%2Frequest_token"];
    [self helperForUrlEncodedString:@"oauth_callback" expect:@"oauth_callback"];
    [self helperForUrlEncodedString:@"TwitterAuthDemo://" expect:@"TwitterAuthDemo%3A%2F%2F"];
    [self helperForUrlEncodedString:@"oauth_signature_method" expect:@"oauth_signature_method"];
    [self helperForUrlEncodedString:@"HMAC-SHA1" expect:@"HMAC-SHA1"];
    [self helperForUrlEncodedString:@"oauth_nonce" expect:@"oauth_nonce"];
    [self helperForUrlEncodedString:@"943FB130-BBCB-4CE7-8072-F2234AC0C5E6" expect:@"943FB130-BBCB-4CE7-8072-F2234AC0C5E6"];
    [self helperForUrlEncodedString:@"oauth_consumer_key" expect:@"oauth_consumer_key"];
    [self helperForUrlEncodedString:@"pxVUnHa52dzSXmkgZZ9kjPCfL" expect:@"pxVUnHa52dzSXmkgZZ9kjPCfL"];
    [self helperForUrlEncodedString:@"oauth_timestamp" expect:@"oauth_timestamp"];
    [self helperForUrlEncodedString:@"1456936623" expect:@"1456936623"];
    [self helperForUrlEncodedString:@"oauth_version" expect:@"oauth_version"];
    [self helperForUrlEncodedString:@"1.0" expect:@"1.0"];
    [self helperForUrlEncodedString:@"oauth_callback=TwitterAuthDemo%3A%2F%2F&oauth_consumer_key=pxVUnHa52dzSXmkgZZ9kjPCfL&oauth_nonce=943FB130-BBCB-4CE7-8072-F2234AC0C5E6&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1456936623&oauth_version=1.0" expect:@"oauth_callback%3DTwitterAuthDemo%253A%252F%252F%26oauth_consumer_key%3DpxVUnHa52dzSXmkgZZ9kjPCfL%26oauth_nonce%3D943FB130-BBCB-4CE7-8072-F2234AC0C5E6%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1456936623%26oauth_version%3D1.0"];
    [self helperForUrlEncodedString:@"nhOETEJHhtyhIV0mRQ9qs5esZIBceoAOp1K3kbaqCJecCHfp8v" expect:@"nhOETEJHhtyhIV0mRQ9qs5esZIBceoAOp1K3kbaqCJecCHfp8v"];
    [self helperForUrlEncodedString:@"6rqypovjfJm9iDdQLphF4q7qLbc=" expect:@"6rqypovjfJm9iDdQLphF4q7qLbc%3D"];
}

- (void)helperForUrlEncodedString:(NSString *)string expect:(NSString *)expect {
NSString *value = string.URLEncodedString_ch;
    XCTAssertEqualObjects(value, expect);
}

- (void)testUuid {
    NSString *first = [TwitterSafariViewControllerAuth sharedInstance].UUID;
    NSString *second = [TwitterSafariViewControllerAuth sharedInstance].UUID;
    XCTAssertNotEqualObjects(first, second);
}

- (void)testCreateOAuthHeader {
    NSString *urlString = @"https://api.twitter.com/oauth/request_token";
    NSString *nonce = @"F465B10F-F3AE-4DCB-8612-3F97B792255E";
    NSString *timestamp = @"1456944863";
    NSString *header = [[TwitterSafariViewControllerAuth sharedInstance] createOAuthHeaderWithToken:nil tokenSecret:nil verifier:nil urlString:urlString consumerKey:kConsumerKey nonce:nonce timestamp:timestamp];
    
    NSString *expect = @"OAuth oauth_consumer_key=\"pxVUnHa52dzSXmkgZZ9kjPCfL\", oauth_callback=\"TwitterAuthDemo%3A%2F%2F\", oauth_signature_method=\"HMAC-SHA1\", oauth_signature=\"eZR5mRysjftRcozmKHHQY3FHzWQ%3D\", oauth_timestamp=\"1456944863\", oauth_nonce=\"F465B10F-F3AE-4DCB-8612-3F97B792255E\", oauth_version=\"1.0\"";

    XCTAssertEqualObjects(header, expect);
}

@end
