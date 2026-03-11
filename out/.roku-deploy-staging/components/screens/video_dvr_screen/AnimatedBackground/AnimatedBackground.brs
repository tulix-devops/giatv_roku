 ' =============================================================================
 ' init - Set top interfaces
 ' =============================================================================

 sub init()

    print "AnimatedBackground.brs - [init]"
  
    m.top.isFullScreen  = "true"
    m.top.panelSize = "true"
  
    m.top.observeField("visible", "onVisibleChange")
  
    m.poster = m.top.findNode("poster")
    m.poster2 = m.top.findNode("poster2")
    m.posterAnimation = m.top.findNode("posterParallelAnimation")
  
  end sub
  
  ' =============================================================================
  ' onImageChanged
  ' =============================================================================
  
  sub onImageChanged()
  
    m.imageUrl = m.top.imageURL
  
    print "AnimatedBackground.brs - [onImageChanged] " m.imageUrl
  
    if m.imageUrl <> invalid then
  
      m.poster.uri = m.imageUrl
      m.poster2.uri = m.imageUrl
  
      m.poster.opacity = "0.0"
      m.poster2.opacity = "0.2"
  
      ' Start the animation of the background images
  
      if m.top.visible then
        m.posterAnimation.control = "start"
      end if
  
    end if
  
  end sub
  
  ' =============================================================================
  ' onVisibleChange
  ' =============================================================================
  
  sub onVisibleChange()
  
    if m.imageUrl <> invalid and m.top.visible = true then
  
      print "AnimationBackground.brs - [onVisibleChange] Visible"
  
      if m.imageUrl <> invalid and Len(m.imageUrl) > 0 then
        m.posterAnimation.control = "start"
      end if
  
    else
  
      print "AnimationBackground.brs - [onVisibleChange] Not visible"
  
      m.posterAnimation.control = "stop"
  
    end if
  
  end sub
  