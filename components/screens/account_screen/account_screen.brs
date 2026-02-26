function init()
    print "AccountScreen.brs - [init] Initializing modern account screen"

    ' Ensure account screen is focusable
    m.top.focusable = true
    
    ' Get UI elements
    m.logoutGroup = m.top.findNode("logoutGroup")
    m.loginGroup = m.top.findNode("loginGroup")
    m.statusValue = m.top.findNode("statusValue")
    m.statusIndicator = m.top.findNode("statusIndicator")
    m.logoutFocusBorder = m.top.findNode("logoutFocusBorder")
    m.loginFocusBorder = m.top.findNode("loginFocusBorder")
    
    ' Get user profile UI elements
    m.userProfileSection = m.top.findNode("userProfileSection")
    m.avatarInitials = m.top.findNode("avatarInitials")
    m.profileFullName = m.top.findNode("profileFullName")
    m.emailValue = m.top.findNode("emailValue")
    m.nameValue = m.top.findNode("nameValue")
    m.subscriptionValue = m.top.findNode("subscriptionValue")
    m.userIdValue = m.top.findNode("userIdValue")

    ' Set up observers
    m.top.ObserveField("accountStatus", "authorizationStatusChanged")
    m.top.ObserveField("visible", "VisibilityChanged")
    m.top.ObserveField("focusedChild", "onAccountFocusChanged")
    
    ' Set up focus observers for modern focus effects
    m.logoutGroup.observeField("focusedChild", "onLogoutFocusChanged")
    m.loginGroup.observeField("focusedChild", "onLoginFocusChanged")

    ' Create dialogs
    m.confirmationButtons = CreateObject("roSGNode", "BackDialog")
    m.confirmationButtons.title = "Log Out"
    m.confirmationButtons.message = "Are you sure you want to log out?"
    m.confirmationButtons.ObserveField("buttonSelected", "onConfirmationButtonSelected")

    m.loggedOutSuccessfully = CreateObject("roSGNode", "BackDialog")
    m.loggedOutSuccessfully.title = "Log Out"
    m.loggedOutSuccessfully.message = "You logged out successfully!"
    m.loggedOutSuccessfully.ObserveField("buttonSelected", "onLoggedOutSuccessfulySelected")

    ' Initialize with logged out state (will be updated by validateAccountStatus)
    m.loginGroup.visible = true
    m.logoutGroup.visible = false
    m.userProfileSection.visible = false
    
    ' Set initial status display
    if m.statusValue <> invalid
        m.statusValue.text = "Not authenticated"
    end if
    if m.statusIndicator <> invalid
        m.statusIndicator.color = "#FF5722"  ' Red for not authenticated
    end if
    
    ' Initialize login/signup variables
    m.loginUsername = ""
    m.loginPassword = ""
    m.signupUsername = ""
    m.signupPassword = ""
    
    ' Don't set initial focus here - let navigation handle focus when user presses right
    ' Focus will be set in onKeyEvent when user explicitly enters the content
    
    ' Load user data from registry if available
    loadUserDataFromRegistry()
    
    print "AccountScreen.brs - [init] Modern account screen initialized"
end function

function VisibilityChanged()
    if m.top.visible = true then
        print "AccountScreen.brs - [VisibilityChanged] Account screen became visible"
        validateAccountStatus()
        ' Ensure UI elements are properly displayed
        refreshAccountUI()
    else
        print "AccountScreen.brs - [VisibilityChanged] Account screen became hidden"
    end if
end function

sub onAccountFocusChanged()
    print "AccountScreen.brs - [onAccountFocusChanged] Account screen focus changed"
    print "AccountScreen.brs - [onAccountFocusChanged] hasFocus: " + m.top.hasFocus().ToStr()
    print "AccountScreen.brs - [onAccountFocusChanged] visible: " + m.top.visible.ToStr()
    
    if m.top.hasFocus() and m.top.visible
        print "AccountScreen.brs - [onAccountFocusChanged] Account screen gained focus - refreshing UI"
        refreshAccountUI()
    end if
end sub

sub onTriggerRightAction()
    ' Handle right action trigger from navigation bar
    print "AccountScreen.brs - [onTriggerRightAction] Triggered from navigation bar"
    
    if m.top.accountStatus = true
        ' User is authenticated - activate logout button
        if m.logoutGroup <> invalid
            print "AccountScreen.brs - [onTriggerRightAction] Activating logout button"
            activateLogoutButton()
            m.logoutGroup.setFocus(true)
        end if
    else
        ' User is not authenticated - activate login button
        if m.loginGroup <> invalid
            print "AccountScreen.brs - [onTriggerRightAction] Activating login button"
            activateLoginButton()
            m.loginGroup.setFocus(true)
        end if
    end if
    
    ' Reset the trigger
    m.top.triggerRightAction = false
end sub

sub refreshAccountUI()
    print "AccountScreen.brs - [refreshAccountUI] Refreshing Account screen UI elements"
    
    ' Ensure all UI elements are properly visible and configured
    if m.loginGroup <> invalid and m.logoutGroup <> invalid
        print "AccountScreen.brs - [refreshAccountUI] Current account status: " + m.top.accountStatus.ToStr()
        
        if m.top.accountStatus = true
            ' User is authenticated - show logout option and user profile
            m.loginGroup.visible = false
            m.logoutGroup.visible = true
            if m.userProfileSection <> invalid
                m.userProfileSection.visible = true
                ' Refresh user data display
                loadUserDataFromRegistry()
            end if
            if m.statusValue <> invalid
                m.statusValue.text = "Authenticated"
            end if
            if m.statusIndicator <> invalid
                m.statusIndicator.color = "#4CAF50"  ' Green for authenticated
            end if
            print "AccountScreen.brs - [refreshAccountUI] Showing logout option and user profile"
        else
            ' User is not authenticated - show login option, hide profile
            m.loginGroup.visible = true
            m.logoutGroup.visible = false
            if m.userProfileSection <> invalid
                m.userProfileSection.visible = false
            end if
            if m.statusValue <> invalid
                m.statusValue.text = "Not authenticated"
            end if
            if m.statusIndicator <> invalid
                m.statusIndicator.color = "#FF5722"  ' Red for not authenticated
            end if
            print "AccountScreen.brs - [refreshAccountUI] Showing login option, hiding user profile"
        end if
        
        print "AccountScreen.brs - [refreshAccountUI] UI refresh complete"
    else
        print "AccountScreen.brs - [refreshAccountUI] ERROR: Login or logout group is invalid"
    end if
end sub

function authorizationStatusChanged()
    print "AccountScreen.brs - [authorizationStatusChanged] Authorization Status Changed: " + m.top.accountStatus.ToStr()
    
    if m.top.accountStatus = true
        ' User is authenticated
        m.loginGroup.visible = false
        m.logoutGroup.visible = true
        if m.statusValue <> invalid
            m.statusValue.text = "Authenticated"
        end if
        if m.statusIndicator <> invalid
            m.statusIndicator.color = "#4CAF50"  ' Green for authenticated
        end if
        ' Don't auto-set focus here - let navigation handle it
        print "AccountScreen.brs - [authorizationStatusChanged] User authenticated - showing logout option"
    else
        ' User is not authenticated
        m.loginGroup.visible = true
        m.logoutGroup.visible = false
        if m.statusValue <> invalid
            m.statusValue.text = "Not authenticated"
        end if
        if m.statusIndicator <> invalid
            m.statusIndicator.color = "#FF5722"  ' Red for not authenticated
        end if
        ' Don't auto-set focus here - let navigation handle it
        print "AccountScreen.brs - [authorizationStatusChanged] User not authenticated - showing login option"
    end if
end function

sub onLoggedOutSuccessfulySelected()
    print "AccountScreen.brs - [onLoggedOutSuccessfulySelected] Logout success dialog closed"
    TopDialogClose()
    
    ' Update account status to logged out
    m.top.accountStatus = false
    
    ' Refresh the UI to show login option
    refreshAccountUI()
    
    ' Set focus back to the login button
    if m.loginGroup <> invalid
        m.loginGroup.setFocus(true)
        activateLoginButton()
    end if
    
    print "AccountScreen.brs - [onLoggedOutSuccessfulySelected] Account screen updated to show login option"
end sub

sub onConfirmationButtonSelected()
    print m.confirmationButtons.buttonSelected
    print "Here is what hapens when you click on it"

    if m.confirmationButtons.buttonSelected = 1 then
        TopDialogClose()
        activateLogoutButton()
    else
        ClearAuthData()
        showLoggedOutSuccessfullyDialog()

    end if
end sub

sub showLoggedOutSuccessfullyDialog()
    m.top.accountStatus = false
    ' activateLoginButton()
    ' deactivateLogoutButton()
    arrayButtons = []
    arrayButtons.Push("Close")

    m.loggedOutSuccessfully.buttons = arrayButtons
    m.loggedOutSuccessfully.optionsDialog = true
    m.top.GetScene().dialog = m.loggedOutSuccessfully
    m.top.GetScene().dialog.setFocus(true)
    m.loggedOutSuccessfully.observeField("buttonSelected", "onDialogButtonSelected")



end sub


sub onDialogButtonSelected(event as object)
    print "AccountScreen.brs - [onDialogButtonSelected] Logout dialog closed"
    
    ' Close the dialog
    m.top.GetScene().dialog = invalid
    
    ' Update account status to logged out
    m.top.accountStatus = false
    
    ' Refresh the UI to show login option instead of logout
    refreshAccountUI()
    
    ' Set focus back to the login button
    if m.loginGroup <> invalid
        m.loginGroup.setFocus(true)
        activateLoginButton()
    end if
    
    print "AccountScreen.brs - [onDialogButtonSelected] Account screen updated to show login option"
end sub



sub showConfirmationDialog()
    arrayButtons = []
    arrayButtons.Push("Yes")
    arrayButtons.Push("No")

    m.confirmationButtons.buttons = arrayButtons
    m.confirmationButtons.optionsDialog = true
    m.top.GetScene().dialog = m.confirmationButtons
    m.top.GetScene().dialog.setFocus(true)
end sub

sub TopDialogClose()
    if m.top.GetScene().dialog <> invalid then
        m.top.GetScene().dialog.close = true
    end if
end sub


function ClearAuthData()
    section = "AUTH"
    sec = CreateObject("roRegistrySection", section)

    ' Clear the auth data
    sec.Delete("authData")
    
    ' Clear the user data
    sec.Delete("userData")
    
    sec.Flush()
    
    ' Clear user profile UI
    clearUserProfile()

    print "Auth data and user data cleared successfully."
end function

sub validateAccountStatus()
    authData = RetrieveAuthData()

    print "OLA AMIGOS"
    print authData
    if authData <> invalid
        if authData.accessToken <> invalid
            print authData.accessToken
            print "Here is the Access TOKEN!!!"
            m.top.accountStatus = true
            ' m.loginGroup.visible = false
            ' m.logoutGroup.visible = true
        else
            m.top.accountStatus = false
            ' m.loginGroup.visible = true
            ' m.logoutGroup.visible = false
        end if
    else
        print "AUTHDATA iS INVALID"
        m.top.accountStatus = false
        authorizationStatusChanged()
        ' m.loginGroup.visible = true
        ' m.logoutGroup.visible = false
    end if
end sub


function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)
    print jsonData
    print "Here is JSON DATA??????"
    ' Check if the JSON data is valid
    if jsonData <> invalid and jsonData <> ""
        ' Deserialize the JSON string back into an associative array
        data = ParseJson(jsonData)
        print data
        print "we are Here?"
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


function onKeyEvent(key as string, press as boolean) as boolean
    print "AccountScreen.brs - [onKeyEvent] *** ACCOUNT SCREEN ONKEYEVENT CALLED ***"
    print "AccountScreen.brs - [onKeyEvent] Key: " + key + ", Press: " + press.ToStr()
    print "AccountScreen.brs - [onKeyEvent] Account screen hasFocus: " + m.top.hasFocus().ToStr()
    print "AccountScreen.brs - [onKeyEvent] Account screen visible: " + m.top.visible.ToStr()
    
    if press = true and key = "right"
        print "AccountScreen.brs - [onKeyEvent] RIGHT key pressed - activating action button"
        print "AccountScreen.brs - [onKeyEvent] Account screen hasFocus: " + m.top.hasFocus().ToStr()
        print "AccountScreen.brs - [onKeyEvent] Account status: " + m.top.accountStatus.ToStr()
        
        ' Activate the appropriate button based on authentication status
        if m.top.accountStatus = true
            ' User is authenticated - activate logout button
            if m.logoutGroup <> invalid
                print "AccountScreen.brs - [onKeyEvent] Activating logout button"
                activateLogoutButton()
                m.logoutGroup.setFocus(true)
                print "AccountScreen.brs - [onKeyEvent] Logout button activated and focused"
            end if
        else
            ' User is not authenticated - activate login button
            if m.loginGroup <> invalid
                print "AccountScreen.brs - [onKeyEvent] Activating login button"
                activateLoginButton()
                m.loginGroup.setFocus(true)
                print "AccountScreen.brs - [onKeyEvent] Login button activated and focused"
            end if
        end if
        return true
    else if press = false and key = "OK" then
        ' m.navBar = m.global.findNode("navigation_bar")
        ' m.navBar.setFocus(true)
        ' m.navBar.navHasFocus = true
        ' deactivateLogoutButton()
        ' deactivateLoginButton()
        return true

    else if (press = false or press = true) and key = "back" then
        print "AccountScreen.brs - [onKeyEvent] BACK key pressed - returning to Profile tab in navigation"
        m.navBar = m.global.findNode("dynamic_navigation_bar")
        if m.navBar <> invalid
            ' Remove focus from account screen first
            m.top.setFocus(false)
            ' Set focus to Profile tab (last item) in navigation - dynamic index
            profileIndex = m.navBar.navigationData.Count()  ' Profile is after all dynamic items
            m.navBar.selectedIndex = profileIndex
            m.navBar.setFocus(true)
            m.navBar.navHasFocus = true
            deactivateLogoutButton()
            deactivateLoginButton()
            print "AccountScreen.brs - [onKeyEvent] Focus returned to Profile tab (index " + profileIndex.ToStr() + ") in navigation bar via BACK"
        end if
        return true
    else if (press = false) and key = "back" then

        return true
    end if

    if press = true and key = "OK" then
        print "AccountScreen.brs - [onKeyEvent] OK key pressed"
        
        if m.logoutGroup <> invalid and m.logoutGroup.hasFocus() then
            print "AccountScreen.brs - [onKeyEvent] Logout button selected - showing confirmation"
            showConfirmationDialog()
            return true
        end if

        if m.loginGroup <> invalid and m.loginGroup.hasFocus() then
            print "AccountScreen.brs - [onKeyEvent] Login button selected - navigating to login"
            navigateToLoginPage()
            return true
        end if
    else if key = "left" and press = true
        print "AccountScreen.brs - [onKeyEvent] LEFT key pressed - returning to Profile tab in navigation"
        m.navBar = m.global.findNode("dynamic_navigation_bar")
        if m.navBar <> invalid
            ' Remove focus from account screen first
            m.top.setFocus(false)
            ' Set focus to Profile tab (last item) in navigation - dynamic index
            profileIndex = m.navBar.navigationData.Count()  ' Profile is after all dynamic items
            m.navBar.selectedIndex = profileIndex
            m.navBar.setFocus(true)
            m.navBar.navHasFocus = true
            deactivateLogoutButton()
            deactivateLoginButton()
            print "AccountScreen.brs - [onKeyEvent] Focus returned to Profile tab in navigation bar"
        end if
        return true
    else if (key = "up" or key = "down") and press = true
        print "AccountScreen.brs - [onKeyEvent] UP/DOWN key pressed - switching tabs via navigation bar"
        m.navBar = m.global.findNode("dynamic_navigation_bar")
        if m.navBar <> invalid
            ' Deactivate buttons first
            deactivateLogoutButton()
            deactivateLoginButton()
            
            ' Calculate the new index based on key pressed - Profile is always last tab
            totalTabs = m.navBar.navigationData.Count() + 1  ' Dynamic items + Profile
            currentIndex = totalTabs - 1  ' Profile is always the last tab
            
            if key = "up"
                newIndex = (currentIndex - 1 + totalTabs) mod totalTabs
                print "AccountScreen.brs - [onKeyEvent] UP: Moving from Profile (" + currentIndex.ToStr() + ") to index " + newIndex.ToStr()
            else ' down
                newIndex = (currentIndex + 1) mod totalTabs
                print "AccountScreen.brs - [onKeyEvent] DOWN: Moving from Profile (" + currentIndex.ToStr() + ") to index " + newIndex.ToStr()
            end if
            
            ' Update navigation bar index
            m.navBar.selectedIndex = newIndex
            m.navBar.setFocus(true)
            m.navBar.navHasFocus = true
            
            ' Tell HomeScene to switch to the new screen
            parentScene = m.top.getScene()
            if parentScene <> invalid
                print "AccountScreen.brs - [onKeyEvent] Calling switchScreenContent(" + newIndex.ToStr() + ")"
                parentScene.callFunc("switchScreenContent", newIndex)
            end if
            
            print "AccountScreen.brs - [onKeyEvent] Switched to tab index: " + newIndex.ToStr()
        end if
        return true


    end if


    return false ' Return true if the key event was handled

    return false
end function

sub onLogoutFocusChanged()
    if m.logoutGroup.hasFocus() or m.logoutGroup.isInFocusChain()
        m.logoutFocusBorder.visible = true
        print "AccountScreen.brs - [onLogoutFocusChanged] Logout focused - showing border"
    else
        m.logoutFocusBorder.visible = false
        print "AccountScreen.brs - [onLogoutFocusChanged] Logout unfocused - hiding border"
    end if
end sub

sub onLoginFocusChanged()
    if m.loginGroup.hasFocus() or m.loginGroup.isInFocusChain()
        m.loginFocusBorder.visible = true
        print "AccountScreen.brs - [onLoginFocusChanged] Login focused - showing border"
    else
        m.loginFocusBorder.visible = false
        print "AccountScreen.brs - [onLoginFocusChanged] Login unfocused - hiding border"
    end if
end sub

function navigateToLoginPage()
    print "AccountScreen.brs - [navigateToLoginPage] Showing login dialog instead of navigation"
    showLoginDialog()
end function

sub showLoginDialog()
    print "AccountScreen.brs - [showLoginDialog] Creating authentication options dialog"
    
    ' Go directly to login flow (no signup dialog)
    print "AccountScreen.brs - [showLoginDialog] Starting login flow directly"
    showLoginFlow()
end sub

sub onAuthorizationDialogSelected()
    ' This function is kept for compatibility but simplified
    print "AccountScreen.brs - [onAuthorizationDialogSelected] Button selected: " + m.authorizationDialog.buttonSelected.ToStr()
    
    if m.authorizationDialog.buttonSelected = 0
        ' Login button pressed
        print "AccountScreen.brs - [onAuthorizationDialogSelected] Login selected"
        closeAuthorizationDialog()
        showLoginFlow()
    else
        ' Cancel button pressed
        print "AccountScreen.brs - [onAuthorizationDialogSelected] Cancel selected"
        closeAuthorizationDialog()
    end if
end sub

sub closeAuthorizationDialog()
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
        m.top.GetScene().dialog = invalid
    end if
    print "AccountScreen.brs - [closeAuthorizationDialog] Authorization dialog closed"
end sub

sub showSignupFlow()
    print "AccountScreen.brs - [showSignupFlow] Starting signup flow"
    
    ' Show username dialog first
    m.usernameDialog = CreateObject("roSGNode", "KeyboardDialog")
    m.usernameDialog.title = "Create Account - Username"
    m.usernameDialog.text = ""
    m.usernameDialog.buttons = ["Next", "Cancel"]
    m.usernameDialog.observeField("buttonSelected", "onSignupUsernameSelected")
    m.usernameDialog.observeField("wasClosed", "onSignupDialogClosed")
    
    m.top.GetScene().dialog = m.usernameDialog
    m.top.GetScene().dialog.setFocus(true)
    
    print "AccountScreen.brs - [showSignupFlow] Username dialog displayed"
end sub

sub showLoginFlow()
    print "AccountScreen.brs - [showLoginFlow] Starting login flow"
    
    ' Show username dialog first
    m.usernameDialog = CreateObject("roSGNode", "KeyboardDialog")
    m.usernameDialog.title = "Login - Username"
    m.usernameDialog.text = ""
    m.usernameDialog.buttons = ["Next", "Cancel"]
    m.usernameDialog.observeField("buttonSelected", "onLoginUsernameSelected")
    m.usernameDialog.observeField("wasClosed", "onLoginDialogClosed")
    
    m.top.GetScene().dialog = m.usernameDialog
    m.top.GetScene().dialog.setFocus(true)
    
    print "AccountScreen.brs - [showLoginFlow] Username dialog displayed"
end sub

sub onSignupUsernameSelected()
    print "AccountScreen.brs - [onSignupUsernameSelected] Button: " + m.usernameDialog.buttonSelected.ToStr()
    
    if m.usernameDialog.buttonSelected = 0 and m.usernameDialog.text.Len() > 0
        ' Next button with valid username
        m.signupUsername = m.usernameDialog.text
        m.usernameDialog.close = true
        showSignupPasswordDialog()
    else if m.usernameDialog.buttonSelected = 1
        ' Cancel button
        m.usernameDialog.close = true
        returnToAccountScreen()
    else
        ' Invalid input
        m.usernameDialog.keyboard.textEditBox.hintText = "Please enter a valid username"
    end if
end sub

sub onLoginUsernameSelected()
    print "AccountScreen.brs - [onLoginUsernameSelected] Button: " + m.usernameDialog.buttonSelected.ToStr()
    
    if m.usernameDialog.buttonSelected = 0 and m.usernameDialog.text.Len() > 0
        ' Next button with valid username
        m.loginUsername = m.usernameDialog.text
        m.usernameDialog.close = true
        showLoginPasswordDialog()
    else if m.usernameDialog.buttonSelected = 1
        ' Cancel button
        m.usernameDialog.close = true
        returnToAccountScreen()
    else
        ' Invalid input
        m.usernameDialog.keyboard.textEditBox.hintText = "Please enter a valid username"
    end if
end sub

sub showSignupPasswordDialog()
    print "AccountScreen.brs - [showSignupPasswordDialog] Showing password dialog for signup"
    
    m.passwordDialog = CreateObject("roSGNode", "KeyboardDialog")
    m.passwordDialog.title = "Create Account - Password"
    m.passwordDialog.keyboard.textEditBox.secureMode = true
    m.passwordDialog.buttons = ["Create Account", "Show Password", "Hide Password", "Back"]
    m.passwordDialog.observeField("buttonSelected", "onSignupPasswordSelected")
    m.passwordDialog.observeField("wasClosed", "onSignupDialogClosed")
    
    m.top.GetScene().dialog = m.passwordDialog
    m.top.GetScene().dialog.setFocus(true)
end sub

sub showLoginPasswordDialog()
    print "AccountScreen.brs - [showLoginPasswordDialog] Showing password dialog for login"
    
    m.passwordDialog = CreateObject("roSGNode", "KeyboardDialog")
    m.passwordDialog.title = "Login - Password"
    m.passwordDialog.keyboard.textEditBox.secureMode = true
    m.passwordDialog.buttons = ["Login", "Show Password", "Hide Password", "Back"]
    m.passwordDialog.observeField("buttonSelected", "onLoginPasswordSelected")
    m.passwordDialog.observeField("wasClosed", "onLoginDialogClosed")
    
    m.top.GetScene().dialog = m.passwordDialog
    m.top.GetScene().dialog.setFocus(true)
end sub

sub onSignupPasswordSelected()
    buttonIndex = m.passwordDialog.buttonSelected
    
    if buttonIndex = 0 and m.passwordDialog.text.Len() > 0
        ' Create Account button
        m.signupPassword = m.passwordDialog.text
        m.passwordDialog.close = true
        processSignup()
    else if buttonIndex = 1
        ' Show Password
        m.passwordDialog.keyboard.textEditBox.secureMode = false
    else if buttonIndex = 2
        ' Hide Password
        m.passwordDialog.keyboard.textEditBox.secureMode = true
    else if buttonIndex = 3
        ' Back button
        m.passwordDialog.close = true
        showSignupFlow()
    else
        ' Invalid input
        m.passwordDialog.keyboard.textEditBox.hintText = "Please enter a valid password"
    end if
end sub

sub onLoginPasswordSelected()
    buttonIndex = m.passwordDialog.buttonSelected
    
    if buttonIndex = 0 and m.passwordDialog.text.Len() > 0
        ' Login button
        m.loginPassword = m.passwordDialog.text
        m.passwordDialog.close = true
        processLogin()
    else if buttonIndex = 1
        ' Show Password
        m.passwordDialog.keyboard.textEditBox.secureMode = false
    else if buttonIndex = 2
        ' Hide Password
        m.passwordDialog.keyboard.textEditBox.secureMode = true
    else if buttonIndex = 3
        ' Back button
        m.passwordDialog.close = true
        showLoginFlow()
    else
        ' Invalid input
        m.passwordDialog.keyboard.textEditBox.hintText = "Please enter a valid password"
    end if
end sub

sub processSignup()
    print "AccountScreen.brs - [processSignup] Processing signup for: " + m.signupUsername
    
    ' Show progress dialog
    m.progressDialog = CreateObject("roSGNode", "ProgressDialog")
    m.progressDialog.title = "Creating Account..."
    m.top.GetScene().dialog = m.progressDialog
    
    ' Simulate signup process (replace with actual API call)
    ' For now, just show success message
    m.progressDialog.close = true
    showSignupSuccess()
end sub

sub processLogin()
    print "AccountScreen.brs - [processLogin] Processing login for: " + m.loginUsername
    
    ' Show progress dialog
    m.progressDialog = CreateObject("roSGNode", "ProgressDialog")
    m.progressDialog.title = "Logging in..."
    m.top.GetScene().dialog = m.progressDialog
    
    ' Create and configure LoginScreenApi
    if m.loginApi <> invalid
        m.loginApi.unobserveField("responseData")
        m.loginApi = invalid
    end if
    
    m.loginApi = CreateObject("roSGNode", "LoginScreenApi")
    m.loginApi.email = m.loginUsername
    m.loginApi.password = m.loginPassword
    m.loginApi.observeField("responseData", "onLoginResponse")
    
    print "AccountScreen.brs - [processLogin] Starting login API call..."
    m.loginApi.control = "RUN"
end sub

sub onLoginResponse()
    print "AccountScreen.brs - [onLoginResponse] Login API response received"
    
    ' Close progress dialog
    if m.progressDialog <> invalid
        m.progressDialog.close = true
    end if
    
    if m.loginApi <> invalid
        response = m.loginApi.responseData
        print "AccountScreen.brs - [onLoginResponse] Response: " + response
        
        if response = "Success"
            print "AccountScreen.brs - [onLoginResponse] Login successful!"
            ' Update account status
            m.top.accountStatus = true
            
            ' Show success message first, then reload app
            showLoginSuccessAndReload()
        else if response = "405"
            print "AccountScreen.brs - [onLoginResponse] Login failed - method not allowed"
            showLoginError("Login failed. Please try again later.")
        else
            print "AccountScreen.brs - [onLoginResponse] Login failed - " + response
            showLoginError("Invalid email or password. Please try again.")
        end if
    end if
end sub

sub showLoginSuccessAndReload()
    print "AccountScreen.brs - [showLoginSuccessAndReload] Showing success and preparing to reload app"
    
    m.reloadDialog = CreateObject("roSGNode", "BackDialog")
    m.reloadDialog.title = "Login Successful!"
    m.reloadDialog.message = "Welcome back! The app will now reload to apply your account settings."
    m.reloadDialog.buttons = ["OK"]
    m.reloadDialog.observeField("buttonSelected", "onReloadDialogSelected")
    
    m.top.GetScene().dialog = m.reloadDialog
    m.top.GetScene().dialog.setFocus(true)
end sub

sub onReloadDialogSelected()
    print "AccountScreen.brs - [onReloadDialogSelected] User confirmed, reloading app..."
    m.reloadDialog.close = true
    
    ' Trigger app reload
    reloadAppWithNewSession()
end sub

sub reloadAppWithNewSession()
    print "AccountScreen.brs - [reloadAppWithNewSession] *** RELOADING APP WITH NEW SESSION ***"
    
    ' Verify user data was saved before reloading
    print "AccountScreen.brs - [reloadAppWithNewSession] Verifying user data in registry before reload..."
    userDataJson = RegRead("userData", "AUTH")
    if userDataJson <> invalid and userDataJson <> ""
        print "AccountScreen.brs - [reloadAppWithNewSession] *** USER DATA VERIFIED IN REGISTRY ***"
        print "AccountScreen.brs - [reloadAppWithNewSession] User data: " + userDataJson
    else
        print "AccountScreen.brs - [reloadAppWithNewSession] WARNING: User data NOT found in registry before reload!"
        print "AccountScreen.brs - [reloadAppWithNewSession] This may cause Account Details to show 'Guest'"
    end if
    
    ' Get the parent scene (HomeScene)
    parentScene = m.top.getScene()
    if parentScene <> invalid
        ' Call the reload function on HomeScene
        print "AccountScreen.brs - [reloadAppWithNewSession] Calling HomeScene reloadAppData()"
        parentScene.callFunc("reloadAppData")
    else
        print "AccountScreen.brs - [reloadAppWithNewSession] ERROR: Could not get parent scene"
    end if
end sub

sub showLoginError(message as string)
    print "AccountScreen.brs - [showLoginError] Showing error: " + message
    
    m.errorDialog = CreateObject("roSGNode", "BackDialog")
    m.errorDialog.title = "Login Failed"
    m.errorDialog.message = message
    m.errorDialog.buttons = ["Try Again", "Cancel"]
    m.errorDialog.observeField("buttonSelected", "onErrorDialogSelected")
    
    m.top.GetScene().dialog = m.errorDialog
    m.top.GetScene().dialog.setFocus(true)
end sub

sub onErrorDialogSelected()
    buttonIndex = m.errorDialog.buttonSelected
    m.errorDialog.close = true
    
    if buttonIndex = 0
        ' Try Again - show login dialog
        showLoginFlow()
    else
        ' Cancel - return to account screen
        returnToAccountScreen()
    end if
end sub

sub showSignupSuccess()
    m.successDialog = CreateObject("roSGNode", "BackDialog")
    m.successDialog.title = "Account Created!"
    m.successDialog.message = "Your account has been created successfully. You can now access all features."
    m.successDialog.buttons = ["OK"]
    m.successDialog.observeField("buttonSelected", "onSuccessDialogSelected")
    
    m.top.GetScene().dialog = m.successDialog
    m.top.GetScene().dialog.setFocus(true)
end sub

sub showLoginSuccess()
    m.successDialog = CreateObject("roSGNode", "BackDialog")
    m.successDialog.title = "Login Successful!"
    m.successDialog.message = "You have been logged in successfully. Welcome back!"
    m.successDialog.buttons = ["OK"]
    m.successDialog.observeField("buttonSelected", "onSuccessDialogSelected")
    
    m.top.GetScene().dialog = m.successDialog
    m.top.GetScene().dialog.setFocus(true)
end sub

sub onSuccessDialogSelected()
    m.successDialog.close = true
    ' Update account status to authenticated
    m.top.accountStatus = true
    returnToAccountScreen()
end sub

sub onSignupDialogClosed()
    returnToAccountScreen()
end sub

sub onLoginDialogClosed()
    returnToAccountScreen()
end sub

sub returnToAccountScreen()
    print "AccountScreen.brs - [returnToAccountScreen] Returning focus to account screen"
    m.top.setFocus(true)
    if m.loginGroup <> invalid
        m.loginGroup.setFocus(true)
    end if
end sub


function activateLogoutButton()
    m.logoutGroup.setFocus(true)
    m.logoutIcon = m.top.findNode("logoutIcon")
    m.logoutIcon.uri = "pkg:/images/png/logout_active.png"
    m.logoutText = m.top.findNode("logoutText")
    m.logoutText.color = "#fe4a65"
end function


function deactivateLogoutButton()
    m.logoutIcon = m.top.findNode("logoutIcon")
    m.logoutIcon.uri = "pkg:/images/png/logout.png"
    m.logoutText = m.top.findNode("logoutText")
    m.logoutText.color = "0xFFFFFF"
end function



function activateLoginButton()
    ' Visual activation only - focus is handled separately
    m.loginIcon = m.top.findNode("loginIcon")
    m.loginIcon.uri = "pkg:/images/png/login_active.png"
    m.loginText = m.top.findNode("loginText")
    m.loginText.color = "#fe4a65"
end function


function deactivateLoginButton()
    m.loginIcon = m.top.findNode("loginIcon")
    m.loginIcon.uri = "pkg:/images/png/login.png"
    m.loginText = m.top.findNode("loginText")
    m.loginText.color = "0xFFFFFF"
end function

' ============================================================================
' USER PROFILE DATA FUNCTIONS
' ============================================================================

sub onUserDataChanged()
    print "AccountScreen.brs - [onUserDataChanged] User data changed"
    userData = m.top.userData
    if userData <> invalid
        print "AccountScreen.brs - [onUserDataChanged] Updating user profile UI"
        populateUserProfile(userData)
    end if
end sub

function refreshUserData() as boolean
    print "AccountScreen.brs - [refreshUserData] =========================================="
    print "AccountScreen.brs - [refreshUserData] *** EXTERNALLY TRIGGERED USER DATA REFRESH ***"
    print "AccountScreen.brs - [refreshUserData] =========================================="
    print "AccountScreen.brs - [refreshUserData] Current accountStatus: " + m.top.accountStatus.ToStr()
    
    ' Load user data from registry
    loadUserDataFromRegistry()
    
    ' Update UI
    refreshAccountUI()
    
    print "AccountScreen.brs - [refreshUserData] Refresh complete"
    return true
end function

sub loadUserDataFromRegistry()
    print "AccountScreen.brs - [loadUserDataFromRegistry] *** LOADING USER DATA FROM REGISTRY ***"
    
    ' Read user data from registry
    userDataJson = RegRead("userData", "AUTH")
    print "AccountScreen.brs - [loadUserDataFromRegistry] Raw userDataJson: " + userDataJson
    
    if userDataJson <> invalid and userDataJson <> ""
        print "AccountScreen.brs - [loadUserDataFromRegistry] User data JSON found, parsing..."
        userData = ParseJson(userDataJson)
        if userData <> invalid
            print "AccountScreen.brs - [loadUserDataFromRegistry] User data parsed successfully:"
            
            ' Safely print each field
            if userData.id <> invalid
                print "AccountScreen.brs - [loadUserDataFromRegistry]   - id: " + userData.id.ToStr()
            else
                print "AccountScreen.brs - [loadUserDataFromRegistry]   - id: (not set)"
            end if
            
            if userData.name <> invalid
                print "AccountScreen.brs - [loadUserDataFromRegistry]   - name: " + userData.name
            else
                print "AccountScreen.brs - [loadUserDataFromRegistry]   - name: (not set)"
            end if
            
            if userData.lastname <> invalid
                print "AccountScreen.brs - [loadUserDataFromRegistry]   - lastname: " + userData.lastname
            else
                print "AccountScreen.brs - [loadUserDataFromRegistry]   - lastname: (not set)"
            end if
            
            if userData.email <> invalid
                print "AccountScreen.brs - [loadUserDataFromRegistry]   - email: " + userData.email
            else
                print "AccountScreen.brs - [loadUserDataFromRegistry]   - email: (not set)"
            end if
            
            if userData.hasPaymentMethod <> invalid
                print "AccountScreen.brs - [loadUserDataFromRegistry]   - hasPaymentMethod: " + userData.hasPaymentMethod.ToStr()
            else
                print "AccountScreen.brs - [loadUserDataFromRegistry]   - hasPaymentMethod: (not set)"
            end if
            
            populateUserProfile(userData)
        else
            print "AccountScreen.brs - [loadUserDataFromRegistry] ERROR: Failed to parse user data JSON"
        end if
    else
        print "AccountScreen.brs - [loadUserDataFromRegistry] No user data found in registry (userData key is empty or invalid)"
        
        ' Also check if auth data exists to understand the state
        authDataJson = RegRead("authData", "AUTH")
        if authDataJson <> invalid and authDataJson <> ""
            print "AccountScreen.brs - [loadUserDataFromRegistry] Auth data exists but user data doesn't - user data may not have been saved during login"
        else
            print "AccountScreen.brs - [loadUserDataFromRegistry] No auth data either - user is not logged in"
        end if
    end if
end sub

sub populateUserProfile(userData as object)
    print "AccountScreen.brs - [populateUserProfile] Populating user profile UI"
    
    if userData = invalid
        print "AccountScreen.brs - [populateUserProfile] User data is invalid, skipping"
        return
    end if
    
    ' Get user info with fallbacks
    userName = ""
    userLastname = ""
    userEmail = ""
    hasPayment = false
    userId = 0
    
    if userData.name <> invalid
        userName = userData.name
    end if
    
    if userData.lastname <> invalid
        userLastname = userData.lastname
    end if
    
    if userData.email <> invalid
        userEmail = userData.email
    end if
    
    if userData.hasPaymentMethod <> invalid
        hasPayment = userData.hasPaymentMethod
    end if
    
    if userData.id <> invalid
        userId = userData.id
    end if
    
    ' Build full name
    fullName = userName
    if userLastname <> ""
        if fullName <> ""
            fullName = fullName + " " + userLastname
        else
            fullName = userLastname
        end if
    end if
    
    ' Get initials for avatar
    initials = ""
    if userName <> ""
        initials = Left(userName, 1).Upper()
    end if
    if userLastname <> ""
        initials = initials + Left(userLastname, 1).Upper()
    end if
    if initials = ""
        initials = "U"
    end if
    
    print "AccountScreen.brs - [populateUserProfile] Name: " + fullName
    print "AccountScreen.brs - [populateUserProfile] Email: " + userEmail
    print "AccountScreen.brs - [populateUserProfile] Has Payment: " + hasPayment.ToStr()
    print "AccountScreen.brs - [populateUserProfile] User ID: " + userId.ToStr()
    print "AccountScreen.brs - [populateUserProfile] Initials: " + initials
    
    ' Update UI elements
    if m.avatarInitials <> invalid
        m.avatarInitials.text = initials
    end if
    
    if m.profileFullName <> invalid
        if fullName <> ""
            m.profileFullName.text = fullName
        else
            m.profileFullName.text = "User"
        end if
    end if
    
    if m.emailValue <> invalid
        if userEmail <> ""
            m.emailValue.text = userEmail
        else
            m.emailValue.text = "Not available"
        end if
    end if
    
    if m.nameValue <> invalid
        if fullName <> ""
            m.nameValue.text = fullName
        else
            m.nameValue.text = "Not available"
        end if
    end if
    
    if m.subscriptionValue <> invalid
        if hasPayment = true
            m.subscriptionValue.text = "Active"
            m.subscriptionValue.color = "#4CAF50"  ' Green
        else
            m.subscriptionValue.text = "Not Set Up"
            m.subscriptionValue.color = "#FF6B6B"  ' Red
        end if
    end if
    
    if m.userIdValue <> invalid
        if userId <> 0
            m.userIdValue.text = "#" + userId.ToStr()
        else
            m.userIdValue.text = "N/A"
        end if
    end if
    
    print "AccountScreen.brs - [populateUserProfile] User profile UI updated"
end sub

sub clearUserProfile()
    print "AccountScreen.brs - [clearUserProfile] Clearing user profile UI"
    
    if m.avatarInitials <> invalid
        m.avatarInitials.text = "?"
    end if
    
    if m.profileFullName <> invalid
        m.profileFullName.text = "Guest"
    end if
    
    if m.emailValue <> invalid
        m.emailValue.text = "Not logged in"
    end if
    
    if m.nameValue <> invalid
        m.nameValue.text = "Not logged in"
    end if
    
    if m.subscriptionValue <> invalid
        m.subscriptionValue.text = "N/A"
        m.subscriptionValue.color = "#888888"
    end if
    
    if m.userIdValue <> invalid
        m.userIdValue.text = "N/A"
    end if
    
    if m.userProfileSection <> invalid
        m.userProfileSection.visible = false
    end if
end sub
