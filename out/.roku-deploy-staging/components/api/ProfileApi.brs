sub init()

    ' m.top.authToken = m.top.findNode("authToken")
    m.top.observeField("authToken", "authTokenChanged")
end sub


sub authTokenChanged()
    if m.top.authToken <> invalid or m.top.authToken <> ""
        m.top.functionName = "GetProfileData"
        m.top.control = "RUN"
    end if

end sub


sub GetProfileData()
    print "ProfileApi.brs - [ProfileApi] Called"
    if m.top.authToken <> invalid or m.top.authToken <> ""
        baseUrl = ""


        authToken = m.top.authToken

        request = CreateObject("roUrlTransfer")
        port = CreateObject("roMessagePort")
        request.setMessagePort(port)

        request.SetCertificatesFile("common:/certs/ca-bundle.crt")
        request.AddHeader("Authorization", "Bearer " + authToken)
        request.InitClientCertificates()

        request.SetUrl(baseUrl)

        if request.AsyncGetToString()
            while true
                msg = wait(0, port)
                if type(msg) = "roUrlEvent"
                    code = msg.GetResponseCode()
                    body = msg.GetString()
                    print code
                    print "What is Code itself?"
                    if code = 200
                        response = ParseJson(msg.GetString())
                        print msg.GetString()
                        m.top.responseData = msg.GetString()
                     
                    else
                        m.top.responseData = "Error"
                    end if
                    exit while
                else if msg = invalid
                    request.AsyncCancel()
                end if
            end while
        end if
    end if




    ' return invalid
end sub



function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    ' return invalid
    return sec.Read(key)
end function

