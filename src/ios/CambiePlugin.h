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

#import <Cordova/CDVPlugin.h>
#import "CambieNavigationBar.h"

@interface CambiePlugin : CDVPlugin <UINavigationBarDelegate> {
    @protected
    CambieNavigationBar* _navbar;
}

@property (nonatomic, strong) UIColor*          themeColor;

- (void) show:(CDVInvokedUrlCommand*)command;
- (void) hide:(CDVInvokedUrlCommand*)command;

- (void) setTitle:(CDVInvokedUrlCommand*)command;
- (void) setColor:(CDVInvokedUrlCommand*)command;

- (void) enableNavigationLinks:(CDVInvokedUrlCommand*)command;
- (void) disableNavigationLinks:(CDVInvokedUrlCommand*)command;

- (void) setToolbarActions:(CDVInvokedUrlCommand*)command;
- (void) setNavigationLinks:(CDVInvokedUrlCommand*)command;

- (void) pushStack:(CDVInvokedUrlCommand*)command;
- (void) replaceStack:(CDVInvokedUrlCommand*)command;
- (void) popStack:(CDVInvokedUrlCommand*)command;

@end
