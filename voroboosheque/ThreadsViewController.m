//
//  ThreadsViewController.m
//  voroboosheque
//
//  Created by admin on 25/02/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import "ThreadsViewController.h"
#import "MBoard.h"
#import "MThread.h"
#import "MPost.h"
#import "MakabaDataManager.h"
#import "PostsViewController.h"

@interface ThreadsViewController ()

@property (nonatomic) NSArray *threads;

@end

@implementation ThreadsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = [NSString stringWithFormat:@"/%@/", self.board.id];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    //    self.refreshControl.backgroundColor = [UIColor purpleColor];
    //    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(fetchThreads)
                  forControlEvents:UIControlEventValueChanged];
    
    self.threads = [[MakabaDataManager shared] getCahcedThreadsForBoard:self.board];
    [self reloadData];
    
    [self fetchThreads];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [self fetchThreads];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];
}

-(void)fetchThreads
{
    [[MakabaDataManager shared] getThreadsDataForBoard:self.board successHandler:^(NSArray *threads)
    {
        self.threads = threads;
        [self reloadData];
        
        // End the refreshing
        if (self.refreshControl) {
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MMM d, h:mm:ss a"];
            NSString *title = [NSString stringWithFormat:@"Last update: %@", [formatter stringFromDate:[NSDate date]]];
            NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor grayColor]
                                                                        forKey:NSForegroundColorAttributeName];
            NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
            self.refreshControl.attributedTitle = attributedTitle;
            
            [self.refreshControl endRefreshing];
        }
    }
    failureHandler:^(NSError *error)
    {
        //
    }];
}

-(void)reloadData
{
    [self.tableView reloadData];
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
    return [self.threads count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ThreadsViewCell" forIndexPath:indexPath];

    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"ThreadsViewCell"];
    }
    
    MThread *thread = [self.threads objectAtIndex:indexPath.row];
    MPost *OPPost = [thread.posts firstObject];
    
    cell.textLabel.text = OPPost.comment;
//    cell.detailTextLabel.text = board.name;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    PostsViewController *postsVC = [storyboard instantiateViewControllerWithIdentifier:@"PostsViewController"];
    postsVC.thread = [self.threads objectAtIndex:indexPath.row];
    
    [self.navigationController pushViewController:postsVC animated:YES];
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
