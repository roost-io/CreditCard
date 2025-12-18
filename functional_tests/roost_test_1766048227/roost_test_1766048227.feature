Feature: מסחר אלקטרוני - חוויית רכישה, ולידציות, קופונים, משלוח, אבטחה וביצועים

  Background:
    Given כתובת האתר מוגדרת במשתנה סביבה 'WEB_BASE_URL'
    And בסיס ה-API מוגדר במשתנה סביבה 'API_BASE_URL'
    And סשן אורח התחלתי קיים עם זיהוי סשן

  # UI Tests
  @ui @TC-F-001
  Scenario: מסע רכישה מלא – מהבאנר הראשי ועד ולידציות בקופה (חסר מיקוד)
    Given אני נמצא בדף הבית בכתובת WEB_BASE_URL
    When אני לוחץ על הכפתור "SHOP NOW" בבאנר "Latest Eyewear For You"
    And אני גולל לתחתית עמוד הקטלוג ולוחץ על חץ "הבא" כדי לעבור לעמוד 2
    And אני בוחר את המוצר "Red Hoodie" באמצעות לחיצה על שם המוצר או התמונה
    And בדף המוצר אני לוחץ "ADD TO CART"
    And בהודעת ההוספה לסל אני לוחץ "VIEW CART"
    And בסל אני בוחר לפי הסדר: "Local pickup" ואז "Delivery Express" ואז "Registered Mail"
    And אני מאמת שהעלות הכוללת מתעדכנת: "Delivery Express" = "₪12.50", "Registered Mail" = "₪5.90", "Local pickup" = "₪0"
    And אני לוחץ "PROCEED TO CHECKOUT"
    And בעמוד הקופה אני ממלא:
      | שדה             | ערך                  |
      | First name      | Meital               |
      | Last name       | Kenzi                |
      | Company         | Menora               |
      | Country         | Israel               |
      | Street address  | Burla yehuda 1       |
      | Apartment/Unit  | 17                   |
      | Town/City       | Tel Aviv,            |
      | Phone           | 0544344345           |
      | Email           | meitalkenzi@gmail.com|
      | Postcode/ZIP    |                      |
    And אני לוחץ "PLACE ORDER"
    Then מוצגת הודעת שגיאה ברורה באזור ההודעות "Billing Postcode / ZIP is a required field."
    And לא נוצרת הזמנה והמשתמש נשאר בדף הקופה עם ערכים שמורים

  @ui @TC-F-002
  Scenario: המשך התסריט – הזנת מיקוד וקבלת שגיאת אמצעי תשלום
    Given אני נמצא בעמוד הקופה כאשר כל השדות מלאים למעט המיקוד
    When אני מזין בשדה "Postcode/ZIP" את הערך "316547"
    And אני לוחץ "PLACE ORDER"
    Then מוצגת הודעת שגיאה "Invalid payment method"
    And לא נוצרת הזמנה והמשתמש נשאר בדף הקופה עם הנתונים שמורים

  @ui @TC-F-003
  Scenario: מעבר לעמוד מס' 2 באמצעות לחיצה על הספרה 2
    Given עמוד קטלוג פתוח לאחר לחיצה על "SHOP NOW"
    When אני לוחץ על הספרה "2" בפאג'ינציה
    Then מוצגת אינדיקציה לעמוד 2 כגון "Showing 13–14 of 14 results"
    And הספרה "2" מסומנת כפעילה

  @ui @TC-F-004
  Scenario Outline: כניסה למוצר באמצעות שם המוצר לעומת התמונה
    Given עמוד 2 של הקטלוג פתוח
    When אני לוחץ על <אלמנט_לחיצה> של "Red Hoodie"
    Then נטען דף המוצר עם כותרת "Red Hoodie"
    And מוצג נתיב פירורי לחם "Home / Men / Red Hoodie"

    Examples:
      | אלמנט_לחיצה        |
      | שם המוצר            |
      | תמונת המוצר         |

  @ui @TC-F-005
  Scenario: הוספה לסל מדף הקטלוג (אם כפתור זמין)
    Given עמוד קטלוג שבו כפתור "Add to cart" זמין עבור "Red Hoodie"
    When אני לוחץ "Add to cart" בכרטיס של "Red Hoodie"
    Then מופיעה הודעת הצלחה/Toast שהמוצר נוסף
    And בהודעה אני לוחץ "VIEW CART" ומגיע לעמוד הסל
    And המוצר "Red Hoodie" מופיע בסל עם כמות 1, מחיר "₪150.00" ומטבע "₪"

  @ui @TC-F-006
  Scenario: עדכון כמויות וחישוב עלויות משלוח
    Given סל פתוח עם "Red Hoodie" בכמות 1
    When אני משנה כמות ל-2 ולוחץ "Update cart" אם נדרש
    And אני בוחר "Delivery Express"
    Then הסכום הכולל מתעדכן ל-300 ₪ + "₪12.50" משלוח
    When אני מחליף ל-"Registered Mail"
    Then המשלוח מתעדכן ל-"₪5.90" והסכום הכולל מחושב בהתאם
    When אני מחליף ל-"Local pickup"
    Then המשלוח הוא "₪0" והסכום הכולל הוא 300 ₪

  @ui @TC-F-007 @TC-F-008
  Scenario Outline: קופון תקף לעומת קופון לא תקף
    Given סל פתוח עם לפחות פריט אחד
    When אני פותח את אזור הקופון ולוחץ "Have a coupon? Click here to enter your code"
    And אני מזין את הקוד "<קוד_קופון>" ולוחץ "Apply coupon"
    Then <תוצאה_צפויה>

    Examples:
      | קוד_קופון | תוצאה_צפויה                                                                                       |
      | SALE10    | מוצגת שורת קופון עם סכום הנחה, סכום סופי מתעדכן במטבע "₪", ומופיעה הודעת הצלחה                   |
      | ABC123    | מוצגת הודעת שגיאה ידידותית (בעברית אם האתר בעברית) וללא שינוי בסכום הכולל                         |

  @ui @TC-F-009
  Scenario Outline: תהליך הזמנה מוצלח עם אמצעי תשלום זמין
    Given סל עם פריט אחד וכתובת בישראל
    When אני לוחץ "PROCEED TO CHECKOUT"
    And אני ממלא את כל פרטי החיוב כולל מיקוד תקין "6473421"
    And אני בוחר שיטת משלוח "Local pickup"
    And אני בוחר אמצעי תשלום "<אמצעי_תשלום>"
    And אני מסמן הסכמה למדיניות אם נדרש
    And אני לוחץ "PLACE ORDER"
    Then מוצג עמוד אישור הזמנה עם מספר הזמנה
    And מתקבל מייל אישור לכתובת שהוזנה
    And אין הודעות שגיאה

    Examples:
      | אמצעי_תשלום          |
      | Direct Bank Transfer |
      | Cash on Delivery     |

  @ui @TC-F-010
  Scenario: שמירת סל לאחר רענון/ניווט חזרה/פתיחה מחדש
    Given סל עם פריט אחד לפחות
    When אני מרענן את עמוד הסל
    Then הפריטים נשמרים בסל
    When אני נווט לעמוד הבית וחוזר לעמוד הסל
    Then הפריטים נשמרים בסל
    When אני סוגר את הדפדפן, פותח מחדש את האתר וחוזר לסל באותו התקן ודפדפן
    Then הפריטים עדיין בסל

  @ui @TC-F-011
  Scenario: הסרת פריט מהסל
    Given סל עם לפחות פריט אחד
    When אני לוחץ על האייקון "X" ליד הפריט בסל
    Then מופיעה הודעת "Cart updated" אם קיימת
    And הפריט נמחק והסכום הכולל מתעדכן
    And אם הסל ריק מוצג כפתור "Return to shop"

  @ui @TC-F-012
  Scenario: בדיקת Breadcrumbs וניווט חזרה לקטגוריה
    Given דף המוצר "Red Hoodie" פתוח
    When אני לוחץ על "Men" ב-Breadcrumbs
    Then אני נוחת בעמוד קטגוריית Men הנכון

  @ui @TC-F-013
  Scenario: הזנת פרטי חיוב בעברית ו-RTL
    Given שפת האתר היא עברית
    When אני ממלא שם פרטי "דנה", שם משפחה "כהן", רחוב "יהודה הלוי 10", עיר "תל אביב", מיקוד "6473421", טלפון "0521234567", אימייל "dana@example.com"
    And אני לוחץ "PLACE ORDER" (עם אמצעי תשלום תקף אם קיים)
    Then אין בעיות כיווניות/יישור וכל השדות בעברית מוצגים נכון
    And אם חסר מידע מוצגות הודעות בעברית והפוקוס מוצב על השדה הבעייתי

  @ui @TC-F-014
  Scenario Outline: ולידציות שדות – אימייל/טלפון/מיקוד לא חוקיים
    Given עמוד קופה פתוח
    When אני מזין אימייל "<אימייל>", טלפון "<טלפון>", מיקוד "<מיקוד>"
    And אני לוחץ "PLACE ORDER"
    Then מוצגות שגיאות ספציפיות לכל שדה והמשך התהליך נחסם
    And הפוקוס מוצב על השדה הבעייתי הראשון

    Examples:
      | אימייל             | טלפון        | מיקוד    |
      | userexample.com    | 05A12B34C    | 1234AB7  |
      | user@domain        | 052-12A-5678 | 123      |
      | user@@example.com  | 0521234xyz   | 12345678 |

  @ui @TC-F-015
  Scenario: שינוי שפה לאנגלית וחזרה לעברית
    Given טופס קופה מלא בערכים
    When אני מחליף שפה ל-"English"
    Then הטקסטים מתורגמים והכיווניות משתנה ל-LTR
    When אני חוזר לעברית
    Then הנתונים בטופס נשמרו והכיווניות חוזרת ל-RTL

  @ui @TC-F-016
  Scenario: נגישות – שימוש מלא במקלדת
    Given דפדפן תומך מקשים ואלמנטי ממשק נגישים
    When אני מנווט עם Tab ל-"SHOP NOW" ומפעיל ב-Enter
    And אני מוסיף מוצר לסל ומנווט ל-"View cart" עם Tab
    And אני ממשיך לקופה וממלא פרטים באמצעות מקלדת בלבד
    And אני לוחץ "PLACE ORDER" באמצעות Enter
    Then סדר הפוקוס הגיוני וכל רכיב ניתן לגישה ואין מלכודות פוקוס

  @ui @TC-F-017
  Scenario: התנהגות במצב חוסר מלאי
    Given מוצר שהוגדר "Out of stock" פתוח
    When אני מנסה להוסיף לסל
    Then כפתור הוספה לסל מושבת או מוסתר ומוצגת הודעה "אזל מהמלאי"

  @ui @TC-F-018
  Scenario: כשל רשת במהלך תשלום ושחזור
    Given עמוד קופה עם פרטים מלאים
    When אני מנתק את הרשת ומייד לוחץ "PLACE ORDER"
    Then מוצגת הודעת כשל זמני ידידותית והנתונים נשמרים
    When אני משחזר את הרשת ומנסה שוב
    Then התהליך מצליח ללא יצירת הזמנות כפולות

  @ui @TC-F-019
  Scenario: התנהגות לאחר לחיצה כפולה על PLACE ORDER
    Given עמוד קופה מוכן להגשה ואמצעי תשלום תקף פעיל
    When אני לוחץ פעמיים במהירות על "PLACE ORDER"
    Then נוצרת הזמנה אחת בלבד והכפתור ננעל או מוצג Spinner לאחר הלחיצה הראשונה

  @ui @TC-F-020
  Scenario: Responsive – ניווט, פאג'ינציה וכפתורים במובייל
    Given אמולציית מובייל או מכשיר אמיתי פעיל
    When אני פותח את דף הבית במובייל
    And אם יש תפריט המבורגר אני פותח אותו ומנווט לקטלוג דרך "SHOP NOW"
    And אני עובר לעמוד 2 באמצעות החץ הבא
    And אני בוחר "Red Hoodie" ומוסיף לסל
    Then כל הכפתורים קריאים, לא קיימת גלילה אופקית והכפתורים ניתנים ללחיצה

  @ui @TC-F-021
  Scenario: בדיקת שינוי מיון קטלוג ושימור בחירה
    Given עמוד קטלוג פתוח
    When אני בוחר מיון "Price: low to high"
    Then סדר כרטיסי המוצרים משתנה בהתאם
    When אני נכנס למוצר וחוזר אחורה
    Then בחירת המיון נשמרת והסדר נשאר לפי המחיר

  @ui @TC-F-022
  Scenario: בדיקת דירוג מוצר ותצוגת ביקורות
    Given דף מוצר פתוח עם אזור ביקורות
    When אני גולל לאזור הביקורות
    And אם מתאפשר לאורחים אני בוחר 4 כוכבים, מזין תגובה ושולח
    Then הביקורת נשמרת ומוצגת עם חיווי כוכבים
    But אם נדרש להתחבר מוצגת הודעה שיש להתחבר כדי לדרג

  @ui @TC-F-023
  Scenario: חישוב מע"מ ישראלי והצגת מטבע
    Given מיקום החיוב/משלוח מוגדר לישראל והגדרות מס פעילות
    When אני מוסיף מוצר לסל ומנווט לקופה
    Then המטבע "₪" מוצג בעקביות
    And אם מע"מ מופעל מוצגת שורת מע"מ 17% והסכומים תואמים

  @ui @TC-F-024
  Scenario: בדיקת טופס – סימון חובה והבלטת שגיאות
    Given דף קופה בעברית פתוח
    When אני לוחץ "PLACE ORDER" עם טופס ריק
    Then כל שדות החובה מסומנים בצורה ברורה
    And מופיע טקסט שגיאה קריא בעברית תחת כל שדה חסר

  @ui @TC-F-025
  Scenario: פונקציית View Cart – ניווט נכון וקריאה לפעולה
    Given הוספתי מוצר לסל מדף מוצר וקיבלתי הודעה צפה
    When אני לוחץ "VIEW CART" בהודעה
    Then עמוד הסל נטען וקיים מסלול חזרה לקניות

  @ui @TC-F-026
  Scenario Outline: בדיקת ריבוי שיטות משלוח ועדכון סכום ותיאור זמן אספקה
    Given סל עם פריט אחד פתוח
    When אני בוחר שיטת משלוח "<שיטה>"
    Then תוספת המשלוח היא "<עלות>"
    And מוצג תיאור זמן אספקה "<תיאור>"

    Examples:
      | שיטה             | עלות    | תיאור         |
      | Local pickup     | ₪0      |               |
      | Delivery Express | ₪12.50  | (1–3 days)    |
      | Registered Mail  | ₪5.90   | (5–8 days)    |

  @ui @TC-F-027
  Scenario: השוואת הוספה לסל מול הסרה – סכום כולל חוזר לברירת מחדל
    Given סל ריק בתחילת התרחיש
    When אני מוסיף "Red Hoodie" ובוחר "Registered Mail"
    And אני מסיר את הפריט מהסל
    Then הטוטאל מאופס ל-"₪0" ושורת המשלוח מוסרת

  # API Tests (נ infer לפי אינטראקציות קופה/סל/קופון/משלוח)
  @api @checkout @TC-F-001 @TC-F-002
  Scenario Outline: ולידציות Checkout ב-API – חסר מיקוד לעומת אמצעי תשלום לא תקין
    Given יש לי מזהה סשן אורח ושמור פריט בסל באמצעות POST ל-"/api/cart/items"
    And גוף הבקשה להוספת פריט:
      """
      {
        "product_id": 12345,
        "quantity": 1
      }
      """
    When אני שולח POST ל-"/api/checkout" עם גוף בקשה:
      """
      {
        "billing": {
          "first_name": "Meital",
          "last_name": "Kenzi",
          "company": "Menora",
          "country": "IL",
          "address_1": "Burla yehuda 1",
          "address_2": "17",
          "city": "Tel Aviv",
          "postcode": <postcode>,
          "phone": "0544344345",
          "email": "meitalkenzi@gmail.com"
        },
        "shipping_method": "registered_mail",
        "payment_method": <payment_method>
      }
      """
    Then קוד התגובה צריך להיות <status>
    And גוף התגובה צריך להכיל את ההודעה "<expected_message>"

    Examples:
      | postcode | payment_method | status | expected_message                                 |
      | null     | "bank_transfer"| 400    | Billing Postcode / ZIP is a required field.      |
      | "316547" | "invalid"      | 400    | Invalid payment method                           |

  @api @coupons @TC-F-007 @TC-F-008
  Scenario Outline: החלת קופון ב-API – הצלחה ושגיאה
    Given סל קיים עם פריט אחד באמצעות סשן אורח
    When אני שולח POST ל-"/api/coupons/apply" עם גוף:
      """
      {
        "code": "<code>"
      }
      """
    Then קוד התגובה צריך להיות <status>
    And גוף התגובה צריך להכיל את השדה "<expected_field>"

    Examples:
      | code   | status | expected_field   |
      | SALE10 | 200    | discount_amount  |
      | ABC123 | 400    | error            |

  @api @shipping @TC-F-026
  Scenario Outline: עדכון שיטת משלוח ב-API והצלבת סכומים
    Given קיים בסל פריט אחד בעל מחיר יחידה 150 ₪
    When אני שולח PUT ל-"/api/cart/shipping" עם גוף:
      """
      {
        "method": "<method>"
      }
      """
    Then קוד התגובה צריך להיות 200
    And סכום המשלוח בתגובה הוא "<shipping_cost>"

    Examples:
      | method           | shipping_cost |
      | local_pickup     | ₪0            |
      | delivery_express | ₪12.50        |
      | registered_mail  | ₪5.90         |

  @api @orders @TC-F-009
  Scenario: יצירת הזמנה תקינה ב-API
    Given סל קיים עם פריט אחד ושיטת משלוח "local_pickup"
    When אני שולח POST ל-"/api/orders" עם גוף:
      """
      {
        "billing": {
          "first_name": "Dana",
          "last_name": "Cohen",
          "country": "IL",
          "address_1": "Yehuda Halevi 10",
          "city": "Tel Aviv",
          "postcode": "6473421",
          "phone": "0521234567",
          "email": "dana@example.com"
        },
        "payment_method": "bank_transfer",
        "confirm": true
      }
      """
    Then קוד התגובה צריך להיות 201
    And גוף התגובה צריך להכיל "order_id" ו-"status"="processing"

  @api @cart @TC-F-010
  Scenario: התמדה של סל ב-API באמצעות סשן
    Given הוספתי פריט לסל עם מזהה סשן X
    When אני שולח GET ל-"/api/cart" עם כותרת "X-Session-Id: X"
    Then קוד התגובה צריך להיות 200
    And הגוף מכיל את הפריט שנוסף קודם

  # Non-Functional Tests
  @nonfunctional @performance @TC-NF-001
  Scenario Outline: ביצועים – זמני טעינה ותגובה בתהליך רכישה
    Given מצב רשת 4G סטנדרטי מוגדר בכלי המדידה
    When אני מודד את "<מדד>" עבור "<מסך/פעולה>"
    Then התוצאה צריכה להיות קטנה מ-<סף> שניות

    Examples:
      | מדד | מסך/פעולה                          | סף |
      | TTI | דף הבית                            | 3  |
      | זמן| לחיצה "Add to cart" עד הודעת הצלחה | 1.5|
      | זמן| טעינת דף הקופה                      | 2  |

  @nonfunctional @load @TC-NF-002
  Scenario: סקיילביליות – עומס משתמשים בו-זמנית
    Given תרחיש עומס ב-JMeter: כניסה → קטלוג → Add to cart → View cart → Checkout
    When אני מריץ עומס מדורג 50 → 100 → 300 משתמשים בו-זמנית
    Then שיעור שגיאות < 1% וזמני תגובה יציבים או דגרדציה נשלטת ללא קריסות

  @nonfunctional @security @TC-NF-003
  Scenario: אבטחה – TLS, HSTS, Cookie Flags ו-CSRF
    Given אני מריץ סריקת SSL Labs לאתר
    When אני בודק כותרות HTTP ל-HSTS, Cookie Secure/HttpOnly/SameSite
    And אני מאמת קיום nonce/CSRF בטפסי "Add to cart"/"Checkout"
    Then הדירוג הוא A, אין העברת PII ב-HTTP ומנגנוני CSRF פעילים

  @nonfunctional @privacy @TC-NF-004
  Scenario: פרטיות – מדיניות פרטיות והסכמות
    Given עמוד "privacy policy" קיים ונגיש בקופה
    When אני פותח את הקישור ובוחן שימוש ב-PII והעברות לצד ג'
    Then המדיניות ברורה, אין איסוף מיותר וקיימות דרכי יצירת קשר למימוש זכויות

  @nonfunctional @pci @TC-NF-005
  Scenario: אבטחת תשלומים – ציות ל-PCI DSS
    Given סביבת סנדבוקס של ספק תשלום פעילה
    When אני מאמת שטפסי תשלום נטענים מדומיין הספק (Iframe/Redirect) ואין אחסון PAN באתר
    And אני בודק שלוגים אינם מכילים PII/פרטי כרטיס
    Then אין דליפת נתונים והודעות שגיאה אינן חושפות מידע רגיש

  @nonfunctional @reliability @TC-NF-006
  Scenario: אמינות – התמדה של סל לאחר timeout/ניתוק
    Given סל עם פריטים קיים
    When אני ממתין 30–45 דקות ללא פעילות ומרענן דף
    Then הסל עדיין קיים או מוצגת הודעה מתאימה על פקיעת סשן

  @nonfunctional @accessibility @TC-NF-007
  Scenario: נגישות – תאימות WCAG 2.1 AA
    Given התקנתי axe/WAVE בדפדפן
    When אני סורק דף הבית, קטלוג, מוצר וקופה
    Then אין כשלים קריטיים, לכל תמונה Alt, לכל שדה תווית, ויחס ניגודיות ≥ 4.5:1

  @nonfunctional @compatibility @TC-NF-008
  Scenario Outline: התאמה בין דפדפנים ומערכות הפעלה
    Given דפדפן "<דפדפן>" על פלטפורמה "<פלטפורמה>" פעיל
    When אני מבצע את התסריט TC-F-001 מקצה לקצה
    Then ההתנהגות אחידה וללא שברים פריסתיים

    Examples:
      | דפדפן   | פלטפורמה  |
      | Chrome  | Windows   |
      | Firefox | Windows   |
      | Edge    | Windows   |
      | Safari  | iOS       |
      | Chrome  | Android   |

  @nonfunctional @logging @TC-NF-009
  Scenario: ניטור ולוגים – תיעוד עסקאות ושגיאות
    Given גישה ללוגי השרת/יישום
    When אני מבצע הזמנה מוצלחת והזמנה כושלת
    Then בלוגים מופיעים מזהה הזמנה, מזהה סשן וסטטוס תשלום ללא PII מלא ועם יכולת קורלציה

  @nonfunctional @thirdparty @TC-NF-010
  Scenario: התאוששות מכשל שירות צד-שלישי (Gateway 5xx)
    Given יכולת לדמות כשל 503 ב-Gateway תשלום
    When אני מנסה "PLACE ORDER" בזמן הכשל
    Then לא נוצרת הזמנה ומוצגת הודעת שגיאה ידידותית
    When השירות חוזר ואני מנסה שוב
    Then נוצרת הזמנה אחת בלבד

  @nonfunctional @security @xss @TC-NF-011
  Scenario: מניעת XSS/Injection בשדות הכתובת
    Given עמוד קופה פתוח
    When אני מזין בשדה "Company" את הטקסט "<script>alert(1)</script>" ומגיש
    Then לא מתבצעת הרצת סקריפט והטקסט מוצג כטקסט/מסונן בכל התצוגות

  @nonfunctional @privacy @referrer @TC-NF-012
  Scenario: מניעת דליפת פרטי לקוח ב-Referrer
    Given DevTools פתוח בלשונית Network
    When אני נווט לקישור חיצוני (למשל ספק תשלום)
    Then כותרת 'Referer' אינה מכילה PII ומוגדרת מדיניות Strict-Origin-When-Cross-Origin או דומה

  @nonfunctional @i18n @TC-NF-013
  Scenario: יציבות RTL/LTR במעבר בין שפות
    Given מתג שפה פעיל באתר
    When אני עובר לאנגלית ובודק שהמטבע "₪" נשאר
    And אני חוזר לעברית ובודק שהפאג'ינציה מיושרת לימין
    Then אין שבירת UI והמטבע נשאר "₪" בכל שפה
