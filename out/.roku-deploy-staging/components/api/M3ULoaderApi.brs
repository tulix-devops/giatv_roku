sub init()
    print "M3ULoaderApi.brs - [init] *** INITIALIZING M3U LOADER TASK ***"
    m.top.functionName = "LoadM3UPlaylist"
    print "M3ULoaderApi.brs - [init] functionName set to: LoadM3UPlaylist"
    print "M3ULoaderApi.brs - [init] Initialization complete"
end sub

sub LoadM3UPlaylist()
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] =========================================="
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] *** FUNCTION CALLED ***"
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] =========================================="
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] Full URL: " + m.top.m3uUrl
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] URL Length: " + Len(m.top.m3uUrl).ToStr()
    
    if m.top.m3uUrl = "" or m.top.m3uUrl = invalid
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] ERROR: Invalid URL"
        m.top.errorMessage = "Invalid M3U URL"
        return
    end if
    
    ' Parse URL to show components
    urlLower = LCase(m.top.m3uUrl)
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] URL Analysis:"
    if Instr(1, urlLower, "username=") > 0 or Instr(1, urlLower, "password=") > 0
        print "M3ULoaderApi.brs - [LoadM3UPlaylist]   - Contains username/password parameters"
    end if
    if Instr(1, urlLower, "get.php") > 0
        print "M3ULoaderApi.brs - [LoadM3UPlaylist]   - Looks like an IPTV provider API (get.php)"
    end if
    if Instr(1, urlLower, ".m3u") > 0
        print "M3ULoaderApi.brs - [LoadM3UPlaylist]   - Direct .m3u file"
    end if
    
    ' Create URL transfer object
    request = CreateObject("roUrlTransfer")
    request.SetUrl(m.top.m3uUrl)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    request.RetainBodyOnError(true)
    request.SetConnectionTimeout(60000)  ' Increased to 60s for IPTV providers (can be slow)
    
    ' Extract base URL for Referer/Origin headers (e.g., http://server:port/)
    baseUrl = ""
    if Instr(1, m.top.m3uUrl, "://") > 0
        ' Find the protocol and host
        protocolEnd = Instr(1, m.top.m3uUrl, "://")
        afterProtocol = Mid(m.top.m3uUrl, protocolEnd + 3)
        pathStart = Instr(1, afterProtocol, "/")
        if pathStart > 0
            baseUrl = Left(m.top.m3uUrl, protocolEnd + 2 + pathStart - 1)
        else
            baseUrl = m.top.m3uUrl
        end if
    end if
    
    ' Add headers that IPTV providers typically expect
    request.AddHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
    request.AddHeader("Accept", "*/*")
    request.AddHeader("Accept-Encoding", "identity")  ' Don't request compression
    request.AddHeader("Connection", "keep-alive")
    
    ' Add Referer and Origin headers (some IPTV providers require these)
    if baseUrl <> ""
        request.AddHeader("Referer", baseUrl)
        request.AddHeader("Origin", baseUrl)
    end if
    
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] HTTP Request Configuration:"
    print "M3ULoaderApi.brs - [LoadM3UPlaylist]   - Timeout: 60000ms (60s)"
    print "M3ULoaderApi.brs - [LoadM3UPlaylist]   - SSL Verification: Disabled"
    print "M3ULoaderApi.brs - [LoadM3UPlaylist]   - Retain Body On Error: Enabled"
    print "M3ULoaderApi.brs - [LoadM3UPlaylist]   - User-Agent: Chrome/Windows (to avoid blocking)"
    print "M3ULoaderApi.brs - [LoadM3UPlaylist]   - Accept-Encoding: identity (no compression)"
    if baseUrl <> ""
        print "M3ULoaderApi.brs - [LoadM3UPlaylist]   - Referer: " + baseUrl
        print "M3ULoaderApi.brs - [LoadM3UPlaylist]   - Origin: " + baseUrl
    end if
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] Making HTTP request..."
    
    ' Use async request with message port for better timeout control
    port = CreateObject("roMessagePort")
    request.SetPort(port)
    
    if not request.AsyncGetToString()
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] ERROR: Failed to start async request"
        m.top.errorMessage = "Failed to start HTTP request"
        return
    end if
    
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] Waiting for response (timeout: 60s)..."
    
    ' Wait for response with timeout
    timeoutMs = 60000
    startTime = CreateObject("roDateTime").AsSeconds()
    response = invalid
    lastLogTime = 0
    
    while true
        msg = port.WaitMessage(1000)  ' Check every second
        
        if msg <> invalid and Type(msg) = "roUrlEvent"
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] =========================================="
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] HTTP Request Completed"
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] =========================================="
            response = msg.GetString()
            exit while
        end if
        
        ' Check timeout
        elapsedSec = CreateObject("roDateTime").AsSeconds() - startTime
        if elapsedSec * 1000 > timeoutMs
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] ERROR: Request timed out after " + elapsedSec.ToStr() + " seconds"
            m.top.errorMessage = "Request timed out - server not responding"
            request.AsyncCancel()
            return
        end if
        
        ' Log progress every 5 seconds
        if elapsedSec >= lastLogTime + 5
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] Still waiting... (" + elapsedSec.ToStr() + "s elapsed)"
            lastLogTime = elapsedSec
        end if
    end while
    
    ' Check response first before getting code
    if response = invalid
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] ERROR: Response is INVALID (network error or timeout)"
        m.top.errorMessage = "Network error - failed to connect to server"
        return
    end if
    
    ' Check if response is empty
    if response = ""
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] ERROR: Response is EMPTY STRING"
        m.top.errorMessage = "Empty response - server returned no data"
        return
    end if
    
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response received! Length: " + response.Len().ToStr() + " bytes"
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] First 100 chars: " + Left(response, 100)
    
    ' Quick check if response looks like M3U data
    responseStart = Left(response.Trim(), 7)
    looksLikeM3U = (responseStart = "#EXTM3U" or responseStart = "#EXTINF")
    looksLikeHTML = (Instr(1, LCase(Left(response, 100)), "<html") > 0 or Instr(1, LCase(Left(response, 100)), "<!doctype") > 0)
    
    if looksLikeM3U
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response appears to be valid M3U data!"
        responseCode = 200  ' Assume success if data looks valid
    else if looksLikeHTML
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] WARNING: Response appears to be HTML (error page?)"
        responseCode = 404  ' Assume error
    else
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response format unclear, attempting to get HTTP status..."
        ' Only try GetResponseCode if we're unsure about the response
        ' Note: This can hang on some network conditions
        responseCode = request.GetResponseCode()
        if responseCode < 0
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] ERROR: Invalid response code: " + responseCode.ToStr()
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] This usually means network timeout or DNS failure"
            m.top.errorMessage = "Connection failed (code " + responseCode.ToStr() + ")"
            return
        end if
    end if
    
    print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response Code: " + responseCode.ToStr()
    
    ' Skip getting headers if we already have valid M3U data
    ' GetResponseHeaders() can hang on certain network conditions
    if looksLikeM3U
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] Skipping response headers (have valid M3U data)"
    else
        ' Only get headers if we need to debug an issue
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] Attempting to get response headers..."
        responseHeaders = request.GetResponseHeaders()
        if responseHeaders <> invalid and Type(responseHeaders) = "roAssociativeArray"
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response Headers:"
            for each key in responseHeaders
                print "M3ULoaderApi.brs - [LoadM3UPlaylist]   " + key + ": " + responseHeaders[key]
            end for
        else
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] No response headers available"
        end if
    end if
    
    ' Check for HTTP error codes
    if responseCode >= 400
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] =========================================="
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] HTTP ERROR: " + responseCode.ToStr()
        errorType = "Unknown Error"
        if responseCode = 404
            errorType = "Not Found (404) - URL does not exist"
        else if responseCode = 403
            errorType = "Forbidden (403) - Access denied"
        else if responseCode = 401
            errorType = "Unauthorized (401) - Authentication required"
        else if responseCode >= 500
            errorType = "Server Error (" + responseCode.ToStr() + ") - Server problem"
        end if
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] Error type: " + errorType
        
        ' Show response body if available (error pages can be helpful)
        if response <> invalid and response <> ""
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] Error response body (first 300 chars):"
            errPreview = 300
            if response.Len() < errPreview then errPreview = response.Len()
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] " + Left(response, errPreview)
        end if
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] =========================================="
        
        m.top.errorMessage = "HTTP " + responseCode.ToStr() + ": " + errorType
        return
    end if
    
    ' Success case: HTTP 200-299
    if response <> invalid and response <> ""
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] =========================================="
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] SUCCESS - Response received"
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response length: " + response.Len().ToStr() + " bytes"
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] =========================================="
        
        ' For large files (>1MB), skip detailed analysis to speed up loading
        if response.Len() > 1000000
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] Large file detected (" + (response.Len() / 1024).ToStr() + " KB)"
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] Skipping detailed analysis to speed up loading"
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] First 200 chars: " + Left(response, 200)
        else
            ' Show first 500 characters of response
            previewLength = 500
            if response.Len() < previewLength then previewLength = response.Len()
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response preview (first " + previewLength.ToStr() + " chars):"
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] " + Left(response, previewLength)
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] =========================================="
            
            ' Count lines in response
            lines = response.Split(Chr(10))
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] Total lines in response: " + lines.Count().ToStr()
            
            ' Count #EXTINF entries (only for smaller files)
            extinfCount = 0
            for each line in lines
                if Left(line.Trim(), 7) = "#EXTINF"
                    extinfCount = extinfCount + 1
                end if
            end for
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] Number of #EXTINF entries found: " + extinfCount.ToStr()
        end if
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] =========================================="
        
        ' Success! Pass response to screen for parsing
        m.top.responseData = response
    else
        ' Got HTTP 200-299 but no response body - this is weird
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] =========================================="
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] ERROR: Empty response with success code"
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] =========================================="
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response Code: " + responseCode.ToStr()
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response body is empty despite success code"
        if response = invalid
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response type: INVALID"
        else if response = ""
            print "M3ULoaderApi.brs - [LoadM3UPlaylist] Response type: EMPTY STRING"
        end if
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] This could indicate a server-side issue or empty playlist"
        print "M3ULoaderApi.brs - [LoadM3UPlaylist] =========================================="
        m.top.errorMessage = "Empty M3U response (HTTP " + responseCode.ToStr() + ")"
    end if
end sub
