//
//  Makaba.m
//  vorobooshek
//
//  Created by admin on 19/02/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import "Makaba.h"

@interface Makaba()// <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate>
{
    NSString *_kAdditionalHeaders;
}

@property (nonatomic) NSString *serverName;

@end

@implementation Makaba


+(instancetype)shared
{
    static Makaba *sharedMakaba = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMakaba = [[self alloc] init];
    });
    
    return sharedMakaba;
}


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _kAdditionalHeaders = @"additionalHeaders";
        self.serverName = @"2ch.hk";
    }
    return self;
}


-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSDictionary *additionalHeaders = [request allHTTPHeaderFields];
    
    if (additionalHeaders)
    {
        [[NSUserDefaults standardUserDefaults] setObject:additionalHeaders forKey:_kAdditionalHeaders];
        if ([additionalHeaders valueForKey:@"Accept-Language"])
        {
            [self.makabaDelegate makabaDidFinishCloudflareVerification];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return YES;
}


-(void)getBoardsWithSuccessHandler:(makabaReturnBlockWithDictionary)successHandler
                    failureHandler:(makabaReturnBlockWithError)failureHandler
{
    NSString *queueString = [NSString stringWithFormat:@"https://%@/makaba/mobile.fcgi?task=get_boards", self.serverName] ;
    
    NSURL *url = [NSURL URLWithString:queueString];
    [self performApiCallForURL:url successHandler:successHandler failureHandler:failureHandler];
}

-(void)getThreadsForBoard:(NSString *)board
           successHandler:(makabaReturnBlockWithArray)successHandler
           failureHandler:(makabaReturnBlockWithError)failureHandler
{
    NSString *queueString = [NSString stringWithFormat:@"https://%@/%@/index.json", self.serverName, board] ;
    
    NSURL *url = [NSURL URLWithString:queueString];
    [self performApiCallForURL:url successHandler:^(NSDictionary *result)
    {
        NSMutableArray *threads = [NSMutableArray array];
        for (NSDictionary *thread in [result objectForKey:@"threads"])
        {
            [threads addObject: [thread objectForKey:@"thread_num"]];
        }
        
        successHandler(threads);
    } failureHandler:^(NSError *error)
     {
         failureHandler(error);
         
     }];
}

-(void)getPostsForBoard:(NSString*)board
              andThread:(NSUInteger)thread
       startingFromPost:(NSUInteger)post
         successHandler:(makabaReturnBlockWithDictionary)successHandler
          failureHandler:(makabaReturnBlockWithError)failureHandler
{
    NSString *queueString = [NSString stringWithFormat: @"https://%@/makaba/mobile.fcgi?task=get_thread&board=%@&thread=%lu&num=%lu", self.serverName, board, (unsigned long)thread, (unsigned long)post];
    
    NSURL *url = [NSURL URLWithString:queueString];
    [self performApiCallForURL:url successHandler:successHandler failureHandler:failureHandler];
}


-(void)getPostsForBoard:(NSString *)board
              andThread:(NSUInteger)thread
   startingFromPosition:(NSUInteger)startingPosition
         successHandler:(makabaReturnBlockWithDictionary)successHandler
         failureHandler:(makabaReturnBlockWithError)failureHandler
{
    NSString *queueString = [NSString stringWithFormat: @"https://%@/makaba/mobile.fcgi?task=get_thread&board=%@&thread=%lu&post=%lu", self.serverName, board, (unsigned long)thread, (unsigned long)startingPosition];
    
    NSURL *url = [NSURL URLWithString:queueString];
    
    [self performApiCallForURL:url successHandler:successHandler failureHandler:failureHandler];
}

-(void)getThreadInfoForBoard:(NSString *)board
                   andThread:(NSUInteger)thread
              successHandler:(makabaReturnBlockWithDictionary)successHandler
              failureHandler:(makabaReturnBlockWithError)failureHandler
{
    NSString *queueString = [NSString stringWithFormat: @"https://%@/makaba/mobile.fcgi?task=get_thread_last_info&board=%@&thread=%lu", self.serverName, board, (unsigned long)thread];
    
    NSURL *url = [NSURL URLWithString:queueString];
    [self performApiCallForURL:url successHandler:successHandler failureHandler:failureHandler];
}

-(void)performApiCallForURL:(NSURL*)url
             successHandler:(makabaReturnBlockWithDictionary)successHandler
             failureHandler:(makabaReturnBlockWithError)failureHandler
{
    if (successHandler)
    {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.HTTPAdditionalHeaders = [[NSUserDefaults standardUserDefaults] dictionaryForKey:_kAdditionalHeaders];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        
        [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
          {
              if (error)
              {
                  failureHandler(error);
                  return;
              }
              
              NSError *jsonError = nil;
              NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
              
              if (dataDictionary)
              {
                  NSString *jsonResponseError;
                  if ([dataDictionary respondsToSelector:@selector(objectForKey:)])
                  {
                      jsonResponseError = [dataDictionary objectForKey:@"Error"];
                  }
                  
                  if (!jsonResponseError)
                  {
                      successHandler(dataDictionary);
                  }
                  else
                  {
                      // Request was successful, but there's something wrong with api query or arguments
                      // or there's no media on a server (outdated, deleted, never existed)
                      
                      NSDictionary *errorUserInfo = @{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Makaba: Server returned error for the api query: %@", jsonResponseError]};
                      
                      failureHandler([NSError errorWithDomain:@"Makaba" code:1 userInfo:errorUserInfo]);
                  }
              }
              else
              {
                  NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
                  NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                  
                  NSString *errorReason = @"Unknown reason";
                  
                  if (statusCode == 503 && [[headers objectForKey:@"Server"] isEqualToString:@"cloudflare-nginx"])
                  {
                      errorReason = @"CloudFlare is down";
                  }
                  else if (statusCode == 403 && [[headers objectForKey:@"Server"] isEqualToString:@"cloudflare-nginx"])
                  {
                      [self.makabaDelegate makabaNeedsCloudflareVerification:data forURL:url];
                      errorReason = @"CloudFlare requires verification";
                  }
                  
                  NSDictionary *errorUserInfo = @{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Makaba: Couldn't retrieve json data from server. %@", errorReason],
                  @"jsonParsingError":jsonError,
                  @"statusCode": [NSString stringWithFormat:@"%ld", (long)statusCode],
                  @"headers":headers};
                  
                  failureHandler([NSError errorWithDomain:@"Makaba" code:0 userInfo:errorUserInfo]);
              }
          }] resume];
    }
}


@end
