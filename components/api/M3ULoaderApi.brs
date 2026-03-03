sub init()
    print "M3ULoaderApi.brs - [init] *** INITIALIZING M3U LOADER TASK ***"
    m.top.functionName = "LoadM3UPlaylist"
    print "M3ULoaderApi.brs - [init] functionName set to: LoadM3UPlaylist"
    print "M3ULoaderApi.brs - [init] Initialization complete"
end sub

sub LoadM3UPlaylist()
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] *** FUNCTION CALLED ***"
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] m3uUrl field: " + m.top.m3uUrl
    
    if m.top.m3uUrl = "" or m.top.m3uUrl = invalid
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] ERROR: Invalid URL"
        m.top.errorMessage = "Invalid M3U URL"
        return
    end if
    
    ' Create URL transfer object
    request = CreateObject("roUrlTransfer")
    request.SetUrl(m.top.m3uUrl)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    request.RetainBodyOnError(true)
    request.SetConnectionTimeout(10000)
    
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] Making HTTP request..."
    
    ' Make synchronous request (we're in a Task, so this is OK)
    response = request.GetToString()
    
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] Request completed"
    
    if response <> invalid and response <> ""
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] Success! Response length: " + response.Len().ToStr()
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response preview: " + Left(response, 200)
        m.top.responseData = response
    else
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] ERROR: Failed to load M3U"
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response is invalid or empty"
        if response = invalid
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response is invalid"
        else if response = ""
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response is empty string"
        end if
        m.top.errorMessage = "Failed to load M3U playlist"
    end if
end sub
