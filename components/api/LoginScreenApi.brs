sub init()
    m.top.functionName = "AttemptToLogin"
    m.top.email = m.top.findNode("email")
    m.top.password = m.top.findNode("password")

    ' m.store = CreateObject("roSGNode", "ChannelStore")
    ' info = CreateObject("roSGNode", "ContentNode")
    ' info.addFields({ context: "signin" })
    ' m.store.requestedUserDataInfo = info
    ' m.store.requestedUserData = "email"
    ' m.store.command = "getUserData"
    ' m.store.observefield("userData", "OnEmail")

end sub



sub AttemptToLogin()
    print "LoginScreenAPI.brs - [LoginScreenAPI] Called"

    print "login attempt Started"
    data = {
        "email": m.top.email,
        "password": m.top.password,
        "deviceInfo": "rokuTV",
    }
    print data
    print "attempt Login Data"

    body = FormatJSON(data)
    port = CreateObject("roMessagePort")
    request = CreateObject("roUrlTransfer")
    request.SetMessagePort(port)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.RetainBodyOnError(true)
    request.AddHeader("Content-Type", "application/json")
    request.SetRequest("POST")
    request.SetUrl("https://giatv.dineo.uk/api/login")
    requestSent = request.AsyncPostFromString(FormatJSON(data))
    if (requestSent)
        msg = wait(0, port)
        if (type(msg) = "roUrlEvent")
            statusCode = msg.GetResponseCode()
            print statusCode
            headers = msg.GetResponseHeaders()
            etag = headers["Etag"]
            body = msg.GetString()
            if statusCode = 405
                m.top.responseData = "405"
                return
            end if
            
            parsedBody = ParseJSON(body)
            print "LoginScreenApi.brs - [AttemptToLogin] *** FULL RESPONSE BODY ***"
            print parsedBody 
            
            if parsedBody = invalid
                print "LoginScreenApi.brs - [AttemptToLogin] ERROR: Could not parse response body"
                m.top.responseData = "405"
                return
            endif

            print "LoginScreenApi.brs - [AttemptToLogin] Response statusCode: " + parsedBody.statusCode.ToStr()
            print "LoginScreenApi.brs - [AttemptToLogin] Response message: " + parsedBody.message
            
            statusCode = parsedBody.statusCode
            if(statusCode = 200)
                print "LoginScreenApi.brs - [AttemptToLogin] *** LOGIN SUCCESS - PRINTING DATA ***"
                
                userData = parsedBody.data
                print "LoginScreenApi.brs - [AttemptToLogin] *** USER DATA OBJECT ***"
                print userData
                
                ' Print all available fields in the data object
                if userData <> invalid
                    print "LoginScreenApi.brs - [AttemptToLogin] --- Data Fields ---"
                    for each key in userData.Keys()
                        fieldValue = userData[key]
                        if Type(fieldValue) = "roAssociativeArray"
                            print "LoginScreenApi.brs - [AttemptToLogin] " + key + ": [Object]"
                            print fieldValue
                        else if Type(fieldValue) = "roArray"
                            print "LoginScreenApi.brs - [AttemptToLogin] " + key + ": [Array with " + fieldValue.Count().ToStr() + " items]"
                            print fieldValue
                        else
                            print "LoginScreenApi.brs - [AttemptToLogin] " + key + ": " + fieldValue.ToStr()
                        end if
                    end for
                    print "LoginScreenApi.brs - [AttemptToLogin] --- End Data Fields ---"
                    
                    ' Check for accessToken
                    if userData.accessToken <> invalid
                        accessToken = userData.accessToken
                        print "LoginScreenApi.brs - [AttemptToLogin] Access Token: " + accessToken
                    else
                        print "LoginScreenApi.brs - [AttemptToLogin] WARNING: No accessToken in response"
                        accessToken = ""
                    end if
                    
                    ' Check for user object and save to registry
                    if userData.user <> invalid
                        print "LoginScreenApi.brs - [AttemptToLogin] *** USER OBJECT ***"
                        print userData.user
                        for each userKey in userData.user.Keys()
                            userFieldValue = userData.user[userKey]
                            if Type(userFieldValue) = "roAssociativeArray" or Type(userFieldValue) = "roArray"
                                print "LoginScreenApi.brs - [AttemptToLogin] user." + userKey + ":"
                                print userFieldValue
                            else
                                print "LoginScreenApi.brs - [AttemptToLogin] user." + userKey + ": " + userFieldValue.ToStr()
                            end if
                        end for
                        
                        ' Save user data to registry for use on Account screen
                        SaveUserData(userData.user)
                    else
                        ' If user data is directly in userData (flat structure)
                        print "LoginScreenApi.brs - [AttemptToLogin] Checking for flat user data structure..."
                        if userData.email <> invalid or userData.name <> invalid
                            print "LoginScreenApi.brs - [AttemptToLogin] Found flat user data, saving..."
                            SaveUserData(userData)
                        end if
                    end if
                    
                    SaveAuthData(accessToken, false, true)
                    m.top.responseData = "Success"
                else
                    print "LoginScreenApi.brs - [AttemptToLogin] ERROR: userData is invalid"
                    m.top.responseData = "Error"
                end if
            else 
                print "LoginScreenApi.brs - [AttemptToLogin] Login failed with statusCode: " + statusCode.ToStr()
                m.top.responseData = "Error"
            end if
        end if
    end if

end sub


sub OnEmail()
    if m.store.userData <> invalid
        email = m.store.userData.email
        print email
        print "Email I want to Check please."
    end if
end sub



function SaveAuthData(accessToken as string, subscribed as boolean, isauth as boolean)
    section = "AUTH"
    sec = CreateObject("roRegistrySection", section)
    if subscribed
        subscribedValue = 1
    else
        subscribedValue = 0
    end if

    if isauth
        isAuthValue = 1
    else
        isAuthValue = 0
    end if

    currentTime = CreateObject("roDateTime").asSeconds()
    expiryTime = currentTime + 10 * 24 * 60 * 60

    data = {
        accessToken: accessToken,
        subscribed: subscribedValue,
        expiry: expiryTime,
        isauth: isAuthValue
    }
    jsonData = FormatJson(data)
    sec.Write("authData", jsonData)
    sec.Flush()
end function

function SaveUserData(userData as object)
    print "LoginScreenApi.brs - [SaveUserData] =========================================="
    print "LoginScreenApi.brs - [SaveUserData] *** SAVING USER DATA TO REGISTRY ***"
    print "LoginScreenApi.brs - [SaveUserData] =========================================="
    
    if userData = invalid
        print "LoginScreenApi.brs - [SaveUserData] ERROR: userData is invalid"
        return invalid
    end if
    
    print "LoginScreenApi.brs - [SaveUserData] Input userData:"
    print FormatJson(userData)
    
    section = "AUTH"
    sec = CreateObject("roRegistrySection", section)
    
    ' Extract user fields
    userDataToSave = {
        id: 0,
        name: "",
        lastname: "",
        email: "",
        hasPaymentMethod: false,
        productId: invalid,
        statusId: invalid
    }
    
    if userData.id <> invalid
        userDataToSave.id = userData.id
    end if
    
    if userData.name <> invalid
        userDataToSave.name = userData.name
    end if
    
    if userData.lastname <> invalid
        userDataToSave.lastname = userData.lastname
    end if
    
    if userData.email <> invalid
        userDataToSave.email = userData.email
    end if
    
    if userData.hasPaymentMethod <> invalid
        userDataToSave.hasPaymentMethod = userData.hasPaymentMethod
    end if
    
    if userData.productId <> invalid
        userDataToSave.productId = userData.productId
    end if
    
    if userData.statusId <> invalid
        userDataToSave.statusId = userData.statusId
    end if
    
    jsonData = FormatJson(userDataToSave)
    print "LoginScreenApi.brs - [SaveUserData] JSON to save: " + jsonData
    
    sec.Write("userData", jsonData)
    sec.Flush()
    
    ' Verify the data was saved by reading it back
    verifyData = sec.Read("userData")
    print "LoginScreenApi.brs - [SaveUserData] Verification - read back: " + verifyData
    
    if verifyData = jsonData
        print "LoginScreenApi.brs - [SaveUserData] *** USER DATA SAVED AND VERIFIED SUCCESSFULLY ***"
    else
        print "LoginScreenApi.brs - [SaveUserData] WARNING: Saved data doesn't match verification read!"
    end if
    
    return userDataToSave
end function

function ClearUserData()
    print "LoginScreenApi.brs - [ClearUserData] Clearing user data from registry"
    section = "AUTH"
    sec = CreateObject("roRegistrySection", section)
    sec.Delete("userData")
    sec.Flush()
end function

function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)
    if jsonData <> invalid and jsonData <> ""
        data = ParseJson(jsonData)
        currentTime = CreateObject("roDateTime").asSeconds()
        if currentTime <= data.expiry
            return data
        else
            return invalid
        end if
    else
        return invalid
    end if
end function






function RegWrite(key, val, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
    sec.Flush() 'commit it
end function


function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    ' return invalid
    return sec.Read(key)
end function

function RegDelete(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    sec.Flush()
end function

