function parseCategoryEntity(jsonString as string) as object
    
    categoryData = ParseJSON(jsonString).data

    parsedCategoryData = []
    parsedData = {}
    for each category in categoryData
        categoryDataMap = {
            "id": category["id"],
            "name": category["name"]
        }
        parsedCategoryData.push(categoryDataMap)
    end for
    return parsedCategoryData
end function