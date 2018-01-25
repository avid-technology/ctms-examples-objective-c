//
//  SimpleSearchImpl.m
//  SimpleSearch
//
//  Created by Nico Ludwig on 2016-07-30
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import "SimpleSearchImpl.h"

#import "../../PlatformTools/PlatformTools.h"
#import "../../PlatformTools/OutputAcceptor.h"

@implementation SimpleSearchImpl

- (instancetype _Nonnull) initWithConfig:(NSDictionary* _Nonnull)config andPlatformTools:(PlatformTools* _Nonnull)platformTools  {
    if (self = [super init]) {
        _config = config;
        self.platformTools = platformTools;
    }
    return self;
}

- (void)simpleSearchWithSession:(NSURLSession* _Nonnull)session
                       andThen:(void (^ _Nullable)(NSURLSession* _Nonnull session, NSError* _Nullable error))done
                       orCatch:(void (^ _Nonnull)(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message))failed {
    NSString* const apiDomain = [_config valueForKey:@"apidomain"];
    NSString* const serviceType = [_config valueForKey:@"servicetype"];
    NSString* const version = [_config valueForKey:@"version"] ? [_config valueForKey:@"version"] : [PlatformTools defaultVersion];
    NSString* const realm = [_config valueForKey:@"realm"];
    NSString* const rawSearchExpression = [_config valueForKey:@"searchexpression"];

    NSMutableURLRequest* const request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/apis/%@;version=%@;realm=%@/searches", apiDomain, serviceType, version, realm]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[PlatformTools defaultRequestTimeoutInterval]];
    [request addValue:@"application/hal+json" forHTTPHeaderField:@"Accept"];
    NSURLSessionDataTask* const searchesTask
     = [session dataTaskWithRequest:request
              completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
                if (!error) {
                    if (200 == ((NSHTTPURLResponse*)response).statusCode) {
                        NSDictionary* const searchesResult = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                        id simpleSearchLinkObject = [searchesResult valueForKeyPath:@"_links.search:simple-search"];

                        // Is simple search supported?
                        if (simpleSearchLinkObject) {
                            /// Doing the simple search and write the results to stdout:
                            // Here, no URL-template library is used in favor to string surgery:
                            NSString* urlUntemplatedSearch = [simpleSearchLinkObject valueForKeyPath:@"href"];
                            urlUntemplatedSearch = [urlUntemplatedSearch substringWithRange:NSMakeRange(0, [urlUntemplatedSearch rangeOfString:@"=" options:NSBackwardsSearch].location + 1)];
                            NSString* const searchExpression = [rawSearchExpression stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                            NSURL* const simpleSearchFirstPageResultURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", urlUntemplatedSearch, searchExpression]];
                        
                            // Page through the result:
                            [self.platformTools pageThroughResultsWithSession:session
                                                                       andURL:simpleSearchFirstPageResultURL
                                                                      andThen:^(NSArray* _Nonnull pages) {
                                                                            NSMutableString* const text = [NSMutableString new];
                                                                            int pageNo = 0;
                                                                            int assetNo = 0;

                                                                            for (id page in pages) {
                                                                                NSArray* const foundAssets = [page valueForKeyPath:@"aa:asset"];
                                                                                if ([foundAssets count]) {
                                                                                    [text appendString:[NSString stringWithFormat:@"Page#: %d, search expression: '%@'\n", ++pageNo, rawSearchExpression]];
                                                                                    for (id item in foundAssets) {
                                                                                        NSString* const theId = [item valueForKeyPath:@"base.id"];
                                                                                        NSString* const name = [item valueForKeyPath:@"common.name"];
                                                                                                
                                                                                        [text appendString:[NSString stringWithFormat:@"\tAsset#: %d, id: %@, name: '%@'\n", ++assetNo, theId, name ? name : [NSString string]]];
                                                                                    }
                                                                                }
                                                                            }
                                                                            [self.platformTools.output writeToOutput:text];
                                                                            NSLog(@"\n%@", text);
                                                                            done(session, error);
                                                                        }
                                                                      orCatch:^(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message) {
                                                                            failed(session, error, message);
                                                                        }];
                        } else {
                            failed(session, error, @"Simple search not supported.");
                        }
                    } else {
                        failed(session, error, [NSString stringWithFormat:@"Request failed with code %ld", (long)((NSHTTPURLResponse*)response).statusCode]);
                    }
                } else {
                    failed(session, error, [NSString string]);
                }
            }];
    [searchesTask resume];
}

@end
