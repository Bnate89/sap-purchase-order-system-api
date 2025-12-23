%dw 2.0
output application/xml
/**
 * Canonical UpdatePORequest to SAP BAPI_PO_CHANGE Input Transformation
 * 
 * This transformation maps the canonical UpdatePORequest model
 * to SAP BAPI_PO_CHANGE input structures including:
 * - POHEADER / POHEADERX (for header updates)
 * - POITEM / POITEMX (for item updates)
 * - POADDRDELIVERY (for address updates)
 * 
 * Input: Canonical UpdatePORequest JSON + poId variable
 * Output: SAP BAPI_PO_CHANGE XML input
 */

// Helper function to format ISO date to SAP date (YYYYMMDD)
fun toSapDate(isoDate): String = 
    if (isoDate != null)
        (isoDate as Date) as String {format: "yyyyMMdd"}
    else "00000000"

// Helper function to pad item number to 5 digits
fun padItemNumber(itemNum: String): String = 
    itemNum as Number as String {format: "00000"}

var updateData = payload
var purchaseOrderId = vars.poId
---
{
    BAPI_PO_CHANGE: {
        "import": {
            PURCHASEORDER: purchaseOrderId,
            (POHEADER: {
                (CURRENCY: updateData.currency) if (updateData.currency?)
            }) if (updateData.currency?),
            (POHEADERX: {
                (CURRENCY: "X") if (updateData.currency?)
            }) if (updateData.currency?)
        },
        tables: {
            (POITEM: {
                (updateData.items map (item) -> {
                    row: {
                        PO_ITEM: padItemNumber(item.itemNumber),
                        (MATERIAL: item.materialId) if (item.materialId?),
                        (SHORT_TEXT: item.description) if (item.description?),
                        (QUANTITY: item.quantity as String) if (item.quantity?),
                        (PO_UNIT: item.unitOfMeasure) if (item.unitOfMeasure?),
                        (PLANT: item.plant) if (item.plant?),
                        (NET_PRICE: item.netPrice as String) if (item.netPrice?),
                        (TAX_CODE: item.taxCode) if (item.taxCode?),
                        (DELIV_DATE: toSapDate(item.expectedDeliveryDate)) if (item.expectedDeliveryDate?)
                    }
                })
            }) if (updateData.items?),
            (POITEMX: {
                (updateData.items map (item) -> {
                    row: {
                        PO_ITEM: padItemNumber(item.itemNumber),
                        PO_ITEMX: "X",
                        (MATERIAL: "X") if (item.materialId?),
                        (SHORT_TEXT: "X") if (item.description?),
                        (QUANTITY: "X") if (item.quantity?),
                        (PO_UNIT: "X") if (item.unitOfMeasure?),
                        (PLANT: "X") if (item.plant?),
                        (NET_PRICE: "X") if (item.netPrice?),
                        (TAX_CODE: "X") if (item.taxCode?),
                        (DELIV_DATE: "X") if (item.expectedDeliveryDate?)
                    }
                })
            }) if (updateData.items?),
            (POADDRDELIVERY: {
                row: {
                    (STREET: updateData.deliveryAddress.street) if (updateData.deliveryAddress.street?),
                    (CITY: updateData.deliveryAddress.city) if (updateData.deliveryAddress.city?),
                    (REGION: updateData.deliveryAddress.state) if (updateData.deliveryAddress.state?),
                    (POSTL_COD1: updateData.deliveryAddress.postalCode) if (updateData.deliveryAddress.postalCode?),
                    (COUNTRY: updateData.deliveryAddress.country) if (updateData.deliveryAddress.country?)
                }
            }) if (updateData.deliveryAddress?)
        }
    }
}
