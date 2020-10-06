//
//  CPSDK.swift
//  PaymentSDK
//
//  Created by Patel, Varun on 2/8/19.
//  Copyright © 2019 First Data. All rights reserved.
//

import UIKit

@objc public enum Environment: Int {
    case qa, cat, prod
}

/**********************************************************
 *
 * CPSDK -> Entry Point to CP-SDK Flows
 *
 **********************************************************/
//MARK: CPDSK
@objc public class CPSdkConfiguration: NSObject {
    @objc public var fdCustomerId: String!
    @objc public var encryptionKey: String!
    @objc public var accessToken: String!
    @objc public var configId: String! //pageId
    @objc public var postUrl: String!
    
    override private init() {}
    @objc public init(withFdCustomerId fdCustomerId:String, encryptionKey:String, accessToken:String, configId:String, andPostUrl postUrl:String) {
        self.fdCustomerId = fdCustomerId
        self.encryptionKey = encryptionKey
        self.accessToken = accessToken
        self.configId = configId
        self.postUrl = postUrl
    }
    
    var environment = Environment.qa
    var baseUrl: String {
        switch environment {
        case .qa: return "https://qa.api.firstdata.com/gateway/v2/connectpay"
        case .cat: return "https://cat.api.firstdata.com/gateway/v2/connectpay"
        case .prod: return "https://prod.api.firstdata.com/gateway/v2/connectpay"
        }
    }
}

@objc public class CPSDK: NSObject {
    @objc public init(withApiKey apiKey:String, andEnvironment environment:Environment) {
        self._environment = environment
        ConfigurationManager.shared.apiKey = apiKey
    }
    //TODO: Add Different SDK targets to control the below (QA/CAT/PROD)
    private var _environment = Environment.qa
    
    @objc public func closeAccount(withCpSdkConfiguration cpSdkConfiguration:CPSdkConfiguration, andCloseAccountConfiguration closeAccountConfiguration:CloseAccountConfiguration) -> CloseAccount? {
        cpSdkConfiguration.environment = self._environment
        return CloseAccount(cpSdkConfiguration: cpSdkConfiguration, closeAccountConfiguration: closeAccountConfiguration)
    }
    
    @objc public func manualEnrollment(withCpSdkConfiguration cpSdkConfiguration:CPSdkConfiguration, andManualEnrollmentConfiguration manualEnrollmentConfiguration:ManualEnrollmentConfiguration) -> ManualEnrollment? {
        cpSdkConfiguration.environment = self._environment
        return ManualEnrollment(cpSdkConfiguration: cpSdkConfiguration, manualEnrollmentConfiguration: manualEnrollmentConfiguration)
    }
    
    @objc public func updateEnrollment(withCpSdkConfiguration cpSdkConfiguration:CPSdkConfiguration, andUpdateEnrollmentConfiguration updateEnrollmentConfiguration:ManualEnrollmentConfiguration) -> UpdateEnrollment? {
        cpSdkConfiguration.environment = self._environment
        return UpdateEnrollment(cpSdkConfiguration: cpSdkConfiguration, updateEnrollmentConfiguration: updateEnrollmentConfiguration)
    }
    
    @objc public func manualDeposit(withCpSdkConfiguration cpSdkConfiguration:CPSdkConfiguration, andManualDepositConfiguration manualDepositConfiguration:ManualDepositConfiguration) -> ManualDeposit? {
        cpSdkConfiguration.environment = self._environment
        return ManualDeposit(cpSdkConfiguration: cpSdkConfiguration, manualDepositConfiguration: manualDepositConfiguration)
    }
    
    @objc public func accountValidation(withCpSdkConfiguration cpSdkConfiguration:CPSdkConfiguration, andAccountValidationConfiguration accountValidationConfiguration:AccountValidationConfiguration) -> AccountValidation? {
        cpSdkConfiguration.environment = self._environment
        return AccountValidation(cpSdkConfiguration: cpSdkConfiguration, accountValidationConfiguration: accountValidationConfiguration)
    }
    
    @objc public func enrollmentAccountDetail(withCpSdkConfiguration cpSdkConfiguration:CPSdkConfiguration, andEnrollmentAccountDetailConfiguration enrollmentAccountDetailConfiguration:ManualEnrollmentConfiguration) -> EnrollmentAccountDetails? {
        cpSdkConfiguration.environment = self._environment
        return EnrollmentAccountDetails(cpSdkConfiguration: cpSdkConfiguration, enrollmentAccountDetailConfiguration: enrollmentAccountDetailConfiguration)
    }
}

/**********************************************************
 *
 * Base CP Flow
 *
 **********************************************************/
//MARK: Base CP Flow
public class BaseCPFlow: NSObject {
    fileprivate var cpSdkConfiguration: CPSdkConfiguration!
    private var completionHandler: (([String : AnyObject]?) -> Void)?
    //MARK: Initializers
    public override init() {
        super.init()        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "PaymentSdkStopSession"), object: nil, queue: OperationQueue.main) { (notification: Notification) in
            if self.completionHandler != nil {
                if let response = notification.userInfo as? [String : AnyObject] {
                    self.completionHandler!(response)
                } else {
                    self.completionHandler!(nil)
                }
            }
            
            self.stop()
        }
    }
    
    //MARK: Lifecycle Methods
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "PaymentSdkStopSession"), object: nil)
    }
    
    //MARK: Flow configuration variables:
    fileprivate var closeAccountConfiguration: CloseAccountConfiguration!
    fileprivate var manualEnrollmentConfiguration: ManualEnrollmentConfiguration!
    fileprivate var updateEnrollmentConfiguration: ManualEnrollmentConfiguration!
    fileprivate var manualDepositConfiguration: ManualDepositConfiguration!
    fileprivate var accountValidationConfiguration: AccountValidationConfiguration!
    fileprivate var enrollmentAccountDetailConfiguration: ManualEnrollmentConfiguration!
    
    //MARK: Base entry and exit points for flows
    @objc public func start(completionHandler: @escaping ([String : AnyObject]?) -> Void) {
        self.completionHandler = completionHandler        
        guard Reachability.isConnectedToNetwork() else {
            var failureDict = [String: AnyObject]()
            failureDict["transactionStatus"] = "ERROR" as AnyObject
            failureDict["transactionStatusCode"] = CPErrorCode.networkError.rawValue as AnyObject
            failureDict["transactionStatusDescription"] = CPErrorMessage.networkError.rawValue as AnyObject
            failureDict["responseVerbiage"] = CPErrorMessage.networkError.rawValue as AnyObject
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PaymentSdkStopSession"), object: nil, userInfo: failureDict)
            return
        }
        var viewControllerToPresent: BaseViewController?
        ConfigurationManager.shared.sdkConstants = cpSdkConfiguration
        switch ConfigurationManager.shared.cpSdkFlow {
        case .closeAccount:
            let baseVC = CPBaseViewController(widgetType: .CPCloseAccountWidget, dataDictionary:_getDataDictionary(forWidgetType: .CPCloseAccountWidget) ?? [:])
            viewControllerToPresent = baseVC
            break
            
        case .manualEnrollment:
            let manualEnrollmentVC = EnrollmentOptionsViewController(widgetType: .None, dataDictionary:_getDataDictionary(forWidgetType: .None) ?? [:])
            viewControllerToPresent = manualEnrollmentVC
            break
            
        case .updateEnrollment:
            let updateEnrollmentVC = UpdateEnrollmentViewController(widgetType: .None, dataDictionary:_getDataDictionary(forWidgetType: .None) ?? [:])
            viewControllerToPresent = updateEnrollmentVC
            break
            
        case .deposit:
            let manualDepositVC = CPBaseViewController(widgetType: .CPManualDepositWidget, dataDictionary: _getDataDictionary(forWidgetType: .CPManualDepositWidget) ?? [:])
            viewControllerToPresent = manualDepositVC
            break
            
        case .load:
            let accountValidationVC = CPBaseViewController(widgetType: .CPAccountValidationWidget, dataDictionary: _getDataDictionary(forWidgetType: .CPAccountValidationWidget) ?? [:])
            viewControllerToPresent = accountValidationVC
            break
        
        case .accountDetails:
            let accountDetailVC = CPBaseViewController(widgetType: .CPEnrollmentAccountDetailsWidget, dataDictionary: _getDataDictionary(forWidgetType: .CPEnrollmentAccountDetailsWidget) ?? [:])
            viewControllerToPresent = accountDetailVC
            break
        }
        
        if let viewControllerToPresent = viewControllerToPresent {
            _startSession(withRootViewController: viewControllerToPresent)
        }
    }
    
    @objc public func stop() {
        //Cleanup
        UIViewController.topViewController().dismiss(animated: true, completion: nil)
        ConfigurationManager.shared.configurationDictionary = nil
        //ConfigurationManager.shared.sdkConstants = nil
        ConfigurationManager.shared.apiKey = nil
    }
    
    //MARK: Private methods
    private func _startSession(withRootViewController rootVC: BaseViewController) {
        let navController = UINavigationController(rootViewController: rootVC)
        navController.view.backgroundColor = UIColor.white
        navController.setNavigationBarHidden(true, animated: false)
        navController.modalPresentationStyle = .fullScreen
        UIViewController.topViewController().present(navController, animated: true, completion: {
            if let cpSdkConfiguration = self.cpSdkConfiguration {
                ConfigurationManager.shared.sdkConstants = cpSdkConfiguration
                let configurationRequest = ConfigurationRequest()
                configurationRequest.makeRequest(withCompletionBlock: { (resultDictionary, success) in
                    if success {
                        ConfigurationManager.shared.configurationDictionary = resultDictionary
                        let configurationVC = rootVC as! CPBaseViewController
                        guard let displayWidgetType = ConfigurationManager.shared.mainScreenConfiguration?.displayWidgets.first?.widgets?.first?.type else {
                            return
                        }
                        configurationVC.widgetType = displayWidgetType
                        configurationVC.widgetConfiguration = ConfigurationManager.shared.mainScreenConfiguration?.widgets[displayWidgetType.rawValue]
                        configurationVC.dataDictionary = self._getDataDictionary(forWidgetType: displayWidgetType) ?? [:]
                        if displayWidgetType == .CPEnrollmentAccountDetailsWidget {
                            configurationVC.mergeDictionaries()
                        }
                        
                        // Remove any extra values from dataDictionary that don't exist in the configuration object
                        var filteredDictionary = [String:String]()
                        ConfigurationManager.shared.mainScreenConfiguration?.widgets.forEach({ (key, widget) in
                            widget.flatFields.forEach({ (fieldConfiguration) in
                                configurationVC.dataDictionary.forEach({ (key, value) in
                                    var components = key.components(separatedBy: ".")
                                    components.removeFirst()
                                    let dictId = components.joined(separator: ".")
                                    if dictId == fieldConfiguration.id {
                                        filteredDictionary[key] = value
                                    }
                                })
                            })
                        })
                        
                        configurationVC.dataDictionary = filteredDictionary
                        
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DidLoadConfiguration"), object: nil)
                        rootVC.tableView.reloadData()
                    } else {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "PaymentSdkStopSession"), object: nil, userInfo: resultDictionary)
                        }
                    }
                })
            } else {
                var alertConfiguration = FDAlertViewConfiguration(withState: .complete, andId: UUID().uuidString)
                alertConfiguration.title = "Error"
                alertConfiguration.message = "Invalid Configuration"
                alertConfiguration.dismissCompletionBlock = { self.stop() }
                FDAlertViewUtility.shared.addConfigurationToQueue(alertConfiguration)
            }
        })
    }
    
    fileprivate func _getDataDictionary(forWidgetType type: WidgetType) -> [String:String]? {
        return nil
    }
}

/**********************************************************
 *
 * Close Account Flow
 *
 **********************************************************/
//MARK: Close Account Flow
@objc public class CloseAccountConfiguration: NSObject {
    @objc fileprivate var accountNumber: String!
    @objc fileprivate var reason: String?
    
    private override init() {}
    @objc public init(withAccountNumber accountNumber:String, andReason reason:String?) {
        self.accountNumber = accountNumber
        self.reason = reason
    }
}

@objc public class CloseAccount: BaseCPFlow {
    private override init() {}
    fileprivate init(cpSdkConfiguration:CPSdkConfiguration, closeAccountConfiguration:CloseAccountConfiguration) {
        super.init()
        self.cpSdkConfiguration = cpSdkConfiguration
        self.closeAccountConfiguration = closeAccountConfiguration
        ConfigurationManager.shared.cpSdkFlow = .closeAccount
    }
    
    override func _getDataDictionary(forWidgetType type: WidgetType) -> [String : String]? {
        var dataDictionary = [String:String]()
        dataDictionary["\(type.rawValue).accountNumber"] = closeAccountConfiguration.accountNumber
        dataDictionary["\(type.rawValue).reason"] = closeAccountConfiguration.reason
        return dataDictionary
    }
}

/**********************************************************
 *
 * Manual Enrollment Flow
 *
 **********************************************************/
//MARK: Manual Enrollment Flow
@objc public class PhoneNumberConfiguration: NSObject {
    @objc public var id: String?
    @objc public var phoneNumber: String?
    @objc public var type: String?
}

@objc public class SecurityQuestionConfiguration: NSObject {
    @objc public var id: String?
    @objc public var question: String?
    @objc public var answer: String?
}

@objc public class ManualEnrollmentConfiguration: NSObject {
    @objc public var routingNumber: String?
    @objc public var accountNumber: String?
    @objc public var accountType: String?
    @objc public var onlineBankTransactionId: String?
    @objc public var cpCardNumber: String?
    @objc public var firstName: String?
    @objc public var lastName: String?
    @objc public var email: String?
    @objc public var phoneNumbers: [PhoneNumberConfiguration]?
    @objc public var streetAddress: String?
    @objc public var apartmentNumber: String?
    @objc public var city: String?
    @objc public var state: String?
    @objc public var zipCode: String?
    @objc public var driversLicense: String?
    @objc public var driversLicenseIssuingState: String?
    @objc public var ssn: String?
    @objc public var gender: String?
    @objc public var dob: String?
    @objc public var pin: String?
    @objc public var newPin: String?
    @objc public var memberSince: String?
    @objc public var securityQuestions: [SecurityQuestionConfiguration]?
    @objc public var genericFlag1: String?
    @objc public var genericFlag2: String?
    @objc public var genericFlag3: String?
    @objc public var genericCode1: String?
    @objc public var genericCode2: String?
    @objc public var genericCode3: String?
    @objc public var reportingField1: String?
    @objc public var reportingField2: String?
    @objc public var reportingField3: String?
}

@objc public class ManualEnrollment: BaseCPFlow {
    private override init() {}
    fileprivate init(cpSdkConfiguration:CPSdkConfiguration, manualEnrollmentConfiguration:ManualEnrollmentConfiguration) {
        super.init()
        self.cpSdkConfiguration = cpSdkConfiguration
        self.manualEnrollmentConfiguration = manualEnrollmentConfiguration
        ConfigurationManager.shared.cpSdkFlow = .manualEnrollment
    }
    
    override func _getDataDictionary(forWidgetType type: WidgetType) -> [String : String]? {
        var dataDictionary = [String:String]()
        dataDictionary["\(type.rawValue).routingNumber"] = manualEnrollmentConfiguration.routingNumber
        dataDictionary["\(type.rawValue).accountNumber"] = manualEnrollmentConfiguration.accountNumber
        dataDictionary["\(type.rawValue).accountType"] = manualEnrollmentConfiguration.accountType
        dataDictionary["\(type.rawValue).onlineBankTransactionId"] = manualEnrollmentConfiguration.onlineBankTransactionId
        dataDictionary["\(type.rawValue).connectPayPaymentNumber"] = manualEnrollmentConfiguration.cpCardNumber
        dataDictionary["\(type.rawValue).firstName"] = manualEnrollmentConfiguration.firstName
        dataDictionary["\(type.rawValue).lastName"] = manualEnrollmentConfiguration.lastName
        dataDictionary["\(type.rawValue).email"] = manualEnrollmentConfiguration.email
        dataDictionary["\(type.rawValue).street"] = manualEnrollmentConfiguration.streetAddress
        dataDictionary["\(type.rawValue).street2"] = manualEnrollmentConfiguration.apartmentNumber
        dataDictionary["\(type.rawValue).city"] = manualEnrollmentConfiguration.city
        dataDictionary["\(type.rawValue).state"] = manualEnrollmentConfiguration.state
        dataDictionary["\(type.rawValue).postalCode"] = manualEnrollmentConfiguration.zipCode
        dataDictionary["\(type.rawValue).driversLicense"] = manualEnrollmentConfiguration.driversLicense
        dataDictionary["\(type.rawValue).driversLicenseIssuingState"] = manualEnrollmentConfiguration.driversLicenseIssuingState
        dataDictionary["\(type.rawValue).ssn"] = manualEnrollmentConfiguration.ssn
        dataDictionary["\(type.rawValue).gender"] = manualEnrollmentConfiguration.gender
        dataDictionary["\(type.rawValue).dob"] = manualEnrollmentConfiguration.dob
        dataDictionary["\(type.rawValue).organizationId"] = ConfigurationManager.shared.mainScreenConfiguration?.threatmetrix?.orgId
        dataDictionary["\(type.rawValue).memberSince"] = manualEnrollmentConfiguration.memberSince
        dataDictionary["\(WidgetType.CPEnrollmentTAndCWidget.rawValue).pin"] = manualEnrollmentConfiguration.pin
        dataDictionary["\(type.rawValue).genericFlag1"] = manualEnrollmentConfiguration.genericFlag1
        dataDictionary["\(type.rawValue).genericFlag2"] = manualEnrollmentConfiguration.genericFlag2
        dataDictionary["\(type.rawValue).genericFlag3"] = manualEnrollmentConfiguration.genericFlag3
        dataDictionary["\(type.rawValue).genericCode1"] = manualEnrollmentConfiguration.genericCode1
        dataDictionary["\(type.rawValue).genericCode2"] = manualEnrollmentConfiguration.genericCode2
        dataDictionary["\(type.rawValue).genericCode3"] = manualEnrollmentConfiguration.genericCode3
        dataDictionary["\(type.rawValue).reportingField1"] = manualEnrollmentConfiguration.reportingField1
        dataDictionary["\(type.rawValue).reportingField2"] = manualEnrollmentConfiguration.reportingField2
        dataDictionary["\(type.rawValue).reportingField3"] = manualEnrollmentConfiguration.reportingField3
        if let phoneNumbers = manualEnrollmentConfiguration.phoneNumbers {
            for phoneIndex in phoneNumbers.indices {
                let configuration = manualEnrollmentConfiguration.phoneNumbers![phoneIndex]
                dataDictionary["\(type.rawValue).phone[\(phoneIndex)].number"] = configuration.phoneNumber
                dataDictionary["\(type.rawValue).phone[\(phoneIndex)].type"] = configuration.type
            }
        }
        return dataDictionary
    }
}

/**********************************************************
 *
 * Update Enrollment Flow
 *
 **********************************************************/
//MARK: Update Enrollment Flow
@objc public class UpdateEnrollment: BaseCPFlow {
    private override init() {}
    fileprivate init(cpSdkConfiguration:CPSdkConfiguration, updateEnrollmentConfiguration:ManualEnrollmentConfiguration) {
        super.init()
        self.cpSdkConfiguration = cpSdkConfiguration
        self.updateEnrollmentConfiguration = updateEnrollmentConfiguration
        ConfigurationManager.shared.cpSdkFlow = .updateEnrollment
    }
    
    override func _getDataDictionary(forWidgetType type: WidgetType) -> [String : String]? {
        var dataDictionary = [String:String]()
        dataDictionary["\(type.rawValue).routingNumber"] = updateEnrollmentConfiguration.routingNumber
        dataDictionary["\(type.rawValue).accountNumber"] = updateEnrollmentConfiguration.accountNumber
        dataDictionary["\(type.rawValue).accountType"] = updateEnrollmentConfiguration.accountType
        dataDictionary["\(type.rawValue).onlineBankTransactionId"] = updateEnrollmentConfiguration.onlineBankTransactionId
        dataDictionary["\(type.rawValue).connectPayPaymentNumber"] = updateEnrollmentConfiguration.cpCardNumber
        dataDictionary["\(type.rawValue).firstName"] = updateEnrollmentConfiguration.firstName
        dataDictionary["\(type.rawValue).lastName"] = updateEnrollmentConfiguration.lastName
        dataDictionary["\(type.rawValue).email"] = updateEnrollmentConfiguration.email
        dataDictionary["\(type.rawValue).street"] = updateEnrollmentConfiguration.streetAddress
        dataDictionary["\(type.rawValue).street2"] = updateEnrollmentConfiguration.apartmentNumber
        dataDictionary["\(type.rawValue).city"] = updateEnrollmentConfiguration.city
        dataDictionary["\(type.rawValue).state"] = updateEnrollmentConfiguration.state
        dataDictionary["\(type.rawValue).postalCode"] = updateEnrollmentConfiguration.zipCode
        dataDictionary["\(type.rawValue).driversLicense"] = updateEnrollmentConfiguration.driversLicense
        dataDictionary["\(type.rawValue).driversLicenseIssuingState"] = updateEnrollmentConfiguration.driversLicenseIssuingState
        dataDictionary["\(type.rawValue).ssn"] = updateEnrollmentConfiguration.ssn
        dataDictionary["\(type.rawValue).gender"] = updateEnrollmentConfiguration.gender
        dataDictionary["\(type.rawValue).dob"] = updateEnrollmentConfiguration.dob
        dataDictionary["\(type.rawValue).pin"] = updateEnrollmentConfiguration.pin
        dataDictionary["\(type.rawValue).pinNew"] = updateEnrollmentConfiguration.newPin
        dataDictionary["\(type.rawValue).organizationId"] = ConfigurationManager.shared.mainScreenConfiguration?.threatmetrix?.orgId
        if let phoneNumbers = updateEnrollmentConfiguration.phoneNumbers {
            for phoneIndex in phoneNumbers.indices {
                let configuration = updateEnrollmentConfiguration.phoneNumbers![phoneIndex]
                dataDictionary["\(type.rawValue).phone[\(phoneIndex)].number"] = configuration.phoneNumber
                dataDictionary["\(type.rawValue).phone[\(phoneIndex)].type"] = configuration.type
            }
        }
        return dataDictionary
    }
}

/**********************************************************
 *
 * Enrollment Account Detail Flow
 *
 **********************************************************/
//MARK: Enrollment Account Detail Flow
@objc public class EnrollmentAccountDetails: BaseCPFlow {
    private override init() {}
    fileprivate init(cpSdkConfiguration:CPSdkConfiguration, enrollmentAccountDetailConfiguration:ManualEnrollmentConfiguration) {
        super.init()
        self.cpSdkConfiguration = cpSdkConfiguration
        self.enrollmentAccountDetailConfiguration = enrollmentAccountDetailConfiguration
        ConfigurationManager.shared.cpSdkFlow = .accountDetails
    }
    
    override func _getDataDictionary(forWidgetType type: WidgetType) -> [String : String]? {
        var dataDictionary = [String:String]()
        dataDictionary["\(type.rawValue).routingNumber"] = enrollmentAccountDetailConfiguration.routingNumber
        dataDictionary["\(type.rawValue).accountNumber"] = enrollmentAccountDetailConfiguration.accountNumber
        dataDictionary["\(type.rawValue).accountType"] = enrollmentAccountDetailConfiguration.accountType
        dataDictionary["\(type.rawValue).onlineBankTransactionId"] = enrollmentAccountDetailConfiguration.onlineBankTransactionId
        dataDictionary["\(type.rawValue).connectPayPaymentNumber"] = enrollmentAccountDetailConfiguration.cpCardNumber
        dataDictionary["\(type.rawValue).firstName"] = enrollmentAccountDetailConfiguration.firstName
        dataDictionary["\(type.rawValue).lastName"] = enrollmentAccountDetailConfiguration.lastName
        dataDictionary["\(type.rawValue).email"] = enrollmentAccountDetailConfiguration.email
        dataDictionary["\(type.rawValue).street"] = enrollmentAccountDetailConfiguration.streetAddress
        dataDictionary["\(type.rawValue).street2"] = enrollmentAccountDetailConfiguration.apartmentNumber
        dataDictionary["\(type.rawValue).city"] = enrollmentAccountDetailConfiguration.city
        dataDictionary["\(type.rawValue).state"] = enrollmentAccountDetailConfiguration.state
        dataDictionary["\(type.rawValue).postalCode"] = enrollmentAccountDetailConfiguration.zipCode
        dataDictionary["\(type.rawValue).driversLicense"] = enrollmentAccountDetailConfiguration.driversLicense
        dataDictionary["\(type.rawValue).driversLicenseIssuingState"] = enrollmentAccountDetailConfiguration.driversLicenseIssuingState
        dataDictionary["\(type.rawValue).ssn"] = enrollmentAccountDetailConfiguration.ssn
        dataDictionary["\(type.rawValue).gender"] = enrollmentAccountDetailConfiguration.gender
        dataDictionary["\(type.rawValue).dob"] = enrollmentAccountDetailConfiguration.dob
        dataDictionary["\(WidgetType.CPEnrollmentTAndCWidget.rawValue).pin"] = enrollmentAccountDetailConfiguration.pin
        dataDictionary["\(type.rawValue).organizationId"] = ConfigurationManager.shared.mainScreenConfiguration?.threatmetrix?.orgId
        if let phoneNumbers = enrollmentAccountDetailConfiguration.phoneNumbers {
            for phoneIndex in phoneNumbers.indices {
                let configuration = enrollmentAccountDetailConfiguration.phoneNumbers![phoneIndex]
                dataDictionary["\(type.rawValue).phone[\(phoneIndex)].number"] = configuration.phoneNumber
                dataDictionary["\(type.rawValue).phone[\(phoneIndex)].type"] = configuration.type
            }
        }
        return dataDictionary
    }
}

/**********************************************************
 *
 * Manual Deposit Flow
 *
 **********************************************************/
//MARK: Manual Deposit Flow
@objc public class ManualDepositConfiguration: NSObject {
    @objc public var accountNumber: String?
    @objc public var firstDepositedAmount: String?
    @objc public var secondDepositedAmount: String?
}

@objc public class ManualDeposit: BaseCPFlow {
    private override init() {}
    fileprivate init(cpSdkConfiguration:CPSdkConfiguration, manualDepositConfiguration:ManualDepositConfiguration) {
        super.init()
        self.cpSdkConfiguration = cpSdkConfiguration
        self.manualDepositConfiguration = manualDepositConfiguration
        ConfigurationManager.shared.cpSdkFlow = .deposit
    }
    
    override func _getDataDictionary(forWidgetType type: WidgetType) -> [String : String]? {
        var dataDictionary = [String:String]()
        dataDictionary["\(type.rawValue).accountNumber"] = manualDepositConfiguration.accountNumber
        if let firstDepositedAmount = manualDepositConfiguration.firstDepositedAmount, firstDepositedAmount != "", !firstDepositedAmount.contains(".") {
            let formattedFirstAmount = "0." + String(firstDepositedAmount.prefix(2))
            dataDictionary["\(type.rawValue).firstDepositedAmount"] = formattedFirstAmount
        } else {
            dataDictionary["\(type.rawValue).firstDepositedAmount"] = manualDepositConfiguration.firstDepositedAmount
        }
        if let secondDepositedAmount = manualDepositConfiguration.secondDepositedAmount, secondDepositedAmount != "", !secondDepositedAmount.contains(".") {
            let formattedSecondAmount = "0." + String(secondDepositedAmount.prefix(2))
            dataDictionary["\(type.rawValue).secondDepositedAmount"] = formattedSecondAmount
        } else {
            dataDictionary["\(type.rawValue).secondDepositedAmount"] = manualDepositConfiguration.secondDepositedAmount
        }
        return dataDictionary
    }
}

/**********************************************************
 *
 * Account Validation Flow
 *
 **********************************************************/
//MARK: Account Validation Flow
@objc public class AccountValidationConfiguration: NSObject {
    @objc public var cpCardNumber: String?
    @objc public var pin: String?
}

@objc public class AccountValidation: BaseCPFlow {
    private override init() {}
    fileprivate init(cpSdkConfiguration:CPSdkConfiguration, accountValidationConfiguration:AccountValidationConfiguration) {
        super.init()
        self.cpSdkConfiguration = cpSdkConfiguration
        self.accountValidationConfiguration = accountValidationConfiguration
        ConfigurationManager.shared.cpSdkFlow = .load
    }
    
    override func _getDataDictionary(forWidgetType type: WidgetType) -> [String : String]? {
        var dataDictionary = [String:String]()
        dataDictionary["\(type.rawValue).connectPayPaymentNumber"] = accountValidationConfiguration.cpCardNumber
        dataDictionary["\(type.rawValue).pin"] = accountValidationConfiguration.pin
        return dataDictionary
    }
}
