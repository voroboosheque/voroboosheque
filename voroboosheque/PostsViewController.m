//
//  PostsViewController.m
//  voroboosheque
//
//  Created by admin on 27/02/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import "PostsViewController.h"
#import "MakabaDataManager.h"
#import "MPost.h"
#import "MBoard.h"
#import "MThread.h"
#import <CCBottomRefreshControl/UIScrollView+BottomRefreshControl.h>
#import "PostsViewCell.h"

@interface PostsViewController ()
{

}

@property (nonatomic) NSMutableArray *posts;
@property (nonatomic) NSMutableArray *postsHeights;
@property (nonatomic) PostsViewCell *offscreenCell;

@end

@implementation PostsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 256.0;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    //    self.refreshControl.backgroundColor = [UIColor purpleColor];
    //    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(fetchPosts)
                  forControlEvents:UIControlEventValueChanged];
    
    UIRefreshControl *bottomRefreshControl = [[UIRefreshControl alloc] init];
    [bottomRefreshControl addTarget:self
                             action:@selector(fetchNewPosts) forControlEvents:UIControlEventValueChanged];
    self.tableView.bottomRefreshControl = bottomRefreshControl;
    
    self.posts = [NSMutableArray arrayWithArray:[[MakabaDataManager shared] getCachedPostsForThread:self.thread]] ;
    self.postsHeights = [NSMutableArray array];
//    [self calculateHeights];
    
    [self reloadData];
    
    [self fetchNewPosts];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)reloadData
{
    [self.tableView reloadData];
}

-(void)endRefreshingWithNewItems:(NSUInteger)newItems
{
    // End the refreshing
    if (self.refreshControl)
    {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMM d, h:mm:ss a"];
//        NSString *title = [NSString stringWithFormat:@"Last update: %@, %d new posts", [formatter stringFromDate:[NSDate date]], newItems];
        NSString *title = [NSString stringWithFormat:@"%d new posts, %d total", newItems, self.posts.count];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor grayColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        self.refreshControl.attributedTitle = attributedTitle;
        
        [self.refreshControl endRefreshing];
    }
    
    if (self.tableView.bottomRefreshControl)
    {
        NSString *title = [NSString stringWithFormat:@"%d new posts, %d total", newItems, self.posts.count];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor grayColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        self.tableView.bottomRefreshControl.attributedTitle = attributedTitle;
        
        [self.tableView.bottomRefreshControl endRefreshing];
    }
}

-(void)fetchNewPosts
{
    [[MakabaDataManager shared] getPostsForThread:self.thread
                             startingFromPosition:[self.posts count]+1
                                   successHandler:^(NSArray *posts)
    {
        if ([posts count])
        {
            NSMutableArray *indexPaths = [NSMutableArray array];
            
            for (id post in posts)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.posts.count + [posts indexOfObject:post] inSection:0];
                [indexPaths addObject:indexPath];
            }
            
            [self.posts addObjectsFromArray:posts];
//            NSLog(@">>>azzzzaa start");
//            [self calculateHeights];
//            NSLog(@">>>azzzzaa end");
            
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation: UITableViewRowAnimationBottom];
            [self.tableView endUpdates];
            
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.posts.count - posts.count inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }

//        [self reloadData];
        
        [self endRefreshingWithNewItems:posts.count];
    }
    failureHandler:^(NSError *error)
    {
        //
    }];
}

-(void)fetchPosts
{
    [[MakabaDataManager shared] getPostsForThread:self.thread
                             startingFromPosition:0 successHandler:^(NSArray *posts)
     {
         NSUInteger newItems = posts.count - self.posts.count;
         self.posts = [NSMutableArray arrayWithArray:posts];
         [self reloadData];
         
         [self endRefreshingWithNewItems:newItems];

     }
                                   failureHandler:^(NSError *error)
     {
         
     }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.posts count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    PostsViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PostsViewCell" forIndexPath:indexPath];
    
    if (cell == nil)
    {
        cell = [[PostsViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"PostsViewCell"];
    }
    
    [self configureCell:cell forTableView:tableView atIndexPath:indexPath];
    
//    cell.commentLabel.preferredMaxLayoutWidth = CGRectGetWidth(tableView.bounds);
    
    return cell;
}

-(void)configureCell:(PostsViewCell*)cell forTableView:(UITableView*)tableView atIndexPath:(NSIndexPath *)indexPath
{
    MPost *post = [self.posts objectAtIndex:indexPath.row];
    //    cell.commentLabel.text = post.comment;
    cell.commentTextView.attributedText = post.attributedComment;
//    "▲▼"
 
//    cell.commentTextView.font = [UIFont fontWithName:@"TrebuchetMS" size:16.0];
    
    if (indexPath.row%2)
    {
        [cell setBackgroundColor:[UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0]];
    }
    else
    {
        [cell setBackgroundColor:[UIColor colorWithRed:242.0/255.0 green:242.0/255.0 blue:242.0/255.0 alpha:1.0]];
    }
    
//    [cell setNeedsUpdateConstraints];
//    [cell updateConstraintsIfNeeded];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //TODO: implement faster method
    if (self.postsHeights.count>indexPath.row)
    {
        return [[self.postsHeights objectAtIndex:indexPath.row] floatValue];
    }
    else
    {
        MPost *post = [self.posts objectAtIndex:indexPath.row];
        
        PostsViewCell *cell = self.offscreenCell;
        
        if (!cell)
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"PostsViewCell"];
            self.offscreenCell = cell;
        }
        
        [self configureCell:cell forTableView:self.tableView atIndexPath:[NSIndexPath indexPathForRow:[self.posts indexOfObject:post] inSection:0]];
        
        cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.bounds), CGRectGetHeight(cell.bounds));
        
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        
        //    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingExpandedSize].height;
        height = [cell.commentTextView sizeThatFits:CGSizeMake(cell.bounds.size.width, 500)].height;
        height += 16.0;
        
        height += 1.0f;
        
        [self.postsHeights addObject: [NSNumber numberWithFloat:height]];
        
        return height;
    }
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.postsHeights.count>indexPath.row)
    {
        return [[self.postsHeights objectAtIndex:indexPath.row] floatValue];
    }
    else
    {
        return 256.0;
    }
}

@end
