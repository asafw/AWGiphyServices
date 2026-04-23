// AWGiphyAPIError.swift — Public error type thrown by all AWGiphyServices methods.

import Foundation

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

extension AWGiphyAPIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkError:
            return "No network connection. Check your internet and try again."
        case .parsingError:
            return "Unexpected response from Giphy. Please try again."
        case .apiError(let code, let message):
            switch code {
            case 403: return "Invalid API key (403). Check your key and try again."
            case 429: return "Rate limit exceeded (429). Please wait and try again."
            default:  return "Giphy error \(code): \(message)"
            }
        }
    }
}
