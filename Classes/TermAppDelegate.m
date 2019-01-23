//
//  TermAppDelegate.m
//  Term
//
//  Created by Oliver VieBrooks on 8/24/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "TermAppDelegate.h"


@implementation TermAppDelegate

@synthesize window;
@synthesize secondview;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
[[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];
    // Add the tab bar controller's current view as a subview of the window
    [window addSubview:secondview.view];
}


/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
}
*/

/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}
*/


- (void)dealloc {
//    [tabBarController release];
    [window release];
    [super dealloc];
}

@end

