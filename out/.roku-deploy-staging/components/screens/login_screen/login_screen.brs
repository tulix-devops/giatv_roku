function init()
    m.top.visible = false
    m.spinLoader = false
    m.progressdialog = createObject("roSGNode", "ProgressDialog")
    m.emailBox = m.top.FindNode("emailBox")
    m.passwordBox = m.top.FindNode("passwordBox")

    m.top.observeField("visible", "visibilityUpdated")

    m.keyboard = m.top.findNode("loginKeyboard")
    m.keyboard.observeField("text", "updateTextBox")

    m.keyboard.domain = "email"
    m.keyboard.textEditBox.visible = false
    m.keyboard.textEditBox.voiceEnabled = true

    m.emailBoxIsActive = true

    m.top.observeField("focusedChild", "handleFocus")
    m.rowList = m.top.findNode("searchList")

    m.nextButton = m.top.findNode("nextButton")
    m.nextButtonText = m.top.findNode("nextLabel")
    m.nextButtonShape = m.top.findNode("nextButtonShape")

    m.cancelButton = m.top.findNode("cancelButton")
    m.cancelButtonText = m.top.findNode("cancelLabel")
    m.cancelButtonShape = m.top.findNode("cancelButtonShape")

    m.emailBoxError = m.top.findNode("emailBoxError")
    m.passwordBoxError = m.top.findNode("passwordBoxError")

    m.activateKeyboard = m.top.findNode("activateKeyboard")
    m.deactivateKeyboard = m.top.findNode("deactivateKeyboard")

    ' CHECK BUTTON
    m.checkButton = m.top.findNode("checkButton")
    m.checkButtonText = m.top.findNode("checkLabel")
    m.checkButtonShape = m.top.findNode("checkButtonShape")

    m.cancelSubButton = m.top.findNode("cancelSubButton")
    m.cancelSubButtonLabel = m.top.findNode("cancelSubButtonLabel")
    m.cancelSubButtonShape = m.top.findNode("cancelSubButtonShape")

    m.mustNotBeEmpty = "Cannot be empty"
    m.incorrectEmail = "Incorrect Email format"
    m.incorrectPassword = "Incorrect Password"

    m.confirmText = "Confirm"
    m.BackText = "Previous"

end function

sub visibilityUpdated()
    ' if m.top.visible = false
    ' else
    '     print "we got here"
    '     m.top.setFocus(true)
    '     m.keyboard.setFocus(true)
    '     print m.keyboard.hasFocus()
    '     print "DOKEYBOARDHAVE FOCUS NOW"
    ' end if
end sub

sub updateTextBox()
    if m.emailBoxIsActive = true then
        m.emailBox.text = m.keyboard.text
        m.emailBox.cursorPosition = Len(m.emailBox.text)

        if Len(m.emailBox.text) > 0 then
            m.emailBoxError.visible = false
        end if
    end if

    if m.emailBoxIsActive = false then
        m.passwordBox.text = m.keyboard.text
        m.passwordBox.cursorPosition = Len(m.passwordBox.text)

        if Len(m.passwordBox.text) > 0 then
            m.passwordBoxError.visible = false
        end if
    end if
end sub

sub updatepasswordBox()
    m.emailBox.text = m.keyboard.text
end sub

sub handleFocus(event as object)
    print "Handle Focus Activated"
    field = event.getRoSGNode()
    m.authData = RetrieveAuthData()
    if m.authData <> invalid then
        if m.authData.subscribed = 1
            ' initializeSubscribePage()
        else
            ' initializeSubscribePage()
            print "not subsrcibed"
        end if
    else
        if m.top.hasFocus() then
            m.keyboard.visible = true
            m.keyboard.setFocus(true)
            m.keyboard.focusable = true
            activateKeyboard()
        end if
    end if
end sub

sub activateKeyboard()
    m.activateKeyboard.control = "start"
end sub

sub deactivateKeyboard()
    m.deactivateKeyboard.control = "start"
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    print "Key: " key
    print "Press: " press

    loginScreen = m.top.findNode("login_screen")
    emailBox = m.top.findNode("emailBox")

    print "Top has focus: " m.top.hasFocus()
    print "Does loginScreen have focus? " loginScreen.hasFocus()
    print "Email Box has focus: " emailBox.hasFocus()
    print "Keyboard has focus: " m.keyboard.hasFocus()
    print "Keyboard is focusable: " m.keyboard.focusable
    print "Keyboard Focused Child" m.keyboard.focusedChild

    if press = false and key = "back"
        if m.top.hasFocus() then
            return true
        end if
        return true
    end if

    if press = false and key <> invalid
        print "Activating play button right?"
        if m.top.hasFocus()
            print "Keyboard has focus after setFocus: " m.keyboard.hasFocus()
            return true
        else if key = "OK"
            ' Additional OK key handling if necessary
        end if
    else if key = "right" and press = true
        if m.nextButton.hasFocus() then
            deactivateNextButton()
            activateCancelButton()
            return true
        else if m.cancelButton.hasFocus() then
            deactivateCancelButton()
            activateNextButton()
            return true
        else if m.checkButton.hasFocus() then
            deactivateCheckButton()
            activateCancelSubButton()
        else if m.cancelSubButton.hasFocus() then
            deactivateCancelSubButton()
            activateCheckButton()
        end if
    else if key = "down" and press = true
        if m.nextButton.hasFocus() then
            m.keyboard.focusable = true
            m.keyboard.setFocus(true)
            deactivateNextButton()
            return true
        else if m.cancelButton.hasFocus() then
            m.keyboard.focusable = true
            m.keyboard.setFocus(true)
            deactivateCancelButton()
            return true
        end if
    else if key = "up" and press = true
        print "Checking loginKeyboard focus state"
        if m.keyboard.focusable = true then
            m.keyboard.focusable = false
            m.keyboard.setFocus(false)
            activateNextButton()
            return true
        end if
    else if key = "left" and press = true
        if m.nextButton.hasFocus() then
            deactivateNextButton()
            activateCancelButton()
            return true
        else if m.cancelButton.hasFocus() then
            deactivateCancelButton()
            activateNextButton()
            return true
        else if m.checkButton.hasFocus() then
            deactivateCheckButton()
            activateCancelSubButton()
        else if m.cancelSubButton.hasFocus() then
            deactivateCancelSubButton()
            activateCheckButton()
        end if
    else if key = "back" and press = true then
        resetActions()
        deactivateNextButton()
        deactivateCancelButton()
        deactivateCancelSubButton()
        deactivateCheckButton()
        if m.top.isNavigatedFromAccountTab = true then
            accountScreen = m.global.findNode("account_screen")
            accountScreen.visible = true
            m.global.findNode("navigation_bar").visible = true
            m.global.findNode("navigation_bar").setFocus(true)
        else
        end if
        m.top.visible = false
        return true
    else if key = "OK" and press = true then
        if m.nextButton.hasFocus() then
            if m.emailBoxIsActive = false then
                onConfirmPressed()
            else if m.emailBoxIsActive = true then
                onNextPressed()
            end if
            return true
        else if m.cancelButton.hasFocus() then
            if m.emailBoxIsActive = false then
                activateEmailBox()
                moveToFirstStep()
                return true
            else if m.emailBoxIsActive = true then
                resetActions()
                deactivateNextButton()
                deactivateCancelButton()
                if m.top.isNavigatedFromAccountTab = true then
                    accountScreen = m.global.findNode("account_screen")
                    accountScreen.visible = true
                    m.global.findNode("navigation_bar").visible = true
                    m.global.findNode("navigation_bar").setFocus(true)
                else
                    m.global.findNode("navigation_bar").visible = true
                    homeScreen = m.global.findNode("home_screen")
                    homeScreen.visible = true
                    m.global.findNode("navigation_bar").setFocus(true)
                end if
                m.top.visible = false
                return true
            end if
        else if m.cancelSubButton.hasFocus() then
            resetActions()
            deactivateNextButton()
            deactivateCancelButton()
            deactivateCancelSubButton()
            deactivateCheckButton()
            if m.top.isNavigatedFromAccountTab = true then
                accountScreen = m.global.findNode("account_screen")
                accountScreen.visible = true
                m.global.findNode("navigation_bar").visible = true
                m.global.findNode("navigation_bar").setFocus(true)
            else
                m.global.findNode("navigation_bar").visible = true
                m.global.findNode("navigation_bar").setFocus(true)
                homeScreen = m.global.findNode("home_screen")
                homeScreen.visible = true
            end if
            m.top.visible = false
            return true
        else if m.checkButton.hasFocus() then
            initializeProfileCheck()
        end if
    end if

    return false
end function

sub initializeProfileCheck()
    fetchProfileInfo()
    m.updatedAuthData = RetrieveAuthData()
    if m.updatedAuthData <> invalid
        statusLabel = m.top.findNode("checkStatus")
        if m.updatedAuthData.subscribed = 1
            print "Subscribed"
            statusLabel.visible = true
            statusLabel.text = "You are now subscribed to channel!"
            statusLabel.color = "#00FF00"
        else
            print "No sub"
            statusLabel.visible = true
            statusLabel.text = "Subscription not arrived yet"
            statusLabel.color = "#FF0000"
        end if
    end if
end sub

sub fetchProfileInfo()
    m.authData = RetrieveAuthData()
    if m.authData <> invalid then
        showLoadingDialog("Loading")
        m.ProfileData = createObject("roSGNode", "ProfileApi")
        m.ProfileData.observeField("responseData", "handleProfileData")
        m.ProfileData.authToken = m.authData.accessToken
    end if
end sub

sub handleProfileData()
    TopDialogClose()
    data = m.ProfileData.responseData
    print data
    print "Printing Data Before Execution"
    if data = "Error"
    else
        subscribed = ParseJson(data).data.subscribed
        print "Hello Auth Data Im here"
        print m.authData.accessToken
        print "Auth Token Please."
        UpdateAuthData(m.authData.accessToken, subscribed, true, m.authData.expiry)
    end if
end sub

function UpdateAuthData(accessToken as string, subscribed as boolean, isauth as boolean, expiry as integer)
    section = "AUTH"
    sec = CreateObject("roRegistrySection", section)

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
        isauth: isAuthValue
    }
    jsonData = FormatJson(data)
    sec.Write("authData", jsonData)
    sec.Flush()
end function

function resetActions()
    moveToFirstStep()
    m.emailBoxIsActive = true
    m.emailBox.active = true
    m.keyboard.text = ""
    m.passwordBox.text = ""
    m.emailBox.text = ""
    m.passwordBoxError.visible = false
    m.emailBoxError.visible = false

    ' m.top.findNode("subscribePage").visible = false
    m.top.findNode("loginPage").visible = true
    m.top.findNode("keyboardGroup").visible = true
end function

function activatePasswordBox()
    m.emailBoxIsActive = false
    m.emailBox.active = false
    m.passwordBox.active = true
    m.keyboard.text = ""
    m.passwordBox.cursorPosition = Len(m.passwordBox.text)
end function

function activateEmailBox()
    m.emailBoxIsActive = true
    m.emailBox.active = true
    m.passwordBox.active = false
    m.keyboard.text = ""
    m.emailBox.cursorPosition = Len(m.emailBox.text)
end function

function moveToFirstStep()
    m.nextButtonText.translation = [120, 30]
    m.cancelButtonText.translation = [100, 30]
    m.nextButtonText.text = "Next"
    m.cancelButtonText.text = "Cancel"
end function

function moveToSecondStep()
    m.nextButtonText.translation = [90, 30]
    m.cancelButtonText.translation = [85, 30]
    m.nextButtonText.text = m.confirmText
    m.cancelButtonText.text = m.BackText
end function

function onNextPressed()
    if Len(m.emailBox.text) = 0 then
        m.emailBoxError.visible = true
        m.emailBoxError.text = m.mustNotBeEmpty
    else if Len(m.emailBox.text) > 0 then
        if isValidEmail(m.emailBox.text) = true then
            m.emailBoxError.visible = false
            moveToSecondStep()
            activatePasswordBox()
        else
            m.emailBoxError.visible = true
            m.emailBoxError.text = m.incorrectEmail
        end if
    end if
end function

function onConfirmPressed()
    if Len(m.passwordBox.text) = 0 then
        m.passwordBoxError.visible = true
        m.passwordBoxError.text = m.mustNotBeEmpty
    else if Len(m.emailBox.text) > 0 then
        initiateLogin()
    end if
end function

sub initiateLogin()
    m.loginData = createObject("roSGNode", "LoginScreenApi")
    m.loginData.observeField("responseData", "handleResponseData")
    m.loginData.email = m.emailBox.text
    m.loginData.password = m.passwordBox.text
    showLoadingDialog("Loading")
    m.loginData.control = "RUN"
end sub

sub handleResponseData()
    data = m.loginData.responseData
    if data = "Success"
        if m.top.isNavigatedFromAccountTab = true then
            resetActions()
            deactivateNextButton()
            deactivateCancelButton()
            deactivateCancelSubButton()
            deactivateCheckButton()
            m.top.visible = false
            accountScreen = m.global.findNode("account_screen")
            accountScreen.accountStatus = true
            accountScreen.visible = true
            m.global.findNode("navigation_bar").visible = true
            m.global.findNode("navigation_bar").setFocus(true)
            TopDialogClose()
        else
            resetActions()
            deactivateNextButton()
            deactivateCancelButton()
            deactivateCancelSubButton()
            deactivateCheckButton()
            m.top.visible = false
            accountScreen = m.global.findNode("account_screen")
            accountScreen.accountStatus = true
            TopDialogClose()
            m.global.findNode("home_screen").visible = true
            m.global.findNode("navigation_bar").visible = true
            m.global.findNode("navigation_bar").setFocus(true)
        end if
    else if data = "405"
        m.emailBoxError.text = "Incorrect credentials"
        m.emailBoxError.visible = true
        TopDialogClose()
    else
        m.emailBoxError.text = "Error Occured"
        m.emailBoxError.visible = true
        TopDialogClose()
    end if
    
end sub

sub checkIfSubscribed()
    authData = RetrieveAuthData()
    print authData
    if authData.subscribed = 1
        print "Subscribed"
        resetActions()
        deactivateNextButton()
        deactivateCancelButton()
        deactivateCancelSubButton()
        deactivateCheckButton()
        detailScreen = m.global.findNode("detailScene")
        detailScreen.visible = true
        m.top.visible = false
        detailScreen.setFocus(true)
    else
        resetActions()
        deactivateNextButton()
        deactivateCancelButton()
        deactivateCancelSubButton()
        deactivateCheckButton()
        detailScreen = m.global.findNode("detailScene")
        detailScreen.visible = true
        m.top.visible = false
        detailScreen.setFocus(true)
        print "not subsrcibed"
    end if
    print "AutHData"
end sub

sub initializeSubscribePage()
    m.top.findNode("subscribePage").visible = true
    m.top.findNode("loginPage").visible = false
    m.top.findNode("keyboardGroup").visible = false

    activateCheckButton()
end sub

function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)

    if jsonData <> invalid and jsonData <> ""
        data = ParseJson(jsonData)
        currentTime = CreateObject("roDateTime").asSeconds()

        if currentTime <= data.expiry
            return data
        else
            return invalid
        end if
    else
        return invalid
    end if
end function

function isValidEmail(email as string) as boolean
    atSymbolFound = false
    dotAfterAtFound = false
    atIndex = -1
    dotIndex = -1
    emailLength = len(email)

    for i = 0 to emailLength - 1
        c = mid(email, i, 1)
        if c = "@"
            if atSymbolFound
                return false
            else
                atSymbolFound = true
                atIndex = i
            end if
        end if

        if c = "."
            if atSymbolFound and i > atIndex + 1
                dotAfterAtFound = true
                dotIndex = i
            end if
        end if
    end for

    if atSymbolFound and atIndex > 0 and dotAfterAtFound and dotIndex < emailLength - 1
        return true
    else
        return false
    end if
end function

function activateNextButton()
    m.nextButton.setFocus(true)
    m.nextButtonText = m.top.findNode("nextLabel")
    m.nextButtonShape = m.top.findNode("nextButtonShape")
    m.nextButtonShape.uri = "pkg:/images/png/shapes/active_rounded.png"
    m.nextButtonText.color = "#000000"
end function

function deactivateNextButton()
    m.nextButtonText = m.top.findNode("nextLabel")
    m.nextButtonShape = m.top.findNode("nextButtonShape")
    m.nextButtonShape.uri = "pkg:/images/png/shapes/pink_rounded.png"
    m.nextButtonText.color = "0xFFFFFF"
end function

function activateCancelButton()
    m.cancelButton.setFocus(true)
    m.cancelButtonText = m.top.findNode("cancelLabel")
    m.cancelButtonShape = m.top.findNode("cancelButtonShape")
    m.cancelButtonShape.uri = "pkg:/images/png/shapes/active_rounded.png"
    m.cancelButtonText.color = "#000000"
end function

function deactivateCancelButton()
    m.cancelButtonText = m.top.findNode("cancelLabel")
    m.cancelButtonShape = m.top.findNode("cancelButtonShape")
    m.cancelButtonShape.uri = "pkg:/images/png/shapes/grey_rounded.png"
    m.cancelButtonText.color = "0xFFFFFF"
end function

' SUBSCRIBE PAGE BUTTONS
function activateCheckButton()
    m.checkButton.setFocus(true)
    m.checkButtonShape.uri = "pkg:/images/png/shapes/active_rounded.png"
    m.checkButtonText.color = "#000000"
end function

function deactivateCheckButton()
    ' m.checkButtonShape.uri = "pkg:/images/png/shapes/pink_rounded.png"
    ' m.checkButtonText.color = "0xFFFFFF"
end function

function activateCancelSubButton()
    m.cancelSubButton.setFocus(true)
    m.cancelSubButtonShape.uri = "pkg:/images/png/shapes/active_rounded.png"
    m.cancelSubButtonLabel.color = "#000000"
end function

function deactivateCancelSubButton()
    ' m.cancelSubButtonShape.uri = "pkg:/images/png/shapes/grey_rounded.png"
    ' m.cancelSubButtonLabel.color = "0xFFFFFF"
end function

function getFocusedChildIndex(container as object) as integer
    for i = 0 to container.getChildCount() - 1
        if container.getChild(i).hasFocus()
            return i
        end if
    end for
    return -1
end function

function RegWrite(key, val, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
    sec.Flush()
end function

function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    return sec.Read(key)
end function

function RegDelete(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    sec.Flush()
end function

sub showLoadingDialog(textToShow as string)
    m.progressdialog.busySpinner.uri = "pkg:/images/png/loader.png"
    m.progressdialog.backgroundUri = "pkg:/images/png/shapes/final_transparent_mask.png"
    m.progressdialog.width = 500

    if m.top.visible = true
        m.top.GetScene().dialog = m.progressdialog
    end if
end sub

sub handleLiveChannelsUpdate()
end sub

sub TopDialogClose()
    if m.top.GetScene().dialog <> invalid then
        m.top.GetScene().dialog.close = true
    end if
end sub



