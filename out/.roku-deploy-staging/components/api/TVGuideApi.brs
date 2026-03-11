sub init()
    m.top.functionName = "GetTVGuideData"
    print "TVGuideApi.brs - [init] Initialized"
end sub

sub GetTVGuideData()
    print "TVGuideApi.brs - [GetTVGuideData] ========================================"
    print "TVGuideApi.brs - [GetTVGuideData] Starting TV Guide API request"
    print "TVGuideApi.brs - [GetTVGuideData] ========================================"

    ' Create HTTP request for TV Guide data
    url = "https://giatv.dineo.uk/api/tvguide"

    ' Optional: request for a specific date (backend may ignore if unsupported)
    dayOffset = 0
    if m.top.dayOffset <> invalid
        dayOffset = m.top.dayOffset
    end if

    if dayOffset <> 0
        targetDate = CreateObject("roDateTime")
        targetDate.ToLocalTime()
        targetSeconds = targetDate.AsSeconds() + (dayOffset * 86400)
        targetDate.FromSeconds(targetSeconds)
        targetDate.ToLocalTime()

        yearStr = targetDate.GetYear().ToStr()
        monthVal = targetDate.GetMonth()
        dayVal = targetDate.GetDayOfMonth()

        monthStr = monthVal.ToStr()
        if monthVal < 10 then monthStr = "0" + monthStr
        dayStr = dayVal.ToStr()
        if dayVal < 10 then dayStr = "0" + dayStr

        url = url + "?date=" + yearStr + "-" + monthStr + "-" + dayStr
    end if
    print "TVGuideApi.brs - [GetTVGuideData] Making request to: " + url
    
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()
    request.SetUrl(url)
    request.AddHeader("Content-Type", "application/json")
    request.AddHeader("Accept", "application/json")
    
    ' Set timeout to 30 seconds to avoid indefinite hanging
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    
    ' Retrieve and add authentication token
    authData = RetrieveAuthData()
    if authData <> invalid and authData.accessToken <> invalid and authData.accessToken <> ""
        request.AddHeader("Authorization", "Bearer " + authData.accessToken)
        print "TVGuideApi.brs - [GetTVGuideData] Making request WITH authentication token"
    else
        print "TVGuideApi.brs - [GetTVGuideData] WARNING: No valid auth token found, making request without authentication"
    end if
    
    ' Make the async request with timeout
    print "TVGuideApi.brs - [GetTVGuideData] About to make HTTP request..."
    if request.AsyncGetToString()
        ' Wait for response with 30 second timeout
        msg = Wait(30000, port)
        if msg <> invalid
            response = msg.GetString()
        else
            print "TVGuideApi.brs - [GetTVGuideData] Request timed out after 30 seconds"
            m.top.errorMessage = "TV Guide request timed out"
            return
        end if
    else
        print "TVGuideApi.brs - [GetTVGuideData] Failed to start async request"
        m.top.errorMessage = "Failed to start TV Guide request"
        return
    end if
    
    print "TVGuideApi.brs - [GetTVGuideData] ========================================"
    print "TVGuideApi.brs - [GetTVGuideData] Response received"
    print "TVGuideApi.brs - [GetTVGuideData] Response Length: " + response.Len().ToStr() + " characters"
    print "TVGuideApi.brs - [GetTVGuideData] ========================================"
    
    if response <> "" and response <> invalid
        ' Parse and analyze the response
        parsedResponse = ParseJson(response)
        if parsedResponse <> invalid
            ' Check if response is an array (list of channels)
            if GetInterface(parsedResponse, "ifArray") <> invalid
                channelCount = parsedResponse.Count()
                print "TVGuideApi.brs - [GetTVGuideData] ========================================"
                print "TVGuideApi.brs - [GetTVGuideData] PARSED DATA ANALYSIS:"
                print "TVGuideApi.brs - [GetTVGuideData] Total channels received: " + channelCount.ToStr()
                print "TVGuideApi.brs - [GetTVGuideData] ========================================"
                
                ' Log details of first few channels
                maxChannelsToLog = 5
                if channelCount < maxChannelsToLog then maxChannelsToLog = channelCount
                
                for i = 0 to maxChannelsToLog - 1
                    channel = parsedResponse[i]
                    if channel <> invalid
                        print "TVGuideApi.brs - [GetTVGuideData] ----------------------------------------"
                        print "TVGuideApi.brs - [GetTVGuideData] Channel " + (i + 1).ToStr() + ":"
                        print "TVGuideApi.brs - [GetTVGuideData]   ID: " + getStringValue(channel.id)
                        print "TVGuideApi.brs - [GetTVGuideData]   Name: " + getStringValue(channel.name)
                        print "TVGuideApi.brs - [GetTVGuideData]   Language: " + getStringValue(channel.language)
                        print "TVGuideApi.brs - [GetTVGuideData]   Icon: " + getStringValue(channel.icon)
                        print "TVGuideApi.brs - [GetTVGuideData]   HTTP URL: " + getStringValue(channel.http)
                        print "TVGuideApi.brs - [GetTVGuideData]   Amagi: " + getStringValue(channel.amagi)
                        print "TVGuideApi.brs - [GetTVGuideData]   FluChannel: " + getStringValue(channel.fluchannel)
                        print "TVGuideApi.brs - [GetTVGuideData]   FreeLive: " + getStringValue(channel.freelive)
                        print "TVGuideApi.brs - [GetTVGuideData]   Package: " + getStringValue(channel.package)
                        
                        ' Log shows info
                        if channel.shows <> invalid and GetInterface(channel.shows, "ifArray") <> invalid
                            showCount = channel.shows.Count()
                            print "TVGuideApi.brs - [GetTVGuideData]   Shows count: " + showCount.ToStr()
                            
                            ' Log first 2 shows
                            maxShowsToLog = 2
                            if showCount < maxShowsToLog then maxShowsToLog = showCount
                            
                            for j = 0 to maxShowsToLog - 1
                                show = channel.shows[j]
                                if show <> invalid
                                    print "TVGuideApi.brs - [GetTVGuideData]     Show " + (j + 1).ToStr() + ":"
                                    print "TVGuideApi.brs - [GetTVGuideData]       Name: " + getStringValue(show.name)
                                    print "TVGuideApi.brs - [GetTVGuideData]       Start: " + getStringValue(show.start)
                                    print "TVGuideApi.brs - [GetTVGuideData]       End: " + getStringValue(show.end)
                                    print "TVGuideApi.brs - [GetTVGuideData]       Duration: " + getStringValue(show.duration)
                                    print "TVGuideApi.brs - [GetTVGuideData]       Description: " + Left(getStringValue(show.longdescription), 80) + "..."
                                    print "TVGuideApi.brs - [GetTVGuideData]       URL: " + getStringValue(show.url)
                                end if
                            end for
                        else
                            print "TVGuideApi.brs - [GetTVGuideData]   Shows: No shows data"
                        end if
                    end if
                end for
                
                if channelCount > maxChannelsToLog
                    print "TVGuideApi.brs - [GetTVGuideData] ----------------------------------------"
                    print "TVGuideApi.brs - [GetTVGuideData] ... and " + (channelCount - maxChannelsToLog).ToStr() + " more channels"
                end if
                
                print "TVGuideApi.brs - [GetTVGuideData] ========================================"
                print "TVGuideApi.brs - [GetTVGuideData] TV Guide data successfully parsed"
                print "TVGuideApi.brs - [GetTVGuideData] ========================================"
                
                m.top.responseData = response
            else
                print "TVGuideApi.brs - [GetTVGuideData] ERROR: Response is not an array"
                print "TVGuideApi.brs - [GetTVGuideData] Response type: " + Type(parsedResponse)
                m.top.responseData = response
            end if
        else
            print "TVGuideApi.brs - [GetTVGuideData] ERROR: Failed to parse JSON response"
            print "TVGuideApi.brs - [GetTVGuideData] Raw response (first 500 chars): " + Left(response, 500)
            m.top.errorMessage = "Failed to parse TV Guide data"
        end if
    else
        print "TVGuideApi.brs - [GetTVGuideData] ERROR: Empty response from server"
        m.top.errorMessage = "No response from TV Guide API"
        m.top.responseData = ""
    end if
end sub

function getStringValue(value as dynamic) as string
    if value = invalid
        return "null"
    else if Type(value) = "roString" or Type(value) = "String"
        return value
    else if Type(value) = "roInt" or Type(value) = "roInteger" or Type(value) = "Integer"
        return value.ToStr()
    else if Type(value) = "roFloat" or Type(value) = "Float" or Type(value) = "Double"
        return Str(value)
    else
        return Type(value)
    end if
end function

function RetrieveAuthData() as object
    print "TVGuideApi.brs - [RetrieveAuthData] Retrieving authentication data"
    
    ' Read from AUTH section, authData key (same as NavigationApi)
    section = "AUTH"
    sec = CreateObject("roRegistrySection", section)
    if sec = invalid
        print "TVGuideApi.brs - [RetrieveAuthData] Could not create registry section"
        return invalid
    end if
    
    if not sec.Exists("authData")
        print "TVGuideApi.brs - [RetrieveAuthData] authData key does not exist"
        return invalid
    end if
    
    jsonData = sec.Read("authData")
    if jsonData = invalid or jsonData = ""
        print "TVGuideApi.brs - [RetrieveAuthData] authData is empty"
        return invalid
    end if
    
    data = ParseJson(jsonData)
    if data = invalid
        print "TVGuideApi.brs - [RetrieveAuthData] Failed to parse authData JSON"
        return invalid
    end if
    
    ' Check if token is expired
    currentTime = CreateObject("roDateTime").asSeconds()
    if data.expiry <> invalid and currentTime > data.expiry
        print "TVGuideApi.brs - [RetrieveAuthData] Auth token expired"
        return invalid
    end if
    
    if data.accessToken <> invalid and data.accessToken <> ""
        print "TVGuideApi.brs - [RetrieveAuthData] Found access token (length: " + data.accessToken.Len().ToStr() + ")"
        return data
    end if
    
    print "TVGuideApi.brs - [RetrieveAuthData] No access token found in auth data"
    return invalid
end function
