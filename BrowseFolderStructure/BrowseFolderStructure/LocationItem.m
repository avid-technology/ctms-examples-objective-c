//
//  LocationItem.m
//  BrowseFolderStructure
//
//  Created by Nico Ludwig on 2016-08-02
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import "LocationItem.h"

#import <AppKit/AppKit.h>

#import "../../PlatformTools/PlatformTools.h"
#import "../../PlatformTools/OutputAcceptor.h"

@implementation LocationItem

static LocationItem* rootItem;
static BOOL readingRootError;

+ (void)resetRoot {
    rootItem = nil;
    readingRootError = NO;
}

+ (LocationItem*)rootItemForOutlineView:(NSOutlineView* _Nonnull)outlineView
                                    withSession:(NSURLSession* _Nonnull)session
                                      andConfig:(NSDictionary* _Nonnull)config
                               andPlatformTools:(PlatformTools* _Nonnull)platformTools {
    if (!rootItem && !readingRootError) {
        NSString* const apiDomain = [config valueForKey:@"apidomain"];
        NSString* const serviceType = [config valueForKey:@"servicetype"];
        NSString* const version = [config valueForKey:@"version"] ? [config valueForKey:@"version"] : [PlatformTools defaultVersion];
        NSString* const realm = [config valueForKey:@"realm"];


        NSMutableURLRequest* const request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/apis/%@;version=%@;realm=%@/locations", apiDomain, serviceType, version, realm]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[PlatformTools defaultRequestTimeoutInterval]];
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request addValue:@"application/hal+json" forHTTPHeaderField:@"Accept"];
        NSURLSessionDataTask* const locationsTask
         = [session dataTaskWithRequest:request
                  completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
                    if (!error) {
                        if (200 == ((NSHTTPURLResponse*)response).statusCode) {
                            NSDictionary* const locationsResult = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                            id rootItemLinkObject = [locationsResult valueForKeyPath:@"_links.loc:root-item"];

                            if (rootItemLinkObject) {
                                NSString* const urlRootItem = [rootItemLinkObject valueForKeyPath:@"href"];
                                rootItem = [[LocationItem alloc] initWithPath:urlRootItem asLeaf:NO andName:@"Root" forOutlineView:outlineView andSession:session andConfig:config andPlatformTools:platformTools];
                            } else {
                                [platformTools.output writeToOutput:@"No root item found."];
                                readingRootError = YES;
                            }
                        } else {
                            [platformTools.output writeToOutput:[NSString stringWithFormat:@"Request failed with code %ld", (long)((NSHTTPURLResponse*)response).statusCode]];
                            readingRootError = YES;
                        }
                    } else {
                        [platformTools.output writeToOutput:error.description];
                        readingRootError = YES;
                    }
                    [platformTools.output updateView];
                }];
        [locationsTask resume];
    }

    return rootItem;
}

+ (BOOL)isLeaf:(id _Nonnull)item {
    return nil == [item valueForKeyPath:@"_links.loc:collection"];
}

- (instancetype _Nonnull)initWithPath:(NSString* _Nonnull)path
                    asLeaf:(BOOL)isLeaf
                   andName:(NSString* _Nonnull)name
            forOutlineView:(NSOutlineView* _Nonnull)outlineView
                andSession:(NSURLSession* _Nonnull)session
                 andConfig:(NSDictionary* _Nonnull)config
          andPlatformTools:(PlatformTools* _Nonnull)platformTools {
    if (self = [super init]) {
        self.myPath = path;
        self.config = config;
        self.platformTools = platformTools;
        self.session = session;
        self.outlineView = outlineView;
        self.name = name;
        self.hasChildren = !isLeaf;
    }
    return self;
}

- (NSArray* _Nonnull)generateChildren {
    if (!children) {
        [self.platformTools.output startProgress];
        children = [[NSMutableArray alloc] init];
        NSMutableURLRequest* const request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.myPath] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[PlatformTools defaultRequestTimeoutInterval]];
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request addValue:@"application/hal+json" forHTTPHeaderField:@"Accept"];
        NSURLSessionDataTask* const readItemTask
         = [self.session dataTaskWithRequest:request
                           completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
                            if (!error) {
                                if (200 == ((NSHTTPURLResponse*)response).statusCode) {
                                    NSDictionary* const itemResult = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

                                    id embedded = [itemResult valueForKeyPath:@"_embedded"];
                                    id collection = embedded ? [embedded valueForKeyPath:@"loc:collection"] : nil;
                                    id embeddedItems = collection ? [collection valueForKeyPath:@"_embedded"] : nil;
                            
                                    if (embeddedItems) {
                                        id itemsObject = [embeddedItems valueForKeyPath:@"loc:item"];
                                        if (itemsObject) {
                                            if ([itemsObject count]) {
                                                for (id item in itemsObject) {
                                                    LocationItem* const nextItem = [[LocationItem alloc] initWithPath:[item valueForKeyPath:@"_links.self.href"] asLeaf:[LocationItem isLeaf:item] andName:[item valueForKeyPath:@"common.name"] forOutlineView:self.outlineView andSession:self.session andConfig:self.config andPlatformTools:self.platformTools];
                                                    [children addObject:nextItem];
                                                }
                                            } else {
                                                LocationItem* const nextItem = [[LocationItem alloc] initWithPath:[itemsObject valueForKeyPath:@"_links.self.href"] asLeaf:[LocationItem isLeaf:itemsObject] andName:[itemsObject valueForKeyPath:@"common.name"] forOutlineView:self.outlineView andSession:self.session andConfig:self.config andPlatformTools:self.platformTools];
                                                [children addObject:nextItem];
                                            }
                                        }
                                        
                                        // Get the items of the folder pagewise:
                                        id linkToNextPage = [collection valueForKeyPath:@"_links.next"];
                                        if (linkToNextPage) {
                                            [self.platformTools pageThroughResultsWithSession:self.session
                                                                                       andURL:[NSURL URLWithString:[linkToNextPage valueForKeyPath:@"href"]]
                                                                                      andThen:^(NSArray* _Nonnull pages) {
                                                                                            for (id page in pages) {
                                                                                                NSArray* const foundLocationItems = [page valueForKeyPath:@"loc:item"];
                                                                                                if ([foundLocationItems count]) {
                                                                                                    for (id locationItem in foundLocationItems) {
                                                                                                        LocationItem* const nextItem = [[LocationItem alloc] initWithPath:[locationItem valueForKeyPath:@"_links.self.href"] asLeaf:[LocationItem isLeaf:locationItem] andName:[locationItem valueForKeyPath:@"common.name"] forOutlineView:self.outlineView andSession:self.session andConfig:self.config andPlatformTools:self.platformTools];
                                                                                                        [children addObject:nextItem];
                                                                                                    }
                                                                                                }
                                                                                            }
                                                                                            [self.platformTools.output updateView];
                                                                                            [self.platformTools.output stopProgress];
                                                                                        }
                                                                                      orCatch:^(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message) {
                                                                                            [self.platformTools.output writeToOutput:error ?  [error description] : [NSString string]];
                                                                                            [self.platformTools.output writeToOutput:message ? message : [NSString string]];
                                                                                            [self.platformTools.output updateView];
                                                                                            [self.platformTools.output stopProgress];
                                                                                        }];
                                        } else {
                                            [self.platformTools.output stopProgress];
                                        }
                                    } else {
                                        [self.platformTools.output stopProgress];
                                    }
                                } else {
                                    [self.platformTools.output writeToOutput: [NSString stringWithFormat:@"Request failed with code %ld", (long)((NSHTTPURLResponse*)response).statusCode]];
                                    [self.platformTools.output updateView];
                                    [self.platformTools.output stopProgress];
                                }
                            } else {
                                [self.platformTools.output writeToOutput:error ?  [error description] : [NSString string]];
                                [self.platformTools.output updateView];
                                [self.platformTools.output stopProgress];
                            }
                            [self.platformTools.output updateView];
                    }];
        [readItemTask resume];
    }
    return children;
}

- (LocationItem* _Nonnull)childAtIndex:(NSUInteger)n {
    return [[self generateChildren] objectAtIndex:n];
}
 
- (NSInteger)numberOfChildren {
    return [self.generateChildren count];
}

@end
