//
//  BoardsViewController.m
//  voroboosheque
//
//  Created by admin on 23/02/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import "BoardsViewController.h"
#import "MakabaDataManager.h"
#import "MBoard.h"
#import "MBoardCategory.h"
#import "ThreadsViewController.h"

@interface BoardsViewController ()

@property (nonatomic) NSArray* boards;
@property (nonatomic) NSArray* categories;

@end

@implementation BoardsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Boards";
    
    [[MakabaDataManager shared] setCurrentViewController:self];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
//    self.refreshControl.backgroundColor = [UIColor purpleColor];
//    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self
                            action:@selector(fetchTableData)
                  forControlEvents:UIControlEventValueChanged];

    self.boards = [[MakabaDataManager shared] getCachedBoards];
    self.categories = [[MakabaDataManager shared] getCachedCategories];
    [self reloadData];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewDidAppear:(BOOL)animated
{
    [self fetchTableData];
}

-(void)fetchTableData
{
    [[MakabaDataManager shared] getBoardsDataWithSuccessHandler:^(NSArray *categories, NSArray *boards)
     {
         self.categories = categories;
         self.boards = boards;
         [self reloadData];
         
         // End the refreshing
         if (self.refreshControl) {
             
             NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
             [formatter setDateFormat:@"MMM d, h:mm a"];
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


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    MBoardCategory *category = [self.categories objectAtIndex:section];
    return category.name;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return [self.categories count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    MBoardCategory *category = [self.categories objectAtIndex:section];
    return [category.boards count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"boardsViewCell" forIndexPath:indexPath];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"boardsViewCell"];
    }
    
//    MBoard *board = [self.boards objectAtIndex:indexPath.row];
    MBoardCategory *category = [self.categories objectAtIndex:indexPath.section];
    
    NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    NSArray *sortedBoards = [category.boards sortedArrayUsingDescriptors:[NSArray arrayWithObject:nameDescriptor]];
    
    MBoard *board = [sortedBoards objectAtIndex:indexPath.row];

    cell.textLabel.text = board.id;
    cell.detailTextLabel.text = board.name;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
    ThreadsViewController *threadsVC = [storyboard instantiateViewControllerWithIdentifier:@"ThreadsViewController"];
    
    MBoardCategory *category = [self.categories objectAtIndex:indexPath.section];
    NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    NSArray *sortedBoards = [category.boards sortedArrayUsingDescriptors:[NSArray arrayWithObject:nameDescriptor]];
    
    threadsVC.board = [sortedBoards objectAtIndex:indexPath.row];

    [self.navigationController pushViewController:threadsVC animated:YES];
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
