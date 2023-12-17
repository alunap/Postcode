module Postcode

using DataFramesMeta, CSV, Downloads, ZipFile

export locate, location

"Download from the first URL. If that fails try the second, and so on"
const DOWNLOAD_URL = "https://download.geonames.org/export/zip/"

struct location
    countrycode::String
    postalcode::String
    placename::String
    statename::String
    statecode::String
    countyname::String
    countycode::String
    communityname::String
    communitycode::String
    latitude::Float64
    longitude::Float64
    accuracy::Float16
end

const VALID_COUNTRIES = [
    "AD",
    "AR",
    "AS",
    "AT",
    "AU",
    "AX",
    "AZ",
    "BD",
    "BE",
    "BG",
    "BM",
    "BR",
    "BY",
    "CA",
    "CH",
    "CL",
    "CO",
    "CR",
    "CY",
    "CZ",
    "DE",
    "DK",
    "DO",
    "DZ",
    "EE",
    "ES",
    "FI",
    "FM",
    "FO",
    "FR",
    "GB",
    "GF",
    "GG",
    "GL",
    "GP",
    "GT",
    "GU",
    "HR",
    "HT",
    "HU",
    "IE",
    "IM",
    "IN",
    "IS",
    "IT",
    "JE",
    "JP",
    "KR",
    "LI",
    "LK",
    "LT",
    "LU",
    "LV",
    "MC",
    "MD",
    "MH",
    "MK",
    "MP",
    "MQ",
    "MT",
    "MW",
    "MX",
    "MY",
    "NC",
    "NL",
    "NO",
    "NZ",
    "PE",
    "PH",
    "PK",
    "PL",
    "PM",
    "PR",
    "PT",
    "PW",
    "RE",
    "RO",
    "RS",
    "RU",
    "SE",
    "SG",
    "SI",
    "SJ",
    "SK",
    "SM",
    "TH",
    "TR",
    "UA",
    "US",
    "UY",
    "VA",
    "VI",
    "WF",
    "YT",
    "ZA",
]

const NA_VALUES = [
    "",
    "#N/A",
    "#N/A N/A",
    "#NA",
    "-1.#IND",
    "-1.#QNAN",
    "-NaN",
    "-nan",
    "1.#IND",
    "1.#QNAN",
    "<NA>",
    "N/A",
    # "NA", # NA is a valid county code for Naples, Italy
    "NULL",
    "NaN",
    "n/a",
    "nan",
    "null",
]

const headers = ["country", "postcode", "town", "state_name", "state_code", "county_name", "county_code", "community_name", "community_code", "latitude", "longitude", "accuracy"]

const coltypes = Dict("country" => String, "postcode" => String, "town" => String, "state_name" => String, "state_code" => String, "county_name" => String, "county_code" => String, "community_name" => String, "community_code" => String, "latitude" => Float64, "longitude" => Float64, "accuracy" => Int8)

"""
    download(country)

Download the artifact for the given ISO 2-char country code, unzip, and store the lookup dataframe. Answer a dataframe containing the contents of the CSV file.
"""
function download(countryfile)
    url = DOWNLOAD_URL * countryfile
    http_response = Downloads.download(url)
    z = ZipFile.Reader(http_response)
    if contains(countryfile, "full")
        filenum = 1 # all standard zips have a 'readme.txt', except the three full ones
    else
        filenum = countryfile[1] > 'R' ? 1 : 2
    end
    codes = CSV.File(z.files[filenum], header=headers, types=coltypes, missingstring=NA_VALUES) |> DataFrame
    return codes
end

function locate(postcode, country)
    postcode = uppercase(strip(postcode))
    country = uppercase(strip(country))
    if country ∉ VALID_COUNTRIES
        @error "$country is not in the valid list of countries"
    end
    # For GB, CA, and NL there is a more detailed dataset
    if country == "GB"
        if length(postcode) > 3
            dataset = download("GB_full.csv.zip")
        else
            dataset = download("GB.zip")
        end
    elseif country == "CA"
        if length(postcode) > 3
            dataset = download("CA_full.csv.zip")
        else
            dataset = download("CA.zip")
        end
    elseif country == "NL"
        if length(postcode) > 3
            dataset = download("NL_full.csv.zip")
        else
            dataset = download("NL.zip")
        end
    else
        dataset = download(country * ".zip")
    end

    d = @rsubset(dataset, :postcode == postcode)
    if nrow(d) == 0
        return nothing
    end
    loc = location(first(d.country), first(d.postcode), first(d.town), first(d.state_name),
        first(d.state_code), first(d.county_name), first(d.county_code), first(d.community_name),
        first(d.community_code), first(d.latitude), first(d.longitude), first(d.accuracy))
    return loc
end


end
