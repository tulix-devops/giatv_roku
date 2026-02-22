sub init()
    m.top.observeField("transactionId", "transactionIdChanged")
end sub



sub transactionIdChanged()
    if m.top.authToken <> invalid or m.top.authToken <> ""
        m.top.functionName = "validateSubscription"
        m.top.control = "RUN"
    end if
end sub

sub validateSubscription()
    print "ValidateSubscriptionApi.brs - [ValidateSubscriptionApi Verify Subscription] Called"

    if m.top.keyword <> invalid or m.top.keyword <> ""
        authToken = m.top.authToken
        transactionId = m.top.transactionId

        request = CreateObject("roUrlTransfer")
        port = CreateObject("roMessagePort")
        request.setMessagePort(port)

        request.SetCertificatesFile("common:/certs/ca-bundle.crt")
        request.AddHeader("Authorization", "Bearer " + authToken)
        request.AddHeader("Content-Type", "application/json")
        request.RetainBodyOnError(true)
        request.SetRequest("POST")
        request.InitClientCertificates()
        baseUrl = "https://pockochannel.13.bozztv.com/api/subscriptions/roku/verify"

        data = {
            "transactionId": transactionId,
            "accessToken" : authToken,
        }
        body = FormatJSON(data)
        request.SetUrl(baseUrl)

        if request.AsyncPostFromString(body)
            while true
                msg = wait(0, port)
                if type(msg) = "roUrlEvent"
                    code = msg.GetResponseCode()
                    body = msg.GetString()
                    print code
                    print "Code is here"
                    if code = 200
                        response = ParseJson(msg.GetString())
                        m.top.responseData = msg.GetString()
                        ' print msg.GetString()
                        ' return response
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

end sub





Function ToString(variable As Dynamic) As String
    If Type(variable) = "roInt" Or Type(variable) = "roInteger" Or Type(variable) = "roFloat" Or Type(variable) = "Float" Then
        Return Str(variable).Trim()
    Else If Type(variable) = "roBoolean" Or Type(variable) = "Boolean" Then
        If variable = True Then
            Return "True"
        End If
        Return "False"
    Else If Type(variable) = "roString" Or Type(variable) = "String" Then
        Return variable
    Else
        Return Type(variable)
    End If
End Function

