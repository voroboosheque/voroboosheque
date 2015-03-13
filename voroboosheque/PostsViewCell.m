//
//  PostsViewCell.m
//  voroboosheque
//
//  Created by admin on 06/03/15.
//  Copyright (c) 2015 voroboosheque. All rights reserved.
//

#import "PostsViewCell.h"

@implementation PostsViewCell

- (void)awakeFromNib
{
//    self.commentLabel.lineBreakMode = NSLineBreakByWordWrapping;
//    [self setBackgroundColor:[UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0]];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

/*
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Make sure the contentView does a layout pass here so that its subviews have their frames set, which we
    // need to use to set the preferredMaxLayoutWidth below.
    [self.contentView setNeedsLayout];
    [self.contentView layoutIfNeeded];
    
    // Set the preferredMaxLayoutWidth of the mutli-line bodyLabel based on the evaluated width of the label's frame,
    // as this will allow the text to wrap correctly, and as a result allow the label to take on the correct height.
//    self.commentTextView.preferredMaxLayoutWidth = CGRectGetWidth(self.commentTextView.frame);
}
 */

@end
