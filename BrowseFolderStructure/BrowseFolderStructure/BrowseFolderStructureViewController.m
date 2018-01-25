//
//  BrowseFolderStructureViewController.m
//  BrowseFolderStructure
//
//  Created by Nico Ludwig on 2016-08-02
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import "BrowseFolderStructureViewController.h"

#import "LocationItem.h"
#import "LocationsDataSource.h"
#import "AppDelegate.h"

#import "../../PlatformTools/PlatformTools.h"


@implementation BrowseFolderStructureViewController

- (void)writeToOutput:(NSString* _Nonnull)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeZone* const timeZone = [NSTimeZone defaultTimeZone];
        NSDateFormatter* const dateFormatter = [NSDateFormatter new];
        [dateFormatter setTimeZone:timeZone];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    
        [self.textView setString:[NSMutableString stringWithFormat:@"%@(%@) %@\n", [self.textView string], [dateFormatter stringFromDate:[NSDate date]], text]];
        [self.textView scrollToEndOfDocument:nil];
        NSLog(@"%@", text);
    });
}

- (IBAction)clear:(id)sender {
    [self clear];
}

- (void)clear {
 dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.string = [NSString string];
    });
}

- (void)updateView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.outlineView reloadData];
    });
}

- (void)startProgress {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressIndicator.hidden = NO;
        [self.progressIndicator startAnimation:self];
    });
}

- (void)reportProgress:(NSInteger)progress {
}

- (void)stopProgress {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressIndicator.hidden = YES;
        [self.progressIndicator stopAnimation:self];
    });
}

- (IBAction)connect:(id)sender {
    [self startProgress];
    
    [self.platformTools authorizeAgainst:[self.config valueForKey:@"apidomain"]
                                withUser:[self.config valueForKey:@"username"]
                             andPassword:[self.config valueForKey:@"password"]
                                 andThen:^(NSURLSession* _Nonnull session, NSError* _Nullable error) {
                                        [LocationItem resetRoot];
                    
                                        // dataSource needs to be a strong reference, otherwise it would be released after set to the NSOutlineView due to ARC
                                        self.dataSource = [[LocationsDataSource alloc] initWithSession:session andConfig:self.config andPlatformTools:self.platformTools];

                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self.outlineView setDataSource:self.dataSource];
                                        });
                                        [self stopProgress];
                                    }
                                 orCatch:^(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message) {
                                        [self writeToOutput:error ? [error description] : [NSString string]];
                                        [self writeToOutput:message ? message : [NSString string]];
                                        [self stopProgress];
                                    }];
}

- (instancetype)init {
    if(self = [super init]) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.progressIndicator.hidden = YES;

    self.platformTools = [[PlatformTools alloc] initConnectWithOutput:self];
    
    NSArray* const args = [[NSProcessInfo processInfo] arguments];
    if (5 >= [args count]) {
        // No or invalid command line arguments => try reading the argument file
        self.config = [self.platformTools readConfiguration];
        if(![self.config count]) {
            NSString* const messageCorrectUsage = [NSString stringWithFormat:
                @"Usage via Commandline: %@ <apidomain> <servicetype> <realm> <username> <password>\n"
                @"Alternatively, the arguments file '%@' must be provided.\n", args[0], [PlatformTools argumentsFilePath]];
            [self.platformTools.output writeToOutput:messageCorrectUsage];
        }
    } else {
        self.config = [NSMutableDictionary dictionaryWithDictionary:@{
            @"apidomain" : args[1]
            , @"servicetype" : args[2]
            , @"realm" : args[3]
            , @"username" : args[4]
            , @"password" : args[5]
        }];
    }
    
    AppDelegate* const appDelegate = (AppDelegate*)[NSApplication sharedApplication].delegate;
    appDelegate.platformAccess = self.platformTools;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

@end
