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
    return [MBoardCategory MR_findAll];
}

-(NSArray *)getCachedBoards
{
    return [MBoard MR_findAll];
}

-(void)getBoardsDataWithSuccessHandler:(void (^)(NSArray *, NSArray *))successHandler
                        failureHandler:(makabaDataReturnBlockWithError)failureHandler
{
    
    /*
    [[Makaba shared] getThreadsForBoard:@"vg" successHandler:^(NSArray *result) {
        //
    } failureHandler:^(NSError *error) {
        //
    }];
     */
    
    if (successHandler)
    {
        [[Makaba shared] getBoardsWithSuccessHandler:^(NSDictionary *result)
        {
            NSMutableArray *boards = [NSMutableArray array];
            NSMutableArray *categories = [NSMutableArray array];
            
//            [MBoard MR_deleteAllMatchingPredicate: [NSPredicate predicateWithValue:YES]];
//            [MBoardCategory MR_deleteAllMatchingPredicate: [NSPredicate predicateWithValue:YES]];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^
            {
                //TODO: delete boards and categories which are not present in json
                for (NSString *jCategory in result)
                {
                    //TODO: check if category with that id is unique
                    MBoardCategory *category = [[MBoardCategory MR_findByAttribute:@"name" withValue:jCategory] lastObject];
                    
                    if (!category)
                    {
                        category = [MBoardCategory MR_createEntity];
                    }
                    
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
                            [board MR_deleteEntity];
                            //TODO: remove all associated threads and posts
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
            
            for (id jThread in result)
            {
                id jOPPost = [[jThread objectForKey:@"posts"] firstObject];
                
                NSNumber *num = [NSNumber numberWithInt:[[jOPPost objectForKey:@"num"] intValue]];
                
                MThread *thread = [[MThread MR_findByAttribute:@"num" withValue:num] lastObject];
                
                if (!thread)
                {
                    thread = [MThread MR_createEntity];
                }
                
                [threads addObject:thread];
                
                thread.num = num;
                
                MPost *post = [[MPost MR_findByAttribute:@"num" withValue:num] lastObject];
                
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
