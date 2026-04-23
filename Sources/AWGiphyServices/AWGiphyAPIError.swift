// AWGiphyAPIError.swift — Public error type thrown by all AWGiphyServices methods.

/// Errors thrown by AWGiphyServices methods.
public enum AWGiphyAPIError: Error, Equatable {
    /// The server returned a non-2xx HTTP status code.
    case networkError
    /// The response payload could not be decoded into the expected type.
    case parsingError
    /// The Giphy API returned an error in the response body (HTTP 4xx/5xx).
    case apiError(code: Int, message: String)
}
