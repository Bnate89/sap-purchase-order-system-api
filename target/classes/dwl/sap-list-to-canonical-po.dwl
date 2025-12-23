%dw 2.0
output application/json
/**
 * SAP BAPI_PO_GETITEMS Response to Canonical PurchaseOrder Array Transformation
 * 
 * This transformation maps SAP PO list response (multiple POs)
 * to an array of canonical PurchaseOrder objects.
 * 
 * Input: SAP BAPI response with PO list
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

// Extract PO headers from SAP response
var poHeaders = payload.BAPI_PO_GETITEMS.PO_HEADERS.*POHEADER default []
var poItems = payload.BAPI_PO_GETITEMS.PO_ITEMS.*POITEM default []

---
poHeaders map (header) -> {
    id: trim(header.PO_NUMBER default ""),
    companyCode: trim(header.COMP_CODE default ""),
    purchasingOrg: trim(header.PURCH_ORG default ""),
    purchasingGroup: trim(header.PUR_GROUP default ""),
    vendorId: trim(header.VENDOR default ""),
    documentDate: formatSapDate(header.DOC_DATE default ""),
    (createdBy: trim(header.CREATED_BY)) if (header.CREATED_BY?),
    currency: trim(header.CURRENCY default ""),
    (totalAmount: header.NET_VALUE as Number) if (header.NET_VALUE?),
    status: mapStatus(header.STATUS default ""),
    items: (poItems filter ($.PO_NUMBER == header.PO_NUMBER)) map (item) -> {
        itemNumber: trim(item.PO_ITEM default ""),
        (materialId: trim(item.MATERIAL)) if (item.MATERIAL?),
        (description: trim(item.SHORT_TEXT)) if (item.SHORT_TEXT?),
        quantity: item.QUANTITY as Number default 0,
        unitOfMeasure: trim(item.PO_UNIT default ""),
        plant: trim(item.PLANT default ""),
        (netPrice: item.NET_PRICE as Number) if (item.NET_PRICE?),
        (taxCode: trim(item.TAX_CODE)) if (item.TAX_CODE?),
        (expectedDeliveryDate: formatSapDate(item.DELIV_DATE default "")) if (item.DELIV_DATE?)
    }
}
