sub init()
    m.timer = m.top.findNode("splashTimer")
    m.timer.control = "start"
    m.timer.observeField("fire", "onTimerFire")
end sub

sub onTimerFire()
    print "SplashScreen.brs - [onTimerFire] Splash timer fired"
    
    m.authData = RetrieveAuthData()
    print "SplashScreen.brs - [onTimerFire] Auth data: "
    print m.authData
    
    ' Hide splash screen
    m.top.visible = false
    
    ' Get the parent scene (HomeScene)
    parentScene = m.top.getScene()
    
    if m.authData <> invalid
        if m.authData.accessToken <> invalid
            authToken = m.authData.accessToken
            print "SplashScreen.brs - [onTimerFire] User is authenticated with token"
        end if
    else
        print "SplashScreen.brs - [onTimerFire] User is not authenticated"
    end if
    
    ' Show the navigation bar and home screen via the parent scene
    ' The dynamic_navigation_bar will be made visible when it receives navigation data
    if parentScene <> invalid
        print "SplashScreen.brs - [onTimerFire] Calling showNavigationAndHomeScreen on parent scene"
        parentScene.callFunc("showNavigationAndHomeScreen")
    else
        print "SplashScreen.brs - [onTimerFire] ERROR: Could not get parent scene"
        
        ' Fallback: try to find and show navigation bar directly
        dynamicNavBar = m.top.getScene().findNode("dynamic_navigation_bar")
        if dynamicNavBar <> invalid
            print "SplashScreen.brs - [onTimerFire] Found dynamic_navigation_bar, making visible"
            dynamicNavBar.visible = true
            dynamicNavBar.setFocus(true)
        end if
    end if
end sub






function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)
    ' Check if the JSON data is valid
    if jsonData <> invalid and jsonData <> ""
        ' Deserialize the JSON string back into an associative array
        data = ParseJson(jsonData)
        currentTime = CreateObject("roDateTime").asSeconds()

        ' Check if the data is expired
        if currentTime <= data.expiry
            ' Data is valid
            return data
        else
            ' Data is expired
            return invalid
        end if
    else
        ' No valid data found
        return invalid
    end if
end function


function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    ' return invalid
    return sec.Read(key)
end function