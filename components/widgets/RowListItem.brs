sub init()
  m.itemposter = m.top.findNode("poster")
  m.posterOverlay = m.top.findNode("posterOverlay")
  m.posterOverlayGroup = m.top.findNode("posterOverlayGroup")
  m.episodeText = m.top.findNode("episodeText")
end sub

sub OnContentSet() ' invoked when item metadata retrieved
  content = m.top.itemContent
  ' m.top.itemContent
  content.observeField("keyPressed", "onKeyPressed")
  if content <> invalid
      if content.isLiveChannel <> invalid
          if content.isLiveChannel = true
              m.itemposter.width = 442
              m.itemposter.height = 310
              m.itemposter.loadWidth = 442
              m.itemposter.loadHeight = 310
          end if
      end if

      ' if content.rowItemFocus = true
      '     m.posterOverlayGroup.opacity = 1
      ' else
      '     m.posterOverlayGroup.opacity = 0
      ' end if
      setEpisodeText(content)
      m.top.FindNode("poster").uri = content.hdPosterUrl
  end if
end sub

sub setEpisodeText(content)
  if content.data.title <> invalid
      title = content.data.title
      if len(title) > 27
          title = left(title, 24) + "..."
      end if
      m.episodeText.text = title
  else
      m.episodeText.text = ""
  end if
end sub

sub showFocus()
end sub