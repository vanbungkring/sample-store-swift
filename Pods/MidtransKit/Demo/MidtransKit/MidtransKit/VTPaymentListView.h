//
//  VTPaymentListView.h
//  MidtransKit
//
//  Created by Arie on 6/17/16.
//  Copyright © 2016 Veritrans. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MidtransUIPaymentListFooter.h"
#import "MidtransUIPaymentListHeader.h"
@interface VTPaymentListView : UIView
@property (nonatomic) MidtransUIPaymentListFooter *footer;
@property (nonatomic) MidtransUIPaymentListHeader *header;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end
