function parseChannelEntity(jsonString as string) as object
    channelData = ParseJSON(jsonString).data

    parsedChannelData = []
    parsedData = {}
    for each channel in channelData
        channelDataMap = {
            "id": channel["id"],
            "statusId": channel["statusId"],
            "title": channel["title"],
            "description": channel["description"],
            "source" : channel["source"],
            "banner" : channel["banner"],
            "images" : channel["images"],
            "typeId" : channel["typeId"],
            "sources" : channel["sources"]
        }
        parsedChannelData.push(channelDataMap)
    end for
    return parsedChannelData
end function
