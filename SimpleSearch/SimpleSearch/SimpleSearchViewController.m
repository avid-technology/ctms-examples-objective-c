//
//  SimpleSearchViewController.m
//  SimpleSearch
//
//  Created by Nico Ludwig on 2016-07-28
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import "SimpleSearchViewController.h"

#import "SimpleSearchImpl.h"

#import "../../PlatformTools/PlatformTools.h"

@implementation SimpleSearchViewController

- (void)writeToOutput:(NSString* _Nonnull)text {

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textView setString:[NSMutableString stringWithFormat:@"%@%@\n", [self.textView string], text]];
        [self.textView scrollToEndOfDocument:nil];
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

- (IBAction)start:(id)sender {
    NSString* rawSearchExpression = [self.config valueForKeyPath:@"searchexpression"];
    rawSearchExpression = [rawSearchExpression substringWithRange:NSMakeRange(1, [rawSearchExpression length] - 2)];
   
    NSMutableDictionary* effectiveConfig = [NSMutableDictionary dictionaryWithDictionary:self.config];
    [effectiveConfig setValue:rawSearchExpression forKey:@"searchexpression"];
    
    [self startProgress];
    [self.platformTools authorizeAgainst:[effectiveConfig valueForKey:@"apidomain"]
                                withUser:[effectiveConfig valueForKey:@"username"]
                             andPassword:[effectiveConfig valueForKey:@"password"]
                                 andThen:^(NSURLSession* _Nonnull session, NSError* _Nullable error) {
                                        SimpleSearchImpl* const simpleSearch = [[SimpleSearchImpl alloc]initWithConfig:effectiveConfig andPlatformTools:self.platformTools];
                                        [simpleSearch simpleSearchWithSession:session
                                                                      andThen:^(NSURLSession* _Nonnull session, NSError* _Nullable error) {
                                                                        [self.platformTools logoutAndThen:^(NSURLSession* _Nullable session, NSError* _Nullable error) {
                                                                                                    [self writeToOutput:@"End"];
                                                                                                    [self stopProgress];
                                                                                                }
                                                                                                 orCatch:^(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message) {
                                                                                                    [self writeToOutput: error ? [error description] : [NSString string]];
                                                                                                    [self writeToOutput:message ? message : [NSString string]];
                                                                                                    [self writeToOutput:@"End"];
                                                                                                    [self stopProgress];
                                                                                                }
                                                                        ];
                                                                        }
                                                                    orCatch:^(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message) {
                                                                        [self writeToOutput:error ? [error description] : [NSString string]];
                                                                        [self writeToOutput:message ? message : [NSString string]];
                                                                        [self writeToOutput:@"End"];
                                                                        [self stopProgress];
                                                                    }];
                                    }
                                orCatch:^(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message) {
                                        [self writeToOutput:error ? [error description] : [NSString string]];
                                        [self writeToOutput:message ? message : [NSString string]];
                                        [self writeToOutput:@"End"];
                                        [self stopProgress];
                                    }
                                 ];
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
    if (6 >= [args count] || [@"'" isEqualToString:args[6]] || '\'' != [args[6] characterAtIndex:0] || '\'' != [args[6] characterAtIndex:[args[6] length] - 1]) {
        // No or invalid command line arguments => try reading the argument file
        self.config = [self.platformTools readConfiguration];
        if(![self.config count]) {
            NSString* const messageCorrectUsage = [NSString stringWithFormat:
                @"Usage via Commandline: %@ <apidomain> <servicetype> <realm> <username> <password> '<searchexpression>'\n"
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
            , @"searchexpression" : args[6]
        }];
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

@end
