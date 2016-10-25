//
//  ViewController.swift
//  sample-store-swift
//
//  Created by Arie on 10/14/16.
//  Copyright © 2016 Arie. All rights reserved.
//

import UIKit

let kClientKey = "client_key"
let kMerchantURL = "merchant_url"
let kEnvironment = "environment"
let kTimeoutInterval = "timeout_interval"

class ViewController: UIViewController {
    var itemDetails = [MidtransItemDetail]()

    override func viewDidLoad() {
        super.viewDidLoad()
        MidtransConfig .setClientKey("VT-client-6_dY49SlR_Ph32_1", serverEnvironment: MIdtransServerEnvironment(rawValue: UInt(0))!, merchantURL: "http://mobile-snap-sandbox.herokuapp.com");
        // Do any additional setup after loading the view, typically from a nib.
        self.itemDetails = generateItemDetails() as! [MidtransItemDetail];
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func checkoutButtonDidTapped(_ sender: AnyObject) {
        var shipAddr = MidtransAddress()
        var billAddr = MidtransAddress()
        var customerDetails = MidtransCustomerDetails(firstName: "FirstName", lastName: "LastName", email: "mail@mailinator.com", phone: "0814444478738", shippingAddress: shipAddr, billingAddress: billAddr);
        var transactionDetails = MidtransTransactionDetails(orderID: String.random(withLength: 20), andGrossAmount: self.grossAmountOfItemDetails(self.itemDetails) as NSNumber!)
    func grossAmountOfItemDetails(_ itemDetails: [MidtransItemDetail]) -> Int {
        var totalPrice: Double = 0
        for itemDetail: MidtransItemDetail in itemDetails {
            totalPrice += (CDouble(itemDetail.price) * CDouble(itemDetail.quantity))
        }
        return (Int(totalPrice))
    }

    func generateItemDetails() -> [Any] {
        var result = [Any]()
        for i in 0..<6 {
            let itemDetail = MidtransItemDetail(itemID: String.random(withLength: 20), name: "Item \(i)", price: 1000, quantity: 3)
            itemDetail?.imageURL = NSURL(string: "http://ecx.images-amazon.com/images/I/41blp4ePe8L._AC_UL246_SR190,246_.jpg")! as URL!
            result.append(itemDetail)
        }
        return result
    }
}
