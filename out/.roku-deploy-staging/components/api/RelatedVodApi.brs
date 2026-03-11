sub init()

    m.top.relatedID = m.top.findNode("relatedID")
    m.top.typeID = m.top.findNode("typeID")
    m.top.observeField("relatedID", "relatedDataChanged")
end sub


sub relatedDataChanged()
    if m.top.relatedID <> invalid or m.top.relatedID <> ""
        m.top.functionName = "RelatedVodData"
        m.top.control = "RUN"
    end if

end sub


sub RelatedVodData()
    print "RelatedVodApi.brs - [RelatedVodApi] Called"
    print m.top.relatedID
    print "RelatedID"
    if m.top.relatedID <> invalid or m.top.relatedID <> "" or m.top.typeID <> invalid or m.top.typeID <> ""
        baseUrl = "https://joygo.tulix.net/api/content/related"
        

        
        relatedID = m.top.relatedID
        typeID = m.top.typeID
        
        fullUrl = baseUrl + "/" + typeID + "/" + relatedID
        print fullUrl
        print "Here is FullURl"
        accessToken = RegRead("accessToken", "AUTH")
        request = CreateObject("roUrlTransfer")
        port = CreateObject("roMessagePort")
        request.setMessagePort(port)

        request.SetCertificatesFile("common:/certs/ca-bundle.crt")
        request.AddHeader("Authorization", "Bearer " + accessToken)
        request.InitClientCertificates()

        request.SetUrl(fullUrl)

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
                        m.top.responseData = msg.GetString()
                    else
                        ' return invalid
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

