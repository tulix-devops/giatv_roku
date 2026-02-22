' Function to parse actor data
function parseActor(data as object) as object
    actorEntity = []
    for each actor in data
        actorMap = {
            "id": actor["id"],
            "storageRecordId": actor["storageRecordId"],
            "storageRecordTypeId": actor["storageRecordTypeId"],
            "title": actor["title"],
            "description": actor["description"],
            "birthYear": actor["birthYear"]
        }
        actorEntity.push(actorMap)
    end for

    return actorEntity
end function

' Function to parse category data
function parseCategory(data) as object
    categoryEntity = []
    for each cat in data
        catMap = {
            "id": cat["id"],
            "title": cat["title"],
            "menuVisible": cat["menuVisible"],
            "homeVisible": cat["homeVisible"],
        }
        categoryEntity.push(catMap)
    end for
    return categoryEntity
end function

' Function to parse country data
function parseCountry(data) as object

    return {
        "id": data["id"],
        "name": data["name"],
    }
end function


function parseEpisodes(data) as object
    episodeEntity = []
    for each episode in data

        ' print episode
        ' print "Episodes"
        entityMap = {
            "id": episode["id"],
            "videoId": episode["videoId"],
            "title": episode["title"],
            "description": episode["description"],
            "storageRecord": episode["storageRecord"],
            "seasonNumber": episode["seasonNumber"],
            "episodeNumber": episode["episodeNumber"],
            "language": episode["language"],
            "chapters": episode["chapters"],
        }
       
        episodeEntity.push(entityMap)
    end for
    
    return episodeEntity
end function

' Main function to parse VodEntity from a JSON string
function parseHomeVodEntity(jsonString as string) as object
    vodData = ParseJSON(jsonString).data
    print type(vodData)
    print vodData
    print "VodData Type HOME"
    homeData = []
    parsedData = {}
    for each cat in vodData
        print "VOD HOME CAT DATA"
        print cat.data
        print cat.name
        print "WHATS IS CAT DATA FOR VODTA"
        isLiveSection = false
        if cat.name = "Live" 
            isLiveSection = true
        end if
        VodDataByIndex = {
            "isLiveSection": isLiveSection,
            "categoryName": cat.name,
            "VodEntityData": parseVodEntity(cat.data)
        }
        homeData.push(VodDataByIndex)
    end for
    return homeData
end function


function parseVodEntity(jsonString) as object
    vodData = jsonString
    print vodData
    print "Here is Vod Data from cat.data"
    parsedVodEntity = []
    indexId = 0
    for each vod in vodData
        ' episodes = parseEpisodes(vod["episodes"])
        print vod
        print vodData
        print vodData[vod]
        print "Which one of this VodData we need"
        for each vodCatItem in vodData[vod]
            print vodCatItem
            print "Here is Vod CatItem"
            vodEntity = {
                "countryId": vodCatItem["countryId"],
                "description": vodCatItem["description"],
                "id": vodCatItem["id"],
                "indexId": indexId,
                "statusId": vodCatItem["statusId"],
                "title": vodCatItem["title"],
                "type": vodCatItem["type"],
                "typeId": vodCatItem["typeId"],
                "sources" : vodCatItem["sources"],
                "images" : vodCatItem["images"],
                "attributes" : vodCatItem["attributes"],
                "duration" : vodCatItem["duration"],
                "seasons" : vodCatItem["seasons"]
            }
            indexId++
    
            parsedVodEntity.push(vodEntity)
        end for
    
 
    end for
    return parsedVodEntity
end function

' VOD SCREEN DATA PARSER
function parseVodScreenEntity(jsonString, limit) as object
    if ParseJSON(jsonString) = invalid
        return []
    end if
    vodData = ParseJSON(jsonString).data
    parsedVodEntity = []
    indexId = 0
    cnt = 0
    for each vod in vodData
        if limit > 0
            cnt = cnt + 1

            if cnt > limit
                exit for
            end if
        end if

        vodEntity = {
            "countryId": vod["countryId"],
            "description": vod["description"],
            "id": vod["id"],
            "indexId": indexId
            "statusId": vod["statusId"],
            "title": vod["title"],
            "type": vod["type"],
            "typeId": vod["typeId"],
            "images": vod["images"],
            "sources" : vod["sources"],
            "attributes" : vod["attributes"],
            "duration" : vod["duration"],
            "seasons" : vod["seasons"]
        }
        indexId++
        parsedVodEntity.push(vodEntity)
    end for
    return parsedVodEntity
end function