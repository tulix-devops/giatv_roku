sub init()
    m.top.functionName = "GetLiveScreenData"
    print "LiveScreenAPI.brs - [init] Initialized"
end sub

sub GetLiveScreenData()
    print "LiveScreenAPI.brs - [GetLiveScreenData] Called"

    ' Check what's actually stored in the registry
    authDataJson = RegRead("authData", "AUTH")
    print "LiveScreenAPI.brs - [GetLiveScreenData] Raw authData from registry: " + authDataJson
    
    if authDataJson <> invalid and authDataJson <> ""
        authData = ParseJson(authDataJson)
        if authData <> invalid
            print "LiveScreenAPI.brs - [GetLiveScreenData] Parsed authData: " + FormatJSON(authData)
            if authData.accessToken <> invalid
                accessToken = authData.accessToken
                print "LiveScreenAPI.brs - [GetLiveScreenData] Access token retrieved: " + accessToken.Len().ToStr() + " characters"
            else
                print "LiveScreenAPI.brs - [GetLiveScreenData] ERROR: No accessToken in authData"
                accessToken = ""
            end if
        else
            print "LiveScreenAPI.brs - [GetLiveScreenData] ERROR: Failed to parse authData JSON"
            accessToken = ""
        end if
    else
        print "LiveScreenAPI.brs - [GetLiveScreenData] ERROR: No authData found in registry"
        accessToken = ""
    end if
    
    if accessToken = ""
        print "LiveScreenAPI.brs - [GetLiveScreenData] ERROR: No valid access token available"
        m.top.responseData = "NoAuthToken"
        return
    end if
    
    request = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    request.setMessagePort(port)

    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.AddHeader("Authorization", "Bearer " + accessToken)
    request.InitClientCertificates()

    baseUrl = "https://wchupload.tulix.net/api/content/"
    url = baseUrl + "3" + "/list"
    print "LiveScreenAPI.brs - [GetLiveScreenData] Request URL: " + url

    request.SetUrl(url)
    print "LiveScreenAPI.brs - [GetLiveScreenData] Sending GET request..."

    if request.AsyncGetToString()
        print "LiveScreenAPI.brs - [GetLiveScreenData] Request sent successfully, waiting for response..."
        while true
            msg = wait(0, port)
            print "LiveScreenAPI.brs - [GetLiveScreenData] Message received, type: " + type(msg)
            
            if type(msg) = "roUrlEvent"
                code = msg.GetResponseCode()
                body = msg.GetString()
                print "LiveScreenAPI.brs - [GetLiveScreenData] HTTP Status Code: " + code.ToStr()
                print "LiveScreenAPI.brs - [GetLiveScreenData] Response body length: " + body.Len().ToStr()
                print "LiveScreenAPI.brs - [GetLiveScreenData] Raw response: " + body
                
                if code = 200 or code = 206
                    print "LiveScreenAPI.brs - [GetLiveScreenData] SUCCESS: Valid status code"
                    response = ParseJson(msg.GetString())
                    if response <> invalid
                        print "LiveScreenAPI.brs - [GetLiveScreenData] JSON parsed successfully"
                        print "LiveScreenAPI.brs - [GetLiveScreenData] Response data: " + FormatJSON(response)
                        m.top.responseData = msg.GetString()
                        print "LiveScreenAPI.brs - [GetLiveScreenData] Response data set successfully"
                    else
                        print "LiveScreenAPI.brs - [GetLiveScreenData] ERROR: Failed to parse JSON"
                        m.top.responseData = "ParseError"
                    end if
                else
                    print "LiveScreenAPI.brs - [GetLiveScreenData] ERROR: Invalid status code: " + code.ToStr()
                    m.top.responseData = "Error"
                end if
                exit while
            else if msg = invalid
                print "LiveScreenAPI.brs - [GetLiveScreenData] Message is invalid, canceling request"
                request.AsyncCancel()
            end if
        end while
    else
        print "LiveScreenAPI.brs - [GetLiveScreenData] ERROR: Failed to send request"
        m.top.responseData = "RequestFailed"
    end if

    print "LiveScreenAPI.brs - [GetLiveScreenData] Final responseData: " + m.top.responseData
    print "LiveScreenAPI.brs - [GetLiveScreenData] Function completed"
end sub

function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    return sec.Read(key)
end function

