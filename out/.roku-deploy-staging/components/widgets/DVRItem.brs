' =============================================================================
' init
' =============================================================================

sub init()
  m.hasFocus = true
  m.poster = m.top.findNode("poster")
  m.posterBackground = m.top.findNode("posterBackground")
  m.backgroundRectangle = m.top.findNode("backgroundRectangle")
  'm.backgroundTopBorderRectangle = m.top.findNode("backgroundTopBorderRectangle")
  m.contentRectangle = m.top.findNode("contentRectangle")
  m.detailGroup = m.top.findNode("detailGroup")
  'm.detailGroupAnimation = m.top.findNode("detailGroupAnimation")
  m.titleLabel = m.top.findNode("titleLabel")
  m.titleShadowLabel = m.top.findNode("titleShadowLabel")
  m.descriptionLabel = m.top.findNode("descriptionLabel")
  m.descriptionShadowLabel = m.top.findNode("descriptionShadowLabel")
  m.detailMaskGroup = m.top.findNode("detailMaskGroup")

  m.titleLabel.font.size = 30
  m.titleShadowLabel.font.size = 30

  m.descriptionLabel.font.size = 22
  m.descriptionShadowLabel.font.size = 22

end sub

' =============================================================================
' itemContentChanged - Called when content is assigned to the item
' =============================================================================

sub itemContentChanged()


  m.poster.loadDisplayMode = "scaleToFill"

  title = m.top.itemContent.title
  ' pubDate = m.top.itemContent.pubDate

  if m.top.itemContent.isLiveParent = true then
    pubDate = "LIVE"
  else
    pubDate = m.top.itemContent.from + " - " + m.top.itemContent.to
    
  end if
  ' pubDate = m.top.itemContent.from + " - " + m.top.itemContent.to

  ' When the item has focus and the focusPercent changes, then focus is being removed.
  ' Clear the local focus flag for the item  and stop watching for key color changes
  ' (the key color can change via OptionsScreen).
  m.hasFocus = true

  'm.backgroundRectangle.color = m.global.keyColor

  m.titleLabel.text = title
  m.titleShadowLabel.text = title
  'm.titleShadowLabel.color = m.global.keyColor

  m.descriptionLabel.text = pubDate
  m.descriptionShadowLabel.text = pubDate
  'm.descriptionShadowLabel.color = m.global.keyColor

  m.titleLabel.font.size = 30
  m.titleShadowLabel.font.size = 30

  m.descriptionLabel.font.size = 22
  m.descriptionShadowLabel.font.size = 22

  m.backgroundRectangle.color = "0x00000000"
  'm.detailGroup.opacity = 0.0
  'm.detailGroup.visible = true
  'm.detailGroupAnimation.control = "start"

  'm.global.observeField("keyColor", "handleKeyColorChanged")

  if m.top.height < 400 and m.top.width < 400
    m.poster.loadWidth = 300
    m.poster.loadHeight = 150
  end if

  updateLayout()

  ' m.poster.uri = m.top.itemContent.HDPOSTERURL
  print m.top.itemContent
  print "Here is a itemContent"
  m.poster.uri = m.top.itemContent.thumbnail


end sub

' =============================================================================
' itemFocusChanged
'
'   focusPercent - Message sent to the row item that is losing focus and the row item gaining focus
'   rowFocusPercent - Message sent to multiple items in the row that is losing focus and multiple items in the row item gaining focus
'
' =============================================================================

sub itemFocusChanged(message as object)

  ' print "DVRItem.brs [itemFocusChanged] hasFocus = " m.hasFocus ", focus =" message.getData() ", field = " message.getField()
  focusPercent = message.getData()
  title = m.top.itemContent.title
  ' pubDate = m.top.itemContent.pubDate
  pubDate = m.top.itemContent.from + " - " + m.top.itemContent.to

  ' When the item has focus and the focusPercent changes, then focus is being removed.
  ' Clear the local focus flag for the item  and stop watching for key color changes
  ' (the key color can change via OptionsScreen).
  m.hasFocus = true

  'm.backgroundRectangle.color = m.global.keyColor

  m.titleLabel.text = title
  m.titleShadowLabel.text = title
  'm.titleShadowLabel.color = m.global.keyColor

  m.descriptionLabel.text = pubDate
  m.descriptionShadowLabel.text = pubDate
  'm.descriptionShadowLabel.color = m.global.keyColor

  m.titleLabel.font.size = 30
  m.titleShadowLabel.font.size = 30

  m.descriptionLabel.font.size = 22
  m.descriptionShadowLabel.font.size = 22


  'm.detailGroup.opacity = 0.0
  'm.detailGroup.visible = true
  'm.detailGroupAnimation.control = "start"

  'm.global.observeField("keyColor", "handleKeyColorChanged")
  if m.hasFocus and focusPercent < 1.0 then

    print "DVRItem.brs [itemFocusChanged] Lost focus on " message.getField() " (" title ")"

    'm.hasFocus = false
    'm.detailGroup.visible = false

    'm.global.unobserveField("keyColor")

    ' Else if the item is not focused and becomes fully focused (focusPercent = 1),
    ' then set the local focus flag and animate in the detail overlay. Also, begin
    ' watching the key color in case the user changes it via OptionsScreen.


  else if not m.hasFocus and focusPercent = 1 and message.getField() = "focusPercent" then

    print "DVRItem.brs [itemFocusChanged] Gained focus on focusPercent (" title ")"



  end if

end sub

' =============================================================================
' handleKeyColorChanged - Called when the item has focus and the user changes
'                         the keyColor via OptionsScreen.
' =============================================================================

sub handleKeyColorChanged()
  'm.backgroundRectangle.color = m.global.keyColor
  'm.titleShadowLabel.color = m.global.keyColor
  'm.descriptionShadowLabel.color = m.global.keyColor
end sub

' =============================================================================
' hasFocus
' =============================================================================

sub hasFocus(isFocused as boolean)

  print "-------------------------------\n"

  ' print "DVRItem.brs [itemFocusChanged] field = " message.getField() ", value =" message.getData() ", uri = " m.poster.uri
  print "DVRItem.brs [itemFocusChanged] isFocused = " isFocused ", uri = " m.poster.uri

end sub

' =============================================================================
' updateLayout - Called when the item's width or height changes, or when
'                the function itemContentChanged is called
' =============================================================================

sub updateLayout()

  ' print "DVRItem.brs - [updateLayout] "

  if m.top.height > 0 and m.top.width > 0 then
    

    
    m.poster.width = m.top.width
    m.poster.height = m.top.height

    m.posterBackground.width = m.top.width
    m.posterBackground.height = m.top.height

    if m.top.height > 400 then
      contentReservedHeight = m.top.height * .25
      m.titleLabel.font = "font:MediumBoldSystemFont"
      m.titleShadowLabel.font = "font:MediumBoldSystemFont"
      m.descriptionLabel.font = "font:MediumBoldSystemFont"
      m.descriptionShadowLabel.font = "font:MediumBoldSystemFont"
    else
      contentReservedHeight = 100
      m.titleLabel.font = "font:SmallBoldSystemFont"
      m.titleShadowLabel.font = "font:SmallBoldSystemFont"
      m.descriptionLabel.font = "font:SmallBoldSystemFont"
      m.descriptionShadowLabel.font = "font:SmallBoldSystemFont"
    end if

    contentReservedHeight = contentReservedHeight - 20

    detailGroupHeight = contentReservedHeight
    detailGroupWidth = m.top.width
    detailGroupYOffset = m.top.height + 0

    m.detailGroup.width = detailGroupWidth
    m.detailGroup.height = detailGroupHeight
    m.detailGroup.translation = [0, detailGroupYOffset]

    m.backgroundRectangle.width = detailGroupWidth
    m.backgroundRectangle.height = detailGroupHeight
    'm.backgroundTopBorderRectangle.width  = detailGroupWidth

    m.detailMaskGroup.width = detailGroupWidth
    m.detailMaskGroup.height = detailGroupHeight
    m.detailMaskGroup.maskSize = [detailGroupWidth, detailGroupHeight]

    contentHeight = detailGroupHeight * 0.96
    contentBorder = detailGroupHeight * 0.04
    contentWidth = detailGroupWidth

    '    print "DVRItem.brs - [updateLayout] contentWidth " contentWidth
    '    print "DVRItem.brs - [updateLayout] contentHeight " contentHeight
    '    print "DVRItem.brs - [updateLayout] contentBorder " contentBorder

    m.contentRectangle.width = contentWidth
    m.contentRectangle.height = contentHeight
    m.contentRectangle.translation = [0, contentBorder]

    m.titleLabel.width = contentWidth - 10
    '    m.titleLabel.height = contentHeight
    m.titleLabel.height = 48
    m.titleLabel.translation = [5, contentBorder + 10]

    m.descriptionLabel.width = contentWidth - 10
    '    m.descriptionLabel.height = contentHeight
    m.descriptionLabel.height = 48
    m.descriptionLabel.translation = [5, contentBorder + 20]

    shadowYOffset = contentBorder + 2

    m.titleShadowLabel.width = contentWidth - 10
    'm.titleShadowLabel.height = contentHeight
    m.titleShadowLabel.height = 48
    m.titleShadowLabel.translation = [7, shadowYOffset + 10]

    m.descriptionShadowLabel.width = contentWidth - 10
    'm.descriptionShadowLabel.height = contentHeight
    m.descriptionShadowLabel.height = 48
    m.descriptionShadowLabel.translation = [7, shadowYOffset + 20]

    m.titleLabel.font.size = 30
    m.titleShadowLabel.font.size = 30

    m.descriptionLabel.font.size = 22
    m.descriptionShadowLabel.font.size = 22


  end if

end sub
