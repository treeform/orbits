## Downloads planet feature (such as craters) with names and location from planetarynames.wr.usgs.gov

import strformat, strutils
import utils

var url = (&"""https://planetarynames.wr.usgs.gov/SearchResults?
  feature=
  &system=
  &target=
  &featureType=
  &northernLatitude=
  &southernLatitude=
  &westernLongitude=
  &easternLongitude=
  &wellKnownText=
  &minFeatureDiameter=
  &maxFeatureDiameter=
  &beginDate=
  &endDate=
  &approvalStatus=
  &continent=
  &ethnicity=
  &reference=
  &sort_asc=false
  &sort_column=diameter
  &is_positive_east=true
  &is_0_360=true
  &is_planetographic=false
  &displayType=CSV
  &pageStart=0
  &resultsPerPage=50
  &featureIDColumn=true
  &featureNameColumn=true
  &cleanFeatureNameColumn=true
  &targetColumn=true
  &diameterColumn=true
  &centerLatLonColumn=true
  &latLonColumn=true
  &coordSystemColumn=true
  &contEthColumn=true
  &featureTypeColumn=true
  &featureTypeCodeColumn=true
  &quadColumn=true
  &approvalStatusColumn=true
  &approvalDateColumn=true
  &referenceColumn=true
  &originColumn=true
  &additionalInfoColumn=true
  &lastUpdatedColumn=true
""").replace(" ", "").replace("\n", "")

downloadFileIfNotExists(url, "db/feature.csv")
writeFile("db/feature.csv", readFile("db/feature.csv").strip())


