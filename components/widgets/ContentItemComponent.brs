sub init()
    m.contentPoster = m.top.findNode("contentPoster")
    m.contentTitle = m.top.findNode("contentTitle")
    m.focusIndicator = m.top.findNode("focusIndicator")
    
    ' Set up focus handling
    m.top.observeField("focusedChild", "onFocusChanged")
end sub

sub updateContent()
    print "ContentItemComponent.brs - [updateContent] Content update triggered"
    content = m.top.itemContent
    print "ContentItemComponent.brs - [updateContent] Content type: " + Type(content).ToStr()
    if content <> invalid
        ' Set title
        if content.title <> invalid
            print "ContentItemComponent.brs - [updateContent] Setting title: " + content.title
            m.contentTitle.text = content.title
        else
            print "ContentItemComponent.brs - [updateContent] No title available"
            m.contentTitle.text = "Unknown Title"
        end if
        
        ' Set poster image
        if content.hdPosterUrl <> invalid and content.hdPosterUrl <> ""
            print "ContentItemComponent.brs - [updateContent] Setting HD poster: " + content.hdPosterUrl
            m.contentPoster.uri = content.hdPosterUrl
        else if content.sdPosterUrl <> invalid and content.sdPosterUrl <> ""
            print "ContentItemComponent.brs - [updateContent] Setting SD poster: " + content.sdPosterUrl
            m.contentPoster.uri = content.sdPosterUrl
        else
            print "ContentItemComponent.brs - [updateContent] No poster URL, using placeholder"
            m.contentPoster.uri = "pkg:/images/png/poster_not_found_220x375.png"
        end if
    end if
end sub

sub onFocusChanged()
    if m.top.hasFocus()
        ' Show focus indicator
        m.focusIndicator.opacity = 0.3
        
        ' Scale up slightly
        scaleAnimation = CreateObject("roSGNode", "Animation")
        scaleAnimation.duration = 0.2
        scaleAnimation.easeFunction = "outQuad"
        
        scaleInterpolator = CreateObject("roSGNode", "Vector2DFieldInterpolator")
        scaleInterpolator.key = [0.0, 1.0]
        scaleInterpolator.keyValue = [[1.0, 1.0], [1.05, 1.05]]
        scaleInterpolator.fieldToInterp = m.top.id + ".scale"
        
        scaleAnimation.appendChild(scaleInterpolator)
        scaleAnimation.control = "start"
    else
        ' Hide focus indicator
        m.focusIndicator.opacity = 0
        
        ' Scale back to normal
        scaleAnimation = CreateObject("roSGNode", "Animation")
        scaleAnimation.duration = 0.2
        scaleAnimation.easeFunction = "outQuad"
        
        scaleInterpolator = CreateObject("roSGNode", "Vector2DFieldInterpolator")
        scaleInterpolator.key = [0.0, 1.0]
        scaleInterpolator.keyValue = [[1.05, 1.05], [1.0, 1.0]]
        scaleInterpolator.fieldToInterp = m.top.id + ".scale"
        
        scaleAnimation.appendChild(scaleInterpolator)
        scaleAnimation.control = "start"
    end if
end sub
