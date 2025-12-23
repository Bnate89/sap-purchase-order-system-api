%dw 2.0
output application/xml
fun toSapDate(isoDate): String = 
    if (isoDate != null)
        (isoDate as Date) as String {format: "yyyyMMdd"}
    else "00000000"

// Helper function to pad item number to 5 digits
fun padItemNumber(index: Number): String = 
    ((index + 1) * 10) as String {format: "00000"}

var poData = payload
---
{
    BAPI_PO_CREATE1: {
        "import": {
            POHEADER: {
                COMP_CODE: poData.companyCode,
                DOC_TYPE: "NB",
                VENDOR: poData.vendorId,
                PURCH_ORG: poData.purchasingOrg,
                PUR_GROUP: poData.purchasingGroup,
                CURRENCY: poData.currency,
                DOC_DATE: now() as String {format: "yyyyMMdd"}
            },
            POHEADERX: {
                COMP_CODE: "X",
                DOC_TYPE: "X",
                VENDOR: "X",
                PURCH_ORG: "X",
                PUR_GROUP: "X",
                CURRENCY: "X",
                DOC_DATE: "X"
            }
        },
        tables: {
            POITEM: {
                (poData.items map (item, index) -> {
                    row: {
                        PO_ITEM: padItemNumber(index),
                        (MATERIAL: item.materialId) if (item.materialId?),
                        (SHORT_TEXT: item.description) if (item.description?),
                        QUANTITY: item.quantity as String,
                        PO_UNIT: item.unitOfMeasure,
                        PLANT: item.plant,
                        (NET_PRICE: item.netPrice as String) if (item.netPrice?),
                        (TAX_CODE: item.taxCode) if (item.taxCode?),
                        (DELIV_DATE: toSapDate(item.expectedDeliveryDate)) if (item.expectedDeliveryDate?)
                    }
                })
            },
            POITEMX: {
                (poData.items map (item, index) -> {
                    row: {
                        PO_ITEM: padItemNumber(index),
                        PO_ITEMX: "X",
                        (MATERIAL: "X") if (item.materialId?),
                        (SHORT_TEXT: "X") if (item.description?),
                        QUANTITY: "X",
                        PO_UNIT: "X",
                        PLANT: "X",
                        (NET_PRICE: "X") if (item.netPrice?),
                        (TAX_CODE: "X") if (item.taxCode?),
                        (DELIV_DATE: "X") if (item.expectedDeliveryDate?)
                    }
                })
            },
            (POADDRDELIVERY: {
                row: {
                    (STREET: poData.deliveryAddress.street) if (poData.deliveryAddress.street?),
                    (CITY: poData.deliveryAddress.city) if (poData.deliveryAddress.city?),
                    (REGION: poData.deliveryAddress.state) if (poData.deliveryAddress.state?),
                    (POSTL_COD1: poData.deliveryAddress.postalCode) if (poData.deliveryAddress.postalCode?),
                    (COUNTRY: poData.deliveryAddress.country) if (poData.deliveryAddress.country?)
                }
            }) if (poData.deliveryAddress?)
        }
    }
}
