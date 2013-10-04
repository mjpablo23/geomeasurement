//
//  LicenseView.h
//  GeoIntMeasure
//
//  Created by Paul Yang on 10/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LicenseDelegate;

@interface LicenseView : UIViewController {
    int showingPrivacy;
    id <LicenseDelegate> delegate;
}

@property (nonatomic, assign) id delegate;

@property (nonatomic, retain) IBOutlet UITextView *textView; // not used (hidden)
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIButton *button;
@property (nonatomic, retain) IBOutlet UIButton *privacyButton;

-(IBAction) buttonPressed:(id) sender;
-(IBAction) privacyButtonPressed:(id)sender;

@end

@protocol LicenseDelegate <NSObject>

-(void) presentInstructionsView;
-(void) testPrint:(int)val;

@end