// AWGiphyAPIError.swift — Public error type thrown by all AWGiphyServices methods.

/// Errors thrown by AWGiphyServices methods.
public enum AWGiphyAPIError: Error, Equatable {
    /// A transport-level error occurred — no connectivity, timeout, DNS failure,
    /// or the URLSession response was not a valid HTTP response.
    case networkError
    /// The response payload could not be decoded into the expected type.
    case parsingError
    /// The Giphy API returned an error in the response body (HTTP 4xx/5xx).
    case apiError(code: Int, message: String)
}
