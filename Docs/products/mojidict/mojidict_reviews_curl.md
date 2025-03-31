curl 'https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/1021094295/platforms/ios/reviews?limit=100&sort=REVIEW_SORT_ORDER_HELPFUL_SUMMARY_ALIGNED&rating=RATING_2' \
  -H 'accept: application/vnd.api+json, application/json, text/csv' \
  -H 'accept-language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7' \
  -H 'content-type: application/json' \
  -b 'geo=HK; s_fid=16FB895008CAB6C1-0E94340A7EF54FD4; s_cc=true; s_vi=[CS]v1|33F3BA190FE22EF3-40000156404AF2AA[CE]; s_sq=%5B%5BB%5D%5D; dslang=CN-ZH; site=CHN; myacinfo=DAWTKNV323952cf8084a204fb20ab2508441a07d02d38a7dd94ba26d3900dc07796e907f4ba7fd4a497def3ae905a0849608e9eb2286f8020512e1dbd8d68e96511f50c7c7bfb77de4b00face7625178c354dc929ecf059b80769f2dfe3b3f408cb9b42964637068e9f94db64f2cb0460ccea415cb3d5dd9f963e00b0455df6b28675c374b0eeb536f39ada3982186e89eae65428df5d110a220c8b4438a6a8b9163aeaf09f1287a79fadd73e5aa46e330dc4439514dd52c3a87e0e92cb4042606941d2aa644099586c2c90cda1b4b1e225f6b8c6e15632bcaf17aae58831bbbb511dfad89de3c046faa8c17f5fe0975495926eb3e16857956edcae7e663ed3ad9c5bef88d12547460ada7032047d74772a474ad82a7deaeb8d245919f107ae5b5ff981c9f988b85a967e2aeb6c713553bfe03749a6795ce9752c0a7be0eb16fb5aa85e93a749af2041d76fed8b167fd862247332b00717c87479e3eb011a3bc1bc9b15e14628e52af986cd724cacae904330281b6e82c7c697e38277cd2bdb9af59956ce0431994c620c90ec542e6cf1a92a9531fadee2109aba65f6de2f5197c9894a75cde07a18df63eee243f018d1120965475729d8830a55890c646ec295bcfeb06c9c0781ffeb3baf9a02be7eb82a18b7ec8500a9512c518f0b527c034945ebe26fef4cb513a307af21b25fd7e5e36a5574277c4254faeec77fa25f598263632ff2ab956061c9e81990f64717c7095bdf8fad597e81b357217de137a575f8249cbfec5a9f82aff1f102aa5ff81d39711eeb9e1a807c41c5abaec129419478f6d75be2f8dcdfcc32e393fd891e9eeff6ec533e2e4e0d63ace12d22707e406857d5cbae6739456b9847f52b96592896d52693f321b863ecf62b38fc2be3d08343f1825eb585a47V3; dc=mr; itctx=eyJjcCI6IjNiNTg0OGMyLTNkNDMtNDQ4Mi05ZTQ1LTMyNDQ0ZTI5ZWMyMSIsImRzIjoxODEyNDI3ODM5LCJleCI6IjIwMjUtMy0zMSAyMzoyMzo1NyJ9|n3c9g8nts82fmi1p3mncmhilei|7E54_rh_079b9IDX7frAOUZgd-I; itcdq=0; dqsid=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3NDM0MzQ2NDgsImp0aSI6Imc1QWZ3dE1NNUViMDlrZkFYd3RiYmcifQ.TNg1FDAGEC0i_oAk9_MAEckhI1VUwnl89XnVIhMjzuc; wosid=bTECv06oZ0z4vbhgZDGvDw; woinst=220069' \
  -H 'priority: u=1, i' \
  -H 'referer: https://appstoreconnect.apple.com/apps/1021094295/distribution/ratings/ios' \
  -H 'sec-ch-ua: "Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-origin' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36' \
  -H 'x-csrf-itc: [asc-ui]'


  sort：
  最新评论：REVIEW_SORT_ORDER_MOST_RECENT
  最有帮助的评论：REVIEW_SORT_ORDER_HELPFUL_SUMMARY_ALIGNED
  高分好评：REVIEW_SORT_ORDER_RATING_DESC
  低分差评：REVIEW_SORT_ORDER_RATING_ASC

  rating：
  1星：RATING_1
  2星：RATING_2
  3星：RATING_3
  4星：RATING_4
  5星：RATING_5

  limit：
  1-200

  返回数据示例：
  {"data":{"reviewCount":6197,"reviews":[{"value":{"id":12373705799,"rating":2,"title":"读音这么卡啥意思呢","review":"我请问一下 也是充了会员使用背词功能  例句点一下卡一下  使用体验十分糟糕 一句话 读音都听不全  第一遍在这个音卡  下一遍可能在另一个音卡  希望可以改进 词语更是卡 像网络无法加载的那种卡顿","created":null,"nickname":"e啥意思","storeFront":"CN","appVersionString":"8.13.0","lastModified":1740929665000,"helpfulViews":0,"totalViews":0,"edited":false,"developerResponse":null},"isEditable":false,"isRequired":false,"errorKeys":null}]},"messages":{"warn":null,"error":null,"info":null},"statusCode":"SUCCESS"}