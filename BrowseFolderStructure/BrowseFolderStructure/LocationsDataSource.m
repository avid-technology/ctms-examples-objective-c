//
//  LocationsDataSource.m
//  BrowseFolderStructure
//
//  Created by Nico Ludwig on 2016-08-03
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import "LocationsDataSource.h"

#import "LocationItem.h"

@implementation LocationsDataSource// Data Source methods

- (instancetype _Nonnull)initWithSession:(NSURLSession* _Nonnull)session andConfig:(NSDictionary* _Nonnull)config andPlatformTools:(PlatformTools* _Nonnull)platformTools {
    if (self = [super init]) {
        self.config = config;
        self.platformTools = platformTools;
        self.session = session;
    }
    return self;
}
 
- (NSInteger)outlineView:(NSOutlineView*)outlineView numberOfChildrenOfItem:(id)item {
    return item
        ? [item numberOfChildren]
        : 1;
}
 
- (BOOL)outlineView:(NSOutlineView*)outlineView isItemExpandable:(id)item {
    return item
        ? ((LocationItem*) item).hasChildren
        : YES;
}
 
- (id)outlineView:(NSOutlineView*)outlineView child:(NSInteger)index ofItem:(id)item {
    return item
        ? [(LocationItem*)item childAtIndex:index]
        : [LocationItem rootItemForOutlineView:outlineView withSession:self.session andConfig:self.config andPlatformTools:self.platformTools];
}
 
- (id)outlineView:(NSOutlineView*)outlineView objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item {
    return item
        ? [item name]
        : [NSString string];
}

@end
