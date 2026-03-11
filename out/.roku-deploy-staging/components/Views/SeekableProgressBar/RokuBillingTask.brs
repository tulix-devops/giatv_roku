' ********** Copyright 2015 Roku Corp.  All Rights Reserved. **********

' Component initialization
sub init()
    print "RokuBillingTask"
    
    m.top.bHasValidSubscription = false
end sub


' onChange handler for "indexPurchase" field. Calls PurchaseProduct function automatically.
sub On_indexPurchase()
    print "RokuBillingTask.brs - [On_indexPurchase] Called "
    if m.top.products <> invalid AND m.top.products.availForPurchase.list[m.top.indexPurchase] <> invalid then
        m.top.functionName = "PurchaseProduct"
        m.top.control = "RUN"
    end if
    print "RokuBillingTask.brs - [On_indexPurchase] Exiting "
end sub


' Task function for getting shared user data. Sets "partialUserData" field.
sub GetPartialUserData()
    print "RokuBillingTask.brs - [GetPartialUserData] Called "
    port = CreateObject("roMessagePort")
    channelStore = CreateObject("roChannelStore")
    channelStore.SetMessagePort(port)
    
    print "RokuBillingTask.brs - [GetPartialUserData] Invoking GetPartialUserData and m.top.userDataToShare " m.top.userDataToShare
    m.top.partialUserData = channelStore.GetPartialUserData(m.top.userDataToShare)
    'm.top.partialUserData = channelStore.GetPartialUserData("email,firstname,lastname,street1,street2,city,state,zip,country,phone")
    print "RokuBillingTask.brs - [GetPartialUserData] Exiting "
end sub


' Task function for getting Roku Billing subscription products. Sets "products" field.
sub GetProducts()

    print "RokuBillingTask.brs - [GetProducts] Called "
    result = {
        availForPurchase : {
            list : []
            map  : {}
        }
        validPurchased : {
            list : []
            map  : {}
        }
    }
    allProducts = Helper_GetAllProducts()
    purchasedProducts = Helper_GetPurchasedProducts()
    
    datetime = CreateObject("roDateTime")
    utimeNow = datetime.AsSeconds()
    productsName = CreateObject("roArray", 100, true)
    for each product in allProducts
        bAddToAvail = true
        print "RokuBillingTask.brs - [GetProducts]  Checking Product"; product
        for each purchase in purchasedProducts
            print "RokuBillingTask.brs - [GetProducts]  AGAINST PURCHSE"; purchase
            if purchase.code = product.code then
                bAddToAvail = false
                print "RokuBillingTask.brs - [GetProducts]  MATCHING CODES "; purchase.code
                if purchase.renewalDate = invalid then
                    print "RokuBillingTask.brs - [GetProducts] Since no Renewal Date, it means that the Subscription has been cancelled by User"
                    m.top.rokuCancelledOrderId = purchase.purchaseId 
                    m.top.bIsCancelledSubscription = true
                end if
                if purchase.expirationDate <> invalid then
                    print "RokuBillingTask.brs - [GetProducts]  Checking Expiry"; purchase.expirationDate
                    datetime.FromISO8601String(purchase.expirationDate)
                    utimeExpire = datetime.AsSeconds()
                    if utimeExpire > utimeNow then
                        print "RokuBillingTask.brs - [GetProducts]  Valid Product and Subscription found :-)"
'''''''''                        m.top.bHasValidSubscription = true
                        result.validPurchased.list.Push(purchase)
                        result.validPurchased.map[purchase.code] = purchase
                    else
                        print "RokuBillingTask.brs - [GetProducts]  We have a purchase but expired..."
                        m.top.isRokuPurchasedSubscriptionExpired = true
                        bAddToAvail = true
                    end if
                end if
                exit for
            end if
        end for
        
        if bAddToAvail then
            print "RokuBillingTask.brs - [GetProducts]  Adding UnPurchased Product"; product
            productsName.Push(product.name + "  " + product.cost)
            result.availForPurchase.list.Push(product)
            result.availForPurchase.map[product.code] = product
        end if
    end for

    m.top.rokuStoreSubscriptions = result.availForPurchase
    m.top.userRokuSubscriptions = result.validPurchased
    
    print "RokuBillingTask.brs - [GetProducts]  Exiting"

    m.top.products = result
    m.top.arrayProductsName = productsName
    print "RokuBillingTask.brs - [GetProducts] Exiting "
end sub


' Task function for purchasing Roku Billing product specified by "indexPurchase" field (see On_indexPurchase).
' Sets "purchaseResult" field.
sub PurchaseProduct()
    print "RokuBillingTask.brs - [PurchaseProduct] Called "
    port = CreateObject("roMessagePort")
    channelStore = CreateObject("roChannelStore")
    channelStore.SetMessagePort(port)
    
    channelStore.ClearOrder()
    channelStore.SetOrder([{
        code : m.top.products.availForPurchase.list[m.top.indexPurchase].code
        qty  : 1
    }])
    channelStore.DoOrder()
    msg = invalid
    while type(msg) <> "roChannelStoreEvent"
        msg = Wait(0, port)
    end while
    
    result = {
        isSuccess : msg.isRequestSucceeded()
    }
    if msg.isRequestSucceeded() then
        response = msg.GetResponse()
        if response <> invalid AND response[0] <> invalid then
            result.Append(response[0])
        end if
    else if msg.isRequestFailed() then
        result.failureCode = msg.GetStatus()
        result.failureMessage = msg.GetStatusMessage()
    end if
    
    m.top.purchaseResult = result
    
    print "RokuBillingTask.brs - [PurchaseProduct] Exiting "
end sub


' Helper function to get Roku Billing subscription products.
function Helper_GetAllProducts() as Object

    print "RokuBillingTask.brs - [Helper_GetAllProducts] Called "
    result = []
    
    port = CreateObject("roMessagePort")
    channelStore = CreateObject("roChannelStore")
    channelStore.SetMessagePort(port)
    
    channelStore.GetCatalog()
    msg = invalid
    while type(msg) <> "roChannelStoreEvent"
        msg = Wait(0, port)
    end while

    if msg.isRequestSucceeded() then
        response = msg.GetResponse()
        if response <> invalid then
            result = response
        end if
    end if
    
    print "RokuBillingTask.brs - [Helper_GetAllProducts] Exiting "
    return result
end function


' Helper function to get purchased Roku Billing products.
function Helper_GetPurchasedProducts()

    print "RokuBillingTask.brs - [Helper_GetPurchasedProducts] Called "
    result = []
    
    port = CreateObject("roMessagePort")
    channelStore = CreateObject("roChannelStore")
    channelStore.SetMessagePort(port)
    
    channelStore.GetPurchases()
    msg = invalid
    while type(msg) <> "roChannelStoreEvent"
        msg = Wait(0, port)
    end while

    if msg.isRequestSucceeded() then
        response = msg.GetResponse()
        if response <> invalid then
            result = response
        end if
    end if
    
    print "RokuBillingTask.brs - [Helper_GetPurchasedProducts] Exiting "
    return result
end function


