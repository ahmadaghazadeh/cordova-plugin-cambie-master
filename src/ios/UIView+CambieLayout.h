//
//  UIView+CambieLayout.h
//
//  Originally written by Shazron Abdulla, licensed under MIT License.
//  Updated by Darryl Pogue

#import <Foundation/Foundation.h>

typedef enum {
    CambieLayoutPositionUnknown = -1,
    CambieLayoutPositionTop = 0,
    //CambieLayoutPositionMiddle, //  always taken up by the web view (currently)
    CambieLayoutPositionBottom,
    CambieLayoutPositionTopOverlay,
    CambieLayoutPositionBottomOverlay
} CambieLayoutPosition;



//  Vertical layout manager for Cordova, for on-screen views.
//  y-order management (think of blocks in a stack, shuffled around and resized to fill available space)
//  Only cares about heights of UIViews so it fills the full screen height of the device.
//
//  All animation arguments are treated as 'NO' for now.

@interface UIView (CambieLayout)

/*
 * Adds a sibling UIView for the UIWebView.
 *
 * Pushes up any sibling UIView at that position.
 * Animation not currently supported.
 */
- (void) addSiblingView:(UIView*) siblingView withPosition:(CambieLayoutPosition)position withAnimation:(BOOL)animate;

/*
 * Removes a sibling UIView.
 *
 * Animation not currently supported.
 */
- (void) removeSiblingView:(UIView*) siblingView withAnimation:(BOOL)animate;

/*
 * Returns true if the sibling view exists.
 *
 */
- (BOOL) hasSiblingView:(UIView*) siblingView;

/*
 * Re-lays out all the sibling UIViews to fill the available height.
 *
 * Animation not currently supported.
 */
- (void) relayout:(BOOL)animate;

/*
 * Finds out the position of the sibling view in relation to the another view (helper)
 *
 */
- (CambieLayoutPosition) layoutPositionOfView:(UIView*)siblingView fromView:(UIView*)fromView;

/*
 * Finds out the position of the sibling view in relation to the middle UIWebView.
 *
 */
- (CambieLayoutPosition) layoutPosition:(UIView*)siblingView;

@end
