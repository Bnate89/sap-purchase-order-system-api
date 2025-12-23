%dw 2.0
output application/json
/**
 * SAP BAPI_PO_GETDETAIL Response to Canonical PurchaseOrder Transformation
 * 
 * This transformation maps SAP EKKO (header) and EKPO (items) structures
 * to the canonical PurchaseOrder model.
 * 
 * Input: SAP BAPI_PO_GETDETAIL XML response
 * Output: Canonical PurchaseOrder JSON
 */

// Helper function to format SAP date (YYYYMMDD) to ISO date
fun formatSapDate(sapDate: String): Date | Null = 
    if (sapDate != null and sapDate != "00000000" and sizeOf(sapDate) == 8)
        sapDate as Date {format: "yyyyMMdd"}
    else null

// Helper function to format SAP timestamp to ISO datetime
fun formatSapTimestamp(sapDate: String, sapTime: String): DateTime | Null = 
    if (sapDate != null and sapDate != "00000000")
        (sapDate ++ (sapTime default "000000")) as DateTime {format: "yyyyMMddHHmmss"}
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

// Extract header data from SAP response
var header = payload.BAPI_PO_GETDETAIL.PO_HEADER default {}
var items = payload.BAPI_PO_GETDETAIL.PO_ITEMS.*POITEM default []
var address = payload.BAPI_PO_GETDETAIL.PO_ADDRESS default {}

---
{
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
    items: items map (item) -> {
        itemNumber: trim(item.PO_ITEM default ""),
        (materialId: trim(item.MATERIAL)) if (item.MATERIAL?),
        (description: trim(item.SHORT_TEXT)) if (item.SHORT_TEXT?),
        quantity: item.QUANTITY as Number default 0,
        unitOfMeasure: trim(item.PO_UNIT default ""),
        plant: trim(item.PLANT default ""),
        (netPrice: item.NET_PRICE as Number) if (item.NET_PRICE?),
        (taxCode: trim(item.TAX_CODE)) if (item.TAX_CODE?),
        (expectedDeliveryDate: formatSapDate(item.DELIV_DATE default "")) if (item.DELIV_DATE?)
    },
    (deliveryAddress: {
        (street: trim(address.STREET)) if (address.STREET?),
        (city: trim(address.CITY)) if (address.CITY?),
        (state: trim(address.REGION)) if (address.REGION?),
        (postalCode: trim(address.POSTL_COD1)) if (address.POSTL_COD1?),
        (country: trim(address.COUNTRY)) if (address.COUNTRY?)
    }) if (address?),
    (createdDate: formatSapTimestamp(header.CREAT_DATE default "", header.CREAT_TIME default "")) if (header.CREAT_DATE?),
    (lastModifiedDate: formatSapTimestamp(header.CHG_DATE default "", header.CHG_TIME default "")) if (header.CHG_DATE?)
}
