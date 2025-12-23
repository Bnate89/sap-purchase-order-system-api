%dw 2.0
output application/json
/**
 * SAP Search Results to Canonical PurchaseOrder Array Transformation
 * 
 * This transformation maps SAP search results (from MAKT/LFA1 tables)
 * to an array of canonical PurchaseOrder objects.
 * 
 * Input: SAP RFC_READ_TABLE response for PO search
 * Output: Array of Canonical PurchaseOrder JSON objects
 */

// Helper function to format SAP date (YYYYMMDD) to ISO date
fun formatSapDate(sapDate: String): Date | Null = 
    if (sapDate != null and sapDate != "00000000" and sizeOf(sapDate) == 8)
        sapDate as Date {format: "yyyyMMdd"}
    else null

// Helper function to map SAP status codes to canonical status
fun mapStatus(sapStatus: String): String = 
    sapStatus match {
        case "A" -> "APPROVED"
        case "B" -> "BLOCKED"
        case "C" -> "COMPLETED"
        case "D" -> "DELETED"
        case "P" -> "PENDING"
        case "R" -> "RELEASED"
        case else -> "UNKNOWN"
    }

// Extract search results from SAP response
var searchResults = payload.RFC_READ_TABLE.DATA.*row default []
var fieldDefs = payload.RFC_READ_TABLE.FIELDS.*row default []

// Parse the fixed-width data into structured records
var parsedResults = searchResults map (row) -> do {
    var fields = row.WA splitBy "|"
    ---
    {
        PO_NUMBER: trim(fields[0] default ""),
        COMP_CODE: trim(fields[1] default ""),
        PURCH_ORG: trim(fields[2] default ""),
        PUR_GROUP: trim(fields[3] default ""),
        VENDOR: trim(fields[4] default ""),
        DOC_DATE: trim(fields[5] default ""),
        CURRENCY: trim(fields[6] default ""),
        STATUS: trim(fields[7] default "")
    }
}
---
parsedResults map (po) -> {
    id: po.PO_NUMBER,
    companyCode: po.COMP_CODE,
    purchasingOrg: po.PURCH_ORG,
    purchasingGroup: po.PUR_GROUP,
    vendorId: po.VENDOR,
    documentDate: formatSapDate(po.DOC_DATE),
    currency: po.CURRENCY,
    status: mapStatus(po.STATUS),
    items: []
}
