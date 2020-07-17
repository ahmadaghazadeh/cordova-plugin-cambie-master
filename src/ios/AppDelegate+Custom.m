//
//  AppDelegate+Custom.m
//  Sleep Guru
//
//  Created by Alex Kyriazis on 2015-01-13.
//
//

#import "MMDrawerViewController.h"
#import "CambieViewController.h"
#import "MMDrawerVisualStateManager.h"
#import "AppDelegate+Custom.h"
#import "MainViewController.h"
#import <objc/runtime.h>

static char const * const drawerControllerKey = "DrawerControllerKey";

@implementation AppDelegate (Custom)

static BOOL OSVersionIsAtLeastiOS7() {
    return (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1);
}

//this overrides the didFinishLaunchingWithOptions in Appdelegate. It includes everything thats in there
//in addition to drawer functionality
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    
    
    #if __has_feature(objc_arc)
        CDVViewController * center = [[MainViewController alloc] init];
    #else
        CDVViewController * center = [[[MainViewController alloc] init] autorelease];
    #endif
    
    self.viewController = center;
    
    
        //if state restoration is supported
        
    self.drawerController = [[CambieViewController alloc]
                                 initWithCenterViewController:center];
        
    [self.drawerController setShowsShadow:NO];

    [self.drawerController setMaximumLeftDrawerWidth:200.0];

    [[MMDrawerVisualStateManager sharedManager] setLeftDrawerAnimationType:MMDrawerAnimationTypeNone];
    [self.drawerController setShouldStretchDrawer:false];
    [self.drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeNone];
    [self.drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
    [self.drawerController setCenterHiddenInteractionMode:MMDrawerOpenCenterInteractionModeNone];

    //animations
    [self.drawerController setDrawerVisualStateBlock:^(CambieViewController *drawerController, MMDrawerSide drawerSide, CGFloat percentVisible) {
        MMDrawerControllerDrawerVisualStateBlock block;
        block = [[MMDrawerVisualStateManager sharedManager]
                 drawerVisualStateBlockForDrawerSide:drawerSide];
        if(block){
            block(drawerController, drawerSide, percentVisible);
        }
    }];
    
    //because for some reason, the drawer puts a default nav bar on the center view, which blocks the cambie one.
    [[center navigationController] setNavigationBarHidden:TRUE];
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    #if __has_feature(objc_arc)
        self.window = [[UIWindow alloc] initWithFrame:screenBounds];
    #else
        self.window = [[[UIWindow alloc] initWithFrame:screenBounds] autorelease];

    #endif
        self.window.autoresizesSubviews = YES;
    
    if(OSVersionIsAtLeastiOS7()){
        UIColor * tintColor = [UIColor colorWithRed:29.0/255.0
                                              green:173.0/255.0
                                               blue:234.0/255.0
                                              alpha:1.0];
        [self.window setTintColor:tintColor];
    }
    
    // Set your app's start page by setting the <content src='foo.html' /> tag in config.xml.
    // If necessary, uncomment the line below to override it.
    // self.viewController.startPage = @"index.html";
    
    // NOTE: To customize the view's frame size (which defaults to full screen), override
    // [self.viewController viewWillAppear:] in your view controller.
    
    self.window.rootViewController = self.drawerController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (CambieViewController *)drawerController {
    return objc_getAssociatedObject(self, drawerControllerKey);
}
- (void)setDrawerController:(CambieViewController *)newController {
    objc_setAssociatedObject(self, drawerControllerKey, newController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//UINavigationBar

@end
