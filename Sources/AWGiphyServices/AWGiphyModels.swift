// AWGiphyModels.swift — Public request and response models for AWGiphyServices.

// MARK: - Request types

/// Parameters for a GIF search request.
public struct AWGiphySearchRequest: Sendable {
    /// The search query term or phrase. Maximum 50 characters.
    public let query: String
    /// The maximum number of results to return. Default: 25, max: 50 (beta keys).
    public let limit: Int
    /// The starting position of results. Default: 0, max: 4999.
    public let offset: Int
    /// Content rating filter. Acceptable values: "g", "pg", "pg-13", "r".
    public let rating: String?

    public init(query: String, limit: Int = 25, offset: Int = 0, rating: String? = nil) {
        self.query = query
        self.limit = limit
        self.offset = offset
        self.rating = rating
    }
}

/// Parameters for a trending GIFs request.
public struct AWGiphyTrendingRequest: Sendable {
    /// The maximum number of results to return. Default: 25.
    public let limit: Int
    /// The starting position of results. Default: 0, max: 499.
    public let offset: Int
    /// Content rating filter. Acceptable values: "g", "pg", "pg-13", "r".
    public let rating: String?

    public init(limit: Int = 25, offset: Int = 0, rating: String? = nil) {
        self.limit = limit
        self.offset = offset
        self.rating = rating
    }
}

// MARK: - Response types

/// A single GIF returned by the Giphy API.
public struct AWGiphyGIF: Decodable, Hashable, Identifiable, Sendable {
    /// The GIF's unique ID.
    public let id: String
    /// The title of the GIF on giphy.com.
    public let title: String
    /// The slug used in the GIF's URL.
    public let slug: String
    /// The public URL for this GIF on giphy.com.
    public let url: String
    /// The content rating (g, pg, pg-13, r).
    public let rating: String
    /// Username of the uploader, if any.
    public let username: String
    /// Available renditions for this GIF.
    public let images: AWGiphyImages

    private enum CodingKeys: String, CodingKey {
        case id, title, slug, url, rating, username, images
    }
}

/// The set of image renditions available for a GIF.
///
/// Use `fixedHeight` for grid thumbnails and `original` for detail views.
public struct AWGiphyImages: Decodable, Hashable, Sendable {
    /// 200px tall rendition. Good for grid thumbnails on mobile.
    public let fixedHeight: AWGiphyRendition
    /// 200px tall still (first frame only).
    public let fixedHeightStill: AWGiphyRendition
    /// 100px tall small rendition. Good for keyboards.
    public let fixedHeightSmall: AWGiphyRendition
    /// 200px wide rendition.
    public let fixedWidth: AWGiphyRendition
    /// 200px wide still (first frame only).
    public let fixedWidthStill: AWGiphyRendition
    /// Original resolution rendition.
    public let original: AWGiphyRendition
    /// Downsized version under 2MB.
    public let downsized: AWGiphyRendition

    private enum CodingKeys: String, CodingKey {
        case fixedHeight        = "fixed_height"
        case fixedHeightStill   = "fixed_height_still"
        case fixedHeightSmall   = "fixed_height_small"
        case fixedWidth         = "fixed_width"
        case fixedWidthStill    = "fixed_width_still"
        case original
        case downsized
    }
}

/// A single rendition of a GIF.
public struct AWGiphyRendition: Decodable, Hashable, Sendable {
    /// The direct GIF URL for this rendition. May be nil for mp4-only renditions.
    public let url: String?
    /// The .mp4 URL for this rendition (smaller file, smoother playback).
    public let mp4: String?
    /// The .webp URL for this rendition.
    public let webp: String?
    /// Width in pixels (as a string per the Giphy API schema).
    public let width: String?
    /// Height in pixels (as a string per the Giphy API schema).
    public let height: String?

    /// Parsed width as an integer. `nil` when the field is absent or non-numeric.
    public var widthInt: Int? { width.flatMap(Int.init) }
    /// Parsed height as an integer. `nil` when the field is absent or non-numeric.
    public var heightInt: Int? { height.flatMap(Int.init) }

    private enum CodingKeys: String, CodingKey {
        case url, mp4, webp, width, height
    }
}

/// Pagination metadata included in list responses.
public struct AWGiphyPagination: Decodable, Sendable {
    /// Total number of items returned in this response.
    public let count: Int
    /// Current offset position in the full result set.
    public let offset: Int
    /// Total number of items available (not always present).
    public let totalCount: Int?

    private enum CodingKeys: String, CodingKey {
        case count, offset
        case totalCount = "total_count"
    }
}

// MARK: - Internal envelope types

struct GiphyListEnvelope: Decodable {
    let data: [AWGiphyGIF]
    let pagination: AWGiphyPagination
}

struct GiphySingleEnvelope: Decodable {
    let data: AWGiphyGIF
}
