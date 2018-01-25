//
//  OutputAcceptor.h
//  PlatformTools
//
//  Created by Nico Ludwig on 2016-08-01
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OutputAcceptor<NSObject>

/// Sends the specified text to output.
///
/// @param text the text to send to output
- (void)writeToOutput:(NSString* _Nonnull)text;

/// Clears the output view output.
- (void)clear;

/// Updates the view used for output.
- (void)updateView;

/// Signals, that something is in progress.
///
/// @see stopProgress
/// @see reportProgress
- (void)startProgress;

/// Signals the current "progress".
///
/// @param progress the "progress" to send to output
/// @see stopProgress
/// @see startProgress
- (void)reportProgress:(NSInteger)progress;

/// Signals, that the progress has stopped.
///
/// @see startProgress
/// @see reportProgress
- (void)stopProgress;

@end
