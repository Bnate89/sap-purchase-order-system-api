%dw 2.0
output application/json
/**
 * Canonical Error Response Transformation
 * 
 * This transformation creates a standardized error response
 * following the ErrorResponse schema defined in the RAML.
 * 
 * Input: Mule error object
 * Output: Canonical ErrorResponse JSON
 */

// Map error types to HTTP-friendly codes
fun mapErrorCode(errorType: String): String = 
    errorType match {
        case "APIKIT:BAD_REQUEST" -> "BAD_REQUEST"
        case "APIKIT:NOT_FOUND" -> "NOT_FOUND"
        case "APIKIT:METHOD_NOT_ALLOWED" -> "METHOD_NOT_ALLOWED"
        case "APIKIT:UNSUPPORTED_MEDIA_TYPE" -> "UNSUPPORTED_MEDIA_TYPE"
        case "APIKIT:NOT_ACCEPTABLE" -> "NOT_ACCEPTABLE"
        case "SAP:CONNECTIVITY" -> "SAP_CONNECTION_ERROR"
        case "SAP:EXECUTION_ERROR" -> "SAP_EXECUTION_ERROR"
        case "SAP:TIMEOUT" -> "SAP_TIMEOUT"
        case "VALIDATION:INVALID_PAYLOAD" -> "VALIDATION_ERROR"
        case "HTTP:CONNECTIVITY" -> "DOWNSTREAM_CONNECTION_ERROR"
        case "HTTP:TIMEOUT" -> "DOWNSTREAM_TIMEOUT"
        case else -> "INTERNAL_ERROR"
    }
---
{
    code: mapErrorCode(error.errorType.identifier default "UNKNOWN"),
    message: error.description default "An unexpected error occurred",
    (details: error.detailedDescription) if (error.detailedDescription?)
}
