sub init()
    m.top.functionName = "GetVodScreenData"
    print "VodScreenAPI.brs - [init] Initialized"
end sub

sub GetVodScreenData()
    print "VodScreenAPI.brs - [GetVodScreenData] Called"

    page = m.top.page
    vodType = m.top.vodType
    categoryType = m.top.categoryType
    print "VodScreenAPI.brs - [GetVodScreenData] Page: " + page.ToStr()
    print "VodScreenAPI.brs - [GetVodScreenData] VOD Type: " + vodType.ToStr()
    print "VodScreenAPI.brs - [GetVodScreenData] Category Type: " + categoryType.ToStr()
    
    ' Check what's actually stored in the registry
    authDataJson = RegRead("authData", "AUTH")
    print "VodScreenAPI.brs - [GetVodScreenData] Raw authData from registry: " + authDataJson
    
    if authDataJson <> invalid and authDataJson <> ""
        authData = ParseJson(authDataJson)
        if authData <> invalid
            print "VodScreenAPI.brs - [GetVodScreenData] Parsed authData: " + FormatJSON(authData)
            
            ' Check for both possible field names
            accessToken = ""
            if authData.accessToken <> invalid
                accessToken = authData.accessToken
                print "VodScreenAPI.brs - [GetVodScreenData] Found accessToken (camelCase): " + accessToken.Len().ToStr() + " characters"
            else if authData.accesstoken <> invalid
                accessToken = authData.accesstoken
                print "VodScreenAPI.brs - [GetVodScreenData] Found accesstoken (lowercase): " + accessToken.Len().ToStr() + " characters"
            else
                print "VodScreenAPI.brs - [GetVodScreenData] ERROR: No accessToken or accesstoken field found"
                print "VodScreenAPI.brs - [GetVodScreenData] Available fields: " + FormatJSON(authData)
            end if
            
            if accessToken <> ""
                print "VodScreenAPI.brs - [GetVodScreenData] Access token retrieved: " + accessToken.Len().ToStr() + " characters"
                print "VodScreenAPI.brs - [GetVodScreenData] Token preview: " + Left(accessToken, 10) + "..."
            end if
        else
            print "VodScreenAPI.brs - [GetVodScreenData] ERROR: Failed to parse authData JSON"
            accessToken = ""
        end if
    else
        print "VodScreenAPI.brs - [GetVodScreenData] ERROR: No authData found in registry"
        accessToken = ""
    end if
    
    ' ALWAYS add Authorization header if we have a token (like CategoriesApi does)
    request = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    request.setMessagePort(port)

    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    if accessToken <> ""
        request.AddHeader("Authorization", "Bearer " + accessToken)
        print "VodScreenAPI.brs - [GetVodScreenData] Added Authorization header with token"
    else
        print "VodScreenAPI.brs - [GetVodScreenData] WARNING: No access token, proceeding without Authorization header"
    end if
    request.InitClientCertificates()
    
    baseUrl = "https://joygo.tulix.net/api/content/"
    url = baseUrl + vodType.ToStr() + "/" + categoryType.ToStr() + "/list"
    print "VodScreenAPI.brs - [GetVodScreenData] Request URL: " + url
    print "VodScreenAPI.brs - [GetVodScreenData] Full request details - URL: " + url + ", Token: " + Left(accessToken, 10) + "..."

    request.SetUrl(url)
    print "VodScreenAPI.brs - [GetVodScreenData] Sending GET request..."

    if request.AsyncGetToString()
        print "VodScreenAPI.brs - [GetVodScreenData] Request sent successfully, waiting for response..."
        while true
            msg = wait(0, port)
            print "VodScreenAPI.brs - [GetVodScreenData] Message received, type: " + type(msg)
            
            if type(msg) = "roUrlEvent"
                code = msg.GetResponseCode()
                body = msg.GetString()
                print "VodScreenAPI.brs - [GetVodScreenData] HTTP Status Code: " + code.ToStr()
                print "VodScreenAPI.brs - [GetVodScreenData] Response body length: " + body.Len().ToStr()
                print "VodScreenAPI.brs - [GetVodScreenData] Raw response: " + body
                
                if code = 200 or code = 206
                    print "VodScreenAPI.brs - [GetVodScreenData] SUCCESS: Valid status code"
                    response = ParseJson(msg.GetString())
                    if response <> invalid
                        print "VodScreenAPI.brs - [GetVodScreenData] JSON parsed successfully"
                        print "VodScreenAPI.brs - [GetVodScreenData] Response data: " + FormatJSON(response)
                        
                        if response.data <> invalid
                            if response.data.count() = 0
                                print "VodScreenAPI.brs - [GetVodScreenData] WARNING: Empty data array"
                                m.top.responseData = "empty"
                            else
                                print "VodScreenAPI.brs - [GetVodScreenData] Data array has " + response.data.count().ToStr() + " items"
                                m.top.responseData = msg.GetString()
                            end if
                        else
                            print "VodScreenAPI.brs - [GetVodScreenData] WARNING: No data field in response"
                            m.top.responseData = msg.GetString()
                        end if
                    else
                        print "VodScreenAPI.brs - [GetVodScreenData] ERROR: Failed to parse JSON"
                        m.top.responseData = "ParseError"
                    end if
                else
                    print "VodScreenAPI.brs - [GetVodScreenData] ERROR: Invalid status code: " + code.ToStr()
                    m.top.responseData = "Error"
                end if
                exit while
            else if msg = invalid
                print "VodScreenAPI.brs - [GetVodScreenData] Message is invalid, canceling request"
                request.AsyncCancel()
            end if
        end while
    else
        print "VodScreenAPI.brs - [GetVodScreenData] ERROR: Failed to send request"
        m.top.responseData = "RequestFailed"
    end if

    print "VodScreenAPI.brs - [GetVodScreenData] Final responseData: " + m.top.responseData
    print "VodScreenAPI.brs - [GetVodScreenData] Function completed"
end sub

function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    return sec.Read(key)
end function

