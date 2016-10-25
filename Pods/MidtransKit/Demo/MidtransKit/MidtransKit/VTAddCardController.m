//
//  VTAddCardController.m
//  MidtransKit
//
//  Created by Nanang Rafsanjani on 2/23/16.
//  Copyright © 2016 Veritrans. All rights reserved.
//

#import "VTAddCardController.h"
#import "VTClassHelper.h"
#import "MidtransUITextField.h"
#import "VTCvvInfoController.h"
#import "MidtransUICCFrontView.h"
#import "VTCCBackView.h"
#import "MidtransUICardFormatter.h"
#import "VTSuccessStatusController.h"
#import "VTErrorStatusController.h"
#import "IHKeyboardAvoiding_vt.h"
#import "UIViewController+Modal.h"
#import "MidtransUIThemeManager.h"
#import "VTCCBackView.h"
#import "VTAddCardView.h"
#import <MidtransCoreKit/MidtransCoreKit.h>

@interface VTAddCardController ()
@property (strong, nonatomic) IBOutlet VTAddCardView *view;
@property (strong, nonatomic) IBOutlet UIView *saveCardView;
@property (nonatomic) NSMutableArray *maskedCards;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *saveCardViewHeight;
@end

@implementation VTAddCardController

@dynamic view;

- (instancetype)initWithToken:(MidtransTransactionTokenResponse *)token maskedCards:(NSMutableArray *)maskedCards {
    if (self = [super initWithToken:token]) {
        self.maskedCards = maskedCards;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(scanCardInformationFromNotification:) name:MIDTRANS_CORE_CREDIT_CARD_SCANNER_OUTPUT object:nil];
    self.title = UILocalizedString(@"creditcard.input.title", nil);
    [self addNavigationToTextFields:@[self.view.cardNumber, self.view.cardExpiryDate, self.view.cardCvv]];
    
    if ([CC_CONFIG saveCard] == NO) {
        self.saveCardView.hidden = YES;
        self.saveCardViewHeight.constant = 0;
    }
    else {
        self.saveCardView.hidden = NO;
        self.saveCardViewHeight.constant = 86;
    }
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:MIDTRANS_CORE_USING_CREDIT_CARD_SCANNER] boolValue]) {
         self.view.scanCardViewWrapper.hidden = NO;
    }
    [self.view setToken:self.token];
}
- (void)scanCardInformationFromNotification:(NSNotification *)notification {
    NSDictionary *dict = notification.object;
    [self.view setCardNumberFromCardIOSDK:dict];
    
}



- (void)handleTransactionSuccess:(MidtransTransactionResult *)result {
    [super handleTransactionSuccess:result];
    [self hideLoadingHud];
}

- (void)handleTransactionError:(NSError *)error {
    [super handleTransactionError:error];
    [self hideLoadingHud];
}

- (IBAction)saveCardSwitchChanged:(UISwitch *)sender {
    [MidtransCreditCardConfig enableSaveCard:sender.on];
}

- (IBAction)cvvInfoPressed:(UIButton *)sender {
    VTCvvInfoController *guide = [[VTCvvInfoController alloc] init];
    [self.navigationController presentCustomViewController:guide onViewController:self.navigationController completion:nil];
}

- (IBAction)registerPressed:(UIButton *)sender {
    
    MidtransCreditCard *creditCard = [[MidtransCreditCard alloc] initWithNumber:self.view.cardNumber.text
                                                                     expiryDate:self.view.cardExpiryDate.text
                                                                            cvv:self.view.cardCvv.text];
    NSError *error = nil;
    if ([creditCard isValidCreditCard:&error] == NO) {
        [self handleRegisterCreditCardError:error];
        return;
    }
    
    [self showLoadingHud];
    
    BOOL enable3Ds = [CC_CONFIG secure];
    MidtransTokenizeRequest *tokenRequest = [[MidtransTokenizeRequest alloc] initWithCreditCard:creditCard
                                                                                    grossAmount:self.token.transactionDetails.grossAmount
                                                                                         secure:enable3Ds];
    
    [[MidtransClient sharedClient] generateToken:tokenRequest
                                      completion:^(NSString * _Nullable token, NSError * _Nullable error) {
                                          if (error) {
                                              
                                              [self hideLoadingHud];
                                              [self handleTransactionError:error];
                                          } else {
                                              [self payWithToken:token];
                                          }
                                      }];
}

- (void)handleRegisterCreditCardError:(NSError *)error {
    [self hideLoadingHud];
    
    if ([self.view isViewError:error] == NO) {
        [self showAlertViewWithTitle:@"Error"
                          andMessage:error.localizedDescription
                      andButtonTitle:@"Close"];
    }
}

#pragma mark - Helper

- (void)payWithToken:(NSString *)token {
    MidtransPaymentCreditCard *paymentDetail = [[MidtransPaymentCreditCard alloc] initWithCreditCardToken:token customerDetails:self.token.customerDetails];
    
    if ([CC_CONFIG saveCard]) {
        paymentDetail.saveToken = self.view.saveCardSwitch.on;
    }
    
    MidtransTransaction *transaction = [[MidtransTransaction alloc] initWithPaymentDetails:paymentDetail token:self.token];
    
    [[MidtransMerchantClient sharedClient] performTransaction:transaction completion:^(MidtransTransactionResult *result, NSError *error) {
        if (error) {
            [self handleTransactionError:error];
        }
        else {
            //save masked cards
            if (result.maskedCreditCard) {
                [self.maskedCards addObject:result.maskedCreditCard];
                [[MidtransMerchantClient sharedClient] saveMaskedCards:self.maskedCards customer:self.token.customerDetails completion:nil];
            }
            
            //transaction finished
            [self handleTransactionSuccess:result];
        }
    }];
}
- (IBAction)scanCardDidTapped:(id)sender {
    [self scanButtonDidTappedFromAddCardViewController];
}

@end
