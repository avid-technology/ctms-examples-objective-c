//
//  LocationItem.h
//  BrowseFolderStructure
//
//  Created by Nico Ludwig on 2016-08-02
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PlatformTools;
@class NSOutlineView;
@class LocationItem;


@interface LocationItem : NSObject
{
@private
    NSMutableArray* _Nonnull children;
}


@property NSString* _Nonnull myPath;
@property NSOutlineView* _Nonnull outlineView;
@property LocationItem* _Nonnull parent;
@property NSDictionary* _Nonnull config;
@property PlatformTools* _Nonnull platformTools;
@property NSURLSession* _Nonnull session;
@property NSString* _Nonnull name;
@property BOOL hasChildren;

+ (void)resetRoot;
+ (LocationItem* _Nullable)rootItemForOutlineView:(NSOutlineView* _Nonnull)outlineView
                                    withSession:(NSURLSession* _Nonnull)session
                                      andConfig:(NSDictionary* _Nonnull)config
                               andPlatformTools:(PlatformTools* _Nonnull)platformTools;

- (instancetype _Nonnull)initWithPath:(NSString* _Nonnull)path
                    asLeaf:(BOOL)isLeaf
                   andName:(NSString* _Nonnull)name
            forOutlineView:(NSOutlineView* _Nonnull)outlineView
                andSession:(NSURLSession* _Nonnull)session
                 andConfig:(NSDictionary* _Nonnull)config
          andPlatformTools:(PlatformTools* _Nonnull)platformTools;
- (NSInteger)numberOfChildren;
- (LocationItem* _Nonnull)childAtIndex:(NSUInteger)n;

@end
