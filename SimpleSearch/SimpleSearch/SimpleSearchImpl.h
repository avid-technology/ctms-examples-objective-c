//
//  SimpleSearchImpl.h
//  SimpleSearch
//
//  Created by Nico Ludwig on 2016-07-30
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PlatformTools;

@interface SimpleSearchImpl : NSObject
{
    NSDictionary* _config;
}

@property PlatformTools* _Nonnull platformTools;

- (instancetype _Nonnull)initWithConfig:(NSDictionary* _Nonnull)config andPlatformTools:(PlatformTools* _Nonnull)platformTools;

- (void)simpleSearchWithSession:(NSURLSession* _Nonnull)session
                       andThen:(void (^ _Nullable)(NSURLSession* _Nonnull session, NSError* _Nullable error))done
                       orCatch:(void (^ _Nonnull)(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message))failed;

@end
