sub init()
    m.top.setFocus(true)
    m.top.navHasFocus = m.top.findNode("navHasFocus")
    m.navBarBackground = m.top.findNode("navBarBackground")
    m.top.navHasFocus = true
    ' m.navItems = [m.top.findNode("searchGroup"), m.top.findNode("homeGroup"), m.top.findNode("liveGroup"), m.top.findNode("videoGroup"), m.top.findNode("savedGroup"), ]
    m.navItems = [m.top.findNode("searchGroup"), m.top.findNode("homeGroup"), m.top.findNode("liveGroup"), m.top.findNode("videoGroup"), m.top.findNode("tvShowGroup"), m.top.findNode("accountGroup"),]

    ' m.top.findNode("exitAppGroup")
    ' m.top.findNode("accountGroup")
    m.currentIndex = 1
    m.navItems[m.currentIndex].setFocus(true)
    m.navItem1Label = m.top.findNode("homeGroup").getChild(1)
    m.navItem1Poster = m.top.findNode("homeGroup").getChild(0)
    m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/home_icon_active.png"
    m.navItem1Label.color = "#f16667"


end sub


sub focusUpdated()
    if m.top.navHasFocus = false
        m.top.opacity = 0.4
        ' m.navBarBackground.color = "#1F1B1B"
    else
        m.top.opacity = 1
        m.navBarBackground.color = "#00000"
    end if
end sub


' m.logoutIcon.uri = "pkg:/images/png/logout_active.png"
function onKeyEvent(key as string, press as boolean) as boolean
    if press then
        if key = "up" then
            m.storedIndex = m.currentIndex
            makeNavItemInactive(m.storedIndex)
            m.currentIndex = (m.currentIndex - 1 + m.navItems.count()) mod m.navItems.count()
            m.navItems[m.currentIndex].setFocus(true)
            makeNavItemActive(m.currentIndex)
            determineAndExecuteNavigation(m.currentIndex)
            return true
        else if key = "down" then
            m.storedIndex = m.currentIndex
            makeNavItemInactive(m.storedIndex)
            m.currentIndex = (m.currentIndex + 1) mod m.navItems.count()
            m.navItems[m.currentIndex].setFocus(true)
            makeNavItemActive(m.currentIndex)
            if m.currentIndex <> 6
                determineAndExecuteNavigation(m.currentIndex)
            end if
            return true
        else if key = "right" then
            m.top.navHasFocus = false
            selectAndScreenSpecificFocus(m.currentIndex)
        ' else if key = "back" and press = true
        '     if m.currentIndex <> 6
        '         return true
        '     end if
        end if
    else if key = "OK" and press = true
        ' SimulateBackButtonPress()
        return true
    end if
    return false
end function





sub makeNavItemActive(index as integer)
    m.navItemStoredLabel = m.navItems[index].getChild(1)
    m.navItem1Poster = m.navItems[index].getChild(0)

    if index = 0 then
        m.navItemStoredLabel.color = "#f16667"
        m.navItemStoredLabel.font.size = 25
        m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/search_icon_active.png"
    else if index = 1 then
        m.navItemStoredLabel.color = "#f16667"
        m.navItemStoredLabel.font.size = 25
        m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/home_icon_active.png"
    else if index = 2 then
        m.navItemStoredLabel.color = "#f16667"
        m.navItemStoredLabel.font.size = 25
        m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/live_icon_active.png"
    else if index = 3 then
        m.navItemStoredLabel.color = "#f16667"
        m.navItemStoredLabel.font.size = 25
        m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/movie_icon_active.png"
    else if index = 4 then
        m.navItemStoredLabel.color = "#f16667"
        m.navItemStoredLabel.font.size = 25
        m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/archives_icon_active.png"
        ' else if index = 5 then
        '     m.navItemStoredLabel.color = "#f16667"
        '     m.navItemStoredLabel.font.size = 25
        '     m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/podcast_icon_active.png"
    else if index = 5 then
        m.navItemStoredLabel.color = "#f16667"
        m.navItemStoredLabel.font.size = 25
        m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/account_icon_active.png"
    ' else if index = 6 then
    '     m.navItemStoredLabel.color = "#f16667"
    '     m.navItemStoredLabel.font.size = 25
    '     m.navItem1Poster.uri = "pkg:/images/png/logout_active.png"
    end if
end sub

sub makeNavItemInactive(index as integer)
    m.navItemStoredLabel = m.navItems[index].getChild(1)
    m.navItem1Poster = m.navItems[index].getChild(0)

    if index = 0 then
        m.navItemStoredLabel.color = "#ffffff"
        m.navItemStoredLabel.font.size = 22
        m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/search_icon.png"
    else if index = 1 then
        m.navItemStoredLabel.color = "#ffffff"
        m.navItemStoredLabel.font.size = 22
        m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/home_icon.png"
    else if index = 2 then
        m.navItemStoredLabel.color = "#ffffff"
        m.navItemStoredLabel.font.size = 22
        m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/live_icon.png"
    else if index = 3 then
        m.navItemStoredLabel.color = "#ffffff"
        m.navItemStoredLabel.font.size = 22
        m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/movie_icon.png"
    else if index = 4 then
        m.navItemStoredLabel.color = "#ffffff"
        m.navItemStoredLabel.font.size = 22
        m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/archives_icon.png"
        ' else if index = 5 then
        '     m.navItemStoredLabel.color = "#ffffff"
        '     m.navItemStoredLabel.font.size = 22
        '     m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/podcast_icon.png"
    else if index = 5 then
        m.navItemStoredLabel.color = "#ffffff"
        m.navItemStoredLabel.font.size = 22
        m.navItem1Poster.uri = "pkg:/images/png/navigation_icons/account_icon.png"
    ' else if index = 6 then
    '     m.navItemStoredLabel.color = "#ffffff"
    '     m.navItemStoredLabel.font.size = 22
    '     m.navItem1Poster.uri = "pkg:/images/png/logout.png"    
    end if


end sub

sub selectAndScreenSpecificFocus(index as integer)
    if index = 0 then
        m.global.findNode("search_screen").setFocus(true)

    else if index = 1 then
        m.global.findNode("home_screen").setFocus(true)

    else if index = 2 then
        m.global.findNode("live_screen").setFocus(true)

        ' m.videoPlayer = m.global.findNode("live_video_player").setFocus(true)
        ' newHighlightBorder.visible = true
    else if index = 3 then
        m.global.findNode("vod_screen").setFocus(true)

    else if index = 4 then
        m.global.findNode("saved_screen").setFocus(true)

        ' else if index = 5 then
        '     m.global.findNode("podcast_screen").setFocus(true)
    else if index = 5 then
        m.global.findNode("account_screen").setFocus(true)
    ' else if index = 6 then
        ' m.global.findNode("account_screen").setFocus(true)
    end if
end sub


sub determineAndExecuteNavigation(index as integer)
    m.global.findNode("live_screen").visible = false
    m.global.findNode("home_screen").visible = false
    m.global.findNode("search_screen").visible = false
    m.global.findNode("vod_screen").visible = false
    m.global.findNode("saved_screen").visible = false
    ' m.global.findNode("podcast_screen").visible = false
    m.global.findNode("account_screen").visible = false
    if index = 0 then
        m.global.findNode("search_screen").visible = true
    else if index = 1 then
        m.global.findNode("home_screen").visible = true
    else if index = 2 then
        m.global.findNode("live_screen").visible = true
    else if index = 3 then
        m.global.findNode("vod_screen").visible = true
    else if index = 4 then
        m.global.findNode("saved_screen").visible = true
        ' else if index = 5 then
        '     m.global.findNode("podcast_screen").visible = true
    else if index = 5 then
        m.global.findNode("account_screen").visible = true
    ' else if index = 6 then
    end if

end sub


