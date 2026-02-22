sub init()
    print "NavigationItemComponent.brs - [init] Initializing navigation item component"
    
    ' Get references to UI elements
    m.focusBackground = m.top.findNode("focusBackground")
    m.itemBackground = m.top.findNode("itemBackground")
    m.navTitle = m.top.findNode("navTitle")
    
    ' Set up focus observer
    m.top.observeField("focused", "onFocusChanged")
    
    ' Initialize as focusable
    m.top.focusable = true
end sub

sub OnContentSet()
    print "NavigationItemComponent.brs - [OnContentSet] Called"
    
    content = m.top.itemContent
    if content = invalid
        print "NavigationItemComponent.brs - [OnContentSet] Content is invalid"
        return
    end if
    
    ' Set navigation title
    if content.title <> invalid and content.title <> ""
        m.navTitle.text = content.title
        print "NavigationItemComponent.brs - [OnContentSet] Navigation title: " + content.title
    else
        m.navTitle.text = "Navigation Item"
    end if
end sub

sub onFocusChanged()
    if m.top.focused
        print "NavigationItemComponent.brs - [onFocusChanged] Item gained focus: " + m.navTitle.text
        ' Show focus background
        m.focusBackground.visible = true
        ' Make text more prominent
        m.navTitle.color = "#f16667"
        if m.navTitle.font <> invalid
            m.navTitle.font.size = 25
        end if
        ' Slightly brighten the background
        m.itemBackground.opacity = 1.0
    else
        print "NavigationItemComponent.brs - [onFocusChanged] Item lost focus: " + m.navTitle.text
        ' Hide focus background
        m.focusBackground.visible = false
        ' Reset text to normal
        m.navTitle.color = "#ffffff"
        if m.navTitle.font <> invalid
            m.navTitle.font.size = 22
        end if
        ' Return background to normal
        m.itemBackground.opacity = 0.8
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if press
        if key = "OK"
            print "NavigationItemComponent.brs - [onKeyEvent] OK pressed on: " + m.navTitle.text
            ' Let parent handle the selection
            return false
        end if
    end if
    return false
end function