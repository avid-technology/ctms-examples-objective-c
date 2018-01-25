//
//  AppDelegate.h
//  BrowseFolderStructure
//
//  Created by Nico Ludwig on 2016-08-02
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.

#import <Cocoa/Cocoa.h>

@protocol PlatformAccess;

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property id<PlatformAccess> _Nonnull platformAccess;

@end

