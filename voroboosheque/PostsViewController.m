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

@interface PostsViewController ()

@property (nonatomic) NSMutableArray *posts;

@end

@implementation PostsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    //    self.refreshControl.backgroundColor = [UIColor purpleColor];
    //    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(fetchPosts)
                  forControlEvents:UIControlEventValueChanged];
    
    self.posts = [NSMutableArray arrayWithArray:[[MakabaDataManager shared] getCachedPostsForThread:self.thread]] ;

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
        NSString *title = [NSString stringWithFormat:@"%d new posts, %d total", newItems, self.posts.count-1];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor grayColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        self.refreshControl.attributedTitle = attributedTitle;
        
        [self.refreshControl endRefreshing];
    }
}

-(void)fetchNewPosts
{
    [[MakabaDataManager shared] getPostsForThread:self.thread
                             startingFromPosition:[self.posts count]+1
                                   successHandler:^(NSArray *posts)
    {
        [self.posts addObjectsFromArray:posts];
        [self reloadData];
        
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return [self.posts count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PostsViewCell" forIndexPath:indexPath];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"PostsViewCell"];
    }
    
    MPost *post = [self.posts objectAtIndex:indexPath.row];
    
    cell.textLabel.text = post.comment;
    //    cell.detailTextLabel.text = board.name;
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
