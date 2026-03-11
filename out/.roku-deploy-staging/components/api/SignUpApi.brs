sub init()
    m.top.functionName = "SignUp"
    m.top.email = m.top.findNode("email")
    m.top.password = m.top.findNode("password")
    m.top.repeatPassword = m.top.findNode("repeatPassword")
end sub



sub SignUp()
    print "SignUpApi.brs - [SignUpApi] Called"

    data = {
        "email": m.top.email,
        ' "email" : "test3@test.com"
        "password": m.top.password,
        "deviceInfo": "Roku Device",
        "repeatPassword": m.top.repeatPassword,
    }

    body = FormatJSON(data)
    port = CreateObject("roMessagePort")
    request = CreateObject("roUrlTransfer")
    request.SetMessagePort(port)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.RetainBodyOnError(true)
    request.AddHeader("Content-Type", "application/json")
    request.SetRequest("POST")
    request.SetUrl("https://giatv.dineo.uk/api/register")
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
            statusCode = parsedBody.statusCode
            if(statusCode = 200)
                
                print ParseJSON(body).data
                print "BODY"
             
              
                m.top.responseData = "Success"
            else m.top.responseData = "Error"
            end if

            json = ParseJSON(body)
            print json
        end if
    end if

   
end sub



