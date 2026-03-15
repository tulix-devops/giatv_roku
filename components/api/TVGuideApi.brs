sub init()
    m.top.functionName = "GetTVGuideData"
end sub

sub GetTVGuideData()
    url = "https://giatv.dineo.uk/api/tvguide"

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
    
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.InitClientCertificates()
    request.SetUrl(url)
    request.AddHeader("Content-Type", "application/json")
    request.AddHeader("Accept", "application/json")
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    
    authData = RetrieveAuthData()
    if authData <> invalid and authData.accessToken <> invalid and authData.accessToken <> ""
        request.AddHeader("Authorization", "Bearer " + authData.accessToken)
    end if
    
    if request.AsyncGetToString()
        msg = Wait(15000, port)
        if msg <> invalid
            response = msg.GetString()
        else
            print "TVGuideApi.brs - [ERROR] Request timed out"
            m.top.errorMessage = "TV Guide request timed out"
            return
        end if
    else
        print "TVGuideApi.brs - [ERROR] Failed to start request"
        m.top.errorMessage = "Failed to start TV Guide request"
        return
    end if
    
    if response <> "" and response <> invalid
        parsedResponse = ParseJson(response)
        if parsedResponse <> invalid
            if GetInterface(parsedResponse, "ifArray") <> invalid
                m.top.responseData = response
            else
                m.top.responseData = response
            end if
        else
            print "TVGuideApi.brs - [ERROR] Failed to parse JSON"
            m.top.errorMessage = "Failed to parse TV Guide data"
        end if
    else
        print "TVGuideApi.brs - [ERROR] Empty response"
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
    section = "AUTH"
    sec = CreateObject("roRegistrySection", section)
    if sec = invalid then return invalid
    
    if not sec.Exists("authData") then return invalid
    
    jsonData = sec.Read("authData")
    if jsonData = invalid or jsonData = "" then return invalid
    
    data = ParseJson(jsonData)
    if data = invalid then return invalid
    
    currentTime = CreateObject("roDateTime").asSeconds()
    if data.expiry <> invalid and currentTime > data.expiry then return invalid
    
    if data.accessToken <> invalid and data.accessToken <> "" then return data
    
    return invalid
end function
