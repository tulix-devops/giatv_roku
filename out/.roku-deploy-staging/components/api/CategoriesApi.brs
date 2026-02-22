sub init()
    m.top.functionName = "GetCategoriesData"
    print "CategoriesAPI.brs - [init] Initialized"
end sub

sub GetCategoriesData()
    print "CategoriesAPI.brs - [GetCategoriesData] Called"
    print "CategoriesAPI.brs - [GetCategoriesData] TypeID: " + m.top.typeID.ToStr()
    
    if m.top.typeID <> invalid or m.top.typeID <> ""
        ' Check what's actually stored in the registry
        authDataJson = RegRead("authData", "AUTH")
        print "CategoriesAPI.brs - [GetCategoriesData] Raw authData from registry: " + authDataJson
        
        if authDataJson <> invalid and authDataJson <> ""
            authData = ParseJson(authDataJson)
            if authData <> invalid
                print "CategoriesAPI.brs - [GetCategoriesData] Parsed authData: " + FormatJSON(authData)
                if authData.accessToken <> invalid
                    accessToken = authData.accessToken
                    print "CategoriesAPI.brs - [GetCategoriesData] Access token retrieved: " + accessToken.Len().ToStr() + " characters"
                else
                    print "CategoriesAPI.brs - [GetCategoriesData] ERROR: No accessToken in authData"
                    accessToken = ""
                end if
            else
                print "CategoriesAPI.brs - [GetCategoriesData] ERROR: Failed to parse authData JSON"
                accessToken = ""
            end if
        else
            print "CategoriesAPI.brs - [GetCategoriesData] ERROR: No authData found in registry"
            accessToken = ""
        end if
        
        baseUrl = "https://joygo.tulix.net/api/category/"
        finalUrl = baseUrl + m.top.typeID.ToStr() + "/list"
        print "CategoriesAPI.brs - [GetCategoriesData] Request URL: " + finalUrl

        request = CreateObject("roUrlTransfer")
        port = CreateObject("roMessagePort")
        request.setMessagePort(port)

        request.SetCertificatesFile("common:/certs/ca-bundle.crt")
        request.AddHeader("Authorization", "Bearer " + accessToken)
        request.InitClientCertificates()

        request.SetUrl(finalUrl)
        print "CategoriesAPI.brs - [GetCategoriesData] Sending GET request..."

        if request.AsyncGetToString()
            print "CategoriesAPI.brs - [GetCategoriesData] Request sent successfully, waiting for response..."
            while true
                msg = wait(0, port)
                print "CategoriesAPI.brs - [GetCategoriesData] Message received, type: " + type(msg)
                
                if type(msg) = "roUrlEvent"
                    code = msg.GetResponseCode()
                    body = msg.GetString()
                    print "CategoriesAPI.brs - [GetCategoriesData] HTTP Status Code: " + code.ToStr()
                    print "CategoriesAPI.brs - [GetCategoriesData] Response body length: " + body.Len().ToStr()
                    print "CategoriesAPI.brs - [GetCategoriesData] Raw response: " + body
                    
                    if code = 200
                        print "CategoriesAPI.brs - [GetCategoriesData] SUCCESS: Status 200"
                        response = ParseJson(msg.GetString())
                        if response <> invalid
                            print "CategoriesAPI.brs - [GetCategoriesData] JSON parsed successfully"
                            print "CategoriesAPI.brs - [GetCategoriesData] Response data: " + FormatJSON(response)
                            m.top.responseData = msg.GetString()
                            print "CategoriesAPI.brs - [GetCategoriesData] Response data set successfully"
                        else
                            print "CategoriesAPI.brs - [GetCategoriesData] ERROR: Failed to parse JSON"
                            m.top.responseData = "ParseError"
                        end if
                    else
                        print "CategoriesAPI.brs - [GetCategoriesData] ERROR: Invalid status code: " + code.ToStr()
                        m.top.responseData = "Error"
                    end if
                    exit while
                else if msg = invalid
                    print "CategoriesAPI.brs - [GetCategoriesData] Message is invalid, canceling request"
                    request.AsyncCancel()
                end if
            end while
        else
            print "CategoriesAPI.brs - [GetCategoriesData] ERROR: Failed to send request"
            m.top.responseData = "RequestFailed"
        end if
    else
        print "CategoriesAPI.brs - [GetCategoriesData] ERROR: TypeID is invalid or empty"
        m.top.responseData = "InvalidTypeID"
    end if

    print "CategoriesAPI.brs - [GetCategoriesData] Final responseData: " + m.top.responseData
    print "CategoriesAPI.brs - [GetCategoriesData] Function completed"
end sub

function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    return sec.Read(key)
end function

