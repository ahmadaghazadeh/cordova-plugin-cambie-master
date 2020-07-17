

// Copyright (c) 2013 Mutual Mobile (http://mutualmobile.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import "MMDrawerViewController.h"
#import "AppDelegate.h"
#import "AppDelegate+Custom.h"


static int NUMBER_OF_ITEMS = 8;
//row height calculated programatically
static int FONT_SIZE = 16;

static float HEADER_HEIGHT = 0.0001f; //note, 0 is not an accepted value (just go very small)
static NSString * HEADER_TITLE = @""; //not used in this case

static float FOOTER_HEIGHT = 0.0;

static float CELL_COLOUR_R = 236.0;
static float CELL_COLOUR_G = 233.0;
static float CELL_COLOUR_B = 216.0;
static float CELL_COLOUR_A = 1.0;

static float TABLE_COLOUR_R = 236.0;
static float TABLE_COLOUR_G = 233.0;
static float TABLE_COLOUR_B = 216.0;
static float TABLE_COLOUR_A = 1.0;

static float NAV_COLOUR_R = 20.0;
static float NAV_COLOUR_G = 3.5;
static float NAV_COLOUR_B = 0.0;
static float NAV_COLOUR_A = 1.0;

static float ICON_SCALE = 24.0;

static NSString * ASSET_DIRECTORY = @"www/";

@implementation MMDrawerViewController

NSMutableSet * _currentRows = nil;

static BOOL OSVersionIsAtLeastiOS7() {
    return (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    

    if(OSVersionIsAtLeastiOS7()){
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    }
    else {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    }

    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    [self.view addSubview:self.tableView];
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self.tableView setScrollEnabled:false];
    

    UIColor * tableViewBackgroundColor;

    tableViewBackgroundColor = [UIColor colorWithRed:TABLE_COLOUR_R/255.0
                                                   green:TABLE_COLOUR_G/255.0
                                                    blue:TABLE_COLOUR_B/255.0
                                                   alpha:TABLE_COLOUR_A];

    [self.tableView setBackgroundColor:tableViewBackgroundColor];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    
    UIColor * barColor = [UIColor colorWithRed:NAV_COLOUR_R/255.0
                                         green:NAV_COLOUR_G/255.0
                                          blue:NAV_COLOUR_B/255.0
                                         alpha:NAV_COLOUR_A];
    
    if([self.navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)]){
        [self.navigationController.navigationBar setBarTintColor:barColor];
    }
    else {
        [self.navigationController.navigationBar setTintColor:barColor];
    }


    NSDictionary *navBarTitleDict;
    UIColor * titleColor = [UIColor colorWithRed:55.0/255.0
                                           green:70.0/255.0
                                            blue:77.0/255.0
                                           alpha:1.0];
    
    navBarTitleDict = @{NSForegroundColorAttributeName:titleColor};
    [self.navigationController.navigationBar setTitleTextAttributes:navBarTitleDict];
    
    [self.view setBackgroundColor:[UIColor clearColor]];



    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfSections-1)] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)contentSizeDidChange:(NSString *)size{
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return NUMBER_OF_ITEMS;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell setBackgroundColor:[UIColor colorWithRed:CELL_COLOUR_R/255.0
                                             green:CELL_COLOUR_G/255.0
                                              blue:CELL_COLOUR_B/255.0
                                             alpha:CELL_COLOUR_A]];
    
    [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:FONT_SIZE]];
    
    if (indexPath.row < [self.settings count]){
        
        NSString * label = [self.settings[indexPath.row] objectForKey:@"label"];
        NSString * iconPath = [self.settings[indexPath.row] objectForKey:@"icon"];
        
        if (![label isKindOfClass:[NSNull class]]){
            [cell.textLabel setText:label];
        }else{
            [cell.textLabel setText:@""];
        }
        if (![iconPath isKindOfClass:[NSNull class]]){
            
            NSString * fullPath = [ASSET_DIRECTORY stringByAppendingString:iconPath];
            UIImage * icon = [UIImage imageNamed:fullPath];
            
            CGSize itemSize = CGSizeMake(ICON_SCALE, ICON_SCALE);
            UIGraphicsBeginImageContextWithOptions(itemSize, false, 0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
            [icon drawInRect:imageRect];
            
            CGContextSetBlendMode(context, kCGBlendModeSourceIn);
            
            if ([self isEnabled:indexPath.row]){
                CGContextSetFillColorWithColor(context,[UIColor blackColor].CGColor);
            }else{
                CGContextSetFillColorWithColor(context,[UIColor grayColor].CGColor);
            }
            CGContextFillRect(context, imageRect);
            
            cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
        }else{
            [cell imageView].image = nil;
        }
        
        
        if (![self isEnabled:(indexPath.row)]){
            cell.textLabel.textColor = [UIColor colorWithRed:128.0/255.0 green:128.0/255.0 blue:128.0/255.0 alpha:1.0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }else{
            cell.textLabel.textColor = [UIColor blackColor];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }

        
    }else{
        //no data for this cell
        [cell imageView].image = nil;
        [cell.textLabel setText:@""];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return HEADER_TITLE;
}


-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView * headerView =  [[UIView alloc] init];
    [headerView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    return headerView;
}
 

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return HEADER_HEIGHT;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    BOOL isiOS7 = (IsAtLeastiOSVersion(@"7.0"));
    CGFloat tableViewHeight = self.tableView.frame.size.height;

    if (isiOS7) {
        tableViewHeight -= 64.0f;
    }
    return round(tableViewHeight/NUMBER_OF_ITEMS);
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return FOOTER_HEIGHT;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < [self.settings count]){
    
        if ([self isEnabled:indexPath.row]){
        
            NSString *callback = [self.settings[indexPath.row] objectForKey:@"callback"];
            if (![callback isKindOfClass:[NSNull class]]){
                NSDictionary * userInfo = [NSDictionary dictionaryWithObject:callback forKey:@"js"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CambieCallback" object:nil userInfo:userInfo];
            
                [[(AppDelegate *)[[UIApplication sharedApplication] delegate] drawerController] closeDrawerAnimated:true completion:^(BOOL finished) {}];
            }
        }
        
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}



-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (OSVersionIsAtLeastiOS7){
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
        }

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
            [cell setLayoutMargins:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
        }
#endif
    }
}

-(void)viewDidLayoutSubviews
{
    if (OSVersionIsAtLeastiOS7){

        if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)]) {
            [self.tableView setSeparatorInset:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
        }

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
        if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)]) {
            [self.tableView setLayoutMargins:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
        }
#endif
    }
}


-(BOOL)isEnabled:(int)row{
    
    id disabledProperty = [self.settings[row] objectForKey:@"disabled"];
    if (![disabledProperty isKindOfClass:[NSNull class]]){
        return ![disabledProperty boolValue];
    }else{
        return false;
    }
}


-(void)updateSettings:(NSArray *) newSettings{
    
    self.settings = [[NSMutableArray alloc] initWithArray:newSettings copyItems:YES];
    [self.tableView reloadData];
}

@end
