sub init()
    m.top.functionName = "GetHomeScreenData"
    print "HomeScreenAPI.brs - [init] Initialized"
end sub

sub GetHomeScreenData()
    print "HomeScreenAPI.brs - [GetHomeScreenData] Called"

    ' Check what's actually stored in the registry
    authDataJson = RegRead("authData", "AUTH")
    print "HomeScreenAPI.brs - [GetHomeScreenData] Raw authData from registry: " + authDataJson
    
    accessToken = ""
    
    if authDataJson <> invalid and authDataJson <> ""
        authData = ParseJson(authDataJson)
        if authData <> invalid
            print "HomeScreenAPI.brs - [GetHomeScreenData] Parsed authData: " + FormatJSON(authData)
            
            ' Check for both possible field names
            if authData.accessToken <> invalid
                accessToken = authData.accessToken
                print "HomeScreenAPI.brs - [GetHomeScreenData] Found accessToken (camelCase): " + accessToken.Len().ToStr() + " characters"
            else if authData.accesstoken <> invalid
                accessToken = authData.accesstoken
                print "HomeScreenAPI.brs - [GetHomeScreenData] Found accesstoken (lowercase): " + accessToken.Len().ToStr() + " characters"
            else
                print "HomeScreenAPI.brs - [GetHomeScreenData] ERROR: No accessToken or accesstoken field found"
                print "HomeScreenAPI.brs - [GetHomeScreenData] Available fields: " + FormatJSON(authData)
            end if
        else
            print "HomeScreenAPI.brs - [GetHomeScreenData] ERROR: Failed to parse authData JSON"
        end if
    else
        print "HomeScreenAPI.brs - [GetHomeScreenData] ERROR: No authData found in registry"
    end if
    
    ' Also check the old way for comparison
    oldAccessToken = RegRead("accessToken", "AUTH")
    print "HomeScreenAPI.brs - [GetHomeScreenData] Old method accessToken: " + oldAccessToken
    
    ' If no token found, return empty data structure instead of error string
    if accessToken = ""
        print "HomeScreenAPI.brs - [GetHomeScreenData] ERROR: No valid access token available"
        ' Return empty data structure that won't break JSON parsing
        emptyResponse = {
            "data": {}
        }
        m.top.responseData = FormatJSON(emptyResponse)
        return
    end if
    
    request = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    request.setMessagePort(port)

    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("Authorization", "Bearer " + accessToken)
    request.AddHeader("Content-Type", "application/json")
    request.InitClientCertificates()
    
    ' baseUrl = "https://joygo.tulix.net/api/content/1/featured-list"
    baseUrl = "https://joygo.tulix.net/api/content/home"
    print "HomeScreenAPI.brs - [GetHomeScreenData] Request URL: " + baseUrl

    request.SetUrl(baseUrl)
    print "HomeScreenAPI.brs - [GetHomeScreenData] Sending GET request..."

    if request.AsyncGetToString()
        while true
            msg = wait(0, port)
            
            if type(msg) = "roUrlEvent"
                code = msg.GetResponseCode()
                body = msg.GetString()
                print "HomeScreenAPI.brs - [GetHomeScreenData] Status: " + code.ToStr() + ", Length: " + body.Len().ToStr()
                
                if code = 200 or code = 206
                    response = ParseJson(msg.GetString())
                    if response <> invalid
                        m.top.responseData = msg.GetString()
                    else
                        print "HomeScreenAPI.brs - [GetHomeScreenData] ERROR: Failed to parse JSON"
                        ' Return empty data structure instead of error string
                        emptyResponse = {
                            "data": {}
                        }
                        m.top.responseData = FormatJSON(emptyResponse)
                    end if
                else if code = 401
                    print "HomeScreenAPI.brs - [GetHomeScreenData] ERROR: Unauthorized (401) - Token may be expired"
                    ' Return empty data structure for unauthorized
                    emptyResponse = {
                        "data": {}
                    }
                    m.top.responseData = FormatJSON(emptyResponse)
                else
                    print "HomeScreenAPI.brs - [GetHomeScreenData] ERROR: Invalid status code: " + code.ToStr()
                    ' Return empty data structure instead of error string
                    emptyResponse = {
                        "data": {}
                    }
                    m.top.responseData = FormatJSON(emptyResponse)
                end if
                exit while
            else if msg = invalid
                print "HomeScreenAPI.brs - [GetHomeScreenData] Message is invalid, canceling request"
                request.AsyncCancel()
            end if
        end while
    else
        print "HomeScreenAPI.brs - [GetHomeScreenData] ERROR: Failed to send request"
        ' Return empty data structure instead of error string
        emptyResponse = {
            "data": {}
        }
        m.top.responseData = FormatJSON(emptyResponse)
    end if

    print "HomeScreenAPI.brs - [GetHomeScreenData] Final responseData: " + m.top.responseData
    print "HomeScreenAPI.brs - [GetHomeScreenData] Function completed"
end sub

function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    return sec.Read(key)
end function

