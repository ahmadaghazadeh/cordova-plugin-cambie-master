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

#import "CambiePlugin.h"
#import "UIView+CambieLayout.h"
#import "AppDelegate+Custom.h"
#import "AppDelegate.h"
#import "MMDrawerViewController.h"

@interface CambiePlugin (NavDelegate) <CambieNavigationDelegate>

- (void) navigationDidGoBack;
- (void) navigationDrawerToggle;

@end

@implementation CambiePlugin

- (void)pluginInitialize
{
    NSString* navType = [self.commandDelegate.settings objectForKey:[@"CambieNavType" lowercaseString]];

    _navbar = [[CambieNavigationBar alloc] initWithViewController:self.webView navType:navType];
    _navbar.delegate = self;

    self.themeColor = [UIColor clearColor];

    // Check if we should show the navbar by default
    NSNumber* showNavbar = [self.commandDelegate.settings objectForKey:[@"CambieVisible" lowercaseString]];
    if (showNavbar == nil || [showNavbar boolValue]) {
        [_navbar show];

        [_navbar enableNavLinks];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callBack:) name:@"CambieCallback" object:nil];
    //remove observer at some point, use the other notification for reference
}

- (void) navigationDidGoBack
{
    [self.webView goBack];
}


- (void)show:(CDVInvokedUrlCommand *)command
{
    [_navbar show];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
}


- (void)hide:(CDVInvokedUrlCommand *)command
{
    [_navbar hide];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
}


- (void)setColor:(CDVInvokedUrlCommand *)command
{
    NSString* color = [command.arguments objectAtIndex:0];

    if ([color hasPrefix:@"rgba"])
    {
        int r = 0, g = 0, b = 0;
        double a = 0.0f;

        NSScanner* scanner = [NSScanner scannerWithString:color];
        [scanner setScanLocation:5];

        [scanner scanInteger:&r];
        [scanner scanString:@"," intoString:nil];
        [scanner scanInteger:&g];
        [scanner scanString:@"," intoString:nil];
        [scanner scanInteger:&b];
        [scanner scanString:@"," intoString:nil];
        [scanner scanDouble:&a];

        self.themeColor = [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a];

    }
    else if ([color hasPrefix:@"rgb"])
    {
        int r = 0, g = 0, b = 0;

        NSScanner* scanner = [NSScanner scannerWithString:color];
        [scanner setScanLocation:4];

        [scanner scanInteger:&r];
        [scanner scanString:@"," intoString:nil];
        [scanner scanInteger:&g];
        [scanner scanString:@"," intoString:nil];
        [scanner scanInteger:&b];

        self.themeColor = [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
    }
    else if ([color hasPrefix:@"#"])
    {
        unsigned int rgbValue = 0;
        NSScanner* scanner = [NSScanner scannerWithString:color];
        [scanner setScanLocation:1];
        [scanner scanHexInt:&rgbValue];

        self.themeColor = [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    }

    _navbar.themeColor = self.themeColor;

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
}

- (void)setTitle:(CDVInvokedUrlCommand *)command
{
    _navbar.title = [command.arguments objectAtIndex:0];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
}

- (void)enableNavigationLinks:(CDVInvokedUrlCommand *)command
{
    [_navbar enableNavLinks];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
}

- (void)disableNavigationLinks:(CDVInvokedUrlCommand *)command
{
    [_navbar disableNavLinks];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
}

- (void)setToolbarActions:(CDVInvokedUrlCommand *)command
{
    NSArray* actions = [command.arguments objectAtIndex:0];

    NSMutableArray* primaries = [[NSMutableArray alloc] init];
    NSMutableArray* secondaries = [[NSMutableArray alloc] init];

    for (NSDictionary* act in actions) {
        id primary = [act objectForKey:@"primary"];
        if ([primary boolValue]) {
            [primaries addObject:act];
        } else {
            [secondaries addObject:act];
        }
    }

    // Pass these in to the CambieNavigationBar
    _navbar.actions = primaries;

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
}

- (void)setNavigationLinks:(CDVInvokedUrlCommand *)command
{
    AppDelegate * delegate = [[UIApplication sharedApplication] delegate];

    //TODO, the following lines of code shouldn't really be here, but the problem is that they are initialized
    //after the cambie navbar so this can't be done in the cambie NavBar initialization
    
    //This is not ideal but rather a temporary fix.
    
    if (IsAtLeastiOSVersion(@"7.0")) {
        _navbar.drawer =  (MMDrawerViewController *)[(UINavigationController *)[[delegate drawerController] leftDrawerViewController] viewControllers][0];
    } else {
        _navbar.drawer = (MMDrawerViewController *)[[delegate drawerController] leftDrawerViewController];
    }
    //until here
    
    
    [_navbar.drawer updateSettings:[command.arguments objectAtIndex:0]];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];

    [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
}


- (void)callBack:(NSNotification *)n{
    NSString * callbackId = [[n userInfo] objectForKey:@"js"];
    if (![callbackId isEqualToString:@""]) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
        [pluginResult setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:callbackId];
    }
}





- (void) pushStack:(CDVInvokedUrlCommand*)command
{
    NSString* title = [command.arguments objectAtIndex:0];
    [_navbar pushStack:title];
}

- (void) replaceStack:(CDVInvokedUrlCommand*)command
{
    NSString* title = [command.arguments objectAtIndex:0];
    [_navbar replaceStack:title];
}

- (void) popStack:(CDVInvokedUrlCommand*)command
{
    if ([self.webView canGoBack]) {
        [_navbar popStack];
    } else {
        [_navbar clearStack];
    }
}

@end
