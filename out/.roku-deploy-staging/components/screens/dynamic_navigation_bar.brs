sub init()
    print "DynamicNavigationBar.brs - [init] Initializing dynamic navigation bar"
    
    ' Ensure navigation bar is focusable
    m.top.focusable = true
    m.top.setFocus(true)
    m.top.navHasFocus = true
    
    ' Observe focus changes to restore navHasFocus when navigation regains focus
    m.top.observeField("focusedChild", "onFocusChanged")
    m.navBarBackground = m.top.findNode("navBarBackground")
    m.dynamicNavContainer = m.top.findNode("dynamicNavContainer")
    
    ' Initialize animation nodes
    m.collapseAnimation = m.top.findNode("collapseAnimation")
    m.expandAnimation = m.top.findNode("expandAnimation")
    
    print "DynamicNavigationBar.brs - [init] Navigation bar focusable: " + m.top.focusable.ToStr()
    print "DynamicNavigationBar.brs - [init] Navigation bar hasFocus: " + m.top.hasFocus().ToStr()
    
    ' Initialize static navigation items
    m.accountGroup = m.top.findNode("accountGroup")
    
    ' Navigation items array (will include dynamic items)
    m.navItems = []
    m.dynamicNavItems = []
    m.currentIndex = 0
    print "DynamicNavigationBar.brs - [init] Initial currentIndex set to: " + m.currentIndex.ToStr()
    
    ' Note: Search screen removed - only dynamic content items will be added
    
    ' Show global loading state while waiting for API
    parentScene = m.top.getParent()
    if parentScene <> invalid
        parentScene.callFunc("showGlobalLoader", "Loading Navigation...")
    end if
    
    ' Initialize navigation API to fetch dynamic items
    initializeNavigationApi()
end sub

sub initializeNavigationApi()
    print "DynamicNavigationBar.brs - [initializeNavigationApi] Fetching navigation data"
    
    m.navigationApi = createObject("roSGNode", "NavigationApi")
    m.navigationApi.observeField("responseData", "handleNavigationResponse")
    m.navigationApi.observeField("errorMessage", "handleNavigationError")
    m.navigationApi.control = "RUN"
end sub

sub handleNavigationResponse()
    print "DynamicNavigationBar.brs - [handleNavigationResponse] ################################################"
    print "DynamicNavigationBar.brs - [handleNavigationResponse] ########## NAVIGATION RESPONSE RECEIVED ########"
    print "DynamicNavigationBar.brs - [handleNavigationResponse] ################################################"
    
    responseData = m.navigationApi.responseData
    if responseData <> invalid and responseData <> ""
        print "DynamicNavigationBar.brs - [handleNavigationResponse] Response length: " + responseData.Len().ToStr()
        parsedData = ParseJson(responseData)
        if parsedData <> invalid and parsedData.data <> invalid
            print "DynamicNavigationBar.brs - [handleNavigationResponse] Successfully parsed " + parsedData.data.Count().ToStr() + " navigation items"
            
            ' Check if user is authenticated and inject TV Guide tab
            print "DynamicNavigationBar.brs - [handleNavigationResponse] *** CALLING injectTVGuideTabIfAuthenticated ***"
            navData = parsedData.data
            navData = injectTVGuideTabIfAuthenticated(navData)
            print "DynamicNavigationBar.brs - [handleNavigationResponse] *** RETURNED FROM injectTVGuideTabIfAuthenticated ***"
            print "DynamicNavigationBar.brs - [handleNavigationResponse] navData count after injection: " + navData.Count().ToStr()
            
            m.top.navigationData = navData
            print "DynamicNavigationBar.brs - [handleNavigationResponse] Set navigationData field with " + navData.Count().ToStr() + " items, should trigger observer"
        else
            print "DynamicNavigationBar.brs - [handleNavigationResponse] ERROR: Invalid navigation data structure, parsedData: " + FormatJson(parsedData)
            ' Only use defaults if we truly can't parse the response
            if parsedData = invalid
                useDefaultNavigation()
            end if
        end if
    else
        print "DynamicNavigationBar.brs - [handleNavigationResponse] ERROR: Empty navigation response"
        useDefaultNavigation()
    end if
end sub

function injectTVGuideTabIfAuthenticated(navData as object) as object
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] ========================================"
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Starting TV Guide injection check"
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Input navData count: " + navData.Count().ToStr()
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] ========================================"
    
    ' Log all input nav items first
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Input navigation items:"
    for i = 0 to navData.Count() - 1
        if navData[i] <> invalid
            itemTitle = ""
            itemId = ""
            if navData[i].title <> invalid then itemTitle = navData[i].title
            if navData[i].id <> invalid then itemId = navData[i].id.ToStr()
            print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated]   [" + i.ToStr() + "] id=" + itemId + ", title=" + itemTitle
        end if
    end for
    
    ' Check if user is authenticated using the correct registry location
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Checking authentication..."
    authData = RetrieveAuthDataForTVGuide()
    
    if authData = invalid or authData.accessToken = invalid or authData.accessToken = ""
        print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] User NOT authenticated - no valid auth data"
        print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Returning original navData without TV Guide"
        return navData
    end if
    
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Auth data found, token length: " + authData.accessToken.Len().ToStr()
    
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] *** USER IS AUTHENTICATED ***"
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Proceeding to inject TV Guide tab"
    
    ' Find the index of "User Channels" (id: 14) to insert TV Guide after it
    insertIndex = -1
    for i = 0 to navData.Count() - 1
        if navData[i] <> invalid and navData[i].id <> invalid
            itemId = navData[i].id
            originalType = Type(itemId)
            if Type(itemId) = "roString" or Type(itemId) = "String"
                itemId = Val(itemId)
            end if
            print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Checking item " + i.ToStr() + ": id=" + itemId.ToStr() + " (original type: " + originalType + ")"
            if itemId = 14 ' User Channels
                insertIndex = i + 1
                print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] *** FOUND User Channels at index " + i.ToStr() + " ***"
                print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Will insert TV Guide at index " + insertIndex.ToStr()
                exit for
            end if
        end if
    end for
    
    ' If User Channels not found, insert before Age Restricted (id: 15) or at the end
    if insertIndex = -1
        print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] User Channels not found, looking for Age Restricted..."
        for i = 0 to navData.Count() - 1
            if navData[i] <> invalid and navData[i].id <> invalid
                itemId = navData[i].id
                if Type(itemId) = "roString" or Type(itemId) = "String"
                    itemId = Val(itemId)
                end if
                if itemId = 15 ' Age Restricted
                    insertIndex = i
                    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] *** FOUND Age Restricted at index " + i.ToStr() + " ***"
                    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Will insert TV Guide before it"
                    exit for
                end if
            end if
        end for
    end if
    
    ' If still not found, insert at the end (before Profile which is added separately)
    if insertIndex = -1
        insertIndex = navData.Count()
        print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Neither User Channels nor Age Restricted found"
        print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Inserting TV Guide at end, index: " + insertIndex.ToStr()
    end if
    
    ' Create TV Guide nav item
    tvGuideItem = {
        id: 17,
        title: "TV Guide",
        type: "tvguide",
        images: invalid
    }
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Created TV Guide item: id=17, title=TV Guide"
    
    ' Insert TV Guide at the determined position
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] Building new navigation array with TV Guide at index " + insertIndex.ToStr()
    newNavData = []
    for i = 0 to navData.Count() - 1
        if i = insertIndex
            newNavData.Push(tvGuideItem)
            print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] >>> INSERTED TV Guide tab at position " + newNavData.Count().ToStr()
        end if
        newNavData.Push(navData[i])
    end for
    
    ' If insertIndex is at the end
    if insertIndex = navData.Count()
        newNavData.Push(tvGuideItem)
        print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] >>> INSERTED TV Guide tab at END, position " + newNavData.Count().ToStr()
    end if
    
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] ========================================"
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] FINAL navigation items count: " + newNavData.Count().ToStr()
    print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] ========================================"
    
    ' Log the final navigation structure
    for i = 0 to newNavData.Count() - 1
        if newNavData[i] <> invalid
            itemTitle = ""
            itemId = ""
            if newNavData[i].title <> invalid then itemTitle = newNavData[i].title
            if newNavData[i].id <> invalid then itemId = newNavData[i].id.ToStr()
            print "DynamicNavigationBar.brs - [injectTVGuideTabIfAuthenticated] FINAL [" + i.ToStr() + "]: id=" + itemId + ", title=" + itemTitle
        end if
    end for
    
    ' Also trigger TV Guide API call to pre-fetch the data
    fetchTVGuideData()
    
    return newNavData
end function

sub fetchTVGuideData()
    print "DynamicNavigationBar.brs - [fetchTVGuideData] ========================================"
    print "DynamicNavigationBar.brs - [fetchTVGuideData] Starting TV Guide API fetch"
    print "DynamicNavigationBar.brs - [fetchTVGuideData] ========================================"
    
    ' Create and run TV Guide API task
    m.tvGuideApi = CreateObject("roSGNode", "TVGuideApi")
    m.tvGuideApi.observeField("responseData", "onTVGuideDataReceived")
    m.tvGuideApi.observeField("errorMessage", "onTVGuideError")
    m.tvGuideApi.control = "run"
end sub

sub onTVGuideDataReceived()
    print "DynamicNavigationBar.brs - [onTVGuideDataReceived] ========================================"
    print "DynamicNavigationBar.brs - [onTVGuideDataReceived] TV Guide data received!"
    print "DynamicNavigationBar.brs - [onTVGuideDataReceived] ========================================"
    
    if m.tvGuideApi <> invalid and m.tvGuideApi.responseData <> invalid
        responseLength = m.tvGuideApi.responseData.Len()
        print "DynamicNavigationBar.brs - [onTVGuideDataReceived] Response data length: " + responseLength.ToStr()
        
        ' Parse the response to log channel count
        parsedData = ParseJson(m.tvGuideApi.responseData)
        if parsedData <> invalid and GetInterface(parsedData, "ifArray") <> invalid
            print "DynamicNavigationBar.brs - [onTVGuideDataReceived] Total TV Guide channels: " + parsedData.Count().ToStr()
            
            ' Store the data for later use
            m.tvGuideData = parsedData
            print "DynamicNavigationBar.brs - [onTVGuideDataReceived] TV Guide data stored in m.tvGuideData"
        end if
    end if
end sub

sub onTVGuideError()
    print "DynamicNavigationBar.brs - [onTVGuideError] ========================================"
    print "DynamicNavigationBar.brs - [onTVGuideError] TV Guide API error!"
    print "DynamicNavigationBar.brs - [onTVGuideError] ========================================"
    
    if m.tvGuideApi <> invalid and m.tvGuideApi.errorMessage <> invalid
        print "DynamicNavigationBar.brs - [onTVGuideError] Error: " + m.tvGuideApi.errorMessage
    end if
end sub

function RetrieveAuthDataForTVGuide() as object
    print "DynamicNavigationBar.brs - [RetrieveAuthDataForTVGuide] Reading auth data from registry"
    
    ' Read from AUTH section, authData key (same as NavigationApi)
    section = "AUTH"
    sec = CreateObject("roRegistrySection", section)
    if sec = invalid
        print "DynamicNavigationBar.brs - [RetrieveAuthDataForTVGuide] Could not create registry section"
        return invalid
    end if
    
    if not sec.Exists("authData")
        print "DynamicNavigationBar.brs - [RetrieveAuthDataForTVGuide] authData key does not exist"
        return invalid
    end if
    
    jsonData = sec.Read("authData")
    if jsonData = invalid or jsonData = ""
        print "DynamicNavigationBar.brs - [RetrieveAuthDataForTVGuide] authData is empty"
        return invalid
    end if
    
    print "DynamicNavigationBar.brs - [RetrieveAuthDataForTVGuide] Read authData, length: " + jsonData.Len().ToStr()
    
    data = ParseJson(jsonData)
    if data = invalid
        print "DynamicNavigationBar.brs - [RetrieveAuthDataForTVGuide] Failed to parse authData JSON"
        return invalid
    end if
    
    ' Check if token is expired
    currentTime = CreateObject("roDateTime").asSeconds()
    if data.expiry <> invalid and currentTime > data.expiry
        print "DynamicNavigationBar.brs - [RetrieveAuthDataForTVGuide] Auth token expired"
        return invalid
    end if
    
    if data.accessToken <> invalid and data.accessToken <> ""
        print "DynamicNavigationBar.brs - [RetrieveAuthDataForTVGuide] Valid auth data found"
        return data
    end if
    
    print "DynamicNavigationBar.brs - [RetrieveAuthDataForTVGuide] No accessToken in auth data"
    return invalid
end function

sub handleNavigationError()
    print "DynamicNavigationBar.brs - [handleNavigationError] Navigation API error: " + m.navigationApi.errorMessage
    ' Only use defaults if there's a real API failure, not parsing issues
    if m.navigationApi.errorMessage <> invalid and m.navigationApi.errorMessage <> ""
        useDefaultNavigation()
    end if
end sub


sub useDefaultNavigation()
    print "DynamicNavigationBar.brs - [useDefaultNavigation] Using default navigation items"
    
    defaultNavData = [
        {
            "id": 1,
            "title": "Home",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/home_icon.png"]
            }
        },
        {
            "id": 2,
            "title": "Live",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/live_icon.png"]
            }
        },
        {
            "id": 3,
            "title": "Movies",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/movie_icon.png"]
            }
        },
        {
            "id": 4,
            "title": "TV Shows",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/archives_icon.png"]
            }
        }
    ]
    
    m.top.navigationData = defaultNavData
end sub

function buildNavigationItems() as boolean
    print "DynamicNavigationBar.brs - [buildNavigationItems] ################################################"
    print "DynamicNavigationBar.brs - [buildNavigationItems] ########## BUILDING NAVIGATION ITEMS ##########"
    print "DynamicNavigationBar.brs - [buildNavigationItems] ################################################"
    
    navigationData = m.top.navigationData
    if navigationData = invalid or navigationData.Count() = 0
        print "DynamicNavigationBar.brs - [buildNavigationItems] No navigation data available"
        return false
    end if
    
    print "DynamicNavigationBar.brs - [buildNavigationItems] Received " + navigationData.Count().ToStr() + " navigation items"
    print "DynamicNavigationBar.brs - [buildNavigationItems] Listing all items:"
    for i = 0 to navigationData.Count() - 1
        if navigationData[i] <> invalid
            itemTitle = "N/A"
            itemId = "N/A"
            if navigationData[i].title <> invalid then itemTitle = navigationData[i].title
            if navigationData[i].id <> invalid then itemId = navigationData[i].id.ToStr()
            print "DynamicNavigationBar.brs - [buildNavigationItems]   [" + i.ToStr() + "] id=" + itemId + ", title=" + itemTitle
        end if
    end for
    
    ' Clear existing dynamic items (including loading state)
    clearDynamicNavItems()
    
    ' Hide global loader
    parentScene = m.top.getParent()
    if parentScene <> invalid
        parentScene.callFunc("hideGlobalLoader")
    end if
    
    ' Ensure navigation bar is visible after build
    m.top.visible = true
    print "DynamicNavigationBar.brs - [buildNavigationItems] Navigation bar visibility set to true"
    
    ' Build dynamic navigation items
    startY = 150 ' Starting Y position for dynamic items
    itemSpacing = 100 ' Spacing between items
    
    for i = 0 to navigationData.Count() - 1
        navItem = navigationData[i]
        if navItem <> invalid
            createDynamicNavItem(navItem, startY + (i * itemSpacing), i) ' Direct index mapping since search is removed
        end if
    end for
    
    ' Add Profile tab after dynamic items
    profileNavItem = {
        id: "999",
        title: "Profile",
        type: "account"
    }
    profileIndex = navigationData.Count()
    print "DynamicNavigationBar.brs - [buildNavigationItems] Creating Profile tab at index: " + profileIndex.ToStr()
    createDynamicNavItem(profileNavItem, startY + (profileIndex * itemSpacing), profileIndex)
    
    ' Set initial focus and visual state
    if m.navItems.Count() > 0
        m.currentIndex = 0 ' Start with first item (Home)
        print "DynamicNavigationBar.brs - [buildNavigationItems] Setting initial currentIndex to: " + m.currentIndex.ToStr()
        
        ' Ensure selectedIndex is also set to 0 to prevent mismatches
        m.top.selectedIndex = 0
        print "DynamicNavigationBar.brs - [buildNavigationItems] Setting initial selectedIndex to: " + m.top.selectedIndex.ToStr()
        
        ' Make all nav items non-focusable so focus goes to the parent Group
        for i = 0 to m.navItems.Count() - 1
            if m.navItems[i] <> invalid
                m.navItems[i].focusable = false
            end if
        end for
        
        ' Set focus on the navigation bar Group itself
        m.top.setFocus(true)
        makeNavItemActive(m.currentIndex)
        
        print "DynamicNavigationBar.brs - [buildNavigationItems] Initial navigation state - currentIndex: " + m.currentIndex.ToStr() + ", selectedIndex: " + m.top.selectedIndex.ToStr()
        
        ' Force initial state to prevent any external interference
        print "DynamicNavigationBar.brs - [buildNavigationItems] *** FORCING INITIAL STATE TO HOME (INDEX 0) ***"
        m.currentIndex = 0
        m.top.selectedIndex = 0
        makeNavItemActive(0)
        print "DynamicNavigationBar.brs - [buildNavigationItems] *** FORCED STATE: currentIndex=" + m.currentIndex.ToStr() + ", selectedIndex=" + m.top.selectedIndex.ToStr() + " ***"
        
        ' Create a timer to re-enforce the initial state after a short delay
        ' This handles cases where external code tries to change the index after initialization
        if m.initialStateTimer <> invalid
            m.initialStateTimer.control = "stop"
        end if
        m.initialStateTimer = CreateObject("roSGNode", "Timer")
        m.initialStateTimer.duration = 0.5  ' 500ms delay
        m.initialStateTimer.repeat = false
        m.initialStateTimer.observeField("fire", "onInitialStateTimer")
        m.initialStateTimer.control = "start"
        print "DynamicNavigationBar.brs - [buildNavigationItems] Started timer to re-enforce initial state"
        
        ' Also create a startup protection timer that prevents ANY index changes for a few seconds
        if m.startupProtectionTimer <> invalid
            m.startupProtectionTimer.control = "stop"
        end if
        m.startupProtectionTimer = CreateObject("roSGNode", "Timer")
        m.startupProtectionTimer.duration = 3.0  ' 3 second protection period
        m.startupProtectionTimer.repeat = false
        m.startupProtectionTimer.observeField("fire", "onStartupProtectionTimer")
        m.startupProtectionTimer.control = "start"
        print "DynamicNavigationBar.brs - [buildNavigationItems] Started 3-second startup protection timer"
    end if
    
    print "DynamicNavigationBar.brs - [buildNavigationItems] Built " + m.navItems.Count().ToStr() + " navigation items"
    return true
end function

sub createDynamicNavItem(navItem as object, yPosition as integer, index as integer)
    print "DynamicNavigationBar.brs - [createDynamicNavItem] Creating item: " + navItem.title
    
    ' Create group for navigation item
    navGroup = CreateObject("roSGNode", "Group")
    navGroup.id = "navItem_" + navItem.id.ToStr()
    navGroup.translation = [15, yPosition]
    navGroup.focusable = true
    
    ' Create focus indicator rectangle (initially hidden)
    focusIndicator = CreateObject("roSGNode", "Rectangle")
    focusIndicator.id = "focusIndicator_" + navItem.id.ToStr()
    focusIndicator.width = 210
    focusIndicator.height = 60
    focusIndicator.color = "#4FC3F7"
    focusIndicator.opacity = 0.2
    focusIndicator.translation = [0, 0]
    focusIndicator.visible = false
    
    ' Create label (perfectly centered within the focus indicator)
    navLabel = CreateObject("roSGNode", "Label")
    navLabel.id = "label_" + navItem.id.ToStr()
    
    ' Shorten long titles to fit in nav bar
    displayTitle = navItem.title
    if displayTitle = "Age Restricted Channels"
        displayTitle = "Age Restricted"
    end if
    navLabel.text = displayTitle
    navLabel.color = "#ffffff"
    navLabel.font = "font:UrbanistMedium"
    navLabel.translation = [0, 0]  ' Align with focus indicator
    navLabel.width = 210  ' Same width as focus indicator (wider for "Age Restricted")
    navLabel.height = 60  ' Same height as focus indicator
    navLabel.horizAlign = "center"
    navLabel.vertAlign = "center"
    
    ' Set font
    labelFont = CreateObject("roSGNode", "Font")
    labelFont.uri = "pkg:/images/UrbanistMedium.ttf"
    labelFont.size = 26
    navLabel.font = labelFont
    
    ' Add focus indicator and label to group
    navGroup.appendChild(focusIndicator)
    navGroup.appendChild(navLabel)
    
    ' Add to dynamic container
    m.dynamicNavContainer.appendChild(navGroup)
    
    ' Add to navigation items array
    m.navItems.Push(navGroup)
    m.dynamicNavItems.Push(navGroup)
    
    ' Store navigation data for later use
    navGroup.addField("navData", "assocarray", false)
    navGroup.navData = navItem
end sub

sub clearDynamicNavItems()
    print "DynamicNavigationBar.brs - [clearDynamicNavItems] Clearing existing dynamic items"
    
    ' Remove dynamic items from navItems array
    if m.dynamicNavItems <> invalid
        for each item in m.dynamicNavItems
            ' Find and remove from navItems
            for i = 0 to m.navItems.Count() - 1
                if m.navItems[i].isSameNode(item)
                    m.navItems.Delete(i)
                    exit for
                end if
            end for
        end for
    end if
    
    ' Clear dynamic container
    m.dynamicNavContainer.removeChildrenIndex(m.dynamicNavContainer.getChildCount(), 0)
    m.dynamicNavItems = []
end sub

sub focusUpdated()
    print "DynamicNavigationBar.brs - [focusUpdated] navHasFocus: " + m.top.navHasFocus.ToStr() + ", hasFocus: " + m.top.hasFocus().ToStr()
    
    if m.top.navHasFocus = false
        m.top.opacity = 1
        ' Collapse navigation when losing focus
        collapseNav()
    else
        m.top.opacity = 1
        ' Expand navigation when gaining focus
        expandNav()
        
        ' Ensure the navigation bar actually has focus when navHasFocus is true
        if not m.top.hasFocus()
            print "DynamicNavigationBar.brs - [focusUpdated] Navigation bar should have focus but doesn't, forcing focus"
            forceFocus()
        end if
        
        ' Double-check: if navigation bar still doesn't have focus, try setting it directly
        if not m.top.hasFocus()
            print "DynamicNavigationBar.brs - [focusUpdated] Still no focus after forceFocus, trying direct setFocus"
            m.top.setFocus(true)
        end if
        
        ' Ensure the current item is visually active (don't set focus on individual items here)
        if m.navItems <> invalid and m.currentIndex <> invalid
            if Type(m.currentIndex) = "roInt" or Type(m.currentIndex) = "Integer" or Type(m.currentIndex) = "roInteger"
                if m.currentIndex >= 0 and m.currentIndex < m.navItems.Count()
                    if m.navItems[m.currentIndex] <> invalid
                        print "DynamicNavigationBar.brs - [focusUpdated] Making nav item visually active: " + m.currentIndex.ToStr()
                        ' Ensure the current item is visually active
                        makeNavItemActive(m.currentIndex)
                    end if
                else
                    print "DynamicNavigationBar.brs - [focusUpdated] currentIndex out of range: " + m.currentIndex.ToStr() + ", navItems count: " + m.navItems.Count().ToStr()
                    ' Reset to valid range
                    if m.navItems.Count() > 0
                        m.currentIndex = 0
                        makeNavItemActive(m.currentIndex)
                    end if
                end if
            else
                print "DynamicNavigationBar.brs - [focusUpdated] currentIndex is not a number, type: " + Type(m.currentIndex)
                if m.navItems <> invalid and m.navItems.Count() > 0
                    m.currentIndex = 0
                    makeNavItemActive(m.currentIndex)
                end if
            end if
        else
            print "DynamicNavigationBar.brs - [focusUpdated] navItems or currentIndex is invalid"
            if m.navItems <> invalid and m.navItems.Count() > 0
                m.currentIndex = 0
                makeNavItemActive(m.currentIndex)
            end if
        end if
    end if
end sub

sub forceFocus()
    print "DynamicNavigationBar.brs - [forceFocus] Aggressively forcing focus on navigation bar"
    
    ' Debug navigation bar properties
    print "DynamicNavigationBar.brs - [forceFocus] Navigation bar focusable: " + m.top.focusable.ToStr()
    print "DynamicNavigationBar.brs - [forceFocus] Navigation bar visible: " + m.top.visible.ToStr()
    print "DynamicNavigationBar.brs - [forceFocus] Navigation bar opacity: " + m.top.opacity.ToStr()
    print "DynamicNavigationBar.brs - [forceFocus] Navigation bar translation: [" + m.top.translation[0].ToStr() + ", " + m.top.translation[1].ToStr() + "]"
    
    ' Ensure navigation bar is focusable
    if not m.top.focusable
        print "DynamicNavigationBar.brs - [forceFocus] Navigation bar not focusable, setting focusable = true"
        m.top.focusable = true
    end if
    
    ' Get parent scene and clear any other focus
    parentScene = m.top.getParent()
    if parentScene <> invalid
        ' Remove focus from all dynamic content screens
        dynamicScreensContainer = parentScene.findNode("dynamicScreensContainer")
        if dynamicScreensContainer <> invalid
            for i = 0 to dynamicScreensContainer.getChildCount() - 1
                child = dynamicScreensContainer.getChild(i)
                if child <> invalid
                    child.setFocus(false)
                end if
            end for
        end if
        
        ' Remove focus from any other scene children
        if parentScene.focusedChild <> invalid and not parentScene.focusedChild.isSameNode(m.top)
            print "DynamicNavigationBar.brs - [forceFocus] Removing focus from: " + Type(parentScene.focusedChild).ToStr()
            parentScene.focusedChild.setFocus(false)
        end if
    end if
    
    ' First, make sure all nav items are not focusable so focus goes to the parent Group
    if m.navItems <> invalid and m.navItems.Count() > 0
        for i = 0 to m.navItems.Count() - 1
            if m.navItems[i] <> invalid
                m.navItems[i].focusable = false
            end if
        end for
    end if
    
    ' Now set focus on navigation bar Group itself
    m.top.setFocus(true)
    print "DynamicNavigationBar.brs - [forceFocus] After forcing focus - hasFocus: " + m.top.hasFocus().ToStr()
    print "DynamicNavigationBar.brs - [forceFocus] After forcing focus - focusable: " + m.top.focusable.ToStr()
    
    ' If navigation bar Group has focus, we're good
    if m.top.hasFocus()
        print "DynamicNavigationBar.brs - [forceFocus] Navigation bar Group has focus - key events should work"
    else
        print "DynamicNavigationBar.brs - [forceFocus] Navigation bar Group still no focus, trying alternative approach"
        ' As a fallback, make the current nav item focusable and focus it
        if m.navItems <> invalid and m.navItems.Count() > 0 and m.currentIndex >= 0 and m.currentIndex < m.navItems.Count()
            navItem = m.navItems[m.currentIndex]
            if navItem <> invalid
                print "DynamicNavigationBar.brs - [forceFocus] Setting focus on current nav item as fallback: " + m.currentIndex.ToStr()
                navItem.focusable = true
                navItem.setFocus(true)
                print "DynamicNavigationBar.brs - [forceFocus] Nav item hasFocus: " + navItem.hasFocus().ToStr()
            end if
        end if
    end if
end sub

sub onInitialStateTimer()
    print "DynamicNavigationBar.brs - [onInitialStateTimer] *** RE-ENFORCING INITIAL STATE ***"
    print "DynamicNavigationBar.brs - [onInitialStateTimer] Current state - currentIndex: " + m.currentIndex.ToStr() + ", selectedIndex: " + m.top.selectedIndex.ToStr()
    
    ' If the index has been changed from 0, force it back
    if m.currentIndex <> 0 or m.top.selectedIndex <> 0
        print "DynamicNavigationBar.brs - [onInitialStateTimer] *** INDEX WAS CHANGED - FORCING BACK TO HOME ***"
        print "DynamicNavigationBar.brs - [onInitialStateTimer] Was: currentIndex=" + m.currentIndex.ToStr() + ", selectedIndex=" + m.top.selectedIndex.ToStr()
        
        ' Deactivate current item
        if m.currentIndex >= 0 and m.currentIndex < m.navItems.Count()
            makeNavItemInactive(m.currentIndex)
        end if
        
        ' Force back to Home
        m.currentIndex = 0
        m.top.selectedIndex = 0
        makeNavItemActive(0)
        
        print "DynamicNavigationBar.brs - [onInitialStateTimer] *** FORCED BACK TO: currentIndex=" + m.currentIndex.ToStr() + ", selectedIndex=" + m.top.selectedIndex.ToStr() + " ***"
    else
        print "DynamicNavigationBar.brs - [onInitialStateTimer] Initial state is correct - no changes needed"
    end if
    
    ' Stop the timer
    if m.initialStateTimer <> invalid
        m.initialStateTimer.control = "stop"
    end if
end sub

sub onStartupProtectionTimer()
    print "DynamicNavigationBar.brs - [onStartupProtectionTimer] *** STARTUP PROTECTION PERIOD ENDED ***"
    print "DynamicNavigationBar.brs - [onStartupProtectionTimer] Final state - currentIndex: " + m.currentIndex.ToStr() + ", selectedIndex: " + m.top.selectedIndex.ToStr()
    
    ' One final check - if we're still not on Home, force it
    if m.currentIndex <> 0 or m.top.selectedIndex <> 0
        print "DynamicNavigationBar.brs - [onStartupProtectionTimer] *** FINAL CORRECTION - FORCING TO HOME ***"
        
        ' Deactivate current item
        if m.currentIndex >= 0 and m.currentIndex < m.navItems.Count()
            makeNavItemInactive(m.currentIndex)
        end if
        
        ' Force to Home
        m.currentIndex = 0
        m.top.selectedIndex = 0
        makeNavItemActive(0)
        
        print "DynamicNavigationBar.brs - [onStartupProtectionTimer] *** FINAL STATE: currentIndex=" + m.currentIndex.ToStr() + ", selectedIndex=" + m.top.selectedIndex.ToStr() + " ***"
    else
        print "DynamicNavigationBar.brs - [onStartupProtectionTimer] Navigation is correctly on Home tab - protection ended successfully"
    end if
    
    ' Clear the timer reference to indicate protection period is over
    m.startupProtectionTimer = invalid
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    return handleNavigationKey(key, press)
end function

function handleNavigationKey(key as string, press as boolean) as boolean
    print "DynamicNavigationBar.brs - [handleNavigationKey] *** FUNCTION CALLED VIA CALLFUNC ***"
    print "DynamicNavigationBar.brs - [handleNavigationKey] Key: " + key + ", Press: " + press.ToStr() + ", navHasFocus: " + m.top.navHasFocus.ToStr() + ", hasFocus: " + m.top.hasFocus().ToStr()
    print "DynamicNavigationBar.brs - [handleNavigationKey] Current index: " + m.currentIndex.ToStr() + ", Total items: " + m.navItems.Count().ToStr()
    
    ' Only handle key press events, not release
    if not press then
        print "DynamicNavigationBar.brs - [handleNavigationKey] Ignoring key release event"
        return false
    end if
    
    print "DynamicNavigationBar.brs - [handleNavigationKey] *** PROCESSING KEY PRESS EVENT: " + key + " ***"
    
    ' Only handle keys if navigation has conceptual focus
    print "DynamicNavigationBar.brs - [handleNavigationKey] Checking navHasFocus: " + m.top.navHasFocus.ToStr()
    if m.top.navHasFocus = false
        print "DynamicNavigationBar.brs - [handleNavigationKey] Navigation doesn't have conceptual focus, ignoring key: " + key
        return false
    end if
    
    print "DynamicNavigationBar.brs - [handleNavigationKey] Navigation has focus, proceeding with key processing"
    
    ' Check if navigation bar Group has focus
    navBarHasFocus = m.top.hasFocus()
    print "DynamicNavigationBar.brs - [handleNavigationKey] navBarHasFocus: " + navBarHasFocus.ToStr()
    
    ' If navigation bar doesn't have focus but should, try to restore it
    if not navBarHasFocus
        print "DynamicNavigationBar.brs - [handleNavigationKey] Navigation bar doesn't have focus, attempting to restore"
        
        ' Force focus update which will try to set focus on navigation bar Group
        forceFocus()
        
        ' Check again if we have focus
        navBarHasFocus = m.top.hasFocus()
        
        ' If still no focus, ignore the key
        if not navBarHasFocus
            print "DynamicNavigationBar.brs - [handleNavigationKey] Still could not restore focus, ignoring key"
            return false
        else
            print "DynamicNavigationBar.brs - [handleNavigationKey] Successfully restored focus, processing key"
        end if
    else
        print "DynamicNavigationBar.brs - [handleNavigationKey] Navigation bar has focus, processing key"
    end if
    
    ' Validate navigation items are available
    if m.navItems = invalid or m.navItems.Count() = 0
        print "DynamicNavigationBar.brs - [handleNavigationKey] No navigation items available"
        return false
    end if
    
    ' Validate current index
    if m.currentIndex = invalid
        print "DynamicNavigationBar.brs - [handleNavigationKey] currentIndex is invalid, resetting to 0"
        m.currentIndex = 0
    else if Type(m.currentIndex) <> "roInt" and Type(m.currentIndex) <> "Integer" and Type(m.currentIndex) <> "roInteger"
        print "DynamicNavigationBar.brs - [handleNavigationKey] currentIndex wrong type: " + Type(m.currentIndex) + ", value: " + m.currentIndex.ToStr() + ", resetting to 0"
        m.currentIndex = 0
    else if m.currentIndex < 0 or m.currentIndex >= m.navItems.Count()
        print "DynamicNavigationBar.brs - [handleNavigationKey] currentIndex out of bounds: " + m.currentIndex.ToStr() + ", navItems count: " + m.navItems.Count().ToStr() + ", resetting to valid range"
        m.currentIndex = 0
    else
        print "DynamicNavigationBar.brs - [handleNavigationKey] currentIndex is valid: " + m.currentIndex.ToStr()
    end if
    
    if key = "up" then
        print "DynamicNavigationBar.brs - [handleNavigationKey] UP: Current index " + m.currentIndex.ToStr()
        m.storedIndex = m.currentIndex
        makeNavItemInactive(m.storedIndex)
        m.currentIndex = (m.currentIndex - 1 + m.navItems.count()) mod m.navItems.count()
        print "DynamicNavigationBar.brs - [handleNavigationKey] *** UP: NEW INDEX " + m.currentIndex.ToStr() + " ***"
        
        ' Debug what screen this index should show
        if m.currentIndex < m.navItems.count() and m.navItems[m.currentIndex] <> invalid
            navGroup = m.navItems[m.currentIndex]
            if navGroup <> invalid and navGroup.getChildCount() > 1
                navLabel = navGroup.getChild(1)
                if navLabel <> invalid
                    print "DynamicNavigationBar.brs - [handleNavigationKey] UP: Switching to screen: " + navLabel.text
                end if
            end if
        end if
        print "DynamicNavigationBar.brs - [handleNavigationKey] UP: Total nav items: " + m.navItems.count().ToStr()
        if m.currentIndex < m.navItems.count() and m.navItems[m.currentIndex] <> invalid
            navLabel = m.navItems[m.currentIndex].getChild(1)
            if navLabel <> invalid
                print "DynamicNavigationBar.brs - [handleNavigationKey] UP: Moving to: " + navLabel.text
            end if
        end if
        
        ' Update visual state (focus stays on navigation bar Group)
        print "DynamicNavigationBar.brs - [handleNavigationKey] UP: Navigation bar hasFocus: " + m.top.hasFocus().ToStr()
        
        makeNavItemActive(m.currentIndex)
        determineAndExecuteNavigation(m.currentIndex)
        
        ' Trigger screen switch - let the content screen handle focus management
        parentScene = m.top.getParent()
        if parentScene <> invalid
            screenIndex = convertNavIndexToScreenIndex(m.currentIndex)
            print "DynamicNavigationBar.brs - [handleNavigationKey] UP: Navigation index " + m.currentIndex.ToStr() + " -> Screen index " + screenIndex.ToStr()
            print "DynamicNavigationBar.brs - [handleNavigationKey] UP: Calling setScreenFocus(" + screenIndex.ToStr() + ")"
            if m.currentIndex < m.navItems.count() and m.navItems[m.currentIndex] <> invalid
                navLabel = m.navItems[m.currentIndex].getChild(1)
                if navLabel <> invalid
                    print "DynamicNavigationBar.brs - [handleNavigationKey] UP: Switching to screen for: " + navLabel.text
                end if
            end if
            parentScene.callFunc("setScreenFocus", screenIndex)
        end if
        return true
        
    else if key = "down" then
        print "DynamicNavigationBar.brs - [handleNavigationKey] *** DOWN KEY PRESSED ***"
        print "DynamicNavigationBar.brs - [handleNavigationKey] DOWN: Current index " + m.currentIndex.ToStr()
        print "DynamicNavigationBar.brs - [handleNavigationKey] DOWN: Total nav items " + m.navItems.count().ToStr()
        m.storedIndex = m.currentIndex
        makeNavItemInactive(m.storedIndex)
        
        ' Calculate new index with detailed logging
        oldIndex = m.currentIndex
        newIndex = (m.currentIndex + 1) mod m.navItems.count()
        print "DynamicNavigationBar.brs - [handleNavigationKey] DOWN: Calculation (" + oldIndex.ToStr() + " + 1) mod " + m.navItems.count().ToStr() + " = " + newIndex.ToStr()
        m.currentIndex = newIndex
        print "DynamicNavigationBar.brs - [handleNavigationKey] *** DOWN: NEW INDEX SET TO " + m.currentIndex.ToStr() + " ***"
        
        ' Debug what screen this index should show
        if m.currentIndex < m.navItems.count() and m.navItems[m.currentIndex] <> invalid
            navGroup = m.navItems[m.currentIndex]
            if navGroup <> invalid and navGroup.getChildCount() > 1
                navLabel = navGroup.getChild(1)
                if navLabel <> invalid
                    print "DynamicNavigationBar.brs - [handleNavigationKey] DOWN: Switching to screen: " + navLabel.text
                end if
            end if
        end if
        print "DynamicNavigationBar.brs - [handleNavigationKey] DOWN: Total nav items: " + m.navItems.count().ToStr()
        if m.currentIndex < m.navItems.count() and m.navItems[m.currentIndex] <> invalid
            navLabel = m.navItems[m.currentIndex].getChild(1)
            if navLabel <> invalid
                print "DynamicNavigationBar.brs - [handleNavigationKey] DOWN: Moving to: " + navLabel.text
            end if
        end if
        
        ' Update visual state (focus stays on navigation bar Group)
        print "DynamicNavigationBar.brs - [handleNavigationKey] DOWN: Navigation bar hasFocus: " + m.top.hasFocus().ToStr()
        
        makeNavItemActive(m.currentIndex)
        determineAndExecuteNavigation(m.currentIndex)
        
        ' Trigger screen switch - let the content screen handle focus management
        parentScene = m.top.getParent()
        if parentScene <> invalid
            screenIndex = convertNavIndexToScreenIndex(m.currentIndex)
            print "DynamicNavigationBar.brs - [handleNavigationKey] DOWN: Navigation index " + m.currentIndex.ToStr() + " -> Screen index " + screenIndex.ToStr()
            print "DynamicNavigationBar.brs - [handleNavigationKey] DOWN: Calling setScreenFocus(" + screenIndex.ToStr() + ")"
            if m.currentIndex < m.navItems.count() and m.navItems[m.currentIndex] <> invalid
                navLabel = m.navItems[m.currentIndex].getChild(1)
                if navLabel <> invalid
                    print "DynamicNavigationBar.brs - [handleNavigationKey] DOWN: Switching to screen for: " + navLabel.text
                end if
            end if
            print "DynamicNavigationBar.brs - [handleNavigationKey] *** DOWN: CALLING setScreenFocus(" + screenIndex.ToStr() + ") ***"
            parentScene.callFunc("setScreenFocus", screenIndex)
            print "DynamicNavigationBar.brs - [handleNavigationKey] *** DOWN: setScreenFocus CALL COMPLETED ***"
        else
            print "DynamicNavigationBar.brs - [handleNavigationKey] ERROR: Parent scene is invalid for DOWN navigation!"
        end if
        return true
        
    else if key = "right" then
        print "DynamicNavigationBar.brs - [handleNavigationKey] RIGHT: Moving focus to content screen"
        
        ' Set flag to indicate explicit content focus is requested
        parentScene = m.top.getParent()
        if parentScene <> invalid
            screenIndex = convertNavIndexToScreenIndex(m.currentIndex)
            
            ' Handle Account/Profile screen (last nav item) specially
            ' Profile doesn't need nav bar to collapse - it's a settings page
            accountIndex = m.navItems.Count() - 1
            if screenIndex = accountIndex
                print "DynamicNavigationBar.brs - [handleNavigationKey] RIGHT key for Profile screen - keeping nav bar visible"
                ' DON'T set navHasFocus = false - keep nav bar visible for Profile
                
                ' Just transfer focus to the Account screen's interactive element
                accountScreen = parentScene.findNode("account_screen")
                if accountScreen <> invalid
                    accountScreen.setFocus(true)
                    print "DynamicNavigationBar.brs - [handleNavigationKey] Profile screen focus set, hasFocus: " + accountScreen.hasFocus().ToStr()
                end if
                return true
            else
                ' Handle dynamic content screens - these DO need nav bar to collapse
                print "DynamicNavigationBar.brs - [handleNavigationKey] RIGHT: Content screen - collapsing nav bar"
                m.top.navHasFocus = false
                
                dynamicScreensContainer = parentScene.findNode("dynamicScreensContainer")
                if dynamicScreensContainer <> invalid
                    contentScreen = dynamicScreensContainer.getChild(screenIndex)
                    if contentScreen <> invalid
                        print "DynamicNavigationBar.brs - [handleNavigationKey] RIGHT: Setting explicitContentFocusRequested flag"
                        contentScreen.explicitContentFocusRequested = true
                    end if
                end if
                
                ' Call selectAndScreenSpecificFocus for content screens
                selectAndScreenSpecificFocus(m.currentIndex)
            end if
        end if
        
        return true
        
    else if key = "OK" then
        print "DynamicNavigationBar.brs - [handleNavigationKey] OK: Activating current navigation item"
        ' OK key should switch to the selected screen and potentially enter content
        selectAndScreenSpecificFocus(m.currentIndex)
        return true
    end if
    
    return false
end function

sub makeNavItemActive(index as integer)
    print "DynamicNavigationBar.brs - [makeNavItemActive] Activating nav item at index: " + index.ToStr()
    
    if index < 0 or index >= m.navItems.Count()
        print "DynamicNavigationBar.brs - [makeNavItemActive] Index out of range: " + index.ToStr() + ", count: " + m.navItems.Count().ToStr()
        return
    end if
    
    navItem = m.navItems[index]
    if navItem = invalid
        print "DynamicNavigationBar.brs - [makeNavItemActive] Nav item is invalid at index: " + index.ToStr()
        return
    end if
    
    ' Get focus indicator and label
    focusIndicator = navItem.getChild(0)  ' First child is focus indicator
    navLabel = navItem.getChild(1)       ' Second child is the label
    
    if focusIndicator <> invalid
        focusIndicator.visible = true
        print "DynamicNavigationBar.brs - [makeNavItemActive] Showing focus indicator"
    end if
    
    if navLabel <> invalid
        print "DynamicNavigationBar.brs - [makeNavItemActive] Setting active style for: " + navLabel.text
        navLabel.color = "#4FC3F7"
        if navLabel.font <> invalid
            navLabel.font.size = 29
        end if
    else
        print "DynamicNavigationBar.brs - [makeNavItemActive] Nav label is invalid at index: " + index.ToStr()
    end if
end sub

sub makeNavItemInactive(index as integer)
    print "DynamicNavigationBar.brs - [makeNavItemInactive] Deactivating nav item at index: " + index.ToStr()
    
    if index < 0 or index >= m.navItems.Count()
        print "DynamicNavigationBar.brs - [makeNavItemInactive] Index out of range: " + index.ToStr() + ", count: " + m.navItems.Count().ToStr()
        return
    end if
    
    navItem = m.navItems[index]
    if navItem = invalid
        print "DynamicNavigationBar.brs - [makeNavItemInactive] Nav item is invalid at index: " + index.ToStr()
        return
    end if
    
    ' Get focus indicator and label
    focusIndicator = navItem.getChild(0)  ' First child is focus indicator
    navLabel = navItem.getChild(1)       ' Second child is the label
    
    if focusIndicator <> invalid
        focusIndicator.visible = false
        print "DynamicNavigationBar.brs - [makeNavItemInactive] Hiding focus indicator"
    end if
    
    if navLabel <> invalid
        print "DynamicNavigationBar.brs - [makeNavItemInactive] Setting inactive style for: " + navLabel.text
        navLabel.color = "#ffffff"
        if navLabel.font <> invalid
            navLabel.font.size = 26
        end if
    else
        print "DynamicNavigationBar.brs - [makeNavItemInactive] Nav label is invalid at index: " + index.ToStr()
    end if
end sub

sub determineAndExecuteNavigation(index as integer)
    print "DynamicNavigationBar.brs - [determineAndExecuteNavigation] Navigating to index: " + index.ToStr()
    
    ' Get the parent scene to handle navigation
    parentScene = m.top.getParent()
    if parentScene <> invalid
        ' Set the selected index on the parent scene
        if parentScene.hasField("selectedNavIndex")
            parentScene.selectedNavIndex = index
        end if
        
        ' Call navigation handler on parent scene
        if parentScene.hasField("handleDynamicNavigation")
            parentScene.callFunc("handleDynamicNavigation", index)
        end if
    end if
end sub

sub selectAndScreenSpecificFocus(index as integer)
    print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Setting focus for screen at index: " + index.ToStr()
    print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Current navigation index (m.currentIndex): " + m.currentIndex.ToStr()
    print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Total nav items: " + m.navItems.Count().ToStr()
    
    ' Get the parent scene to handle focus
    parentScene = m.top.getParent()
    print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Parent scene: " + Type(parentScene).ToStr()
    
    if parentScene <> invalid
        print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Parent scene subtype: " + parentScene.subtype()
        
        ' Convert navigation index to screen index
        screenIndex = convertNavIndexToScreenIndex(index)
        print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Navigation index " + index.ToStr() + " -> Screen index " + screenIndex.ToStr()
        
        ' Call setScreenFocus function
        result = parentScene.callFunc("setScreenFocus", screenIndex)
        if result <> invalid
            print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Successfully called setScreenFocus, result: " + result.ToStr()
        else
            print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] setScreenFocus returned invalid, but call may have succeeded"
        end if
        
        ' Handle Account screen (last nav item) separately from dynamic content screens
        accountIndex = m.navItems.Count() - 1
        if screenIndex = accountIndex
            print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Account screen (index " + accountIndex.ToStr() + ") - focus handled by home_scene"
            ' Account screen focus is handled by home_scene's showAccountScreen function
        else
            ' After setting screen focus, try to get the content screen and set focus on it
            dynamicScreensContainer = parentScene.findNode("dynamicScreensContainer")
            if dynamicScreensContainer <> invalid
                print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Found dynamicScreensContainer with " + dynamicScreensContainer.getChildCount().ToStr() + " children"
                contentScreen = dynamicScreensContainer.getChild(screenIndex)
                if contentScreen <> invalid
                    print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Found content screen, type: " + Type(contentScreen).ToStr()
                    print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Content screen focusable: " + contentScreen.focusable.ToStr()
                    print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Content screen visible: " + contentScreen.visible.ToStr()
                    print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Setting focus on content screen"
                    contentScreen.setFocus(true)
                    print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Content screen hasFocus: " + contentScreen.hasFocus().ToStr()
                    
                    ' If content screen still doesn't have focus, try to force it
                    if not contentScreen.hasFocus()
                        print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Content screen didn't get focus, ensuring it's focusable"
                        contentScreen.focusable = true
                        contentScreen.setFocus(true)
                        print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Content screen hasFocus after retry: " + contentScreen.hasFocus().ToStr()
                    end if
                else
                    print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Could not find content screen at index: " + screenIndex.ToStr()
                end if
            else
                print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] Could not find dynamicScreensContainer"
            end if
        end if
    else
        print "DynamicNavigationBar.brs - [selectAndScreenSpecificFocus] ERROR: Parent scene is invalid"
    end if
end sub

sub onSelectedIndexChanged()
    print "DynamicNavigationBar.brs - [onSelectedIndexChanged] *** SELECTED INDEX CHANGED ***"
    print "DynamicNavigationBar.brs - [onSelectedIndexChanged] Selected index changed to: " + m.top.selectedIndex.ToStr()
    print "DynamicNavigationBar.brs - [onSelectedIndexChanged] Current index was: " + m.currentIndex.ToStr()
    print "DynamicNavigationBar.brs - [onSelectedIndexChanged] Navigation items count: " + m.navItems.Count().ToStr()
    
    ' Add stack trace to see what's calling this
    print "DynamicNavigationBar.brs - [onSelectedIndexChanged] *** CALL STACK TRACE ***"
    
    ' CRITICAL: Prevent external changes during initial load AND enforce Home tab always during startup
    parentScene = m.top.getParent()
    if parentScene <> invalid and parentScene.callFunc <> invalid
        isInitialLoad = parentScene.callFunc("isInitialLoadPhase")
        print "DynamicNavigationBar.brs - [onSelectedIndexChanged] isInitialLoad: " + isInitialLoad.ToStr()
        
        ' During initial load, ONLY allow index 0 (Home)
        if isInitialLoad = true and m.top.selectedIndex <> 0
            print "DynamicNavigationBar.brs - [onSelectedIndexChanged] *** BLOCKING EXTERNAL INDEX CHANGE DURING INITIAL LOAD ***"
            print "DynamicNavigationBar.brs - [onSelectedIndexChanged] Attempted to change from 0 to " + m.top.selectedIndex.ToStr() + " - REVERTING"
            
            ' Deactivate the incorrectly activated item
            if m.top.selectedIndex >= 0 and m.top.selectedIndex < m.navItems.Count()
                makeNavItemInactive(m.top.selectedIndex)
            end if
            
            m.top.selectedIndex = 0
            m.currentIndex = 0
            makeNavItemActive(0)
            print "DynamicNavigationBar.brs - [onSelectedIndexChanged] *** REVERTED TO HOME (INDEX 0) ***"
            return
        end if
        
        ' Even after initial load, add extra protection for the first few seconds
        ' Check if timer is NOT invalid (still running) = protection is ACTIVE
        if m.startupProtectionTimer <> invalid
            print "DynamicNavigationBar.brs - [onSelectedIndexChanged] Still in startup protection period (timer active)"
            if m.top.selectedIndex <> 0
                print "DynamicNavigationBar.brs - [onSelectedIndexChanged] *** STARTUP PROTECTION: BLOCKING INDEX CHANGE TO " + m.top.selectedIndex.ToStr() + " ***"
                
                ' Deactivate the incorrectly activated item
                if m.top.selectedIndex >= 0 and m.top.selectedIndex < m.navItems.Count()
                    makeNavItemInactive(m.top.selectedIndex)
                end if
                
                m.top.selectedIndex = 0
                m.currentIndex = 0
                makeNavItemActive(0)
                print "DynamicNavigationBar.brs - [onSelectedIndexChanged] *** STARTUP PROTECTION: REVERTED TO HOME (INDEX 0) ***"
                return
            end if
        else
            print "DynamicNavigationBar.brs - [onSelectedIndexChanged] Startup protection period has ended, allowing index changes"
        end if
    end if
    
    ' Update current index and focus
    if m.top.selectedIndex >= 0 and m.top.selectedIndex < m.navItems.Count()
        if m.currentIndex <> m.top.selectedIndex
            print "DynamicNavigationBar.brs - [onSelectedIndexChanged] Updating navigation visual state"
            makeNavItemInactive(m.currentIndex)
            m.currentIndex = m.top.selectedIndex
            makeNavItemActive(m.currentIndex)
        else
            print "DynamicNavigationBar.brs - [onSelectedIndexChanged] Index unchanged, no visual update needed"
        end if
    else
        print "DynamicNavigationBar.brs - [onSelectedIndexChanged] Invalid selectedIndex: " + m.top.selectedIndex.ToStr()
    end if
end sub

function convertNavIndexToScreenIndex(navIndex as integer) as integer
    ' Convert navigation bar index to screen index
    ' Navigation structure (when authenticated):
    '   0=Home, 1=Live TV, 2=Movies, 3=Series, 4=User Channels, 5=TV Guide, 6=Age Restricted, 7=Personal, 8=Account
    ' Navigation structure (when not authenticated):
    '   0=Home, 1=Live TV, 2=Movies, 3=Series, 4=User Channels, 5=Account
    ' Screen structure: Direct 1:1 mapping based on dynamic navigation items
    
    print "DynamicNavigationBar.brs - [convertNavIndexToScreenIndex] Converting nav index " + navIndex.ToStr() + " to screen index " + navIndex.ToStr()
    return navIndex
end function

sub onFocusChanged()
    print "DynamicNavigationBar.brs - [onFocusChanged] Focus changed, hasFocus: " + m.top.hasFocus().ToStr()
    print "DynamicNavigationBar.brs - [onFocusChanged] Current navHasFocus: " + m.top.navHasFocus.ToStr()
    
    ' If navigation bar has focus, restore navHasFocus
    if m.top.hasFocus() and m.top.navHasFocus = false
        print "DynamicNavigationBar.brs - [onFocusChanged] Restoring navHasFocus to true"
        m.top.navHasFocus = true
    end if
end sub

function reloadNavigation() as boolean
    print "DynamicNavigationBar.brs - [reloadNavigation] *** RELOADING NAVIGATION DATA ***"
    
    ' Ensure navigation bar stays visible
    m.top.visible = true
    
    ' Reset navigation state
    m.currentIndex = 0
    m.top.selectedIndex = 0
    m.top.navHasFocus = true
    
    ' Clear existing navigation items
    clearDynamicNavItems()
    
    ' Show global loading state
    parentScene = m.top.getParent()
    if parentScene <> invalid
        parentScene.callFunc("showGlobalLoader", "Reloading App...")
    end if
    
    ' Re-initialize navigation API to fetch fresh data
    print "DynamicNavigationBar.brs - [reloadNavigation] Re-fetching navigation data from API"
    initializeNavigationApi()
    
    return true
end function

' Collapse navigation bar (slide off-screen to the left)
function collapseNav() as boolean
    print "DynamicNavigationBar.brs - [collapseNav] Collapsing navigation bar"
    
    if m.top.isCollapsed = true
        print "DynamicNavigationBar.brs - [collapseNav] Already collapsed, skipping"
        return true
    end if
    
    ' Stop any running animation
    if m.expandAnimation <> invalid
        m.expandAnimation.control = "stop"
    end if
    
    ' Start collapse animation
    if m.collapseAnimation <> invalid
        m.collapseAnimation.control = "start"
    end if
    
    m.top.isCollapsed = true
    
    ' Notify parent to expand content
    parentScene = m.top.getParent()
    if parentScene <> invalid
        print "DynamicNavigationBar.brs - [collapseNav] Calling expandContent on parent"
        parentScene.callFunc("expandContent")
    end if
    
    return true
end function

' Expand navigation bar (slide back on-screen)
function expandNav() as boolean
    print "DynamicNavigationBar.brs - [expandNav] Expanding navigation bar"
    
    if m.top.isCollapsed = false
        print "DynamicNavigationBar.brs - [expandNav] Already expanded, skipping"
        return true
    end if
    
    ' Stop any running animation
    if m.collapseAnimation <> invalid
        m.collapseAnimation.control = "stop"
    end if
    
    ' Start expand animation
    if m.expandAnimation <> invalid
        m.expandAnimation.control = "start"
    end if
    
    m.top.isCollapsed = false
    
    ' Notify parent to collapse content
    parentScene = m.top.getParent()
    if parentScene <> invalid
        print "DynamicNavigationBar.brs - [expandNav] Calling collapseContent on parent"
        parentScene.callFunc("collapseContent")
    end if
    
    return true
end function
