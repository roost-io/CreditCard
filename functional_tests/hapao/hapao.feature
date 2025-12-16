Feature: ניהול בקשה לאחזור פרטי כרטיס – generateOtp ו-otpByToken (MS: restore-details-gw)

  # API Tests
  Background:
    Given כתובת הבסיס של ה-API מוגדרת במשתנה סביבה 'BASE_URL'
    And כתובת הבסיס למתפעלת כאל מוגדרת במשתנה סביבה 'CAL_BASE_URL' כ-'https://tst-api.cal-online.co.il/PartnerAuthentication.Api'
    And כתובת הבסיס למתפעלת ישראכרט מוגדרת במשתנה סביבה 'ISRC_BASE_URL' כ-'https://preprod.api.isracard.co.il/isracard/preprod'
    And כותרת Authorization לרמת הרשאה CA מוגדרת עם ערך תקין
    And מוגדרות הכותרות הבאות לשירות:
      | header                  | value        |
      | Content-Type            | application/json |
      | variousChannelTypeCode  | 10001        |
      | bankNumber              | 012          |
      | branchNumber            | 123          |
      | accountNumber           | 1234567      |
      | partySerialId           | 12345678901  |
      | partyShortId            | 012345678    |
      | partyIdTypeCode         | 1            |
      | countryId               | 212          |

  @api @cal @otp
  Scenario Outline: הקמת בקשה OTP – כאל (SMS/IVR) – ניתוב, מיפוי שדות ובדיקת זמן תגובה
    Given השירות זמין וההרשאות בתוקף
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/otp' עם גוף:
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 3,
        "creditCardSerialId": "abcdef_1234_abcd_5678_90ab_cdef_1234",
        "cardIdServiceProvider": "1234567890123456789",
        "smsByVoice": <smsByVoice>,
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002"
      }
      """
    And המערכת מפעילה קריאה חיצונית POST אל "{CAL_BASE_URL}/api/SendOtp/sendOTP" עם כותרת 'x-access-token' תקינה וגוף:
      """
      {
        "CustomerDetails": {
          "idNumber": "012345678",
          "CustomerIdType": 1
        },
        "cardInfo": {
          "cardId": "1234567890123456789"
        },
        "message": {
          "smsTemplate": 0,
          "smsSender": "",
          "smsByVoice": <smsByVoice>
        }
      }
      """
    Then תגובת המתפעלת מתקבלת בתוך פחות מ-5000ms
    And התקבל קוד סטטוס HTTP 200 מהמתפעלת עם StatusCode=1
    And תגובת השירות היא HTTP 200 וללא errors
    And הגוף כולל את השדות otpToken ו-phoneNumber
    And orderId בתשובה זהה לערך שנשלח בגוף הבקשה

    Examples:
      | smsByVoice |
      | 0          |
      | 1          |

  @api @isracard @otp
  Scenario Outline: הקמת בקשה OTP – ישראכרט (SMS/IVR) – שני שלבים (token ואז send) כולל מיפוי CYYMMDD ו-alpha2CountryCode
    Given השירות זמין וההרשאות בתוקף
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/otp' עם גוף:
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 1,
        "creditCardSerialId": "abcdef_1234_abcd_5678_90ab_cdef_1234",
        "cardSuffix": "1234",
        "birthDate": "15/04/1998",
        "smsByVoice": <smsByVoice>,
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002",
        "alpha2CountryCode": "IL"
      }
      """
    And המערכת מפעילה קריאה חיצונית POST אל "{ISRC_BASE_URL}/authorization/token/v1.2.0/byIdAndDateOfBirth" עם גוף המכיל:
      """
      {
        "tokenPostRequest": {
          "requestId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002",
          "requestTimeStamp": "<yyyy-MM-dd-HH.mm.ss.SSSSSS@Asia/Jerusalem>",
          "idNumber": "012345678",
          "idCode": 1,
          "cardLastFourDigits": "1234",
          "companyCode": "B",
          "dateOfBirth": "0980415",
          "activityType": 101,
          "alpha2CountryCode": "IL",
          "bankCode": "012"
        }
      }
      """
    And מתקבל token תקין מהשלב הראשון
    And המערכת מפעילה קריאה חיצונית POST אל "{ISRC_BASE_URL}/authorization/otpByToken/v1.3.0/send" עם גוף:
      """
      {
        "requestGeneralHeader": {
          "requestId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002"
        },
        "tokenRequest": {
          "authorizationToken": "<token>"
        },
        "deliveryMethod": <deliveryMethod>
      }
      """
    Then התקבל קוד סטטוס HTTP 200 מהשלב השני
    And תגובת השירות היא HTTP 200 וללא errors
    And הגוף כולל את השדות otpToken ו-phoneNumber (maskedCellphoneNumber)
    And orderId בתשובה זהה לערך שנשלח בגוף הבקשה

    Examples:
      | smsByVoice | deliveryMethod |
      | 0          | 0              |
      | 1          | 1              |

  @api @max @otp
  Scenario Outline: ניתוב ל-MAX – הקמת OTP ובדיקת החזרת תשובה/שגיאה
    Given השירות זמין וההרשאות בתוקף
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/otp' עם גוף:
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 2,
        "creditCardSerialId": "abcdef_1234_abcd_5678_90ab_cdef_1234",
        "cardIdServiceProvider": "1234567890123456789",
        "smsByVoice": 0,
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002"
      }
      """
    And אני מאמת שהמערכת ניתבה לפעילות מול מתפעלת MAX והפעילה את נקודת הקצה של MAX
    Then תגובת השירות היא HTTP <expectedHttp> ובה הגוף משקף את תשובת MAX (שדות otpToken/phoneNumber במקרה הצלחה או גוף שגיאה במקרה כישלון)

    Examples:
      | expectedHttp |
      | 200          |
      | 400          |

  @api @validation @otp
  Scenario Outline: ולידציות קלט generateOtp – שדות חסרים/לא תקינים (Id=7)
    Given השירות זמין וההרשאות בתוקף
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/otp' עם גוף:
      """
      {
        "activityTypeCode": <activityTypeCode>,
        "cardIssuingSpCode": <cardIssuingSpCode>,
        "creditCardSerialId": "<creditCardSerialId>",
        "cardIdServiceProvider": "<cardIdServiceProvider>",
        "cardSuffix": "<cardSuffix>",
        "birthDate": "<birthDate>",
        "smsByVoice": <smsByVoice>,
        "orderId": "<orderId>",
        "alpha2CountryCode": "<alpha2CountryCode>"
      }
      """
    And אם הערך '<missingField>' שונה מ-'none' אני מסיר את השדה '<missingField>' מהגוף לפני השליחה
    Then תגובת השירות היא HTTP 400
    And השדה errors כולל id=7 עם הודעה מתאימה

    Examples:
      | missingField         | activityTypeCode | cardIssuingSpCode | creditCardSerialId                               | cardIdServiceProvider    | cardSuffix | birthDate    | smsByVoice | orderId                                   | alpha2CountryCode |
      | cardIssuingSpCode    | 101              | 3                 | abcdef_1234_abcd_5678_90ab_cdef_1234             | 1234567890123456789      |            |              | 0          | a3e9f7d2-4b5c-11ee-be56-0242ac120002      |                   |
      | none                 | 101              | 4                 | abcdef_1234_abcd_5678_90ab_cdef_1234             | 1234567890123456789      |            |              | 0          | a3e9f7d2-4b5c-11ee-be56-0242ac120002      |                   |
      | none                 | "10A"            | 3                 | abcdef_1234_abcd_5678_90ab_cdef_1234             | 1234567890123456789      |            |              | 0          | a3e9f7d2-4b5c-11ee-be56-0242ac120002      |                   |
      | none                 | 101              | 3                 | xyz123_@@@@_abcd_5678_90ab_cdef_1234             | 1234567890123456789      |            |              | 0          | a3e9f7d2-4b5c-11ee-be56-0242ac120002      |                   |
      | none                 | 101              | 1                 | abcdef_1234_abcd_5678_90ab_cdef_1234             |                          | 12AB       | 15/04/1998   | 0          | a3e9f7d2-4b5c-11ee-be56-0242ac120002      | IL                |
      | none                 | 101              | 1                 | abcdef_1234_abcd_5678_90ab_cdef_1234             |                          | 12345      | 15/04/1998   | 0          | a3e9f7d2-4b5c-11ee-be56-0242ac120002      | IL                |
      | none                 | 101              | 3                 | abcdef_1234_abcd_5678_90ab_cdef_1234             | 12345678901234567A       |            |              | 0          | a3e9f7d2-4b5c-11ee-be56-0242ac120002      |                   |
      | none                 | 101              | 1                 | abcdef_1234_abcd_5678_90ab_cdef_1234             |                          | 1234       | 1998-04-15   | 0          | a3e9f7d2-4b5c-11ee-be56-0242ac120002      | IL                |
      | none                 | 101              | 3                 | abcdef_1234_abcd_5678_90ab_cdef_1234             | 1234567890123456789      |            |              | 2          | a3e9f7d2-4b5c-11ee-be56-0242ac120002      |                   |
      | none                 | 101              | 3                 | abcdef_1234_abcd_5678_90ab_cdef_1234             | 1234567890123456789      |            |              | 0          | a3e9f7d24b5c11eebe560242ac120002          |                   |

  @api @validation @otp
  Scenario: שגיאת המרה בקלט (Mismatch Conversion Id=19) – partySerialId בכותרת אינו מספרי
    Given השירות זמין וההרשאות בתוקף
    And ערך הכותרת 'partySerialId' מוגדר ל-"ABCDEF" במקום מספר
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/otp' עם גוף תקין מינימלי למתפעלת כאל
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 3,
        "creditCardSerialId": "abcdef_1234_abcd_5678_90ab_cdef_1234",
        "cardIdServiceProvider": "1234567890123456789",
        "smsByVoice": 0,
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002"
      }
      """
    Then תגובת השירות היא HTTP 400
    And השדה errors כולל id=19 והודעה "Cannot assign field [partySerialId] due to a mismatch conversion"

  @api @isracard @errors @otp
  Scenario Outline: שגיאות/טיימאאוט – ישראכרט (token/send) ומיפוי לתשובת השירות
    Given השירות זמין וההרשאות בתוקף
    And מוגדרת הדמיה לשלב '<stage>' של ישראכרט להחזיר '<providerStatus>' עם קוד שגיאה '<providerErrorCode>'
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/otp' עם גוף תקין לישראכרט
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 1,
        "creditCardSerialId": "abcdef_1234_abcd_5678_90ab_cdef_1234",
        "cardSuffix": "1234",
        "birthDate": "15/04/1998",
        "smsByVoice": 0,
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002",
        "alpha2CountryCode": "IL"
      }
      """
    Then תגובת השירות היא HTTP <expectedHttp>
    And אם <expectedStatusCode> גדול מ-0 אז גוף התשובה כולל StatusCode=<expectedStatusCode>
    And אם <expectedErrorId> גדול מ-0 אז errors.id=<expectedErrorId>

    Examples:
      | stage | providerStatus | providerErrorCode    | expectedHttp | expectedStatusCode | expectedErrorId |
      | token | TIMEOUT        |                      | 408          | 0                  | 8               |
      | token | 423            |                      | 409          | 3                  | 0               |
      | send  | 404            | undefined_parameter  | 409          | 4                  | 0               |
      | send  | 500            |                      | 500          | 0                  | 6               |

  @api @cal @errors @otp
  Scenario Outline: שגיאות/טיימאאוט – כאל sendOTP ומיפוי לתשובת השירות
    Given השירות זמין וההרשאות בתוקף
    And מוגדרת הדמיה ל-sendOTP של כאל להחזיר '<providerStatus>'
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/otp' עם גוף תקין למתפעלת כאל
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 3,
        "creditCardSerialId": "abcdef_1234_abcd_5678_90ab_cdef_1234",
        "cardIdServiceProvider": "1234567890123456789",
        "smsByVoice": 0,
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002"
      }
      """
    Then תגובת השירות היא HTTP <expectedHttp>
    And אם <expectedErrorId> גדול מ-0 אז errors.id=<expectedErrorId>

    Examples:
      | providerStatus | expectedHttp | expectedErrorId |
      | TIMEOUT        | 408          | 8               |
      | 401            | 401          | 0               |
      | 500            | 500          | 6               |

  @api @mapping @otp
  Scenario: מיפוי מספר טלפון – ישראכרט (masked) מול כאל (plain)
    Given השירות זמין וההרשאות בתוקף
    When אני יוצר OTP במסלול ישראכרט ומקבל phoneNumber מהשירות
    And אני יוצר OTP במסלול כאל ומקבל phoneNumber מהשירות
    Then במסלול ישראכרט מספר הטלפון הוא מחרוזת באורך 10 המייצגת maskedCellphoneNumber
    And במסלול כאל מספר הטלפון גלוי כפי שהתקבל מהמתפעלת

  @api @isracard @mapping
  Scenario: alpha2CountryCode – מיפוי IL מ-countryId=212 ונשלח לבקשת token
    Given השירות זמין וההרשאות בתוקף
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/otp' עם גוף תקין לישראכרט
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 1,
        "creditCardSerialId": "abcdef_1234_abcd_5678_90ab_cdef_1234",
        "cardSuffix": "1234",
        "birthDate": "15/04/1998",
        "smsByVoice": 0,
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002",
        "alpha2CountryCode": "IL"
      }
      """
    Then בבקשת token לישראכרט נשלח alpha2CountryCode="IL"
    And תגובת השירות היא HTTP 200

  @api @isracard @validation
  Scenario: חסר alpha2CountryCode אצל ישראכרט – שגיאת ולידציה (Id=7)
    Given השירות זמין וההרשאות בתוקף
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/otp' עם גוף ללא alpha2CountryCode
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 1,
        "creditCardSerialId": "abcdef_1234_abcd_5678_90ab_cdef_1234",
        "cardSuffix": "1234",
        "birthDate": "15/04/1998",
        "smsByVoice": 0,
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002"
      }
      """
    Then תגובת השירות היא HTTP 400
    And errors.id=7 עם הודעה על שדה חסר alpha2CountryCode

  @api @isracard @timestamp
  Scenario: requestTimeStamp – פורמט ותזמון Asia/Jerusalem בבקשת token
    Given השירות זמין וההרשאות בתוקף
    When אני מפעיל מסלול ישראכרט ומנטר את גוף בקשת token
    Then השדה requestTimeStamp נמצא בפורמט yyyy-MM-dd-HH.mm.ss.SSSSSS
    And השעה שנשלחה היא באזור זמן Asia/Jerusalem (כולל התאמה לשעון קיץ)

  @api @isracard @conversion
  Scenario Outline: המרת תאריך לידה ל-CYYMMDD – לפני/אחרי שנת 2000
    Given השירות זמין וההרשאות בתוקף
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/otp' עם birthDate="<birthDate>" במסלול ישראכרט
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 1,
        "creditCardSerialId": "abcdef_1234_abcd_5678_90ab_cdef_1234",
        "cardSuffix": "1234",
        "birthDate": "<birthDate>",
        "smsByVoice": 0,
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002",
        "alpha2CountryCode": "IL"
      }
      """
    Then בבקשת token השדה dateOfBirth נשלח כ-"<expectedCYYMMDD>"

    Examples:
      | birthDate   | expectedCYYMMDD |
      | 15/04/1998  | 0980415         |
      | 02/01/2001  | 1010102         |

  @api @isracard @constants
  Scenario: קבועים bankCode ו-companyCode בבקשת token לישראכרט
    Given השירות זמין וההרשאות בתוקף
    When אני מפעיל בקשת token במסלול ישראכרט
    Then בבקשה נשלחים bankCode="012" ו-companyCode="B"

  @api @cal @verify
  Scenario: אימות OTP – כאל: הצלחה (Authenticate ואז GetEncryptedKey)
    Given השירות זמין וההרשאות בתוקף ויש otpToken תקף
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/verify-otp' עם גוף:
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 3,
        "otpPassword": "123456",
        "otpToken": "OTP123TOKEN",
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002"
      }
      """
    And המערכת מפעילה POST אל "{CAL_BASE_URL}/api/Authenticate/authenticate" עם token=otpToken ו-password=otpPassword ומקבלת jwt
    And המערכת מפעילה POST אל "{CAL_BASE_URL}/api/GetEncryptedKey/getEncryptedKey" עם authorization=jwt ומקבלת encryptionKey
    Then תגובת השירות היא HTTP 200 וללא errors
    And הגוף כולל ott=<jwt> ו-encryptionKey=<encryptionKey>
    And orderId בתשובה זהה לקלט

  @api @isracard @verify
  Scenario: אימות OTP – ישראכרט: הצלחה (validate – tek ו-authorizationToken)
    Given השירות זמין וההרשאות בתוקף ויש otpToken תקף
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/verify-otp' עם גוף:
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 1,
        "otpPassword": "123456",
        "otpToken": "OTP123TOKEN",
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002"
      }
      """
    And המערכת מפעילה POST אל "{ISRC_BASE_URL}/authorization/otpByToken/v1.4.0/validate" עם הנתונים ומקבלת tek ו-authorizationToken
    Then תגובת השירות היא HTTP 200 וללא errors
    And הגוף כולל ott=<authorizationToken> ו-encryptionKey=<tek>
    And orderId בתשובה זהה לקלט

  @api @validation @verify
  Scenario Outline: ולידציות קלט verify-otp – חסרים/לא תקינים (Id=7) ושימור אפסים מובילים
    Given השירות זמין וההרשאות בתוקף
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/verify-otp' עם גוף:
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 3,
        "otpPassword": "<otpPassword>",
        "otpToken": "OTP123TOKEN",
        "orderId": "<orderId>"
      }
      """
    And אם הערך '<missingField>' שונה מ-'none' אני מסיר את השדה '<missingField>' מהגוף לפני השליחה
    Then תגובת השירות היא HTTP <expectedHttp>
    And אם <expectedHttp> = 400 אז errors.id=7
    And אם "<otpPassword>" = "000123" אז אני מאמת שהערך נשלח כ-"000123" למתפעלת ללא איבוד אפסים מובילים

    Examples:
      | missingField | otpPassword | orderId                                   | expectedHttp |
      | otpPassword  |             | a3e9f7d2-4b5c-11ee-be56-0242ac120002      | 400          |
      | none         | 12A45       | a3e9f7d2-4b5c-11ee-be56-0242ac120002      | 400          |
      | none         | 000123      | a3e9f7d2-4b5c-11ee-be56-0242ac120002      | 200          |
      | none         | 123456      | INVALID-UUID                              | 400          |

  @api @cal @timeout @verify
  Scenario: טיימאאוט כאל – Authenticate (Id=8)
    Given השירות זמין וההרשאות בתוקף
    And מוגדרת הדמיה ל-Authenticate של כאל להחזיר TIMEOUT
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/verify-otp' עם גוף תקין למסלול כאל
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 3,
        "otpPassword": "123456",
        "otpToken": "OTP123TOKEN",
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002"
      }
      """
    Then תגובת השירות היא HTTP 408
    And errors.id=8

  @api @isracard @errors @verify
  Scenario Outline: שגיאות validate – ישראכרט ומיפוי לתשובת השירות
    Given השירות זמין וההרשאות בתוקף
    And מוגדרת הדמיה ל-validate של ישראכרט להחזיר '<providerStatus>' עם responseCode='<responseCode>'
    When אני שולח בקשת POST אל '/card-operator/restore-details-gw/verify-otp' עם גוף תקין למסלול ישראכרט
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 1,
        "otpPassword": "123456",
        "otpToken": "OTP123TOKEN",
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002"
      }
      """
    Then תגובת השירות היא HTTP <expectedHttp>
    And אם <expectedStatusCode> גדול מ-0 אז גוף התשובה כולל StatusCode=<expectedStatusCode>
    And אם <expectedErrorId> גדול מ-0 אז errors.id=<expectedErrorId>

    Examples:
      | providerStatus | responseCode         | expectedHttp | expectedStatusCode | expectedErrorId |
      | 200            | invalid_otp_attempt  | 409          | 7                  | 0               |
      | 423            |                      | 409          | 8                  | 0               |
      | 401            |                      | 403          | 33                 | 0               |
      | 500            |                      | 500          | 0                  | 6               |

  @api @echo
  Scenario Outline: השבת orderId בתשובות – generateOtp ו-verify-otp
    Given השירות זמין וההרשאות בתוקף
    When אני שולח בקשת POST אל '<endpoint>' עם גוף המכיל orderId="<orderId>"
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": <spCode>,
        "creditCardSerialId": "abcdef_1234_abcd_5678_90ab_cdef_1234",
        "cardIdServiceProvider": "1234567890123456789",
        "cardSuffix": "1234",
        "birthDate": "15/04/1998",
        "otpPassword": "123456",
        "otpToken": "OTP123TOKEN",
        "smsByVoice": 0,
        "orderId": "<orderId>",
        "alpha2CountryCode": "IL"
      }
      """
    Then בתשובת השירות orderId זהה ל-"<orderId>"

    Examples:
      | endpoint                                      | spCode | orderId                                   |
      | /card-operator/restore-details-gw/otp         | 3      | a3e9f7d2-4b5c-11ee-be56-0242ac120002      |
      | /card-operator/restore-details-gw/verify-otp  | 1      | a3e9f7d2-4b5c-11ee-be56-0242ac120002      |

  @api @auth
  Scenario Outline: אימות הרשאה – רמה 2 (CA) חסרה/פגה – החזרת 401 (Id=5)
    Given אני מסיר או מבטל את כותרת ההרשאה CA
    When אני שולח בקשת POST אל '<endpoint>' עם גוף תקין
      """
      {
        "activityTypeCode": 101,
        "cardIssuingSpCode": 3,
        "creditCardSerialId": "abcdef_1234_abcd_5678_90ab_cdef_1234",
        "cardIdServiceProvider": "1234567890123456789",
        "smsByVoice": 0,
        "otpPassword": "123456",
        "otpToken": "OTP123TOKEN",
        "orderId": "a3e9f7d2-4b5c-11ee-be56-0242ac120002"
      }
      """
    Then תגובת השירות היא HTTP 401
    And errors.id=5

    Examples:
      | endpoint                                     |
      | /card-operator/restore-details-gw/otp        |
      | /card-operator/restore-details-gw/verify-otp |

  # Non-Functional Tests
  @performance @otp
  Scenario Outline: ביצועים – זמן תגובה generateOtp תחת עומס (SLA)
    Given סביבת בדיקות יציבה וכלי עומס זמינים
    When אני מריץ עומס של <rps> בקשות לשנייה למשך <duration> אל '/card-operator/restore-details-gw/otp' עם נתונים תקינים (חלוקה <split> בין כאל/ישראכרט)
    Then ממוצע זמן תגובה < <avgMs>ms ו-p95 < <p95Ms>ms
    And שיעור שגיאות < <errorRate>%

    Examples:
      | rps | duration | split | avgMs | p95Ms | errorRate |
      | 500 | 60s      | 50/50 | 1500  | 2500  | 1         |

  @performance @verify
  Scenario Outline: ביצועים – זמן תגובה otpByToken תחת עומס (SLA)
    Given הוכנו מראש <tokens> otpToken תקפים
    When אני מריץ עומס של <rps> בקשות לשנייה למשך <duration> אל '/card-operator/restore-details-gw/verify-otp' עם נתונים תקינים למסלולי כאל/ישראכרט
    Then ממוצע זמן תגובה < <avgMs>ms ו-p95 < <p95Ms>ms
    And שיעור שגיאות נמוך מ-<errorRate>%

    Examples:
      | tokens | rps | duration | avgMs | p95Ms | errorRate |
      | 300    | 300 | 60s      | 1500  | 2500  | 1         |

  @security @tls
  Scenario: אבטחה – תמיכת TLS1.2+ בלבד בתקשורת נכנסת/יוצאת
    Given יש לי גישה לסריקת פרוטוקולי TLS עבור השירות והאינטגרציות
    When אני מנסה להתחבר עם TLS1.0 ו-TLS1.1
    Then החיבור נכשל עבור TLS1.0/1.1
    And הנתמכים הם TLS1.2 ומעלה בלבד

  @privacy @logging
  Scenario: פרטיות – אי-לוגינג של OTP/Token/Master Key
    Given הופעלו תרחישי TC-001, TC-029, TC-030 ליצירת לוגים
    When אני סורק את יומני המערכת וה-APM
    Then אין מופעים של otpPassword, otpToken, encryptionKey או 16 ספרות מלאות של כרטיס
    And נרשמים רק מזהים לא רגישים (orderId, StatusCode)

  @l10n @content
  Scenario: נגישות ותמיכה תרבותית – תוכן SMS/IVR בעברית ו-RTL
    Given הופקו מסרים בערוצי SMS/IVR בעקבות יצירת OTP במסלולים השונים
    When אני בוחן את נוסח ההודעות כפי שנשלחו ללקוח
    Then ההודעות בעברית תקינה, מיושרות RTL וברורות
    And ספרות ה-OTP מוצגות באופן קריא (לדוגמה "הקוד שלך: 123456")

  @observability
  Scenario: איתור וניטור – קורלציה מלאה לפי orderId לאורך השרשרת
    Given הופעלו תרחישי OTP והפעלת אימות (למשל TC-003 ו-TC-030)
    When אני בוחן לוגים, מטריקות ו-Traceים במערכות הניטור
    Then קיים קשר קורלציה בין כל הקריאות לפי orderId (כולל TraceId/SpanId)

  @ratelimit
  Scenario: Rate Limiting/Brute Force – ניסיונות OTP מוגבלים במסלול ישראכרט
    Given זמינות להדמיית מספר ניסיונות גבוה לאימות OTP
    When אני שולח רצף ניסיונות אימות כושלים ל-'/card-operator/restore-details-gw/verify-otp' עם cardIssuingSpCode=1 עד לקבלת 423 מהמתפעלת
    Then תגובת השירות ממופה ל-HTTP 409 עם StatusCode=8
    And אין דליפת מידע רגיש בגוף התשובה

  @scalability
  Scenario: סקיילביליות – עומס מקבילי גבוה על /otp ו-/verify-otp
    Given תשתית עומס תומכת ב-1000 חיבורים מקביליים
    When אני מריץ 1000 חיבורים מקביליים אל נקודות הקצה '/otp' ו-'/verify-otp'
    Then המערכת יציבה, שיעור השגיאות נמוך ואין קריסה או דליפות זיכרון

  @resilience
  Scenario: התאוששות מתקלות – טיימאאוט/404 והחזרת מסרים ידידותיים
    Given מוגדרת הדמיית 408 במסלול כאל ו-404 במסלול ישראכרט
    When אני מפעיל את המסלולים וגורם לשגיאות אלו
    Then עבור 408 מוחזר errors.id=8 והודעה "The service is temporarily unavailable"
    And עבור 404 מוחזר errors.id=20 והודעה "The server was not able to retrieve the requested page"
    And אין חשיפת פרטים אישיים במסרים

  @l10n
  Scenario: לוקליזציה – פורמטי תאריך/זמן ואזור זמן Asia/Jerusalem
    Given הופעלו תרחישים המייצרים לוגים עם שדות תאריך
    When אני בוחן תאריכים למשתמשים ולקריאות למתפעלת
    Then למשתמשים פורמט dd/MM/yyyy
    And ל-API החיצוניים נשלחים הפורמטים הנדרשים (כולל CYYMMDD ו-requestTimeStamp)
    And אזור הזמן הוא Asia/Jerusalem

  @compliance
  Scenario: ציות לרגולציה – בנק ישראל והגנת הפרטיות
    Given קיימים מסמכי מדיניות ובקרות אבטחה
    When אני בודק תהליכי הזדהות, ניהול הרשאות CA רמה 2, שמירת נתונים ואנונימיזציה
    Then המערכת עומדת בדרישות הרגולציה המקומית ללא ליקויי פרטיות או אבטחה
