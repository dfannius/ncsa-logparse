module QC.Integration (tests) where

import Data.Either
import Data.Attoparsec.ByteString.Char8
import qualified Data.ByteString as B
import Data.Either
import Data.Time
import Data.Time.LocalTime (minutesToTimeZone, utc)
import System.Locale (defaultTimeLocale, months)
import Test.Framework.Providers.QuickCheck2 (testProperty)
import Test.QuickCheck
import Web.UAParser

import Parse.Log
import Types
import qualified Utils as U


tests = [ testProperty "parse common log" testCommonLogParser
        , testProperty "parse extended log" testExtendedLogParser]




zt = ZonedTime {
    zonedTimeToLocalTime=LocalTime {
        localDay=fromGregorian 2015 1 12,
        localTimeOfDay=TimeOfDay 20 37 55
    },
    zonedTimeZone=utc
}


uaVal = UAResult {
    uarFamily="Chrome",
    uarV1=Just "46",
    uarV2=Just "0",
    uarV3=Just "2490"
}


osVal = OSResult {
    osrFamily="Mac OS X",
    osrV1=Just "10",
    osrV2=Just "9",
    osrV3=Just "5",
    osrV4=Nothing
}


testCommonLogParser :: Bool
testCommonLogParser = compareLogEntries actual expected
    where
            logLine = "216.74.39.38 - - [12/Jan/2015:20:37:55 +0000] \"GET index.htm HTTP/1.0\" 200 215"
            actual = head $ rights [parseOnly parseAsCommonLogLine logLine]
            expected = LogEntry {
                ip=IP 216 74 39 38,
                identity=Nothing,
                userid=Nothing,
                timestamp=zt,
                method=Just Get,
                url="index.htm",
                proto=Just HTTP,
                protoVer=ProtocolVersion 1 0,
                status=Just 200,
                byteSize=215,
                referrer=Nothing,
                userAgent=Nothing,
                browser=Nothing,
                platform=Nothing
            }


testExtendedLogParser :: Bool
testExtendedLogParser = compareLogEntries actual expected
    where
            logLine = "216.74.39.38 - - [12/Jan/2015:20:37:55 +0000] \"GET index.htm HTTP/1.0\" 200 215 \"http://www.example.com/start.html\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36\""
            actual = head $ rights [parseOnly parseAsExtendedLogLine logLine]
            expected = LogEntry {
                ip=IP 216 74 39 38,
                identity=Nothing,
                userid=Nothing,
                timestamp=zt,
                method=Just Get,
                url="index.htm",
                proto=Just HTTP,
                protoVer=ProtocolVersion 1 0,
                status=Just 200,
                byteSize=215,
                referrer=Just "http://www.example.com/start.html",
                userAgent=Just "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36",
                browser=Just uaVal,
                platform=Just osVal
            }


compareLogEntries :: LogEntry -> LogEntry -> Bool
compareLogEntries expected actual = all (== True) results
    where results =   [ ip actual == ip expected
                      , identity actual == identity expected
                      , userid actual == userid expected
                      , (U.formatZonedTime $ timestamp actual) == (U.formatZonedTime $ timestamp expected)
                      , method actual == method expected
                      , url actual == url expected
                      , proto actual == proto expected
                      , protoVer actual == protoVer expected
                      , status actual == status expected
                      , byteSize actual == byteSize expected
                      , referrer actual == referrer expected
                      , userAgent actual == userAgent expected
                      , browser actual == browser expected
                      , platform actual == platform expected]
