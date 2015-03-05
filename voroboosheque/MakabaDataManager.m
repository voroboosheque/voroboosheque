//
//  MakabaDataManager.m
//  voroboosheque
//
//  Created by admin on 23/02/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import "MakabaDataManager.h"
#import "CoreData+MagicalRecord.h"
#import "Makaba.h"
#import "MBoard.h"
#import "MBoardCategory.h"
#import "MThread.h"
#import "MPost.h"
#import "CloudflareViewController.h"

//#define MR_SHORTHAND

@import UIKit;

@interface UIWindow (PazLabs)

- (UIViewController *) visibleViewController;

@end

@interface MakabaDataManager() <makabaDelegateProtocol>

@property (nonatomic) CloudflareViewController *cloudflareVC;

@end

@implementation UIWindow (PazLabs)

////
- (UIViewController *)visibleViewController
{
    UIViewController *rootViewController = self.rootViewController;
    return [UIWindow getVisibleViewControllerFrom:rootViewController];
}

+ (UIViewController *) getVisibleViewControllerFrom:(UIViewController *) vc
{
    if ([vc isKindOfClass:[UINavigationController class]])
    {
        return [UIWindow getVisibleViewControllerFrom:[((UINavigationController *) vc) visibleViewController]];
    }
    else if ([vc isKindOfClass:[UITabBarController class]])
    {
        return [UIWindow getVisibleViewControllerFrom:[((UITabBarController *) vc) selectedViewController]];
    }
    else
    {
        if (vc.presentedViewController)
        {
            return [UIWindow getVisibleViewControllerFrom:vc.presentedViewController];
        }
        else
        {
            return vc;
        }
    }
}

@end

@implementation MakabaDataManager

+(instancetype)shared
{
    static MakabaDataManager *sharedMakabaDataManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMakabaDataManager = [[self alloc] init];
    });
    
    return sharedMakabaDataManager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [[Makaba shared] setMakabaDelegate:self];
    }
    return self;
}

-(void)resetCache
{
    NSArray *allObjects = [NSManagedObject MR_findAll];
    
    for (NSManagedObject *object in allObjects)
    {
        [object MR_deleteEntity];
    }
}

-(NSArray *)getCachedCategories
{
    return [MBoardCategory MR_findAllSortedBy:@"order" ascending:YES];
}

-(NSArray *)getCachedBoards
{
    return [MBoard MR_findAll];
}

-(NSArray *)getCahcedThreadsForBoard:(MBoard*)board
{
    return [board.threads array];
}

-(NSArray *)getCachedPostsForThread:(MThread*)thread
{
    return [thread.posts array];
}

-(void)getBoardsDataWithSuccessHandler:(void (^)(NSArray *, NSArray *))successHandler
                        failureHandler:(makabaDataReturnBlockWithError)failureHandler
{
    if (successHandler)
    {
        [[Makaba shared] getBoardsWithSuccessHandler:^(NSDictionary *result)
        {
            NSMutableArray *boards = [NSMutableArray array];
            NSMutableArray *categories = [NSMutableArray array];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^
            {
                NSUInteger i = 0;
                for (NSString *jCategory in result)
                {
                    //TODO: check if category with that id is unique
                    MBoardCategory *category = [[MBoardCategory MR_findByAttribute:@"name" withValue:jCategory] lastObject];
                    
                    if (!category)
                    {
                        category = [MBoardCategory MR_createEntity];
                    }
                    
                    category.order = [NSNumber numberWithUnsignedInteger:i];
                    i++;
                    category.name = jCategory;
                    [categories addObject:category];

                    for (id jBoard in [result objectForKey:jCategory])
                    {
                        //TODO: check if board with that id is unique
                        MBoard *board = [[MBoard MR_findByAttribute:@"id" withValue:[jBoard objectForKey:@"id"]] lastObject];
                        
                        if (!board)
                        {
                            board = [MBoard MR_createEntity];
                        }

                        board.name = [jBoard objectForKey:@"name"];
                        board.bumpLimit = [jBoard objectForKey:@"bump_limit"];
                        board.defaultName = [jBoard objectForKey:@"default_name"];
                        board.enablePosting = [jBoard objectForKey:@"enable_posting"];
                        board.id = [jBoard objectForKey:@"id"];
                        board.pages = [jBoard objectForKey:@"pages"];
                        board.sage = [jBoard objectForKey:@"sage"];
                        board.tripcodes = [jBoard objectForKey:@"tripcodes"];
                        board.category = category;
                        
                        [boards addObject:board];
                    }
                    
                    //remove from cache all MBoards not present in JSON response
                    for (MBoard *board in category.boards)
                    {
                        BOOL presentInJSONResponse = NO;
                        
                        for (id jBoard in [result objectForKey:jCategory])
                        {
                            if ([[jBoard objectForKey:@"id"] isEqualToString:board.id])
                            {
                                presentInJSONResponse = YES;
                            }
                        }
                        
                        if (!presentInJSONResponse)
                        {
                            [self deleteAllThreadsForBoard:board];
                            [board MR_deleteEntity];
                        }
                    }
                }
                
                [self saveContext];
                successHandler(categories, boards);
            }];
            

        }
        failureHandler:^(NSError *error)
        {


        }];
    }
}

-(void)getThreadsDataForBoard:(MBoard *)board
               successHandler:(void (^)(NSArray *))successHandler
               failureHandler:(makabaDataReturnBlockWithError)failureHandler
{
    [[Makaba shared] getThreadsForBoard:board.id successHandler:^(NSArray *result)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^
        {
            NSMutableArray *threads = [NSMutableArray array];
            
            int i = 0;
            for (id jThread in result)
            {
                id jOPPost = [[jThread objectForKey:@"posts"] firstObject];
                
                NSNumber *num = [NSNumber numberWithInt:[[jOPPost objectForKey:@"num"] intValue]];
                
                NSPredicate *predicate =  [NSPredicate predicateWithFormat:@"(board == %@) AND (num == %@)", board, num];
                
                MThread *thread = [[MThread MR_findAllWithPredicate:predicate] lastObject];
                
                if (!thread)
                {
                    thread = [MThread MR_createEntity];
//                    thread.board = board;
                    thread.num = num;
                }
                
                [board insertObject:thread inThreadsAtIndex:i];
//                [board addThreadsObject:thread];
                i++;
                
                [threads addObject:thread];
                
                predicate =  [NSPredicate predicateWithFormat:@"(parent == %@) AND (num == %@)", thread, num];
                
                MPost *post = [[MPost MR_findAllWithPredicate:predicate] lastObject];
                
                if (!post)
                {
                    post = [MPost MR_createEntity];
                    post.parent = thread;
                    post.num = num;
                    post.comment = [jOPPost objectForKey:@"comment"];
                }
            }
            
            [self saveContext];
            successHandler(threads);
        }];
    }
    failureHandler:^(NSError *error)
    {
        //
    }];
    
}

-(void)getPostsForThread:(MThread *)thread
    startingFromPosition:(NSUInteger)startingPosition
          successHandler:(void (^)(NSArray *))successHandler
          failureHandler:(makabaDataReturnBlockWithError)failureHandler
{
    NSLog(@"+++++++++++  %d", [[MPost MR_findAll] count]);
    
    [[Makaba shared] getPostsForBoard:thread.board.id
                            andThread:[thread.num unsignedIntegerValue]
                 startingFromPosition:startingPosition
                       successHandler:^(NSDictionary *result)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^
         {
             NSMutableArray *posts = [NSMutableArray array];
             
             for (id jPost in result)
             {
                 NSNumber *num = [NSNumber numberWithInt:[[jPost objectForKey:@"num"] intValue]];
                 NSPredicate *predicate =  [NSPredicate predicateWithFormat:@"(parent == %@) AND (num == %@)", thread, num];
                 
                 MPost *post = [[MPost MR_findAllWithPredicate:predicate] lastObject];
                 
                 if (!post)
                 {
                     post = [MPost MR_createEntity];
                     post.comment = [jPost objectForKey:@"comment"];
                     post.num = num;
                     post.parent = thread;
//                     [thread addPostsObject: post];
                 }
                 
                 [posts addObject:post];
                 
             }
             
             [self saveContext];
             successHandler(posts);
         }];
//        NSLog(@"AAAAAAAA %d", [result count]);
    }
    failureHandler:^(NSError *error)
    {
//        NSLog(@"AAAAAAAAerror %@", error.localizedDescription);
    }];
}

-(void)deleteAllBoardsForCategory:(MBoardCategory*)category
{
    for (MBoard *board in category.boards)
    {
        [self deleteAllThreadsForBoard:board];
        [board MR_deleteEntity];
    }
    
    [self saveContext];
}

-(void)deleteAllThreadsForBoard:(MBoard*)board
{
    for (MThread *thread in board.threads)
    {
        [self deleteAllPostsForThread:thread];
        [thread MR_deleteEntity];
    }
    
    [self saveContext];
}

-(void)deleteAllPostsForThread:(MThread*)thread
{
    for (MPost *post in thread.posts)
    {
        [post MR_deleteEntity];
    }
    
    [self saveContext];
}

-(void)makabaNeedsCloudflareVerification:(NSData *)data forURL:(NSURL *)url
{
    UIViewController *topVC = [self getTopMostViewController];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    
    if (self.cloudflareVC)
    {
        self.cloudflareVC.webView.delegate = nil;
        
        if (!self.cloudflareVC.dismissed)
        {
            [self.cloudflareVC dismissViewControllerAnimated:NO completion:^
             {
                 //
             }];
        }
        self.cloudflareVC = nil;
    }
    
    self.cloudflareVC = [storyboard instantiateViewControllerWithIdentifier:@"CloudflareViewController"];
    //            cfVC.modalPresentationStyle = UIModalPresentationFormSheet;
    //            cfVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    //            topVC = self.currentViewController;
    
    /*
     // to present semitransparent view
     if ([[UIDevice currentDevice] systemVersion].integerValue < 8)
     {
     // Before iOS 8, you do this:
     topVC.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
     }
     else
     {
     // in iOS 8, you have to do this:
     topVC.providesPresentationContextTransitionStyle = YES;
     topVC.definesPresentationContext = YES;
     [cfVC setModalPresentationStyle:UIModalPresentationOverCurrentContext];
     }
     NSLog(@">>%@", topVC.navigationController);
     */
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^
     {
         [topVC presentViewController:self.cloudflareVC animated:YES completion:^
         {
             self.cloudflareVC.webView.delegate = [Makaba shared];
             [self.cloudflareVC.webView loadData:data MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:url];
         }];
     }];
}

-(void)makabaDidFinishCloudflareVerification
{
    if (self.cloudflareVC)
    {
        self.cloudflareVC.webView.delegate = nil;
        
        [self.cloudflareVC dismissViewControllerAnimated:YES completion:^
        {
            //
        }];
        
        self.cloudflareVC = nil;
    }
}

#pragma mark - helper methods

- (void)saveContext
{
    //TODO: create context for non-main threads
    //https://github.com/magicalpanda/MagicalRecord/wiki/Working-with-Managed-Object-Contexts
//    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    
    /*
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error)
    {
        if (success)
        {
            NSLog(@"You successfully saved your context.");
        }
        else if (error)
        {
            NSLog(@"Error saving context: %@", error.description);
        }
    }];
     */
}

- (UIViewController*) getTopMostViewController
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(window in windows)
        {
            if (window.windowLevel == UIWindowLevelNormal)
            {
                break;
            }
        }
    }
    
    for (UIView *subView in [window subviews])
    {
        UIResponder *responder = [subView nextResponder];
        
        //added this block of code for iOS 8 which puts a UITransitionView in between the UIWindow and the UILayoutContainerView
        if ([responder isEqual:window])
        {
            //this is a UITransitionView
            if ([[subView subviews] count])
            {
                UIView *subSubView = [subView subviews][0]; //this should be the UILayoutContainerView
                responder = [subSubView nextResponder];
            }
        }
        
        if([responder isKindOfClass:[UIViewController class]])
        {
            return [self topViewController: (UIViewController *) responder];
        }
    }
    
    return nil;
}

- (UIViewController *) topViewController: (UIViewController *) controller
{
    BOOL isPresenting = NO;
    do {
        // this path is called only on iOS 6+, so -presentedViewController is fine here.
        UIViewController *presented = [controller presentedViewController];
        isPresenting = presented != nil;
        if(presented != nil) {
            controller = presented;
        }
        
    } while (isPresenting);
    
    return controller;
}


@end
