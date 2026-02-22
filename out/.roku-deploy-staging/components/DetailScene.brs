sub init()
    m.top.observeField("detailScreenData", "detailsScreenDataChanged")
    m.top.visible = false
    m.top.observeField("visible", "visibilityUpdated")
    m.top.relatedDataEntity = m.top.findNode("relatedDataEntity")
    m.top.observeField("relatedDataEntity", "relatedDataUpdated")

    m.playButtonGroup = m.top.findNode("playButtonGroup")
    m.trailerGroup = m.top.findNode("trailerGroup")
    m.moreLikeThisGroup = m.top.findNode("moreLikeThisGroup")


    m.playButtonIcon = m.top.findNode("playButtonIcon")
    m.playButtonText = m.top.findNode("playButtonText")

    m.moreLikeThisButtonIcon = m.top.findNode("moreLikeThisButtonIcon")
    m.moreLikeThisButtonText = m.top.findNode("moreLikeThisButtonText")

    m.watchTrailerButtonIcon = m.top.findNode("watchTrailerButtonIcon")
    m.trailerButtonText = m.top.findNode("trailerButtonText")

    m.rowList = m.top.findNode("relatedList")

    m.relatedID = "0"

    m.spinner = m.top.findNode("spinner")

    m.activateDetailsPage = m.top.findNode("activateDetailsPage")

    m.deactivateDetailsPage = m.top.findNode("deactivateDetailsPage")

    m.deactivateDetailsPage.observeField("state", "deactivationStateChanged")

    m.firstEntryScreenData = m.top.detailScreenData
    m.isFirstEntryData = true


    m.relatedContainer = m.top.findNode("relatedContainer")
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
    else
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

        ' m.posterUri.uri = m.top.detailScreenData[0].data.storage["record"]["banner"]
        m.posterUri.uri = m.top.detailScreenData[0].data.storage["record"]["poster"]

        m.relatedID = m.top.detailScreenData[0].data.id
        print "here is RelatedID We want YK"
        m.itemDetails = m.global.findNode("itemDetailSceneLayout")
        tmpData = []
        tmpData.push(m.top.detailScreenData[0])
        m.itemDetails.itemDetailsData = tmpData
        ' item.hdPosterUrl = "https://183.bozztv.com/storage/movies/" + channel.storageRecord["thumb"]
        ' m.descrField.text = m.top.dDescr
        ' m.titleField.text = m.top.dTitle
    end if
end sub


function onKeyEvent(key as string, press as boolean) as boolean
    print key
    print press
    print "DetailSceneKeyEvent"

    if press = false then
        if key = "back" then
            if m.top.hasFocus() then
                if m.isFirstEntryData = false then
                    m.top.detailScreenData = m.firstEntryScreenData

                else
                    m.global.findNode("home_screen").setFocus(true)
                    commonResetActions()
                end if
                m.isFirstEntryData = true
                return true
            end if
        else if key = "OK" then
            handleOKButton()
            return true
        end if
    end if

    return false
end function


sub commonResetActions()
    m.deactivateDetailsPage.control = "start"
    m.relatedContainer.visible = false
    deactivatePlayButton()
    deactivateWatchTrailerButton()
    deactivateMoreLikeThisButton()
    m.top.relatedDataEntity = invalid
    clearChildren(m.rowList)
    m.global.findNode("home_screen").visible = true
    m.global.findNode("navigation_bar").visible = true
end sub

sub clearChildren(rowList as object)
    childrenToRemove = []
    for i = 0 to rowList.getChildCount() - 1
        childrenToRemove.push(rowList.getChild(i))
    end for
    rowList.removeChildren(childrenToRemove)
end sub

sub handleOKButton()
    print "Handle OK button logic here"
    if m.rowList.hasFocus() then
        m.isFirstEntryData = false
        focusedItem = getActiveEntityDetails()
        tmpData = []
        tmpData.push(focusedItem)
        m.top.detailScreenData = tmpData
    end if
    if m.playButtonGroup.hasFocus() then

        navigateToPlayVideo()
    else if m.trailerGroup.hasFocus() then
    else if m.moreLikeThisGroup.hasFocus() then
        initializeRelatedVideos()
    end if
end sub






' function onKeyEvent(key as string, press as boolean) as boolean
'     print key
'     print press
'     print "DetailSceneKeyEvent"
'     m.relatedGroup = m.top.findNode("relatedContainer")

'     if press = false and key = "back"
'         print key
'         print press
'         print "DetailSceneKeyEvent"
'         print "do I get here When I press back BUtton2"
'         if m.top.hasFocus() then
'             print "do I get here When I press back BUtton3"
'             if m.isFirstEntryData = false then
'                 m.top.detailScreenData = m.firstEntryScreenData
'                 m.isFirstEntryData = true
'                 return true
'             else
'                 print "do I get here When I press back BUtton4"
'                 m.global.findNode("home_screen").setFocus(true)
'                 m.deactivateDetailsPage.control = "start"
'                 m.relatedContainer.visible = false
'                 deactivatePlayButton()
'                 deactivateWatchTrailerButton()
'                 deactivateMoreLikeThisButton()
'                 m.top.relatedDataEntity = invalid
'                 childrenToRemove = []
'                 for i = 0 to m.rowList.getChildCount() - 1
'                     childrenToRemove.push(m.rowList.getChild(i))
'                 end for
'                 print "do I get here When I press back BUtton5"
'                 m.rowList.removeChildren(childrenToRemove)
'                 m.global.findNode("home_screen").visible = true
'                 m.global.findNode("navigation_bar").visible = true
'                 return true
'             end if
'             return true
'         end if
'         print "do I get here When I press back BUtton4"
'         return true

'     else
'         print key
'         print press
'         print "DetailSceneKeyEvent"
'         print "do I get here When I press back BUtton2"
'         if press = false and key <> invalid
'             print "This is ACTIVATING PLAY  BUTTON RIGHT?"

'             if m.top.hasFocus()
'                 activatePlayButton()
'                 return true
'             else if key = "OK"
'                 print "do we get here?"
'                 if m.rowList.hasFocus() then
'                     m.isFirstEntryData = false
'                     focusedItem = getActiveEntityDetails()
'                     tmpData = []
'                     tmpData.push(focusedItem)
'                     m.top.detailScreenData = tmpData
'                     return true
'                 end if
'             end if


'         else if key = "right" and press = true
'         else if key = "down" and press = true

'             if m.playButtonGroup.hasFocus() then
'                 deactivatePlayButton()
'                 activateWatchTrailerButton()
'                 return true
'             else if m.trailerGroup.hasFocus() then
'                 deactivateWatchTrailerButton()
'                 activateMoreLikeThisButton()
'                 return true

'             else if m.moreLikeThisGroup.hasFocus() then
'                 m.rowList = m.top.findNode("relatedList")
'                 m.rowList.setFocus(true)
'             end if

'         else if key = "up" and press = true
'             if m.playButtonGroup.hasFocus() then

'             else if m.trailerGroup.hasFocus() then
'                 deactivateWatchTrailerButton()
'                 activatePlayButton()
'                 return true

'             else if m.moreLikeThisGroup.hasFocus() then
'                 deactivateMoreLikeThisButton()
'                 activateWatchTrailerButton()

'                 return true
'             else if m.rowList.hasFocus() then
'                 activateMoreLikeThisButton()
'                 return true
'             end if

'         else if key = "left" and press = true
'         else if key = "back" and press = true then
'             if m.isFirstEntryData = false then
'                 m.top.detailScreenData = m.firstEntryScreenData
'                 m.isFirstEntryData = true
'                 return true
'             else
'             return true
'             end if
'             return true
'         else if key = "OK" and press = true then
'             if m.playButtonGroup.hasFocus() then
'                 print "doI get Here TWICE?"
'                 navigateToPlayVideo()
'                 return true
'             else if m.trailerGroup.hasFocus() then
'             else if m.moreLikeThisGroup.hasFocus() then
'                 initializeRelatedVideos()
'                 ' else if m.relatedGroup.hasFocus() then
'                 '     print "RowList Here"
'                 '     rowItemFocusedInfo = m.rowList.rowItemFocused
'                 '     print rowItemFocusedInfo[1]
'                 '     print "here is RowitemFocusedInfo"

'             end if

'         end if
'     end if
'     return false
' end function



sub initializeRelatedVideos()
    m.relatedData = createObject("roSGNode", "RelatedVod")
    m.relatedData.observeField("responseData", "handleResponseData")
    m.relatedData.relatedID = m.relatedID
    ShowSpinner(true)
    ' m.relatedData.control = "RUN"

end sub


sub handleResponseData()
    data = m.relatedData.responseData

    m.top.relatedDataEntity = parseVodScreenEntity(data, 8)
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
            if vodData.storage <> invalid
                if vodData.storage["record"] <> invalid
                    if vodData.storage["record"]["banner"] <> invalid
                        item.hdPosterUrl = vodData.storage["record"]["banner"]
                    end if
                end if
            else
                item.hdPosterUrl = ""
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
    m.videoPlayerScreen.contentURL = m.top.detailScreenData[0].data.storage["record"]["trailer"]

    m.videoPlayerScreen.contentProgramData = m.top.detailScreenData

end function


sub navigateToPlayVideo()
    ' TODO navigation
    m.global.findNode("login_screen").setFocus(true)
    m.deactivateDetailsPage.control = "start"
    m.relatedContainer.visible = false
    deactivatePlayButton()
    deactivateWatchTrailerButton()
    deactivateMoreLikeThisButton()
    m.top.relatedDataEntity = invalid
    clearChildren(m.rowList)
    m.global.findNode("login_screen").visible = true
    m.global.findNode("navigation_bar").visible = false

    ' m.videoPlayerScreen = m.global.findNode("videoPlayerScreen")


    ' ' m.videoPlayerScreen.contentURL =  m.top.detailScreenData[0].storageRecord["source"]
    ' m.videoPlayerScreen.contentURL = m.top.detailScreenData[0].data.storage["record"]["source"]
    ' m.videoPlayerScreen.setFocus(true)
    ' ' m.videoPlayerScreen.contentProgramData = m.top.detailScreenData

    ' m.global.findNode("detailScene").visible = false
    ' m.videoPlayerScreen.visible = true
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
    m.playButtonGroup.setFocus(true)
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