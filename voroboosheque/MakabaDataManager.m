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

-(NSArray *)getCachedBoards
{
    return [MBoard MR_findAll];
}

-(void)getBoardsDataWithSuccessHandler:(makabaDataReturnBlockWithArray)successHandler failureHandler:(makabaDataReturnBlockWithError)failureHandler
{
    if (successHandler)
    {
        
        NSArray *oldBoards = [MBoard MR_findAll];
//        NSArray *oldCategories = [MBoardCategory MR_findAll];
        
        if (oldBoards)
        {
//             successHandler(oldBoards);
        }

        [[Makaba shared] getBoardsWithSuccessHandler:^(NSDictionary *result)
        {
            NSMutableArray *boards = [NSMutableArray array];
            
            [MBoard MR_deleteAllMatchingPredicate: [NSPredicate predicateWithValue:YES]];
            [MBoardCategory MR_deleteAllMatchingPredicate: [NSPredicate predicateWithValue:YES]];
            
            for (NSString *jCategory in result)
            {
//                MBoard *board = [MBoard MR_createEntity];
//                board.name = [jsonBoard objectForKey:@"name"];
                
                MBoardCategory *category = [MBoardCategory MR_createEntity];
                category.name = jCategory;
//                NSLog(@"%@ ", category);
//
                for (id jBoard in [result objectForKey:jCategory])
                {
                    MBoard *board = [MBoard MR_createEntity];
                    
                    board.name = [jBoard objectForKey:@"name"];
                    board.bumpLimit = [jBoard objectForKey:@"bump_limit"];
                    board.defaultName = [jBoard objectForKey:@"default_name"];
                    board.enablePosting = [jBoard objectForKey:@"enable_posting"];
                    board.id = [jBoard objectForKey:@"id"];
                    board.pages = [jBoard objectForKey:@"pages"];
                    board.sage = [jBoard objectForKey:@"sage"];
                    board.tripcodes = [jBoard objectForKey:@"tripcodes"];
                    board.category = category;
                    
                    [category addBoardsObject:board];
//                    board.defaultName = [jBoard objectForKey:@"def"];
//                    NSLog(@"%@ ", board);
                    [boards addObject:board];
                }
            }
            
            [self saveContext];
            successHandler(boards);
        }
        failureHandler:^(NSError *error)
        {


        }];
    }
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
