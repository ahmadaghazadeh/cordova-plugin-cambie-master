/**
 * Copyright (c) 2015 Darryl Pogue
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

#import "CambieNavigationBar.h"
#import "UIView+CambieLayout.h"
#import "AppDelegate+Custom.h"

#import <Cordova/CDVAvailability.h>

@interface CambieNavigationBar () <UINavigationBarDelegate> {
    BOOL _popFromWeb;
    BOOL _popFromNav;
    BOOL _pendingPop;
}

- (BOOL) navigationBar:(UINavigationBar*)navigationBar shouldPopItem:(UINavigationItem*)item;
- (void) navigationBar:(UINavigationBar*)navigationBar didPopItem:(UINavigationItem*)item;
@end

@interface CambieNavigationBar (DrawerIcon)

+ (UIImage*) drawerButtonItemImage;

@end

@implementation CambieNavigationBar

@synthesize delegate;

- (id) initWithViewController:(UIView*)content navType:(NSString *)nav
{
    if (![super init]) {
        return self;
    }

    BOOL isiOS7 = (IsAtLeastiOSVersion(@"7.0"));

    CGFloat toolBarHeight = 44.0f;

    CGRect statusBarBounds = [[UIApplication sharedApplication] statusBarFrame];

    if (isiOS7) {
        // Add status bar height
        toolBarHeight += statusBarBounds.size.height;
    }

    CGRect toolBarFrame = [[UIScreen mainScreen] bounds];
    toolBarFrame.size.height = toolBarHeight;

    _stack = [NSMutableArray array];
    [_stack addObject:@""];

    if ([nav isKindOfClass:[NSNull class]]) {
        _navType = @"tabs";
    } else {
        _navType = [nav lowercaseString];
    }

    _actions = [NSMutableArray array];
    _toolbarCallbacks = [NSMutableArray array];

    _popFromNav = NO;
    _popFromWeb = NO;
    _pendingPop = NO;

    _navEnabled = YES;
    _navbarEnabled = YES;
    _isOverlaying = NO;

    _content = content;

    _statBar = [[UIView alloc] initWithFrame:statusBarBounds];
    _statBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin);
    _statBar.autoresizesSubviews = YES;

    _toolBar = [[UINavigationBar alloc] initWithFrame:toolBarFrame];
    _toolBar.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin);
    _toolBar.autoresizesSubviews = YES;
    _toolBar.delegate = self;

    if (isiOS7) {
        _backButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    } else {
        _backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    }

    _drawerButton = [[UIBarButtonItem alloc] initWithImage:[self.class drawerButtonItemImage]
                                                             style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(navigationDrawerToggle)];

    return self;
}


- (void) updateNativeUIComponents
{
    if (!_navbarEnabled && [_content hasSiblingView:_toolBar]) {
        [_content removeSiblingView:_toolBar withAnimation:YES];

        CGRect frame = _content.frame;
        frame.origin.y = 0;
        frame.size.height += _toolBar.frame.size.height;
        _content.frame = frame;
    } else if (_navbarEnabled && [_content hasSiblingView:_statBar]) {
        [_content removeSiblingView:_statBar withAnimation:YES];

        CGRect frame = _content.frame;
        frame.origin.y = 0;
        frame.size.height += _statBar.frame.size.height;
        _content.frame = frame;
    }

    // If we're switching from overlay to non-overlay
    if (_navbarEnabled && [_content hasSiblingView:_toolBar] && _isOverlaying && !self.overlayWebView) {
        [_content removeSiblingView:_toolBar withAnimation:YES];

        CGRect frame = _content.frame;
        frame.origin.y = 0;
        frame.size.height += _toolBar.frame.size.height;
    }


    BOOL isiOS7 = (IsAtLeastiOSVersion(@"7.0"));

    if (self.overlayWebView)
    {
        if (_navbarEnabled && ![_content hasSiblingView:_toolBar]) {
            [_content addSiblingView:_toolBar withPosition:CambieLayoutPositionTopOverlay withAnimation:YES];
        }
        // No statusbar in overlay mode if no NavigationBar
        _isOverlaying = YES;
    }
    else
    {
        if (_navbarEnabled && ![_content hasSiblingView:_toolBar]) {
            [_content addSiblingView:_toolBar withPosition:CambieLayoutPositionTop withAnimation:YES];
        } else if (!_navbarEnabled && isiOS7 && ![_content hasSiblingView:_statBar]) {
            [_content addSiblingView:_statBar withPosition:CambieLayoutPositionTop withAnimation:YES];
        }

        _isOverlaying = NO;
    }

    if ([_actions count] > 0) {
        [_toolBar.topItem setRightBarButtonItems:_actions animated:YES];
    } else {
        [_toolBar.topItem setRightBarButtonItems:nil animated:NO];
    }
}

- (void) hide
{
    [self hideDrawer];
    _navbarEnabled = NO;
    [self updateNativeUIComponents];
}

- (void) show
{

    [self showDrawer];
    _navbarEnabled = YES;
    [self updateNativeUIComponents];
}

- (void) showDrawer
{
    if (_navEnabled && [_navType isEqualToString:@"drawer"])
    {

        AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
        [[appDelegate drawerController]setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];

        if (_stack.count == 1) {
            [_toolBar.topItem setLeftBarButtonItem:_drawerButton animated:YES];
        }
    }
}

- (void) hideDrawer
{
    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    [[appDelegate drawerController]setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeNone];

    if (_stack.count == 1) {
        [_toolBar.topItem setLeftBarButtonItem:nil];
    }
}

- (void) enableNavLinks
{
    _navEnabled = YES;

    if ([_navType isEqualToString:@"drawer"]) {
        [self showDrawer];
    }
}

- (void) disableNavLinks
{
    _navEnabled = NO;

    if ([_navType isEqualToString:@"drawer"]) {
        [self hideDrawer];
    }
}


- (void) navigationDrawerToggle
{
    if (_navEnabled && [_navType isEqualToString:@"drawer"]) {
        AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];

        [[(AppDelegate *)appDelegate drawerController] openDrawerSide:MMDrawerSideLeft animated:true completion:^(BOOL finished) {}];
    }
}


- (IBAction) handleActionClick:(UIBarButtonItem*)action
{
    NSString* callbackId = [_toolbarCallbacks objectAtIndex:action.tag];

    if (![callbackId isEqualToString:@""]) {
        NSDictionary * userInfo = [NSDictionary dictionaryWithObject:callbackId forKey:@"js"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CambieCallback" object:nil userInfo:userInfo];
    }
}

#pragma mark - Stack Management

- (void) pushStack:(NSString*)title
{
    if (title.length) {
        [_stack addObject:title];
    } else {
        NSString* temp = [_stack.lastObject copy];
        [_stack addObject:temp];
    }

    //the reason we set this to a blank string is so that the new animated title isn't cut off
    //the actual title is set right after pushing
    UINavigationItem * item = [[UINavigationItem alloc]initWithTitle:@"           "];
    [self setUpItem:item];

    [_toolBar pushNavigationItem:item animated:YES];
    [item setTitle:self.title];
}

- (void) replaceStack:(NSString*)title
{
    if (_toolBar.topItem == nil) {
        UINavigationItem * item = [[UINavigationItem alloc]initWithTitle:@"           "];
        [self setUpItem:item];

        [_toolBar pushNavigationItem:item animated:YES];
    }

    if (title.length) {
        [_stack replaceObjectAtIndex:(_stack.count - 1) withObject:title];

        if (_pendingPop) {
            [_toolBar.backItem setTitle:title];
        } else {
            [_toolBar.topItem setTitle:title];
        }
    }
}

- (void) popStack
{
    if (!_popFromNav) {
        _popFromWeb = YES;

        [_toolBar popNavigationItemAnimated:YES];
    }

    _popFromNav = NO;
}

- (void) clearStack
{
    if (_popFromNav) {
        [self popStack];
    } else {
        NSString* temp = [_stack.lastObject copy];
        [_stack removeAllObjects];
        [_stack addObject:temp];

        NSArray* empty = [NSArray array];
        [_toolBar setItems:empty];

        UINavigationItem * item = [[UINavigationItem alloc]initWithTitle:temp];

        [self setUpItem:item];

        [_toolBar pushNavigationItem:item animated:YES];
    }
}


#pragma mark - Getters and Setters

- (void) setThemeColor:(UIColor*)themeColor
{
    _themeColor = themeColor;

    if ([_toolBar respondsToSelector:@selector(barTintColor)]) {
        [_toolBar setBarTintColor:_themeColor];
        [_toolBar setTranslucent:self.overlayWebView];
    } else {
        [_toolBar setTintColor:_themeColor];
        [_toolBar setOpaque:!self.overlayWebView];
    }

    _statBar.backgroundColor = _themeColor;

    const CGFloat* componentColors = CGColorGetComponents(_themeColor.CGColor);
    CGFloat colorBrightness = ((componentColors[0] * 299) + (componentColors[1] * 587) + (componentColors[2] * 114)) / 1000;
    if (colorBrightness < 0.5)
    {
        _toolBar.barStyle = UIBarStyleBlack;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];

        // We're going to set the back button colour to match the text
        if ([_toolBar respondsToSelector:@selector(barTintColor)]) {
            _toolBar.tintColor = [UIColor whiteColor];
        }
    }
    else
    {
        _toolBar.barStyle = UIBarStyleDefault;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];

        // We're going to use the default color
        if ([_toolBar respondsToSelector:@selector(barTintColor)]) {
            _toolBar.tintColor = nil;
        }
    }

    if (_navbarEnabled) {
        [self updateNativeUIComponents];
    }
}

- (UIColor*) themeColor
{
    return _themeColor;
}


- (void) setAccentColor:(UIColor*)accentColor
{
    _accentColor = accentColor;

    _toolBar.tintColor = _accentColor;
}

- (UIColor*) accentColor
{
    return _accentColor;
}


- (void) setTitle:(NSString*)title
{
    if (_stack.count) {
        [self replaceStack:title];
    } else {
        [self pushStack:title];
    }
}

- (NSString*) title
{
    return _stack.lastObject;
}

- (void) setActions:(NSArray*)actions
{
    NSMutableArray* buttons = [[NSMutableArray alloc] init];
    NSInteger tag = 0;

    for (NSDictionary* act in actions) {
        UIBarButtonItem* item;

        NSString* title = [act objectForKey:@"label"];
        NSString* iconPath = [act objectForKey:@"icon"];

        if (![iconPath isKindOfClass:[NSNull class]]) {
            NSString* fullPath = [@"www/" stringByAppendingString:iconPath];
            UIImage* icon = [UIImage imageNamed:fullPath];

            CGSize itemSize = CGSizeMake(22, 22);
            UIGraphicsBeginImageContextWithOptions(itemSize, false, 0);

            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
            [icon drawInRect:imageRect];

            UIImage* sizedIcon = UIGraphicsGetImageFromCurrentImageContext();

            item = [[UIBarButtonItem alloc] initWithImage:sizedIcon style:UIBarButtonItemStylePlain target:self action:@selector(handleActionClick:)];
        } else if (![title isKindOfClass:[NSNull class]]) {
            item = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(handleActionClick:)];
        }

        NSString* callbackId = [act objectForKey:@"callback"];
        if (![callbackId isEqualToString:@""]) {
            [item setTag:tag++];
            [_toolbarCallbacks addObject:callbackId];
        }

        [buttons addObject:item];
    }

    _actions = buttons;

    [self updateNativeUIComponents];
}


- (BOOL) overlayWebView
{
    return CGColorGetAlpha(_themeColor.CGColor) < 1.0f;
}

- (BOOL) navEnabled
{
    return _navEnabled;
}


#pragma mark - NavBarDelegate methods

- (BOOL) navigationBar:(UINavigationBar*)navigationBar shouldPopItem:(UINavigationItem*)item
{
    _pendingPop = YES;

    [_stack removeLastObject];
    [_toolBar.backItem setTitle:_stack.lastObject];

    if (!_popFromWeb) {
        _popFromNav = YES;

        [[self delegate] navigationDidGoBack];
    }

    _popFromWeb = NO;

    return YES;
}

- (void) navigationBar:(UINavigationBar*)navigationBar didPopItem:(UINavigationItem*)item
{
    _pendingPop = NO;

    if (_stack.count == 1) {
        if (_navEnabled && [_navType isEqualToString:@"drawer"]) {
            [_toolBar.topItem setLeftBarButtonItem:_drawerButton animated:NO];
        } else {
            [_toolBar.topItem setLeftBarButtonItem:nil];
        }
    }
}

- (void) setUpItem:(UINavigationItem *)item
{
    if (_stack.count) {
        [_toolBar.topItem setBackBarButtonItem:_backButton];
    }

    if (_stack.count == 1 && _navEnabled && [_navType isEqualToString:@"drawer"]) {
        [item setLeftBarButtonItem:_drawerButton animated:NO];
    }
}


#pragma mark - Drawer Icon

+ (UIImage*) drawerButtonItemImage
{
    static UIImage *drawerButtonImage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIGraphicsBeginImageContextWithOptions( CGSizeMake(26, 26), NO, 0 );

        //// Color Declarations
        UIColor* fillColor = [UIColor whiteColor];

        //// Frames
        CGRect frame = CGRectMake(0, 0, 26, 26);

        //// Bottom Bar Drawing
        UIBezierPath* bottomBarPath = [UIBezierPath bezierPathWithRect: CGRectMake(CGRectGetMinX(frame) + floor((CGRectGetWidth(frame) - 16) * 0.50000 + 0.5), CGRectGetMinY(frame) + floor((CGRectGetHeight(frame) - 1) * 0.72000 + 0.5), 16, 1)];
        [fillColor setFill];
        [bottomBarPath fill];


        //// Middle Bar Drawing
        UIBezierPath* middleBarPath = [UIBezierPath bezierPathWithRect: CGRectMake(CGRectGetMinX(frame) + floor((CGRectGetWidth(frame) - 16) * 0.50000 + 0.5), CGRectGetMinY(frame) + floor((CGRectGetHeight(frame) - 1) * 0.48000 + 0.5), 16, 1)];
        [fillColor setFill];
        [middleBarPath fill];


        //// Top Bar Drawing
        UIBezierPath* topBarPath = [UIBezierPath bezierPathWithRect: CGRectMake(CGRectGetMinX(frame) + floor((CGRectGetWidth(frame) - 16) * 0.50000 + 0.5), CGRectGetMinY(frame) + floor((CGRectGetHeight(frame) - 1) * 0.24000 + 0.5), 16, 1)];
        [fillColor setFill];
        [topBarPath fill];

        drawerButtonImage = UIGraphicsGetImageFromCurrentImageContext();
    });

    return drawerButtonImage;
}

@end
