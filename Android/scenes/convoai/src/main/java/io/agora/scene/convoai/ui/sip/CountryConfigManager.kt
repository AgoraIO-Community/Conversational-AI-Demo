package io.agora.scene.convoai.ui.sip

import io.agora.scene.convoai.api.CovSipCallee

/**
 * Enum representing a country configuration
 * Equivalent to Swift's CountryConfig but more convenient
 */
enum class CountryConfig(val flagEmoji: String, val dialCode: String) {
    // Asia
    CN("🇨🇳", "+86"),
    JP("🇯🇵", "+81"),
    KR("🇰🇷", "+82"),
    IN("🇮🇳", "+91"),
    SG("🇸🇬", "+65"),
    TH("🇹🇭", "+66"),
    MY("🇲🇾", "+60"),
    ID("🇮🇩", "+62"),
    PH("🇵🇭", "+63"),
    VN("🇻🇳", "+84"),
    TW("🇹🇼", "+886"),
    HK("🇭🇰", "+852"),
    MO("🇲🇴", "+853"),
    
    // Europe
    GB("🇬🇧", "+44"),
    DE("🇩🇪", "+49"),
    FR("🇫🇷", "+33"),
    IT("🇮🇹", "+39"),
    ES("🇪🇸", "+34"),
    RU("🇷🇺", "+7"),
    NL("🇳🇱", "+31"),
    CH("🇨🇭", "+41"),
    AT("🇦🇹", "+43"),
    BE("🇧🇪", "+32"),
    SE("🇸🇪", "+46"),
    NO("🇳🇴", "+47"),
    DK("🇩🇰", "+45"),
    FI("🇫🇮", "+358"),
    PL("🇵🇱", "+48"),
    CZ("🇨🇿", "+420"),
    HU("🇭🇺", "+36"),
    RO("🇷🇴", "+40"),
    BG("🇧🇬", "+359"),
    GR("🇬🇷", "+30"),
    PT("🇵🇹", "+351"),
    IE("🇮🇪", "+353"),
    LU("🇱🇺", "+352"),
    
    // North America
    US("🇺🇸", "+1"),
    CA("🇨🇦", "+1"),
    MX("🇲🇽", "+52"),
    
    // South America
    BR("🇧🇷", "+55"),
    AR("🇦🇷", "+54"),
    CL("🇨🇱", "+56"),
    CO("🇨🇴", "+57"),
    PE("🇵🇪", "+51"),
    VE("🇻🇪", "+58"),
    UY("🇺🇾", "+598"),
    PY("🇵🇾", "+595"),
    BO("🇧🇴", "+591"),
    EC("🇪🇨", "+593"),
    GY("🇬🇾", "+592"),
    SR("🇸🇷", "+597"),
    
    // Africa
    ZA("🇿🇦", "+27"),
    EG("🇪🇬", "+20"),
    NG("🇳🇬", "+234"),
    KE("🇰🇪", "+254"),
    MA("🇲🇦", "+212"),
    TN("🇹🇳", "+216"),
    DZ("🇩🇿", "+213"),
    GH("🇬🇭", "+233"),
    ET("🇪🇹", "+251"),
    UG("🇺🇬", "+256"),
    TZ("🇹🇿", "+255"),
    ZW("🇿🇼", "+263"),
    ZM("🇿🇲", "+260"),
    BW("🇧🇼", "+267"),
    NA("🇳🇦", "+264"),
    MW("🇲🇼", "+265"),
    MZ("🇲🇿", "+258"),
    MG("🇲🇬", "+261"),
    MU("🇲🇺", "+230"),
    SC("🇸🇨", "+248"),
    RE("🇷🇪", "+262"),
    
    // Oceania
    AU("🇦🇺", "+61"),
    NZ("🇳🇿", "+64"),
    FJ("🇫🇯", "+679"),
    PG("🇵🇬", "+675"),
    NC("🇳🇨", "+687"),
    VU("🇻🇺", "+678"),
    SB("🇸🇧", "+677"),
    TO("🇹🇴", "+676"),
    WS("🇼🇸", "+685"),
    KI("🇰🇮", "+686"),
    TV("🇹🇻", "+688"),
    NR("🇳🇷", "+674"),
    PW("🇵🇼", "+680"),
    MH("🇲🇭", "+692"),
    FM("🇫🇲", "+691"),
    
    // Middle East
    AE("🇦🇪", "+971"),
    SA("🇸🇦", "+966"),
    QA("🇶🇦", "+974"),
    KW("🇰🇼", "+965"),
    BH("🇧🇭", "+973"),
    OM("🇴🇲", "+968"),
    JO("🇯🇴", "+962"),
    LB("🇱🇧", "+961"),
    SY("🇸🇾", "+963"),
    IQ("🇮🇶", "+964"),
    IR("🇮🇷", "+98"),
    IL("🇮🇱", "+972"),
    PS("🇵🇸", "+970"),
    TR("🇹🇷", "+90"),
    CY("🇨🇾", "+357"),
    
    // Other Important Countries
    IS("🇮🇸", "+354"),
    MT("🇲🇹", "+356"),
    EE("🇪🇪", "+372"),
    LV("🇱🇻", "+371"),
    LT("🇱🇹", "+370"),
    SK("🇸🇰", "+421"),
    SI("🇸🇮", "+386"),
    HR("🇭🇷", "+385"),
    RS("🇷🇸", "+381"),
    BA("🇧🇦", "+387"),
    ME("🇲🇪", "+382"),
    MK("🇲🇰", "+389"),
    AL("🇦🇱", "+355"),
    XK("🇽🇰", "+383"),
    MD("🇲🇩", "+373"),
    UA("🇺🇦", "+380"),
    BY("🇧🇾", "+375"),
    GE("🇬🇪", "+995"),
    AM("🇦🇲", "+374"),
    AZ("🇦🇿", "+994"),
    KZ("🇰🇿", "+7"),
    UZ("🇺🇿", "+998"),
    KG("🇰🇬", "+996"),
    TJ("🇹🇯", "+992"),
    TM("🇹🇲", "+993"),
    AF("🇦🇫", "+93"),
    PK("🇵🇰", "+92"),
    BD("🇧🇩", "+880"),
    LK("🇱🇰", "+94"),
    MV("🇲🇻", "+960"),
    BT("🇧🇹", "+975"),
    NP("🇳🇵", "+977"),
    MM("🇲🇲", "+95"),
    LA("🇱🇦", "+856"),
    KH("🇰🇭", "+855"),
    BN("🇧🇳", "+673"),
    TL("🇹🇱", "+670"),
    MN("🇲🇳", "+976"),
    KP("🇰🇵", "+850");
    
    /**
     * Get country code (enum name)
     */
    val countryCode: String get() = name
}

/**
 * Extension functions for CountryConfig to work with CovSipCallee
 */
fun CountryConfigManager.findByRegionCode(regionCode: String): CountryConfig? {
    return allCountries.firstOrNull { 
        it.countryCode == regionCode.uppercase() 
    }
}

fun CountryConfigManager.fromSipCallees(sipCallees: List<CovSipCallee>): List<CountryConfig> {
    return sipCallees.mapNotNull { callee ->
        findByRegionCode(callee.region_code)
    }.distinctBy { it.countryCode }
}

/**
 * Country Configuration Manager
 * Now using enum for better performance and type safety
 */
object CountryConfigManager {
    
    /**
     * All countries configuration
     * Now using enum values directly
     */
    val allCountries: List<CountryConfig> = CountryConfig.values().toList()
    
    /**
     * Get country by country code
     * Equivalent to Swift's getCountryByCode method
     */
    fun getCountryByCode(countryCode: String): CountryConfig? {
        return try {
            CountryConfig.valueOf(countryCode.uppercase())
        } catch (e: IllegalArgumentException) {
            null
        }
    }
    
    /**
     * Get country by dial code
     */
    fun getCountryByDialCode(dialCode: String): CountryConfig? {
        return allCountries.find { it.dialCode == dialCode }
    }
}
