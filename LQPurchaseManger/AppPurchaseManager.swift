//
//  AppPurchaseManager.swift
//  LQPurchaseManger
//
//  Created by Quan Li on 2019/7/22.
//  Copyright © 2019 williamoneilchina. All rights reserved.
//

import Foundation
import StoreKit

public enum PurchaseErrorType:String{
    case NoPermission = "没有打开内购功能"
    case GetProductListError = "获取产品列表失败"
    case InvalidProductId = "无效的产品ID"
    case PurchaseFailure = "购买失败"
    case RestoreFailure = "恢复购买失败"
}

public protocol AppPurchaseManagerDelgate:AnyObject {
    func purchaseGetProductList(productList:[SKProduct])
    func purchaseFailure(type:PurchaseErrorType,transaction: SKPaymentTransaction?)
    func purchaseSuccess(transaction:SKPaymentTransaction)
    func restoreSuccess(transaction:SKPaymentTransaction)
}

open class AppPurchaseManager:NSObject{
    public weak var delegate:AppPurchaseManagerDelgate?
    
    public var isRequestProduct = false
    
    public var isPurchase = false
    
    public var  canMakePayments:Bool{
        return SKPaymentQueue.canMakePayments()
    }
    
    public override init(){
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    public func removeObserver() {
        SKPaymentQueue.default().remove(self)
    }
    
    deinit {
        removeObserver()
    }
    
    public func getProductList(productIds:Set<String>){
        if  canMakePayments {
            let request = SKProductsRequest.init(productIdentifiers: productIds)
            request.delegate = self
            request.start()
            isRequestProduct = true
        }else{
            delegate?.purchaseFailure(type: .NoPermission,transaction: nil)
        }
    }
    
    public func purchase(product:SKProduct?){
        guard let pro = product else {
            return
        }
        let payment = SKPayment.init(product: pro)
        SKPaymentQueue.default().add(payment)
        isPurchase = true
    }
    
    public func restore(){
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    public static var transactionReceipt:String?{
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        do {
            let receiptData = try Data(contentsOf: url)
            return receiptData.base64EncodedString()
        } catch {
            #if DEBUG
            print("Error loading receipt data: \(error.localizedDescription)")
            #endif
            return nil
        }
    }
    
}

extension AppPurchaseManager:SKProductsRequestDelegate{
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        isRequestProduct = false
        delegate?.purchaseGetProductList(productList: response.products)
        if  !response.invalidProductIdentifiers.isEmpty {
            delegate?.purchaseFailure(type: .InvalidProductId, transaction: nil)
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        isRequestProduct = false
        delegate?.purchaseFailure(type: .GetProductListError,transaction: nil)
        #if DEBUG
        print("request product list error: \(error.localizedDescription)")
        #endif
    }
}


extension AppPurchaseManager:SKPaymentTransactionObserver{
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for (_,item) in transactions.enumerated() {
            switch(item.transactionState){
            case .purchased:
                delegate?.purchaseSuccess(transaction: item)
            case .failed:
                delegate?.purchaseFailure(type: .PurchaseFailure, transaction: item)
            case .restored:
                delegate?.restoreSuccess(transaction: item)
            case .purchasing:
                break
            case .deferred:
                break
            @unknown default:
                break
            }
            SKPaymentQueue.default().finishTransaction(item)
        }
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        delegate?.purchaseFailure(type: .RestoreFailure, transaction: nil)
        #if DEBUG
        print("restore error: \(error.localizedDescription)")
        #endif
    }
}


extension SKProduct {
    private static var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.formatterBehavior = .behavior10_4
        return formatter
    }()
    
    public var formattedPrice: String {
        if SKProduct.formatter.locale != self.priceLocale {
            SKProduct.formatter.locale = self.priceLocale
        }
        return SKProduct.formatter.string(from: self.price) ?? "\(self.price)"
    }
    
    public func formattedDiscountPrice(discount:NSDecimalNumber) -> String {
        if SKProduct.formatter.locale != self.priceLocale {
            SKProduct.formatter.locale = self.priceLocale
        }
        return SKProduct.formatter.string(from: discount) ?? "\(discount)"
    }
}


