//
//  TermAppDelegate.h
//  Term
//
//  Created by Oliver VieBrooks on 8/24/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SecondView.h"

@class GLView;

@interface TermAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    SecondView *secondview;
}
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SecondView *secondview;

@end
