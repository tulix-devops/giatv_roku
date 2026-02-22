sub init()
    m.top.observeField("detailScreenData", "detailsScreenDataChanged")
    m.top.visible = false
    m.top.observeField("visible", "visibilityUpdated")
    m.top.relatedDataEntity = m.top.findNode("relatedDataEntity")
    m.progressdialog = createObject("roSGNode", "ProgressDialog")

    m.top.observeField("relatedDataEntity", "relatedDataUpdated")

    m.playButtonGroup = m.top.findNode("playButtonGroup")
    m.trailerGroup = m.top.findNode("trailerGroup")
    m.moreLikeThisGroup = m.top.findNode("moreLikeThisGroup")
    m.episodesGroup = m.top.findNode("episodesGroup")

    m.playButtonIcon = m.top.findNode("playButtonIcon")
    m.playButtonText = m.top.findNode("playButtonText")

    m.moreLikeThisButtonIcon = m.top.findNode("moreLikeThisButtonIcon")
    m.moreLikeThisButtonText = m.top.findNode("moreLikeThisButtonText")

    m.watchTrailerButtonIcon = m.top.findNode("watchTrailerButtonIcon")
    m.trailerButtonText = m.top.findNode("trailerButtonText")




    m.episodesButtonIcon = m.top.findNode("episodesButtonIcon")
    m.episodesButtonText = m.top.findNode("episodesButtonText")

    m.rowList = m.top.findNode("relatedList")


    m.episodesList = m.top.findNode("episodesList")

    m.relatedID = "0"

    m.spinner = m.top.findNode("spinner")

    m.activateDetailsPage = m.top.findNode("activateDetailsPage")

    m.deactivateDetailsPage = m.top.findNode("deactivateDetailsPage")

    m.deactivateDetailsPage.observeField("state", "deactivationStateChanged")

    m.firstEntryScreenData = m.top.detailScreenData
    m.isFirstEntryData = true


    m.relatedContainer = m.top.findNode("relatedContainer")
    m.relatedContainer.visible = false
    m.episodesContainer = m.top.findNode("episodesContainer")

    m.isTVSHOW = false



    m.dialogErrFailedToFetchSubscriptions = CreateObject("roSGNode", "BackDialog")
    m.dialogErrFailedToFetchSubscriptions.title = "Server error"
    m.dialogErrFailedToFetchSubscriptions.message = "Failed to fetch Subscriptions from Roku Store, please try again!"
    m.dialogErrFailedToFetchSubscriptions.buttons = ["OK"]
    m.dialogErrFailedToFetchSubscriptions.ObserveField("buttonSelected", "TopDialogClose")


    m.dialogPurchaseableProducts = CreateObject("roSGNode", "BackDialog")
    m.dialogPurchaseableProducts.title = "Purchase Subscription"
    m.dialogPurchaseableProducts.message = "Please select subscription type"
    m.dialogPurchaseableProducts.ObserveField("buttonSelected", "On_dialogPurchaseProducts_buttonSelected")



    m.dialogErrPurchanseSubscriptionFailed = CreateObject("roSGNode", "BackDialog")
    m.dialogErrPurchanseSubscriptionFailed.title = "Server Error"
    m.dialogErrPurchanseSubscriptionFailed.message = "Failed to complete purchase, please try again"
    m.dialogErrPurchanseSubscriptionFailed.buttons = ["OK"]
    m.dialogErrPurchanseSubscriptionFailed.ObserveField("buttonSelected", "TopDialogClose")




    m.purchaseSubscriptionSuccess = CreateObject("roSGNode", "BackDialog")
    m.purchaseSubscriptionSuccess.title = "Success"
    m.purchaseSubscriptionSuccess.message = "Enjoy your Subscription!"
    m.purchaseSubscriptionSuccess.buttons = ["OK"]
    m.purchaseSubscriptionSuccess.ObserveField("buttonSelected", "TopDialogClose")



    m.availForPurchase = []


    m.rokuUserPurchaseId = ""
    m.accessToken = ""


    ' AUTHORIZATION DIALOG ELEMENTS


    m.authorizationDialog = CreateObject("roSGNode", "BackDialog")
    m.authorizationDialog.title = "Login or Signup"
    m.authorizationDialog.ObserveField("buttonSelected", "onAuthorizationDialogSelected")



    m.password = ""
    m.repeatPassword = ""




    m.keyboard = CreateObject("roSGNode", "KeyboardDialog")
    m.keyboard.observeField("input", "onPasswordInputChanged")
    m.keyboard.observeField("keyEvent", "onKeyEvent")
    m.keyboard.ObserveField("buttonSelected", "passwordButtonSelected")
    m.keyboard.title = "Enter your password"
    m.keyboard.hintText = "Password"
    m.keyboard.showText = true
    m.keyboard.maxLength = 32
    m.keyboard.message = ""
    m.keyboard.messageColor = "#FF0000"
    m.passwordDialog = CreateObject("roSGNode", "Dialog")



    m.repeatKeyboard = CreateObject("roSGNode", "KeyboardDialog")
    m.repeatKeyboard.title = "Repeat your password"
    m.repeatKeyboard.ObserveField("buttonSelected", "repeatKeyboardButtonSelected")
    m.repeatKeyboard.hintText = "Password"
    m.repeatKeyboard.showText = true
    m.repeatKeyboard.maxLength = 32
    m.repeatKeyboard.message = ""
    m.repeatKeyboard.messageColor = "#FF0000"

    m.repeatPasswordDialog = CreateObject("roSGNode", "Dialog")




    m.apiResponseErrorDialog = CreateObject("roSGNode", "BackDialog")
    m.apiResponseErrorDialog.title = "Error Occured"
    m.apiResponseErrorDialog.ObserveField("buttonSelected", "TopDialogClose")




end sub

function showApiResponseErrorDialog(errorMessage as string)
    arrayButtons = []
    arrayButtons.Push("Okay")

    m.apiResponseErrorDialog.buttons = arrayButtons
    m.apiResponseErrorDialog.title = errorMessage
    m.top.GetScene().dialog = m.apiResponseErrorDialog
    m.dialog.setFocus(true)
end function

function passwordButtonSelected()
    if m.keyboard.buttonSelected = 0 then
        password = m.keyboard.text
        hasUpperCase = false

        ' Check if password has at least one uppercase character
        for i = 1 to len(password)
            char = mid(password, i, 1)
            if char >= "A" and char <= "Z" then
                hasUpperCase = true
                exit for
            end if
        end for

        if len(password) > 7 and hasUpperCase then
            print password
            print "Here is keyboardText"
            TopDialogClose()
            ShowRepeatPasswordDialog()
        else
            if len(password) <= 7 then
                m.keyboard.message = "Password length must be at least 8 characters"
            else if not hasUpperCase then
                m.keyboard.message = "Password must contain at least one uppercase letter"
            end if
        end if
    else
        m.keyboard.text = ""
        m.keyboard.message = ""
        TopDialogClose()
    end if
end function

function repeatKeyboardButtonSelected()
    if m.repeatKeyboard.buttonSelected = 0 then
        if len(m.repeatKeyboard.text) > 7 then
            if m.repeatKeyboard.text = m.keyboard.text then
                TopDialogClose()
                initiateSignUp()
            else
                m.repeatKeyboard.message = "Passwords doesn't match"
            end if
            ' TopDialogClose()
            ' ShowRepeatPasswordDialog()
        else
            m.repeatKeyboard.message = "Password length must be at least 8 characters"
        end if
    else

        ' print m.billing.partialUserData.email
        ' print "Hello This is Billing Email"
        m.keyboard.text = ""
        m.keyboard.message = ""
        m.repeatKeyboard.message = ""
        m.repeatKeyboard.text = ""
        TopDialogClose()
    end if


end function


function handleSignUpData()
    data = m.signUpApi.responseData
    if data = "Success"
        initiateLogin()
    else
        showApiResponseErrorDialog("Error Occured During Sign Up")
    end if
    TopDialogClose()
end function



sub initiateLogin()
    m.loginData = createObject("roSGNode", "LoginScreenApi")
    m.loginData.observeField("responseData", "handleLoginData")
    ' REMOVE TESTER EMAIL
    ' m.loginData.email = "test3@test.com"
    m.loginData.email = m.billing.partialUserData.email
    m.loginData.password = m.keyboard.text
    showLoadingDialog("Loading")
    m.loginData.control = "RUN"

end sub

sub handleLoginData()
    data = m.loginData.responseData
    if data = "Success"

    else if data = "405"
        showApiResponseErrorDialog("Incorrect credentials")
    else
        showApiResponseErrorDialog("Error Occured")
    end if
    TopDialogClose()
end sub


sub initiateSignUp()
    m.signUpApi = createObject("roSGNode", "SignUpApi")
    m.signUpApi.observeField("responseData", "handleSignUpData")
    m.signUpApi.email = "t"
    m.signUpApi.password = m.keyboard.text
    m.signUpApi.repeatPassword = m.repeatKeyboard.text
    showLoadingDialog("Loading")
    m.signUpApi.control = "RUN"
end sub

function ShowPasswordDialog()
    arrayButtons = []
    arrayButtons.Push("Next")
    arrayButtons.Push("Cancel")

    m.keyboard.buttons = arrayButtons
    m.passwordDialog.appendChild(m.keyboard)
    m.passwordDialog.appendChild(arrayButtons)

    m.top.GetScene().dialog = m.passwordDialog
    m.keyboard.setFocus(true)

end function


function ShowRepeatPasswordDialog()
    arrayButtons = []
    arrayButtons.Push("Next")
    arrayButtons.Push("Cancel")
    m.repeatPasswordDialog.buttons = arrayButtons

    m.repeatKeyboard.buttons = arrayButtons
    m.repeatPasswordDialog.appendChild(m.repeatKeyboard)
    m.repeatPasswordDialog.appendChild(arrayButtons)

    m.top.GetScene().dialog = m.repeatPasswordDialog
    m.repeatKeyboard.setFocus(true)

end function

sub onAuthorizationDialogSelected()
    if m.authorizationDialog.buttonSelected = 0 then
        TopDialogClose()
        initiateSignUpProcess()
    else if m.authorizationDialog.buttonSelected = 1 then
        TopDialogClose()
        m.relatedContainer.visible = false
        m.deactivateDetailsPage.control = "start"
        m.global.findNode("navigation_bar").visible = false

        m.loginScreen = m.global.findNode("login_screen")
        m.loginScreen.visible = true
        m.loginScreen.isNavigatedFromAccountTab = false
        m.loginScreen.focusable = true
        m.loginScreen.setFocus(true)
    else if m.authorizationDialog.buttonSelected = 2 then
        TopDialogClose()
    end if

end sub


sub initiateSignUpProcess()
    initiateNewUserSignupFlow()
    '    ShowPasswordDialog()
    ' m.billing.partialUserData.email
end sub


sub deactivationStateChanged()
    if m.deactivateDetailsPage.state = "stopped" then
        m.global.findNode("detailScene").visible = false

    end if
end sub

sub detailsScreenDataChanged()
    if m.top.detailScreenData <> invalid
        initiateUpdatedData()
    end if
end sub

sub visibilityUpdated()
    if m.top.visible = false
        ' m.deactivateDetailsPage.control.start
    else if m.top.visible = true
        print "ACTIVATE DETAILS PAGE [ HERE ]"
        m.activateDetailsPage.control = "start"
    end if
end sub


sub initiateUpdatedData()
    if m.top.detailScreenData[0] <> invalid
        ' dEntity = m.top.detailScreenData[0]
        if m.isFirstEntryData = true
            m.firstEntryScreenData = m.top.detailScreenData
        end if


        print m.top.detailScreenData[0]
        m.posterUri = m.top.findNode("posterThumb")
        ' m.posterUri.uri = "https://183.bozztv.com/storage/movies/" + m.top.detailScreenData[0].storageRecord["poster"]
        print "DetailScreenData"

        if m.top.detailScreenData[0].isLiveChannel = true
            activateLiveBasedButtons()
            ' m.posterUri.uri = m.top.detailScreenData[0].data.storage["record"]["thumb"]
            ' m.posterUri.uri = m.top.detailScreenData[0].data.banner
            ' print m.top.detailScreenData[0].data.storage["record"]["thumb"]
            print "Here is Storage"

        else
            activateVodBasedButtons()
            ' m.posterUri.uri = m.top.detailScreenData[0].data.storage["record"]["poster"]
            ' m.posterUri.uri = m.top.detailScreenData[0].data.images["banner"]

        end if

        'TODO TV episodes
        if m.top.detailScreenData[0].data.typeId = 2 then
            m.isTVSHOW = true
            m.episodesGroup.visible = true
            m.episodesContainer.visible = true
            initializeEpisodes()
        else
            m.isTVSHOW = false
            m.episodesGroup.visible = false
            m.episodesContainer.visible = false
        end if


        ' m.posterUri.uri = m.top.detailScreenData[0].data.storage["record"]["banner"]

        m.typeID = m.top.detailScreenData[0].data.typeId
        m.relatedID = m.top.detailScreenData[0].data.id
        m.itemDetails = m.global.findNode("itemDetailSceneLayout")
        tmpData = []
        tmpData.push(m.top.detailScreenData[0])
        m.itemDetails.itemDetailsData = tmpData
        ' item.hdPosterUrl = "https://183.bozztv.com/storage/movies/" + channel.storageRecord["thumb"]
        ' m.descrField.text = m.top.dDescr
        ' m.titleField.text = m.top.dTitle
    end if
end sub



sub activateLiveBasedButtons()
    m.trailerGroup.visible = false
    m.moreLikeThisGroup.visible = false
end sub

sub activateVodBasedButtons()
    m.trailerGroup.visible = true
    m.moreLikeThisGroup.visible = true
end sub



sub commonResetActions()
    m.deactivateDetailsPage.control = "start"
    m.relatedContainer.visible = false
    deactivatePlayButton()
    deactivateWatchTrailerButton()
    deactivateMoreLikeThisButton()
    deactivateEpisodesButton()
    m.top.relatedDataEntity = invalid
    clearChildren(m.rowList)

    if m.top.navigatedFrom = "VOD" then
        m.global.findNode("vod_screen").visible = true
    else if m.top.navigatedFrom = "HOME" then
        m.global.findNode("home_screen").visible = true
    else if m.top.navigatedFrom = "LIVE" then
        m.global.findNode("live_screen").visible = true
    else if m.top.navigatedFrom = "Search" then
        m.global.findNode("search_screen").visible = true
    else if m.top.navigatedFrom = "TVSHOW" then
        m.global.findNode("saved_screen").visible = true
    end if
    m.global.findNode("navigation_bar").visible = true
end sub

sub clearChildren(rowList as object)
    childrenToRemove = []
    for i = 0 to rowList.getChildCount() - 1
        childrenToRemove.push(rowList.getChild(i))
    end for
    rowList.removeChildren(childrenToRemove)
end sub





function onKeyEvent(key as string, press as boolean) as boolean
    m.relatedGroup = m.top.findNode("relatedContainer")

    print key
    print press
    print "DetailScene Brs KeyEvent"

    if press = false and key = "back"
        if m.top.hasFocus() then
            activatePlayButton()
            return true
        end if
        ' if m.isFirstEntryData = true then
        '     print "do we get here"
        '     m.global.findNode("home_screen").setFocus(true)
        '     commonResetActions()
        ' end if
        return true
    end if
    if press = false and key <> invalid

        if m.top.hasFocus()
            activatePlayButton()
            return true
        else if key = "OK"
            if m.rowList.hasFocus() then
                m.isFirstEntryData = false
                focusedItem = getActiveEntityDetails()
                tmpData = []
                tmpData.push(focusedItem)
                m.top.detailScreenData = tmpData
                m.episodesContainer.visible = false
                m.relatedContainer.visible = false
                return true
            else if m.episodesList.hasFocus() then
                navigateToSelectedEpisode()
                return true
            end if
        end if


    else if key = "right" and press = true
    else if key = "down" and press = true
        if m.top.detailScreenData[0].isLiveChannel = false
            if m.playButtonGroup.hasFocus() then
                deactivatePlayButton()
                activateWatchTrailerButton()
                return true
            else if m.trailerGroup.hasFocus() then
                deactivateWatchTrailerButton()
                activateMoreLikeThisButton()
                return true

            else if m.moreLikeThisGroup.hasFocus() then
                if m.isTVSHOW = true then
                    deactivateMoreLikeThisButton()
                    activateEpisodesButton()
                    print "is this true"
                else
                    if m.relatedContainer.visible = true then
                        m.rowList = m.top.findNode("relatedList")
                        m.rowList.setFocus(true)
                        deactivateMoreLikeThisButton()
                        print "or is this true"
                    end if

                end if

                return true
            else if m.episodesGroup.hasFocus() then
                if m.episodesContainer.visible = false then
                    deactivateEpisodesButton()
                    m.rowList = m.top.findNode("relatedList")
                    m.rowList.setFocus(true)
                else
                    m.episodesList.setFocus(true)
                    deactivateEpisodesButton()
                end if

                return true
            end if
        end if
    else if key = "up" and press = true
        if m.top.detailScreenData[0].isLiveChannel = false
            if m.playButtonGroup.hasFocus() then

            else if m.trailerGroup.hasFocus() then
                deactivateWatchTrailerButton()
                activatePlayButton()
                return true

            else if m.moreLikeThisGroup.hasFocus() then
                deactivateMoreLikeThisButton()
                activateWatchTrailerButton()

                return true
                ' else if m.epi
            else if m.rowList.hasFocus() then
                if m.isTVSHOW = true then
                    activateEpisodesButton()
                else
                    activateMoreLikeThisButton()
                end if
                return true
            else if m.episodesGroup.hasFocus() then
                activateMoreLikeThisButton()
                deactivateEpisodesButton()
                return true
            else if m.episodesList.hasFocus() then
                activateEpisodesButton()
                return true

            end if


        end if
    else if key = "left" and press = true
    else if key = "back" and press = true then
        if m.isFirstEntryData = false then
            m.top.detailScreenData = m.firstEntryScreenData

        else
            if m.isFirstEntryData = true then
                print "Here Comes the OOGWAY"
                if m.top.navigatedFrom = "VOD" then
                    m.global.findNode("vod_screen").setFocus(true)
                    commonResetActions()
                    return true
                else if m.top.navigatedFrom = "LIVE" then
                    m.global.findNode("live_screen").setFocus(true)
                    commonResetActions()
                    return true
                else if m.top.navigatedFrom = "HOME" then
                    m.global.findNode("home_screen").setFocus(true)
                    commonResetActions()
                    return true
                else if m.top.navigatedFrom = "Search" then
                    m.global.findNode("search_screen").setFocus(true)
                    commonResetActions()
                    return true
                else if m.top.navigatedFrom = "TVSHOW" then
                    m.global.findNode("saved_screen").setFocus(true)
                    commonResetActions()
                    return true
                end if

            end if
        end if
        m.isFirstEntryData = true
        return true
    else if key = "OK" and press = true then
        if m.playButtonGroup.hasFocus() then
            if m.isTVSHOW = true then
                navigateToFirstEpisode()
            else
                navigateToPlayVideo()
            end if

            return true
        else if m.trailerGroup.hasFocus() then
            deactivateWatchTrailerButton()
            navigateToTrailerVideo()
            return true
        else if m.moreLikeThisGroup.hasFocus() then
            initializeRelatedVideos()
            m.relatedContainer.visible = true
            m.episodesContainer.visible = false
            return true
            ' else if m.relatedGroup.hasFocus() then
            '     print "RowList Here"
            '     rowItemFocusedInfo = m.rowList.rowItemFocused
            '     print rowItemFocusedInfo[1]
            '     print "here is RowitemFocusedInfo"
        else if m.episodesGroup.hasFocus() then
            m.episodesContainer.visible = true
            m.relatedContainer.visible = false
            ' deactivateEpisodesButton()
            ' m.episodesList.setFocus(true)
            return true

        end if

    end if

    return false
end function





sub initializeRelatedVideos()
    m.relatedData = createObject("roSGNode", "RelatedVod")
    m.relatedData.observeField("responseData", "handleResponseData")
    m.relatedData.typeID = m.typeID
    m.relatedData.relatedID = m.relatedID
    ShowSpinner(true)
    ' m.relatedData.control = "RUN"

end sub


sub handleResponseData()
    data = m.relatedData.responseData

    m.top.relatedDataEntity = parseVodScreenEntity(data, 0)
end sub



sub initializeEpisodes()
    if m.top.detailScreenData[0] <> invalid

        m.episodesContainer.visible = true
        hvc = CreateObject("roSGNode", "HomeVodContent")
        defaultFont = CreateObject("roSGNode", "Font")
        defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
        defaultFont.size = 42

        m.episodesList.focusable = true
        m.episodesList.rowLabelFont = defaultFont
        content = CreateObject("roSGNode", "ContentNode")
        ' m.episodesList.numColumns = vodCat.VodEntityData.count()
        ' m.episodesList.numRows = 4


        content.title = ""
        for each episode in m.top.detailScreenData[0].data.episodes
            print episode
            print "here is Episode we are Looking FOr"
            item = CreateObject("roSGNode", "ContentNode")
            item.title = episode.title
            item.addfields({
                rowItemFocus: false
                data: episode
                isLiveChannel: false
            })
            item.focusable = true
            ' item.hdPosterUrl = "https://183.bozztv.com/storage/movies/" + episode.storageRecord["thumb"]
            print episode.storageRecord
            if episode.storageRecord <> invalid
                if episode.storageRecord <> invalid
                    if episode.storageRecord["poster"] <> invalid
                        item.hdPosterUrl = episode.storageRecord["poster"]
                    end if
                end if
            else
                item.hdPosterUrl = ""
            end if

            content.appendChild(item)
        end for
        hvc.appendChild(content)
        ' m.episodesList.content = content
        ' m.episodesList.content = content

        ' m.episodesList.content = CreateObject("roSGNode", "RowListContent")

        m.episodesList.content = hvc
        m.episodesContainer.appendChild(m.episodesList)
        ' m.episodesList.observeField("rowItemFocused", "onRowItemFocused")


    end if


end sub


sub relatedDataUpdated()
    if m.top.relatedDataEntity <> invalid

        m.relatedContainer.visible = true
        hvc = CreateObject("roSGNode", "HomeVodContent")
        defaultFont = CreateObject("roSGNode", "Font")
        defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
        defaultFont.size = 42

        m.rowList.focusable = true
        m.rowList.rowLabelFont = defaultFont
        content = CreateObject("roSGNode", "ContentNode")
        ' m.rowList.numColumns = vodCat.VodEntityData.count()
        ' m.rowList.numRows = 4


        content.title = ""
        for each vodData in m.top.relatedDataEntity
            item = CreateObject("roSGNode", "ContentNode")
            item.title = vodData.title
            item.addfields({
                rowItemFocus: false
                data: vodData
                isLiveChannel: false
            })
            item.focusable = true
            ' item.hdPosterUrl = "https://183.bozztv.com/storage/movies/" + vodData.storageRecord["thumb"]
            if vodData.images <> invalid
                if vodData.images["thumbnail"] <> invalid
                    item.hdPosterUrl = vodData.images["thumbnail"]
                else item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
                end if
            end if



            content.appendChild(item)
        end for
        hvc.appendChild(content)
        ' m.rowList.content = content
        ' m.rowList.content = content

        ' m.rowList.content = CreateObject("roSGNode", "RowListContent")

        m.rowList.content = hvc
        m.relatedContainer.appendChild(m.rowList)
        m.rowList.observeField("rowItemFocused", "onRowItemFocused")


    end if

    ShowSpinner(false)

end sub


function navigateTrailerVideo()
    m.videoPlayerScreen = m.global.findNode("videoPlayerScreen")
    m.videoPlayerScreen.setFocus(true)
    m.global.findNode("detailScene").visible = false
    m.videoPlayerScreen.visible = true
    ' m.videoPlayerScreen.contentURL =  m.top.detailScreenData[0].storageRecord["source"]
    ' m.videoPlayerScreen.contentURL = m.top.detailScreenData[0].data.storage["record"]["trailer"]

    m.videoPlayerScreen.contentURL = m.top.detailScreenData[0].data.sources["primary"]

    m.videoPlayerScreen.contentProgramData = m.top.detailScreenData

end function


sub navigateToPlayVideo()

    ' onShowDVRPlayerScreen()
    m.videoPlayerScreen = m.global.findNode("videoPlayerScreen")


    ' m.videoPlayerScreen.contentURL =  m.top.detailScreenData[0].storageRecord["source"]
    print m.top.detailScreenData[0].data.sources["primary"]
    print "Do we even use this DEtail Screen Properly"
    if m.top.detailScreenData[0].isLiveChannel = true then
        m.videoPlayerScreen.contentProgram = m.top.detailScreenData[0].data.sources["primary"]
        ' m.videoPlayerScreen.isLive = "true"
    else
        progNodeToPlay = CreateObject("roSGNode", "ContentNode")
        progNodeToPlay.url = m.top.detailScreenData[0].data.sources["primary"]
        progNodeToPlay.title = m.top.detailScreenData[0].data.title
        progNodeToPlay.description = m.top.detailScreenData[0].data.description
        progNodeToPlay.hdposterurl = m.top.detailScreenData[0].data["images"]["thumbnail"]
        ' progNodeToPlay.playStart = "00"duration
        progNodeToPlay.playDuration = m.top.detailScreenData[0].data.duration
        progNodeToPlay.addFields({
            isCC: "false",
            isHD: "true",
            channelTitle: "JoyGo"
        })


        m.videoPlayerScreen.contentProgram = progNodeToPlay
        ' m.videoPlayerScreen.isLive = "false"
    end if
    m.videoPlayerScreen.setFocus(true)
    ' m.videoPlayerScreen.contentProgramData = m.top.detailScreenData

    m.global.findNode("detailScene").visible = false
    m.videoPlayerScreen.visible = true
end sub



sub onShowDVRPlayerScreen()
    ' print "MainScene.brs - [onShowDVRPlayerScreen()] Called " event

    ' epgGridScreen = event.getData()

    dvrVideoPlayerScreen = CreateObject("roSGNode", "VideoScreen")
    ' dvrVideoPlayerScreen.contentProgram = m.currentProgramContent
    dvrVideoPlayerScreen.contentProgram = m.top.detailScreenData[0].data.sources["primary"]
    print "MainScene.brs - [onShowDVRPlayerScreen()] programContent " m.currentProgramContent
    dvrVideoPlayerScreen.observeField("wasClosed", "onVideoPlayerDVRScreenViewClosed")


    print m.top.ComponentController
    print "Here is Component Controller"
    m.top.ComponentController.CallFunc("show", {
        view: dvrVideoPlayerScreen
    })

end sub

sub navigateToFirstEpisode()
    m.videoPlayerScreen = m.global.findNode("videoPlayerScreen")
    episode = m.top.detailScreenData[0].data.episodes[0]
    m.videoPlayerScreen.contentURL = episode.storageRecord["source"]
    m.videoPlayerScreen.isLive = "false"
    m.videoPlayerScreen.setFocus(true)
    m.global.findNode("detailScene").visible = false
    m.videoPlayerScreen.visible = true


    ' isSubscribed = validateSubscription()

    ' ' m.relatedContainer.visible = false
    ' ' m.deactivateDetailsPage.control = "start"

    ' if isSubscribed = true
    '     m.videoPlayerScreen = m.global.findNode("videoPlayerScreen")
    '     episode = m.top.detailScreenData[0].data.episodes[0]
    '     m.videoPlayerScreen.contentURL = episode.storageRecord["source"]
    '     m.videoPlayerScreen.isLive = "false"
    '     m.videoPlayerScreen.setFocus(true)
    '     m.global.findNode("detailScene").visible = false
    '     m.videoPlayerScreen.visible = true
    ' else
    '     ' m.loginScreen = m.global.findNode("login_screen")
    '     ' m.loginScreen.visible = true
    '     ' m.loginScreen.focusable = true
    '     ' m.loginScreen.setFocus(true)
    ' end if

    ' m.global.findNode("navigation_bar").visible = false
end sub



sub initiateNewUserSignupFlow()

    showLoadingDialog("Loading please wait...")
    m.bIsNewSignUp = true
    print "SignupScreenView.brs - [initiateNewUserSignupFlow] Called"
    print "SignupScreenView.brs - [initiateNewUserSignupFlow] Fetching User Data"

    m.billing = m.top.CreateChild("RokuBillingTask")
    m.billing.userDataToShare = "email,firstname,lastname,street1,street2,city,state,zip,country,phone"
    m.billing.requestedUserData = "email,firstname,lastname,street1,street2,city,state,zip,country,phone"
    m.billing.functionName = "GetPartialUserData"
    m.billing.ObserveField("partialUserData", "OnBillingPartialUserDataReceived")
    m.billing.control = "RUN"

    print "SignupScreenView.brs - [initiateNewUserSignupFlow] Exiting"
end sub

sub showAvailableSubscriptionsForPurchase()
    m.billing = invalid
    print "SignupScreenView.brs - [showAvailableSubscriptionsForPurchase] Called"

    showLoadingDialog("Fetching Subscriptions please wait...")
    if m.billing = invalid then
        print "SignupScreenView.brs - [showAvailableSubscriptionsForPurchase] Instantiating Billing"
        m.billing = m.top.CreateChild("RokuBillingTask")
    end if

    m.billing.functionName = "GetProducts"
    m.billing.ObserveField("products", "OnPurchaseableProductsFetched")
    m.billing.control = "RUN"

    print "SignupScreenView.brs - [showAvailableSubscriptionsForPurchase] Exiting"

end sub

sub OnBillingPartialUserDataReceived()

    print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] Called and partialUserData " m.billing.partialUserData

    if m.billing.partialUserData <> invalid then
        print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] Valid User Data Received "
        m.top.userSignupData = m.billing.partialUserData
        userEmail = m.billing.partialUserData.email

        print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] bIsNewSignUp " m.bIsNewSignUp
        print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] Email " m.billing.partialUserData.email
        print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] firstname " m.billing.partialUserData.firstname
        print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] lastname " m.billing.partialUserData.lastname
        print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] street1 " m.billing.partialUserData.street1
        print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] street2 " m.billing.partialUserData.street2
        print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] city " m.billing.partialUserData.city
        print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] state " m.billing.partialUserData.state
        print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] zip " m.billing.partialUserData.zip
        print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] country " m.billing.partialUserData.country
        print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] phone " m.billing.partialUserData.phone

        if m.bIsNewSignUp = true then
            ShowPasswordDialog()
            ' print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] New Signup Case "
            ' m.checkEmail = createObject("roSGNode", "CheckEmail")
            ' m.checkEmail.setField("email",m.billing.partialUserData.email)
            ' m.checkEmail.setField("status","")
            ' m.checkEmail.observeField("status","onCheckAccountResponse")
            ' m.checkEmail.control = "RUN"
        else
            print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] Expired Subscription Case??? "
        end if

    else
        print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] INVALID User Data Received "
    end if

    print "SignupScreenView.brs - [OnBillingPartialUserDataReceived] Exiting "
end sub

sub OnPurchaseableProductsFetched()
    print "SignupScreenView.brs - [OnPurchaseableProductsFetched] Called"

    TopDialogClose()

    if m.billing.bHasValidSubscription = true then
        print "SignupScreenView.brs - [OnPurchaseableProductsFetched] User already have a valid Subscription..."
        m.top.GetScene().dialog = m.dialogErrValidSubscriptionExists
    else
        if m.billing.products <> invalid then
            print "SignupScreenView.brs - [OnPurchaseableProductsFetched] We have Purchasable Subscriptions"
            print "SignupScreenView.brs - [OnPurchaseableProductsFetched] Products/Subscriptions " m.billing.products
            print "SignupScreenView.brs - [OnPurchaseableProductsFetched] arrayProductsName " m.billing.arrayProductsName
            m.productSubscriptions = m.billing.products
            m.arraySubscriptionsNameCost = m.billing.arrayProductsName

            showDialogPurchaseSubscriptions()
        else
            print "SignupScreenView.brs - [OnPurchaseableProductsFetched] No Subscription to Purchase"
            m.top.GetScene().dialog = m.dialogErrFailedToFetchSubscriptions
        end if
    end if

    print "SignupScreenView.brs - [OnPurchaseableProductsFetched] Exiting"
end sub


sub showDialogPurchaseSubscriptions()

    print "SignupScreenView.brs - [showDialogPurchaseSubscriptions] Called "
    print "SignupScreenView.brs - [showDialogPurchaseSubscriptions] With Subs" m.top.arraySubscriptionsNameCost

    arrayButtons = []
    m.availForPurchase = []

    print m.productSubscriptions
    print m.productSubscriptions.availforpurchase
    print "Here is Products"

    nnn = 0
    for each product in m.productSubscriptions.availForPurchase.list
        print "SignupScreenView.brs - [showDialogPurchaseSubscriptions] product Adding " product
        print "SignupScreenView.brs - [showDialogPurchaseSubscriptions] Added as " product.name + "  " + product.cost

        ' if m.global.signup = "jbroadbandTVplus" AND product.code="jbroadbandTVplus" then
        '         arrayButtons.Push(product.name + " -  " + product.cost)
        ' 	m.availForPurchase.Push(nnn)
        ' else if m.global.signup = "jbroadbandtv" AND product.code="jbroadbandtv" then
        '         arrayButtons.Push(product.name + "  " + product.cost)
        ' 	m.availForPurchase.Push(nnn)
        ' end if

        if product.code = "pockoFirstSub" then
            arrayButtons.Push(product.name + " -  " + product.cost)
            m.availForPurchase.Push(nnn)
        end if


        nnn = nnn + 1
    end for
    arrayButtons.Push("Cancel")
    print "SignupScreenView.brs - [showDialogPurchaseSubscriptions] arrayButtons " arrayButtons

    '''    m.totalPurchaseableProducts = m.productSubscriptions.availForPurchase.list.count()
    m.totalPurchaseableProducts = arrayButtons.count() - 1
    m.dialogPurchaseableProducts.buttons = arrayButtons
    m.dialogPurchaseableProducts.optionsDialog = true
    m.top.GetScene().dialog = m.dialogPurchaseableProducts
    m.top.GetScene().dialog.setFocus(true)

    print "SignupScreenView.brs - [showDialogPurchaseSubscriptions] m.totalPurchaseableProducts " m.totalPurchaseableProducts
    print "SignupScreenView.brs - [showDialogPurchaseSubscriptions] Exiting"

end sub

sub showSuccessDialog()
    m.top.GetScene().dialog = m.purchaseSubscriptionSuccess
    m.top.GetScene().dialog.setFocus(true)
end sub



sub On_dialogPurchaseProducts_buttonSelected()

    print "SignupScreenView.brs - [On_dialogPurchaseProducts_buttonSelected()] buttonSelected " m.dialogPurchaseableProducts.buttonSelected
    print "SignupScreenView.brs - [On_dialogPurchaseProducts_buttonSelected()] totalPurchaseableProducts = " m.totalPurchaseableProducts
    print "SignupScreenView.brs - [On_dialogPurchaseProducts_buttonSelected()] availForPurchase " m.productSubscriptions.availForPurchase.list

    if m.dialogPurchaseableProducts.buttonSelected = m.totalPurchaseableProducts then
        TopDialogClose()
    else
        print "SignupScreenView.brs - [On_dialogPurchaseProducts_buttonSelected()] User Selected Some Product to Purchase"
        showLoadingDialog("Initiating Subscription Purchase, please wait...")
        m.billing.indexPurchase = m.availForPurchase[m.dialogPurchaseableProducts.buttonSelected]
        m.billing.functionName = "PurchaseProduct"
        m.billing.ObserveField("purchaseResult", "OnPurchaseProductSubscriptionResult")
        m.billing.control = "RUN"

    end if

    print "SignupScreenView.brs - [On_dialogPurchaseProducts_buttonSelected()] Exiting"

end sub


sub TopDialogClose()
    if m.top.GetScene().dialog <> invalid then
        m.top.GetScene().dialog.close = true
    end if
end sub


sub verifySubscription()
    getAuthToken()
    showLoadingDialog("Loading, please wait...")
    m.validateSubscriptionApi = createObject("roSGNode", "ValidateSubscriptionApi")
    m.validateSubscriptionApi.observeField("responseData", "handleVerificationResponseData")
    m.validateSubscriptionApi.authToken = m.accessToken
    m.validateSubscriptionApi.transactionId = m.rokuUserPurchaseId
end sub


sub handleVerificationResponseData()
    if m.validateSubscriptionApi.responseData <> invalid
        print m.validateSubscriptionApi.responseData
        print "ResponseData of Subscription"
        m.authData = RetrieveAuthData()
        if m.authData <> invalid
            authToken = m.authData.accessToken
            fetchProfileInfo(authToken)

        end if
    end if
end sub


sub showLoadingDialog(textToShow as string)
    m.progressdialog.busySpinner.uri = "pkg:/images/png/loader.png"
    m.progressdialog.backgroundUri = "pkg:/images/png/shapes/final_transparent_mask.png"
    m.progressdialog.width = 500
    m.progressdialog.title = textToShow

    if m.top.visible = true
        m.top.GetScene().dialog = m.progressdialog
    end if



end sub



sub OnPurchaseProductSubscriptionResult()

    print "SignupScreenView.brs - [OnPurchaseProductSubscriptionResult()] Called"
    if m.billing.purchaseResult <> invalid then
        print "SignupScreenView.brs - [OnPurchaseProductSubscriptionResult()] We have Purchase Result"
        if m.billing.purchaseResult.isSuccess = true then
            ''HERE we need to Signup User On Server with our Subscription Code!
            'Here we need to further continue the Signup Process...
            m.rokuUserPurchaseId = m.billing.purchaseResult.purchaseId
            m.rokuUserPurchasedCode = m.billing.purchaseResult.code
            print m.billing.purchaseResult
            print m.rokuUserPurchaseId
            print m.rokuUserPurchasedCode
            print "Here is Purchase ID tho"
            TopDialogClose()
            verifySubscription()
            ' signupAccount()
        else
            print "SignupScreenView.brs - [OnPurchaseProductSubscriptionResult()] Purchase Failed"
            if m.billing.purchaseResult.failureMessage <> invalid then
                print "SignupScreenView.brs - [OnPurchaseProductSubscriptionResult()] Purchase Failed with Message " m.billing.purchaseResult.failureMessage
                m.dialogErrPurchanseSubscriptionFailed.message = m.billing.purchaseResult.failureMessage
            end if
            m.top.GetScene().dialog = m.dialogErrPurchanseSubscriptionFailed
        end if
    else
        print "SignupScreenView.brs - [OnPurchaseProductSubscriptionResult()] Error in Purchasing Subscription"
        m.top.GetScene().dialog = m.dialogErrPurchanseSubscriptionFailed
    end if

    print "SignupScreenView.brs - [OnPurchaseProductSubscriptionResult()] Exiting"
end sub

sub navigateToSelectedEpisode()
    m.videoPlayerScreen = m.global.findNode("videoPlayerScreen")
    episode = getAtciveEpisodeDetails()

    if episode <> invalid
        m.videoPlayerScreen.contentURL = episode.data.sources["primary"]
        m.videoPlayerScreen.isLive = "false"
        m.videoPlayerScreen.setFocus(true)
        m.global.findNode("detailScene").visible = false
        m.videoPlayerScreen.visible = true
    end if


    ' isSubscribed = validateSubscription()
    ' ' m.relatedContainer.visible = false
    ' ' m.deactivateDetailsPage.control = "start"
    ' if isSubscribed = true
    '     m.videoPlayerScreen = m.global.findNode("videoPlayerScreen")
    '     episode = getAtciveEpisodeDetails()
    '     print episode.data
    '     print "Here is Episode"

    '     m.videoPlayerScreen.contentURL = episode.data.storageRecord["source"]
    '     m.videoPlayerScreen.isLive = "false"
    '     m.videoPlayerScreen.setFocus(true)
    '     m.global.findNode("detailScene").visible = false
    '     m.videoPlayerScreen.visible = true
    ' else
    '     ' m.loginScreen = m.global.findNode("login_screen")


    '     ' m.loginScreen.visible = true
    '     ' m.loginScreen.focusable = true
    '     ' m.loginScreen.setFocus(true)
    ' end if

    ' m.global.findNode("navigation_bar").visible = false
end sub

sub getAuthToken()
    authData = RetrieveAuthData()
    m.accessToken = authData.accessToken
end sub


sub validateSubscription() as boolean
    authData = RetrieveAuthData()

    print authData
    if authData <> invalid
        m.accessToken = authData.accessToken
        if authData.subscribed = 1
            return true
        else
            showAvailableSubscriptionsForPurchase()
            ' initiateNewUserSignupFlow()
            return false
        end if
    else
        ' m.relatedContainer.visible = false
        ' m.deactivateDetailsPage.control = "start"
        ' m.global.findNode("navigation_bar").visible = false

        ' m.loginScreen = m.global.findNode("login_screen")
        ' m.loginScreen.visible = true
        ' m.loginScreen.isNavigatedFromAccountTab = false
        ' m.loginScreen.focusable = true
        ' m.loginScreen.setFocus(true)
        ' ShowPasswordDialog()
        showAvailableAuthorizationOptions()
        return false
    end if
end sub

sub showAvailableAuthorizationOptions()
    arrayButtons = []
    arrayButtons.Push("Signup")
    arrayButtons.Push("Log in")
    arrayButtons.Push("Cancel")
    m.authorizationDialog.buttons = arrayButtons
    m.authorizationDialog.optionsDialog = true
    m.top.GetScene().dialog = m.authorizationDialog
    m.top.GetScene().dialog.setFocus(true)

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


sub navigateToTrailerVideo()

    m.relatedContainer.visible = false
    m.deactivateDetailsPage.control = "start"

    m.videoPlayerScreen = m.global.findNode("videoPlayerScreen")
    ' m.videoPlayerScreen.contentURL =  m.top.detailScreenData[0].storageRecord["source"]
    m.videoPlayerScreen.contentURL = m.top.detailScreenData[0].data.sources["trailer"]
    m.videoPlayerScreen.setFocus(true)
    ' m.videoPlayerScreen.contentProgramData = m.top.detailScreenData

    m.global.findNode("detailScene").visible = false
    m.videoPlayerScreen.visible = true
end sub



function activatePlayButton()
    m.playButtonGroup.setFocus(true)
    m.playButtonIcon = m.top.findNode("playButtonIcon")
    m.playButtonIcon.uri = "pkg:/images/png/play_button_filled.png"
    m.playButtonText = m.top.findNode("playButtonText")
    m.playButtonText.color = "#fe4a65"
end function




function activateWatchTrailerButton()
    m.trailerGroup.setFocus(true)
    m.watchTrailerButtonIcon.uri = "pkg:/images/png/play_button_filled.png"
    m.trailerButtonText.color = "#fe4a65"

end function

function activateMoreLikeThisButton()
    m.moreLikeThisGroup.setFocus(true)
    m.moreLikeThisButtonIcon.uri = "pkg:/images/png/more_like_this_fileld.png"
    m.moreLikeThisButtonText.color = "#fe4a65"
end function


function deactivatePlayButton()
    ' m.playButtonGroup.setFocus(true)
    m.playButtonIcon.uri = "pkg:/images/png/play_button_empty.png"
    m.playButtonText.color = "0xFFFFFF"
end function




function deactivateWatchTrailerButton()
    m.watchTrailerButtonIcon.uri = "pkg:/images/png/play_button_empty.png"
    m.trailerButtonText.color = "0xFFFFFF"

end function

function deactivateMoreLikeThisButton()
    m.moreLikeThisButtonIcon.uri = "pkg:/images/png/more_like_this_empty.png"
    m.moreLikeThisButtonText.color = "0xFFFFFF"
end function



function activateEpisodesButton()
    m.episodesGroup.setFocus(true)
    m.episodesButtonIcon.uri = "pkg:/images/png/more_like_this_fileld.png"
    m.episodesButtonText.color = "#fe4a65"
end function


function deactivateEpisodesButton()
    m.episodesButtonIcon.uri = "pkg:/images/png/more_like_this_empty.png"
    m.episodesButtonText.color = "0xFFFFFF"
end function







function ToString(variable as dynamic) as string
    if Type(variable) = "roInt" or Type(variable) = "roInteger" or Type(variable) = "roFloat" or Type(variable) = "Float" then
        return Str(variable).Trim()
    else if Type(variable) = "roBoolean" or Type(variable) = "Boolean" then
        if variable = True then
            return "True"
        end if
        return "False"
    else if Type(variable) = "roString" or Type(variable) = "String" then
        return variable
    else
        return Type(variable)
    end if
end function

sub ShowSpinner(show)
    m.spinner.visible = show
    if show
        m.spinner.control = "start"
    else
        m.spinner.control = "stop"
    end if
end sub


function getActiveEntityDetails()
    rowItemFocusedInfo = m.rowList.rowItemFocused
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        focusedRow = m.rowList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid

                return focusedItem
            end if
        end if
    end if
end function


function getAtciveEpisodeDetails()
    rowItemFocusedInfo = m.episodesList.rowItemFocused
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        focusedRow = m.episodesList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid

                return focusedItem
            end if
        end if
    end if
end function



sub fetchProfileInfo(authToken as string)
    m.ProfileData = createObject("roSGNode", "ProfileApi")
    m.ProfileData.observeField("responseData", "handleProfileData")
    m.ProfileData.authToken = authToken
    showLoadingDialog("Loading please wait...")
end sub



sub handleProfileData()
    data = m.ProfileData.responseData
    if data = "Error"
    else
        subscribed = ParseJson(data).data.subscribed

        UpdateAuthData(m.authData.accessToken, subscribed, true, m.authData.expiry)
    end if
    TopDialogClose()

    showSuccessDialog()
    ' sendAppLaunchCompleteBeacon()
end sub


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





