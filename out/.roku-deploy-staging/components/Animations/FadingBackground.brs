' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

' =============================================================================
' init
' =============================================================================

sub init()

    print "FadingBackground.brs - [Init]"
  
    ' Setting top interfaces
  
    m.background = m.top.findNode("background")
    m.backgroundColor = m.top.findNode("backgroundColor")
    m.oldBackground = m.top.findNode("oldBackground")
  
    ' Rect used to darken the background
  
    m.shade = m.top.findNode("shade")
  
    ' Animations used to transition the old and new background
  
    m.fadeinNewAnimation = m.top.findNode("fadeinNewAnimation")
    m.fadeoutOldAnimation = m.top.findNode("fadeoutOldAnimation")
    m.fadeoutOldInterpolator = m.top.findNode("fadeoutOldInterpolator")
  
    ' Setting observers
  
    m.top.observeField("width", "onSizeChange")
    m.top.observeField("height", "onSizeChange")
  
    m.background.observeField("bitmapWidth", "onBackgroundLoaded")
  
  end sub
  
  ' =============================================================================
  ' onBackgroundUriChange - If background changes (see interface field),
  '                         start animation and populate fields
  ' =============================================================================
  
  sub onBackgroundUriChange()
  
    print "FadingBackground.brs - [onBackgroundUriChange] Fade out old background"
  
    oldUrl = m.background.uri
    m.background.uri = m.top.uri
  
    if oldUrl <> "" then
      m.oldBackground.uri = oldUrl
      m.fadeoutOldInterpolator = [m.background.opacity, 0]
      m.fadeoutOldAnimation.control = "start"
    end if
  
  end sub
  
  ' =============================================================================
  ' onBackgroundLoaded - When Background image loaded, start animation
  ' =============================================================================
  
  sub onBackgroundLoaded()
    print "FadingBackground.brs - [onBackgroundLoaded] Fade in new background bitmapWitdth =" m.background.bitmapWidth
    m.fadeinNewAnimation.control = "start"
  end sub
  
  ' =============================================================================
  ' onSizeChange - If size changed, change children's size
  ' =============================================================================
  
  sub onSizeChange()
  
    print "FadingBackground.brs - [onSizeChange] width =" m.top.width ", height =" m.top.height
  
    size = m.top.size
  
    m.background.width = m.top.width
    m.background.height = m.top.height
  
    m.backgroundColor.width = m.top.width
    m.backgroundColor.height = m.top.height
  
    m.oldBackground.width = m.top.width
    m.oldBackground.height = m.top.height
  
    m.shade.width = m.top.width
    m.shade.height = m.top.height
  
  end sub
  