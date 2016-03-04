//
//  TwitterSafariViewControllerAuth.m
//
//  Created by Daniel Khamsing on 2/29/16.
//  Copyright © 2016 Daniel Khamsing. All rights reserved.
//

#import "TwitterSafariViewControllerAuth.h"
@import SafariServices;

static NSString * const api_url_oauth_access_token  = @"https://api.twitter.com/oauth/access_token";
static NSString * const api_url_oauth_request_token = @"https://api.twitter.com/oauth/request_token";
static NSString * const api_url_oauth_authenticate  = @"https://api.twitter.com/oauth/authenticate";

static NSString * const tsvca_POST  = @"POST";

// HMAC (sign request)
#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

@interface NSString (encode)

/**
 URL encode string by Dave DeLong http://stackoverflow.com/questions/3423545/objective-c-iphone-percent-encode-a-string/3426140#3426140
 @return URL encoded string.
 */
- (NSString *)URLEncodedString_ch;

@end

@implementation NSString (encode)

- (NSString *) URLEncodedString_ch {
    NSMutableString * output = [NSMutableString string];
    const unsigned char * source = (const unsigned char *)[self UTF8String];
    int sourceLen = (CC_LONG)(strlen((const char *)source));
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

@end

@interface TwitterSafariViewControllerAuth ()

@property (nonatomic, strong) NSString *consumerSecret;

@property (nonatomic, strong) NSString *consumerKey;

@property (nonatomic, strong) NSString *redirectUri;

@property (nonatomic, strong) SFSafariViewController *safariViewController;

@end

@implementation TwitterSafariViewControllerAuth

+ (instancetype)sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (void)configureConsumerKey:(NSString *)clientId consumerSecret:(NSString *)consumerSecret urlScheme:(NSString *)urlScheme;
{
    self.consumerKey = clientId;
    self.consumerSecret = consumerSecret;
    self.redirectUri = urlScheme;
}

- (void)configureConsumerKey:(NSString *)clientId consumerSecret:(NSString *)consumerSecret;
{
    NSArray *list = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    NSDictionary *item = list.firstObject;
    
    NSArray *schemes = item[@"CFBundleURLSchemes"];
    NSString *scheme = schemes.firstObject;
    NSString *urlScheme = [NSString stringWithFormat:@"%@://", scheme];
    
    [self configureConsumerKey:clientId consumerSecret:consumerSecret urlScheme:urlScheme];
}

- (void)handleOpenUrl:(NSURL *)url options:(NSDictionary *)options success:(void (^)(NSDictionary *))success failure:(void (^)(NSError *))failure;
{
    [self.safariViewController dismissViewControllerAnimated:YES completion:^{
        if ([url.absoluteString containsString:@"denied"]) {
            if (failure) {
                failure([NSError errorWithDomain:@"User denied authentication" code:800 userInfo:nil]);
            }
            return;
        }
        
        [self getAccessTokenWithUrl:url success:^(NSData *oauthAccessTokenData) {
            NSString *data_string = [[NSString alloc] initWithData:oauthAccessTokenData encoding:NSUTF8StringEncoding];
            
            NSMutableDictionary *results = [self parseUrlQueryString:data_string].mutableCopy;
            results[@"data"] = oauthAccessTokenData;
            results[@"data_string"] = data_string;
            
            if (success) {
                success(results);
            }
        }];
    }];
}

- (void)getAuthUrlWithCompletion:(void (^)(NSURL *))completion;
{
    [self postUrlString:api_url_oauth_request_token token:nil secret:nil verifier:nil completion:^(NSData *data) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *key = @"oauth_token";
        NSDictionary *parameters = [self parseUrlQueryString:string];
        NSString *token = parameters[key];
        NSString *urlString = [NSString stringWithFormat:@"%@?%@=%@", api_url_oauth_authenticate, key, token];
        NSURL *url = [NSURL URLWithString:urlString];
        
        if (completion) {
            completion(url);
        }
    }];
}

- (void)presentOAuthLoginFromController:(UIViewController *)controller;
{
    [self getAuthUrlWithCompletion:^(NSURL *url) {
        self.safariViewController = [[SFSafariViewController alloc] initWithURL:url entersReaderIfAvailable:NO];
        [controller presentViewController:self.safariViewController animated:YES completion:nil];
    }];
}

#pragma mark - Private

- (void)getAccessTokenWithUrl:(NSURL *)url success:(void (^)(NSData *oauthAccessTokenData))success;
{
    NSString *urlString = url.absoluteString;
    NSRange range = [urlString rangeOfString:@"?"];
    NSString *filtered = [urlString substringFromIndex:range.location + 1];
    NSDictionary *parameters = [self parseUrlQueryString:filtered];
    NSString *token = parameters[@"oauth_token"];
    NSString *verifier = parameters[@"oauth_verifier"];
    
    [self postUrlString:api_url_oauth_access_token token:token secret:nil verifier:verifier completion:success];
}

- (NSDictionary *)parseUrlQueryString:(NSString *)query
{
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    NSArray *list = [query componentsSeparatedByString:@"&"];
    
    [list enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *item = [obj componentsSeparatedByString:@"="];
        NSString *key = item[0];
        NSString *value = item[1];
        if (key && value) {
            results[key] = value;
        }
    }];
    
    return results;
}

- (void)postUrlString:(NSString *)urlString token:(NSString *)token
               secret:(NSString *)secret
             verifier:(NSString *)verifier
           completion:(void (^)(NSData *))completion;
{
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    request.HTTPShouldHandleCookies = NO;
    request.HTTPMethod = tsvca_POST;
    
    NSString *oauthHeader = [self createOAuthHeaderWithToken:token tokenSecret:nil verifier:verifier urlString:request.URL.absoluteString consumerKey:self.consumerKey nonce:self.UUID timestamp:[NSString stringWithFormat:@"%ld",time(nil)]];
    [request setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger status = httpResponse.statusCode;
        if (status == 200) {
            if (completion) {
                completion(data);
            }
        }
        else {
            NSError *jsonError;
            id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            NSLog(@"post url string json error = %@", json);
        }
    }];
    [task resume];
}

#pragma mark Based on https://github.com/fhsjaagshs/FHSTwitterEngine

- (NSString *)UUID {
    return [NSUUID UUID].UUIDString;
}

- (NSString *)createOAuthHeaderWithToken:(NSString *)tokenString tokenSecret:(NSString *)tokenSecretString verifier:(NSString *)verifierString urlString:(NSString *)urlString consumerKey:(NSString *)consumerKey nonce:(NSString *)nonce timestamp:(NSString *)timestamp
{
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    
    mutableParams[@"oauth_consumer_key"] = consumerKey;
    mutableParams[@"oauth_signature_method"] = @"HMAC-SHA1";
    mutableParams[@"oauth_timestamp"] = timestamp;
    mutableParams[@"oauth_nonce"] = nonce;
    mutableParams[@"oauth_version"] = @"1.0";
    
    if (tokenString) {
        mutableParams[@"oauth_token"] = tokenSecretString.URLEncodedString_ch;
        
        if (verifierString) {
            mutableParams[@"oauth_verifier"] = verifierString.URLEncodedString_ch;
        }
    } else {
        mutableParams[@"oauth_callback"] = self.redirectUri;
    }
    
    NSMutableArray *paramPairs = [NSMutableArray arrayWithCapacity:mutableParams.count];
    
    for (NSString *key in mutableParams.allKeys) {
        NSString *value = mutableParams[key];
        [paramPairs addObject:[NSString stringWithFormat:@"%@=%@", key.URLEncodedString_ch, value.URLEncodedString_ch]];
    }
    
    [paramPairs sortUsingSelector:@selector(compare:)];
    
    NSString *normalizedRequestParameters = [paramPairs componentsJoinedByString:@"&"].URLEncodedString_ch;
    
    // Sign request elements using HMAC-SHA1
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",
                                     tsvca_POST,
                                     urlString.URLEncodedString_ch,
                                     normalizedRequestParameters];
    
    NSString *key = [NSString stringWithFormat:@"%@&%@",
                     self.consumerSecret.URLEncodedString_ch,
                     tokenSecretString.URLEncodedString_ch?:@""];
    NSData *secretData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [signatureBaseString dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, secretData.bytes, secretData.length, clearTextData.bytes, clearTextData.length, result);
    NSData *theData = [[NSData dataWithBytes:result length:CC_SHA1_DIGEST_LENGTH] base64EncodedDataWithOptions:0];
    
    NSString *signature = [[NSString alloc]initWithData:theData encoding:NSUTF8StringEncoding].URLEncodedString_ch;
    
    NSString *oauth_callback = [NSString stringWithFormat:@"oauth_callback=\"%@\", ", self.redirectUri.URLEncodedString_ch];
    NSString *oauthToken = (tokenString.length > 0)?[NSString stringWithFormat:@"oauth_token=\"%@\", ",tokenString.URLEncodedString_ch]:oauth_callback;
    NSString *oauthVerifier = (verifierString.length > 0)?[NSString stringWithFormat:@"oauth_verifier=\"%@\", ",verifierString]:@"";
    
    NSString *oauthHeader = [NSString stringWithFormat:@"OAuth oauth_consumer_key=\"%@\", %@%@oauth_signature_method=\"HMAC-SHA1\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"1.0\"",consumerKey,oauthToken,oauthVerifier,signature,timestamp,nonce];
    
    return oauthHeader;
}

@end
