//
//  PlatformTools.h
//  PlatformTools
//
//  Created by Nico Ludwig on 2016-07-16
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PlatformAccess.h"

@protocol OutputAcceptor;

@interface PlatformTools : NSObject<NSURLSessionDelegate, PlatformAccess>

/// Gets and sets the object, which accepts output to be signaled to the controller.
@property id<OutputAcceptor> _Nonnull output;

/// Retrieves the name of the arguments file.
///
/// @return the path of the JSON file containing the arguments
+ (NSString* _Nonnull)argumentsFilePath;

/// Retrieves the default request interval.
///
/// @return the default request interval.
+ (NSTimeInterval) defaultRequestTimeoutInterval;

/// Retrieves the default version.
///
/// @return the default version.
+ (NSString* _Nonnull) defaultVersion;

/// Initializes a newly allocated PlatformTools instance with an object, which accetps output to be signaled to the controller.
///
/// @param outputAcceptor an object, which accetps output to be signaled to the controller
/// @see output
- (instancetype _Nonnull)initConnectWithOutput:(id<OutputAcceptor> _Nonnull)outputAcceptor;

/// Reads the configuration for the platformexamples from an arguments file in JSON format.
///
/// @return the read arguments as key-value pairs
/// @see argumentsFilePath
- (NSDictionary* _Nonnull)readConfiguration;

/// Pages through the HAL resources available via the passed resultPageURL. The results are collected and passed to
/// the additionally passed "continuation" block, which is executed after all pages have been collected.
///
/// If the HAL resource available from resultPageURL has the property "_embedded", its content will be collected
/// And if this HAL resource has the property "pageResult._links.next", its href will be used to
/// fetch and collect the next page and call this method recursively.
///
/// @param session the session, which is used to get the pages
/// @param resultPageURL URL to a HAL resource, which supports paging
/// @param done a "continuation" block, which is called, when the paging procedure ended successfully, the pages are passed to this block.
/// @param failed a "continuation" block, which is called, when the paging procedure failed.
- (void)pageThroughResultsWithSession:(NSURLSession* _Nonnull)session
                               andURL:(NSURL* _Nonnull)resultPageURL
                              andThen:(void (^ _Nonnull)(NSArray* _Nonnull pages))done
                              orCatch:(void (^ _Nonnull)(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message))failed;

@end
