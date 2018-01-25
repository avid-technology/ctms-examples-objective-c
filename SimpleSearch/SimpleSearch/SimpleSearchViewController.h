//
//  SimpleSearchViewController.h
//  SimpleSearch
//
//  Created by Nico Ludwig on 2016-07-28
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "../../PlatformTools/OutputAcceptor.h"

@class PlatformTools;

@interface SimpleSearchViewController : NSViewController<OutputAcceptor>

@property NSDictionary* _Nonnull config;
@property PlatformTools* _Nonnull platformTools;
@property (unsafe_unretained) IBOutlet NSTextView* _Nonnull textView;
@property (weak) IBOutlet NSProgressIndicator* _Nullable progressIndicator;

@property (weak) IBOutlet NSMenu* _Nullable textViewContextMenu;

- (void)viewDidLoad;
- (IBAction)clear:(id _Nonnull)sender;
@end

