//
//  PlatformTools.m
//  PlatformTools
//
//  Created by Nico Ludwig on 2016-07-19
//  Copyright © 1998 - 2017 Avid Technology, Inc. All rights reserved.
//

#import "PlatformTools.h"

#import "OutputAcceptor.h"

@interface PlatformTools ()

@property dispatch_source_t _Nonnull sessionRefresher;
@property NSURLSession* _Nonnull session;
@property NSString* _Nonnull apiDomain;

@end


@implementation PlatformTools

static NSString* const argumentsFileName = @"~/Arguments.json";
static const NSTimeInterval defaultRequestTimeoutIntervalValue = 60.;
static NSString* const defaultVersionValue = @"0";

+ (NSString* _Nonnull)argumentsFilePath {
    return argumentsFileName;
}

+ (NSTimeInterval) defaultRequestTimeoutInterval {
    return defaultRequestTimeoutIntervalValue;
}

+ (NSString* _Nonnull) defaultVersion {
    return defaultVersionValue;
}

+ (NSDictionary* _Nonnull)readArgumentsFromFile:(NSString* _Nonnull)filePath {
    NSError* error;
    NSData* const content = [NSData dataWithContentsOfFile:filePath options:0 error:&error];
    NSDictionary* const argumentsRaw = (!error) ? [NSJSONSerialization JSONObjectWithData:content options:0 error:&error] : [NSDictionary dictionary];
    return (!error) ? argumentsRaw : [NSDictionary dictionary];
}

- (instancetype _Nonnull) initConnectWithOutput:(id<OutputAcceptor> _Nonnull)outputAcceptor {
    if (self = [super init]) {
        self.output = outputAcceptor;
    }
    return self;
}

- (void)URLSession:(NSURLSession* _Nonnull)session
didReceiveChallenge:(NSURLAuthenticationChallenge* _Nonnull)challenge
  completionHandler:(void (^ _Nonnull)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential* _Nullable credential))completionHandler {
    // Establish tolerant certificate check:
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    }
}

- (void)URLSession:(NSURLSession* _Nonnull)session
              task:(NSURLSessionTask* _Nonnull)task
willPerformHTTPRedirection:(NSHTTPURLResponse* _Nonnull)redirectResponse
        newRequest:(NSURLRequest* _Nonnull)request
 completionHandler:(void (^ _Nonnull)(NSURLRequest* _Nonnull))completionHandler {
    // Handle redirects:
    NSURLRequest* const newRequest = redirectResponse ? nil : request;
    completionHandler(newRequest);
}

- (NSDictionary* _Nonnull)readConfiguration {
    return [NSMutableDictionary dictionaryWithDictionary:[PlatformTools readArgumentsFromFile:[[PlatformTools argumentsFilePath] stringByExpandingTildeInPath]]];    
}

- (void)authorizeAgainst:(NSString* _Nonnull)apiDomain
               withUser:(NSString* _Nonnull)username
            andPassword:(NSString* _Nonnull)password
                andThen:(void (^ _Nonnull)(NSURLSession* _Nullable session, NSError* _Nullable error))done
                orCatch:(void (^ _Nonnull)(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message))failed {
    self.apiDomain = apiDomain;
    /// Authorization procedure:
    // Get identity providers:
    
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];    
    NSMutableURLRequest* const authRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/auth", self.apiDomain]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[PlatformTools defaultRequestTimeoutInterval]];
    [authRequest addValue:@"application/hal+json" forHTTPHeaderField:@"Accept"];
    NSURLSessionDataTask* const authTask
     = [self.session dataTaskWithRequest:authRequest
              completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
            NSString* const rawAuthResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (!error && rawAuthResult) {
                NSDictionary* const authResult = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSString* const urlIdentityProviders = [[authResult valueForKeyPath:@"_links.auth:identity-providers"][0] valueForKey:@"href"];

                NSMutableURLRequest* const identityProvidersRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlIdentityProviders] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[PlatformTools defaultRequestTimeoutInterval]];
                [identityProvidersRequest addValue:@"application/hal+json" forHTTPHeaderField:@"Accept"];
                NSURLSessionDataTask* const identityProvidersTask
                 = [self.session dataTaskWithRequest:identityProvidersRequest
                          completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
                            NSString* const rawIdentityProvidersResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                            if (!error && rawIdentityProvidersResult) {
                                NSDictionary* const identityProvidersResult = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                NSArray* const identityProviders = [identityProvidersResult valueForKeyPath:@"_embedded.auth:identity-provider"];
                                const NSUInteger idx
                                 = [identityProviders indexOfObjectPassingTest:^(id identityProvider, NSUInteger idx, BOOL* stop) {
                                    *stop = [@"mcux" isEqualToString:[identityProvider valueForKey:@"kind"]];
                                    return *stop;
                                }];
                                id mcuxIdentityProvider =  identityProviders[idx];
                                NSString* const urlAuthorization = [mcuxIdentityProvider valueForKeyPath:@"_links.auth-mcux:login.href"][0];
                                NSMutableURLRequest* const loginRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlAuthorization] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[PlatformTools defaultRequestTimeoutInterval]];
                                [loginRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                                [loginRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
                                [loginRequest setHTTPMethod:@"POST"];
                                [loginRequest setHTTPBody:[[NSString stringWithFormat:@"{ \"username\" : \"%@\", \"password\" : \"%@\"}", username, password] dataUsingEncoding:NSUTF8StringEncoding]];
                                NSURLSessionDataTask* const loginTask
                                 = [self.session dataTaskWithRequest:loginRequest
                                              completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
                                                if(!error && (303 == ((NSHTTPURLResponse*)response).statusCode || 200 == ((NSHTTPURLResponse*)response).statusCode)) {
                                                    const dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                                                    self.sessionRefresher = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
                                                    const uint64_t refreshPeriodNanoseconds = 120ull * NSEC_PER_SEC;
                                                    dispatch_source_set_timer(self.sessionRefresher, dispatch_time(DISPATCH_TIME_NOW, 0), refreshPeriodNanoseconds, 0);
                                                    dispatch_source_set_event_handler(self.sessionRefresher, ^{
                                                        [self sessionKeepAliveAgainst:apiDomain withSession:self.session];
                                                    });
                                                    dispatch_resume(self.sessionRefresher);
                                                    done(self.session, error);
                                                } else {
                                                    failed(self.session, error, @"Authorization failed.");
                                                }
                                              }];
                                [loginTask resume];
                            } else {
                                failed(self.session, error, [NSString stringWithFormat:@"<%@> %@", urlIdentityProviders, error ? error.localizedDescription : rawIdentityProvidersResult]);
                            }
                        }];
                        [identityProvidersTask resume];
            } else {
                failed(self.session, error, [NSString stringWithFormat:@"<%@> %@", authRequest.URL, error ? error.localizedDescription : rawAuthResult]);
            }
    }];
    [authTask resume];
}

- (void)sessionKeepAliveAgainst:(NSString* _Nonnull) apiDomain withSession:(NSURLSession* _Nonnull) session {
    // TODO: this is a workaround, see {CORE-7359}. In future the access token prolongation API should be used.
    NSURL* const pingURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/api/middleware/service/ping", apiDomain]];
    NSURLSessionDataTask* const connectionPing
     = [session dataTaskWithURL:pingURL
              completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
        //[self.output writeToOutput:@"Ping"];
        NSLog(@"Ping!");
        if(error) {
            // [self.output writeToOutput:[NSString stringWithFormat:@"Error pinging <%@> %@", pingURL, error ? error.localizedDescription : [NSString string]]];
            NSLog(@"Error pinging <%@> %@", pingURL, error ? error.localizedDescription : [NSString string]);
        }
    }];
    [connectionPing resume];
}

- (void)logoutAndThen:(void (^ _Nonnull)(NSURLSession* _Nullable session, NSError* _Nullable error))done
              orCatch:(void (^ _Nonnull)(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message))failed {
    /// Logout from platform:
    NSMutableURLRequest* const authRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/auth", self.apiDomain]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[PlatformTools defaultRequestTimeoutInterval]];
    [authRequest addValue:@"application/hal+json" forHTTPHeaderField:@"Accept"];
    NSURLSessionDataTask* const authTask
     = [self.session dataTaskWithRequest:authRequest
            completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
                NSString* const rawAuthResult = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (!error && rawAuthResult) {
                    NSDictionary* const authResult = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    NSArray* const authTokens = [authResult valueForKeyPath:@"_links.auth:token"];
 
                    const NSUInteger idx
                     = [authTokens indexOfObjectPassingTest:^(id token, NSUInteger idx, BOOL* stop) {
                        *stop = [@"current" isEqualToString:[token valueForKey:@"name"]];
                        return *stop;
                    }];
                    
                    if (NSNotFound != idx) {
                        NSDictionary* const currentToken = authTokens[idx];
                        NSString* const urlCurrentToken= [currentToken valueForKeyPath:@"href"];
                        
                        NSMutableURLRequest* const removeTokenRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlCurrentToken]
                                                                                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                                             timeoutInterval:[PlatformTools defaultRequestTimeoutInterval]];
                        [removeTokenRequest setHTTPMethod:@"DELETE"];
                        NSURLSessionDataTask* const removeTokenTask
                                         = [self.session dataTaskWithRequest:removeTokenRequest
                                                      completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
                                                        [self.session resetWithCompletionHandler:^() {}];

                                                        // Should result in 204:
                                                        //const NSInteger responseCode = ((NSHTTPURLResponse*)response).statusCode;
                                                        if(!error) {
                                                            done(self.session, error);
                                                        } else {
                                                            failed(self.session, error, @"Removal of current token didn't succeed.");
                                                        }
                                                      }];
                        [removeTokenTask resume];
                    } else {
                        failed(self.session, error, @"Current token not found.");
                    }
                } else {

                    failed(self.session, error, [NSString stringWithFormat:@"Request failed for <%@>.", authRequest.URL]);
                }
            }];
    [authTask resume];
    
    /// Unregister the keep alive task:
    if(self.sessionRefresher) {
        dispatch_source_cancel(self.sessionRefresher);
    }
}

- (void)pageThroughResultsWithSession:(NSURLSession* _Nonnull)session
                               andURL:(NSURL* _Nonnull)resultPageURL
                              andThen:(void (^ _Nonnull)(NSArray* _Nonnull pages))done
                              orCatch:(void (^ _Nonnull)(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message))failed  {
    NSMutableArray* const pages = [NSMutableArray new];
    
    // TODO: the extra replacement is required for PAM and acts as temp. fix?
    //???? options.path = urlResultPage.replace(new RegExp(' ', 'g'), '%20');
    
    NSMutableURLRequest* const pageRequest = [NSMutableURLRequest requestWithURL:resultPageURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:[PlatformTools defaultRequestTimeoutInterval]];
    [pageRequest addValue:@"application/hal+json" forHTTPHeaderField:@"Accept"];
    NSURLSessionDataTask* const pageTask
     = [session dataTaskWithRequest:pageRequest
                  completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
                    if (!error) {
                        NSDictionary* const pageResult = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                        NSDictionary* const embeddedResults = [pageResult valueForKeyPath:@"_embedded"];
                                                                                            
                        // Do we have results:
                        if (embeddedResults) {
                            [pages addObject:embeddedResults];
                        
                            // If we have more results, follow the next link and get the next page:
                            id linkToNextPage = [pageResult valueForKeyPath:@"_links.next"];
                            if (linkToNextPage) {
                                [self pageThroughResultsWithSession:session
                                                             andURL:[NSURL URLWithString:[linkToNextPage valueForKeyPath:@"href"]]
                                                            andThen:^(NSArray* _Nonnull nextPages) {
                                                                [pages addObjectsFromArray:nextPages];
                                                                done(pages);
                                                            } orCatch:^(NSURLSession* _Nullable session, NSError* _Nullable error, NSString* _Nullable message) {
                                                                failed(session, error, message);
                                                            }];
                            } else {
                                done(pages);
                            }
                        } else {
                            failed(session, error, [NSString stringWithFormat:@"Paging failed for <%@>.", resultPageURL]);
                        }
                    } else {
                        failed(session, error, [NSString string]);
                    }
                }];
    [pageTask resume];
}

@end
