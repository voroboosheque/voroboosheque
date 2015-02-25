//
//  CloudflareViewController.m
//  voroboosheque
//
//  Created by admin on 24/02/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import "CloudflareViewController.h"

@interface CloudflareViewController ()

@end

@implementation CloudflareViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dismissed = NO;
    
}
- (IBAction)cancelBtnTapped:(id)sender
{
    self.dismissed = YES;
    [self dismissViewControllerAnimated:YES completion:^
    {
        //
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
