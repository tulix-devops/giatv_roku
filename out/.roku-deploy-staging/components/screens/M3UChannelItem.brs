sub init()
    m.background = m.top.findNode("background")
    m.focusBorder = m.top.findNode("focusBorder")
    m.innerBackground = m.top.findNode("innerBackground")
    m.channelPoster = m.top.findNode("channelPoster")
    m.titleBg = m.top.findNode("titleBg")
    m.bottomTitle = m.top.findNode("bottomTitle")
    m.categoryLabel = m.top.findNode("categoryLabel")
end sub

sub onContentChanged()
    content = m.top.itemContent
    if content = invalid then return

    ' Title
    channelTitle = "Unknown Channel"
    if content.title <> invalid and content.title <> ""
        channelTitle = content.title
    end if
    if m.bottomTitle <> invalid then m.bottomTitle.text = channelTitle

    ' Category subtitle
    if m.categoryLabel <> invalid
        if content.category <> invalid and content.category <> ""
            m.categoryLabel.text = content.category
        else
            m.categoryLabel.text = ""
        end if
    end if

    ' Poster
    posterUrl = ""
    if content.HDPosterUrl <> invalid and content.HDPosterUrl <> "" then posterUrl = content.HDPosterUrl
    if posterUrl = "" and content.hdPosterUrl <> invalid and content.hdPosterUrl <> "" then posterUrl = content.hdPosterUrl
    if posterUrl = "" and content.logo <> invalid and content.logo <> "" then posterUrl = content.logo

    if m.channelPoster <> invalid
        if posterUrl <> ""
            m.channelPoster.uri = posterUrl
        else
            m.channelPoster.uri = "pkg:/images/png/poster_not_found_350x245.png"
        end if
    end if
end sub

sub onFocusPercentChanged()
    focusPercent = m.top.focusPercent

    ' if focusPercent > 0.5
    '     ' Focused state - simple white border
    '     if m.focusBorder <> invalid then m.focusBorder.opacity = 1.0
    '     if m.titleBg <> invalid then m.titleBg.color = "#1e2640"
    '     if m.innerBackground <> invalid then m.innerBackground.color = "#1e2640"
    '     if m.bottomTitle <> invalid then m.bottomTitle.color = "#ffffff"
    '     if m.categoryLabel <> invalid then m.categoryLabel.color = "#cccccc"
    ' else
    '     ' Unfocused state
    '     if m.focusBorder <> invalid then m.focusBorder.opacity = 0.0
    '     if m.titleBg <> invalid then m.titleBg.color = "#0f1623"
    '     if m.innerBackground <> invalid then m.innerBackground.color = "#131720"
    '     if m.bottomTitle <> invalid then m.bottomTitle.color = "#cccccc"
    '     if m.categoryLabel <> invalid then m.categoryLabel.color = "#9ca3af"
    ' end if
end sub
