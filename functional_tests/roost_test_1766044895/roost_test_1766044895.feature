Feature: חנות אונליין - בדיקות מקצה לקצה, API ולוקליזציה לישראל (₪, RTL, תקני אבטחה)

  Background:
    Given סביבת הבדיקות מוגדרת לדפדפן בעברית ובפריסת RTL
    And API base URL מוגדר במשתנה סביבה 'API_BASE_URL'
    And מוגדר טוקן הרשאה תקף לבדיקות API

  # UI Tests - תרחישים פונקציונליים בממשק
  @ui @rtl @e2e @TC-FUNC-001
  Scenario: מסע משתמש מלא עם ולידציות שגיאה (חוסר מיקוד ושיטת תשלום לא תקינה)
    Given אני נמצא בדף הבית בכתובת 'https://share.google/gX4PkITYxjSjISHwh'
    When אני לוחץ על הכפתור 'SHOP NOW' תחת הקטגוריה 'Latest Eyewear For You'
    And אני לוחץ על מספר העמוד '2' בניווט הדפים
    Then אני אמור להיות בעמוד 2 של הקטגוריה ולראות רשימת מוצרים מעודכנת
    When אני חוזר לעמוד 1 באמצעות הניווט
    And אני לוחץ על חץ 'הבא' בניווט הדפים
    Then אני אמור לראות שהגעתי לאותו תוכן ו-URL כפי שהופיע בעמוד 2 (עקביות שני מסלולים)
    When אני לוחץ על תמונת המוצר 'Red Hoodie'
    Then אני אמור לראות את עמוד הפריט 'Red Hoodie'
    When אני חוזר לעמוד הקטגוריה
    And אני לוחץ על שם המוצר 'Red Hoodie'
    Then אני אמור לראות שוב את עמוד הפריט 'Red Hoodie'
    When אני לוחץ על הכפתור 'ADD TO CART'
    And אני לוחץ על הכפתור 'VIEW CART'
    Then אני אמור לראות את 'Red Hoodie' בעגלה
    When אני בוחר את שיטת המשלוח 'Local pickup'
    Then עלות המשלוח אמורה להתעדכן ל-₪0 (או לפי הגדרה) ומוצגת הערכת זמן איסוף
    When אני בוחר את שיטת המשלוח 'Delivery Express'
    Then עלות המשלוח אמורה להתעדכן לטווח צפוי (למשל ₪35-₪60) ומוצג זמן אספקה מותאם
    When אני בוחר את שיטת המשלוח 'Registered Mail'
    Then עלות המשלוח אמורה להתעדכן לטווח צפוי (למשל ₪20-₪30) ומוצג זמן אספקה מותאם
    When אני לוחץ על 'PROCEED TO CHECKOUT'
    And אני ממלא את פרטי הצ'קאאוט פרט ל-Postcode/ZIP: שם פרטי 'דנה', שם משפחה 'כהן', כתובת 'הרצל 10', עיר 'תל אביב', טלפון '0541234567', אימייל 'dana@test.co.il'
    And אינני בוחר שיטת תשלום
    And אני לוחץ על 'PLACE ORDER'
    Then אמורה להופיע הודעת שגיאה בעברית על חוסר בשדה מיקוד (Postcode/ZIP) 7 ספרות
    When אני מזין בשדה Postcode/ZIP את '6777655'
    And אני לוחץ על 'PLACE ORDER'
    Then אמורה להופיע הודעת שגיאה בעברית לגבי שיטת תשלום לא תקינה/לא נבחרה

  @ui @rtl @payments @TC-FUNC-002
  Scenario: הזמנה מוצלחת עם תשלום אשראי תקין ומייל אישור
    Given אני נמצא בדף הבית בכתובת 'https://share.google/gX4PkITYxjSjISHwh'
    When אני לוחץ על 'SHOP NOW' בקטגוריה 'Latest Eyewear For You'
    And אני מנווט לעמוד '2' ולוחץ על 'Red Hoodie'
    And אני לוחץ 'ADD TO CART' ואז 'VIEW CART'
    And אני בוחר 'Delivery Express' ומוודא שסימן המטבע הוא ₪
    And אני לוחץ 'PROCEED TO CHECKOUT'
    And אני ממלא פרטים: שם 'יואב', משפחה 'לוי', כתובת 'בן גוריון 25', עיר 'חיפה', טלפון '0529876543', אימייל 'yoav@example.com', מיקוד '3276543'
    And אני בוחר שיטת תשלום 'Credit Card'
    And אני מזין כרטיס: מספר '4111111111111111', תוקף '12/28', CVV '123', ת"ז '123456789', שם בעל הכרטיס 'יואב לוי'
    And אני לוחץ 'PLACE ORDER'
    Then אמורה להופיע הודעת הצלחה עם מספר הזמנה ייחודי וסיכום הכולל מע"מ 17% וש"ח
    And אמור להתקבל אימייל אישור בעברית הכולל תאריך בפורמט dd/mm/yyyy ושעה באזור Asia/Jerusalem

  @ui @rtl @navigation @TC-FUNC-003
  Scenario: ניווט חלופי לעמוד 2 - מספר עמוד מול חץ 'הבא'
    Given אני בעמוד הקטגוריה לאחר לחיצה על 'SHOP NOW'
    When אני לוחץ על '2' בניווט הדפים
    And אני שומר את רשימת המוצרים ואת ה-URL
    And אני חוזר לעמוד 1
    And אני לוחץ על חץ 'הבא'
    Then רשימת המוצרים וה-URL אמורים להיות זהים/עקביים לעומת העמוד שאוחסן קודם (page=2 או בהתאם לסטנדרט האתר)

  @ui @rtl @product @TC-FUNC-004
  Scenario Outline: בחירת מוצר באמצעות תמונה או שם
    Given אני בעמוד הקטגוריה שבו מוצג 'Red Hoodie'
    When אני לוחץ על <רכיב_לחיץ> של 'Red Hoodie'
    Then אני אמור לראות את עמוד המוצר 'Red Hoodie'

    Examples:
      | רכיב_לחיץ  |
      | תמונה      |
      | שם המוצר   |

  @ui @rtl @cart @pricing @TC-FUNC-005
  Scenario: עדכון עגלה - כמות, חישובי סכומים בש"ח והסרה
    Given הוספתי את 'Red Hoodie' לעגלה ואני בעמוד 'VIEW CART'
    When אני משנה את הכמות ל-2 ומעדכן את העגלה (אם נדרש)
    Then סכום הביניים אמור להיות מחיר יחידה כפול 2 בש"ח
    And אם מוצג מע"מ 17% הוא מחושב נכון
    And הסכום הכולל מוצג נכון בשקלים
    When אני מסיר את הפריט מהעגלה
    Then העגלה אמורה להיות ריקה וללא עלות משלוח

  @ui @rtl @shipping @TC-FUNC-006
  Scenario Outline: בחירת שיטת משלוח והשפעתה על המחיר ועל זמן האספקה
    Given יש מוצר בעגלה ואני בעמוד 'VIEW CART'
    When אני בוחר את שיטת המשלוח '<שיטת_משלוח>'
    Then עלות המשלוח אמורה להיות בטווח '<טווח_מחיר_ש"ח>'
    And זמן האספקה אמור להיות '<זמן_אספקה>'

    Examples:
      | שיטת_משלוח      | טווח_מחיר_ש"ח | זמן_אספקה              |
      | Local pickup     | ₪0             | איסוף מיידי/זמן איסוף |
      | Delivery Express | ₪35-₪60        | 1-2 ימי עסקים          |
      | Registered Mail  | ₪20-₪30        | 3-7 ימי עסקים          |

  @ui @rtl @validation @checkout @TC-FUNC-007
  Scenario Outline: ולידציות שדות בצ'קאאוט - אימייל, טלפון, מיקוד ושדות חובה
    Given יש מוצר בעגלה ואני בעמוד הצ'קאאוט
    When אני מזין בשדה '<שדה>' את הערך '<ערך>' (או משאיר ריק אם מצוין)
    And אני לוחץ 'PLACE ORDER'
    Then אמורה להופיע הודעת שגיאה בעברית: '<הודעת_שגיאה>'

    Examples:
      | שדה         | ערך           | הודעת_שגיאה                              |
      | שם פרטי     |               | שדה חובה                                 |
      | אימייל      | user@wrong    | אימייל אינו תקין                         |
      | טלפון       | 1234          | מספר טלפון ישראלי אינו תקין              |
      | Postcode/ZIP| 12345         | יש להזין מיקוד בן 7 ספרות                |

  @ui @rtl @coupon @pricing @TC-FUNC-008
  Scenario: קופון הנחה תקף - החלה וביטול
    Given יש מוצר בעגלה
    When אני מזין קוד קופון 'SALE10' ולוחץ 'Apply'
    Then המחיר אמור לרדת ב-10% והנחה מוצגת בש"ח
    When אני מבטל/מסיר את הקופון
    Then המחיר אמור לחזור למחיר המלא ללא הנחה

  @ui @rtl @coupon @TC-FUNC-008
  Scenario: קופון לא תקין/פג תוקף
    Given יש מוצר בעגלה
    When אני מזין קוד קופון 'OLD5' ולוחץ 'Apply'
    Then אמורה להופיע הודעה בעברית: 'קופון פג תוקף' או 'קופון לא תקין'

  @ui @rtl @payments @cards @TC-FUNC-009
  Scenario Outline: תשלום בכרטיסים מקומיים - ישראכרט ודיינרס
    Given יש מוצר בעגלה ואני בעמוד הצ'קאאוט
    When אני בוחר תשלום 'Credit Card' ומזין כרטיס <מותג>: מספר '<מספר>', תוקף '<תוקף>', CVV '<CVV>'<תז>
    And אני לוחץ 'PLACE ORDER'
    Then מתקבלת תגובת הצלחה או שגיאה מבוקרת בהתאם לסביבת הבדיקות ללא חשיפת פרטי כרטיס מלאים

    Examples:
      | מותג      | מספר              | תוקף  | CVV | תז                 |
      | ישראכרט  | 4580000000000000  | 05/27 | 123 | , ת"ז '123456782'  |
      | דיינרס    | 30000000000004    | 11/26 | 123 |                    |

  @ui @rtl @paypal @TC-FUNC-010
  Scenario: תשלום ב-PayPal (אם קיים) וחזרה לסיכום
    Given יש מוצר בעגלה ואני בעמוד הצ'קאאוט
    When אני בוחר 'PayPal'
    Then אני אמור להיות מנותב לעמוד PayPal
    When אני מבצע כניסה לחשבון בדמה ומאשר תשלום
    Then אני אמור לחזור לאתר עם סטטוס 'אושר' וסיכום הזמנה כולל מספר הזמנה

  @ui @rtl @auth @TC-FUNC-011
  Scenario: צ'קאאוט כאורח ללא יצירת חשבון
    Given יש מוצר בעגלה ואני בעמוד הצ'קאאוט
    When אני ממלא את כל הפרטים הנדרשים ללא כניסה לחשבון
    And אני משלים הזמנה
    Then ההזמנה נקלטת ואין דרישה ליצירת חשבון

  @ui @rtl @auth @TC-FUNC-011
  Scenario: צ'קאאוט כמשתמש רשום ושמירת פרטים
    Given אני מתנתק/מנקה עוגיות ונכנס עם 'noa@example.com'
    When אני מגיע לצ'קאאוט
    Then פרטי המשלוח נטענים אוטומטית מהפרופיל
    When אני מעדכן כתובת ושומר
    Then הכתובת החדשה נשמרת ומוצגת בפרופיל לבאות

  @ui @rtl @stock @TC-FUNC-012
  Scenario: מוצר ללא מלאי - מניעת הזמנה
    Given אני בעמוד פריט שמסומן Out of Stock
    When אני מנסה ללחוץ 'ADD TO CART'
    Then הכפתור מושבת או מוצגת הודעה 'אין במלאי' ואין הוספה לעגלה

  @ui @rtl @postcode @TC-FUNC-013
  Scenario: מיקוד ישראלי - 7 ספרות ועזרה למשתמש
    Given יש מוצר בעגלה ואני בעמוד הצ'קאאוט
    When אני מזין מיקוד '123456' ולוחץ 'PLACE ORDER'
    Then מוצגת הודעת שגיאה: 'יש להזין מיקוד בן 7 ספרות'
    And קיים קישור/טיפ עזרה (למשל לאתר דואר ישראל) למציאת מיקוד

  @ui @rtl @email @TC-FUNC-014
  Scenario: הודעות אימייל - אישור הזמנה
    Given השלמתי הזמנה מוצלחת
    When אני בודק את תיבת הדואר של הלקוח בסביבת בדיקה
    Then מתקבל אימייל בעברית עם תאריך dd/mm/yyyy, סכומים ב-₪ ופירוט מע"מ
    And אם קיים, מופיע קישור לשחזור עגלה/הזמנה

  @ui @rtl @i18n @TC-FUNC-015
  Scenario: ממשק בעברית ו-RTL בכל הדפים המרכזיים
    Given אני בודק את דף הבית, קטגוריה, מוצר, עגלה וצ'קאאוט
    Then כל הטקסטים בעברית, יישור לימין ותוויות מוצגות נכון
    And אין ערבוב כיוונים (LTR/RTL) הגורם לשבירה
    And אין שגיאות כתיב בעברית

  @ui @rtl @idempotency @TC-FUNC-016
  Scenario: מניעת הזמנה כפולה בלחיצה כפולה על 'PLACE ORDER'
    Given יש מוצר בעגלה ואני בעמוד הצ'קאאוט עם פרטים מלאים
    When אני לוחץ פעמיים במהירות על 'PLACE ORDER'
    Then נוצרת רק הזמנה אחת ואין חיוב כפול

  @ui @rtl @vat @TC-FUNC-019
  Scenario: הצגת מע"מ 17% בסיכום ההזמנה והחשבונית
    Given יש מוצר בעגלה
    When אני משלים הזמנה
    Then בסיכום/חשבונית מוצג פירוט מע"מ 17% בש"ח והסכומים מדויקים

  @ui @rtl @shipping @form @TC-FUNC-020
  Scenario: Local pickup - הסרת חובת כתובת והצגת מידע איסוף
    Given בחרתי 'Local pickup' בעגלה
    When אני ממשיך לצ'קאאוט ומנסה להזמין ללא הזנת כתובת מלאה
    Then אין שגיאה על שדות כתובת
    And מוצגת כתובת החנות/שעות איסוף

  @ui @rtl @shipping @sla @TC-FUNC-021
  Scenario Outline: עדכון זמן אספקה לפי עיר בישראל
    Given יש מוצר בעגלה ואני בעמוד הצ'קאאוט
    When אני מזין עיר '<עיר>' ובוחר 'Delivery Express'
    Then זמן האספקה המוצג צריך להיות '<זמן_אספקה>'

    Examples:
      | עיר      | זמן_אספקה        |
      | תל אביב  | 1-2 ימי עסקים    |
      | מטולה    | 2-4 ימי עסקים    |

  @ui @rtl @cart @sync @TC-FUNC-022
  Scenario: שמירת עגלה בין מכשירים וסשנים למשתמש רשום
    Given אני מתחבר בדסקטופ ומוסיף פריט לעגלה
    When אני מתנתק ומתחבר ממכשיר מובייל
    Then העגלה אמורה להסתנכרן ולהציג את אותו הפריט

  @ui @rtl @shipping @pricing @TC-FUNC-023
  Scenario: הוספת מוצר נוסף והשפעה על עלות משלוח משוקללת
    Given הוספתי 'Red Hoodie' לעגלה
    When אני מוסיף מוצר נוסף 'Blue Sunglasses' ובוחר 'Delivery Express'
    Then עלות המשלוח מתעדכנת לפי משקל/נפח בהתאם לכללי התעריפים

  @ui @rtl @address @TC-FUNC-025
  Scenario: תמיכה בעברית בשדות כתובת - תווים מיוחדים ושמות רחובות
    Given יש מוצר בעגלה ואני בעמוד הצ'קאאוט
    When אני מזין כתובת "הרב קוק 12/3 קומה 2-א'"
    And אני לוחץ 'PLACE ORDER'
    Then הכתובת מתקבלת ונרשמת ללא סינון שגוי של תווים חוקיים

  @ui @rtl @payments @visibility @TC-FUNC-026
  Scenario Outline: התאמת שיטת תשלום לפי סכום הזמנה
    Given יש מוצר/ים בעגלה עם סכום כולל '<סכום_הזמנה>'
    When אני מגיע לצ'קאאוט
    Then שיטת 'תשלומים' אמורה להיות '<נראות_תשלומים>'

    Examples:
      | סכום_הזמנה | נראות_תשלומים |
      | ₪10         | מוסתרת        |
      | ₪1000       | זמינה         |

  @ui @rtl @guidance @TC-NF-014
  Scenario: התאוששות משגיאת 'Invalid payment method' - הנחיה לפתרון
    Given בצעתי ניסיון תשלום שהחזיר 'Invalid payment method'
    When אני קורא את הודעת השגיאה על המסך
    Then ההודעה צריכה להציע בחירה בשיטה אחרת או בדיקת פרטי התשלום
    When אני בוחר שיטה אחרת ומנסה שוב
    Then התשלום אמור להצליח או להיכשל באופן מבוקר עם הנחיה נוספת

  @ui @rtl @privacy @TC-NF-013
  Scenario: פרטיות - הסכמה לעיבוד נתונים ומינימיזציה של PII
    Given אני בעמוד הצ'קאאוט
    When אני בודק שקיימת תיבת סימון להסכמה ומדיניות פרטיות בעברית
    Then ההזמנה לא מבקשת פרטים מיותרים מעבר לנדרש
    And לוגים/מסכים אינם מציגים אימייל/טלפון גולמיים

  @ui @rtl @usability @errors @TC-NF-007
  Scenario: שימושיות - הודעות שגיאה בעברית ברורות ומנחות
    Given אני גורם לשגיאות אימייל/טלפון/מיקוד בטפסים
    When ההודעות מוצגות
    Then ההודעות ברורות, לא טכניות מדי, ומציינות מה לתקן
    And קישורי עזרה (אם קיימים) פועלים ומועילים

  @ui @rtl @accessibility @WCAG @TC-NF-008
  Scenario: נגישות - תאימות לתקן 5568/WCAG 2.1 AA
    Given אני מריץ בדיקות axe ובודק עם NVDA/JAWS
    When אני מנווט עם מקלדת בכל הרכיבים
    Then לכל שדה יש aria-label תקין וניגודיות צבעים >= 4.5:1
    And לתמונות מוצרים יש טקסט אלטרנטיבי ומיקוד נראה (focus outline)

  @ui @rtl @compatibility @browsers @TC-NF-009
  Scenario Outline: תאימות דפדפנים ומכשירים נפוצים בישראל
    Given אני מריץ תרחיש קניה מלא בדפדפן/מכשיר '<פלטפורמה>'
    When אני בודק פריסת RTL וטקסטים בעברית
    Then החוויה אחידה וללא שבירות RTL

    Examples:
      | פלטפורמה        |
      | Chrome Desktop  |
      | Firefox Desktop |
      | Edge Desktop    |
      | Safari Desktop  |
      | iOS Safari      |
      | Android Chrome  |

  @ui @rtl @resume @TC-NF-015
  Scenario: אמינות - שמירת הזמנה לא גמורה והמשך מאוחר יותר
    Given אני ממלא חלק משדות הצ'קאאוט כמשתמש רשום
    When אני יוצא מהדף/מתנתק
    And אני נכנס שוב וחוזר לצ'קאאוט
    Then השדות שמורים וניתן להמשיך מהנקודה שהופסקה

  @ui @rtl @3DS @payments @TC-NF-017
  Scenario Outline: אבטחה - דרישת 3D Secure לפי סכום
    Given יש בעגלה סכום '<סכום>'
    When אני בוחר תשלום אשראי ומבצע תשלום
    Then עבור סכום ברמת '<מדיניות_3DS>' אמורה להתבצע הפניית 3DS ואימות OTP בהתאם למדיניות

    Examples:
      | סכום   | מדיניות_3DS    |
      | ₪1500  | נדרש 3DS       |
      | ₪100   | לא נדרש 3DS    |

  # API Tests - תרחישים פונקציונליים ותשתיתיים
  @api @orders @idempotency @TC-FUNC-016
  Scenario: API - מניעת הזמנה כפולה עם Idempotency-Key
    Given כתובת ה-API היא '${API_BASE_URL}' ויש טוקן הרשאה תקף
    When אני שולח בקשת POST ל'/api/orders' עם כותרת 'Idempotency-Key: 123e4567' והמטען:
      """
      {
        "customer": {
          "firstName": "דנה",
          "lastName": "כהן",
          "email": "dana@test.co.il",
          "phone": "0541234567"
        },
        "shipping": {
          "method": "delivery_express",
          "address": {
            "street": "הרצל 10",
            "city": "תל אביב",
            "postcode": "6777655",
            "country": "IL"
          }
        },
        "items": [
          {"sku": "RED-HOODIE", "qty": 1, "price": 199.00, "currency": "ILS"}
        ],
        "payment": {"method": "credit_card", "token": "tok_test_ok"}
      }
      """
    Then סטטוס התגובה צריך להיות 201
    And גוף התגובה צריך להכיל 'orderId' ו'currency'='ILS'
    When אני שולח שוב את אותה בקשה עם אותו Idempotency-Key
    Then סטטוס התגובה צריך להיות 201
    And יוחזר אותו 'orderId' (אין יצירת הזמנה כפולה)

  @api @inventory @TC-FUNC-017
  Scenario: API - עדכון מלאי לאחר הזמנה מוצלחת
    Given כתובת ה-API היא '${API_BASE_URL}' ויש טוקן הרשאה תקף
    When אני שולח GET ל'/api/inventory/products/RED-HOODIE'
    Then סטטוס התגובה צריך להיות 200
    And אני שומר את 'onHand' ההתחלתי
    When אני שולח POST ל'/api/orders' ליצירת הזמנה עם פריט RED-HOODIE (qty=1) והמָטען:
      """
      {
        "items": [{"sku": "RED-HOODIE", "qty": 1}],
        "payment": {"method": "credit_card", "token": "tok_test_ok"},
        "currency": "ILS"
      }
      """
    Then סטטוס התגובה צריך להיות 201
    When אני שולח GET ל'/api/inventory/products/RED-HOODIE'
    Then ערך 'onHand' החדש צריך להיות קטן ב-1 מהערך ההתחלתי

  @api @orders @refunds @TC-FUNC-018
  Scenario: API - ביטול הזמנה והחזר לפי מדיניות
    Given יש הזמנה קיימת במצב 'pending' עם מזהה 'ORD-123'
    When אני שולח POST ל'/api/orders/ORD-123/cancel' עם סיבת ביטול 'לקוח ביקש'
    Then סטטוס התגובה צריך להיות 200
    And סטטוס ההזמנה צריך להיות 'canceled'
    And ייווצר רישום החזר בהתאם לאמצעי התשלום

  @api @shipping @rates @TC-FUNC-021
  Scenario Outline: API - זמני אספקה ועלויות לפי עיר
    Given כתובת ה-API היא '${API_BASE_URL}'
    When אני שולח POST ל'/api/shipping/rates' עם:
      """
      {
        "city": "<עיר>",
        "country": "IL",
        "methods": ["delivery_express"],
        "items": [{"sku": "RED-HOODIE", "qty": 1, "weight": 0.5}]
      }
      """
    Then סטטוס התגובה צריך להיות 200
    And התגובה צריכה להכיל method='delivery_express' עם 'eta'='<ETA>' ו'price.currency'='ILS'

    Examples:
      | עיר      | ETA             |
      | תל אביב  | 1-2 ימי עסקים   |
      | מטולה    | 2-4 ימי עסקים   |

  @api @concurrency @oversell @TC-FUNC-024
  Scenario: API - מניעת מכירה יתר (Race Condition) עם מלאי 1
    Given במוצר RED-HOODIE יש מלאי onHand=1
    When שני משתמשים A ו-B שולחים במקביל POST ל'/api/orders' עם פריט RED-HOODIE qty=1
    Then רק אחד צריך לקבל 201 עם orderId תקף
    And השני צריך לקבל 409/422 עם הודעה 'המוצר אינו זמין'

  @api @email @TC-FUNC-014
  Scenario: API - אימות שליחת אימייל אישור הזמנה
    Given יש הזמנה חדשה עם מזהה 'ORD-200'
    When אני מחפש בתיבת הדואר הבדיקתית דרך '/api/test/mailbox/search?orderId=ORD-200&locale=he-IL'
    Then סטטוס התגובה צריך להיות 200
    And גוף ההודעה צריך לכלול סכומים ב-₪, תאריך בפורמט dd/mm/yyyy ופירוט מע"מ

  @api @feature_flags @shipping @TC-NF-016
  Scenario: API - Feature Flags לשיטות משלוח
    Given דגל 'registered_mail' פעיל
    When אני מכבה את הדגל דרך POST '/api/flags/registered_mail/disable'
    Then סטטוס צריך להיות 200
    When אני שולח GET ל'/api/shipping/methods?country=IL'
    Then 'registered_mail' לא יופיע ברשימת השיטות
    When אני מפעיל מחדש את הדגל דרך POST '/api/flags/registered_mail/enable'
    Then 'registered_mail' יחזור להופיע ברשימה

  @api @compatibility @versioning @TC-NF-010
  Scenario Outline: API - תאימות חוזים בין גרסאות v1/v2
    Given כתובת ה-API היא '${API_BASE_URL}'
    When אני שולח POST ל'/<גרסה>/orders' עם מטען בסיסי:
      """
      {
        "items": [{"sku": "RED-HOODIE", "qty": 1}],
        "currency": "ILS",
        "payment": {"method": "credit_card", "token": "tok_test_ok"}
      }
      """
    Then סטטוס התגובה צריך להיות 201
    And השדות הקריטיים קיימים: 'orderId', 'amount', 'currency', 'transactionId'
    And טיפול בשדות חדשים/חסרים נעשה ללא כשל

    Examples:
      | גרסה |
      | v1   |
      | v2   |

  @api @reliability @payments @retry @TC-NF-006
  Scenario: API - התאוששות מכשל זמני בשער תשלום (Retry)
    Given כתובת ה-API היא '${API_BASE_URL}'
    When אני שולח POST ל'/api/payments/charge' עם סימולציית כשל זמני:
      """
      {
        "amount": 299.00,
        "currency": "ILS",
        "method": "credit_card",
        "token": "tok_simulate_temporary_failure"
      }
      """
    Then סטטוס התגובה צריך להיות 503 והודעה: 'תקלה זמנית בתשלום, נסה שוב או בחר אמצעי אחר'
    When אני מנסה שוב עם אותו מטען לאחר 5 שניות
    Then הסטטוס צריך להיות 200/201 בהתאם והעסקה תתקבל ללא יצירת הזמנה כפולה

  @api @privacy @logging @monitoring @TC-NF-011
  Scenario: API - לוגים, ניטור והתראות ללא חשיפת PII
    Given מופעלת מערכת לוגים וניטור
    When אני מבצע הזמנה מוצלחת ושגויה
    Then בלוגים יופיעו: מזהה הזמנה, זמן, סטטוס ללא אימייל/טלפון גולמיים
    When אני מסמלץ שגיאת שער תשלום
    Then נשלחת התראה לצוות (Slack/Email) עם פרטים לא מזהים בלבד

  @api @reliability @shipping_outage @TC-NF-012
  Scenario: API - נפילת שירות משלוח ו-Fallback
    Given אני משבית זמנית את 'delivery_express' דרך '/api/shipping/providers/delivery_express/disable'
    When אני מבקש תעריפי משלוח לישראל
    Then מתקבלת הודעה על אי זמינות ואלטרנטיבה 'registered_mail' מוצעת
    When אני מפעיל מחדש את השירות דרך '/api/shipping/providers/delivery_express/enable'
    Then הבקשות חוזרות לתפקד כרגיל

  @api @security @tls @hsts @pci @TC-NF-005
  Scenario: API - הצפנת תעבורה ועמידה ב-PCI DSS (TLS/HSTS)
    Given אתר הבדיקה נגיש ב-HTTPS בלבד
    When אני מריץ סריקת SSL על '${API_BASE_URL}'
    Then יש תמיכה ב-TLS 1.2/1.3 ו-HSTS מופעל
    And אין שמירת PAN מלא בלוגים/DB ונעשה Tokenization לפרטי כרטיס

  # Non-Functional UI/API - ביצועים, סקיילביליות, אבטחה, סשן
  @performance @web @TC-NF-001
  Scenario: ביצועים - זמן טעינת דף הבית והקטגוריה (FCP/TTFB)
    Given סביבת בדיקות יציבה וכלי Lighthouse/WPT זמינים
    When אני מודד FCP לדף הבית 3 פעמים
    Then ממוצע FCP קטן מ-2 שניות
    When אני מודד FCP לעמוד קטגוריה 3 פעמים
    Then ממוצע FCP קטן מ-2.5 שניות
    When יש עומס של 200 משתמשים סימולטניים
    Then הירידה בביצועים אינה עולה על 20% וה-95th percentile נשלט

  @load @scalability @checkout @TC-NF-002
  Scenario Outline: סקיילביליות - צ'קאאוט תחת עומס עולה
    Given תרחיש צ'קאאוט מלא אוטומטי מוגדר
    When אני מריץ את התרחיש ל-<משתמשים> משתמשים במקביל
    Then אחוזי כשל < 1% וזמן תגובה ממוצע לצ'קאאוט < <SLA> שניות (עד 500)
    And ב-1000 משתמשים אין קריסה והירידה מבוקרת

    Examples:
      | משתמשים | SLA |
      | 100      | 3   |
      | 500      | 3   |
      | 1000     | 5   |

  @security @inputs @xss @sqli @TC-NF-003
  Scenario: אבטחה - ולידציית קלט, XSS ו-SQL Injection
    Given אני בעמודי צ'קאאוט וחיפוש
    When אני מזין "<script>alert(1)</script>" בשדות טקסט
    Then הקלט מסונן/מוסקר ואינו רץ בדפדפן
    When אני מזין "' OR 1=1 --" בשדות רלוונטיים
    Then אין הזרקת SQL והודעת שגיאה כללית ואינה חושפת פרטי מערכת

  @security @session @cookies @csrf @TC-NF-004
  Scenario: אבטחה - ניהול סשן, Cookies ו-CSRF
    Given אני נכנס לחשבון משתמש בדמה
    When אני בודק את ה-Cookies
    Then ה-Cookies מסומנים HttpOnly ו-Secure
    When אין פעילות במשך 30 דקות
    Then הסשן פג תוקף ונדרש להתחבר מחדש
    When אני מנסה פעולה רגישה ללא CSRF Token תקף
    Then הפעולה נחסמת

