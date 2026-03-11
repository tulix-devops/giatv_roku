sub init()
    ' m.top.functionName = "GetLiveScreenData"
    m.top.keyword = m.top.findNode("keyword")
    m.top.observeField("keyword", "keywordUpdated")
    print "SearchScreenAPI.brs - [init] Initialized"
end sub

sub keywordUpdated()
    if m.top.keyword <> invalid or m.top.keyword <> ""
        m.top.functionName = "GetVideosByKeyword"
        m.top.control = "RUN"
    end if
end sub

sub GetVideosByKeyword()
    print "SearchScreenAPI.brs - [GetVideosByKeyword] Called"
    print "SearchScreenAPI.brs - [GetVideosByKeyword] Keyword: " + m.top.keyword

    if m.top.keyword <> invalid or m.top.keyword <> ""
        ' Check what's actually stored in the registry
        authDataJson = RegRead("authData", "AUTH")
        print "SearchScreenAPI.brs - [GetVideosByKeyword] Raw authData from registry: " + authDataJson
        
        if authDataJson <> invalid and authDataJson <> ""
            authData = ParseJson(authDataJson)
            if authData <> invalid
                print "SearchScreenAPI.brs - [GetVideosByKeyword] Parsed authData: " + FormatJSON(authData)
                
                ' Check for both possible field names
                accessToken = ""
                if authData.accessToken <> invalid
                    accessToken = authData.accessToken
                    print "SearchScreenAPI.brs - [GetVideosByKeyword] Found accessToken (camelCase): " + accessToken.Len().ToStr() + " characters"
                else if authData.accesstoken <> invalid
                    accessToken = authData.accesstoken
                    print "SearchScreenAPI.brs - [GetVideosByKeyword] Found accesstoken (lowercase): " + accessToken.Len().ToStr() + " characters"
                else
                    print "SearchScreenAPI.brs - [GetVideosByKeyword] ERROR: No accessToken or accesstoken field found"
                    print "SearchScreenAPI.brs - [GetVideosByKeyword] Available fields: " + FormatJSON(authData)
                end if
                
                if accessToken <> ""
                    print "SearchScreenAPI.brs - [GetVideosByKeyword] Access token retrieved: " + accessToken.Len().ToStr() + " characters"
                    print "SearchScreenAPI.brs - [GetVideosByKeyword] Token preview: " + Left(accessToken, 10) + "..."
                end if
            else
                print "SearchScreenAPI.brs - [GetVideosByKeyword] ERROR: Failed to parse authData JSON"
                accessToken = ""
            end if
        else
            print "SearchScreenAPI.brs - [GetVideosByKeyword] ERROR: No authData found in registry"
            accessToken = ""
        end if
        
        request = CreateObject("roUrlTransfer")
        port = CreateObject("roMessagePort")
        request.setMessagePort(port)

        request.SetCertificatesFile("common:/certs/ca-bundle.crt")
        if accessToken <> ""
            request.AddHeader("Authorization", "Bearer " + accessToken)
            print "SearchScreenAPI.brs - [GetVideosByKeyword] Added Authorization header with token"
        else
            print "SearchScreenAPI.brs - [GetVideosByKeyword] WARNING: No access token, proceeding without Authorization header"
        end if
        request.AddHeader("Content-Type", "application/json")
        request.RetainBodyOnError(true)
        request.SetRequest("POST")
        request.InitClientCertificates()

        baseUrl = "https://joygo.tulix.net/api/content/search"
        keyword = m.top.keyword
        print "SearchScreenAPI.brs - [GetVideosByKeyword] Request URL: " + baseUrl

        data = {
            "search": keyword,
        }
        body = FormatJSON(data)
        print "SearchScreenAPI.brs - [GetVideosByKeyword] Request body: " + body
        request.SetUrl(baseUrl)

        if request.AsyncPostFromString(body)
            print "SearchScreenAPI.brs - [GetVideosByKeyword] Request sent successfully, waiting for response..."
            while true
                msg = wait(0, port)
                print "SearchScreenAPI.brs - [GetVideosByKeyword] Message received, type: " + type(msg)
                
                if type(msg) = "roUrlEvent"
                    code = msg.GetResponseCode()
                    body = msg.GetString()
                    print "SearchScreenAPI.brs - [GetVideosByKeyword] HTTP Status Code: " + code.ToStr()
                    print "SearchScreenAPI.brs - [GetVideosByKeyword] Response body length: " + body.Len().ToStr()
                    print "SearchScreenAPI.brs - [GetVideosByKeyword] Raw response: " + body
                    
                    if code = 200
                        print "SearchScreenAPI.brs - [GetVideosByKeyword] SUCCESS: Status 200"
                        response = ParseJson(msg.GetString())
                        if response <> invalid
                            print "SearchScreenAPI.brs - [GetVideosByKeyword] JSON parsed successfully"
                            print "SearchScreenAPI.brs - [GetVideosByKeyword] Response data: " + FormatJSON(response)
                            m.top.responseData = msg.GetString()
                            print "SearchScreenAPI.brs - [GetVideosByKeyword] Response data set successfully"
                        else
                            print "SearchScreenAPI.brs - [GetVideosByKeyword] ERROR: Failed to parse JSON"
                            m.top.responseData = "ParseError"
                        end if
                    else
                        print "SearchScreenAPI.brs - [GetVideosByKeyword] ERROR: Invalid status code: " + code.ToStr()
                        m.top.responseData = "Error"
                    end if
                    exit while
                else if msg = invalid
                    print "SearchScreenAPI.brs - [GetVideosByKeyword] Message is invalid, canceling request"
                    request.AsyncCancel()
                end if
            end while
        else
            print "SearchScreenAPI.brs - [GetVideosByKeyword] ERROR: Failed to send request"
            m.top.responseData = "RequestFailed"
        end if
    else
        print "SearchScreenAPI.brs - [GetVideosByKeyword] ERROR: Keyword is invalid or empty"
        m.top.responseData = "InvalidKeyword"
    end if

    print "SearchScreenAPI.brs - [GetVideosByKeyword] Final responseData: " + m.top.responseData
    print "SearchScreenAPI.brs - [GetVideosByKeyword] Function completed"
end sub

function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    return sec.Read(key)
end function

