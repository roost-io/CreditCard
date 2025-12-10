# language: he
Feature: תהליך רכישת מוצר באתר "עתיד האוטומציה"

  @ui @regression
  Scenario: ביצוע תהליך רכישה מלא עם ולידציה של שגיאות צפויות
    Given אני נמצא בדף הבית של האתר "https://share.google/gX4PkITYxjSjISHwh"
    When אני לוחץ על כפתור "SHOP NOW" בקטגוריית "Latest Eyewear For You"
    And אני מנווט לעמוד מספר 2
    And אני בוחר במוצר "Red Hoodie"
    And אני לוחץ על כפתור "ADD TO CART"
    And אני לוחץ על כפתור "VIEW CART"
    And אני בוחר בשיטת משלוח "Delivery Express"
    And אני לוחץ על כפתור "PROCEED TO CHECKOUT"
    And אני ממלא את פרטי החיוב הבאים בטופס:
      | שדה              | ערך                  |
      | First name       | ישראל                |
      | Last name        | ישראלי               |
      | Street address   | הרצל 10              |
      | Town / City      | תל אביב              |
      | State            | המרכז                |
      | Phone            | 0501234567           |
      | Email address    | test@automation.com  |
    And אני לוחץ על כפתור "PLACE ORDER"
    Then אני אמור לראות הודעת שגיאה המציינת ששדה המיקוד הוא שדה חובה
    When אני ממלא את השדה "Postcode / ZIP" עם הערך "6514910"
    And אני לוחץ שוב על כפתור "PLACE ORDER"
    Then אני אמור לראות הודעת שגיאה "Invalid payment method"

  @ui @checkout @negative
  Scenario Outline: בדיקת ולידציה של שדות חובה בטופס התשלום
    Given הוספתי את המוצר "Red Hoodie" לעגלה והגעתי לדף התשלום
    When אני ממלא את כל פרטי החיוב פרט לשדה "<שדה_חסר>"
    And אני לוחץ על כפתור "PLACE ORDER"
    Then אני אמור לראות הודעת שגיאה עבור שדה חובה "<שדה_חסר>"

    Examples:
      | שדה_חסר          |
      | First name       |
      | Last name        |
      | Street address   |
      | Town / City      |
      | Postcode / ZIP   |
      | Phone            |
      | Email address    |

  @ui @cart @positive
  Scenario Outline: בחירת מוצרים שונים ושיטות משלוח
    Given אני נמצא בדף המוצרים לאחר לחיצה על "SHOP NOW"
    When אני מנווט לעמוד מספר <מספר_עמוד>
    And אני בוחר במוצר "<שם_מוצר>" ומוסיף אותו לעגלה
    And אני צופה בעגלת הקניות
    Then אני אמור לראות את המוצר "<שם_מוצר>" בעגלה
    When אני בוחר בשיטת משלוח "<שיטת_משלוח>"
    Then שיטת המשלוח "<שיטת_משלוח>" צריכה להיות מסומנת

    Examples:
      | מספר_עמוד | שם_מוצר      | שיטת_משלוח       |
      | 1          | Black Hoodie | Local pickup      |
      | 2          | Red Hoodie   | Delivery Express  |
      | 3          | Green Hoodie | Registered Mail   |

  @ui @checkout @negative
  Scenario Outline: בדיקת ערכים לא תקינים בשדות טופס התשלום
    Given הוספתי את המוצר "Red Hoodie" לעגלה והגעתי לדף התשלום
    When אני ממלא את השדה "<שם_שדה>" עם הערך הלא תקין "<ערך_לא_תקין>"
    And אני ממלא את שאר שדות החובה עם ערכים תקינים
    And אני לוחץ על כפתור "PLACE ORDER"
    Then אני אמור לראות הודעת שגיאה מתאימה עבור "<שם_שדה>"

    Examples:
      | שם_שדה        | ערך_לא_תקין       |
      | Phone         | abcde             |
      | Phone         | 123               |
      | Email address | test@automation   |
      | Email address | test.automation.com |
      | Postcode / ZIP| מיקוד לא תקין     |
