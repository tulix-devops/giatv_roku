function init()
    ? "[home_scene] init"
    
    ' Initialize Account screen as invalid to force recreation with proper contentTypeId
    m.accountScreen = invalid
    
    ' Initialize DVR screen management
    m.dvrScreen = invalid
    m.isDVRScreenVisible = false
    
    ' Initialize video player management
    m.videoPlayerScreen = invalid
    m.isVideoPlayerVisible = false
    m.previousScreenIndex = -1
    m.previousItemSelection = invalid
    
    ' Initialize navigation bars
    m.dynamicNavBar = m.top.findNode("dynamic_navigation_bar")
    m.verticalNavBar = m.top.findNode("vertical_navigation_bar")
    m.markupNavBar = m.top.findNode("markup_navigation_bar")
    
    ' Navigation system toggle
    ' 0 = original, 1 = vertical, 2 = markup
    m.navigationMode = 0  ' Set to 0 to use original dynamic navigation bar
    
    ' Initialize screen references
    m.dynamicScreensContainer = m.top.findNode("dynamicScreensContainer")
    m.homeBannerGroup = m.top.findNode("homeBannerGroup")
    
    ' Debug banner initialization
    if m.homeBannerGroup <> invalid
        print "HomeScene.brs - [init] Home banner group found successfully"
        print "HomeScene.brs - [init] Banner group visible: " + m.homeBannerGroup.visible.ToStr()
    else
        print "HomeScene.brs - [init] ERROR: Home banner group not found!"
    end if
    
    ' Global loader
    m.globalLoader = m.top.findNode("globalLoader")
    m.loaderText = m.top.findNode("loaderText")
    m.loadingDots = [
        m.top.findNode("dot1"),
        m.top.findNode("dot2"),
        m.top.findNode("dot3"),
        m.top.findNode("dot4")
    ]
    m.loadingAnimation = invalid
    
    ' Debug loader initialization
    print "HomeScene.brs - [init] globalLoader found: " + (m.globalLoader <> invalid).ToStr()
    print "HomeScene.brs - [init] loaderText found: " + (m.loaderText <> invalid).ToStr()
    if m.globalLoader <> invalid
        print "HomeScene.brs - [init] globalLoader visible: " + m.globalLoader.visible.ToStr()
        print "HomeScene.brs - [init] globalLoader translation: [" + m.globalLoader.translation[0].ToStr() + ", " + m.globalLoader.translation[1].ToStr() + "]"
    end if
    m.accountScreen = m.top.findNode("account_screen")
    m.loginScreen = m.top.findNode("login_screen")
    m.splashPage = m.top.findNode("splashPage")
    
    ' Note: Search screen removed from navigation
    
    ' Dynamic screens tracking
    m.dynamicContentScreens = CreateObject("roAssociativeArray")
    m.navigationItems = []
    
    ' Add fields for dynamic navigation handling
    m.top.addField("selectedNavIndex", "int", false)
    m.top.addField("handleDynamicNavigation", "string", false)
    ' setScreenFocus function is now declared in the interface
    
    ' Initialize current screen tracking
    m.currentScreen = invalid
    m.currentScreenIndex = -1
    
    ' Flag to prevent navigation index changes during initial load
    m.isInitialLoad = true
    
    ' Navigation mapping for dynamic items
    m.navigationMapping = {}
    
    m.showParentGroupAnimation = m.top.findNode("showNavigationAnimation")
    m.top.navBarUnfocused = m.top.findNode("navBarUnfocused")
    m.authToken = ""
    
    ' Check authentication and show appropriate screen
    checkAuthenticationAndShowScreen()
end function

sub showHomeScreen()
    m.homeScreen = m.top.findNode("home_screen")
end sub

sub checkAuthenticationAndShowScreen()
    print "HomeScene.brs - [checkAuthenticationAndShowScreen] Skipping authentication, showing navigation directly"
    
    ' Proceed immediately to show navigation and home screen
    showNavigationAndHomeScreen()
end sub


sub showNavigationAndHomeScreen()
    print "HomeScene.brs - [showNavigationAndHomeScreen] Showing navigation and home screen"
    
    ' Show home banner initially (since we start on Home screen)
    if m.homeBannerGroup <> invalid
        print "HomeScene.brs - [showNavigationAndHomeScreen] Showing home banner on app start"
        m.homeBannerGroup.visible = true
    else
        print "HomeScene.brs - [showNavigationAndHomeScreen] ERROR: Home banner group not found during startup!"
    end if
    
    ' Hide splash screen
    if m.splashPage <> invalid
        m.splashPage.visible = false
    end if
    
    ' Show appropriate navigation bar based on mode
    ' Hide all navigation bars first
    if m.dynamicNavBar <> invalid
        m.dynamicNavBar.visible = false
        m.dynamicNavBar.navHasFocus = false
    end if
    if m.verticalNavBar <> invalid
        m.verticalNavBar.visible = false
        m.verticalNavBar.navHasFocus = false
    end if
    if m.markupNavBar <> invalid
        m.markupNavBar.visible = false
        m.markupNavBar.navHasFocus = false
    end if
    
    if m.navigationMode = 2
        print "HomeScene.brs - [showNavigationAndHomeScreen] Using MARKUP navigation system (proven approach)"
        if m.markupNavBar <> invalid
            print "HomeScene.brs - [showNavigationAndHomeScreen] Initializing markup navigation"
            m.markupNavBar.visible = true
            m.markupNavBar.navHasFocus = true
            m.markupNavBar.setFocus(true)
            
            ' Listen for navigation data changes
            m.markupNavBar.observeField("navigationData", "onNavigationDataReceived")
            
            print "HomeScene.brs - [showNavigationAndHomeScreen] Markup navigation bar shown and focused"
        else
            print "HomeScene.brs - [showNavigationAndHomeScreen] ERROR: markupNavBar is invalid"
        end if
    else if m.navigationMode = 1
        print "HomeScene.brs - [showNavigationAndHomeScreen] Using VERTICAL navigation system"
        if m.verticalNavBar <> invalid
            print "HomeScene.brs - [showNavigationAndHomeScreen] Initializing vertical navigation"
            m.verticalNavBar.visible = true
            m.verticalNavBar.navHasFocus = true
            m.verticalNavBar.setFocus(true)
            
            ' Listen for navigation data changes
            m.verticalNavBar.observeField("navigationData", "onNavigationDataReceived")
            
            print "HomeScene.brs - [showNavigationAndHomeScreen] Vertical navigation bar shown and focused"
        else
            print "HomeScene.brs - [showNavigationAndHomeScreen] ERROR: verticalNavBar is invalid"
        end if
    else
        print "HomeScene.brs - [showNavigationAndHomeScreen] Using ORIGINAL navigation system"
        if m.dynamicNavBar <> invalid
            m.dynamicNavBar.visible = true
            m.dynamicNavBar.navHasFocus = true
            m.dynamicNavBar.setFocus(true)
            
            ' Force focus update to ensure proper initial state
            m.dynamicNavBar.callFunc("forceFocus")
            
            ' Listen for navigation data changes
            m.dynamicNavBar.observeField("navigationData", "onNavigationDataReceived")
            
            print "HomeScene.brs - [showNavigationAndHomeScreen] Original navigation bar shown"
        end if
    end if
    
    ' Show loader immediately when Home screen becomes visible
    print "HomeScene.brs - [showNavigationAndHomeScreen] Home screen visible, showing initialization loader"
    showGlobalLoader("Initializing Application...")
end sub

sub showLoginScreen()
    print "HomeScene.brs - [showLoginScreen] *** FUNCTION CALLED *** Showing login screen"
    
    ' Hide all other screens
    hideAllScreens()
    
    ' Show login screen
    if m.loginScreen <> invalid
        print "HomeScene.brs - [showLoginScreen] Login screen found, making visible and setting focus"
        m.loginScreen.visible = true
        m.loginScreen.setFocus(true)
    else
        print "HomeScene.brs - [showLoginScreen] ERROR: Login screen is invalid"
    end if
end sub

sub hideAllScreens()
    print "HomeScene.brs - [hideAllScreens] Hiding all screens"
    
    screens = [m.homeScreen, m.liveScreen, m.searchScreen, m.vodScreen, m.savedScreen, m.accountScreen, m.splashPage]
    
    for each screen in screens
        if screen <> invalid
            screen.visible = false
        end if
    end for
    
    ' Hide navigation bar
    if m.dynamicNavBar <> invalid
        m.dynamicNavBar.visible = false
    end if
end sub

function handleDynamicNavigation(index as integer)
    print "HomeScene.brs - [handleDynamicNavigation] Handling navigation to index: " + index.ToStr()
    
    showScreenByIndex(index)
    return true
end function

function setScreenFocus(index as integer)
    print "HomeScene.brs - [setScreenFocus] Setting focus for screen at index: " + index.ToStr()
    print "HomeScene.brs - [setScreenFocus] Current screen index: " + m.currentScreenIndex.ToStr()
    print "HomeScene.brs - [setScreenFocus] Total dynamic screens available: " + m.dynamicContentScreens.Count().ToStr()
    print "HomeScene.brs - [setScreenFocus] Available screen keys: " + FormatJson(m.dynamicContentScreens.Keys())
    
    ' Always allow screen switching to ensure proper synchronization
    ' Remove the "already on screen" check as it can cause sync issues
    print "HomeScene.brs - [setScreenFocus] Switching to screen " + index.ToStr() + " (was on " + m.currentScreenIndex.ToStr() + ")"
    
    ' Show the screen first
    print "HomeScene.brs - [setScreenFocus] About to call showScreenByIndex(" + index.ToStr() + ")"
    showScreenByIndex(index)
    
    ' After screen is shown, focus should return to navigation
    ' This is now handled by the dynamic content screen itself
    print "HomeScene.brs - [setScreenFocus] Screen shown, focus management delegated to content screen"
    
    return true
end function

function isInitialLoadPhase() as boolean
    ' Check if we're still in the initial load phase
    if m.isInitialLoad = invalid
        return false
    end if
    return m.isInitialLoad
end function

function switchScreenContent(index as integer)
    print "HomeScene.brs - [switchScreenContent] *** SWITCHING SCREEN CONTENT TO INDEX: " + index.ToStr() + " ***"
    print "HomeScene.brs - [switchScreenContent] Current screen index: " + m.currentScreenIndex.ToStr()
    print "HomeScene.brs - [switchScreenContent] Total dynamic screens: " + m.dynamicContentScreens.Count().ToStr()
    
    ' Debug what screen this should be
    if index < m.dynamicContentScreens.Count()
        indexStr = index.ToStr()
        if m.dynamicContentScreens.DoesExist(indexStr)
            screenInfo = m.dynamicContentScreens[indexStr]
            if screenInfo <> invalid
                print "HomeScene.brs - [switchScreenContent] Should show: " + screenInfo.navItem.title + " (contentTypeId: " + screenInfo.screen.contentTypeId.ToStr() + ")"
            end if
        end if
    else
        print "HomeScene.brs - [switchScreenContent] Index beyond dynamic screens - should be Account"
    end if
    
    ' Update navigation bar selected index to keep them in sync
    activeNavBar = invalid
    if m.navigationMode = 0
        activeNavBar = m.dynamicNavBar
    else if m.navigationMode = 1
        activeNavBar = m.verticalNavBar
    else if m.navigationMode = 2
        activeNavBar = m.markupNavBar
    end if
    
    if activeNavBar <> invalid and activeNavBar.selectedIndex <> index
        activeNavBar.selectedIndex = index
        print "HomeScene.brs - [switchScreenContent] Updated navigation selectedIndex to: " + index.ToStr()
    end if
    
    ' Switch to the requested screen
    print "HomeScene.brs - [switchScreenContent] About to call showScreenByIndex(" + index.ToStr() + ")"
    showScreenByIndex(index)
    
    ' Keep focus on navigation bar during UP/DOWN navigation for ALL screens including Account
    ' navHasFocus should only be set to false when user explicitly presses RIGHT
    print "HomeScene.brs - [switchScreenContent] Keeping focus on navigation bar for screen: " + index.ToStr()
    if activeNavBar <> invalid
        activeNavBar.setFocus(true)
        activeNavBar.navHasFocus = true
        if m.navigationMode = 0
            ' Only dynamicNavBar has focusUpdated method
            m.dynamicNavBar.callFunc("focusUpdated")
        end if
    end if
    
    return true
end function

sub repositionAllScreens(visibleIndex as integer)
    print "HomeScene.brs - [repositionAllScreens] Repositioning all screens, visible index: " + visibleIndex.ToStr()
    
    ' Go through all dynamic screens and position them correctly
    ' Screens are inside dynamicScreensContainer which handles the nav bar offset
    for each key in m.dynamicContentScreens.Keys()
        screenInfo = m.dynamicContentScreens[key]
        if screenInfo <> invalid and screenInfo.screen <> invalid
            screenIndex = Val(key)
            if screenIndex = visibleIndex
                ' Visible screen at origin inside container
                screenInfo.screen.translation = [0, 0]
                print "HomeScene.brs - [repositionAllScreens] Screen " + key + " positioned at [0, 0] (visible)"
            else
                ' Hide screen off-screen to the right to prevent peeking
                screenInfo.screen.translation = [2000, 0]
                print "HomeScene.brs - [repositionAllScreens] Screen " + key + " positioned at [2000, 0] (hidden)"
            end if
        end if
    end for
    
    ' Handle Account screen separately (last tab)
    ' Note: The STATIC account_screen is NOT inside dynamicScreensContainer
    accountIndex = getAccountScreenIndex()
    staticAccountScreen = m.top.findNode("account_screen")
    if visibleIndex = accountIndex and staticAccountScreen <> invalid
        staticAccountScreen.translation = [240, 0]  ' Right of 240px nav bar (static position)
        staticAccountScreen.visible = true
        print "HomeScene.brs - [repositionAllScreens] Account screen positioned at [240, 0] (visible)"
        
        ' Ensure all other screens are properly hidden when Account is visible
        for each key in m.dynamicContentScreens.Keys()
            screenInfo = m.dynamicContentScreens[key]
            if screenInfo <> invalid and screenInfo.screen <> invalid
                screenInfo.screen.visible = false
                print "HomeScene.brs - [repositionAllScreens] Hiding dynamic screen " + key + " while Account is visible"
            end if
        end for
    else if staticAccountScreen <> invalid
        staticAccountScreen.translation = [240, 5400]  ' Off-screen below
        staticAccountScreen.visible = false
        print "HomeScene.brs - [repositionAllScreens] Account screen positioned at [240, 5400] (hidden)"
        
        ' Restore visibility of the currently visible screen
        if visibleIndex >= 0 and visibleIndex < m.dynamicContentScreens.Count()
            indexStr = visibleIndex.ToStr()
            if m.dynamicContentScreens.DoesExist(indexStr)
                screenInfo = m.dynamicContentScreens[indexStr]
                if screenInfo <> invalid and screenInfo.screen <> invalid
                    screenInfo.screen.visible = true
                    print "HomeScene.brs - [repositionAllScreens] Restoring visibility of screen " + indexStr
                end if
            end if
        end if
    end if
end sub

sub showScreenByIndex(index as integer)
    print "HomeScene.brs - [showScreenByIndex] *** SHOWING SCREEN AT INDEX: " + index.ToStr() + " ***"
    
    ' Handle Account screen (last tab) separately using existing account_screen component
    accountIndex = getAccountScreenIndex()
    if index = accountIndex
        print "HomeScene.brs - [showScreenByIndex] *** SHOWING ACCOUNT SCREEN (INDEX " + accountIndex.ToStr() + ") ***"
        showAccountScreen()
        return
    end if
    
    print "HomeScene.brs - [showScreenByIndex] Total dynamic screens: " + m.dynamicContentScreens.Count().ToStr()
    print "HomeScene.brs - [showScreenByIndex] Available screen keys: " + FormatJson(m.dynamicContentScreens.Keys())
    
    ' Hide account screen if it's visible (when navigating to other screens)
    hideAccountScreen()
    
    ' Hide current screen by moving off-screen right
    if m.currentScreen <> invalid
        m.currentScreen.translation = [2000, 0]  ' Off-screen right to prevent peeking
        print "HomeScene.brs - [showScreenByIndex] Moved current screen " + m.currentScreenIndex.ToStr() + " to [2000, 0] (hidden)"
    else
        print "HomeScene.brs - [showScreenByIndex] No current screen to hide"
    end if
    
    ' Get and show new screen
    newScreen = getScreenByIndex(index)
    if newScreen <> invalid
        print "HomeScene.brs - [showScreenByIndex] *** FOUND SCREEN FOR INDEX " + index.ToStr() + " ***"
        print "HomeScene.brs - [showScreenByIndex] Screen ID: " + newScreen.id
        expectedType = "Dynamic screen"
        if index = accountIndex then expectedType = "Account (contentTypeId 6)"
        print "HomeScene.brs - [showScreenByIndex] Expected for index " + index.ToStr() + ": " + expectedType
        print "HomeScene.brs - [showScreenByIndex] Moving screen " + index.ToStr() + " to visible position: [0, 0]"
        newScreen.translation = [0, 0]  ' Visible at origin inside container
        print "HomeScene.brs - [showScreenByIndex] Screen translation after move: [" + newScreen.translation[0].ToStr() + ", " + newScreen.translation[1].ToStr() + "]"
        
        ' Ensure this screen is visible and others are hidden
        newScreen.visible = true
        
        ' If this is the Account screen, ensure all dynamic screens are hidden
        if index = accountIndex and newScreen.id = "account_screen"
            print "HomeScene.brs - [showScreenByIndex] Account screen shown - hiding all dynamic screens"
            for each key in m.dynamicContentScreens.Keys()
                screenInfo = m.dynamicContentScreens[key]
                if screenInfo <> invalid and screenInfo.screen <> invalid
                    screenInfo.screen.visible = false
                    print "HomeScene.brs - [showScreenByIndex] Hiding dynamic screen " + key
                end if
            end for
        end if
        
        ' Force the screen to load its content
        print "HomeScene.brs - [showScreenByIndex] *** CALLING loadContentForType ON SCREEN ***"
        print "HomeScene.brs - [showScreenByIndex] Screen type: " + Type(newScreen).ToStr()
        print "HomeScene.brs - [showScreenByIndex] Screen ID: " + newScreen.id
        
        ' Check if this is Account screen by index and contentTypeId
        print "HomeScene.brs - [showScreenByIndex] Checking screen: index=" + index.ToStr() + ", id='" + newScreen.id + "'"
        if index = accountIndex
            print "HomeScene.brs - [showScreenByIndex] *** THIS IS INDEX " + accountIndex.ToStr() + " - SHOULD BE ACCOUNT SCREEN ***"
            print "HomeScene.brs - [showScreenByIndex] Checking Account screen contentTypeId..."
            print "HomeScene.brs - [showScreenByIndex] ContentTypeId type: " + Type(newScreen.contentTypeId).ToStr()
            if newScreen.contentTypeId <> invalid
                print "HomeScene.brs - [showScreenByIndex] Account screen contentTypeId: " + newScreen.contentTypeId.ToStr()
                if newScreen.contentTypeId = 6
                    print "HomeScene.brs - [showScreenByIndex] *** CONFIRMED ACCOUNT SCREEN - MANUAL CONTENT LOADING ***"
                    ' Manually trigger Account screen content loading
                    newScreen.visible = true
                    ' Force the Account screen to load its content by calling loadContentForType directly
                    result = newScreen.callFunc("loadContentForType")
                    if result <> invalid
                        print "HomeScene.brs - [showScreenByIndex] Account loadContentForType result: " + result.ToStr()
                    else
                        print "HomeScene.brs - [showScreenByIndex] Account loadContentForType returned invalid - trying focus approach"
                        newScreen.setFocus(true)
                    end if
                else
                    print "HomeScene.brs - [showScreenByIndex] ERROR: Account index screen has wrong contentTypeId: " + newScreen.contentTypeId.ToStr()
                    ' Fall back to regular handling
                    result = newScreen.callFunc("loadContentForType")
                end if
            else
                print "HomeScene.brs - [showScreenByIndex] ContentTypeId is invalid - Account screen field issue detected"
                ' Since this is the account index, we know it should be Account screen
                ' The contentTypeId field doesn't exist or is inaccessible - add it properly
                print "HomeScene.brs - [showScreenByIndex] Adding contentTypeId field to Account screen"
                
                ' Add the field (this might fail silently if it already exists, which is fine)
                newScreen.addField("contentTypeId", "int", false)
                print "HomeScene.brs - [showScreenByIndex] Attempted to add contentTypeId field"
                
                ' Now set the value
                print "HomeScene.brs - [showScreenByIndex] Setting contentTypeId to 6"
                newScreen.contentTypeId = 6
                print "HomeScene.brs - [showScreenByIndex] ContentTypeId assignment completed"
                
                ' Since accessing contentTypeId might crash, let's just proceed with loading
                print "HomeScene.brs - [showScreenByIndex] Proceeding with Account content loading"
                
                ' Since contentTypeId is problematic, directly call Account functions
                print "HomeScene.brs - [showScreenByIndex] Directly calling Account content functions"
                
                ' Try multiple approaches to load Account content
                result1 = newScreen.callFunc("showPrettierAuthorizationMessage")
                if result1 <> invalid
                    print "HomeScene.brs - [showScreenByIndex] Direct showPrettierAuthorizationMessage succeeded"
                else
                    print "HomeScene.brs - [showScreenByIndex] Direct showPrettierAuthorizationMessage failed"
                    
                    ' Try the regular loadContentForType
                    result2 = newScreen.callFunc("loadContentForType")
                    if result2 <> invalid
                        print "HomeScene.brs - [showScreenByIndex] loadContentForType succeeded"
                    else
                        print "HomeScene.brs - [showScreenByIndex] loadContentForType failed - trying focus approach"
                        newScreen.setFocus(true)
                    end if
                end if
            end if
        else
            ' Regular screen handling for non-Account screens
            result = newScreen.callFunc("loadContentForType")
            if result <> invalid
                print "HomeScene.brs - [showScreenByIndex] loadContentForType call result: " + result.ToStr()
            else
                print "HomeScene.brs - [showScreenByIndex] loadContentForType call returned invalid"
            end if
        end if
        print "HomeScene.brs - [showScreenByIndex] *** loadContentForType CALL COMPLETED ***"
        
        ' Ensure all other screens are in their correct positions
        repositionAllScreens(index)
        
        ' Set focus on the newly visible screen
        newScreen.setFocus(true)
        print "HomeScene.brs - [showScreenByIndex] Focus set on newly visible screen"
        
        ' Special handling for Account screen - force content loading
        if index = accountIndex and newScreen.id = "account_screen"
            print "HomeScene.brs - [showScreenByIndex] *** FORCING ACCOUNT SCREEN CONTENT LOADING ***"
            print "HomeScene.brs - [showScreenByIndex] Current contentTypeId: " + newScreen.contentTypeId.ToStr()
            ' Force the contentTypeId to trigger onChange by changing it
            newScreen.contentTypeId = -1  ' Reset to trigger change
            newScreen.contentTypeId = 6   ' Set to Account type
            print "HomeScene.brs - [showScreenByIndex] Account screen contentTypeId reset and set to 6"
        end if
        
        m.currentScreen = newScreen
        m.currentScreenIndex = index
        
        ' Show/hide home banner based on screen index
        if m.homeBannerGroup <> invalid
            if index = 0  ' Home screen
                print "HomeScene.brs - [showScreenByIndex] Showing home banner for Home screen (index: " + index.ToStr() + ")"
                print "HomeScene.brs - [showScreenByIndex] Banner visible before: " + m.homeBannerGroup.visible.ToStr()
                m.homeBannerGroup.visible = true
                print "HomeScene.brs - [showScreenByIndex] Banner visible after: " + m.homeBannerGroup.visible.ToStr()
                print "HomeScene.brs - [showScreenByIndex] Banner translation: [" + m.homeBannerGroup.translation[0].ToStr() + ", " + m.homeBannerGroup.translation[1].ToStr() + "]"
            else
                print "HomeScene.brs - [showScreenByIndex] Hiding home banner for screen: " + index.ToStr()
                print "HomeScene.brs - [showScreenByIndex] Banner visible before: " + m.homeBannerGroup.visible.ToStr()
                m.homeBannerGroup.visible = false
                print "HomeScene.brs - [showScreenByIndex] Banner visible after: " + m.homeBannerGroup.visible.ToStr()
            end if
        else
            print "HomeScene.brs - [showScreenByIndex] ERROR: Home banner group is invalid!"
        end if
        
        ' Ensure navigation bar is synchronized with screen index
        if m.navigationMode = 2 and m.markupNavBar <> invalid
            print "HomeScene.brs - [showScreenByIndex] Synchronizing markup navigation bar to index: " + index.ToStr()
            m.markupNavBar.selectedIndex = index
        else if m.navigationMode = 1 and m.verticalNavBar <> invalid
            print "HomeScene.brs - [showScreenByIndex] Synchronizing vertical navigation bar to index: " + index.ToStr()
            m.verticalNavBar.selectedIndex = index
        else if m.dynamicNavBar <> invalid
            print "HomeScene.brs - [showScreenByIndex] Synchronizing original navigation bar to index: " + index.ToStr()
            m.dynamicNavBar.selectedIndex = index
        end if
        
        ' Initialize screen if needed
        initializeScreenByIndex(index)
    end if
end sub

function getScreenByIndex(index as integer) as object
    print "HomeScene.brs - [getScreenByIndex] *** GETTING SCREEN FOR INDEX: " + index.ToStr() + " ***"
    print "HomeScene.brs - [getScreenByIndex] Available screen keys: " + FormatJson(m.dynamicContentScreens.Keys())
    print "HomeScene.brs - [getScreenByIndex] Total screens available: " + m.dynamicContentScreens.Count().ToStr()
    
    ' Debug each screen's details
    for each key in m.dynamicContentScreens.Keys()
        screenInfo = m.dynamicContentScreens[key]
        if screenInfo <> invalid and screenInfo.screen <> invalid
            print "HomeScene.brs - [getScreenByIndex] Screen " + key + ": " + screenInfo.navItem.title + " (contentTypeId: " + screenInfo.screen.contentTypeId.ToStr() + ")"
        end if
    end for
    
    ' All screens are now dynamic content screens (0, 1, 2, ...)
    indexStr = index.ToStr()
    print "HomeScene.brs - [getScreenByIndex] Looking for screen with key: '" + indexStr + "'"
    print "HomeScene.brs - [getScreenByIndex] Available keys: " + FormatJson(m.dynamicContentScreens.Keys())
    print "HomeScene.brs - [getScreenByIndex] Collection count: " + m.dynamicContentScreens.Count().ToStr()
    if m.dynamicContentScreens.DoesExist(indexStr)
        screenInfo = m.dynamicContentScreens[indexStr]
        if screenInfo <> invalid and screenInfo.screen <> invalid
            print "HomeScene.brs - [getScreenByIndex] Found dynamic screen: " + screenInfo.navItem.title + " (contentTypeId: " + screenInfo.screen.contentTypeId.ToStr() + ")"
            print "HomeScene.brs - [getScreenByIndex] Screen ID: " + screenInfo.screen.id
            print "HomeScene.brs - [getScreenByIndex] NavItem ID: " + screenInfo.navItem.id.ToStr()
            return screenInfo.screen
        else
            print "HomeScene.brs - [getScreenByIndex] ERROR: Screen info or screen is invalid for key: " + indexStr
        end if
    else
        print "HomeScene.brs - [getScreenByIndex] ERROR: No screen found for key: " + indexStr
        print "HomeScene.brs - [getScreenByIndex] This might be the User Channels issue!"
    end if
    
    ' Check if this is the Account screen (last index)
    ' Account should be a hardcoded screen, not dynamic content
    print "HomeScene.brs - [getScreenByIndex] Checking if index " + index.ToStr() + " is Account screen"
    print "HomeScene.brs - [getScreenByIndex] Dynamic screens count: " + m.dynamicContentScreens.Count().ToStr()
    if index >= m.dynamicContentScreens.Count()
        print "HomeScene.brs - [getScreenByIndex] *** INDEX " + index.ToStr() + " IS ACCOUNT SCREEN ***"
        print "HomeScene.brs - [getScreenByIndex] Dynamic screens count: " + m.dynamicContentScreens.Count().ToStr()
        print "HomeScene.brs - [getScreenByIndex] Requested index: " + index.ToStr()
        ' This should be the Account screen - create or return it
        accountScreen = getOrCreateAccountScreen()
        if accountScreen <> invalid
            print "HomeScene.brs - [getScreenByIndex] Account screen returned successfully"
        else
            print "HomeScene.brs - [getScreenByIndex] ERROR: Account screen is invalid!"
        end if
        return accountScreen
    end if
    
    print "HomeScene.brs - [getScreenByIndex] No screen found for index: " + index.ToStr()
    return invalid
end function

function getOrCreateAccountScreen() as object
    print "HomeScene.brs - [getOrCreateAccountScreen] Creating or getting Account screen"
    
    ' Check if Account screen already exists and has proper contentTypeId
    if m.accountScreen <> invalid
        print "HomeScene.brs - [getOrCreateAccountScreen] Account screen already exists, checking contentTypeId..."
        if m.accountScreen.hasField("contentTypeId") and m.accountScreen.contentTypeId = 6
            print "HomeScene.brs - [getOrCreateAccountScreen] Account screen has valid contentTypeId, returning it"
            return m.accountScreen
        else
            print "HomeScene.brs - [getOrCreateAccountScreen] Account screen has invalid contentTypeId, recreating..."
            ' Remove the old screen and recreate
            if m.dynamicScreensContainer <> invalid and m.accountScreen <> invalid
                m.dynamicScreensContainer.removeChild(m.accountScreen)
            end if
            m.accountScreen = invalid
        end if
    end if
    
    ' Create Account screen as a dynamic content screen with special contentTypeId
    print "HomeScene.brs - [getOrCreateAccountScreen] Creating new Account screen"
    m.accountScreen = CreateObject("roSGNode", "dynamic_content_screen")
    if m.accountScreen <> invalid
        print "HomeScene.brs - [getOrCreateAccountScreen] Account screen created successfully"
        m.accountScreen.id = "account_screen"
        
        ' Ensure contentTypeId field exists first
        if not m.accountScreen.hasField("contentTypeId")
            m.accountScreen.addField("contentTypeId", "int", false)
            print "HomeScene.brs - [getOrCreateAccountScreen] Added contentTypeId field to Account screen"
        end if
        
        ' Set contentTypeId with proper error checking
        print "HomeScene.brs - [getOrCreateAccountScreen] Setting contentTypeId to 6"
        m.accountScreen.contentTypeId = 6  ' Account content type
        
        ' Verify contentTypeId was set correctly
        print "HomeScene.brs - [getOrCreateAccountScreen] Verifying contentTypeId..."
        print "HomeScene.brs - [getOrCreateAccountScreen] ContentTypeId type: " + Type(m.accountScreen.contentTypeId).ToStr()
        if m.accountScreen.contentTypeId <> invalid
            print "HomeScene.brs - [getOrCreateAccountScreen] ContentTypeId set successfully: " + m.accountScreen.contentTypeId.ToStr()
        else
            print "HomeScene.brs - [getOrCreateAccountScreen] ERROR: Failed to set contentTypeId!"
            ' Try alternative approach
            m.accountScreen.addField("contentTypeId", "int", false)
            m.accountScreen.contentTypeId = 6
            print "HomeScene.brs - [getOrCreateAccountScreen] Retry contentTypeId: " + m.accountScreen.contentTypeId.ToStr()
        end if
        
        m.accountScreen.translation = [2000, 0]  ' Position off-screen right initially
        m.accountScreen.focusable = true
        m.accountScreen.visible = true
        print "HomeScene.brs - [getOrCreateAccountScreen] Account screen configured - ID: " + m.accountScreen.id + ", contentTypeId: " + m.accountScreen.contentTypeId.ToStr()
    else
        print "HomeScene.brs - [getOrCreateAccountScreen] ERROR: Failed to create Account screen!"
        return invalid
    end if
    
    ' Add to main container
    if m.dynamicScreensContainer <> invalid
        m.dynamicScreensContainer.appendChild(m.accountScreen)
        print "HomeScene.brs - [getOrCreateAccountScreen] Account screen added to container"
    else
        print "HomeScene.brs - [getOrCreateAccountScreen] ERROR: Dynamic screens container not found"
    end if
    
    ' CRITICAL: Add Account screen to the screens collection so it can be found by index
    print "HomeScene.brs - [getOrCreateAccountScreen] Adding Account screen to dynamicContentScreens collection"
    print "HomeScene.brs - [getOrCreateAccountScreen] Before adding Account - Collection keys: " + FormatJson(m.dynamicContentScreens.Keys())
    accountScreenInfo = CreateObject("roAssociativeArray")
    accountScreenInfo.screen = m.accountScreen
    accountScreenInfo.navItem = {
        id: "999",
        title: "Account",
        type: "account"
    }
    accountIndex = getAccountScreenIndex()
    accountScreenInfo.navIndex = accountIndex
    
    ' Add to collection with dynamic account index
    accountIndexStr = accountIndex.ToStr()
    m.dynamicContentScreens[accountIndexStr] = accountScreenInfo
    print "HomeScene.brs - [getOrCreateAccountScreen] Account screen added to collection with key '" + accountIndexStr + "'"
    print "HomeScene.brs - [getOrCreateAccountScreen] After adding Account - Collection keys: " + FormatJson(m.dynamicContentScreens.Keys())
    print "HomeScene.brs - [getOrCreateAccountScreen] Total screens now: " + m.dynamicContentScreens.Count().ToStr()
    
    ' Initialize the Account screen
    print "HomeScene.brs - [getOrCreateAccountScreen] Initializing Account screen content"
    ' Don't call loadContentForType here - it will be called when screen is shown
    print "HomeScene.brs - [getOrCreateAccountScreen] Account screen ready for content loading"
    
    print "HomeScene.brs - [getOrCreateAccountScreen] Account screen created successfully"
    print "HomeScene.brs - [getOrCreateAccountScreen] Account screen contentTypeId: " + m.accountScreen.contentTypeId.ToStr()
    return m.accountScreen
end function

sub showAccountScreen()
    print "HomeScene.brs - [showAccountScreen] Showing existing account screen"
    
    ' Get the existing STATIC account screen from the scene (the Profile UI)
    accountScreen = m.top.findNode("account_screen")
    if accountScreen = invalid
        print "HomeScene.brs - [showAccountScreen] ERROR: account_screen not found in scene"
        return
    end if
    
    ' Hide all dynamic screens AND reposition them off-screen
    ' This ensures they don't visually overlap with the Account screen
    for each key in m.dynamicContentScreens.Keys()
        screenInfo = m.dynamicContentScreens[key]
        if screenInfo <> invalid and screenInfo.screen <> invalid
            screenInfo.screen.visible = false
            ' Move screen off-screen right to prevent any visual overlap
            screenInfo.screen.translation = [2000, 0]
            print "HomeScene.brs - [showAccountScreen] Hidden dynamic screen: " + key + " at position [2000, 0]"
        end if
    end for
    
    ' Hide DVR screen if visible
    if m.dvrScreen <> invalid
        m.dvrScreen.visible = false
    end if
    
    ' Hide home banner
    if m.homeBannerGroup <> invalid
        m.homeBannerGroup.visible = false
    end if
    
    ' Position and show the account screen
    ' Note: Static account_screen is NOT inside dynamicScreensContainer, so position is absolute
    accountScreen.translation = [240, 0]  ' Right of 240px nav bar (static screen position)
    accountScreen.visible = true
    print "HomeScene.brs - [showAccountScreen] Account screen positioned at [240, 0]"
    
    ' Ensure account screen is focusable but DON'T give it focus yet
    accountScreen.focusable = true
    
    ' Remove focus from any dynamic content screens that might be interfering
    for each key in m.dynamicContentScreens.Keys()
        screenInfo = m.dynamicContentScreens[key]
        if screenInfo <> invalid and screenInfo.screen <> invalid
            screenInfo.screen.setFocus(false)
        end if
    end for
    
    ' IMPORTANT: Explicitly remove focus from account screen to prevent it from stealing focus
    accountScreen.setFocus(false)
    
    ' Update current screen tracking
    m.currentScreen = accountScreen
    accountIndex = getAccountScreenIndex()
    m.currentScreenIndex = accountIndex
    
    ' Update navigation selected index but DON'T change focus
    ' Focus transfer will happen only when user presses RIGHT on nav bar
    if m.dynamicNavBar <> invalid
        m.dynamicNavBar.selectedIndex = accountIndex
        ' IMPORTANT: Ensure nav bar keeps focus
        m.dynamicNavBar.setFocus(true)
        m.dynamicNavBar.navHasFocus = true
        print "HomeScene.brs - [showAccountScreen] Navigation bar selectedIndex set to: " + accountIndex.ToStr()
        print "HomeScene.brs - [showAccountScreen] Ensured nav bar keeps focus"
    end if
    
    print "HomeScene.brs - [showAccountScreen] Account screen displayed (focus remains on nav bar until user presses RIGHT)"
end sub

sub onAccountFocusRetry()
    ' NOTE: This function is deprecated - focus should only transfer when user presses RIGHT
    ' Keeping for backward compatibility but disabling the aggressive focus handling
    print "HomeScene.brs - [onAccountFocusRetry] Timer fired but focus transfer is disabled"
    print "HomeScene.brs - [onAccountFocusRetry] Focus will only transfer when user presses RIGHT"
    
    ' Stop the timer if it's running
    if m.accountFocusRetryTimer <> invalid
        m.accountFocusRetryTimer.control = "stop"
    end if
end sub

sub hideAccountScreen()
    print "HomeScene.brs - [hideAccountScreen] Hiding account screen"
    
    ' Get the account screen
    accountScreen = m.top.findNode("account_screen")
    if accountScreen <> invalid
        accountScreen.visible = false
        accountScreen.setFocus(false)
    end if
    
    print "HomeScene.brs - [hideAccountScreen] Account screen hidden"
end sub

sub initializeScreenByIndex(index as integer)
    print "HomeScene.brs - [initializeScreenByIndex] Initializing screen at index: " + index.ToStr()
    
    ' Initialize dynamic content screens
    indexStr = index.ToStr()
    if m.dynamicContentScreens.DoesExist(indexStr)
        screenInfo = m.dynamicContentScreens[indexStr]
        if screenInfo <> invalid and screenInfo.screen <> invalid
            print "HomeScene.brs - [initializeScreenByIndex] Initializing dynamic content screen: " + screenInfo.navItem.title
    print "HomeScene.brs - [initializeScreenByIndex] Screen contentTypeId: " + screenInfo.screen.contentTypeId.ToStr()
            
            ' The dynamic content screen will automatically load content when contentTypeId is set
            ' This was already set during screen creation, so content should load automatically
        end if
    end if
    
    ' Note: Search screen initialization removed
end sub

sub onNavigationDataReceived()
    print "HomeScene.brs - [onNavigationDataReceived] Navigation data received, creating dynamic screens"
    print "HomeScene.brs - [onNavigationDataReceived] Function called successfully"
    
    ' Get navigation data from the active navigation bar
    navigationData = invalid
    if m.navigationMode = 2 and m.markupNavBar <> invalid
        print "HomeScene.brs - [onNavigationDataReceived] Getting data from markup navigation bar"
        navigationData = m.markupNavBar.navigationData
    else if m.navigationMode = 1 and m.verticalNavBar <> invalid
        print "HomeScene.brs - [onNavigationDataReceived] Getting data from vertical navigation bar"
        navigationData = m.verticalNavBar.navigationData
    else if m.dynamicNavBar <> invalid
        print "HomeScene.brs - [onNavigationDataReceived] Getting data from original navigation bar"
        navigationData = m.dynamicNavBar.navigationData
    end if
    
    if navigationData <> invalid and navigationData.Count() > 0
        print "HomeScene.brs - [onNavigationDataReceived] FULL NAVIGATION DATA: " + FormatJson(navigationData)
        for i = 0 to navigationData.Count() - 1
            navItem = navigationData[i]
            if navItem <> invalid
                print "HomeScene.brs - [onNavigationDataReceived] Nav Item " + i.ToStr() + ": Title='" + navItem.title + "', ID=" + navItem.id.ToStr()
            end if
        end for
        
        ' Filter navigation items based on authentication
        filteredNavigationData = filterNavigationByAuth(navigationData)
        print "HomeScene.brs - [onNavigationDataReceived] Filtered navigation: " + filteredNavigationData.Count().ToStr() + " items (was " + navigationData.Count().ToStr() + ")"
        
        m.navigationItems = filteredNavigationData
        
        ' CRITICAL: Force rebuild of navigation bar with filtered data
        ' We need to manually call buildNavigationItems since we're modifying the data after it was set
        forceNavigationRebuild(filteredNavigationData)
        
        createDynamicContentScreens()
        
        ' Show first content screen by default but keep focus on navigation
        print "HomeScene.brs - [onNavigationDataReceived] Auto-showing first screen (index 0) without focusing content"
        print "HomeScene.brs - [onNavigationDataReceived] Available screens: " + FormatJson(m.dynamicContentScreens.Keys())
        print "HomeScene.brs - [onNavigationDataReceived] All screens should have loaded their content by now"
        
        print "HomeScene.brs - [onNavigationDataReceived] Auto-showing first screen (index 0) without focusing content"
        print "HomeScene.brs - [onNavigationDataReceived] Available screens: " + FormatJson(m.dynamicContentScreens.Keys())
        print "HomeScene.brs - [onNavigationDataReceived] All screens should have loaded their content by now"
        
        ' Add a fallback timer to hide loader if content doesn't load
        if m.loaderFallbackTimer <> invalid
            m.loaderFallbackTimer.control = "stop"
        end if
        m.loaderFallbackTimer = CreateObject("roSGNode", "Timer")
        m.loaderFallbackTimer.duration = 5.0  ' 5 second fallback
        m.loaderFallbackTimer.repeat = false
        m.loaderFallbackTimer.observeField("fire", "onLoaderFallbackTimeout")
        m.loaderFallbackTimer.control = "start"
        print "HomeScene.brs - [onNavigationDataReceived] Started 5-second fallback timer"
        
        ' Ensure current screen index is properly initialized
        m.currentScreenIndex = 0
        print "HomeScene.brs - [onNavigationDataReceived] Setting initial currentScreenIndex to: " + m.currentScreenIndex.ToStr()
        
        ' CRITICAL: Ensure navigation bar is set to Home before switching content
        if m.dynamicNavBar <> invalid
            print "HomeScene.brs - [onNavigationDataReceived] *** FORCING NAVIGATION TO HOME BEFORE CONTENT SWITCH ***"
            
            m.dynamicNavBar.selectedIndex = 0
            print "HomeScene.brs - [onNavigationDataReceived] *** FORCED NAVIGATION selectedIndex TO 0 ***"
        end if
        
        switchScreenContent(0)
        
        ' Mark initial load as complete after first screen is shown
        m.isInitialLoad = false
        print "HomeScene.brs - [onNavigationDataReceived] Initial load complete, navigation index changes now allowed"
    else
        print "HomeScene.brs - [onNavigationDataReceived] No navigation data available"
    end if
end sub

sub createDynamicContentScreens()
    print "HomeScene.brs - [createDynamicContentScreens] Creating " + m.navigationItems.Count().ToStr() + " dynamic content screens"
    
    ' Clear existing dynamic screens
    clearDynamicContentScreens()
    
    ' Create content screen for each navigation item
    for i = 0 to m.navigationItems.Count() - 1
        navItem = m.navigationItems[i]
        if navItem <> invalid and navItem.id <> invalid
            createContentScreenForNavItem(navItem, i)
        end if
    end for
    
    print "HomeScene.brs - [createDynamicContentScreens] Created " + m.dynamicContentScreens.Count().ToStr() + " content screens"
    
    ' Show the first screen by default
    if m.dynamicContentScreens.Count() > 0
        showScreenByIndex(0)
        print "HomeScene.brs - [createDynamicContentScreens] Showing first screen by default"
    end if
end sub

sub createContentScreenForNavItem(navItem as object, index as integer)
    print "HomeScene.brs - [createContentScreenForNavItem] Creating screen for: " + navItem.title + " (ID: " + navItem.id.ToStr() + ")"
    print "HomeScene.brs - [createContentScreenForNavItem] Screen index: " + index.ToStr() + ", Navigation item: " + FormatJson(navItem)
    
    ' Special debugging for User Channels
    if LCase(navItem.title).Instr("user") >= 0 and LCase(navItem.title).Instr("channel") >= 0
        print "HomeScene.brs - [createContentScreenForNavItem] *** CREATING USER CHANNELS SCREEN ***"
        print "HomeScene.brs - [createContentScreenForNavItem] User Channels at index: " + index.ToStr()
    end if
    
    ' Special debugging for Age Restricted Channels (authenticated users only)
    if LCase(navItem.title).Instr("age") >= 0 or LCase(navItem.title).Instr("restricted") >= 0
        print "HomeScene.brs - [createContentScreenForNavItem] *** CREATING AGE RESTRICTED CHANNELS SCREEN ***"
        print "HomeScene.brs - [createContentScreenForNavItem] Age Restricted Channels at index: " + index.ToStr()
    end if
    
    ' Special debugging for Personal tab (authenticated users only)
    if LCase(navItem.title).Instr("personal") >= 0
        print "HomeScene.brs - [createContentScreenForNavItem] *** CREATING PERSONAL SCREEN ***"
        print "HomeScene.brs - [createContentScreenForNavItem] Personal at index: " + index.ToStr()
    end if
    
    ' Special handling for TV Guide tab - use dedicated EPG screen
    ' ONLY match TV Guide by exact ID 17 to avoid false matches
    isTVGuide = false
    if navItem.id = 17
        isTVGuide = true
        print "HomeScene.brs - [createContentScreenForNavItem] *** CREATING TV GUIDE EPG SCREEN ***"
        print "HomeScene.brs - [createContentScreenForNavItem] TV Guide (ID 17) at index: " + index.ToStr()
    end if
    
    ' Debug: Log what type of screen we're creating
    print "HomeScene.brs - [createContentScreenForNavItem] navItem.id=" + navItem.id.ToStr() + ", isTVGuide=" + isTVGuide.ToStr()
    
    ' Create appropriate screen type
    contentScreen = invalid
    if isTVGuide
        contentScreen = CreateObject("roSGNode", "TVGuideScreen")
        print "HomeScene.brs - [createContentScreenForNavItem] Created TVGuideScreen for TV Guide"
    else
        contentScreen = CreateObject("roSGNode", "dynamic_content_screen")
        print "HomeScene.brs - [createContentScreenForNavItem] Created dynamic_content_screen for: " + navItem.title
    end if
    
    ' Map navigation item to proper content type ID
    mappedContentTypeId = mapNavItemToContentTypeId(navItem, index)
    contentScreen.contentTypeId = mappedContentTypeId
    print "HomeScene.brs - [createContentScreenForNavItem] Original navItem.id: " + navItem.id.ToStr() + ", Mapped contentTypeId: " + mappedContentTypeId.ToStr() + " for " + navItem.title
    print "HomeScene.brs - [createContentScreenForNavItem] MISMATCH CHECK: Screen '" + navItem.title + "' at index " + index.ToStr() + " has contentTypeId " + contentScreen.contentTypeId.ToStr()
    
    ' Add to container and position vertically based on index
    m.dynamicScreensContainer.appendChild(contentScreen)
    
    ' Set up event handlers for DVR requests and video playback
    contentScreen.observeField("dvrRequested", "onDVRRequested")
    contentScreen.observeField("videoPlayRequested", "onVideoPlayRequested")
    
    ' Position screens: visible screen at [0, 0] inside container, others hidden off-screen right
    ' Container handles the offset (starts at [240, 0], animates to [0, 0] when nav collapses)
    if index = 0
        contentScreen.translation = [0, 0]  ' Visible screen at origin inside container
        print "HomeScene.brs - [createContentScreenForNavItem] Screen " + index.ToStr() + " positioned at [0, 0] (visible)"
    else
        ' Hide screens far to the right (off-screen) to prevent peeking
        contentScreen.translation = [2000, 0]
        print "HomeScene.brs - [createContentScreenForNavItem] Screen " + index.ToStr() + " positioned at [2000, 0] (hidden off-screen right)"
    end if
    
    ' Store reference with navigation index (convert to string for associative array)
    screenInfo = CreateObject("roAssociativeArray")
    screenInfo.screen = contentScreen
    screenInfo.navItem = navItem
    screenInfo.navIndex = index + 1  ' +1 because search is index 0
    
    navIndexStr = index.ToStr()
    m.dynamicContentScreens[navIndexStr] = screenInfo
    
    print "HomeScene.brs - [createContentScreenForNavItem] Screen stored with key: " + navIndexStr
    print "HomeScene.brs - [createContentScreenForNavItem] Screen title: " + navItem.title + ", contentTypeId: " + contentScreen.contentTypeId.ToStr()
    
    ' Special debugging for User Channels
    if LCase(navItem.title).Instr("user") >= 0 and LCase(navItem.title).Instr("channel") >= 0
        print "HomeScene.brs - [createContentScreenForNavItem] *** USER CHANNELS SCREEN STORED ***"
        print "HomeScene.brs - [createContentScreenForNavItem] Dictionary now has keys: " + FormatJson(m.dynamicContentScreens.Keys())
    end if
    
    ' Special debugging for Age Restricted Channels
    if LCase(navItem.title).Instr("age") >= 0 or LCase(navItem.title).Instr("restricted") >= 0
        print "HomeScene.brs - [createContentScreenForNavItem] *** AGE RESTRICTED CHANNELS SCREEN STORED ***"
        print "HomeScene.brs - [createContentScreenForNavItem] Dictionary now has keys: " + FormatJson(m.dynamicContentScreens.Keys())
    end if
    
    ' Special debugging for Personal tab
    if LCase(navItem.title).Instr("personal") >= 0
        print "HomeScene.brs - [createContentScreenForNavItem] *** PERSONAL SCREEN STORED ***"
        print "HomeScene.brs - [createContentScreenForNavItem] Dictionary now has keys: " + FormatJson(m.dynamicContentScreens.Keys())
    end if
    
    ' Special debugging for TV Guide tab
    if LCase(navItem.title).Instr("tv guide") >= 0 or LCase(navItem.title).Instr("tvguide") >= 0 or LCase(navItem.title).Instr("guide") >= 0
        print "HomeScene.brs - [createContentScreenForNavItem] *** TV GUIDE SCREEN STORED ***"
        print "HomeScene.brs - [createContentScreenForNavItem] Dictionary now has keys: " + FormatJson(m.dynamicContentScreens.Keys())
    end if
    
    print "HomeScene.brs - [createContentScreenForNavItem] Screen created for nav index: " + index.ToStr()
end sub

sub clearDynamicContentScreens()
    print "HomeScene.brs - [clearDynamicContentScreens] Clearing existing dynamic screens"
    
    ' Remove all children from dynamic screens container
    if m.dynamicScreensContainer <> invalid
        m.dynamicScreensContainer.removeChildrenIndex(m.dynamicScreensContainer.getChildCount(), 0)
    end if
    
    ' Clear screen references
    m.dynamicContentScreens = CreateObject("roAssociativeArray")
end sub









function initializeLiveChannelData()
    m.liveChannelData = createObject("roSGNode", "LiveScreenApi")
    m.liveChannelData.observeField("responseData", "handleResponseData")
    m.liveChannelData.control = "RUN"

end function




sub sendAppLaunchCompleteBeacon()
    ' Replace these placeholders with actual values from your Roku developer account
    developerId = "88cda8a8ed744cba6c0fc1cb4aedc3dcd307f448"
    channelId = "777725"
    timeStamp = m.top.timeNow()

    ' Construct the URL for the beacon
    beaconUrl = "https://beacon.appcloud.roku.com/beacon/roku/app/launchcomplete"
    beaconUrl = beaconUrl + "?did=" + developerId + "&cid=" + channelId + "&ts=" + timeStamp

    ' Send the GET request to the beacon URL
    request = createObject("roUrlTransfer")
    request.setUrl(beaconUrl)
    request.getToFile("NUL:") ' Send the request and ignore response

    ' Optionally log or handle any errors
    if request.getResponseCode() <> 200 then
        print "Error sending AppLaunchComplete beacon: " + request.getResponseCode()
    end if
end sub


sub handleResponseData()
    data = m.liveChannelData.responseData

    m.top.liveChannelsEntity = parseChannelEntity(data)


    m.global.liveChannelsEntity = m.top.liveChannelsEntity

end sub



function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)
    print jsonData
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


function UpdateAuthData(accessToken as string, subscribed as boolean, isauth as boolean, expiry as integer)
    section = "AUTH"
    sec = CreateObject("roRegistrySection", section)

    ' Convert boolean values to integers
    if subscribed
        subscribedValue = 1
    else
        subscribedValue = 0
    end if

    if isauth
        isAuthValue = 1
    else
        isAuthValue = 0
    end if

    data = {
        accessToken: accessToken,
        subscribed: subscribedValue,
        expiry: expiry,
        ' expiry: 4,
        isauth: isAuthValue
    }
    jsonData = FormatJson(data)
    ' Write the associative array to the registry
    sec.Write("authData", jsonData)
    sec.Flush()
end function


function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    ' return invalid
    return sec.Read(key)
end function

function mapNavItemToContentTypeId(navItem as object, index as integer) as integer
    ' Map navigation items to proper content type IDs
    ' DIRECT PASSTHROUGH: Use the ID from the navigation API as-is
    ' API returns: Home=13, Live TV=3, Movies=1, Series=2, User Channels=14, Age Restricted=15, Personal=16
    
    print "HomeScene.brs - [mapNavItemToContentTypeId] =========================================="
    print "HomeScene.brs - [mapNavItemToContentTypeId] Mapping navItem: '" + navItem.title + "'"
    print "HomeScene.brs - [mapNavItemToContentTypeId]   Original ID from API: " + navItem.id.ToStr()
    print "HomeScene.brs - [mapNavItemToContentTypeId]   Navigation index: " + index.ToStr()
    
    ' Use the ID directly from the navigation API - no restrictions!
    ' The API returns the correct content type IDs:
    ' - Home: 13
    ' - Live TV: 3
    ' - Movies: 1
    ' - Series: 2
    ' - User Channels: 14
    ' - Age Restricted Channels: 15 (only when authenticated)
    ' - Personal: 16 (only when authenticated)
    originalId = Int(navItem.id)
    
    if originalId > 0
        print "HomeScene.brs - [mapNavItemToContentTypeId]   Using API ID directly: " + originalId.ToStr()
        print "HomeScene.brs - [mapNavItemToContentTypeId] =========================================="
        return originalId
    end if
    
    ' Fallback only if API ID is 0 or invalid: Map based on title keywords
    title = LCase(navItem.title)
    mappedId = 13 ' Default to Home
    
    if title.Instr("home") >= 0
        mappedId = 13  ' Home = ID 13
    else if title.Instr("live") >= 0
        mappedId = 3   ' Live TV = ID 3
    else if title.Instr("movie") >= 0 or title.Instr("film") >= 0
        mappedId = 1   ' Movies = ID 1
    else if title.Instr("series") >= 0 or title.Instr("tv show") >= 0
        mappedId = 2   ' Series = ID 2
    else if title.Instr("user") >= 0 and title.Instr("channel") >= 0
        mappedId = 14  ' User Channels = ID 14
    else if title.Instr("age") >= 0 or title.Instr("restricted") >= 0
        mappedId = 15  ' Age Restricted Channels = ID 15
    else if title.Instr("personal") >= 0
        mappedId = 16  ' Personal = ID 16
    else if title.Instr("tv guide") >= 0 or title.Instr("tvguide") >= 0 or title.Instr("guide") >= 0
        mappedId = 17  ' TV Guide = ID 17
    else if title.Instr("account") >= 0
        mappedId = 99  ' Account = special ID 99
    end if
    
    print "HomeScene.brs - [mapNavItemToContentTypeId]   FALLBACK: Mapped '" + navItem.title + "' to ID " + mappedId.ToStr()
    print "HomeScene.brs - [mapNavItemToContentTypeId] =========================================="
    return mappedId
end function

function getExpectedTitleForContentTypeId(contentTypeId as integer) as string
    ' Return expected title keywords for each content type ID
    ' Based on ACTUAL API IDs from navigation response:
    ' 13 = Home, 3 = Live TV, 1 = Movies, 2 = Series, 14 = User Channels, 15 = Age Restricted, 16 = Personal, 17 = TV Guide
    if contentTypeId = 13
        return "home"
    else if contentTypeId = 3
        return "live"
    else if contentTypeId = 1
        return "movie"
    else if contentTypeId = 2
        return "series"
    else if contentTypeId = 14
        return "user"
    else if contentTypeId = 15
        return "age restricted"
    else if contentTypeId = 16
        return "personal"
    else if contentTypeId = 17
        return "tv guide"
    else if contentTypeId = 99 or contentTypeId = 6
        return "account"
    else
        return ""
    end if
end function

function checkAuthenticationForUserChannels() as boolean
    ' Check if user is authenticated for User Channels access
    authData = RetrieveAuthData()
    if authData <> invalid and authData.isauth = 1
        print "HomeScene.brs - [checkAuthenticationForUserChannels] User is authenticated"
        return true
    else
        print "HomeScene.brs - [checkAuthenticationForUserChannels] User is not authenticated"
        return false
    end if
end function

function filterNavigationByAuth(navigationData as object) as object
    ' Filter navigation items based on authentication status
    ' Remove User Channels (ID 14) if user is not authenticated
    print "HomeScene.brs - [filterNavigationByAuth] ========== FILTERING NAVIGATION =========="
    print "HomeScene.brs - [filterNavigationByAuth] Input items: " + navigationData.Count().ToStr()
    
    isAuthenticated = checkAuthenticationForUserChannels()
    print "HomeScene.brs - [filterNavigationByAuth] User authenticated: " + isAuthenticated.ToStr()
    
    filteredItems = []
    
    for each navItem in navigationData
        if navItem <> invalid and navItem.id <> invalid
            itemId = navItem.id
            itemTitle = ""
            if navItem.title <> invalid then itemTitle = navItem.title
            
            ' Check if this is User Channels (ID 14)
            if itemId = 14
                if isAuthenticated
                    print "HomeScene.brs - [filterNavigationByAuth] ✓ User Channels (ID 14) - KEEPING (user authenticated)"
                    filteredItems.Push(navItem)
                else
                    print "HomeScene.brs - [filterNavigationByAuth] ✗ User Channels (ID 14) - REMOVING (user not authenticated)"
                    ' DO NOT add to filteredItems
                end if
            else
                ' Keep all other items
                print "HomeScene.brs - [filterNavigationByAuth] ✓ '" + itemTitle + "' (ID " + itemId.ToStr() + ") - KEEPING"
                filteredItems.Push(navItem)
            end if
        end if
    end for
    
    print "HomeScene.brs - [filterNavigationByAuth] =========================================="
    print "HomeScene.brs - [filterNavigationByAuth] RESULT: " + filteredItems.Count().ToStr() + " items (was " + navigationData.Count().ToStr() + ")"
    print "HomeScene.brs - [filterNavigationByAuth] Items removed: " + (navigationData.Count() - filteredItems.Count()).ToStr()
    print "HomeScene.brs - [filterNavigationByAuth] =========================================="
    return filteredItems
end function

sub forceNavigationRebuild(filteredData as object)
    ' Force navigation bar to rebuild with filtered data
    print "HomeScene.brs - [forceNavigationRebuild] ========== FORCING NAV BAR REBUILD =========="
    print "HomeScene.brs - [forceNavigationRebuild] Filtered items count: " + filteredData.Count().ToStr()
    
    ' Get the active navigation bar
    activeNavBar = invalid
    navBarType = ""
    if m.navigationMode = 2 and m.markupNavBar <> invalid
        activeNavBar = m.markupNavBar
        navBarType = "markup"
    else if m.navigationMode = 1 and m.verticalNavBar <> invalid
        activeNavBar = m.verticalNavBar
        navBarType = "vertical"
    else if m.dynamicNavBar <> invalid
        activeNavBar = m.dynamicNavBar
        navBarType = "dynamic"
    end if
    
    if activeNavBar <> invalid
        print "HomeScene.brs - [forceNavigationRebuild] Found " + navBarType + " navigation bar"
        
        ' Unobserve to prevent recursive calls
        print "HomeScene.brs - [forceNavigationRebuild] Unobserving navigationData field"
        activeNavBar.unobserveField("navigationData")
        
        ' Set the filtered data
        print "HomeScene.brs - [forceNavigationRebuild] Setting navigationData with " + filteredData.Count().ToStr() + " items"
        activeNavBar.navigationData = filteredData
        
        ' Directly call the buildNavigationItems function to force rebuild
        print "HomeScene.brs - [forceNavigationRebuild] Calling buildNavigationItems() directly"
        result = activeNavBar.callFunc("buildNavigationItems")
        
        if result <> invalid
            print "HomeScene.brs - [forceNavigationRebuild] ✓ buildNavigationItems() completed successfully"
        else
            print "HomeScene.brs - [forceNavigationRebuild] buildNavigationItems() returned invalid (might be sub, not function)"
        end if
        
        print "HomeScene.brs - [forceNavigationRebuild] ✓ Navigation bar rebuilt with " + filteredData.Count().ToStr() + " items"
    else
        print "HomeScene.brs - [forceNavigationRebuild] ERROR: No active navigation bar found"
        print "HomeScene.brs - [forceNavigationRebuild] Navigation mode: " + m.navigationMode.ToStr()
    end if
    
    print "HomeScene.brs - [forceNavigationRebuild] =========================================="
end sub

function getAccountScreenIndex() as integer
    ' Get the Account screen index dynamically based on navigation items count
    ' Account is always the last tab, added after all dynamic navigation items
    if m.navigationItems <> invalid and m.navigationItems.Count() > 0
        accountIndex = m.navigationItems.Count()
        print "HomeScene.brs - [getAccountScreenIndex] Account screen index: " + accountIndex.ToStr() + " (based on " + m.navigationItems.Count().ToStr() + " nav items)"
        return accountIndex
    end if
    ' Default fallback if navigation items not loaded yet
    print "HomeScene.brs - [getAccountScreenIndex] Using default Account index: 5"
    return 5
end function

' Authorization dialog functions removed - now handled in dynamic_content_screen.brs

function onKeyEvent(key as string, press as boolean) as boolean
    print "HomeScene.brs - [onKeyEvent] Key: " + key + ", Press: " + press.ToStr() + ", VideoPlayerVisible: " + m.isVideoPlayerVisible.ToStr()
    
    ' Only handle key press events (not release)
    if not press
        return false
    end if
    
    ' Check if video player is visible and handle video navigation
    if m.isVideoPlayerVisible = true
        print "HomeScene.brs - [onKeyEvent] Video player is visible, handling key: " + key
        
        if key = "back" or key = "left"
            print "HomeScene.brs - [onKeyEvent] *** BACK BUTTON INTERCEPTED IN HOME SCENE ***"
            print "HomeScene.brs - [onKeyEvent] Stopping video and returning to content"
            
            ' Stop video playback
            if m.videoPlayerScreen <> invalid
                videoPlayerNode = m.videoPlayerScreen.findNode("VideoPlayer")
                if videoPlayerNode <> invalid
                    videoPlayerNode.control = "stop"
                    print "HomeScene.brs - [onKeyEvent] Video playback stopped"
                end if
            end if
            
            ' Hide video player and restore content
            hideVideoPlayer()
            return true
        else if key = "OK" or key = "play" or key = "pause"
            ' Let video player handle playback control keys
            if m.videoPlayerScreen <> invalid
                videoPlayerNode = m.videoPlayerScreen.findNode("VideoPlayer")
                if videoPlayerNode <> invalid
                    if key = "OK" or key = "play"
                        if videoPlayerNode.state = "paused" or videoPlayerNode.state = "stopped"
                            videoPlayerNode.control = "play"
                            print "HomeScene.brs - [onKeyEvent] Video resumed/started"
                        else if videoPlayerNode.state = "playing"
                            videoPlayerNode.control = "pause"
                            print "HomeScene.brs - [onKeyEvent] Video paused"
                        end if
                    else if key = "pause"
                        videoPlayerNode.control = "pause"
                        print "HomeScene.brs - [onKeyEvent] Video paused"
                    end if
                    return true
                end if
            end if
        else
            ' Let video player handle other keys (seeking, etc.)
            if m.videoPlayerScreen <> invalid
                return m.videoPlayerScreen.callFunc("onKeyEvent", key, press)
            end if
        end if
    end if
    
    ' Check if DVR screen is visible and handle DVR navigation
    if m.isDVRScreenVisible = true
        if key = "back" or key = "left"
            print "HomeScene.brs - [onKeyEvent] Back from DVR screen"
            hideDVRScreen()
            ' Restore previous screen
            if m.currentScreenIndex >= 0
                showScreenByIndex(m.currentScreenIndex)
            else
                ' Default to home screen
                showScreenByIndex(0)
            end if
            return true
        else
            ' Let DVR screen handle other keys
            if m.dvrScreen <> invalid
                return m.dvrScreen.callFunc("onKeyEvent", key, press)
            end if
        end if
    end if
    
    ' Check if navigation bar has focus (support both navigation systems)
    activeNavBar = invalid
    navHasFocus = false
    
    if m.navigationMode = 2 and m.markupNavBar <> invalid
        activeNavBar = m.markupNavBar
        navHasFocus = m.markupNavBar.navHasFocus = true
        print "HomeScene.brs - [onKeyEvent] Checking markup navigation bar focus"
    else if m.navigationMode = 1 and m.verticalNavBar <> invalid
        activeNavBar = m.verticalNavBar
        navHasFocus = m.verticalNavBar.navHasFocus = true
        print "HomeScene.brs - [onKeyEvent] Checking vertical navigation bar focus"
    else if m.dynamicNavBar <> invalid
        activeNavBar = m.dynamicNavBar
        navHasFocus = m.dynamicNavBar.navHasFocus = true
        print "HomeScene.brs - [onKeyEvent] Checking original navigation bar focus"
    end if
    
    if activeNavBar <> invalid and navHasFocus
        print "HomeScene.brs - [onKeyEvent] Navigation bar has focus, letting it handle keys"
        print "HomeScene.brs - [onKeyEvent] NavBar hasFocus: " + activeNavBar.hasFocus().ToStr()
        
        ' Ensure navigation bar actually has focus
        ' BUT don't interfere if we're in the middle of screen switching
        if not activeNavBar.hasFocus()
            print "HomeScene.brs - [onKeyEvent] Navigation bar lost focus, checking if we should restore it"
            print "HomeScene.brs - [onKeyEvent] Key: " + key + ", Press: " + press.ToStr()
            
            ' Handle RIGHT key when navHasFocus=true but hasFocus()=false
            ' This means navigation bar wants to handle keys but lost actual focus
            ' Call handleNavigationKey directly to let nav bar process the key
            if key = "right" and press = true
                print "HomeScene.brs - [onKeyEvent] Calling navigation bar handleNavigationKey for RIGHT"
                result = activeNavBar.callFunc("handleNavigationKey", key, press)
                if result <> invalid and result = true
                    print "HomeScene.brs - [onKeyEvent] Navigation bar handled RIGHT key"
                    return true
                end if
            end if
            
            ' Don't restore focus during UP/DOWN navigation as it interferes with screen switching
            if (key = "up" or key = "down") and press = true
        print "HomeScene.brs - [onKeyEvent] Skipping focus restoration during UP/DOWN navigation to allow screen switching"
        ' Handle navigation directly in home scene since callFunc isn't working
        if activeNavBar <> invalid
            print "HomeScene.brs - [onKeyEvent] Setting navHasFocus = true and handling navigation directly"
            activeNavBar.navHasFocus = true
            
            ' Get current navigation index
            currentIndex = activeNavBar.selectedIndex
            if currentIndex = invalid
                currentIndex = 0
            end if
            print "HomeScene.brs - [onKeyEvent] Current navigation index: " + currentIndex.ToStr()
            
            ' Calculate new index based on key
            newIndex = currentIndex
            totalItems = m.navigationItems.Count() + 1  ' Dynamic nav items + Account
            accountIndex = getAccountScreenIndex()
            if key = "up"
                newIndex = (currentIndex - 1 + totalItems) mod totalItems
                print "HomeScene.brs - [onKeyEvent] UP: " + currentIndex.ToStr() + " -> " + newIndex.ToStr()
            else if key = "down"
                newIndex = (currentIndex + 1) mod totalItems
                print "HomeScene.brs - [onKeyEvent] DOWN: " + currentIndex.ToStr() + " -> " + newIndex.ToStr()
            end if
            
            ' Debug what screen this should be
            if newIndex = accountIndex
                print "HomeScene.brs - [onKeyEvent] *** NAVIGATING TO ACCOUNT SCREEN (INDEX " + accountIndex.ToStr() + ") ***"
            end if
            
            ' Update navigation and switch screen
            if newIndex <> currentIndex
                print "HomeScene.brs - [onKeyEvent] *** SWITCHING TO SCREEN INDEX: " + newIndex.ToStr() + " ***"
                activeNavBar.selectedIndex = newIndex
                switchScreenContent(newIndex)
                return true
            else
                print "HomeScene.brs - [onKeyEvent] No index change needed"
                return false
            end if
        end if
        return false
            end if
            
            print "HomeScene.brs - [onKeyEvent] Proceeding with focus restoration"
            print "HomeScene.brs - [onKeyEvent] Current focused child: " + Type(m.top.focusedChild).ToStr()
            if m.top.focusedChild <> invalid
                print "HomeScene.brs - [onKeyEvent] Focused child ID: " + m.top.focusedChild.id
            end if
            
            ' Force remove focus from current focused child
            if m.top.focusedChild <> invalid and not m.top.focusedChild.isSameNode(activeNavBar)
                print "HomeScene.brs - [onKeyEvent] Removing focus from: " + Type(m.top.focusedChild).ToStr()
                m.top.focusedChild.setFocus(false)
            end if
            
            activeNavBar.setFocus(true)
            ' Call focusUpdated only for the original navigation bar
            if m.navigationMode = 0 and activeNavBar <> invalid and m.dynamicNavBar <> invalid
                if activeNavBar.isSameNode(m.dynamicNavBar)
                    activeNavBar.callFunc("focusUpdated")
                end if
            end if
            print "HomeScene.brs - [onKeyEvent] After restore - NavBar hasFocus: " + activeNavBar.hasFocus().ToStr()
        end if
        
        ' Let navigation bar handle its own keys
        return false
    end if
    
    ' Check if any dialog is open
    if m.top.dialog <> invalid
        print "HomeScene.brs - [onKeyEvent] Dialog is open, letting dialog handle keys"
        return false
    end if
    
    ' Note: Search screen interference removed
    
    ' Check if current screen should handle the key
    if m.currentScreen <> invalid
        print "HomeScene.brs - [onKeyEvent] Current screen exists, checking if it should handle key"
        
        ' For back key, always try to return focus to navigation first
        if key = "back"
            print "HomeScene.brs - [onKeyEvent] Back key pressed, returning focus to navigation"
            if m.dynamicNavBar <> invalid
                m.dynamicNavBar.setFocus(true)
                m.dynamicNavBar.navHasFocus = true
                return true
            end if
        end if
        
        ' For right key, check if navigation has focus and delegate properly
        if key = "right"
            print "HomeScene.brs - [onKeyEvent] Right key pressed"
            if m.dynamicNavBar <> invalid and m.dynamicNavBar.navHasFocus = true
                print "HomeScene.brs - [onKeyEvent] Navigation has focus, letting it handle right key"
                return false ' Let navigation bar handle the right key
            else
                print "HomeScene.brs - [onKeyEvent] Navigation doesn't have focus, checking current screen"
                
                ' Special handling for Account screen
                accountIndex = getAccountScreenIndex()
                if m.currentScreenIndex = accountIndex and m.accountScreen <> invalid
                    print "HomeScene.brs - [onKeyEvent] Account screen active (index " + accountIndex.ToStr() + "), routing RIGHT key directly to Account screen"
                    print "HomeScene.brs - [onKeyEvent] Account screen visible: " + m.accountScreen.visible.ToStr()
                    print "HomeScene.brs - [onKeyEvent] Account screen hasFocus: " + m.accountScreen.hasFocus().ToStr()
                    
                    if m.accountScreen.visible = true
                        ' Ensure Account screen has focus before calling its onKeyEvent
                        if not m.accountScreen.hasFocus()
                            print "HomeScene.brs - [onKeyEvent] Account screen doesn't have focus, setting focus first"
                            m.accountScreen.setFocus(true)
                        end if
                        
                        print "HomeScene.brs - [onKeyEvent] Calling Account screen onKeyEvent with key: " + key + ", press: " + press.ToStr()
                        result = m.accountScreen.callFunc("onKeyEvent", key, press)
                        print "HomeScene.brs - [onKeyEvent] Account screen onKeyEvent returned: " + result.ToStr()
                        
                        if result = true
                            print "HomeScene.brs - [onKeyEvent] Account screen handled the RIGHT key successfully"
                            return true
                        else
                            print "HomeScene.brs - [onKeyEvent] Account screen did not handle the RIGHT key, result: " + result.ToStr()
                        end if
                    else
                        print "HomeScene.brs - [onKeyEvent] Account screen is not visible, showing it first"
                        showScreenByIndex(accountIndex)
                        print "HomeScene.brs - [onKeyEvent] Account screen shown, will handle subsequent RIGHT keys"
                        return true
                    end if
                end if
                
                print "HomeScene.brs - [onKeyEvent] Letting current screen handle right key"
                return false ' Let current screen handle it
            end if
        end if
        
        ' Let the current screen handle other keys
        return false
    end if
    
    ' If no specific handling, ensure navigation has focus for navigation keys
    if key = "up" or key = "down" or key = "OK"
        print "HomeScene.brs - [onKeyEvent] Ensuring navigation bar has focus for key: " + key
        if m.dynamicNavBar <> invalid
            m.dynamicNavBar.setFocus(true)
            m.dynamicNavBar.navHasFocus = true
            ' Force focus to ensure navigation bar actually gets it
            m.dynamicNavBar.callFunc("forceFocus")
            return false ' Let navigation handle the key
        end if
    end if
    
    ' For right key when navigation doesn't have focus, ensure current screen has focus
    if key = "right"
        print "HomeScene.brs - [onKeyEvent] Right key with no navigation focus, ensuring current screen has focus"
        if m.currentScreen <> invalid
            print "HomeScene.brs - [onKeyEvent] Setting focus on current screen"
            m.currentScreen.setFocus(true)
            return false ' Let current screen handle the key
        end if
    end if
    
    return false
end function

' Global loader functions
sub showGlobalLoader(message = "Loading..." as string)
    print "HomeScene.brs - [showGlobalLoader] Showing global loader: " + message
    print "HomeScene.brs - [showGlobalLoader] globalLoader found: " + (m.globalLoader <> invalid).ToStr()
    print "HomeScene.brs - [showGlobalLoader] loaderText found: " + (m.loaderText <> invalid).ToStr()
    
    if m.loaderText <> invalid
        m.loaderText.text = message
        print "HomeScene.brs - [showGlobalLoader] Set loader text to: " + message
    else
        print "HomeScene.brs - [showGlobalLoader] ERROR: loaderText is invalid!"
    end if
    
    if m.globalLoader <> invalid
        m.globalLoader.visible = true
        print "HomeScene.brs - [showGlobalLoader] Set globalLoader visible to: " + m.globalLoader.visible.ToStr()
        print "HomeScene.brs - [showGlobalLoader] globalLoader translation: [" + m.globalLoader.translation[0].ToStr() + ", " + m.globalLoader.translation[1].ToStr() + "]"
    else
        print "HomeScene.brs - [showGlobalLoader] ERROR: globalLoader is invalid!"
    end if
    
    startLoadingAnimation()
end sub

sub hideGlobalLoader()
    print "HomeScene.brs - [hideGlobalLoader] *** FUNCTION CALLED *** Hiding global loader"
    if m.globalLoader <> invalid
        print "HomeScene.brs - [hideGlobalLoader] Setting globalLoader visible to false"
        m.globalLoader.visible = false
        print "HomeScene.brs - [hideGlobalLoader] globalLoader visible after hide: " + m.globalLoader.visible.ToStr()
    else
        print "HomeScene.brs - [hideGlobalLoader] ERROR: globalLoader is invalid!"
    end if
    stopLoadingAnimation()
    print "HomeScene.brs - [hideGlobalLoader] *** FUNCTION COMPLETE ***"
    
    ' Stop fallback timer if it's running
    if m.loaderFallbackTimer <> invalid
        m.loaderFallbackTimer.control = "stop"
        m.loaderFallbackTimer = invalid
        print "HomeScene.brs - [hideGlobalLoader] Stopped fallback timer"
    end if
end sub

sub onLoaderFallbackTimeout()
    print "HomeScene.brs - [onLoaderFallbackTimeout] *** FALLBACK TIMEOUT *** Forcing loader to hide"
    if m.globalLoader <> invalid and m.globalLoader.visible = true
        print "HomeScene.brs - [onLoaderFallbackTimeout] Loader still visible, forcing hide"
        m.globalLoader.visible = false
        stopLoadingAnimation()
    end if
    m.loaderFallbackTimer = invalid
end sub

sub startLoadingAnimation()
    ' Create a simple pulsing animation for the dots
    if m.loadingAnimation <> invalid
        m.loadingAnimation.control = "stop"
    end if
    
    m.loadingAnimation = CreateObject("roSGNode", "Animation")
    m.loadingAnimation.duration = 1.5
    m.loadingAnimation.repeat = true
    m.loadingAnimation.easeFunction = "inOutQuad"
    
    ' Animate opacity of dots in sequence
    for i = 0 to m.loadingDots.Count() - 1
        if m.loadingDots[i] <> invalid
            interpolator = CreateObject("roSGNode", "FloatFieldInterpolator")
            interpolator.key = [0.0, 0.25, 0.5, 0.75, 1.0]
            interpolator.keyValue = [0.3, 1.0, 0.3, 1.0, 0.3]
            interpolator.fieldToInterp = "dot" + (i + 1).ToStr() + ".opacity"
            m.loadingAnimation.appendChild(interpolator)
        end if
    end for
    
    m.top.appendChild(m.loadingAnimation)
    m.loadingAnimation.control = "start"
end sub

sub stopLoadingAnimation()
    if m.loadingAnimation <> invalid
        m.loadingAnimation.control = "stop"
        m.loadingAnimation = invalid
    end if
    
    ' Reset dot opacity
    for i = 0 to m.loadingDots.Count() - 1
        if m.loadingDots[i] <> invalid
            m.loadingDots[i].opacity = 1.0
        end if
    end for
end sub

' DVR Screen Management Functions
function getOrCreateDVRScreen() as object
    print "HomeScene.brs - [getOrCreateDVRScreen] Creating or getting DVR screen"
    
    if m.dvrScreen = invalid
        print "HomeScene.brs - [getOrCreateDVRScreen] Creating new DVR screen"
        
        ' Create DVR screen
        dvrScreen = CreateObject("roSGNode", "dvr_content_screen")
        dvrScreen.id = "dvr_screen"
        dvrScreen.translation = [2000, 0]  ' Start off-screen right
        dvrScreen.visible = false
        
        ' Add to main container
        m.dynamicScreensContainer.appendChild(dvrScreen)
        
        ' Set up event handlers
        dvrScreen.observeField("focusedChild", "onDVRScreenFocusChanged")
        
        m.dvrScreen = dvrScreen
        print "HomeScene.brs - [getOrCreateDVRScreen] DVR screen created with ID: " + dvrScreen.id
    else
        print "HomeScene.brs - [getOrCreateDVRScreen] DVR screen already exists"
    end if
    
    return m.dvrScreen
end function

sub showDVRScreen(dvrUrl as string, channelTitle as string)
    print "HomeScene.brs - [showDVRScreen] Showing DVR screen for URL: " + dvrUrl
    
    ' Get or create DVR screen
    dvrScreen = getOrCreateDVRScreen()
    
    ' Hide all other screens
    hideAllScreens()
    
    ' Set DVR parameters
    dvrScreen.dvrUrl = dvrUrl
    dvrScreen.channelTitle = channelTitle
    
    ' Position and show DVR screen
    dvrScreen.translation = [0, 0]
    dvrScreen.visible = true
    dvrScreen.setFocus(true)
    
    ' Update state
    m.isDVRScreenVisible = true
    m.currentScreenIndex = -1  ' Special index for DVR screen
    
    ' Hide navigation and home banner
    if m.homeBannerGroup <> invalid
        m.homeBannerGroup.visible = false
    end if
    if m.originalNavBar <> invalid
        m.originalNavBar.visible = false
    end if
    
    print "HomeScene.brs - [showDVRScreen] DVR screen displayed"
end sub

sub hideDVRScreen()
    print "HomeScene.brs - [hideDVRScreen] Hiding DVR screen"
    
    if m.dvrScreen <> invalid
        m.dvrScreen.visible = false
        m.dvrScreen.translation = [2000, 0]  ' Move off-screen right
        m.dvrScreen.setFocus(false)
    end if
    
    m.isDVRScreenVisible = false
    
    ' Restore navigation
    if m.originalNavBar <> invalid
        m.originalNavBar.visible = true
        m.originalNavBar.setFocus(true)
    end if
    
    print "HomeScene.brs - [hideDVRScreen] DVR screen hidden"
end sub


sub onDVRScreenFocusChanged()
    print "HomeScene.brs - [onDVRScreenFocusChanged] DVR screen focus changed"
    ' Handle DVR screen focus changes if needed
end sub

' Video Player Management Functions
sub showVideoPlayer(videoData as object)
    print "HomeScene.brs - [showVideoPlayer] Showing video player for: " + videoData.title
    
    ' Store current screen and selection state for restoration
    m.previousScreenIndex = m.currentScreenIndex
    storePreviousItemSelection()
    
    ' Store that we came from a screen with content (for proper focus restoration)
    m.returnFromVideoWithContentFocus = (m.previousItemSelection <> invalid)
    if m.returnFromVideoWithContentFocus
        print "HomeScene.brs - [showVideoPlayer] Will restore content focus when returning from video"
    end if
    
    ' Get the existing video player screen from the scene
    m.videoPlayerScreen = m.top.findNode("videoDVRScreen")
    
    if m.videoPlayerScreen = invalid
        print "HomeScene.brs - [showVideoPlayer] ERROR: VideoDVRScreen not found in scene"
        return
    end if
    
    ' Hide all other content
    hideAllScreensForVideo()
    
    ' Create content node for the video player
    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.url = videoData.contentUrl
    videoContent.title = videoData.title
    videoContent.streamFormat = "hls"
    
    if videoData.description <> invalid
        videoContent.description = videoData.description
    end if
    
    if videoData.thumbnail <> invalid
        videoContent.hdPosterUrl = videoData.thumbnail
    end if
    
    ' Add debugging for video content
    print "HomeScene.brs - [showVideoPlayer] Video content created:"
    print "HomeScene.brs - [showVideoPlayer] URL: " + videoContent.url
    print "HomeScene.brs - [showVideoPlayer] Title: " + videoContent.title
    print "HomeScene.brs - [showVideoPlayer] Stream Format: " + videoContent.streamFormat
    
    ' Set content and show video player
    m.videoPlayerScreen.content = videoContent
    
    ' Set up video player error monitoring
    m.videoPlayerScreen.observeField("videoPlayerVisible", "onVideoPlayerVisibilityChanged")
    
    ' Override the video player screen's key event handling
    m.videoPlayerScreen.observeField("focusedChild", "onVideoPlayerFocusChanged")
    
    ' Monitor for navigation attempts from the video player
    m.videoPlayerScreen.observeField("navigatedFrom", "onVideoPlayerNavigationAttempt")
    
    ' Get the actual video player node and monitor its state
    videoPlayerNode = m.videoPlayerScreen.findNode("VideoPlayer")
    if videoPlayerNode <> invalid
        videoPlayerNode.observeField("state", "onVideoStateChanged")
        videoPlayerNode.observeField("errorMsg", "onVideoErrorChanged")
        print "HomeScene.brs - [showVideoPlayer] Video player state monitoring set up"
    else
        print "HomeScene.brs - [showVideoPlayer] ERROR: Could not find VideoPlayer node"
    end if
    
    ' Hide all UI elements except the video player itself
    hideVideoPlayerUIElements()
    
    ' Set fields directly instead of using addFields
    m.videoPlayerScreen.managedByHomeScene = true
    m.videoPlayerScreen.backButtonPressed = false
    m.videoPlayerScreen.sourceScreenIndex = m.previousScreenIndex
    
    ' Debug: Verify fields were set
    print "HomeScene.brs - [showVideoPlayer] Field setting verification:"
    print "HomeScene.brs - [showVideoPlayer] managedByHomeScene: " + m.videoPlayerScreen.managedByHomeScene.ToStr()
    print "HomeScene.brs - [showVideoPlayer] sourceScreenIndex: " + m.videoPlayerScreen.sourceScreenIndex.ToStr()
    print "HomeScene.brs - [showVideoPlayer] backButtonPressed: " + m.videoPlayerScreen.backButtonPressed.ToStr()
    
    ' Monitor for back button presses in the video player
    m.videoPlayerScreen.observeField("backButtonPressed", "onVideoPlayerBackButton")
    
    sourceScreenName = getScreenNameByIndex(m.previousScreenIndex)
    print "HomeScene.brs - [showVideoPlayer] Set source screen index: " + m.previousScreenIndex.ToStr() + " (" + sourceScreenName + ")"
    
    m.videoPlayerScreen.visible = true
    
    ' Set focus on the video player node directly, not the screen
    videoPlayerNode = m.videoPlayerScreen.findNode("VideoPlayer")
    if videoPlayerNode <> invalid
        videoPlayerNode.setFocus(true)
        print "HomeScene.brs - [showVideoPlayer] Focus set directly on video player node"
    else
        ' Fallback to screen focus
        m.videoPlayerScreen.setFocus(true)
        print "HomeScene.brs - [showVideoPlayer] Fallback: Focus set on video player screen"
    end if
    
    ' Update state
    m.isVideoPlayerVisible = true
    
    print "HomeScene.brs - [showVideoPlayer] Video player displayed and playing: " + videoData.contentUrl
end sub

sub hideVideoPlayer()
    print "HomeScene.brs - [hideVideoPlayer] Hiding video player"
    
    if m.videoPlayerScreen <> invalid
        ' Stop video playback
        videoPlayerNode = m.videoPlayerScreen.findNode("VideoPlayer")
        if videoPlayerNode <> invalid
            videoPlayerNode.control = "stop"
            print "HomeScene.brs - [hideVideoPlayer] Video playback stopped"
        end if
        
        ' Restore UI elements (in case they were hidden)
        restoreVideoPlayerUIElements()
        
        ' Hide the video player screen
        m.videoPlayerScreen.visible = false
        m.videoPlayerScreen.setFocus(false)
    end if
    
    m.isVideoPlayerVisible = false
    
    ' Restore navigation and content
    restoreNavigationAndContent()
    
    print "HomeScene.brs - [hideVideoPlayer] Video player hidden and content restored"
end sub

sub hideAllScreensForVideo()
    print "HomeScene.brs - [hideAllScreensForVideo] Hiding all UI for video playback"
    
    ' Hide all dynamic screens and stop any preview video players
    for each key in m.dynamicContentScreens
        screen = m.dynamicContentScreens[key].screen
        if screen <> invalid
            ' Stop any preview video players (e.g., TV Guide preview)
            previewVideoPlayer = screen.findNode("videoPlayer")
            if previewVideoPlayer <> invalid
                previewVideoPlayer.control = "stop"
                print "HomeScene.brs - [hideAllScreensForVideo] Stopped preview video player in screen: " + key
            end if
            
            screen.visible = false
        end if
    end for
    
    ' Hide account screen
    if m.accountScreen <> invalid
        m.accountScreen.visible = false
    end if
    
    ' Hide DVR screen
    if m.dvrScreen <> invalid
        m.dvrScreen.visible = false
    end if
    
    ' Hide navigation
    if m.dynamicNavBar <> invalid
        m.dynamicNavBar.visible = false
    end if
    if m.originalNavBar <> invalid
        m.originalNavBar.visible = false
    end if
    
    ' Hide home banner
    if m.homeBannerGroup <> invalid
        m.homeBannerGroup.visible = false
    end if
    
    print "HomeScene.brs - [hideAllScreensForVideo] All UI hidden for video playback"
end sub

sub restoreNavigationAndContent()
    print "HomeScene.brs - [restoreNavigationAndContent] Restoring navigation and content"
    
    ' Restore navigation
    if m.dynamicNavBar <> invalid
        m.dynamicNavBar.visible = true
    end if
    
    ' Restore previous screen
    screenIndexToRestore = m.previousScreenIndex
    if screenIndexToRestore < 0
        screenIndexToRestore = m.currentScreenIndex
    end if
    
    ' Get screen name and type for logging
    screenName = "Unknown"
    screenType = "rowlist"
    if screenIndexToRestore >= 0 and screenIndexToRestore < m.dynamicContentScreens.Count()
        screenKey = screenIndexToRestore.ToStr()
        if m.dynamicContentScreens.DoesExist(screenKey)
            screenInfo = m.dynamicContentScreens[screenKey]
            if screenInfo.navItem <> invalid and screenInfo.navItem.title <> invalid
                screenName = screenInfo.navItem.title
            end if
            ' Check if this is TV Guide
            if screenInfo.screen <> invalid and screenInfo.screen.findNode("timeGrid") <> invalid
                screenType = "tvguide"
            end if
        end if
    end if
    
    if screenIndexToRestore >= 0
        print "HomeScene.brs - [restoreNavigationAndContent] Restoring to screen: " + screenIndexToRestore.ToStr() + " (" + screenName + ")"
        showScreenByIndex(screenIndexToRestore)
        
        ' For TV Guide, restore item selection and focus to content (not navigation)
        if screenType = "tvguide"
            print "HomeScene.brs - [restoreNavigationAndContent] Restoring TV Guide - focusing content, not navigation"
            ' Restore item selection after a short delay to ensure screen is ready
            restorePreviousItemSelection()
        else
            ' For regular screens, focus navigation bar first
            if m.dynamicNavBar <> invalid
                m.dynamicNavBar.setFocus(true)
            end if
            ' Restore item selection after a short delay to ensure screen is ready
            restorePreviousItemSelection()
        end if
    else
        ' Default to home screen
        print "HomeScene.brs - [restoreNavigationAndContent] No valid screen index, defaulting to Home (0)"
        showScreenByIndex(0)
        if m.dynamicNavBar <> invalid
            m.dynamicNavBar.setFocus(true)
        end if
    end if
    
    print "HomeScene.brs - [restoreNavigationAndContent] Navigation and content restoration complete"
end sub

sub storePreviousItemSelection()
    print "HomeScene.brs - [storePreviousItemSelection] Storing current item selection"
    
    ' Get current screen
    if m.currentScreenIndex >= 0 and m.currentScreenIndex < m.dynamicContentScreens.Count()
        screenKey = m.currentScreenIndex.ToStr()
        if m.dynamicContentScreens.DoesExist(screenKey)
            currentScreen = m.dynamicContentScreens[screenKey].screen
            if currentScreen <> invalid
                ' Check if this is a TV Guide screen (has TimeGrid instead of RowList)
                timeGrid = currentScreen.findNode("timeGrid")
                if timeGrid <> invalid
                    ' Store TimeGrid selection (channelFocused, programFocused)
                    m.previousItemSelection = {
                        screenIndex: m.currentScreenIndex,
                        screenType: "tvguide",
                        channelFocused: timeGrid.channelFocused,
                        programFocused: timeGrid.programFocused
                    }
                    print "HomeScene.brs - [storePreviousItemSelection] Stored TV Guide selection - Screen: " + m.currentScreenIndex.ToStr()
                    print "HomeScene.brs - [storePreviousItemSelection] Channel focused: " + timeGrid.channelFocused.ToStr()
                    print "HomeScene.brs - [storePreviousItemSelection] Program focused: " + timeGrid.programFocused.ToStr()
                else
                    ' Get the RowList from the current screen
                    rowList = currentScreen.findNode("contentRowList")
                    if rowList <> invalid
                        ' Store the current selection
                        m.previousItemSelection = {
                            screenIndex: m.currentScreenIndex,
                            screenType: "rowlist",
                            itemFocused: rowList.itemFocused,
                            rowItemFocused: rowList.rowItemFocused
                        }
                        print "HomeScene.brs - [storePreviousItemSelection] Stored RowList selection - Screen: " + m.currentScreenIndex.ToStr()
                        if rowList.itemFocused <> invalid
                            print "HomeScene.brs - [storePreviousItemSelection] Item focused: " + FormatJson(rowList.itemFocused)
                        end if
                        if rowList.rowItemFocused <> invalid
                            print "HomeScene.brs - [storePreviousItemSelection] Row item focused: " + FormatJson(rowList.rowItemFocused)
                        end if
                    else
                        print "HomeScene.brs - [storePreviousItemSelection] No RowList or TimeGrid found in current screen"
                    end if
                end if
            end if
        end if
    end if
end sub

sub restorePreviousItemSelection()
    print "HomeScene.brs - [restorePreviousItemSelection] Restoring previous item selection"
    
    if m.previousItemSelection = invalid
        print "HomeScene.brs - [restorePreviousItemSelection] No previous selection to restore"
        return
    end if
    
    ' Create a timer to restore selection after screen is fully loaded
    selectionTimer = CreateObject("roSGNode", "Timer")
    selectionTimer.duration = 0.5  ' 500ms delay
    selectionTimer.repeat = false
    selectionTimer.observeField("fire", "onRestoreSelectionTimer")
    selectionTimer.control = "start"
    m.selectionTimer = selectionTimer
    
    print "HomeScene.brs - [restorePreviousItemSelection] Selection restoration timer started"
end sub

sub onRestoreSelectionTimer()
    print "HomeScene.brs - [onRestoreSelectionTimer] Restoring item selection after delay"
    
    if m.previousItemSelection <> invalid
        screenIndex = m.previousItemSelection.screenIndex
        screenKey = screenIndex.ToStr()
        screenType = "rowlist" ' Default
        if m.previousItemSelection.screenType <> invalid
            screenType = m.previousItemSelection.screenType
        end if
        
        if m.dynamicContentScreens.DoesExist(screenKey)
            screen = m.dynamicContentScreens[screenKey].screen
            if screen <> invalid
                ' Check if this is a TV Guide screen
                if screenType = "tvguide"
                    timeGrid = screen.findNode("timeGrid")
                    if timeGrid <> invalid
                        ' Restore TimeGrid focus
                        if m.previousItemSelection.channelFocused <> invalid and m.previousItemSelection.programFocused <> invalid
                            ' Use jumpToItem to restore both channel and program focus
                            timeGrid.jumpToItem = [m.previousItemSelection.channelFocused, m.previousItemSelection.programFocused]
                            print "HomeScene.brs - [onRestoreSelectionTimer] Restored TimeGrid focus to channel: " + m.previousItemSelection.channelFocused.ToStr() + ", program: " + m.previousItemSelection.programFocused.ToStr()
                        end if
                        
                        ' Set focus on the TimeGrid
                        timeGrid.setFocus(true)
                        print "HomeScene.brs - [onRestoreSelectionTimer] Focus restored to TV Guide TimeGrid"
                    else
                        print "HomeScene.brs - [onRestoreSelectionTimer] ERROR: TimeGrid not found in TV Guide screen"
                    end if
                else
                    ' Handle regular RowList screens
                    rowList = screen.findNode("contentRowList")
                    if rowList <> invalid
                        ' Restore item focus
                        if m.previousItemSelection.itemFocused <> invalid
                            rowList.itemFocused = m.previousItemSelection.itemFocused
                            print "HomeScene.brs - [onRestoreSelectionTimer] Restored itemFocused: " + FormatJson(m.previousItemSelection.itemFocused)
                        end if
                        
                        ' Restore row item focus
                        if m.previousItemSelection.rowItemFocused <> invalid
                            rowList.rowItemFocused = m.previousItemSelection.rowItemFocused
                            print "HomeScene.brs - [onRestoreSelectionTimer] Restored rowItemFocused: " + FormatJson(m.previousItemSelection.rowItemFocused)
                        end if
                        
                        ' Set focus on the content
                        rowList.setFocus(true)
                        print "HomeScene.brs - [onRestoreSelectionTimer] Focus restored to content RowList"
                    else
                        print "HomeScene.brs - [onRestoreSelectionTimer] ERROR: RowList not found"
                    end if
                end if
            else
                print "HomeScene.brs - [onRestoreSelectionTimer] ERROR: Screen not found"
            end if
        else
            print "HomeScene.brs - [onRestoreSelectionTimer] ERROR: Screen key not found: " + screenKey
        end if
    end if
    
    ' Clean up
    m.previousItemSelection = invalid
    m.selectionTimer = invalid
end sub

function getScreenNameByIndex(screenIndex as integer) as string
    if screenIndex < 0 or screenIndex >= m.dynamicContentScreens.Count()
        return "Invalid Index"
    end if
    
    screenKey = screenIndex.ToStr()
    if m.dynamicContentScreens.DoesExist(screenKey)
        screenInfo = m.dynamicContentScreens[screenKey]
        if screenInfo.navItem <> invalid and screenInfo.navItem.title <> invalid
            return screenInfo.navItem.title
        end if
    end if
    
    return "Unknown Screen"
end function

sub onVideoPlayerVisibilityChanged()
    print "HomeScene.brs - [onVideoPlayerVisibilityChanged] Video player visibility changed"
    
    if m.videoPlayerScreen <> invalid
        print "HomeScene.brs - [onVideoPlayerVisibilityChanged] Video player visible: " + m.videoPlayerScreen.videoPlayerVisible.ToStr()
        
        ' If video player becomes invisible (due to error or completion), restore navigation
        if m.videoPlayerScreen.videoPlayerVisible = false and m.isVideoPlayerVisible = true
            print "HomeScene.brs - [onVideoPlayerVisibilityChanged] Video player hidden due to error or completion"
            hideVideoPlayer()
        end if
    end if
end sub

sub hideVideoPlayerUIElements()
    print "HomeScene.brs - [hideVideoPlayerUIElements] Hiding video player UI elements for clean playback"
    
    if m.videoPlayerScreen <> invalid
        ' Hide control buttons
        buttons = m.videoPlayerScreen.findNode("Buttons")
        if buttons <> invalid
            buttons.visible = false
            print "HomeScene.brs - [hideVideoPlayerUIElements] Hidden control buttons"
        end if
        
        ' Hide HUD rectangle (bottom bar)
        hudRect = m.videoPlayerScreen.findNode("HUDRectangle")
        if hudRect <> invalid
            hudRect.visible = false
            print "HomeScene.brs - [hideVideoPlayerUIElements] Hidden HUD rectangle"
        end if
        
        ' Hide poster
        poster = m.videoPlayerScreen.findNode("Poster")
        if poster <> invalid
            poster.visible = false
            print "HomeScene.brs - [hideVideoPlayerUIElements] Hidden poster"
        end if
        
        ' Hide description
        description = m.videoPlayerScreen.findNode("Description")
        if description <> invalid
            description.visible = false
            print "HomeScene.brs - [hideVideoPlayerUIElements] Hidden description"
        end if
        
        ' Hide overhang (top bar)
        overhang = m.videoPlayerScreen.findNode("detailsOverhang")
        if overhang <> invalid
            overhang.visible = false
            print "HomeScene.brs - [hideVideoPlayerUIElements] Hidden overhang"
        end if
        
        ' Hide overhang background
        overhangBg = m.videoPlayerScreen.findNode("overhangBackground")
        if overhangBg <> invalid
            overhangBg.visible = false
            print "HomeScene.brs - [hideVideoPlayerUIElements] Hidden overhang background"
        end if
        
        ' Hide background panel set
        backgroundPanel = m.videoPlayerScreen.findNode("backgroundPanelSet")
        if backgroundPanel <> invalid
            backgroundPanel.visible = false
            print "HomeScene.brs - [hideVideoPlayerUIElements] Hidden background panel"
        end if
        
        print "HomeScene.brs - [hideVideoPlayerUIElements] All UI elements hidden for clean video playback"
    end if
end sub

sub restoreVideoPlayerUIElements()
    print "HomeScene.brs - [restoreVideoPlayerUIElements] Restoring video player UI elements"
    
    if m.videoPlayerScreen <> invalid
        ' Restore control buttons
        buttons = m.videoPlayerScreen.findNode("Buttons")
        if buttons <> invalid
            buttons.visible = true
        end if
        
        ' Restore HUD rectangle
        hudRect = m.videoPlayerScreen.findNode("HUDRectangle")
        if hudRect <> invalid
            hudRect.visible = true
        end if
        
        ' Restore poster
        poster = m.videoPlayerScreen.findNode("Poster")
        if poster <> invalid
            poster.visible = true
        end if
        
        ' Restore description
        description = m.videoPlayerScreen.findNode("Description")
        if description <> invalid
            description.visible = true
        end if
        
        ' Restore overhang
        overhang = m.videoPlayerScreen.findNode("detailsOverhang")
        if overhang <> invalid
            overhang.visible = true
        end if
        
        ' Restore overhang background
        overhangBg = m.videoPlayerScreen.findNode("overhangBackground")
        if overhangBg <> invalid
            overhangBg.visible = true
        end if
        
        ' Restore background panel
        backgroundPanel = m.videoPlayerScreen.findNode("backgroundPanelSet")
        if backgroundPanel <> invalid
            backgroundPanel.visible = true
        end if
        
        print "HomeScene.brs - [restoreVideoPlayerUIElements] UI elements restored"
    end if
end sub

sub onVideoStateChanged()
    print "HomeScene.brs - [onVideoStateChanged] Video player state changed"
    
    if m.videoPlayerScreen <> invalid
        videoPlayerNode = m.videoPlayerScreen.findNode("VideoPlayer")
        if videoPlayerNode <> invalid
            print "HomeScene.brs - [onVideoStateChanged] Video state: " + videoPlayerNode.state
            if videoPlayerNode.content <> invalid
                contentUrl = "No URL"
                if videoPlayerNode.content.url <> invalid and videoPlayerNode.content.url <> ""
                    contentUrl = videoPlayerNode.content.url
                end if
                
                contentTitle = "No title"
                if videoPlayerNode.content.title <> invalid and videoPlayerNode.content.title <> ""
                    contentTitle = videoPlayerNode.content.title
                end if
                
                print "HomeScene.brs - [onVideoStateChanged] Video content URL: " + contentUrl
                print "HomeScene.brs - [onVideoStateChanged] Video content title: " + contentTitle
            else
                print "HomeScene.brs - [onVideoStateChanged] Video content: No content set"
            end if
            
            if videoPlayerNode.state = "error"
                print "HomeScene.brs - [onVideoStateChanged] VIDEO ERROR DETECTED!"
                print "HomeScene.brs - [onVideoStateChanged] Error message: " + videoPlayerNode.errorMsg
                print "HomeScene.brs - [onVideoStateChanged] Error code: " + videoPlayerNode.errorCode.ToStr()
                
                ' Hide video player and return to content on error
                hideVideoPlayer()
            else if videoPlayerNode.state = "finished"
                print "HomeScene.brs - [onVideoStateChanged] Video playback finished"
                ' Hide video player and return to content when finished
                hideVideoPlayer()
            else if videoPlayerNode.state = "playing"
                print "HomeScene.brs - [onVideoStateChanged] Video is now playing successfully"
            else if videoPlayerNode.state = "buffering"
                print "HomeScene.brs - [onVideoStateChanged] Video is buffering..."
            else if videoPlayerNode.state = "paused"
                print "HomeScene.brs - [onVideoStateChanged] Video is paused"
            else if videoPlayerNode.state = "stopped"
                print "HomeScene.brs - [onVideoStateChanged] Video is stopped"
            end if
        end if
    end if
end sub

sub onVideoErrorChanged()
    print "HomeScene.brs - [onVideoErrorChanged] Video error message changed"
    
    if m.videoPlayerScreen <> invalid
        videoPlayerNode = m.videoPlayerScreen.findNode("VideoPlayer")
        if videoPlayerNode <> invalid and videoPlayerNode.errorMsg <> ""
            print "HomeScene.brs - [onVideoErrorChanged] ERROR: " + videoPlayerNode.errorMsg
        end if
    end if
end sub

sub onVideoPlayerFocusChanged()
    print "HomeScene.brs - [onVideoPlayerFocusChanged] Video player focus changed"
    
    ' Ensure the scene maintains focus to intercept key events
    if m.isVideoPlayerVisible = true
        m.top.setFocus(true)
        print "HomeScene.brs - [onVideoPlayerFocusChanged] Scene focus restored to intercept keys"
    end if
end sub

sub onVideoPlayerNavigationAttempt()
    print "HomeScene.brs - [onVideoPlayerNavigationAttempt] Video player attempting navigation"
    
    if m.isVideoPlayerVisible = true
        print "HomeScene.brs - [onVideoPlayerNavigationAttempt] Intercepting video player navigation - returning to content"
        
        ' The video player is trying to navigate away, intercept this
        hideVideoPlayer()
    end if
end sub

sub onVideoPlayerBackButton()
    print "HomeScene.brs - [onVideoPlayerBackButton] Back button detected in video player"
    
    if m.isVideoPlayerVisible = true
        print "HomeScene.brs - [onVideoPlayerBackButton] *** BACK BUTTON INTERCEPTED VIA FIELD OBSERVER ***"
        
        ' Get the source screen index from the video player
        sourceScreenIndex = -1
        if m.videoPlayerScreen <> invalid and m.videoPlayerScreen.sourceScreenIndex <> invalid
            sourceScreenIndex = m.videoPlayerScreen.sourceScreenIndex
            print "HomeScene.brs - [onVideoPlayerBackButton] Returning to source screen index: " + sourceScreenIndex.ToStr()
        else
            print "HomeScene.brs - [onVideoPlayerBackButton] No source screen index, using previous screen: " + m.previousScreenIndex.ToStr()
            sourceScreenIndex = m.previousScreenIndex
        end if
        
        ' Update the previous screen index to ensure proper restoration
        m.previousScreenIndex = sourceScreenIndex
        
        hideVideoPlayer()
    end if
end sub

sub onDVRRequested(event as object)
    print "HomeScene.brs - [onDVRRequested] DVR content requested"
    
    ' Get DVR data from the event
    dvrData = event.getData()
    if dvrData <> invalid and dvrData.dvrUrl <> invalid and dvrData.dvrUrl <> ""
        print "HomeScene.brs - [onDVRRequested] Opening DVR screen for: " + dvrData.channelTitle
        showDVRScreen(dvrData.dvrUrl, dvrData.channelTitle)
    else
        print "HomeScene.brs - [onDVRRequested] Invalid DVR data received"
    end if
end sub

sub onVideoPlayRequested(event as object)
    print "HomeScene.brs - [onVideoPlayRequested] Video playback requested"
    
    ' Get video data from the event
    videoData = event.getData()
    if videoData <> invalid and videoData.contentUrl <> invalid and videoData.contentUrl <> ""
        print "HomeScene.brs - [onVideoPlayRequested] Playing video: " + videoData.title
        print "HomeScene.brs - [onVideoPlayRequested] Video URL: " + videoData.contentUrl
        showVideoPlayer(videoData)
    else
        print "HomeScene.brs - [onVideoPlayRequested] Invalid video data received"
    end if
end sub

function reloadAppData() as boolean
    print "HomeScene.brs - [reloadAppData] *** RELOADING APP DATA WITH NEW SESSION ***"
    
    ' Show global loading screen
    showGlobalLoader("Reloading App...")
    
    ' Reset initial load flag so the app behaves like fresh start
    m.isInitialLoad = true
    
    ' Clear all dynamic content screens
    print "HomeScene.brs - [reloadAppData] Clearing all dynamic content screens..."
    if m.dynamicContentScreens <> invalid
        for each key in m.dynamicContentScreens.Keys()
            screenInfo = m.dynamicContentScreens[key]
            if screenInfo <> invalid and screenInfo.screen <> invalid
                print "HomeScene.brs - [reloadAppData] Removing screen: " + key
                screenInfo.screen.visible = false
                if m.dynamicScreensContainer <> invalid
                    m.dynamicScreensContainer.removeChild(screenInfo.screen)
                end if
            end if
        end for
        m.dynamicContentScreens.Clear()
    end if
    
    ' Reset Account screen if it exists
    accountScreen = m.top.findNode("account_screen")
    if accountScreen <> invalid
        print "HomeScene.brs - [reloadAppData] Updating Account screen status"
        accountScreen.visible = false
        accountScreen.accountStatus = true ' User is now logged in
        
        ' Trigger user data reload on Account screen
        print "HomeScene.brs - [reloadAppData] Triggering Account screen to reload user data"
        accountScreen.callFunc("refreshUserData")
    else
        print "HomeScene.brs - [reloadAppData] WARNING: Account screen not found"
    end if
    
    ' Hide home banner
    if m.homeBannerGroup <> invalid
        m.homeBannerGroup.visible = false
    end if
    
    ' Reset navigation state
    m.currentScreenIndex = 0
    m.currentScreen = invalid
    
    ' Keep navigation bar VISIBLE during reload - don't call hideAllScreens()
    ' This ensures the navigation bar remains visible after reload
    
    ' Trigger navigation bar reload
    activeNavBar = invalid
    if m.navigationMode = 0
        activeNavBar = m.dynamicNavBar
    else if m.navigationMode = 1
        activeNavBar = m.verticalNavBar
    else if m.navigationMode = 2
        activeNavBar = m.markupNavBar
    end if
    
    if activeNavBar <> invalid
        print "HomeScene.brs - [reloadAppData] Ensuring navigation bar is visible..."
        activeNavBar.visible = true
        activeNavBar.navHasFocus = true
        
        print "HomeScene.brs - [reloadAppData] Reloading navigation bar data..."
        activeNavBar.callFunc("reloadNavigation")
    else
        print "HomeScene.brs - [reloadAppData] ERROR: No active navigation bar found"
        hideGlobalLoader()
    end if
    
    return true
end function

' Expand content to full width (when nav bar collapses)
function expandContent() as boolean
    print "HomeScene.brs - [expandContent] Expanding content to full width"
    
    if m.top.isContentExpanded = true
        print "HomeScene.brs - [expandContent] Already expanded, skipping"
        return true
    end if
    
    ' Stop any running collapse animations
    collapseContentAnim = m.top.findNode("collapseContentAnimation")
    if collapseContentAnim <> invalid
        collapseContentAnim.control = "stop"
    end if
    collapseBannerAnim = m.top.findNode("collapseBannerAnimation")
    if collapseBannerAnim <> invalid
        collapseBannerAnim.control = "stop"
    end if
    
    ' Start expand animations
    expandContentAnim = m.top.findNode("expandContentAnimation")
    if expandContentAnim <> invalid
        expandContentAnim.control = "start"
    end if
    
    ' Also animate banner if visible
    if m.homeBannerGroup <> invalid and m.homeBannerGroup.visible = true
        expandBannerAnim = m.top.findNode("expandBannerAnimation")
        if expandBannerAnim <> invalid
            expandBannerAnim.control = "start"
        end if
    end if
    
    ' Propagate expanded state to all dynamic content screens
    if m.dynamicScreensContainer <> invalid
        for i = 0 to m.dynamicScreensContainer.getChildCount() - 1
            contentScreen = m.dynamicScreensContainer.getChild(i)
            if contentScreen <> invalid and contentScreen.hasField("isExpanded")
                contentScreen.isExpanded = true
            end if
        end for
    end if
    
    m.top.isContentExpanded = true
    print "HomeScene.brs - [expandContent] Content expansion started"
    
    return true
end function

' Collapse content back to normal width (when nav bar expands)
function collapseContent() as boolean
    print "HomeScene.brs - [collapseContent] Collapsing content to normal width"
    
    if m.top.isContentExpanded = false
        print "HomeScene.brs - [collapseContent] Already collapsed, skipping"
        return true
    end if
    
    ' Stop any running expand animations
    expandContentAnim = m.top.findNode("expandContentAnimation")
    if expandContentAnim <> invalid
        expandContentAnim.control = "stop"
    end if
    expandBannerAnim = m.top.findNode("expandBannerAnimation")
    if expandBannerAnim <> invalid
        expandBannerAnim.control = "stop"
    end if
    
    ' Start collapse animations
    collapseContentAnim = m.top.findNode("collapseContentAnimation")
    if collapseContentAnim <> invalid
        collapseContentAnim.control = "start"
    end if
    
    ' Also animate banner if visible
    if m.homeBannerGroup <> invalid and m.homeBannerGroup.visible = true
        collapseBannerAnim = m.top.findNode("collapseBannerAnimation")
        if collapseBannerAnim <> invalid
            collapseBannerAnim.control = "start"
        end if
    end if
    
    ' Propagate collapsed state to all dynamic content screens
    if m.dynamicScreensContainer <> invalid
        for i = 0 to m.dynamicScreensContainer.getChildCount() - 1
            contentScreen = m.dynamicScreensContainer.getChild(i)
            if contentScreen <> invalid and contentScreen.hasField("isExpanded")
                contentScreen.isExpanded = false
            end if
        end for
    end if
    
    m.top.isContentExpanded = false
    print "HomeScene.brs - [collapseContent] Content collapse started"
    
    return true
end function
