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
                    /*
                    post.attributedComment = [[NSAttributedString alloc] initWithData:[post.comment dataUsingEncoding:NSUTF8StringEncoding]
                                                                              options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                        NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                   documentAttributes:nil error:nil];
                     */
                    post.attributedComment = [self attributedCommentWithComment:post.comment];
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
//    NSLog(@"+++++++++++  %d", [[MPost MR_findAll] count]);
    
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
                     /*
                     post.attributedComment = [[NSAttributedString alloc] initWithData:[post.comment dataUsingEncoding:NSUTF8StringEncoding]
                                                                               options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                         NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                    documentAttributes:nil error:nil];
                      */
                     post.attributedComment = [self attributedCommentWithComment:post.comment];
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


//https://github.com/alextewpin/tabula/blob/master/m2ch/Post.m
- (NSAttributedString *)attributedCommentWithComment:(NSString *)comment
{
    float fontSize = 15.0;
    
    //чистка исходника и посильная замена хтмл-литералов
    comment = [comment stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    //comment = [comment stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#44;" withString:@","];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#47;" withString:@"/"];
    comment = [comment stringByReplacingOccurrencesOfString:@"&#92;" withString:@"\\"];
    
    NSRange range = NSMakeRange(0, comment.length);
    
    NSMutableAttributedString *maComment = [[NSMutableAttributedString alloc]initWithString:comment];
    [maComment addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"TrebuchetMS" size:fontSize] range:range];
    
    NSMutableParagraphStyle *commentStyle = [[NSMutableParagraphStyle alloc]init];
    //    commentStyle.lineSpacing = kCommentLineSpacing;
    [maComment addAttribute:NSParagraphStyleAttributeName value:commentStyle range:range];
    
    //em
    UIFont *emFont = [UIFont fontWithName:@"TrebuchetMS-Italic" size:fontSize];
    NSMutableArray *emRangeArray = [NSMutableArray array];
    NSRegularExpression *em = [[NSRegularExpression alloc]initWithPattern:@"<em[^>]*>(.*?)</em>" options:0 error:nil];
    [em enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSFontAttributeName value:emFont range:result.range];
        NSValue *value = [NSValue valueWithRange:result.range];
        [emRangeArray addObject:value];
    }];
    
    //strong
    UIFont *strongFont = [UIFont fontWithName:@"TrebuchetMS-Bold" size:fontSize];
    NSMutableArray *strongRangeArray = [NSMutableArray array];
    NSRegularExpression *strong = [[NSRegularExpression alloc]initWithPattern:@"<strong[^>]*>(.*?)</strong>" options:0 error:nil];
    [strong enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSFontAttributeName value:strongFont range:result.range];
        NSValue *value = [NSValue valueWithRange:result.range];
        [strongRangeArray addObject:value];
    }];
    
    //emstrong
    UIFont *emStrongFont = [UIFont fontWithName:@"Trebuchet-BoldItalic" size:fontSize];
    for (NSValue *emRangeValue in emRangeArray) {
        //value to range
        NSRange emRange = [emRangeValue rangeValue];
        for (NSValue *strongRangeValue in strongRangeArray) {
            NSRange strongRange = [strongRangeValue rangeValue];
            NSRange emStrongRange = NSIntersectionRange(emRange, strongRange);
            if (emStrongRange.length != 0) {
                [maComment addAttribute:NSFontAttributeName value:emStrongFont range:emStrongRange];
            }
        }
    }
    
    //strike
    //не будет работать с tttattributedlabel, нужно переделывать ссылки и все такое
    NSRegularExpression *strike = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"s\">(.*?)</span>" options:0 error:nil];
    [strike enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:result.range];
    }];
    
    //spoiler
    UIColor *spoilerColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    NSRegularExpression *spoiler = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"spoiler\">(.*?)</span>" options:0 error:nil];
    [spoiler enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSForegroundColorAttributeName value:spoilerColor range:result.range];
    }];
    
    //quote
    UIColor *quoteColor = [UIColor colorWithRed:(17/255.0) green:(139/255.0) blue:(116/255.0) alpha:1.0];
    NSRegularExpression *quote = [[NSRegularExpression alloc]initWithPattern:@"<span class=\"unkfunc\">(.*?)</span>" options:0 error:nil];
    [quote enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        [maComment addAttribute:NSForegroundColorAttributeName value:quoteColor range:result.range];
    }];
    
    //link
    UIColor *linkColor = [UIColor colorWithRed:(255/255.0) green:(102/255.0) blue:(0/255.0) alpha:1.0];
    NSRegularExpression *link = [[NSRegularExpression alloc]initWithPattern:@"<a[^>]*>(.*?)</a>" options:0 error:nil];
    NSRegularExpression *linkLink = [[NSRegularExpression alloc]initWithPattern:@"href=\"(.*?)\"" options:0 error:nil];
    NSRegularExpression *linkLinkTwo = [[NSRegularExpression alloc]initWithPattern:@"href='(.*?)'" options:0 error:nil];
    
    [link enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, __unused NSMatchingFlags flags, __unused BOOL *stop) {
        NSString *fullLink = [comment substringWithRange:result.range];
        NSTextCheckingResult *linkLinkResult = [linkLink firstMatchInString:fullLink options:0 range:NSMakeRange(0, fullLink.length)];
        NSTextCheckingResult *linkLinkTwoResult = [linkLinkTwo firstMatchInString:fullLink options:0 range:NSMakeRange(0, fullLink.length)];
        
        NSRange urlRange = NSMakeRange(0, 0);
        
        if (linkLinkResult.numberOfRanges != 0) {
            urlRange = NSMakeRange(linkLinkResult.range.location+6, linkLinkResult.range.length-7);
        } else if (linkLinkResult.numberOfRanges != 0) {
            urlRange = NSMakeRange(linkLinkTwoResult.range.location+6, linkLinkTwoResult.range.length-7);
        }
        
        if (urlRange.length != 0) {
            NSString *urlString = [fullLink substringWithRange:urlRange];
            urlString = [urlString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
            NSURL *url = [[NSURL alloc]initWithString:urlString];
            if (url) {
                //                UrlNinja *un = [UrlNinja unWithUrl:url];
                //                if ([un.boardId isEqualToString:self.boardId] && [un.threadId isEqualToString:self.threadId] && un.type == boardThreadPostLink) {
                //                    if (![self.replyTo containsObject:un.postId]) {
                //                        [self.replyTo addObject:un.postId];
                //                    }
                //                }
                [maComment addAttribute:NSLinkAttributeName value:url range:result.range];
                [maComment addAttribute:NSForegroundColorAttributeName value:linkColor range:result.range];
                [maComment addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleNone] range:result.range];
            }
        }
    }];
    
    //находим все теги и сохраняем в массив
    NSMutableArray *tagArray = [NSMutableArray array];
    NSRegularExpression *tag = [[NSRegularExpression alloc]initWithPattern:@"<[^>]*>" options:0 error:nil];
    [tag enumerateMatchesInString:comment options:0 range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSValue *value = [NSValue valueWithRange:result.range];
        [tagArray addObject:value];
    }];
    
    //вырезательный цикл
    int shift = 0;
    for (NSValue *rangeValue in tagArray) {
        NSRange cutRange = [rangeValue rangeValue];
        cutRange.location -= shift;
        [maComment deleteCharactersInRange:cutRange];
        shift += cutRange.length;
    }
    
    //чистим переводы строк в начале и конце
    NSRegularExpression *whitespaceStart = [[NSRegularExpression alloc]initWithPattern:@"^\\s\\s*" options:0 error:nil];
    NSTextCheckingResult *wsResult = [whitespaceStart firstMatchInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length])];
    [maComment deleteCharactersInRange:wsResult.range];
    
    NSRegularExpression *whitespaceEnd = [[NSRegularExpression alloc]initWithPattern:@"\\s\\s*$" options:0 error:nil];
    NSTextCheckingResult *weResult = [whitespaceEnd firstMatchInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length])];
    [maComment deleteCharactersInRange:weResult.range];
    
    //и пробелы в начале каждой строки
    NSMutableArray *whitespaceLineStartArray = [NSMutableArray array];
    NSRegularExpression *whitespaceLineStart = [[NSRegularExpression alloc]initWithPattern:@"^[\\t\\f\\p{Z}]+" options:NSRegularExpressionAnchorsMatchLines error:nil];
    [whitespaceLineStart enumerateMatchesInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSValue *value = [NSValue valueWithRange:result.range];
        [whitespaceLineStartArray addObject:value];
    }];
    
    int whitespaceLineStartShift = 0;
    for (NSValue *rangeValue in whitespaceLineStartArray) {
        NSRange cutRange = [rangeValue rangeValue];
        cutRange.location -= whitespaceLineStartShift;
        [maComment deleteCharactersInRange:cutRange];
        whitespaceLineStartShift += cutRange.length;
    }
    
    //и двойные переводы
    NSMutableArray *whitespaceDoubleArray = [NSMutableArray array];
    NSRegularExpression *whitespaceDouble = [[NSRegularExpression alloc]initWithPattern:@"[\\n\\r]{3,}" options:0 error:nil];
    [whitespaceDouble enumerateMatchesInString:[maComment string] options:0 range:NSMakeRange(0, [maComment length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSValue *value = [NSValue valueWithRange:result.range];
        [whitespaceDoubleArray addObject:value];
    }];
    
    int whitespaceDoubleShift = 0;
    for (NSValue *rangeValue in whitespaceDoubleArray) {
        NSRange cutRange = [rangeValue rangeValue];
        cutRange.location -= whitespaceDoubleShift;
        [maComment deleteCharactersInRange:cutRange];
        [maComment insertAttributedString:[[NSAttributedString alloc]initWithString:@"\n\n" attributes:nil] atIndex:cutRange.location];
        whitespaceDoubleShift += cutRange.length - 2;
    }
    
    //добавляем заголовок поста, если он есть
    /*
     if (self.subject && ![self.subject isEqualToString:@""])
     {
     
     self.subject = [self.subject stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
     self.subject = [self.subject stringByReplacingOccurrencesOfString:@"&#44;" withString:@","];
     
     NSMutableAttributedString *maSubject = [[NSMutableAttributedString alloc]initWithString:[self.subject stringByAppendingString:@"\n"]];
     [maSubject addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0] range:NSMakeRange(0, maSubject.length)];
     [maSubject addAttribute:NSParagraphStyleAttributeName value:commentStyle range:NSMakeRange(0, maSubject.length)];
     
     [maComment insertAttributedString:maSubject atIndex:0];
     }
     */
    
    //заменить хтмл-литералы на нормальные символы (раньше этого делать нельзя, сломается парсинг)
    [[maComment mutableString] replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    [[maComment mutableString] replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    [[maComment mutableString] replaceOccurrencesOfString:@"&quot;" withString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    [[maComment mutableString] replaceOccurrencesOfString:@"&amp;" withString:@"&" options:NSCaseInsensitiveSearch range:NSMakeRange(0, maComment.string.length)];
    
    return maComment;
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
