//
//  BrowseFolderStructureViewController.h
//  BrowseFolderStructure
//
//  Created by Nico Ludwig on 2016-08-02
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "../../PlatformTools/OutputAcceptor.h"

@class PlatformTools;
@protocol NSOutlineViewDataSource;

@interface BrowseFolderStructureViewController : NSViewController<OutputAcceptor>

@property NSDictionary* _Nonnull config;
@property PlatformTools* _Nonnull platformTools;
@property (weak) IBOutlet NSOutlineView* _Nullable outlineView;
// dataSource needs to be a strong reference, otherwise it would be released after set to the NSOutlineView due to ARC
@property id<NSOutlineViewDataSource> _Nonnull dataSource;
@property (unsafe_unretained) IBOutlet NSTextView* _Nonnull textView;
@property (weak) IBOutlet NSProgressIndicator* _Nullable progressIndicator;

@property (weak) IBOutlet NSMenu* _Nullable textViewContextMenu;

- (void)updateView;
- (IBAction)connect:(id _Nonnull)sender;
- (IBAction)clear:(id _Nonnull)sender;

- (void)viewDidLoad;

@end

