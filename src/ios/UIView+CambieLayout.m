//
//  UIView+CambieLayout.m
//
//  Originally written by Shazron Abdulla, licensed under MIT License.
//  Updated by Darryl Pogue

#import "UIView+CambieLayout.h"
#import <Cordova/CDVAvailability.h>

NSComparisonResult sortByYPos(UIView* u1, UIView* u2, void* context)
{
    if (u1.frame.origin.y == u2.frame.origin.y) { // same
        return NSOrderedSame;
    } else if (u1.frame.origin.y > u2.frame.origin.y) { // greater
        return NSOrderedDescending;
    } else { // lesser
        return NSOrderedAscending;
    }
}


//  Sibling view management for PhoneGap.
//  Only tested for the case of 1 Top and/or 1 Bottom sibling view (for now).
@implementation UIView (CambieLayout)

- (void) addSiblingView:(UIView*) siblingView withPosition:(CambieLayoutPosition)position withAnimation:(BOOL)animate
{
    //NSAssert(siblingView.frame.size.height < self.frame.size.height, @"Cambie: Cannot add a sibling view that is larger than the WebView");

    CGRect siblingViewFrame = siblingView.frame;
    CGRect webViewFrame = self.frame;
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect statusBarRect = [ [UIApplication sharedApplication] statusBarFrame];

    NSEnumerator* enumerator = [self.superview.subviews objectEnumerator];
    UIView* subview;

    switch (position)
    {
        case CambieLayoutPositionTop:
        case CambieLayoutPositionTopOverlay:
        {
            if (position != CambieLayoutPositionTopOverlay) {
                // shift down y-position of all sibling views by new view's height (only CDVLayoutPositionTop items),
                while ( (subview = [enumerator nextObject]) ) {
                    if ([self layoutPosition:subview] == CambieLayoutPositionTop) {
                        CGRect subviewFrame = subview.frame;
                        subviewFrame.origin.y += siblingView.frame.size.height;
                        subview.frame = subviewFrame;
                    }
                }

                // webView is shrunk by new view's height (origin shift down as well)
                webViewFrame.origin.y += siblingView.frame.size.height;
                webViewFrame.size.height -= siblingView.frame.size.height;
                self.frame = webViewFrame;
            }

            // make sure the siblingView's frame is to the top
            siblingViewFrame.origin.y = 0.0f;
            siblingView.frame = siblingViewFrame;
        }
            break;
        case CambieLayoutPositionBottom:
        case CambieLayoutPositionBottomOverlay:
        {
            if (position != CambieLayoutPositionBottomOverlay) {
                // shift up y-position of all sibling views by new view's height (only CDVLayoutPositionBottom items),
                while ( (subview = [enumerator nextObject]) ) {
                    if ([self layoutPosition:subview] == CambieLayoutPositionBottom) {
                        CGRect subviewFrame = subview.frame;
                        subviewFrame.origin.y -= siblingView.frame.size.height;
                        subview.frame = subviewFrame;
                    }
                }

                // webView is shrunk by new view's height (no origin shift)
                webViewFrame.size.height -= siblingView.frame.size.height;
                self.frame = webViewFrame;
            }

            // make sure the siblingView's frame is to the bottom
            siblingViewFrame.origin.y = (screenBounds.size.height - statusBarRect.size.height) - siblingView.frame.size.height;
            siblingView.frame = siblingViewFrame;
        }
            break;
        default: // not specified, or unsupported, so we return
            return;
    }

    [self.superview addSubview:siblingView];

    if (position == CambieLayoutPositionTopOverlay || position == CambieLayoutPositionBottomOverlay) {
        [self.superview bringSubviewToFront:siblingView];
    }
}


- (void) removeSiblingView:(UIView*) siblingView withAnimation:(BOOL)animate
{
    // pg_relayout: needs to be called after to fill in the gap

    if ([self hasSiblingView:siblingView]) {
        [siblingView removeFromSuperview];
    }
}


- (BOOL) hasSiblingView:(UIView*) siblingView
{
    return ([self.superview.subviews indexOfObject:siblingView] != NSNotFound);
}

- (CGSize) totalViewDimensions:(NSMutableArray*)views
{
    NSEnumerator* enumerator = [views objectEnumerator];
    UIView* subview;
    CGSize size = CGSizeMake(0, 0);

    while (subview = [enumerator nextObject])
    {
        if (subview.hidden) {
            continue;
        }
        size.width  += subview.frame.size.width;
        size.height += subview.frame.size.height;
    }

    return size;
}


- (void) sortViews:(NSMutableArray*)views withOrigin:(CGPoint)origin
{
    // sort by y-position
    [views sortUsingFunction:sortByYPos context:nil];

    // now we fill in the gaps
    NSEnumerator* enumerator = [views objectEnumerator];
    UIView* subview;
    CGPoint nextOrigin = CGPointMake(origin.x, origin.y);

    while (subview = [enumerator nextObject])
    {
        if (subview.hidden) {
            continue;
        }

        CGRect subviewFrame = subview.frame;
        subviewFrame.origin.y = nextOrigin.y;
        subview.frame = subviewFrame;

        nextOrigin = CGPointMake(nextOrigin.x, (subviewFrame.origin.y + subviewFrame.size.height));
    }
}


- (void) relayout:(BOOL)animate
{
    BOOL isiOS7 = (IsAtLeastiOSVersion(@"7.0"));

    // check each sibling view, and re-size if necessary (UIWebview) (top to bottom)
    // first we partition, then move any intersecting (with UIWebView) to either the top, or bottom.
    // here we will choose the top

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGRect statusBarRect = [ [UIApplication sharedApplication] statusBarFrame];

    if (isiOS7) {
        statusBarRect.size.height = 0;
    }

    BOOL middleToTop = YES;

    UIView* centreView = self;

    NSMutableArray* top =       [NSMutableArray arrayWithCapacity:1];
    NSMutableArray* middle =    [NSMutableArray arrayWithCapacity:1];
    NSMutableArray* bottom =    [NSMutableArray arrayWithCapacity:1];

    NSEnumerator* enumerator = [centreView.superview.subviews objectEnumerator];
    UIView* subview;

    while (subview = [enumerator nextObject]) {
        if (subview.hidden) {
            continue;
        }

        if ([self layoutPositionOfView:subview fromView:centreView] == CambieLayoutPositionTop) {
            [top addObject:subview];
        } else if ([self layoutPositionOfView:subview fromView:centreView] == CambieLayoutPositionBottom) {
            [bottom addObject:subview];
        } else if (subview != centreView) { // it is in the "middle" check that it is not the centreView
            [middle addObject:subview];
        }
    }

    // Special case: no items in Top, Middle, Bottom. Restore centreView to full screen
    if ([top count] == 0 && [middle count] == 0 && [bottom count] == 0) {
        CGRect centreViewRect = centreView.frame;
        centreViewRect.size.height = screenBounds.size.height - statusBarRect.size.height;
        centreViewRect.origin.y = 0;
        centreView.frame = centreViewRect;

        return;
    }

    // Special case: no items in Bottom. Restore centreView to full height
    if ([top count] == 0 && [middle count] == 0 && [bottom count] == 0) {
        CGRect centreViewRect = centreView.frame;
        centreViewRect.size.height = screenBounds.size.height - statusBarRect.size.height;
        centreViewRect.origin.y = 0;
        centreView.frame = centreViewRect;

        return;
    }


    // Sort the Top, Middle, and Bottom Items.

    CGPoint nextOrigin = CGPointMake(0, 0);

    // sort Top items
    [self sortViews:top withOrigin:nextOrigin];

    // get the last object from Top, to set the origin of Middle
    UIView* lastObject = [top lastObject];
    if (lastObject) {
        nextOrigin = CGPointMake(0, lastObject.frame.origin.y + lastObject.frame.size.height);
    }

    if (middleToTop) {
        // sort Middle items
        [self sortViews:middle withOrigin:nextOrigin];

        lastObject = [middle lastObject];
        if (lastObject) {
            nextOrigin = CGPointMake(0, lastObject.frame.origin.y + lastObject.frame.size.height);
        }
    }

    // get the last object from Middle, to set the origin of centreView
    if (lastObject || [bottom count] == 0 || [top count] == 0) {
        CGRect centreViewRect = centreView.frame;

        centreViewRect.origin.y = nextOrigin.y;

        // to calculate the height, we do (screenBounds - (topHeight + middleHeight + bottomHeight))
        CGFloat newHeight = (screenBounds.size.height - statusBarRect.size.height);
        newHeight -= ([self totalViewDimensions:top].height +
                      [self totalViewDimensions:middle].height +
                      [self totalViewDimensions:bottom].height);

        centreViewRect.size.height = newHeight;

        centreView.frame = centreViewRect;

        nextOrigin = CGPointMake(0, (centreViewRect.origin .y + centreViewRect.size.height));
    }

    if (!middleToTop) {
        // sort Middle items
        [self sortViews:middle withOrigin:nextOrigin];


        lastObject = [middle lastObject];
        if (lastObject) {
            nextOrigin = CGPointMake(0, lastObject.frame.origin.y + lastObject.frame.size.height);
        }
    }

    // sort Bottom items
    [self sortViews:bottom withOrigin:nextOrigin];
}


- (CambieLayoutPosition) layoutPositionOfView:(UIView*)siblingView fromView:(UIView*)fromView
{
    CGRect fromViewFrame = fromView.frame;
    CGRect siblingFrame = siblingView.frame;

    if (siblingFrame.origin.y >= (fromViewFrame.origin.y + fromViewFrame.size.height))
    {
        return CambieLayoutPositionBottom;
    }
    else if (fromViewFrame.origin.y >= (siblingFrame.origin.y + siblingFrame.size.height))
    {
        return CambieLayoutPositionTop;
    }
    else
    {
        return CambieLayoutPositionUnknown;
    }
}


- (CambieLayoutPosition) layoutPosition:(UIView*)siblingView
{
    return [self layoutPositionOfView:siblingView fromView:self];
}


@end
