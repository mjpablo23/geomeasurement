//
//  CustomCell.m
//  GeoIntMeasure
//
//  Created by Paul Yang on 9/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CustomCell.h"


@implementation CustomCell

@synthesize primaryLabel,secondaryLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        primaryLabel = [[UILabel alloc]init];
        primaryLabel.textAlignment = UITextAlignmentLeft;
        primaryLabel.font = [UIFont systemFontOfSize:15];
        [primaryLabel setBackgroundColor:[UIColor clearColor]];
        secondaryLabel = [[UILabel alloc]init];
        secondaryLabel.textAlignment = UITextAlignmentLeft;
        secondaryLabel.font = [UIFont systemFontOfSize:12];
        [secondaryLabel setBackgroundColor:[UIColor clearColor]];
        [self.contentView addSubview:primaryLabel];
        [self.contentView addSubview:secondaryLabel];
        //[self.contentView setBackgroundColor:[UIColor clearColor]];
        
        primaryLabel.textColor = [UIColor blueColor];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect contentRect = self.contentView.bounds;
    CGFloat boundsX = contentRect.origin.x;
    CGRect frame;
    
    // frame= CGRectMake(boundsX+10 ,0, 50, 50);
    //    myImageView.frame = frame;
    
    frame= CGRectMake(boundsX+5 ,0, 310, 20);
    primaryLabel.frame = frame;
    
    frame= CGRectMake(boundsX+5 ,20, 310, 20);
    secondaryLabel.frame = frame;

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)dealloc
{
    [primaryLabel release];
    [secondaryLabel release];
    [super dealloc];
}

@end
