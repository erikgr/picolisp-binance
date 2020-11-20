#
# Functions to interface with the Binance
# cryptocurrency market.
#
# Parameters are supplied as dotted pairs:
#
# H - HTTP headers
# G - GET parameters
# P - POST parameters
#
# Depends on picolisp-https library found here: https://github.com/aw/picolisp-https
#
# todo: keep track of endpoint weights



(setq *binance_api_url* "https://www.binance.com")


[de api-get ( endpoint headers parameters )
    (prinl ">> Binance: GET " endpoint)
    (let (_url (pack *binance_api_url* endpoint "?" parameters))
        (api-callback (https~req-get _url headers NIL) ) ) ]


[de api-post ( endpoint headers parameters postdata )
    (prinl ">> Binance: POST " endpoint)
    (let (_url (pack *binance_api_url* endpoint "?" parameters))
        (api-callback (https~req-post _url headers NIL postdata) ) ) ]


[de api-put ( endpoint headers parameters )
    (prinl ">> Binance: PUT " endpoint)
    (let (_url (pack *binance_api_url* endpoint "?" parameters))
        (api-callback (https~req-put _url headers NIL) ) ) ]


[de api-delete ( endpoint headers parameters )
    (prinl ">> Binance: DELETE " endpoint)
    (let (_url (pack *binance_api_url* endpoint "?" parameters))
        (api-callback (https~req-delete _url headers NIL) ) ) ]


[de api-callback ( req )
    (prinl
        ">> Binance: "
        (find-val "date" (find-val "Headers" req)) " "
        (find-val "Code" req) " "
        (find-val "Message" req)
        (find-val "version" req) " "
        (find-val "Url" req) " " )
    (catch NIL
        (case (find-val "Code" req)
            (200 # OK
                req)
            (429 # request rate limit broken. TODO: increase sleep time here
                (prinl ">> Binance: WARNING: Broke request limit. Increasing sleeptime.")
                (prinl ">> Binance: (btw this isnt really implemented yet)")
                req)
            (418 # Autobanned ---> exit TODO: check ban time and sleep until unbanned
                (prinl ">> Binance: FATAL! Got autobanned, exiting..")
                (bye))
            (400 # malformed request
                (prinl ">> Binance: WARNING! MALFORMED REQUEST!")
                req)
            (500 # internal error
                (prinl ">> Binance: WARNING! INTERNAL ERROR! UNKNOWN END STATE.")
                req)
            (T # anything else 
                (prinl ">> Binance: WARNING: Received unhandled HTTP response: " (find-val "Code" req))
                req) ) ) ]


####################
#                  #
# Public endpoints #
#                  #
####################



# for checking connectivity.
#
[de api-ping ( H )
    (prinl ">> Binance: entering api-ping")
        (let (api-endpoint "/api/v1/ping")
                (api-get api-endpoint H NIL) ) ]


#
#
[de api-servertime ( H )
    (prinl ">> Binance: entered api-servertime")
    (let (api-endpoint "/api/v1/time")
        (api-get api-endpoint H NIL) ) ]

# 
#
#
[de api-limits ( H )
    (prinl ">> Binance: entering api-exchangeinfo")
    (let (api-endpoint "/api/v1/exchangeInfo")
        (api-get api-endpoint H NIL) ) ]


# order book
#
# symbol
# optional: limit // default 100 max 1000 valid 5 10 20 50 100 500 1000
#
[de api-depth ( H G )
    (prinl ">> Binance: entering api-depth")
    (if (require '(symbol) G)
        (let (api-endpoint "/api/v1/depth")
            (api-get api-endpoint H (pack-params G) NIL) ) ) ]


# symbol
# optional: limit //default 500, max 500
#
[de api-trades ( H G )
    (prinl ">> Binance: entering api-trades")
    (if (require '(symbol) G)
        (let (api-endpoint "/api/v1/trades")
            (api-get api-endpoint H (pack-params G) NIL) ) ) ]


# symbol
# optional: limit
# optional: tradeid
#
[de api-historicaltrades ( H G )
    (prinl ">> Binance: entering api-historicaltrades")
    (if (require '(symbol) G)
        (let (api-endpoint "/api/v1/historicalTrades")
            (api-get api-endpoint H (pack-params G) NIL) ) ) ]


# symbol
# optional: fromid
# optional: startTime
# optional: endTime
# optional: limit //default 500 max 500
#
[de api-aggregatetrades ( H G )
    (prinl ">> Binance: entering api-aggregatetrades")
    (if (require '(symbol) G)
        (let (api-endpoint "/api/v1/aggTrades")
            (api-get api-endpoint H (pack-params G) NIL) ) ) ]


# symbol // technically not required
#        // but very expensive if omitted
#
[de api-24hticker ( H G )
    (prinl ">> Binance: entering api-24hticker")
    (if (require '(symbol) G)
        (let (api-endpoint "/api/v1/ticker/24hr")
            (api-get api-endpoint H (pack-params G) NIL) ) ) ]


# optional: symbol
#
[de api-priceticker ( H G )
    (prinl ">> Binance: entering api-pricetricker")
    (let (api-endpoint "/api/v3/ticker/price")
        (api-get api-endpoint H (pack-params G) NIL) ) ]


# optional: symbol
#
[de api-orderbookticker ( H G )
    (prinl ">> Binance: Entering api-orderbookticker")
    (let (api-endpoint "/api/v3/ticker/bookTicker")
        (api-get api-endpoint H (pack-params G) NIL) ) ]


# symbol
# interval
# optional: limit
# optional: start time
# optional: end time
#
[de api-candlesticks ( H G )
    (prinl ">> Binance: Entering api-candlesticks")
    (if (require '(symbol interval) G)
        (let (api-endpoint "/api/v1/klines")
            (api-get api-endpoint H (pack-params G) NIL) ) ) ]



###########################
#                         #
# Account endpoints       #
#                         #
# These require signature #
#                         #
###########################


# symbol
# side
# type
# quantity
# timestamp
# optional: timeInForce
# optional: price
# optional: newClientOrderId
# optional: stopPrice
# optional: icebergQty
# optional: newOrderRespType
# optional: recvWindow
#
[de api-order ( H G P )
    (prinl ">> Binance: Entering api-order")
    (if (require '(symbol side type quantity timestamp) (append G P))
        (let (api-endpoint "/api/v3/order")
            (api-post api-endpoint H (pack-params G) NIL (pack-params P) ) ) ) ]


# Same as above, but does not
# send the order to the matching
# engine.
#
[de api-testorder ( H G P )
    (prinl ">> Binance: Entering api-test-order")
    (if (require '(symbol side type quantity timestamp) (append G P))
        (let (api-endpoint "/api/v3/order/test")
            (api-post api-endpoint H (pack-params G) NIL (pack-params P) ) ) ) ]


# symbol
# timestamp
# optional: orderId
# optional: origClientOrderId
# optional: recvWindow
#
[de api-queryorder ( H G P )
    (prinl ">> Binance: Entering api-queryorder")
    (if (require '(symbol timestamp) (append G P))
        (let (api-endpoint "/api/v3/order")
            (api-get api-endpoint H (pack-params G) NIL (pack-params P) ) ) ) ]


# symbol
# timestamp
# optional: orderId
# optional: origClientOrderId
# optional: newClientOrderId
# optional: recvWindow
#
[de api-cancelorder ( H G P )
    (prinl ">> Binance: Entering api-cancelorder")
    (if (require '(symbol timestamp) (append G P))
        (let (api-endpoint "/api/v3/order")
            (api-delete api-endpoint H (pack-params G) NIL (pack-params P) ) ) ) ]


# timestamp
# optional: symbol
# optional: recvWindow
#
[de api-openorders ( H G )
    (prinl ">> Binance: Entering api-openorders")
    (if (require '(timestamp) G)
        (let (api-endpoint "/api/v3/openOrders")
            (api-get api-endpoint H (pack-params G) NIL) ) ) ]


# timestamp
# optional: recvWindow
#
[de api-account ( H G )
    (prinl ">> Binance: Entering api-account")
    (if (require '(timestamp) G)
        (let (api-endpoint "/api/v3/account")
            (api-get api-endpoint H (pack-params G) NIL) ) ) ]


# symbol
# timestamp
# optional: recvWindow
# optional: fromId
# optional: limit
#
[de api-mytrades ( H G )
    (prinl ">> Binance: Entering api-mytrades")
    (if (require '(timestamp) G)
        (let (api-endpoint "/api/v3/account")
            (api-get api-endpoint H (pack-params G) NIL) ) ) ]
