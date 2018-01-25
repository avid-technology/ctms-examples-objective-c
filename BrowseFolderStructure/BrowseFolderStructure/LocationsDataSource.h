//
//  LocationsDataSource.h
//  BrowseFolderStructure
//
//  Created by Nico Ludwig on 2016-08-03
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "../../PlatformTools/PlatformTools.h"

@interface LocationsDataSource : NSObject<NSOutlineViewDataSource>
@property NSDictionary* _Nonnull config;
@property PlatformTools* _Nonnull platformTools;
@property NSURLSession* _Nonnull session;

- (instancetype _Nonnull)initWithSession:(NSURLSession* _Nonnull)session andConfig:(NSDictionary* _Nonnull)config andPlatformTools:(PlatformTools* _Nonnull)platformTools;

@end
