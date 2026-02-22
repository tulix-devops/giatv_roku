sub init()
    m.itemposter = m.top.findNode("poster")
    m.posterOverlay = m.top.findNode("posterOverlay")
end sub

sub OnContentSet() ' invoked when item metadata retrieved
    content = m.top.itemContent

    if content.rowItemFocus = true
        ' m.posterOverlayGroup.opacity = 1
        toggleFocus(1)
    else
        ' m.posterOverlayGroup.opacity = 0
        toggleFocus(0)
    end if
    if content <> invalid
        m.top.FindNode("poster").uri = content.hdPosterUrl
    end if
end sub

function toggleFocus(value as integer)
   
    ' if m.top.itemContent.hasFocus()
        scale = 1 + (value * 0.08)
        m.itemposter.scale = [scale, scale]
    ' end if
 
end function

sub showFocus()

    ' if m.top.itemContent.hasFocus()
        ' scale = 1 + (m.top.focusPercent * 0.08)
        ' m.itemposter.scale = [scale, scale]
    ' end if
 

    ' highlightBorder.uri = "pkg:/images/png/shapes/card_active_border.png"
    ' "pkg:/images/png/shapes/inactive_card_shape.png"
end sub



function onKeyEvent(key as string, press as boolean) as boolean
    if press then
        
        if key = "right" or key = "left"
        
            return true
        end if


        return false ' Return true if the key event was handled
    end if
    return false
end function



