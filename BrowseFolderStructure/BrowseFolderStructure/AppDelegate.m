//
//  AppDelegate.m
//  BrowseFolderStructure
//
//  Created by Nico Ludwig on 2016-08-02
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import "AppDelegate.h"

#import "../../PlatformTools/PlatformAccess.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification {
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification*)aNotification {
    const dispatch_semaphore_t logoutComplete = dispatch_semaphore_create(0);
    [self.platformAccess logoutAndThen:^(NSURLSession* _Nullable session, NSError* _Nullable error) {
                                    dispatch_semaphore_signal(logoutComplete);
                                }
                              orCatch:^(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message) {
                                    NSLog(@"%@", error ? [error description] : [NSString string]);
                                    NSLog(@"%@", message ? message : [NSString string]);
                                }];
    
    const dispatch_time_t waitAtMost = dispatch_time(DISPATCH_TIME_NOW, (int64_t)NSEC_PER_SEC);
    dispatch_semaphore_wait(logoutComplete, waitAtMost);
}

@end
