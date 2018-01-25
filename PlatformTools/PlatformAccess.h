//
//  PlatformAccess.h
//  PlatformTools
//
//  Created by Nico Ludwig on 2016-08-07
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PlatformAccess

/// Performs a login against the platform and awaits a "continuation" block with the code working with the authorization.
///
/// MCUX-identity-provider based authorization via credentials and cookies.
/// The used server-certificate validation is tolerant. As a side effect the global cookie handler is configured in a
/// way to refer a set of cookies, which are required for the communication with the platform.
///
/// @param apiDomain address to get "auth"
/// @param username MCUX login
/// @param password MCUX password
/// @param done a "continuation" block, which is called, when the authorization procedure ended successfully. The block should contain the code, which
/// continues working with the session resulting from the authorization.
/// @param failed a "continuation" block, which is called, when the authorization procedure failed.
- (void)authorizeAgainst:(NSString* _Nonnull)apiDomain
                withUser:(NSString* _Nonnull)username
             andPassword:(NSString* _Nonnull)password
                 andThen:(void (^ _Nonnull)(NSURLSession* _Nullable session, NSError* _Nullable error))done
                 orCatch:(void (^ _Nonnull)(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message))failed;

/// Signals the platform, that our session is still in use.
///
/// @param apiDomain address, against to which we want send a keep alive signal
- (void)sessionKeepAliveAgainst:(NSString* _Nonnull) apiDomain
                    withSession:(NSURLSession* _Nonnull) session;

/// Performs a logout against the platform and awaits a "continuation" block with the code to be performed, after the logout ended.
///
/// @param done a "continuation" block, which is called, when the logout procedure ended successfully.
/// @param failed a "continuation" block, which is called, when the logout procedure failed.
- (void)logoutAndThen:(void (^ _Nonnull)(NSURLSession* _Nullable session, NSError* _Nullable error))done
              orCatch:(void (^ _Nonnull)(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message))failed;

@end
