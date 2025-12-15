# language: he
Feature: תהליך רכישת מוצר בחנות האונליין

  # תרחיש זה מכסה את זרימת המשתמש המלאה כפי שתוארה בדרישות,
  # כולל ניווט, הוספת מוצר לעגלה, ומילוי טופס תשלום עם נתונים חסרים
  # כדי לוודא שהודעות השגיאה הנכונות מוצגות למשתמש.

  @ui @regression @checkout
  Scenario: אימות הצגת שגיאות בתהליך תשלום עם נתונים חסרים
    Given אני נמצא בדף הבית בכתובת "https://share.google/gX4PkITYxjSjISHwh"
    And לחצתי על כפתור "SHOP NOW" בקטגוריית "Latest Eyewear For You"
    And ניווטתי לעמוד מוצרים מספר 2
    And בחרתי במוצר בשם "Red Hoodie"
    And לחצתי על כפתור "ADD TO CART"
    And לחצתי על כפתור "VIEW CART"
    And בחרתי בשיטת משלוח "Local pickup"
    And בחרתי בשיטת משלוח "Delivery Express"
    And בחרתי בשיטת משלוח "Registered Mail"
    And לחצתי על כפתור "PROCEED TO CHECKOUT"
    When אני ממלא את פרטי החיוב הבאים:
      | שדה          | ערך             |
      | First name   | ישראל          |
      | Last name    | ישראלי          |
      | Street address | הרצל 10         |
      | Town / City  | תל אביב         |
      | Phone        | 0501234567      |
      | Email address| test@test.com   |
    And אני לוחץ על כפתור "PLACE ORDER"
    Then אני אמור לראות את הודעת השגיאה "Billing Postcode / ZIP is a required field."
    When אני מזין "12345" בשדה "Postcode / ZIP"
    And אני לוחץ על כפתור "PLACE ORDER"
    Then אני אמור לראות את הודעת השגיאה "Invalid payment method."

  # תרחיש זה בודק את מסלול ה"Happy Path" - רכישה מוצלחת עם כל הנתונים תקינים.
  # שימוש ב-Scenario Outline מאפשר לבדוק את התהליך עם סטים שונים של נתונים תקינים בעתיד.

  @ui @smoke @checkout
  Scenario Outline: ביצוע רכישה מוצלחת של מוצר עם נתונים תקינים
    Given הוספתי את המוצר "Red Hoodie" לעגלה וניגשתי לדף התשלום
    When אני ממלא את כל פרטי החיוב עם "<שם פרטי>", "<שם משפחה>", "<כתובת>", "<עיר>", "<מיקוד>", "<טלפון>" ו-"<אימייל>"
    And אני בוחר אמצעי תשלום תקין
    And אני מסכים לתנאי השימוש
    And אני לוחץ על כפתור "PLACE ORDER"
    Then אני אמור לראות את הודעת אישור ההזמנה "Thank you. Your order has been received."

    Examples:
      | שם פרטי | שם משפחה | כתובת      | עיר      | מיקוד  | טלפון     | אימייל              |
      | משה     | כהן      | ז'בוטינסקי 5 | רמת גן   | 5252005 | 0528765432 | moshe@example.com    |
      | דנה     | לוי      | אבן גבירול 33 | תל אביב  | 6407807 | 0541122334 | dana@example.com     |

  # תרחיש זה מתמקד בבדיקות ולידציה שליליות על טופס התשלום.
  # הוא בודק ששדות חובה אכן נדרשים ושהודעות שגיאה מתאימות מוצגות עבור כל שדה חסר.
  # זה מכסה מקרי קצה ובדיקות שליליות באופן שיטתי.

  @ui @regression @validation
  Scenario Outline: בדיקת ולידציות בטופס התשלום עם נתונים חסרים או שגויים
    Given הוספתי את המוצר "Red Hoodie" לעגלה וניגשתי לדף התשלום
    When אני ממלא את טופס התשלום עם הנתונים הבאים: "<שם פרטי>", "<שם משפחה>", "<כתובת>", "<עיר>", "<מיקוד>", "<טלפון>" ו-"<אימייל>"
    And אני לוחץ על כפתור "PLACE ORDER"
    Then אני אמור לראות את הודעת השגיאה "<הודעת שגיאה>"

    Examples:
      | שם פרטי | שם משפחה | כתובת      | עיר      | מיקוד  | טלפון     | אימייל           | הודעת שגיאה                                      |
      |         | ישראלי    | הרצל 10    | תל אביב  | 12345  | 0501234567 | test@test.com     | Billing First name is a required field.           |
      | ישראל   |           | הרצל 10    | תל אביב  | 12345  | 0501234567 | test@test.com     | Billing Last name is a required field.            |
      | ישראל   | ישראלי    |            | תל אביב  | 12345  | 0501234567 | test@test.com     | Billing Street address is a required field.       |
      | ישראל   | ישראלי    | הרצל 10    |          | 12345  | 0501234567 | test@test.com     | Billing Town / City is a required field.          |
      | ישראל   | ישראלי    | הרצל 10    | תל אביב  |        | 0501234567 | test@test.com     | Billing Postcode / ZIP is a required field.       |
      | ישראל   | ישראלי    | הרצל 10    | תל אביב  | 12345  |            | test@test.com     | Billing Phone is a required field.                |
      | ישראל   | ישראלי    | הרצל 10    | תל אביב  | 12345  | 0501234567 |                   | Billing Email address is a required field.        |
      | ישראל   | ישראלי    | הרצל 10    | תל אביב  | 12345  | 0501234567 | not-an-email      | Billing Email address is not a valid email address. |

